import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// ORIA Chat — assistant IA.
/// Empty state central (4 suggestions) + bulles user (bleu, align right) vs ORIA (gris, align left + avatar) + barre saisie pill collée bottom.
class OriaScreen extends StatefulWidget {
  final String? initialPrompt;
  const OriaScreen({super.key, this.initialPrompt});

  @override
  State<OriaScreen> createState() => _OriaScreenState();
}

class _OriaScreenState extends State<OriaScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Message> _messages = [];
  String? _sessionId;
  bool _sending = false;
  bool _hasUserInput = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasUserInput) {
        setState(() => _hasUserInput = has);
      }
    });
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.text = widget.initialPrompt!;
        _send();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(_Message(role: _Role.user, text: text));
      _sending = true;
    });
    _controller.clear();
    HapticFeedback.selectionClick();
    _scrollToBottom();

    try {
      final api = ApiService();
      final res = await api.envoyerMessageOria(text, sessionId: _sessionId);
      final reply = (res['reponse'] ??
              res['message'] ??
              res['content'] ??
              res['reply'] ??
              'Pas de réponse') as String;
      _sessionId = (res['sessionId'] ?? _sessionId) as String?;
      if (!mounted) return;
      setState(() {
        _messages.add(
          _Message(
            role: _Role.oria,
            text: reply,
            suggestions: _extractFollowups(res),
          ),
        );
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _Message(
            role: _Role.oria,
            text: 'Oups, une erreur est survenue. Réessaye dans quelques secondes.',
            isError: true,
          ),
        );
        _sending = false;
      });
      _scrollToBottom();
    }
  }

  List<String> _extractFollowups(Map<String, dynamic> res) {
    final raw = res['suggestions'] ?? res['followups'] ?? res['propositions'];
    if (raw is List) {
      return raw.map((e) => e.toString()).take(3).toList();
    }
    return const [];
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('ORIA', style: AppTextStyles.headingMedium),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.textDark),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      itemCount: _messages.length + (_sending ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _messages.length) {
                          return _buildTypingIndicator();
                        }
                        return _buildMessageBubble(_messages[i]);
                      },
                    ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(painter: _OriaLogoPainter()),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Comment puis-je\nt\'aider ?',
            style: AppTextStyles.displayLarge.copyWith(fontSize: 28),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Choisis une suggestion ou écris ta question',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          // Grille 2x2
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            children: [
              _SuggestionTile(
                emoji: '📊',
                label: 'Comparer 2 filières',
                color: AppColors.primary,
                onTap: () {
                  _controller.text = 'Comparer 2 filières';
                  _send();
                },
              ),
              _SuggestionTile(
                emoji: '📍',
                label: 'École à Lomé',
                color: AppColors.success,
                onTap: () {
                  _controller.text = 'Trouver une école à Lomé';
                  _send();
                },
              ),
              _SuggestionTile(
                emoji: '🧠',
                label: 'Mon profil RIASEC',
                color: AppColors.accent,
                onTap: () {
                  _controller.text = 'Comprendre mon profil RIASEC';
                  _send();
                },
              ),
              _SuggestionTile(
                emoji: '💼',
                label: 'Préparer un entretien',
                color: const Color(0xFFEC4899),
                onTap: () {
                  _controller.text = 'Préparer un entretien d\'embauche';
                  _send();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_Message msg) {
    final isUser = msg.role == _Role.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const _OriaAvatar(),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.messageBubbleUser
                        : (msg.isError
                            ? AppColors.error.withOpacity(0.10)
                            : AppColors.messageBubbleAI),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppSpacing.radiusLg),
                      topRight: const Radius.circular(AppSpacing.radiusLg),
                      bottomLeft: Radius.circular(
                          isUser ? AppSpacing.radiusLg : 6),
                      bottomRight: Radius.circular(
                          isUser ? 6 : AppSpacing.radiusLg),
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isUser
                          ? Colors.white
                          : (msg.isError ? AppColors.error : AppColors.textDark),
                      height: 1.4,
                    ),
                  ),
                ),
                if (!isUser && msg.suggestions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: msg.suggestions
                        .map((s) => GestureDetector(
                              onTap: () {
                                _controller.text = s;
                                _send();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppColors.borderSubtle),
                                ),
                                child: Text(
                                  s,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          const _OriaAvatar(),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.messageBubbleAI,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const _AnimatedDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {},
              child: const Icon(Icons.mic_none,
                  color: AppColors.textLight, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Demande à ORIA…',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textLight),
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _hasUserInput
                    ? AppColors.primary
                    : AppColors.borderSubtle,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: _hasUserInput ? _send : null,
                icon: const Icon(
                  Icons.arrow_upward,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Modèle interne ────────────────────────────────────────────────────────

class _Role {
  static const _Role user = _Role._('user');
  static const _Role oria = _Role._('oria');
  final String name;
  const _Role._(this.name);
}

class _Message {
  final _Role role;
  final String text;
  final List<String> suggestions;
  final bool isError;
  _Message({
    required this.role,
    required this.text,
    this.suggestions = const [],
    this.isError = false,
  });
}

class _OriaAvatar extends StatelessWidget {
  const _OriaAvatar();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = ((_ctrl.value - i * 0.2) % 1.0).clamp(0.0, 1.0);
            final phase = (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.textMedium.withOpacity(0.3 + 0.7 * phase),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.label.copyWith(color: AppColors.textDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OriaLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.gradientStart, AppColors.gradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: size.width));
    // Étoile 8 branches (spark)
    final path = Path();
    final r1 = size.width * 0.45;
    final r2 = size.width * 0.18;
    for (int i = 0; i < 8; i++) {
      final r = i.isEven ? r1 : r2;
      final a = (i / 8) * 2 * math.pi - math.pi / 2; // start en haut
      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
