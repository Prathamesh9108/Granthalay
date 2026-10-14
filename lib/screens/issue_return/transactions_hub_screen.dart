import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routing/app_routes.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/borrow_record.dart';
import '../../repositories/borrowing_repository.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/custom_card.dart';

class TransactionsHubScreen extends StatefulWidget {
  final BorrowingRepository borrowingRepository;
  final VoidCallback? onOpenDrawer;

  const TransactionsHubScreen({
    super.key,
    required this.borrowingRepository,
    this.onOpenDrawer,
  });

  @override
  State<TransactionsHubScreen> createState() => _TransactionsHubScreenState();
}

class _TransactionsHubScreenState extends State<TransactionsHubScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRecords();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<BorrowRecord> _filterRecords(List<BorrowRecord> list, Locale locale) {
    if (_searchQuery.isEmpty) return list;
    return list.where((r) {
      final title = r.displayBookTitle(locale).toLowerCase();
      final member = r.displayMemberName(locale).toLowerCase();
      final bookCode = r.bookCode.toLowerCase();
      final memberCode = r.memberCode.toLowerCase();
      return title.contains(_searchQuery) ||
          member.contains(_searchQuery) ||
          bookCode.contains(_searchQuery) ||
          memberCode.contains(_searchQuery);
    }).toList();
  }

  Future<void> _fetchRecords() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await widget.borrowingRepository.getAllRecords();
    } catch (_) {} finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _confirmReturn(BorrowRecord record) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.returnBookTitle),
        content: Text('${l10n.returnConfirmPrompt}\n\n${record.displayBookTitle(locale)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await widget.borrowingRepository.returnBook(record.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.returnSuccess), backgroundColor: AppColors.accentGreen),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Return failed: ${e.toString().replaceAll("ApiException: ", "")}',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } finally {
                _fetchRecords();
              }
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.navTransactions),
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: widget.onOpenDrawer,
              )
            : null,
        actions: [
          IconButton(
            tooltip: l10n.quickIssueBook,
            icon: const Icon(Icons.outbox_rounded, color: AppColors.primary),
            onPressed: () async {
              final res = await Navigator.pushNamed(context, AppRoutes.issueBook);
              if (res == true) {
                _fetchRecords();
              }
            },
          ),
          IconButton(
            tooltip: l10n.quickReturnBook,
            icon: const Icon(Icons.move_to_inbox_rounded, color: AppColors.accentGreen),
            onPressed: () async {
              final res = await Navigator.pushNamed(context, AppRoutes.returnBook);
              if (res == true) {
                _fetchRecords();
              }
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _isRefreshing ? null : _fetchRecords,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(text: l10n.historyFilterIssued),
            Tab(text: l10n.historyFilterOverdue),
            Tab(text: l10n.historyFilterReturned),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: locale.languageCode == 'mr'
                    ? 'पुस्तक, सभासद किंवा कोड शोधा...'
                    : 'Search by book, member or code...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim().toLowerCase());
              },
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.borrowingRepository as Listenable,
              builder: (context, _) {
                final allRecords = widget.borrowingRepository.records;
                final issuedRecords = _filterRecords(allRecords.where((r) => !r.isReturned).toList(), locale);
                final overdueRecords = _filterRecords(allRecords.where((r) => r.isCurrentlyOverdue).toList(), locale);
                final returnedRecords = _filterRecords(allRecords.where((r) => r.isReturned).toList(), locale);

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Currently Issued
                    _buildRecordsList(
                      records: issuedRecords,
                      emptyTitle: l10n.noRecentTransactions,
                      locale: locale,
                      l10n: l10n,
                      showReturnBtn: true,
                    ),

                    // Tab 2: Overdue
                    _buildRecordsList(
                      records: overdueRecords,
                      emptyTitle: 'कोणतेही पुस्तक मुदत संपलेले नाही',
                      locale: locale,
                      l10n: l10n,
                      showReturnBtn: true,
                    ),

                    // Tab 3: Returned
                    _buildRecordsList(
                      records: returnedRecords,
                      emptyTitle: l10n.noRecentTransactions,
                      locale: locale,
                      l10n: l10n,
                      showReturnBtn: false,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList({
    required List<BorrowRecord> records,
    required String emptyTitle,
    required Locale locale,
    required AppLocalizations l10n,
    required bool showReturnBtn,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        await widget.borrowingRepository.getAllRecords();
      },
      child: records.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                EmptyState(
                  icon: Icons.assignment_outlined,
                  title: emptyTitle,
                  subtitle: 'पुस्तके देण्यासाठी किंवा जमा करण्यासाठी वरील बटणे वापरा',
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final rec = records[i];
        return CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      rec.bookCode,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  StatusBadge.borrowStatus(
                    borrowStatus: rec.actualStatus,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                rec.displayBookTitle(locale),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.borrowingHistory,
                    arguments: {
                      'memberId': rec.memberId,
                      'memberName': rec.displayMemberName(locale),
                      'memberCode': rec.memberCode,
                    },
                  );
                },
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${rec.displayMemberName(locale)} (${rec.memberCode})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.issueDate}: ${rec.issueDate.day}/${rec.issueDate.month}/${rec.issueDate.year}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      Text(
                        '${l10n.dueDate}: ${rec.dueDate.day}/${rec.dueDate.month}/${rec.dueDate.year}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: rec.isCurrentlyOverdue ? AppColors.error : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (showReturnBtn)
                    ElevatedButton(
                      onPressed: () => _confirmReturn(rec),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: Text(l10n.quickReturnBook),
                    )
                  else if (rec.returnDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${rec.returnDate!.day}/${rec.returnDate!.month}/${rec.returnDate!.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGreen,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}
}
