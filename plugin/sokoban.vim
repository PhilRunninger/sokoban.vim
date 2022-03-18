" Boilerplate {{{1
" Copyright (c) 1998-2022   {{{2
" Michael Sharpe <feline@irendi.com>
" Phil Runninger
"
" We grant permission to use, copy modify, distribute, and sell this
" software for any purpose without fee, provided that the above copyright
" notice and this text are not removed. We make no guarantee about the
" suitability of this software for any purpose and we are not liable
" for any damages resulting from its use. Further, we are under no
" obligation to maintain or extend this software. It is provided on an
" "as is" basis without any expressed or implied warranty.
"
" Objective:   {{{2
" The goal of VimSokoban is to push all the packages ($) into
" the  home area (.) of each level using hjkl keys or the arrow
" keys. The arrow keys move the player (X) in the corresponding
" direction, pushing an object if it is in the way and there
" is a clear space on the other side.
"
" Levels came from the xsokoban distribution which is in the public domain.
" http://www.cs.cornell.edu/andru/xsokoban.html
"
" Commands / Maps:   {{{2
"    :Sokoban - or -  :Sokoban <level>   -- Start sokoban in the current window
"    :SokobanH - or - :SokobanH <level>  -- horiz split and start sokoban
"    :SokobanV - or - :SokobanV <level>  -- vertical split and start sokoban
"
"    h or <Left>  - move the man left
"    j or <Down>  - move the man down
"    k or <Up>    - move the man up
"    l or <Right> - move the man right
"    r            - restart level
"    n            - next level
"    p            - previous level
"    u            - undo move
"
" Installation / Setup:   {{{2
"
" Install according to the directions found in any of the various Vim Plugin
" managers, such as: pathogen, Vundle, vim-plug, etc.
"
" The location of the scores file is configurable. If not set in your .vimrc,
" g:SokobanScoreFile defaults to .VimSokobanScores in the plugin's root folder.
"
" The characters used to display the level are configurable. By default, they
" are set to some Unicode characters, so if your terminal is incompatible, you
" should change them. The variables are:
"   g:charSoko
"   g:charWall
"   g:charPackage
"   g:charPackageHome
"   g:charHome
"
" Release Notes:   {{{2
"    1.0  - initial release
"    1.1  - j/k mapping bug fixed
"         - added SokobanH, and SokobanV commands to control splitting
"         - added extra guidance on the level complete message
"    1.1a - minor windows changes
"    1.1b - finally default to the <sfile> expansions
"    1.2  - funny how the first ten levels work and then 11 fails to
"          complete properly. Fixed a bug in AreAllPackagesHome() which
"          prevent the level from completing correctly.
"    1.3  - set buftype to nofle
"         - set nomodifiable
"         - remember current level
"         - best scores for each level
"
" Acknowledgements:   {{{2
"    Dan Sharp - j/k key mappings were backwards.
"    Bindu Wavell/Gergely Kontra - <sfile> expansion
"    Gergely Kontra - set buftype suggestion, set nomodifiable
" }}}
" }}}

" Allow the user to specify the location of the sokoban levels
let g:SokobanLevelDirectory = resolve(fnamemodify(expand('<sfile>:p:h') . '/../levels/','p:'))

" Allow the user to specify the location of the score file.
let g:SokobanScoreFile = get(g:,'SokobanScoreFile',resolve(expand('<sfile>:p:h') . '/../.VimSokobanScores'))

" Characters used to draw the maze and objects on the screen.
let g:charWall        = get(g:,'charWall',       '█') " replaces # in level file
let g:charSoko        = get(g:,'charSoko',       '◆') " replaces @ and + in level file
let g:charHome        = get(g:,'charHome',       '◻') " replaces . in level file
let g:charPackageHome = get(g:,'charPackageHome','◼') " replaces * in level file
let g:charPackage     = get(g:,'charPackage',    '○') " replaces $ in level file

command! -nargs=? Sokoban call sokoban#PlaySokoban('e', <f-args>)
command! -nargs=? SokobanH call sokoban#PlaySokoban('h', <f-args>)
command! -nargs=? SokobanV call sokoban#PlaySokoban('v', <f-args>)

" vim: foldmethod=marker
