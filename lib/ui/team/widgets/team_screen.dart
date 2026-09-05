import 'package:colonia_front_app/domain/models/team_chat_message.dart';
import 'package:flutter/material.dart';
import '../view_models/team_viewmodel.dart';
import '../../core/themes/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/models/team.dart';
import '../../../domain/models/enums/team_role.dart';
import '../../../domain/models/enums/message_type.dart';
import '../../../ui/core/navigation/app_router.dart';
import 'team_shared_widgets.dart';

class TeamScreen extends StatelessWidget {
  final TeamViewModel viewModel;

  const TeamScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }

        if (viewModel.currentTeam == null) {
          return _NoTeamView(viewModel: viewModel);
        }

        return _TeamDetailsView(viewModel: viewModel);
      },
    );
  }

  static void showExploreTeamsSheet(BuildContext context, TeamViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => _ExploreTeamsSheet(viewModel: viewModel),
      ),
    );
  }

  static void showSentRequestsSheet(BuildContext context, TeamViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => RequestListSheet(
          requests: viewModel.userMadeRequests,
          type: RequestListType.sent,
          onAccept: (_) {},
          onReject: (_) {},
          onCancel: (req) async {
            final success = await viewModel.cancelRequest(req.team!.id);
            if (success && context.mounted) {
              final locale = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(locale.requestCancelled))
              );
            }
          },
          isLoading: viewModel.isLoading,
        ),
      ),
    );
  }
}

class _NoTeamView extends StatelessWidget {
  final TeamViewModel viewModel;
  const _NoTeamView({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final sentRequestsCount = viewModel.userMadeRequests.length;

    return Container(
      color: AppTheme.darkBackground,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.group_off, size: 80, color: Colors.white24),
              const SizedBox(height: 24),
              Text(
                locale.youNotHaveTeam.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Oswald',
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showCreateTeamSheet(context, viewModel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(locale.createTeam.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showExploreTeamsSheet(context, viewModel),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryColor),
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(locale.joinTeam.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              if (sentRequestsCount > 0) ...[
                const SizedBox(height: 32),
                TextButton.icon(
                  onPressed: () => TeamScreen.showSentRequestsSheet(context, viewModel),
                  icon: Badge(
                    label: Text("$sentRequestsCount"),
                    backgroundColor: AppTheme.primaryColor,
                    textColor: Colors.black,
                    child: const Icon(Icons.send_outlined),
                  ),
                  label: const Text("VIEW SENT REQUESTS"),
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateTeamSheet(BuildContext context, TeamViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateEditTeamSheet(viewModel: viewModel),
    );
  }

  void _showExploreTeamsSheet(BuildContext context, TeamViewModel viewModel) {
    TeamScreen.showExploreTeamsSheet(context, viewModel);
  }
}

class _TeamDetailsView extends StatelessWidget {
  final TeamViewModel viewModel;
  const _TeamDetailsView({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final team = viewModel.currentTeam!;
    final isLeader = viewModel.currentUser?.isTeamLeader ?? false;
    final canModerate = viewModel.currentUser?.canModerateTeam ?? false;
    final pendingRequestsCount = viewModel.teamReceivedRequests.length;
    final locale = AppLocalizations.of(context)!;

    return Container(
      color: AppTheme.darkBackground,
      child: TeamDetailsBody(
        team: team,
        members: viewModel.teamMembers,
        appBarActions: [
          if (isLeader)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => _showEditTeamSheet(context, viewModel),
            ),
        ],
        headerActions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showTeamChatSheet(context, viewModel),
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.black),
                  label: const Text("TEAM CHAT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (canModerate) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showJoinRequestsSheet(context, viewModel),
                    icon: Badge(
                      label: Text("$pendingRequestsCount"),
                      isLabelVisible: pendingRequestsCount > 0,
                      backgroundColor: AppTheme.primaryColor,
                      textColor: Colors.black,
                      child: const Icon(Icons.person_add_outlined),
                    ),
                    label: const Text("JOIN REQUESTS"),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primaryColor.withAlpha(100)),
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (viewModel.userMadeRequests.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => TeamScreen.showSentRequestsSheet(context, viewModel),
                icon: Badge(
                  label: Text("${viewModel.userMadeRequests.length}"),
                  backgroundColor: Colors.blueAccent,
                  child: const Icon(Icons.send_outlined),
                ),
                label: Text(locale.viewSentRequests),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blueAccent.withAlpha(100)),
                  foregroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
        onMemberTap: (member) => _showMemberActions(context, viewModel, member),
        bottomAction: OutlinedButton(
          onPressed: () => _handleLeaveTeam(context, viewModel),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.redAccent),
            foregroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(locale.leaveColony, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _showTeamChatSheet(BuildContext context, TeamViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TeamChatSheet(viewModel: viewModel),
    );
  }

  void _showJoinRequestsSheet(BuildContext context, TeamViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => RequestListSheet(
          requests: viewModel.teamReceivedRequests,
          type: RequestListType.received,
          onAccept: (req) async {
            final success = await viewModel.acceptRequest(req.user!.id);
            if (success && context.mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${req.user?.name ?? 'Member'} ${AppLocalizations.of(context)!.accepted}"))
              );
            }
          },
          onReject: (req) async {
            final success = await viewModel.rejectRequest(req.user!.id);
            if (success && context.mounted) {
              final locale = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(locale.requestRejected), backgroundColor: Colors.redAccent)
              );
            }
          },
          onCancel: (_) {},
          isLoading: viewModel.isLoading,
        ),
      ),
    );
  }

  void _showEditTeamSheet(BuildContext context, TeamViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateEditTeamSheet(viewModel: viewModel, team: viewModel.currentTeam),
    );
  }

  void _showMemberActions(BuildContext context, TeamViewModel viewModel, TeamMemberSummary member) {
    final currentUser = viewModel.currentUser;
    if (currentUser == null || currentUser.id == member.userId) return;

    final isLeader = currentUser.isTeamLeader;
    final isModerator = currentUser.canModerateTeam && !isLeader;

    final targetIsModerator = member.role == TeamRole.moderator.name;
    final targetIsMember = member.role == TeamRole.member.name;
    final locale = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkBackground,
      shape: const BeveledRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: Text(member.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(member.role.toUpperCase(), style: const TextStyle(color: Colors.white54)),
            ),
            const Divider(color: Colors.white12),

            if (isLeader) ...[
              if (targetIsMember)
                ListTile(
                  leading: const Icon(Icons.security, color: Colors.blue),
                  title: Text(locale.promoteToModerator, style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    final success = await viewModel.promoteMember(member.userId);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locale.memberPromotedToMod)));
                    }
                  },
                ),
              if (targetIsModerator)
                ListTile(
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: Text(locale.promoteToLeader, style: const TextStyle(color: Colors.white)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppTheme.darkBackground,
                        title: Text(locale.transferLeadership, style: const TextStyle(color: Colors.white)),
                        content: Text(locale.promoteToLeaderConfirm(member.userName)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(locale.cancel.toUpperCase())),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(locale.promote.toUpperCase(), style: const TextStyle(color: Colors.amber))),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      Navigator.pop(context);
                      final success = await viewModel.promoteMember(member.userId);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locale.leadershipTransferred)));
                      }
                    }
                  },
                ),
            ],

            if ((isLeader || isModerator) && targetIsModerator)
              ListTile(
                leading: const Icon(Icons.keyboard_arrow_down, color: Colors.orange),
                title: Text(locale.demoteToMember, style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await viewModel.demoteMember(member.userId);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locale.memberDemotedToMember)));
                  }
                },
              ),

            if (isLeader || (isModerator && targetIsMember))
              ListTile(
                leading: const Icon(Icons.person_remove, color: Colors.redAccent),
                title: Text(locale.kickMember, style: const TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppTheme.darkBackground,
                      title: Text(locale.kickMember, style: const TextStyle(color: Colors.white)),
                      content: Text(locale.kickMemberConfirm(member.userName)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(locale.cancel.toUpperCase())),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(locale.kick.toUpperCase(), style: const TextStyle(color: Colors.redAccent))),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    Navigator.pop(context);
                    final success = await viewModel.kickMember(member.userId);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locale.memberKicked)));
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _handleLeaveTeam(BuildContext context, TeamViewModel viewModel) async {
    final locale = AppLocalizations.of(context)!;
    final isLeader = viewModel.currentUser?.isTeamLeader ?? false;
    final memberCount = viewModel.teamMembers.length;

    if (isLeader) {
      if (memberCount > 1) {
        _showErrorDialog(context, locale.leaderLeaveError);
        return;
      } else {
        _showErrorDialog(context, locale.onlyMemberDeleteError);
        return;
      }
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkBackground,
        title: Text(locale.leaveColonyTitle, style: const TextStyle(color: Colors.white)),
        content: Text(locale.leaveColonyConfirm, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(locale.cancel.toUpperCase())),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(locale.leave.toUpperCase(), style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm == true) {
      final success = await viewModel.leaveTeam();
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locale.leftColony)));
        TeamScreen.showExploreTeamsSheet(context, viewModel);
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    final locale = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkBackground,
        title: Text(locale.actionRequired, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(locale.ok.toUpperCase())),
        ],
      ),
    );
  }
}

class _CreateEditTeamSheet extends StatefulWidget {
  final TeamViewModel viewModel;
  final Team? team;
  const _CreateEditTeamSheet({required this.viewModel, this.team});

  @override
  State<_CreateEditTeamSheet> createState() => _CreateEditTeamSheetState();
}

class _CreateEditTeamSheetState extends State<_CreateEditTeamSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late bool _isPublic;
  late double _hue;

  Color get _selectedColor => HSVColor.fromAHSV(1.0, _hue, 0.8, 0.9).toColor();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.team?.name ?? "");
    _descController = TextEditingController(text: widget.team?.description ?? "");
    _isPublic = widget.team?.isPublic ?? true;
    if (widget.team != null) {
      _hue = HSVColor.fromColor(Color(widget.team!.color)).hue;
    } else {
      _hue = 200.0;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onConfirm() async {
    if (_nameController.text.isEmpty) return;

    bool success;
    if (widget.team != null) {
      success = await widget.viewModel.updateTeam(
        name: _nameController.text,
        description: _descController.text,
        isPublic: _isPublic,
        color: _selectedColor.toARGB32(),
      );
    } else {
      success = await widget.viewModel.createTeam(
        name: _nameController.text,
        description: _descController.text,
        isPublic: _isPublic,
        color: _selectedColor.toARGB32(),
      );
    }

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.team != null ? "Colony updated successfully" : "Colony created successfully"))
      );
    }
  }

  void _onDelete() async {
    if (widget.viewModel.teamMembers.length > 1) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.darkBackground,
          title: const Text("Cannot Delete", style: TextStyle(color: Colors.white)),
          content: const Text("You cannot delete a colony with active members", style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkBackground,
        title: const Text("Delete Colony", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to delete this colony? This action cannot be undone.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("DELETE", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm == true) {
      final success = await widget.viewModel.deleteTeam();
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Colony deleted")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final locale = AppLocalizations.of(context)!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubicEmphasized,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 16 + bottomInset,
      ),
      decoration: ShapeDecoration(
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        color: AppTheme.darkBackground.withAlpha(240),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  (widget.team != null ? "EDIT COLONY" : locale.createTeam).toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oswald',
                    fontSize: 20,
                  ),
                ),
                if (widget.team != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: _onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 32),
            _InputField(
              controller: _nameController,
              label: locale.name.toUpperCase(),
              hint: "",
            ),
            const SizedBox(height: 16),
            _InputField(
              controller: _descController,
              label: locale.description.toUpperCase(),
              hint: "",
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Text(
              locale.accessType.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _ChoiceChip(
                  label: locale.public.toUpperCase(),
                  isSelected: _isPublic,
                  onSelected: () => setState(() => _isPublic = true),
                ),
                const SizedBox(width: 12),
                _ChoiceChip(
                  label: locale.private.toUpperCase(),
                  isSelected: !_isPublic,
                  onSelected: () => setState(() => _isPublic = false),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  locale.color.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.rectangle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _HueSlider(
              hue: _hue,
              onChanged: (val) => setState(() => _hue = val),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) => ElevatedButton(
                onPressed: widget.viewModel.isLoading
                  ? null
                  : _onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: widget.viewModel.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Text((widget.team != null ? "SAVE" : locale.confirm).toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              )
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ExploreTeamsSheet extends StatefulWidget {
  final TeamViewModel viewModel;
  const _ExploreTeamsSheet({required this.viewModel});

  @override
  State<_ExploreTeamsSheet> createState() => _ExploreTeamsSheetState();
}

class _ExploreTeamsSheetState extends State<_ExploreTeamsSheet> {
  List<Team> _teams = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() => _isLoading = true);
    final teams = await widget.viewModel.loadAllTeams();
    setState(() {
      _teams = teams;
      _isLoading = false;
    });
  }

  Future<void> _searchTeams(String query) async {
    if (query.isEmpty) {
      _loadTeams();
      return;
    }
    setState(() => _isLoading = true);
    final teams = await widget.viewModel.searchTeams(query);
    setState(() {
      _teams = teams;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(24),
      decoration: const ShapeDecoration(
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        color: AppTheme.darkBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                locale.exploreColonies,
                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontFamily: 'Oswald', fontSize: 24),
              ),

            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: _searchTeams,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: locale.searchByName,
              hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withAlpha(10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : _teams.isEmpty
                    ? Center(child: Text(locale.noColoniesFound, style: const TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: _teams.length,
                        itemBuilder: (context, index) {
                          final team = _teams[index];
                          return _TeamListItem(
                            team: team,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRouter.colonyDetails,
                                arguments: {'teamId': team.id},
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _TeamListItem extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;

  const _TeamListItem({required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: ShapeDecoration(
        color: Colors.white.withAlpha(10),
        shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: Color(team.color).withAlpha(40), shape: BoxShape.circle, border: Border.all(color: Color(team.color), width: 2)),
          child: Icon(Icons.group, color: Color(team.color), size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                team.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Oswald', fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: team.isPublic ? Colors.green.withAlpha(40) : Colors.orange.withAlpha(40),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: team.isPublic ? Colors.green : Colors.orange, width: 0.5),
              ),
              child: Text(
                (team.isPublic ? locale.public.toUpperCase() : locale.private.toUpperCase()),
                style: TextStyle(
                  color: team.isPublic ? Colors.green : Colors.orange,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.person, color: Colors.white54, size: 14),
            const SizedBox(width: 4),
            Text("${team.stats?.memberCount ?? 0}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(width: 12),
            const Icon(Icons.map, color: Colors.white54, size: 14),
            const SizedBox(width: 4),
            Text("${team.stats?.territoriesControlled ?? 0}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(width: 12),
            const Icon(Icons.shield, color: AppTheme.primaryColor, size: 14),
            const SizedBox(width: 4),
            Text("${team.stats?.totalDefensePoints.toStringAsFixed(0) ?? 0}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      ),
    );
  }
}

class _HueSlider extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;

  const _HueSlider({required this.hue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        const double thumbRadius = 12.0;
        final double thumbLeft = (hue / 360.0) * width - thumbRadius;

        return GestureDetector(
          onPanUpdate: (details) {
            double newHue = (details.localPosition.dx / width) * 360.0;
            onChanged(newHue.clamp(0.0, 360.0));
          },
          onTapDown: (details) {
            double newHue = (details.localPosition.dx / width) * 360.0;
            onChanged(newHue.clamp(0.0, 360.0));
          },
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 32,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: ShapeDecoration(
                    shape: BeveledRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF0000),
                        Color(0xFFFFFF00),
                        Color(0xFF00FF00),
                        Color(0xFF00FFFF),
                        Color(0xFF0000FF),
                        Color(0xFFFF00FF),
                        Color(0xFFFF0000),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: thumbLeft,
                  child: Container(
                    width: thumbRadius * 2,
                    height: thumbRadius * 2,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black12, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
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

class _TeamChatSheet extends StatefulWidget {
  final TeamViewModel viewModel;
  const _TeamChatSheet({required this.viewModel});

  @override
  State<_TeamChatSheet> createState() => _TeamChatSheetState();
}

class _TeamChatSheetState extends State<_TeamChatSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int? _selectedMessageId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.fetchChatMessages().then((_) => _scrollToBottom());
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _getLocalizedSystemMessage(AppLocalizations locale, TeamChatMessage msg) {
    final username = msg.user?.name ?? 'User';
    switch (msg.type) {
      case 'team_join':
        return locale.teamJoin(username);
      case 'team_kick':
        return locale.teamKick(username);
      case 'team_exit':
        return locale.teamExit(username);
      default:
        return msg.message;
    }
  }

  String _formatTimestamp(BuildContext context, dynamic timestamp) {
    final locale = AppLocalizations.of(context)!;
    if (timestamp == null) return locale.justNow;

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
          return locale.justNow;
        }
      }
    } else {
      return locale.justNow;
    }

    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return locale.daysAgo(diff.inDays);
    if (diff.inHours > 0) return locale.hoursAgo(diff.inHours);
    if (diff.inMinutes > 0) return locale.minutesAgo(diff.inMinutes);
    return locale.justNow;
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final teamVm = widget.viewModel;
        final currentUser = teamVm.currentUser;
        final isLeader = currentUser?.isTeamLeader ?? false;
        final isModerator = currentUser?.isTeamMod ?? false;

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: ShapeDecoration(
            color: AppTheme.darkBackground,
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              )
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: ShapeDecoration(
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  )
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locale.colonyChat.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withAlpha(100),
                            fontFamily: 'Oswald',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          teamVm.currentTeam!.name,
                          style: TextStyle(
                            color: Color(teamVm.currentTeam!.color),
                            fontFamily: 'Oswald',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Messages List
              Expanded(
                child: teamVm.isChatLoading && teamVm.chatMessages.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                    : teamVm.chatMessages.isEmpty
                        ? Center(child: Text(locale.noMessagesYet, style: const TextStyle(color: Colors.white38)))
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: teamVm.chatMessages.length,
                            itemBuilder: (context, index) {
                              final msg = teamVm.chatMessages[index];
                              final type = msg.type ?? 'user_message';
                              final isUserMessage = type == 'user_message' || type == MessageType.user_message.name;
                              final isOwnMessage = msg.user?.id == currentUser?.id;
                              final targetRole = msg.user?.role?.toLowerCase() ?? '';
                              final isTargetLeader = targetRole == TeamRole.leader.name.toLowerCase();
                              final isTargetModerator = targetRole == TeamRole.moderator.name.toLowerCase();
                              final canDelete = isLeader || 
                                                (isModerator && !isTargetLeader && !isTargetModerator) || 
                                                isOwnMessage;
                              final isSelected = _selectedMessageId == msg.id;

                              if (!isUserMessage) {
                                // System message
                                final locale = AppLocalizations.of(context)!;
                                final systemText = _getLocalizedSystemMessage(locale, msg);

                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: ShapeDecoration(
                                      color: Colors.white.withAlpha(10),
                                      shape: BeveledRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      )
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          systemText,
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatTimestamp(context, msg.date),
                                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // User message
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedMessageId = isSelected ? null : msg.id;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.all(12),

                                  decoration: ShapeDecoration(
                                    shape: BeveledRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    color: isOwnMessage 
                                        ? Color(teamVm.currentTeam!.color).withAlpha(20)
                                        : Colors.white.withAlpha(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,

                                    children: [
                                      Row(

                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: Colors.white24,
                                            child: msg.user?.thumbnail != null && msg.user!.thumbnail!.isNotEmpty
                                                ? ClipOval(child: Image.network(msg.user!.thumbnail!))
                                                : Text(
                                                    (msg.user?.name ?? 'U')[0].toUpperCase(),
                                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                                  ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            msg.user?.name ?? 'Unknown',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor.withAlpha(40),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              (msg.user?.role ?? 'member').toUpperCase(),
                                              style: const TextStyle(
                                                color: AppTheme.primaryColor,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            _formatTimestamp(context, msg.date),
                                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        msg.message,
                                        style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 14),
                                      ),
                                      if (isSelected && canDelete) ...[
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              final success = await teamVm.deleteChatMessage(msg.id);
                                              if (success) {
                                                setState(() => _selectedMessageId = null);
                                              }
                                            },
                                            icon: const Icon(Icons.delete, size: 16, color: Colors.black),
                                            label: Text(locale.delete.toUpperCase(), style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),

              // Input Bar
              Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(100),
                  border: Border(top: BorderSide(color: Colors.white.withAlpha(20))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: locale.typeMessage,
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withAlpha(10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        final text = _messageController.text.trim();
                        if (text.isNotEmpty) {
                          _messageController.clear();
                          final success = await teamVm.sendChatMessage(text);
                          if (success) {
                            _scrollToBottom();
                          }
                        }
                      },
                      icon: const Icon(Icons.send, color: AppTheme.primaryColor),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor.withAlpha(30),
                        padding: const EdgeInsets.all(12),
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(0)
                        )
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
            filled: true,
            fillColor: Colors.white.withAlpha(10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _ChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: ShapeDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white.withAlpha(10),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
