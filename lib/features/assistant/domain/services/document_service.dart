import 'dart:typed_data';

class DocumentData {
  final String name;
  final String extension; // minúscula, ex: 'pdf', 'docx', 'doc'
  final Uint8List bytes;
  final String? path; // pode ser null no Web

  DocumentData({
    required this.name,
    required this.extension,
    required this.bytes,
    this.path,
  });
}

abstract class DocumentService {
  Future<DocumentData?> pickDocumentFile();
  Future<String> extractTextFromDocument(DocumentData document);
}
