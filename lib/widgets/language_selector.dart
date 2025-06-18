import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/language_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context);

    return IconButton(
      icon: const Text("Language"),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n?.language ?? 'Language'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.blue),
                  title: Text(l10n?.english ?? 'English'),
                  onTap: () {
                    languageProvider.setLanguage(const Locale('en'));
                    print("language set to Amharic");
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.green),
                  title: Text(l10n?.amharic ?? 'አማርኛ'),
                  onTap: () {
                    languageProvider.setLanguage(const Locale('am'));
                    print("language set to Amharic");
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 