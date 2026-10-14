class CompleteMediaUploadRequest {
  final int selectionVersion;

  const CompleteMediaUploadRequest({required this.selectionVersion});

  Map<String, dynamic> toJson() {
    return {'selectionVersion': selectionVersion};
  }
}
