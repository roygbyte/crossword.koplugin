# Crossword

Solve crosswords on your [KOReader](https://github.com/koreader/koreader) powered device!

![kocrossword_desk](https://user-images.githubusercontent.com/82218266/156276756-26628c01-8441-44eb-8c09-b8d14c515c31.png)

## Installation

### Get the project files and transfer them to your device.

1. Download or clone this repository to your computer.
2. Initialize the [submodule](https://github.com/doshea/nyt_crosswords/tree/623e72e99b25a524c85b56bf832dd7cd8c2a34a9) (run `git submodule update --init` inside the `crossword.koplugin` folder, or visit the submodule repo, download it to your machine, and place it in this project's directory)
3. Attach your e-reader to your computer.
4. Drag the entire folder (titled `crossword.koplugin`) to your e-reader, placing it in the `plugins` folder located at: `.adds/koreader/plugins/`.
5. Restart your device.

### Configure the plugin 

1. Launch the plugin on your device (you'll find it in the main toolbar).
2. Click on "Settings" in the plugin's menu.
3. Click on "Set puzzles folder" and choose the `nyt_crosswords` folder.

## Development

See my article ["How I develop plugins for KOReader"](https://roygbyte.com/how_i_develop_plugins_for_koreader.html) for an overview of this plugin's development process.

### Testing

Copy `crossword_spec.koplugin` into `koreader/spec/unit`. Run the tests with `./kodev test front crossword_spec.lua`.

### Flaws

- Deleting the crossword history doesn't delete the underlying puzzle values. In other words, you can't delete the history and expect to start a puzzle fresh again.
- The puzzle library doesn't show you puzzles you have completed or are working in progress.
- There's no congratulatory message upon completing a puzzle (I would expect balloons).
- There are no easter eggs.
