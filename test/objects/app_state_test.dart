import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/objects/group.dart';
import 'package:final_project/objects/lake_appointment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import 'package:final_project/objects/app_state.dart';
import 'package:final_project/objects/activity.dart';

Future<AppState> initializeAppStateTests(
    FakeFirebaseFirestore instance, MockFirebaseAuth auth) async {
  AppState appState = AppState(instance, auth);

  await auth.currentUser!.reload();

  await instance.collection('events').doc('Test Subject').set({
    "name": "Test Subject",
    "ageMin": 1,
    "groupMax": 6,
    "desc": "Test Description"
  });

  await instance.collection('appointments').doc('Test Appointment').set({
    "start_time": DateTime.utc(1969, 7, 20, 20),
    "end_time": DateTime.utc(1969, 7, 20, 21),
    "color": "Color(0xff2471a3)",
    "notes": "Test Notes",
    "subject": "Test Subject",
    "group": "Test Group",
  });

  await instance
      .collection('groups')
      .doc('Test Group')
      .set({"age": 100, "color": "Color(0xff000000)", "name": "Test Group"});

  return appState;
}

void main() {
  test('AppState initializer creates listeners', () async {
    FakeFirebaseFirestore instance = FakeFirebaseFirestore();
    MockFirebaseAuth auth = MockFirebaseAuth(signedIn: true);

    AppState appState = await initializeAppStateTests(instance, auth);

    expect(appState.activities.length, 1);
    expect(appState.appointments.length, 1);
    expect(appState.groups.length, 1);
  });
  test('AppState listeners dont duplicate objects', () async {
    FakeFirebaseFirestore instance = FakeFirebaseFirestore();
    MockFirebaseAuth auth = MockFirebaseAuth(signedIn: true);

    AppState appState = await initializeAppStateTests(instance, auth);

    expect(appState.activities.length, 1);
    expect(appState.appointments.length, 1);
    expect(appState.groups.length, 1);

    await instance.collection('events').doc('Test Activity 2').set({
      "name": "Test",
      "ageMin": 1,
      "groupMax": 6,
      "desc": "Test Description"
    });

    await instance.collection('appointments').doc('Test Appointment 2').set({
      "start_time": DateTime.utc(1969, 7, 20, 20),
      "end_time": DateTime.utc(1969, 7, 20, 20, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject",
      "group": "Test Group",
    });

    await instance
        .collection('groups')
        .doc('Test Group 2')
        .set({"age": 100, "color": "Color(0xff000000)", "name": "Test Group"});

    expect(appState.activities.length, 2);
    expect(appState.appointments.length, 2);
    expect(appState.groups.length, 2);
  });
  test('filterAppointments returns all appointments when not fileterd',
      () async {
    FakeFirebaseFirestore instance = FakeFirebaseFirestore();
    MockFirebaseAuth auth = MockFirebaseAuth(signedIn: true);

    AppState appState = await initializeAppStateTests(instance, auth);

    await instance.collection('appointments').doc('Test Appointment 2').set({
      "start_time": DateTime.utc(1969, 7, 20, 20),
      "end_time": DateTime.utc(1969, 7, 20, 20, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject 2",
      "group": "Test Group 2",
    });

    List<LakeAppointment> appts = appState.filterAppointments([], []);

    expect(appts.length, 2);
    expect(appts[0].subject, "Test Subject");
    expect(appts[1].subject, "Test Subject 2");
  });
  test(
      'filterAppointments returns only matching appointments when filtered by activity',
      () async {
    FakeFirebaseFirestore instance = FakeFirebaseFirestore();
    MockFirebaseAuth auth = MockFirebaseAuth(signedIn: true);

    AppState appState = await initializeAppStateTests(instance, auth);

    await instance.collection('appointments').doc('Test Appointment 2').set({
      "start_time": DateTime.utc(1969, 7, 20, 20),
      "end_time": DateTime.utc(1969, 7, 20, 20, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject 2",
      "group": "Test Group 2",
    });

    await instance.collection('appointments').doc('Test Appointment 3').set({
      "start_time": DateTime.utc(1969, 7, 20, 20),
      "end_time": DateTime.utc(1969, 7, 20, 20, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject",
      "group": "Test Group 2",
    });

    List<LakeAppointment> appts =
        appState.filterAppointments([], ["Test Subject"]);

    expect(appts.length, 2);
    expect(appts[0].subject, "Test Subject");
    expect(appts[1].subject, "Test Subject");
  });
  test(
      'filterAppointments returns only matching appointments when filtered by group',
      () async {
    FakeFirebaseFirestore instance = FakeFirebaseFirestore();
    MockFirebaseAuth auth = MockFirebaseAuth(signedIn: true);

    AppState appState = await initializeAppStateTests(instance, auth);

    await instance.collection('appointments').doc('Test Appointment 2').set({
      "start_time": DateTime.utc(1969, 7, 20, 20),
      "end_time": DateTime.utc(1969, 7, 20, 20, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject 2",
      "group": "Test Group 2",
    });

    await instance.collection('appointments').doc('Test Appointment 3').set({
      "start_time": DateTime.utc(1969, 7, 20, 20),
      "end_time": DateTime.utc(1969, 7, 20, 20, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject",
      "group": "Test Group 2",
    });

    List<LakeAppointment> appts = appState.filterAppointments(
        [const Group(age: 1, color: Color(0xff000000), name: "Test Group 2")],
        []);

    expect(appts.length, 2);
    expect(appts[0].subject, "Test Subject 2");
    expect(appts[1].subject, "Test Subject");
  });
  test(
      'filterAppointments returns only appointments that match both group and activity.',
      () async {
    FakeFirebaseFirestore instance = FakeFirebaseFirestore();
    MockFirebaseAuth auth = MockFirebaseAuth(signedIn: true);

    AppState appState = await initializeAppStateTests(instance, auth);

    await instance.collection('appointments').doc('Test Appointment 2').set({
      "start_time": DateTime.utc(1969, 7, 20, 20),
      "end_time": DateTime.utc(1969, 7, 20, 20, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject 2",
      "group": "Test Group 2",
    });

    await instance.collection('appointments').doc('Test Appointment 3').set({
      "start_time": DateTime.utc(1969, 7, 20, 20),
      "end_time": DateTime.utc(1969, 7, 20, 20, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject",
      "group": "Test Group 2",
    });

    List<LakeAppointment> appts = appState.filterAppointments(
        [const Group(age: 1, color: Color(0xff000000), name: "Test Group 2")],
        ["Test Subject 2"]);

    expect(appts.length, 1);
    expect(appts[0].subject, "Test Subject 2");
  });
  test('addAppointments adds appointments to firebase', () async {
    FakeFirebaseFirestore instance = FakeFirebaseFirestore();
    MockFirebaseAuth auth = MockFirebaseAuth(signedIn: true);

    AppState appState = await initializeAppStateTests(instance, auth);

    await instance
        .collection('appointments')
        .count()
        .get()
        .then((value) => expect(value.count, 1));

    await appState.addAppointments({
      'appt 1': {
        "start_time": DateTime.utc(1969, 7, 20, 20),
        "end_time": DateTime.utc(1969, 7, 20, 20, 30),
        "color": "Color(0xff2471a3)",
        "notes": "Test Notes",
        "subject": "Test Subject",
        "group": "Test Group 2",
      },
      'appt 2': {
        "start_time": DateTime.utc(1969, 7, 20, 20),
        "end_time": DateTime.utc(1969, 7, 20, 20, 30),
        "color": "Color(0xff2471a3)",
        "notes": "Test Notes",
        "subject": "Test Subject",
        "group": "Test Group 2",
      }
    }, instance);

    await instance
        .collection('appointments')
        .count()
        .get()
        .then((value) => expect(value.count, 3));
    await instance
        .collection('appointments')
        .where("group", isEqualTo: "Test Group 2")
        .count()
        .get()
        .then((value) => expect(value.count, 2));
  });
  test('getCurrentAmount gets gets correct ratio of groups', () async {
    FakeFirebaseFirestore instance = FakeFirebaseFirestore();
    MockFirebaseAuth auth = MockFirebaseAuth(signedIn: true);

    AppState appState = await initializeAppStateTests(instance, auth);

    await instance.collection('appointments').doc('Test Appointment 2').set({
      "start_time": DateTime.utc(1969, 7, 20, 20),
      "end_time": DateTime.utc(1969, 7, 20, 20, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject",
      "group": "Test Group 2",
    });

    await instance.collection('appointments').doc('Test Appointment 3').set({
      "start_time": DateTime.utc(1969, 7, 20, 20),
      "end_time": DateTime.utc(1969, 7, 20, 20, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject 2",
      "group": "Test Group 2",
    });

    expect(
        appState.getCurrentAmount(
            "Test Subject", DateTime.utc(1969, 7, 20, 20)),
        "2/6");
  });
  test('getApptsAtTime gets right appts', () async {
    FakeFirebaseFirestore instance = FakeFirebaseFirestore();
    MockFirebaseAuth auth = MockFirebaseAuth(signedIn: true);

    AppState appState = await initializeAppStateTests(instance, auth);

    await instance.collection('appointments').doc('Test Appointment 2').set({
      "start_time": DateTime.utc(1969, 7, 20, 20),
      "end_time": DateTime.utc(1969, 7, 20, 20, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject",
      "group": "Test Group 2",
    });

    await instance.collection('appointments').doc('Test Appointment 3').set({
      "start_time": DateTime.utc(1969, 7, 20, 19),
      "end_time": DateTime.utc(1969, 7, 20, 20, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject",
      "group": "Test Group 2",
    });

    await instance.collection('appointments').doc('Test Appointment 4').set({
      "start_time": DateTime.utc(1969, 7, 20, 21),
      "end_time": DateTime.utc(1969, 7, 20, 21, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject",
      "group": "Test Group 2",
    });

    await instance.collection('appointments').doc('Test Appointment 5').set({
      "start_time": DateTime.utc(1969, 7, 20, 5),
      "end_time": DateTime.utc(1969, 7, 20, 22, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject",
      "group": "Test Group 2",
    });

    expect(appState.getApptsAtTime(DateTime.utc(1969, 7, 20, 20)).length, 4);
  });
  test('getGroupsAtTime gets all groups in an activity at the given time',
      () async {
    FakeFirebaseFirestore instance = FakeFirebaseFirestore();
    MockFirebaseAuth auth = MockFirebaseAuth(signedIn: true);

    AppState appState = await initializeAppStateTests(instance, auth);

    await instance.collection('appointments').doc('Test Appointment 2').set({
      "start_time": DateTime.utc(1969, 7, 20, 20),
      "end_time": DateTime.utc(1969, 7, 20, 20, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject",
      "group": "Test Group 2",
    });

    await instance.collection('appointments').doc('Test Appointment 3').set({
      "start_time": DateTime.utc(1969, 7, 20, 19),
      "end_time": DateTime.utc(1969, 7, 20, 20, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject",
      "group": "Test Group 3",
    });

    await instance.collection('appointments').doc('Test Appointment 4').set({
      "start_time": DateTime.utc(1969, 7, 20, 21),
      "end_time": DateTime.utc(1969, 7, 20, 21, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject",
      "group": "Test Group 4",
    });

    await instance.collection('appointments').doc('Test Appointment 5').set({
      "start_time": DateTime.utc(1969, 7, 20, 5),
      "end_time": DateTime.utc(1969, 7, 20, 19, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject",
      "group": "Test Group 5",
    });

    List<String> groups =
        appState.getGroupsAtTime(DateTime.utc(1969, 7, 20, 20));

    expect(groups.length, 3);
    expect(groups.contains("Test Group 2"), true);
    expect(groups.contains("Test Group"), true);
    expect(groups.contains("Test Group 3"), true);
    expect(groups.contains("Test Group 4"), false);
    expect(groups.contains("Test Group 5"), false);
  });
  test('getGroupsAtTime doesnt add duplicates to list', () async {
    FakeFirebaseFirestore instance = FakeFirebaseFirestore();
    MockFirebaseAuth auth = MockFirebaseAuth(signedIn: true);

    AppState appState = await initializeAppStateTests(instance, auth);

    await instance.collection('appointments').doc('Test Appointment 2').set({
      "start_time": DateTime.utc(1969, 7, 20, 20),
      "end_time": DateTime.utc(1969, 7, 20, 20, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject",
      "group": "Test Group 2",
    });

    await instance.collection('appointments').doc('Test Appointment 3').set({
      "start_time": DateTime.utc(1969, 7, 20, 20),
      "end_time": DateTime.utc(1969, 7, 20, 20, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject",
      "group": "Test Group 2",
    });

    List<String> groups =
        appState.getGroupsAtTime(DateTime.utc(1969, 7, 20, 20));

    expect(groups.length, 2);
    expect(groups.where((element) => element == "Test Group 2").length, 1);
  });
  test('lookupActivityByName gets correct activity', () async {
    FakeFirebaseFirestore instance = FakeFirebaseFirestore();
    MockFirebaseAuth auth = MockFirebaseAuth(signedIn: true);

    AppState appState = await initializeAppStateTests(instance, auth);

    await instance.collection('events').doc('Test Activity 2').set({
      "name": "Test Subject 2",
      "ageMin": 3,
      "groupMax": 9,
      "desc": "Test Description"
    });

    Activity activity = appState.lookupActivityByName("Test Subject 2");

    expect(activity.name, "Test Subject 2");
    expect(activity.ageMin, 3);
    expect(activity.groupMax, 9);
  });
  test('createActivity adds activities to firebase', () async {
    FakeFirebaseFirestore instance = FakeFirebaseFirestore();
    MockFirebaseAuth auth = MockFirebaseAuth(signedIn: true);

    AppState appState = await initializeAppStateTests(instance, auth);

    await instance
        .collection('events')
        .count()
        .get()
        .then((value) => expect(value.count, 1));

    await appState.createActivity(
        instance, "Test Activity 2", 9, 42, "Test Description");

    await instance
        .collection('events')
        .count()
        .get()
        .then((value) => expect(value.count, 2));
  });
  test('deleteAppointment deletes appointments locally and from firebase',
      () async {
    FakeFirebaseFirestore instance = FakeFirebaseFirestore();
    MockFirebaseAuth auth = MockFirebaseAuth(signedIn: true);

    AppState appState = await initializeAppStateTests(instance, auth);

    await instance
        .collection('appointments')
        .count()
        .get()
        .then((value) => expect(value.count, 1));

    expect(appState.appointments.length, 1);

    await appState.deleteAppt(
        startTime: DateTime.utc(1969, 7, 20, 20),
        subject: "Test Subject",
        group: "Test Group");

    await instance
        .collection('appointments')
        .count()
        .get()
        .then((value) => expect(value.count, 0));

    expect(appState.appointments.length, 0);
  });
  test('checkActiviy identifies if an activty is full', () async {
    FakeFirebaseFirestore instance = FakeFirebaseFirestore();
    MockFirebaseAuth auth = MockFirebaseAuth(signedIn: true);

    AppState appState = await initializeAppStateTests(instance, auth);

    await instance.collection('appointments').doc('Test Appointment 2').set({
      "start_time": DateTime.utc(1969, 7, 20, 20),
      "end_time": DateTime.utc(1969, 7, 20, 20, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject",
      "group": "Test Group 2",
    });

    await instance.collection('appointments').doc('Test Appointment 3').set({
      "start_time": DateTime.utc(1969, 7, 20, 20),
      "end_time": DateTime.utc(1969, 7, 20, 20, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject",
      "group": "Test Group 3",
    });

    await instance.collection('appointments').doc('Test Appointment 4').set({
      "start_time": DateTime.utc(1969, 7, 20, 20),
      "end_time": DateTime.utc(1969, 7, 20, 20, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject",
      "group": "Test Group 4",
    });

    await instance.collection('appointments').doc('Test Appointment 5').set({
      "start_time": DateTime.utc(1969, 7, 20, 20),
      "end_time": DateTime.utc(1969, 7, 20, 20, 30),
      "color": "Color(0xff2471a3)",
      "notes": "Test Notes",
      "subject": "Test Subject",
      "group": "Test Group 5",
    });

    expect(
        appState.checkActivity('Test Subject', DateTime.utc(1969, 7, 20, 20),
            DateTime.utc(1969, 7, 20, 21), 0),
        true);

    expect(
        appState.checkActivity('Test Subject', DateTime.utc(1969, 7, 20, 20),
            DateTime.utc(1969, 7, 20, 21), 1),
        true);

    expect(
        appState.checkActivity('Test Subject', DateTime.utc(1969, 7, 20, 20),
            DateTime.utc(1969, 7, 20, 21), 2),
        false);

    expect(
        appState.checkActivity('Test Subject', DateTime.utc(1969, 7, 20, 20),
            DateTime.utc(1969, 7, 20, 21), 3),
        false);
  });
  test('checkGroupTime identifies if a group is scheduled', () async {
    FakeFirebaseFirestore instance = FakeFirebaseFirestore();
    MockFirebaseAuth auth = MockFirebaseAuth(signedIn: true);

    AppState appState = await initializeAppStateTests(instance, auth);

    expect(
        appState.checkGroupTime(
            group: 'Test Group',
            startTime: DateTime.utc(1969, 7, 20, 20),
            endTime: DateTime.utc(1969, 7, 20, 21)),
        false);

    expect(
        appState.checkGroupTime(
            group: 'Test Group',
            startTime: DateTime.utc(1969, 7, 20, 19),
            endTime: DateTime.utc(1969, 7, 20, 10)),
        true);

    expect(
        appState.checkGroupTime(
            group: 'Test Group',
            startTime: DateTime.utc(1969, 7, 20, 21),
            endTime: DateTime.utc(1969, 7, 20, 23)),
        true);
  });
  test('editAppt edits existing appointments', () async {
    FakeFirebaseFirestore instance = FakeFirebaseFirestore();
    MockFirebaseAuth auth = MockFirebaseAuth(signedIn: true);

    AppState appState = await initializeAppStateTests(instance, auth);

    await instance
        .collection('appointments')
        .doc('Test Appointment')
        .get()
        .then((value) {
      expect(value.data()?['subject'], 'Test Subject');
      expect(value.data()?['start_time'],
          Timestamp.fromDate(DateTime.utc(1969, 7, 20, 20)));
      expect(value.data()?['end_time'],
          Timestamp.fromDate(DateTime.utc(1969, 7, 20, 21)));
      expect(value.data()?['color'], "Color(0xff2471a3)");
      expect(value.data()?['notes'], "Test Notes");
      expect(value.data()?['group'], 'Test Group');
    });

    await appState.editAppt(
        startTime: DateTime.utc(1969, 7, 20, 20),
        subject: 'Test Subject',
        group: 'Test Group',
        data: {
          "start_time": DateTime.utc(1969, 7, 20, 22),
          "end_time": DateTime.utc(1969, 7, 20, 23),
          "color": "Color(0xff2471ff)",
          "notes": "Test Notes 2",
          "subject": "Test Subject 2",
          "group": "Test Group 2",
        });

    await instance
        .collection('appointments')
        .doc('Test Appointment')
        .get()
        .then((value) {
      expect(value.data()?['subject'], 'Test Subject 2');
      expect(value.data()?['start_time'],
          Timestamp.fromDate(DateTime.utc(1969, 7, 20, 22)));
      expect(value.data()?['end_time'],
          Timestamp.fromDate(DateTime.utc(1969, 7, 20, 23)));
      expect(value.data()?['color'], "Color(0xff2471ff)");
      expect(value.data()?['notes'], "Test Notes 2");
      expect(value.data()?['group'], 'Test Group 2');
    });
  });
  test('deleteActivity deletes activities from firebase', () async {
    FakeFirebaseFirestore instance = FakeFirebaseFirestore();
    MockFirebaseAuth auth = MockFirebaseAuth(signedIn: true);

    AppState appState = await initializeAppStateTests(instance, auth);

    await instance
        .collection('events')
        .count()
        .get()
        .then((value) => expect(value.count, 1));

    expect(appState.activities.length, 1);

    await appState.deleteActivity(appState.activities[0]);

    await instance
        .collection('events')
        .count()
        .get()
        .then((value) => expect(value.count, 0));

    expect(appState.activities.length, 0);
  });
  test('nameInActivities identifies if an activity exists', () async {
    FakeFirebaseFirestore instance = FakeFirebaseFirestore();
    MockFirebaseAuth auth = MockFirebaseAuth(signedIn: true);

    AppState appState = await initializeAppStateTests(instance, auth);

    expect(appState.nameInActivities("Test Subject"), true);

    expect(appState.nameInActivities('Test Subject 2'), false);
  });
  test('filterGroupsByAge filters out all groups younger than the given age',
      () async {
    FakeFirebaseFirestore instance = FakeFirebaseFirestore();
    MockFirebaseAuth auth = MockFirebaseAuth(signedIn: true);

    AppState appState = await initializeAppStateTests(instance, auth);

    await instance
        .collection('groups')
        .doc('Test Group 2')
        .set({"age": 50, "color": "Color(0xff000000)", "name": "Test Group"});

    await instance
        .collection('groups')
        .doc('Test Group 3')
        .set({"age": 25, "color": "Color(0xff000000)", "name": "Test Group"});

    expect(appState.filterGroupsByAge(75, appState.groups).length, 1);

    expect(appState.filterGroupsByAge(30, appState.groups).length, 2);
  });
  test('filterGroupsByTime filters out all groups currently in an appointment',
      () async {
    FakeFirebaseFirestore instance = FakeFirebaseFirestore();
    MockFirebaseAuth auth = MockFirebaseAuth(signedIn: true);

    AppState appState = await initializeAppStateTests(instance, auth);

    await instance
        .collection('groups')
        .doc('Test Group 2')
        .set({"age": 50, "color": "Color(0xff000000)", "name": "Test Group 2"});

    await instance
        .collection('groups')
        .doc('Test Group 3')
        .set({"age": 25, "color": "Color(0xff000000)", "name": "Test Group 3"});

    expect(
        appState
            .filterGroupsByTime(DateTime.utc(1969, 7, 20, 20),
                DateTime.utc(1969, 7, 20, 21), appState.groups)
            .length,
        2);

    expect(
        appState
            .filterGroupsByTime(DateTime.utc(1969, 7, 20, 19),
                DateTime.utc(1969, 7, 20, 20), appState.groups)
            .length,
        3);
  });
}
