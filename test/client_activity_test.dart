import 'package:flutter_test/flutter_test.dart';
import 'package:gym_system_management_lite/core/client_activity.dart';
import 'package:gym_system_management_lite/data/models.dart';

void main() {
  StudioClient client({DateTime? due, bool active = true}) => StudioClient(
    id: 1, name: 'María Villafañez', active: active,
    dueDate: due, createdAt: '2026-01-01T00:00:00Z');

  const limit = 30;
  final today = DateTime(2026, 11, 11);

  test('Los filtros muestran solo activos, solo inactivos o todos', () {
    expect(ClientListFilter.active.includes(ClientActivity.vigente), isTrue);
    expect(ClientListFilter.active.includes(ClientActivity.pendiente), isTrue);
    expect(ClientListFilter.active.includes(ClientActivity.inactivoAutomatico), isFalse);
    expect(ClientListFilter.active.includes(ClientActivity.inactivoManual), isFalse);
    expect(ClientListFilter.inactive.includes(ClientActivity.vigente), isFalse);
    expect(ClientListFilter.inactive.includes(ClientActivity.inactivoAutomatico), isTrue);
    expect(ClientListFilter.inactive.includes(ClientActivity.inactivoManual), isTrue);
    for (final status in ClientActivity.values) {
      expect(ClientListFilter.all.includes(status), isTrue);
    }
  });

  test('Clientes con cuota vigente permanecen en activos', () {
    expect(clientActivity(client(due: DateTime(2026, 11, 11)),
        today: today, inactiveAfterDays: limit), ClientActivity.vigente);
    expect(clientActivity(client(due: DateTime(2026, 12, 11)),
        today: today, inactiveAfterDays: limit), ClientActivity.vigente);
  });

  test('Cuota vencida sigue pendiente durante el plazo configurado', () {
    expect(clientActivity(client(due: DateTime(2026, 11, 10)),
        today: today, inactiveAfterDays: limit), ClientActivity.pendiente);
    expect(clientActivity(client(due: DateTime(2026, 10, 12)),
        today: today, inactiveAfterDays: limit), ClientActivity.pendiente);
  });

  test('Superado el umbral pasa a inactivo automático sin eliminarse', () {
    expect(clientActivity(client(due: DateTime(2026, 10, 11)),
        today: today, inactiveAfterDays: limit), ClientActivity.inactivoAutomatico);
  });

  test('Un cliente sin cuotas registradas queda pendiente', () {
    expect(clientActivity(client(), today: today, inactiveAfterDays: limit),
        ClientActivity.pendiente);
  });

  test('Desactivación manual prevalece incluso si está al día', () {
    expect(clientActivity(client(due: DateTime(2026, 12, 12), active: false),
        today: today, inactiveAfterDays: limit), ClientActivity.inactivoManual);
  });

  test('La misma cuota puede pasar a inactiva con un umbral menor', () {
    final late = client(due: DateTime(2026, 11, 1));
    expect(clientActivity(late, today: today, inactiveAfterDays: 15),
        ClientActivity.pendiente);
    expect(clientActivity(late, today: today, inactiveAfterDays: 7),
        ClientActivity.inactivoAutomatico);
  });

  test('Al renovar recupera su condición activa de forma automática', () {
    final before = client(due: DateTime(2026, 9, 30));
    final after = client(due: DateTime(2026, 12, 11));
    expect(clientActivity(before, today: today, inactiveAfterDays: limit).isInactive,
        isTrue);
    expect(clientActivity(after, today: today, inactiveAfterDays: limit),
        ClientActivity.vigente);
  });
}
