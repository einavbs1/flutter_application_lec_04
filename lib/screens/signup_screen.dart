import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'main_shell_screen.dart'; // For MainShellScreen

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  String _fullName = '';
  String _email = '';
  String _countryCode = '+972';
  String _phone = '';
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final fullPhoneNumber = _countryCode.trim() + _phone.trim();
      
      try {
        if (kIsWeb) {
          final result = await FirebaseAuth.instance.signInWithPhoneNumber(fullPhoneNumber);
          _showWebCodeDialog(result);
        } else {
          await FirebaseAuth.instance.verifyPhoneNumber(
            phoneNumber: fullPhoneNumber,
            verificationCompleted: (PhoneAuthCredential credential) async {
              await _createAccountAndLink(credential);
            },
            verificationFailed: (FirebaseAuthException e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Phone verification failed: ${e.message}')),
                );
              }
            },
            codeSent: (String verificationId, int? resendToken) {
              _showCodeDialog(verificationId);
            },
            codeAutoRetrievalTimeout: (String verificationId) {},
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Phone verification failed: $e')),
          );
        }
      }
    }
  }

  void _showWebCodeDialog(ConfirmationResult result) {
    final TextEditingController codeController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter SMS Code'),
        content: TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '6-digit code'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final userCredential = await result.confirm(codeController.text.trim());
                
                AuthCredential emailCred = EmailAuthProvider.credential(
                  email: _email,
                  password: _passwordController.text,
                );
                
                await userCredential.user!.linkWithCredential(emailCred);
                await userCredential.user!.updateDisplayName(_fullName);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account created and phone verified successfully!')),
                  );
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainShellScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid code or linking failed: $e')),
                  );
                }
              }
            },
            child: const Text('Verify & Create Account'),
          ),
        ],
      ),
    );
  }

  void _showCodeDialog(String verificationId) {
    final TextEditingController codeController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter SMS Code'),
        content: TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '6-digit code'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                PhoneAuthCredential credential = PhoneAuthProvider.credential(
                  verificationId: verificationId,
                  smsCode: codeController.text.trim(),
                );
                await _createAccountAndLink(credential);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid code: $e')),
                  );
                }
              }
            },
            child: const Text('Verify & Create Account'),
          ),
        ],
      ),
    );
  }

  Future<void> _createAccountAndLink(PhoneAuthCredential credential) async {
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email,
        password: _passwordController.text,
      );
      
      await userCredential.user!.updateDisplayName(_fullName);
      await userCredential.user!.linkWithCredential(credential);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created and phone verified successfully!')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainShellScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sign Up Failed'),
            content: Text(e.message ?? 'An error occurred during sign up.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Sign Up', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
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
                          'Create Account',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF3F3D56)),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Sign up for free',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 40),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter your full name';
                            return null;
                          },
                          onSaved: (value) => _fullName = value!,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter email';
                            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                            if (!emailRegex.hasMatch(value)) return 'Please enter a valid email address';
                            return null;
                          },
                          onSaved: (value) => _email = value!,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 100,
                              child: TextFormField(
                                initialValue: _countryCode,
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
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: Icon(Icons.phone),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter phone number';
                                  return null;
                                },
                                onSaved: (value) => _phone = value!,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter password';
                            final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
                            final hasNumber = RegExp(r'[0-9]').hasMatch(value);
                            final hasSymbol = RegExp(r'[!@#\$&*~%]').hasMatch(value);
                            if (!hasLetter || !hasNumber || !hasSymbol) {
                              return 'Must contain at least one letter, number, and symbol';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          obscureText: !_isConfirmPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please confirm your password';
                            if (value != _passwordController.text) return 'Passwords do not match';
                            return null;
                          },
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _submit,
                            icon: const Icon(Icons.person_add),
                            label: const Text('SIGN UP'),
                          ),
                        ),
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