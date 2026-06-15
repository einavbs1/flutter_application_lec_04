import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadingFileName;

  Future<void> _pickAndUploadResume() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to upload your resume.')),
      );
      return;
    }

    try {
      // Pick PDF file
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // Required for Web to get file bytes
      );

      if (result == null || result.files.isEmpty) return;

      if (!mounted) return;

      final file = result.files.first;

      // Validate extension
      if (file.extension?.toLowerCase() != 'pdf') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only PDF files are allowed.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _uploadingFileName = file.name;
      });

      // Get bytes
      Uint8List? fileBytes = file.bytes;
      if (fileBytes == null && !kIsWeb && file.path != null) {
        fileBytes = await io.File(file.path!).readAsBytes();
      }

      if (fileBytes == null) {
        throw Exception('Could not read file data.');
      }

      // Configure Storage bucket
      final storage = FirebaseStorage.instanceFor(bucket: 'gs://androidnewapp.firebasestorage.app');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'users/${user.uid}/resumes/${timestamp}_${file.name}';
      final ref = storage.ref().child(storagePath);

      // Start Upload
      final uploadTask = ref.putData(
        fileBytes,
        SettableMetadata(contentType: 'application/pdf'),
      );

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (mounted) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      });

      await uploadTask;

      // Get Download URL
      final downloadUrl = await ref.getDownloadURL();

      // Save Metadata to Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('resumes')
          .add({
            'name': file.name,
            'url': downloadUrl,
            'storagePath': storagePath,
            'timestamp': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resume uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading resume: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadingFileName = null;
        });
      }
    }
  }

  Future<void> _openResume(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open document: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _deleteResume(String docId, String storagePath) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Resume?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this resume? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 1. Delete from Firebase Storage
      final storage = FirebaseStorage.instanceFor(bucket: 'gs://androidnewapp.firebasestorage.app');
      await storage.ref().child(storagePath).delete();

      // 2. Delete from Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('resumes')
          .doc(docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume deleted.')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting resume: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: CustomScrollView(
        slivers: [
          // Sleek modern header matching download screen
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF3F3D56),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: const Text(
                'MY RESUMES',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6C63FF), Color(0xFF3F3D56)],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.description_outlined,
                    size: 80,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ),
          ),

          // Upload action
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isUploading) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
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
                              Row(
                                children: [
                                  const CircularProgressIndicator(strokeWidth: 3),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Uploading Resume...',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _uploadingFileName ?? 'file.pdf',
                                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                value: _uploadProgress,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ] else ...[
                        ElevatedButton.icon(
                          onPressed: _pickAndUploadResume,
                          icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
                          label: const Text('UPLOAD NEW RESUME', style: TextStyle(letterSpacing: 1)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      const Text(
                        'Uploaded Resumes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3F3D56),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Dynamic Resume List
          if (user == null)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text('Please log in to view resumes.', style: TextStyle(color: Colors.grey)),
                ),
              ),
            )
          else
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('resumes')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(60.0),
                        child: Column(
                          children: [
                            Icon(Icons.insert_drive_file_outlined, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No resumes uploaded yet.',
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final docId = doc.id;
                        final name = data['name'] ?? 'Resume.pdf';
                        final url = data['url'] ?? '';
                        final storagePath = data['storagePath'] ?? '';
                        final timestamp = data['timestamp'] as Timestamp?;
                        
                        String formattedDate = '';
                        if (timestamp != null) {
                          formattedDate = DateFormat('MMM d, yyyy - HH:mm').format(timestamp.toDate());
                        }

                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Icon
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.picture_as_pdf_rounded,
                                      color: Color(0xFF6C63FF),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF3F3D56),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formattedDate.isNotEmpty ? 'Uploaded: $formattedDate' : 'Uploading...',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Action Buttons
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.open_in_new, color: Color(0xFF6C63FF)),
                                        tooltip: 'Open',
                                        onPressed: () => _openResume(url),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                        tooltip: 'Delete',
                                        onPressed: () => _deleteResume(docId, storagePath),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: snapshot.data!.docs.length,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
