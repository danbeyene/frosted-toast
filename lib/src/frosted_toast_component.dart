import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

part 'frosted_toast_service.dart';

class FrostedToastOptions {
  final String message;
  final Alignment alignment;
  final bool isDarkBackground;
  final EdgeInsets insetsPadding;
  final Widget? child;
  final Duration duration;
  final bool autoDismiss;
  final void Function(_FrostedToastComponentState state)? onInit;

  const FrostedToastOptions({
    this.message = '',
    this.alignment = Alignment.bottomCenter,
    this.isDarkBackground = true,
    this.insetsPadding = const EdgeInsets.symmetric(horizontal: 8),
    this.child,
    this.duration = const Duration(seconds: 3),
    this.autoDismiss = true,
    this.onInit,
  });
}

class FrostedToastComponent extends StatefulWidget {
  final FrostedToastOptions options;
  final VoidCallback onDismiss;

  const FrostedToastComponent({
    super.key,
    required this.options,
    required this.onDismiss,
  });

  @override
  State<FrostedToastComponent> createState() => _FrostedToastComponentState();
}

class _FrostedToastComponentState extends State<FrostedToastComponent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;

  FrostedToastOptions get options => widget.options;
  bool isBottomPosition = false;

  @override
  void initState() {
    super.initState();
    isBottomPosition = options.alignment.y > 0;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, isBottomPosition ? 1 : -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    options.onInit?.call(this);
    _animationController.forward();

    if (options.autoDismiss) {
      _dismissTimer = Timer(options.duration, _safeDismiss);
    }
  }

  void _safeDismiss() async {
    if (!mounted) return;
    
    try {
      await _animationController.reverse();
      if (mounted) {
        widget.onDismiss();
      }
    } catch (e) {
      // If there's an error with the animation, still call onDismiss
      if (mounted) {
        widget.onDismiss();
      }
    }
  }

  void dismiss() {
    _safeDismiss();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = options.isDarkBackground;

    return SafeArea(
      child: Container(
        alignment: widget.options.alignment,
        margin: widget.options.insetsPadding,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.5)
                        : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.5)
                          : Colors.grey.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: options.child ??
                            Text(
                              widget.options.message,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                      ),
                      GestureDetector(
                        onTap: dismiss,
                        child: Icon(
                          Icons.close,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}