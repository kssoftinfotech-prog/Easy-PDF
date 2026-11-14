import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _isLoadingAd = false;
  final List<VoidCallback> _onAdLoadedCallbacks = [];
  final List<Function(LoadAdError)> _onAdFailedCallbacks = [];

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

  void loadAd({VoidCallback? onLoaded, Function(LoadAdError)? onFailed}) {
    if (onLoaded != null) _onAdLoadedCallbacks.add(onLoaded);
    if (onFailed != null) _onAdFailedCallbacks.add(onFailed);

    if (_isAdLoaded && _rewardedAd != null) {
      _notifySuccess();
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
          _notifySuccess();
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _isAdLoaded = false;
          _isLoadingAd = false;
          _notifyFailure(error);
        },
      ),
    );
  }

  void _notifySuccess() {
    final List<VoidCallback> callbacks = List.from(_onAdLoadedCallbacks);
    _onAdLoadedCallbacks.clear();
    _onAdFailedCallbacks.clear();
    for (final cb in callbacks) {
      cb();
    }
  }

  void _notifyFailure(LoadAdError error) {
    final List<Function(LoadAdError)> callbacks = List.from(_onAdFailedCallbacks);
    _onAdLoadedCallbacks.clear();
    _onAdFailedCallbacks.clear();
    for (final cb in callbacks) {
      cb(error);
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

    // 1. If ad is loaded, show immediately
    if (_isAdLoaded && _rewardedAd != null) {
      _presentAd(context: context, onRewarded: onRewarded);
      return;
    }

    // 2. Show loading dialog and attempt to load with auto-retry
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

    void attemptLoad(int attemptsLeft) {
      loadAd(
        onLoaded: () {
          if (dialogShowing && context.mounted) {
            dialogShowing = false;
            Navigator.pop(context); // Dismiss loading dialog
            Future.delayed(const Duration(milliseconds: 300), () {
              if (context.mounted) {
                _presentAd(context: context, onRewarded: onRewarded);
              }
            });
          }
        },
        onFailed: (error) {
          if (attemptsLeft > 1) {
            // Auto-retry once if initial load failed
            attemptLoad(attemptsLeft - 1);
          } else {
            if (dialogShowing && context.mounted) {
              dialogShowing = false;
              Navigator.pop(context); // Dismiss loading dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ad loading delayed. Please tap "Watch Ad & Save" again.'),
                ),
              );
            }
          }
        },
      );
    }

    attemptLoad(2);
  }

  void _presentAd({
    required BuildContext context,
    required VoidCallback onRewarded,
  }) {
    bool userEarnedReward = false;

    if (_rewardedAd == null) return;

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
