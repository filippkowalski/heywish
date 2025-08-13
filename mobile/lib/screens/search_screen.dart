import 'package:flutter/material.dart';
import '../services/mock_data_service.dart';
import '../theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadSuggestions() {
    setState(() {
      _suggestions = MockDataService.getMockSuggestions();
    });
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
      });
    } else {
      setState(() {
        _isSearching = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search for gifts, brands, or ideas...',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  ),
              ],
              onChanged: _onSearchChanged,
            ),
          ),
          
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildDiscoverContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: AppTheme.gray400,
          ),
          SizedBox(height: 16),
          Text('Search results coming soon!'),
          SizedBox(height: 8),
          Text(
            'We\'re working on connecting to product databases',
            style: TextStyle(color: AppTheme.gray400),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories
          _buildCategoriesSection(),
          
          // Trending and suggestions
          ..._suggestions.map((section) => _buildSuggestionSection(section)),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categories = [
      {'name': 'Electronics', 'icon': Icons.devices, 'color': AppTheme.primaryColor},
      {'name': 'Fashion', 'icon': Icons.checkroom, 'color': AppTheme.coralColor},
      {'name': 'Home & Garden', 'icon': Icons.home, 'color': AppTheme.mintColor},
      {'name': 'Books', 'icon': Icons.book, 'color': AppTheme.skyColor},
      {'name': 'Sports', 'icon': Icons.sports_tennis, 'color': AppTheme.amberColor},
      {'name': 'Beauty', 'icon': Icons.face, 'color': AppTheme.primaryColor},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse Categories',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(category);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${category['name']} category coming soon!')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: (category['color'] as Color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (category['color'] as Color).withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category['icon'] as IconData,
              size: 32,
              color: category['color'] as Color,
            ),
            const SizedBox(height: 8),
            Text(
              category['name'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: category['color'] as Color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionSection(Map<String, dynamic> section) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                section['title'] as String,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('View all coming soon!')),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: (section['items'] as List).length,
              itemBuilder: (context, index) {
                final item = (section['items'] as List)[index];
                return _buildSuggestionCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> item) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.gray100,
              ),
              child: item['image'] != null
                  ? Image.network(
                      item['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.image,
                          color: AppTheme.gray400,
                        );
                      },
                    )
                  : const Icon(
                      Icons.image,
                      color: AppTheme.gray400,
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (item['price'] != null)
                      Text(
                        '\$${item['price']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (item['trend'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getTrendColor(item['trend']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['trend'].toString().toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _getTrendColor(item['trend']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTrendColor(String trend) {
    switch (trend.toLowerCase()) {
      case 'viral':
        return AppTheme.coralColor;
      case 'popular':
        return AppTheme.primaryColor;
      case 'rising':
        return AppTheme.mintColor;
      default:
        return AppTheme.gray400;
    }
  }
}