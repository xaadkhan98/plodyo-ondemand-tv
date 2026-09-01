import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/tv_card.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../data/models/media_item.dart';
import '../../../../data/repositories/mock_vod_repository.dart';
import '../../auth/widgets/tv_keyboard.dart';

/// TV Search View matching Plodyo UI design with 6-column virtual keyboard and search results grid.
class SearchView extends StatefulWidget {
  const SearchView({
    super.key,
    required this.onMediaSelected,
  });

  final ValueChanged<MediaItem> onMediaSelected;

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final VodRepository _repository = MockVodRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _screenFocusNode = FocusNode();
  final FocusNode _searchFieldFocusNode = FocusNode();

  List<MediaItem> _results = [];
  bool _isLoading = false;
  bool _showCursor = true;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();

    // Blinking cursor simulation
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 550), (timer) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _searchController.dispose();
    _screenFocusNode.dispose();
    _searchFieldFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handlePhysicalKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      if (key == LogicalKeyboardKey.backspace) {
        _handleBackspace();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.space) {
        _handleSpace();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.escape) {
        _handleClear();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
        _performSearch(_searchController.text);
        return KeyEventResult.handled;
      } else if (event.character != null &&
          event.character!.isNotEmpty &&
          event.character!.codeUnitAt(0) >= 32) {
        _handleVirtualKeyPress(event.character!);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _handleVirtualKeyPress(String key) {
    setState(() {
      _searchController.text += key;
    });
    _performSearch(_searchController.text);
  }

  void _handleBackspace() {
    if (_searchController.text.isNotEmpty) {
      setState(() {
        _searchController.text =
            _searchController.text.substring(0, _searchController.text.length - 1);
      });
      _performSearch(_searchController.text);
    }
  }

  void _handleSpace() {
    setState(() {
      _searchController.text += ' ';
    });
    _performSearch(_searchController.text);
  }

  void _handleClear() {
    setState(() {
      _searchController.clear();
      _results.clear();
      _isLoading = false;
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final allItems = await _repository.searchCatalog(query);

    if (mounted) {
      setState(() {
        _results = allItems;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return Focus(
      focusNode: _screenFocusNode,
      autofocus: true,
      onKeyEvent: _handlePhysicalKey,
      child: Container(
        color: const Color(0xFFFAF7FC),
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: "Search" Title, Search Input Bar, and Virtual Keyboard
          SizedBox(
            width: 320,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar Branding Header
                  const PlodyoHeader(padding: EdgeInsets.only(bottom: 12)),

                  // Headline: "Search"
                  const Text(
                    'Search',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF18181B),
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Search Input Box
                  GestureDetector(
                    onTap: () => _searchFieldFocusNode.requestFocus(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF9333EA),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9333EA).withValues(alpha: 0.12),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              _searchController.text.isEmpty
                                  ? 'Search stories...'
                                  : _searchController.text,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: _searchController.text.isEmpty
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF18181B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Opacity(
                            opacity: _showCursor ? 1.0 : 0.0,
                            child: Container(
                              width: 1.8,
                              height: 16,
                              color: const Color(0xFF9333EA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 6-Column Virtual TV Keyboard
                  TvKeyboard(
                    statusText: '',
                    onKeyPress: _handleVirtualKeyPress,
                    onBackspace: _handleBackspace,
                    onSpace: _handleSpace,
                    onClear: _handleClear,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 36),

          // Right Column: Search Results Grid or Empty Prompt State
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9333EA)),
                    ),
                  )
                : !hasQuery
                    ? _buildEmptyPromptState()
                    : _results.isEmpty
                        ? _buildNoResultsState()
                        : _buildSearchResultsGrid(),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildEmptyPromptState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 34,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'What would you like to read?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF18181B),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use the keyboard to search by title.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF71717A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 48,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 14),
          Text(
            'No stories found matching "${_searchController.text}"',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try searching for another keyword or character name.',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF71717A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_results.length} Stories Found',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF18181B),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              childAspectRatio: 2 / 3.2,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
            ),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final item = _results[index];
              return TvCard(
                item: item,
                variant: TvCardVariant.poster,
                onTap: () => widget.onMediaSelected(item),
              );
            },
          ),
        ),
      ],
    );
  }
}
