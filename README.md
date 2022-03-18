# VimSokoban

The goal of VimSokoban is to push all the packages into the home area of each level using the cursor movement keys. The keys move the player in the corresponding direction. If a package is in the way it will be moved too, if there's an empty space beyond it. Packages can only be pushed. If you get stuck, you can undo your moves or restart the level.

## Starting the Game
Use any of the following commands to start a game. `<level>` is an optional parameter that lets you select the level to play. If not supplied, you will resume at the last level you played.
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
* <kbd>0</kbd>-<kbd>9</kbd> - select any level by number typed
* <kbd>s</kbd> - select a level set to play

## Customizing
* The plugin uses Unicode characters that may not display well in your font. You can customize them in your `.vimrc` file like so:
```
let g:charSoko    = '@'
let g:charWall    = '#'
let g:charPackage = '$'
let g:charHome    = '.'
```
* The path and name of the high score file is in the variable `g:SokobanScoreFile`. It defaults to *.VimSokobanScores* in the plugin's root folder.

## Reference
The level sets were derived from the zip file at the [Download all levels in a ZIP file](http://www.sourcecode.se/sokoban/download/Levels.zip) link on the [http://www.sourcecode.se/sokoban/levels](http://www.sourcecode.se/sokoban/levels) webpage. Each `*.slc` file in that zip file is a level set ranging wildly in terms of size, difficulty and number of levels. The function named `converter#slc#ToJSON()` in [autoload/converter/slc.vim](https://github.com/PhilRunninger/sokoban.vim/tree/master/autoload/converter/slc.vim) converts an `*.slc` file to JSON format so it can be used by this plugin. Read the documentation that comes with it before using it. If you would like to contribute by converting more `*.slc` files to JSON, please do and submit a pull request.

More information about Sokoban can be found on its [Wikipedia page](https://en.wikipedia.org/wiki/Sokoban).
