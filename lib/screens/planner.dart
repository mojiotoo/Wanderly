import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/planner_item.dart';

const Color kBackground = Color(0xFFFFFDF6);
const Color kPrimary = Color(0xFF2978A0);
const Color kAccent = Color(0xFFBBDEF0);
const Color kHighlight = Color(0xFFF3DFA2);

class PlannerDetailScreen extends StatefulWidget {
  final String countryName;

  const PlannerDetailScreen({super.key, required this.countryName});

  @override
  State<PlannerDetailScreen> createState() => _PlannerDetailScreenState();
}

class _PlannerDetailScreenState extends State<PlannerDetailScreen> {
  List<PlannerItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'planner_items_${widget.countryName}';
    final data = prefs.getString(key);
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      setState(() {
        _items = jsonList.map((e) => PlannerItem.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'planner_items_${widget.countryName}';
    final jsonList = _items.map((e) => e.toJson()).toList();
    await prefs.setString(key, jsonEncode(jsonList));
  }

  void _addOrEditItem({PlannerItem? item, int? index}) async {
    final result = await showDialog<PlannerItem>(
      context: context,
      builder: (context) => PlannerItemDialog(item: item),
    );
    if (result != null) {
      setState(() {
        if (index != null) {
          _items[index] = result;
        } else {
          _items.add(result);
        }
        _items.sort((a, b) {
          final dateCompare = a.date.compareTo(b.date);
          if (dateCompare != 0) return dateCompare;
          return a.time.hour * 60 + a.time.minute - (b.time.hour * 60 + b.time.minute);
        });
      });
      await _saveItems();
    }
  }

  void _deleteItem(int index) async {
    setState(() {
      _items.removeAt(index);
    });
    await _saveItems();
  }

  double get _totalPrice => _items.fold(0, (sum, e) => sum + e.price);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: Text('${widget.countryName} Planner'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      body: _items.isEmpty
          ? Center(
              child: Text(
                'No plans yet. Tap + to add.',
                style: const TextStyle(fontSize: 18),
              ),
            )
          : ListView.separated(
              itemCount: _items.length + 1,
              separatorBuilder: (context, idx) {
                // Only add divider between items, not after the last item or before the total
                if (idx < _items.length - 1) {
                  return const Divider(height: 1, thickness: 1);
                }
                return const SizedBox.shrink();
              },
              itemBuilder: (context, idx) {
                if (idx == _items.length) {
                  return Container(
                    color: kHighlight,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ListTile(
                      title: const Text(
                        'Total Budget',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        '\$${_totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
                final item = _items[idx];
                return Stack(
                  children: [
                    ListTile(
                      tileColor: kBackground,
                      title: Padding(
                        padding: const EdgeInsets.only(right: 40.0), // reduce space for icons
                        child: Text(item.place),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(right: 40.0),
                        child: Text(
                          '${item.date.toLocal().toString().split(' ')[0]} '
                          '${item.time.format(context)}\n'
                          'Price: \$${item.price.toStringAsFixed(2)}',
                        ),
                      ),
                      isThreeLine: true,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey, size: 18),
                            onPressed: () => _addOrEditItem(item: item, index: idx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact, // Remove extra padding
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey, size: 18),
                            onPressed: () => _deleteItem(idx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact, // Remove extra padding
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditItem(),
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: kBackground),
      ),
    );
  }
}

class PlannerItemDialog extends StatefulWidget {
  final PlannerItem? item;
  const PlannerItemDialog({super.key, this.item});

  @override
  State<PlannerItemDialog> createState() => _PlannerItemDialogState();
}

class _PlannerItemDialogState extends State<PlannerItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _placeController;
  late TextEditingController _priceController;
  DateTime? _date;
  TimeOfDay? _time;

  @override
  void initState() {
    super.initState();
    _placeController = TextEditingController(text: widget.item?.place ?? '');
    _priceController = TextEditingController(
        text: widget.item != null ? widget.item!.price.toString() : '');
    _date = widget.item?.date;
    _time = widget.item?.time;
  }

  @override
  void dispose() {
    _placeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Add Planner Item' : 'Edit Planner Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _placeController,
                decoration: const InputDecoration(labelText: 'Place'),
                validator: (v) => v == null || v.isEmpty ? 'Enter place' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter price';
                  final val = double.tryParse(v);
                  if (val == null || val < 0) return 'Enter valid price';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(_date == null
                    ? 'Select Date'
                    : _date!.toLocal().toString().split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              ListTile(
                title: Text(_time == null
                    ? 'Select Time'
                    : _time!.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _time ?? TimeOfDay.now(),
                  );
                  if (picked != null) setState(() => _time = picked);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() &&
                _date != null &&
                _time != null) {
              Navigator.pop(
                context,
                PlannerItem(
                  id: widget.item?.id ?? UniqueKey().toString(),
                  place: _placeController.text,
                  time: _time!,
                  date: _date!,
                  price: double.parse(_priceController.text),
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
