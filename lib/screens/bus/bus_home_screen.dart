import 'package:flutter/material.dart';

import 'professional_bus_home_screen.dart';

/// Legacy entry point kept for compatibility. The old version ran on a small
/// hardcoded dataset; the bus home is now [ProfessionalBusHomeScreen], backed
/// by the full Delhi GTFS network via `BusProvider`.
class BusHomeScreen extends StatelessWidget {
  const BusHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const ProfessionalBusHomeScreen();
}
