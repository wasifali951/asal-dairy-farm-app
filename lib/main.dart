import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/pos_cart_provider.dart';
import 'services/payment_service.dart';
import 'services/sync_service.dart';
import 'services/printer_service.dart';
import 'screens/main_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/location_permission_screen.dart';
import 'screens/admin_signin_screen.dart';
import 'config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize();
  await Firebase.initializeApp();
  runApp(const AsalDairyApp());
}

class AsalDairyApp extends StatelessWidget {
  const AsalDairyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => PosCartProvider()),
        ChangeNotifierProvider(
          create: (_) => PaymentProvider(
            service: MockPaymentService(provider: PaymentGateway.jazzCash),
          )..init(),
        ),
        // POS offline sync — not a ChangeNotifier, just needs to exist app-wide
        Provider<SyncService>(
          lazy: false,
          create: (_) => SyncService()..startAutoSync(),
        ),
        // Shared printer connection — persists across POS + pairing screens
        Provider<PrinterService>(
          lazy: false,
          create: (_) => PrinterService(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Asal Dairy',
        theme: ThemeData(
          primarySwatch: Colors.green,
          useMaterial3: true,
        ),
        home: const _AppBootstrap(),
      ),
    );
  }
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _initFuture = _initializeUser(authProvider);
  }

  Future<void> _initializeUser(AuthProvider authProvider) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await authProvider.loadUserData(currentUser.uid);
      final hasWrongRole = AppConfig.isOwnerApp
          ? !authProvider.isAdmin()
          : authProvider.isAdmin();
      if (hasWrongRole) {
        await authProvider.signOut();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }

        final authProvider = Provider.of<AuthProvider>(context);
        if (authProvider.isLoggedIn) {
          if (!authProvider.isAdmin() &&
              authProvider.currentUser?.latitude == null) {
            return LocationPermissionScreen(
              onPermissionGranted: () async {
                await authProvider
                    .updateUserLocation(authProvider.currentUser!.id);
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                );
              },
              onSkip: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                );
              },
            );
          }
          return const MainScreen();
        }
        return AppConfig.isOwnerApp
            ? const AdminSignInScreen()
            : const SignInScreen();
      },
    );
  }
}
