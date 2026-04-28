import 'package:best_flutter_ui_templates/app_theme.dart';
import 'package:best_flutter_ui_templates/custom_drawer/drawer_user_controller.dart';
import 'package:best_flutter_ui_templates/custom_drawer/home_drawer.dart';
import 'package:best_flutter_ui_templates/feedback_screen.dart';
import 'package:best_flutter_ui_templates/help_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/employer_dashboard_screen.dart';
import 'screens/owner_dashboard_screen.dart';
import 'screens/deliveries_screen.dart';
import 'screens/assign_city_screen.dart';
import 'screens/employers_screen.dart';
import 'screens/drivers_screen.dart';
import 'screens/cities_screen.dart';
import 'screens/product_types_screen.dart';
import 'screens/logs_screen.dart';
import 'services/api_service.dart';
import 'package:best_flutter_ui_templates/invite_friend_screen.dart';
import 'package:flutter/material.dart';

class NavigationHomeScreen extends StatefulWidget {
  @override
  _NavigationHomeScreenState createState() => _NavigationHomeScreenState();
}

class _NavigationHomeScreenState extends State<NavigationHomeScreen> {
  Widget? screenView;
  DrawerIndex? drawerIndex;
  String? _userRole;

  @override
  void initState() {
    drawerIndex = DrawerIndex.HOME;
    _loadUserRole();
    super.initState();
  }

  void _loadUserRole() async {
    _userRole = await apiService.getUserRole();
    _initDashboard();
  }

  void _initDashboard() {
    setState(() {
      if (_userRole == 'owner') {
        screenView = const OwnerDashboardScreen();
      } else if (_userRole == 'employer') {
        screenView = const EmployerDashboardScreen();
      } else {
        screenView = const DashboardScreen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.white,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Scaffold(
          backgroundColor: AppTheme.nearlyWhite,
          body: DrawerUserController(
            screenIndex: drawerIndex,
            drawerWidth: MediaQuery.of(context).size.width * 0.75,
            onDrawerCall: (DrawerIndex drawerIndexdata) {
              changeIndex(drawerIndexdata);
              //callback from drawer for replace screen as user need with passing DrawerIndex(Enum index)
            },
            screenView: screenView,
            //we replace screen view as we need on navigate starting screens like MyHomePage, HelpScreen, FeedbackScreen, etc...
          ),
        ),
      ),
    );
  }

  void changeIndex(DrawerIndex drawerIndexdata) {
    if (drawerIndex != drawerIndexdata) {
      drawerIndex = drawerIndexdata;
      switch (drawerIndex) {
        case DrawerIndex.HOME:
          _initDashboard();
          break;
        case DrawerIndex.Employers:
          setState(() {
            screenView = const EmployersScreen();
          });
          break;
        case DrawerIndex.Drivers:
          setState(() {
            screenView = const DriversScreen();
          });
          break;
        case DrawerIndex.Cities:
          setState(() {
            screenView = const CitiesScreen();
          });
          break;
        case DrawerIndex.ProductTypes:
          setState(() {
            screenView = const ProductTypesScreen();
          });
          break;
        case DrawerIndex.Deliveries:
          setState(() {
            screenView = DeliveriesScreen(isDriver: _userRole == 'driver');
          });
          break;
        case DrawerIndex.AssignCity:
          setState(() {
            screenView = const AssignCityScreen();
          });
          break;  
        case DrawerIndex.Help:
          setState(() {
            screenView = HelpScreen();
          });
          break;
        case DrawerIndex.FeedBack:
          setState(() {
            screenView = FeedbackScreen();
          });
          break;
        case DrawerIndex.Invite:
          setState(() {
            screenView = InviteFriend();
          });
          break;
        case DrawerIndex.Logs:
          setState(() {
            screenView = const LogsScreen();
          });
          break;
        default:
          break;
      }
    }
  }
}
