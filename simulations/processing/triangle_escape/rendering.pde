import processing.sound.*;
import java.io.*;

SoundFile bounceSoundA;
SoundFile bounceSoundB;
SoundFile bgMusic;

int totalFramesToCapture = 3600;
String basePath = "render"; // Base name for the rendering folders
String sessionFolderPath; // Variable to hold the session folder path
String framesFolderPath; // Variable to hold the frames subfolder path
boolean isRendering = false;

void initializeRendering(String baseFolderPath, int frameRate, boolean enableRendering) {
  basePath = baseFolderPath;
  isRendering = enableRendering;

  if (isRendering) {
    int nextSessionNumber = getNextSessionNumber(basePath) + 1;
    String sessionFolderName = nf(nextSessionNumber, 3);
    sessionFolderPath = basePath + "/" + sessionFolderName;
    framesFolderPath = sessionFolderPath + "/frames";

    // Create the session folder and frames subfolder
    File framesFolder = new File(sketchPath(framesFolderPath));
    if (!framesFolder.exists()) {
      framesFolder.mkdirs();
    }

    String pythonCommand = "python3 audio.py " + sketchPath(sessionFolderPath) + "/audio_events.txt " + frameRate + " " + sketchPath(sessionFolderPath) + "/final_audio.wav";

    String ffmpegSilentVideoCommand = "ffmpeg -framerate " + frameRate + " -i " + sketchPath(framesFolderPath) + "/frame-%05d.png -c:v libx264 -pix_fmt yuv420p -crf 20 " + sketchPath(sessionFolderPath) + "/silent_video.mp4";

    String ffmpegMergeCommand = "ffmpeg -i " + sketchPath(sessionFolderPath) + "/silent_video.mp4 -i " + sketchPath(sessionFolderPath) + "/final_audio.wav -c:v copy -c:a aac -strict experimental " + sketchPath(sessionFolderPath) + "/output_final.mp4";

    String combinedCommands = pythonCommand + " && " + ffmpegSilentVideoCommand + " && " + ffmpegMergeCommand;

    String commandFilePath = sketchPath(sessionFolderPath + "/commands.txt");
    saveText(commandFilePath, combinedCommands);
  }
}

int getNextSessionNumber(String basePath) {
  File parentFolder = new File(sketchPath(basePath));
  if (!parentFolder.exists()) {
    parentFolder.mkdirs();
    return 0; // Start numbering from 1
  }
  File[] existingFolders = parentFolder.listFiles();
  int maxNumber = 0;
  for (File folder : existingFolders) {
    if (folder.isDirectory()) {
      try {
        int folderNumber = Integer.parseInt(folder.getName());
        maxNumber = max(maxNumber, folderNumber);
      } catch (NumberFormatException e) {
        // Ignore files or folders that don't have a numeric name
      }
    }
  }
  return maxNumber;
}

void saveText(String path, String content) {
  BufferedWriter writer;
  try {
    writer = new BufferedWriter(new FileWriter(path));
    writer.write(content);
    writer.close();
  } catch (IOException e) {
    e.printStackTrace();
  }
}

// Function to log audio events
void logAudioEvent(String soundName, int frame) {
  if (isRendering) {
    String filename = sketchPath(sessionFolderPath + "/audio_events.txt"); 
    String logEntry = soundName + "," + frame + "\n";
    try {
      FileWriter fw = new FileWriter(filename, true); // 'true' to append data
      BufferedWriter bw = new BufferedWriter(fw);
      bw.write(logEntry);
      bw.close();
    } catch (IOException e) {
      e.printStackTrace();
    }
  }
}

void renderFrame() {
  if (isRendering && frameCount <= totalFramesToCapture) {
    saveFrame(framesFolderPath + "/frame-#####.png");
  }
}
