import 'dart:typed_data' show Uint8List;
import 'dart:convert' show utf8;
import 'package:polkadart_scale_codec/utils/utils.dart';
import 'package:substrate_metadata/substrate_hashers/substrate_hashers.dart';
import 'package:substrate_metadata/substrate_metadata.dart';
import 'package:polkadart_scale_codec/polkadart_scale_codec.dart' as cocec;
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Storage Hashers Test', () {
    test('Blake2bHasher works', () {
      final testCases = {
        '': decodeHex('cae66941d9efbd404e4d88758ea67670'),
        'foo': decodeHex('04136e24f85d470465c3db66e58ed56c'),
        'System': decodeHex('789f1c09383940a7773420432ffd084a'),
      };

      for (final entry in testCases.entries) {
        final hasher = Blake2bHasher(16);
        final hash = hasher.hash(Uint8List.fromList(utf8.encode(entry.key)));
        expect(encodeHex(hash), encodeHex(entry.value));
      }
    });

    test('TwoxxHasher works', () {
      final testCases = {
        '': decodeHex('99e9d85137db46ef'),
        'foo': decodeHex('3fbac459a800bf33'),
        'System': decodeHex('26aa394eea5630e0'),
      };

      for (final entry in testCases.entries) {
        final hasher = TwoxxHasher(1);
        final hash = hasher.hash(Uint8List.fromList(utf8.encode(entry.key)));
        expect(encodeHex(hash), encodeHex(entry.value));
      }
    });

    test('TwoxxHasher works', () {
      final testCases = {
        '': decodeHex('99e9d85137db46ef4bbea33613baafd5'),
        'System': decodeHex('26aa394eea5630e07c48ae0c9558cef7'),
        'CurrentPhase': decodeHex('d9764401941df7f707a47ba7db64a6ea'),
        'EndorsementTicketsPerBootstrapper': decodeHex('5c03954ec993845da1c7ff36c91390da'),
      };

      for (final entry in testCases.entries) {
        final hasher = TwoxxHasher(2);
        final hash = hasher.hash(Uint8List.fromList(utf8.encode(entry.key)));
        expect(encodeHex(hash), encodeHex(entry.value));
      }
    });

    // The AccountId being hashed: c1763ec7974010d7d4d3810f266921bcc759d5f65e5cedd67e926ddcf2230e6b
    // Expected xxHash64 (from PJS): a8107b48dc0a9baa
    test('TwoxxHasher with 32-byte AccountId', () {
      // This is the AccountId bytes that need to be hashed
      final accountId = decodeHex(
        'c1763ec7974010d7d4d3810f266921bcc759d5f65e5cedd67e926ddcf2230e6b',
      );

      // Expected xxHash64 output (from Polkadot.js)
      final expectedHash = decodeHex('a8107b48dc0a9baa');

      final hasher = TwoxxHasher(1); // Twox64 = 1 block of 64 bits
      final hash = hasher.hash(accountId);

      expect(
        encodeHex(hash),
        encodeHex(expectedHash),
        reason: 'Twox64 hash of 32-byte AccountId should match PJS',
      );
    });

    // The AccountId being hashed: c1763ec7974010d7d4d3810f266921bcc759d5f65e5cedd67e926ddcf2230e6b
    // Expected xxHash64 (from PJS): a8107b48dc0a9baa
    test('TwoxxHasher with 32-byte AccountId', () {
      // This is the AccountId bytes that need to be hashed
      final accountId = decodeHex(
        '26be5a2c3b0c85d4f4783e2950a293b0c9f6026e5c5a897bbb9d0746a52de907',
      );

      final storageMap = StorageMap(
        prefix: 'Proxy',
        storage: 'Proxies',
        hasher: StorageHasher.twoxx64Concat(AccountId32Codec()),
        // Random codec, we do not care about the value.
        valueCodec: AccountId32Codec(),
      );

      // Expected output (from Polkadot.js)
      final module = '1809d78346727a0ef58c0fa03bafa323';
      final method = '1d885dcfb277f185f2d8e62a5f290c85';
      final twox64ConcatAccountId32 = '427611b5147e9bca26be5a2c3b0c85d4f4783e2950a293b0c9f6026e5c5a897bbb9d0746a52de907';
      final expectedHash = decodeHex(module + method + twox64ConcatAccountId32);

      final key = storageMap.hashedKeyFor(accountId);

      expect(
        encodeHex(key),
        encodeHex(expectedHash),
        reason: 'Twox64 hash of 32-byte AccountId should match PJS',
      );
    });
  });
}

// corresponds what is generated in: 'sp_core/crypto/account_id32.dart'
typedef AccountId32 = List<int>;

class AccountId32Codec with cocec.Codec<AccountId32> {
  const AccountId32Codec();

  @override
  AccountId32 decode(cocec.Input input) {
    return const cocec.U8ArrayCodec(32).decode(input);
  }

  @override
  void encodeTo(
      AccountId32 value,
      cocec.Output output,
      ) {
    const cocec.U8ArrayCodec(32).encodeTo(
      value,
      output,
    );
  }

  @override
  int sizeHint(AccountId32 value) {
    return const cocec.U8ArrayCodec(32).sizeHint(value);
  }

  @override
  bool isSizeZero() {
    return false;
  }
}

