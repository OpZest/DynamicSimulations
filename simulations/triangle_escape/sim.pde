import java.util.ArrayList;
import processing.sound.*;

ArrayList<Triangle> triangles;
Ball ball;
float initialSize = 1080;
int interval = 50; // Initial interval in frames to add a new triangle
int lastTriangleFrame; // The frame when the last triangle was added
int intervalIncrement = -10; // Decrease in interval for adding new triangles
ArrayList<PVector> starDust = new ArrayList<PVector>();
PImage logo;
SoundFile[] bounceSounds;
String[] bounceSoundFiles;
int soundIndex = 0; // Index to keep track of the current sound in the sequence
int triangleCounter = 0; // Counter to keep track of the number of triangles created

void setup() {
    size(1080, 1920);
    int frameRate = 60; // FPS
    frameRate(frameRate);
    triangles = new ArrayList<Triangle>();
    float centerX = width / 2;
    float centerY = height / 2;
    // Add the first triangle at the beginning
    triangles.add(new Triangle(centerX, centerY, initialSize, triangleCounter++));
    ball = new Ball(centerX, centerY);
    lastTriangleFrame = frameCount;

    // Initialize star dust
    for (int i = 0; i < 100; i++) {
        PVector star = new PVector(random(width), random(height));
        starDust.add(star);
    }

    // Load logo
    logo = loadImage("logo.png");

    // Load sound files
    bounceSounds = new SoundFile[3];
    bounceSoundFiles = new String[]{"te-1.wav", "te-2.wav", "te-3.wav"};
    for (int i = 0; i < bounceSounds.length; i++) {
        bounceSounds[i] = new SoundFile(this, bounceSoundFiles[i]);
    }

    // Initialize rendering
    initializeRendering("render", frameRate, true);
}

void draw() {
    background(13, 15, 30); 
    drawStarDust();
    
    strokeWeight(2);

    for (Triangle t : triangles) {
        if (!t.disappeared) {
            t.display();
        }
    }
    strokeWeight(1);

    for (Triangle t : triangles) {
        t.shrink(); // Shrink the triangle
    }

    for (Triangle t : triangles) {
        if (!t.disappeared) {
            t.checkCollision(ball);
        }
    }

    ball.update();
    ball.display();

    // Check if it's time to add a new triangle
    if (frameCount - lastTriangleFrame >= interval) {
        float centerX = width / 2;
        float centerY = height / 2;
        triangles.add(new Triangle(centerX, centerY, initialSize, triangleCounter++));
        lastTriangleFrame = frameCount;
        interval = max(20, interval + intervalIncrement); // Decrease the interval for the next triangle, with a minimum limit
    }

    float newLogoWidth = logo.width / 3;
    float newLogoHeight = logo.height / 3;
    image(logo, width / 2 - newLogoWidth / 2, height - newLogoHeight - 100, newLogoWidth, newLogoHeight);
    
    renderFrame();
}

void drawStarDust() {
    noStroke();
    fill(255, 255, 255, 90); 
    for (PVector star : starDust) {
        ellipse(star.x, star.y, 3, 3);
    }
}

void playBounceSound() {
    bounceSounds[soundIndex].play();
    logAudioEvent(bounceSoundFiles[soundIndex], frameCount); // Log the bounce sound event
    soundIndex = (soundIndex + 1) % bounceSounds.length; // Move to the next sound in the sequence
}

class Triangle {
    PVector p1, p2, p3;
    float initialSize;
    float size;
    boolean disappeared = false;
    float shrinkFactor = 0.995; // Factor by which to shrink the triangle each frame
    int colorIndex; // Index to determine the color of the triangle

    Triangle(float x, float y, float size, int colorIndex) {
        this.initialSize = size;
        this.size = size;
        this.colorIndex = colorIndex;
        updateVertices(x, y);
    }

    void updateVertices(float x, float y) {
        p1 = new PVector(x, y - size * sqrt(3) / 3);
        p2 = new PVector(x - size / 2, y + size * sqrt(3) / 6);
        p3 = new PVector(x + size / 2, y + size * sqrt(3) / 6);
    }

    void display() {
        noFill();
        switch (colorIndex % 3) {
            case 0: stroke(4, 237, 241); break;
            case 1: stroke(67, 233, 192); break;
            case 2: stroke(130, 228, 142); break;
        }
        beginShape();
        vertex(p1.x, p1.y);
        vertex(p2.x, p2.y);
        vertex(p3.x, p3.y);
        endShape(CLOSE);
    }

    void shrink() {
        size *= shrinkFactor;
        float centerX = (p1.x + p2.x + p3.x) / 3;
        float centerY = (p1.y + p2.y + p3.y) / 3;
        updateVertices(centerX, centerY);
        if (size < 10) { // Disappear when the triangle is too small
            disappeared = true;
        }
    }

    void checkCollision(Ball ball) {
        if (lineIntersectsCircle(p1, p2, ball.position, ball.radius)) {
            ball.bounce(p1, p2);
            disappeared = true;
            playBounceSound();
        } else if (lineIntersectsCircle(p2, p3, ball.position, ball.radius)) {
            ball.bounce(p2, p3);
            disappeared = true;
            playBounceSound();
        } else if (lineIntersectsCircle(p3, p1, ball.position, ball.radius)) {
            ball.bounce(p3, p1);
            disappeared = true;
            playBounceSound();
        }
    }

    boolean lineIntersectsCircle(PVector v1, PVector v2, PVector c, float r) {
        PVector d = v2.copy().sub(v1);
        PVector f = v1.copy().sub(c);
        float a = d.dot(d);
        float b = 2 * f.dot(d);
        float cDist = f.dot(f) - r * r;
        float discriminant = b * b - 4 * a * cDist;
        if (discriminant < 0) {
            return false;
        } else {
            discriminant = sqrt(discriminant);
            float t1 = (-b - discriminant) / (2 * a);
            float t2 = (-b + discriminant) / (2 * a);
            if (t1 >= 0 && t1 <= 1 || t2 >= 0 && t2 <= 1) {
                return true;
            }
        }
        return false;
    }
}

class Ball {
    PVector position;
    PVector velocity;
    float radius = 15;
    float randomFactor = 0.2; // Random factor for adding randomness to the velocity
    float speedIncrement = 1.001; // Small increment factor for speed
    ArrayList<PVector> trail;
    int trailLength = 1 * 60;

    Ball(float x, float y) {
        position = new PVector(x, y);
        velocity = new PVector(-3, 3);
        trail = new ArrayList<PVector>();
    }

    void update() {
        position.add(velocity);
        velocity.mult(speedIncrement); // Gradually increase the speed of the ball
        updateTrail();

        if (position.x < radius || position.x > width - radius) {
            velocity.x *= -1;
        }
        if (position.y < radius || position.y > height - radius) {
            velocity.y *= -1;
        }
    }

    void updateTrail() {
        trail.add(new PVector(position.x, position.y));
        if (trail.size() > trailLength) {
            trail.remove(0);
        }
    }

    void display() {
        fill(255);
        noStroke();
        ellipse(position.x, position.y, radius * 2, radius * 2);
        displayTrail();
    }

    void displayTrail() {
        // Draw a fading comet tail effect
        noFill();
        for (int i = 0; i < trail.size(); i++) {
            float alpha = map(i, 0, trail.size(), 0, 80); // Adjust alpha to fade the tail
            stroke(255, 219, 42, alpha);
            PVector trailPos = trail.get(i);
            ellipse(trailPos.x, trailPos.y, radius, radius);
        }
    }

    void bounce(PVector v1, PVector v2) {
        // Calculate the normal vector to the line
        PVector line = v2.copy().sub(v1);
        PVector normal = new PVector(-line.y, line.x);
        normal.normalize();

        // Reflect the velocity vector
        float dot = velocity.dot(normal);
        PVector reflection = normal.copy().mult(2 * dot);
        velocity.sub(reflection);

        // Add a slight random factor to the velocity
        velocity.x += random(-randomFactor, randomFactor);
        velocity.y += random(-randomFactor, randomFactor);
    }
}
