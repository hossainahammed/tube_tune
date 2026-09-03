/// Model representing a single closed caption / subtitle cue.
class SubtitleModel {
  final Duration start;
  final Duration end;
  final String text;

  const SubtitleModel({
    required this.start,
    required this.end,
    required this.text,
  });
}
