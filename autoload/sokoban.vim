let s:panelWidth = 26

function! s:BoardSize()   " Returns a dictionary of game board dimensions. {{{1
    return {'maxWidth': max([winwidth(0)-s:panelWidth, empty(b:levelSet) ? 0 : b:levelSet.maxWidth]),
         \  'maxHeight': max([22, empty(b:levelSet) ? 0 : b:levelSet.maxHeight])}
endfunction

function! s:DrawGameBoard()   " Draws the game board in the buffer. {{{1
    let board = s:BoardSize()
    if board.maxWidth + s:panelWidth > winwidth(0) || board.maxHeight > winheight(0)
        echomsg 'Your window is too small to display the entire board.'
        echomsg 'Try resizing the window or using a smaller text size.'
    endif

    setlocal modifiable
    silent normal! 1GdG
    call append(0, repeat([''],board.maxHeight))
    call setline( 1,       ' ╞═╡ VIM SOKOBAN, v2.0 ╞═╗' . repeat(' ',board.maxWidth))
    call setline( 2,       '─╯ ╰───────────────────╯ ║' . repeat(' ',board.maxWidth))
    call setline( 3,       'Set:                     ║' . repeat(' ',board.maxWidth))
    call setline( 4,       'Level:                   ║' . repeat(' ',board.maxWidth))
    call setline( 5,       'Score:═══════════════════╣' . repeat(' ',board.maxWidth))
    call setline( 6,       '    0 moves      0 pushes║' . repeat(' ',board.maxWidth))
    call setline( 7,       'Fewest Moves:════════════╣' . repeat(' ',board.maxWidth))
    call setline( 8,       '      moves        pushes║' . repeat(' ',board.maxWidth))
    call setline( 9,       '                         ║' . repeat(' ',board.maxWidth))
    call setline(10,       'Fewest Pushes:═══════════╣' . repeat(' ',board.maxWidth))
    call setline(11,       '      moves        pushes║' . repeat(' ',board.maxWidth))
    call setline(12,       '                         ║' . repeat(' ',board.maxWidth))
    call setline(13,       'Legend:══════════════════╣' . repeat(' ',board.maxWidth))
    call setline(14,printf('  %s %s Package   %s Home   ║', g:charPackage, g:charPackageAtHome, g:charHome) . repeat(' ',board.maxWidth))
    call setline(15,printf('  %s   Player    %s Wall   ║', g:charSoko, g:charWall) . repeat(' ',board.maxWidth))
    call setline(16,       'Keys:════════════════════╣' . repeat(' ',board.maxWidth))
    let l = 17
    while l < board.maxHeight
        call setline(l,    '                         ║' . repeat(' ',board.maxWidth))
        let l += 1
    endwhile
    call setline(l,        '═════════════════════════╩' . repeat('═',board.maxWidth))
    call setline(l+1,      'Sequence:')
    setlocal nomodifiable

    call s:UpdatePanel(1)
    call s:LoadLevel()
endfunction

function! s:Marquee(text, width, increment)   " Scroll long text within a given width. {{{1
    let s:marqueeOffset += a:increment

    if strchars(a:text) <= a:width
        return a:text
    endif

    let delay = 7
    let divisor = strchars(a:text)+(delay+1)
    let l:text = strcharpart(repeat("\x07",delay).a:text, s:marqueeOffset % divisor)
    let l:text = substitute(l:text, "\x07", '', 'g')
    if strchars(l:text) > a:width
        return strcharpart(l:text, 0, a:width-1) . '…'
    else
        return strcharpart(l:text, 0, a:width)
    endif
endfunction

function! s:UpdatePanel(gameInProgress = 1)   " Update the moves and the push scores in the header {{{1
    let levelName = b:levelSet.levels[b:currentLevel-1].id
    let displayLevel = b:currentLevel . (string(b:currentLevel) == levelName ? '' : ': '.levelName)
    call s:ReplaceTextAt([ 3,0], printf('Set: %-20s║',           s:Marquee(b:levelSet.title, 20, 1)))
    call s:ReplaceTextAt([ 4,0], printf('Level: %-18s║'         ,s:Marquee(displayLevel,18, 0)))
    call s:ReplaceTextAt([ 6,0], printf('%5s moves  %5s pushes║',b:moves,b:pushes))
    call s:ReplaceTextAt([ 8,0], printf('%5s moves  %5s pushes║',b:fewestMovesMoves,b:fewestMovesPushes))
    call s:ReplaceTextAt([ 9,0], printf('%25s║',                 b:fewestMovesDate))
    call s:ReplaceTextAt([11,0], printf('%5s moves  %5s pushes║',b:fewestPushesMoves,b:fewestPushesPushes))
    call s:ReplaceTextAt([12,0], printf('%25s║',                 b:fewestPushesDate))
    call s:ReplaceTextAt([17,0], a:gameInProgress ? '  h j k l Move           ║' : '  r       Restart        ║')
    call s:ReplaceTextAt([18,0], a:gameInProgress ? '  u r     Undo/Restart   ║' : '  s       Pick a Set     ║')
    call s:ReplaceTextAt([19,0], a:gameInProgress ? '  s       Pick a Set     ║' : '  0-9     Pick a Level   ║')
    call s:ReplaceTextAt([20,0], a:gameInProgress ? '  0-9     Pick a Level   ║' : '  n p     Next/Prev Level║')
    call s:ReplaceTextAt([21,0], a:gameInProgress ? '  n p     Next/Prev Level║' : '                         ║' )
endfunction

function! s:UpdateFooter() " Updates the sequence of moves in the footer {{{1
    setlocal modifiable
    let board = s:BoardSize()
    call deletebufline(bufname('%'),board.maxHeight+1,'$')
    call append(line('$'), split('Sequence: '.s:CompressMoves(), '.\{'.(s:panelWidth+board.maxWidth).'}\zs'))
    setlocal nomodifiable
endfunction

function! s:DisplayLevelCompleteMessage()   " Display the message indicating that the level has been completed {{{1
    let msg = ['╔═════════════════════╗',
             \ '║   LEVEL COMPLETE!   ║',
             \ '╚═════════════════════╝']
    let board = s:BoardSize()
    let left = s:panelWidth + (board.maxWidth - max(map(copy(msg),{_,l -> strchars(l)}))) / 2
    for l in range(len(msg))
        call s:ReplaceTextAt([l+1,left], msg[l])
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
            elseif (ch == '@')
                let b:manPos = location
            elseif (ch == '+')
                let b:manPos = location
                call add(b:homeList, location)
            elseif (ch == '.')
                call add(b:homeList, location)
            elseif (ch == '*')
                call add(b:homeList, location)
                call add(b:packageList, location)
            elseif (ch == '$')
                call add(b:packageList, location)
            endif
        endfor
    endfor
endfunction

function! s:SelectLevelByNumber(num)   " {{{1
    let s:levelSearch = get(s:, 'levelSearch', 0)*10 + a:num
    while s:levelSearch > len(b:levelSet.levels)
        let s:levelSearch = str2nr(string(s:levelSearch)[1:])
    endwhile
    call sokoban#PlaySokoban('', s:levelSearch)
endfunction

function! s:LoadLevelSet()   " Load the JSON file into memory. It contains all levels in the set. {{{1
    let levelFile = g:SokobanLevelDirectory . '/' . b:currentSet . '.json'
    if filereadable(levelFile)
        let b:levelSet = eval(join(readfile(levelFile),''))
    else
        let b:levelSet = {}
    endif
endfunction

function! s:LoadLevel()   " Loads the level and sets up the syntax highlighting for the file {{{1
    let level = b:levelSet.levels[b:currentLevel-1]

    let board = s:BoardSize()
    let left = s:panelWidth + (board.maxWidth-level.width) / 2
    let top = max([1,(board.maxHeight-level.height)/2])
    call s:ProcessLevel(level.room, top, left)

    for l in range(level.height)
        let roomline = level.room[l]
        let roomline = substitute(roomline, '\V@', g:charSoko, 'g')
        let roomline = substitute(roomline, '\V+', g:charSoko, 'g')
        let roomline = substitute(roomline, '\V#', g:charWall, 'g')
        let roomline = substitute(roomline, '\V$', g:charPackage, 'g')
        let roomline = substitute(roomline, '\V.', g:charHome, 'g')
        let roomline = substitute(roomline, '\V*', g:charPackageAtHome, 'g')
        call s:ReplaceTextAt([l+top,left], roomline)
    endfor

    setlocal buftype=nofile filetype=vimsokoban
    setlocal nolist nonumber nowrap signcolumn=no
endfunction

function! s:ReplaceTextAt(cell, text)   " Puts text at a specific position in the buffer {{{1
    let [theLine,theCol] = a:cell
    let ln = getline(theLine)
    let leftStr = strcharpart(ln, 0, theCol)
    let rightStr = strcharpart(ln, theCol + strchars(a:text))
    let ln = leftStr . a:text . rightStr
    setlocal modifiable
    call setline(theLine, ln)
    setlocal nomodifiable
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
        call s:ReplaceTextAt(a:from, g:charHome)
    else
        call s:ReplaceTextAt(a:from, ' ')
    endif
    call s:ReplaceTextAt(a:to, a:item)
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

        call s:Move(newManPos, newPkgPos, s:IsHome(newPkgPos) ? g:charPackageAtHome : g:charPackage)
        call s:UpdatePackageList(newManPos, newPkgPos)
        let b:pushes = b:pushes + 1
        let undo .= 'p'
    endif

    call s:Move(b:manPos, newManPos, g:charSoko)
    call insert(b:undoList, undo)
    let b:moves = b:moves + 1
    let b:manPos = newManPos
    call s:UpdatePanel(1)
    call s:UpdateFooter()

    if s:AreAllPackagesHome()
        call s:MapKeys(0)
        call s:DisplayLevelCompleteMessage()
        call s:UpdateHighScores()
        call s:WriteUserData()
        call s:GetCurrentHighScores()
        call s:UpdatePanel(0)
    endif

    setlocal nomodifiable
endfunction

function! s:UndoMove()   " Called when the u key is hit to handle the undo move operation. {{{1
    if !empty(b:undoList)
        let prevMove = b:undoList[0]
        call remove(b:undoList, 0)

        " Determine which direction un-does the move
        let delta = {'h':[0,1],'j':[-1,0],'k':[1,0],'l':[0,-1]}[prevMove[0]]

        let priorManPos = s:AddVectors(b:manPos, delta)
        call s:Move(b:manPos, priorManPos, g:charSoko)
        if prevMove =~ 'p$'
            let currPkgPos = s:SubtractVectors(b:manPos, delta)
            call s:Move(currPkgPos, b:manPos, s:IsHome(b:manPos) ? g:charPackageAtHome : g:charPackage)
            let b:pushes = b:pushes - 1
            call s:UpdatePackageList(currPkgPos, b:manPos)
        endif

        let b:manPos = priorManPos
        let b:moves = b:moves - 1
        call s:UpdatePanel(1)
        call s:UpdateFooter()
    endif
endfunction

function! s:MapKeys(gameInProgress)   " Sets up the various maps to control the movement of the game. {{{1
    if a:gameInProgress
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
    nnoremap <silent> <buffer> r :call sokoban#PlaySokoban('', b:currentLevel)<CR>
    nnoremap <silent> <buffer> n :call sokoban#PlaySokoban('', b:currentLevel + 1)<CR>
    nnoremap <silent> <buffer> p :call sokoban#PlaySokoban('', b:currentLevel - 1)<CR>
    nnoremap <silent> <buffer> s :call <SID>ChangeLevelSet()<CR>
    for key in range(10)
        execute "nnoremap <silent> <buffer> ".key." :call <SID>SelectLevelByNumber(".key.")<CR>"
    endfor
endfunction

function! s:ReadUserData()   " Loads the highscores file if it exists. Determines the last level played. {{{1
    if filereadable(g:SokobanScoreFile)
        let b:userData = json_decode(readfile(g:SokobanScoreFile))
        call s:MigrateUserData()
    else
        let b:userData = {'version':'2.0', 'currentSet':'Original', 'Original': {'currentLevel':1}}
    endif

    let b:currentSet = b:userData.currentSet
    let b:currentLevel = b:userData[b:currentSet].currentLevel
endfunction

function! s:WriteUserData()   " Saves the current scores to the highscores file. {{{1
    call writefile([json_encode(b:userData)], g:SokobanScoreFile)
endfunction

function! s:MigrateUserData()   " Migrate user data file to the current version. {{{1
    if !has_key(b:userData, 'version')
        let currentLevel=remove(b:userData, 'current')
        let b:userData = {'version':'2.0', 'currentSet':'Original', 'Original': extend(b:userData, {'currentLevel':currentLevel})}
        call s:WriteUserData()
    endif
endfunction

function! s:GetCurrentHighScores()   " Retrieves the high scores for the current level. {{{1
    let b:fewestMovesDate = ''
    let b:fewestMovesMoves = ''
    let b:fewestMovesPushes = ''
    let b:fewestPushesDate = ''
    let b:fewestPushesMoves = ''
    let b:fewestPushesPushes = ''

    if !has_key(b:userData[b:currentSet], b:currentLevel)
        return
    endif

    let best = b:userData[b:currentSet][b:currentLevel]
    let b:fewestMovesMoves = best.fewestMoves.moves
    let b:fewestMovesPushes = best.fewestMoves.pushes
    let b:fewestMovesDate = get(best.fewestMoves, 'date', '')

    call extend(best, {'fewestPushes':best.fewestMoves}, 'keep')
    let b:fewestPushesMoves = best.fewestPushes.moves
    let b:fewestPushesPushes = best.fewestPushes.pushes
    let b:fewestPushesDate = get(best.fewestPushes, 'date', '')
endfunction

function! s:UpdateHighScores()   " Determines if a highscore has been beaten, and if so saves it to the highscores file. {{{1
    " This is a little tricky as there are two high scores possible for each
    " level. One for the pushes and one for the moves.
    call extend(b:userData, {b:currentSet:{}}, 'keep')
    call extend(b:userData[b:currentSet], {b:currentLevel:{}}, 'keep')
    call extend(b:userData[b:currentSet][b:currentLevel], {'fewestMoves': {'seq':'','moves':999999999,'pushes':999999999}}, 'keep')
    call extend(b:userData[b:currentSet][b:currentLevel], {'fewestPushes': {'seq':'','moves':999999999,'pushes':999999999}}, 'keep')

    let thisGame = { 'moves':b:moves, 'pushes':b:pushes, 'seq':s:CompressMoves(), 'date':strftime('%Y-%m-%d %T') }
    let best = b:userData[b:currentSet][b:currentLevel]

    if (b:moves < best.fewestMoves.moves) || (b:moves == best.fewestMoves.moves && b:pushes < best.fewestMoves.pushes)
        let best.fewestMoves = thisGame
    endif

    if (b:pushes < best.fewestPushes.pushes) || (b:pushes == best.fewestPushes.pushes && b:moves < best.fewestPushes.moves)
        let best.fewestPushes = thisGame
    endif

    if best.fewestMoves.moves == best.fewestPushes.moves && best.fewestMoves.pushes == best.fewestPushes.pushes
        call remove(best, 'fewestPushes')
    endif
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

function! s:SaveCurrentLevelToFile(currentSet, currentLevel=-1)   " Saves the current level so to start next time where user left off. {{{1
    let b:userData.currentSet = a:currentSet
    call extend(b:userData, {a:currentSet:{}}, 'keep')
    call extend(b:userData[a:currentSet], {'currentLevel':1}, 'keep')
    if a:currentLevel != -1
        let b:currentLevel = min([len(b:levelSet.levels), max([1, a:currentLevel])])
        let b:userData[a:currentSet].currentLevel = b:currentLevel
    endif
    call s:WriteUserData()
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

function! s:ChangeLevelSet()   " Presents a list of level sets for the player to choose from. {{{1
    call s:GetLevelSets()
    let choices = ['Choose a level set (by number) from this list.']
                \ + map(copy(s:levelSets), {i,v -> printf('%2d: %s -- [%s] © %s', i+1, v.title, v.description, v.copyright)})
    let choice = inputlist(choices)
    if choice > 0 && choice <= len(s:levelSets)
        call s:SaveCurrentLevelToFile(s:levelSets[choice-1].file)
        call sokoban#PlaySokoban('')
    endif
endfunction

function! s:GetLevelSets()   " Get the list of available level sets. {{{1
    let levelSetFiles = map(globpath(g:SokobanLevelDirectory,'*.json',0,1), {_,v -> fnamemodify(v,':p')})
    if !exists('s:levelSets') || len(s:levelSets) != len(levelSetFiles)
        let s:levelSets = []
        for levelSetFile in levelSetFiles
            let levelSet = eval(join(readfile(levelSetFile),''))
            let s:levelSets += [ {'file': fnamemodify(levelSetFile,':t:r'),
                               \  'title':levelSet.title,
                               \  'description':get(levelSet, 'description', ''),
                               \  'copyright':get(levelSet, 'copyright', '')} ]
        endfor
    endif
endfunction

function! sokoban#PlaySokoban(splitWindow, currentLevel=-1)   " This is the entry point to the game. {{{1
    call s:FindOrCreateBuffer(a:splitWindow)
    call s:ReadUserData()
    call s:SaveCurrentLevelToFile(b:currentSet, a:currentLevel)
    call s:GetCurrentHighScores()
    call s:LoadLevelSet()
    let b:moves = 0
    let b:pushes = 0
    let s:marqueeOffset = 0
    call s:DrawGameBoard()
    call s:MapKeys(1)
    normal! 1G0
endfunction

" vim: foldmethod=marker
