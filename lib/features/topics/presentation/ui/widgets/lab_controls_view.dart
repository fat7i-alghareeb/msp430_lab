import 'package:flutter/material.dart';

import '../../labs/topic_lab.dart';

/// Buttons sized to their label: the theme's buttons are full width.
const Size compactButtonSize = Size(64, 40);

/// Draws a lab's controls the same way on every device.
class LabControlsView extends StatelessWidget {
  const LabControlsView({super.key, required this.controls});

  final List<LabControl> controls;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final c in controls)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: switch (c) {
              LabButtons() => _Buttons(c),
              LabChoice() => _Choice(c),
              LabSlider() => _Slider(c),
              LabCharField() => _CharField(c),
              LabBits() => _Bits(c),
            },
          ),
      ],
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons(this.c);

  final LabButtons c;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final b in c.buttons)
          b.primary || b.warm
              ? FilledButton(
                  onPressed: b.onTap,
                  style: FilledButton.styleFrom(
                    minimumSize: compactButtonSize,
                    backgroundColor: b.warm ? const Color(0xFFAD5C17) : null,
                  ),
                  child: Text(b.label),
                )
              : FilledButton.tonal(
                  onPressed: b.onTap,
                  style: FilledButton.styleFrom(
                    minimumSize: compactButtonSize,
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                  ),
                  child: Text(b.label),
                ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice(this.c);

  final LabChoice c;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chips = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        for (final (value, label) in c.options)
          ChoiceChip(
            label: Text(label),
            selected: value == c.value,
            showCheckmark: false,
            selectedColor: scheme.primary,
            labelStyle: TextStyle(
              color: value == c.value ? scheme.onPrimary : scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) => c.onChanged(value),
          ),
      ],
    );
    if (c.label == null) return chips;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          c.label!,
          textDirection: TextDirection.ltr,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        chips,
      ],
    );
  }
}

class _Slider extends StatelessWidget {
  const _Slider(this.c);

  final LabSlider c;

  @override
  Widget build(BuildContext context) {
    final shown = c.max <= 10 ? c.value.toStringAsFixed(2) : c.value.round().toString();
    return Row(
      children: <Widget>[
        Text(c.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(
          child: Slider(
            min: c.min,
            max: c.max,
            divisions: c.divisions,
            value: c.value.clamp(c.min, c.max),
            onChanged: c.onChanged,
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(shown, textDirection: TextDirection.ltr, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

class _CharField extends StatefulWidget {
  const _CharField(this.c);

  final LabCharField c;

  @override
  State<_CharField> createState() => _CharFieldState();
}

class _CharFieldState extends State<_CharField> {
  late final TextEditingController _text = TextEditingController(text: widget.c.value);

  @override
  void didUpdateWidget(covariant _CharField old) {
    super.didUpdateWidget(old);
    if (widget.c.value != _text.text && _text.text.isNotEmpty) {
      _text.text = widget.c.value;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Text('الحرف المرسل', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 10),
        SizedBox(
          width: 56,
          child: TextField(
            controller: _text,
            maxLength: 1,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              counterText: '',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: widget.c.onChanged,
          ),
        ),
      ],
    );
  }
}

class _Bits extends StatelessWidget {
  const _Bits(this.c);

  final LabBits c;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Wrap(
        spacing: 3,
        runSpacing: 3,
        children: <Widget>[
          for (var i = 0; i < c.bits.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: BoxDecoration(
                color: i == c.current
                    ? const Color(0xFFF2B000)
                    : i < c.current
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                c.bits[i],
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Consolas',
                  fontFamilyFallback: const <String>['Menlo', 'monospace'],
                  color: i < c.current ? scheme.primary : scheme.onSurface,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
