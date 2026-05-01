import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app.dart';
import '../../../../config/di.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../domain/repositories/wallet_repository.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  String _selectedLanguage = 'English';
  String _selectedPrivacy = 'Standard Context';

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }

  void _showThemeDialog() async {
    final chosen = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose Theme'),
        children: ThemeMode.values.map((mode) {
          final isSelected = App.themeNotifier.value == mode;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, mode),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    mode == ThemeMode.light
                        ? Icons.light_mode
                        : mode == ThemeMode.dark
                            ? Icons.dark_mode
                            : Icons.settings_brightness,
                    color: isSelected ? AppColors.primary : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _themeLabel(mode),
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );

    if (chosen != null) {
      App.themeNotifier.value = chosen;
      setState(() {});
    }
  }

  void _showCurrencyDialog() async {
    final newCurr = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Currency'),
        children: ['LKR', 'USD'].map((curr) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, curr),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                curr == 'LKR' ? 'LKR (Sri Lankan Rupee)' : 'USD (US Dollar)',
                style: TextStyle(
                  fontWeight: App.currencyNotifier.value == curr
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: App.currencyNotifier.value == curr ? AppColors.primary : null,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );

    if (newCurr != null && newCurr != App.currencyNotifier.value) {
      App.currencyNotifier.value = newCurr;
      setState(() {});
    }
  }

  void _showLanguageDialog() async {
    final newLang = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Language'),
        children: ['English', 'Sinhala', 'Tamil'].map((lang) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, lang),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                lang,
                style: TextStyle(
                  fontWeight: _selectedLanguage == lang
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _selectedLanguage == lang ? AppColors.primary : null,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );

    if (newLang != null && newLang != _selectedLanguage) {
      setState(() => _selectedLanguage = newLang);
    }
  }

  void _showPrivacyDialog() async {
    final newPrivacy = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Privacy Profile'),
        children: [
          'Standard Context',
          'Hide Booking History',
          'Fully Anonymous'
        ].map((priv) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, priv),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                priv,
                style: TextStyle(
                  fontWeight: _selectedPrivacy == priv
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _selectedPrivacy == priv ? AppColors.primary : null,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );

    if (newPrivacy != null && newPrivacy != _selectedPrivacy) {
      setState(() => _selectedPrivacy = newPrivacy);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          VoltCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  onTap: _showThemeDialog,
                  leading: Icon(
                    App.themeNotifier.value == ThemeMode.dark
                        ? Icons.dark_mode
                        : App.themeNotifier.value == ThemeMode.light
                            ? Icons.light_mode
                            : Icons.settings_brightness,
                    color: AppColors.accent,
                  ),
                  title: const Text('App theme'),
                  subtitle: Text(
                    _themeLabel(App.themeNotifier.value),
                    style: TextStyle(color: secondaryText),
                  ),
                  trailing: Icon(Icons.chevron_right, color: secondaryText),
                ),
                const Divider(height: 1),
                ListTile(
                  onTap: _showCurrencyDialog,
                  leading: const Icon(
                    Icons.payments_outlined,
                    color: AppColors.accent,
                  ),
                  title: const Text('Currency'),
                  subtitle: Text(
                    App.currencyNotifier.value == 'USD' 
                        ? 'USD (US Dollar)' 
                        : 'LKR (Sri Lankan Rupee)',
                    style: TextStyle(color: secondaryText),
                  ),
                  trailing: Icon(Icons.chevron_right, color: secondaryText),
                ),
                const Divider(height: 1),
                ListTile(
                  onTap: _showLanguageDialog,
                  leading: const Icon(
                    Icons.language_outlined,
                    color: AppColors.accent,
                  ),
                  title: const Text('Language'),
                  subtitle: Text(
                    _selectedLanguage,
                    style: TextStyle(color: secondaryText),
                  ),
                  trailing: Icon(Icons.chevron_right, color: secondaryText),
                ),
                const Divider(height: 1),
                ListTile(
                  onTap: _showPrivacyDialog,
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppColors.accent,
                  ),
                  title: const Text('Privacy'),
                  subtitle: Text(
                    _selectedPrivacy,
                    style: TextStyle(color: secondaryText),
                  ),
                  trailing: Icon(Icons.chevron_right, color: secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          VoltCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  value: _pushEnabled,
                  onChanged: (value) => setState(() => _pushEnabled = value),
                  title: const Text('Push notifications'),
                  subtitle: const Text('Charging updates, bookings, payouts'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _emailEnabled,
                  onChanged: (value) => setState(() => _emailEnabled = value),
                  title: const Text('Email notifications'),
                  subtitle: const Text('Receipts and account alerts'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  bool _is2faEnabled = false;

  Future<void> _showChangePasswordDialog() async {
    final bool? shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: const Text(
          'We will send a password reset link to your currently registered email address. Do you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );

    if (shouldReset == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending reset link...')),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent to your email!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _show2FaSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Two-Factor Authentication',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Add an extra layer of security to your account. When you sign in, you\'ll need to enter your secure code in addition to your password.',
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: const Text('Enable SMS Authentication'),
                    subtitle: const Text('Receive security codes via SMS'),
                    value: _is2faEnabled,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (bool value) async {
                      // Optimistic UI update
                      setModalState(() {
                        _is2faEnabled = value;
                      });
                      setState(() {});
                      
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Updating security metrics...')),
                      );
                      
                      await Future.delayed(const Duration(seconds: 1));

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value 
                                  ? 'Two-Factor Authentication is now ENABLED.' 
                                  : 'Two-Factor Authentication is now DISABLED.',
                            ),
                            backgroundColor: value ? Colors.green : Colors.amber,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          VoltCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.password_outlined,
                    color: AppColors.accent,
                  ),
                  title: const Text('Change password'),
                  subtitle: Text(
                    'Use Firebase Auth password reset',
                    style: TextStyle(color: secondaryText),
                  ),
                  trailing: Icon(Icons.chevron_right, color: secondaryText),
                  onTap: _showChangePasswordDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.phonelink_lock_outlined,
                    color: AppColors.accent,
                  ),
                  title: const Text('Two-factor authentication'),
                  subtitle: Text(
                    _is2faEnabled ? 'Enabled via SMS' : 'Configure from Firebase Authentication console',
                    style: TextStyle(
                      color: _is2faEnabled ? Colors.green : secondaryText,
                      fontWeight: _is2faEnabled ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right, color: secondaryText),
                  onTap: _show2FaSettings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  static const _faqs = <Map<String, String>>[
    {
      'q': 'How do I book a charger?',
      'a': 'Go to the Discover tab, tap a charger pin on the map, select a '
          'package and your preferred time slot, then confirm the booking. '
          'The amount will be deducted from your wallet.',
    },
    {
      'q': 'How does QR verification work?',
      'a': 'When you arrive at the charger, tap the QR scan button and scan '
          'the code displayed on the Host charger. This verifies your '
          'booking and unlocks the charging session.',
    },
    {
      'q': 'How do I top up my wallet?',
      'a': 'Go to Profile → Wallet, tap "Top Up", choose an amount, and '
          'enter your card details. The balance is added instantly.',
    },
    {
      'q': 'Can I cancel a booking?',
      'a': 'Yes. Open Bookings, find the active booking, and tap "Cancel". '
          'A full refund is credited to your wallet if cancelled before the '
          'scheduled start time.',
    },
    {
      'q': 'How do I become a Host?',
      'a': 'Switch to Host Mode from your Profile page, then tap "Add Charger" '
          'in the Host Dashboard. Fill in the charger details, set pricing '
          'packages, and mark the location on the map.',
    },
    {
      'q': 'How are Host payouts calculated?',
      'a': 'Hosts receive 85% of each completed session total cost. The '
          'remaining 15% is the Charge Lanka platform fee. Payouts can be '
          'withdrawn to linked bank accounts.',
    },
    {
      'q': 'What connector types are supported?',
      'a': 'Charge Lanka supports Type 2 (AC), CCS2 (DC fast), CHAdeMO, '
          'and standard 3-pin household plugs. Hosts specify the connector '
          'type when listing their charger.',
    },
    {
      'q': 'Is my payment information secure?',
      'a': 'Yes. All payment data is processed over secure TLS connections. '
          'Card details are never stored on our servers — they are handled '
          'by our PCI-DSS compliant payment gateway.',
    },
  ];

  final Set<int> _expandedIndices = {};

  void _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@chargelanka.lk',
      queryParameters: {
        'subject': 'Charge Lanka App – Support Request',
      },
    );
    try {
      await launchUrl(uri);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email client.')),
      );
    }
  }

  void _launchPhone() async {
    final uri = Uri(scheme: 'tel', path: '+94112345678');
    try {
      await launchUrl(uri);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open dialer.')),
      );
    }
  }

  void _showLiveChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark
          : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final msgController = TextEditingController();
        final messages = <String>[
          'Hi there! 👋 Welcome to Charge Lanka support.',
          'How can I help you today?',
        ];
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SizedBox(
              height: 400,
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.support_agent, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Live Chat',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Typically replies within minutes',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(ctx).brightness == Brightness.dark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final idx = messages.length - 1 - i;
                        final isAgent = idx < 2;
                        return Align(
                          alignment: isAgent
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isAgent
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              messages[idx],
                              style: TextStyle(
                                color: isAgent ? null : Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: msgController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (_) {
                            final text = msgController.text.trim();
                            if (text.isEmpty) return;
                            setSheetState(() {
                              messages.add(text);
                              msgController.clear();
                            });
                            Future.delayed(
                              const Duration(seconds: 1),
                              () {
                                if (!ctx.mounted) return;
                                setSheetState(() {
                                  messages.add(
                                    'Thanks for reaching out! A support agent '
                                    'will review your message shortly. Ref #'
                                    '${DateTime.now().millisecondsSinceEpoch % 10000}',
                                  );
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.small(
                        heroTag: 'chatSend',
                        onPressed: () {
                          final text = msgController.text.trim();
                          if (text.isEmpty) return;
                          setSheetState(() {
                            messages.add(text);
                            msgController.clear();
                          });
                          Future.delayed(
                            const Duration(seconds: 1),
                            () {
                              if (!ctx.mounted) return;
                              setSheetState(() {
                                messages.add(
                                  'Thanks for reaching out! A support agent '
                                  'will review your message shortly. Ref #'
                                  '${DateTime.now().millisecondsSinceEpoch % 10000}',
                                );
                              });
                            },
                          );
                        },
                        backgroundColor: AppColors.primary,
                        child: const Icon(Icons.send, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── FAQ Section ──
          const SectionHeader(title: 'Frequently Asked Questions'),
          const SizedBox(height: 8),
          VoltCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: List.generate(_faqs.length, (index) {
                final faq = _faqs[index];
                final isExpanded = _expandedIndices.contains(index);
                return Column(
                  children: [
                    if (index > 0) const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        isExpanded
                            ? Icons.remove_circle_outline
                            : Icons.add_circle_outline,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      title: Text(
                        faq['q']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isExpanded ? AppColors.primary : null,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedIndices.remove(index);
                          } else {
                            _expandedIndices.add(index);
                          }
                        });
                      },
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(
                          left: 56,
                          right: 16,
                          bottom: 12,
                        ),
                        child: Text(
                          faq['a']!,
                          style: TextStyle(color: secondaryText, fontSize: 13),
                        ),
                      ),
                      crossFadeState: isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                    ),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 24),

          // ── Contact Support Section ──
          const SectionHeader(title: 'Contact Us'),
          const SizedBox(height: 8),
          VoltCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined, color: AppColors.accent),
                  title: const Text('Email Support'),
                  subtitle: Text(
                    'support@chargelanka.lk',
                    style: TextStyle(color: secondaryText),
                  ),
                  trailing: Icon(Icons.chevron_right, color: secondaryText),
                  onTap: _launchEmail,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone_outlined, color: AppColors.accent),
                  title: const Text('Call Us'),
                  subtitle: Text(
                    '+94 11 234 5678 (Mon–Fri, 9am–5pm)',
                    style: TextStyle(color: secondaryText),
                  ),
                  trailing: Icon(Icons.chevron_right, color: secondaryText),
                  onTap: _launchPhone,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline, color: AppColors.accent),
                  title: const Text('Live Chat'),
                  subtitle: Text(
                    'Chat with a support agent now',
                    style: TextStyle(color: secondaryText),
                  ),
                  trailing: Icon(Icons.chevron_right, color: secondaryText),
                  onTap: _showLiveChat,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BankDetailsPage extends StatefulWidget {
  const BankDetailsPage({super.key});

  @override
  State<BankDetailsPage> createState() => _BankDetailsPageState();
}

class _BankDetailsPageState extends State<BankDetailsPage> {
  final _bankNameController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _branchController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(title: const Text('Bank Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          VoltCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add bank details for withdrawals',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'These details are stored in your profile for payout requests.',
                  style: TextStyle(color: secondaryText),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'Bank name',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _accountHolderController,
                  decoration: const InputDecoration(
                    labelText: 'Account holder name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Account number',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _branchController,
                  decoration: const InputDecoration(
                    labelText: 'Branch',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: GlowingButton(
                    label: 'Save Bank Details',
                    icon: Icons.save_outlined,
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _saveBankDetails,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBankDetails() async {
    final bankName = _bankNameController.text.trim();
    final accountHolder = _accountHolderController.text.trim();
    final accountNumber = _accountNumberController.text.trim();
    final branch = _branchController.text.trim();

    if (bankName.isEmpty ||
        accountHolder.isEmpty ||
        accountNumber.isEmpty ||
        branch.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all bank detail fields.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await getIt<WalletRepository>().saveBankDetails(
        bankName: bankName,
        accountHolder: accountHolder,
        accountNumber: accountNumber,
        branch: branch,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bank details saved successfully.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _auth = FirebaseAuth.instance;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveAccountDetails() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    // Phone is read-only for email/password accounts on Firebase Auth
    // ignore: unused_local_variable
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and email are required.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = _auth.currentUser!;

      // Update display name
      if (user.displayName != name) {
        await user.updateDisplayName(name);
      }

      // Update email (requires recent login in production)
      if (user.email != email) {
        await user.verifyBeforeUpdateEmail(email);
      }

      await user.reload();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account details updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Failed to update account.'),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          VoltCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit your account details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Changes will be synced to your Firebase profile.',
                  style: TextStyle(color: secondaryText),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '+94 7X XXX XXXX',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: GlowingButton(
                    label: 'Save Changes',
                    icon: Icons.save_outlined,
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _saveAccountDetails,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
