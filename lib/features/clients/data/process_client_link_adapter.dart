import 'package:hive/hive.dart';
import '../../processes/domain/models/process_models.dart';

part 'process_client_link_adapter.g.dart';

@HiveType(typeId: 1)
class ProcessClientLinkHive extends HiveObject {
  @HiveField(0)
  String clientId;
  @HiveField(1)
  String name;
  @HiveField(2)
  String role;
  @HiveField(3)
  bool isPrimary;

  ProcessClientLinkHive({
    required this.clientId,
    required this.name,
    required this.role,
    this.isPrimary = false,
  });

  factory ProcessClientLinkHive.fromModel(ProcessClientLink model) =>
      ProcessClientLinkHive(
        clientId: model.clientId,
        name: model.name,
        role: model.role,
        isPrimary: model.isPrimary,
      );

  ProcessClientLink toModel() => ProcessClientLink(
    clientId: clientId,
    name: name,
    role: role,
    isPrimary: isPrimary,
  );
}
