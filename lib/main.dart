import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Public / Exhibitor
import 'exhibition_homepage.dart';
import 'exhibitions.dart';
import 'browse_exhibitions.dart';
import 'exhibition_details.dart';
import 'exhibitor_login.dart';
import 'exhibitor_register.dart';
import 'exhibitor_profile.dart';
import 'application_status.dart';

// Admin / Organizer
import 'admin_exhibition_login.dart';
import 'admin_exhibition_dashboard.dart';
import 'admin_applications.dart';
import 'organizer_dashboard.dart';
import 'add_exhibition.dart';
import 'all_exhibitions.dart';

// Booth / Application
import 'booth_selection.dart';
import 'application_form.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final role = prefs.getString('current_user_role') ?? 'guest';

  runApp(ExpoManagerApp(role: role));
}

class ExpoManagerApp extends StatelessWidget {
  final String role;
  const ExpoManagerApp({super.key, required this.role});

  /// 🏠 HOME BY ROLE
  Widget _homeByRole() {
    switch (role) {
      case 'admin':
        return const AdminExhibitionDashboard();
      case 'organizer':
        return const OrganizerDashboard();
      default:
        return const ExhibitionHomePage();
    }
  }

  /// 🔐 ROUTE GUARD (SYNC + SAFE)
  bool _allowRoute(String route) {
    // Auth pages always allowed
    if (route == '/login' || route == '/register' || route == '/adminlogin') {
      return true;
    }

    // Guest restrictions
    if (role == 'guest') {
      if (route == '/profile' ||
          route == '/applicationform' ||
          route == '/applicationstatus') {
        return false;
      }
    }

    // Admin-only
    if (route.startsWith('/admindashboard') ||
        route.startsWith('/adminapplications')) {
      return role == 'admin';
    }

    // Organizer-only
    if (route.startsWith('/organizerdashboard')) {
      return role == 'organizer';
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expo Manager',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
      ),

      home: _homeByRole(),

      // STATIC ROUTES
      routes: {
        '/home': (_) => const ExhibitionHomePage(),
        '/exhibitions': (_) => const ExhibitionsPage(),
        '/browse': (_) => const BrowseExhibitionsPage(),
        '/login': (_) => const ExhibitorLoginPage(),
        '/register': (_) => const ExhibitorRegisterPage(),
        '/profile': (_) => const ExhibitorProfilePage(),

        // Admin / Organizer
        '/adminlogin': (_) => const AdminExhibitionLoginPage(),
        '/admindashboard': (_) => const AdminExhibitionDashboard(),
        '/adminapplications': (_) => const AdminApplicationsPage(),
        '/organizerdashboard': (_) => const OrganizerDashboard(),

        // Common
        '/addexhibition': (_) => const AddExhibitionPage(),
        '/allexhibitions': (_) => const AllExhibitionsPage(),
      },

      // ROUTES WITH ARGUMENTS (SYNC ONLY)
      onGenerateRoute: (settings) {
        final route = settings.name ?? '';

        if (!_allowRoute(route)) {
          return MaterialPageRoute(
            builder: (_) => const ExhibitionHomePage(),
          );
        }

        final args = settings.arguments as Map<String, dynamic>? ?? {};

        switch (route) {
          case '/exhibitiondetails':
            return MaterialPageRoute(
              builder: (_) => ExhibitionDetailsPage(
                exhibitionId: args['exhibitionId'] ?? '',
                exhibitionName: args['exhibitionName'] ?? '',
                description: args['description'] ?? '',
                startDate: args['start_date'] ?? '',
                endDate: args['end_date'] ?? '',
                venue: args['venue'] ?? '',
              ),
            );

          case '/floorplan':
            return MaterialPageRoute(
              builder: (_) => BoothSelectionPage(
                exhibitionId: args['exhibitionId'],
                exhibitionName: args['exhibitionName'],
                venue: args['venue'],
              ),
            );

          case '/applicationform':
            return MaterialPageRoute(
              builder: (_) => ApplicationFormPage(
                exhibitionId: args['exhibitionId'],
                exhibitionName: args['exhibitionName'],
                venue: args['venue'],
                boothCode: args['boothCode'],
                boothPrice: args['boothPrice'] ?? 0,
              ),
            );

          case '/applicationstatus':
            return MaterialPageRoute(
              builder: (_) => ApplicationStatusPage(application: args),
            );

          default:
            return null;
        }
      },
    );
  }
}
