# Delhi Travel Guide 🚇🚌🚖

A comprehensive Flutter mobile app designed to help people in Delhi travel and navigate the city more easily. The app provides real-time information about metro, bus services, and other transport options with detailed route planning, fare calculation, and city assistance features.

## Features

### 🚇 Metro Features
- **Fare Calculator** – Enter starting and destination metro stations to get exact fare
- **Route Finder** – Find the fastest metro route with line changes and journey time
- **Live Updates** – Real-time status of delays, closures, or maintenance
- **Nearest Station** – Detect the nearest metro station using GPS

### 🚌 Bus Features
- **Route Finder** – Find available bus routes between locations
- **Stop Locator** – Show nearest bus stops on the map
- **Live Timing** – Expected arrival times for buses
- **Stop Information** – Details about facilities and available buses

### 🚖 Other Transport Options
- **Auto & Cab Fare Estimator** – Approximate cost of autos and cabs
- **Cycle/Scooter Rentals** – Integration with bike sharing services
- **Transport Options** – Comprehensive list of available transport modes

### 📍 General City Assistance
- **Tourist Spots & Maps** – Information about monuments, markets, and attractions
- **Emergency Numbers** – Quick dial for police, ambulance, women's helpline
- **Weather Updates** – Current weather and Air Quality Index (AQI) in Delhi

## Screenshots

The app features a modern, intuitive interface with:
- Clean Material Design 3 UI
- Color-coded metro lines
- Real-time updates and notifications
- GPS-based location services
- Comprehensive city information

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code
- Android device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/delhi-travel-guide.git
   cd delhi-travel-guide
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Configuration

The app requires the following permissions:
- **Location** - To find nearest stations and stops
- **Internet** - For real-time updates and weather data
- **Phone** - For emergency number dialing

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── metro_station.dart
│   ├── metro_route.dart
│   ├── bus_station.dart
│   └── weather_data.dart
├── providers/                # State management
│   ├── location_provider.dart
│   ├── metro_provider.dart
│   ├── bus_provider.dart
│   └── weather_provider.dart
├── services/                 # API services
│   ├── metro_service.dart
│   ├── bus_service.dart
│   └── weather_service.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── metro/
│   ├── bus/
│   ├── transport/
│   └── city/
├── widgets/                  # Reusable widgets
│   └── feature_card.dart
└── utils/
    └── app_theme.dart        # App theming
```

## Dependencies

- **flutter** - UI framework
- **provider** - State management
- **go_router** - Navigation
- **geolocator** - Location services
- **geocoding** - Address geocoding
- **google_maps_flutter** - Maps integration
- **http** - API calls
- **shared_preferences** - Local storage
- **url_launcher** - External links
- **permission_handler** - Permission management

## Features in Detail

### Metro Services
- Complete Delhi Metro network coverage
- Real-time fare calculation based on distance
- Route optimization with interchange information
- Live updates for delays and maintenance
- GPS-based nearest station detection

### Bus Services
- Comprehensive bus stop database
- Route planning with multiple options
- Real-time bus timing information
- Stop facilities and bus availability
- Distance-based stop recommendations

### Transport Options
- Auto rickshaw fare estimation
- Cab service integration (Uber, Ola)
- Bike sharing services (Yulu, Rapido)
- Comprehensive transport comparison

### City Assistance
- Tourist attraction database
- Emergency contact integration
- Weather and air quality monitoring
- Location-based recommendations

## API Integration

The app is designed to integrate with:
- Delhi Metro API (for real-time updates)
- DTC Bus API (for live timings)
- Weather API (for current conditions)
- Maps API (for navigation)

*Note: Currently uses mock data for demonstration purposes*

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Delhi Metro Rail Corporation (DMRC)
- Delhi Transport Corporation (DTC)
- Flutter community
- Material Design team

## Contact

For questions or support, please contact:
- Email: support@delhitravelguide.com
- GitHub Issues: [Create an issue](https://github.com/yourusername/delhi-travel-guide/issues)

---

**Made with ❤️ for Delhi travelers**

