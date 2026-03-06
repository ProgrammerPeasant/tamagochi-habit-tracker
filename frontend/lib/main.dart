import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Здесь будут импорты ваших провайдеров

void main() {
  runApp(const HabitPetApp());
}

class HabitPetApp extends StatelessWidget {
  const HabitPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Сюда добавите провайдеры (HabitProvider, PetProvider)
      ],
      child: MaterialApp(
        title: 'Habit Pet',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
          useMaterial3: true,
        ),
        home: const HomeScreen(), // Заглушка, потом замените на роутинг
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Тамагочи Привычек')),
      body: const Center(child: Text('Питомец будет здесь')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Навигация к добавлению привычки
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}