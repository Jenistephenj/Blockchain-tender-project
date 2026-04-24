import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tender/utills/auth_gate_public.dart';
import 'package:tender/utills/auth_gate_contractor.dart';
import 'package:tender/utills/auth_gate_government.dart';
import 'package:tender/utills/auth_gate_department.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1A5F7A),
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF1A5F7A),
          secondary: const Color(0xFF2D936C),
          background: const Color(0xFFF8F9FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1A5F7A),
          elevation: 3,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A5F7A),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: const Color(0xFF2C3E50),
          ),
          labelLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A5F7A),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
        ),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_outlined, size: 24),
            SizedBox(width: 10),
            Text(
              'Tender Management System',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A5F7A),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF8F9FA),
              const Color(0xFFE9ECEF),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[

              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A5F7A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.shield_outlined,
                            color: const Color(0xFF1A5F7A),
                            size: 30,
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            'Secure & Transparent Tender Management',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A5F7A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Text(
                      'A blockchain-enabled platform ensuring integrity, transparency, and accountability in public procurement processes.',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF5D6D7E),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D936C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2D936C).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user, size: 16, color: const Color(0xFF2D936C)),
                          SizedBox(width: 5),
                          Text(
                            'Immutable Audit Trail',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2D936C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 25),


              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Your Role',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Choose your portal to access the tender management system',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF7F8C8D),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),


              Expanded(
                child: GridView.builder(
                  physics: BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final roles = [
                      {
                        'label': 'Administrator',
                        'icon': Icons.account_balance,
                        'route': () => _navigateToGovernmentModule(context),
                        'color': const Color(0xFF1A5F7A),
                        'description': 'Oversee tender allocation and management',
                      },
                      {
                        'label': 'Contractor',
                        'icon': Icons.business_center_rounded,
                        'route': () => _navigateToContractorModule(context),
                        'color': const Color(0xFF2D936C),
                        'description': 'Submit bids and manage projects',
                      },
                      {
                        'label': 'Department',
                        'icon': Icons.apartment_rounded,
                        'route': () => _navigateToDepartmentModule(context),
                        'color': const Color(0xFF34495E),
                        'description': 'Release and monitor tenders',
                      },
                     {
                        'label': 'Public\nPortal',
                        'icon': Icons.groups_rounded,
                        'route': () => _navigateToPeoplesModule(context),
                        'color': const Color(0xFF8E44AD),
                        'description': 'Track progress and provide feedback',
                      },
                    ];

                    final role = roles[index];
                    return _buildRoleCard(
                      role['label'] as String,
                      role['icon'] as IconData,
                      role['route'] as VoidCallback,
                      role['color'] as Color,
                      role['description'] as String,
                      context,
                    );
                  },
                ),
              ),


              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFeatureItem(Icons.lock_outline, 'Secure'),
                    _buildFeatureItem(Icons.visibility_outlined, 'Transparent'),
                    _buildFeatureItem(Icons.timeline_outlined, 'Traceable'),
                    _buildFeatureItem(Icons.assignment_turned_in_outlined, 'Accountable'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
      String label,
      IconData icon,
      VoidCallback onPressed,
      Color color,
      String description,
      BuildContext context,
      ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.05),
                  color.withOpacity(0.02),
                ],
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 32,
                        color: color,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2C3E50),
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF7F8C8D),
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Access Portal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                          SizedBox(width: 5),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: color,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A5F7A).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF1A5F7A),
          ),
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  void _navigateToContractorModule(BuildContext context) {
    _navigateWithAnimation(context, AuthGateContractor(), "Contractor Portal");
  }

  void _navigateToDepartmentModule(BuildContext context) {
    _navigateWithAnimation(context, AuthGateDepartment(), "Department Portal");
  }

  void _navigateToPeoplesModule(BuildContext context) {
    _navigateWithAnimation(context, AuthGatePublic(), "Public Portal");
  }

  void _navigateToGovernmentModule(BuildContext context) {
    _navigateWithAnimation(context, AuthGateGovernment(), "Government Portal");
  }

  void _navigateWithAnimation(BuildContext context, Widget page, String tag) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var curve = Curves.easeInOut;
          var curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: curve,
          );

          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      ),
    );
  }
}