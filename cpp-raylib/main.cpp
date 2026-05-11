#include <cassert>
#include <cmath>
#include <cstdlib>
#include <raylib.h>
#include <vector>

const Color circleColor = BLUE;
const Color planetColor = RED;
const float radius = 20.0f;
const float p_rad = 5.0f;
const int width = 1000;
const int height = 600;

typedef struct {
  Vector2 pos;
  float gravity_const;
  float range;
} Planet;

void onClick(std::vector<Vector2> *circles, std::vector<Vector2> *velocities) {
  if (IsMouseButtonPressed(MOUSE_LEFT_BUTTON)) {
    Vector2 mousePos = GetMousePosition();
    circles->push_back({mousePos.x, mousePos.y});
    velocities->push_back(
        {(std::rand() % 100) / 100.0f, (std::rand() % 100) / 100.0f});
  }
}

void drawCircles(const std::vector<Vector2> &circles, Color color) {
  for (const Vector2 &circle : circles) {
    DrawCircleV(circle, radius, color);
  }
}

void drawPlanet(const std::vector<Planet> &planets, Color color) {
  for (const Planet &p : planets) {
    DrawCircleV(p.pos, p_rad, color);
  }
}

bool inRange(Vector2 x, Vector2 y, float rad_x, float rad_y) {
  return pow(rad_x + rad_y, 2) > pow(x.x - y.x, 2) + pow(x.y - y.y, 2);
}

void applyGravity(std::vector<Vector2> &circles,
                  std::vector<Vector2> &velocities,
                  std::vector<Planet> planets) {
  for (size_t i = 0; i < circles.size(); i++) {
    const Vector2 c = circles[i];
    Vector2 &v = velocities[i];
    for (size_t j = 0; j < planets.size(); j++) {
      const Planet p = planets[j];
      if (inRange(c, p.pos, radius, p.range)) {
        const auto dx = p.pos.x - c.x;
        const auto dy = p.pos.y - c.y;
        const auto strength = abs(p.range - sqrt(pow(dx, 2) + pow(dy, 2)));
        v.x += strength * p.gravity_const / 1000 * dx;
        v.y += strength * p.gravity_const / 1000 * dy;
      }
    }
  }
}

void detectCollision(std::vector<Vector2> &circles,
                     std::vector<Vector2> &velocities) {
  for (size_t i = 0; i < circles.size(); i++) {
    Vector2 &circle = circles[i];
    Vector2 &velocity = velocities[i];

    for (size_t j = i + 1; j < circles.size(); j++) {
      Vector2 &other_circle = circles[j];
      Vector2 &other_velocity = velocities[j];

      const float dx = other_circle.x - circle.x;
      const float dy = other_circle.y - circle.y;
      const float d = dx * dx + dy * dy;
      const float minDist = radius * 2.0f;

      if (d < minDist * minDist) {
        const float length = std::sqrt(d);
        const Vector2 normal_n = (length > 0.0f)
                                     ? Vector2{dx / length, dy / length}
                                     : Vector2{1.0f, 0.0f};

        const Vector2 rv = {other_velocity.x - velocity.x,
                            other_velocity.y - velocity.y};
        const float velAlongNormal = rv.x * normal_n.x + rv.y * normal_n.y;

        if (velAlongNormal > 0.0f) {
          continue;
        }

        const float restitution = 1.0f;
        const float impulseMagnitude =
            -(1.0f + restitution) * velAlongNormal / 2.0f;
        const Vector2 impulse = {impulseMagnitude * normal_n.x,
                                 impulseMagnitude * normal_n.y};

        velocity = {velocity.x - impulse.x, velocity.y - impulse.y};
        other_velocity = {other_velocity.x + impulse.x,
                          other_velocity.y + impulse.y};
      }
    }

    if (circle.x >= (width - radius)) {
      velocity.x = velocity.x > 0 ? -velocity.x : velocity.x;
    }

    if (circle.x <= radius) {
      velocity.x = velocity.x < 0 ? -velocity.x : velocity.x;
    }

    if (circle.y >= (height - radius)) {
      velocity.y = velocity.y > 0 ? -velocity.y : velocity.y;
    }

    if (circle.y <= radius) {
      velocity.y = velocity.y < 0 ? -velocity.y : velocity.y;
    }
  }
}

void addRandomPlanets(std::vector<Planet> &planets) {
  const auto number = 3 + (std::rand() % 5);
  for (int i = 0; i < number; i++) {
    const Planet p = {{(float)(std::rand() % (height - 100)),
                       (float)(std::rand() % (height - 100))},
                      std::rand() % 90 / 100.0f,
                      50.0f + std::rand() % 100};
    planets.push_back(p);
  }
}

void friction(std::vector<Vector2> &velocities) {
  for (size_t i = 0; i < velocities.size(); i++) {
    Vector2 &v = velocities[i];
    v.x *= 0.999f;
    v.y *= 0.999f;
  }
}

void applyVelocity(std::vector<Vector2> &circles,
                   const std::vector<Vector2> &velocities) {
  for (size_t i = 0; i < circles.size(); i++) {
    const Vector2 v = velocities[i];
    Vector2 &c = circles[i];
    c.x = c.x + v.x;
    c.y = c.y + v.y;
  }
}

void drawConnected(const std::vector<Vector2> &circles) {
  for (size_t i = 0; i < circles.size(); i++) {
    for (size_t j = i; j < circles.size(); j++) {
      DrawLineV(circles[i], circles[j], BLUE);
    }
  }
}

int main() {
  InitWindow(width, height, "Hello world");
  SetTargetFPS(60);

  std::vector<Vector2> circles;
  std::vector<Vector2> velocities;
  std::vector<Planet> planets;
  addRandomPlanets(planets);

  while (!WindowShouldClose()) {
    onClick(&circles, &velocities);
    friction(velocities);
    applyGravity(circles, velocities, planets);
    detectCollision(circles, velocities);
    applyVelocity(circles, velocities);
    BeginDrawing();
    ClearBackground(RAYWHITE);
    drawCircles(circles, circleColor);
    drawPlanet(planets, planetColor);
    drawConnected(circles);
    EndDrawing();
  }

  CloseWindow();
  return 0;
}
