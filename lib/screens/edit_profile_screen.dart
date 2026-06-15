import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();

  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (user != null) {
      // Set defaults from Firebase Auth
      _nameController.text = AppState().customDisplayName.isNotEmpty
          ? AppState().customDisplayName
          : (user?.displayName ?? '');
      _phoneController.text = user?.phoneNumber ?? '';
      _emailController.text = user?.email ?? '';

      try {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (docSnapshot.exists && docSnapshot.data() != null) {
          final data = docSnapshot.data()!;
          if (data['displayName'] != null) {
            _nameController.text = data['displayName'];
          }
          if (data['phoneNumber'] != null) {
            _phoneController.text = data['phoneNumber'];
          }
          if (data['email'] != null) {
            _emailController.text = data['email'];
          }
          _facebookController.text = data['facebookUrl'] ?? '';
          _instagramController.text = data['instagramUrl'] ?? '';
          _tiktokController.text = data['tiktokUrl'] ?? '';
        }
      } catch (e) {
        debugPrint('Error fetching Firestore user profile: $e');
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Update Firebase Auth DisplayName (and email if changed/permitted)
      await user!.updateDisplayName(newName);
      
      // Update local AppState
      AppState().customDisplayName = newName;

      // 2. Save all fields to Firestore users collection
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'displayName': newName,
        'phoneNumber': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'facebookUrl': _facebookController.text.trim(),
        'instagramUrl': _instagramController.text.trim(),
        'tiktokUrl': _tiktokController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile changes saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving changes: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3F3D56))),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Password cannot be empty';
                      }
                      if (value.trim().length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                    validator: (value) {
                      if (value != newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  try {
                    await user?.updatePassword(newPasswordController.text.trim());
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString().contains("requires-recent-login") ? "Re-authentication required. Please log out and log back in." : e.toString()}'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('UPDATE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Ensure no back button is shown
        iconTheme: const IconThemeData(color: Color(0xFF3F3D56)),
        titleTextStyle: const TextStyle(color: Color(0xFF3F3D56), fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Avatar Section
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF6C63FF), width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 70,
                          backgroundImage: NetworkImage(AppState().profileImageUrl),
                          backgroundColor: Colors.grey[200],
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF6C63FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  // Info Card (Personal Details)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3F3D56)),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 20),
                        // Change Password Trigger
                        OutlinedButton.icon(
                          onPressed: _showChangePasswordDialog,
                          icon: const Icon(Icons.lock_reset_outlined, size: 20),
                          label: const Text('CHANGE PASSWORD'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Social Media URLs Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Social Links',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3F3D56)),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _facebookController,
                          decoration: const InputDecoration(
                            labelText: 'Facebook URL',
                            prefixIcon: Icon(Icons.link),
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _instagramController,
                          decoration: const InputDecoration(
                            labelText: 'Instagram URL',
                            prefixIcon: Icon(Icons.link),
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _tiktokController,
                          decoration: const InputDecoration(
                            labelText: 'TikTok URL',
                            prefixIcon: Icon(Icons.link),
                          ),
                          keyboardType: TextInputType.url,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
