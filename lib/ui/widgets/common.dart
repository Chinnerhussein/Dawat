import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/booking.dart';
import '../../data/models/planner.dart';
import '../../data/models/service.dart';
import '../../data/repositories/repositories.dart';
import '../../logic/booking_actions.dart';

extension BackendContext on BuildContext {
  Backend get backend => read<Backend>();
  BookingActions get actions => read<BookingActions>();
}

/// Shows a short message at the bottom of the screen.
void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Runs [task] and shows its error, if any, as a message.
Future<bool> runGuarded(BuildContext context, Future<void> Function() task, {String? success}) async {
  try {
    await task();
    if (success != null && context.mounted) toast(context, success);
    return true;
  } on AppException catch (e) {
    if (context.mounted) toast(context, e.message);
  } catch (e) {
    if (context.mounted) toast(context, 'Something went wrong: $e');
  }
  return false;
}

/// Subscribes to a stream once and rebuilds with each value. Change the
/// widget's key to resubscribe.
class StreamView<T> extends StatefulWidget {
  const StreamView({super.key, required this.stream, required this.builder, this.loading});

  final Stream<T> Function() stream;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loading;

  @override
  State<StreamView<T>> createState() => _StreamViewState<T>();
}

class _StreamViewState<T> extends State<StreamView<T>> {
  late final Stream<T> _stream = widget.stream();

  @override
  Widget build(BuildContext context) => StreamBuilder<T>(
    stream: _stream,
    builder: (context, snap) {
      if (snap.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load this data.\n${snap.error}',
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
          ),
        );
      }
      if (!snap.hasData) {
        return widget.loading ??
            const Center(
              child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
            );
      }
      return widget.builder(context, snap.data as T);
    },
  );
}

/// Aubergine gradient with a henna-copper glow in the top corner.
class HennaHero extends StatelessWidget {
  const HennaHero({super.key, required this.child, this.padding, this.radius = 0});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.heroTop, c.heroBottom],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.85, -1.1),
              radius: 1.1,
              colors: [c.glow.withValues(alpha: 0.45), c.glow.withValues(alpha: 0)],
            ),
          ),
          child: Padding(padding: padding ?? const EdgeInsets.all(20), child: child),
        ),
      ),
    );
  }
}

/// Text on the hero always uses the dark palette's light ink.
const heroInk = Color(0xFFF8E8DA);
const heroMuted = Color(0xFFCBB6BE);

class DawatLogo extends StatelessWidget {
  const DawatLogo({super.key, this.size = 30, this.color = heroInk});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    'Dawat',
    style: TextStyle(
      fontFamily: AppTheme.display,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w600,
      fontSize: size,
      height: 1,
      color: color,
    ),
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 12, 10),
    child: Row(
      children: [
        Expanded(child: Text(title, style: context.text.headlineSmall)),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
        Text(
          label,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color, height: 1.3),
        ),
      ],
    ),
  );
}

Color bookingColor(BuildContext context, BookingStatus s) {
  final c = context.colors;
  return switch (s) {
    BookingStatus.pending => c.warning,
    BookingStatus.accepted => c.success,
    BookingStatus.declined => c.danger,
    BookingStatus.cancelled => c.muted,
    BookingStatus.completed => c.info,
  };
}

Color rsvpColor(BuildContext context, RsvpStatus s) {
  final c = context.colors;
  return switch (s) {
    RsvpStatus.pending => c.warning,
    RsvpStatus.attending => c.success,
    RsvpStatus.declined => c.danger,
  };
}

class BookingStatusPill extends StatelessWidget {
  const BookingStatusPill(this.status, {super.key});
  final BookingStatus status;
  @override
  Widget build(BuildContext context) => StatusPill(status.label, color: bookingColor(context, status));
}

/// Gradient artwork for a service category (until providers upload photos).
class ServiceArt extends StatelessWidget {
  const ServiceArt({super.key, required this.category, this.height = 120, this.radius = 14, this.iconSize = 40});

  final ServiceCategory category;
  final double height;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = category.artColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -iconSize * 0.3,
              bottom: -iconSize * 0.35,
              child: Icon(category.icon, size: iconSize * 2.6, color: Colors.white.withValues(alpha: 0.10)),
            ),
            Center(
              child: Icon(category.icon, size: iconSize, color: Colors.white.withValues(alpha: 0.85)),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.isFavorite, required this.onPressed, this.onImage = true});
  final bool isFavorite;
  final VoidCallback onPressed;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final color = isFavorite ? context.colors.roseGold : (onImage ? Colors.white : context.colors.muted);
    final icon = Icon(isFavorite ? Icons.favorite : Icons.favorite_border, size: 20, color: color);
    return Semantics(
      button: true,
      label: isFavorite ? 'Remove from favorites' : 'Save to favorites',
      child: onImage
          ? Material(
              color: Colors.black.withValues(alpha: 0.28),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed,
                child: Padding(padding: const EdgeInsets.all(7), child: icon),
              ),
            )
          : IconButton(onPressed: onPressed, icon: icon),
    );
  }
}

class RatingText extends StatelessWidget {
  const RatingText({super.key, required this.rating, required this.count});
  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return Text('New', style: context.text.bodySmall);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 15, color: context.colors.warning),
        const SizedBox(width: 2),
        Text('${rating.toStringAsFixed(1)} ($count)', style: context.text.bodySmall),
      ],
    );
  }
}

/// Card used in the horizontal "featured" row.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    required this.onTap,
    this.isFavorite = false,
    this.onFavorite,
    this.width = 200,
  });

  final Service service;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavorite;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ServiceArt(category: service.category, height: 112, radius: 0),
                if (onFavorite != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: FavoriteButton(isFavorite: isFavorite, onPressed: onFavorite!),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 13, color: context.colors.muted),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          cityName(service.city),
                          style: context.text.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      RatingText(rating: service.rating, count: service.ratingCount),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${money(service.price)}${service.priceUnit.suffix}',
                    style: context.text.labelLarge?.copyWith(color: context.colors.roseGold),
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

/// Full-width row used in lists.
class ServiceTile extends StatelessWidget {
  const ServiceTile({
    super.key,
    required this.service,
    required this.onTap,
    this.isFavorite = false,
    this.onFavorite,
    this.trailing,
  });

  final Service service;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavorite;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(width: 92, child: ServiceArt(category: service.category, height: 92, radius: 10, iconSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.category.label.toUpperCase(),
                    style: context.text.labelSmall?.copyWith(color: context.colors.muted),
                  ),
                  const SizedBox(height: 2),
                  Text(service.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    '${service.providerName} · ${cityName(service.city)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${money(service.price)}${service.priceUnit.suffix}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelLarge?.copyWith(color: context.colors.roseGold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      RatingText(rating: service.rating, count: service.ratingCount),
                    ],
                  ),
                ],
              ),
            ),
            if (onFavorite != null) FavoriteButton(isFavorite: isFavorite, onPressed: onFavorite!, onImage: false),
            ?trailing,
          ],
        ),
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(shape: BoxShape.circle, color: context.scheme.primary.withValues(alpha: 0.12)),
            child: Icon(icon, size: 34, color: context.scheme.primary),
          ),
          const SizedBox(height: 16),
          Text(title, style: context.text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            message,
            style: context.text.bodyMedium?.copyWith(color: context.colors.muted),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 18), FilledButton(onPressed: onAction, child: Text(action!))],
        ],
      ),
    ),
  );
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, required this.icon, this.color, this.onTap});
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? context.scheme.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(height: 10),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: context.text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays stat tiles out two per row; each row is as tall as its tallest tile.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children, this.columns = 2});
  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < children.length; i += columns) ...[
        if (i > 0) const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = i; j < i + columns; j++) ...[
                if (j > i) const SizedBox(width: 10),
                Expanded(child: j < children.length ? children[j] : const SizedBox.shrink()),
              ],
            ],
          ),
        ),
      ],
    ],
  );
}

/// Circular progress with a value in the middle.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 84,
    this.stroke = 8,
    required this.center,
    this.color,
  });
  final double value;
  final double size;
  final double stroke;
  final Widget center;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _RingPainter(
        value: value.clamp(0, 1).toDouble(),
        color: color ?? context.scheme.primary,
        track: context.colors.outline,
        stroke: stroke,
      ),
      child: Center(child: center),
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.color, required this.track, required this.stroke});
  final double value;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, p..color = track);
    if (value > 0) canvas.drawArc(r, -math.pi / 2, math.pi * 2 * value, false, p..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color || old.track != track;
}

/// Thin labelled bar used for budget categories and RSVP splits.
class LabeledBar extends StatelessWidget {
  const LabeledBar({super.key, required this.value, this.color});
  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(99),
    child: LinearProgressIndicator(
      value: value.clamp(0, 1).toDouble(),
      minHeight: 6,
      color: color,
      backgroundColor: context.colors.outline,
    ),
  );
}

/// Button that shows a spinner while its async action runs.
class AsyncButton extends StatefulWidget {
  const AsyncButton({super.key, required this.label, required this.onPressed, this.icon, this.outlined = false});
  final String label;
  final Future<void> Function()? onPressed;
  final IconData? icon;
  final bool outlined;

  @override
  State<AsyncButton> createState() => _AsyncButtonState();
}

class _AsyncButtonState extends State<AsyncButton> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onPressed = widget.onPressed == null || _busy ? null : _run;
    final child = _busy
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[Icon(widget.icon, size: 19), const SizedBox(width: 8)],
              Flexible(child: Text(widget.label, overflow: TextOverflow.ellipsis)),
            ],
          );
    return widget.outlined
        ? OutlinedButton(onPressed: onPressed, child: child)
        : FilledButton(onPressed: onPressed, child: child);
  }
}

/// Asks the user to confirm an action. Returns true when confirmed.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: ctx.text.headlineSmall),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: ctx.scheme.error,
                  foregroundColor: ctx.scheme.onError,
                  minimumSize: const Size(64, 44),
                )
              : FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Unread badge for the notifications bell.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, required this.userId, required this.onPressed, this.color});
  final String userId;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) => StreamView(
    key: ValueKey('bell-$userId'),
    stream: () => context.backend.watchNotifications(userId),
    loading: IconButton(
      onPressed: onPressed,
      icon: Icon(Icons.notifications_none, color: color),
    ),
    builder: (context, list) {
      final unread = list.where((n) => !n.read).length;
      return IconButton(
        tooltip: 'Notifications',
        onPressed: onPressed,
        icon: Badge(
          isLabelVisible: unread > 0,
          label: Text('$unread'),
          backgroundColor: context.scheme.primary,
          textColor: context.scheme.onPrimary,
          child: Icon(Icons.notifications_none, color: color),
        ),
      );
    },
  );
}

/// Ensures an async callback is not started twice.
void fireAndForget(Future<void> future) => unawaited(future);
