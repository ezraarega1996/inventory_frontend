import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/auth_provider.dart';
import 'package:inventory_frontend/screens/admin/admin_dashboard.dart';
import 'package:inventory_frontend/screens/auth/business_registration_screen.dart';
import 'package:inventory_frontend/screens/owner/owner_dashboard.dart';
import 'package:inventory_frontend/screens/salesman/salesman_dashboard.dart';
import 'package:inventory_frontend/widgets/custom_button.dart';
import 'package:inventory_frontend/widgets/custom_text_field.dart';
import 'package:inventory_frontend/widgets/language_selector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      if (success) {
        if (authProvider.isAdmin) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboard())
          );
        } else if (authProvider.isOwner) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OwnerDashboard())
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SalesmanDashboard())
          );
        }
      } else {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.error ?? l10n.loginFailed))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LanguageSelector(),
                  Text(
                    l10n.loginSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Image.asset(
                    'assets/images/logo.png',
                    width: MediaQuery.of(context).size.width,
                    height: 300,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.loginTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: _usernameController,
                    labelText: l10n.usernameLabel,
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.usernameRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _passwordController,
                    labelText: l10n.passwordLabel,
                    prefixIcon: Icons.lock,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.passwordRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                    CustomButton(
                    text: l10n.loginButton,
                    isLoading: authProvider.isLoading,
                    onPressed: _login,
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BusinessRegistrationScreen())
                      );
                    },
                    child: Text(l10n.registerBusiness),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
