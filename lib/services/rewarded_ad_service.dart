import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _isLoadingAd = false;
  final List<VoidCallback> _onAdLoadedCallbacks = [];

  // Live AdMob Rewarded Ad Unit ID for Android
  final String _adUnitId = 'ca-app-pub-2950394301574451/8171000911';

  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void loadAd({VoidCallback? onAdLoadedCallback}) {
    if (onAdLoadedCallback != null) {
      _onAdLoadedCallbacks.add(onAdLoadedCallback);
    }

    if (_isAdLoaded) {
      _notifyCallbacks();
      return;
    }

    if (_isLoadingAd) return;
    _isLoadingAd = true;

    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
          _isLoadingAd = false;
          _notifyCallbacks();
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _isAdLoaded = false;
          _isLoadingAd = false;
          _onAdLoadedCallbacks.clear();
        },
      ),
    );
  }

  void _notifyCallbacks() {
    final List<VoidCallback> callbacks = List.from(_onAdLoadedCallbacks);
    _onAdLoadedCallbacks.clear();
    for (final callback in callbacks) {
      callback();
    }
  }

  Future<void> showAdOrWait({
    required BuildContext context,
    required VoidCallback onRewarded,
  }) async {
    final isOnline = await hasInternetConnection();
    if (!context.mounted) return;

    if (!isOnline) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Expanded(child: Text('Internet Required')),
            ],
          ),
          content: const Text(
            'An active internet connection is required to load the video ad and save your PDF document. Please connect to Wi-Fi or Mobile Data and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (_isAdLoaded && _rewardedAd != null) {
      _presentAd(context: context, onRewarded: onRewarded);
      return;
    }

    // Show loading dialog
    bool dialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(
              child: Text('Loading video ad...\nPlease wait a moment.'),
            ),
          ],
        ),
      ),
    );

    loadAd(onAdLoadedCallback: () {
      if (dialogShowing && context.mounted) {
        dialogShowing = false;
        Navigator.pop(context); // Dismiss loading dialog
        _presentAd(context: context, onRewarded: onRewarded);
      }
    });

    // Timeout after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      if (dialogShowing && !_isAdLoaded) {
        dialogShowing = false;
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad loading timed out. Please tap "Watch Ad & Save" again.'),
            ),
          );
        }
      }
    });
  }

  void _presentAd({
    required BuildContext context,
    required VoidCallback onRewarded,
  }) {
    bool userEarnedReward = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _isAdLoaded = false;
        _rewardedAd = null;
        loadAd(); // Preload next ad

        if (userEarnedReward) {
          onRewarded();
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ad not completed. Watch the full video ad to save your PDF.'),
              ),
            );
          }
        }
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        _isAdLoaded = false;
        _rewardedAd = null;
        loadAd();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to show video ad. Please try again.'),
            ),
          );
        }
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        userEarnedReward = true;
      },
    );
  }
}
