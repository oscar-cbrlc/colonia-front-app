import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';
import '../../../domain/models/team.dart';
import '../../../domain/models/team_request.dart';
import '../../../domain/models/enums/team_role.dart';
import '../../../l10n/app_localizations.dart';

class StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const StatItem({super.key, required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor.withAlpha(150), size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Oswald')),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class MemberCard extends StatelessWidget {
  final TeamMemberSummary member;
  final VoidCallback? onTap;
  final bool isLarge;
  final int? color;

  const MemberCard({super.key, required this.member, this.onTap, this.isLarge = false, this.color});

  @override
  Widget build(BuildContext context) {
    final avatarSize = isLarge ? 40.0 : 30.0;
    final isLeader = member.role == TeamRole.leader.name;
    final themeColor = color != null ? Color(color!) : AppTheme.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: Colors.white.withAlpha(10),
          shape: BeveledRectangleBorder(
            side: BorderSide(color: themeColor.withAlpha(100), width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                CircleAvatar(
                  radius: avatarSize,
                  backgroundColor: isLeader ? Colors.amber.withAlpha(50) : Colors.white10,
                  child: member.userThumbnail != null && member.userThumbnail!.isNotEmpty
                    ? ClipOval(child: Image.network(member.userThumbnail!))
                    : Text(member.userName[0].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: isLarge ? 32 : 24)),
                ),
                if (isLeader)
                  const Icon(Icons.star, color: Colors.amber, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              member.userName,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isLarge ? 16 : 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              member.role.toUpperCase(),
              style: TextStyle(color: AppTheme.primaryColor.withAlpha(150), fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class TeamDetailsBody extends StatelessWidget {
  final Team team;
  final List<TeamMemberSummary> members;
  final List<Widget>? appBarActions;
  final List<Widget>? headerActions;
  final Widget? bottomAction;
  final Function(TeamMemberSummary)? onMemberTap;

  const TeamDetailsBody({
    super.key, 
    required this.team, 
    required this.members,
    this.appBarActions,
    this.headerActions,
    this.bottomAction,
    this.onMemberTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    
    final leader = members.where((m) => m.role == TeamRole.leader.name).firstOrNull;
    final moderators = members.where((m) => m.role == TeamRole.moderator.name).toList();
    final regularMembers = members.where((m) => m.role == TeamRole.member.name).toList();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200.0,
          floating: false,
          pinned: true,
          backgroundColor: Color(team.color),
          actions: appBarActions,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              team.name.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Oswald',
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontStyle: FontStyle.normal,
              ),
            ),
            centerTitle: true,
            background: Container(
              decoration: BoxDecoration(
                color: Color(team.color),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(team.color).withAlpha(150),
                    Color(team.color),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.group,
                  size: 80,
                  color: Colors.white.withAlpha(100),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      locale.description.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: team.isPublic ? Colors.green.withAlpha(50) : Colors.blue.withAlpha(50),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: team.isPublic ? Colors.green : Colors.blue, width: 1),
                      ),
                      child: Text(
                        (team.isPublic ? locale.public : locale.private).toUpperCase(),
                        style: TextStyle(
                          color: team.isPublic ? Colors.green : Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (team.description != null && team.description!.isNotEmpty)
                  Text(
                    team.description!,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  )
                else
                  const Text("No description provided", style: TextStyle(color: Colors.white38, fontSize: 14, fontStyle: FontStyle.italic)),
                const SizedBox(height: 24),
                
                if (headerActions != null && headerActions!.isNotEmpty) ...[
                  ...headerActions!,
                  const SizedBox(height: 24),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    StatItem(
                      label: "MEMBERS",
                      value: team.stats?.memberCount.toString() ?? "0",
                      icon: Icons.person,
                    ),
                    StatItem(
                      label: "TERRITORIES",
                      value: team.stats?.territoriesControlled.toString() ?? "0",
                      icon: Icons.map,
                    ),
                    StatItem(
                      label: "DEFENSE",
                      value: team.stats?.totalDefensePoints.toStringAsFixed(0) ?? "0",
                      icon: Icons.shield,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        if (leader != null)
          SliverToBoxAdapter(
            child: Column(
              children: [
                const Text(
                  "LEADER",
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 160,
                  child: MemberCard(
                    member: leader,
                    isLarge: true,
                    onTap: onMemberTap != null ? () => onMemberTap!(leader) : null,
                    color: team.color
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),

        if (moderators.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "MODERATORS (${moderators.length})",
                    style: TextStyle(
                      color: AppTheme.primaryColor.withAlpha(150),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final member = moderators[index];
                  return MemberCard(
                    member: member,
                    onTap: onMemberTap != null ? () => onMemberTap!(member) : null,
                    color: team.color,
                  );
                },
                childCount: moderators.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],

        if (regularMembers.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "COLONY MEMBERS (${regularMembers.length})",
                    style: TextStyle(
                      color: AppTheme.primaryColor.withAlpha(150),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final member = regularMembers[index];
                  return MemberCard(
                    member: member,
                    onTap: onMemberTap != null ? () => onMemberTap!(member) : null,
                  );
                },
                childCount: regularMembers.length,
              ),
            ),
          ),
        ],

        if (bottomAction != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: bottomAction,
            ),
          ),
          
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }
}

enum RequestListType { sent, received }

class RequestListSheet extends StatefulWidget {
  final List<TeamRequest> requests;
  final RequestListType type;
  final Function(TeamRequest) onAccept;
  final Function(TeamRequest) onReject;
  final Function(TeamRequest) onCancel;
  final bool isLoading;

  const RequestListSheet({
    super.key,
    required this.requests,
    required this.type,
    required this.onAccept,
    required this.onReject,
    required this.onCancel,
    this.isLoading = false,
  });

  @override
  State<RequestListSheet> createState() => _RequestListSheetState();
}

class _RequestListSheetState extends State<RequestListSheet> {
  bool _isNewestFirst = true;

  DateTime _parseTimestamp(String timestamp) {
    try {
      return DateTime.parse(timestamp);
    } catch (_) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedRequests = List<TeamRequest>.from(widget.requests);
    sortedRequests.sort((a, b) {
      final dateA = _parseTimestamp(a.requestTimestamp);
      final dateB = _parseTimestamp(b.requestTimestamp);
      return _isNewestFirst ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
    });

    final title = widget.type == RequestListType.received 
        ? "PENDING JOIN REQUESTS" 
        : "MY SENT REQUESTS";

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const ShapeDecoration(
        color: AppTheme.darkBackground,
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Oswald',
                  fontSize: 20,
                ),
              ),
              if (sortedRequests.isNotEmpty)
                IconButton(
                  icon: Icon(
                    _isNewestFirst ? Icons.arrow_upward_sharp : Icons.arrow_downward_sharp,
                    color: Colors.white70,
                  ),
                  tooltip: _isNewestFirst ? "Sort by Oldest" : "Sort by Newest",
                  onPressed: () => setState(() => _isNewestFirst = !_isNewestFirst),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (sortedRequests.isEmpty)
             Expanded(
              child: Center(
                child: Text(
                  widget.type == RequestListType.received 
                      ? "No pending requests" 
                      : "You haven't sent any join requests",
                  style: const TextStyle(color: Colors.white38),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: sortedRequests.length,
                itemBuilder: (context, index) {
                  final req = sortedRequests[index];
                  final name = widget.type == RequestListType.received 
                      ? req.user?.name 
                      : req.team?.name;
                  final thumbnail = widget.type == RequestListType.received 
                      ? req.user?.thumbnail 
                      : null;
                  final color = widget.type == RequestListType.sent 
                      ? req.team?.color 
                      : null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: ShapeDecoration(
                      color: Colors.white.withAlpha(10),
                      shape: const BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color != null ? Color(color).withAlpha(50) : Colors.white10,
                          child: thumbnail != null && thumbnail.isNotEmpty
                              ? ClipOval(child: Image.network(thumbnail))
                              : Icon(
                                  widget.type == RequestListType.received ? Icons.person : Icons.group,
                                  color: color != null ? Color(color) : Colors.white70,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name ?? "Unknown",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                _formatTimestamp(req.requestTimestamp),
                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (!widget.isLoading) ...[
                          if (widget.type == RequestListType.received) ...[
                            IconButton(
                              icon: const Icon(Icons.check_box_outlined, color: Colors.green, size: 32,),
                              onPressed: () => widget.onAccept(req),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel_presentation_sharp, color: Colors.redAccent, size: 32,),
                              onPressed: () => widget.onReject(req),
                            ),
                          ] else 
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 32,),
                              tooltip: "Cancel Request",
                              onPressed: () => widget.onCancel(req),
                            ),
                        ] else
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    
    DateTime date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else if (timestamp is int) {
      date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      try {
        date = DateTime.parse(timestamp);
      } catch (_) {
        try {
          date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
        } catch (_) {
          return "Just now";
        }
      }
    } else {
      return "Just now";
    }

    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
    return "Just now";
  }
}
