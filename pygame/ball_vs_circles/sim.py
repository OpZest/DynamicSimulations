import pygame
import sys
import math
import random
from render import VideoRenderer

# Initialize Pygame and Pygame mixer
pygame.init()
pygame.mixer.init()

# Set up the display
DISPLAY_WIDTH, DISPLAY_HEIGHT = 1080, 1920
RENDER_SCALE = 2
WIDTH, HEIGHT = DISPLAY_WIDTH * RENDER_SCALE, DISPLAY_HEIGHT * RENDER_SCALE
screen = pygame.display.set_mode((DISPLAY_WIDTH, DISPLAY_HEIGHT))
render_surface = pygame.Surface((WIDTH, HEIGHT))
pygame.display.set_caption("Concentric Circles with Unstable Marble")

# Rendering settings
RENDER_VIDEO = True
FPS = 60
DURATION = 60  # In seconds

# Initialize renderer if rendering is enabled
renderer = VideoRenderer('simulation_silent.mp4', FPS, WIDTH, HEIGHT) if RENDER_VIDEO else None

# Load sound effects and set up channels
sound_effects = [pygame.mixer.Sound(f"audio/cc-{i}.wav") for i in range(1, 25)]
num_channels = 8
channels = [pygame.mixer.Channel(i) for i in range(num_channels)]
current_sound_index = 0
current_channel_index = 0

# Colors
BACKGROUND = (13, 15, 30)
WHITE = (255, 255, 255)
TRAIL_COLOR = (255, 219, 42)

# Circle colors
CIRCLE_COLORS = [
    (4, 237, 241),
    (54, 233, 201),
    (104, 229, 161),
    (154, 225, 121),
    (204, 221, 81),
    (255, 219, 42)
]

# Center offset
CENTER_OFFSET_X = 0 * RENDER_SCALE
CENTER_OFFSET_Y = -100 * RENDER_SCALE

# Center calculation
center_x = WIDTH // 2 + CENTER_OFFSET_X
center_y = HEIGHT // 2 + CENTER_OFFSET_Y

# Load and resize the logo
logo = pygame.image.load("logo.png").convert_alpha()
logo_width = int(WIDTH * 0.75)  
logo_height = int(logo.get_height() * (logo_width / logo.get_width()))
logo = pygame.transform.smoothscale(logo, (logo_width, logo_height))

# Calculate logo position
logo_x = (WIDTH - logo_width) // 2
logo_y = int(HEIGHT * 29/40)

# Ball movement config
INITIAL_SPEED_RANGE = (-1 * RENDER_SCALE, 1 * RENDER_SCALE)
GRAVITY = 0.15 * RENDER_SCALE
ELASTICITY = 1
FRICTION = 1
MAX_SPEED = 10 * RENDER_SCALE
CONTAINMENT_STRENGTH = 0.005
COLLISION_RANDOMNESS = 0.5 * RENDER_SCALE
MOVEMENT_RANDOMNESS = 0.1 * RENDER_SCALE

# Speed increase settings
SPEED_INCREASE_RATE = 0.000005
MAX_SPEED_MULTIPLIER = 2.0  # Maximum speed multiplier

# Circle properties
num_circles = 6
max_radius = min(WIDTH, HEIGHT) // 2 - 50 * RENDER_SCALE
radius_step = max_radius // num_circles
CIRCLE_STROKE_WIDTH = 2 * RENDER_SCALE

# Ball properties
ball_radius = 25 * RENDER_SCALE
ball_x = center_x
ball_y = center_y
ball_speed_x = random.uniform(*INITIAL_SPEED_RANGE)
ball_speed_y = random.uniform(*INITIAL_SPEED_RANGE)

# Trail properties
trail = []
trail_length = 20

# Star dust properties
num_stars = 100
stars = [(random.randint(0, WIDTH), random.randint(0, HEIGHT)) for _ in range(num_stars)]

# Hole properties
hole_size_pixels = 60 * RENDER_SCALE

# Circle segments (radius, [(start_angle, end_angle)])
circles = [(max_radius - i * radius_step, [(0, 2 * math.pi)]) for i in range(num_circles)]

# Particle properties
particles = []
PARTICLE_LIFETIME = 30
PARTICLE_COUNT = 5

# Pygame clock
clock = pygame.time.Clock()

def draw_aa_circle(surface, color, pos, radius, width=0):
    rect = pygame.Rect(pos[0] - radius, pos[1] - radius, radius * 2, radius * 2)
    shape_surf = pygame.Surface(rect.size, pygame.SRCALPHA)
    pygame.draw.circle(shape_surf, color, (radius, radius), radius, width)
    surface.blit(shape_surf, rect)

def draw_aa_arc(surface, color, rect, start_angle, stop_angle, width=1):
    shape_surf = pygame.Surface(rect.size, pygame.SRCALPHA)
    pygame.draw.arc(shape_surf, color, (0, 0, rect.width, rect.height), start_angle, stop_angle, width)
    surface.blit(shape_surf, rect)

def draw_logo(surface):
    surface.blit(logo, (logo_x, logo_y))

class Particle:
    def __init__(self, x, y):
        self.x = x
        self.y = y
        self.vx = random.uniform(-2, 2) * RENDER_SCALE
        self.vy = random.uniform(-2, 0) * RENDER_SCALE
        self.lifetime = PARTICLE_LIFETIME

    def update(self):
        self.x += self.vx
        self.y += self.vy
        self.lifetime -= 1

    def draw(self, surface):
        alpha = int(255 * (self.lifetime / PARTICLE_LIFETIME))
        color = (*WHITE, alpha)
        draw_aa_circle(surface, color, (int(self.x), int(self.y)), 2 * RENDER_SCALE)

def create_particles(x, y):
    for _ in range(PARTICLE_COUNT):
        particles.append(Particle(x, y))

def update_particles():
    global particles
    particles = [p for p in particles if p.lifetime > 0]
    for particle in particles:
        particle.update()

def draw_particles(surface):
    for particle in particles:
        particle.draw(surface)

def create_hole(circle_index, collision_angle):
    global circles
    radius, segments = circles[circle_index]
    hole_size_radians = hole_size_pixels / radius
    new_segments = []
    for start, end in segments:
        if start <= collision_angle <= end:
            if collision_angle - hole_size_radians/2 > start:
                new_segments.append((start, collision_angle - hole_size_radians/2))
            if collision_angle + hole_size_radians/2 < end:
                new_segments.append((collision_angle + hole_size_radians/2, end))
        else:
            new_segments.append((start, end))
    circles[circle_index] = (radius, new_segments)

def draw_star_dust(surface):
    for star in stars:
        draw_aa_circle(surface, WHITE, star, 1 * RENDER_SCALE)

def apply_containment_force():
    global ball_x, ball_y, ball_speed_x, ball_speed_y
    dx = center_x - ball_x
    dy = center_y - ball_y
    distance = math.sqrt(dx*dx + dy*dy)
    
    if distance > max_radius - ball_radius:
        force_x = dx / distance * CONTAINMENT_STRENGTH
        force_y = dy / distance * CONTAINMENT_STRENGTH
        ball_speed_x += force_x
        ball_speed_y += force_y

def check_circle_collision(x, y, circle_index):
    radius, circle_segments = circles[circle_index]
    dx = x - center_x
    dy = y - center_y
    distance = math.sqrt(dx*dx + dy*dy)
    
    collision_threshold = ball_radius * 0.4
    
    if abs(distance - radius) < collision_threshold:
        collision_angle = (math.atan2(-dy, dx) + 2 * math.pi) % (2 * math.pi)
        for start, end in circle_segments:
            if start <= collision_angle <= end:
                return True, distance < radius, collision_angle
        
        # If we're here, the ball is in a hole. Check if it can fit through.
        ball_angular_size = 2 * math.asin(ball_radius / distance)
        for i in range(len(circle_segments)):
            start, end = circle_segments[i]
            next_start = circle_segments[(i+1) % len(circle_segments)][0]
            gap_size = next_start - end if next_start > end else next_start + 2*math.pi - end
            if gap_size < ball_angular_size and start <= collision_angle <= next_start:
                return True, distance < radius, (end + gap_size/2) % (2*math.pi)
    
    return False, False, None

def play_collision_sound():
    global current_sound_index, current_channel_index
    channels[current_channel_index].play(sound_effects[current_sound_index])
    if RENDER_VIDEO:
        renderer.add_sound_event(current_sound_index)
    current_sound_index = (current_sound_index + 1) % 24
    current_channel_index = (current_channel_index + 1) % num_channels

def handle_collision(circle_index, is_inner_collision, collision_angle):
    global ball_x, ball_y, ball_speed_x, ball_speed_y
    
    radius, _ = circles[circle_index]
    
    # Calculate the normal vector
    normal_x = math.cos(collision_angle)
    normal_y = -math.sin(collision_angle)
    
    if is_inner_collision:
        normal_x = -normal_x
        normal_y = -normal_y
    
    # Calculate the dot product of velocity and normal
    dot_product = ball_speed_x * normal_x + ball_speed_y * normal_y
    
    # Calculate the reflection
    ball_speed_x = (ball_speed_x - 2 * dot_product * normal_x) * ELASTICITY
    ball_speed_y = (ball_speed_y - 2 * dot_product * normal_y) * ELASTICITY

    # Add some randomness to the bounce
    ball_speed_x += random.uniform(-COLLISION_RANDOMNESS, COLLISION_RANDOMNESS)
    ball_speed_y += random.uniform(-COLLISION_RANDOMNESS, COLLISION_RANDOMNESS)

    # Move the ball slightly away from the collision point
    offset = ball_radius * 0.1
    if is_inner_collision:
        ball_x = center_x + (radius - ball_radius - offset) * math.cos(collision_angle)
        ball_y = center_y - (radius - ball_radius - offset) * math.sin(collision_angle)
    else:
        ball_x = center_x + (radius + ball_radius + offset) * math.cos(collision_angle)
        ball_y = center_y - (radius + ball_radius + offset) * math.sin(collision_angle)

    play_collision_sound()
    create_particles(ball_x, ball_y)
    create_hole(circle_index, collision_angle)

# Main game loop
frame_count = 0
total_frames = FPS * DURATION if RENDER_VIDEO else float('inf')
escape_time = 0
speed_multiplier = 1.0

while frame_count < total_frames:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            if RENDER_VIDEO:
                renderer.finish()
            pygame.quit()
            sys.exit()

    render_surface.fill(BACKGROUND)
    draw_star_dust(render_surface)

    for i, (radius, circle_segments) in enumerate(circles):
        color = CIRCLE_COLORS[i]
        for start, end in circle_segments:
            draw_aa_arc(render_surface, color, 
                        pygame.Rect(center_x - radius, center_y - radius, radius * 2, radius * 2),
                        start, end, CIRCLE_STROKE_WIDTH)

    # Increase the speed multiplier
    speed_multiplier = min(speed_multiplier + SPEED_INCREASE_RATE, MAX_SPEED_MULTIPLIER)

    # Apply gravity and friction
    ball_speed_y += GRAVITY * speed_multiplier
    ball_speed_x *= FRICTION
    ball_speed_y *= FRICTION

    apply_containment_force()

    # Apply speed multiplier to ball speed
    ball_speed_x *= speed_multiplier
    ball_speed_y *= speed_multiplier

    # Cap the ball's speed
    speed = math.sqrt(ball_speed_x**2 + ball_speed_y**2)
    if speed > MAX_SPEED * speed_multiplier:
        ball_speed_x = (ball_speed_x / speed) * MAX_SPEED * speed_multiplier
        ball_speed_y = (ball_speed_y / speed) * MAX_SPEED * speed_multiplier

    sub_steps = 10
    dx = ball_speed_x / sub_steps
    dy = ball_speed_y / sub_steps
    
    for _ in range(sub_steps):
        new_x = ball_x + dx
        new_y = ball_y + dy
        
        collision_occurred = False
        for i in range(len(circles)):
            collision, is_inner, angle = check_circle_collision(new_x, new_y, i)
            if collision:
                handle_collision(i, is_inner, angle)
                collision_occurred = True
                break
        
        if not collision_occurred:
            ball_x = new_x
            ball_y = new_y

    ball_speed_x += random.uniform(-MOVEMENT_RANDOMNESS, MOVEMENT_RANDOMNESS)
    ball_speed_y += random.uniform(-MOVEMENT_RANDOMNESS, MOVEMENT_RANDOMNESS)

    update_particles()
    draw_particles(render_surface)

    trail.append((int(ball_x), int(ball_y)))
    if len(trail) > trail_length:
        trail.pop(0)

    for i, pos in enumerate(trail):
        alpha = int(255 * (i / trail_length))
        trail_color = (*TRAIL_COLOR, alpha)
        trail_surface = pygame.Surface((ball_radius * 2, ball_radius * 2), pygame.SRCALPHA)
        draw_aa_circle(trail_surface, trail_color, (ball_radius, ball_radius), ball_radius, 2 * RENDER_SCALE)
        render_surface.blit(trail_surface, (pos[0] - ball_radius, pos[1] - ball_radius))

    dx = ball_x - center_x
    dy = ball_y - center_y
    distance = math.sqrt(dx*dx + dy*dy)
    if distance > max_radius + ball_radius:
        if escape_time == 0:
            escape_time = frame_count / FPS
    
    draw_logo(render_surface)

    draw_aa_circle(render_surface, WHITE, (int(ball_x), int(ball_y)), ball_radius)

    # Scale down the render_surface to the display size
    scaled_surface = pygame.transform.smoothscale(render_surface, (DISPLAY_WIDTH, DISPLAY_HEIGHT))
    screen.blit(scaled_surface, (0, 0))

    pygame.display.flip()

    if RENDER_VIDEO:
        renderer.add_frame(render_surface)

    frame_count += 1
    clock.tick(FPS)

# Cleanup
if RENDER_VIDEO:
    renderer.finish()
    renderer.combine_audio('simulation_with_audio.mp4')

pygame.quit()