# Dynamic Simulations

Written using a [Semi-Autonomous Production Engine instance](https://github.com/OpZest/Papers/blob/main/White_papers/Precision_Shaking_and_DORPO.md) (SAPE), these visual simulations explore various concepts in mathematics and physics, along with some imaginative and made-up scenarios.

## Render examples

- 3-body problem: [Link](https://www.youtube.com/shorts/3IXeo3I_Kko)
- Triangle escape: [Link](https://www.youtube.com/shorts/707H8ApfNKo)

## Using Processing Simulations

To use the simulations provided in this repo, follow these steps:

### 1. Download Processing

- Download and install Processing from [processing.org](https://processing.org/download/).

### 2. Clone the Repository or Download a Specific Simulation

- Clone this repo or download a specific simulation from the `simulations` folder. Each simulation folder contains the necessary files.

### 3. Open the Simulation in Processing

- Navigate to the simulation folder and open `sim.pde` in Processing.

### 4. Running the Simulation/Rendering a Video

#### 4A. If you want to render a video of the simulation:

- Ensure `initializeRendering` is set to `true` in `sim.pde`.
- Hit play in Processing to start the simulation.
- After running the simulation:
  - Navigate to the `render` folder.
  - Open the folder with the latest rendering session (e.g., `"001"`).
  - Open `commands.txt` and copy the full rendering command.
  - Open a terminal at the root folder of the simulation and paste the command.
  - Execute the command in the terminal.
- The video will be rendered as `output_final` in the respective render session folder.

#### 4B. If you do not want to render a video:

- Make sure `initializeRendering` is set to `false` in `sim.pde`.
- Hit play in Processing to run the simulation.
