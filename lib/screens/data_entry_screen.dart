import 'package:flutter/material.dart';
import '../models/chemical.dart';
import '../services/hive_service.dart';

/// Manual data entry screen with offline support
///
/// Features:
/// - Form validation
/// - Saves data locally using Hive
/// - Queues for sync when offline
/// - Animated form interactions
/// - Real-time validation feedback
class DataEntryScreen extends StatefulWidget {
  const DataEntryScreen({super.key});

  @override
  State<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final HiveService _hiveService;

  // Form controllers
  final _productNameController = TextEditingController();
  final _casNumberController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _quantityController = TextEditingController();
  final _storageLocationController = TextEditingController();
  final _categoryController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedUnit = 'L';
  String _selectedLocation = 'Storage Room A';
  bool _isSaving = false;

  // Dropdown options
  final List<String> _units = ['L', 'mL', 'g', 'kg', 'units'];
  final List<String> _predefinedLocations = [
    'Storage Room A',
    'Storage Room B',
    'Refrigerator 1',
    'Cabinet 1',
    'Other',
  ];

  _DataEntryScreenState() : _hiveService = HiveService();

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _productNameController.dispose();
    _casNumberController.dispose();
    _manufacturerController.dispose();
    _quantityController.dispose();
    _storageLocationController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  /// Save chemical data to local storage
  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Create chemical object from form data
      final chemical = Chemical(
        productName: _productNameController.text.trim(),
        casNumber: _casNumberController.text.trim(),
        manufacturerName: _manufacturerController.text.trim(),
        currentStockQuantity: double.parse(_quantityController.text),
        unit: _selectedUnit,
        category: _categoryController.text.isNotEmpty
            ? _categoryController.text.trim()
            : null,
        storageLocation: _selectedLocation == 'Other'
            ? _storageLocationController.text.trim()
            : _selectedLocation,
        expiryDate: null, // Can be added with date picker
      );

      // Save to Hive for offline access
      await _hiveService.addPendingSync(chemical);

      // Show success message with animation
      if (mounted) {
        _showSuccessDialog();
      }

      // Clear form
      _clearForm();
    } catch (e) {
      _showError('Error saving data: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Show success dialog with animation
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('Success'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chemical saved successfully!'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_off, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Data saved locally and will sync when online',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Clear form fields
  void _clearForm() {
    _productNameController.clear();
    _casNumberController.clear();
    _manufacturerController.clear();
    _quantityController.clear();
    _storageLocationController.clear();
    _categoryController.clear();

    setState(() {
      _selectedUnit = 'L';
      _selectedLocation = 'Storage Room A';
    });

    // Reset and replay animation
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Entry'),
        actions: [
          // Show pending count
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Chip(
                label: Text(
                  '${_hiveService.getPendingSyncCount()} pending',
                  style: const TextStyle(fontSize: 12),
                ),
                avatar: const Icon(Icons.pending_actions, size: 16),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Text(
                    'Add New Chemical',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fill in the details below to add a new chemical to inventory',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Product Name
                  _buildAnimatedTextField(
                    controller: _productNameController,
                    label: 'Product Name *',
                    hint: 'Enter chemical name',
                    icon: Icons.science,
                    delay: 0,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter product name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // CAS Number
                  _buildAnimatedTextField(
                    controller: _casNumberController,
                    label: 'CAS Number *',
                    hint: 'e.g., 7732-18-5',
                    icon: Icons.tag,
                    delay: 50,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter CAS number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Manufacturer
                  _buildAnimatedTextField(
                    controller: _manufacturerController,
                    label: 'Manufacturer *',
                    hint: 'Enter manufacturer name',
                    icon: Icons.business,
                    delay: 100,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter manufacturer';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Quantity Row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildAnimatedTextField(
                          controller: _quantityController,
                          label: 'Quantity *',
                          hint: 'Enter quantity',
                          icon: Icons.inventory_2,
                          delay: 150,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAnimatedDropdown(
                          value: _selectedUnit,
                          label: 'Unit',
                          items: _units,
                          delay: 200,
                          onChanged: (value) {
                            setState(() => _selectedUnit = value!);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category (Optional)
                  _buildAnimatedTextField(
                    controller: _categoryController,
                    label: 'Category (Optional)',
                    hint: 'e.g., Acid, Base, Solvent',
                    icon: Icons.category,
                    delay: 250,
                  ),
                  const SizedBox(height: 16),

                  // Storage Location Dropdown
                  _buildAnimatedDropdown(
                    value: _selectedLocation,
                    label: 'Storage Location *',
                    items: _predefinedLocations,
                    delay: 300,
                    icon: Icons.location_on,
                    onChanged: (value) {
                      setState(() => _selectedLocation = value!);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Custom Location (if "Other" selected)
                  if (_selectedLocation == 'Other')
                    _buildAnimatedTextField(
                      controller: _storageLocationController,
                      label: 'Custom Location *',
                      hint: 'Enter storage location',
                      icon: Icons.edit_location,
                      delay: 350,
                      validator: (value) {
                        if (_selectedLocation == 'Other' &&
                            (value == null || value.isEmpty)) {
                          return 'Please enter location';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 24),

                  // Offline Info Card
                  _buildInfoCard(),
                  const SizedBox(height: 24),

                  // Save Button
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build animated text field
  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required int delay,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  /// Build animated dropdown
  Widget _buildAnimatedDropdown({
    required String value,
    required String label,
    required List<String> items,
    required int delay,
    IconData? icon,
    required void Function(String?) onChanged,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOut,
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: child,
          ),
        );
      },
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: const OutlineInputBorder(),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  /// Build info card
  Widget _buildInfoCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Offline Sync Info',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Data will be saved locally and synced automatically when connection is restored.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build save button with loading state
  Widget _buildSaveButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveData,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
        ),
        child: _isSaving
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Text(
          'Save Chemical',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}