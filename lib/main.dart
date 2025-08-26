import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/dark_room_game.dart';
import 'game/ui/menu/main_menu_screen.dart';
import 'game/ui/touch_controls.dart';

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
      home: const GameNavigator(),
    );
  }
}

class GameNavigator extends StatefulWidget {
  const GameNavigator({super.key});

  @override
  State<GameNavigator> createState() => _GameNavigatorState();
}

class _GameNavigatorState extends State<GameNavigator> {
  bool _showingMenu = true;
  DarkRoomGame? _game;
  String? _currentLevelId;

  void _onLevelSelected(String levelId) {
    print('🎯 NAVIGATOR: Starting level: $levelId');
    setState(() {
      _currentLevelId = levelId;
      _showingMenu = false;
      _game = DarkRoomGame(onReturnToMenu: _returnToMenu);
    });
  }

  void _returnToMenu() {
    print('🔙 NAVIGATOR: Returning to menu');
    setState(() {
      _showingMenu = true;
      _game = null;
      _currentLevelId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showingMenu) {
      return MainMenuScreen(onLevelSelected: _onLevelSelected);
    } else {
      return GameScreen(
        game: _game!,
        levelId: _currentLevelId!,
        onReturnToMenu: _returnToMenu,
      );
    }
  }
}

class GameScreen extends StatefulWidget {
  final DarkRoomGame game;
  final String levelId;
  final VoidCallback onReturnToMenu;

  const GameScreen({
    super.key,
    required this.game,
    required this.levelId,
    required this.onReturnToMenu,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    _waitForGameAndLoadLevel();
  }

  void _waitForGameAndLoadLevel() {
    // Check if game is ready, if not, wait and retry
    if (widget.game.isInitialized) {
      _loadSelectedLevel();
    } else {
      print('⏳ SCREEN: Waiting for game initialization...');
      // Wait for next frame and check again
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _waitForGameAndLoadLevel();
        }
      });
    }
  }

  void _loadSelectedLevel() {
    print('🎯 SCREEN: Game ready, loading level ${widget.levelId}');
    widget.game.loadLevelById(widget.levelId);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => widget.onReturnToMenu(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            GameWidget(game: widget.game),
            Positioned(
              top: 40,
              left: 16,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: widget.onReturnToMenu,
                    tooltip: 'Return to Menu',
                  ),
                ),
              ),
            ),
            // Touch controls overlay for mobile/tablet
            TouchControls(game: widget.game),
          ],
        ),
      ),
    );
  }
}