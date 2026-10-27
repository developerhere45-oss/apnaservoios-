package com.apnaservo.partner;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

import androidx.security.crypto.EncryptedSharedPreferences;
import androidx.security.crypto.MasterKeys;

import java.security.KeyStore;

final class PartnerSecurePreferences {
    private static final String TAG = "PartnerSecurePreferences";
    private static final String PREFS = "apna_servo_partner_v3";
    private static final String LEGACY_SPLASH_ENABLED = "splash_powered_by_enabled";
    private static final String LEGACY_SPLASH_PREFIX = "splash_powered_by_prefix";
    private static final String LEGACY_SPLASH_TEXT = "splash_powered_by_text";

    private static SharedPreferences cachedPreferences;

    private PartnerSecurePreferences() {}

    static SharedPreferences open(Context context) {
        SharedPreferences result = cachedPreferences;
        if (result != null) return result;

        synchronized (PartnerSecurePreferences.class) {
            result = cachedPreferences;
            if (result != null) return result;

            Context appContext = context.getApplicationContext();
            removeLegacyPlaintextBranding(appContext);
            String keyAlias = null;
            try {
                keyAlias = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC);
                result = createPreferences(appContext, keyAlias);
                result.getAll();
            } catch (SecurityException error) {
                Log.e(TAG, "Encrypted partner preferences are unreadable; resetting the encrypted cache", error);
                result = resetAndRecreate(appContext, keyAlias, error);
            } catch (Exception error) {
                Log.e(TAG, "Unable to open encrypted partner preferences", error);
                throw new IllegalStateException("Secure partner storage is unavailable", error);
            }
            cachedPreferences = result;
            return result;
        }
    }

    private static void removeLegacyPlaintextBranding(Context context) {
        boolean removed = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .remove(LEGACY_SPLASH_ENABLED)
                .remove(LEGACY_SPLASH_PREFIX)
                .remove(LEGACY_SPLASH_TEXT)
                .commit();
        if (!removed) {
            throw new IllegalStateException("Could not migrate legacy splash branding preferences");
        }
    }

    private static SharedPreferences resetAndRecreate(Context context, String keyAlias, SecurityException cause) {
        try {
            boolean cleared = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                    .edit()
                    .clear()
                    .commit();
            if (!cleared) {
                throw new IllegalStateException("Could not clear unreadable encrypted partner preferences");
            }

            if (keyAlias != null) {
                KeyStore keyStore = KeyStore.getInstance("AndroidKeyStore");
                keyStore.load(null);
                if (keyStore.containsAlias(keyAlias)) {
                    keyStore.deleteEntry(keyAlias);
                }
            }

            String freshKeyAlias = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC);
            SharedPreferences recovered = createPreferences(context, freshKeyAlias);
            recovered.getAll();
            Log.w(TAG, "Encrypted partner preferences were reset; the partner must sign in again");
            return recovered;
        } catch (Exception recoveryError) {
            recoveryError.addSuppressed(cause);
            Log.e(TAG, "Unable to recover encrypted partner preferences", recoveryError);
            throw new IllegalStateException("Secure partner storage could not be recovered", recoveryError);
        }
    }

    private static SharedPreferences createPreferences(Context context, String keyAlias) throws Exception {
        return EncryptedSharedPreferences.create(
                PREFS,
                keyAlias,
                context,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        );
    }
}
