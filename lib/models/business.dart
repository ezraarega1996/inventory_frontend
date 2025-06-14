import 'package:uuid/uuid.dart';

class Business {
  final String id;
  final String name;
  final String? logo;
  final bool isActive;
  final String subscriptionStatus;
  final String subscriptionPlan;
  final DateTime? trialEndsAt;
  final DateTime? subscriptionEndsAt;

  Business({
    String? id,
    required this.name,
    this.logo,
    this.isActive = true,
    this.subscriptionStatus = 'trial',
    this.subscriptionPlan = 'free',
    this.trialEndsAt,
    this.subscriptionEndsAt,
  }) : id = id ?? const Uuid().v4();

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'],
      name: json['name'],
      logo: json['logo'],
      isActive: json['isActive'] ?? true,
      subscriptionStatus: json['subscriptionStatus'] ?? 'trial',
      subscriptionPlan: json['subscriptionPlan'] ?? 'free',
      trialEndsAt:
          json['trialEndsAt'] != null
              ? DateTime.parse(json['trialEndsAt'])
              : null,
      subscriptionEndsAt:
          json['subscriptionEndsAt'] != null
              ? DateTime.parse(json['subscriptionEndsAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'isActive': isActive,
      'subscriptionStatus': subscriptionStatus,
      'subscriptionPlan': subscriptionPlan,
      'trialEndsAt': trialEndsAt?.toIso8601String(),
      'subscriptionEndsAt': subscriptionEndsAt?.toIso8601String(),
    };
  }

  Business copyWith({
    String? name,
    String? logo,
    bool? isActive,
    String? subscriptionStatus,
    String? subscriptionPlan,
    DateTime? trialEndsAt,
    DateTime? subscriptionEndsAt,
  }) {
    return Business(
      id: id,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      isActive: isActive ?? this.isActive,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      subscriptionEndsAt: subscriptionEndsAt ?? this.subscriptionEndsAt,
    );
  }

  @override
  String toString() {
    return 'Business(id: $id, name: $name, logo: $logo, isActive: $isActive, subscriptionStatus: $subscriptionStatus, subscriptionPlan: $subscriptionPlan, trialEndsAt: $trialEndsAt, subscriptionEndsAt: $subscriptionEndsAt)';
  }
}
