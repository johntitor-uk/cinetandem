import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import 'home_page.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 10, 10, 31),
              Color.fromARGB(255, 26, 26, 64),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 40),
            const Icon(
              Icons.people_alt_rounded,
              size: 100,
              color: Colors.deepOrangeAccent,
            ),
            const SizedBox(height: 24),
            Text(
              'CineTandem',
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Mira películas en sincronía con desconocidos de todo el mundo.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: '¡Ver una película con alguien!',
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const HomePage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Iniciar sesión no implementado.')),
                );
              },
              child: const Text(
                'Iniciar sesión',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialButton(
                  icon: Icons.g_mobiledata,
                  iconColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inicio de sesión con Google no implementado.')),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _SocialButton(
                  icon: Icons.facebook,
                  iconColor: Colors.blue[700]!,
                  backgroundColor: Colors.blue[700]!.withOpacity(0.2),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inicio de sesión con Facebook no implementado.')),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _SocialButton(
                  icon: Icons.alternate_email,
                  iconColor: Colors.lightBlue,
                  backgroundColor: Colors.lightBlue.withOpacity(0.1),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inicio de sesión con Twitter no implementado.')),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _SocialButton(
                  icon: Icons.apple,
                  iconColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.2),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inicio de sesión con Apple no implementado.')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Creada por DigitalSant technology',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: CircleAvatar(
        backgroundColor: backgroundColor,
        child: Icon(icon, color: iconColor, size: 24),
      ),
      onPressed: onPressed,
    );
  }
}