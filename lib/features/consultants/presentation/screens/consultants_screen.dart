import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../models/consultant_model.dart';
import '../../../../models/consultation_model.dart';
import 'register_consultant_screen.dart';

/// Screen displaying all registered agricultural consultants in a live-updating stream.
class ConsultantsScreen extends StatefulWidget {
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;
  final Stream<QuerySnapshot<Map<String, dynamic>>>? consultantsStream;
  final List<ConsultantModel>? initialConsultants;

  const ConsultantsScreen({
    super.key,
    this.firestore,
    this.auth,
    this.consultantsStream,
    this.initialConsultants,
  });

  @override
  State<ConsultantsScreen> createState() => _ConsultantsScreenState();
}

class _ConsultantsScreenState extends State<ConsultantsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getConsultantsStream() {
    if (widget.consultantsStream != null) {
      return widget.consultantsStream!;
    }
    final firestore = _firestore;
    if (firestore != null) {
      try {
        return firestore.collection(FirestoreCollections.consultants).snapshots();
      } catch (e) {
        return const Stream.empty();
      }
    }
    return const Stream.empty();
  }

  void _navigateToRegisterConsultant() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RegisterConsultantScreen(
          firestore: widget.firestore,
          auth: widget.auth,
        ),
      ),
    );
  }

  void _showRequestConsultationDialog(ConsultantModel consultant) {
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogInnerContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusMedium),
              ),
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                    radius: 20,
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Request Consultation',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send your inquiry to ${consultant.name} (${consultant.specialization}):',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('consultation_message_field'),
                      controller: messageController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Message / Problem Description *',
                        hintText: 'Describe crop condition, pest issue, or soil inquiry...',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please describe your consultation query';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  key: const Key('submit_consultation_request_button'),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          try {
                            final firestore = _firestore;
                            if (firestore == null) {
                              throw Exception('Database service unavailable.');
                            }

                            final currentUser = _auth?.currentUser;
                            final farmerId = currentUser?.uid ?? 'guest_farmer';

                            final docRef = firestore
                                .collection(FirestoreCollections.consultations)
                                .doc();
                            final now = DateTime.now();

                            final consultation = ConsultationModel(
                              consultationId: docRef.id,
                              consultantId: consultant.consultantId,
                              farmerId: farmerId,
                              message: messageController.text.trim(),
                              status: 'pending',
                              createdAt: now,
                              updatedAt: now,
                            );

                            await docRef.set(consultation.toMap());

                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Consultation requested successfully with ${consultant.name}!',
                                ),
                                backgroundColor: AppColors.primaryGreen,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (!dialogContext.mounted) return;
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text('Error booking consultation: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Submit Request'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expert Consultants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Register as Consultant',
            onPressed: _navigateToRegisterConsultant,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('register_consultant_fab'),
        onPressed: _navigateToRegisterConsultant,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Register as Consultant'),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppColors.paddingMedium,
              AppColors.paddingMedium,
              AppColors.paddingMedium,
              AppColors.paddingSmall,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, specialization, location...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim().toLowerCase());
              },
            ),
          ),

          // Live Consultants Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _getConsultantsStream(),
              builder: (context, snapshot) {
                if (widget.initialConsultants == null && snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppColors.paddingLarge),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 48, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text(
                            'Error loading consultants',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${snapshot.error}',
                            style: const TextStyle(color: AppColors.lightTextSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final List<ConsultantModel> rawConsultants;
                if (widget.initialConsultants != null) {
                  rawConsultants = widget.initialConsultants!;
                } else {
                  final docs = snapshot.data?.docs ?? [];
                  rawConsultants = docs
                      .map((doc) => ConsultantModel.fromMap(doc.data(), doc.id))
                      .toList();
                }

                final consultants = rawConsultants.where((consultant) {
                  if (_searchQuery.isEmpty) return true;
                  return consultant.name.toLowerCase().contains(_searchQuery) ||
                      consultant.specialization.toLowerCase().contains(_searchQuery) ||
                      consultant.location.toLowerCase().contains(_searchQuery);
                }).toList();

                if (consultants.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppColors.paddingLarge),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.psychology_outlined,
                            size: 72,
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No consultants registered yet'
                                : 'No matching consultants found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Be the first expert to join our network and support farmers!'
                                : 'Try searching with a different term or keyword.',
                            style: const TextStyle(color: AppColors.lightTextSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          if (_searchQuery.isEmpty)
                            ElevatedButton.icon(
                              onPressed: _navigateToRegisterConsultant,
                              icon: const Icon(Icons.person_add_rounded),
                              label: const Text('Register as Consultant'),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppColors.paddingMedium,
                    AppColors.paddingSmall,
                    AppColors.paddingMedium,
                    80, // room for floating action button
                  ),
                  itemCount: consultants.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final consultant = consultants[index];
                    return _ConsultantCard(
                      consultant: consultant,
                      onRequestConsultation: () => _showRequestConsultationDialog(consultant),
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

class _ConsultantCard extends StatelessWidget {
  final ConsultantModel consultant;
  final VoidCallback onRequestConsultation;

  const _ConsultantCard({
    required this.consultant,
    required this.onRequestConsultation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        side: BorderSide(
          color: AppColors.lightBorder.withValues(alpha: 0.8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppColors.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar, Name, Specialization badge, Verified tag
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.12),
                  child: Text(
                    consultant.name.isNotEmpty
                        ? consultant.name[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              consultant.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (consultant.verified)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                        ),
                        child: Text(
                          consultant.specialization,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6A1B9A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Experience and Location Details
            Row(
              children: [
                // Experience
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.workspace_premium_outlined,
                        size: 18,
                        color: AppColors.accentAmber,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${consultant.experience} ${consultant.experience == 1 ? "year" : "years"} exp',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.lightTextSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Location
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          consultant.location,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.lightTextSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Action Button: Request Consultation
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: Key('request_consultation_button_${consultant.consultantId}'),
                onPressed: onRequestConsultation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusMedium),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text(
                  'Request Consultation',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
