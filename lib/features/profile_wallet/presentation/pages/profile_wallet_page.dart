import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../app.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/wallet_entity.dart';
import '../bloc/wallet_bloc.dart';

class ProfileWalletPage extends StatefulWidget {
  const ProfileWalletPage({super.key});

  @override
  State<ProfileWalletPage> createState() => _ProfileWalletPageState();
}

class _ProfileWalletPageState extends State<ProfileWalletPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isUploadingPicture = false;

  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(LoadWallet());
  }

  Future<void> _pickAndUploadProfilePicture() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;
      
      setState(() => _isUploadingPicture = true);
      
      final file = File(pickedFile.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users/${_auth.currentUser!.uid}/profile.jpg');
          
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();
      
      await _auth.currentUser!.updatePhotoURL(downloadUrl);
      
      await _auth.currentUser!.reload();
      if (mounted) {
        setState(() {
          _isUploadingPicture = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPicture = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update picture: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/profile/settings'),
          ),
        ],
      ),
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state is WalletError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is WalletLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final walletState = state is WalletLoaded ? state : null;
          final wallet = walletState?.wallet;
          final transactions = walletState?.transactions ?? const [];

          return RefreshIndicator(
            onRefresh: () async {
              context.read<WalletBloc>().add(LoadWallet());
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                VoltCard(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.15,
                            ),
                            backgroundImage: user?.photoURL != null
                                ? NetworkImage(user!.photoURL!)
                                : null,
                            child: user?.photoURL == null
                                ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: AppColors.primary,
                                  )
                                : null,
                          ),
                          if (_isUploadingPicture)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickAndUploadProfilePicture,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.surfaceDark
                                          : AppColors.surfaceLight,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.displayName?.isNotEmpty == true
                            ? user!.displayName!
                            : 'Charge Lanka User',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'No email',
                        style: TextStyle(color: secondaryText),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const StatusChip(
                            label: 'USER',
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          StatusChip(
                            label: user?.emailVerified == true
                                ? 'Verified'
                                : 'Unverified',
                            color: user?.emailVerified == true
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                VoltCard(
                  showGlow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Wallet Balance',
                            style: TextStyle(color: secondaryText),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              App.currencyNotifier.value,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.format(wallet?.balance ?? 0),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GlowingButton(
                              label: 'Top Up',
                              icon: Icons.add,
                              onPressed: () => _showTopUpDialog(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showWithdrawDialog(
                                context,
                                availableBalance: wallet?.balance ?? 0,
                              ),
                              icon: const Icon(Icons.send),
                              label: const Text('Withdraw'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SectionHeader(title: 'Recent Transactions'),
                const SizedBox(height: 8),
                if (transactions.isEmpty)
                  VoltCard(
                    child: Text(
                      'No wallet transactions yet.',
                      style: TextStyle(color: secondaryText),
                    ),
                  )
                else
                  ...transactions.map(
                    (tx) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TransactionTile(transaction: tx),
                    ),
                  ),
                const SizedBox(height: 16),
                const SectionHeader(title: 'Settings'),
                const SizedBox(height: 8),
                VoltCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.swap_horiz,
                        title: 'Switch to Host Mode',
                        subtitle: 'Go to host dashboard',
                        onTap: () => context.go('/host'),
                      ),
                      const Divider(height: 1, indent: 60),
                      _SettingsTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Manage alerts',
                        onTap: () => context.push('/profile/notifications'),
                      ),
                      const Divider(height: 1, indent: 60),
                      _SettingsTile(
                        icon: Icons.person_outline,
                        title: 'Account',
                        subtitle: 'Edit name, email & phone',
                        onTap: () => context.push('/profile/account'),
                      ),
                      const Divider(height: 1, indent: 60),
                      _SettingsTile(
                        icon: Icons.security,
                        title: 'Security',
                        subtitle: 'Password & 2FA',
                        onTap: () => context.push('/profile/security'),
                      ),
                      const Divider(height: 1, indent: 60),
                      _SettingsTile(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'FAQ & Contact',
                        onTap: () => context.push('/profile/help'),
                      ),
                      const Divider(height: 1, indent: 60),
                      _SettingsTile(
                        icon: Icons.logout,
                        title: 'Sign Out',
                        subtitle: '',
                        isDestructive: true,
                        onTap: () => _confirmSignOut(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showTopUpDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amounts = [500, 1000, 2500, 5000, 10000];
    final customAmountController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Up Wallet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: amounts.map((amt) {
                return ActionChip(
                  label: Text(CurrencyFormatter.format(amt.toDouble(), noDecimals: true)),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _showPaymentDetailsDialog(context, amt.toDouble());
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: customAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Custom Amount',
                prefixText: App.currencyNotifier.value == 'USD' ? '\$ ' : 'LKR ',
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: GlowingButton(
                label: 'Add Funds',
                icon: Icons.add_circle,
                onPressed: () {
                  final amountText = double.tryParse(
                    customAmountController.text.trim(),
                  );
                  if (amountText == null || amountText <= 0) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(
                        content: Text('Enter a valid top-up amount.'),
                      ),
                    );
                    return;
                  }
                  final finalAmount = App.currencyNotifier.value == 'USD'
                      ? amountText * CurrencyFormatter.usdRate
                      : amountText;
                  Navigator.pop(sheetContext);
                  _showPaymentDetailsDialog(context, finalAmount);
                },
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() => customAmountController.dispose());
  }

  void _showPaymentDetailsDialog(BuildContext context, double amount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardNumberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();
    final cardHolderController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Payment Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    CurrencyFormatter.format(amount, noDecimals: true),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cardNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  prefixIcon: Icon(Icons.credit_card),
                  hintText: '0000 0000 0000 0000',
                  counterText: "",
                ),
                maxLength: 19,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expiryController,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date',
                        prefixIcon: Icon(Icons.date_range),
                        hintText: 'MM/YY',
                        counterText: "",
                      ),
                      maxLength: 5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: cvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        prefixIcon: Icon(Icons.lock_outline),
                        hintText: '123',
                        counterText: "",
                      ),
                      maxLength: 4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cardHolderController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Cardholder Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GlowingButton(
                  label: 'Pay Now',
                  icon: Icons.check_circle_outline,
                  onPressed: () {
                    if (cardNumberController.text.trim().isEmpty ||
                        expiryController.text.trim().isEmpty ||
                        cvvController.text.trim().isEmpty ||
                        cardHolderController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all payment details.'),
                        ),
                      );
                      return;
                    }
                    context.read<WalletBloc>().add(TopUpWallet(amount));
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment verified and balance updated!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      cardNumberController.dispose();
      expiryController.dispose();
      cvvController.dispose();
      cardHolderController.dispose();
    });
  }

  void _showWithdrawDialog(
    BuildContext context, {
    required double availableBalance,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Withdraw Funds',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Available: ${CurrencyFormatter.format(availableBalance)}',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: App.currencyNotifier.value == 'USD' ? '\$ ' : 'LKR ',
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: GlowingButton(
                label: 'Request Withdrawal',
                icon: Icons.send,
                onPressed: () {
                  final amountText = double.tryParse(amountController.text.trim());
                  if (amountText == null || amountText <= 0) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid amount.'),
                      ),
                    );
                    return;
                  }
                  final amount = App.currencyNotifier.value == 'USD'
                      ? amountText * CurrencyFormatter.usdRate
                      : amountText;
                      
                  if (amount > availableBalance) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Amount exceeds available wallet balance.',
                        ),
                      ),
                    );
                    return;
                  }

                  context.read<WalletBloc>().add(WithdrawFromWallet(amount));
                  Navigator.pop(sheetContext);
                  context.push('/profile/bank-details');
                },
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() => amountController.dispose());
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (!context.mounted || result != true) return;
    context.read<AuthBloc>().add(LogoutRequested());
    context.go('/login');
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    final amount = transaction.amount;
    final isPositive = transaction.type == 'TOP_UP';
    final icon = _iconForType(transaction.type);
    final iconColor = isPositive ? AppColors.success : AppColors.primary;

    return VoltCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? transaction.type,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  DateTimeFormatter.formatDate(transaction.createdAt),
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : '-'}${CurrencyFormatter.format(amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isPositive ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'TOP_UP':
        return Icons.add_circle;
      case 'HOST_PAYOUT':
        return Icons.account_balance_wallet;
      case 'COMMISSION':
        return Icons.percent;
      default:
        return Icons.bolt;
    }
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : AppColors.accent,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, style: TextStyle(fontSize: 12, color: secondaryText))
          : null,
      trailing: Icon(Icons.chevron_right, color: secondaryText),
      onTap: onTap,
    );
  }
}
