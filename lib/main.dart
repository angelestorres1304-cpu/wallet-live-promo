import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final promoProvider = StateNotifierProvider<PromoController, List<Promo>>((ref) => PromoController());

class Promo { final String code; final int discount, maxUses; final DateTime expires; int uses;
  Promo({required this.code, required this.discount, required this.maxUses, required this.expires, this.uses = 0});
  bool get active => DateTime.now().isBefore(expires) && uses < maxUses;
}

class PromoController extends StateNotifier<List<Promo>> {
  PromoController() : super([]) { _load(); }
  Future<void> _load() async { final p = await SharedPreferences.getInstance(); final saved = p.getStringList('promo_codes') ?? []; state = saved.map((c) => Promo(code: c, discount: 20, maxUses: 100, expires: DateTime.now().add(const Duration(hours: 2)))).toList(); }
  Future<void> add({required int discount, required int maxUses, required int minutes}) async { final code = _newCode(); state = [Promo(code: code, discount: discount, maxUses: maxUses, expires: DateTime.now().add(Duration(minutes: minutes))), ...state]; await _save(); }
  Future<void> remove(String code) async { state = state.where((p) => p.code != code).toList(); await _save(); }
  Future<void> _save() async { final p = await SharedPreferences.getInstance(); await p.setStringList('promo_codes', state.map((x) => x.code).toList()); }
  String _newCode() { const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; final now = DateTime.now().microsecondsSinceEpoch; return 'LIVE${List.generate(6, (i) => chars[(now ~/ (i + 3)) % chars.length]).join()}'; }
}

void main() => runApp(const ProviderScope(child: TikTokPromoApp()));

class TikTokPromoApp extends StatelessWidget { const TikTokPromoApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.pink), home: const LivePage());
}

class LivePage extends ConsumerWidget { const LivePage({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) { final promos = ref.watch(promoProvider).where((p) => p.active).toList(); return Scaffold(appBar: AppBar(title: const Text('TikTok LIVE Promo'), actions: [IconButton(onPressed: () => _showHelp(context), icon: const Icon(Icons.help_outline))]), body: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('● EN VIVO', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)), SizedBox(height: 8), Text('Comparte este código en tu LIVE', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('Genera una oferta, cópiala y pégala en el chat de TikTok.', style: TextStyle(color: Colors.white70))])), const SizedBox(height: 16), FilledButton.icon(onPressed: () => _newPromo(context, ref), icon: const Icon(Icons.add), label: const Text('GENERAR CÓDIGO')), const SizedBox(height: 16), Text('${promos.length} códigos activos', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), Expanded(child: promos.isEmpty ? const Center(child: Text('Genera tu primer código para comenzar')) : ListView.builder(itemCount: promos.length, itemBuilder: (_, i) => _PromoCard(promo: promos[i])))])))); }
  void _newPromo(BuildContext context, WidgetRef ref) { showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => _PromoForm(onCreate: (d, u, m) => ref.read(promoProvider.notifier).add(discount: d, maxUses: u, minutes: m))); }
  void _showHelp(BuildContext context) => showDialog(context: context, builder: (_) => const AlertDialog(title: Text('Cómo usarlo en TikTok'), content: Text('1. Genera el código.\n2. Pulsa COPIAR.\n3. Abre TikTok LIVE.\n4. Pega el código en el chat y muéstralo en pantalla.\n\nEsta app es un panel auxiliar: no inicia ni controla la transmisión de TikTok.')));
}

class _PromoCard extends ConsumerWidget { final Promo promo; const _PromoCard({required this.promo});
  @override Widget build(BuildContext context, WidgetRef ref) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(promo.code, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, letterSpacing: 2)), Chip(label: Text('${promo.discount}% OFF'))]), Text('${promo.maxUses - promo.uses} usos disponibles · vence en ${promo.expires.difference(DateTime.now()).inMinutes} min'), const SizedBox(height: 10), Row(children: [Expanded(child: FilledButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: promo.code)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código copiado'))); }, icon: const Icon(Icons.copy), label: const Text('COPIAR'))), const SizedBox(width: 8), IconButton(onPressed: () => ref.read(promoProvider.notifier).remove(promo.code), icon: const Icon(Icons.delete_outline))])])));
}

class _PromoForm extends StatefulWidget { final void Function(int, int, int) onCreate; const _PromoForm({required this.onCreate}); @override State<_PromoForm> createState() => _PromoFormState(); }
class _PromoFormState extends State<_PromoForm> { final d = TextEditingController(text: '20'), u = TextEditingController(text: '100'), m = TextEditingController(text: '60'); @override Widget build(BuildContext context) => Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Nueva promoción', style: Theme.of(context).textTheme.headlineSmall), TextField(controller: d, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Descuento (%)')), TextField(controller: u, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Límite de usos')), TextField(controller: m, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duración (minutos)')), const SizedBox(height: 16), FilledButton(onPressed: () { widget.onCreate(int.tryParse(d.text) ?? 20, int.tryParse(u.text) ?? 100, int.tryParse(m.text) ?? 60); Navigator.pop(context); }, child: const Text('CREAR'))])); @override void dispose() { d.dispose(); u.dispose(); m.dispose(); super.dispose(); } }
