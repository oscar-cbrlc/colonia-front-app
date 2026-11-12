import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:colonia_front_app/data/services/api/store_service.dart';
import 'package:colonia_front_app/domain/models/shop_offer.dart';

class ShopRepository extends ChangeNotifier {
  final StoreService _storeService;

  List<ShopOffer> _offers = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Set<int> _purchasedOfferIds = {};

  ShopRepository(this._storeService);

  List<ShopOffer> get offers => List.unmodifiable(_offers);
  List<ShopOffer> get itemOffers => _offers.where((o) => o.typeEnum == ShopOfferType.item).toList();
  List<ShopOffer> get bundleOffers => _offers.where((o) => o.typeEnum == ShopOfferType.bundle).toList();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Set<int> get purchasedOfferIds => Set.unmodifiable(_purchasedOfferIds);

  bool isOfferPurchased(int offerId) => _purchasedOfferIds.contains(offerId);

  Future<void> fetchOffers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var response = await _storeService.getOffers();
      if (response.statusCode != 200) {
        response = await _storeService.getOffers();
      }

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          _offers = decoded.map((json) => ShopOffer.fromJson(json as Map<String, dynamic>)).toList();
        } else if (decoded is Map<String, dynamic> && decoded['offers'] is List) {
          _offers = (decoded['offers'] as List).map((json) => ShopOffer.fromJson(json as Map<String, dynamic>)).toList();
        }
      } else {
        _errorMessage = 'Failed to load shop offers (${response.statusCode})';
      }
    } catch (e) {
      debugPrint('ShopRepository: Error fetching shop offers: $e');
      _errorMessage = 'Error loading shop offers: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> buyOffer(int offerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var response = await _storeService.buyOffer(offerId);
      if (response.statusCode != 200 && response.statusCode != 201) {
        response = await _storeService.buyOffer(offerId);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        _purchasedOfferIds.add(offerId);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to purchase offer (${response.statusCode})';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('ShopRepository: Error buying offer $offerId: $e');
      _errorMessage = 'Error purchasing offer: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
