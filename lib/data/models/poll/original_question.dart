/// The card a question was copied from (a fun card, a "Questions worth asking" card). The create sheet keeps it so
/// an edited copy can be put back to this original with Reset.
class OriginalQuestion {
  const OriginalQuestion({required this.question, required this.options});

  final String question;
  final List<String> options;
}
