import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shubhnow_user/Pages/Profile_Page/profile_model.dart';
import 'package:shubhnow_user/Pages/Profile_Page/profile_provider.dart';

class ManageAddressScreen extends ConsumerStatefulWidget {
  const ManageAddressScreen({super.key});

  @override
  ConsumerState<ManageAddressScreen> createState() => _ManageAddressScreenState();
}

class _ManageAddressScreenState extends ConsumerState<ManageAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _houseController = TextEditingController();
  final _streetController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  String _selectedType = "Home";

  // 🚀 LOADER STATES
  bool _isSaving = false; // For Add/Edit Button
  bool _isProcessing = false; // For Delete/Default actions

  @override
  void dispose() {
    _houseController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  // ==========================================
  // 🔥 ACTIONS WITH LOADERS
  // ==========================================

  // 1. Save or Update Address
  Future<void> _handleSave(String? editId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      "addressType": _selectedType,
      "houseNo": _houseController.text.trim(),
      "street": _streetController.text.trim(),
      "landmark": _landmarkController.text.trim(),
      "city": _cityController.text.trim(),
      "district": _cityController.text.trim(),
      "state": _stateController.text.trim(),
      "pincode": _pincodeController.text.trim(),
      "lat": 25.5941,
      "lng": 85.1376,
    };

    try {
      if (editId == null) {
        await ref.read(profileControllerProvider.notifier).addAddress(data);
      } else {
        await ref.read(profileControllerProvider.notifier).updateAddress(editId, data);
      }

      if (mounted) {
        Navigator.pop(context); // Close Bottom Sheet
        _showSnackBar(editId == null ? "Address added successfully!" : "Address updated!");
      }
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // 2. Set Default Action
  Future<void> _handleSetDefault(String id) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(profileControllerProvider.notifier).setDefaultAddress(id);
      _showSnackBar("Default address updated");
    } catch (e) {
      _showSnackBar("Failed to update: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // 3. Delete Action
  Future<void> _handleDelete(String id) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(profileControllerProvider.notifier).deleteAddress(id);
      _showSnackBar("Address removed", isError: true);
    } catch (e) {
      _showSnackBar("Failed to delete: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================
  // 📍 UI BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);

    return Stack( // 🚀 Global Stack for Overlay Loader
      children: [
        Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text('My Addresses', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            centerTitle: true,
            backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0.5,
          ),
          body: profileState.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.deepOrange)),
            error: (e, s) => Center(child: Text(e.toString())),
            data: (user) => user.addresses.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: user.addresses.length,
              itemBuilder: (context, index) => _buildAddressCard(user.addresses[index]),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _isProcessing ? null : () => _showAddressSheet(),
            backgroundColor: Colors.black,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Add New", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),

        // 🚀 THE GLOBAL OVERLAY LOADER
        if (_isProcessing)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: Card(
                elevation: 5,
                shape: CircleBorder(),
                child: Padding(
                  padding: EdgeInsets.all(15.0),
                  child: CircularProgressIndicator(color: Colors.deepOrange),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ==========================================
  // 🛠️ ADDRESS FORM SHEET
  // ==========================================
  void _showAddressSheet({AddressModel? address}) {
    if (address != null) {
      _houseController.text = address.houseNo;
      _streetController.text = address.street;
      _landmarkController.text = address.landmark;
      _cityController.text = address.city;
      _stateController.text = address.state;
      _pincodeController.text = address.pincode;
      _selectedType = address.addressType;
    } else {
      _houseController.clear(); _streetController.clear(); _landmarkController.clear();
      _cityController.clear(); _stateController.clear(); _pincodeController.clear();
      _selectedType = "Home";
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  Text(address == null ? "New Address" : "Edit Address", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 20),

                  _buildTypePicker(setSheetState),
                  const SizedBox(height: 20),

                  _buildTextField(_houseController, "House / Flat No.", Icons.home_filled),
                  const SizedBox(height: 12),
                  _buildTextField(_streetController, "Street Name", Icons.location_on),
                  const SizedBox(height: 12),
                  _buildTextField(_landmarkController, "Landmark (Optional)", Icons.assistant_navigation, required: false),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_cityController, "City", Icons.location_city)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(_pincodeController, "Pincode", Icons.pin_drop, isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(_stateController, "State", Icons.map),

                  const SizedBox(height: 30),

                  // 🚀 ACTION BUTTON WITH LOADER
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isSaving ? null : () => _handleSave(address?.id),
                      child: _isSaving
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(address == null ? "SAVE ADDRESS" : "UPDATE ADDRESS",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 🛠️ REUSABLE WIDGETS
  // ==========================================

  Widget _buildAddressCard(AddressModel addr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: addr.isDefault ? Colors.deepOrange : Colors.grey.shade200, width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade50,
              child: Icon(addr.addressType == "Home" ? Icons.home_rounded : Icons.work_rounded, color: Colors.deepOrange),
            ),
            title: Text(addr.addressType, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text("${addr.houseNo}, ${addr.street}, ${addr.city}\n${addr.pincode}"),
            trailing: IconButton(icon: const Icon(Icons.edit_rounded, size: 20), onPressed: () => _showAddressSheet(address: addr)),
          ),
          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: addr.isDefault ? null : () => _handleSetDefault(addr.id),
                child: Text(addr.isDefault ? "Current Default" : "Set as Default",
                    style: TextStyle(color: addr.isDefault ? Colors.grey : Colors.blue, fontWeight: FontWeight.bold)),
              ),
              const VerticalDivider(width: 1),
              TextButton(
                onPressed: () => _confirmDelete(addr.id),
                child: const Text("Remove", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTypePicker(StateSetter setSheetState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ["Home", "Office", "Other"].map((type) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: ChoiceChip(
          label: Text(type),
          selected: _selectedType == type,
          onSelected: (val) => setSheetState(() => _selectedType = type),
          selectedColor: Colors.black,
          labelStyle: TextStyle(color: _selectedType == type ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      )).toList(),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool required = true, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        hintText: hint,
        filled: true, fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.deepOrange)),
      ),
      validator: (v) => (required && (v == null || v.isEmpty)) ? "Required" : null,
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Address?"),
        content: const Text("Are you sure you want to remove this saved location?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(onPressed: () { Navigator.pop(ctx); _handleDelete(id); },
              child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.location_off_rounded, size: 100, color: Colors.grey.shade200),
      const SizedBox(height: 16),
      const Text("No Addresses Saved", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
    ]));
  }
}