# CarsBuzz Home Screen Implementation

## Overview
Created a new home screen that matches the provided design image with the following features:

## Key Features Implemented

### 1. Address Display
- Shows current user address at the top
- Displays custom address title (e.g., "Ajay new address")
- Includes car model information (BMW 2 series Grand Coupe)
- Location icon with proper styling

### 2. Search Bar
- Styled search bar with "Detailing" placeholder
- Proper color scheme matching the design
- Search icon on the right side

### 3. Banner Carousel
- Dynamic banner loading from API
- Page indicator dots
- Fallback default banner with CarsBuzz branding
- Smooth page transitions

### 4. Services Section
- Displays available service categories
- Dynamic service count display
- Category-specific icons
- Tap handlers for navigation

### 5. Offers & Combos Section
- Service combo display with discount badge
- Professional car detailing imagery
- "10.0% OFF" promotional tag

### 6. Referral Section
- "Refer & Earn ₹1000!" promotion
- Green gradient background
- "Refer Now" action button
- Proper Indian rupee symbol

### 7. Bottom Navigation
- 5-tab navigation (Home, Buy Car, Sell Car, Profile, Support)
- Material Design styling
- Active state handling

## API Integration

### New Models Created:
- `AddressRequest` - For saving user addresses
- `AddressResponse` - For receiving address data
- `ToggleAddressStatusRequest` - For updating address status
- `BannerDataResponse` - For banner carousel data

### API Endpoints Added:
- `POST /cars/user/addresses` - Save user address
- `GET /cars/current/{userId}` - Get current address
- `GET /cars/user/addresses/{userId}` - Get all user addresses
- `PUT /cars/user/toggle-active` - Update address status
- `GET /banners` - Get banner carousel data

### Repository Layer:
- `NewHomeRepo` - Handles all home screen data fetching
- Proper error handling and fallbacks
- Concurrent API calls for better performance

## UI Components

### Custom Widgets:
- `NewHomeScreen` - Main home screen widget
- `ServiceCategoryCard` - Reusable service card component
- Proper Material Design components

### Styling:
- Color scheme matching the design
- Proper spacing and typography
- Responsive layout design
- Card-based UI elements

## Navigation Integration
- Updated `AuthWrapper` to use `NewHomeScreen`
- Post-OTP navigation flows to the new home screen
- Bottom navigation structure ready for future screens

## Usage

After OTP verification, users will see the new home screen with:
1. Their current address displayed
2. Search functionality for services
3. Promotional banners
4. Available service categories
5. Current offers and combos
6. Referral program information
7. Easy navigation to other app sections

## Future Enhancements
- Add actual navigation handlers for bottom tabs
- Implement address selection/change functionality
- Add service booking flows from category cards
- Integrate real banner images from API
- Add location permission handling
- Implement actual referral system

The implementation follows Flutter best practices with proper state management, error handling, and Material Design guidelines.