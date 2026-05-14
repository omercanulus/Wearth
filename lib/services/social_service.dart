import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserProfile {
  final String uid;
  final String username;
  final String? email;

  UserProfile({required this.uid, required this.username, this.email});

  factory UserProfile.fromJson(Map<dynamic, dynamic> json) => UserProfile(
    uid: json['uid'] as String? ?? '',
    username: json['username'] as String? ?? 'Anonim',
    email: json['email'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'username': username,
    'email': email,
  };
}

class SocialService {
  static final SocialService _instance = SocialService._internal();
  factory SocialService() => _instance;
  SocialService._internal();

  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;
  String? get currentUid => _currentUser?.uid;

  // ─── Profil Yönetimi ───────────────────────────────────────────

  /// Kullanıcı profilini oluşturur veya günceller.
  Future<void> ensureProfile() async {
    final user = _currentUser;
    if (user == null) return;

    try {
      final userRef = _db.ref('users/${user.uid}');
      final snapshot = await userRef.get();
      final data = snapshot.value as Map?;

      // Eğer profil yoksa VEYA kullanıcı adı alanı eksikse/boşsa oluştur/güncelle
      if (!snapshot.exists || data == null || data['username'] == null || data['username'] == 'Anonim') {
        String baseUsername = user.displayName ?? user.email?.split('@')[0] ?? 'User';
        // Özel karakterleri temizle
        baseUsername = baseUsername.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
        if (baseUsername.isEmpty) baseUsername = 'User';
        
        String username = baseUsername;
        int counter = 1;
        
        // Benzersiz kullanıcı adı bulana kadar döngü
        while (!(await isUsernameAvailable(username))) {
          username = '$baseUsername$counter';
          counter++;
        }

        final profileData = {
          'uid': user.uid,
          'username': username,
          'email': user.email,
          'updatedAt': ServerValue.timestamp,
        };

        if (!snapshot.exists) {
          profileData['createdAt'] = ServerValue.timestamp;
        }

        await userRef.update(profileData);
        
        // Arama ve benzersizlik için username index'i oluştur
        await _db.ref('usernames/${username.toLowerCase()}').set(user.uid);
      }
    } catch (e) {
      print('Profile güncelleme hatası: $e');
    }
  }

  /// Kullanıcı adının müsait olup olmadığını kontrol eder.
  Future<bool> isUsernameAvailable(String username) async {
    if (username.isEmpty) return false;
    final snapshot = await _db.ref('usernames/${username.toLowerCase()}').get();
    return !snapshot.exists;
  }

  /// Kullanıcı adına göre arama yapar.
  Future<List<UserProfile>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    
    try {
      // 1. Önce tam eşleşme ara (Daha hızlı ve kesin)
      final exactSnapshot = await _db.ref('usernames/${query.toLowerCase()}').get();
      if (exactSnapshot.exists) {
        final uid = exactSnapshot.value.toString();
        if (uid != _currentUser?.uid) {
          final profile = await getUserProfile(uid);
          if (profile != null) return [profile];
        }
      }

      // 2. Prefix search (Index gerektirir, hata alabilir)
      // Query'yi lowercase yapmıyoruz çünkü RTDB index'i case-sensitive olabilir
      final snapshot = await _db.ref('users')
          .orderByChild('username')
          .startAt(query)
          .endAt('$query\uf8ff')
          .limitToFirst(10)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!snapshot.exists) return [];

      final List<UserProfile> results = [];
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final profile = UserProfile.fromJson(value as Map);
        if (profile.uid != _currentUser?.uid) {
          results.add(profile);
        }
      });
      return results;
    } catch (e) {
      print('Arama hatası: $e');
      return [];
    }
  }

  /// Belirli bir UID'li kullanıcının profilini getirir.
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final snapshot = await _db.ref('users/$uid').get().timeout(const Duration(seconds: 3));
      if (!snapshot.exists) return null;
      return UserProfile.fromJson(snapshot.value as Map);
    } catch (e) {
      print('User profil getirme hatası: $uid, $e');
      return null;
    }
  }

  // ─── Arkadaşlık İlişkileri ─────────────────────────────────────

  /// Arkadaşlık isteği gönderir.
  Future<void> sendFriendRequest(String targetUid) async {
    final myUid = _currentUser?.uid;
    if (myUid == null || myUid == targetUid) return;

    try {
      // Gönderilen isteği kaydet
      await _db.ref('users/$myUid/requests/outgoing/$targetUid').set(true);
      // Gelen isteği hedefe kaydet
      await _db.ref('users/$targetUid/requests/incoming/$myUid').set(true);
    } catch (e) {
      print('İstek gönderme hatası: $e');
    }
  }

  /// Arkadaşlık isteğini kabul eder.
  Future<void> acceptFriendRequest(String senderUid) async {
    final myUid = _currentUser?.uid;
    if (myUid == null) return;

    try {
      final batch = <String, dynamic>{};

      // Arkadaş listesine ekle
      batch['users/$myUid/friends/$senderUid'] = true;
      batch['users/$senderUid/friends/$myUid'] = true;

      // İstekleri temizle
      batch['users/$myUid/requests/incoming/$senderUid'] = null;
      batch['users/$senderUid/requests/outgoing/$myUid'] = null;

      await _db.ref().update(batch);
    } catch (e) {
      print('İstek kabul hatası: $e');
    }
  }

  /// Arkadaşlık isteğini reddeder (Alıcı için).
  Future<void> declineFriendRequest(String senderUid) async {
    final myUid = _currentUser?.uid;
    if (myUid == null) return;

    try {
      await _db.ref('users/$myUid/requests/incoming/$senderUid').remove();
      await _db.ref('users/$senderUid/requests/outgoing/$myUid').remove();
    } catch (e) {
      print('İstek reddetme hatası: $e');
    }
  }

  /// Arkadaşlık isteğini iptal eder (Gönderen için).
  Future<void> cancelFriendRequest(String targetUid) async {
    final myUid = _currentUser?.uid;
    if (myUid == null) return;

    try {
      await _db.ref('users/$myUid/requests/outgoing/$targetUid').remove();
      await _db.ref('users/$targetUid/requests/incoming/$myUid').remove();
    } catch (e) {
      print('İstek iptal hatası: $e');
    }
  }

  /// Engeller.
  Future<void> blockUser(String targetUid) async {
    final myUid = _currentUser?.uid;
    if (myUid == null) return;

    try {
      // Önce arkadaşlığı ve istekleri bitir
      await removeFriend(targetUid);
      await cancelFriendRequest(targetUid);
      await declineFriendRequest(targetUid);

      // Engellenenlere ekle
      await _db.ref('users/$myUid/blocked/$targetUid').set(true);
    } catch (e) {
      print('Engelleme hatası: $e');
    }
  }

  /// Engeli kaldırır.
  Future<void> unblockUser(String targetUid) async {
    final myUid = _currentUser?.uid;
    if (myUid == null) return;

    try {
      await _db.ref('users/$myUid/blocked/$targetUid').remove();
    } catch (e) {
      print('Engel kaldırma hatası: $e');
    }
  }

  /// Arkadaşlıktan çıkarır.
  Future<void> removeFriend(String friendUid) async {
    final myUid = _currentUser?.uid;
    if (myUid == null) return;

    await _db.ref('users/$myUid/friends/$friendUid').remove();
    await _db.ref('users/$friendUid/friends/$myUid').remove();
  }

  /// Bir kullanıcının durumunu (arkadaş, bekleyen, engellenen vb.) kontrol eder.
  Future<String> getRelationshipStatus(String targetUid) async {
    final myUid = _currentUser?.uid;
    if (myUid == null) return 'none';

    try {
      final userSnapshot = await _db.ref('users/$myUid').get().timeout(const Duration(seconds: 3));
      if (!userSnapshot.exists) return 'none';

      final data = userSnapshot.value as Map<dynamic, dynamic>;
      
      // Engelli mi?
      if (data['blocked'] != null && data['blocked'][targetUid] == true) {
        return 'blocked';
      }

      // Arkadaşlar mı?
      if (data['friends'] != null && data['friends'][targetUid] == true) {
        return 'friend';
      }

      // Giden istek var mı?
      if (data['requests'] != null && 
          data['requests']['outgoing'] != null && 
          data['requests']['outgoing'][targetUid] == true) {
        return 'sent';
      }

      // Gelen istek var mı?
      if (data['requests'] != null && 
          data['requests']['incoming'] != null && 
          data['requests']['incoming'][targetUid] == true) {
        return 'received';
      }
    } catch (e) {
      print('İlişki durumu kontrol hatası: $e');
    }

    return 'none';
  }

  // ─── Streamler (Realtime) ──────────────────────────────────────

  /// Arkadaş listesini dinler.
  /// Arkadaş listesini dinler.
  Stream<List<UserProfile>> listenFriends() {
    final myUid = _currentUser?.uid;
    if (myUid == null) return Stream.value([]);

    return _db.ref('users/$myUid/friends').onValue.asyncMap((event) async {
      try {
        final data = event.snapshot.value;
        if (data == null) return [];

        final friendUids = (data as Map<dynamic, dynamic>).keys.map((k) => k.toString()).toList();
        final profiles = await Future.wait(
          friendUids.map((uid) => getUserProfile(uid))
        );
        
        return profiles.whereType<UserProfile>()
            .where((p) => p.uid != myUid)
            .toList();
      } catch (e) {
        print('Friends listen error: $e');
        return [];
      }
    });
  }

  /// Gelen istekleri dinler.
  /// Gelen istekleri dinler.
  Stream<List<UserProfile>> listenIncomingRequests() {
    final myUid = _currentUser?.uid;
    if (myUid == null) return Stream.value([]);

    return _db.ref('users/$myUid/requests/incoming').onValue.asyncMap((event) async {
      try {
        final data = event.snapshot.value;
        if (data == null) return [];

        final requesterUids = (data as Map<dynamic, dynamic>).keys.map((k) => k.toString()).toList();
        final profiles = await Future.wait(
          requesterUids.map((uid) => getUserProfile(uid))
        );
        
        return profiles.whereType<UserProfile>()
            .where((p) => p.uid != myUid)
            .toList();
      } catch (e) {
        print('Requests listen error: $e');
        return [];
      }
    });
  }
}
