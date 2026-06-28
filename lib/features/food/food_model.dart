class Food {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final bool isAvailable;

  Food({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.isAvailable,
  });

  factory Food.fromMap(Map data) {
    return Food(
      id: data['id'],
      name: data['name'],
      price: (data['price'] as num).toDouble(),
      imageUrl: data['image_url'] ?? '',
      isAvailable: data['is_available'] ?? true,
    );
  }
}
