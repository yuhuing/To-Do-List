import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum Priority { high, medium, low }

class Task {
  String? firestoreId; // Add this to track Firestore document ID
  String title;
  String details;
  DateTime? dueDate;
  bool isDone;
  Priority priority;
  DateTime? createdAt;
  DateTime? updatedAt;
  bool completeLate;
  bool isPriorityManual;

  Task({
    this.firestoreId,
    required this.title,
    this.details = '',
    this.dueDate,
    this.isDone = false,
    this.priority = Priority.medium,
    this.createdAt,
    this.updatedAt,
    this.completeLate = false,
    this.isPriorityManual = false,
  }) {
    createdAt ??= DateTime.now();
  }

  // Helper method to get priority color
  Color get priorityColor {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  // Helper method to get priority display name
  String get priorityDisplayName {
    switch (priority) {
      case Priority.high:
        return 'High';
      case Priority.medium:
        return 'Medium';
      case Priority.low:
        return 'Low';
    }
  }

  // Helper method to determine if task is overdue
  bool get isOverdue {
    if (dueDate == null || isDone) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return taskDate.isBefore(today);
  }

  // Helper method to get days until due
  int? get daysUntilDue {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return taskDate.difference(today).inDays;
  }

  // Convert Task to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'details': details,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'isDone': isDone,
      'priority': priority.toString().split('.').last, // Convert enum to string
      'createdAt':
          createdAt != null
              ? Timestamp.fromDate(createdAt!)
              : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'completeLate': completeLate,
      'isPriorityManual': isPriorityManual,
    };
  }

  // Create Task from Firestore document
  factory Task.fromFirestore(String docId, Map<String, dynamic> data) {
    return Task(
      firestoreId: docId,
      title: data['title'] ?? '',
      details: data['details'] ?? '',
      dueDate:
          data['dueDate'] != null
              ? (data['dueDate'] as Timestamp).toDate()
              : null,
      isDone: data['isDone'] ?? false,
      priority: _parsePriority(data['priority']),
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      updatedAt:
          data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
      completeLate: data['completeLate'] ?? false,
      isPriorityManual: data['isPriorityManual'] ?? false,
    );
  }

  // Helper method to parse priority string to enum
  static Priority _parsePriority(dynamic priorityData) {
    if (priorityData == null) return Priority.medium;

    final priorityStr = priorityData.toString().toLowerCase();
    switch (priorityStr) {
      case 'high':
        return Priority.high;
      case 'low':
        return Priority.low;
      case 'medium':
      default:
        return Priority.medium;
    }
  }

  // Copy constructor for updates
  Task copyWith({
    String? firestoreId,
    String? title,
    String? details,
    DateTime? dueDate,
    bool? isDone,
    Priority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? completeLate,
    bool? isPriorityManual,
  }) {
    return Task(
      firestoreId: firestoreId ?? this.firestoreId,
      title: title ?? this.title,
      details: details ?? this.details,
      dueDate: dueDate ?? this.dueDate,
      isDone: isDone ?? this.isDone,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completeLate: completeLate ?? this.completeLate,
      isPriorityManual: isPriorityManual ?? this.isPriorityManual,
    );
  }

  @override
  String toString() {
    return 'Task(id: $firestoreId, title: $title, isDone: $isDone, priority: $priority, dueDate: $dueDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.firestoreId == firestoreId;
  }

  @override
  int get hashCode => firestoreId.hashCode;
}
