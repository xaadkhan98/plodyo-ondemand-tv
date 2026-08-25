import 'package:flutter/material.dart';
import '../../../../data/models/media_item.dart';
import '../../../../data/repositories/mock_vod_repository.dart';

/// ViewModel for Home TV Screen managing state and catalog sections.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({VodRepository? repository})
      : _repository = repository ?? MockVodRepository();

  final VodRepository _repository;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  MediaItem? _featuredHero;
  MediaItem? get featuredHero => _featuredHero;

  List<MediaItem> _continueWatching = [];
  List<MediaItem> get continueWatching => _continueWatching;

  List<MediaItem> _trendingMovies = [];
  List<MediaItem> get trendingMovies => _trendingMovies;

  List<MediaItem> _popularSeries = [];
  List<MediaItem> get popularSeries => _popularSeries;

  List<MediaItem> _sciFiCatalog = [];
  List<MediaItem> get sciFiCatalog => _sciFiCatalog;

  Future<void> loadCatalog() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getHeroFeatured(),
        _repository.getContinueWatching(),
        _repository.getTrendingMovies(),
        _repository.getPopularSeries(),
        _repository.getSciFiCatalog(),
      ]);

      _featuredHero = results[0] as MediaItem;
      _continueWatching = results[1] as List<MediaItem>;
      _trendingMovies = results[2] as List<MediaItem>;
      _popularSeries = results[3] as List<MediaItem>;
      _sciFiCatalog = results[4] as List<MediaItem>;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateHeroPreview(MediaItem item) {
    _featuredHero = item;
    notifyListeners();
  }
}
