import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'config/di.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/discovery/presentation/bloc/discovery_bloc.dart';
import 'features/booking/presentation/bloc/booking_bloc.dart';
import 'features/charging_monitor/presentation/bloc/charging_bloc.dart';
import 'features/profile_wallet/presentation/bloc/wallet_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await configureDependencies();
    runApp(const ChargeLankaApp());
  } catch (e) {
    runApp(_StartupErrorApp(error: e.toString()));
  }
}

class ChargeLankaApp extends StatelessWidget {
  const ChargeLankaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthBloc>()),
        BlocProvider(create: (_) => getIt<DiscoveryBloc>()),
        BlocProvider(create: (_) => getIt<BookingBloc>()),
        BlocProvider(create: (_) => getIt<ChargingBloc>()),
        BlocProvider(create: (_) => getIt<WalletBloc>()),
      ],
      child: const App(),
    );
  }
}

class _StartupErrorApp extends StatelessWidget {
  final String error;

  const _StartupErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Startup failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
