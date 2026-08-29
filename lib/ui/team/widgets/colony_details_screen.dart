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
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    if (_team == null) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
        body: const Center(child: Text("Colony not found", style: TextStyle(color: Colors.white))),
      );
    }

    final team = _team!;
    final viewModel = context.watch<TeamViewModel>();
    final isMyTeam = viewModel.currentUser?.team?.id == team.id;
    
    final pendingRequest = viewModel.userMadeRequests.where((r) => r.team?.id == team.id).firstOrNull;
    final hasPendingRequest = pendingRequest != null;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: TeamDetailsBody(
        team: team,
        members: team.members ?? [],
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
                  child: const Text("REQUEST PENDING"),
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
                        const SnackBar(content: Text("Request cancelled"))
                      );
                      _loadTeamDetails();
                    } else if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to cancel request"))
                      );
                    }
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  child: const Text("DECLINE REQUEST"),
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
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Successfully joined the colony"),
                        ));
                        Navigator.of(context).pop();
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      }
                    } else {
                      final success = await viewModel.requestJoin(team.id);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Request sent successfully"),
                        ));
                      }
                    }
                  },
                  child: viewModel.isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text((team.isPublic ? locale.joinTeam : "REQUEST TO JOIN").toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ) : null,
      ),
    );
  }
}
