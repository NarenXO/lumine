import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReflectTranscript extends StatelessWidget {
  final String? userText;
  final String livePartial;
  final String? lumineReply;
  final String emptyPrompt;
  final String emptySub;
  final ScrollController? scrollController;

  const ReflectTranscript({
    super.key,
    this.userText,
    this.livePartial = '',
    this.lumineReply,
    this.emptyPrompt = "Share what's on your heart.",
    this.emptySub = "Lumíne listens deeply.",
    this.scrollController,
  });

  static const Color muted = Color(0xFF9CA3AF);
  static const Color emphasis = Color(0xFF1A1A1A);

  String get _displayUser {
    final base = userText ?? '';
    if (livePartial.isEmpty) return base;
    if (base.isEmpty) return livePartial;
    return '$base $livePartial';
  }

  @override
  Widget build(BuildContext context) {
    final full = _displayUser.trim();
    final hasUser = full.isNotEmpty;
    final hasReply = lumineReply != null && lumineReply!.trim().isNotEmpty;

    if (!hasUser && !hasReply) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emptyPrompt,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                color: emphasis.withOpacity(0.45),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptySub,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: muted,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (hasUser) _buildUserBlock(full, livePartial.trim().isNotEmpty),
          if (hasReply) ...[
            const SizedBox(height: 20),
            Text(
              lumineReply!,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 17,
                height: 1.45,
                color: emphasis.withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserBlock(String full, bool isLive) {
    if (!isLive || full.length < 8) {
      return Text(
        full,
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          height: 1.45,
          color: emphasis,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final words = full.split(RegExp(r'\s+'));
    if (words.length <= 3) {
      return Text(
        full,
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          height: 1.45,
          color: emphasis,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final boldCount = (words.length * 0.35).ceil().clamp(2, 6);
    final mutedPart = words.sublist(0, words.length - boldCount).join(' ');
    final boldPart = words.sublist(words.length - boldCount).join(' ');

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          height: 1.45,
        ),
        children: [
          TextSpan(
            text: '$mutedPart ',
            style: const TextStyle(color: muted, fontWeight: FontWeight.w400),
          ),
          TextSpan(
            text: boldPart,
            style: const TextStyle(color: emphasis, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
