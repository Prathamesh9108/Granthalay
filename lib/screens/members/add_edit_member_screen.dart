import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/member.dart';
import '../../repositories/member_repository.dart';

class AddEditMemberScreen extends StatefulWidget {
  final MemberRepository memberRepository;
  final Member? memberToEdit;

  const AddEditMemberScreen({
    super.key,
    required this.memberRepository,
    this.memberToEdit,
  });

  @override
  State<AddEditMemberScreen> createState() => _AddEditMemberScreenState();
}

class _AddEditMemberScreenState extends State<AddEditMemberScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _codeController;
  late final TextEditingController _nameMrController;
  late final TextEditingController _nameEnController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _deptController;

  bool _isLoading = false;
  bool get _isEditing => widget.memberToEdit != null;

  @override
  void initState() {
    super.initState();
    final m = widget.memberToEdit;
    _codeController = TextEditingController(text: m?.memberCode ?? 'M00${widget.memberRepository.members.length + 1}');
    _nameMrController = TextEditingController(text: m?.nameMr ?? '');
    _nameEnController = TextEditingController(text: m?.nameEn ?? '');
    _phoneController = TextEditingController(text: m?.phone ?? '');
    _emailController = TextEditingController(text: m?.email ?? '');
    _addressController = TextEditingController(text: m?.address ?? '');
    _deptController = TextEditingController(text: m?.departmentClass ?? '');
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameMrController.dispose();
    _nameEnController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _deptController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    // Require at least one name
    final hasName = _nameMrController.text.trim().isNotEmpty || _nameEnController.text.trim().isNotEmpty;
    if (!hasName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.nameRequired),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final member = Member(
      id: widget.memberToEdit?.id ?? '',
      memberCode: _codeController.text.trim(),
      nameMr: _nameMrController.text.trim(),
      nameEn: _nameEnController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      departmentClass: _deptController.text.trim(),
      registeredDate: widget.memberToEdit?.registeredDate ?? DateTime.now(),
    );

    try {
      if (_isEditing) {
        await widget.memberRepository.updateMember(member);
      } else {
        await widget.memberRepository.addMember(member);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? l10n.successUpdated : l10n.successSaved),
            backgroundColor: AppColors.accentGreen,
          ),
        );
        Navigator.pop(context, member);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
        title: Text(_isEditing ? l10n.editMember : l10n.addMember),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Member Code
              _buildSectionTitle(l10n.memberCode),
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: l10n.memberCode,
                  hintText: 'उदा. M001',
                  prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.codeRequired;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Full Name (Marathi & English)
              _buildSectionTitle(l10n.memberNameMarathi),
              TextFormField(
                controller: _nameMrController,
                decoration: InputDecoration(
                  labelText: l10n.memberNameMarathi,
                  hintText: 'उदा. राहुल पाटील',
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameEnController,
                decoration: InputDecoration(
                  labelText: l10n.memberNameEnglish,
                  hintText: 'e.g. Rahul Patil',
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                ),
              ),

              const SizedBox(height: 20),

              // Contact Information
              _buildSectionTitle(l10n.phoneNumber),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.phoneNumber,
                  hintText: '९८२२०१२३४५',
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.phoneNumber;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.emailAddress,
                  hintText: 'example@email.com',
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                ),
              ),

              const SizedBox(height: 20),

              // Department & Address
              _buildSectionTitle(l10n.departmentClass),
              TextFormField(
                controller: _deptController,
                decoration: InputDecoration(
                  labelText: l10n.departmentClass,
                  hintText: 'उदा. कला शाखा / B.A. Marathi',
                  prefixIcon: const Icon(Icons.school_outlined, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.address,
                  hintText: 'उदा. शिवाजी नगर, पुणे',
                  prefixIcon: const Icon(Icons.home_outlined, color: AppColors.primary),
                ),
              ),

              const SizedBox(height: 32),

              // Save & Cancel Actions
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
