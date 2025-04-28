import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/business_provider.dart';
import 'package:inventory_frontend/providers/auth_provider.dart';
import 'package:inventory_frontend/providers/sales_provider.dart';
import 'package:inventory_frontend/providers/item_provider.dart';
import 'package:inventory_frontend/providers/category_provider.dart';
import 'package:inventory_frontend/providers/user_provider.dart';
import 'package:inventory_frontend/providers/bought_provider.dart';
import 'package:inventory_frontend/providers/available_item_provider.dart';
import 'package:inventory_frontend/services/business_service.dart';
import 'package:inventory_frontend/screens/business/business_list_screen.dart';
import 'package:inventory_frontend/screens/business/business_register_screen.dart';
import 'package:inventory_frontend/screens/business/business_detail_screen.dart';
import 'package:inventory_frontend/screens/auth/login_screen.dart';
import 'package:inventory_frontend/screens/splash_screen.dart';
import 'package:inventory_frontend/models/business.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(
          create: (_) => BusinessService(
            baseUrl: 'http://localhost:5000', // Update with your backend URL
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
      ],
      child: MaterialApp(
        title: 'Inventory Management',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/business/register': (context) => const BusinessRegisterScreen(),
          '/business/detail': (context) {
            final business = ModalRoute.of(context)!.settings.arguments as Business;
            return BusinessDetailScreen(business: business);
          },
        },
      ),
    );
  }
}
