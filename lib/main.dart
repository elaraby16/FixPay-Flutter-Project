import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'screens/account_screen.dart';
import 'screens/color_screen.dart';
import 'screens/create_account_screen.dart';
import 'screens/earnings_screen.dart';
import 'screens/forgot_password.dart';
import 'screens/home_screen.dart';
import 'screens/jobs_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_aej_screen.dart';
import 'screens/personal_page.dart';
import 'screens/send_code_screen.dart';
import 'screens/user_provider.dart';
import 'screens/verefication2_screen.dart';
import 'screens/welcome_screen_modified.dart';
import 'screens/worker_map_test_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  final role = prefs.getString('user_role');
  final verifyStatus = prefs.getString('user_verify_status');
  
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
      child: MyApp(startToken: token, startRole: role, verifyStatus: verifyStatus),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? startToken;
  final String? startRole;
  final String? verifyStatus;
  const MyApp({super.key, this.startToken, this.startRole, this.verifyStatus});

  @override
  Widget build(BuildContext context) {
    // Initialize provider data if token exists
    if (startToken != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final up = Provider.of<UserProvider>(context, listen: false);
        up.setAuth(startToken!, ""); // userId will be re-fetched or loaded
      });
    }

    Widget initialScreen = const LoginScreen();
    if (startToken != null) {
      if (startRole == 'worker') {
        initialScreen = const MainScreen(selectedSkills: []);
      } else {
        initialScreen = const HomeScreen();
      }
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // initialRoute: '/home',
      // routes: {
      //   '/home':(context)=>const HomeScreen()

      // },
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Container();
        };
        return child!;
      },
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          iconTheme: IconThemeData(color: AppColors.backgroundWhite),
          toolbarHeight: 80.0,
          titleTextStyle: TextStyle(
            color: AppColors.secondaryLightBeige,
            fontSize: 33,
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: AppColors.primaryDarkGreen,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            //padding: const EdgeInsets.symmetric(vertical: 12,horizontal:15 ),
            backgroundColor: AppColors.primaryDarkGreen,
            foregroundColor: AppColors.secondaryLightBeige,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style:
              TextButton.styleFrom(
                foregroundColor: AppColors.primaryDarkGreen,
              ).copyWith(
                overlayColor: MaterialStateProperty.resolveWith<Color?>((
                  Set<MaterialState> states,
                ) {
                  if (states.contains(MaterialState.pressed)) {
                    return AppColors.primaryDarkGreen.withOpacity(0.2);
                  }
                  return null;
                }),
              ),
        ),

        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColors.primaryDarkGreen,
          selectionHandleColor: AppColors.primaryDarkGreen,
          selectionColor: AppColors.primaryDarkGreen.withOpacity(0.3),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white70,
          labelStyle: const TextStyle(color: AppColors.primaryDarkGreen),
          hintStyle: TextStyle(color: AppColors.primaryDarkGreen),
          prefixIconColor:
              AppColors.primaryDarkGreen, // AppColors.primaryDarkGreen,
          suffixIconColor: AppColors.textgrey,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white70.withOpacity(0.1)),
            // width: 1.0,)
            // (
            // color: Colors.white70,
            // width: 2.0,
            // ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: AppColors.primaryDarkGreen.withOpacity(0.2),
              width: 1.0,
            ),
          ),
        ),
      ),
      // home: const WelcomeScreenModified(),
      // home: const MainScreen(selectedSkills: []),
      // TODO: REVERT THIS LATER
      home: const WorkerMapTestScreen(),
    );
  }
}
