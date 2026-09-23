import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../models/consultant_model.dart';
import '../../../../widgets/custom_button.dart';

/// Screen allowing an agricultural consultant to register their professional profile.
class RegisterConsultantScreen extends StatefulWidget {
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;

  const RegisterConsultantScreen({
    super.key,
    this.firestore,
    this.auth,
  });

  @override
  State<RegisterConsultantScreen> createState() => _RegisterConsultantScreenState();
}

class _RegisterConsultantScreenState extends State<RegisterConsultantScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();

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
    _nameController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitConsultant() async {
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
      final userId = currentUser?.uid ?? 'guest_farmer';

      final docRef = firestore.collection(FirestoreCollections.consultants).doc();
      final now = DateTime.now();

      final consultant = ConsultantModel(
        consultantId: docRef.id,
        userId: userId,
        name: _nameController.text.trim(),
        specialization: _specializationController.text.trim(),
        experience: int.tryParse(_experienceController.text.trim()) ?? 0,
        location: _locationController.text.trim(),
        phone: _phoneController.text.trim(),
        availability: true,
        verified: false,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(consultant.toMap());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${consultant.name} registered as Consultant successfully!'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to register consultant: $e'),
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
        title: const Text('Register as Consultant'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppColors.paddingMedium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Information Card
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
                          backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                          radius: 24,
                          child: const Icon(
                            Icons.psychology_rounded,
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
                                'Expert Advisory Profile',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Share your agricultural expertise with local farmers and agribusinesses.',
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

                // Full Name Field
                TextFormField(
                  key: const Key('consultant_name_field'),
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'e.g. Dr. Rajesh Kumar',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppColors.paddingMedium),

                // Specialization Field
                TextFormField(
                  key: const Key('consultant_specialization_field'),
                  controller: _specializationController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Specialization *',
                    hintText: 'e.g. Soil Health, Crop Pathology, Organic Farming',
                    prefixIcon: Icon(Icons.workspace_premium_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your specialization';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppColors.paddingMedium),

                // Experience (Years) Field
                TextFormField(
                  key: const Key('consultant_experience_field'),
                  controller: _experienceController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Experience (in years) *',
                    hintText: 'e.g. 8',
                    prefixIcon: Icon(Icons.timeline_rounded),
                    suffixText: 'years',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your experience';
                    }
                    final exp = int.tryParse(value.trim());
                    if (exp == null || exp < 0) {
                      return 'Please enter a valid positive number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppColors.paddingMedium),

                // Location Field
                TextFormField(
                  key: const Key('consultant_location_field'),
                  controller: _locationController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Location / District *',
                    hintText: 'e.g. Coimbatore, Tamil Nadu',
                    prefixIcon: Icon(Icons.location_on_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppColors.paddingMedium),

                // Phone Field
                TextFormField(
                  key: const Key('consultant_phone_field'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    hintText: 'e.g. +91 9876543210',
                    prefixIcon: Icon(Icons.phone_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                    if (digitsOnly.length < 7) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppColors.paddingLarge),

                // Submit Button
                CustomButton(
                  key: const Key('register_consultant_submit_button'),
                  label: 'Register Profile',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _isLoading,
                  onPressed: _submitConsultant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
