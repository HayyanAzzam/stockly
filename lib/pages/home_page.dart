import 'package:flutter/material.dart';
import 'package:stockly/pages/accounts_page.dart';
import 'package:stockly/pages/dashboard_page.dart';
import 'package:stockly/pages/harvesters_page.dart';
import 'package:stockly/pages/profiles_page.dart';
import 'package:stockly/pages/proxies_page.dart';
import 'package:stockly/pages/settings_page.dart';
import 'package:stockly/pages/tasks_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const DashboardPage(),
    const TasksPage(),
    const ProxiesPage(),
    const ProfilesPage(),
    const AccountsPage(),
    const SettingsPage(),
    const HarvestersPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.public),
            label: 'Proxies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profiles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco),
            label: 'Harvesters',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
