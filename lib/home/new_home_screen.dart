import 'package:flutter/material.dart';
import 'package:carsbuzz/home/new_home_repo.dart';
import 'package:carsbuzz/profile/profile_screen.dart';
import 'package:carsbuzz/home/service_category_card.dart';
import 'package:carsbuzz/models/address_response.dart';
import 'package:carsbuzz/models/banner_data_response.dart';
import 'package:carsbuzz/models/category_response.dart';
import 'package:carsbuzz/models/selected_car.dart';
import 'package:carsbuzz/repository/selected_cars_repo.dart';
import 'package:carsbuzz/screens/car_selection_screen.dart';
import 'package:carsbuzz/widgets/refer_and_earn_widget.dart';
import 'package:carsbuzz/widgets/selected_cars_modal.dart';
import '../screens/refer_and_earn_screen.dart';
import 'package:carsbuzz/widgets/location_selection_bottom_sheet.dart';
import 'package:carsbuzz/storage/app_shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  final NewHomeRepo _repo = NewHomeRepo();
  final SelectedCarsRepo _selectedCarsRepo = SelectedCarsRepo();
  final PageController _bannerController = PageController();
  
  AddressResponse? currentAddress;
  List<BannerDataResponse> banners = [];
  List<CategoryResponse> categories = [];
  SelectedCar? primarySelectedCar;
  List<SelectedCar> selectedCars = []; // Add this to store all selected cars
  bool isLoading = true;
  int currentBannerIndex = 0;
  
  // Location selection variables
  String? selectedLocationAddress;
  String? selectedLocationTitle;
  AppSharedPreferences? _prefs;
  
  // User ID loaded from SharedPreferences during authentication
  int? userId;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
    _loadHomeData();
  }
  
  Future<void> _initializePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _prefs = AppSharedPreferences(prefs);
    
    // Load user ID from SharedPreferences
    String? userIdStr = prefs.getString('user_id');
    print('🏠 Home screen loading user ID from prefs: $userIdStr');
    if (userIdStr != null) {
      userId = int.parse(userIdStr);
      print('🏠 User ID loaded successfully: $userId');
    } else {
      print('🏠 No user ID found in SharedPreferences');
    }
    
    _loadSelectedLocation();
  }
  
  void _loadSelectedLocation() {
    if (_prefs != null) {
      setState(() {
        selectedLocationAddress = _prefs!.getSelectedAddress();
        selectedLocationTitle = _prefs!.getSelectedAddressTitle();
      });
    }
    }
  
    void _loadHomeData() async {
      // Try to reload user ID if not available initially (timing issue)
      if (userId == null) {
        print('🏠 User ID not available, trying to reload from SharedPreferences...');
        final prefs = await SharedPreferences.getInstance();
        String? userIdStr = prefs.getString('user_id');
        if (userIdStr != null) {
          userId = int.parse(userIdStr);
          print('🏠 User ID reloaded successfully: $userId');
        }
      }
      
      // Only proceed if user ID is available
      if (userId == null) {
        print('🏠 User ID still not available, skipping home data load');
        return;
      }

      setState(() => isLoading = true);

      // Fetch home data, selected cars, and primary car in parallel
      final futures = await Future.wait([
        _repo.fetchHomeData(userId!),
        _selectedCarsRepo.fetchSelectedCars(userId!), // Fetch all selected cars
        _selectedCarsRepo.fetchPrimarySelectedCar(userId!),
      ]);
      
      if (mounted) {
        final homeData = futures[0] as Map<String, dynamic>;
        final allSelectedCars = futures[1] as List<SelectedCar>;
        final primaryCar = futures[2] as SelectedCar?;
        
        setState(() {
        currentAddress = homeData['currentAddress'] as AddressResponse?;
        banners = homeData['banners'] as List<BannerDataResponse>;
        categories = homeData['categories'] as List<CategoryResponse>;
        selectedCars = allSelectedCars; // Store all selected cars
        primarySelectedCar = primaryCar;
        isLoading = false;
      });
    }
  }
  
  void _showLocationSelectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationSelectionBottomSheet(
        onLocationSelected: (address, title) {
          setState(() {
            selectedLocationAddress = address;
            selectedLocationTitle = title;
          });
          
          // Save to shared preferences
          if (_prefs != null) {
            _prefs!.saveSelectedLocation(address, title);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location updated to: ${title ?? address}')),
          );
        },
      ),
    );
  }

  void _showSelectedCarsModal() async {
    if (userId == null) return;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectedCarsModal(
        selectedCars: selectedCars,
        userId: userId!,
        onPrimaryChanged: (newPrimaryCar) {
          setState(() {
            primarySelectedCar = newPrimaryCar;
            // Update the selectedCars list to reflect the primary change
            selectedCars = selectedCars.map((car) {
              return SelectedCar(
                carName: car.carName,
                carImage: car.carImage,
                primary: car.carName == newPrimaryCar.carName,
              );
            }).toList();
          });
        },
      ),
    );
    
    // Refresh selected cars data after modal is closed
    // (in case user added a new car from the modal)
    if (userId != null) {
      final updatedSelectedCars = await _selectedCarsRepo.fetchSelectedCars(userId!);
      final updatedPrimaryCar = await _selectedCarsRepo.fetchPrimarySelectedCar(userId!);
      if (mounted) {
        setState(() {
          selectedCars = updatedSelectedCars;
          primarySelectedCar = updatedPrimaryCar;
        });
      }
    }
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBannerCarousel(),
                    _buildServicesSection(),
                    _buildOffersSection(),
                    _buildReferralSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    // Determine which address to show
    String displayAddress = selectedLocationAddress ?? 
                          currentAddress?.address ?? 
                          '1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA';
    String displayTitle = selectedLocationTitle ?? 
                         currentAddress?.title ?? 
                         'Ajay new address';
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _showLocationSelectionDialog,
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayAddress,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayTitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey.shade600,
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              if (primarySelectedCar == null) {
                // Navigate to car selection screen if no primary car
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const CarSelectionScreen()),
                );
                
                // Refresh selected cars if user added a new car
                if (result == true && userId != null) {
                  final updatedSelectedCars = await _selectedCarsRepo.fetchSelectedCars(userId!);
                  final updatedPrimaryCar = await _selectedCarsRepo.fetchPrimarySelectedCar(userId!);
                  if (mounted) {
                    setState(() {
                      selectedCars = updatedSelectedCars;
                      primarySelectedCar = updatedPrimaryCar;
                    });
                  }
                }
              } else {
                // Show selected cars modal if there's a primary car
                // If selectedCars is empty but primary car exists, create a list with primary car
                List<SelectedCar> carsToShow = selectedCars.isNotEmpty 
                  ? selectedCars 
                  : [primarySelectedCar!];
                  
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => SelectedCarsModal(
                    selectedCars: carsToShow,
                    userId: userId!,
                    onPrimaryChanged: (newPrimaryCar) {
                      setState(() {
                        primarySelectedCar = newPrimaryCar;
                        // Update the selectedCars list to reflect the primary change
                        selectedCars = selectedCars.map((car) {
                          return SelectedCar(
                            carName: car.carName,
                            carImage: car.carImage,
                            primary: car.carName == newPrimaryCar.carName,
                          );
                        }).toList();
                      });
                    },
                  ),
                );
                
                // Refresh selected cars data after modal is closed
                if (userId != null) {
                  final updatedSelectedCars = await _selectedCarsRepo.fetchSelectedCars(userId!);
                  final updatedPrimaryCar = await _selectedCarsRepo.fetchPrimarySelectedCar(userId!);
                  if (mounted) {
                    setState(() {
                      selectedCars = updatedSelectedCars;
                      primarySelectedCar = updatedPrimaryCar;
                    });
                  }
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show car image if available, otherwise show car icon
                  if (primarySelectedCar?.carImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        primarySelectedCar!.carImage,
                        width: 16,
                        height: 12,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.directions_car, color: Colors.white, size: 14);
                        },
                      ),
                    )
                  else
                    const Icon(Icons.directions_car, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    primarySelectedCar?.carName ?? 'Select Car',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Add dropdown arrow if there's a primary car
                  if (primarySelectedCar != null) ...[
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_drop_down, color: Colors.white, size: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search "Detailing"',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            Icon(Icons.search, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCarousel() {
    if (banners.isEmpty) {
      return _buildDefaultBanner();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _bannerController,
              onPageChanged: (index) {
                setState(() => currentBannerIndex = index);
              },
              itemCount: banners.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(banners[index].imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              banners.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentBannerIndex == index
                      ? Colors.blue
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, color: Colors.white, size: 48),
            SizedBox(height: 8),
            Text(
              'Welcome to CarsBuzz',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Professional Car Care Services',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SERVICES',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          // Display categories if available
          if (categories.isNotEmpty)
            ...categories.take(3).map((category) => ServiceCategoryCard(
              title: category.itemCategory,
              description: '${category.items.length} services available',
              icon: _getCategoryIcon(category.itemCategory),
              onTap: () {
                // Navigate to category details
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening ${category.itemCategory} services')),
                );
              },
            )),
          if (categories.isEmpty)
            const ServiceCategoryCard(
              title: 'Car Detailing',
              description: 'Professional car wash and detailing services',
              icon: Icons.local_car_wash,
            ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'detailing':
      case 'car wash':
        return Icons.local_car_wash;
      case 'maintenance':
      case 'service':
        return Icons.build;
      case 'repair':
        return Icons.car_repair;
      case 'tyres':
      case 'tires':
        return Icons.trip_origin;
      case 'interior':
        return Icons.airline_seat_recline_normal;
      default:
        return Icons.directions_car;
    }
  }

  Widget _buildOffersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Offer & Combos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade200,
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'https://via.placeholder.com/400x200/4A90E2/FFFFFF?text=Service+Combo',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2C3E50), Color(0xFF4A90E2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.car_repair, color: Colors.white, size: 48),
                              SizedBox(height: 8),
                              Text(
                                'Professional Car Detailing',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Service combo (10.0% OFF)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReferralSection() {
    return ReferAndEarnWidget(
      onReferNowTapped: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ReferAndEarnScreen(),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
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
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Buy Car',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sell),
            label: 'Sell Car',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: 'Support',
          ),
        ],
        onTap: (index) {
          // Handle navigation
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              // Navigate to buy car
              break;
            case 2:
              // Navigate to sell car
              break;
            case 3:
              // Navigate to profile
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              break;
            case 4:
              // Navigate to support
              break;
          }
        },
      ),
    );
  }
}