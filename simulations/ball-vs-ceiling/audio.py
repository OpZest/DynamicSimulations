import argparse
import subprocess

def generate_ffmpeg_command(audio_events_file, framerate, output_audio_file):
    events = []
    with open(audio_events_file, 'r') as f:
        for line in f:
            parts = line.strip().split(',')
            if len(parts) == 2:
                events.append(("data/" + parts[0], int(parts[1])))

    # Start the ffmpeg command with specifying the base silent audio as the first input
    ffmpeg_cmd = ['ffmpeg', '-i', 'base_silent_audio.wav']

    # Add inputs for each event audio file
    for idx, (event, _) in enumerate(events, start=1):
        ffmpeg_cmd += ['-i', event]

    # Construct the filter_complex command with correct stream labels
    filter_complex_cmd = []
    inputs = [f'[{idx}:a]adelay={int(frame/framerate*1000)}|{int(frame/framerate*1000)}[a{idx}]' for idx, (_, frame) in enumerate(events, start=1)]
    filter_complex_cmd += inputs
    # Mix all adjusted inputs plus the base audio
    filter_complex_cmd += [f'[0:a]{"".join(f"[a{idx}]" for idx in range(1, len(events)+1))}amix=inputs={len(events)+1}[mixed]']
    # Apply loudnorm filter to the mixed audio
    filter_complex_cmd += ['[mixed]loudnorm=I=-16:LRA=14:TP=-1[a]']

    # Specify the output file
    ffmpeg_cmd += ['-filter_complex', ';'.join(filter_complex_cmd), '-map', '[a]', output_audio_file]

    return ffmpeg_cmd

if __name__ == "__main__":
    # Create the parser
    parser = argparse.ArgumentParser(description='Generate an ffmpeg command to process audio events.')

    # Define arguments
    parser.add_argument('audio_events_file', type=str, help='The path to the audio events file.')
    parser.add_argument('framerate', type=int, help='The video framerate.')
    parser.add_argument('output_audio_file', type=str, help='The path for the output audio file.')

    # Parse arguments
    args = parser.parse_args()

    # Generate FFmpeg command using parsed arguments
    ffmpeg_command = generate_ffmpeg_command(args.audio_events_file, args.framerate, args.output_audio_file)

    # Execute the ffmpeg command
    print(f"Executing ffmpeg command: {' '.join(ffmpeg_command)}")
    subprocess.run(ffmpeg_command)

