class CreateMediaUploadSessionRequest {
  final String mediaType;
  final String contentType;
  final String? fileName;
  final int? fileSize;
  final int selectionVersion;
  final String? pollId;

  const CreateMediaUploadSessionRequest({
    required this.mediaType,
    required this.contentType,
    required this.selectionVersion,
    this.fileName,
    this.fileSize,
    this.pollId,
  });

  Map<String, dynamic> toJson() {
    return {
      'mediaType': mediaType,
      'contentType': contentType,
      'selectionVersion': selectionVersion,
      if (fileName != null && fileName!.isNotEmpty) 'fileName': fileName,
      if (fileSize != null) 'fileSize': fileSize,
      if (pollId != null && pollId!.isNotEmpty) 'pollId': pollId,
    };
  }
}
