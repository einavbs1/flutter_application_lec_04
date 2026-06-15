import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'main_shell_screen.dart'; // To navigate to MainShellScreen

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();
  
  String _countryCode = '+972';
  bool _codeSent = false;
  String? _verificationId;
  ConfirmationResult? _confirmationResult;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyPhone() async {
    if (_formKey.currentState!.validate()) {
      // Unfocus keyboard first to avoid focus trap on disabled elements
      FocusScope.of(context).unfocus();
      
      try {
        final fullPhoneNumber = _countryCode.trim() + _phoneController.text.trim();
        
        if (kIsWeb) {
          final result = await FirebaseAuth.instance.signInWithPhoneNumber(fullPhoneNumber);
          setState(() {
            _confirmationResult = result;
            _codeSent = true;
          });
          
          // Request focus on the newly visible SMS code input
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _codeFocusNode.requestFocus();
            }
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('SMS Code sent!')),
            );
          }
        } else {
          await FirebaseAuth.instance.verifyPhoneNumber(
            phoneNumber: fullPhoneNumber,
            verificationCompleted: (PhoneAuthCredential credential) async {
              await FirebaseAuth.instance.signInWithCredential(credential);
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const MainShellScreen()),
                );
              }
            },
            verificationFailed: (FirebaseAuthException e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Verification failed: ${e.message}')),
              );
            },
            codeSent: (String verificationId, int? resendToken) {
              setState(() {
                _verificationId = verificationId;
                _codeSent = true;
              });

              // Request focus on the newly visible SMS code input
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  _codeFocusNode.requestFocus();
                }
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SMS Code sent!')),
              );
            },
            codeAutoRetrievalTimeout: (String verificationId) {
              _verificationId = verificationId;
            },
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to verify phone number: $e')),
          );
        }
      }
    }
  }

  Future<void> _signInWithCode() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (kIsWeb && _confirmationResult != null) {
          await _confirmationResult!.confirm(_codeController.text.trim());
        } else if (!kIsWeb && _verificationId != null) {
          PhoneAuthCredential credential = PhoneAuthProvider.credential(
            verificationId: _verificationId!,
            smsCode: _codeController.text.trim(),
          );
          await FirebaseAuth.instance.signInWithCredential(credential);
        } else {
          return;
        }
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainShellScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${e.message}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Phone Login', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Phone Login',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF3F3D56)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _codeSent ? 'Enter the SMS code sent to your phone' : 'Enter your phone number (with country code)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              initialValue: _countryCode,
                              enabled: !_codeSent,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Code',
                              ),
                              onChanged: (value) => _countryCode = value,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Req';
                                if (!value.startsWith('+')) return 'Use +';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              enabled: !_codeSent,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: Icon(Icons.phone),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter phone number';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_codeSent) ...[
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _codeController,
                          focusNode: _codeFocusNode,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '6-digit Code',
                            prefixIcon: Icon(Icons.password),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter code';
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _codeSent ? _signInWithCode : _verifyPhone,
                          icon: Icon(_codeSent ? Icons.check_circle : Icons.send),
                          label: Text(_codeSent ? 'VERIFY & LOGIN' : 'SEND SMS'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      if (_codeSent) ...[
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _codeSent = false;
                              _codeController.clear();
                            });
                          },
                          child: const Text('Change Phone Number'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
