import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/nearby_service.dart';
import 'providers/theme_provider.dart';
import 'views/login.dart';
import 'views/home_screen.dart';           
import 'components/nav_bar.dart';          

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(const GeoTalkApp());
}

class GeoTalkApp extends StatelessWidget {
  const GeoTalkApp({super.key});

  Future<Widget> _determineInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();

    final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    if (!onboardingCompleted) {

      return const HomeScreen();
    }
    final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (isLoggedIn) {
      final savedName = prefs.getString('userDisplayName') ?? 'Usuário';
      return const BottomNavBar();
    } else {
  
      return const Login();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NearbyService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'GeoTalk',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF004E89),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF004E89),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: themeProvider.themeMode,
            home: FutureBuilder<Widget>(
              future: _determineInitialScreen(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return snapshot.data!;
                }

            
                return const Scaffold(
                  backgroundColor: Color(0xFF004E89),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_tethering, size: 80, color: Colors.white),
                        SizedBox(height: 32),
                        Text(
                          'GeoTalk',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 24),
                        CircularProgressIndicator(color: Colors.white),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}