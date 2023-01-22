import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frc_scouting/helpers/match_schedule_helper.dart';
import 'package:frc_scouting/helpers/scouters_schedule_helper.dart';
import 'package:frc_scouting/models/robot_action.dart';
import 'package:frc_scouting/models/service.dart';
import 'package:get/get.dart';

import '../getx_screens/home_screen.dart';
import '../persistence/files_helper.dart';
import '../models/event.dart';
import '../models/match_data.dart';
import '../helpers/scouters_helper.dart';

enum MatchFilterType { date, hasNotUploaded }

extension MatchFilterTypeExtension on MatchFilterType {
  String get localizedDescription {
    switch (this) {
      case MatchFilterType.date:
        return "Date";
      case MatchFilterType.hasNotUploaded:
        return "Not Uploaded";
      default:
        return "Unknown";
    }
  }
}

class BusinessLogicController extends GetxController {
  late MatchData matchData;
  final FilesHelper documentsHelper = FilesHelper();
  var matchFilterType = MatchFilterType.date.obs;
  final ServiceHelper serviceHelper = ServiceHelper();

  @override
  void onInit() async {
    matchData = MatchData();

    try {
      MatchScheduleHelper.shared.getMatchSchedule(networkRefresh: true);
    } catch (e) {
      try {
        MatchScheduleHelper.shared.getMatchSchedule(networkRefresh: false);
      } catch (e) {}
      print("Error getting event schedule: $e");
    }

    try {
      ScoutersHelper.shared.getAllScouters(networkRefresh: true);
    } catch (e) {
      try {
        ScoutersHelper.shared.getAllScouters(networkRefresh: false);
      } catch (e) {}
      print("Error getting scouters: $e");
    }

    try {
      ScoutersScheduleHelper.shared.getScoutersSchedule(networkRefresh: true);
    } catch (e) {
      try {
        ScoutersScheduleHelper.shared
            .getScoutersSchedule(networkRefresh: false);
      } catch (e) {}

      print("Error getting scouters schedule: $e");
    }

    super.onInit();
  }

  Orientation get currentOrientation {
    return Get.mediaQuery.orientation;
  }

  void setPortraitOrientation() {
    SystemChrome.setPreferredOrientations(
      [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
    );
  }

  void setLandscapeOrientation() {
    SystemChrome.setPreferredOrientations(
      [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
    );
  }

  void resetOrientation() {
    SystemChrome.setPreferredOrientations(
      [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
    );
  }

  void addEventToTimeline(
      {required RobotAction robotAction, required int position}) {
    final event = Event(
      timeSince: Duration(
          milliseconds: DateTime.now().millisecondsSinceEpoch -
              matchData.startTime.millisecondsSinceEpoch),
      action: robotAction,
      position: position,
    );

    matchData.events.add(event);
    event.debugLogDescription();
  }

  List<String> separateEventsToQrCodes(MatchData matchData) {
    List<String> qrCodes = [];
    var jsonString = jsonEncode(matchData.toJson(includeUploadStatus: false));
    const qrCodeLimit = 2500;
    final totalPages = (jsonString.length / qrCodeLimit).ceil();

    print("jsonString length: ${jsonString.length}");

    var currentPage = 0;

    while (jsonString.length > qrCodeLimit) {
      final jsonPage = jsonEncode({
        "uuid": matchData.uuid,
        "currentPage": currentPage,
        "totalPages": totalPages,
        "data": jsonString.substring(0, qrCodeLimit)
      });

      currentPage++;

      qrCodes.add(jsonPage);
      jsonString = jsonString.replaceRange(0, qrCodeLimit, "");
    }

    final jsonPage = jsonEncode({
      "uuid": matchData.uuid,
      "currentPage": currentPage,
      "totalPages": totalPages,
      "data": jsonString
    });

    qrCodes.add(jsonPage);

    print("# of QrCodes: ${qrCodes.length}");

    return qrCodes;
  }

  void reset() {
    // ignore: unnecessary_string_interpolations
    final scouterName = "${matchData.scouterName.value}";
    matchData = MatchData();
    matchData.scouterName.value = scouterName;
    Get.offAll(() => HomeScreen());
  }
}
