import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/booking_bloc.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _scanned = false;
  bool _isHandlingScan = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _controller.stop();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is QRVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR verified. Charging session is ready.'),
            ),
          );
          context.go('/charging');
          return;
        }
        if (state is BookingError) {
          if (!mounted) return;
          setState(() {
            _scanned = false;
            _isHandlingScan = false;
          });
          _controller.start();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'Scan QR Code',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: ValueListenableBuilder(
                valueListenable: _controller,
                builder: (context, state, child) {
                  return Icon(
                    state.torchState == TorchState.on
                        ? Icons.flash_on
                        : Icons.flash_off,
                    color: state.torchState == TorchState.on
                        ? AppColors.primary
                        : Colors.white,
                  );
                },
              ),
              onPressed: () => _controller.toggleTorch(),
            ),
            IconButton(
              icon: const Icon(Icons.cameraswitch, color: Colors.white),
              onPressed: () => _controller.switchCamera(),
            ),
          ],
        ),
        body: Stack(
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                if (_scanned || _isHandlingScan) return;
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _controller.stop();
                    if (!mounted) return;
                    setState(() {
                      _scanned = true;
                      _isHandlingScan = true;
                    });
                    _handleQrResult(barcode.rawValue!);
                    break;
                  }
                }
              },
            ),

            Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _scanned ? AppColors.success : AppColors.primary,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),

            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Icon(
                    _scanned ? Icons.check_circle : Icons.qr_code_scanner,
                    color: _scanned ? AppColors.success : AppColors.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _scanned
                        ? 'QR Code Detected!'
                        : 'Align the QR code within the frame',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _scanned
                        ? 'Verifying your booking...'
                        : 'Scan the QR code at the charging station',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleQrResult(String qrToken) async {
    final token = qrToken.trim();
    if (token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _scanned = false;
        _isHandlingScan = false;
      });
      _controller.start();
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _scanned = false;
        _isHandlingScan = false;
      });
      _controller.start();
      return;
    }

    final chargers = await _firestore
        .collection('chargers')
        .where('qr_code_token', isEqualTo: token)
        .limit(1)
        .get();
    if (chargers.docs.isEmpty) {
      if (!mounted) return;
      setState(() {
        _scanned = false;
        _isHandlingScan = false;
      });
      _controller.start();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR token not recognized.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final listingId = chargers.docs.first.id;
    final bookings = await _firestore
        .collection('bookings')
        .where('user_id', isEqualTo: user.uid)
        .where('listing_id', isEqualTo: listingId)
        .where('status', whereIn: ['PENDING', 'CONFIRMED'])
        .get();

    if (bookings.docs.isEmpty) {
      if (!mounted) return;
      setState(() {
        _scanned = false;
        _isHandlingScan = false;
      });
      _controller.start();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No matching booking found for this QR code.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!mounted) return;
    final sorted = bookings.docs.toList()
      ..sort((a, b) {
        final aTime =
            (a.data()['created_at'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            (b.data()['created_at'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
    context.read<BookingBloc>().add(
      VerifyQR(bookingId: sorted.first.id, qrToken: token),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }
}
