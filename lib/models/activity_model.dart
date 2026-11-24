class ActivityModel {
  final String id;
  final String userName;
  final String userAvatar;
  final String actionText;
  final String targetTitle;
  final DateTime timestamp;
  final String badgeText;
  final String badgeColorType; // passed, failed, blocked, info

  const ActivityModel({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.actionText,
    required this.targetTitle,
    required this.timestamp,
    required this.badgeText,
    required this.badgeColorType,
  });
}
