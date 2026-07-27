import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/calendar_service.dart';
import '../services/tts_service.dart';
import '../services/app_controller.dart';
import '../services/theme_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _signedIn = false;
  bool _loading = false;
  List<Map<String, dynamic>> _events = [];
  Map<String, dynamic>? _imminentEvent;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    _checkSignIn();
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
    }
  }

  void _startEventMonitoring() {
    _checkTimer?.cancel();
    _checkTimer =
        Timer.periodic(const Duration(minutes: 5), (_) => _loadEvents());
  }

  void _triggerPreEventIntervention(Map<String, dynamic> event) async {
    AppController().setEmotion("stressed");
    final title = event['title'] as String;
    final minutes = event['minutesUntil'] as int;
    final scripture = CalendarService.getEventScripture(title);
    final message = CalendarService.getLumineMessage(title, minutes);
    await TtsService.speak("$message $scripture");
    if (mounted) _showInterventionBanner(title, message, scripture, minutes);
  }

  void _showInterventionBanner(
      String eventTitle, String message, String scripture, int minutes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("✦ PREPARING FOR",
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.black38)),
              const SizedBox(height: 8),
              Text(eventTitle,
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text(message,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, height: 1.6, color: Colors.black87)),
              const SizedBox(height: 16),
              Text('"$scripture"',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54)),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder()),
                  child: const Text("I am ready."),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const CalendarMeshBackground(),
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
                    _buildSignInPrompt()
                  else ...[
                    if (_imminentEvent != null) _buildImminentCard(),
                    const SizedBox(height: 20),
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
            Text("Calendar",
                style: GoogleFonts.playfairDisplay(
                    fontSize: 32, fontWeight: FontWeight.bold)),
            Text("Lumíne walks ahead of you.",
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: Colors.black45)),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.black45, size: 18),
        ),
      ],
    );
  }

  Widget _buildSignInPrompt() {
    return CalendarBentoCard(
      child: Column(
        children: [
          const Icon(Icons.calendar_today_rounded,
              size: 50, color: Colors.black12),
          const SizedBox(height: 20),
          Text(
            "Connect your calendar so Lumíne can speak before your important moments.",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, color: Colors.black54, height: 1.6),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _loading ? null : _signIn,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder()),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Connect Google Calendar"),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildImminentCard() {
    final title = _imminentEvent!['title'] as String;
    return CalendarBentoCard(
      padding: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("COMING SOON",
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Colors.indigoAccent)),
              Text("${_imminentEvent!['minutesUntil']}m",
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black38)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '"${CalendarService.getEventScripture(title)}"',
            style: GoogleFonts.playfairDisplay(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: Colors.black54),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildEventList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_events.isEmpty) {
      return Center(
          child: Text("No events today.",
              style: GoogleFonts.plusJakartaSans(color: Colors.black26)));
    }

    return ListView.builder(
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CalendarBentoCard(
            padding: 20,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event['title'],
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '"${CalendarService.getEventScripture(event['title'])}"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: Colors.black38),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text("${event['minutesUntil']}m",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black26)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooterActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
              onPressed: _loadEvents,
              child: Text("Refresh",
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black45))),
          TextButton(
              onPressed: () async {
                await CalendarService.signOut();
                setState(() => _signedIn = false);
              },
              child: Text("Disconnect",
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: Colors.black26))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title,
        style: GoogleFonts.playfairDisplay(
            fontSize: 22, fontWeight: FontWeight.bold));
  }
}

class CalendarBentoCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final double padding;
  const CalendarBentoCard(
      {super.key, required this.child, this.height, this.padding = 24});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ]),
      child: child,
    );
  }
}

class CalendarMeshBackground extends StatelessWidget {
  const CalendarMeshBackground({super.key});
  @override
  Widget build(BuildContext context) {
       return AnimatedContainer(
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      color: ThemeService.getEmotionColor(),
      child: Stack(
        children: [
          Positioned(
              top: -50,
              right: -50,
              child: _glow(const Color(0xFFFDE047).withOpacity(0.2))),
          Positioned(
              bottom: 100,
              left: -50,
              child: _glow(const Color(0xFFFBCFE8).withOpacity(0.3))),
        ],
      ),
    );
  }

  Widget _glow(Color c) => Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: 30, duration: 5.seconds);
}