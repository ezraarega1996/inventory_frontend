import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/providers/business_provider.dart';
import 'package:inventory_frontend/services/business_service.dart';
import 'package:inventory_frontend/screens/business/business_list_screen.dart';
import 'package:inventory_frontend/screens/business/business_register_screen.dart';
import 'package:inventory_frontend/screens/business/business_detail_screen.dart';
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
          '/': (context) => const BusinessListScreen(),
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
