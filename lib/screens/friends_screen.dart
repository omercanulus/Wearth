import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/social_service.dart';
import '../services/matchmaking_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'online_matchmaking_screen.dart';
import '../widgets/profile_card.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SocialService _socialService = SocialService();
  final AppLocalizations _l10n = AppLocalizations();
  final TextEditingController _searchController = TextEditingController();
  
  List<UserProfile> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Timer? _searchDebounce;

  void _onSearch(String query) {
    _searchDebounce?.cancel();
    
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      setState(() => _isSearching = true);
      
      try {
        final results = await _socialService.searchUsers(query);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.wearth.scaffoldBg,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.wearth.scaffoldBg,
              context.isDark ? const Color(0xFF1E1E2E) : const Color(0xFFE2E8F0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildSearchBar(),
              
              if (_searchController.text.isNotEmpty)
                Expanded(child: _buildSearchResults())
              else ...[
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      const _FriendsListTab(),
                      const _RequestsListTab(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: _glassButton(Icons.arrow_back_ios_new_rounded),
            ),
          ),
          Text(
            _l10n.t('friends').toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: context.wearth.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: context.wearth.glassBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.wearth.glassBorder),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: GoogleFonts.outfit(color: context.wearth.textPrimary),
              decoration: InputDecoration(
                hintText: _l10n.t('searchUser'),
                hintStyle: GoogleFonts.outfit(color: context.wearth.textMuted),
                prefixIcon: Icon(Icons.search_rounded, color: context.wearth.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: Icon(Icons.close_rounded, color: context.wearth.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults = []);
                      },
                    )
                  : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) return const Center(child: CircularProgressIndicator());
    if (_searchResults.isEmpty) {
      return _buildEmptyState(context, _l10n.t('noResults'), Icons.search_off_rounded);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) => _UserTile(user: _searchResults[index]),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.wearth.glassBackground.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: context.wearth.glassBackgroundStrong,
          border: Border.all(color: context.wearth.glassBorder),
        ),
        labelColor: context.wearth.textPrimary,
        unselectedLabelColor: context.wearth.textSecondary,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        tabs: [
          Tab(text: _l10n.t('friends')),
          Tab(text: _l10n.t('friendRequests')),
        ],
      ),
    );
  }

  Widget _glassButton(IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.wearth.glassBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.wearth.glassBorder),
          ),
          child: Icon(icon, size: 20, color: context.wearth.textPrimary),
        ),
      ),
    );
  }
}

class _FriendsListTab extends StatefulWidget {
  const _FriendsListTab();
  @override
  State<_FriendsListTab> createState() => _FriendsListTabState();
}

class _FriendsListTabState extends State<_FriendsListTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final socialService = SocialService();
    final l10n = AppLocalizations();

    return StreamBuilder<List<UserProfile>>(
      stream: socialService.listenFriends(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final rawFriends = snapshot.data ?? [];
        final myUid = socialService.currentUid;
        final friends = rawFriends.where((p) => p.uid != myUid).toList();

        if (friends.isEmpty) {
          return _buildEmptyState(context, l10n.t('noFriends'), Icons.people_outline_rounded);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friends.length,
          itemBuilder: (context, index) => _UserTile(user: friends[index], isFriend: true),
        );
      },
    );
  }
}

class _RequestsListTab extends StatefulWidget {
  const _RequestsListTab();
  @override
  State<_RequestsListTab> createState() => _RequestsListTabState();
}

class _RequestsListTabState extends State<_RequestsListTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final socialService = SocialService();
    final l10n = AppLocalizations();

    return StreamBuilder<List<UserProfile>>(
      stream: socialService.listenIncomingRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final rawRequests = snapshot.data ?? [];
        final myUid = socialService.currentUid;
        final requests = rawRequests.where((p) => p.uid != myUid).toList();

        if (requests.isEmpty) {
          return _buildEmptyState(context, l10n.t('noRequests'), Icons.mark_email_unread_outlined);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) => _UserTile(user: requests[index], isRequest: true),
        );
      },
    );
  }
}

Widget _buildEmptyState(BuildContext context, String msg, IconData icon) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: context.wearth.textMuted),
        const SizedBox(height: 16),
        Text(msg, style: GoogleFonts.outfit(color: context.wearth.textSecondary)),
      ],
    ),
  );
}

class _UserTile extends StatefulWidget {
  final UserProfile user;
  final bool isFriend;
  final bool isRequest;

  const _UserTile({required this.user, this.isFriend = false, this.isRequest = false});

  @override
  State<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<_UserTile> {
  final SocialService _socialService = SocialService();
  final MatchmakingService _matchmakingService = MatchmakingService();
  String _relationshipStatus = 'none';
  bool _isChallenging = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() async {
    final status = await _socialService.getRelationshipStatus(widget.user.uid);
    if (mounted) setState(() => _relationshipStatus = status);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.wearth.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.wearth.glassBorder),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => ProfileCard.show(context, widget.user),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF3B82F6).withAlpha(20),
                  child: Text(widget.user.username[0].toUpperCase(), 
                      style: GoogleFonts.outfit(color: const Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.user.username,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: context.wearth.textPrimary),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (widget.isFriend)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionButton(
                  _isChallenging ? Icons.hourglass_empty_rounded : Icons.play_arrow_rounded, 
                  Colors.blueAccent, 
                  _isChallenging ? () {} : () async {
                    setState(() => _isChallenging = true);
                    try {
                      final matchId = await _matchmakingService.challengeFriend(
                        widget.user.uid, 
                        widget.user.username
                      );
                      if (mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => OnlineMatchmakingScreen(matchId: matchId),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Hata: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isChallenging = false);
                    }
                  },
                  label: 'Oyna',
                ),
                const SizedBox(width: 8),
                _actionButton(Icons.block_flipped, Colors.orangeAccent, () async {
                  final confirmed = await _showConfirmDialog(
                    context, 
                    l10n.t('blockUser'), 
                    l10n.t('blockConfirm')
                  );
                  if (confirmed) {
                    await _socialService.blockUser(widget.user.uid);
                    if (mounted) setState(() {});
                  }
                }),
                const SizedBox(width: 8),
                _actionButton(Icons.person_remove_rounded, Colors.redAccent, () async {
                  final confirmed = await _showConfirmDialog(
                    context, 
                    l10n.t('unfriend'), 
                    l10n.t('unfriendConfirm')
                  );
                  if (confirmed) {
                    await _socialService.removeFriend(widget.user.uid);
                    if (mounted) setState(() {});
                  }
                }),
              ],
            )
          else if (widget.isRequest)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionButton(Icons.close_rounded, Colors.redAccent, () async {
                  await _socialService.declineFriendRequest(widget.user.uid);
                  if (mounted) setState(() {});
                }),
                const SizedBox(width: 8),
                _actionButton(Icons.check_rounded, Colors.greenAccent, () async {
                  await _socialService.acceptFriendRequest(widget.user.uid);
                  if (mounted) setState(() {});
                }),
              ],
            )
          else
            _buildSearchAction(widget.user.uid, _relationshipStatus, l10n),
        ],
      ),
    );
  }

  Widget _buildSearchAction(String uid, String status, AppLocalizations l10n) {
    if (status == 'friend') return Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20);
    if (status == 'blocked') return _actionButton(Icons.refresh_rounded, Colors.orangeAccent, () async {
      await _socialService.unblockUser(uid);
      _checkStatus();
    });
    
    if (status == 'sent') return _actionButton(Icons.close_rounded, Colors.redAccent, () async {
      await _socialService.cancelFriendRequest(uid);
      _checkStatus();
    }, label: l10n.t('cancelRequest'));
    
    if (status == 'received') return _actionButton(Icons.check_rounded, Colors.greenAccent, () async {
      await _socialService.acceptFriendRequest(uid);
      _checkStatus();
    });
    
    return IconButton(
      icon: const Icon(Icons.person_add_rounded, color: Color(0xFF3B82F6), size: 20),
      onPressed: () async {
        await _socialService.sendFriendRequest(uid);
        _checkStatus();
      },
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap, {String? label}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(BuildContext context, String title, String message) async {
    final l10n = AppLocalizations();
    return await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: context.wearth.glassBackgroundStrong,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: context.wearth.glassBorder),
          ),
          title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.wearth.textPrimary)),
          content: Text(message, style: GoogleFonts.outfit(color: context.wearth.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.t('no'), style: GoogleFonts.outfit(color: context.wearth.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.t('yes'), style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ) ?? false;
  }
}
