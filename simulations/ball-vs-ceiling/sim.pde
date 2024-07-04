import java.io.*;
import java.util.ArrayList;
import processing.sound.*;


ArrayList<PVector[]> particles = new ArrayList<PVector[]>();
ArrayList<PVector> starDust = new ArrayList<PVector>();
float elasticity = 0.9;
float floorY;
float ceilingY;
PImage logo;
Ball ball;
int bounceCount = 0;
SoundFile[] bounceSounds;
String[] bounceSoundFiles;
int soundIndex = 0; // Index to keep track of the current sound in the sequence

void setup() {
    size(1080, 1920);
    float widthScale = 1080.0 / 720.0;
    float heightScale = 1920.0 / 1280.0;
    int frameRate = 60;
    frameRate(frameRate);
    floorY = height - 350 * heightScale;
    ceilingY = 50 * heightScale; // Initial position of the ceiling
    ball = new Ball(width / 2, height / 4, 40 * widthScale, color(255, 255, 255), color(255, 219, 42), 1);
    logo = loadImage("logo.png");
    for (int i = 0; i < 100; i++) {
        PVector star = new PVector(random(width), random(height));
        starDust.add(star);
    }
    // Load sound files
    bounceSounds = new SoundFile[9];
    bounceSoundFiles = new String[]{"ls-E.wav", "ls-D-sharp.wav", "ls-E.wav", "ls-D-sharp.wav", "ls-E.wav", "ls-B.wav", "ls-D.wav", "ls-C.wav", "ls-A.wav"};
    for (int i = 0; i < bounceSounds.length; i++) {
        bounceSounds[i] = new SoundFile(this, bounceSoundFiles[i]);
    }

    // Initialize rendering
    initializeRendering("render", frameRate, true);
}

void draw() {
    background(13, 15, 30);
    drawStarDust();
    ball.update();
    ball.display();
    drawParticles();
    stroke(255);
    line(0, floorY, width, floorY);
    line(0, ceilingY, width, ceilingY);
    line(0, 0, 0, height);
    line(width, 0, width, height);
    float newLogoWidth = logo.width / 5 * (1080.0 / 720.0);
    float newLogoHeight = logo.height / 5 * (1920.0 / 1280.0);
    image(logo, width/2 - newLogoWidth/2, floorY + 50 * (1920.0 / 1280.0), newLogoWidth, newLogoHeight);
    // Set a constant speed for the ceiling's movement
    float ceilingMoveSpeed = 1.5;
    ceilingY = min(ceilingY + ceilingMoveSpeed, floorY - 2 * ball.radius - 0.4 * (1920.0 / 1280.0)); // Ensure ceiling does not go lower than the target
    // Display the bounce count
    fill(255);
    textSize(32 * (1920.0 / 1280.0));
    text("Bounces: " + bounceCount, (width / 2) - 130, 130 * (1920.0 / 1280.0));

    // Render frame
    renderFrame();
}

void createParticles(float x, float y) {
    for (int i = 0; i < 20; i++) {
        PVector particle = new PVector(x, y);
        PVector velocity = new PVector(random(-2, 2), random(-2, 0));
        particles.add(new PVector[]{particle, velocity});
    }
}

void drawStarDust() {
    noStroke();
    fill(255, 255, 255, 90);
    for (PVector star : starDust) {
        ellipse(star.x, star.y, 2 * (1080.0 / 720.0), 2 * (1920.0 / 1280.0));
    }
}

void drawParticles() {
    noStroke();
    fill(255, 100);
    for (int i = particles.size() - 1; i >= 0; i--) {
        PVector[] particle = particles.get(i);
        particle[0].add(particle[1]);
        ellipse(particle[0].x, particle[0].y, 4 * (1080.0 / 720.0), 4 * (1920.0 / 1280.0));
        if (particle[0].y > floorY || particle[0].x < 0 || particle[0].x > width) {
            particles.remove(i);
        }
    }
}

void playBounceSound() {
    bounceSounds[soundIndex].play();
    logAudioEvent(bounceSoundFiles[soundIndex], frameCount); // Log the bounce sound event
    soundIndex = (soundIndex + 1) % bounceSounds.length; // Move to the next sound in the sequence
}

class Ball {
    PVector pos;
    PVector speed;
    float radius;
    int ballColor;
    int trailColor;
    ArrayList<PVector> trail = new ArrayList<PVector>();
    float glowIntensity = 25;
    float currentGlowIntensity; 
    float mass;
    float baseGlowSize;
    float currentGlowSize;
    boolean isGlowEnabled = true;
    float trailOpacity = 75;
    int[] trailColors = {color(4, 237, 241), color(130, 228, 142), color(255, 219, 42)};
    int currentTrailColorIndex = 0;

    Ball(float x, float y, float r, int c, int tColor, float m) {
        pos = new PVector(x, y);
        speed = new PVector(5 * (1080.0 / 720.0), 5 * (1920.0 / 1280.0));
        radius = r;
        ballColor = color(255, 255, 255);
        trailColor = color(255, 219, 42);
        mass = m;
        baseGlowSize = radius * 3.5f; 
        currentGlowSize = baseGlowSize;
        currentGlowIntensity = glowIntensity; 
    }

    void update() {
        pos.add(speed);
        if (trail.size() > 800) {
            trail.remove(0);
        }
        trail.add(pos.copy());
        // Bounce off the floor
        if (pos.y >= floorY - radius) {
            pos.y = floorY - radius;
            speed.y = -speed.y * elasticity;
            currentGlowSize = baseGlowSize * 1.2f; // Increase glow size upon impact
            currentGlowIntensity = 130; // Increase glow intensity upon impact
            createParticles(pos.x, pos.y + radius);
            changeTrailColor();
            bounceCount++;
            playBounceSound(); 
        }
        // Bounce off the ceiling
        if (pos.y <= ceilingY + radius) {
            pos.y = ceilingY + radius;
            speed.y = -speed.y * elasticity;
            currentGlowSize = baseGlowSize * 1.2f; // Increase glow size upon impact
            currentGlowIntensity = 130; // Increase glow intensity upon impact
            createParticles(pos.x, pos.y - radius);
            changeTrailColor();
            bounceCount++;
            playBounceSound();
        }
        // Bounce off the left wall
        if (pos.x <= radius) {
            pos.x = radius;
            speed.x = -speed.x * elasticity;
            currentGlowSize = baseGlowSize * 1.2f; // Increase glow size upon impact
            currentGlowIntensity = 130; // Increase glow intensity upon impact
            createParticles(pos.x - radius, pos.y);
            changeTrailColor();
            bounceCount++; 
            playBounceSound();
        }
        // Bounce off the right wall
        if (pos.x >= width - radius) {
            pos.x = width - radius;
            speed.x = -speed.x * elasticity;
            currentGlowSize = baseGlowSize * 1.2f; // Increase glow size upon impact
            currentGlowIntensity = 130; // Increase glow intensity upon impact
            createParticles(pos.x + radius, pos.y);
            changeTrailColor();
            bounceCount++; 
            playBounceSound();
        }
        // Gradually decrease the glow size and intensity
        currentGlowSize = max(baseGlowSize, currentGlowSize - 0.2f * (1920.0 / 1280.0));
        currentGlowIntensity = max(glowIntensity, currentGlowIntensity - 1);
    }

    void changeTrailColor() {
        currentTrailColorIndex = (currentTrailColorIndex + 1) % trailColors.length;
        trailColor = trailColors[currentTrailColorIndex];
    }

    void display() {
        if (isGlowEnabled) {
            // Draw the glow
            noStroke();
            fill(255, 255, 255, currentGlowIntensity); 
            blendMode(ADD);
            ellipse(pos.x, pos.y, currentGlowSize, currentGlowSize);
        }
        // Draw the trail
        blendMode(BLEND); // Switch back to normal blending mode for other elements
        for (PVector p : trail) {
            stroke(trailColor, trailOpacity); // Use the original trail color with its glow intensity
            noFill(); // Or no fill for just the stroke
            ellipse(p.x, p.y, radius * 2, radius * 2);
        }
        // Then, draw the ball on top of its glow
        fill(color(255, 255, 255));
        noStroke();
        ellipse(pos.x, pos.y, radius * 2, radius * 2);
        blendMode(BLEND); // Reset blending mode to default for other elements
    }
}
