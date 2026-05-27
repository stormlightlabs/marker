import 'package:flutter_test/flutter_test.dart';
import 'package:margin_poptart/at/margin/note/body.dart' as margin_body;
import 'package:margin_poptart/at/margin/note/main.dart' as margin_note;
import 'package:margin_poptart/at/margin/note/main_motivation.dart' as margin_motivation;
import 'package:margin_poptart/at/margin/note/selector.dart' as margin_selector;
import 'package:margin_poptart/at/margin/note/selector_type.dart' as margin_selector_type;
import 'package:margin_poptart/at/margin/note/target.dart' as margin_target;
import 'package:cosmik_poptart/network/cosmik/card.dart';
import 'package:cosmik_poptart/network/cosmik/collection.dart';
import 'package:cosmik_poptart/network/cosmik/collection_link.dart';
import 'package:poptart_core/poptart_core.dart';
import 'package:poptart_lex/com/atproto/repo/strong_ref.dart';

void main() {
  test('cosmik_poptart card type serializes URL bookmarks', () {
    final record = CardRecord(
      type: const CardType.knownValue(data: KnownCardType.uRL),
      url: 'https://example.com/article',
      content: UCardContent.urlContent(
        data: UrlContent(
          url: 'https://example.com/article',
          metadata: UrlMetadata(
            title: 'Example Article',
            description: 'Reference material',
            retrievedAt: DateTime.utc(2026, 5, 26, 12),
          ),
        ),
      ),
      createdAt: DateTime.utc(2026, 5, 26, 12),
    );

    final json = record.toJson();

    expect(json['\$type'], 'network.cosmik.card');
    expect(json['type'], 'URL');
    expect((json['content']! as Map<String, Object?>)['url'], 'https://example.com/article');
    expect(CardRecord.validate(json), isTrue);
    expect(CardRecord.fromJson(json).content.urlContent, isA<UrlContent>());
  });

  test('cosmik_poptart collection and link types use strong refs', () {
    final collection = CollectionRecord(
      name: 'Research',
      description: 'Papers and references',
      accessType: const CollectionAccessType.knownValue(data: KnownCollectionAccessType.cLOSED),
      createdAt: DateTime.utc(2026, 5, 26, 12),
      updatedAt: DateTime.utc(2026, 5, 26, 12),
    );
    final link = CollectionLinkRecord(
      collection: const RepoStrongRef(
        uri: AtUri('at://did:plc:alice/network.cosmik.collection/abc'),
        cid: 'bafycollection',
      ),
      card: const RepoStrongRef(uri: AtUri('at://did:plc:alice/network.cosmik.card/def'), cid: 'bafycard'),
      addedBy: 'did:plc:alice',
      addedAt: DateTime.utc(2026, 5, 26, 12),
    );

    expect(collection.toJson()['accessType'], 'CLOSED');
    expect((link.toJson()['collection']! as Map<String, Object?>)['cid'], 'bafycollection');
    expect(CollectionLinkRecord.fromJson(link.toJson()).card.cid, 'bafycard');
  });

  test('Margin note package remains the source for at.margin note types', () {
    final note = margin_note.NoteRecord(
      motivation: const margin_motivation.NoteMotivation.knownValue(
        data: margin_motivation.KnownNoteMotivation.highlighting,
      ),
      color: 'yellow',
      body: const margin_body.Body(value: 'reader note', format: 'text/markdown'),
      target: const margin_target.Target(
        source: 'https://example.com/article',
        title: 'Example Article',
        selector: margin_selector.Selector(
          type: margin_selector_type.SelectorType.knownValue(
            data: margin_selector_type.KnownSelectorType.textQuoteSelector,
          ),
          exact: 'selected text',
        ),
      ),
      createdAt: DateTime.utc(2026, 5, 26, 12),
    );

    final json = note.toJson();

    expect(json['\$type'], 'at.margin.note');
    expect(json['target'], isA<Map<String, Object?>>());
    expect((json['body']! as Map<String, Object?>)['format'], 'text/markdown');
  });
}
