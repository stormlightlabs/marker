import { createId, nowIso } from './id';
import type {
  AnnotationBodyRecord,
  AnnotationMotivation,
  AnnotationRecord,
  AnnotationTargetRecord,
  MarkerDb,
  Selector,
} from './schema';

export type CreateAnnotationInput = {
  pageId: string;
  sourceUrl: string;
  selector: Selector[];
  motivation: AnnotationMotivation;
  bodies?: Array<Omit<AnnotationBodyRecord, 'id' | 'annotationId'>>;
  now?: string;
};

export type AnnotationWithParts = {
  annotation: AnnotationRecord;
  targets: AnnotationTargetRecord[];
  bodies: AnnotationBodyRecord[];
};

export class AnnotationRepository {
  constructor(private readonly db: MarkerDb) {}

  async createAnnotation(input: CreateAnnotationInput): Promise<AnnotationWithParts> {
    const now = input.now ?? nowIso();
    const annotation: AnnotationRecord = {
      id: createId('annotation'),
      pageId: input.pageId,
      motivation: input.motivation,
      createdAt: now,
      modifiedAt: now,
    };
    const target: AnnotationTargetRecord = {
      id: createId('target'),
      annotationId: annotation.id,
      sourceUrl: input.sourceUrl,
      selector: input.selector,
    };
    const bodies: AnnotationBodyRecord[] = (input.bodies ?? []).map((body) => ({
      id: createId('body'),
      annotationId: annotation.id,
      ...body,
    }));

    await this.db.transaction(
      'rw',
      this.db.annotations,
      this.db.annotationTargets,
      this.db.annotationBodies,
      async () => {
        await this.db.annotations.add(annotation);
        await this.db.annotationTargets.add(target);
        await this.db.annotationBodies.bulkAdd(bodies);
      },
    );

    return { annotation, targets: [target], bodies };
  }

  async listAnnotationsForPage(pageId: string): Promise<AnnotationWithParts[]> {
    const annotations = await this.db.annotations
      .where('pageId')
      .equals(pageId)
      .filter((annotation) => annotation.deletedAt == null)
      .toArray();

    return Promise.all(annotations.map((annotation) => this.getAnnotationWithParts(annotation)));
  }

  async updateMarkdownBody(annotationId: string, value: string, now = nowIso()): Promise<void> {
    const body = await this.db.annotationBodies
      .where('annotationId')
      .equals(annotationId)
      .filter((candidate) => candidate.type === 'TextualBody' && candidate.format === 'text/markdown')
      .first();

    if (body == null) {
      await this.db.annotationBodies.add({
        id: createId('body'),
        annotationId,
        type: 'TextualBody',
        format: 'text/markdown',
        value,
      });
    } else {
      await this.db.annotationBodies.update(body.id, { value });
    }

    await this.db.annotations.update(annotationId, { modifiedAt: now });
  }

  async deleteAnnotation(annotationId: string, now = nowIso()): Promise<void> {
    await this.db.annotations.update(annotationId, { deletedAt: now, modifiedAt: now });
  }

  private async getAnnotationWithParts(annotation: AnnotationRecord): Promise<AnnotationWithParts> {
    const [targets, bodies] = await Promise.all([
      this.db.annotationTargets.where('annotationId').equals(annotation.id).toArray(),
      this.db.annotationBodies.where('annotationId').equals(annotation.id).toArray(),
    ]);
    return { annotation, targets, bodies };
  }
}
