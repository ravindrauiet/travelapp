import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/metro_provider.dart';
import '../../models/metro_station.dart';
import '../../utils/app_theme.dart';

class MetroLiveUpdatesScreen extends StatefulWidget {
  const MetroLiveUpdatesScreen({super.key});

  @override
  State<MetroLiveUpdatesScreen> createState() => _MetroLiveUpdatesScreenState();
}

class _MetroLiveUpdatesScreenState extends State<MetroLiveUpdatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MetroProvider>().loadLiveUpdates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Metro Updates'),
        backgroundColor: AppTheme.metroGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<MetroProvider>().loadLiveUpdates();
            },
          ),
        ],
      ),
      body: Consumer<MetroProvider>(
        builder: (context, metroProvider, child) {
          if (metroProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (metroProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    metroProvider.error!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      metroProvider.clearError();
                      metroProvider.loadLiveUpdates();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (metroProvider.liveUpdates.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'All metro services are running normally',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No delays or disruptions reported',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await metroProvider.loadLiveUpdates();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: metroProvider.liveUpdates.length,
              itemBuilder: (context, index) {
                final update = metroProvider.liveUpdates[index];
                return _buildUpdateCard(update);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpdateCard(MetroUpdate update) {
    Color cardColor;
    Color iconColor;
    IconData icon;

    switch (update.severity) {
      case 'high':
        cardColor = Colors.red.withOpacity(0.1);
        iconColor = Colors.red;
        icon = Icons.warning;
        break;
      case 'medium':
        cardColor = Colors.orange.withOpacity(0.1);
        iconColor = Colors.orange;
        icon = Icons.info;
        break;
      default:
        cardColor = Colors.blue.withOpacity(0.1);
        iconColor = Colors.blue;
        icon = Icons.info_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: cardColor,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          update.stationName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getTimeAgo(update.timestamp),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      update.severity.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Text(
                update.message,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Icon(
                    _getTypeIcon(update.type),
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getTypeText(update.type),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${update.timestamp.hour.toString().padLeft(2, '0')}:${update.timestamp.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'delay':
        return Icons.schedule;
      case 'closure':
        return Icons.block;
      case 'maintenance':
        return Icons.build;
      default:
        return Icons.info;
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'delay':
        return 'Delay';
      case 'closure':
        return 'Closure';
      case 'maintenance':
        return 'Maintenance';
      default:
        return 'Update';
    }
  }
}
