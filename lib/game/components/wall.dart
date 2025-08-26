import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

class Wall extends PositionComponent with CollisionCallbacks {
  Wall({
    required Vector2 position,
    required Vector2 size,
  }) : super(
    position: position,
    size: size,
  );
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Add rectangular hitbox for collision
    add(RectangleHitbox(
      size: size,
    ));
  }
  
  @override
  void render(Canvas canvas) {
    // Walls are invisible in normal gameplay
    // Debug mode will handle visualization
  }
}