abstract class DocumentService {
  Future<String?> pickDocumentFile();
  Future<String> extractTextFromDocument(String filePath);
}
