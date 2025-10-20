import 'package:flutter/material.dart';

/// Enum representing wish item categories
enum WishCategory {
  // Electronics & Tech
  electronics,
  phone,
  computer,
  headphones,
  gaming,
  camera,

  // Fashion & Accessories
  clothing,
  shoes,
  jewelry,
  watch,
  bag,
  sunglasses,

  // Home & Living
  home,
  furniture,
  kitchen,
  decoration,

  // Beauty & Personal Care
  beauty,
  perfume,
  skincare,

  // Sports & Fitness
  sports,
  fitness,
  outdoor,

  // Books & Media
  books,
  music,
  movie,

  // Food & Beverage
  food,

  // Travel
  travel,

  // Toys & Kids
  toys,

  // Art & Craft
  art,

  // Pet
  pet,

  // Tools & Hardware
  tools,

  // Vehicles
  vehicle,

  // Baby & Kids
  baby,

  // Office & Stationery
  office,

  // Garden
  garden,

  // Health & Wellness
  health,

  // Default
  gift,
}

/// Utility class for detecting wish categories from titles and providing icons
class WishCategoryDetector {
  /// Detect category from wish title using smart scoring algorithm
  static WishCategory detectCategory(String title) {
    final lowerTitle = title.toLowerCase();

    // Score each category based on keyword matches
    final scores = <WishCategory, double>{};

    for (final category in WishCategory.values) {
      final keywords = _getKeywords(category);
      double score = 0;

      for (final keyword in keywords) {
        final lowerKeyword = keyword.toLowerCase();
        if (lowerTitle.contains(lowerKeyword)) {
          // Longer keywords get higher scores (more specific)
          // Exact word matches get bonus points
          final keywordLength = lowerKeyword.length;
          double matchScore = keywordLength.toDouble();

          // Check if it's a whole word match (not just substring)
          final pattern = RegExp('\\b${RegExp.escape(lowerKeyword)}\\b');
          if (pattern.hasMatch(lowerTitle)) {
            matchScore *= 2; // Double the score for exact word matches
          }

          score += matchScore;
        }
      }

      if (score > 0) {
        scores[category] = score;
      }
    }

    // Return category with highest score, or default if no matches
    if (scores.isEmpty) {
      return WishCategory.gift;
    }

    var maxScore = 0.0;
    var bestCategory = WishCategory.gift;

    scores.forEach((category, score) {
      if (score > maxScore) {
        maxScore = score;
        bestCategory = category;
      }
    });

    return bestCategory;
  }

  /// Get color for a category
  static Color getColor(WishCategory category) {
    switch (category) {
      // Electronics & Tech - Blue/Cyan shades
      case WishCategory.electronics:
        return const Color(0xFF2196F3); // Blue
      case WishCategory.phone:
        return const Color(0xFF00BCD4); // Cyan
      case WishCategory.computer:
        return const Color(0xFF3F51B5); // Indigo
      case WishCategory.headphones:
        return const Color(0xFF009688); // Teal
      case WishCategory.gaming:
        return const Color(0xFF9C27B0); // Purple
      case WishCategory.camera:
        return const Color(0xFF607D8B); // Blue Grey

      // Fashion & Accessories - Pink/Purple/Orange shades
      case WishCategory.clothing:
        return const Color(0xFFE91E63); // Pink
      case WishCategory.shoes:
        return const Color(0xFFFF5722); // Deep Orange
      case WishCategory.jewelry:
        return const Color(0xFFFFD700); // Gold
      case WishCategory.watch:
        return const Color(0xFF795548); // Brown
      case WishCategory.bag:
        return const Color(0xFFF06292); // Light Pink
      case WishCategory.sunglasses:
        return const Color(0xFFFFA726); // Orange

      // Home & Living - Warm tones
      case WishCategory.home:
        return const Color(0xFF8D6E63); // Brown
      case WishCategory.furniture:
        return const Color(0xFFA1887F); // Light Brown
      case WishCategory.kitchen:
        return const Color(0xFFFF9800); // Orange
      case WishCategory.decoration:
        return const Color(0xFFFFB74D); // Light Orange

      // Beauty & Personal Care - Pink/Purple shades
      case WishCategory.beauty:
        return const Color(0xFFEC407A); // Pink
      case WishCategory.perfume:
        return const Color(0xFFBA68C8); // Purple
      case WishCategory.skincare:
        return const Color(0xFFAB47BC); // Purple

      // Sports & Fitness - Green/Lime shades
      case WishCategory.sports:
        return const Color(0xFF4CAF50); // Green
      case WishCategory.fitness:
        return const Color(0xFF8BC34A); // Light Green
      case WishCategory.outdoor:
        return const Color(0xFF66BB6A); // Green

      // Books & Media - Red/Orange/Purple shades
      case WishCategory.books:
        return const Color(0xFF795548); // Brown
      case WishCategory.music:
        return const Color(0xFFE91E63); // Pink
      case WishCategory.movie:
        return const Color(0xFFF44336); // Red

      // Food & Beverage - Red/Orange shades
      case WishCategory.food:
        return const Color(0xFFFF5722); // Deep Orange

      // Travel - Blue shade
      case WishCategory.travel:
        return const Color(0xFF03A9F4); // Light Blue

      // Toys & Kids - Bright colors
      case WishCategory.toys:
        return const Color(0xFFFF6F00); // Orange

      // Art & Craft - Colorful
      case WishCategory.art:
        return const Color(0xFF9C27B0); // Purple

      // Pet - Brown/Orange
      case WishCategory.pet:
        return const Color(0xFF8D6E63); // Brown

      // Tools & Hardware - Grey
      case WishCategory.tools:
        return const Color(0xFF757575); // Grey

      // Vehicles - Dark Grey/Black
      case WishCategory.vehicle:
        return const Color(0xFF424242); // Dark Grey

      // Baby & Kids - Pastel Pink/Blue
      case WishCategory.baby:
        return const Color(0xFFFFB6C1); // Light Pink

      // Office & Stationery - Blue/Grey
      case WishCategory.office:
        return const Color(0xFF5C6BC0); // Indigo

      // Garden - Green
      case WishCategory.garden:
        return const Color(0xFF66BB6A); // Green

      // Health & Wellness - Teal/Mint
      case WishCategory.health:
        return const Color(0xFF26A69A); // Teal

      // Default - Primary color
      case WishCategory.gift:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Get icon for a category
  static IconData getIcon(WishCategory category) {
    switch (category) {
      // Electronics & Tech
      case WishCategory.electronics:
        return Icons.devices;
      case WishCategory.phone:
        return Icons.smartphone;
      case WishCategory.computer:
        return Icons.laptop_mac;
      case WishCategory.headphones:
        return Icons.headphones;
      case WishCategory.gaming:
        return Icons.sports_esports;
      case WishCategory.camera:
        return Icons.camera_alt;

      // Fashion & Accessories
      case WishCategory.clothing:
        return Icons.checkroom;
      case WishCategory.shoes:
        return Icons.sports_martial_arts; // Closest to shoes
      case WishCategory.jewelry:
        return Icons.diamond;
      case WishCategory.watch:
        return Icons.watch;
      case WishCategory.bag:
        return Icons.shopping_bag;
      case WishCategory.sunglasses:
        return Icons.wb_sunny;

      // Home & Living
      case WishCategory.home:
        return Icons.home;
      case WishCategory.furniture:
        return Icons.weekend;
      case WishCategory.kitchen:
        return Icons.kitchen;
      case WishCategory.decoration:
        return Icons.auto_awesome;

      // Beauty & Personal Care
      case WishCategory.beauty:
        return Icons.spa;
      case WishCategory.perfume:
        return Icons.water_drop;
      case WishCategory.skincare:
        return Icons.face;

      // Sports & Fitness
      case WishCategory.sports:
        return Icons.sports_soccer;
      case WishCategory.fitness:
        return Icons.fitness_center;
      case WishCategory.outdoor:
        return Icons.terrain;

      // Books & Media
      case WishCategory.books:
        return Icons.menu_book;
      case WishCategory.music:
        return Icons.music_note;
      case WishCategory.movie:
        return Icons.movie;

      // Food & Beverage
      case WishCategory.food:
        return Icons.restaurant;

      // Travel
      case WishCategory.travel:
        return Icons.flight;

      // Toys & Kids
      case WishCategory.toys:
        return Icons.toys;

      // Art & Craft
      case WishCategory.art:
        return Icons.palette;

      // Pet
      case WishCategory.pet:
        return Icons.pets;

      // Tools & Hardware
      case WishCategory.tools:
        return Icons.build;

      // Vehicles
      case WishCategory.vehicle:
        return Icons.directions_car;

      // Baby & Kids
      case WishCategory.baby:
        return Icons.child_care;

      // Office & Stationery
      case WishCategory.office:
        return Icons.work_outline;

      // Garden
      case WishCategory.garden:
        return Icons.local_florist;

      // Health & Wellness
      case WishCategory.health:
        return Icons.favorite_border;

      // Default
      case WishCategory.gift:
        return Icons.card_giftcard_outlined;
    }
  }

  /// Get keywords for a category (multilingual support)
  static List<String> _getKeywords(WishCategory category) {
    switch (category) {
      case WishCategory.electronics:
        return [
          // English
          'electronics', 'electronic', 'gadget', 'gadgets', 'device', 'devices', 'tech', 'smart', 'digital',
          // Spanish
          'electrónica', 'electrónico', 'aparato', 'aparatos', 'dispositivo', 'dispositivos', 'tecnología', 'inteligente',
          // French
          'électronique', 'appareil', 'appareils', 'technologie', 'intelligent',
          // German
          'elektronik', 'elektronisch', 'gerät', 'geräte', 'technologie', 'intelligent',
          // Portuguese
          'eletrônica', 'eletrônico', 'dispositivo', 'dispositivos', 'tecnologia', 'inteligente',
          // Italian
          'elettronica', 'elettronico', 'dispositivo', 'dispositivi', 'tecnologia', 'intelligente',
        ];

      case WishCategory.phone:
        return [
          // English
          'phone', 'iphone', 'smartphone', 'mobile', 'cell', 'samsung', 'android',
          // Spanish
          'teléfono', 'móvil', 'celular',
          // French
          'téléphone', 'portable',
          // German
          'telefon', 'handy',
          // Portuguese
          'telefone', 'celular',
          // Italian
          'telefono', 'cellulare',
        ];

      case WishCategory.computer:
        return [
          // English
          'computer', 'computers', 'laptop', 'laptops', 'macbook', 'ipad', 'ipads', 'tablet', 'tablets',
          'desktop', 'monitor', 'monitors', 'keyboard', 'keyboards', 'mouse', 'mice', 'chromebook',
          // Spanish
          'computadora', 'computadoras', 'ordenador', 'ordenadores', 'portátil', 'portátiles', 'tableta', 'tabletas', 'teclado', 'teclados', 'ratón',
          // French
          'ordinateur', 'ordinateurs', 'portable', 'portables', 'tablette', 'tablettes', 'clavier', 'claviers', 'souris',
          // German
          'computer', 'laptop', 'laptops', 'tastatur', 'tastaturen', 'maus',
          // Portuguese
          'computador', 'computadores', 'notebook', 'notebooks', 'teclado', 'teclados',
          // Italian
          'computer', 'portatile', 'portatili', 'tastiera', 'tastiere',
        ];

      case WishCategory.headphones:
        return [
          // English - single words for better matching
          'headphones', 'headphone', 'airpods', 'airpod', 'earbuds', 'earbud', 'earphone', 'earphones', 'headset', 'headsets',
          'cancelling', 'canceling', 'anc',
          // Spanish
          'auriculares', 'auricular', 'audífonos', 'audífono', 'cascos', 'casco',
          // French
          'écouteurs', 'écouteur', 'casque',
          // German
          'kopfhörer', 'ohrhörer',
          // Portuguese
          'fones', 'fone', 'auriculares', 'auricular',
          // Italian
          'cuffie', 'cuffia', 'auricolari', 'auricolare',
        ];

      case WishCategory.gaming:
        return [
          // English
          'game', 'gaming', 'playstation', 'xbox', 'nintendo', 'console', 'ps5', 'switch', 'controller', 'joystick',
          // Spanish
          'juego', 'videojuego', 'consola', 'controlador',
          // French
          'jeu', 'jeu vidéo', 'console', 'manette',
          // German
          'spiel', 'videospiel', 'konsole', 'controller',
          // Portuguese
          'jogo', 'videogame', 'console', 'controle',
          // Italian
          'gioco', 'videogioco', 'console', 'controller',
        ];

      case WishCategory.camera:
        return [
          // English
          'camera', 'lens', 'photography', 'gopro', 'dslr', 'mirrorless',
          // Spanish
          'cámara', 'lente', 'fotografía',
          // French
          'caméra', 'objectif', 'photographie',
          // German
          'kamera', 'objektiv', 'fotografie',
          // Portuguese
          'câmera', 'lente', 'fotografia',
          // Italian
          'fotocamera', 'obiettivo', 'fotografia',
        ];

      case WishCategory.clothing:
        return [
          // English
          'shirt', 'shirts', 'pants', 'dress', 'dresses', 'jacket', 'jackets', 'sweater', 'sweaters',
          'hoodie', 'hoodies', 'jeans', 'blouse', 'blouses', 'skirt', 'skirts', 'coat', 'coats',
          'tshirt', 'tee', 'polo', 'cardigan', 'blazer', 'suit', 'trousers',
          // Spanish
          'camisa', 'camisas', 'pantalón', 'pantalones', 'vestido', 'vestidos', 'chaqueta', 'chaquetas',
          'suéter', 'sudadera', 'sudaderas', 'falda', 'faldas', 'abrigo', 'abrigos', 'ropa',
          // French
          'chemise', 'chemises', 'pantalon', 'pantalons', 'robe', 'robes', 'veste', 'vestes',
          'pull', 'pulls', 'jupe', 'jupes', 'manteau', 'manteaux', 'vêtement', 'vêtements',
          // German
          'hemd', 'hemden', 'hose', 'hosen', 'kleid', 'kleider', 'jacke', 'jacken',
          'pullover', 'rock', 'röcke', 'mantel', 'mäntel', 'kleidung',
          // Portuguese
          'camisa', 'camisas', 'calça', 'calças', 'vestido', 'vestidos', 'jaqueta', 'jaquetas',
          'suéter', 'moletom', 'moletoms', 'saia', 'saias', 'casaco', 'casacos', 'roupa', 'roupas',
          // Italian
          'camicia', 'camicie', 'pantaloni', 'vestito', 'vestiti', 'giacca', 'giacche',
          'maglione', 'maglioni', 'gonna', 'gonne', 'cappotto', 'cappotti', 'abbigliamento',
        ];

      case WishCategory.shoes:
        return [
          // English
          'shoes', 'shoe', 'sneakers', 'sneaker', 'boots', 'boot', 'sandals', 'sandal', 'heels', 'heel',
          'nike', 'adidas', 'jordans', 'jordan', 'puma', 'reebok', 'vans', 'converse',
          'running', 'trainers', 'loafers', 'slippers', 'flip-flops', 'flats',
          // Spanish
          'zapatos', 'zapato', 'zapatillas', 'zapatilla', 'botas', 'bota', 'sandalias', 'sandalia', 'tacones', 'tacón', 'calzado',
          // French
          'chaussures', 'chaussure', 'baskets', 'basket', 'bottes', 'botte', 'sandales', 'sandale', 'talons', 'talon',
          // German
          'schuhe', 'schuh', 'stiefel', 'sandalen', 'sandale', 'turnschuhe',
          // Portuguese
          'sapatos', 'sapato', 'tênis', 'botas', 'bota', 'sandálias', 'sandália', 'saltos', 'salto', 'calçados', 'calçado',
          // Italian
          'scarpe', 'scarpa', 'stivali', 'stivale', 'sandali', 'sandalo', 'tacchi', 'tacco',
        ];

      case WishCategory.jewelry:
        return [
          // English
          'jewelry', 'necklace', 'ring', 'bracelet', 'earring', 'pendant', 'chain',
          // Spanish
          'joyería', 'collar', 'anillo', 'pulsera', 'pendiente', 'arete', 'cadena',
          // French
          'bijoux', 'collier', 'bague', 'bracelet', 'boucle d\'oreille', 'chaîne',
          // German
          'schmuck', 'halskette', 'ring', 'armband', 'ohrringe', 'kette',
          // Portuguese
          'joia', 'colar', 'anel', 'pulseira', 'brinco', 'corrente',
          // Italian
          'gioielli', 'collana', 'anello', 'braccialetto', 'orecchino', 'catena',
        ];

      case WishCategory.watch:
        return [
          // English
          'watch', 'smartwatch', 'apple watch', 'rolex', 'timepiece',
          // Spanish
          'reloj', 'reloj inteligente',
          // French
          'montre', 'montre connectée',
          // German
          'uhr', 'smartwatch',
          // Portuguese
          'relógio', 'smartwatch',
          // Italian
          'orologio', 'smartwatch',
        ];

      case WishCategory.bag:
        return [
          // English
          'bag', 'backpack', 'purse', 'handbag', 'wallet', 'luggage', 'suitcase', 'tote',
          // Spanish
          'bolso', 'mochila', 'cartera', 'maleta', 'equipaje',
          // French
          'sac', 'sac à dos', 'portefeuille', 'valise', 'bagage',
          // German
          'tasche', 'rucksack', 'geldbeutel', 'koffer', 'gepäck',
          // Portuguese
          'bolsa', 'mochila', 'carteira', 'mala', 'bagagem',
          // Italian
          'borsa', 'zaino', 'portafoglio', 'valigia', 'bagaglio',
        ];

      case WishCategory.sunglasses:
        return [
          // English
          'sunglasses', 'shades', 'ray-ban', 'eyewear', 'glasses',
          // Spanish
          'gafas de sol', 'lentes de sol', 'gafas',
          // French
          'lunettes de soleil', 'lunettes',
          // German
          'sonnenbrille', 'brille',
          // Portuguese
          'óculos de sol', 'óculos',
          // Italian
          'occhiali da sole', 'occhiali',
        ];

      case WishCategory.home:
        return [
          // English
          'home', 'house', 'decor', 'interior', 'living room', 'bedroom', 'bathroom',
          // Spanish
          'hogar', 'casa', 'decoración', 'sala', 'dormitorio', 'baño',
          // French
          'maison', 'décoration', 'intérieur', 'salon', 'chambre', 'salle de bain',
          // German
          'haus', 'wohnung', 'dekoration', 'wohnzimmer', 'schlafzimmer', 'badezimmer',
          // Portuguese
          'casa', 'lar', 'decoração', 'sala', 'quarto', 'banheiro',
          // Italian
          'casa', 'decorazione', 'soggiorno', 'camera', 'bagno',
        ];

      case WishCategory.furniture:
        return [
          // English
          'furniture', 'chair', 'table', 'sofa', 'couch', 'bed', 'desk', 'shelf', 'cabinet', 'dresser',
          // Spanish
          'mueble', 'silla', 'mesa', 'sofá', 'cama', 'escritorio', 'estante', 'armario', 'cómoda',
          // French
          'meuble', 'chaise', 'table', 'canapé', 'lit', 'bureau', 'étagère', 'armoire', 'commode',
          // German
          'möbel', 'stuhl', 'tisch', 'sofa', 'bett', 'schreibtisch', 'regal', 'schrank', 'kommode',
          // Portuguese
          'móvel', 'cadeira', 'mesa', 'sofá', 'cama', 'escrivaninha', 'prateleira', 'armário', 'cômoda',
          // Italian
          'mobile', 'sedia', 'tavolo', 'divano', 'letto', 'scrivania', 'scaffale', 'armadio', 'cassettiera',
        ];

      case WishCategory.kitchen:
        return [
          // English
          'kitchen', 'cookware', 'pot', 'pan', 'blender', 'toaster', 'coffee maker', 'microwave', 'oven', 'knife',
          // Spanish
          'cocina', 'olla', 'sartén', 'licuadora', 'tostadora', 'cafetera', 'microondas', 'horno', 'cuchillo',
          // French
          'cuisine', 'casserole', 'poêle', 'mixeur', 'grille-pain', 'cafetière', 'micro-ondes', 'four', 'couteau',
          // German
          'küche', 'topf', 'pfanne', 'mixer', 'toaster', 'kaffeemaschine', 'mikrowelle', 'ofen', 'messer',
          // Portuguese
          'cozinha', 'panela', 'frigideira', 'liquidificador', 'torradeira', 'cafeteira', 'micro-ondas', 'forno', 'faca',
          // Italian
          'cucina', 'pentola', 'padella', 'frullatore', 'tostapane', 'caffettiera', 'microonde', 'forno', 'coltello',
        ];

      case WishCategory.decoration:
        return [
          // English
          'decoration', 'ornament', 'vase', 'candle', 'picture frame', 'wall art', 'poster', 'plant', 'lamp', 'light',
          // Spanish
          'decoración', 'ornamento', 'jarrón', 'vela', 'marco', 'cuadro', 'póster', 'planta', 'lámpara', 'luz',
          // French
          'décoration', 'ornement', 'vase', 'bougie', 'cadre', 'tableau', 'affiche', 'plante', 'lampe', 'lumière',
          // German
          'dekoration', 'ornament', 'vase', 'kerze', 'bilderrahmen', 'wandkunst', 'poster', 'pflanze', 'lampe', 'licht',
          // Portuguese
          'decoração', 'ornamento', 'vaso', 'vela', 'porta-retrato', 'quadro', 'pôster', 'planta', 'lâmpada', 'luz',
          // Italian
          'decorazione', 'ornamento', 'vaso', 'candela', 'cornice', 'quadro', 'poster', 'pianta', 'lampada', 'luce',
        ];

      case WishCategory.beauty:
        return [
          // English
          'makeup', 'cosmetics', 'beauty', 'lipstick', 'mascara', 'foundation', 'eyeshadow', 'nail polish',
          // Spanish
          'maquillaje', 'cosméticos', 'belleza', 'labial', 'rímel', 'base', 'sombra de ojos', 'esmalte de uñas',
          // French
          'maquillage', 'cosmétiques', 'beauté', 'rouge à lèvres', 'mascara', 'fond de teint', 'fard à paupières', 'vernis à ongles',
          // German
          'make-up', 'kosmetik', 'schönheit', 'lippenstift', 'mascara', 'foundation', 'lidschatten', 'nagellack',
          // Portuguese
          'maquiagem', 'cosméticos', 'beleza', 'batom', 'máscara', 'base', 'sombra', 'esmalte',
          // Italian
          'trucco', 'cosmetici', 'bellezza', 'rossetto', 'mascara', 'fondotinta', 'ombretto', 'smalto',
        ];

      case WishCategory.perfume:
        return [
          // English
          'perfume', 'cologne', 'fragrance', 'scent', 'eau de toilette', 'eau de parfum',
          // Spanish
          'perfume', 'colonia', 'fragancia', 'aroma',
          // French
          'parfum', 'cologne', 'fragrance', 'senteur',
          // German
          'parfüm', 'duft', 'duftwasser',
          // Portuguese
          'perfume', 'colônia', 'fragrância', 'aroma',
          // Italian
          'profumo', 'fragranza', 'colonia',
        ];

      case WishCategory.skincare:
        return [
          // English
          'skincare', 'moisturizer', 'cleanser', 'serum', 'cream', 'lotion', 'face mask', 'sunscreen',
          // Spanish
          'cuidado de la piel', 'hidratante', 'limpiador', 'sérum', 'crema', 'loción', 'mascarilla', 'protector solar',
          // French
          'soin de la peau', 'hydratant', 'nettoyant', 'sérum', 'crème', 'lotion', 'masque', 'crème solaire',
          // German
          'hautpflege', 'feuchtigkeitscreme', 'reiniger', 'serum', 'creme', 'lotion', 'gesichtsmaske', 'sonnencreme',
          // Portuguese
          'cuidados com a pele', 'hidratante', 'limpador', 'sérum', 'creme', 'loção', 'máscara', 'protetor solar',
          // Italian
          'cura della pelle', 'idratante', 'detergente', 'siero', 'crema', 'lozione', 'maschera', 'crema solare',
        ];

      case WishCategory.sports:
        return [
          // English
          'sports', 'ball', 'football', 'soccer', 'basketball', 'baseball', 'tennis', 'golf', 'volleyball', 'sport',
          // Spanish
          'deportes', 'pelota', 'fútbol', 'baloncesto', 'béisbol', 'tenis', 'golf', 'voleibol', 'deporte',
          // French
          'sport', 'balle', 'football', 'basket', 'baseball', 'tennis', 'golf', 'volley',
          // German
          'sport', 'ball', 'fußball', 'basketball', 'baseball', 'tennis', 'golf', 'volleyball',
          // Portuguese
          'esporte', 'bola', 'futebol', 'basquete', 'beisebol', 'tênis', 'golfe', 'vôlei',
          // Italian
          'sport', 'palla', 'calcio', 'pallacanestro', 'baseball', 'tennis', 'golf', 'pallavolo',
        ];

      case WishCategory.fitness:
        return [
          // English
          'fitness', 'gym', 'workout', 'exercise', 'dumbbells', 'weights', 'treadmill', 'yoga mat', 'resistance band',
          // Spanish
          'fitness', 'gimnasio', 'ejercicio', 'entrenamiento', 'mancuernas', 'pesas', 'caminadora', 'colchoneta de yoga', 'banda de resistencia',
          // French
          'fitness', 'gym', 'entraînement', 'exercice', 'haltères', 'poids', 'tapis roulant', 'tapis de yoga', 'bande de résistance',
          // German
          'fitness', 'fitnessstudio', 'training', 'übung', 'hanteln', 'gewichte', 'laufband', 'yogamatte', 'widerstandsband',
          // Portuguese
          'fitness', 'academia', 'treino', 'exercício', 'halteres', 'pesos', 'esteira', 'tapete de yoga', 'faixa de resistência',
          // Italian
          'fitness', 'palestra', 'allenamento', 'esercizio', 'manubri', 'pesi', 'tapis roulant', 'tappetino yoga', 'banda di resistenza',
        ];

      case WishCategory.outdoor:
        return [
          // English
          'outdoor', 'camping', 'hiking', 'tent', 'backpack', 'sleeping bag', 'compass', 'flashlight', 'binoculars',
          // Spanish
          'exterior', 'camping', 'senderismo', 'tienda', 'mochila', 'saco de dormir', 'brújula', 'linterna', 'binoculares',
          // French
          'extérieur', 'camping', 'randonnée', 'tente', 'sac à dos', 'sac de couchage', 'boussole', 'lampe de poche', 'jumelles',
          // German
          'draußen', 'camping', 'wandern', 'zelt', 'rucksack', 'schlafsack', 'kompass', 'taschenlampe', 'fernglas',
          // Portuguese
          'ar livre', 'camping', 'caminhada', 'barraca', 'mochila', 'saco de dormir', 'bússola', 'lanterna', 'binóculos',
          // Italian
          'all\'aperto', 'campeggio', 'escursionismo', 'tenda', 'zaino', 'sacco a pelo', 'bussola', 'torcia', 'binocolo',
        ];

      case WishCategory.books:
        return [
          // English
          'book', 'novel', 'magazine', 'comic', 'manga', 'textbook', 'ebook', 'kindle', 'reading',
          // Spanish
          'libro', 'novela', 'revista', 'cómic', 'manga', 'libro de texto', 'lectura',
          // French
          'livre', 'roman', 'magazine', 'bande dessinée', 'manga', 'manuel', 'lecture',
          // German
          'buch', 'roman', 'magazin', 'comic', 'manga', 'lehrbuch', 'lesen',
          // Portuguese
          'livro', 'romance', 'revista', 'quadrinho', 'mangá', 'livro didático', 'leitura',
          // Italian
          'libro', 'romanzo', 'rivista', 'fumetto', 'manga', 'libro di testo', 'lettura',
        ];

      case WishCategory.music:
        return [
          // English
          'music', 'album', 'vinyl', 'record', 'cd', 'instrument', 'guitar', 'piano', 'drums', 'microphone', 'speaker',
          // Spanish
          'música', 'álbum', 'vinilo', 'disco', 'instrumento', 'guitarra', 'piano', 'batería', 'micrófono', 'altavoz',
          // French
          'musique', 'album', 'vinyle', 'disque', 'instrument', 'guitare', 'piano', 'batterie', 'microphone', 'haut-parleur',
          // German
          'musik', 'album', 'schallplatte', 'instrument', 'gitarre', 'klavier', 'schlagzeug', 'mikrofon', 'lautsprecher',
          // Portuguese
          'música', 'álbum', 'vinil', 'disco', 'instrumento', 'violão', 'piano', 'bateria', 'microfone', 'caixa de som',
          // Italian
          'musica', 'album', 'vinile', 'disco', 'strumento', 'chitarra', 'pianoforte', 'batteria', 'microfono', 'altoparlante',
        ];

      case WishCategory.movie:
        return [
          // English
          'movie', 'film', 'dvd', 'blu-ray', 'cinema', 'theater', 'tv show', 'series',
          // Spanish
          'película', 'filme', 'cine', 'teatro', 'serie',
          // French
          'film', 'cinéma', 'théâtre', 'série',
          // German
          'film', 'kino', 'theater', 'serie',
          // Portuguese
          'filme', 'cinema', 'teatro', 'série',
          // Italian
          'film', 'cinema', 'teatro', 'serie',
        ];

      case WishCategory.food:
        return [
          // English
          'food', 'snack', 'candy', 'chocolate', 'cookie', 'cake', 'coffee', 'tea', 'wine', 'beer', 'restaurant', 'meal',
          // Spanish
          'comida', 'snack', 'dulce', 'chocolate', 'galleta', 'pastel', 'café', 'té', 'vino', 'cerveza', 'restaurante',
          // French
          'nourriture', 'snack', 'bonbon', 'chocolat', 'biscuit', 'gâteau', 'café', 'thé', 'vin', 'bière', 'restaurant',
          // German
          'essen', 'snack', 'süßigkeit', 'schokolade', 'keks', 'kuchen', 'kaffee', 'tee', 'wein', 'bier', 'restaurant',
          // Portuguese
          'comida', 'lanche', 'doce', 'chocolate', 'biscoito', 'bolo', 'café', 'chá', 'vinho', 'cerveja', 'restaurante',
          // Italian
          'cibo', 'snack', 'caramella', 'cioccolato', 'biscotto', 'torta', 'caffè', 'tè', 'vino', 'birra', 'ristorante',
        ];

      case WishCategory.travel:
        return [
          // English
          'travel', 'trip', 'vacation', 'holiday', 'flight', 'hotel', 'ticket', 'passport', 'suitcase', 'luggage',
          // Spanish
          'viaje', 'vacaciones', 'vuelo', 'hotel', 'billete', 'pasaporte', 'maleta', 'equipaje',
          // French
          'voyage', 'vacances', 'vol', 'hôtel', 'billet', 'passeport', 'valise', 'bagage',
          // German
          'reise', 'urlaub', 'flug', 'hotel', 'ticket', 'reisepass', 'koffer', 'gepäck',
          // Portuguese
          'viagem', 'férias', 'voo', 'hotel', 'bilhete', 'passaporte', 'mala', 'bagagem',
          // Italian
          'viaggio', 'vacanza', 'volo', 'hotel', 'biglietto', 'passaporto', 'valigia', 'bagaglio',
        ];

      case WishCategory.toys:
        return [
          // English
          'toy', 'doll', 'lego', 'puzzle', 'board game', 'action figure', 'stuffed animal', 'teddy bear',
          // Spanish
          'juguete', 'muñeca', 'lego', 'rompecabezas', 'juego de mesa', 'figura de acción', 'peluche', 'oso de peluche',
          // French
          'jouet', 'poupée', 'lego', 'puzzle', 'jeu de société', 'figurine', 'peluche', 'ours en peluche',
          // German
          'spielzeug', 'puppe', 'lego', 'puzzle', 'brettspiel', 'actionfigur', 'plüschtier', 'teddybär',
          // Portuguese
          'brinquedo', 'boneca', 'lego', 'quebra-cabeça', 'jogo de tabuleiro', 'boneco', 'pelúcia', 'ursinho',
          // Italian
          'giocattolo', 'bambola', 'lego', 'puzzle', 'gioco da tavolo', 'action figure', 'peluche', 'orsacchiotto',
        ];

      case WishCategory.art:
        return [
          // English
          'art', 'painting', 'drawing', 'sketch', 'canvas', 'paint', 'brush', 'pencil', 'marker', 'craft', 'sculpture',
          // Spanish
          'arte', 'pintura', 'dibujo', 'boceto', 'lienzo', 'pincel', 'lápiz', 'marcador', 'artesanía', 'escultura',
          // French
          'art', 'peinture', 'dessin', 'esquisse', 'toile', 'pinceau', 'crayon', 'marqueur', 'artisanat', 'sculpture',
          // German
          'kunst', 'malerei', 'zeichnung', 'skizze', 'leinwand', 'pinsel', 'bleistift', 'marker', 'handwerk', 'skulptur',
          // Portuguese
          'arte', 'pintura', 'desenho', 'esboço', 'tela', 'pincel', 'lápis', 'marcador', 'artesanato', 'escultura',
          // Italian
          'arte', 'pittura', 'disegno', 'schizzo', 'tela', 'pennello', 'matita', 'pennarello', 'artigianato', 'scultura',
        ];

      case WishCategory.pet:
        return [
          // English
          'pet', 'dog', 'cat', 'bird', 'fish', 'hamster', 'rabbit', 'pet food', 'collar', 'leash', 'cage', 'aquarium',
          // Spanish
          'mascota', 'perro', 'gato', 'pájaro', 'pez', 'hámster', 'conejo', 'comida para mascotas', 'collar', 'correa', 'jaula', 'acuario',
          // French
          'animal de compagnie', 'chien', 'chat', 'oiseau', 'poisson', 'hamster', 'lapin', 'nourriture pour animaux', 'collier', 'laisse', 'cage', 'aquarium',
          // German
          'haustier', 'hund', 'katze', 'vogel', 'fisch', 'hamster', 'kaninchen', 'tierfutter', 'halsband', 'leine', 'käfig', 'aquarium',
          // Portuguese
          'animal de estimação', 'cachorro', 'gato', 'pássaro', 'peixe', 'hamster', 'coelho', 'ração', 'coleira', 'guia', 'gaiola', 'aquário',
          // Italian
          'animale domestico', 'cane', 'gatto', 'uccello', 'pesce', 'criceto', 'coniglio', 'cibo per animali', 'collare', 'guinzaglio', 'gabbia', 'acquario',
        ];

      case WishCategory.tools:
        return [
          // English
          'tool', 'hammer', 'screwdriver', 'drill', 'wrench', 'saw', 'pliers', 'toolbox', 'hardware',
          // Spanish
          'herramienta', 'martillo', 'destornillador', 'taladro', 'llave', 'sierra', 'alicates', 'caja de herramientas', 'ferretería',
          // French
          'outil', 'marteau', 'tournevis', 'perceuse', 'clé', 'scie', 'pince', 'boîte à outils', 'quincaillerie',
          // German
          'werkzeug', 'hammer', 'schraubenzieher', 'bohrer', 'schraubenschlüssel', 'säge', 'zange', 'werkzeugkasten', 'hardware',
          // Portuguese
          'ferramenta', 'martelo', 'chave de fenda', 'furadeira', 'chave inglesa', 'serra', 'alicate', 'caixa de ferramentas', 'ferragens',
          // Italian
          'attrezzo', 'martello', 'cacciavite', 'trapano', 'chiave', 'sega', 'pinza', 'cassetta degli attrezzi', 'ferramenta',
        ];

      case WishCategory.vehicle:
        return [
          // English
          'car', 'vehicle', 'automobile', 'bike', 'bicycle', 'motorcycle', 'motorbike', 'scooter', 'truck', 'van',
          'tesla', 'bmw', 'mercedes', 'audi', 'toyota', 'honda', 'ford', 'chevrolet',
          'auto parts', 'car accessories', 'tires', 'wheels',
          // Spanish
          'coche', 'carro', 'automóvil', 'vehículo', 'bicicleta', 'moto', 'motocicleta', 'camión', 'camioneta',
          'accesorios para auto', 'partes de auto', 'neumáticos', 'ruedas',
          // French
          'voiture', 'automobile', 'véhicule', 'vélo', 'bicyclette', 'moto', 'motocyclette', 'camion',
          'accessoires auto', 'pièces auto', 'pneus', 'roues',
          // German
          'auto', 'fahrzeug', 'automobil', 'fahrrad', 'motorrad', 'lkw',
          'autozubehör', 'autoteile', 'reifen', 'räder',
          // Portuguese
          'carro', 'automóvel', 'veículo', 'bicicleta', 'moto', 'motocicleta', 'caminhão',
          'acessórios de carro', 'peças de carro', 'pneus', 'rodas',
          // Italian
          'auto', 'automobile', 'veicolo', 'bicicletta', 'moto', 'motocicletta', 'camion',
          'accessori auto', 'ricambi auto', 'pneumatici', 'ruote',
        ];

      case WishCategory.baby:
        return [
          // English
          'baby', 'babies', 'infant', 'infants', 'newborn', 'newborns', 'toddler', 'toddlers',
          'stroller', 'strollers', 'crib', 'cribs', 'diaper', 'diapers', 'nappy', 'nappies',
          'bottle', 'bottles', 'pacifier', 'pacifiers', 'onesie', 'onesies',
          'monitor', 'nursing', 'breastfeeding', 'formula', 'bassinet',
          // Spanish
          'bebé', 'bebés', 'infante', 'infantes', 'carriola', 'carriolas', 'cuna', 'cunas', 'pañal', 'pañales',
          'biberón', 'biberones', 'chupete', 'chupetes', 'portabebés',
          // French
          'bébé', 'bébés', 'nourrisson', 'nourrissons', 'poussette', 'poussettes', 'berceau', 'berceaux',
          'couche', 'couches', 'biberon', 'biberons', 'tétine', 'tétines',
          // German
          'baby', 'babies', 'säugling', 'säuglinge', 'kleinkind', 'kleinkinder',
          'kinderwagen', 'krippe', 'krippen', 'windel', 'windeln',
          'babyflasche', 'babyflaschen', 'schnuller', 'babyphone', 'babytrage',
          // Portuguese
          'bebê', 'bebês', 'carrinho', 'carrinhos', 'berço', 'berços', 'fralda', 'fraldas',
          'mamadeira', 'mamadeiras', 'chupeta', 'chupetas', 'cadeirinha', 'cadeirão', 'canguru',
          // Italian
          'bambino', 'bambini', 'neonato', 'neonati', 'infante', 'infanti',
          'passeggino', 'passeggini', 'culla', 'culle', 'pannolino', 'pannolini',
          'biberon', 'ciuccio', 'seggiolino', 'seggiolone', 'marsupio',
        ];

      case WishCategory.office:
        return [
          // English
          'office', 'desk', 'desks', 'stationery', 'pen', 'pens', 'pencil', 'pencils',
          'notebook', 'notebooks', 'planner', 'planners', 'calendar', 'calendars',
          'paper', 'stapler', 'staplers', 'folder', 'folders', 'binder', 'binders',
          'organizer', 'organizers', 'filing', 'cabinet', 'whiteboard', 'whiteboards',
          'marker', 'markers', 'highlighter', 'highlighters',
          'calculator', 'calculators', 'printer', 'printers', 'scanner', 'scanners',
          'clip', 'clips', 'sticky', 'postit',
          // Spanish
          'oficina', 'escritorio', 'escritorios', 'papelería', 'pluma', 'plumas', 'lápiz', 'lápices',
          'cuaderno', 'cuadernos', 'agenda', 'agendas', 'calendario', 'calendarios',
          'papel', 'grapadora', 'grapadoras', 'carpeta', 'carpetas', 'organizador', 'organizadores',
          'archivero', 'pizarra', 'pizarras', 'marcador', 'marcadores', 'resaltador', 'resaltadores',
          'calculadora', 'calculadoras', 'impresora', 'impresoras', 'escáner',
          // French
          'bureau', 'bureaux', 'papeterie', 'stylo', 'stylos', 'crayon', 'crayons',
          'cahier', 'cahiers', 'agenda', 'agendas', 'calendrier', 'calendriers',
          'papier', 'agrafeuse', 'agrafeuses', 'dossier', 'dossiers', 'classeur', 'classeurs',
          'organisateur', 'organisateurs', 'tableau', 'marqueur', 'marqueurs', 'surligneur', 'surligneurs',
          'calculatrice', 'calculatrices', 'imprimante', 'imprimantes', 'scanner', 'trombone',
          // German
          'büro', 'schreibtisch', 'schreibwaren', 'stift', 'stifte', 'bleistift', 'bleistifte',
          'notizbuch', 'notizbücher', 'planer', 'kalender',
          'papier', 'hefter', 'ordner', 'organizer', 'aktenschrank',
          'bürostuhl', 'whiteboard', 'marker', 'textmarker',
          'taschenrechner', 'drucker', 'büroklammer', 'haftnotizen',
          // Portuguese
          'escritório', 'escritórios', 'mesa', 'mesas', 'papelaria', 'caneta', 'canetas',
          'lápis', 'caderno', 'cadernos', 'agenda', 'agendas', 'calendário', 'calendários',
          'papel', 'grampeador', 'grampeadores', 'pasta', 'pastas', 'fichário', 'fichários',
          'organizador', 'organizadores', 'arquivo', 'quadro', 'marcador', 'marcadores',
          'calculadora', 'calculadoras', 'impressora', 'impressoras', 'scanner', 'clipe',
          // Italian
          'ufficio', 'scrivania', 'scrivanie', 'cartoleria', 'penna', 'penne', 'matita', 'matite',
          'quaderno', 'quaderni', 'agenda', 'agende', 'calendario', 'calendari',
          'carta', 'cucitrice', 'cucitrici', 'cartella', 'cartelle', 'raccoglitore', 'raccoglitori',
          'organizer', 'schedario', 'lavagna', 'lavagne', 'pennarello', 'pennarelli',
          'evidenziatore', 'evidenziatori', 'calcolatrice', 'calcolatrici', 'stampante', 'stampanti', 'graffetta',
        ];

      case WishCategory.garden:
        return [
          // English
          'garden', 'plant', 'flower', 'tree', 'seed', 'pot', 'planter', 'soil',
          'gardening', 'lawn', 'grass', 'shovel', 'rake', 'hoe', 'watering can',
          'garden hose', 'sprinkler', 'fertilizer', 'compost', 'mulch',
          'outdoor furniture', 'patio', 'deck', 'grill', 'bbq', 'barbecue',
          // Spanish
          'jardín', 'planta', 'flor', 'árbol', 'semilla', 'maceta', 'tierra',
          'jardinería', 'césped', 'pala', 'rastrillo', 'azada', 'regadera',
          'manguera', 'aspersor', 'fertilizante', 'compost', 'mantillo',
          'muebles de exterior', 'patio', 'terraza', 'parrilla', 'barbacoa',
          // French
          'jardin', 'plante', 'fleur', 'arbre', 'graine', 'pot', 'terre',
          'jardinage', 'pelouse', 'gazon', 'pelle', 'râteau', 'houe', 'arrosoir',
          'tuyau', 'arroseur', 'engrais', 'compost', 'paillis',
          'mobilier d\'extérieur', 'terrasse', 'grill', 'barbecue',
          // German
          'garten', 'pflanze', 'blume', 'baum', 'samen', 'topf', 'erde',
          'gartenarbeit', 'rasen', 'schaufel', 'rechen', 'hacke', 'gießkanne',
          'gartenschlauch', 'sprinkler', 'dünger', 'kompost', 'mulch',
          'gartenmöbel', 'terrasse', 'grill',
          // Portuguese
          'jardim', 'planta', 'flor', 'árvore', 'semente', 'vaso', 'terra',
          'jardinagem', 'gramado', 'pá', 'ancinho', 'enxada', 'regador',
          'mangueira', 'aspersor', 'fertilizante', 'composto', 'cobertura',
          'móveis de jardim', 'pátio', 'churrasqueira', 'churrasco',
          // Italian
          'giardino', 'pianta', 'fiore', 'albero', 'seme', 'vaso', 'terra',
          'giardinaggio', 'prato', 'pala', 'rastrello', 'zappa', 'annaffiatoio',
          'tubo', 'irrigatore', 'fertilizzante', 'compost', 'pacciame',
          'mobili da esterno', 'patio', 'griglia', 'barbecue',
        ];

      case WishCategory.health:
        return [
          // English
          'health', 'wellness', 'vitamin', 'vitamins', 'supplement', 'supplements',
          'medicine', 'medicines', 'medication', 'medications', 'tracker',
          'thermometer', 'thermometers', 'massage', 'massager', 'massagers', 'spa',
          'aromatherapy', 'meditation', 'mindfulness', 'yoga', 'pilates', 'stretching',
          'protein', 'nutrition', 'nutritional', 'whey', 'collagen',
          // Spanish
          'salud', 'bienestar', 'vitamina', 'vitaminas', 'suplemento', 'suplementos',
          'medicina', 'medicinas', 'medicamento', 'medicamentos', 'termómetro', 'termómetros',
          'masaje', 'masajes', 'masajeador', 'masajeadores', 'aromaterapia',
          'meditación', 'proteína', 'proteínas', 'nutrición',
          // French
          'santé', 'vitamine', 'vitamines', 'supplément', 'suppléments', 'médicament', 'médicaments',
          'thermomètre', 'thermomètres', 'massage', 'massages', 'masseur', 'masseurs',
          'aromathérapie', 'méditation', 'protéine', 'protéines', 'nutrition',
          // German
          'gesundheit', 'wellness', 'vitamin', 'vitamine', 'ergänzung', 'ergänzungen',
          'medizin', 'medikament', 'medikamente', 'thermometer', 'massage', 'massagen',
          'massagegerät', 'aromatherapie', 'meditation', 'achtsamkeit',
          'protein', 'proteine', 'ernährung',
          // Portuguese
          'saúde', 'vitamina', 'vitaminas', 'suplemento', 'suplementos',
          'remédio', 'remédios', 'medicamento', 'medicamentos', 'termômetro', 'termômetros',
          'massagem', 'massagens', 'massageador', 'massageadores', 'aromaterapia',
          'meditação', 'proteína', 'proteínas', 'nutrição',
          // Italian
          'salute', 'benessere', 'vitamina', 'vitamine', 'integratore', 'integratori',
          'medicina', 'medicine', 'farmaco', 'farmaci', 'termometro', 'termometri',
          'massaggio', 'massaggi', 'massaggiatore', 'massaggiatori', 'aromaterapia',
          'meditazione', 'consapevolezza', 'proteine', 'nutrizione',
        ];

      case WishCategory.gift:
        return [
          // Default/Generic
          'gift', 'present', 'wish',
          // Spanish
          'regalo', 'presente', 'deseo',
          // French
          'cadeau', 'présent', 'souhait',
          // German
          'geschenk', 'wunsch',
          // Portuguese
          'presente', 'desejo',
          // Italian
          'regalo', 'desiderio',
        ];
    }
  }

  /// Get icon from wish title (convenience method)
  static IconData getIconFromTitle(String title) {
    final category = detectCategory(title);
    return getIcon(category);
  }

  /// Get color from wish title (convenience method)
  static Color getColorFromTitle(String title) {
    final category = detectCategory(title);
    return getColor(category);
  }

  /// Get both icon and color from wish title (convenience method)
  static (IconData, Color) getIconAndColorFromTitle(String title) {
    final category = detectCategory(title);
    return (getIcon(category), getColor(category));
  }
}
