import 'package:flexi_board/flexi_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Bright, airy palette — cool sky into soft mint (not purple / cream kitsch).
const _sky = Color(0xFFE7F3FB);
const _mist = Color(0xFFF3FBF0);
const _foam = Color(0xFFFFFFFF);
const _ink = Color(0xFF143042);
const _muted = Color(0xFF5B7384);
const _accent = Color(0xFF0F8A7A);
const _accentSoft = Color(0xFFD7F3EE);
const _line = Color(0xFFD5E4EE);
const _high = Color(0xFFE4572E);
const _mid = Color(0xFFD4A017);
const _low = Color(0xFF2A9D8F);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const FlexiBoardExampleApp());
}

class FlexiBoardExampleApp extends StatelessWidget {
  const FlexiBoardExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'PlusJakartaSans',
    );
    final textTheme = base.textTheme.apply(
      bodyColor: _ink,
      displayColor: _ink,
      fontFamily: 'PlusJakartaSans',
    );

    return MaterialApp(
      title: 'FlexiBoard',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: _sky,
        colorScheme: const ColorScheme.light(
          primary: _accent,
          onPrimary: _foam,
          secondary: _accentSoft,
          onSecondary: _ink,
          surface: _foam,
          onSurface: _ink,
          outline: _line,
        ),
        textTheme: textTheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: _ink,
          titleTextStyle: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: _ink,
            height: 1.1,
          ),
        ),
      ),
      home: const ExampleHome(),
    );
  }
}

class ExampleHome extends StatefulWidget {
  const ExampleHome({super.key});

  @override
  State<ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<ExampleHome>
    with SingleTickerProviderStateMixin {
  late final FlexiBoardController<Task> _controller;
  late final AnimationController _intro;
  FlexiBoardLayout _layout = FlexiBoardLayout.tabs;
  bool _useCustomCards = true;

  @override
  void initState() {
    super.initState();
    _controller = FlexiBoardController<Task>(initial: _buildWorkspace());
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(fade);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_sky, Color(0xFFEEF8F4), _mist],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopBar(
                        canUndo: _controller.canUndo,
                        canRedo: _controller.canRedo,
                        onUndo: _controller.undo,
                        onRedo: _controller.redo,
                        customCards: _useCustomCards,
                        onToggleCards: () {
                          setState(() => _useCustomCards = !_useCustomCards);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Drag cards across boards. Long-press to lift.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: _muted,
                                      height: 1.35,
                                    ),
                              ),
                            ),
                            _LayoutSwitcher(
                              layout: _layout,
                              onChanged: (layout) =>
                                  setState(() => _layout = layout),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _foam.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _line.withValues(alpha: 0.8),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF143042)
                                      .withValues(alpha: 0.06),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: FlexiBoard<Task>(
                                controller: _controller,
                                layout: _layout,
                                physics: FlexiBoardPhysics.snappy,
                                theme: _boardTheme,
                                cardBuilder:
                                    _useCustomCards ? _buildCustomCard : null,
                                columnHeaderBuilder: _buildColumnHeader,
                                columnFooterBuilder: _buildColumnFooter,
                                boardTabBuilder: _buildTab,
                                emptyColumnBuilder: _buildEmptyColumn,
                                onDrag: (details) {
                                  debugPrint(
                                    'drag ${details.phase.name} '
                                    '${details.card.data.title}',
                                  );
                                },
                                onDrop: (details) {
                                  debugPrint(
                                    'drop accepted=${details.accepted} '
                                    '${details.card.data.title}',
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  FlexiBoardTheme get _boardTheme => const FlexiBoardTheme(
        boardBackgroundColor: Color(0x00FFFFFF),
        columnBackgroundColor: Color(0xFFF7FBFD),
        columnHeaderColor: Color(0xFFF0F7FA),
        cardBackgroundColor: _foam,
        cardBorderColor: _line,
        placeholderColor: Color(0x330F8A7A),
        rejectedColor: Color(0x33E4572E),
        wipWarningColor: _mid,
        wipExceededColor: _high,
        tabSelectedColor: _accentSoft,
        tabUnselectedColor: Color(0xFFEAF2F7),
        columnBorderRadius: 16,
        cardBorderRadius: 14,
        cardElevation: 0,
      );

  Widget _buildTab(
    BuildContext context,
    FlexiBoardBoard<Task> board,
    bool selected,
    bool dragHover,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: dragHover
            ? _accent.withValues(alpha: 0.16)
            : selected
                ? _accentSoft
                : const Color(0xFFEAF2F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected || dragHover ? _accent.withValues(alpha: 0.35) : _line,
        ),
      ),
      child: Text(
        board.title,
        style: TextStyle(
                  fontFamily: 'PlusJakartaSans', 
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: _ink,
          fontSize: 13.5,
        ),
      ),
    );
  }

  Widget _buildColumnHeader(BuildContext context, FlexiBoardColumn<Task> column) {
    final limit = column.wipLimit;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              column.title,
              style: TextStyle(
                  fontFamily: 'PlusJakartaSans', 
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _ink,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: column.isAtWipLimit
                  ? _high.withValues(alpha: 0.12)
                  : const Color(0xFFEAF2F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              limit == null
                  ? '${column.cardCount}'
                  : '${column.cardCount}/$limit',
              style: TextStyle(
                  fontFamily: 'PlusJakartaSans', 
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: column.isAtWipLimit ? _high : _muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnFooter(BuildContext context, FlexiBoardColumn<Task> column) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: _accent,
          alignment: Alignment.centerLeft,
        ),
        onPressed: () {
          _controller.addCard(
            boardId: _controller.activeBoardId,
            columnId: column.id,
            card: FlexiBoardCard(
              id: 'new_${DateTime.now().millisecondsSinceEpoch}',
              data: Task(
                title: 'New task',
                priority: Priority.medium,
                tag: 'Fresh',
              ),
            ),
          );
          setState(() {});
        },
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Add card'),
      ),
    );
  }

  Widget _buildEmptyColumn(BuildContext context, FlexiBoardColumn<Task> column) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
      child: Text(
        'Drop here',
        textAlign: TextAlign.center,
        style: TextStyle(
                  fontFamily: 'PlusJakartaSans', 
          color: _muted.withValues(alpha: 0.8),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildCustomCard(
    BuildContext context,
    FlexiBoardCard<Task> card,
    FlexiBoardCardDragDetails details,
  ) {
    final priority = card.data.priority;
    final accent = switch (priority) {
      Priority.high => _high,
      Priority.medium => _mid,
      Priority.low => _low,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: _foam,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: details.isDragging
              ? _accent.withValues(alpha: 0.45)
              : _line,
        ),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: details.isDragging ? 0.12 : 0.04),
            blurRadius: details.isDragging ? 18 : 10,
            offset: Offset(0, details.isDragging ? 8 : 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                priority.label,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans', 
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accent,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            card.data.title,
            style: TextStyle(
                  fontFamily: 'PlusJakartaSans', 
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _ink,
              height: 1.3,
            ),
          ),
          if (card.data.tag != null) ...[
            const SizedBox(height: 10),
            Text(
              card.data.tag!,
              style: TextStyle(
                  fontFamily: 'PlusJakartaSans', 
                fontSize: 11.5,
                color: _muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.customCards,
    required this.onToggleCards,
  });

  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool customCards;
  final VoidCallback onToggleCards;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF19A394), Color(0xFF3DB8D0)],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.view_kanban_rounded, color: _foam, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FlexiBoard',
                  style: TextStyle(
                    fontFamily: 'Fraunces', 
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                    height: 1.05,
                  ),
                ),
                Text(
                  'Multi-board DnD demo',
                  style: TextStyle(
                  fontFamily: 'PlusJakartaSans', 
                    fontSize: 12.5,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
          _IconAction(
            tooltip: 'Undo',
            icon: Icons.undo_rounded,
            onPressed: canUndo ? onUndo : null,
          ),
          _IconAction(
            tooltip: 'Redo',
            icon: Icons.redo_rounded,
            onPressed: canRedo ? onRedo : null,
          ),
          _IconAction(
            tooltip: customCards ? 'Default cards' : 'Custom cards',
            icon: customCards
                ? Icons.auto_awesome_rounded
                : Icons.crop_square_rounded,
            onPressed: onToggleCards,
            active: customCards,
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.active = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: active ? _accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                icon,
                size: 20,
                color: onPressed == null
                    ? _muted.withValues(alpha: 0.35)
                    : active
                        ? _accent
                        : _ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LayoutSwitcher extends StatelessWidget {
  const _LayoutSwitcher({
    required this.layout,
    required this.onChanged,
  });

  final FlexiBoardLayout layout;
  final ValueChanged<FlexiBoardLayout> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <(FlexiBoardLayout, String, IconData)>[
      (FlexiBoardLayout.single, 'One', Icons.crop_portrait_rounded),
      (FlexiBoardLayout.tabs, 'Tabs', Icons.tab_rounded),
      (FlexiBoardLayout.sideBySide, 'Split', Icons.view_column_rounded),
      (FlexiBoardLayout.paged, 'Paged', Icons.view_carousel_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _foam.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in items)
            _LayoutChip(
              label: item.$2,
              icon: item.$3,
              selected: layout == item.$1,
              onTap: () => onChanged(item.$1),
            ),
        ],
      ),
    );
  }
}

class _LayoutChip extends StatelessWidget {
  const _LayoutChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Icon(icon, size: 15, color: selected ? _accent : _muted),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans', 
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? _ink : _muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum Priority { low, medium, high }

extension on Priority {
  String get label => switch (this) {
        Priority.high => 'High',
        Priority.medium => 'Medium',
        Priority.low => 'Low',
      };
}

class Task {
  Task({
    required this.title,
    required this.priority,
    this.tag,
  });

  final String title;
  final Priority priority;
  final String? tag;

  @override
  String toString() => title;
}

FlexiBoardWorkspace<Task> _buildWorkspace() {
  return FlexiBoardWorkspace<Task>(
    activeBoardId: 'product',
    boards: [
      FlexiBoardBoard<Task>(
        id: 'product',
        title: 'Product',
        columns: [
          FlexiBoardColumn<Task>(
            id: 'backlog',
            title: 'Backlog',
            cards: [
              FlexiBoardCard(
                id: 'p1',
                data: Task(
                  title: 'Research competitors',
                  priority: Priority.low,
                  tag: 'Discovery',
                ),
              ),
              FlexiBoardCard(
                id: 'p2',
                data: Task(
                  title: 'Draft product brief',
                  priority: Priority.medium,
                  tag: 'Writing',
                ),
              ),
            ],
          ),
          FlexiBoardColumn<Task>(
            id: 'doing',
            title: 'In Progress',
            wipLimit: 2,
            cards: [
              FlexiBoardCard(
                id: 'p3',
                data: Task(
                  title: 'Prototype drag physics',
                  priority: Priority.high,
                  tag: 'Engineering',
                ),
              ),
            ],
          ),
          const FlexiBoardColumn<Task>(
            id: 'done',
            title: 'Done',
          ),
        ],
      ),
      FlexiBoardBoard<Task>(
        id: 'marketing',
        title: 'Marketing',
        columns: [
          FlexiBoardColumn<Task>(
            id: 'ideas',
            title: 'Ideas',
            cards: [
              FlexiBoardCard(
                id: 'm1',
                data: Task(
                  title: 'Launch announcement',
                  priority: Priority.medium,
                  tag: 'Social',
                ),
              ),
            ],
          ),
          const FlexiBoardColumn<Task>(
            id: 'scheduled',
            title: 'Scheduled',
            wipLimit: 3,
          ),
        ],
      ),
    ],
  );
}
