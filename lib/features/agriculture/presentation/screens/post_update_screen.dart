import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../models/agriculture_update_model.dart';
import '../../../../widgets/custom_button.dart';

/// Screen allowing an agriculture officer to publish official updates, schemes,
/// training sessions, camps, announcements, subsidies, or events.
class PostUpdateScreen extends StatefulWidget {
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;

  const PostUpdateScreen({
    super.key,
    this.firestore,
    this.auth,
  });

  @override
  State<PostUpdateScreen> createState() => _PostUpdateScreenState();
}

class _PostUpdateScreenState extends State<PostUpdateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();

  static const List<String> categories = [
    'Scheme',
    'Training',
    'Camp',
    'Announcement',
    'Subsidy',
    'Event',
  ];

  String _selectedCategory = categories.first;
  bool _isLoading = false;

  FirebaseFirestore? get _firestore {
    if (widget.firestore != null) return widget.firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _auth {
    if (widget.auth != null) return widget.auth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String category) {
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

  IconData _getCategoryIcon(String category) {
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

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestore = _firestore;
      if (firestore == null) {
        throw Exception('Database service unavailable.');
      }

      final currentUser = _auth?.currentUser;
      final authorId = currentUser?.uid ?? 'guest_farmer';

      final docRef = firestore
          .collection(FirestoreCollections.agricultureUpdates)
          .doc();
      final now = DateTime.now();

      final update = AgricultureUpdateModel(
        updateId: docRef.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        content: _contentController.text.trim(),
        authorId: authorId,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(update.toMap());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update "${update.title}" posted successfully!'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post update: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Agriculture Update'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppColors.paddingMedium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Banner
                Card(
                  elevation: 0,
                  color: AppColors.primaryGreen.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusMedium),
                    side: BorderSide(
                      color: AppColors.primaryGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppColors.paddingMedium),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              AppColors.primaryGreen.withValues(alpha: 0.15),
                          radius: 24,
                          child: const Icon(
                            Icons.campaign_rounded,
                            color: AppColors.primaryGreen,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppColors.paddingMedium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Agriculture Officer Bulletin',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Post schemes, workshops, camps, and subsidies directly to local farmers.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppColors.paddingLarge),

                // Title Field
                TextFormField(
                  key: const Key('update_title_field'),
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g. PM-KISAN 17th Installment Release',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    if (value.trim().length < 3) {
                      return 'Title must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppColors.paddingMedium),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  key: const Key('update_category_dropdown'),
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(category),
                            size: 18,
                            color: _getCategoryColor(category),
                          ),
                          const SizedBox(width: 8),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: AppColors.paddingMedium),

                // Description Field (Short Text)
                TextFormField(
                  key: const Key('update_description_field'),
                  controller: _descriptionController,
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Description (Short Summary) *',
                    hintText:
                        'e.g. Direct benefit transfer credited to eligible small & marginal farmers.',
                    prefixIcon: Icon(Icons.notes_rounded),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a short description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppColors.paddingMedium),

                // Content Field (Multiline text, full details)
                TextFormField(
                  key: const Key('update_content_field'),
                  controller: _contentController,
                  maxLines: 6,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Full Content & Details *',
                    hintText:
                        'Detailed eligibility criteria, documents required, application deadlines, venues, contact officers, and guidelines...',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the full content details';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppColors.paddingLarge),

                // Submit Button
                CustomButton(
                  key: const Key('post_update_submit_button'),
                  label: 'Post Update',
                  icon: Icons.send_rounded,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _submitUpdate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
