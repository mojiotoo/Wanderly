import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For JSON encoding/decoding

import '../models/folder.dart';
import '../widgets/folderThumbnail.dart';
import 'planner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TravelFolder> _folders = [];
  final String _foldersKey = 'travel_folders';

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
    }
  }

  Future<void> _saveFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final String foldersString = jsonEncode(
      _folders.map((f) => f.toJson()).toList(),
    );
    await prefs.setString(_foldersKey, foldersString);
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
                                .toString(), // Simple unique ID
                        name: controller.text.trim(),
                        creationDate: DateTime.now(),
                      ),
                    );
                  });
                  _saveFolders(); // Save changes
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
                  _saveFolders(); // Save changes
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
                _saveFolders(); // Save changes
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
      appBar: AppBar(
        title: const Text('My Travel Planners'),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _addFolder,
          ),
        ],
      ),
      body:
          _folders.isEmpty
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
                  crossAxisCount: 2, // Two folders per row
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.9,
                ),
                itemCount: _folders.length,
                itemBuilder: (context, index) {
                  final folder = _folders[index];
                  return FolderThumbnailCard(
                    folder: folder,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  PlannerDetailScreen(countryName: folder.name),
                        ),
                      );
                    },
                    onLongPress: () {
                      // Show options to edit or delete on long press
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
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFolder,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
