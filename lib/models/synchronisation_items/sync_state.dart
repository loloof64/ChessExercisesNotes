enum SyncStatus { idle, syncing, success, error }

class SyncState {
  final SyncStatus status;
  final String? errorMessage;
  final int totalActions;
  final int completedActions;

  const SyncState({
    this.status = SyncStatus.idle,
    this.errorMessage,
    this.totalActions = 0,
    this.completedActions = 0,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? errorMessage,
    int? totalActions,
    int? completedActions,
  }) {
    return SyncState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      totalActions: totalActions ?? this.totalActions,
      completedActions: completedActions ?? this.completedActions,
    );
  }
}
