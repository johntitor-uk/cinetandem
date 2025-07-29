import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:email_validator/email_validator.dart';
import 'package:image_picker/image_picker.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final Function(String) onAddNotification;
  final Function(String) onAchievementCompleted;

  const ProfileSettingsScreen({
    super.key,
    required this.onAddNotification,
    required this.onAchievementCompleted,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedCountry;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _enableNotifications = true;
  File? _selectedImage;

  // Lista de países
  final List<String> _countries = [
    'Argentina',
    'Brasil',
    'Chile',
    'Colombia',
    'España',
    'México',
    'Perú',
    'Estados Unidos',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nicknameController.text = prefs.getString('nickname') ?? 'CineLover123';
      _fullNameController.text = prefs.getString('fullName') ?? 'Juan Pérez';
      _emailController.text = prefs.getString('email') ?? '';
      _selectedCountry = prefs.getString('country') ?? _countries[0];
      _enableNotifications = prefs.getBool('enableNotifications') ?? true;
    });
  }

  Future<void> _saveUserData() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nickname', _nicknameController.text.trim());
      await prefs.setString('fullName', _fullNameController.text.trim());
      await prefs.setString('email', _emailController.text.trim());
      if (_passwordController.text.isNotEmpty) {
        await prefs.setString('password', _passwordController.text);
      }
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        final base64Image = base64Encode(bytes);
        await prefs.setString('photoUrl', 'data:image/png;base64,$base64Image');
      } else {
        await prefs.setString('photoUrl', 'https://via.placeholder.com/150');
      }
      await prefs.setString('country', _selectedCountry!);
      await prefs.setBool('enableNotifications', _enableNotifications);
      widget.onAddNotification('Perfil actualizado con éxito');
      widget.onAchievementCompleted('Personalizar perfil');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado con éxito')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  ImageProvider<Object>? _getProfileImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    }
    return const NetworkImage('https://via.placeholder.com/150');
  }

  void _showProfilePreview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 10, 10, 31),
        title: const Text(
          'Vista previa del perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              backgroundImage: _getProfileImage(),
            ),
            const SizedBox(height: 16),
            Text(
              _nicknameController.text.isEmpty ? 'CineLover123' : _nicknameController.text,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              _fullNameController.text.isEmpty ? 'Juan Pérez' : _fullNameController.text,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              _emailController.text.isEmpty ? 'Sin correo' : _emailController.text,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              _selectedCountry ?? _countries[0],
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: Colors.deepOrangeAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 10, 31),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 10, 10, 31),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Configuración del Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto de perfil
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey,
                  backgroundImage: _getProfileImage(),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _pickImage,
                  child: const Text(
                    'Seleccionar foto desde galería',
                    style: TextStyle(color: Colors.deepOrangeAccent),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Campo para el nickname
              TextFormField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: 'Nickname',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, ingresa un nickname';
                  }
                  if (value.trim().length < 3) {
                    return 'El nickname debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Campo para el nombre completo
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre completo',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, ingresa un nombre completo';
                  }
                  if (value.trim().length < 2) {
                    return 'El nombre debe tener al menos 2 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Campo para el correo electrónico
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, ingresa un correo electrónico';
                  }
                  if (!EmailValidator.validate(value.trim())) {
                    return 'Por favor, ingresa un correo electrónico válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Campo para la contraseña
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña (opcional)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    },
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                obscureText: !_isPasswordVisible,
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Campo para confirmar contraseña
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirmar nueva contraseña',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                    },
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                obscureText: !_isConfirmPasswordVisible,
                validator: (value) {
                  if (_passwordController.text.isNotEmpty) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, confirma la contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Dropdown para seleccionar país
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: InputDecoration(
                  labelText: 'País',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                dropdownColor: const Color.fromARGB(255, 10, 10, 31),
                items: _countries.map((country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCountry = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor, selecciona un país';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Switch para notificaciones
              SwitchListTile(
                title: const Text(
                  'Habilitar notificaciones',
                  style: TextStyle(color: Colors.white),
                ),
                value: _enableNotifications,
                onChanged: (value) {
                  setState(() => _enableNotifications = value);
                },
                activeColor: Colors.deepOrangeAccent,
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.white24,
              ),
              const SizedBox(height: 24),
              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _showProfilePreview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Vista previa',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _saveUserData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrangeAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Guardar cambios',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}