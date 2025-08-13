import 'package:get/get.dart';

/// Base para ViewModels usando GetX, oferecendo estados comuns.
abstract class BaseViewModel extends GetxController {
  final isLoading = false.obs;
  final error = RxnString();

  void setLoading(bool v) => isLoading.value = v;
  void setError(String? message) => error.value = message;
  void clearError() => error.value = null;
}
