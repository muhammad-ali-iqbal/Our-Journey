import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/memory.dart';
import '../services/memory_service.dart';
import '../utils/app_theme.dart';
import 'memory_saved_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class AddMemoryScreen extends StatefulWidget {
  final Memory? existingMemory;
  const AddMemoryScreen({super.key, this.existingMemory});

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final _titleCtrl = TextEditingController();
  final _storyCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _quizQuestionCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls =
      List.generate(4, (_) => TextEditingController());

  DateTime _selectedDate = DateTime.now();
  int _correctOptionIndex = 0;
  final List<File> _selectedImages = [];
  bool _isSaving = false;

  final _picker = ImagePicker();

  bool get _isEditing => widget.existingMemory != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if editing
    final m = widget.existingMemory;
    if (m != null) {
      _titleCtrl.text = m.title;
      _storyCtrl.text = m.story;
      _locationCtrl.text = m.locationName;
      _selectedDate = m.date;
      if (m.quiz != null) {
        _quizQuestionCtrl.text = m.quiz!.question;
        for (int i = 0; i < m.quiz!.options.length && i < 4; i++) {
          _optionCtrls[i].text = m.quiz!.options[i].text;
          if (m.quiz!.options[i].isCorrect) _correctOptionIndex = i;
        }
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _storyCtrl.dispose();
    _locationCtrl.dispose();
    _quizQuestionCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickImage() async {
    try {
      final results = await _picker.pickMultiImage(imageQuality: 85);
      if (results.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(results.map((x) => File(x.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final story = _storyCtrl.text.trim();
    final location = _locationCtrl.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a title for this memory.')),
      );
      return;
    }

    MemoryQuiz? quiz;
    final question = _quizQuestionCtrl.text.trim();
    final options = _optionCtrls.map((c) => c.text.trim()).toList();
    final filledOptions = options.where((o) => o.isNotEmpty).toList();

    if (question.isNotEmpty && filledOptions.length >= 2) {
      quiz = MemoryQuiz(
        question: question,
        options: List.generate(
          options.length,
          (i) => QuizOption(
            text: options[i],
            isCorrect: i == _correctOptionIndex,
          ),
        ).where((o) => o.text.isNotEmpty).toList(),
      );
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        // Update existing memory
        final updated = widget.existingMemory!.copyWith(
          title: title,
          story: story,
          locationName: location,
          date: _selectedDate,
          quiz: quiz,
          isUnlocked: quiz == null ? true : widget.existingMemory!.isUnlocked,
        );
        await MemoryService().updateMemory(updated);
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Memory updated!')),
        );
      } else {
        // Create new memory
        final memory = Memory(
          id: const Uuid().v4(),
          title: title,
          story: story,
          locationName: location,
          date: _selectedDate,
          imagePaths: const [],
          quiz: quiz,
          isUnlocked: quiz == null,
          createdAt: DateTime.now(),
        );

        final saved = await MemoryService().saveMemory(
          memory: memory,
          localImages: _selectedImages,
        );

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MemorySavedScreen(memory: saved)),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving memory: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Sticky top bar ─────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.bgLight,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                titleSpacing: 0,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                ),
                title: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close,
                          color: AppColors.textDark, size: 22),
                    ),
                    const Expanded(
                      child: Text(
                        'Our Map',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 18,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _isSaving ? null : _save,
                      child: Text(
                        'SAVE',
                        style: TextStyle(
                          color: _isSaving
                              ? AppColors.primary.withOpacity(0.4)
                              : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),

                      // ══ STEP ONE: TITLE & STORY ══════════════════════
                      _SectionHeader(
                        step: 'STEP ONE',
                        title: "What's the title\nof this story?",
                        subtitle: 'Capture the essence of your journey in a few words.',
                      ),
                      const SizedBox(height: 28),

                      _FieldLabel('HEADING'),
                      const SizedBox(height: 8),
                      _StyledTextField(
                        controller: _titleCtrl,
                        hint: 'Summer in the Amalfi Coast',
                        useSerif: true,
                        fontSize: 20,
                      ),
                      const SizedBox(height: 20),

                      _FieldLabel('THE STORY'),
                      const SizedBox(height: 8),
                      _StyledTextField(
                        controller: _storyCtrl,
                        hint: 'Describe the scent of the lemons, the warmth of the sun, and the shared laughter...',
                        maxLines: 6,
                        fontSize: 15,
                      ),

                      // ── Section divider ───────────────────────────────
                      const _SectionDivider(),

                      // ══ STEP TWO: LOCATION & DATE ════════════════════
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Where did it happen?',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 18,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pin this memory to your map',
                                  style: TextStyle(
                                    color: AppColors.textMid,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_on,
                                      size: 13, color: AppColors.primary),
                                  const SizedBox(width: 5),
                                  Text(
                                    _formatDate(_selectedDate),
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _StyledTextField(
                        controller: _locationCtrl,
                        hint: 'e.g. Positano, Italy',
                        prefixIcon: Icons.location_on,
                        fontSize: 15,
                      ),
                      const SizedBox(height: 12),

                      // ── Section divider ───────────────────────────────
                      const _SectionDivider(),

                      // ══ MEMORY QUIZ ══════════════════════════════════
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Memory Quiz',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create a fun challenge for your future self',
                              style: TextStyle(
                                  color: AppColors.textMid, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _FieldLabel('MEMORY QUESTION'),
                      const SizedBox(height: 8),
                      _StyledTextField(
                        controller: _quizQuestionCtrl,
                        hint: 'What was the first thing I said...',
                        useSerif: true,
                        fontSize: 17,
                      ),
                      const SizedBox(height: 20),

                      _FieldLabel('MULTIPLE CHOICE ANSWERS'),
                      const SizedBox(height: 4),
                      Text(
                        'Tap ✓ to mark the correct answer',
                        style: TextStyle(
                            color: AppColors.textMid, fontSize: 12),
                      ),
                      const SizedBox(height: 12),

                      ...List.generate(
                        4,
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AnswerOptionRow(
                            controller: _optionCtrls[i],
                            index: i,
                            isCorrect: _correctOptionIndex == i,
                            onMarkCorrect: () =>
                                setState(() => _correctOptionIndex = i),
                          ),
                        ),
                      ),

                      // ── Section divider ───────────────────────────────
                      const _SectionDivider(),

                      // ══ VISUAL KEEPSAKES ══════════════════════════════
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Visual Keepsakes',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add photos to bring your story to life',
                              style: TextStyle(
                                  color: AppColors.textMid, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      _PhotoGrid(
                        images: _selectedImages,
                        onAdd: _pickImage,
                        onRemove: (i) =>
                            setState(() => _selectedImages.removeAt(i)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Fixed bottom save bar ──────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          _isEditing ? 'UPDATE' : 'SAVE',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),

          // Gold accent bottom line
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.gold,
                  AppColors.primary,
                  AppColors.gold,
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(step,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            )),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            color: AppColors.textDark,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMid,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 3,
        ),
      );
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Divider(color: AppColors.primary.withOpacity(0.07)),
      );
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool useSerif;
  final double fontSize;
  final IconData? prefixIcon;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.useSerif = false,
    this.fontSize = 15,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = useSerif
        ? GoogleFonts.playfairDisplay(
            fontSize: fontSize,
            color: AppColors.textDark,
            height: maxLines > 1 ? 1.6 : null,
          )
        : TextStyle(
            fontSize: fontSize,
            color: AppColors.textDark,
            height: maxLines > 1 ? 1.6 : null,
          );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
          BorderSide(color: AppColors.primary.withOpacity(0.1)),
    );
    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary),
    );

    return TextField(
      controller: controller,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      style: baseStyle,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: baseStyle.copyWith(
          color: AppColors.textMid.withOpacity(0.35),
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.primary, size: 20)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: maxLines > 1 ? 18 : 16,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: focusBorder,
      ),
    );
  }
}

class _AnswerOptionRow extends StatelessWidget {
  final TextEditingController controller;
  final int index;
  final bool isCorrect;
  final VoidCallback onMarkCorrect;

  const _AnswerOptionRow({
    required this.controller,
    required this.index,
    required this.isCorrect,
    required this.onMarkCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.primary.withOpacity(0.1)),
    );

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'Option ${index + 1}',
              hintStyle: TextStyle(
                  color: AppColors.textMid.withOpacity(0.35), fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: border,
              enabledBorder: border,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onMarkCorrect,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isCorrect
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.2),
                width: 2,
              ),
              color: isCorrect
                  ? AppColors.primary.withOpacity(0.08)
                  : Colors.transparent,
            ),
            child: isCorrect
                ? const Icon(Icons.check, color: AppColors.primary, size: 18)
                : null,
          ),
        ),
      ],
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<File> images;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _PhotoGrid({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: images.length + 1,
      itemBuilder: (context, i) {
        if (i == images.length) {
          return GestureDetector(
            onTap: onAdd,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.25),
                  width: 1.5,
                ),
                color: AppColors.primary.withOpacity(0.04),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo,
                      color: AppColors.primary, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    'UPLOAD\nPHOTO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primary.withOpacity(0.7),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(images[i], fit: BoxFit.cover),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => onRemove(i),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4),
                    ],
                  ),
                  child: const Icon(Icons.close,
                      color: AppColors.textDark, size: 13),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
