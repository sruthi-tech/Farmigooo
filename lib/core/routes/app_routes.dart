import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/land/presentation/screens/land_placeholder_screen.dart';
import '../../features/machinery/presentation/screens/machinery_placeholder_screen.dart';
import '../../features/workers/presentation/screens/workers_placeholder_screen.dart';
import '../../features/marketplace/presentation/screens/marketplace_screen.dart';
import '../../features/marketplace/presentation/screens/add_product_screen.dart';
import '../../features/consultants/presentation/screens/consultants_placeholder_screen.dart';
import '../../features/agriculture/presentation/screens/agriculture_placeholder_screen.dart';
import '../../features/notifications/presentation/screens/notifications_placeholder_screen.dart';

/// Central Routing configuration for FARMIGO.
abstract class AppRoutes {
  static const String initial = login;

  static const String login = '/login';
  static const String home = '/home';
  static const String land = '/land';
  static const String machinery = '/machinery';
  static const String workers = '/workers';
  static const String marketplace = '/marketplace';
  static const String addProduct = '/marketplace/add-product';
  static const String consultants = '/consultants';
  static const String agriculture = '/agriculture';
  static const String notifications = '/notifications';

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginScreen(),
        home: (context) => const HomeScreen(),
        land: (context) => const LandPlaceholderScreen(),
        machinery: (context) => const MachineryPlaceholderScreen(),
        workers: (context) => const WorkersPlaceholderScreen(),
        marketplace: (context) => const MarketplaceScreen(),
        addProduct: (context) => const AddProductScreen(),
        consultants: (context) => const ConsultantsPlaceholderScreen(),
        agriculture: (context) => const AgriculturePlaceholderScreen(),
        notifications: (context) => const NotificationsPlaceholderScreen(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(
        builder: builder,
        settings: settings,
      );
    }
    return MaterialPageRoute(
      builder: (context) => const LoginScreen(),
      settings: settings,
    );
  }
}
