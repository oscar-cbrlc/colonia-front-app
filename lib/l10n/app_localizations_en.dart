// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginOrSignUp => 'Login or sign up';

  @override
  String get continueWithEmail => 'Continue with Email';

  @override
  String get selectYourAuthPref =>
      'Select your preferred method to continue setting up your account';

  @override
  String get ifCreatingNewAccount => 'If you are creating a new account, ';

  @override
  String get termsAndConditions => 'Terms & Conditions';

  @override
  String get and => 'and';

  @override
  String get privacyPolicy => 'Privace Policy';

  @override
  String get willApply => 'will apply';

  @override
  String get notValidInput => 'Not a valid input';

  @override
  String get enterYourEmail => 'Enter your email to log in or sign up';

  @override
  String get emailAddress => 'Email address';

  @override
  String get continueM => 'Continue';

  @override
  String get createPass => 'Create password';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get register => 'Register';

  @override
  String get yourPasswordMustInclude => 'Your password must include:';

  @override
  String get atLeast8Characters => 'At least 8 characters';

  @override
  String get oneUppercaseLetter => 'One uppercase letter';

  @override
  String get oneLowercaseLetter => 'One lowercase letter';

  @override
  String get oneNumber => 'One number';

  @override
  String get oneSpecialCharacter => 'One special character';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get loginButton => 'Log in';

  @override
  String get errorEmptyPassword => 'Password cannot be empty';

  @override
  String get createUsername => 'Create your username';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameHint => 'Cataglyphis-Maximus-99';

  @override
  String get usernameGuide => 'User name guide:';

  @override
  String get beBetween4and16Chars => 'Between 4-16 characters';

  @override
  String get onlyContainUsernameChars => 'Allowed letters, numbers, -, _, ?, !';

  @override
  String get createANameToIdentifyYou => 'Create a name so others identify you';

  @override
  String get map => 'Map';

  @override
  String get team => 'Team';

  @override
  String get profile => 'Profile';

  @override
  String get startActivity => 'Start activity';

  @override
  String get walk => 'Walk';

  @override
  String get run => 'Run';

  @override
  String get bike => 'Bike';

  @override
  String get activity => 'Activity';

  @override
  String get training => 'Training';

  @override
  String get free => 'Free';

  @override
  String get distance => 'Distance';

  @override
  String get time => 'Time';

  @override
  String get pace => 'Pace';

  @override
  String get timeTrial => 'Time Trial';

  @override
  String get setObjective => 'Objective';

  @override
  String get km => 'km';

  @override
  String get meters => 'meters';

  @override
  String get hours => 'hours';

  @override
  String get min => 'min';

  @override
  String get sec => 'sec';

  @override
  String get targetPace => 'Target pace (min/km)';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get pause => 'Pause';

  @override
  String get stop => 'Stop';

  @override
  String get resume => 'Resume';

  @override
  String get finish => 'Finish';

  @override
  String get setUpActivity => 'Set up activity';

  @override
  String get start => 'Start';

  @override
  String get timeUp => 'Time up';

  @override
  String get objectiveAchieved => 'Objective achieved';

  @override
  String get objectiveFailed => 'Objective failed';

  @override
  String get success => 'Success';

  @override
  String get remaining => 'Remaining';

  @override
  String get failed => 'Failed';

  @override
  String get trainingFinished => 'Training finished';

  @override
  String get activitySummary => 'Activity summary';

  @override
  String get nextImpact => 'Next impact';

  @override
  String get youNotHaveTeam => 'You are not part of a Colony';

  @override
  String get createTeam => 'Create a Colony';

  @override
  String get joinTeam => 'Join a Colony';

  @override
  String get description => 'Description';

  @override
  String get teamMembers => 'Colony members';

  @override
  String get name => 'Name';

  @override
  String get accessType => 'Access type';

  @override
  String get location => 'Location';

  @override
  String get private => 'Private';

  @override
  String get public => 'Public';

  @override
  String get color => 'Color';

  @override
  String get info => 'Info';

  @override
  String teamJoin(String username) {
    return '$username joined the colony';
  }

  @override
  String teamKick(String username) {
    return '$username has been exiled from the colony';
  }

  @override
  String teamExit(String username) {
    return '$username has abandoned the colony';
  }

  @override
  String get colonyChat => 'Colony Chat';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get delete => 'Delete';

  @override
  String get memberKicked => 'Member kicked from colony';

  @override
  String get leaderLeaveError =>
      'You cannot leave the colony as a Leader. Please promote another member to Leader first.';

  @override
  String get onlyMemberDeleteError =>
      'You are the only member. Please delete the colony instead.';

  @override
  String get leaveColonyTitle => 'Leave Colony';

  @override
  String get leaveColonyConfirm =>
      'Are you sure you want to leave this colony?';

  @override
  String get leave => 'Leave';

  @override
  String get leftColony => 'You have left the colony';

  @override
  String get actionRequired => 'Action Required';

  @override
  String get exploreColonies => 'EXPLORE COLONIES';

  @override
  String get searchByName => 'Search by name...';

  @override
  String get noColoniesFound => 'No colonies found';

  @override
  String get requestCancelled => 'Request cancelled';

  @override
  String get viewSentRequests => 'VIEW SENT REQUESTS';

  @override
  String get joinRequests => 'JOIN REQUESTS';

  @override
  String get leaveColony => 'LEAVE COLONY';

  @override
  String get ok => 'OK';

  @override
  String get colonyNotFound => 'Colony not found';

  @override
  String get requestRejected => 'Request rejected';

  @override
  String get requestPending => 'Request pending';

  @override
  String get failedToCancelRequest => 'Failed to cancel request';

  @override
  String get declineRequest => 'Decline request';

  @override
  String get successfullyJoinedColony => 'Successfully joined the colony';

  @override
  String get requestSentSuccessfully => 'Request sent successfully';

  @override
  String get requestToJoin => 'Request to join';

  @override
  String get memberPromotedToMod => 'Member promoted to moderator';

  @override
  String promoteToLeaderConfirm(String username) {
    return 'Are you sure you want to promote $username to Leader? You will lose Leader privileges.';
  }

  @override
  String get leadershipTransferred => 'Leadership transferred';

  @override
  String get memberDemotedToMember => 'Member demoted to member';

  @override
  String kickMemberConfirm(String username) {
    return 'Are you sure you want to kick $username from the colony?';
  }

  @override
  String get colonyDeleted => 'Colony deleted';

  @override
  String get deleteColony => 'Delete colony';

  @override
  String get deleteColonyConfirm =>
      'Are you sure you want to delete this colony?';

  @override
  String get kickMember => 'Kick member';

  @override
  String get kick => 'Kick';

  @override
  String get promoteToModerator => 'Promote to moderator';

  @override
  String get promoteToLeader => 'Promote to leader';

  @override
  String get demote => 'Demote';

  @override
  String get demoteToMember => 'Demote to member';

  @override
  String get transferLeadership => 'Transfer Leadership';

  @override
  String get promote => 'Promote';

  @override
  String get cannotDelete => 'Cannot Delete';

  @override
  String get cannotDeleteActiveMembers =>
      'You cannot delete a colony with active members';

  @override
  String get colonyUpdatedSuccessfully => 'Colony updated successfully';

  @override
  String get colonyCreatedSuccessfully => 'Colony created successfully';

  @override
  String get accepted => 'accepted';
}
