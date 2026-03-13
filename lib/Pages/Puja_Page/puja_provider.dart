import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'puja_service.dart';
import 'puja_model.dart';

// ==========================================
// 1. SERVICE PROVIDER (Dependency Injection)
// ==========================================
// Ye poori app me ek hi PujaService ka instance maintain karega.
final pujaServiceProvider = Provider<PujaService>((ref) {
  return PujaService();
});

// ==========================================
// 2. MASTER FUTURE PROVIDER (Fetch Everything)
// ==========================================
// Ye provider backend ke '/user/all' se saari pujas fetch karega.
// Isko hum cache ki tarah use karenge taaki API baar-baar hit na ho.
final allPujasProvider = FutureProvider<List<PujaModel>>((ref) async {
  final service = ref.read(pujaServiceProvider);
  return await service.fetchAllPujas();
});

// ==========================================
// 3. DERIVED PROVIDERS (Smart Filtering)
// ==========================================
// Ye specifically 'regular' pujas nikalega.
// Jab allPujasProvider load hoga, ye automatically update ho jayega bina nayi API call ke!
final regularPujasProvider = FutureProvider<List<PujaModel>>((ref) async {
  // Master provider ke data ka wait karo
  final allPujas = await ref.watch(allPujasProvider.future);

  // Sirf 'regular' type filter karo
  return allPujas.where((puja) => puja.pujaType == 'regular').toList();
});

final weddingPujasProvider = FutureProvider<List<PujaModel>>((ref) async {
  // Master provider se saara data lo (No new API hit required)
  final allPujas = await ref.watch(allPujasProvider.future);

  // Sirf 'wedding' type filter karo
  return allPujas.where((puja) => puja.pujaType == 'wedding').toList();
});

final hawanPujasProvider = FutureProvider<List<PujaModel>>((ref) async {
  final allPujas = await ref.watch(allPujasProvider.future);

  // Backend mein enum 'hawan' hai
  return allPujas.where((puja) => puja.pujaType == 'hawan').toList();
});
// 🔥 PRO-TIP: Kal ko agar "Festival" ya "Wedding" section banana ho,
// toh bas aisi ek line add karni hogi:
final festivalPujasProvider = FutureProvider<List<PujaModel>>((ref) async {
  final allPujas = await ref.watch(allPujasProvider.future);
  return allPujas.where((puja) => puja.pujaType == 'festival').toList(); //
});

// ==========================================
// 4. FAMILY PROVIDER (For Puja Details Screen)
// ==========================================
// Jab user kisi specific puja par click karega, tab ye kaam aayega.
// .family ka matlab hai ki hum isko ek ID pass kar sakte hain.
final pujaDetailProvider = FutureProvider.family<PujaModel, String>((ref, pujaId) async {
  final service = ref.read(pujaServiceProvider);
  // Backend ke '/user/:id' route ko hit karega
  return await service.fetchPujaById(pujaId);
});