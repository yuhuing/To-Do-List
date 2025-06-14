import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/AppDrawer.dart';


// Color constants matching the pattern
class AppColors {
  static const Color espresso = Color(0xFF2C1810);
  static const Color coffeeBrown = Color(0xFF4A2C2A);
  static const Color caramelBrown = Color(0xFF8B5A2B);
  static const Color creamWhite = Color(0xFFFAF7F2);
  static const Color milkFoam = Color(0xFFF5F2ED);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color coffeeShadow = Color(0x1A2C1810);
}

// ======= MODELS =======
class GroupMember {
  final String id;
  final String name;
  final String email;

  GroupMember({required this.id, required this.name, required this.email});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'email': email};
  }

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
    );
  }
}

class Task {
  final String id;
  final String title;
  final String assignedTo;
  final String createdBy;
  final DateTime createdAt;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.assignedTo,
    required this.createdBy,
    required this.createdAt,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      assignedTo: map['assignedTo'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

class Group {
  final String id;
  final String name;
  final String createdBy;
  final List<GroupMember> members;

  Group({required this.id, required this.name, required this.createdBy})
    : members = [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdBy': createdBy,
      'members': members.map((member) => member.toMap()).toList(),
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    final group = Group(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      createdBy: map['createdBy'] ?? '',
    );

    if (map['members'] != null) {
      group.members.addAll(
        (map['members'] as List).map(
          (memberMap) => GroupMember.fromMap(memberMap),
        ),
      );
    }

    return group;
  }

  bool isCreatedByCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && createdBy == user.uid;
  }

  bool isCurrentUserMember() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return members.any((member) => member.id == user.uid);
  }
}

// ======= FIREBASE SERVICE =======
class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  // Find user by email
  static Future<DocumentSnapshot?> findUserByEmail(String email) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email.toLowerCase())
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first;
      }
      return null;
    } catch (e) {
      print('Error finding user: $e');
      return null;
    }
  }

  // Create group
  static Future<String?> createGroup(String groupName) async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final groupDoc = _firestore.collection('groups').doc();
      final group = Group(
        id: groupDoc.id,
        name: groupName,
        createdBy: user.uid,
      );

      // Add creator as the first member
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final creatorMember = GroupMember(
          id: user.uid,
          name: userData['name'] ?? user.email?.split('@')[0] ?? 'User',
          email: user.email ?? '',
        );
        group.members.add(creatorMember);
      }

      await groupDoc.set(group.toMap());

      // Add group to user's groups list
      await _firestore.collection('users').doc(user.uid).update({
        'groups': FieldValue.arrayUnion([groupDoc.id]),
      });

      return groupDoc.id;
    } catch (e) {
      print('Error creating group: $e');
      return null;
    }
  }

  // Add member to group
  static Future<bool> addMemberToGroup(
    String groupId,
    String memberEmail,
  ) async {
    try {
      final userDoc = await findUserByEmail(memberEmail);
      if (userDoc == null) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      final member = GroupMember(
        id: userDoc.id,
        name: userData['name'] ?? memberEmail.split('@')[0],
        email: memberEmail,
      );

      // Check if member already exists
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (groupDoc.exists) {
        final groupData = groupDoc.data() as Map<String, dynamic>;
        final existingMembers = List<Map<String, dynamic>>.from(
          groupData['members'] ?? [],
        );

        bool alreadyMember = existingMembers.any((m) => m['id'] == userDoc.id);
        if (alreadyMember) return false;
      }

      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([member.toMap()]),
      });

      await _firestore.collection('users').doc(userDoc.id).update({
        'groups': FieldValue.arrayUnion([groupId]),
      });

      return true;
    } catch (e) {
      print('Error adding member: $e');
      return false;
    }
  }

  // Remove member from group
  static Future<bool> removeMemberFromGroup(
    String groupId,
    String memberId,
  ) async {
    try {
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) return false;

      final groupData = groupDoc.data() as Map<String, dynamic>;
      final members = List<Map<String, dynamic>>.from(
        groupData['members'] ?? [],
      );

      members.removeWhere((member) => member['id'] == memberId);

      await _firestore.collection('groups').doc(groupId).update({
        'members': members,
      });

      await _firestore.collection('users').doc(memberId).update({
        'groups': FieldValue.arrayRemove([groupId]),
      });

      // Delete member's tasks
      final tasksSnapshot =
          await _firestore
              .collection('groups')
              .doc(groupId)
              .collection('tasks')
              .where('assignedTo', isEqualTo: memberId)
              .get();

      for (var taskDoc in tasksSnapshot.docs) {
        await taskDoc.reference.delete();
      }

      return true;
    } catch (e) {
      print('Error removing member: $e');
      return false;
    }
  }

  // Create task
  static Future<String?> createTask(
    String groupId,
    String title,
    String assignedToId,
  ) async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final taskDoc =
          _firestore
              .collection('groups')
              .doc(groupId)
              .collection('tasks')
              .doc();
      final task = Task(
        id: taskDoc.id,
        title: title,
        assignedTo: assignedToId,
        createdBy: user.uid,
        createdAt: DateTime.now(),
      );

      await taskDoc.set(task.toMap());
      return taskDoc.id;
    } catch (e) {
      print('Error creating task: $e');
      return null;
    }
  }

  // Delete task
  static Future<bool> deleteTask(String groupId, String taskId) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('tasks')
          .doc(taskId)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }

  // Toggle task completion
  static Future<bool> toggleTaskCompletion(
    String groupId,
    String taskId,
    bool isCompleted,
  ) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('tasks')
          .doc(taskId)
          .update({'isCompleted': isCompleted});
      return true;
    } catch (e) {
      print('Error toggling task: $e');
      return false;
    }
  }

  // Get groups stream
  static Stream<List<Group>> getGroupsStream() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return _firestore.collection('groups').snapshots().map((snapshot) {
      List<Group> userGroups = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final group = Group.fromMap(data);

        if (group.createdBy == user.uid ||
            group.members.any((member) => member.id == user.uid)) {
          userGroups.add(group);
        }
      }

      return userGroups;
    });
  }

  // Get tasks stream
  static Stream<List<Task>> getTasksStream(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Task.fromMap(data);
          }).toList();
        });
  }

  static Future<bool> deleteGroup(String groupId) async {
    try {
      final groupDocRef = _firestore.collection('groups').doc(groupId);

      // Get group data to find members before deleting
      final groupDoc = await groupDocRef.get();
      if (!groupDoc.exists) {
        print('Group not found, cannot delete.');
        return false;
      }

      final groupData = groupDoc.data() as Map<String, dynamic>;
      final members = List<Map<String, dynamic>>.from(
        groupData['members'] ?? [],
      );

      // 1. Delete all tasks in the sub-collection using a batch write for efficiency
      final tasksSnapshot = await groupDocRef.collection('tasks').get();
      final batch = _firestore.batch();
      for (var doc in tasksSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // 2. Remove group ID from each member's user document
      for (var member in members) {
        final memberId = member['id'];
        if (memberId != null) {
          await _firestore.collection('users').doc(memberId).update({
            'groups': FieldValue.arrayRemove([groupId]),
          });
        }
      }

      // 3. Delete the group document itself
      await groupDocRef.delete();

      return true;
    } catch (e) {
      print('Error deleting group: $e');
      return false;
    }
  }
}

// ======= MAIN PAGE =======
class GroupCollaborationPage extends StatefulWidget {
  @override
  State<GroupCollaborationPage> createState() => _GroupCollaborationPageState();
}

class _GroupCollaborationPageState extends State<GroupCollaborationPage> {
  final TextEditingController _groupController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: AppColors.creamWhite,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.groups, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              "Group Collaboration",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: AppColors.espresso,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.espresso, AppColors.coffeeBrown],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Create Group Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.coffeeShadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.caramelBrown.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_circle_outline,
                          color: AppColors.caramelBrown,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Create New Group",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.espresso,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.milkFoam,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.caramelBrown.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _groupController,
                            decoration: InputDecoration(
                              hintText: 'Enter group name',
                              hintStyle: TextStyle(
                                color: AppColors.coffeeBrown.withOpacity(0.6),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            style: TextStyle(
                              color: AppColors.espresso,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.caramelBrown,
                              AppColors.coffeeBrown,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.caramelBrown.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_groupController.text.trim().isNotEmpty) {
                              final groupId = await FirebaseService.createGroup(
                                _groupController.text.trim(),
                              );
                              if (groupId != null) {
                                _groupController.clear();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Group created successfully!',
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Failed to create group',
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Create",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Groups List
            Expanded(
              child: StreamBuilder<List<Group>>(
                stream: FirebaseService.getGroupsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.caramelBrown,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.coffeeShadow,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.group_off,
                                  size: 64,
                                  color: AppColors.caramelBrown.withOpacity(
                                    0.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No groups yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.espresso,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create your first group above!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.coffeeBrown,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final groups = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      return GroupCard(group: groups[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======= GROUP CARD =======
class GroupCard extends StatelessWidget {
  final Group group;

  const GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final TextEditingController _memberController = TextEditingController();
    final TextEditingController _taskController = TextEditingController();
    final bool isCreator = group.isCreatedByCurrentUser();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.coffeeShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: ExpansionTileThemeData(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.all(0),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.caramelBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.group,
                  color: AppColors.caramelBrown,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.espresso,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.milkFoam,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${group.members.length} members',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.coffeeBrown,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isCreator
                                    ? Colors.orange.withOpacity(0.2) // Owner
                                    : Colors.green.withOpacity(0.2), // Member
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isCreator
                                      ? Colors.orange.withOpacity(
                                        0.3,
                                      ) // Owner border
                                      : Colors.green.withOpacity(
                                        0.3,
                                      ), // Member border
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isCreator ? "Owner" : "Member",
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isCreator
                                      ? Colors
                                          .orange
                                          .shade700 // Owner text
                                      : Colors.green.withOpacity(
                                        0.8,
                                      ), // Member text color
                              fontWeight:
                                  isCreator ? FontWeight.w600 : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isCreator)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  onPressed: () => _showDeleteGroupDialog(context, group),
                  tooltip: 'Delete Group',
                ),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add Member Section (Only for creators)
                  if (isCreator) ...[
                    _buildSectionHeader("Add Member", Icons.person_add),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.milkFoam,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.caramelBrown.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _memberController,
                              decoration: InputDecoration(
                                hintText: 'Enter member email',
                                hintStyle: TextStyle(
                                  color: AppColors.coffeeBrown.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              style: TextStyle(
                                color: AppColors.espresso,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton("Add", Icons.add, () async {
                          if (_memberController.text.trim().isNotEmpty) {
                            final success =
                                await FirebaseService.addMemberToGroup(
                                  group.id,
                                  _memberController.text.trim(),
                                );

                            _memberController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Member added!'
                                      : 'Failed to add member',
                                ),
                                backgroundColor:
                                    success ? Colors.green : Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Create Task Section
                  _buildSectionHeader("Create Task", Icons.assignment),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.milkFoam,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.caramelBrown.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _taskController,
                            decoration: InputDecoration(
                              hintText: 'Enter task description',
                              hintStyle: TextStyle(
                                color: AppColors.coffeeBrown.withOpacity(0.6),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            style: TextStyle(
                              color: AppColors.espresso,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildActionButton("Create", Icons.add_task, () {
                        if (_taskController.text.trim().isNotEmpty) {
                          _showAssignTaskDialog(
                            context,
                            group,
                            _taskController.text.trim(),
                          );
                          _taskController.clear();
                        }
                      }),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Members List
                  if (group.members.isNotEmpty) ...[
                    _buildSectionHeader("Members", Icons.people),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.milkFoam,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children:
                            group.members.asMap().entries.map((entry) {
                              final index = entry.key;
                              final member = entry.value;
                              final isCurrentUser =
                                  FirebaseAuth.instance.currentUser?.uid ==
                                  member.id;
                              final isLast = index == group.members.length - 1;

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border:
                                      isLast
                                          ? null
                                          : Border(
                                            bottom: BorderSide(
                                              color: AppColors.caramelBrown
                                                  .withOpacity(0.1),
                                              width: 1,
                                            ),
                                          ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.caramelBrown
                                          .withOpacity(0.1),
                                      child: Text(
                                        member.name[0].toUpperCase(),
                                        style: TextStyle(
                                          color: AppColors.caramelBrown,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            member.name +
                                                (isCurrentUser ? ' (You)' : ''),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.espresso,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            member.email,
                                            style: TextStyle(
                                              color: AppColors.coffeeBrown,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isCreator && !isCurrentUser)
                                      IconButton(
                                        icon: Icon(
                                          Icons.remove_circle,
                                          color: Colors.red.shade400,
                                          size: 20,
                                        ),
                                        onPressed:
                                            () => _showRemoveMemberDialog(
                                              context,
                                              group,
                                              member,
                                            ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Tasks Section
                  StreamBuilder<List<Task>>(
                    stream: FirebaseService.getTasksStream(group.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Column(
                          children: [
                            _buildSectionHeader("Tasks", Icons.assignment),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.milkFoam,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'No tasks yet',
                                  style: TextStyle(
                                    color: AppColors.coffeeBrown,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      final tasks = snapshot.data!;
                      return TasksView(tasks: tasks, group: group);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.caramelBrown.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: AppColors.caramelBrown, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.caramelBrown, AppColors.coffeeBrown],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.caramelBrown.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showAssignTaskDialog(
    BuildContext context,
    Group group,
    String taskTitle,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Assign Task',
              style: TextStyle(
                color: AppColors.espresso,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.milkFoam,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Task: $taskTitle',
                    style: TextStyle(
                      color: AppColors.espresso,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Assign to:',
                  style: TextStyle(
                    color: AppColors.coffeeBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...group.members.map(
                  (member) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.milkFoam,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.caramelBrown.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.caramelBrown.withOpacity(
                          0.1,
                        ),
                        child: Text(
                          member.name[0].toUpperCase(),
                          style: TextStyle(
                            color: AppColors.caramelBrown,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        member.name,
                        style: TextStyle(
                          color: AppColors.espresso,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        member.email,
                        style: TextStyle(
                          color: AppColors.coffeeBrown,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        final taskId = await FirebaseService.createTask(
                          group.id,
                          taskTitle,
                          member.id,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              taskId != null
                                  ? 'Task assigned to ${member.name}'
                                  : 'Failed to create task',
                            ),
                            backgroundColor:
                                taskId != null ? Colors.green : Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.coffeeBrown),
                ),
              ),
            ],
          ),
    );
  }

  void _showRemoveMemberDialog(
    BuildContext context,
    Group group,
    GroupMember member,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Remove Member',
              style: TextStyle(
                color: AppColors.espresso,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Remove ${member.name} from this group?\n\nThis will also delete all tasks assigned to them.',
              style: TextStyle(color: AppColors.coffeeBrown),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.coffeeBrown),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await FirebaseService.removeMemberFromGroup(
                    group.id,
                    member.id,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? '${member.name} removed'
                            : 'Failed to remove member',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }

  void _showDeleteGroupDialog(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder:
          (context) => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 370, minWidth: 370),
              child: AlertDialog(
                backgroundColor: AppColors.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Delete Group',
                      style: TextStyle(
                        color: AppColors.espresso,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Are you sure you want to delete the group "${group.name}"?',
                  style: TextStyle(
                    color: AppColors.coffeeBrown,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.coffeeBrown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context); // Close dialog first
                      final success = await FirebaseService.deleteGroup(
                        group.id,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Group "${group.name}" deleted successfully.'
                                  : 'Failed to delete group.',
                            ),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      backgroundColor: Colors.red[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

// ======= TASKS VIEW =======
class TasksView extends StatelessWidget {
  final List<Task> tasks;
  final Group group;

  const TasksView({required this.tasks, required this.group});

  @override
  Widget build(BuildContext context) {
    // Group tasks by member
    Map<String, List<Task>> tasksByMember = {};

    for (var member in group.members) {
      tasksByMember[member.id] = [];
    }

    for (var task in tasks) {
      if (tasksByMember.containsKey(task.assignedTo)) {
        tasksByMember[task.assignedTo]!.add(task);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.caramelBrown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.assignment,
                color: AppColors.caramelBrown,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Tasks by Member',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.milkFoam,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children:
                group.members.asMap().entries.map((entry) {
                  final index = entry.key;
                  final member = entry.value;
                  final memberTasks = tasksByMember[member.id] ?? [];
                  final completed =
                      memberTasks.where((t) => t.isCompleted).length;
                  final isLast = index == group.members.length - 1;

                  return Container(
                    decoration: BoxDecoration(
                      border:
                          isLast
                              ? null
                              : Border(
                                bottom: BorderSide(
                                  color: AppColors.caramelBrown.withOpacity(
                                    0.1,
                                  ),
                                  width: 1,
                                ),
                              ),
                    ),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.caramelBrown.withOpacity(
                            0.1,
                          ),
                          child: Text(
                            member.name[0].toUpperCase(),
                            style: TextStyle(
                              color: AppColors.caramelBrown,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        title: Text(
                          member.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.espresso,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${completed}/${memberTasks.length} completed',
                          style: TextStyle(
                            color: AppColors.coffeeBrown,
                            fontSize: 12,
                          ),
                        ),
                        children: [
                          if (memberTasks.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                'No tasks assigned',
                                style: TextStyle(
                                  color: AppColors.coffeeBrown.withOpacity(0.7),
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          else
                            ...memberTasks.map(
                              (task) => TaskItem(task: task, group: group),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}

// ======= TASK ITEM =======
class TaskItem extends StatelessWidget {
  final Task task;
  final Group group;

  const TaskItem({required this.task, required this.group});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final canManage =
        currentUser != null &&
        (task.createdBy == currentUser.uid ||
            task.assignedTo == currentUser.uid ||
            group.isCreatedByCurrentUser());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.caramelBrown.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: task.isCompleted,
            onChanged:
                canManage
                    ? (value) async {
                      await FirebaseService.toggleTaskCompletion(
                        group.id,
                        task.id,
                        value ?? false,
                      );
                    }
                    : null,
            activeColor: AppColors.caramelBrown,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                    color:
                        task.isCompleted
                            ? AppColors.coffeeBrown.withOpacity(0.6)
                            : AppColors.espresso,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Created: ${task.createdAt.day}/${task.createdAt.month}/${task.createdAt.year}',
                  style: TextStyle(
                    color: AppColors.coffeeBrown.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 2),

                FutureBuilder<String>(
                  future: _getCreatorName(task.createdBy),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        'Created by: ${snapshot.data}',
                        style: TextStyle(
                          color: AppColors.caramelBrown.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          if (canManage)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red.shade400,
                size: 18,
              ),
              onPressed: () => _showDeleteTaskDialog(context, task, group),
            ),
        ],
      ),
    );
  }

  void _showDeleteTaskDialog(BuildContext context, Task task, Group group) {
    showDialog(
      context: context,
      builder:
          (context) => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 370, minWidth: 370),
              child: AlertDialog(
                backgroundColor: AppColors.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Delete Task',
                      style: TextStyle(
                        color: AppColors.espresso,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Are you sure you want to delete the task "${task.title}"?',
                  style: TextStyle(
                    color: AppColors.coffeeBrown,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.coffeeBrown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context); // Close dialog first
                      final success = await FirebaseService.deleteTask(
                        group.id,
                        task.id,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Task deleted successfully.'
                                  : 'Failed to delete task.',
                            ),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      backgroundColor: Colors.red[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // Add this method inside the TaskItem class:
  Future<String> _getCreatorName(String creatorId) async {
    // First check if it's someone in the group
    final creator = group.members.firstWhere(
      (member) => member.id == creatorId,
      orElse: () => GroupMember(id: '', name: '', email: ''),
    );

    if (creator.id.isNotEmpty) {
      return creator.name;
    }

    // If not found in group members, try to get from Firestore
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(creatorId)
              .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['name'] ??
            userData['email']?.split('@')[0] ??
            'Unknown';
      }
    } catch (e) {
      print('Error getting creator name: $e');
    }

    return 'Unknown';
  }
}
