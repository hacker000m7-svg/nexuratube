import 'package:flutter/material.dart';

// استدعاء الشاشات الأربعة
import 'hub/hub_screen.dart';
import 'browser/browser_screen.dart';
import 'media_hub/media_hub_screen.dart';
import 'toolbox/toolbox_screen.dart';

// استدعاء شريط التنقل
import '../widgets/custom_nav_bar.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({Key? key}) : super(key: key);

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // قائمة الشاشات المدمجة
  final List<Widget> _screens = const [
    HubScreen(),
    BrowserScreen(),
    MediaHubScreen(),
    ToolboxScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // نستخدم IndexedStack للحفاظ على حالة المتصفح والتحميلات عند التنقل بين التبويبات
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // جعل شريط التنقل يطفو فوق المحتوى (Extend Body)
      extendBody: true, 
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}