import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/test_case_provider.dart';
import '../../models/test_case.dart';
import '../../router.dart';

class TestCaseListPage extends StatefulWidget {
  const TestCaseListPage({Key? key}) : super(key: key);

  @override
  State<TestCaseListPage> createState() => _TestCaseListPageState();
}

class _TestCaseListPageState extends State<TestCaseListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TestCaseProvider>(context, listen: false).fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TestCaseProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Test Cases')),
      body: provider.loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.cases.length,
              itemBuilder: (context, i) {
                final tc = provider.cases[i];
                return ListTile(
                  title: Text(tc.title),
                  subtitle: Text(tc.description),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => context.goNamed('test_case_edit', pathParameters: {'id': tc.id})),
                    IconButton(icon: Icon(Icons.delete), onPressed: () => provider.delete(tc.id)),
                  ]),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.goNamed('test_case_create'),
        child: Icon(Icons.add),
      ),
    );
  }
}
