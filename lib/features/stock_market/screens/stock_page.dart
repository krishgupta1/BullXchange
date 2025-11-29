import 'package:bullxchange/features/stock_market/screens/StockDetailPage.dart';
import 'package:bullxchange/features/stock_market/screens/explore_page.dart';
import 'package:bullxchange/features/stock_market/screens/holdings_page.dart';
import 'package:bullxchange/features/stock_market/screens/order_page.dart';
import 'package:bullxchange/features/stock_market/screens/position_page.dart';
import 'package:bullxchange/features/stock_market/screens/watchlist_page.dart';
import 'package:bullxchange/features/stock_market/widgets/action_tab_bar.dart';
import 'package:bullxchange/features/stock_market/widgets/index_card.dart';
import 'package:bullxchange/features/stock_market/widgets/main_page_header.dart';
import 'package:bullxchange/features/stock_market/widgets/shimmer_loading.dart';
import 'package:bullxchange/features/stock_market/widgets/stock_card.dart';
import 'package:bullxchange/models/order_model.dart';
import 'package:bullxchange/provider/instrument_provider.dart';
import 'package:bullxchange/models/instrument_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';

class StockPage extends StatefulWidget {
  final int initialActionIndex;
  const StockPage({super.key, this.initialActionIndex = 0});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late int _selectedActionIndex;
  String? _userName;
  String? _uid;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Instrument> _allStocks = [];
  List<Instrument> _filteredStocks = [];
  final List<Instrument> _displayedStocks = [];
  bool _stocksInitialized = false;
  bool _isLoadingMore = false;
  final int _batchSize = 50;

  @override
  void initState() {
    super.initState();
    _selectedActionIndex = widget.initialActionIndex;
    _loadUserData();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (mounted) setState(() => _uid = user.uid);
      }
      if (user != null &&
          user.displayName != null &&
          user.displayName!.trim().isNotEmpty) {
        if (mounted) setState(() => _userName = user.displayName);
        return;
      }
      if (_uid != null) {
        final profile = await UserService().readUserProfile(_uid!);
        if (profile != null && profile.name.trim().isNotEmpty) {
          if (!mounted) return;
          setState(() => _userName = profile.name);
          return;
        }
      }
    } catch (_) {
      // Ignore errors
    }
  }

  void _initializeStocks(InstrumentProvider provider) {
    if (_stocksInitialized || provider.allNSEStocks.isEmpty) return;
    _allStocks = provider.allNSEStocks.where((stock) {
      final baseSymbol = stock.symbol.replaceAll('-EQ', '');
      final lowerCaseName = stock.name.toLowerCase();
      if (baseSymbol.contains(RegExp(r'[0-9]'))) return false;
      const excludedKeywords = [
        'etf',
        'bees',
        'nifty',
        'gold',
        'bond',
        'debenture',
        'pref',
        'index',
      ];
      if (excludedKeywords.any((keyword) => lowerCaseName.contains(keyword))) {
        return false;
      }
      if (baseSymbol.length < 3 || baseSymbol.length > 12) return false;
      if (!RegExp(r'^[A-Z]+$').hasMatch(baseSymbol)) return false;
      return true;
    }).toList();
    _stocksInitialized = true;
  }

  void _onScroll() {
    if (!_isSearching) return;
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _displayedStocks.length < _filteredStocks.length) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if (_isLoadingMore) return;
    if (mounted) setState(() => _isLoadingMore = true);
    final currentLength = _displayedStocks.length;
    final moreItems = _filteredStocks
        .skip(currentLength)
        .take(_batchSize)
        .toList();
    if (moreItems.isNotEmpty) {
      if (mounted) {
        setState(() => _displayedStocks.addAll(moreItems));
      }
    }
    if (context.mounted) {
      final provider = Provider.of<InstrumentProvider>(context, listen: false);
      provider.fetchLiveDataFor(moreItems);
    }
    if (mounted) setState(() => _isLoadingMore = false);
  }

  void _onSearchChanged() {
    _searchStocks(_searchController.text);
  }

  void _searchStocks(String query) {
    if (!_stocksInitialized) {
      final provider = Provider.of<InstrumentProvider>(context, listen: false);
      _initializeStocks(provider);
    }
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _filteredStocks = [];
          _displayedStocks.clear();
        });
      }
      return;
    }
    final results = _allStocks.where((stock) {
      final symbol = stock.symbol.toLowerCase();
      final name = stock.name.toLowerCase();
      final searchQuery = query.toLowerCase();
      return symbol.contains(searchQuery) || name.contains(searchQuery);
    }).toList();
    if (mounted) {
      setState(() {
        _filteredStocks = results;
        _displayedStocks.clear();
      });
    }
    _loadMoreItems();
  }

  void _cancelSearch() {
    FocusManager.instance.primaryFocus?.unfocus();
    _searchController.clear();
    if (mounted) {
      setState(() {
        _isSearching = false;
        _filteredStocks = [];
        _displayedStocks.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamProvider<List<OrderModel>>.value(
      value: _uid != null
          ? UserService().streamOpenOrders(_uid!)
          : Stream.value([]),
      initialData: const [],
      child: Consumer<InstrumentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.allNSEStocks.isEmpty) {
            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
            );
          }
          if (provider.errorMessage != null) {
            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${provider.errorMessage}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ),
            );
          }
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildHeader(),
                        const SizedBox(height: 30),
                        if (!_isSearching) ...[
                          Row(
                            children: [
                              Expanded(
                                child: IndexCard(
                                  instrument: provider.nifty50,
                                  title: "NIFTY 50",
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: IndexCard(
                                  instrument: provider.bankNifty,
                                  title: "BANK NIFTY",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ActionTabBar(
                            labels: const [
                              "Explore",
                              "Holdings",
                              "Position",
                              "Orders",
                              "Watchlist",
                            ],
                            selectedIndex: _selectedActionIndex,
                            onTabSelected: (index) {
                              setState(() {
                                _selectedActionIndex = index;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                  if (!_isSearching) ...[
                    Expanded(
                      child: IndexedStack(
                        index: _selectedActionIndex,
                        children: [
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: ExplorePage(),
                          ),
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: HoldingsPage(),
                          ),
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: PositionPage(),
                          ),
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: OrderPage(),
                          ),
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: WatchListPage(),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        child: MediaQuery.removePadding(
                          context: context,
                          removeLeft: true,
                          removeRight: true,
                          child: _buildSearchResultsList(context),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isSearching) {
      return _buildSearchBar();
    }

    return MainPageHeader(
      userName: _userName,
      defaultUserName: 'User',
      welcomeMessage: 'Welcome to BullXchange',
      onProfileTap: () {
        Scaffold.of(context).openDrawer();
      },
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
          icon: Icon(Icons.search, color: colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return TextField(
      controller: _searchController,
      autofocus: true,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: "Search company, stocks...",
        hintStyle: TextStyle(color: textTheme.bodySmall?.color, fontSize: 10),
        // --- ⭐️ FIX START: Added padding and constraints to fix overlap ---
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12.0, right: 8.0),
          child: CustomBackButton(
            onPressed: _cancelSearch,
            iconSize: 20,
            padding: EdgeInsets.zero,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        // --- ⭐️ FIX END ---
        suffixIcon: IconButton(
          icon: Icon(Icons.close, color: textTheme.bodySmall?.color),
          onPressed: () => _searchController.clear(),
        ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: colorScheme.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildSearchResultsList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_searchController.text.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            "Start typing to search for stocks.",
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
      );
    }
    if (_isLoadingMore && _displayedStocks.isEmpty) {
      return _buildShimmerLoadingList();
    }
    if (_filteredStocks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            "No stocks found.",
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
      );
    }
    return Column(
      children: [
        ...List.generate(_displayedStocks.length, (index) {
          final instrument = _displayedStocks[index];
          return StockCard(
            instrument: instrument,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StockDetailPage(instrument: instrument),
              ),
            ),
          );
        }),
        if (_isLoadingMore) _buildLoadMoreShimmer(),
      ],
    );
  }

  Widget _buildShimmerLoadingList() {
    final theme = Theme.of(context);

    return Shimmer.fromColors(
      baseColor: theme.brightness == Brightness.light
          ? Colors.grey.shade300
          : Colors.grey.shade800,
      highlightColor: theme.brightness == Brightness.light
          ? Colors.grey.shade100
          : Colors.grey.shade700,
      child: Column(
        children: List.generate(10, (index) => const StockShimmerItem()),
      ),
    );
  }

  Widget _buildLoadMoreShimmer() {
    final theme = Theme.of(context);

    return Shimmer.fromColors(
      baseColor: theme.brightness == Brightness.light
          ? Colors.grey.shade300
          : Colors.grey.shade800,
      highlightColor: theme.brightness == Brightness.light
          ? Colors.grey.shade100
          : Colors.grey.shade700,
      child: Column(
        children: [const StockShimmerItem(), const StockShimmerItem()],
      ),
    );
  }
}


