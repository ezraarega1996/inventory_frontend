import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/language_provider.dart';
import 'package:inventory_frontend/screens/auth/login_screen.dart';
import 'package:inventory_frontend/screens/salesman/available_items_screen.dart';
import 'package:inventory_frontend/providers/business_provider.dart';
import 'package:inventory_frontend/providers/auth_provider.dart';
import 'package:inventory_frontend/providers/sales_provider.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/providers/category_provider.dart';
import 'package:inventory_frontend/providers/user_provider.dart';
import 'package:inventory_frontend/providers/bought_provider.dart';
import 'package:inventory_frontend/providers/available_item_provider.dart';
import 'package:inventory_frontend/providers/shop_provider.dart';
import 'package:inventory_frontend/services/business_service.dart';
import 'package:inventory_frontend/screens/business/business_list_screen.dart';
import 'package:inventory_frontend/screens/business/business_register_screen.dart';
import 'package:inventory_frontend/screens/business/business_detail_screen.dart';
import 'package:inventory_frontend/screens/splash_screen.dart';
import 'package:inventory_frontend/models/business.dart';
import 'package:inventory_frontend/screens/salesman/sell_item_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final languageProvider = await LanguageProvider.create();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: languageProvider),
        Provider(
          create: (_) => BusinessService(
            baseUrl: 'https://18.116.170.87:5000/api',
          ),
        ),
        ChangeNotifierProxyProvider<BusinessService, BusinessProvider>(
          create: (context) => BusinessProvider(
            Provider.of<BusinessService>(context, listen: false),
          ),
          update: (context, businessService, previous) => BusinessProvider(
            businessService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SalesProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ItemProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => BoughtProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AvailableItemProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ShopProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          title: 'Inventory Management',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('am'), // Amharic
          ],
          locale: languageProvider.locale,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/business/register': (context) => const BusinessRegisterScreen(),
            '/business/detail': (context) {
              final business = ModalRoute.of(context)!.settings.arguments as Business;
              return BusinessDetailScreen(business: business);
            },
            '/sell-item': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
              return SellItemScreen(
                preSelectedAvailableItem: args?['preSelectedItem'],
                preSelectedAvailableFraction: args?['preSelectedFraction'],
              );
            },
            '/available-items': (context) => AvailableItemsScreen(),
            '/business/list': (context) => const BusinessListScreen(),
          },
        );
      },
    );
  }
}
