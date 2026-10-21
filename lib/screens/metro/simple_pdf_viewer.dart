import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';
import '../../widgets/ui_kit.dart';

class SimplePDFViewer extends StatefulWidget {
  final String pdfPath;
  final String title;

  const SimplePDFViewer({
    super.key,
    required this.pdfPath,
    required this.title,
  });

  @override
  State<SimplePDFViewer> createState() => _SimplePDFViewerState();
}

class _SimplePDFViewerState extends State<SimplePDFViewer> {
  Future<void> _openOfficialMap() async {
    const url = 'https://www.delhimetrorail.com/network_map';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open external browser.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              GradientHeader(
                title: widget.title,
                subtitle: 'Official DMRC network schematic',
                icon: Icons.map_rounded,
                gradient: AppTheme.royalGradient,
                illustration: 'assets/images/illus_explore.svg',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                child: Column(
                  children: [
                    // Hero Visual Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: AppTheme.heroGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppTheme.glow(AppTheme.brandViolet, alpha: 0.3),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Opacity(
                              opacity: 0.55,
                              child: SvgPicture.asset('assets/images/hero_skyline.svg', fit: BoxFit.fitWidth),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                  ),
                                  child: const Icon(Icons.map_rounded, size: 28, color: Colors.white),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Delhi Metro Network Map',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'The official, always up-to-date DMRC network schematic with every line, station and interchange. Opens on the DMRC website in your browser (internet needed).',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.82),
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 70),

                                // Open High-Res Map Button
                                GradientButton(
                                  label: 'Open Official DMRC Map',
                                  icon: Icons.open_in_new_rounded,
                                  onPressed: _openOfficialMap,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Key Highlights Card
                    AppCard(
                      radius: 24,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Network highlights',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: p.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildHighlightRow('12 Metro Lines', 'Including Airport Express & Rapid Metro', Icons.linear_scale_rounded, AppTheme.metroYellow),
                          _buildHighlightRow('28 Interchange Stations', 'Easy seamless transfer between lines', Icons.swap_calls_rounded, AppTheme.successColor),
                          _buildHighlightRow('Airport Express Direct', 'New Delhi to IGI T3 in 19 minutes', Icons.flight_takeoff_rounded, AppTheme.metroOrange),
                          _buildHighlightRow('First & Last Train', 'Generally 05:30 AM to 11:30 PM', Icons.schedule_rounded, AppTheme.primaryColor),
                        ],
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

  Widget _buildHighlightRow(String title, String desc, IconData icon, Color color) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          IconBubble(icon: icon, color: color, size: 42, radius: 13),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: p.textPrimary),
                ),
                const SizedBox(height: 1),
                Text(
                  desc,
                  style: TextStyle(fontSize: 11.5, color: p.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
