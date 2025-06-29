class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const MarketsView(),
    const PortfolioView(),
    const WishlistView(),
    const NewsView(),
    const ProfileView(),
  ];

  static const List<String> _titles = ['Markets', 'Portfolio', 'Wishlist', 'News', 'Profile'];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: NetworkImage('https://placehold.co/100x100/E2E8F0/4A5568?text=U'),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good morning', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
            Text('User', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(BootstrapIcons.search)),
          IconButton(onPressed: () {}, icon: const Icon(BootstrapIcons.bell)),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(BootstrapIcons.graph_up_arrow),
            label: 'Markets',
          ),
          BottomNavigationBarItem(
            icon: Icon(BootstrapIcons.briefcase),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(BootstrapIcons.star),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(BootstrapIcons.newspaper),
            label: 'News',
          ),
          BottomNavigationBarItem(
            icon: Icon(BootstrapIcons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.brandGreen,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}
