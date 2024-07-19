import cv2
import numpy as np
from moviepy.editor import VideoFileClip, AudioFileClip
from pydub import AudioSegment
import pygame
import os

class VideoRenderer:
    def __init__(self, filename, fps, width, height):
        self.filename = filename
        self.fps = fps
        self.width = width
        self.height = height
        self.fourcc = cv2.VideoWriter_fourcc(*'H264')
        self.video = cv2.VideoWriter(filename, self.fourcc, fps, (width, height), isColor=True)
        self.frame_count = 0
        self.sound_events = []

    def add_frame(self, surface):
        frame = pygame.surfarray.array3d(surface)
        frame = cv2.transpose(frame)
        frame = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)
        self.video.write(frame)
        self.frame_count += 1

    def add_sound_event(self, sound_index):
        self.sound_events.append((self.frame_count / self.fps, sound_index))

    def finish(self):
        self.video.release()
        print(f"Video rendering complete. Output: {self.filename}")

    def combine_audio(self, output_filename):
        # Create a silent base audio
        base_audio = AudioSegment.silent(duration=int(self.frame_count / self.fps * 1000))

        # Overlay all sound events
        for time, sound_index in self.sound_events:
            sound_file = f"audio/cc-{sound_index + 1}.wav"
            sound = AudioSegment.from_wav(sound_file)
            base_audio = base_audio.overlay(sound, position=int(time * 1000))

        # Normalize the audio
        target_level = -14  # Target loudness level in LUFS
        change_in_dbfs = target_level - base_audio.dBFS
        normalized_audio = base_audio.compress_dynamic_range(
            threshold=-18,
            ratio=2,
            attack=5,
            release=50
        ).apply_gain(change_in_dbfs)

        # Export the normalized audio
        temp_audio_file = "temp_normalized_audio.wav"
        normalized_audio.export(temp_audio_file, format="wav")

        # Combine video and normalized audio with higher quality settings
        video = VideoFileClip(self.filename)
        audio = AudioFileClip(temp_audio_file)
        final_video = video.set_audio(audio)
        final_video.write_videofile(output_filename, codec="libx264", audio_codec="aac", bitrate="8000k", preset="slow")

        # Clean up temporary audio file
        os.remove(temp_audio_file)

        print(f"Video with normalized audio rendered.")