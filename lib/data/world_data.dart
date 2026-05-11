import '../models/city.dart';
import '../models/continent.dart';

class WorldData {
  static const int levelsPerContinent = 50;
  static const int totalLevels = 350; // 7 continents * 50

  static const List<Continent> continents = [
    Continent(
      id: 'europe',
      name: 'Avrupa',
      startLevel: 1,
      endLevel: 50,
      darkBgUrl: 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?q=80&w=800&auto=format&fit=crop', // Paris night
      lightBgUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?q=80&w=800&auto=format&fit=crop', // Paris day
    ),
    Continent(
      id: 'africa',
      name: 'Afrika',
      startLevel: 51,
      endLevel: 100,
      darkBgUrl: 'https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?q=80&w=800&auto=format&fit=crop',
      lightBgUrl: 'https://images.unsplash.com/photo-1523805009345-7448845a9e53?q=80&w=800&auto=format&fit=crop',
    ),
    Continent(
      id: 'asia',
      name: 'Asya',
      startLevel: 101,
      endLevel: 150,
      darkBgUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?q=80&w=800&auto=format&fit=crop',
      lightBgUrl: 'https://images.unsplash.com/photo-1464817739973-0128fe77aaa1?q=80&w=800&auto=format&fit=crop',
    ),
    Continent(
      id: 'north_america',
      name: 'Kuzey Amerika',
      startLevel: 151,
      endLevel: 200,
      darkBgUrl: 'https://images.unsplash.com/photo-1485871981521-5b1fd3805eee?q=80&w=800&auto=format&fit=crop',
      lightBgUrl: 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?q=80&w=800&auto=format&fit=crop',
    ),
    Continent(
      id: 'south_america',
      name: 'Güney Amerika',
      startLevel: 201,
      endLevel: 250,
      darkBgUrl: 'https://images.unsplash.com/photo-1518639192441-8fce0a366e2e?q=80&w=800&auto=format&fit=crop',
      lightBgUrl: 'https://images.unsplash.com/photo-1533729064979-1144ab9865fa?q=80&w=800&auto=format&fit=crop',
    ),
    Continent(
      id: 'oceania',
      name: 'Okyanusya',
      startLevel: 251,
      endLevel: 300,
      darkBgUrl: 'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?q=80&w=800&auto=format&fit=crop',
      lightBgUrl: 'https://images.unsplash.com/photo-1528072164453-f4e8ef0d475a?q=80&w=800&auto=format&fit=crop',
    ),
    Continent(
      id: 'antarctica',
      name: 'Antarktika',
      startLevel: 301,
      endLevel: 350,
      darkBgUrl: 'https://images.unsplash.com/photo-1517415170366-0dbbc910bbcb?q=80&w=800&auto=format&fit=crop',
      lightBgUrl: 'https://images.unsplash.com/photo-1473446059929-232d39891eec?q=80&w=800&auto=format&fit=crop',
    ),
  ];

  static Continent getContinentForLevel(int level) {
    for (var continent in continents) {
      if (level >= continent.startLevel && level <= continent.endLevel) {
        return continent;
      }
    }
    return continents.last;
  }

  // Returns a city if the level is a milestone (e.g. every 10 levels)
  static City? getCityUnlockedAt(int level) {
    // Determine milestone condition. For example, 10, 20, 30...
    if (level % 10 == 0) {
      final continent = getContinentForLevel(level);
      return City(
        id: 'city_$level',
        name: '${continent.name} Şehri ${level ~/ 10}',
        country: continent.name,
        unlockLevel: level,
        description: '${continent.name} kıtasındaki gizemli bir şehir.',
      );
    }
    return null;
  }
}
