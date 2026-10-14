class CreatePollOptionRequest {
  final String? text;
  final int? displayOrder;

  const CreatePollOptionRequest({this.text, this.displayOrder});

  Map<String, dynamic> toJson() {
    return {
      if (text != null) 'text': text,
      if (displayOrder != null) 'displayOrder': displayOrder,
    };
  }
}
