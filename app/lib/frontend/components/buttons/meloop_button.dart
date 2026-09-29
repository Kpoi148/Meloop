import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/tokens/tempo_tokens.dart';
import '../layout/meloop_icon.dart';

enum MeloopButtonStyle { primary, yellow, outline, soft, orange, danger }

class MeloopButton extends StatefulWidget {
  const MeloopButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = MeloopButtonStyle.primary,
    this.isLoading = false,
    this.loadingLabel = 'Đang lưu…',
    this.fullWidth = true,
    this.onError,
    this.prominent = false,
  });

  final String label;
  final FutureOr<void> Function()? onPressed;
  final MeloopIcons? icon;
  final MeloopButtonStyle style;
  final bool isLoading;
  final String loadingLabel;
  final bool fullWidth;
  final bool prominent;
  final void Function(Object error, StackTrace stackTrace)? onError;

  @override
  State<MeloopButton> createState() => _MeloopButtonState();
}

class _MeloopButtonState extends State<MeloopButton> {
  bool _running = false;

  Future<void> _activate() async {
    if (_running || widget.isLoading || widget.onPressed == null) return;
    // Lock synchronously, before awaiting or rebuilding the button.
    setState(() => _running = true);
    try {
      await widget.onPressed!();
    } catch (error, stackTrace) {
      if (widget.onError == null) Error.throwWithStackTrace(error, stackTrace);
      widget.onError!(error, stackTrace);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _running || widget.isLoading;
    final foreground = switch (widget.style) {
      MeloopButtonStyle.yellow ||
      MeloopButtonStyle.outline ||
      MeloopButtonStyle.soft => TempoColors.ink,
      _ => TempoColors.white,
    };
    final background = switch (widget.style) {
      MeloopButtonStyle.primary => TempoColors.teal,
      MeloopButtonStyle.yellow => TempoColors.yellow,
      MeloopButtonStyle.outline => Colors.transparent,
      MeloopButtonStyle.soft => TempoColors.soft,
      MeloopButtonStyle.orange => TempoColors.orange,
      MeloopButtonStyle.danger => TempoColors.error,
    };
    return Semantics(
      liveRegion: busy,
      child: SizedBox(
        width: widget.fullWidth ? double.infinity : null,
        child: TextButton(
          onPressed: busy || widget.onPressed == null ? null : _activate,
          style: TextButton.styleFrom(
            foregroundColor: foreground,
            backgroundColor: background,
            disabledForegroundColor: foreground.withValues(alpha: .65),
            disabledBackgroundColor: background.withValues(alpha: .5),
            minimumSize: Size(
              TempoSize.touchTarget,
              widget.prominent
                  ? TempoSize.prominentButtonMinHeight
                  : TempoSize.buttonMinHeight,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
            textStyle: widget.prominent
                ? TempoType.prominentButton
                : TempoType.button,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TempoRadius.button),
              side: widget.style == MeloopButtonStyle.outline
                  ? const BorderSide(color: TempoColors.fieldBorder)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                SizedBox.square(
                  dimension: TempoSize.buttonIcon,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              else if (widget.icon != null)
                MeloopIcon(
                  widget.icon!,
                  size: TempoSize.buttonIcon,
                  color: foreground,
                ),
              if (busy || widget.icon != null)
                const SizedBox(width: TempoSpace.sm),
              Flexible(
                child: Text(
                  busy ? widget.loadingLabel : widget.label,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
