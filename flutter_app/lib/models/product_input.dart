class ProductInput {
  final String text;
  final String? url;
  final String? category;

  const ProductInput({required this.text, this.url, this.category});

  Map<String, dynamic> toJson() => {
        'text': text,
        if (url != null) 'url': url,
        if (category != null) 'category': category,
      };
}
