import 'package:flutter/material.dart';

import 'package:colonia_front_app/domain/models/enums/message_type.dart';
import 'package:colonia_front_app/domain/models/enums/team_role.dart';
import 'package:colonia_front_app/domain/models/team_chat_message.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/ui/core/ui/loading_widget.dart';
import 'package:colonia_front_app/ui/team/view_models/team_viewmodel.dart';

void showTeamChatSheet(BuildContext context, TeamViewModel viewModel) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TeamChatSheet(viewModel: viewModel),
  );
}

class TeamChatSheet extends StatefulWidget {
  final TeamViewModel viewModel;
  const TeamChatSheet({super.key, required this.viewModel});

  @override
  State<TeamChatSheet> createState() => _TeamChatSheetState();
}

class _TeamChatSheetState extends State<TeamChatSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  int? _selectedMessageId;
  bool _isSending = false;
  bool _isRefreshingFromBottom = false;
  double _lastBottomInset = 0.0;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);

    widget.viewModel.fetchChatMessages().then((_) {
      _scrollToBottom(animate: false);
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _scrollToBottom(animate: false);
        }
      });
    });
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _scrollToBottom(animate: true);
    }
  }

  Future<void> _handleBottomRefresh() async {
    if (_isRefreshingFromBottom || widget.viewModel.isChatLoading) return;
    setState(() {
      _isRefreshingFromBottom = true;
    });
    await widget.viewModel.fetchChatMessages();
    if (mounted) {
      setState(() {
        _isRefreshingFromBottom = false;
      });
      _scrollToBottom(animate: true);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          if (animate) {
            _scrollController.animateTo(
              maxScroll,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          } else {
            _scrollController.jumpTo(maxScroll);
          }
        }
      }
    });
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    if (bottomInset > 0 && bottomInset != _lastBottomInset) {
      _lastBottomInset = bottomInset;
      _scrollToBottom(animate: true);
    } else {
      _lastBottomInset = bottomInset;
    }

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final teamVm = widget.viewModel;
        final currentUser = teamVm.currentUser;
        final isLeader = currentUser?.isTeamLeader ?? false;
        final isModerator = currentUser?.isTeamMod ?? false;

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const ShapeDecoration(
            color: AppTheme.darkBackground,
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: const ShapeDecoration(
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
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
                          teamVm.currentTeam?.name ?? '',
                          style: TextStyle(
                            color: Color(teamVm.currentTeam?.color ?? AppTheme.primaryColor.toARGB32()),
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
              Expanded(
                child: teamVm.isChatLoading && teamVm.chatMessages.isEmpty
                    ? const LoadingWidget()
                    : teamVm.chatMessages.isEmpty
                        ? Center(child: Text(locale.noMessagesYet, style: const TextStyle(color: Colors.white38)))
                        : NotificationListener<ScrollNotification>(
                            onNotification: (scrollNotification) {
                              if (scrollNotification.metrics.pixels >=
                                      scrollNotification.metrics.maxScrollExtent - 10 &&
                                  (scrollNotification is OverscrollNotification ||
                                      scrollNotification is ScrollEndNotification)) {
                                _handleBottomRefresh();
                              }
                              return false;
                            },
                            child: ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
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
                                final systemText = _getLocalizedSystemMessage(locale, msg);

                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: ShapeDecoration(
                                    color: Colors.white.withAlpha(10),
                                    shape: BeveledRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
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
                                        ? Color(teamVm.currentTeam?.color ?? AppTheme.primaryColor.toARGB32()).withAlpha(20)
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
                                            label: Text(
                                              locale.delete.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
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
              ),
              if (_isRefreshingFromBottom)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  color: Colors.black.withAlpha(80),
                  child: const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
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
                        focusNode: _focusNode,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: locale.typeMessage,
                          hintStyle: const TextStyle(color: Colors.white38),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.darkBackground,
                          disabledBackgroundColor: AppTheme.primaryColor.withAlpha(100),
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(44, 44),
                          shape: const BeveledRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                        onPressed: _isSending
                            ? null
                            : () async {
                                final text = _messageController.text.trim();
                                if (text.isNotEmpty) {
                                  _messageController.clear();
                                  setState(() {
                                    _isSending = true;
                                  });
                                  final success = await teamVm.sendChatMessage(text);
                                  if (mounted) {
                                    setState(() {
                                      _isSending = false;
                                    });
                                  }
                                  if (success) {
                                    _scrollToBottom(animate: true);
                                  }
                                }
                              },
                        child: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.darkBackground,
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color: AppTheme.darkBackground,
                                size: 18,
                              ),
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
