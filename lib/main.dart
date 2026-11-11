import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/app_database.dart';
import 'data/gym_repository.dart';
import 'state/gym_store.dart';
import 'ui/theme.dart';
import 'licensing/license_gate.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/clients_screen.dart';
import 'ui/screens/payments_screen.dart';
import 'ui/screens/reports_screen.dart';
import 'ui/screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_AR');
  final store = GymStore(GymRepository(AppDatabase()));
  try {
    await store.refresh();
    runApp(GymLiteApp(store: store));
  } catch (e) {
    runApp(MaterialApp(home: Scaffold(body: SafeArea(child: Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text('No se pudo abrir la base de datos local. No desinstales la app sin revisar tus respaldos.\n\n$e'),
    ))))));
  }
}

class GymLiteApp extends StatelessWidget {
  const GymLiteApp({super.key, required this.store});
  final GymStore store;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => MaterialApp(
      title: 'Higea Fitness',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(store.colorIndex),
      darkTheme: buildAppTheme(store.colorIndex, brightness: Brightness.dark),
      themeMode: store.themeMode,
      locale: const Locale('es', 'AR'),
      supportedLocales: const [Locale('es', 'AR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: LicenseGate(child: GymShell(store: store)),
    ),
  );
}

class GymShell extends StatefulWidget {
  const GymShell({super.key, required this.store});
  final GymStore store;
  @override
  State<GymShell> createState() => _GymShellState();
}

class _GymShellState extends State<GymShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    const titles = ['Inicio', 'Clientes', 'Pagos', 'Informes'];
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        leading: (widget.store.settings['studio_logo_b64'] ?? '').isEmpty
          ? null
          : Padding(padding: const EdgeInsets.all(7), child: CircleAvatar(
              backgroundColor: Colors.white,
              child: ClipOval(child: Image.memory(
                Uint8List.fromList(base64Decode(widget.store.settings['studio_logo_b64']!)),
                width: 34, height: 34, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.fitness_center),
              )))),
        title: Text(index == 0 ? widget.store.studioName : titles[index],
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: index == 0 ? 24 : 20,
            fontWeight: index == 0 ? FontWeight.w800 : FontWeight.w700,
            letterSpacing: index == 0 ? -0.4 : 0,
          )),
        actions: [
          IconButton(
            tooltip: 'Ajustes',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => SettingsScreen(store: widget.store))),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(top: false, child: Stack(children: [
        IndexedStack(index: index, children: [
          HomeScreen(store: widget.store, onClients: () => setState(() => index = 1)),
          ClientsScreen(store: widget.store),
          PaymentsScreen(store: widget.store),
          ReportsScreen(store: widget.store),
        ]),
        if (widget.store.busy) const LinearProgressIndicator(minHeight: 2),
      ])),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Clientes'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet), label: 'Pagos'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart), label: 'Informes'),
        ],
      ),
    );
  }
}
