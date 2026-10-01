import '../../l10n/app_localizations.dart';
import '../application/startup_controller.dart';
import '../components/layout/meloop_art.dart';

String instrumentLabel(AppLocalizations strings, MeloopInstrument instrument) =>
    switch (instrument) {
      MeloopInstrument.guitar => strings.instrumentGuitar,
      MeloopInstrument.piano => strings.instrumentPiano,
      MeloopInstrument.ukulele => strings.instrumentUkulele,
      MeloopInstrument.violin => strings.instrumentViolin,
      MeloopInstrument.flute => strings.instrumentFlute,
      MeloopInstrument.drums => strings.instrumentDrums,
      MeloopInstrument.other => strings.instrumentOther,
    };

String profileDisplayName(
  AppLocalizations strings,
  PreviewInstrumentProfile profile,
) {
  if (profile.name case final name? when name.trim().isNotEmpty) return name;
  return profile.instrument == MeloopInstrument.piano
      ? strings.samplePianoProfile
      : strings.defaultProfileName;
}
