import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../l10n/l10n.dart';
import '../../theme/tokens/tempo_tokens.dart';
import '../inputs/meloop_field.dart';
import '../layout/meloop_icon.dart';

/// Optional 1–5 self rating. Tapping the active value clears it to null.
class MeloopRating extends FormField<int> {
  MeloopRating({
    super.key,
    required String label,
    required ValueChanged<int?> onChanged,
    super.initialValue,
    super.enabled = true,
    bool mood = true,
  }) : super(
         builder: (field) => Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             MeloopFieldLabel(
               label: label,
               requirement: MeloopFieldRequirement.optional,
             ),
             const SizedBox(height: TempoSpace.sm),
             Row(
               spacing: TempoSpace.sm,
               children: [
                 for (var i = 1; i <= 5; i++)
                   Expanded(
                     child: Semantics(
                       label: field.context.l10n.ratingSemantics(label, i),
                       selected: field.value == i,
                       button: true,
                       child: Material(
                         color: field.value == i
                             ? TempoColors.selection
                             : TempoColors.fieldFill,
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(
                             TempoRadius.field,
                           ),
                           side: BorderSide(
                             color: field.value == i
                                 ? TempoColors.teal
                                 : TempoColors.line,
                             width: field.value == i ? 2 : 1,
                           ),
                         ),
                         child: InkWell(
                           borderRadius: BorderRadius.circular(
                             TempoRadius.field,
                           ),
                           onTap: !field.widget.enabled
                               ? null
                               : () {
                                   final next = field.value == i ? null : i;
                                   field.didChange(next);
                                   onChanged(next);
                                 },
                           child: Padding(
                             padding: const EdgeInsets.symmetric(vertical: 8),
                             child: Column(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 if (mood)
                                   SvgPicture.asset(
                                     'assets/icons/mood-$i.svg',
                                     width: 27,
                                     height: 27,
                                     excludeFromSemantics: true,
                                     colorFilter: const ColorFilter.mode(
                                       TempoColors.ink,
                                       BlendMode.srcIn,
                                     ),
                                   )
                                 else
                                   const MeloopIcon(
                                     MeloopIcons.target,
                                     size: 27,
                                   ),
                                 const SizedBox(height: 3),
                                 ExcludeSemantics(
                                   child: Text('$i', style: TempoType.caption),
                                 ),
                               ],
                             ),
                           ),
                         ),
                       ),
                     ),
                   ),
               ],
             ),
             const SizedBox(height: TempoSpace.xs),
             Text(
               mood
                   ? field.context.l10n.moodRatingHint
                   : field.context.l10n.focusRatingHint,
               style: TempoType.caption.copyWith(color: TempoColors.muted),
             ),
           ],
         ),
       );
}
