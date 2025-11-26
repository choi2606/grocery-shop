import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:grocery_admin_panel/firebase_options.dart';
import 'package:grocery_admin_panel/inner_screens/add_prod.dart';
import 'package:grocery_admin_panel/screens/main_screen.dart';
import 'package:grocery_admin_panel/services/auth_service.dart';
import 'package:provider/provider.dart';

import 'consts/theme_data.dart';
import 'controllers/MenuControllerr.dart';
import 'providers/dark_theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✓ Firebase initialized successfully');
  } catch (e) {
    print('✗ Firebase initialization error: $e');
  }

  // Đăng nhập anonymous trong background, không block app startup
  // Nếu có lỗi IndexedDB, sẽ không ảnh hưởng đến việc upload sản phẩm
  AuthService.signInAnonymously().catchError((error) {
    print('⚠ Authentication failed (không ảnh hưởng đến app): $error');
    return null;
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  DarkThemeProvider themeChangeProvider = DarkThemeProvider();

  void getCurrentAppTheme() async {
    themeChangeProvider.setDarkTheme =
        await themeChangeProvider.darkThemePreference.getTheme();
  }

  @override
  void initState() {
    getCurrentAppTheme();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MenuControllerr(),
        ),
        ChangeNotifierProvider(
          create: (_) {
            return themeChangeProvider;
          },
        ),
      ],
      child: Consumer<DarkThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Grocery',
            theme: Styles.themeData(themeProvider.getDarkTheme, context),
            home: const MainScreen(),
            routes: {
              UploadProductForm.routeName: (context) =>
                  const UploadProductForm(),
            },
          );
        },
      ),
    );
  }
}
