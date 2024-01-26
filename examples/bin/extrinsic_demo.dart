import 'package:convert/convert.dart';
import 'package:polkadart/polkadart.dart'
    show
        AuthorApi,
        Extrinsic,
        Provider,
        SignatureType,
        SigningPayload,
        StateApi;
import 'package:polkadart_keyring/polkadart_keyring.dart';

import 'package:polkadart_example/generated/polkadot/polkadot.dart';
import 'package:polkadart_example/generated/polkadot/types/sp_runtime/multiaddress/multi_address.dart';

Future<void> main(List<String> arguments) async {
  final provider = Provider.fromUri(Uri.parse('ws://127.0.0.1:9944'));
  final api = Polkadot(provider);

  final stateApi = StateApi(provider);

  final runtimeVersion = await stateApi.getRuntimeVersion();

  final specVersion = runtimeVersion.specVersion;

  final transactionVersion = runtimeVersion.transactionVersion;

  final block = await provider.send('chain_getBlock', []);

  final blockNumber = int.parse(block.result['block']['header']['number']);

  final blockHash = (await provider.send('chain_getBlockHash', []))
      .result
      .replaceAll('0x', '');

  final genesisHash = (await provider.send('chain_getBlockHash', [0]))
      .result
      .replaceAll('0x', '');

  final alice = await KeyPair.sr25519.fromUri('//Alice');
  final bob = await KeyPair.sr25519.fromUri('//Bob');

  final alicePublicKey = hex.encode(alice.publicKey.bytes);
  print('Public Key: $alicePublicKey');
  final bobMultiAddress = $MultiAddress().id(bob.publicKey.bytes);

  // Most chains have configured 12 decimals.
  const oneBalanceUnit = 1000000000000;
  final runtimeCall = api.tx.balances.transferKeepAlive(
    dest: bobMultiAddress,
    value: BigInt.from(oneBalanceUnit),
  );
  final encodedCall = hex.encode(runtimeCall.encode());
  print('Encoded call: $encodedCall');

  final accountInfo = await api.query.system.account(alice.publicKey.bytes);
  print('Nonce: ${accountInfo.nonce}');

  final payloadToSign = SigningPayload(
    method: encodedCall,
    specVersion: specVersion,
    transactionVersion: transactionVersion,
    genesisHash: genesisHash,
    blockHash: blockHash,
    blockNumber: blockNumber,
    eraPeriod: 64,
    nonce: accountInfo.nonce,
    tip: 0,
  );

  final payload = payloadToSign.encode(api.registry);
  print('Payload: ${hex.encode(payload)}');

  final signature = alice.sign(payload);
  final hexSignature = hex.encode(signature);
  print('Signature: $hexSignature');

  final extrinsic = Extrinsic.withSigningPayload(
          signer: alicePublicKey,
          method: encodedCall,
          signature: hexSignature,
          payload: payloadToSign)
      .encode(api.registry, SignatureType.sr25519);

  final hexExtrinsic = hex.encode(extrinsic);
  print('Extrinsic: $hexExtrinsic');

  final author = AuthorApi(provider);
  author.submitAndWatchExtrinsic(
      extrinsic, (p0) => print("Extrinsic result: ${p0.type} - {${p0.value}}"));
}
