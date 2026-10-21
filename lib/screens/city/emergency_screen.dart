import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/ui_kit.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  static const LinearGradient _sosGradient = LinearGradient(
    colors: [Color(0xFF7F1D1D), Color(0xFFDC2626), AppTheme.brandRose],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientHeader(
                title: 'Emergency Helplines',
                subtitle: 'One tap to call help, 24x7 across Delhi',
                icon: Icons.sos_rounded,
                gradient: _sosGradient,
                bottom: _buildHero112Banner(context),
              ),
              const SizedBox(height: 22),

              // Quick SOS grid
              const SectionHeader(
                title: 'Quick SOS',
                subtitle: 'Most-needed numbers, big and easy to reach',
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildSosTile(
                            context,
                            label: 'Ambulance',
                            number: AppConstants.ambulanceNumber,
                            icon: Icons.medical_services_rounded,
                            gradient: AppTheme.emeraldGradient,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSosTile(
                            context,
                            label: 'Fire Service',
                            number: AppConstants.fireNumber,
                            icon: Icons.local_fire_department_rounded,
                            gradient: AppTheme.sunsetGradient,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSosTile(
                            context,
                            label: 'Women in Distress',
                            number: AppConstants.delhiWomenHelpline,
                            icon: Icons.female_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFBE185D), Color(0xFFEC4899)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSosTile(
                            context,
                            label: 'Metro Helpline',
                            number: AppConstants.dmrcMetroHelpline,
                            icon: Icons.train_rounded,
                            gradient: AppTheme.transitGradient,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              // Other helplines
              const SectionHeader(
                title: 'More helplines',
                subtitle: 'Specialised support services',
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildEmergencyCard(
                      context,
                      title: 'Delhi Women in Distress',
                      number: AppConstants.delhiWomenHelpline,
                      description: '24x7 Delhi Commission for Women (DCW) emergency support',
                      icon: Icons.female_rounded,
                      color: const Color(0xFFDB2777),
                    ),
                    _buildEmergencyCard(
                      context,
                      title: 'Delhi Metro 24x7 Helpline',
                      number: AppConstants.dmrcMetroHelpline,
                      description: 'DMRC passenger assistance, lost & found, station help',
                      icon: Icons.train_rounded,
                      color: AppTheme.metroBlue,
                    ),
                    _buildEmergencyCard(
                      context,
                      title: 'Ambulance & Medical Emergency',
                      number: AppConstants.ambulanceNumber,
                      description: 'Centralized government ambulance dispatch',
                      icon: Icons.medical_services_rounded,
                      color: AppTheme.successColor,
                    ),
                    _buildEmergencyCard(
                      context,
                      title: 'Delhi Fire Service',
                      number: AppConstants.fireNumber,
                      description: 'Fire control room and rescue headquarters',
                      icon: Icons.local_fire_department_rounded,
                      color: AppTheme.metroOrange,
                    ),
                    _buildEmergencyCard(
                      context,
                      title: 'Delhi Disaster Management (DDMA)',
                      number: AppConstants.disasterHelpline,
                      description: 'Disaster response, building collapse & flood control',
                      icon: Icons.warning_rounded,
                      color: AppTheme.warningColor,
                    ),
                    _buildEmergencyCard(
                      context,
                      title: 'Women Safety Helpline',
                      number: AppConstants.womenSafetyHelpline,
                      description: 'Delhi Police women security unit',
                      icon: Icons.health_and_safety_rounded,
                      color: AppTheme.metroPurple,
                    ),
                    _buildEmergencyCard(
                      context,
                      title: 'Childline India',
                      number: AppConstants.childHelpline,
                      description: '24-hour emergency response for children in need',
                      icon: Icons.child_care_rounded,
                      color: AppTheme.infoColor,
                    ),
                    _buildEmergencyCard(
                      context,
                      title: 'Delhi Traffic Police',
                      number: AppConstants.trafficPoliceHelpline,
                      description: 'Traffic gridlock, accident reporting & breakdown',
                      icon: Icons.traffic_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    _buildEmergencyCard(
                      context,
                      title: 'Senior Citizen Helpline',
                      number: AppConstants.seniorCitizenHelpline,
                      description: 'Elderline national support & grievance helpline',
                      icon: Icons.elderly_rounded,
                      color: const Color(0xFF059669),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Major Hospital Casualty Numbers
              const SectionHeader(
                title: 'Hospital emergency wards',
                subtitle: 'Major casualty & trauma centres',
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildEmergencyCard(
                      context,
                      title: 'AIIMS Trauma Centre',
                      number: '011-26588500',
                      dial: '01126588500',
                      description: 'All India Institute of Medical Sciences Casualty',
                      icon: Icons.local_hospital_rounded,
                      color: AppTheme.errorColor,
                    ),
                    _buildEmergencyCard(
                      context,
                      title: 'Safdarjung Hospital Emergency',
                      number: '011-26165000',
                      dial: '01126165000',
                      description: 'Govt tertiary emergency & burns casualty',
                      icon: Icons.local_hospital_rounded,
                      color: AppTheme.errorColor,
                    ),
                    _buildEmergencyCard(
                      context,
                      title: 'RML Hospital (Dr. Ram Manohar Lohia)',
                      number: '011-23365525',
                      dial: '01123365525',
                      description: 'Central Delhi central government hospital casualty',
                      icon: Icons.local_hospital_rounded,
                      color: AppTheme.errorColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Emergency tips card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTipsCard(context),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        bottomNavigationBar: const AppBottomNavigation(currentIndex: 0),
      ),
    );
  }

  Widget _buildHero112Banner(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => _makeCall('112'),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.glow(Colors.black, alpha: 0.2),
                ),
                child: const Icon(Icons.emergency_rounded, color: Color(0xFFDC2626), size: 34),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '112',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
                            height: 1.05,
                          ),
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'TOLL-FREE',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'National Emergency Helpline',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Police • Fire • Ambulance • Disaster',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.call_rounded, size: 16, color: Color(0xFFDC2626)),
                    SizedBox(width: 4),
                    Text(
                      'CALL',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
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

  Widget _buildSosTile(
    BuildContext context, {
    required String label,
    required String number,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    return AppCard(
      gradient: gradient,
      radius: 22,
      padding: const EdgeInsets.all(16),
      onTap: () => _makeCall(number),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(Icons.call_rounded, size: 16, color: gradient.colors.first),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(
    BuildContext context, {
    required String title,
    required String number,
    required String description,
    required IconData icon,
    required Color color,
    String? dial,
  }) {
    final p = context.palette;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: () => _makeCall(dial ?? number),
      child: Row(
        children: [
          IconBubble(icon: icon, color: color, size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: p.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                number,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: p.tint(AppTheme.successColor),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.call_rounded, size: 12, color: AppTheme.successColor),
                    SizedBox(width: 3),
                    Text(
                      'Call',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppTheme.successColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(BuildContext context) {
    final p = context.palette;
    const tips = [
      'State your nearest metro station, landmark or road pillar number.',
      'Mention the nature of the emergency clearly (medical, crime, accident).',
      'Keep line open until dispatcher confirms police / ambulance dispatch.',
      'Inside metro stations, look for red Emergency Stop Plungers or talk to CISF security.',
    ];
    return AppCard(
      color: p.cardAlt,
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(icon: Icons.info_outline_rounded, color: AppTheme.infoColor, size: 38, radius: 12),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Crucial information when calling 112',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < tips.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.tint(AppTheme.errorColor),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.errorColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tips[i],
                      style: TextStyle(fontSize: 12.5, height: 1.45, color: p.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _makeCall(String number) async {
    final clean = number.replaceAll(RegExp(r'[^0-9]'), '');
    final url = 'tel:$clean';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
