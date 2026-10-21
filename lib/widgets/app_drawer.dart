import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../providers/theme_provider.dart';
import 'ui_kit.dart';

class AppDrawer extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color primaryColor;
  final Color secondaryColor;

  const AppDrawer({
    super.key,
    required this.title,
    required this.subtitle,
    this.primaryColor = AppTheme.primaryColor,
    this.secondaryColor = AppTheme.secondaryColor,
  });

  void _go(BuildContext context, String route) {
    Navigator.pop(context);
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Drawer(
      backgroundColor: p.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              children: [
                const _DrawerSectionLabel('Travel'),
                _DrawerItem(
                  icon: Icons.home_rounded,
                  color: AppTheme.accentColor,
                  label: 'Home',
                  onTap: () => _go(context, '/'),
                ),
                _DrawerItem(
                  icon: Icons.train_rounded,
                  color: AppTheme.metroBlue,
                  label: 'Metro Services',
                  onTap: () => _go(context, '/metro'),
                ),
                _DrawerItem(
                  icon: Icons.directions_bus_rounded,
                  color: AppTheme.metroGreen,
                  label: 'Bus Guide & Tracking',
                  onTap: () => _go(context, '/bus'),
                ),
                _DrawerItem(
                  icon: Icons.local_taxi_rounded,
                  color: AppTheme.metroOrange,
                  label: 'Auto & Cab Fares',
                  onTap: () => _go(context, '/transport'),
                ),
                const _DrawerSectionLabel('City'),
                _DrawerItem(
                  icon: Icons.wb_sunny_rounded,
                  color: AppTheme.warningColor,
                  label: 'Weather & Air Quality (AQI)',
                  onTap: () => _go(context, '/weather'),
                ),
                _DrawerItem(
                  icon: Icons.tour_rounded,
                  color: AppTheme.metroPurple,
                  label: 'Tourist Spots',
                  badge: '${AppConstants.touristSpotsCount}',
                  onTap: () => _go(context, '/tourist-spots'),
                ),
                _DrawerItem(
                  icon: Icons.emergency_rounded,
                  color: AppTheme.errorColor,
                  label: 'Emergency Helplines',
                  badge: '112',
                  onTap: () => _go(context, '/emergency'),
                ),
                const _DrawerSectionLabel('Fun'),
                _DrawerItem(
                  icon: Icons.sports_esports_rounded,
                  color: AppTheme.brandViolet,
                  label: 'Commute Games',
                  onTap: () => _go(context, '/games'),
                ),
                const _DrawerSectionLabel('Settings'),
                const _ThemeModeSelector(),
                const SizedBox(height: 6),
                _DrawerItem(
                  icon: Icons.privacy_tip_rounded,
                  color: AppTheme.infoColor,
                  label: 'Privacy Policy',
                  trailingIcon: Icons.open_in_new_rounded,
                  onTap: () {
                    // The drawer is gone once the URL check finishes; use the
                    // navigator's context for the fallback dialog.
                    final hostContext = Navigator.of(context).context;
                    Navigator.pop(context);
                    _openPrivacyPolicy(hostContext);
                  },
                ),
                _DrawerItem(
                  icon: Icons.info_rounded,
                  color: AppTheme.metroGrey,
                  label: 'About & Disclaimers',
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.3,
              child: SvgPicture.asset(
                'assets/images/hero_skyline.svg',
                height: 84,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                      ),
                      child: SvgPicture.asset('assets/images/logo.svg', width: 44, height: 44),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const TagPill(
                  label: 'DELHI NCR • METRO & BUS',
                  color: Colors.white,
                  icon: Icons.location_on_rounded,
                  onDark: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: p.border)),
        ),
        child: Row(
          children: [
            const Icon(Icons.favorite_rounded, size: 14, color: AppTheme.brandRose),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Made for Delhi commuters',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: p.textTertiary, fontWeight: FontWeight.w600),
              ),
            ),
            TagPill(label: 'v${AppConstants.appVersion}', color: p.primary),
          ],
        ),
      ),
    );
  }

  void _openPrivacyPolicy(BuildContext context) async {
    final uri = Uri.parse(AppConstants.privacyPolicyUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        _showLocalPrivacyDialog(context);
      }
    } catch (_) {
      if (context.mounted) _showLocalPrivacyDialog(context);
    }
  }

  void _showLocalPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            IconBubble(icon: Icons.privacy_tip_rounded, color: AppTheme.infoColor, size: 38, radius: 12),
            SizedBox(width: 10),
            Expanded(child: Text('Privacy Policy')),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Metromate respects your privacy.\n\n'
            '• Location Data: Used solely on-device to locate nearest metro/bus stations and follow active commutes. Location data is never stored on external servers or sold to third parties.\n\n'
            '• Transit Data: Bus telemetry is read directly from Delhi Government Open Transit Data feeds.\n\n'
            '• No Third-Party Tracking: We do not profile users or track personal identifiers.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final p = context.palette;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              SvgPicture.asset('assets/images/logo.svg', width: 36, height: 36),
              const SizedBox(width: 10),
              const Expanded(child: Text('Metromate')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TagPill(label: 'VERSION ${AppConstants.appVersion}', color: p.primary),
                const SizedBox(height: 12),
                Text(
                  'Your smart travel companion for Delhi NCR. Plan routes, calculate accurate fares, explore bus stops, and follow station sequences.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: p.textSecondary),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.tint(AppTheme.warningColor),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.warningColor),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Important Disclaimer',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.warningColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Metromate is an independent transit navigation guide. It is not affiliated with, authorized, endorsed by, or in any way officially connected with the Delhi Metro Rail Corporation (DMRC), Delhi Transport Corporation (DTC), or the Government of NCT of Delhi.',
                        style: TextStyle(fontSize: 11, color: p.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Transit Data Sources:',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: p.textPrimary),
                ),
                const SizedBox(height: 8),
                _buildSourceLink(
                  context,
                  'Delhi Open Transit Data (otd.delhi.gov.in)',
                  AppConstants.otdPortalUrl,
                ),
                const SizedBox(height: 4),
                _buildSourceLink(
                  context,
                  'Delhi Metro Rail Corporation (DMRC)',
                  'https://www.delhimetrorail.com',
                ),
                const SizedBox(height: 4),
                _buildSourceLink(
                  context,
                  'Delhi Transport Corporation (DTC)',
                  'https://www.dtc.nic.in',
                ),
                const SizedBox(height: 12),
                Divider(color: p.border),
                const SizedBox(height: 4),
                _buildSourceLink(
                  context,
                  'Privacy Policy',
                  AppConstants.privacyPolicyUrl,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSourceLink(BuildContext context, String label, String url) {
    final linkColor = context.palette.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.link_rounded, size: 14, color: linkColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: linkColor,
                  decoration: TextDecoration.underline,
                  decorationColor: linkColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  final String label;
  const _DrawerSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: context.palette.textTertiary,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String? badge;
  final IconData? trailingIcon;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.badge,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: [
                IconBubble(icon: icon, color: color, size: 38, radius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  TagPill(label: badge!, color: color),
                ],
                const SizedBox(width: 6),
                Icon(trailingIcon ?? Icons.chevron_right_rounded, size: 18, color: p.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Light / Dark / Auto segmented control backed by [ThemeProvider].
class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.border),
            boxShadow: p.shadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBubble(icon: themeProvider.themeIcon, color: p.primary, size: 34, radius: 10),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Theme: ${themeProvider.themeModeName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: p.cardAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _segment(context, themeProvider, ThemeMode.light, Icons.light_mode_rounded, 'Light'),
                    _segment(context, themeProvider, ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
                    _segment(context, themeProvider, ThemeMode.system, Icons.brightness_auto_rounded, 'Auto'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _segment(
    BuildContext context,
    ThemeProvider provider,
    ThemeMode mode,
    IconData icon,
    String label,
  ) {
    final p = context.palette;
    final selected = provider.themeMode == mode;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => provider.setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            gradient: selected ? AppTheme.heroGradient : null,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected ? AppTheme.glow(AppTheme.brandIndigo, alpha: 0.3) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: selected ? Colors.white : p.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : p.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
