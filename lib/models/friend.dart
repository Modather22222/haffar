/// Friends for the social feature
class Friend {
  final String id;
  final String name;
  final String avatar;
  final int xp;
  final String league;
  final bool isOnline;

  const Friend({
    required this.id,
    required this.name,
    required this.avatar,
    required this.xp,
    required this.league,
    this.isOnline = false,
  });
}
