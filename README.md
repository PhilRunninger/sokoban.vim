# VimSokoban

The goal of VimSokoban is to push all the packages into the home area of each level using the cursor movement keys. The keys move the player in the corresponding direction. If a package is in the way it will be moved too, if there's an empty space beyond it. Packages can only be pushed, so until they're in their home position, make sure you can get behind them to push in the right direction. If you get stuck, you can undo your moves or restart the level.

## Starting the Game
Use any of the following commands to start a game. `<level>` is an optional parameter that lets you select the level to play, a number from 1 to 90. If not supplied, you will resume at the last level you played.
* `:Sokoban <level>`    (no split window)
* `:SokobanH <level>`   (horizontal split window)
* `:SokobanV <level>`   (vertical split window)

## Keys
These are the keys you need to use when playing the game.
* <kbd>h</kbd> or <kbd>Left</kbd> - move left
* <kbd>j</kbd> or <kbd>Down</kbd> - move down
* <kbd>k</kbd> or <kbd>Up</kbd> - move up
* <kbd>l</kbd> or <kbd>Right</kbd> - move right
* <kbd>u</kbd> - undo move
* <kbd>r</kbd> - restart level
* <kbd>n</kbd> - next level
* <kbd>p</kbd> - previous level

## Customizing
The plugin uses Unicode characters that may not display well in your font. You can customize them in your `.vimrc` file like so:
```
let g:charSoko    = '@'
let g:charWall    = '#'
let g:charPackage = '$'
let g:charHome    = '.'
```
The directory containing the level files is in the variable `g:SokobanLevelDirectory`.

The path and name of the high score file is in the variable `g:SokobanScoreFile`.

## Reference
Levels came from the [xsokoban distribution](http://www.cs.cornell.edu/andru/xsokoban.html) which is in the public domain. The site provides a way to submit your moves to be recorded for posterity, but whether that list is being maintained is unknown. The link for submitting scores is: http://www.cs.cornell.edu/andru/xsokoban/manual-solve.html

More information about Sokoban can be found on its [Wikipedia page](https://en.wikipedia.org/wiki/Sokoban).

