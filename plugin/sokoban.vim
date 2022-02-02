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

" Initial setup   {{{1
" Allow the user to specify the location of the sokoban levels
let g:SokobanLevelDirectory = get(g:,'SokobanLevelDirectory',resolve(fnamemodify(expand('<sfile>:p:h') . '/../levels/','p:')))
if !isdirectory(g:SokobanLevelDirectory)
    echoerr 'g:SokobanLevelDirectory ('.g:SokobanLevelDirectory.') contains an invalid path.'
    finish
endif

" Allow the user to specify the location of the score file.
let g:SokobanScoreFile = get(g:,'SokobanScoreFile',resolve(expand('<sfile>:p:h') . '/../.VimSokobanScores'))

" Characters used to draw the maze and objects on the screen.
let g:charSoko        = get(g:,'charSoko',       '◆') " replaces @ in level file
let g:charWall        = get(g:,'charWall',       '█') " replaces # in level file
let g:charPackage     = get(g:,'charPackage',    '☻') " replaces $ in level file
let g:charHome        = get(g:,'charHome',       '○') " replaces . in level file
let g:charPackageHome = get(g:,'charPackageHome','●') " replaces * in level file

command! -nargs=? Sokoban call Sokoban('e', <f-args>)
command! -nargs=? SokobanH call Sokoban('h', <f-args>)
command! -nargs=? SokobanV call Sokoban('v', <f-args>)

function! s:ClearBuffer()   " clears the buffer of all characters {{{1
    normal! 1GdG
endfunction

function! s:BoardSize()   " Returns a dictionary of game board dimensions, a minimum of 51 columns and 30 lines. {{{1
    return {'maxWidth': max([51, empty(b:levelSet) ? 0 : b:levelSet.maxWidth]),
         \  'maxHeight': max([30, empty(b:levelSet) ? 0 : b:levelSet.maxHeight])}
endfunction

function! s:DrawGameBoard(level)   " Draws the game board in the buffer. {{{1
    let maxWidth = s:BoardSize().maxWidth
    call s:ClearBuffer()
    call append(0, repeat([''],s:BoardSize().maxHeight))
    call setline( 1,       '    ╭───────────────────╮    ' . repeat(' ',maxWidth))
    call setline( 2,       '╔═══╡ VIM SOKOBAN, v2.0 ╞═══╗' . repeat(' ',maxWidth))
    call setline( 3,       '║   ╰───────────────────╯   ║' . repeat(' ',maxWidth))
    call setline( 4,       '║ Set:                      ║' . repeat(' ',maxWidth))
    call setline( 5,       '║ Level #:                  ║' . repeat(' ',maxWidth))
    call setline( 6,       '║ Name:                     ║' . repeat(' ',maxWidth))
    call setline( 7,       '║                           ║' . repeat(' ',maxWidth))
    call setline( 8,       '║ Score:                    ║' . repeat(' ',maxWidth))
    call setline( 9,       '║     0 moves      0 pushes ║' . repeat(' ',maxWidth))
    call setline(10,       '╠═══════════════════════════╣' . repeat(' ',maxWidth))
    call setline(11,       '║ Fewest Moves:             ║' . repeat(' ',maxWidth))
    call setline(12,       '║       moves        pushes ║' . repeat(' ',maxWidth))
    call setline(13,       '║                           ║' . repeat(' ',maxWidth))
    call setline(14,       '║                           ║' . repeat(' ',maxWidth))
    call setline(15,       '║ Fewest Pushes:            ║' . repeat(' ',maxWidth))
    call setline(16,       '║       moves        pushes ║' . repeat(' ',maxWidth))
    call setline(17,       '║                           ║' . repeat(' ',maxWidth))
    call setline(18,       '╠═══════════════════════════╣' . repeat(' ',maxWidth))
    call setline(19,printf('║ Legend:  %s     Player     ║', g:charSoko) . repeat(' ',maxWidth))
    call setline(20,printf('║         %s %s    Package    ║', g:charPackage, g:charPackageHome) . repeat(' ',maxWidth))
    call setline(21,printf('║          %s     Wall       ║', g:charWall) . repeat(' ',maxWidth))
    call setline(22,printf('║          %s     Home       ║', g:charHome) . repeat(' ',maxWidth))
    call setline(23,       '║                           ║' . repeat(' ',maxWidth))
    call setline(24,       '║ Keys: h j k l  Move       ║' . repeat(' ',maxWidth))
    call setline(25,       '║          u     Undo       ║' . repeat(' ',maxWidth))
    call setline(26,       '║          r     Restart    ║' . repeat(' ',maxWidth))
    call setline(27,       '║          n     Next Level ║' . repeat(' ',maxWidth))
    call setline(28,       '║          p     Prev Level ║' . repeat(' ',maxWidth))
    call setline(29,       '║          c     Choose Set ║' . repeat(' ',maxWidth))
    let l = 30
    while l < s:BoardSize().maxHeight
        call setline(l,    '║                           ║' . repeat(' ',maxWidth))
        let l += 1
    endwhile
    call setline(l,        '╚═══════════════════════════╝' . repeat(' ',maxWidth))
    call s:UpdateHeader(a:level)
    call s:LoadLevel(a:level)
endfunction

function! s:ScrollText(text, width, increment)
    let s:scroll = get(s:, 'scroll', -1) + a:increment
    let divisor = max([0, strchars(a:text) - a:width + 15])
    let l:text = strcharpart('⚅⚅⚅⚅⚅'.a:text, s:scroll % divisor)
    return strcharpart(substitute(l:text, '⚅', '', 'g'), 0, a:width)
endfunction

function! s:UpdateHeader(level)   " Update the moves and the push scores in the header {{{1
    call s:ReplaceTextInLine([ 4,0], printf('║ Set: %-20s ║', s:ScrollText(b:levelSet.title, 20, 1)))
    call s:ReplaceTextInLine([ 5,0], printf('║ Level #: %-5d            ║', a:level))
    call s:ReplaceTextInLine([ 6,0], printf('║ Name: %-19s ║', s:ScrollText(b:levelSet.levels[a:level-1].id, 19, 0)))
    call s:ReplaceTextInLine([ 9,0], printf('║ %5s moves  %5s pushes ║',b:moves,b:pushes))
    call s:ReplaceTextInLine([12,0], printf('║ %5s moves  %5s pushes ║',b:fewestMovesMoves,b:fewestMovesPushes))
    call s:ReplaceTextInLine([13,0], printf('║ %25s ║',                 b:fewestMovesDate))
    call s:ReplaceTextInLine([16,0], printf('║ %5s moves  %5s pushes ║',b:fewestPushesMoves,b:fewestPushesPushes))
    call s:ReplaceTextInLine([17,0], printf('║ %25s ║',                 b:fewestPushesDate))
endfunction

function! s:UpdateFooter() " updates the sequence of moves in the footer {{{1
    call deletebufline(bufname('%'),s:startSequence+1,'$')
    call append(line('$'), split(s:CompressMoves(), '.\{80}\zs'))
endfunction

function! s:DisplayLevelCompleteMessage()   " Display the message indicating that the level has been completed {{{1
    let msg = ['╭──────────────────────────────────╮',
             \ '│ ╭──────────────────────────────╮ │',
             \ '│ │        LEVEL COMPLETE        │ │',
             \ '│ │                              │ │',
      \ printf('│ │         %6d Moves         │ │', b:moves),
      \ printf('│ │         %6d Pushes        │ │', b:pushes),
             \ '│ │                              │ │',
             \ '│ ╰──────────────────────────────╯ │',
             \ '╰──────────────────────────────────╯']
    let left = 30 + (s:BoardSize().maxWidth - max(map(copy(msg),{_,l -> strchars(l)}))) / 2
    let top = (s:BoardSize().maxHeight - len(msg))/2
    for l in range(len(msg))
        call s:ReplaceTextInLine([l+top,left], msg[l])
    endfor
endfunction

function! s:ProcessLevel(room, top, left)   " Processes a level and populates the object lists and sokoban man position. {{{1
    let b:wallList = []    " list of all wall locations
    let b:homeList = []    " list of all home square locations
    let b:packageList = [] " list of all package locations
    let b:undoList = []    " list of current moves (used for the undo move feature)

    for l in range(len(a:room))
        for c in range(strchars(a:room[l]))
            let ch = strcharpart(a:room[l], c, 1)
            let location = [l+a:top,c+a:left]
            if (ch == '#')
                call add(b:wallList, location)
            elseif (ch == '.')
                call add(b:homeList, location)
            elseif (ch == '*')
                call add(b:homeList, location)
                call add(b:packageList, location)
            elseif (ch == '$')
                call add(b:packageList, location)
            elseif (ch == '@')
                let b:manPos = location
            endif
        endfor
    endfor
endfunction

    " About...   {{{2
    " Purpose  : loads the level pack JSON file into memory.
function! s:LoadLevelSet()   " Load the JSON file into memory. It contains all levels in the set. {{{1
    let levelFile = g:SokobanLevelDirectory . '/Original.json'
    if filereadable(levelFile)
        let b:levelSet = eval(join(readfile(levelFile),''))
    else
        let b:levelSet = {}
    endif
endfunction

function! s:LoadLevel(level)   " Loads the level and sets up the syntax highlighting for the file {{{1
    if a:level <= len(b:levelSet.levels)
        let level = b:levelSet.levels[a:level-1]
        let left = 29 + (s:BoardSize().maxWidth-level.width) / 2
        let top = max([1,(s:BoardSize().maxHeight-level.height)/2])
        call s:ProcessLevel(level.room, top, left)

        setlocal modifiable
        for l in range(level.height)
            let roomline = level.room[l]
            let roomline = substitute(roomline, '\V@', g:charSoko, 'g')
            let roomline = substitute(roomline, '\V#', g:charWall, 'g')
            let roomline = substitute(roomline, '\V$', g:charPackage, 'g')
            let roomline = substitute(roomline, '\V.', g:charHome, 'g')
            let roomline = substitute(roomline, '\V*', g:charPackageHome, 'g')
            call s:ReplaceTextInLine([l+top,left], roomline)
        endfor

        let b:level = a:level
        let s:startSequence = line('$')

        call s:SaveCurrentLevelToFile(a:level)
        setlocal buftype=nofile filetype=vimsokoban
        setlocal nomodifiable
        setlocal nolist nonumber nowrap signcolumn=no
    else
        let b:level = 0
    endif
endfunction

function! s:ReplaceTextInLine(cell, text)   " Puts text at a specific position in the buffer {{{1
    let [theLine,theCol] = a:cell
    let ln = getline(theLine)
    let leftStr = strcharpart(ln, 0, theCol)
    let rightStr = strcharpart(ln, theCol + strchars(a:text))
    let ln = leftStr . a:text . rightStr
    call setline(theLine, ln)
endfunction

function! s:IsWall(cell)   " Determines whether the specified cell corresponds to a wall {{{1
    return index(b:wallList, a:cell) >= 0
endfunction

function! s:IsHome(cell)   " Determines whether the specified (line, column) pair corresponds {{{1
    return index(b:homeList, a:cell) >= 0
endfunction

function! s:IsPackage(cell)   " Determines whether the specified cell corresponds to a package {{{1
    return index(b:packageList, a:cell) >= 0
endfunction

function! s:IsEmpty(cell)   " Determines whether the specified cell corresponds to empty space in the maze {{{1
    return !s:IsWall(a:cell) && !s:IsPackage(a:cell)
endfunction

function! s:Move(from, to, item)   " Moves the item (man or package) in the buffer. Home squares are handled correctly in this function too. {{{1
    if s:IsHome(a:from)
        call s:ReplaceTextInLine(a:from, g:charHome)
    else
        call s:ReplaceTextInLine(a:from, ' ')
    endif
    call s:ReplaceTextInLine(a:to, a:item)
endfunction

function! s:UpdatePackageList(old, new)   " Updates the package list when a package is moved {{{1
    call remove(b:packageList, index(b:packageList, a:old))
    call add(b:packageList, a:new)
endfunction

function! s:AreAllPackagesHome()   " Determines if all packages have been placed in the home area {{{1
    for pkg in b:packageList
        if !s:IsHome(pkg)
            return 0
        endif
    endfor
    return 1
endfunction

function! s:AddVectors(x, y)   " Adds two vectors (lists) together. {{{1
    return [a:x[0]+a:y[0], a:x[1]+a:y[1]]
endfunction

function! s:SubtractVectors(x, y)   " Subtracts two vectors (lists) together. {{{1
    return [a:x[0]-a:y[0], a:x[1]-a:y[1]]
endfunction

function! s:MakeMove(delta, moveDirection)   " This is the core function which is called when a move is made. {{{1
    let newManPos = s:AddVectors(b:manPos, a:delta)
    if s:IsWall(newManPos)
        return
    endif

    setlocal modifiable
    let undo = a:moveDirection

    if s:IsPackage(newManPos)
        let newPkgPos = s:AddVectors(newManPos, a:delta)
        if !s:IsEmpty(newPkgPos)
            return
        endif

        call s:Move(newManPos, newPkgPos, s:IsHome(newPkgPos) ? g:charPackageHome : g:charPackage)
        call s:UpdatePackageList(newManPos, newPkgPos)
        let b:pushes = b:pushes + 1
        let undo .= 'p'
    endif

    call s:Move(b:manPos, newManPos, g:charSoko)
    call insert(b:undoList, undo)
    let b:moves = b:moves + 1
    let b:manPos = newManPos
    call s:UpdateHeader(b:level)
    call s:UpdateFooter()

    if s:AreAllPackagesHome()
        call s:SetupMaps(0)
        call s:DisplayLevelCompleteMessage()
        call s:UpdateHighScores()
        call s:SaveCurrentLevelToFile(b:level + 1)
    endif

    setlocal nomodifiable
endfunction

function! s:UndoMove()   " Called when the u key is hit to handle the undo move operation. {{{1
    if !empty(b:undoList)
        let prevMove = b:undoList[0]
        call remove(b:undoList, 0)

        setlocal modifiable

        " determine which direction un-does the move
        let delta = {'h':[0,1],'j':[-1,0],'k':[1,0],'l':[0,-1]}[prevMove[0]]

        let priorManPos = s:AddVectors(b:manPos, delta)
        call s:Move(b:manPos, priorManPos, g:charSoko)
        if prevMove =~ 'p$'
            let currPkgPos = s:SubtractVectors(b:manPos, delta)
            call s:Move(currPkgPos, b:manPos, s:IsHome(b:manPos) ? g:charPackageHome : g:charPackage)
            let b:pushes = b:pushes - 1
            call s:UpdatePackageList(currPkgPos, b:manPos)
        endif

        let b:manPos = priorManPos
        let b:moves = b:moves - 1
        call s:UpdateHeader(b:level)
        call s:UpdateFooter()
        setlocal nomodifiable
    endif
endfunction

function! s:SetupMaps(enable)   " Sets up the various maps to control the movement of the game. {{{1
    if a:enable
        nnoremap <silent> <buffer> h       :call <SID>MakeMove([0, -1], 'h')<CR>
        nnoremap <silent> <buffer> <Left>  :call <SID>MakeMove([0, -1], 'h')<CR>
        nnoremap <silent> <buffer> j       :call <SID>MakeMove([1, 0], 'j')<CR>
        nnoremap <silent> <buffer> <Down>  :call <SID>MakeMove([1, 0], 'j')<CR>
        nnoremap <silent> <buffer> k       :call <SID>MakeMove([-1, 0], 'k')<CR>
        nnoremap <silent> <buffer> <Up>    :call <SID>MakeMove([-1, 0], 'k')<CR>
        nnoremap <silent> <buffer> l       :call <SID>MakeMove([0, 1], 'l')<CR>
        nnoremap <silent> <buffer> <Right> :call <SID>MakeMove([0, 1], 'l')<CR>
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

function! s:LoadScoresFile()   " Loads the highscores file if it exists. Determines the last level played. {{{1
    if filereadable(g:SokobanScoreFile)
        let b:scores = eval(join(readfile(g:SokobanScoreFile),''))
        return b:scores['current']
    else
        let b:scores = {}
        return 0
    endif
endfunction

function! s:SaveScoresToFile()   " Saves the current scores to the highscores file. {{{1
    call writefile([json_encode(b:scores)], g:SokobanScoreFile)
endfunction

function! s:GetCurrentHighScores(level)   " Determines the high scores for a particular level. {{{1
    " This is a little tricky as there are two high scores possible for each
    " level. One for the pushes and one for the moves. This function detemines
    " both and maintains the information for both
    let b:fewestMovesDate = ''
    let b:fewestMovesMoves = ''
    let b:fewestMovesPushes = ''
    let b:fewestPushesDate = ''
    let b:fewestPushesMoves = ''
    let b:fewestPushesPushes = ''
    if has_key(b:scores,a:level)
        let best = b:scores[a:level]
        let b:fewestMovesMoves = best['fewestMoves']['moves']
        let b:fewestMovesPushes = best['fewestMoves']['pushes']
        if has_key(best['fewestMoves'],'date')
            let b:fewestMovesDate = best['fewestMoves']['date']
        endif
        if has_key(best,'fewestPushes')
        let b:fewestPushesMoves = best['fewestPushes']['moves']
        let b:fewestPushesPushes = best['fewestPushes']['pushes']
            if has_key(best['fewestPushes'],'date')
                let b:fewestPushesDate = best['fewestPushes']['date']
            endif
        endif
    endif
endfunction

function! s:UpdateHighScores()   " Determines if a highscore has been beaten, and if so saves it to the highscores file. {{{1
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
                   \ 'seq':s:CompressMoves(),
                   \ 'date':strftime('%Y-%m-%d %T') }

    if (b:moves <= b:scores[b:level]['fewestMoves']['moves']) ||
     \ (b:moves == b:scores[b:level]['fewestMoves']['moves'] && b:pushes <= b:scores[b:level]['fewestMoves']['pushes'])
        let b:scores[b:level]['fewestMoves'] = thisGame
    endif

    if (b:pushes <= b:scores[b:level]['fewestPushes']['pushes']) ||
     \ (b:pushes == b:scores[b:level]['fewestPushes']['pushes'] && b:moves <= b:scores[b:level]['fewestPushes']['moves'])
        let b:scores[b:level]['fewestPushes'] = thisGame
    endif

    if b:scores[b:level]['fewestMoves']['moves'] == b:scores[b:level]['fewestPushes']['moves'] &&
     \ b:scores[b:level]['fewestMoves']['pushes'] == b:scores[b:level]['fewestPushes']['pushes']
        call remove(b:scores[b:level], 'fewestPushes')
    endif
    call s:SaveScoresToFile()
endfunction

function! s:CompressMoves()   " Compresses the sequence of moves using run-length-encoding. {{{1
    let moves = substitute(join(reverse(copy(b:undoList)),''),'p','','g')
    for direction in ['h','j','k','l']
        for count in range(9,2,-1)
            while match(moves, repeat(direction, count)) > -1
                let moves = substitute(moves, repeat(direction, count), count.direction.' ', 'g')
            endwhile
        endfor
    endfor
    return substitute(moves, ' ', '', 'g')
endfunction

function! s:SaveCurrentLevelToFile(level)   " Saves the current level to the high scores file. {{{1
    let b:scores['current'] = a:level
    call s:SaveScoresToFile()
endfunction

function! s:FindOrCreateBuffer(doSplit)   " Create or go to the window containing the VimSokoban buffer. {{{1
    let filename = '_.#VimSokoban#._'
    let bufNum = bufnr(filename, 1)
    let winNum = bufwinnr(filename)
    if (winNum == -1)
        execute {'h': 'sbuffer', 'v':'vert sbuffer', 'e':'buffer'}[a:doSplit] . filename
    else
        execute winNum.'wincmd w'
    endif
endfunction

function! Sokoban(splitWindow, ...)   " This is the entry point to the game. {{{1
    call s:FindOrCreateBuffer(a:splitWindow)
    setlocal modifiable
    call s:ClearBuffer()
    let lastRecordedLevel = s:LoadScoresFile()
    let level = max([1, a:0 ? a:1 : lastRecordedLevel])
    call s:GetCurrentHighScores(level)
    let b:moves = 0        " counter of number of moves made
    let b:pushes = 0       " counter of number of pushes made
    call s:LoadLevelSet()
    call s:DrawGameBoard(level)
    setlocal nomodifiable
    call s:SetupMaps(1)
    " do something with the cursor....
    normal! 1G0
endfunction

" vim: foldmethod=marker
