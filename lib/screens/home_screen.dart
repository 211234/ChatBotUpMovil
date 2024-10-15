import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chatbot_screen.dart'; // Importa la vista del chatbot

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Repositorio'),
              onTap: () async {
                const url =
                    'https://github.com/211234/ChatBotUpMovil'; // Reemplaza con el enlace de tu repositorio
                if (await canLaunch(url)) {
                  await launch(url);
                } else {
                  throw 'No se pudo abrir $url';
                }
              },
            ),
            ListTile(
              title: const Text('ChatBot'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ChatBotScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Center( // Usamos el widget Center para centrar el contenido
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centrar verticalmente
            crossAxisAlignment: CrossAxisAlignment.center, // Centrar horizontalmente
            children: [
              Image.asset(
                'assets/LogoUp.jpeg', // Asegúrate de agregar el logo en assets
                height: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                'Universidad: UP Chiapas',
                style: TextStyle(fontSize: 18),
              ),
              const Text(
                'Carrera: Ingeniería en Software',
                style: TextStyle(fontSize: 18),
              ),
              const Text(
                'Materia: Programación para Móviles II',
                style: TextStyle(fontSize: 18),
              ),
              const Text(
                'Grupo: A',
                style: TextStyle(fontSize: 18),
              ),
              const Text(
                'Alumno: César Josué Martínez Castillejos',
                style: TextStyle(fontSize: 18),
              ),
              const Text(
                'Matrícula: 211234',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
