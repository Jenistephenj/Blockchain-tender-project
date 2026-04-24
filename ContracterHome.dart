import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tender/contractor/ContracterLogin.dart';
import 'package:tender/contractor/ContractorViewTenders.dart';

import 'ContractorProfile.dart';
import 'MyBiddingStatus.dart';
import 'ContractorMyTenders.dart';

void main() {
  runApp(MaterialApp(
    home: ContracterHome(),
  ));
}

class ContracterHome extends StatefulWidget {
  @override
  State<ContracterHome> createState() => _ContracterHomeState();
}

class _ContracterHomeState extends State<ContracterHome> {
  int _selectedIndex = 0;
  bool isLogoutLoading = false;



  final List<Widget> _pages = [
    HomePage(),
    VieTenders(),
    ContractorBiddingStatus(),
    CpntractorMyTenders(),
    ContractorProfilePage(),
  ];

  final List<String> _pageTitles = [
    'Home',
    'View Tenders',
    'Bidding Status',
    'My Tenders',
    'Profile',
  ];




  Future<void> logout() async {

    bool? shouldLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.teal[700])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal[700],
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    setState(() {
      isLogoutLoading = true;
    });

    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ContracterLogin()),
    );

    setState(() {
      isLogoutLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[700],
        title: Text(
          _pageTitles[_selectedIndex],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: logout,
            icon: isLogoutLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Icon(Icons.exit_to_app, color: Colors.white),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal[700]),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person, size: 80, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      'Welcome, Contractor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 5),
                    Text(
                      FirebaseAuth.instance.currentUser?.email ?? 'No Email',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            ListTile(
              leading: Icon(Icons.home, color: Colors.teal[700]),
              title: Text('Home'),
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.view_agenda, color: Colors.teal[700]),
              title: Text('View Tenders'),
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.assignment_turned_in, color: Colors.teal[700]),
              title: Text('My Tenders'),
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.gavel, color: Colors.teal[700]),
              title: Text('My Tenders'),
              onTap: () {
                setState(() => _selectedIndex = 3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.teal[700]),
              title: Text('Profile'),
              onTap: () {
                setState(() => _selectedIndex = 4);
                Navigator.pop(context);
              },
            ),
            Divider(),

            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.red),
              title: Text('Logout'),
              onTap: logout,
            ),
          ],
        ),
      ),


      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 500),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.teal[700],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        selectedLabelStyle: TextStyle(fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_agenda),
            label: 'View Tenders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in),
            label: 'Bidding Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gavel),
            label: 'My Tenders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _carouselItems = [
    {
      'title': 'Find Tenders',
      'description': 'Browse available  tenders',
      'color': Colors.teal[600],
      'icon': Icons.search,
    },
    {
      'title': 'Apply Easily',
      'description': 'Quick and simple tender application process',
      'color': Colors.teal[700],
      'icon': Icons.send,
    },
    {
      'title': 'Track Status',
      'description': 'Monitor your tender applications',
      'color': Colors.teal[800],
      'icon': Icons.track_changes,
    },
  ];

  final List<Map<String, dynamic>> _quickActions = [
    {
      'title': 'View Tenders',
      'icon': Icons.view_agenda,
      'index': 1,
    },

    {
      'title': 'Bidding Status',
      'icon': Icons.assignment_turned_in,
      'index': 2,
    },
    {
      'title': 'My Tenders',
      'icon': Icons.gavel,
      'index': 3,
    },

    {
      'title': 'Profile',
      'icon': Icons.person,
      'index': 4,
    },
  ];

  @override
  void initState() {
    super.initState();

    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(Duration(seconds: 3), () {
      if (_pageController.hasClients) {
        if (_currentPage < _carouselItems.length - 1) {
          _pageController.nextPage(
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else {
          _pageController.jumpToPage(0);
        }
        _startAutoScroll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [

          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.teal[50],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.business, size: 80, color: Colors.teal[700]),
                SizedBox(height: 15),
                Text(
                  'Contractor Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 15),
                Text(
                  'Your one-stop portal for managing  tenders. '
                      'Find, apply, and track tenders with ease and efficiency.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user, color: Colors.teal[700], size: 18),
                    SizedBox(width: 5),
                    Text(
                      'Secure & Reliable Platform',
                      style: TextStyle(
                        color: Colors.teal[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 20),


          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    'Features',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  height: 180,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _carouselItems.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _carouselItems[index]['color'],
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _carouselItems[index]['icon'],
                                  size: 40,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  _carouselItems[index]['title'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  _carouselItems[index]['description'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _carouselItems.length,
                        (index) => Container(
                      width: 8,
                      height: 8,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? Colors.teal[700]
                            : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),


          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
                SizedBox(height: 15),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _quickActions.length,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () {

                          (context.findAncestorStateOfType<_ContracterHomeState>()!)
                              .setState(() {
                            (context.findAncestorStateOfType<_ContracterHomeState>()!)
                                ._selectedIndex = _quickActions[index]['index'];
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.teal[50]!,
                                Colors.teal[100]!,
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _quickActions[index]['icon'],
                                size: 40,
                                color: Colors.teal[700],
                              ),
                              SizedBox(height: 10),
                              Text(
                                _quickActions[index]['title'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal[900],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 30),


          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.teal[700],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Icon(Icons.business, size: 40, color: Colors.white),
                SizedBox(height: 15),
                Text(
                  'Welcome, Contractor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'Manage your tenders efficiently with our portal.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}