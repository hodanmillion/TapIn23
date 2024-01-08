import 'dart:developer';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myapp/firebase_options.dart';
import 'package:myapp/pages/auto_generated_chat_page.dart';
import 'package:myapp/pages/chatPage.dart';
import 'package:myapp/pages/image_view_page.dart';

import 'package:myapp/pages/past_chat_view.dart';
import 'package:myapp/pages/past_chats_page.dart';
import 'package:myapp/pages/publicChatProfile.dart';
import 'package:myapp/pages/userPrivateProfilePage.dart';
import 'package:myapp/pages/userProfilePage.dart';
import 'package:myapp/services/auth/auth_service.dart';
import 'package:myapp/services/auth_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/services/notification/notification.dart';
import 'package:myapp/services/notification/notification2.dart';
import 'package:myapp/viewBindings/ChatViewBinding.dart';
import 'package:myapp/viewBindings/PastChatViewBinding.dart';
import 'package:myapp/viewBindings/PublicChatViewBinding.dart';
import 'package:provider/provider.dart';
import '../dependancyinjection/injection_container.dart' as di;
import 'pages/contacts_page.dart';
import 'routes/app_route.dart';
import 'viewBindings/ContactsViewBinding.dart';

@pragma("vm:entry-point")
Future<void> _firebaseMessagingBackgroundHandler(message) async {
  await Firebase.initializeApp();
  log("Handling a background message $message");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await di.init();
 /* FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };*/
/*  AppNotification().getNotification();
  AppNotification().configLocalNotification();*/
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    ChangeNotifierProvider(
        create: (context) => AuthService(), child: const MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
/*    AppNotification().getNotification();
    AppNotification().configLocalNotification();*/
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        WidgetsBinding.instance.focusManager.primaryFocus!.unfocus();
/*        FocusScopeNode currentFocus = FocusScope.of(context);

        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }*/
      },
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,

        home: AuthG(),
        // initialRoute: PageConst.authG,
        // onGenerateRoute: (settings) => OnGenerateRoute.route(settings),
        defaultTransition: Transition.cupertino,
        getPages: [
          GetPage(
            name: PageConst.authG,
            page: () => AuthG(),
          ),
          GetPage(
              name: PageConst.pastChatListPage,
              page: () => PastChatListPage(),
              binding: PublicChatViewBinding()),
          GetPage(
              name: PageConst.pastChatView,
              page: () => PastChatView(),
              binding: PastChatViewBinding()),
          GetPage(
              name: PageConst.autoGeneratedChatPage,
              page: () => AutoGeneratedChatPage(),
              binding: PublicChatViewBinding()),
          GetPage(
              name: PageConst.contactsView,
              page: () => ContactsPage(),
              binding: ContactsViewBinding()),
          GetPage(
              name: PageConst.chatView,
              page: () => ChatPage(),
              binding: ChatViewBinding()),
          GetPage(
            name: PageConst.userProfilePage,
            page: () => UserProfilePage(),
          ),
          GetPage(
            name: PageConst.userPrivateProfilePage,
            page: () => UserPrivateProfilePage(),
          ),
          GetPage(
            name: PageConst.publicChatProfilePage,
            page: () => PublicChatProfilePage(),
          ),
          GetPage(
            name: PageConst.imageView,
            page: () => ImageViewPage(),
          ),
        ],
      ),
    );
  }
}
