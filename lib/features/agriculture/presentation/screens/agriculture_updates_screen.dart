import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../models/agriculture_update_model.dart';
import 'post_update_screen.dart';

/// Screen displaying all official agricultural updates in a live-updating list.
class AgricultureUpdatesScreen extends StatefulWidget {
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;
  final Stream<QuerySnapshot<Map<String, dynamic>>>? updatesStream;
  final List<AgricultureUpdateModel>? initialUpdates;

  const AgricultureUpdatesScreen({
    super.key,
    this.firestore,
    this.auth,
    this.updatesStream,
    this.initialUpdates,
  });

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'scheme':
        return AppColors.primaryGreen;
      case 'training':
        return AppColors.primary;
      case 'camp':
        return AppColors.accentAmber;
      case 'announcement':
        return const Color(0xFF8E24AA);
      case 'subsidy':
        return AppColors.accentTeal;
      case 'event':
        return AppColors.error;
      default:
        return const Color(0xFF546E7A);
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'scheme':
        return Icons.policy_rounded;
      case 'training':
        return Icons.school_rounded;
      case 'camp':
        return Icons.campaign_rounded;
      case 'announcement':
        return Icons.notifications_active_rounded;
      case 'subsidy':
        return Icons.monetization_on_rounded;
      case 'event':
        return Icons.event_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  @override
  State<AgricultureUpdatesScreen> createState() =>
      _AgricultureUpdatesScreenState();
}

class _AgricultureUpdatesScreenState extends State<AgricultureUpdatesScreen> {
  String _selectedCategory = 'All';

  static const List<String> _filterCategories = [
    'All',
    'Scheme',
    'Training',
    'Camp',
    'Announcement',
    'Subsidy',
    'Event',
  ];

  FirebaseFirestore? get _firestore {
    if (widget.firestore != null) return widget.firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getUpdatesStream() {
    if (widget.updatesStream != null) {
      return widget.updatesStream!;
    }
    final firestore = _firestore;
    if (firestore != null) {
      try {
        return firestore
            .collection(FirestoreCollections.agricultureUpdates)
            .orderBy('createdAt', descending: true)
            .snapshots();
      } catch (e) {
        return firestore
            .collection(FirestoreCollections.agricultureUpdates)
            .snapshots();
      }
    }
    return const Stream.empty();
  }

  void _navigateToPostUpdate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PostUpdateScreen(
          firestore: widget.firestore,
          auth: widget.auth,
        ),
      ),
    );
  }

  void _openDetailView(AgricultureUpdateModel update) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AgricultureUpdateDetailScreen(update: update),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agriculture Updates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.post_add_rounded),
            tooltip: 'Post Update',
            onPressed: _navigateToPostUpdate,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('post_update_fab'),
        onPressed: _navigateToPostUpdate,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post Update'),
      ),
      body: Column(
        children: [
          // Category Filter Chips
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(
              horizontal: AppColors.paddingMedium,
              vertical: AppColors.paddingSmall,
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filterCategories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _filterCategories[index];
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  key: Key('category_chip_$category'),
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.primaryGreen
                        : theme.colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = category);
                    }
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Live Stream List of Updates
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _getUpdatesStream(),
              builder: (context, snapshot) {
                if (widget.initialUpdates == null &&
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: AppColors.paddingMedium),
                        Text('Loading official updates...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppColors.paddingLarge),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: AppColors.paddingMedium),
                          Text(
                            'Failed to load agriculture updates',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppColors.paddingSmall),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final List<AgricultureUpdateModel> rawUpdates;
                if (widget.initialUpdates != null) {
                  rawUpdates = List.of(widget.initialUpdates!);
                } else {
                  final docs = snapshot.data?.docs ?? [];
                  rawUpdates = docs
                      .map((doc) =>
                          AgricultureUpdateModel.fromMap(doc.data(), doc.id))
                      .toList();
                }

                // Sort newest first
                rawUpdates.sort((a, b) {
                  final aTime =
                      a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final bTime =
                      b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return bTime.compareTo(aTime);
                });

                // Apply category filter
                final updates = _selectedCategory == 'All'
                    ? rawUpdates
                    : rawUpdates
                        .where((item) =>
                            item.category.toLowerCase() ==
                            _selectedCategory.toLowerCase())
                        .toList();

                if (updates.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppColors.paddingLarge),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.campaign_outlined,
                              size: 64,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: AppColors.paddingMedium),
                          Text(
                            _selectedCategory == 'All'
                                ? 'No Agriculture Updates Available'
                                : 'No $_selectedCategory Updates Available',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppColors.paddingSmall),
                          Text(
                            _selectedCategory == 'All'
                                ? 'Agriculture officers can publish official schemes, advisories, and camps using the button below.'
                                : 'There are currently no updates in the "$_selectedCategory" category.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: AppColors.paddingLarge),
                          ElevatedButton.icon(
                            onPressed: _navigateToPostUpdate,
                            icon: const Icon(Icons.add),
                            label: const Text('Post First Update'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppColors.paddingMedium,
                    AppColors.paddingMedium,
                    AppColors.paddingMedium,
                    80, // room for FAB
                  ),
                  itemCount: updates.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppColors.paddingMedium),
                  itemBuilder: (context, index) {
                    final update = updates[index];
                    return _AgricultureUpdateCard(
                      update: update,
                      onTap: () => _openDetailView(update),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Card displaying an update summary with category badge, title, description, and timestamp.
class _AgricultureUpdateCard extends StatelessWidget {
  final AgricultureUpdateModel update;
  final VoidCallback onTap;

  const _AgricultureUpdateCard({
    required this.update,
    required this.onTap,
  });

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    return '$day $month $year';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor =
        AgricultureUpdatesScreen.getCategoryColor(update.category);
    final categoryIcon =
        AgricultureUpdatesScreen.getCategoryIcon(update.category);

    return Card(
      key: Key('update_card_${update.updateId}'),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        side: BorderSide(
          color: AppColors.lightBorder.withValues(alpha: 0.8),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppColors.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Category Badge and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Category Badge with icon & color
                  Container(
                    key: Key('category_badge_${update.updateId}'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusSmall),
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(categoryIcon, size: 14, color: categoryColor),
                        const SizedBox(width: 4),
                        Text(
                          update.category,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: categoryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Date
                  if (update.createdAt != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(update.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: AppColors.paddingSmall),

              // Title
              Text(
                update.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Description
              if (update.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  update.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ],
              const SizedBox(height: AppColors.paddingSmall),

              // View details prompt
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Read full details',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.primaryGreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Detail screen showing the complete agricultural update content.
class AgricultureUpdateDetailScreen extends StatelessWidget {
  final AgricultureUpdateModel update;

  const AgricultureUpdateDetailScreen({
    super.key,
    required this.update,
  });

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$day $month $year, $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor =
        AgricultureUpdatesScreen.getCategoryColor(update.category);
    final categoryIcon =
        AgricultureUpdatesScreen.getCategoryIcon(update.category);

    return Scaffold(
      appBar: AppBar(
        title: Text(update.category),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing update details...')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppColors.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category badge & Timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusSmall),
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(categoryIcon, size: 16, color: categoryColor),
                        const SizedBox(width: 6),
                        Text(
                          update.category,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: categoryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (update.createdAt != null)
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(update.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: AppColors.paddingMedium),

              // Title
              Text(
                update.title,
                key: const Key('update_detail_title'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: AppColors.paddingSmall),

              // Official Notice Tag
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      size: 16,
                      color: AppColors.primaryGreen,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Official Agriculture Extension Bulletin',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppColors.paddingMedium),

              // Summary Box (Description)
              if (update.description.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppColors.paddingMedium),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    borderRadius:
                        BorderRadius.circular(AppColors.radiusMedium),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        update.description,
                        key: const Key('update_detail_description'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppColors.paddingLarge),
              ],

              // Full Details Section Header
              Text(
                'Full Details & Instructions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppColors.paddingSmall),
              const Divider(),
              const SizedBox(height: AppColors.paddingSmall),

              // Full Content
              Text(
                update.content,
                key: const Key('update_detail_content'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: AppColors.paddingLarge),
            ],
          ),
        ),
      ),
    );
  }
}
