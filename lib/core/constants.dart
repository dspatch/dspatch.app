// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Human-readable application name shown in the title bar and about dialog.
const kAppName = 'd:spatch';

/// Minimum window dimensions enforced at startup.
const kMinWindowWidth = 900.0;
const kMinWindowHeight = 600.0;

/// Width below which the sidebar collapses into a drawer.
const kSidebarBreakpoint = 800.0;

/// Maximum width for centered content areas (forms, detail views).
const kContentMaxWidth = 900.0;

/// Fixed width of the sidebar / drawer in both desktop and mobile layouts.
const kSidebarWidth = 220.0;

/// HKDF info parameter for API key encryption/decryption.
const kApiKeyCryptoContext = 'api_key';

/// Whether dev-only features are enabled.
const kDevMode = false;

/// Centralized preference key constants to prevent string-literal typos.
class PreferenceKeys {
  PreferenceKeys._();

  static const themeMode = 'theme_mode';

  /// Last-used embedded server port. Reused across restarts so that
  /// surviving containers can reconnect at the same URL.
  static const serverPort = 'server_port';
}

/// Notification preference keys and their default enabled state.
class NotificationPreferenceKeys {
  NotificationPreferenceKeys._();

  static const newInquiry = 'notification.new_inquiry';
  static const highPriorityInquiry = 'notification.high_priority_inquiry';
  static const sessionCompleted = 'notification.session_completed';
  static const sessionFailed = 'notification.session_failed';

  static const defaults = {
    newInquiry: true,
    highPriorityInquiry: true,
    sessionCompleted: true,
    sessionFailed: true,
  };
}
