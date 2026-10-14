import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/book.dart';
import '../../repositories/book_repository.dart';

class AddEditBookScreen extends StatefulWidget {
  final BookRepository bookRepository;
  final Book? bookToEdit;

  const AddEditBookScreen({
    super.key,
    required this.bookRepository,
    this.bookToEdit,
  });

  @override
  State<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends State<AddEditBookScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _codeController;
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _isbnController;
  late final TextEditingController _totalCopiesController;
  late final TextEditingController _availableCopiesController;

  bool _isLoading = false;

  bool get _isEditing => widget.bookToEdit != null;

  @override
  void initState() {
    super.initState();
    final b = widget.bookToEdit;
    _codeController = TextEditingController(
      text: b?.bookCode ?? 'BK-${(DateTime.now().millisecondsSinceEpoch % 900) + 100}',
    );

    // Initializing single title and author with fallback
    final initialTitle = b != null ? (b.titleMr.isNotEmpty ? b.titleMr : b.titleEn) : '';
    final initialAuthor = b != null ? (b.authorMr.isNotEmpty ? b.authorMr : b.authorEn) : '';
    _titleController = TextEditingController(text: initialTitle);
    _authorController = TextEditingController(text: initialAuthor);
    _isbnController = TextEditingController(text: b?.isbn ?? '');
    _totalCopiesController = TextEditingController(
      text: b?.totalCopies.toString() ?? '5',
    );
    _availableCopiesController = TextEditingController(
      text: b?.availableCopies.toString() ?? '5',
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _totalCopiesController.dispose();
    _availableCopiesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final totalCopies = int.tryParse(_totalCopiesController.text.trim()) ?? 1;
    final availableCopies = int.tryParse(_availableCopiesController.text.trim()) ?? totalCopies;

    final enteredTitle = _titleController.text.trim();
    final enteredAuthor = _authorController.text.trim();

    String titleMr = enteredTitle;
    String titleEn = enteredTitle;
    if (_isEditing && widget.bookToEdit != null) {
      final old = widget.bookToEdit!;
      if (enteredTitle == old.titleMr) {
        titleMr = old.titleMr;
        titleEn = old.titleEn.isNotEmpty ? old.titleEn : enteredTitle;
      } else if (enteredTitle == old.titleEn) {
        titleMr = old.titleMr.isNotEmpty ? old.titleMr : enteredTitle;
        titleEn = old.titleEn;
      }
    }

    String authorMr = enteredAuthor;
    String authorEn = enteredAuthor;
    if (_isEditing && widget.bookToEdit != null) {
      final old = widget.bookToEdit!;
      if (enteredAuthor == old.authorMr) {
        authorMr = old.authorMr;
        authorEn = old.authorEn.isNotEmpty ? old.authorEn : enteredAuthor;
      } else if (enteredAuthor == old.authorEn) {
        authorMr = old.authorMr.isNotEmpty ? old.authorMr : enteredAuthor;
        authorEn = old.authorEn;
      }
    }

    final book = Book(
      id: widget.bookToEdit?.id ?? '',
      bookCode: _codeController.text.trim(),
      titleMr: titleMr,
      titleEn: titleEn,
      authorMr: authorMr,
      authorEn: authorEn,
      category: widget.bookToEdit?.category ?? 'General',
      isbn: _isbnController.text.trim(),
      publisher: widget.bookToEdit?.publisher ?? '',
      publicationYear: widget.bookToEdit?.publicationYear ?? 0,
      totalCopies: totalCopies,
      availableCopies: availableCopies.clamp(0, totalCopies),
    );

    try {
      if (_isEditing) {
        await widget.bookRepository.updateBook(book);
      } else {
        await widget.bookRepository.addBook(book);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? l10n.successUpdated : l10n.successSaved),
            backgroundColor: AppColors.accentGreen,
          ),
        );
        Navigator.pop(context, book);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll("ApiException: ", "")}'),
            backgroundColor: AppColors.error,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editBook : l10n.addBook),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Book Code
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: '${l10n.bookCode} *',
                  hintText: 'उदा. BK-101',
                  prefixIcon: const Icon(Icons.qr_code_rounded, color: AppColors.primary),
                  suffixIcon: !_isEditing
                      ? IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          tooltip: 'Generate new code',
                          onPressed: () {
                            setState(() {
                              _codeController.text =
                                  'BK-${(DateTime.now().millisecondsSinceEpoch % 900) + 100}';
                            });
                          },
                        )
                      : null,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.codeRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Book Title Section
              _buildSectionTitle(l10n.bookTitle),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.bookTitle,
                  hintText: l10n.bookTitleHint,
                  prefixIcon: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.bookTitleRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Author Section
              _buildSectionTitle(l10n.author),
              TextFormField(
                controller: _authorController,
                decoration: InputDecoration(
                  labelText: l10n.author,
                  hintText: l10n.authorHint,
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                ),
                validator: (val) {
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ISBN Number
              TextFormField(
                controller: _isbnController,
                decoration: InputDecoration(
                  labelText: l10n.isbn,
                  hintText: '978-81-7766-321-1 (ऐच्छिक)',
                  prefixIcon: const Icon(Icons.numbers_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),

              // Copies
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalCopiesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '${l10n.totalCopiesLabel} *',
                        prefixIcon: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                      ),
                      validator: (val) {
                        final n = int.tryParse(val ?? '');
                        if (n == null || n < 1) return l10n.positiveNumberRequired;
                        return null;
                      },
                      onChanged: (val) {
                        if (!_isEditing) {
                          _availableCopiesController.text = val;
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _availableCopiesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '${l10n.availableCopiesLabel} *',
                        prefixIcon: const Icon(Icons.check_circle_outline, color: AppColors.accentGreen),
                      ),
                      validator: (val) {
                        final n = int.tryParse(val ?? '');
                        if (n == null || n < 0) return l10n.positiveNumberRequired;
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Action buttons (Save and Cancel)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(l10n.save),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
