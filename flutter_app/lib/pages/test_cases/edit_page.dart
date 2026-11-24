import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/test_case_provider.dart';
import '../../models/test_case.dart';

class TestCaseEditPage extends StatefulWidget {
  final String? id;
  const TestCaseEditPage({Key? key, this.id}) : super(key: key);

  @override
  State<TestCaseEditPage> createState() => _TestCaseEditPageState();
}

class _TestCaseEditPageState extends State<TestCaseEditPage> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  bool _loading = false;
  TestCase? _editing;

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      final provider = Provider.of<TestCaseProvider>(context, listen: false);
      final found = provider.cases.firstWhere((e) => e.id == widget.id, orElse: () => TestCase(id: '', title: '', description: ''));
      if (found.id.isNotEmpty) {
        _editing = found;
        _title.text = found.title;
        _desc.text = found.description;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TestCaseProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.id == null ? 'Create Test Case' : 'Edit Test Case')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(controller: _title, decoration: InputDecoration(labelText: 'Title')),
          SizedBox(height: 8),
          TextField(controller: _desc, decoration: InputDecoration(labelText: 'Description')),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loading
                ? null
                : () async {
                    setState(() => _loading = true);
                    try {
                      if (_editing != null) {
                        _editing!.title = _title.text;
                        _editing!.description = _desc.text;
                        await provider.update(_editing!);
                      } else {
                        final newCase = TestCase(id: DateTime.now().millisecondsSinceEpoch.toString(), title: _title.text, description: _desc.text);
                        await provider.create(newCase);
                      }
                      Navigator.of(context).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    } finally {
                      setState(() => _loading = false);
                    }
                  },
            child: _loading ? CircularProgressIndicator() : Text('Save'),
          )
        ]),
      ),
    );
  }
}
