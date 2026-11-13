import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  // Live AdMob Rewarded Ad Unit ID for Android
  final String _adUnitId = 'ca-app-pub-2950394301574451/8171000911';

  void loadAd() {
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _isAdLoaded = false;
        },
      ),
    );
  }

  void showAd({
    required VoidCallback onRewarded,
    required VoidCallback onAdNotReady,
  }) {
    if (_isAdLoaded && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          ad.dispose();
          loadAd();
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          ad.dispose();
          loadAd();
          onAdNotReady();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          onRewarded();
        },
      );
      _rewardedAd = null;
      _isAdLoaded = false;
    } else {
      loadAd();
      onAdNotReady();
    }
  }
}
