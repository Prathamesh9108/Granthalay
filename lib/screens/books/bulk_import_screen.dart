import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routing/app_routes.dart';
import '../../repositories/book_repository.dart';
import '../../widgets/custom_card.dart';

class BulkImportScreen extends StatefulWidget {
  final BookRepository bookRepository;

  const BulkImportScreen({
    super.key,
    required this.bookRepository,
  });

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  Map<String, dynamic>? _importResult;
  String? _errorMessage;

  Future<void> _pickFile() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (result.isNotEmpty) {
        setState(() {
          _selectedFile = result.first;
          _importResult = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick file: $e';
      });
    }
  }

  Future<void> _startImport() async {
    if (_selectedFile == null || _selectedFile!.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a CSV or Excel file first')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _importResult = null;
    });

    try {
      final res = await widget.bookRepository.bulkImportBooks(_selectedFile!.path!);
      if (mounted) {
        setState(() {
          _importResult = res;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showSampleFormatSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.table_chart_rounded, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text(
                    'Required Columns (10 Columns)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Your CSV or Excel file must contain these exact 10 columns in row 1:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildColumnItem('1', 'bookCode', 'Unique identifier (e.g. B001, BK-101)'),
              _buildColumnItem('2', 'titleMr', 'मराठी शीर्षक (e.g. श्यामची आई)'),
              _buildColumnItem('3', 'titleEn', 'English Title (e.g. Shyamchi Aai)'),
              _buildColumnItem('4', 'authorMr', 'मराठी लेखक (e.g. साने गुरुजी)'),
              _buildColumnItem('5', 'authorEn', 'English Author (e.g. Sane Guruji)'),
              _buildColumnItem('6', 'category', 'कादंबरी, इतिहास, कथासंग्रह, etc.'),
              _buildColumnItem('7', 'isbn', 'ISBN Number (e.g. 978-81-7766-001-1)'),
              _buildColumnItem('8', 'publisher', 'प्रकाशन (e.g. मेहता पब्लिशिंग)'),
              _buildColumnItem('9', 'publicationYear', 'वर्ष (e.g. 1935, 2024)'),
              _buildColumnItem('10', 'totalCopies', 'एकूण प्रती (e.g. 3, 5, 10)'),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
                ),
                child: const Text(
                  '💡 Tip: Up to 5,000+ books are imported in fast batch chunks. Existing book codes are automatically skipped without stopping the import.',
                  style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumnItem(String number, String name, String example) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primary,
            child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ),
          const SizedBox(width: 12),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const Spacer(),
          Text(example, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  String _getFileSizeString() {
    if (_selectedFile?.path == null) return '';
    try {
      final bytes = File(_selectedFile!.path!).lengthSync();
      return '${(bytes / 1024).toStringAsFixed(1)} KB • ';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMarathi = Localizations.localeOf(context).languageCode == 'mr';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isMarathi ? 'मोठ्या प्रमाणात आयात' : 'Bulk Book Import'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Format Help',
            onPressed: _showSampleFormatSheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Enterprise Info Banner
            CustomCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMarathi ? 'हजारो पुस्तके एकाच वेळी जोडा' : 'Enterprise Bulk Book Ingestion',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isMarathi
                                  ? 'CSV किंवा Excel (.xlsx) फाईलद्वारे ५०००+ पुस्तके थेट MySQL मध्ये आयात करा.'
                                  : 'Import up to 5,000+ books into MySQL via CSV or Excel (.xlsx) file.',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBadge(Icons.check_circle_outline, '.CSV Supported', AppColors.primary),
                      _buildBadge(Icons.table_view_rounded, '.XLSX / Excel Supported', AppColors.accentGreen),
                      _buildBadge(Icons.speed_rounded, 'Batch Optimized', AppColors.info),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // File Selection Box
            GestureDetector(
              onTap: _isUploading ? null : _pickFile,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedFile != null ? AppColors.primary : AppColors.border,
                    width: _selectedFile != null ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFile != null ? Icons.file_present_rounded : Icons.cloud_upload_outlined,
                      size: 54,
                      color: _selectedFile != null ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFile != null
                          ? _selectedFile!.name
                          : (isMarathi ? 'CSV किंवा Excel फाईल निवडा' : 'Choose CSV or Excel File'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedFile != null
                          ? '${_getFileSizeString()}Tap to change file'
                          : (isMarathi ? 'येथे टॅप करा आणि फाईल निवडा' : 'Tap to browse phone storage or Google Drive'),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Format Help & Sample Template Button
            OutlinedButton.icon(
              onPressed: _showSampleFormatSheet,
              icon: const Icon(Icons.format_list_numbered_rounded, size: 18),
              label: Text(isMarathi ? '१० स्तंभांचे नमुना स्वरूप पहा' : 'View 10-Column Required Format'),
            ),

            const SizedBox(height: 20),

            // Upload / Import Action Button
            ElevatedButton(
              onPressed: (_selectedFile != null && !_isUploading) ? _startImport : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isUploading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        ),
                        SizedBox(width: 14),
                        Text('आयात प्रक्रिया सुरू आहे... (Processing batch)', style: TextStyle(fontSize: 15)),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.file_upload_rounded),
                        const SizedBox(width: 8),
                        Text(
                          isMarathi ? 'पुस्तके आयात करा (Start Import)' : 'Upload & Import Books',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),

            // Error Display
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Results Card
            if (_importResult != null) ...[
              const SizedBox(height: 20),
              _buildResultCard(isMarathi),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildResultCard(bool isMarathi) {
    final successCount = _importResult!['successCount'] ?? 0;
    final skipCount = _importResult!['skipCount'] ?? 0;
    final errorCount = _importResult!['errorCount'] ?? 0;
    final totalRows = _importResult!['totalRows'] ?? 0;
    final message = _importResult!['message'] ?? '';
    final errors = (_importResult!['errors'] as List?) ?? [];

    return CustomCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.task_alt_rounded, color: AppColors.accentGreen, size: 24),
              const SizedBox(width: 10),
              Text(
                isMarathi ? 'आयात निकाल (Import Summary)' : 'Import Summary',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.toString(),
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          ),
          const Divider(height: 24),
          Row(
            children: [
              _buildStatMetric('एकूण ओळी', totalRows.toString(), AppColors.textPrimary),
              _buildStatMetric('यशस्वी', successCount.toString(), AppColors.accentGreen),
              _buildStatMetric('वगळले (Duplicate)', skipCount.toString(), AppColors.info),
              _buildStatMetric('त्रुटी', errorCount.toString(), AppColors.error),
            ],
          ),
          if (errors.isNotEmpty) ...[
            const Divider(height: 24),
            const Text(
              'त्रुटींची यादी (Error Log):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.error),
            ),
            const SizedBox(height: 6),
            ...errors.take(5).map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $e', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ),
                ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.booksList);
            },
            icon: const Icon(Icons.menu_book_rounded),
            label: Text(isMarathi ? 'पुस्तकांची यादी पहा' : 'View Books Directory'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
