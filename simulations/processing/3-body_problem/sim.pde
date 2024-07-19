import java.util.ArrayList;

ArrayList<PVector> starDust = new ArrayList<PVector>();
float G = 20; // Gravitational constant
Ball ball1, ball2, ball3;
PVector cameraPos;

void setup() {
    size(1080, 1920);
    float scaleFactor = 1.5;
    int frameRate = 60; // FPS
    frameRate(frameRate);
    for (int i = 0; i < 100; i++) { 
        PVector star = new PVector(random(width / scaleFactor), random(height / scaleFactor));
        starDust.add(star);
    }
    float sideLength = 320; // Length of the side of the equilateral triangle
    float heightOffset = sqrt(3) / 2 * sideLength; // Height of the equilateral triangle
    ball1 = new Ball(width / (2 * scaleFactor), height / (2 * scaleFactor) - heightOffset / 3, 20, color(255, 219, 42), 1);
    ball2 = new Ball(width / (2 * scaleFactor) - sideLength / 2, height / (2 * scaleFactor) + heightOffset / 3, 20, color(4, 237, 241), 1);
    ball3 = new Ball(width / (2 * scaleFactor) + sideLength / 2, height / (2 * scaleFactor) + heightOffset / 3, 20, lerpColor(color(255, 219, 42), color(4, 237, 241), 0.5), 1);
    // Calculate the center of mass
    PVector centerOfMass = new PVector((ball1.pos.x + ball2.pos.x + ball3.pos.x) / 3, (ball1.pos.y + ball2.pos.y + ball3.pos.y) / 3);
    // Set initial velocities tangentially around the center of mass
    float initialSpeed = 5;
    ball1.speed = new PVector(-(ball1.pos.y - centerOfMass.y), ball1.pos.x - centerOfMass.x).normalize().mult(initialSpeed);
    ball2.speed = new PVector(-(ball2.pos.y - centerOfMass.y), ball2.pos.x - centerOfMass.x).normalize().mult(initialSpeed);
    ball3.speed = new PVector(-(ball3.pos.y - centerOfMass.y), ball3.pos.x - centerOfMass.x).normalize().mult(initialSpeed);
    // Initialize camera position
    cameraPos = centerOfMass.copy();
    
    // Initialize rendering
    initializeRendering("render", frameRate, true);
}

void draw() {
    background(13, 15, 30);
    scale(1.5);
    drawStarDust();
    // Update balls
    ball1.update(ball2, ball3);
    ball2.update(ball1, ball3);
    ball3.update(ball1, ball2);
    // Calculate the center of mass
    PVector centerOfMass = new PVector((ball1.pos.x + ball2.pos.x + ball3.pos.x) / 3, (ball1.pos.y + ball2.pos.y + ball3.pos.y) / 3);
    // Smoothly move the camera towards the center of mass
    cameraPos.lerp(centerOfMass, 0.1);
    // Translate the view to keep the center of mass in the center of the screen
    translate(width / 2 / 1.5 - cameraPos.x, height / 2 / 1.5 - cameraPos.y);
    // Display balls
    ball1.display();
    ball2.display();
    ball3.display();
    // Reset translation to draw mass info in fixed position
    resetMatrix();
    displayMassInfo();
    
    renderFrame();
}

void drawStarDust() {
    noStroke();
    fill(255, 255, 255, 90);
    for (PVector star : starDust) {
        ellipse(star.x, star.y, 2, 2);
    }
}

void displayMassInfo() {
    float circleDiameter = 60;
    float textOffset = 50;
    float yOffset = height / 1.5 + 260;
    float xOffset = 260;

    // Display outline for ball1
    noFill();
    stroke(ball1.trailColor);
    strokeWeight(2);
    ellipse(xOffset, yOffset, circleDiameter, circleDiameter);
    fill(255);
    textSize(36);
    text(" = " + ball1.mass, xOffset + textOffset, yOffset + 8);

    // Display outline for ball2
    noFill();
    stroke(ball2.trailColor);
    ellipse(xOffset + width / 3 / 1.5, yOffset, circleDiameter, circleDiameter);
    fill(255);
    text(" = " + ball2.mass, xOffset + width / 3 / 1.5 + textOffset, yOffset + 8);

    // Display outline for ball3
    noFill();
    stroke(ball3.trailColor);
    ellipse(xOffset + 2 * width / 3 / 1.5, yOffset, circleDiameter, circleDiameter);
    fill(255);
    text(" = " + ball3.mass, xOffset + 2 * width / 3 / 1.5 + textOffset, yOffset + 8);
}

class Ball {
    PVector pos;
    PVector speed;
    float radius;
    int trailColor;
    float mass;
    ArrayList<PVector> trail;
    int trailLength;

    Ball(float x, float y, float r, int c, float m) {
        pos = new PVector(x, y);
        speed = new PVector(0, 0);
        radius = r;
        trailColor = c;
        mass = m;
        trail = new ArrayList<PVector>();
        trailLength = 7 * 60; // X seconds worth of frames at 60 FPS
    }

    void update(Ball other1, Ball other2) {
        PVector force1 = calculateGravitationalForce(other1);
        PVector force2 = calculateGravitationalForce(other2);
        PVector totalForce = PVector.add(force1, force2);
        PVector acceleration = PVector.div(totalForce, mass);
        speed.add(acceleration);
        pos.add(speed);
        updateTrail();
    }

    PVector calculateGravitationalForce(Ball other) {
        PVector direction = PVector.sub(other.pos, this.pos);
        float distance = direction.mag();
        distance = constrain(distance, 5, 25); // Avoid extreme forces at very close distances
        direction.normalize();
        float forceMagnitude = (G * this.mass * other.mass) / (distance * distance);
        direction.mult(forceMagnitude);
        return direction;
    }

    void updateTrail() {
        trail.add(new PVector(pos.x, pos.y));
        if (trail.size() > trailLength) {
            trail.remove(0);
        }
    }

    void display() {
        fill(trailColor);
        noStroke();
        ellipse(pos.x, pos.y, radius * 2, radius * 2);
        displayTrail();
        displayGlow();
    }

    void displayTrail() {
        // Draw a fading comet tail effect
        noFill();
        for (int i = 0; i < trail.size(); i++) {
            float alpha = map(i, 0, trail.size(), 0, 80);
            stroke(trailColor, alpha);
            PVector trailPos = trail.get(i);
            ellipse(trailPos.x, trailPos.y, radius, radius);
        }
    }

    void displayGlow() {
        for (int i = 0; i < 10; i++) {
            float alpha = map(i, 0, 10, 50, 0);
            fill(255, 255, 255, alpha);
            ellipse(pos.x, pos.y, radius * 2 + i * 4, radius * 2 + i * 4);
        }
    }
}
