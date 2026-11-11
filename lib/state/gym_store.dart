import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/gym_repository.dart';
import '../data/models.dart';

class GymStore extends ChangeNotifier {
  GymStore(this.repo);
  final GymRepository repo;
  List<StudioClient> clients = [];
  List<StudioPlan> plans = [];
  List<StudioPayment> payments = [];
  Map<String, String> settings = {};
  bool busy = false;

  Future<void> refresh() async {
    busy = true;
    notifyListeners();
    try {
      final c = await repo.clients();
      final p = await repo.plans();
      final pay = await repo.payments();
      final s = await repo.settings();
      clients = c;
      plans = p;
      payments = pay;
      settings = s;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  String get studioName {
    final name = settings['studio_name']?.trim() ?? '';
    return name.isEmpty ? 'Mi estudio' : name;
  }
  int get colorIndex => int.tryParse(settings['color_index'] ?? '0') ?? 0;

  ThemeMode get themeMode {
    switch (settings['theme_mode']) {
      case 'dark': return ThemeMode.dark;
      case 'system': return ThemeMode.system;
      default: return ThemeMode.light;
    }
  }
  StudioClient? clientById(int id) {
    for (final client in clients) {
      if (client.id == id) return client;
    }
    return null;
  }
  StudioPlan? planById(int id) {
    for (final plan in plans) {
      if (plan.id == id) return plan;
    }
    return null;
  }
  Future<void> modify(Future<void> Function() action) async {
    await action();
    await refresh();
  }
}
