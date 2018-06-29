" Boilerplate {{{1
" Copyright (c) 1998-2018   {{{2
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
" The locations of the levels direcory and the scores file are configurable. If
" not set in your .vimrc,
"   1) g:SokobanLevelDirectory defaults to the plugin's levels folder.
"   2) g:SokobanScoreFile defaults to .VimSokobanScores in the plugin's root folder.
"
" The characters used to display the level are configurable. By default, they
" are set to some Unicode characters, so if your terminal is incompatible, you
" should change them. The variables are:
"   g:charSoko
"   g:charWall
"   g:charPackage
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

" Initial setup   {{{1
" Do nothing if the script has already been loaded
if (exists("g:VimSokoban_version"))
    finish
endif
let g:VimSokoban_version = "1.4"

" Allow the user to specify the location of the sokoban levels
if exists("g:SokobanLevelDirectory")
    if !isdirectory("g:SokobanLevelDirectory")
        echoerr "g:SokobanLevelDirectory contains an invalid path."
        finish
    endif
else
    let g:SokobanLevelDirectory = fnamemodify(expand("<sfile>:p:h") . "/../levels/","p:")
endif

" Allow the user to specify the location of the score file.
if !exists("g:SokobanScoreFile")
    let g:SokobanScoreFile = expand("<sfile>:p:h") . "/../.VimSokobanScores"
endif

" Characters used to draw the level on the screen.
if exists("g:charSoko")
    let g:charSoko = strcharpart(g:charSoko,0,1)
else
    let g:charSoko = '☺'  " replaces @ in level file
endif
if exists("g:charWall")
    let g:charWall = strcharpart(g:charWall,0,1)
else
    let g:charWall = '▓'  " replaces # in level file
endif
if exists("g:charPackage")
    let g:charPackage = strcharpart(g:charPackage,0,1)
else
    let g:charPackage  = '✠'  " replaces $ in level file
endif
if exists("g:charHome")
    let g:charHome = strcharpart(g:charHome,0,1)
else
    let g:charHome = '○'  " replaces . and * in level file
endif

command! -nargs=? Sokoban call Sokoban("", <f-args>)
command! -nargs=? SokobanH call Sokoban("h", <f-args>)
command! -nargs=? SokobanV call Sokoban("v", <f-args>)

function! <SID>ClearBuffer()   "{{{1
    " About...   {{{2
    " Function : ClearBuffer (PRIVATE
    " Purpose  : clears the buffer of all characters
    " Args     : none
    " Returns  : nothing
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    normal 1G
    normal dG
endfunction

function! <SID>DisplayInitialHeader(level)   "{{{1
    " About...   {{{2
    " Function : DisplayInitialHeader (PRIVATE)
    " Purpose  : Displays the header of the sokoban screen
    " Args     : level - the current level number
    " Returns  : nothing
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    call append(0, '                            VIM SOKOBAN')
    call append(1, '                        <<<<=<<=<=>=>>=>>>>')
    call append(2, 'Score                                                         Key')
    call append(3, '==============   Best (moves,pushes)                          ==================')
    call append(4, printf('Level:  %6d   =================================            %s soko      %s wall', a:level,g:charSoko,g:charWall))
    call append(5, '')
    call append(6, '')
    call <SID>UpdateHeader()  " Fill in those two blank lines I just made.
    call append(7, ' ')
    call append(8, 'Commands:  h,j,k,l - move   u - undo   r - restart   n,p - next, previous level')
    call append(9, '================================================================================')
    call append(10, ' ')
    let s:endHeaderLine = 11
endfunction

function! <SID>UpdateHeader()   "{{{1
    " About...   {{{2
    " Function : UpdateHeader (PRIVATE
    " Purpose  : updates the moves and the pushes scores in the header
    " Args     : none
    " Returns  : nothing
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    call setline(6, printf("Moves:  %6d   %-40s     %s package   %s home",b:moves,b:fewestMoves,g:charPackage,g:charHome))
    call setline(7, printf("Pushes: %6d   %-40s", b:pushes,b:fewestPushes))
endfunction

function! <SID>DisplayLevelCompleteMessage()   "{{{1
    " About...   {{{2
    " Function : DisplayLevelCompleteMessage (PRIVATE
    " Purpose  : Display the message indicating that the level has been completed
    " Args     : none
    " Returns  : nothing
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    call setline(14, "          |                                                         |           ")
    call setline(15, "        --+---------------------------------------------------------+--         ")
    call setline(16, "          |                       LEVEL COMPLETE                    |           ")
    call setline(17, printf("          |              %6d Moves  %6d Pushes                |           ", b:moves,b:pushes))
    call setline(18, "          |---------------------------------------------------------|           ")
    call setline(19, "          | r - restart level   p - previous level   n - next level |           ")
    call setline(20, "        --+---------------------------------------------------------+--         ")
    call setline(21, "          |                                                         |           ")
endfunction

function! <SID>ProcessLevel()   "{{{1
    " About...   {{{2
    " Function : ProcessLevel (PRIVATE
    " Purpose  : processes a level which has been loaded and populates the object
    "            lists and sokoban man position.
    " Args     : none
    " Returns  : nothing
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    let b:wallList = []    " list of all wall locations
    let b:homeList = []    " list of all home square locations
    let b:packageList = [] " list of all package locations
    let b:undoList = []    " list of current moves (used for the undo move feature)

    let eob = line('$')
    let l = s:endHeaderLine
    while (l <= eob)
        let currentLine = getline(l)
        let eoc = strchars(currentLine)
        let c = 1
        while (c <= eoc)
            let ch = currentLine[c]
            if (ch == '#')
                call add(b:wallList, [l,c])
            elseif (ch == '.')
                call add(b:homeList, [l,c])
            elseif (ch == '*')
                call add(b:homeList, [l,c])
                call add(b:packageList, [l,c])
            elseif (ch == '$')
                call add(b:packageList, [l,c])
            elseif (ch == '@')
                let b:manPos = [l,c]
            else
            endif
            let c = c + 1
        endwhile
        let l = l + 1
    endwhile
endfunction

function! <SID>LoadLevel(level)   "{{{1
    " About...   {{{2
    " Function : LoadLevel (PRIVATE)
    " Purpose  : loads the level and sets up the syntax highlighting for the file
    " Args     : level - the level to load
    " Returns  : nothing
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    normal dG
    let levelFile = g:SokobanLevelDirectory . "level" . a:level . ".sok"
    if filereadable(levelFile)
        setlocal modifiable
        execute "r " . levelFile
        silent! execute s:endHeaderLine.",$ s/^/           /g"
        call <SID>ProcessLevel()
        let b:level = a:level

        " Replace placeholder text (level file) with appropriate characters.
        silent! execute s:endHeaderLine . ",$ s/\\V@/".g:charSoko."/g"
        silent! execute s:endHeaderLine . ",$ s/\\V#/".g:charWall."/g"
        silent! execute s:endHeaderLine . ",$ s/\\V$/".g:charPackage."/g"
        silent! execute s:endHeaderLine . ",$ s/\\V./".g:charHome."/g"
        silent! execute s:endHeaderLine . ",$ s/\\V*/".g:charPackage."/g"

        call append(line("$"), "")
        call append(line("$"), '================================================================================')
        call append(line("$"), "The sequence of moves is stored in the scores file.")

        if has("syntax")
            syn clear
            execute 'syn match SokobanMan /'.g:charSoko.'/'
            execute 'syn match SokobanPackage /'.g:charPackage.'/'
            execute 'syn match SokobanWall /'.g:charWall.'/'
            execute 'syn match SokobanHome /'.g:charHome.'/'
            highlight link SokobanPackage String
            highlight link SokobanMan Special
            highlight link SokobanWall Comment
            highlight link SokobanHome Statement
        endif
        call <SID>SaveCurrentLevelToFile(a:level)
        setlocal buftype=nofile
        setlocal nomodifiable
        setlocal nolist nonumber
    else
        let b:level = 0
        call append(10, "Could not find file " . levelFile)
    endif
endfunction

function! <SID>SetCharInLine(cell, char)   "{{{1
    " About...   {{{2
    " Function : SetCharInLine (PRIVATE)
    " Purpose  : Puts a specified character at a specific position in the specified
    "            line
    " Args     : cell - the cell to manipulate
    "            char - the character to set at the position
    " Returns  : nothing
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    let [theLine,theCol] = a:cell
    let ln = getline(theLine)
    let leftStr = strcharpart(ln, 0, theCol)
    let rightStr = strcharpart(ln, theCol + 1)
    let ln = leftStr . a:char . rightStr
    call setline(theLine, ln)
endfunction

function! <SID>IsWall(cell)   "{{{1
    " About...   {{{2
    " Function : IsWall (PRIVATE)
    " Purpose  : determines whether the specified cell corresponds to a wall
    " Args     : cell - the location to check
    " Returns  : 1 if the cell is a wall, 0 otherwise
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    return index(b:wallList, a:cell) >= 0
endfunction

function! <SID>IsHome(cell)   "{{{1
    " About...   {{{2
    " Function : IsHome (PRIVATE)
    " Purpose  : determines whether the specified (line, column) pair corresponds
    "            to a home area
    " Args     : cell - the location to check
    " Returns  : 1 if the cell is a home area, 0 otherwise
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    return index(b:homeList, a:cell) >= 0
endfunction

function! <SID>IsPackage(cell)   "{{{1
    " About...   {{{2
    " Function : IsPackage (PRIVATE)
    " Purpose  : determines whether the specified cell corresponds to a package
    " Args     : cell - the location to check
    " Returns  : 1 if the cell is a package, 0 otherwise
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    return index(b:packageList, a:cell) >= 0
endfunction

function! <SID>IsEmpty(cell)   "{{{1
    " About...   {{{2
    " Function : IsEmpty (PRIVATE)
    " Purpose  : determines whether the specified cell corresponds to empty space in the maze
    " Args     : cell - the location to check
    " Returns  : 1 if the cell is an empty space, 0 otherwise
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    return !<SID>IsWall(a:cell) && !<SID>IsPackage(a:cell)
endfunction

function! <SID>MoveMan(from, to, package)   "{{{1
    " About...   {{{2
    " Function : MoveMan (PRIVATE)
    " Purpose  : moves the man and possibly a package in the buffer. The package is
    "            assumed to move from where the man moves too. Home squares are
    "            handled correctly in this function too. Things are a little crazy
    "            for the undo'ing of a move.
    " Args     : from - the cell where the man is moving from
    "            to - the cell where the man is moving to
    "            package - the cell where a package is moving to
    " Returns  : nothing
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    if <SID>IsHome(a:from)
        call <SID>SetCharInLine(a:from, g:charHome)
    else
        call <SID>SetCharInLine(a:from, ' ')
    endif
    call <SID>SetCharInLine(a:to, g:charSoko)
    if !empty(a:package)
        call <SID>SetCharInLine(a:package, g:charPackage)
    endif
endfunction

function! <SID>UpdatePackageList(old, new)   "{{{1
    " About...   {{{2
    " Function : UpdatePackageList (PRIVATE)
    " Purpose  : updates the package list when a package is moved
    " Args     : old - the cell of the old package location
    "            new - the cell of the package's new location
    " Returns  : nothing
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    call remove(b:packageList, index(b:packageList, a:old))
    call add(b:packageList, a:new)
endfunction

function! <SID>AreAllPackagesHome()   "{{{1
    " About...   {{{2
    " Function : AreAllPackagesHome (PRIVATE
    " Purpose  : Determines if all packages have been placed in the home area
    " Args     : none
    " Returns  : 1 if all packages are home (i.e. level complete), 0 otherwise
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    for pkg in b:packageList
        if !<SID>IsHome(pkg)
            return 0
        endif
    endfor
    return 1
endfunction

function! <SID>AddVectors(x, y)   "{{{1
    " About...   {{{2
    " Function : AddVectors (PRIVATE)
    " Purpose  : Adds two vectors (lists) together.
    " Args     : x - a list of 2 numbers
    "            y - a list of 2 numbers
    " Returns  : A new list, the sum of x and y
    " Author   : Phil Runninger (philrunninger@gmail.com)   }}}
    return [a:x[0]+a:y[0], a:x[1]+a:y[1]]
endfunction

function! <SID>SubtractVectors(x, y)   "{{{1
    " About...   {{{2
    " Function : SubtractVectors (PRIVATE)
    " Purpose  : Subtracts two vectors (lists) together.
    " Args     : x - a list of 2 numbers
    "            y - a list of 2 numbers
    " Returns  : A new list, the difference of x and y
    " Author   : Phil Runninger (philrunninger@gmail.com)   }}}
    return [a:x[0]-a:y[0], a:x[1]-a:y[1]]
endfunction

function! <SID>MakeMove(delta, moveDirection)   "{{{1
    " About...   {{{2
    " Function : MakeMove (PRIVATE)
    " Purpose  : This is the core function which is called when a move is made. It
    "            detemines if the move is legal, if packages have moved and takes
    "            care of updating the buffer to reflect the new position of
    "            everything.
    " Args     : delta - indicates the direction the man has moved
    "            moveDirection - character to place in the undolist which
    "                            represents the move
    " Returns  : nothing
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    let newManPos = <SID>AddVectors(b:manPos, a:delta)
    if !<SID>IsWall(newManPos)
        " if the location we want to move to is not a wall continue processing
        if <SID>IsPackage(newManPos)
            " if the new position is a package check to see if the package moves
            let newPkgPos = <SID>AddVectors(newManPos, a:delta)
            if <SID>IsEmpty(newPkgPos)
                setlocal modifiable
                " the move is possible and we pushed a package
                call <SID>MoveMan(b:manPos, newManPos, newPkgPos)
                call <SID>UpdatePackageList(newManPos, newPkgPos)
                call insert(b:undoList, a:moveDirection . "p")
                let b:moves = b:moves + 1
                let b:pushes = b:pushes + 1
                let b:manPos = newManPos
                call <SID>UpdateHeader()
                " check to see if the level is complete. Only need to do this after
                " each package push as each level must end with a package push
                if <SID>AreAllPackagesHome()
                    call <SID>SetupMaps(0)
                    call <SID>DisplayLevelCompleteMessage()
                    call <SID>UpdateHighScores()
                    call <SID>SaveCurrentLevelToFile(b:level + 1)
                endif
                setlocal nomodifiable
            endif
        else
            setlocal modifiable
            " the move is possible and no packages moved
            call <SID>MoveMan(b:manPos, newManPos, [])
            call insert(b:undoList, a:moveDirection)
            let b:moves = b:moves + 1
            let b:manPos = newManPos
            call <SID>UpdateHeader()
            setlocal nomodifiable
        endif
    endif
endfunction

function! <SID>UndoMove()   "{{{1
    " About...   {{{2
    " Function : UndoMove (PRIVATE
    " Purpose  : Called when the u key is hit to handle the undo move operation
    " Args     : none
    " Returns  : nothing
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    if !empty(b:undoList)
        let prevMove = b:undoList[0]
        call remove(b:undoList, 0)

        " determine which way the man has to move to undo the move
        if prevMove =~ "^h"
            let delta = [0,1]
        elseif prevMove =~ "^l"
            let delta = [0,-1]
        elseif prevMove =~ "^k"
            let delta = [1,0]
        elseif prevMove =~ "^j"
            let delta = [-1,0]
        else
            return
        endif

        " old position of the man
        let newManPos = <SID>AddVectors(b:manPos, delta)

        " determine if the move had moved a package so that can be undone too.
        if prevMove =~ "p$"
            " if we pushed a package, the man's position is where the package was
            let oldPkgPos = b:manPos
            let currPkgPos = <SID>SubtractVectors(b:manPos, delta)
            let b:pushes = b:pushes - 1
            call <SID>UpdatePackageList(currPkgPos, oldPkgPos)
        else
            let oldPkgPos = []
            let currPkgPos = b:manPos
        endif
        setlocal modifiable
        " this is abusing this function a little :)
        call <SID>MoveMan(currPkgPos, newManPos, oldPkgPos)
        let b:manPos = newManPos
        let b:moves = b:moves - 1
        call <SID>UpdateHeader()
        setlocal nomodifiable
    endif
endfunction

function! <SID>SetupMaps(enable)   "{{{1
    " About...   {{{2
    " Function : SetupMaps (PRIVATE
    " Purpose  : Sets up the various maps to control the movement of the game
    " Args     : enable - if 0, turn off movement maps; otherwise, turn them on.
    " Returns  : nothing
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    if a:enable
        nnoremap <silent> <buffer> h       :call <SID>MakeMove([0, -1], "h")<CR>
        nnoremap <silent> <buffer> <Left>  :call <SID>MakeMove([0, -1], "h")<CR>
        nnoremap <silent> <buffer> j       :call <SID>MakeMove([1, 0], "j")<CR>
        nnoremap <silent> <buffer> <Down>  :call <SID>MakeMove([1, 0], "j")<CR>
        nnoremap <silent> <buffer> k       :call <SID>MakeMove([-1, 0], "k")<CR>
        nnoremap <silent> <buffer> <Up>    :call <SID>MakeMove([-1, 0], "k")<CR>
        nnoremap <silent> <buffer> l       :call <SID>MakeMove([0, 1], "l")<CR>
        nnoremap <silent> <buffer> <Right> :call <SID>MakeMove([0, 1], "l")<CR>
        nnoremap <silent> <buffer> u       :call <SID>UndoMove()<CR>
    else
        nnoremap <buffer> h       <Nop>
        nnoremap <buffer> <Left>  <Nop>
        nnoremap <buffer> j       <Nop>
        nnoremap <buffer> <Down>  <Nop>
        nnoremap <buffer> k       <Nop>
        nnoremap <buffer> <Up>    <Nop>
        nnoremap <buffer> l       <Nop>
        nnoremap <buffer> <Right> <Nop>
        nnoremap <buffer> u       <Nop>
    endif
    nnoremap <silent> <buffer> r       :call Sokoban("", b:level)<CR>
    nnoremap <silent> <buffer> n       :call Sokoban("", b:level + 1)<CR>
    nnoremap <silent> <buffer> p       :call Sokoban("", b:level - 1)<CR>
endfunction

function! <SID>LoadScoresFile()   "{{{1
    " About...   {{{2
    " Function : LoadScoresFile (PRIVATE
    " Purpose  : loads the highscores file if it exists. Determines the last
    "            level played. The contents of the highscore file end up in the
    "            b:scores variable.
    " Args     : none
    " Returns  : the last level played.
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    if filereadable(g:SokobanScoreFile)
        execute "let b:scores = " . readfile(g:SokobanScoreFile)[0]
        return b:scores['current']
    else
        let b:scores = {}
        return 0
    endif
endfunction

function! <SID>SaveScoresToFile()   "{{{1
    " About...   {{{2
    " Function : SaveScoresToFile (PRIVATE
    " Purpose  : saves the current scores to the highscores file.
    " Args     : none
    " Returns  : nothing
    " Notes    : call by silent! call SaveScoresToFile()
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    call writefile([string(b:scores)], g:SokobanScoreFile)
endfunction

function! <SID>GetCurrentHighScores(level)   "{{{1
    " About...   {{{2
    " Function : GetCurrentHighScores (PRIVATE)
    " Purpose  : determines the high scores for a particular level. This is a
    "            little tricky as there are two high scores possible for each
    "            level. One for the pushes and one for the moves. This function
    "            detemines both and maintains the information for both
    " Args     : level - the level to determine the high scores
    " Returns  : nothing, sets alot of buffer variables though
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    let b:fewestMoves = ''
    let b:fewestPushes = ''
    if has_key(b:scores,a:level)
        let best = b:scores[a:level]
        let b:fewestMoves = '*'.best['fewestMoves']['moves'].', '.best['fewestMoves']['pushes'].' '
        if has_key(best['fewestMoves'],'date')
            let b:fewestMoves = b:fewestMoves.'  '.best['fewestMoves']['date']
        endif
        if has_key(best,'fewestPushes')
            let b:fewestPushes = ' '.best['fewestPushes']['moves'].', '.best['fewestPushes']['pushes'].'*'
            if has_key(best['fewestPushes'],'date')
                let b:fewestPushes = b:fewestPushes.'  '.best['fewestPushes']['date']
            endif
        endif
    endif
endfunction

function! <SID>UpdateHighScores()   "{{{1
    " About...   {{{2
    " Function : UpdateHighScores (PRIVATE
    " Purpose  : Determines if a highscore has been beaten, and if so saves it to
    "            the highscores file
    " Args     : none.
    " Returns  : nothing
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    if !has_key(b:scores,b:level)
        let b:scores[b:level] = {}
    endif
    if !has_key(b:scores[b:level],'fewestMoves')
        let b:scores[b:level]['fewestMoves'] = {'seq':'','moves':999999999,'pushes':999999999}
    endif
    if !has_key(b:scores[b:level],'fewestPushes')
        let b:scores[b:level]['fewestPushes'] = b:scores[b:level]['fewestMoves']
    endif

    let thisGame = { 'moves':b:moves, 'pushes':b:pushes,
                   \ 'seq':substitute(join(reverse(copy(b:undoList)),''),'p','','g'),
                   \ 'date':strftime("%Y-%m-%d %T") }

    if (b:moves < b:scores[b:level]['fewestMoves']['moves']) ||
     \ (b:moves == b:scores[b:level]['fewestMoves']['moves'] && b:pushes < b:scores[b:level]['fewestMoves']['pushes'])
        let b:scores[b:level]['fewestMoves'] = thisGame
    endif

    if (b:pushes < b:scores[b:level]['fewestPushes']['pushes']) ||
     \ (b:pushes == b:scores[b:level]['fewestPushes']['pushes'] && b:moves < b:scores[b:level]['fewestPushes']['moves'])
        let b:scores[b:level]['fewestPushes'] = thisGame
    endif

    if b:scores[b:level]['fewestMoves']['moves'] == b:scores[b:level]['fewestPushes']['moves'] &&
     \ b:scores[b:level]['fewestMoves']['pushes'] == b:scores[b:level]['fewestPushes']['pushes']
        call remove(b:scores[b:level], 'fewestPushes')
    endif
    call <SID>SaveScoresToFile()
endfunction

function! <SID>SaveCurrentLevelToFile(level)   "{{{1
    " About...   {{{2
    " Function : SaveCurrentLevelToFile (PRIVATE)
    " Purpose  : saves the current level to the high scores file.
    " Args     : level - the level number to save to the file
    " Returns  : nothing
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    let b:scores['current'] = a:level
    call <SID>SaveScoresToFile()
endfunction

function! <SID>FindOrCreateBuffer(filename, doSplit)   "{{{1
    " About...   {{{2
    " Function : FindOrCreateBuffer (PRIVATE)
    "            Checks the window list for the buffer. If the buffer is in an
    "            already open window, it switches to the window. If the buffer
    "            was not in a window, it switches to that buffer. If the buffer did
    "            not exist, it creates it.
    " Args     : filename (IN) -- the name of the file
    "            doSplit (IN) -- indicates whether the window should be split
    "                            ("v", "h", "")
    " Returns  : nothing
    " Author   : Michael Sharpe <feline@irendi.com>   }}}
    " Check to see if the buffer is already open before re-opening it.
    let bufName = bufname(a:filename)
    if (bufName == "")
        " Buffer did not exist....create it
        if (a:doSplit == "h")
            execute ":split " . a:filename
        elseif (a:doSplit == "v")
            execute ":vsplit " . a:filename
        else
            execute ":e " . a:filename
        endif
    else
        " Buffer was already open......check to see if it is in a window
        let bufWindow = bufwinnr(a:filename)
        if (bufWindow == -1)
            if (a:doSplit == "h")
                execute ":sbuffer " . a:filename
            elseif (a:doSplit == "v")
                execute ":vert sbuffer " . a:filename
            else
                execute ":buffer " . a:filename
            endif
        else
            " search the windows for the target window
            if bufWindow != winnr()
                " only search if the current window does not contain the buffer
                execute "normal \<C-W>b"
                let winNum = winnr()
                while (winNum != bufWindow && winNum > 0)
                    execute "normal \<C-W>k"
                    let winNum = winNum - 1
                endwhile
                if (0 == winNum)
                    " something wierd happened...open the buffer
                    if (a:doSplit == "h")
                        execute ":split " . a:filename
                    elseif (a:doSplit == "v")
                        execute ":vsplit " . a:filename
                    else
                        execute ":e " . a:filename
                    endif
                endif
            endif
        endif
    endif
endfunction

function! Sokoban(splitWindow, ...)   "{{{1
    " About...   {{{2
    " Function : Sokoban (PUBLIC)
    " Purpose  : This is the entry point to the game. It create the buffer, loads
    "            the level, and sets the game up.
    " Args     : splitWindow - indicates how to split the window
    "            level (optional) - specifies the start level
    " Returns  : nothing
    " Author   : Michael Sharpe (feline@irendi.com)   }}}
    if (a:0 == 0)
        let level = 1
    else
        let level = a:1 <= 0 ? 1 : a:1
    endif
    call <SID>FindOrCreateBuffer('__\.\#\$VimSokoban\$\#\.__', a:splitWindow)
    setlocal modifiable
    call <SID>ClearBuffer()
    let savedLevel = <SID>LoadScoresFile()
    " if there was a saved level and the level was not specified use it now
    if (a:0 == 0 && savedLevel != 0)
        let level = savedLevel
    endif
    let b:moves = 0        " counter of number of moves made
    let b:pushes = 0       " counter of number of pushes made
    call <SID>GetCurrentHighScores(level)
    call <SID>DisplayInitialHeader(level)
    call <SID>LoadLevel(level)
    setlocal nomodifiable
    call <SID>SetupMaps(1)
    " do something with the cursor....
    normal 1G
    normal 0
endfunction

" vim: foldmethod=marker
