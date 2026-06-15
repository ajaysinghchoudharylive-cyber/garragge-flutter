import 'package:flutter/material.dart';
import 'package:carsbuzz/repository/selected_cars_repo.dart';
import 'package:carsbuzz/models/selected_car.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CarSelectionScreen extends StatefulWidget {
  const CarSelectionScreen({super.key});

  @override
  State<CarSelectionScreen> createState() => _CarSelectionScreenState();
}

class _CarSelectionScreenState extends State<CarSelectionScreen> {
  final SelectedCarsRepo _repo = SelectedCarsRepo();
  final TextEditingController _searchController = TextEditingController();
  
  List<CarBrand> _brands = [];
  List<CarBrand> _filteredBrands = [];
  List<CarModel> _models = [];
  List<SelectedCar> _selectedCars = [];
  
  String? _selectedBrand;
  String? _selectedModel;
  int? _userId;
  
  bool _isLoadingBrands = true;
  bool _isLoadingModels = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadUserAndData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredBrands = _brands;
      } else {
        _filteredBrands = _brands.where((brand) => 
          brand.brandName.toLowerCase().contains(query)
        ).toList();
      }
    });
  }

  Future<void> _loadUserAndData() async {
    // Load user ID
    final prefs = await SharedPreferences.getInstance();
    final userIdStr = prefs.getString('user_id');
    if (userIdStr != null) {
      _userId = int.parse(userIdStr);
      await Future.wait([
        _loadBrands(),
        _loadSelectedCars(),
      ]);
    }
  }

  Future<void> _loadBrands() async {
    try {
      setState(() => _isLoadingBrands = true);
      final brands = await _repo.fetchAllCarBrands();
      if (mounted) {
        setState(() {
          _brands = brands;
          _filteredBrands = brands; // Initialize filtered list
          _isLoadingBrands = false;
        });
        if (brands.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No car brands available at the moment')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBrands = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load car brands: $e')),
        );
      }
    }
  }

  Future<void> _loadModels(String brandName) async {
    try {
      setState(() {
        _isLoadingModels = true;
        _models.clear();
        _selectedModel = null;
      });
      
      final models = await _repo.fetchCarModels(brandName);
      if (mounted) {
        setState(() {
          _models = models;
          _isLoadingModels = false;
        });
        if (models.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No models available for $brandName')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingModels = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load models: $e')),
        );
      }
    }
  }

  Future<void> _loadSelectedCars() async {
    if (_userId == null) return;
    
    try {
      final cars = await _repo.fetchSelectedCars(_userId!);
      setState(() => _selectedCars = cars);
    } catch (e) {
      print('Error loading selected cars: $e');
    }
  }

  Future<void> _addCar() async {
    if (_userId == null || _selectedBrand == null || _selectedModel == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final carName = '$_selectedBrand $_selectedModel';
      // Use the actual car image from the selected model if available
      final selectedModelData = _models.firstWhere(
        (model) => model.modelName == _selectedModel,
        orElse: () => CarModel(modelName: _selectedModel!, imageUrl: null),
      );
      final carImage = selectedModelData.imageUrl ?? 
                      'https://carsbuzz-car-brands.s3.amazonaws.com/default_car.png';
      
      // Set as primary if this is the first car
      final setPrimary = _selectedCars.isEmpty;
      
      print('🚗 Attempting to add car: $carName with image: $carImage');
      
      // Save locally first (as fallback)
      await _saveCarLocally(carName, carImage, setPrimary);
      
      final success = await _repo.addSelectedCar(
        userId: _userId!,
        carName: carName,
        carImage: carImage,
        setPrimary: setPrimary,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('$carName added successfully!'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$carName saved locally'),
                        const Text(
                          'Will sync with server when available.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        Navigator.pop(context, true); // Always return true since we saved locally
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveCarLocally(String carName, String carImage, bool isPrimary) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save selected car data locally
      await prefs.setString('selected_car_name', carName);
      await prefs.setString('selected_car_image', carImage);
      await prefs.setBool('selected_car_primary', isPrimary);
      
      print('🚗 Car saved locally: $carName');
    } catch (e) {
      print('❌ Error saving car locally: $e');
    }
  }

@override
Widget build(BuildContext context) {
  return DraggableScrollableSheet(
    initialChildSize: 0.75,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    expand: false,
    builder: (context, scrollController) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [

            /// 🔥 DRAG HANDLE (optional but recommended)
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 6),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            /// 🔥 TOP HEADER + SAVE BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select Car Brand',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: (_selectedBrand != null && _selectedModel != null)
                        ? _addCar
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text("Save", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),

            /// 🔥 SEARCH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchField(),
            ),

            const SizedBox(height: 12),

            /// 🔥 SCROLLABLE CONTENT
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController, // 🔥 VERY IMPORTANT
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _buildBrandSelection(),

                    if (_selectedBrand != null) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Select Model',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildModelSelection(),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          if (_selectedBrand != null) 
            Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedBrand!,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedBrand = null;
                        _selectedModel = null;
                        _models.clear();
                        _searchController.clear();
                        _filteredBrands = _brands;
                      });
                    },
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TextField(
              controller: _searchController,
              enabled: _selectedBrand == null, // Disable when brand is selected
              decoration: InputDecoration(
                hintStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandSelection() {
    if (_isLoadingBrands) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show only selected brand if one is selected, otherwise show all filtered brands
    final brandsToShow = _selectedBrand != null 
        ? _filteredBrands.where((brand) => brand.brandName == _selectedBrand).toList()
        : _filteredBrands;

    if (brandsToShow.isEmpty && _selectedBrand == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No brands found matching your search',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _selectedBrand != null ? 1 : 3, // Single column when brand selected
        childAspectRatio: _selectedBrand != null ? 4 : 1, // Different aspect ratio for selected brand
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: brandsToShow.length,
      itemBuilder: (context, index) {
        final brand = brandsToShow[index];
        final isSelected = _selectedBrand == brand.brandName;
        
        return GestureDetector(
          onTap: () {
            if (_selectedBrand == null) {
              // Selecting a brand for the first time
              setState(() {
                _selectedBrand = brand.brandName;
                _models.clear();
                _selectedModel = null;
                // Clear search when brand is selected
                _searchController.clear();
                _filteredBrands = _brands;
              });
              _loadModels(brand.brandName);
            }
            // If brand is already selected, tapping it won't do anything (use clear button instead)
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? Colors.blue.shade50 : Colors.white,
            ),
            child: _selectedBrand != null 
                ? _buildSelectedBrandRow(brand, isSelected)
                : _buildBrandGridItem(brand, isSelected),
          ),
        );
      },
    );
  }

  Widget _buildBrandGridItem(CarBrand brand, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.network(
          brand.logoUrl,
          height: 40,
          width: 40,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 40,
              width: 40,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_car, color: Colors.white),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          brand.brandName,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.blue : Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSelectedBrandRow(CarBrand brand, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Image.network(
            brand.logoUrl,
            height: 32,
            width: 32,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 32,
                width: 32,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_car, color: Colors.white, size: 16),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  brand.brandName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.blue.shade700 : Colors.black87,
                  ),
                ),
                Text(
                  'Selected brand - choose model below',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelection() {
    if (_isLoadingModels) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_models.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No models found for this brand'),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _models.length,
      itemBuilder: (context, index) {
        final model = _models[index];
        final isSelected = _selectedModel == model.modelName;
        
        return GestureDetector(
          onTap: () {
            setState(() => _selectedModel = model.modelName);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? Colors.blue.shade50 : Colors.white,
              boxShadow: isSelected ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Car Image
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: model.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              height: 60,
                              width: 60,
                              model.imageUrl!,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.directions_car, 
                                    color: Colors.grey, 
                                    size: 32,
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.directions_car, 
                              color: Colors.grey, 
                              size: 32,
                            ),
                          ),
                  ),
                ),
                // Model Name
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      model.modelName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.blue.shade700 : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Selection indicator
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomButton() {
    final canAdd = _selectedBrand != null && _selectedModel != null;
    final buttonText = canAdd 
        ? 'Add $_selectedBrand $_selectedModel' 
        : _selectedBrand != null 
            ? 'Select a $_selectedBrand model' 
            : 'Select Brand & Model';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canAdd)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.directions_car, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_selectedBrand $_selectedModel',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'This will be added to your garage',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: canAdd && !_isSaving ? _addCar : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAdd ? Colors.blue : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: canAdd ? 2 : 0,
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (canAdd) ...[
                            const Icon(Icons.add, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            buttonText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}