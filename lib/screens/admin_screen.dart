// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final List<Map<String, dynamic>> loadedUsers = [];
      for (var doc in snapshot.docs) {
        loadedUsers.add({
          'id': doc.id,
          'lastKanjiId': doc.data()['lastKanjiId'] ?? '없음',
        });
      }

      setState(() {
        _users = loadedUsers;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching users: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터를 불러오는 데 실패했습니다: $e')),
      );
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      setState(() {
        _users.removeWhere((user) => user['id'] == userId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ID: $userId 사용자가 삭제되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 페이지 - 유저 리스트'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  title: Text('User ID: ${user['id']}'),
                  subtitle: Text(
                      '진행 현황: 한자[${user['lastKanjiId']}] / 동사[${user['lastVerbId']}]'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    onPressed: () => _deleteUser(user['id']),
                  ),
                );
              },
            ),
    );
  }
}
