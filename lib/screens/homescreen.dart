import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For JSON encoding/decoding

import '../models/folder.dart';
import '../widgets/folder_thumbnail.dart';
import 'planner.dart';

const Color kBackground = Color(0xFFFFFDF6);
const Color kPrimary = Color(0xFF2978A0);
const Color kAccent = Color(0xFFBBDEF0);
const Color kHighlight = Color(0xFFF3DFA2);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TravelFolder> _folders = [];
  final String _foldersKey = 'travel_folders';
  Map<String, int> _planCounts = {}; // Add this line

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final prefs = await SharedPreferences.getInstance();

    final String? foldersString = prefs.getString(_foldersKey);

    if (foldersString != null) {
      final List<dynamic> jsonList = jsonDecode(foldersString);
      setState(() {
        _folders = jsonList.map((json) => TravelFolder.fromJson(json)).toList();
      });
      await _loadPlanCounts(); // Add this line
    }
  }

  Future<void> _loadPlanCounts() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, int> counts = {};
    for (var folder in _folders) {
      final key = 'planner_items_${folder.name}';
      final data = prefs.getString(key);
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        counts[folder.id] = jsonList.length;
      } else {
        counts[folder.id] = 0;
      }
    }
    setState(() {
      _planCounts = counts;
    });
  }

  Future<void> _saveFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final String foldersString = jsonEncode(
      _folders.map((f) => f.toJson()).toList(),
    );
    await prefs.setString(_foldersKey, foldersString);
    await _loadPlanCounts(); // Add this line to refresh counts after changes
  }

  void _addFolder() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Travel Folder'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter country name'),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Create'),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _folders.add(
                      TravelFolder(
                        id:
                            DateTime.now().millisecondsSinceEpoch
                                .toString(), 
                        name: controller.text.trim(),
                        creationDate: DateTime.now(),
                      ),
                    );
                  });
                  _saveFolders(); 
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _editFolder(int index) {
    final TextEditingController controller = TextEditingController(
      text: _folders[index].name,
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rename Travel Folder'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter new country name',
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Rename'),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _folders[index].name = controller.text.trim();
                  });
                  _saveFolders();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteFolder(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Folder?'),
          content: Text(
            'Are you sure you want to delete "${_folders[index].name}"?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                setState(() {
                  _folders.removeAt(index);
                });
                _saveFolders(); 
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('My Travel Planners'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      body: _folders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.travel_explore, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'No travel plans yet!',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Tap the "+" icon to create your first planner.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.9,
              ),
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                final folder = _folders[index];
                final planCount = _planCounts[folder.id] ?? 0; // Add this line
                return Card(
                  child: FolderThumbnailCard(
                    folder: folder,
                    planCount: planCount, // Pass the count here
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PlannerDetailScreen(countryName: folder.name),
                        ),
                      );
                      await _loadPlanCounts(); // Refresh counts after returning
                    },
                    onLongPress: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ListTile(
                                  leading: const Icon(Icons.edit),
                                  title: const Text('Rename Folder'),
                                  onTap: () {
                                    Navigator.pop(
                                      context,
                                    ); // Close bottom sheet
                                    _editFolder(index);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  title: const Text(
                                    'Delete Folder',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onTap: () {
                                    Navigator.pop(
                                      context,
                                    ); // Close bottom sheet
                                    _deleteFolder(index);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFolder,
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: kBackground),
      ),
    );
  }
}
