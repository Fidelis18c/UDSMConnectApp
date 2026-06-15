typedef UnreadRefreshCallback = void Function();

UnreadRefreshCallback? onUnreadRefreshRequested;

void requestUnreadRefresh() => onUnreadRefreshRequested?.call();