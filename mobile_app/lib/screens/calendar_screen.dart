import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/calendar_service.dart';
import '../services/tts_service.dart';
import '../services/app_controller.dart';
import '../services/theme_service.dart';
import '../services/app_theme.dart';
import '../widgets/lumine_background.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  bool _signedIn = false;
  bool _loading = false;
  List<Map<String, dynamic>> _events = [];
  Map<String, dynamic>? _imminentEvent;
  Timer? _checkTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _checkSignIn();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _checkSignIn() {
    setState(() => _signedIn = CalendarService.isSignedIn);
    if (_signedIn) {
      _loadEvents();
      _startEventMonitoring();
    }
  }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    final success = await CalendarService.signIn();
    setState(() {
      _loading = false;
      _signedIn = success;
    });
    if (success) {
      _loadEvents();
      _startEventMonitoring();
    }
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    final events = await CalendarService.getUpcomingEvents();
    final imminent = await CalendarService.getImminentEvent();
    if (mounted) {
      setState(() {
        _events = events;
        _imminentEvent = imminent;
        _loading = false;
      });
      if (imminent != null) _triggerPreEventIntervention(imminent);
      CalendarService.scheduleEventNotifications();
    }
  }

  void _startEventMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(
        const Duration(minutes: 5), (_) => _loadEvents());
  }

  void _triggerPreEventIntervention(Map<String, dynamic> event) async {
    AppController().setEmotion('stressed');
    final title = event['title'] as String;
    final minutes = event['minutesUntil'] as int;
    final scripture = CalendarService.getEventScripture(title);
    final message = CalendarService.getLumineMessage(title, minutes);
    await TtsService.speak('$message $scripture');
    if (mounted) _showInterventionBanner(title, message, scripture, minutes);
  }

  void _showInterventionBanner(
      String eventTitle, String message, String scripture, int minutes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.bgSlate,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: AppTheme.bgSlateGlow),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderSoft,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'PREPARING FOR',
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppTheme.goldMid.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              eventTitle,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.manrope(
                fontSize: 14,
                height: 1.6,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '"$scripture"',
              style: GoogleFonts.literata(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: AppTheme.textPrimary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.goldMid.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.goldMid.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text(
                    'I am ready.',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.goldMid,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          const Positioned.fill(child: LumineBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 30),
                  if (!_signedIn)
                    Expanded(child: _buildSignInPrompt())
                  else ...[
                    if (_imminentEvent != null) ...[
                      _buildImminentCard(),
                      const SizedBox(height: 16),
                    ],
                    _buildSectionHeader("Today's Schedule"),
                    const SizedBox(height: 12),
                    Expanded(child: _buildEventList()),
                    _buildFooterActions(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calendar',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Lumíne walks ahead of you.',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.bgSlate,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderSoft),
            ),
            child: Icon(Icons.arrow_back_rounded,
                color: AppTheme.textSecondary, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInPrompt() {
    return Center(
      child: _CalendarBentoBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) {
                return Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.bgSlateHigh,
                    border: Border.all(
                      color: AppTheme.goldMid.withOpacity(
                          0.3 + _pulseController.value * 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldMid.withOpacity(
                            0.1 + _pulseController.value * 0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(Icons.calendar_month_rounded,
                      size: 32, color: AppTheme.goldMid),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Connect your calendar so Lumíne can speak before your important moments.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _loading ? null : _signIn,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.goldMid.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.goldMid.withOpacity(0.4)),
                ),
                child: Center(
                  child: _loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppTheme.goldMid,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link_rounded,
                                color: AppTheme.goldMid, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Connect Google Calendar',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.goldMid,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildImminentCard() {
    final title = _imminentEvent!['title'] as String;
    final minutes = _imminentEvent!['minutesUntil'] as int;

    return _CalendarBentoBox(
      accentColor: const Color(0xFFFFA560),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COMING SOON',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: const Color(0xFFFFA560),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA560).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFFFA560).withOpacity(0.3)),
                ),
                child: Text(
                  '${minutes}m away',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFFA560),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"${CalendarService.getEventScripture(title)}"',
            style: GoogleFonts.literata(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildEventList() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.goldMid,
          strokeWidth: 2,
        ),
      );
    }

    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_rounded,
                color: AppTheme.textTertiary, size: 40),
            const SizedBox(height: 12),
            Text(
              'No events today.',
              style: GoogleFonts.manrope(
                  fontSize: 14, color: AppTheme.textTertiary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        final minutes = event['minutesUntil'] as int;
if (minutes < 0) return const SizedBox.shrink();
final isNext = index == 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _CalendarBentoBox(
            accentColor: isNext ? AppTheme.goldMid : null,
            child: Row(
              children: [
                // Time pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSlateHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSoft),
                  ),
                  child: Text(
                   minutes < 60
    ? '${minutes}m'
    : '${(minutes / 60).floor()}h ${minutes % 60}m',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['title'],
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"${CalendarService.getEventScripture(event['title'])}"',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.literata(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isNext)
                  Icon(Icons.chevron_right_rounded,
                      color: AppTheme.goldMid.withOpacity(0.6), size: 20),
              ],
            ),
          ).animate().fadeIn(delay: (index * 80).ms),
        );
      },
    );
  }

  Widget _buildFooterActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _loadEvents,
            child: Row(
              children: [
                Icon(Icons.refresh_rounded,
                    color: AppTheme.textTertiary, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Refresh',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              await CalendarService.signOut();
              setState(() => _signedIn = false);
            },
            child: Text(
              'Disconnect',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: const Color(0xFFE85D5D).withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.cormorantGaramond(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// CALENDAR BENTO BOX
// ══════════════════════════════════════════════════════════════════
class _CalendarBentoBox extends StatelessWidget {
  final Widget child;
  final Color? accentColor;

  const _CalendarBentoBox({required this.child, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppTheme.bgSlateGlow;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgSlate,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.bgSlateGlow.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: accent.withOpacity(0.06),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}