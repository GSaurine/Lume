import 'package:flutter_test/flutter_test.dart';
import 'package:lume_launcher/data/models/installed_app.dart';

void main() {
  group('InstalledApp.fromMap', () {
    test('lê o que o Kotlin envia', () {
      final InstalledApp app = InstalledApp.fromMap(<Object?, Object?>{
        'id': 'com.whatsapp/com.whatsapp.Main',
        'name': 'WhatsApp',
        'packageName': 'com.whatsapp',
        'activityName': 'com.whatsapp.Main',
        'isSystemApp': false,
      });

      expect(app.name, 'WhatsApp');
      expect(app.packageName, 'com.whatsapp');
      expect(app.id, 'com.whatsapp/com.whatsapp.Main');
      expect(app.isSystemApp, isFalse);
    });

    test('usa o package como nome quando o label vem vazio', () {
      final InstalledApp app = InstalledApp.fromMap(<Object?, Object?>{
        'name': '   ',
        'packageName': 'com.example.semnome',
      });

      expect(app.name, 'com.example.semnome');
    });

    test('aguenta campos opcionais em falta', () {
      final InstalledApp app = InstalledApp.fromMap(<Object?, Object?>{
        'packageName': 'com.example.app',
      });

      expect(app.activityName, isEmpty);
      expect(app.isSystemApp, isFalse);
    });
  });

  group('LauncherPlatformEvent', () {
    test('mapeia os tipos enviados pelo Android', () {
      expect(
        LauncherPlatformEvent.fromMap(<Object?, Object?>{'type': 'package_added'}).type,
        LauncherEventType.packageAdded,
      );
      expect(
        LauncherPlatformEvent.fromMap(<Object?, Object?>{'type': 'home_pressed'}).type,
        LauncherEventType.homePressed,
      );
      expect(
        LauncherPlatformEvent.fromMap(<Object?, Object?>{'type': 'qualquer'}).type,
        LauncherEventType.unknown,
      );
    });

    test('só os eventos de pacote invalidam a lista', () {
      bool affects(String type) =>
          LauncherPlatformEvent.fromMap(<Object?, Object?>{'type': type}).affectsAppList;

      expect(affects('package_added'), isTrue);
      expect(affects('package_removed'), isTrue);
      expect(affects('home_pressed'), isFalse);
    });
  });
}
