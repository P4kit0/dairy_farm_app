import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MiscarriagePage extends StatefulWidget {
  @override
  _MiscarriagePageState createState() => _MiscarriagePageState();
}

class _MiscarriagePageState extends State<MiscarriagePage> {
  final _cattleIdController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isFormVisible = false;
  String? _editingRecordId;

  final CollectionReference _miscarriageCollection =
      FirebaseFirestore.instance.collection('miscarriage_records');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Miscarriage Records'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Miscarriage Card
                    Card(
                      color: Colors.white,
                      elevation: 4.0,
                      margin: const EdgeInsets.all(8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Miscarriage Details',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.lightBlueAccent,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            _isFormVisible ? _buildMiscarriageForm() : SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ),
                    // Miscarriage List
                    Card(
                      color: Colors.white,
                      elevation: 4.0,
                      margin: const EdgeInsets.all(8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Miscarriage List',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.lightBlueAccent,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            _buildMiscarriageList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isFormVisible = !_isFormVisible;
            if (_isFormVisible) {
              _clearForm();
              _editingRecordId = null;
            }
          });
        },
        child: Icon(_isFormVisible ? Icons.close : Icons.add),
        backgroundColor: Colors.lightBlueAccent,
      ),
    );
  }

  Widget _buildMiscarriageForm() {
    return Column(
      children: [
        // Cattle Serial Number
        TextFormField(
          controller: _cattleIdController,
          decoration: InputDecoration(
            labelText: 'Select Cattle',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16.0),

        // Date of Miscarriage
        TextFormField(
          controller: _dateController,
          decoration: InputDecoration(
            labelText: 'Date Of Miscarriage',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            suffixIcon: GestureDetector(
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  String formattedDate = '${pickedDate.year.toString().padLeft(4, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
                  setState(() {
                    _dateController.text = formattedDate;
                  });
                }
              },
              child: Icon(Icons.calendar_today),
            ),
          ),
          keyboardType: TextInputType.datetime,
        ),
        const SizedBox(height: 16.0),

        // Notes
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: 'Notes',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16.0),

        ElevatedButton(
          onPressed: () {
            _isFormVisible ? _submitForm() : null;
          },
          child: Text(_editingRecordId == null ? 'Submit' : 'Update'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiscarriageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _miscarriageCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final records = snapshot.data?.docs ?? [];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Cattle Name')),
              DataColumn(label: Text('Miscarriage Date')),
              DataColumn(label: Text('Actions')),
            ],
            rows: records.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return DataRow(
                cells: [
                  DataCell(Text(data['cattleId'] ?? 'N/A')),
                  DataCell(Text(data['date'] ?? 'N/A')),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _showEditForm(doc.id, data);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _confirmDeleteRecord(doc.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _submitForm() async {
    final cattleId = _cattleIdController.text;
    final date = _dateController.text;
    final notes = _notesController.text;

    if (cattleId.isEmpty || date.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      if (_editingRecordId == null) {
        // Adding a new record
        await _miscarriageCollection.add({
          'cattleId': cattleId,
          'date': date,
          'notes': notes,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Record saved successfully')),
        );
      } else {
        // Updating an existing record
        await _miscarriageCollection.doc(_editingRecordId).update({
          'cattleId': cattleId,
          'date': date,
          'notes': notes,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Record updated successfully')),
        );
      }

      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save record: $e')),
      );
    }
  }

  void _clearForm() {
    _cattleIdController.clear();
    _dateController.clear();
    _notesController.clear();
  }

  void _confirmDeleteRecord(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteRecord(id);
    }
  }

  void _deleteRecord(String id) async {
    try {
      await _miscarriageCollection.doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Record deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete record: $e')),
      );
    }
  }

  void _showEditForm(String id, Map<String, dynamic> data) {
    setState(() {
      _cattleIdController.text = data['cattleId'] ?? '';
      _dateController.text = data['date'] ?? '';
      _notesController.text = data['notes'] ?? '';
      _editingRecordId = id;
      _isFormVisible = true;
    });
  }
}
