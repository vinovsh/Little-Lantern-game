package com.rendermind.littlelantern;

import android.app.Activity;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import androidx.annotation.NonNull;
import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;
import com.google.android.gms.ads.rewarded.RewardedAd;
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback;
import com.google.android.ump.ConsentInformation;
import com.google.android.ump.ConsentRequestParameters;
import com.google.android.ump.UserMessagingPlatform;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

/** Native SDK bridge. Disabled until the publisher explicitly configures ads. */
public final class LanternAds extends GodotPlugin {
    private final Handler main = new Handler(Looper.getMainLooper());
    private volatile RewardedAd rewarded;
    private volatile InterstitialAd interstitial;
    private volatile boolean enabled, foreground = true, showing, initializing, initialized;
    private volatile boolean privacyRequired;
    private boolean loadingRewarded, loadingInterstitial;
    private long rewardedAt, interstitialAt;
    private int rewardFailures, interstitialFailures;
    private ConsentInformation consent;
    private String rewardedId = "ca-app-pub-3940256099942544/5224354917";
    private String interstitialId = "ca-app-pub-3940256099942544/1033173712";
    private static final long MAX_AGE_MS = 55 * 60 * 1000;

    public LanternAds(Godot godot) { super(godot); }
    @NonNull @Override public String getPluginName() { return "LanternAds"; }
    @NonNull @Override public Set<SignalInfo> getPluginSignals() {
        return new HashSet<>(Arrays.asList(
            new SignalInfo("reward_earned", String.class, String.class),
            new SignalInfo("ad_closed"), new SignalInfo("availability_changed")));
    }

    @UsedByGodot public void initialize() {
        main.post(() -> {
            Activity activity = getActivity();
            if (activity == null || initializing || initialized) return;
            try {
                ApplicationInfo info = activity.getPackageManager().getApplicationInfo(activity.getPackageName(), PackageManager.GET_META_DATA);
                Bundle config = info.metaData;
                enabled = config != null && config.getBoolean("littlelantern.ads_enabled", false);
                if (!enabled) return;
                rewardedId = config.getString("littlelantern.rewarded_id", rewardedId);
                interstitialId = config.getString("littlelantern.interstitial_id", interstitialId);
            } catch (PackageManager.NameNotFoundException e) { return; }
            initializing = true;
            consent = UserMessagingPlatform.getConsentInformation(activity);
            consent.requestConsentInfoUpdate(activity, new ConsentRequestParameters.Builder().build(), () -> {
                privacyRequired = consent.getPrivacyOptionsRequirementStatus() == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED;
                emitSignal("availability_changed");
                UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity, error -> maybeInitialize());
                maybeInitialize();
            }, error -> maybeInitialize());
        });
    }

    private void maybeInitialize() {
        if (!enabled || initialized || consent == null || !consent.canRequestAds() || getActivity() == null) return;
        initialized = true; // Set before either consent callback can enter again.
        MobileAds.initialize(getActivity(), status -> main.post(() -> { loadRewarded(); loadInterstitial(); }));
    }
    @UsedByGodot public boolean is_enabled() { return enabled; }
    @UsedByGodot public boolean is_rewarded_ready() {
        return enabled && foreground && !showing && rewarded != null && SystemClock.elapsedRealtime() - rewardedAt < MAX_AGE_MS;
    }
    @UsedByGodot public boolean is_interstitial_ready() {
        return enabled && foreground && !showing && interstitial != null && SystemClock.elapsedRealtime() - interstitialAt < MAX_AGE_MS;
    }
    @UsedByGodot public boolean privacy_options_required() { return enabled && privacyRequired; }
    @UsedByGodot public void show_privacy_options() {
        main.post(() -> {
            if (privacyRequired && getActivity() != null) {
                UserMessagingPlatform.showPrivacyOptionsForm(getActivity(), error -> {
                    rewarded = null; interstitial = null;
                    emitSignal("availability_changed");
                    if (consent.canRequestAds()) { maybeInitialize(); loadRewarded(); loadInterstitial(); }
                });
            }
        });
    }

    private boolean canLoad() { return enabled && initialized && foreground && consent != null && consent.canRequestAds() && getActivity() != null; }
    private void loadRewarded() {
        if (!canLoad() || loadingRewarded || (rewarded != null && SystemClock.elapsedRealtime() - rewardedAt < MAX_AGE_MS)) return;
        loadingRewarded = true;
        RewardedAd.load(getActivity(), rewardedId, new AdRequest.Builder().build(), new RewardedAdLoadCallback() {
            @Override public void onAdLoaded(@NonNull RewardedAd ad) {
                if (!enabled) return;
                loadingRewarded = false; rewardFailures = 0; rewarded = ad; rewardedAt = SystemClock.elapsedRealtime();
                emitSignal("availability_changed");
            }
            @Override public void onAdFailedToLoad(@NonNull LoadAdError error) {
                loadingRewarded = false; rewarded = null;
                emitSignal("availability_changed");
                main.postDelayed(() -> loadRewarded(), Math.min(120000, 5000L << Math.min(5, rewardFailures++)));
            }
        });
    }
    private void loadInterstitial() {
        if (!canLoad() || loadingInterstitial || (interstitial != null && SystemClock.elapsedRealtime() - interstitialAt < MAX_AGE_MS)) return;
        loadingInterstitial = true;
        InterstitialAd.load(getActivity(), interstitialId, new AdRequest.Builder().build(), new InterstitialAdLoadCallback() {
            @Override public void onAdLoaded(@NonNull InterstitialAd ad) {
                if (!enabled) return;
                loadingInterstitial = false; interstitialFailures = 0; interstitial = ad; interstitialAt = SystemClock.elapsedRealtime();
            }
            @Override public void onAdFailedToLoad(@NonNull LoadAdError error) {
                loadingInterstitial = false; interstitial = null;
                main.postDelayed(() -> loadInterstitial(), Math.min(120000, 5000L << Math.min(5, interstitialFailures++)));
            }
        });
    }

    @UsedByGodot public void show_rewarded(String placement, String token) {
        main.post(() -> {
            if (!is_rewarded_ready()) { emitSignal("ad_closed"); loadRewarded(); return; }
            RewardedAd ad = rewarded; rewarded = null; showing = true;
            emitSignal("availability_changed");
            ad.setFullScreenContentCallback(new FullScreenContentCallback() {
                @Override public void onAdDismissedFullScreenContent() { closeAd(); loadRewarded(); }
                @Override public void onAdFailedToShowFullScreenContent(@NonNull AdError error) { closeAd(); loadRewarded(); }
            });
            ad.show(getActivity(), reward -> emitSignal("reward_earned", placement, token));
        });
    }
    @UsedByGodot public void show_interstitial() {
        main.post(() -> {
            if (!is_interstitial_ready()) { emitSignal("ad_closed"); loadInterstitial(); return; }
            InterstitialAd ad = interstitial; interstitial = null; showing = true;
            ad.setFullScreenContentCallback(new FullScreenContentCallback() {
                @Override public void onAdDismissedFullScreenContent() { closeAd(); loadInterstitial(); }
                @Override public void onAdFailedToShowFullScreenContent(@NonNull AdError error) { closeAd(); loadInterstitial(); }
            });
            ad.show(getActivity());
        });
    }
    private void closeAd() { if (!showing) return; showing = false; emitSignal("ad_closed"); emitSignal("availability_changed"); }
    @Override public void onMainPause() { foreground = false; }
    @Override public void onMainResume() {
        foreground = true;
        if (initialized) main.post(() -> { loadRewarded(); loadInterstitial(); });
    }
    @Override public void onMainDestroy() {
        enabled = false; initialized = false;
        main.removeCallbacksAndMessages(null);
        rewarded = null; interstitial = null;
    }
}
