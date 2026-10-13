import 'package:colonia_front_app/ui/core/navigation/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/team_viewmodel.dart';
import '../../core/themes/app_theme.dart';
import '../../../domain/models/team.dart';
import '../../../l10n/app_localizations.dart';
import 'team_shared_widgets.dart';

class ColonyDetailsScreen extends StatefulWidget {
  final int teamId;
  const ColonyDetailsScreen({super.key, required this.teamId});

  @override
  State<ColonyDetailsScreen> createState() => _ColonyDetailsScreenState();
}

class _ColonyDetailsScreenState extends State<ColonyDetailsScreen> {
  Team? _team;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeamDetails();
  }

  Future<void> _loadTeamDetails() async {
    debugPrint('ColonyDetailsScreen: Loading details for team ${widget.teamId}');
    try {
      final viewModel = context.read<TeamViewModel>();
      final team = await viewModel.getTeamById(widget.teamId);
      
      if (mounted) {
        setState(() {
          _team = team;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ColonyDetailsScreen: Error loading team details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    if (_team == null) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(locale.colonyNotFound, style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final team = _team!;
    final viewModel = context.watch<TeamViewModel>();
    final isMyTeam = viewModel.currentUser?.team?.id == team.id;
    
    final pendingRequest = viewModel.userMadeRequests.where((r) => r.team?.id == team.id).firstOrNull;
    final hasPendingRequest = pendingRequest != null;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: TeamDetailsBody(
          onMemberTap: (member) => _showMemberActions(context, viewModel, member),
          team: team,
          members: team.members ?? [],
          showBackButton: true,
          bottomAction: !isMyTeam ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasPendingRequest) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    disabledBackgroundColor: Colors.white10,
                    disabledForegroundColor: Colors.white38,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(locale.requestPending.toUpperCase()),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: viewModel.isLoading ? null : () async {
                    final success = await viewModel.cancelRequest(team.id);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(locale.requestCancelled))
                      );
                      _loadTeamDetails();
                    } else if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(locale.failedToCancelRequest))
                      );
                    }
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  child: Text(locale.declineRequest.toUpperCase()),
                ),
              ),
            ] else 
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: viewModel.isLoading ? null : () async {
                    if (team.isPublic) {
                      final success = await viewModel.joinTeam(team.id);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(locale.successfullyJoinedColony),
                        ));
                        Navigator.of(context).pop();
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      }
                    } else {
                      final success = await viewModel.requestJoin(team.id);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(locale.requestSentSuccessfully),
                        ));
                      }
                    }
                  },
                  child: viewModel.isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text((team.isPublic ? locale.joinTeam : locale.requestToJoin).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ) : null,
      ),
    ));
  }

  void _showMemberActions(BuildContext context, TeamViewModel viewModel, TeamMemberSummary member) {
    final currentUser = viewModel.currentUser;
    if (currentUser == null || currentUser.id == member.userId) return;

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
              trailing: const Icon(Icons.chevron_right, color: Colors.white24),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRouter.profile,
                  arguments: {'user': viewModel.getUserById(member.userId)},
                );
              },
            ),
            const Divider(color: Colors.white12),
          ],
        ),
      ),
    );
  }
}
