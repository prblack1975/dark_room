import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/dark_room_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DarkRoomApp());
}

class DarkRoomApp extends StatelessWidget {
  const DarkRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dark Room',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final DarkRoomGame game;

  @override
  void initState() {
    super.initState();
    game = DarkRoomGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GameWidget(game: game),
    );
  }
}