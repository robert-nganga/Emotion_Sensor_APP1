import 'package:app/data/collections/scan_session_collection.dart';
import 'package:app/data/collections/sensor_data_collection.dart';
import 'package:app/models/scan_session.dart';
import 'package:app/models/sensor_data.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

class SensorLocalDataSource {
  final Isar isar;
  SensorLocalDataSource({required this.isar});

  Future<bool> saveScanSession(List<SensorData> sensorDataList) async {
    final scanSession = ScanSessionCollection()
      ..startTime = DateTime.now(); // ensure startTime is set explicitly

    try {
      await isar.writeTxn(() async {
        // Save the session first
        final sessionId = await isar.scanSessionCollections.put(scanSession);

        // Convert SensorData -> SensorDataCollection and link back to session
        final sensorDataCollectionList = sensorDataList.map((element) {
          final collection = element.toCollection();
          collection.scanSession.value = scanSession; // back link
          return collection;
        }).toList();

        // Save sensor data
        final ids = await isar.sensorDataCollections.putAll(sensorDataCollectionList);
        debugPrint('Saved SensorData IDs: $ids');

        // 🔑 Save the forward link too (session -> sensorData)
        scanSession.sensorData.addAll(sensorDataCollectionList);
        await scanSession.sensorData.save();
      });

      return true;
    } catch (e, st) {
      debugPrint('Error saving scan session: $e\n$st');
      return false;
    }
  }


  Future<List<ScanSession>> getScanSessions() async {
    try {
      final sessions = await isar.scanSessionCollections.where().findAll();
      for (final session in sessions) {
        await session.sensorData.load();
      }
      debugPrint(' Source Sessions ${sessions}');
      return sessions.map((e) => e.toModel()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> deleteScanSession(int id) async {
    try {
      await isar.writeTxn(() async {
        final sensorData =
            await isar.sensorDataCollections
                .filter()
                .scanSession((q) => q.idEqualTo(id))
                .findAll();
        final sensorDataIds = sensorData.map((element) => element.id).toList();
        if (sensorDataIds.isNotEmpty) {
          await isar.sensorDataCollections.deleteAll(sensorDataIds);
        }
        await isar.scanSessionCollections.delete(id);
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
