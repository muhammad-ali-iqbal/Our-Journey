import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/memory.dart';
import '../services/memory_service.dart';
import '../utils/app_theme.dart';
import 'memory_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizScreen extends StatefulWidget {
  final Memory memory;

  const QuizScreen({super.key, required this.memory});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  bool _answered = false;
  bool _isCorrect = false;

  late AnimationController _resultCtrl;
  late Animation<double> _resultAnim;

  @override
  void initState() {
    super.initState();
    _resultCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _resultAnim = CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _resultCtrl.dispose();
    super.dispose();
  }

  void _selectOption(int index) {
    if (_answered) return;
    setState(() => _selectedIndex = index);
  }

  Future<void> _submit() async {
    if (_selectedIndex == null) return;

    final quiz = widget.memory.quiz!;
    final isCorrect = quiz.options[_selectedIndex!].isCorrect;

    setState(() {
      _answered = true;
      _isCorrect = isCorrect;
    });

    _resultCtrl.forward();

    if (isCorrect) {
      await MemoryService().unlockMemory(widget.memory.id);
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => CorrectScreen(memory: widget.memory),
      ));
    }
  }

  void _tryAgain() {
    setState(() {
      _selectedIndex = null;
      _answered = false;
      _isCorrect = false;
    });
    _resultCtrl.reset();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.memory;
    final quiz = m.quiz!;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Stack(
        children: [
          // Photo header
          if (m.imagePaths.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 200,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPhoto(m.imagePaths.first),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.bgLight],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.85),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1), blurRadius: 8),
                  ],
                ),
                child:
                    const Icon(Icons.close, size: 18, color: Colors.black87),
              ),
            ),
          ),

          // Content
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: m.imagePaths.isNotEmpty ? 140 : 80),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Date pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          DateFormat('MMMM d, yyyy')
                              .format(m.date)
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'A Walk Down Memory Lane',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textDark,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 48,
                        height: 2,
                        color: AppColors.primary.withOpacity(0.4),
                      ),
                      const SizedBox(height: 20),

                      // Wrong answer feedback
                      if (_answered && !_isCorrect)
                        FadeTransition(
                          opacity: _resultAnim,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Not quite! Try to remember...',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.red.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),

                      // Question
                      Text(
                        '"${quiz.question}"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Options
                      ...List.generate(quiz.options.length, (i) {
                        final opt = quiz.options[i];
                        final isSelected = _selectedIndex == i;
                        final showWrong =
                            _answered && isSelected && !opt.isCorrect;
                        final showCorrect = _answered && opt.isCorrect;

                        final Color borderColor;
                        final Color bgColor;
                        if (showWrong) {
                          borderColor = Colors.red.shade400;
                          bgColor = Colors.red.shade50;
                        } else if (showCorrect) {
                          borderColor = Colors.green.shade400;
                          bgColor = Colors.green.shade50;
                        } else if (isSelected) {
                          borderColor = AppColors.primary;
                          bgColor = AppColors.primaryLight;
                        } else {
                          borderColor = Colors.grey.shade200;
                          bgColor = Colors.white;
                        }

                        return GestureDetector(
                          onTap: () => _selectOption(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: borderColor,
                                width:
                                    (isSelected || _answered) ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    opt.text,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: showWrong
                                          ? Colors.red.shade700
                                          : showCorrect
                                              ? Colors.green.shade700
                                              : AppColors.textDark,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected || showCorrect
                                          ? (showWrong
                                              ? Colors.red.shade400
                                              : AppColors.primary)
                                          : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                    color: isSelected || showCorrect
                                        ? (showWrong
                                            ? Colors.red.shade50
                                            : AppColors.primaryLight)
                                        : Colors.transparent,
                                  ),
                                  child: (isSelected || showCorrect)
                                      ? Center(
                                          child: Icon(
                                            Icons.circle,
                                            size: 10,
                                            color: showWrong
                                                ? Colors.red.shade400
                                                : AppColors.primary,
                                          ),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 20),

                      // Action button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _selectedIndex == null
                              ? null
                              : (_answered && !_isCorrect
                                  ? _tryAgain
                                  : _submit),
                          icon: Icon(
                            _answered && !_isCorrect
                                ? Icons.refresh
                                : Icons.auto_awesome,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            _answered && !_isCorrect
                                ? 'Try Again'
                                : 'Unlock Memory',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _answered && !_isCorrect
                                ? Colors.red.shade500
                                : AppColors.primary,
                            disabledBackgroundColor: Colors.grey.shade200,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding:
                                const EdgeInsets.symmetric(vertical: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'A shared history, written in the stars.',
                        style: GoogleFonts.playfairDisplay(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                          color: AppColors.textMid,
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto(String path) {
    if (path.startsWith('http')) {
      return Image.network(path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: Colors.grey.shade200));
    }
    final f = File(path);
    return f.existsSync()
        ? Image.file(f, fit: BoxFit.cover)
        : Container(color: Colors.grey.shade200);
  }
}

// ── Correct / Unlocked screen ─────────────────────────────────────────────────
class CorrectScreen extends StatefulWidget {
  final Memory memory;
  const CorrectScreen({super.key, required this.memory});

  @override
  State<CorrectScreen> createState() => _CorrectScreenState();
}

class _CorrectScreenState extends State<CorrectScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.memory;
    final hasPhoto = m.imagePaths.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              // Gold heart icon
              ScaleTransition(
                scale: _scaleAnim,
                child: const Icon(Icons.favorite,
                    color: AppColors.gold, size: 52),
              ),
              const SizedBox(height: 16),
              Text(
                'Correct!',
                style: TextStyle(
                  fontSize: 34,
                  fontStyle: FontStyle.italic,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'MEMORY UNLOCKED',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const Spacer(),

              // Memory card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (hasPhoto)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: SizedBox(
                            height: 200,
                            width: double.infinity,
                            child: _buildPhoto(m.imagePaths.first),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              m.title,
                              style: TextStyle(
                                fontSize: 22,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMMM d, yyyy')
                                  .format(m.date)
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 2.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              child: Container(
                                  height: 1,
                                  color: Colors.grey.shade200),
                            ),
                            Text(
                              '"${m.story.length > 160 ? '${m.story.substring(0, 160)}...' : m.story}"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                                height: 1.7,
                                color:
                                    AppColors.textDark.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    icon: const Icon(Icons.location_on_outlined,
                        color: Colors.white),
                    label: const Text('Back to Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(String path) {
    if (path.startsWith('http')) {
      return Image.network(path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: Colors.grey.shade200));
    }
    final f = File(path);
    return f.existsSync()
        ? Image.file(f, fit: BoxFit.cover)
        : Container(color: Colors.grey.shade200);
  }
}
