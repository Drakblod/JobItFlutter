class RoutePoint {
  final int order;
  final double latitude;
  final double longitude;
  bool isCompleted;

  RoutePoint({
    required this.order,
    required this.latitude,
    required this.longitude,
    this.isCompleted = false,
  });

  factory RoutePoint.fromJson(Map<dynamic, dynamic> json) {
    return RoutePoint(
      order: json['Order'] ?? json['order'] ?? 0,
      latitude: (json['Latitude'] ?? json['latitude'] ?? 0.0) as double,
      longitude: (json['Longitude'] ?? json['longitude'] ?? 0.0) as double,
      isCompleted: json['IsCompleted'] ?? json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Order': order,
      'Latitude': latitude,
      'Longitude': longitude,
      'IsCompleted': isCompleted,
    };
  }
}
