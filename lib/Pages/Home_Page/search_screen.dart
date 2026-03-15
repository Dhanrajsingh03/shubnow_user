import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🔥 API & Provider Imports (Ensure these paths are correct in your project)
import '../Puja_Page/puja_model.dart';
import '../Puja_Page/puja_provider.dart';


class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = "";

  // 📈 LIVE Recent Searches List
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches(); // 🚀 Load history on start

    // Auto focus keyboard when page opens
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  // ==========================================
  // 💾 LOCAL STORAGE LOGIC FOR RECENT SEARCHES
  // ==========================================

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveRecentSearch(String term) async {
    if (term.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();

    // Remove if already exists to bring it to the top
    _recentSearches.remove(term);
    _recentSearches.insert(0, term);

    // Keep maximum 8 recent searches
    if (_recentSearches.length > 8) {
      _recentSearches = _recentSearches.sublist(0, 8);
    }

    await prefs.setStringList('recent_searches', _recentSearches);
    setState(() {});
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() {
      _recentSearches.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<PujaModel> allPujas = ref.watch(allPujasProvider).valueOrNull ?? <PujaModel>[];

    final List<PujaModel> filteredPujas = _searchQuery.isEmpty
        ? <PujaModel>[]
        : allPujas.where((puja) =>
    puja.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        puja.title.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 🔍 1. PREMIUM SEARCH HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        onChanged: (value) => setState(() => _searchQuery = value),
                        onSubmitted: (value) {
                          // 🚀 Save when user hits 'Enter/Search' on keyboard
                          _saveRecentSearch(value);
                        },
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: "Search for Pujas, Pandits...",
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = "");
                            },
                          )
                              : const Icon(Icons.mic, color: Colors.deepOrange, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: Colors.grey.shade100, thickness: 1.5, height: 0),

            // --- 📝 2. DYNAMIC CONTENT AREA ---
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildRecentSection()
                  : _buildSearchResults(filteredPujas),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🎨 UI COMPONENTS
  // ==========================================

  // 🕰️ ACTUAL RECENT SEARCHES VIEW
  Widget _buildRecentSection() {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Text("Search for your favourite pujas!", style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_rounded, color: Colors.deepOrange, size: 20), // Updated Icon
                  const SizedBox(width: 8),
                  Text("Recent Searches", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.grey.shade800)),
                ],
              ),
              // 🚀 Premium Clear Button
              GestureDetector(
                onTap: _clearRecentSearches,
                child: const Text("Clear", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: _recentSearches.map((term) => GestureDetector(
              onTap: () {
                _searchController.text = term;
                setState(() => _searchQuery = term);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(term, style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // 📋 SEARCH RESULTS VIEW
  Widget _buildSearchResults(List<PujaModel> results) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text("No Pujas Found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
            const SizedBox(height: 8),
            Text("Try searching for something else\nlike 'Satyanarayan' or 'Wedding'", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final puja = results[index];
        return _buildResultCard(puja);
      },
    );
  }

  // 🎴 COMPACT RESULT CARD
  Widget _buildResultCard(PujaModel puja) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // 🚀 1. Save this search term to history before leaving!
          _saveRecentSearch(puja.name);

          // 🚀 2. Hide keyboard before navigating
          FocusScope.of(context).unfocus();

          // 🚀 3. Navigate
          context.pushNamed('puja-details', extra: puja);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  puja.image, height: 70, width: 70, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 70, width: 70, color: Colors.orange.shade50, child: const Icon(Icons.temple_hindu, color: Colors.deepOrange)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(puja.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(puja.title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text("₹${puja.price.basePrice.toInt()}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.deepOrange)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}