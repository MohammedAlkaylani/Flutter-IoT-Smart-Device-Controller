import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/screens/auth/login_screen.dart';
import 'package:myapp/screens/auth/register_screen.dart';
import 'package:myapp/screens/home/home_screen.dart';
import 'package:myapp/screens/welcome/welcome_screen.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/cubit/auth_cubit.dart';
import 'package:myapp/cubit/bloc_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();
  
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = await AuthService.isLoggedIn();
  
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthCubit()..initializeUserData(),
        ),
      ],
      child: ChangeNotifierProvider(
        create: (context) => AuthService(),
        child: MyApp(initialScreen: isLoggedIn),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool initialScreen;
  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto', // Changed to more common font
      ),
      home: BlocProvider.value(
        value: BlocProvider.of<AuthCubit>(context),
        child: initialScreen ? const HomeScreen() : const WelcomeScreen(),
      ),
      routes: {
        '/home': (context) => BlocProvider.value(
          value: BlocProvider.of<AuthCubit>(context),
          child: const HomeScreen(),
        ),
        '/welcome': (context) => BlocProvider.value(
          value: BlocProvider.of<AuthCubit>(context),
          child: const WelcomeScreen(),
        ),
      },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 375;

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/welcome_background.png'), // Changed asset name
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    children: [
                      Image.asset(
                        'assets/app_logo.png', // Changed asset name
                        width: size.width * 0.5,
                        height: size.height * 0.1,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: size.height * 0.01),
                      RichText(
                        text: const TextSpan(
                          text: 'MY ', // Changed app name
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(
                              text: 'APP',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.normal,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.05),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: isSmallScreen ? 50 : 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E232C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.02),
                        SizedBox(
                          width: double.infinity,
                          height: isSmallScreen ? 50 : 56,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegisterScreen()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFF1E232C),
                                width: 2,
                              ),
                              backgroundColor: Colors.white.withOpacity(0.9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Register',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E232C),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.03),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HomeScreen()),
                            );
                          },
                          child: Text(
                            'Continue as guest',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              color: const Color(0xFFF18000),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.05),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}