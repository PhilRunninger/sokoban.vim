# VimSokoban

The goal of **VimSokoban** is to push all the packages into the home area of each level using the cursor movement keys. The keys move the player in the corresponding direction. If a package is in the way it will be moved too, if there's an empty space beyond it. Packages can only be pushed. If you get stuck, you can undo your moves or restart the level.

## Starting the Game
Use any of the following commands to start a game. `<level>` is an optional parameter that lets you select the level to play in the current set of levels. If not supplied, you will resume at the last level you played.
* `:Sokoban <level>`    (no split window)
* `:SokobanH <level>`   (horizontal split window)
* `:SokobanV <level>`   (vertical split window)

## Keys
These are the keys you need to use when playing the game.

Key | Function
:-:|---
<kbd>h</kbd> or <kbd>Left</kbd> | Move Left
<kbd>j</kbd> or <kbd>Down</kbd> | Move Down
<kbd>k</kbd> or <kbd>Up</kbd> | Move Up
<kbd>l</kbd> or <kbd>Right</kbd> | Move Right
<kbd>u</kbd> | **U**ndo Move
<kbd>r</kbd> | **R**estart Level
<kbd>n</kbd> | **N**ext Level
<kbd>p</kbd> | **P**revious Level
<kbd>0</kbd>-<kbd>9</kbd> | Select any level by **number** typed.
<kbd>s</kbd> | Choose a level **s**et to play

## Customizing
* The plugin uses Unicode characters that may not display well in your font. You can customize them in your `.vimrc` file like so:
```vim
let g:charWall          = '#'     " Default: '█'
let g:charSoko          = '@'     " Default: '◆'
let g:charPackage       = '$'     " Default: '○'
let g:charHome          = '.'     " Default: '◻'
let g:charPackageAtHome = '*'     " Default: '◼'
```
* The path and name of the high score file is in the variable `g:SokobanScoreFile`. It defaults to *.VimSokobanScores* in the plugin's root folder.

## More Levels
Additional level sets can be downloaded from the very long list on the [http://www.sourcecode.se/sokoban/levels](http://www.sourcecode.se/sokoban/levels) webpage. Choose the option to download as an XML file; it will have an extension of SLC. These collections range wildly in terms of size, difficulty and number of levels.

The SLC file needs to be converted before it can used by this plugin. Run the `:SokobanConvertSLC` command while your cursor is in the SLC buffer. Check the resulting JSON for errors, and then save the buffer as a JSON file in the plugin's `levels` folder. If you would like to contribute to **VimSokoban** by converting more SLC files to JSON, please do by submitting a pull request.

## Reference
More information about Sokoban can be found on its [Wikipedia page](https://en.wikipedia.org/wiki/Sokoban).
