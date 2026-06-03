import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'constants.dart';
import 'services/auth_service.dart';
import 'services/theme_localization_service.dart';
import 'views/auth/login_page.dart';
import 'views/dashboard/foreman_dashboard_page.dart';
import 'views/dashboard/worker_dashboard_page.dart';
import 'views/profile/worker_list_page.dart';
import 'views/settings/about_page.dart';
import 'views/job/job_details_page.dart';
import 'views/map/define_route_page.dart';
import 'views/map/snowracer_live_page.dart';
import 'views/map/pick_location_page.dart';
import 'views/map/full_route_map_page.dart';
import 'views/job/image_editor_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using inline configuration matching google-services.json
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: Constants.firebaseWebApiKey,
      appId: '1:869827384340:android:1f406a649a6ad0bd3c0301',
      messagingSenderId: '869827384340',
      projectId: 'jobitapp-37146',
      databaseURL: Constants.firebaseDatabaseUrl,
      storageBucket: Constants.firebaseStorageBucket,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeAndLocalizationProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeAndLocalizationProvider>(context);

    // If settings are not loaded yet, show a loading placeholder
    if (!themeProvider.isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'JobIt',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/foreman': (context) => const ForemanDashboardPage(),
        '/worker': (context) => const WorkerDashboardPage(),
        '/workforce': (context) => const WorkerListPage(),
        '/about': (context) => const AboutPage(),
        '/job_details': (context) => JobDetailsPage(jobId: ModalRoute.of(context)!.settings.arguments as String),
        '/define_route': (context) => const DefineRoutePage(),
        '/snowracer_live': (context) => SnowracerLivePage(jobId: ModalRoute.of(context)!.settings.arguments as String),
        '/pick_location': (context) => const PickLocationPage(),
        '/full_route_map': (context) => FullRouteMapPage(jobId: ModalRoute.of(context)!.settings.arguments as String),
        '/image_editor': (context) => const ImageEditorPage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Show splash spinner while checking auth session state
    if (authService.isLoading && authService.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 64, color: Colors.blue),
              SizedBox(height: 16),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    // Determine target page based on login state and role
    if (authService.isLoggedIn) {
      if (authService.isForeman) {
        return const ForemanDashboardPage();
      } else {
        return const WorkerDashboardPage();
      }
    } else {
      return const LoginPage();
    }
  }
}
