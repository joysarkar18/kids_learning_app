import 'package:flutter/material.dart';
import '../../data/models/drawing_template.dart';

/// Bottom sheet to pick a drawing template.
class TemplateSelectorSheet extends StatelessWidget {
  final List<DrawingTemplate> templates;
  final ValueChanged<DrawingTemplate> onSelected;

  const TemplateSelectorSheet({
    super.key,
    required this.templates,
    required this.onSelected,
  });

  static void show(
    BuildContext context,
    List<DrawingTemplate> templates,
    ValueChanged<DrawingTemplate> onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TemplateSelectorSheet(
        templates: templates,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group by category
    final categories = <String, List<DrawingTemplate>>{};
    for (final t in templates) {
      final cat = t.category.isEmpty ? 'All' : t.category;
      categories.putIfAbsent(cat, () => []).add(t);
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8E1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.brown.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pick a Drawing!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: categories.length == 1
                ? _TemplateGrid(
                    templates: categories.values.first,
                    onSelected: onSelected,
                  )
                : DefaultTabController(
                    length: categories.length,
                    child: Column(
                      children: [
                        TabBar(
                          isScrollable: categories.length > 3,
                          labelColor: const Color(0xFF5D4037),
                          unselectedLabelColor: Colors.brown.withOpacity(0.5),
                          indicatorColor: const Color(0xFF4CAF50),
                          indicatorWeight: 3,
                          tabs: categories.keys
                              .map((k) => Tab(
                                    text: k[0].toUpperCase() + k.substring(1),
                                  ))
                              .toList(),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: categories.values
                                .map((list) => _TemplateGrid(
                                      templates: list,
                                      onSelected: onSelected,
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TemplateGrid extends StatelessWidget {
  final List<DrawingTemplate> templates;
  final ValueChanged<DrawingTemplate> onSelected;

  const _TemplateGrid({required this.templates, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final t = templates[index];
        return GestureDetector(
          onTap: () {
            onSelected(t);
            Navigator.of(context).pop();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBCAAA4), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: t.isNetworkImage
                          ? Image.network(
                              t.referenceImage,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.brush,
                                size: 40,
                                color: Color(0xFF5D4037),
                              ),
                            )
                          : Image.asset(
                              t.referenceImage,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.brush,
                                size: 40,
                                color: Color(0xFF5D4037),
                              ),
                            ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    t.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
