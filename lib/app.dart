import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:situp/services/camera_service.dart';
import 'package:situp/viewmodel/camera_viewmodel.dart';
import 'services/auth_service.dart';
import 'viewmodel/auth_viewmodel.dart';
import 'view/login_screen.dart';
import 'view/home_screen.dart';
import 'services/mock_posture_backend.dart';
import 'services/database_service.dart';

class SitUpApp extends StatelessWidget {
  const SitUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(AuthService())),
        Provider(create: (_) => MockPostureBackend()),
        ChangeNotifierProvider(
          create: (ctx) => CameraViewModel(
            CameraService(),
            ctx.read<MockPostureBackend>(),
            DatabaseService(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SitUp',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return StreamBuilder<User?>(
      stream: authVM.userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
