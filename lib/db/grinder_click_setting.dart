class GrinderClickSetting {
  final int? id;
  final int grinderId;
  final int grindSizeId;
  final int minClicks;
  final int maxClicks;

  GrinderClickSetting({
    this.id,
    required this.grinderId,
    required this.grindSizeId,
    required this.minClicks,
    required this.maxClicks,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grinder_id': grinderId,
      'grind_size_id': grindSizeId,
      'min_clicks': minClicks,
      'max_clicks': maxClicks,
    };
  }

  factory GrinderClickSetting.fromMap(Map<String, dynamic> map) {
    return GrinderClickSetting(
      id: map['id'] as int?,
      grinderId: map['grinder_id'] as int,
      grindSizeId: map['grind_size_id'] as int,
      minClicks: map['min_clicks'] as int,
      maxClicks: map['max_clicks'] as int,
    );
  }
}
