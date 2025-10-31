import 'package:alsat/modules/home/cart_screen.dart';
import 'package:alsat/modules/home/chat_screen.dart';
import 'package:alsat/modules/home/home_screen.dart';
import 'package:alsat/modules/home/products_screen.dart';
import 'package:alsat/modules/home/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/cart_service.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CartScreen(),
    const ProductsScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_selectedIndex],

      bottomNavigationBar: _buildBottomAppBar(),

      floatingActionButton: Transform.translate(
        offset: const Offset(0, 12),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedIndex = 2;
            });
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF5A623),
                ),
                child: const Icon(
                  Icons.add,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomAppBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        color: Colors.white,
        elevation: 8,
        child: SizedBox(
          height: 70,
          child: Stack(
            children: [
              Positioned(
                top: 4,
                left: MediaQuery.of(context).size.width / 2 - 20,
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavBarIcon(Icons.home, 0, context),
                  _buildNavBarIcon(Icons.shopping_cart, 1, context),
                  const SizedBox(width: 40),
                  _buildNavBarIcon(Icons.chat_bubble_outline, 3, context),
                  _buildNavBarIcon(Icons.person_outline, 4, context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarIcon(IconData icon, int index, BuildContext context) {
    Widget iconWidget = Icon(
      icon,
      color: _selectedIndex == index
          ? const Color(0xFF7E57C2)
          : Colors.grey,
    );

    if (index == 1) { // Cart icon index
      return Consumer<CartService>(
        builder: (context, cartService, child) {
          final itemCount = cartService.totalItemCount; // Using the new getter
          return Stack(
            children: [
              IconButton(
                icon: iconWidget,
                onPressed: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
              if (itemCount > 0) // Only show badge if there are items
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      itemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }

    return IconButton(
      icon: iconWidget,
      onPressed: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }
}