import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:myapp/model/GroupModel.dart';
import 'package:myapp/usecases/edit_group_use_case.dart';

import '../model/message.dart';
import '../usecases/add_message_usecase.dart';
import '../usecases/create_chat_group_use_case.dart';
import '../usecases/get_messages_usecase.dart';

class ChatController extends GetxController {
  final Set<String> blockedUsers =
      {}; // Declare a Set to store blocked user IDs
  RxBool isLocationSet = true.obs;
RxBool isChatCreated = false.obs;

  // Method to create a chat
  void createChat() {
    // Logic to create a chat...
    isChatCreated.value = true;
  }
  // Check if a user is blocked
  bool isUserBlocked(String userId) {
    return blockedUsers.contains(userId);
  }

  // Block a user
  void blockUser(String userId) {
    blockedUsers.add(userId);
  }

  AddMessageUseCase? _addMessageUseCase;
  GetMessagesUseCase? _getMessagesUseCase;
  CreateChatGroupUseCase? _createChatGroupUseCase;
  EditGroupUseCase? _editGroupUseCase;

  ChatController({
    GetMessagesUseCase? getMessages,
    AddMessageUseCase? addMessages,
    EditGroupUseCase? editGroup,
    CreateChatGroupUseCase? createGroup,
  }) {
    _addMessageUseCase = addMessages;
    _getMessagesUseCase = getMessages;
    _createChatGroupUseCase = createGroup;
    _editGroupUseCase = editGroup;
  }

  final _messageText = TextEditingController().obs;
  final searchGifText = TextEditingController().obs;

  final _Text = TextEditingController().obs;
  String searchGifString = "";

  static const String apiKey =
      'l1WfAFgqA5WupWoMaCaWKB12G54J6LtZ'; // Replace with your GIPHY API key
  static const String endpoint =
      'https://api.giphy.com/v1/gifs/trending?api_key=$apiKey&limit=10';

  TextEditingController get messageTextCont => _messageText.value;
  FirebaseAuth? _firebaseAuth = null;

  RxBool _isBusy = false.obs;

  bool get isBusy => _isBusy.value;

  FirebaseAuth get firebaseAuth => _firebaseAuth!;

  setBusy(bool? isBusy) {
    _isBusy.value = isBusy!;
  }

  String? _getCurrentUserId = '';

  String? get currentUserId => _getCurrentUserId;
  RxString groupId = ''.obs;
  RxString streetName = ''.obs;

  String? get getgroupId => groupId.value;

  String? get getstreetName => streetName.value;

  String? _getFriendUserId = '';

  RxInt isMessageFirst = 0.obs;

  String? get friendUserId => _getFriendUserId;

  RxList<MessagePublicChat> _messagesList = RxList<MessagePublicChat>();

  List<MessagePublicChat> get messagesList => _messagesList;

  RxList<GroupModel> _groupListModel = RxList<GroupModel>();

  List<GroupModel> get groupListModel => _groupListModel;

  RxList<String> gifUrl = RxList<String>();
  RxList<String> titleGif = RxList<String>();

  RxString selectedGifUrl = ''.obs;

  RxBool isSeachActive = false.obs;

  cancelSearch() {
    isSeachActive.value = false;
    searchGifText.value.text = "";
    gifUrl.clear();
    titleGif.clear();
    fetchGifs();
  }

  searchByGifName() async {
    isSeachActive.value = true;
    print("====gifloading==");

    final response = await http.get(Uri.parse(
        'https://api.giphy.com/v1/gifs/search?api_key=$apiKey&limit=10&q=${searchGifText.value.text.toString().trim()}'));
    if (response.statusCode == 200) {
      print("====gifloading==");
      gifUrl.clear();
      titleGif.clear();
      final data = json.decode(response.body);
      gifUrl.addAll(List<String>.from(
          data['data'].map((x) => x['images']['original']['url'])));
      titleGif.addAll(List<String>.from(data['data'].map((x) => x['title'])));
    } else {
      throw Exception('Failed to load GIFs');
    }
  }

  fetchGifs() async {
    final response = await http.get(Uri.parse(endpoint));
    List<String> urls = [];
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      gifUrl.addAll(List<String>.from(
          data['data'].map((x) => x['images']['original']['url'])));

      titleGif.addAll(List<String>.from(data['data'].map((x) => x['title'])));
    } else {
      throw Exception('Failed to load GIFs');
    }
  }

  getMessagesListFromDB() {
    _messagesList.bindStream(_getMessagesUseCase!.call(groupId: groupId.value));
    print("==messagelist" + _messagesList.length.toString());
    // _messagesList.sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  void _manualCheckIn(Position position) {
    // Implement your logic for manual check-in here.
    // For example, update the user's location in the database.
    // You may also update the UI or perform any other actions.

    print('Manual check-in at ${position.latitude}, ${position.longitude}');

    // Set the location flag to true
    isLocationSet.value = true;
  }

  Future<void> addAMessageToDB({MessagePublicChat? messageVal}) async {

    try {
      print("addmessage");
      final message = MessagePublicChat(
        senderId: messageVal!.senderId,
        timestamp: messageVal.timestamp,
        message: messageVal.message,
        senderEmail: messageVal.senderEmail,
        gifUrl: messageVal.gifUrl,
        isGif: messageVal.isGif,
      );
      await _addMessageUseCase!.call(message: message, groupId: groupId.value);
      // _messagesList.reversed;
      String formattedDate =
          DateFormat('yyyy-MM-dd').format(messageVal.timestamp);

      if (isMessageFirst.value == 0) {
        print("====groups added");
        FirebaseFirestore.instance
            .collection("users")
            .doc(messageVal.senderId.toString())
            .collection("groups")
            .doc(groupId.value)
            .set({
          "status": 1,
          "groupId": groupId.value,
          "groupName": streetName.value,
          "time": messageVal.timestamp,
          "gifUrl": messageVal.gifUrl,
          "isGif": messageVal.isGif,
        });
      }
      selectedGifUrl.value = '';
      isMessageFirst.value++;
      _messageText.value.clear();
      searchGifText.value.text = "";
    } catch (e) {}
  }

  Stream<List<DocumentSnapshot>> nearestGroup(double lat, double lang,
      GeoFlutterFire geo, CollectionReference groupCollection) {
    GeoFirePoint location = geo.point(latitude: lat, longitude: lang);
    return geo.collection(collectionRef: groupCollection).within(
        center: location, radius: 0.2, field: 'position', strictMode: true);
  }

  createOrAddInGroup(double lat, double lang, Location location,
      GeoFlutterFire geo, CollectionReference groupCollection) {
    print("createoradd in ===");

    Stream<List<DocumentSnapshot>> streamListen =
        nearestGroup(lat, lang, geo, groupCollection);

    streamListen.first.then((value) {
      if (value.length > 0) {
        print("IDD==" + value[0]['groupId']);
        groupId.value = value[0]['groupId'];
        print("==groupid edit=" + groupId.value);
        _editGroupUseCase?.call(lat: lat, lang: lang, groupId: groupId.value);
        getMessagesListFromDB();
        getPastGroupBinding();
      } else {
        print("==create groupt=");
        groupId.value = "$lat-$lang";

        _createChatGroupUseCase?.call(
          lat: lat,
          lang: lang,
          location: location,
          groupName: streetName.value,
        );

        getMessagesListFromDB();
        getPastGroupBinding();
      }
    });

    return groupId.value;
  }

  getFriendsId() async {
    _getFriendUserId = Get.arguments as String?;
  }

  Future<void> getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final Position position = await Geolocator.getCurrentPosition();
        Location location = Location();

        final double latitude = position.latitude;
        final double longitude = position.longitude;
        final CollectionReference groupCollection =
            FirebaseFirestore.instance.collection("public_chats");
        final geo = GeoFlutterFire();

        List<Placemark> placemarks =
            await placemarkFromCoordinates(latitude, longitude);
        streetName.value = placemarks[0].street!.isEmpty ? "${placemarks[0].locality!},${placemarks[0].subLocality!}" : placemarks[0].street! ;
        print("===street===" + streetName.value);
        createOrAddInGroup(
          latitude,
          longitude,
          location,
          geo,
          groupCollection,
        );

        location.onLocationChanged.listen((LocationData updatedLocation) {
          Stream<List<DocumentSnapshot>> streamListen = nearestGroup(
            updatedLocation.latitude!,
            updatedLocation.longitude!,
            geo,
            groupCollection,
          );

          streamListen.first.then((value) {
            isMessageFirst.value = 0;
            if (value.isNotEmpty) {
              if (groupId.value.compareTo(value[0]['groupId']) != 0) {
                groupId.value = value[0]['groupId'];
                print("==groupid edit=" + groupId.value);
                _messagesList.clear();
                _editGroupUseCase?.call(
                  lat: updatedLocation.latitude!,
                  lang: updatedLocation.longitude!,
                  groupId: groupId.value,
                );
                getMessagesListFromDB();
              }
            } else {
              groupId.value = "${updatedLocation.latitude}-${updatedLocation.longitude}";

              _createChatGroupUseCase?.call(
                lat: updatedLocation.latitude!,
                lang: updatedLocation.longitude!,
                location: location,
                groupName: streetName.value,
              );

              getMessagesListFromDB();
              _messagesList.clear();
            }
          });
        });
      } else {
        print('Location permission denied');
      }
    } catch (e) {
      print('Error retrieving user location: $e');
    }
  }

  Stream<List<GroupModel>> getPastGroups() {
    var groupsData;
    try {
      final CollectionReference groupCollection =
          FirebaseFirestore.instance.collection("users");
      print("UID====${_firebaseAuth!.currentUser!.uid}-${groupId.value}");

      var groupsDelere = groupCollection
          .doc(_firebaseAuth!.currentUser!.uid.toString())
          .collection("groups")
          .where("time",
              isLessThanOrEqualTo:
                  DateTime.now().subtract(const Duration(days: 2)))
          .get()
          .then((value) {
        value.docs.forEach((element) {
          groupCollection
              .doc(_firebaseAuth!.currentUser!.uid.toString())
              .collection("groups")
              .doc(element.id)
              .delete()
              .then((value) {
            print("===groups deleted!" + element.id.toString());
          });
        });
      });

      var groups = groupCollection
          .doc(_firebaseAuth!.currentUser!.uid.toString())
          .collection("groups")
          .where("groupId", isNotEqualTo: groupId.value);

      groupsData = groups.snapshots().map((querySnap) {
        return querySnap.docs
            .map((docSnap) => GroupModel.fromJson(docSnap))
            .toList();
      });
    } catch (e) {
      e.printError();
    }
    return groupsData;
  }

  getPastGroupBinding() {
    _groupListModel.bindStream(getPastGroups());
  }

  @override
  void onInit() async {
    _firebaseAuth = FirebaseAuth.instance;
    getUserLocation();
    fetchGifs();
    //  getMessagesListFromDB();

    super.onInit();
  }
}