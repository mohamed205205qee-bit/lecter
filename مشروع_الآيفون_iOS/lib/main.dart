import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/schedule_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScheduleProvider()..init(),
      child: Consumer<ScheduleProvider>(
        builder: (context, provider, child) {
          final textTheme = GoogleFonts.cairoTextTheme();

          return MaterialApp(
            title: 'منظم المحاضرات والسكاشن',
            debugShowCheckedModeBanner: false,
            locale: const Locale('ar', 'EG'),
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ar', 'EG'),
              Locale('en', 'US'),
            ],
            themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF00796B), // Medical Teal
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF7F9FA),
              textTheme: textTheme,
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
                backgroundColor: Color(0xFFF7F9FA),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF004D40),
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF121212),
              textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
                backgroundColor: Color(0xFF121212),
              ),
            ),
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: HomeScreen(),
            ),
          );
        },
      ),
    );
  }
}
