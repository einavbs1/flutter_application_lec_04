import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'signup_screen.dart';
import 'login_screen.dart';
import 'main_shell_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isTestLoggingIn = false;

  Future<void> _runOneTapTestLogin() async {
    if (_isTestLoggingIn) return;

    setState(() {
      _isTestLoggingIn = true;
    });

    final testPhone = '+972501234567';
    final testPin = '123456';

    try {
      if (kIsWeb) {
        // Web Programmatic Auth Bypass
        final confirmationResult = await FirebaseAuth.instance.signInWithPhoneNumber(testPhone);
        await confirmationResult.confirm(testPin);
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainShellScreen()),
          );
        }
      } else {
        // Mobile Programmatic Auth Bypass
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: testPhone,
          verificationCompleted: (PhoneAuthCredential credential) async {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainShellScreen()),
              );
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            setState(() {
              _isTestLoggingIn = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Test Login Failed: ${e.message}'),
                backgroundColor: Colors.redAccent,
              ),
            );
          },
          codeSent: (String verificationId, int? resendToken) async {
            // Programmatically submit test PIN to bypass SMS manual input
            PhoneAuthCredential credential = PhoneAuthProvider.credential(
              verificationId: verificationId,
              smsCode: testPin,
            );
            await FirebaseAuth.instance.signInWithCredential(credential);
            
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainShellScreen()),
              );
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTestLoggingIn = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test Login Failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Welcome', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Hello!',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3F3D56),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sign in or sign up to continue',
                    style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24.0),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1555421689-491a97ff2040?q=80&w=1000&auto=format&fit=crop&ixlib=rb-4.0.3.jpg',
                        width: 250,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Normal Login
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Login(title: 'Login')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 4,
                        shadowColor: const Color(0xFF6C63FF).withOpacity(0.4),
                      ),
                      child: const Text('LOGIN'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Sign Up
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignupPage()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6C63FF),
                        side: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text('SIGN UP'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Premium 1-Tap Test Login bypass
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isTestLoggingIn ? null : _runOneTapTestLogin,
                      icon: const Icon(Icons.flash_on, color: Colors.white),
                      label: const Text(
                        '1-TAP TEST LOGIN',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB300), // High-visibility premium Amber/Gold
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 6,
                        shadowColor: const Color(0xFFFFB300).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (_isTestLoggingIn)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB300)),
                        ),
                        SizedBox(height: 20),
                        Text(
                          '⚡ Running 1-Tap Login...',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Authenticating with test phone number...',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}