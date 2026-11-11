import '../data/models.dart';
import 'formatters.dart';

/// Estado visible de un cliente. No elimina datos ni modifica SQLite.
/// Un inactivo automático puede volver a figurar activo al renovar su cuota.
enum ClientActivity {
  vigente,
  pendiente,
  inactivoAutomatico,
  inactivoManual,
}

extension ClientActivityLabels on ClientActivity {
  bool get isInactive =>
      this == ClientActivity.inactivoAutomatico ||
      this == ClientActivity.inactivoManual;

  String get label {
    switch (this) {
      case ClientActivity.vigente:
        return 'Vigente';
      case ClientActivity.pendiente:
        return 'Pendiente';
      case ClientActivity.inactivoAutomatico:
      case ClientActivity.inactivoManual:
        return 'Inactivo';
    }
  }
}

/// Calcula estado a partir de la fecha de vencimiento (no de asistencia).
/// El día de vencimiento cuenta como vigente. Luego figura pendiente
/// durante el plazo de tolerancia; recién DESPUÉS pasa a inactivo.
/// Sin un pago/vencimiento previo se mantiene pendiente, no inactivo.
ClientActivity clientActivity(
  StudioClient client, {
  required DateTime today,
  required int inactiveAfterDays,
}) {
  if (!client.active) return ClientActivity.inactivoManual;
  final due = client.dueDate;
  if (due == null) return ClientActivity.pendiente;
  final pastDue = day(today).difference(day(due)).inDays;
  if (pastDue <= 0) return ClientActivity.vigente;
  if (pastDue > inactiveAfterDays) return ClientActivity.inactivoAutomatico;
  return ClientActivity.pendiente;
}

enum ClientListFilter { active, inactive, all }

extension ClientListFilterSelection on ClientListFilter {
  String get label {
    switch (this) {
      case ClientListFilter.active: return 'Activos';
      case ClientListFilter.inactive: return 'Ver inactivos';
      case ClientListFilter.all: return 'Incluir inactivos';
    }
  }
  bool includes(ClientActivity status) {
    switch (this) {
      case ClientListFilter.active: return !status.isInactive;
      case ClientListFilter.inactive: return status.isInactive;
      case ClientListFilter.all: return true;
    }
  }
}
