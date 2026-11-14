import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  Completer<bool>? _adLoadCompleter;

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

  Future<bool> loadAd() async {
    if (_isAdLoaded && _rewardedAd != null) {
      return true;
    }

    if (_adLoadCompleter != null && !_adLoadCompleter!.isCompleted) {
      return _adLoadCompleter!.future;
    }

    _adLoadCompleter = Completer<bool>();

    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
          if (!(_adLoadCompleter?.isCompleted ?? true)) {
            _adLoadCompleter!.complete(true);
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _isAdLoaded = false;
          if (!(_adLoadCompleter?.isCompleted ?? true)) {
            _adLoadCompleter!.complete(false);
          }
        },
      ),
    );

    return _adLoadCompleter!.future;
  }

  Future<void> showAdOrWait({
    required BuildContext context,
    required VoidCallback onRewarded,
  }) async {
    // 1. Internet check
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

    // 2. If already loaded, present immediately!
    if (_isAdLoaded && _rewardedAd != null) {
      _presentAd(context: context, onRewarded: onRewarded);
      return;
    }

    // 3. Show loading dialog while awaiting the Completer
    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(
                child: Text('Loading video ad...\nPlease wait a moment.'),
              ),
            ],
          ),
        );
      },
    );

    // Wait for ad load with a 10s timeout limit
    final success = await loadAd().timeout(
      const Duration(seconds: 10),
      onTimeout: () => false,
    );

    // Dismiss loading dialog
    if (dialogContext != null && context.mounted) {
      Navigator.of(dialogContext!).pop();
    }

    if (!context.mounted) return;

    if (success && _isAdLoaded && _rewardedAd != null) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (context.mounted) {
        _presentAd(context: context, onRewarded: onRewarded);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad loading delayed. Please tap "Watch Ad & Save" again.'),
        ),
      );
    }
  }

  void _presentAd({
    required BuildContext context,
    required VoidCallback onRewarded,
  }) {
    if (_rewardedAd == null) return;

    bool userEarnedReward = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _isAdLoaded = false;
        _rewardedAd = null;
        _adLoadCompleter = null;
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
        _adLoadCompleter = null;
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
