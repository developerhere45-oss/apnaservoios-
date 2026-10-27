package com.apnaservo.partner;

import android.app.Application;
import android.content.Intent;
import android.os.Build;
import android.os.SystemClock;
import android.util.Log;

/**
 * Application entry point for the ApnaServo partner app.
 *
 * <p>This class exists for one job: give the whole app a last-resort safety net
 * so it behaves smoothly on every device, from the oldest supported Android
 * (API 24) to the newest. Low-end and old OEM builds throw in places newer
 * devices never do (missing/updated Play Services, OEM notification quirks,
 * aggressive memory killers, obscure vendor bugs). Without a global handler a
 * single unexpected exception on any thread kills the process instantly with
 * no recovery. Here we install a {@link Thread.UncaughtExceptionHandler} that:
 *   1. still reports the crash to Crashlytics through the default handler, and
 *   2. relaunches the app into a clean state instead of leaving the user on a
 *      dead screen — but only if the app was alive long enough that an instant
 *      relaunch would not create a crash-restart loop.
 */
public class PartnerApp extends Application {

    private static final String TAG = "PartnerApp";

    /**
     * If the process dies sooner than this after launch we assume start-up
     * itself is broken on this device and do NOT auto-relaunch, otherwise we
     * would spin in an endless crash/restart loop. The OS crash dialog is a
     * safer outcome in that rare case.
     */
    private static final long MIN_UPTIME_BEFORE_RESTART_MS = 8_000L;

    private long startedAtMillis;

    @Override
    public void onCreate() {
        super.onCreate();
        startedAtMillis = SystemClock.elapsedRealtime();
        installGlobalCrashFallback();
    }

    private void installGlobalCrashFallback() {
        final Thread.UncaughtExceptionHandler previousHandler =
                Thread.getDefaultUncaughtExceptionHandler();

        Thread.setDefaultUncaughtExceptionHandler((thread, throwable) -> {
            try {
                Log.e(TAG, "Uncaught exception on thread " + (thread == null ? "?" : thread.getName()), throwable);
            } catch (Throwable ignored) {
                // Logging itself must never throw further here.
            }

            boolean relaunched = false;
            try {
                long uptime = SystemClock.elapsedRealtime() - startedAtMillis;
                if (uptime >= MIN_UPTIME_BEFORE_RESTART_MS) {
                    relaunched = relaunchIntoSafeState(throwable);
                }
            } catch (Throwable ignored) {
                relaunched = false;
            }

            // Let the platform's handler run so Crashlytics records the exception.
            // The recovery launch is already scheduled and opens a safe screen.
            try {
                if (previousHandler != null) {
                    previousHandler.uncaughtException(thread, throwable);
                }
            } catch (Throwable ignored) {
                // Fall through to process termination if the platform handler fails.
            }
            try {
                android.os.Process.killProcess(android.os.Process.myPid());
                System.exit(10);
            } catch (Throwable ignored) {
                // Nothing left to do; the process is already terminating.
            }
        });
    }

    /**
     * Schedules a fresh launch of {@link MainActivity} so the user lands back on
     * the splash/login flow instead of a crashed blank screen.
     *
     * @return true if a relaunch intent was successfully scheduled.
     */
    private boolean relaunchIntoSafeState(Throwable throwable) {
        try {
            Intent intent = getPackageManager().getLaunchIntentForPackage(getPackageName());
            if (intent == null) {
                intent = new Intent(this, MainActivity.class);
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK
                    | Intent.FLAG_ACTIVITY_CLEAR_TASK
                    | Intent.FLAG_ACTIVITY_CLEAR_TOP);
            intent.putExtra(MainActivity.EXTRA_RECOVERED_FROM_CRASH, true);
            intent.putExtra(MainActivity.EXTRA_RECOVERY_DIAGNOSTIC, crashDiagnostic(throwable));

            int pendingFlags = android.app.PendingIntent.FLAG_ONE_SHOT
                    | android.app.PendingIntent.FLAG_CANCEL_CURRENT;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                pendingFlags |= android.app.PendingIntent.FLAG_IMMUTABLE;
            }
            android.app.PendingIntent pendingIntent = android.app.PendingIntent.getActivity(
                    this, 0, intent, pendingFlags);

            // Fire the relaunch ~1s after this process goes away so the new
            // process does not start inside the dying one.
            android.app.AlarmManager alarmManager =
                    (android.app.AlarmManager) getSystemService(ALARM_SERVICE);
            if (alarmManager != null) {
                alarmManager.set(
                        android.app.AlarmManager.RTC,
                        System.currentTimeMillis() + 1_000L,
                        pendingIntent);
                return true;
            }
            // Fall back to an immediate restart if AlarmManager is unavailable.
            startActivity(intent);
            return true;
        } catch (Throwable ignored) {
            return false;
        }
    }

    private String crashDiagnostic(Throwable throwable) {
        StringBuilder details = new StringBuilder(512);
        details.append("ApnaServo Partner crash diagnostic\n")
                .append("App version: ").append(BuildConfig.VERSION_NAME)
                .append(" (").append(BuildConfig.VERSION_CODE).append(")\n")
                .append("Android API: ").append(Build.VERSION.SDK_INT).append('\n')
                .append("Device: ").append(Build.MANUFACTURER).append(' ').append(Build.MODEL).append('\n')
                .append("Failure phase: Uncaught app exception\n");
        if (throwable == null) {
            details.append("Error: uncaught exception details unavailable\n");
            return details.toString();
        }
        details.append("Error type: ").append(throwable.getClass().getName()).append('\n');
        Throwable rootCause = throwable;
        for (int depth = 0; depth < 8 && rootCause.getCause() != null && rootCause.getCause() != rootCause; depth++) {
            rootCause = rootCause.getCause();
        }
        if (rootCause != throwable) {
            details.append("Root cause: ").append(rootCause.getClass().getName()).append('\n');
        }
        StackTraceElement[] frames = rootCause.getStackTrace();
        for (int index = 0; index < Math.min(frames.length, 8); index++) {
            details.append(" at ").append(frames[index]).append('\n');
        }
        return details.toString();
    }
}
