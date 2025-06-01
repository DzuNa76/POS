import 'package:flutter/material.dart';
import 'package:pos/data/models/item_model.dart';
import 'package:pos/data/repositories/item_repository.dart';

class ProductProvider with ChangeNotifier {
  final ItemRepository _itemRepository;

  ProductProvider(this._itemRepository);

  List<Item> _allItems = [];
  List<Item> _filteredItems = [];
  String _searchQuery = "";
  String? _selectedCategory;
  bool _isLoading = false;
  bool _isCategoryLoading = false;
  final int _limit = 100; // Jumlah item yang diambil per permintaan
  int _offset = 0;
  int _currentBatch = 0;
  int _loadedItems = 0;

  bool get isSyncing => _isSyncing;
  bool get isCategoryLoading => _isCategoryLoading;

  int _savedItems = 0; // Jumlah item yang disimpan ke lokal
  int get savedItems => _savedItems;

  int get totalItems => _allItems.length;
  int get filteredItemCount => _filteredItems.length;
  bool get isLoading => _isLoading;
  int get loadedItems => _loadedItems;
  bool _isFullyLoaded = false;
  bool _isSyncing = false;

  // Getter for current selected category
  String? get selectedCategory => _selectedCategory;

  // Getter to access all items without filters (for getting categories)
  List<Item> get allItems => _allItems;

  List<Item> get filteredItems => _filteredItems;

  bool _isSearching = false;

  bool get isSearching => _isSearching;

  Future<void> searchItems(String query) async {
    // Set searching state
    _isSearching = true;
    notifyListeners();

    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));

      // Dummy data generation based on search query
      _filteredItems = _allItems
          .where((item) =>
              item.itemName!.contains(query) ||
              item.itemCode!.contains(query) ||
              item.itemGroup!.contains(query))
          .toList();
      (query);

      // Update searching state
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      // Handle errors
      _isSearching = false;
      _filteredItems = [];
      notifyListeners();
      debugPrint('Search error: $e');
    }
  }

  // Clear search results
  void clearSearchResults() {
    _filteredItems = [];
    _isSearching = false;
    notifyListeners();
  }

  void setItems(List<Item> items) {
    if (_allItems != items) {
      _allItems = items;
      _applySearchFilter();
      notifyListeners();
    }
  }

  void searchItem(String query) {
    _searchQuery = query;
    _applySearchFilter();
    notifyListeners();
  }

  void addItems(List<Item> items) {
    _allItems.addAll(items);
    _applySearchFilter(); // Filter ulang data
    notifyListeners();
  }

  // New method to filter by category
  Future<void> filterByCategory(String? category) async {
    if (_selectedCategory == category) return; // Skip if same category

    _isCategoryLoading = true;
    notifyListeners();

    try {
      // Simulate network delay for category filtering (optional)
      // In a real app, you might need to fetch additional data for the category
      await Future.delayed(Duration(milliseconds: 500));

      _selectedCategory = category;
      _applySearchFilter();
    } catch (e) {
      debugPrint("Error filtering by category: $e");
    } finally {
      _isCategoryLoading = false;
      notifyListeners();
    }
  }

  void resetSearch() {
    _searchQuery = "";
    _applySearchFilter();
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = "";
    _selectedCategory = null;
    _applySearchFilter();
    notifyListeners();
  }

  void clearItems() {
    _allItems.clear();
    _filteredItems.clear();
    _offset = 0;
    _searchQuery = "";
    _selectedCategory = null;
    _isFullyLoaded = false; // Reset status data lengkap
    _loadedItems = 0; // Reset loaded items count
    _currentBatch = 0; // Reset current batch
    notifyListeners();
  }

  void _applySearchFilter() {
    // First apply search filter
    if (_searchQuery.isEmpty && _selectedCategory == null) {
      _filteredItems = _allItems;
      return;
    }

    _filteredItems = _allItems.where((item) {
      // Apply search filter
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        matchesSearch =
            (item.itemName?.toLowerCase().contains(searchLower) ?? false) ||
                (item.itemCode?.toLowerCase().contains(searchLower) ?? false) ||
                (item.itemGroup?.toLowerCase().contains(searchLower) ?? false);
      }

      // Apply category filter
      bool matchesCategory = true;
      if (_selectedCategory != null) {
        matchesCategory = item.itemGroup == _selectedCategory;
      }

      // Item must match both filters
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> loadItems() async {
    if (_isLoading || _isFullyLoaded)
      return; // Hindari fetching jika sedang loading atau sudah selesai

    _isLoading = true;
    notifyListeners();

    try {
      // Coba memuat data lokal
      await loadLocalItems();

      // Jika data lokal kosong, sinkronkan dengan server
      if (_allItems.isEmpty) {
        await syncWithServer();
      }
    } catch (e) {
      debugPrint("Error loading items: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> getTotalItemCount() async {
    try {
      // Anggap ItemRepository punya metode ini (kalau belum ada, bikin di repo)
      final totalCount = await _itemRepository.fetchTotalItemsCount();
      return totalCount;
    } catch (e) {
      debugPrint("Error getTotalItemCount: $e");
      return 0;
    }
  }

  Future<void> fetchItemsWithProgress({
    int batchSize = 500,
    required Function(int loaded) onProgressUpdate,
  }) async {
    clearItems();

    int offset = 0;
    int loaded = 0;
    int saved = 0;

    while (true) {
      try {
        final items =
            await _itemRepository.getItems(limit: batchSize, offset: offset);

        if (items.isEmpty) break;

        addItems(items);

        loaded += items.length;
        saved += items.length;
        offset += items.length;

        updateLoadedItems(loaded);
        updateSavedItems(saved);

        onProgressUpdate(loaded);
      } catch (e) {
        debugPrint("Error fetchItemsWithProgress: $e");
        break;
      }
    }

    notifyListeners();
  }

  // In ProductProvider:

  // This method loads local cached data immediately
  Future<void> loadLocalItems() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final localItems =
          await _itemRepository.getLocalItems(limit: _limit, offset: _offset);
      if (localItems.isNotEmpty) {
        _allItems.addAll(localItems);
        _applySearchFilter();
        _offset += _limit; // Geser offset ke batch berikutnya
        notifyListeners();
      } else {
        _isFullyLoaded = true; // Semua data sudah dimuat, stop pagination
      }
    } catch (e) {
      debugPrint("Error loading local items: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int get currentBatch => _currentBatch;

  // This method performs background syncing
  Future<void> syncWithServer({Function(int loaded)? onProgressUpdate}) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      int currentCount = 0;
      bool hasMoreData = true;

      // Reset the offset if starting a fresh sync
      if (_offset == 0) {
        clearItems();
        _loadedItems = 0; // Reset loaded items count when starting fresh
      }

      while (hasMoreData && !_isFullyLoaded) {
        final newItems =
            await _itemRepository.getItems(limit: _limit, offset: _offset);

        // Update the current batch count
        _currentBatch = (_offset / _limit).ceil();

        // If we got fewer items than the limit or no items, we've reached the end
        if (newItems.isEmpty || newItems.length < _limit) {
          _isFullyLoaded = true;
        }

        if (newItems.isEmpty) {
          break;
        }

        // Save to local storage
        await saveItemsToLocal(newItems);

        // Add to current list
        addItems(newItems);

        _offset += newItems.length;
        currentCount += newItems.length;
        _loadedItems += newItems.length; // Update the loaded items count

        if (onProgressUpdate != null) {
          onProgressUpdate(currentCount);
        }

        // Small delay to prevent overwhelming the server
        await Future.delayed(Duration(milliseconds: 100));

        // Make sure to notify listeners for UI updates
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error syncing with server: $e");
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> saveItemsToLocal(List<Item> items) async {
    try {
      await _itemRepository.saveItemsToLocal(items);
    } catch (e) {
      debugPrint("Error saving items to local: $e");
    }
  }

  void updateLoadedItems(int count) {
    _loadedItems = count;
    notifyListeners();
  }

  void updateSavedItems(int count) {
    _savedItems = count;
    notifyListeners();
  }
}
