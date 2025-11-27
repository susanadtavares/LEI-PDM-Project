import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final Widget? customDrawer;
  final Color appBarColor;
  final String? customLogo;

  const AppScaffold({
    required this.title,
    required this.body,
    this.appBar,
    this.backgroundColor,
    this.customDrawer,
    this.appBarColor = Colors.white,
    this.customLogo,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLightAppBar =
        appBarColor == Colors.white || appBarColor == const Color(0xFFFFFFFF);
    final Color iconColor = isLightAppBar ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor ?? const Color(0xFFF8F5FB),
      appBar: appBar ??
          AppBar(
            backgroundColor: appBarColor,
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
                color: iconColor,
              ),
            ),
            centerTitle: true,
            title: GestureDetector(
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/principal',
                  (route) => false,
                );
              },
              child: Image.asset(
                customLogo ?? 'assets/images/logosoftinsa.png',
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  Navigator.pushNamed(context, '/notificacoes');
                },
                color: iconColor,
              ),
            ],
          ),
      drawer: customDrawer ?? _defaultDrawer(context),
      body: body,
    );
  }

  Widget _defaultDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 40),
        children: [
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            leading: const Icon(Icons.home),
            title: const Text('Página Principal'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/principal');
            },
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Todos os Cursos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/todosCursos');
            },
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            leading: const Icon(Icons.book),
            title: const Text('Os Meus Cursos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/os-meus-cursos');
            },
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            leading: const Icon(Icons.forum_outlined),
            title: const Text('Fórum'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/forum');
            },
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            leading: const Icon(Icons.person_outline),
            title: const Text('Perfil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/perfil');
            },
          ),
          const Divider(height: 1),
          ListTile(

            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
          const Divider(height: 1),
          
         
        ],
      ),
    );
  }
}
