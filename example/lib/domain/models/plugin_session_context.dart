import 'package:flutter/foundation.dart';

/// Authentication credentials passed to the embedded plugin.
@immutable
class AuthContext {
  final String token;
  final String tokenType;
  final int expiresIn;

  const AuthContext({
    required this.token,
    this.tokenType = 'Bearer',
    this.expiresIn = 3600,
  });

  Map<String, dynamic> toJson() => {
    'token': token,
    'tokenType': tokenType,
    'expiresIn': expiresIn,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthContext &&
          runtimeType == other.runtimeType &&
          token == other.token &&
          tokenType == other.tokenType &&
          expiresIn == other.expiresIn;

  @override
  int get hashCode => Object.hash(token, tokenType, expiresIn);
}

/// Fiscal and organization context required by accounting plugins.
@immutable
class FiscalContext {
  final String companyId;
  final String companyName;
  final String finYear;
  final String branchId;
  final String currency;

  const FiscalContext({
    required this.companyId,
    required this.companyName,
    required this.finYear,
    required this.branchId,
    required this.currency,
  });

  Map<String, dynamic> toJson() => {
    'companyId': companyId,
    'companyName': companyName,
    'finYear': finYear,
    'branchId': branchId,
    'currency': currency,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FiscalContext &&
          runtimeType == other.runtimeType &&
          companyId == other.companyId &&
          companyName == other.companyName &&
          finYear == other.finYear &&
          branchId == other.branchId &&
          currency == other.currency;

  @override
  int get hashCode => Object.hash(companyId, companyName, finYear, branchId, currency);
}

/// User identity and authorization profile.
@immutable
class UserContext {
  final String id;
  final String name;
  final String role;

  const UserContext({
    required this.id,
    required this.name,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserContext &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          role == other.role;

  @override
  int get hashCode => Object.hash(id, name, role);
}

/// Comprehensive session bootstrap envelope transmitted to embedded plugins.
@immutable
class PluginSessionContext {
  final AuthContext auth;
  final FiscalContext context;
  final UserContext user;

  const PluginSessionContext({
    required this.auth,
    required this.context,
    required this.user,
  });

  Map<String, dynamic> toJson() => {
    'auth': auth.toJson(),
    'context': context.toJson(),
    'user': user.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PluginSessionContext &&
          runtimeType == other.runtimeType &&
          auth == other.auth &&
          context == other.context &&
          user == other.user;

  @override
  int get hashCode => Object.hash(auth, context, user);

  @override
  String toString() => 'PluginSessionContext(company: ${context.companyId}, finYear: ${context.finYear}, user: ${user.name})';
}
