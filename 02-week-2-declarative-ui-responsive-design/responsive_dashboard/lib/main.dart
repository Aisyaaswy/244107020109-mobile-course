import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

const double kWidthBreakpoint = 700;
void main() => runApp(const DashboardApp());

class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: Colors.indigo),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: DashboardPage(
        isDark: isDark,
        onDarkChanged: (value) => setState(() => isDark = value),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.isDark,
    required this.onDarkChanged,
    super.key,
  });
  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          focusable: true,
          child: const Text('Student Dashboard'),
        ),
        actions:[
          ExcludeSemantics(
            child: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
          ),
          const SizedBox(width: 8),
          CupertinoSwitch(
            value: isDark,
            onChanged: onDarkChanged,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= kWidthBreakpoint ? 2 : 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Semantics(
                  container: true,
                  focusable: true,
                  label: 'Nama Mahasiswa: Aisya Aswy Nur Aidha, NIM: 244107020109',
                  child: const Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(
                        'Aisya Aswy Nur Aidha',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('NIM: 244107020109'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(16),
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.6,
                  children: const [
                    InfoCard(title: 'Assignments', value: '8'),
                    InfoCard(title: 'Attendance', value: '92%'),
                    InfoCard(title: 'Portfolio', value: 'Ready'),
                    InfoCard(title: 'Current week', value: '02'),
                  ],
                ),
              ),
            ],
          );
        },
      ),    
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.title, 
    required this.value, 
    super.key
    });
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      focusable: true,
      label: 'Kategori $title, nilai $value',
      child: Card(  
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
            Expanded(
              child: Text(
                title, 
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
            )),
          ]),
        ),
      ),
    );
  }
}