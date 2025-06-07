import 'package:flutter/material.dart';

class FeedbackModel {
  String message;
  int rating;
  FeedbackModel({required this.message, required this.rating});
}

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  int _rating = 0;
  int? _editIndex;
  List<FeedbackModel> _feedbackList = [];

  void _saveFeedback() {
    if (!_formKey.currentState!.validate()) return;
    if (_editIndex == null) {
      setState(() {
        _feedbackList.add(FeedbackModel(message: _messageController.text, rating: _rating));
      });
    } else {
      setState(() {
        _feedbackList[_editIndex!] = FeedbackModel(message: _messageController.text, rating: _rating);
        _editIndex = null;
      });
    }
    _messageController.clear();
    setState(() => _rating = 0);
  }

  void _editFeedback(int index) {
    setState(() {
      _editIndex = index;
      _messageController.text = _feedbackList[index].message;
      _rating = _feedbackList[index].rating;
    });
  }

  void _deleteFeedback(int index) {
    setState(() {
      _feedbackList.removeAt(index);
      if (_editIndex == index) {
        _editIndex = null;
        _messageController.clear();
        _rating = 0;
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Widget _buildRatingBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
          onPressed: () => setState(() => _rating = index + 1),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Kesan & Pesan'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _messageController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Kesan & Pesan',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.green.withOpacity(0.05),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Pesan tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildRatingBar(),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _saveFeedback,
                          child: Text(_editIndex == null ? 'Simpan' : 'Update'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _feedbackList.isEmpty
                  ? const Center(child: Text('Belum ada kesan & pesan'))
                  : ListView.builder(
                      itemCount: _feedbackList.length,
                      itemBuilder: (context, i) {
                        final fb = _feedbackList[i];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(fb.message),
                            subtitle: Row(
                              children: List.generate(5, (idx) => Icon(
                                idx < fb.rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 20,
                              )),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editFeedback(i),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteFeedback(i),
                                ),
                              ],
                            ),
                          ),
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
