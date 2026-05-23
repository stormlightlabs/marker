import type {
  AnnotationBodyRecord,
  AnnotationRecord,
  AnnotationTargetRecord,
  BookmarkFolderRecord,
  BookmarkRecord,
  MarkerDb,
  PageRecord,
} from './schema';

export type MarkerExport = {
  version: 1;
  exportedAt: string;
  pages: PageRecord[];
  bookmarkFolders: BookmarkFolderRecord[];
  bookmarks: BookmarkRecord[];
  annotations: AnnotationRecord[];
  annotationTargets: AnnotationTargetRecord[];
  annotationBodies: AnnotationBodyRecord[];
};

export class ExportRepository {
  constructor(private readonly db: MarkerDb) {}

  async exportJson(exportedAt = new Date().toISOString()): Promise<MarkerExport> {
    const [pages, bookmarkFolders, bookmarks, annotations, annotationTargets, annotationBodies] = await Promise.all([
      this.db.pages.toArray(),
      this.db.bookmarkFolders.toArray(),
      this.db.bookmarks.toArray(),
      this.db.annotations.toArray(),
      this.db.annotationTargets.toArray(),
      this.db.annotationBodies.toArray(),
    ]);

    return {
      version: 1,
      exportedAt,
      pages,
      bookmarkFolders,
      bookmarks,
      annotations,
      annotationTargets,
      annotationBodies,
    };
  }

  async importJson(input: MarkerExport): Promise<void> {
    if (input.version !== 1) {
      throw new Error(`Unsupported Marker export version: ${input.version}`);
    }

    await this.db.transaction(
      'rw',
      [
        this.db.pages,
        this.db.bookmarkFolders,
        this.db.bookmarks,
        this.db.annotations,
        this.db.annotationTargets,
        this.db.annotationBodies,
      ],
      async () => {
        await this.db.pages.bulkPut(input.pages);
        await this.db.bookmarkFolders.bulkPut(input.bookmarkFolders);
        await this.db.bookmarks.bulkPut(input.bookmarks);
        await this.db.annotations.bulkPut(input.annotations);
        await this.db.annotationTargets.bulkPut(input.annotationTargets);
        await this.db.annotationBodies.bulkPut(input.annotationBodies);
      },
    );
  }
}
