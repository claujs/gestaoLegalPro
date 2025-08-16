import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';
import '../../domain/services/document_service.dart';

class DocumentServiceImpl implements DocumentService {
  @override
  Future<DocumentData?> pickDocumentFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
        withData: true, // necessário para Web
      );

      if (result != null && result.files.isNotEmpty) {
        final f = result.files.single;
        final name = f.name;
        final ext = (f.extension ?? name.split('.').last).toLowerCase();
        final bytes = f.bytes;
        if (bytes == null) {
          // No Web não há path; exigimos bytes.
          throw Exception(
            'Não foi possível obter bytes do arquivo selecionado. No Web, ative withData ou selecione um arquivo menor.',
          );
        }

        return DocumentData(
          name: name,
          extension: ext,
          bytes: bytes,
          path: null, // não acessar f.path no Web
        );
      }
      return null;
    } catch (e) {
      print('Erro ao selecionar arquivo: $e');
      return null;
    }
  }

  @override
  Future<String> extractTextFromDocument(DocumentData document) async {
    switch (document.extension) {
      case 'pdf':
        return await _extractTextFromPdf(document.bytes);
      case 'docx':
        return await _extractTextFromDocx(document.bytes);
      case 'doc':
        return await _extractTextFromDoc(document);
      default:
        throw Exception(
          'Formato de arquivo não suportado: ${document.extension}',
        );
    }
  }

  Future<String> _extractTextFromPdf(List<int> bytes) async {
    try {
      final document = PdfDocument(inputBytes: bytes);

      String fullText = '';

      // Extrai texto de cada página
      for (int i = 0; i < document.pages.count; i++) {
        final textExtractor = PdfTextExtractor(document);
        final pageText = textExtractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        );

        if (pageText.isNotEmpty) {
          fullText += pageText;
          if (i < document.pages.count - 1) {
            fullText += '\n\n'; // Separador entre páginas
          }
        }
      }

      document.dispose();

      if (fullText.trim().isEmpty) {
        throw Exception('Não foi possível extrair texto do PDF');
      }

      return fullText.trim();
    } catch (e) {
      print('Erro ao extrair texto do PDF: $e');
      throw Exception('Erro ao processar PDF: ${e.toString()}');
    }
  }

  Future<String> _extractTextFromDocx(List<int> bytes) async {
    try {
      final text = docxToText(Uint8List.fromList(bytes));

      if (text.trim().isEmpty) {
        throw Exception('Não foi possível extrair texto do documento DOCX');
      }

      return text.trim();
    } catch (e) {
      print('Erro ao extrair texto do DOCX: $e');
      throw Exception('Erro ao processar DOCX: ${e.toString()}');
    }
  }

  Future<String> _extractTextFromDoc(DocumentData document) async {
    // Para arquivos .doc (formato antigo), vamos sugerir conversão para .docx
    // ou usar uma biblioteca específica. Por agora, retornamos uma mensagem explicativa.
    throw Exception(
      'Arquivos .doc (formato antigo) não são suportados diretamente. '
      'Por favor, converta para .docx ou use PDF.',
    );
  }
}
