import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_localization_service.dart';
import '../widgets/base_screen.dart';
import '../widgets/glass_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? _localPhotoPath;
  Uint8List? _photoBytes;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _nameController = TextEditingController(text: authService.currentUser?.displayName ?? '');
    _phoneController = TextEditingController(text: authService.currentUser?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _localPhotoPath = pickedFile.path;
          _photoBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        final provider = Provider.of<ThemeAndLocalizationProvider>(context, listen: false);
        return Container(
          color: provider.backgroundColor,
          child: SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.photo_library, color: provider.primaryColor),
                  title: Text(context.tr('ChooseMonth').replaceAll('Month', 'Photo from Gallery')), // We can write raw or translation
                  // Wait, we have TakePhoto in translations! Let's check
                  // TakePhoto is 'Take Photo', and for Gallery, we can use raw text or search for a translation key. We can just use raw text like Gallery/Camera.
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: provider.primaryColor),
                  title: Text(context.tr('TakePhoto')),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final storageService = StorageService();

    setState(() {
      _isUploading = true;
    });

    try {
      String? uploadUrl;
      if (_photoBytes != null && authService.currentUser != null) {
        uploadUrl = await storageService.uploadProfilePicture(
          _photoBytes!,
          authService.currentUser!.id,
        );
      }

      await authService.updateProfile(
        displayName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        profilePicUrl: uploadUrl ?? authService.currentUser?.profilePicUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('ProfileUpdatedSuccess'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('UpdateProfileError')}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeAndLocalizationProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    if (user == null) {
      return const BaseScreen(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    ImageProvider profileImage;
    if (_photoBytes != null) {
      profileImage = MemoryImage(_photoBytes!);
    } else if (user.profilePicUrl != null && user.profilePicUrl!.isNotEmpty) {
      profileImage = NetworkImage(user.profilePicUrl!);
    } else {
      profileImage = const AssetImage('assets/images/dotnet_bot.png');
    }

    return BaseScreen(
      title: context.tr('MyProfile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture Section
              Stack(
                children: [
                  CircleAvatar(
                    radius: 64,
                    backgroundImage: profileImage,
                    backgroundColor: Colors.grey.shade800,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: provider.primaryColor,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        onPressed: _showImagePickerOptions,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Profile Form Card
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.tr('Identity'),
                      style: TextStyle(
                        color: provider.textPrimaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 24),

                    // Read-only Email Field
                    Text(
                      context.tr('EmailReadOnly'),
                      style: TextStyle(color: provider.textSecondaryColor, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: provider.borderColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        user.email,
                        style: TextStyle(color: provider.textSecondaryColor, fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Read-only Role Field
                    Text(
                      context.tr('Role'),
                      style: TextStyle(color: provider.textSecondaryColor, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: provider.borderColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        user.role == 'Foreman' ? context.tr('Foreman') : context.tr('Worker'),
                        style: TextStyle(color: provider.textSecondaryColor, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Display Name Field
                    Text(
                      context.tr('FullNamePlaceholder'),
                      style: TextStyle(color: provider.textSecondaryColor, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: provider.textPrimaryColor),
                      decoration: InputDecoration(
                        hintText: context.tr('DisplayNamePlaceholder'),
                        hintStyle: TextStyle(color: provider.textSecondaryColor),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: provider.borderColor.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: provider.primaryColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('FillAllFields');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone Field (using a standard label "Phone")
                    Text(
                      'Phone',
                      style: TextStyle(color: provider.textSecondaryColor, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneController,
                      style: TextStyle(color: provider.textPrimaryColor),
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '+46 70 123 45 67',
                        hintStyle: TextStyle(color: provider.textSecondaryColor),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: provider.borderColor.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: provider.primaryColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: (_isUploading || authService.isLoading) ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: provider.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: (_isUploading || authService.isLoading)
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              context.tr('SaveChanges'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
