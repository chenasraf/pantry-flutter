import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/wear_pairing.dart';

void main() {
  const credentials = NextcloudCredentials(
    serverUrl: 'https://cloud.example',
    loginName: 'ada',
    appPassword: 'secret',
  );

  test('a grant survives the round trip whole', () {
    const sent = WearPairingGrant(
      credentials: credentials,
      certPins: {
        'cloud.example': ['AA:BB'],
      },
      houseId: 4,
      listId: 9,
      hiddenItemChips: {'price', 'store'},
    );

    final received = WearPairingGrant.fromJson(sent.toJson());

    expect(received, isNotNull);
    expect(received!.credentials.serverUrl, 'https://cloud.example');
    expect(received.credentials.loginName, 'ada');
    expect(received.credentials.appPassword, 'secret');
    expect(received.certPins, {
      'cloud.example': ['AA:BB'],
    });
    expect(received.houseId, 4);
    expect(received.listId, 9);
    expect(received.hiddenItemChips, {'price', 'store'});
  });

  test('the meta list is a legal seeded list, not an absent one', () {
    const sent = WearPairingGrant(
      credentials: credentials,
      certPins: {},
      houseId: 4,
      listId: 0,
    );

    expect(WearPairingGrant.fromJson(sent.toJson())!.listId, 0);
  });

  test('a scope-less grant is still a grant', () {
    const sent = WearPairingGrant(credentials: credentials, certPins: {});

    final received = WearPairingGrant.fromJson(sent.toJson());

    expect(received, isNotNull);
    expect(received!.houseId, isNull);
    expect(received.listId, isNull);
    expect(received.hiddenItemChips, isEmpty);
  });

  test('a payload with no credential is refused rather than half-applied', () {
    expect(WearPairingGrant.fromJson({'houseId': 4}), isNull);
    expect(WearPairingGrant.fromJson({'credentials': 'nonsense'}), isNull);
    expect(
      WearPairingGrant.fromJson({
        'credentials': {'serverUrl': 'https://cloud.example'},
      }),
      isNull,
    );
  });

  test('an empty app password is refused, not stored', () {
    expect(
      WearPairingGrant.fromJson({
        'credentials': {
          'serverUrl': 'https://cloud.example',
          'loginName': 'ada',
          'appPassword': '',
        },
      }),
      isNull,
    );
  });

  test('pins of an unexpected shape are dropped, not fatal', () {
    final received = WearPairingGrant.fromJson({
      'credentials': credentials.toJson(),
      'certPins': {
        'cloud.example': ['AA:BB'],
        'broken.example': 'not-a-list',
      },
    });

    expect(received, isNotNull);
    expect(received!.certPins, {
      'cloud.example': ['AA:BB'],
    });
  });

  test('a refusal names the one condition the watch cannot infer', () {
    expect(
      WearPairingRefusal.fromJson(WearPairingRefusal.signedOut.toJson()),
      WearPairingRefusal.signedOut,
    );
    expect(WearPairingRefusal.fromJson(const {}), isNull);
    expect(WearPairingRefusal.fromJson(const {'reason': 'later'}), isNull);
  });

  test('paths are the pair both devices agree on across releases', () {
    expect(WearPairing.requestPath, '/pairing/request');
    expect(WearPairing.grantPath, '/pairing/grant');
    expect(WearPairing.refusalPath, '/pairing/refusal');
    expect(WearPairing.unpairPath, '/pairing/unpair');
  });
}
