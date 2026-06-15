import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

enum DownloadStatus { ready, downloading, downloaded }

class DownloadItem {
  final String name;
  final String category;
  final IconData icon;
  final Color themeColor;
  final String fileName; // Name of the file in Firebase Storage (e.g. service_guide.pdf)
  final String fallbackUrl; // High-availability public fallback PDF url
  double progress;
  DownloadStatus status;
  String? downloadUrl; // Holds the fetched download URL

  DownloadItem({
    required this.name,
    required this.category,
    required this.icon,
    required this.themeColor,
    required this.fileName,
    required this.fallbackUrl,
    this.progress = 0.0,
    this.status = DownloadStatus.ready,
    this.downloadUrl,
  });
}

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final List<DownloadItem> _content = [
    DownloadItem(
      name: 'Service Guide', 
      category: 'Official Guide PDF', 
      icon: Icons.picture_as_pdf_rounded, 
      themeColor: const Color(0xFF6C63FF),
      fileName: 'service_guide.pdf',
      fallbackUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    ),
    DownloadItem(
      name: 'Maintenance Manual', 
      category: 'Detailed Manual PDF', 
      icon: Icons.settings_suggest_rounded, 
      themeColor: const Color(0xFFE91E63),
      fileName: 'maintenance_manual.pdf',
      fallbackUrl: 'https://pdfmyurl.com/samples/key_features_pdfmyurl.pdf',
    ),
    DownloadItem(
      name: 'Safety Checklist', 
      category: 'Important Safety Rules', 
      icon: Icons.verified_user_rounded, 
      themeColor: const Color(0xFF00BCD4),
      fileName: 'safety_checklist.pdf',
      fallbackUrl: 'https://www.orimi.com/pdf-test.pdf',
    ),
    DownloadItem(
      name: 'Pricing Catalog', 
      category: 'Services & Rates PDF', 
      icon: Icons.monetization_on_rounded, 
      themeColor: const Color(0xFFFF9800),
      fileName: 'pricing_catalog.pdf',
      fallbackUrl: 'https://www.africau.edu/images/default/sample.pdf',
    ),
    DownloadItem(
      name: 'Terms & Conditions', 
      category: 'Legal Agreements PDF', 
      icon: Icons.gavel_rounded, 
      themeColor: const Color(0xFF4CAF50),
      fileName: 'terms_conditions.pdf',
      fallbackUrl: 'https://unec.edu.az/application/uploads/2014/12/pdf-sample.pdf',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: CustomScrollView(
        slivers: [
          // Sleek Modern Header
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
                'LIBRARY',
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
                    Icons.cloud_done_outlined,
                    size: 80,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ),
          ),
          
          // Centered Content List
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Documents',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3F3D56),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Download resources directly from Firebase Storage to open them.',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        // List of items
                        ..._content.map((item) => PremiumDownloadTile(item: item)).toList(),
                      ],
                    ),
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

class PremiumDownloadTile extends StatefulWidget {
  final DownloadItem item;
  const PremiumDownloadTile({super.key, required this.item});

  @override
  State<PremiumDownloadTile> createState() => _PremiumDownloadTileState();
}

class _PremiumDownloadTileState extends State<PremiumDownloadTile> {
  Timer? _timer;
  DateTime? _lastUpdatedTime;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      final storage = FirebaseStorage.instanceFor(bucket: 'gs://androidnewapp.firebasestorage.app');
      final ref = storage.ref().child(widget.item.fileName);
      final metadata = await ref.getMetadata();
      if (mounted) {
        setState(() {
          _lastUpdatedTime = metadata.updated;
        });
      }
    } catch (e) {
      debugPrint('Error fetching storage metadata for ${widget.item.fileName}: $e');
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      widget.item.status = DownloadStatus.downloading;
      widget.item.progress = 0.0;
    });

    try {
      // Explicitly target your bucket to prevent configuration mismatch errors
      final storage = FirebaseStorage.instanceFor(bucket: 'gs://androidnewapp.firebasestorage.app');
      final ref = storage.ref().child(widget.item.fileName);
      final fetchedUrl = await ref.getDownloadURL();
      
      widget.item.downloadUrl = fetchedUrl;
      debugPrint('Successfully fetched Firebase Storage URL: $fetchedUrl');

      // Premium progress bar animation
      _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          widget.item.progress += 0.04; // Fast, smooth animation
          if (widget.item.progress >= 1.0) {
            widget.item.progress = 1.0;
            widget.item.status = DownloadStatus.downloaded;
            _timer?.cancel();
          }
        });
      });
    } catch (e) {
      debugPrint('Firebase Storage download error: $e');
      if (mounted) {
        setState(() {
          widget.item.status = DownloadStatus.ready;
          widget.item.progress = 0.0;
          widget.item.downloadUrl = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download failed: Document not found or Storage permissions blocked.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _stopDownload() {
    _timer?.cancel();
    setState(() {
      widget.item.status = DownloadStatus.ready;
      widget.item.progress = 0.0;
      widget.item.downloadUrl = null;
    });
  }

  Future<void> _openFile() async {
    final urlStr = widget.item.downloadUrl;
    if (urlStr == null) return;

    final Uri uri = Uri.parse(urlStr);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $urlStr';
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Stylized Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: widget.item.themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.item.icon, color: widget.item.themeColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3F3D56),
                          ),
                        ),
                        Text(
                          widget.item.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (_lastUpdatedTime != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Updated: ${_lastUpdatedTime!.day}/${_lastUpdatedTime!.month}/${_lastUpdatedTime!.year} ${_lastUpdatedTime!.hour.toString().padLeft(2, '0')}:${_lastUpdatedTime!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Action Button
                  _buildActionButton(),
                ],
              ),
            ),
            // Elegant Bottom Progress Line
            if (widget.item.status == DownloadStatus.downloading)
              LinearProgressIndicator(
                value: widget.item.progress,
                minHeight: 4,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(widget.item.themeColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    switch (widget.item.status) {
      case DownloadStatus.ready:
        return OutlinedButton(
          onPressed: _startDownload,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            side: BorderSide(color: widget.item.themeColor.withOpacity(0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            'GET',
            style: TextStyle(color: widget.item.themeColor, fontWeight: FontWeight.bold),
          ),
        );
      case DownloadStatus.downloading:
        return IconButton(
          icon: Icon(Icons.close_rounded, color: Colors.grey[400]),
          onPressed: _stopDownload);
      case DownloadStatus.downloaded:
        return ElevatedButton(
          onPressed: _openFile,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.item.themeColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text('OPEN', style: TextStyle(fontWeight: FontWeight.bold)),
        );
    }
  }
}
