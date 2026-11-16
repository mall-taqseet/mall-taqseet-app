import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data.dart';
import 'home.dart';
import 'auth.dart';
import 'activation_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = await Session.load();
  runApp(MallApp(session: session));
}

class MallApp extends StatefulWidget {
  final Session session;
  const MallApp({super.key, required this.session});
  @override
  State<MallApp> createState() => _MallAppState();
}

class _MallAppState extends State<MallApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مول التقسيط',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBlack,
        colorScheme: const ColorScheme.dark(
          primary: kOrange,
          onPrimary: Colors.black,
          secondary: kOrange,
          surface: kBlack,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kBlack,
          foregroundColor: kOrange,
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kOrange,
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(52),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      home: widget.session.activated
          ? HomeShell(
              session: widget.session,
              onLogout: () => setState(() {}),
            )
          : ActivationPage(
              session: widget.session,
              onActivated: () => setState(() {}),
            ),
    );
  }
}
