class CreatePollOptionRequest {
  final String? text;
  final String? imageId;

  const CreatePollOptionRequest({this.text, this.imageId});

  Map<String, dynamic> toJson() {
    return {
      if (text != null) 'text': text,
      if (imageId != null) 'imageId': imageId,
    };
  }
}
