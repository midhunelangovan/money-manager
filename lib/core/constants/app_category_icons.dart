import 'package:flutter/material.dart';

class CategoryIconItem {
  final String id;
  final String label;
  final IconData icon;
  final List<String> searchKeywords;

  const CategoryIconItem({
    required this.id,
    required this.label,
    required this.icon,
    this.searchKeywords = const [],
  });
}

class CategoryIconGroup {
  final String title;
  final IconData groupIcon;
  final List<CategoryIconItem> icons;

  const CategoryIconGroup({
    required this.title,
    required this.groupIcon,
    required this.icons,
  });
}

class AppCategoryIcons {
  static const List<CategoryIconGroup> groups = [
    CategoryIconGroup(
      title: 'Accounts & Money',
      groupIcon: Icons.account_balance_rounded,
      icons: [
        CategoryIconItem(id: 'account_balance_rounded', label: 'Bank', icon: Icons.account_balance_rounded, searchKeywords: ['bank', 'account', 'money', 'finance', 'institution']),
        CategoryIconItem(id: 'account_balance_wallet_rounded', label: 'Wallet', icon: Icons.account_balance_wallet_rounded, searchKeywords: ['wallet', 'money', 'salary', 'cash', 'income']),
        CategoryIconItem(id: 'savings_rounded', label: 'Savings', icon: Icons.savings_rounded, searchKeywords: ['savings', 'piggy', 'bank', 'deposit', 'interest']),
        CategoryIconItem(id: 'paid_rounded', label: 'Money Bag', icon: Icons.paid_rounded, searchKeywords: ['paid', 'money', 'bag', 'wealth', 'cash']),
        CategoryIconItem(id: 'credit_card_rounded', label: 'Card', icon: Icons.credit_card_rounded, searchKeywords: ['card', 'credit', 'debit', 'visa', 'mastercard']),
        CategoryIconItem(id: 'local_atm_rounded', label: 'ATM', icon: Icons.local_atm_rounded, searchKeywords: ['atm', 'cash', 'withdraw', 'machine']),
        CategoryIconItem(id: 'monetization_on_rounded', label: 'Coins', icon: Icons.monetization_on_rounded, searchKeywords: ['coins', 'cash', 'money', 'gold']),
        CategoryIconItem(id: 'currency_exchange_rounded', label: 'Exchange', icon: Icons.currency_exchange_rounded, searchKeywords: ['exchange', 'forex', 'currency', 'transfer']),
        CategoryIconItem(id: 'receipt_rounded', label: 'Receipt', icon: Icons.receipt_rounded, searchKeywords: ['receipt', 'bill', 'voucher', 'invoice']),
        CategoryIconItem(id: 'attach_money_rounded', label: 'Currency', icon: Icons.attach_money_rounded, searchKeywords: ['currency', 'dollar', 'rupee', 'money']),
        CategoryIconItem(id: 'request_quote_rounded', label: 'Invoice', icon: Icons.request_quote_rounded, searchKeywords: ['invoice', 'quote', 'bill', 'payment']),
        CategoryIconItem(id: 'price_check_rounded', label: 'Check', icon: Icons.price_check_rounded, searchKeywords: ['check', 'audit', 'price', 'verify']),
      ],
    ),
    CategoryIconGroup(
      title: 'Food & Dining',
      groupIcon: Icons.restaurant_rounded,
      icons: [
        CategoryIconItem(id: 'restaurant_rounded', label: 'Dining', icon: Icons.restaurant_rounded, searchKeywords: ['restaurant', 'dining', 'food', 'meal', 'dinner', 'fork', 'knife', 'plate']),
        CategoryIconItem(id: 'shopping_basket_rounded', label: 'Groceries', icon: Icons.shopping_basket_rounded, searchKeywords: ['groceries', 'basket', 'supermarket', 'food', 'market', 'cart']),
        CategoryIconItem(id: 'fastfood_rounded', label: 'Fast Food', icon: Icons.fastfood_rounded, searchKeywords: ['burger', 'food', 'fastfood', 'snack', 'lunch']),
        CategoryIconItem(id: 'shopping_cart_rounded', label: 'Cart', icon: Icons.shopping_cart_rounded, searchKeywords: ['cart', 'supermarket', 'store', 'shop']),
        CategoryIconItem(id: 'local_pizza_rounded', label: 'Pizza', icon: Icons.local_pizza_rounded, searchKeywords: ['pizza', 'italian', 'food', 'snack']),
        CategoryIconItem(id: 'local_cafe_rounded', label: 'Coffee', icon: Icons.local_cafe_rounded, searchKeywords: ['coffee', 'cafe', 'tea', 'drink', 'beverage']),
        CategoryIconItem(id: 'bakery_dining_rounded', label: 'Bakery', icon: Icons.bakery_dining_rounded, searchKeywords: ['bakery', 'bread', 'cake', 'pastry']),
        CategoryIconItem(id: 'local_bar_rounded', label: 'Bar', icon: Icons.local_bar_rounded, searchKeywords: ['bar', 'cocktail', 'drink', 'alcohol', 'party']),
        CategoryIconItem(id: 'shopping_cart_rounded', label: 'Groceries', icon: Icons.shopping_cart_rounded, searchKeywords: ['groceries', 'supermarket', 'food', 'market', 'cart']),
        CategoryIconItem(id: 'icecream_rounded', label: 'Dessert', icon: Icons.icecream_rounded, searchKeywords: ['icecream', 'dessert', 'sweet', 'treat']),
        CategoryIconItem(id: 'soup_kitchen_rounded', label: 'Kitchen', icon: Icons.soup_kitchen_rounded, searchKeywords: ['kitchen', 'cooking', 'soup', 'home food']),
        CategoryIconItem(id: 'lunch_dining_rounded', label: 'Lunch', icon: Icons.lunch_dining_rounded, searchKeywords: ['lunch', 'meal', 'food']),
        CategoryIconItem(id: 'dinner_dining_rounded', label: 'Dinner', icon: Icons.dinner_dining_rounded, searchKeywords: ['dinner', 'dining', 'food']),
        CategoryIconItem(id: 'takeout_dining_rounded', label: 'Takeout', icon: Icons.takeout_dining_rounded, searchKeywords: ['takeout', 'delivery', 'swiggy', 'zomato', 'food']),
        CategoryIconItem(id: 'local_drink_rounded', label: 'Beverage', icon: Icons.local_drink_rounded, searchKeywords: ['drink', 'beverage', 'water', 'juice']),
      ],
    ),
    CategoryIconGroup(
      title: 'Transportation',
      groupIcon: Icons.directions_car_rounded,
      icons: [
        CategoryIconItem(id: 'directions_car_rounded', label: 'Car', icon: Icons.directions_car_rounded, searchKeywords: ['car', 'auto', 'vehicle', 'drive']),
        CategoryIconItem(id: 'directions_bus_rounded', label: 'Bus', icon: Icons.directions_bus_rounded, searchKeywords: ['bus', 'transit', 'public transport']),
        CategoryIconItem(id: 'local_taxi_rounded', label: 'Taxi', icon: Icons.local_taxi_rounded, searchKeywords: ['taxi', 'cab', 'uber', 'ola']),
        CategoryIconItem(id: 'directions_bike_rounded', label: 'Bicycle', icon: Icons.directions_bike_rounded, searchKeywords: ['bike', 'bicycle', 'cycle']),
        CategoryIconItem(id: 'two_wheeler_rounded', label: 'Motorcycle', icon: Icons.two_wheeler_rounded, searchKeywords: ['motorcycle', 'scooter', 'bike', 'two wheeler']),
        CategoryIconItem(id: 'local_gas_station_rounded', label: 'Fuel', icon: Icons.local_gas_station_rounded, searchKeywords: ['fuel', 'petrol', 'diesel', 'gas', 'cng']),
        CategoryIconItem(id: 'flight_rounded', label: 'Flight', icon: Icons.flight_rounded, searchKeywords: ['flight', 'airplane', 'travel', 'airline']),
        CategoryIconItem(id: 'train_rounded', label: 'Train', icon: Icons.train_rounded, searchKeywords: ['train', 'railway', 'metro']),
        CategoryIconItem(id: 'subway_rounded', label: 'Metro', icon: Icons.subway_rounded, searchKeywords: ['subway', 'metro', 'underground']),
        CategoryIconItem(id: 'local_parking_rounded', label: 'Parking', icon: Icons.local_parking_rounded, searchKeywords: ['parking', 'park', 'garage']),
        CategoryIconItem(id: 'car_repair_rounded', label: 'Service', icon: Icons.car_repair_rounded, searchKeywords: ['service', 'repair', 'mechanic', 'maintenance']),
        CategoryIconItem(id: 'commute_rounded', label: 'Commute', icon: Icons.commute_rounded, searchKeywords: ['commute', 'travel', 'toll']),
        CategoryIconItem(id: 'electric_car_rounded', label: 'EV', icon: Icons.electric_car_rounded, searchKeywords: ['ev', 'electric car', 'charging']),
      ],
    ),
    CategoryIconGroup(
      title: 'Home & Living',
      groupIcon: Icons.home_rounded,
      icons: [
        CategoryIconItem(id: 'home_rounded', label: 'Home', icon: Icons.home_rounded, searchKeywords: ['home', 'house', 'rent', 'mortgage', 'living']),
        CategoryIconItem(id: 'house_rounded', label: 'House', icon: Icons.house_rounded, searchKeywords: ['house', 'property', 'flat', 'apartment']),
        CategoryIconItem(id: 'chair_rounded', label: 'Furniture', icon: Icons.chair_rounded, searchKeywords: ['furniture', 'chair', 'table', 'sofa', 'decor']),
        CategoryIconItem(id: 'bed_rounded', label: 'Bedroom', icon: Icons.bed_rounded, searchKeywords: ['bed', 'mattress', 'furnishing']),
        CategoryIconItem(id: 'lightbulb_rounded', label: 'Utilities', icon: Icons.lightbulb_rounded, searchKeywords: ['utilities', 'electricity', 'light', 'bulb']),
        CategoryIconItem(id: 'cleaning_services_rounded', label: 'Cleaning', icon: Icons.cleaning_services_rounded, searchKeywords: ['cleaning', 'maid', 'hygiene', 'maintenance']),
        CategoryIconItem(id: 'security_rounded', label: 'Security', icon: Icons.security_rounded, searchKeywords: ['security', 'guard', 'lock', 'alarm']),
        CategoryIconItem(id: 'handyman_rounded', label: 'Repair', icon: Icons.handyman_rounded, searchKeywords: ['repair', 'handyman', 'plumbing', 'electrician']),
        CategoryIconItem(id: 'bathtub_rounded', label: 'Bathroom', icon: Icons.bathtub_rounded, searchKeywords: ['bathroom', 'sanitary', 'bath']),
        CategoryIconItem(id: 'hardware_rounded', label: 'Tools', icon: Icons.hardware_rounded, searchKeywords: ['tools', 'hardware', 'equipment']),
      ],
    ),
    CategoryIconGroup(
      title: 'Shopping',
      groupIcon: Icons.shopping_bag_rounded,
      icons: [
        CategoryIconItem(id: 'shopping_bag_rounded', label: 'Shopping', icon: Icons.shopping_bag_rounded, searchKeywords: ['shopping', 'clothes', 'fashion', 'mall']),
        CategoryIconItem(id: 'shopping_cart_checkout_rounded', label: 'Checkout', icon: Icons.shopping_cart_checkout_rounded, searchKeywords: ['cart', 'online', 'amazon', 'flipkart']),
        CategoryIconItem(id: 'store_rounded', label: 'Store', icon: Icons.store_rounded, searchKeywords: ['store', 'shop', 'retail']),
        CategoryIconItem(id: 'local_offer_rounded', label: 'Discount', icon: Icons.local_offer_rounded, searchKeywords: ['discount', 'offer', 'coupon', 'sale']),
        CategoryIconItem(id: 'storefront_rounded', label: 'Boutique', icon: Icons.storefront_rounded, searchKeywords: ['boutique', 'market', 'mall']),
        CategoryIconItem(id: 'diamond_rounded', label: 'Jewelry', icon: Icons.diamond_rounded, searchKeywords: ['jewelry', 'gold', 'diamond', 'luxury']),
        CategoryIconItem(id: 'checkroom_rounded', label: 'Apparel', icon: Icons.checkroom_rounded, searchKeywords: ['apparel', 'clothes', 'wardrobe']),
        CategoryIconItem(id: 'watch_rounded', label: 'Watch', icon: Icons.watch_rounded, searchKeywords: ['watch', 'accessories', 'luxury']),
        CategoryIconItem(id: 'sell_rounded', label: 'Tags', icon: Icons.sell_rounded, searchKeywords: ['tags', 'brand', 'merchandise']),
      ],
    ),
    CategoryIconGroup(
      title: 'Education',
      groupIcon: Icons.school_rounded,
      icons: [
        CategoryIconItem(id: 'school_rounded', label: 'School', icon: Icons.school_rounded, searchKeywords: ['school', 'college', 'university', 'tuition', 'fees']),
        CategoryIconItem(id: 'menu_book_rounded', label: 'Books', icon: Icons.menu_book_rounded, searchKeywords: ['books', 'reading', 'textbook', 'stationery']),
        CategoryIconItem(id: 'auto_stories_rounded', label: 'Stories', icon: Icons.auto_stories_rounded, searchKeywords: ['stories', 'novel', 'literature']),
        CategoryIconItem(id: 'local_library_rounded', label: 'Library', icon: Icons.local_library_rounded, searchKeywords: ['library', 'study', 'research']),
        CategoryIconItem(id: 'computer_rounded', label: 'Courses', icon: Icons.computer_rounded, searchKeywords: ['courses', 'coding', 'online learning', 'edtech']),
        CategoryIconItem(id: 'science_rounded', label: 'Science', icon: Icons.science_rounded, searchKeywords: ['science', 'lab', 'research', 'experiment']),
        CategoryIconItem(id: 'psychology_rounded', label: 'Skills', icon: Icons.psychology_rounded, searchKeywords: ['skills', 'training', 'mind', 'learning']),
        CategoryIconItem(id: 'quiz_rounded', label: 'Exam', icon: Icons.quiz_rounded, searchKeywords: ['exam', 'test', 'certifications']),
      ],
    ),
    CategoryIconGroup(
      title: 'Health & Medical',
      groupIcon: Icons.medical_services_rounded,
      icons: [
        CategoryIconItem(id: 'medical_services_rounded', label: 'Doctor', icon: Icons.medical_services_rounded, searchKeywords: ['doctor', 'clinic', 'hospital', 'consultation']),
        CategoryIconItem(id: 'local_hospital_rounded', label: 'Hospital', icon: Icons.local_hospital_rounded, searchKeywords: ['hospital', 'emergency', 'surgery']),
        CategoryIconItem(id: 'medication_rounded', label: 'Medicine', icon: Icons.medication_rounded, searchKeywords: ['medicine', 'pharmacy', 'pills', 'drugs', 'chemist']),
        CategoryIconItem(id: 'favorite_rounded', label: 'Health', icon: Icons.favorite_rounded, searchKeywords: ['health', 'cardio', 'wellness', 'checkup']),
        CategoryIconItem(id: 'healing_rounded', label: 'First Aid', icon: Icons.healing_rounded, searchKeywords: ['first aid', 'bandage', 'treatment']),
        CategoryIconItem(id: 'fitness_center_rounded', label: 'Fitness', icon: Icons.fitness_center_rounded, searchKeywords: ['fitness', 'gym', 'workout', 'exercise']),
        CategoryIconItem(id: 'spa_rounded', label: 'Wellness', icon: Icons.spa_rounded, searchKeywords: ['wellness', 'spa', 'massage', 'therapy']),
        CategoryIconItem(id: 'health_and_safety_rounded', label: 'Dental', icon: Icons.health_and_safety_rounded, searchKeywords: ['dental', 'teeth', 'care', 'safety']),
      ],
    ),
    CategoryIconGroup(
      title: 'Personal Care',
      groupIcon: Icons.face_rounded,
      icons: [
        CategoryIconItem(id: 'face_rounded', label: 'Salon', icon: Icons.face_rounded, searchKeywords: ['salon', 'beauty', 'parlour', 'grooming']),
        CategoryIconItem(id: 'content_cut_rounded', label: 'Haircut', icon: Icons.content_cut_rounded, searchKeywords: ['haircut', 'barber', 'salon']),
        CategoryIconItem(id: 'self_improvement_rounded', label: 'Yoga', icon: Icons.self_improvement_rounded, searchKeywords: ['yoga', 'meditation', 'mindfulness']),
        CategoryIconItem(id: 'style_rounded', label: 'Cosmetics', icon: Icons.style_rounded, searchKeywords: ['cosmetics', 'makeup', 'skincare']),
        CategoryIconItem(id: 'dry_cleaning_rounded', label: 'Laundry', icon: Icons.dry_cleaning_rounded, searchKeywords: ['laundry', 'dry cleaning', 'ironing', 'wash']),
        CategoryIconItem(id: 'pool_rounded', label: 'Swim', icon: Icons.pool_rounded, searchKeywords: ['swim', 'pool', 'sports']),
      ],
    ),
    CategoryIconGroup(
      title: 'Entertainment & Leisure',
      groupIcon: Icons.movie_rounded,
      icons: [
        CategoryIconItem(id: 'movie_rounded', label: 'Cinema', icon: Icons.movie_rounded, searchKeywords: ['cinema', 'movie', 'film', 'theatre', 'netflix']),
        CategoryIconItem(id: 'music_note_rounded', label: 'Music', icon: Icons.music_note_rounded, searchKeywords: ['music', 'spotify', 'concert', 'songs']),
        CategoryIconItem(id: 'sports_esports_rounded', label: 'Gaming', icon: Icons.sports_esports_rounded, searchKeywords: ['gaming', 'games', 'playstation', 'xbox', 'steam']),
        CategoryIconItem(id: 'sports_soccer_rounded', label: 'Sports', icon: Icons.sports_soccer_rounded, searchKeywords: ['sports', 'football', 'cricket', 'game']),
        CategoryIconItem(id: 'theater_comedy_rounded', label: 'Events', icon: Icons.theater_comedy_rounded, searchKeywords: ['events', 'shows', 'standup', 'comedy']),
        CategoryIconItem(id: 'tv_rounded', label: 'Streaming', icon: Icons.tv_rounded, searchKeywords: ['streaming', 'tv', 'hotstar', 'prime', 'ott']),
        CategoryIconItem(id: 'celebration_rounded', label: 'Party', icon: Icons.celebration_rounded, searchKeywords: ['party', 'celebration', 'festival', 'club']),
        CategoryIconItem(id: 'headphones_rounded', label: 'Audio', icon: Icons.headphones_rounded, searchKeywords: ['audio', 'podcast', 'headphones']),
        CategoryIconItem(id: 'casino_rounded', label: 'Casino', icon: Icons.casino_rounded, searchKeywords: ['casino', 'lottery', 'gambling']),
      ],
    ),
    CategoryIconGroup(
      title: 'Travel & Vacation',
      groupIcon: Icons.luggage_rounded,
      icons: [
        CategoryIconItem(id: 'luggage_rounded', label: 'Travel', icon: Icons.luggage_rounded, searchKeywords: ['travel', 'trip', 'luggage', 'holiday', 'vacation']),
        CategoryIconItem(id: 'hotel_rounded', label: 'Hotel', icon: Icons.hotel_rounded, searchKeywords: ['hotel', 'resort', 'stay', 'airbnb']),
        CategoryIconItem(id: 'beach_access_rounded', label: 'Beach', icon: Icons.beach_access_rounded, searchKeywords: ['beach', 'vacation', 'holiday', 'sun']),
        CategoryIconItem(id: 'map_rounded', label: 'Sightseeing', icon: Icons.map_rounded, searchKeywords: ['sightseeing', 'map', 'tour', 'guide']),
        CategoryIconItem(id: 'explore_rounded', label: 'Adventure', icon: Icons.explore_rounded, searchKeywords: ['adventure', 'trek', 'explore']),
        CategoryIconItem(id: 'forest_rounded', label: 'Nature', icon: Icons.forest_rounded, searchKeywords: ['nature', 'forest', 'camping', 'park']),
        CategoryIconItem(id: 'terrain_rounded', label: 'Mountain', icon: Icons.terrain_rounded, searchKeywords: ['mountain', 'hills', 'hiking']),
        CategoryIconItem(id: 'sailing_rounded', label: 'Cruise', icon: Icons.sailing_rounded, searchKeywords: ['cruise', 'boat', 'sailing']),
      ],
    ),
    CategoryIconGroup(
      title: 'Work & Business',
      groupIcon: Icons.business_center_rounded,
      icons: [
        CategoryIconItem(id: 'business_center_rounded', label: 'Business', icon: Icons.business_center_rounded, searchKeywords: ['business', 'work', 'office', 'freelance']),
        CategoryIconItem(id: 'laptop_mac_rounded', label: 'Office', icon: Icons.laptop_mac_rounded, searchKeywords: ['office', 'tech', 'software', 'hardware']),
        CategoryIconItem(id: 'work_history_rounded', label: 'Projects', icon: Icons.work_history_rounded, searchKeywords: ['projects', 'consulting', 'contract']),
        CategoryIconItem(id: 'badge_rounded', label: 'Salary', icon: Icons.badge_rounded, searchKeywords: ['salary', 'wages', 'employment', 'bonus']),
        CategoryIconItem(id: 'analytics_rounded', label: 'Analytics', icon: Icons.analytics_rounded, searchKeywords: ['analytics', 'metrics', 'marketing']),
        CategoryIconItem(id: 'groups_rounded', label: 'Team', icon: Icons.groups_rounded, searchKeywords: ['team', 'clients', 'meeting']),
        CategoryIconItem(id: 'factory_rounded', label: 'Production', icon: Icons.factory_rounded, searchKeywords: ['production', 'manufacturing', 'industry']),
        CategoryIconItem(id: 'engineering_rounded', label: 'Engineering', icon: Icons.engineering_rounded, searchKeywords: ['engineering', 'construction', 'tech']),
      ],
    ),
    CategoryIconGroup(
      title: 'Family & Social',
      groupIcon: Icons.family_restroom_rounded,
      icons: [
        CategoryIconItem(id: 'family_restroom_rounded', label: 'Family', icon: Icons.family_restroom_rounded, searchKeywords: ['family', 'kids', 'parents', 'home']),
        CategoryIconItem(id: 'child_care_rounded', label: 'Kids', icon: Icons.child_care_rounded, searchKeywords: ['kids', 'baby', 'childcare', 'toys', 'daycare']),
        CategoryIconItem(id: 'pets_rounded', label: 'Pets', icon: Icons.pets_rounded, searchKeywords: ['pets', 'dog', 'cat', 'vet', 'pet food']),
        CategoryIconItem(id: 'people_rounded', label: 'Friends', icon: Icons.people_rounded, searchKeywords: ['friends', 'gathering', 'social']),
        CategoryIconItem(id: 'cake_rounded', label: 'Birthday', icon: Icons.cake_rounded, searchKeywords: ['birthday', 'anniversary', 'celebration']),
        CategoryIconItem(id: 'volunteer_activism_rounded', label: 'Donation', icon: Icons.volunteer_activism_rounded, searchKeywords: ['donation', 'charity', 'help', 'ngo']),
        CategoryIconItem(id: 'handshake_rounded', label: 'Repayments', icon: Icons.handshake_rounded, searchKeywords: ['repayments', 'borrow', 'lend', 'settlement', 'debt']),
      ],
    ),
    CategoryIconGroup(
      title: 'Bills & Utilities',
      groupIcon: Icons.receipt_long_rounded,
      icons: [
        CategoryIconItem(id: 'receipt_long_rounded', label: 'Bills', icon: Icons.receipt_long_rounded, searchKeywords: ['bills', 'utility', 'due', 'monthly']),
        CategoryIconItem(id: 'electric_bolt_rounded', label: 'Electricity', icon: Icons.electric_bolt_rounded, searchKeywords: ['electricity', 'power', 'current', 'eb bill']),
        CategoryIconItem(id: 'water_drop_rounded', label: 'Water', icon: Icons.water_drop_rounded, searchKeywords: ['water', 'utilities', 'tanker']),
        CategoryIconItem(id: 'wifi_rounded', label: 'Internet', icon: Icons.wifi_rounded, searchKeywords: ['internet', 'wifi', 'broadband', 'fiber']),
        CategoryIconItem(id: 'phone_android_rounded', label: 'Mobile', icon: Icons.phone_android_rounded, searchKeywords: ['mobile', 'recharge', 'phone', 'postpaid', 'prepaid']),
        CategoryIconItem(id: 'connected_tv_rounded', label: 'DTH / Cable', icon: Icons.connected_tv_rounded, searchKeywords: ['dth', 'cable', 'tata play', 'dish tv']),
        CategoryIconItem(id: 'shield_rounded', label: 'Insurance', icon: Icons.shield_rounded, searchKeywords: ['insurance', 'policy', 'premium', 'lic']),
        CategoryIconItem(id: 'subscriptions_rounded', label: 'Subscriptions', icon: Icons.subscriptions_rounded, searchKeywords: ['subscriptions', 'recurring', 'software']),
      ],
    ),
    CategoryIconGroup(
      title: 'Investments',
      groupIcon: Icons.trending_up_rounded,
      icons: [
        CategoryIconItem(id: 'trending_up_rounded', label: 'Stocks', icon: Icons.trending_up_rounded, searchKeywords: ['stocks', 'equity', 'shares', 'trading', 'sip']),
        CategoryIconItem(id: 'show_chart_rounded', label: 'Mutual Funds', icon: Icons.show_chart_rounded, searchKeywords: ['mutual funds', 'mf', 'growth', 'index']),
        CategoryIconItem(id: 'apartment_rounded', label: 'Real Estate', icon: Icons.apartment_rounded, searchKeywords: ['real estate', 'land', 'commercial', 'property']),
        CategoryIconItem(id: 'stars_rounded', label: 'Gold', icon: Icons.stars_rounded, searchKeywords: ['gold', 'sovereign', 'silver', 'precious metal']),
        CategoryIconItem(id: 'query_stats_rounded', label: 'Crypto', icon: Icons.query_stats_rounded, searchKeywords: ['crypto', 'bitcoin', 'tokens', 'defi']),
        CategoryIconItem(id: 'equalizer_rounded', label: 'Bonds', icon: Icons.equalizer_rounded, searchKeywords: ['bonds', 'fd', 'fixed deposit', 'ppf']),
      ],
    ),
    CategoryIconGroup(
      title: 'Gifts & Donations',
      groupIcon: Icons.card_giftcard_rounded,
      icons: [
        CategoryIconItem(id: 'card_giftcard_rounded', label: 'Gifts', icon: Icons.card_giftcard_rounded, searchKeywords: ['gifts', 'present', 'reward']),
        CategoryIconItem(id: 'redeem_rounded', label: 'Rewards', icon: Icons.redeem_rounded, searchKeywords: ['rewards', 'cashback', 'coupon']),
        CategoryIconItem(id: 'loyalty_rounded', label: 'Loyalty', icon: Icons.loyalty_rounded, searchKeywords: ['loyalty', 'points', 'membership']),
        CategoryIconItem(id: 'favorite_border_rounded', label: 'Charity', icon: Icons.favorite_border_rounded, searchKeywords: ['charity', 'donation', 'social cause']),
      ],
    ),
    CategoryIconGroup(
      title: 'Other',
      groupIcon: Icons.category_rounded,
      icons: [
        CategoryIconItem(id: 'category_rounded', label: 'General', icon: Icons.category_rounded, searchKeywords: ['general', 'other', 'misc', 'category']),
        CategoryIconItem(id: 'star_rounded', label: 'Special', icon: Icons.star_rounded, searchKeywords: ['special', 'star', 'custom']),
        CategoryIconItem(id: 'extension_rounded', label: 'Plugins', icon: Icons.extension_rounded, searchKeywords: ['plugins', 'extra', 'puzzle']),
        CategoryIconItem(id: 'task_alt_rounded', label: 'Tasks', icon: Icons.task_alt_rounded, searchKeywords: ['tasks', 'checklist', 'goals']),
        CategoryIconItem(id: 'bookmark_rounded', label: 'Saved', icon: Icons.bookmark_rounded, searchKeywords: ['saved', 'bookmark', 'favorite']),
        CategoryIconItem(id: 'help_outline_rounded', label: 'Unknown', icon: Icons.help_outline_rounded, searchKeywords: ['unknown', 'other', 'question']),
      ],
    ),
  ];

  static IconData getIconData(String? iconName) {
    if (iconName == null || iconName.isEmpty) return Icons.category_rounded;
    for (final group in groups) {
      for (final item in group.icons) {
        if (item.id == iconName) return item.icon;
      }
    }
    // Fallback legacy aliases
    switch (iconName.toLowerCase()) {
      case 'restaurant':
      case 'restaurant_outlined':
      case 'restaurant_rounded':
      case 'food':
      case 'dining':
      case 'food & dining':
        return Icons.restaurant_rounded;
      case 'shopping_basket':
      case 'shopping_basket_outlined':
      case 'shopping_basket_rounded':
      case 'groceries':
      case 'grocery':
        return Icons.shopping_basket_rounded;
      case 'shopping_cart':
      case 'shopping_cart_outlined':
      case 'shopping_cart_rounded':
      case 'cart':
        return Icons.shopping_cart_rounded;
      case 'fastfood':
      case 'fastfood_rounded':
      case 'burger':
        return Icons.fastfood_rounded;
      case 'directions_car':
      case 'directions_car_outlined':
      case 'directions_car_rounded':
      case 'transport':
      case 'transportation':
      case 'car':
        return Icons.directions_car_rounded;
      case 'local_gas_station':
      case 'local_gas_station_outlined':
      case 'local_gas_station_rounded':
      case 'fuel':
      case 'gas':
      case 'petrol':
        return Icons.local_gas_station_rounded;
      case 'shopping_bag':
      case 'shopping_bag_outlined':
      case 'shopping_bag_rounded':
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'receipt_long':
      case 'receipt_long_outlined':
      case 'receipt_long_rounded':
      case 'receipt':
      case 'receipt_rounded':
      case 'bills':
      case 'bills & utilities':
      case 'utilities':
        return Icons.receipt_long_rounded;
      case 'medical_services':
      case 'medical_services_outlined':
      case 'medical_services_rounded':
      case 'health':
      case 'healthcare':
      case 'medical':
        return Icons.medical_services_rounded;
      case 'school':
      case 'school_outlined':
      case 'school_rounded':
      case 'education':
        return Icons.school_rounded;
      case 'luggage':
      case 'luggage_rounded':
      case 'flight':
      case 'flight_rounded':
      case 'travel':
      case 'vacation':
        return Icons.luggage_rounded;
      case 'movie':
      case 'movie_outlined':
      case 'movie_rounded':
      case 'entertainment':
        return Icons.movie_rounded;
      case 'home':
      case 'home_outlined':
      case 'home_rounded':
      case 'house':
      case 'housing & rent':
      case 'rent':
        return Icons.home_rounded;
      case 'spa':
      case 'spa_rounded':
      case 'face':
      case 'face_rounded':
      case 'personal care':
      case 'grooming':
        return Icons.spa_rounded;
      case 'subscriptions':
      case 'subscriptions_rounded':
      case 'recurring':
        return Icons.subscriptions_rounded;
      case 'trending_up':
      case 'trending_up_outlined':
      case 'trending_up_rounded':
      case 'investment':
      case 'investment & dividends':
      case 'investments':
      case 'stocks':
        return Icons.trending_up_rounded;
      case 'account_balance':
      case 'account_balance_outlined':
      case 'account_balance_rounded':
      case 'bank':
      case 'banking':
        return Icons.account_balance_rounded;
      case 'account_balance_wallet':
      case 'account_balance_wallet_outlined':
      case 'account_balance_wallet_rounded':
      case 'wallet':
      case 'cash':
        return Icons.account_balance_wallet_rounded;
      case 'payments':
      case 'payments_outlined':
      case 'payments_rounded':
      case 'salary':
        return Icons.payments_rounded;
      case 'savings':
      case 'savings_outlined':
      case 'savings_rounded':
        return Icons.savings_rounded;
      case 'card_giftcard':
      case 'card_giftcard_outlined':
      case 'card_giftcard_rounded':
      case 'gifts':
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'work':
      case 'work_outline':
      case 'business':
      case 'business_center_rounded':
        return Icons.business_center_rounded;
      case 'category':
      case 'category_outlined':
      case 'category_rounded':
      default:
        return Icons.category_rounded;
    }
  }
}
