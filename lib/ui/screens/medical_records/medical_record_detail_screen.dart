import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MedicalRecordDetailScreen extends StatefulWidget {
  final String id;

  const MedicalRecordDetailScreen({
    Key? key,
    required this.id,
  }) : super(key: key);

  @override
  State<MedicalRecordDetailScreen> createState() => _MedicalRecordDetailScreenState();
}

class _MedicalRecordDetailScreenState extends State<MedicalRecordDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _recordData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMedicalRecord();
  }

  Future<void> _loadMedicalRecord() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final doc = await FirebaseFirestore.instance
          .collection('medical_records')
          .doc(widget.id)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'Medical record not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _recordData = doc.data();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load medical record: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Record Details'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMedicalRecord,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_recordData == null) {
      return const Center(child: Text('No data available'));
    }

    final date = _recordData!['date'] != null 
        ? DateFormat('MMMM dd, yyyy').format((_recordData!['date'] as Timestamp).toDate())
        : 'Unknown date';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Record Type and Date
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _recordData!['type'] ?? 'Medical Record',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('Date: $date'),
                  if (_recordData!['doctorName'] != null)
                    Text('Doctor: ${_recordData!['doctorName']}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Diagnosis
          if (_recordData!['diagnosis'] != null) ...[
            _buildSectionHeader('Diagnosis'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_recordData!['diagnosis']),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Medication
          if (_recordData!['medication'] != null) ...[
            _buildSectionHeader('Medication'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _recordData!['medicationName'] ?? 'Prescribed Medication',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_recordData!['medication']),
                    if (_recordData!['dosage'] != null) ...[
                      const SizedBox(height: 8),
                      Text('Dosage: ${_recordData!['dosage']}'),
                    ],
                    if (_recordData!['frequency'] != null) ...[
                      const SizedBox(height: 4),
                      Text('Frequency: ${_recordData!['frequency']}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Notes
          if (_recordData!['notes'] != null) ...[
            _buildSectionHeader('Notes'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_recordData!['notes']),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}