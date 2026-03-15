import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shubhnow_user/Pages/Profile_Page/profile_model.dart';
import 'package:shubhnow_user/Pages/Profile_Page/profile_provider.dart';

// 🔥 TODO: Apne exact file paths yahan verify kar lena
import '../Login_Page/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🚀 Listening to the Profile Provider
    final profileState = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      body: profileState.when(
        loading: () => _buildProfileShimmer(),
        error: (error, stack) => _buildErrorScreen(error.toString(), ref),
        data: (user) => _buildActualProfile(context, ref, user),
      ),
    );
  }

  // =========================================================
  // 1. ACTUAL PREMIUM PROFILE UI (MINIMAL & SYNCED)
  // =========================================================
  Widget _buildActualProfile(BuildContext context, WidgetRef ref, ProfileModel user) {

    // 🔥 AVATAR LOGIC: Check if real photo exists or use First Letter
    bool hasValidAvatar = user.avatar.isNotEmpty && !user.avatar.contains('avatar_placeholder');
    String firstLetter = user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 🚀 1. THE HERO HEADER
        SliverAppBar(
          expandedHeight: 250,
          floating: false,
          pinned: true,
          elevation: 0,
          backgroundColor: Colors.deepOrange,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF7A00), Color(0xFFD53A00)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    // Subtle Watermark
                    Positioned(
                      right: -40,
                      top: 10,
                      child: Icon(Icons.temple_hindu_rounded, size: 220, color: Colors.white.withOpacity(0.08)),
                    ),

                    // Profile Data (Center Aligned)
                    Align(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 🔥 INTERACTIVE PROFILE PICTURE
                          GestureDetector(
                            onTap: () => _showImagePickerBottomSheet(context, ref),
                            child: Stack(
                              children: [
                                Container(
                                  height: 95,
                                  width: 95,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(color: Colors.white, width: 3),
                                    image: hasValidAvatar
                                        ? DecorationImage(
                                      // 🚀 THE CACHE KILLER: "?v=timestamp" adds a unique ID to every load
                                      image: NetworkImage("${user.avatar}?v=${DateTime.now().millisecondsSinceEpoch}"),
                                      fit: BoxFit.cover,
                                    )
                                        : null,
                                  ),
                                  child: !hasValidAvatar
                                      ? Center(child: Text(firstLetter, style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.deepOrange)))
                                      : null,
                                ),
                                  ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user.fullName,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              user.phoneNumber,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(24),
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))
              ),
            ),
          ),
        ),

        // 🚀 2. CLEAN MENU SECTIONS (Exactly 6 items)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 10),
                _buildSectionTitle('Account'),
                _buildMenuTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Personal Information',
                  subtitle: 'Update your name, email & phone',
                  onTap: () {
                    context.pushNamed('personal-info', extra: user);
                  },
                ),
                _buildMenuTile(
                  icon: Icons.map_outlined,
                  title: 'Manage Addresses',
                  subtitle: 'Add or edit your saved locations',
                  onTap: () {
                    context.pushNamed('manage-address');
                  },
                ),

                const SizedBox(height: 24),
                _buildSectionTitle('Activity & Offers'),
                _buildMenuTile(
                  icon: Icons.receipt_long_rounded,
                  title: 'Booking History',
                  subtitle: 'Track past and upcoming poojas',
                  onTap: () {},
                ),
                _buildMenuTile(
                  icon: Icons.card_giftcard_rounded,
                  title: 'Refer & Earn',
                  subtitle: 'Invite friends, get discounts',
                  onTap: () {},
                ),

                const SizedBox(height: 24),
                _buildSectionTitle('Help & Settings'),
                _buildMenuTile(
                  icon: Icons.support_agent_rounded,
                  title: 'Help & Support',
                  subtitle: 'Chat or call for assistance',
                  onTap: () {},
                ),
                _buildMenuTile(
                  icon: Icons.settings_outlined,
                  title: 'App Settings',
                  subtitle: 'Notifications, language & preferences',
                  onTap: () {},
                ),

                const SizedBox(height: 30),

                // 🚀 LOGOUT BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.red.shade100, width: 1.5)),
                    ),
                    onPressed: () => _showLogoutDialog(context, ref),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout from ShubhNow', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),

                const SizedBox(height: 100), // Padding for Bottom Nav Bar
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // 🔥 IMAGE PICKER & REAL BACKEND UPLOAD LOGIC
  // =========================================================
  void _showImagePickerBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Wrap(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text('Update Profile Picture', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.photo_library_rounded, color: Colors.deepOrange),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(context, ImageSource.gallery, ref);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.deepOrange),
                  ),
                  title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(context, ImageSource.camera, ref);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source, WidgetRef ref) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 60, // Reduces size for faster Cloudinary upload
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        // 🚀 UX Feedback: Tell user upload has started
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading profile picture... Please wait.'),
            backgroundColor: Colors.deepOrange,
            duration: Duration(seconds: 2),
          ),
        );

        // 🚀 THE MAGIC: Pass image directly to the Provider
        // Provider will show shimmer -> Upload via Dio -> Fetch new Data -> UI will re-render!
        await ref.read(profileControllerProvider.notifier).updateProfile(imageFile: imageFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update picture: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // =========================================================
  // REUSABLE WIDGETS
  // =========================================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 12, left: 4),
      child: Text(
          title.toUpperCase(),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1.2)
      ),
    );
  }

  Widget _buildMenuTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.deepOrange, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black87)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(children: [Icon(Icons.logout_rounded, color: Colors.redAccent), SizedBox(width: 10), Text('Logout', style: TextStyle(fontWeight: FontWeight.w900))]),
          content: const Text('Are you sure you want to log out of your spiritual journey?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(authControllerProvider.notifier).logoutUser();
              },
              child: const Text('Yes, Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // SHIMMER & ERROR SCREENS
  // =========================================================

  Widget _buildProfileShimmer() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100,
            child: Container(
              height: 250, width: double.infinity,
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade200, highlightColor: Colors.white,
              child: Column(
                children: [
                  Container(height: 70, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
                  const SizedBox(height: 12),
                  Container(height: 70, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
                  const SizedBox(height: 12),
                  Container(height: 70, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
                  const SizedBox(height: 12),
                  Container(height: 70, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 80, color: Colors.deepOrange),
            const SizedBox(height: 20),
            Text(error.replaceAll('Exception: ', ''), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => ref.read(profileControllerProvider.notifier).fetchUserProfile(),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}