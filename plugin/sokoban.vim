" Copyright (c) 1998-2018   {{{1
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
" Objective:   {{{1
" The goal of VimSokoban is to push all the packages ($) into
" the  home area (.) of each level using hjkl keys or the arrow
" keys. The arrow keys move the player (X) in the corresponding
" direction, pushing an object if it is in the way and there
" is a clear space on the other side.
"
" Levels came from the xsokoban distribution which is in the public domain.
" http://www.cs.cornell.edu/andru/xsokoban.html
"
" Commands / Maps:   {{{1
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
" Installation / Setup:   {{{1
"
" Install according to the directions found in any of the various Vim Plugin
" managers, such as: pathogen, Vundle, vim-plug, etc.
"
" The locations of the levels direcory and the scores file are configurable. If
" not set in your .vimrc,
"   1) g:SokobanLevelDirectory defaults to the plugin's levels folder.
"   2) g:SokobanScoreFile defaults to .VimSokobanScores in the plugin's root folder.
"
" Release Notes:   {{{1
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
" Acknowledgements:   {{{1
"    Dan Sharp - j/k key mappings were backwards.
"    Bindu Wavell/Gergely Kontra - <sfile> expansion
"    Gergely Kontra - set buftype suggestion, set nomodifiable
" }}}

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
    let g:SokobanLevelDirectory = expand("<sfile>:p:h") . "/../levels/"
endif

" Allow the user to specify the location of the score file.
if !exists("g:SokobanScoreFile")
   let g:SokobanScoreFile = expand("<sfile>:p:h") . "/../.VimSokobanScores"
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
   call append(0, '                              VIM SOKOBAN')
   call append(1, '                              ═══════════')
   call append(2, 'Score                                        Key')
   call append(3, '──────────────                               ──────────────────')
   call append(4, 'Level:  ' . printf("%6d",a:level) . '                               X soko      # wall')
   call append(5, 'Moves:       0                               $ package   . home')
   call append(6, 'Pushes:      0')
   call append(7, ' ')
   call append(8, 'Commands:  h,j,k,l - move   u - undo   r - restart   n,p - next, previous level')
   call append(9, '────────────────────────────────────────────────────────────────────────────────')
   call append(10, ' ')
   let s:endHeaderLine = 11
endfunction

function! <SID>ProcessLevel()   "{{{1
" About...   {{{2
" Function : ProcessLevel (PRIVATE
" Purpose  : processes a level which has been loaded and populates the object
"            lists and sokoban man position.
" Args     : none
" Returns  : nothing
" Author   : Michael Sharpe (feline@irendi.com)   }}}
   " list of the locations of all walls
   let b:wallList = ""
   " list of the locations of all home squares
   let b:homeList = ""
   " list of the locations of all packages
   let b:packageList = ""
   " list of current moves (used for the undo move feature)
   let b:undoList = ""
   " counter of number of moves made
   let b:moves = 0
   " counter of number of pushes made
   let b:pushes = 0

   let eob = line('$')
   let l = s:endHeaderLine
   while (l <= eob)
      let currentLine = getline(l)
      let eoc = strchars(currentLine)
      let c = 1
      while (c <= eoc)
         let ch = currentLine[c]
         if (ch == '#')
            let b:wallList = b:wallList . '(' . l . ',' . c . '):'
         elseif (ch == '.')
            let b:homeList = b:homeList . '(' . l . ',' . c . '):'
         elseif (ch == '*')
            let b:homeList = b:homeList . '(' . l . ',' . c . '):'
            let b:packageList = b:packageList . '(' . l . ',' . c . '):'
         elseif (ch == '$')
            let b:packageList = b:packageList . '(' . l . ',' . c . '):'
         elseif (ch == '@')
            let b:manPosLine = l
            let b:manPosCol = c
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
   let levelExists = filereadable(levelFile)
   if (levelExists)
      set modifiable
      execute "r " . levelFile
      silent! execute "11,$ s/^/           /g"
      call <SID>ProcessLevel()
      let b:level = a:level
      silent! execute s:endHeaderLine . ",$ s/\*/$/g"
      silent! execute s:endHeaderLine . ",$ s/@/X/g"
      if has("syntax")
         syn clear
         syn match SokobanPackage /\$/
         syn match SokobanMan /X/
         syn match SokobanWall /\#/
         syn match SokobanHome /\./
         highlight link SokobanPackage Comment
         highlight link SokobanMan Error
         highlight link SokobanWall Number
         highlight link SokobanHome Keyword
      endif
      call <SID>DetermineHighScores(a:level)
      call <SID>DisplayHighScores()
      call <SID>SaveCurrentLevelToFile(a:level)
      set buftype=nofile
      set nomodifiable
      set nolist nonumber
   else
      let b:level = 0
      call append(11, "Could not find file " . levelFile)
   endif
endfunction

function! <SID>SetCharInLine(theLine, theCol, char)   "{{{1
" About...   {{{2
" Function : SetCharInLine (PRIVATE)
" Purpose  : Puts a specified character at a specific position in the specified
"            line
" Args     : theLine - the line number to manipulate
"            theCol - the column of the character to manipulate
"            char - the character to set at the position
" Returns  : nothing
" Author   : Michael Sharpe (feline@irendi.com)   }}}
   let ln = getline(a:theLine)
   let leftStr = strcharpart(ln, 0, a:theCol)
   let rightStr = strcharpart(ln, a:theCol + 1)
   let ln = leftStr . a:char . rightStr
   call setline(a:theLine, ln)
endfunction

function! <SID>IsInList(theList, line, column)   "{{{1
" About...   {{{2
" Function : IsInList (PRIVATE)
" Purpose  : determines whether the specified (line, column) pair is in
"            the specified list.
" Args     : theList - the list to check
"            line - the line coordinate
"            column - the column coordinate
" Returns  : 1 if the (line, column) pair is in the list, 0 otherwise
" Author   : Michael Sharpe (feline@irendi.com)   }}}

" TODO: switch to actual lists, not string representatives, and use the index() function.

   return <SID>IsInList2(a:theList, "(" . a:line . "," . a:column . ")")
endfunction

function! <SID>IsInList2(theList, str)   "{{{1
" About...   {{{2
" Function : IsInList2 (PRIVATE)
" Purpose  : determines whether the specified (line, column) pair is in
"            the specified list.
" Args     : theList - the list to check
"            str - string representing the (line, column) pair
" Returns  : 1 if the (line, column) pair is in the list, 0 otherwise
" Author   : Michael Sharpe (feline@irendi.com)   }}}
   return stridx(a:theList, a:str) != -1
endfunction

function! <SID>IsWall(line, column)   "{{{1
" About...   {{{2
" Function : IsWall (PRIVATE)
" Purpose  : determines whether the specified (line, column) pair corresponds
"            to a wall
" Args     : line - the line part of the pair
"            column - the column part of the pair
" Returns  : 1 if the (line, column) pair is a wall, 0 otherwise
" Author   : Michael Sharpe (feline@irendi.com)   }}}
   return <SID>IsInList(b:wallList, a:line, a:column)
endfunction

function! <SID>IsHome(line, column)   "{{{1
" About...   {{{2
" Function : IsHome (PRIVATE)
" Purpose  : determines whether the specified (line, column) pair corresponds
"            to a home area
" Args     : line - the line part of the pair
"            column - the column part of the pair
" Returns  : 1 if the (line, column) pair is a home area, 0 otherwise
" Author   : Michael Sharpe (feline@irendi.com)   }}}
   return <SID>IsInList(b:homeList, a:line, a:column)
endfunction

function! <SID>IsPackage(line, column)   "{{{1
" About...   {{{2
" Function : IsPackage (PRIVATE)
" Purpose  : determines whether the specified (line, column) pair corresponds
"            to a package
" Args     : line - the line part of the pair
"            column - the column part of the pair
" Returns  : 1 if the (line, column) pair is a package, 0 otherwise
" Author   : Michael Sharpe (feline@irendi.com)   }}}
   return <SID>IsInList(b:packageList, a:line, a:column)
endfunction

function! <SID>IsEmpty(line, column)   "{{{1
" About...   {{{2
" Function : IsEmpty (PRIVATE)
" Purpose  : determines whether the specified (line, column) pair corresponds
"            to empty space in the maze
" Args     : line - the line part of the pair
"            column - the column part of the pair
" Returns  : 1 if the (line, column) pair is empty space, 0 otherwise
" Author   : Michael Sharpe (feline@irendi.com)   }}}
   return !<SID>IsWall(a:line, a:column) && !<SID>IsPackage(a:line, a:column)
endfunction

function! <SID>MoveMan(fromLine, fromCol, toLine, toCol, pkgLine, pkgCol)   "{{{1
" About...   {{{2
" Function : MoveMan (PRIVATE)
" Purpose  : moves the man and possibly a package in the buffer. The package is
"            assumed to move from where the man moves too. Home squares are
"            handled correctly in this function too. Things are a little crazy
"            for the undo'ing of a move.
" Args     : fromLine - the line where the man is moving from
"            fromCol - the column where the man is moving from
"            toLine - the line where the man is moving to
"            toCol - the column where the man is moving to
"            pkgLine - the line of where a package is moving to
"            pkgCol - the column of where a package is moving to
" Returns  : 1 if the (line, column) pair is empty space, 0 otherwise
" Author   : Michael Sharpe (feline@irendi.com)   }}}
   let isHomePos = <SID>IsHome(a:fromLine, a:fromCol)
   if (isHomePos)
      call <SID>SetCharInLine(a:fromLine, a:fromCol, '.')
   else
      call <SID>SetCharInLine(a:fromLine, a:fromCol, ' ')
   endif
   call <SID>SetCharInLine(a:toLine, a:toCol, 'X')
   if ((a:pkgLine != -1) && (a:pkgCol != -1))
      call <SID>SetCharInLine(a:pkgLine, a:pkgCol, '$')
   endif
endfunction

function! <SID>UpdateHeader()   "{{{1
" About...   {{{2
" Function : UpdateHeader (PRIVATE
" Purpose  : updates the moves and the pushes scores in the header
" Args     : none
" Returns  : nothing
" Author   : Michael Sharpe (feline@irendi.com)   }}}
   call setline(6, 'Moves:  ' . printf("%6d",b:moves) . '                               $ package   . home')
   call setline(7, 'Pushes: ' . printf("%6d",b:pushes))
endfunction

function! <SID>UpdatePackageList(oldLine, oldCol, newLine, newCol)   "{{{1
" About...   {{{2
" Function : UpdatePackageList (PRIVATE)
" Purpose  : updates the package list when a package is moved
" Args     : oldLine - the line of the old package location
"            oldCol - the column of the old package location
"            newLine - the line of the package's new location
"            newCol - the column of the package's new location
" Returns  : nothing
" Author   : Michael Sharpe (feline@irendi.com)   }}}
   let oldStr = "(" . a:oldLine . "," . a:oldCol . ")"
   let newStr = "(" . a:newLine . "," . a:newCol . ")"
   let b:packageList = substitute(b:packageList, oldStr, newStr, "")
endfunction

function! <SID>DisplayLevelCompleteMessage()   "{{{1
" About...   {{{2
" Function : DisplayLevelCompleteMessage (PRIVATE
" Purpose  : Display the message indicating that the level has been completed
" Args     : none
" Returns  : nothing
" Author   : Michael Sharpe (feline@irendi.com)   }}}
   call setline(14, '                                                                                ')
   call setline(15, '          ╭─────────────────────────────────────────────────────────╮           ')
   call setline(16, '          │                       LEVEL COMPLETE                    │           ')
   call setline(17, '          │                ' . printf('%6d',b:moves) . ' Moves  ' . printf('%6d',b:pushes) . ' Pushes              │           ')
   call setline(18, '          ├─────────────────────────────────────────────────────────┤           ')
   call setline(19, '          │ r - restart level   p - previous level   n - next level │           ')
   call setline(20, '          ╰─────────────────────────────────────────────────────────╯           ')
   call setline(21, '                                                                                ')
endfunction

function! <SID>AreAllPackagesHome()   "{{{1
" About...   {{{2
" Function : AreAllPackagesHome (PRIVATE
" Purpose  : Determines if all packages have been placed in the home area
" Args     : none
" Returns  : 1 if all packages are home (i.e. level complete), 0 otherwise
" Author   : Michael Sharpe (feline@irendi.com)   }}}
   let allHome = 1
   let endPos = -1
   while (allHome == 1)
      let startPos = endPos + 1
      let endPos = match(b:packageList, ":", startPos)
      if (endPos != -1)
         let pkg = strcharpart(b:packageList, startPos, endPos - startPos)
         let pkgIsHome = <SID>IsInList2(b:homeList, pkg)
         if (pkgIsHome != 1)
            let allHome = 0
         endif
      else
         break
      endif
   endwhile
   return allHome
endfunction

function! <SID>MakeMove(lineDelta, colDelta, moveDirection)   "{{{1
" About...   {{{2
" Function : MakeMove (PRIVATE)
" Purpose  : This is the core function which is called when a move is made. It
"            detemines if the move is legal, if packages have moved and takes
"            care of updating the buffer to reflect the new position of
"            everything.
" Args     : lineDelta - indicates the direction the  man has moved in a line
"            colDelta - indicates the direction the man has moved in a column
"            moveDirection - character to place in the undolist which
"                            represents the move
" Returns  : nothing
" Author   : Michael Sharpe (feline@irendi.com)   }}}
   let newManPosLine = b:manPosLine + a:lineDelta
   let newManPosCol = b:manPosCol + a:colDelta
   let newManPosIsWall = <SID>IsWall(newManPosLine, newManPosCol)
   if (!newManPosIsWall)
      " if the location we want to move to is not a wall continue processing
      let newManPosIsPackage = <SID>IsPackage(newManPosLine, newManPosCol)
      if (newManPosIsPackage)
         " if the new position is a package check to see if the package moves
         let newPkgPosLine = newManPosLine + a:lineDelta
         let newPkgPosCol = newManPosCol + a:colDelta
         let newPkgPosIsEmpty = <SID>IsEmpty(newPkgPosLine, newPkgPosCol)
         if (newPkgPosIsEmpty)
            set modifiable
            " the move is possible and we pushed a package
            call <SID>MoveMan(b:manPosLine, b:manPosCol, newManPosLine, newManPosCol, newPkgPosLine, newPkgPosCol)
            call <SID>UpdatePackageList(newManPosLine, newManPosCol, newPkgPosLine, newPkgPosCol)
            let b:undoList = a:moveDirection . "p," . b:undoList
            let b:moves = b:moves + 1
            let b:pushes = b:pushes + 1
            let b:manPosLine = newManPosLine
            let b:manPosCol = newManPosCol
            call <SID>UpdateHeader()
            " check to see if the level is complete. Only need to do this after
            " each package push as each level must end with a package push
            let levelIsComplete = <SID>AreAllPackagesHome()
            if (levelIsComplete)
               call <SID>DisplayLevelCompleteMessage()
               call <SID>UpdateHighScores()
               call <SID>SaveCurrentLevelToFile(b:level + 1)
            endif
            set nomodifiable
         endif
      else
         set modifiable
         " the move is possible and no packages moved
         call <SID>MoveMan(b:manPosLine, b:manPosCol, newManPosLine, newManPosCol, -1, -1)
         let b:undoList = a:moveDirection . "," . b:undoList
         let b:moves = b:moves + 1
         let b:manPosLine = newManPosLine
         let b:manPosCol = newManPosCol
         call <SID>UpdateHeader()
         set nomodifiable
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
   if (b:undoList != "")
      let endMove = match(b:undoList, ",", 0)
      if (endMove != -1)
         " get the last move so that it can be undone
         let prevMove = strcharpart(b:undoList, 0, endMove)
         " determine which way the man has to move to undo the move
         if (prevMove[0] == "l")
            let lineDelta = 0
            let colDelta = 1
         elseif (prevMove[0] == "r")
            let lineDelta = 0
            let colDelta = -1
         elseif (prevMove[0] == "u")
            let lineDelta = 1
            let colDelta = 0
         elseif (prevMove[0] == "d")
            let lineDelta = -1
            let colDelta = 0
         else
            let lineDelta = 0
            let colDelta = 0
         endif

         " only continue if a valid move was found.
         if (lineDelta != 0 || colDelta != 0)
            " determine if the move had moved a package so that can be undone
            " too
            if (prevMove[1] == "p")
               let pkgMoved = 1
            else
               let pkgMoved = 0
            endif

            " old position of the man
            let newManPosLine = b:manPosLine + lineDelta
            let newManPosCol = b:manPosCol + colDelta
            if (pkgMoved)
               " if we pushed a package, the position were the man was is where
               " the package was
               let oldPkgPosLine = b:manPosLine
               let oldPkgPosCol = b:manPosCol

               " the position where the package which was pushed is now
               let currPkgOrManPosLine = b:manPosLine - lineDelta
               let currPkgOrManPosCol = b:manPosCol - colDelta
               let b:pushes = b:pushes - 1
               call <SID>UpdatePackageList(currPkgOrManPosLine, currPkgOrManPosCol, oldPkgPosLine, oldPkgPosCol)
            else
               let oldPkgPosLine = 0
               let oldPkgPosCol = 0
               let currPkgOrManPosLine = b:manPosLine
               let currPkgOrManPosCol = b:manPosCol
            endif
            set modifiable
            " this is abusing this function a little :)
            call <SID>MoveMan(currPkgOrManPosLine, currPkgOrManPosCol, newManPosLine, newManPosCol, oldPkgPosLine, oldPkgPosCol)
            let b:manPosLine = newManPosLine
            let b:manPosCol = newManPosCol
            let b:moves = b:moves - 1
            call <SID>UpdateHeader()
            set nomodifiable
         endif
         " remove the move from the undo list
         let b:undoList = strcharpart(b:undoList, endMove + 1, strchars(b:undoList))
      endif
   endif
endfunction

function! <SID>SetupMaps()   "{{{1
" About...   {{{2
" Function : SetupMaps (PRIVATE
" Purpose  : Sets up the various maps to control the movement of the game
" Args     : none
" Returns  : nothing
" Author   : Michael Sharpe (feline@irendi.com)   }}}
   map <silent> <buffer> h       :call <SID>MakeMove(0, -1, "l")<CR>
   map <silent> <buffer> <Left>  :call <SID>MakeMove(0, -1, "l")<CR>
   map <silent> <buffer> j       :call <SID>MakeMove(1, 0, "d")<CR>
   map <silent> <buffer> <Down>  :call <SID>MakeMove(1, 0, "d")<CR>
   map <silent> <buffer> k       :call <SID>MakeMove(-1, 0, "u")<CR>
   map <silent> <buffer> <Up>    :call <SID>MakeMove(-1, 0, "u")<CR>
   map <silent> <buffer> l       :call <SID>MakeMove(0, 1, "r")<CR>
   map <silent> <buffer> <Right> :call <SID>MakeMove(0, 1, "r")<CR>
   map <silent> <buffer> u       :call <SID>UndoMove()<CR>
   map <silent> <buffer> r       :call Sokoban("", b:level)<CR>
   map <silent> <buffer> n       :call Sokoban("", b:level + 1)<CR>
   map <silent> <buffer> p       :call Sokoban("", b:level - 1)<CR>
endfunction

function! <SID>LoadScoresFile()   "{{{1
" About...   {{{2
" Function : LoadScoresFile (PRIVATE
" Purpose  : loads the highscores file if it exists. Determines the last
"            level played. The contents of the highscore file end up in the
"            b:scoreFileContents variable.
" Args     : none
" Returns  : the last level played.
" Author   : Michael Sharpe (feline@irendi.com)   }}}

" TODO: Change b:scoreFileContents to a dictionary, and (de)serialize with the
" code suggested in https://stackoverflow.com/questions/31348782/how-do-i-serialize-a-variable-in-vimscript

   let currentLevel = 0
   let scoreFileExists = filereadable(g:SokobanScoreFile)
   if (scoreFileExists)
      execute ":r " . g:SokobanScoreFile
      normal 1G
      normal dG
      let b:scoreFileContents = @"
      let startPos = matchend(b:scoreFileContents, "CurrentLevel = ")
      if (startPos != -1)
         let endPos = match(b:scoreFileContents, ";", startPos)
         if (endPos != -1)
            let len = endPos - startPos
            let currentLevel = strcharpart(b:scoreFileContents, startPos, len)
         endif
      endif
   else
      let b:scoreFileContents = ""
   endif
   let b:scoresFileLoaded = 1
   return currentLevel
endfunction

function! <SID>SaveScoresToFile()   "{{{1
" About...   {{{2
" Function : SaveScoresToFile (PRIVATE
" Purpose  : saves the current scores to the highscores file.
" Args     : none
" Returns  : nothing
" Notes    : call by silent! call SaveScoresToFile()
" Author   : Michael Sharpe (feline@irendi.com)   }}}
   " newline characters keep creeping into the file. The sub below attempts to
   " control that
   let b:scoreFileContents = substitute(b:scoreFileContents, "\n\n", "\n", "g")
   execute 'redir! > ' . g:SokobanScoreFile
   echo b:scoreFileContents
   redir END
endfunction

function! <SID>ExtractNumberInStr(str, prefix, suffix)   "{{{1
" About...   {{{2
" Function : ExtractNumberInStr (PRIVATE)
" Purpose  : extracts the number in a string which is between prefix and suffix
" Args     : str - the string containing the prefix, number and suffix
"            prefix - the text before the number
"            suffix - the text after the number
" Returns  : the extracted number
" Author   : Michael Sharpe (feline@irendi.com)   }}}
   let startPos = matchend(a:str, a:prefix)
   if (startPos != -1)
      let endPos = match(a:str, a:suffix)
      let len = endPos - startPos
      let theNumber = strcharpart(a:str, startPos, len)
   else
      let theNumber = 0
   endif
   return theNumber
endfunction

function! <SID>DetermineHighScores(level)   "{{{1
" About...   {{{2
" Function : DetermineHighScores (PRIVATE)
" Purpose  : determines the high scores for a particular level. This is a
"            little tricky as there are two high scores possible for each
"            level. One for the pushes and one for the moves. This function
"            detemines both and maintains the information for both
" Args     : level - the level to determine the high scores
" Returns  : nothing, sets alot of buffer variables though
" Author   : Michael Sharpe (feline@irendi.com)   }}}
  let b:highScoreByMoveMoves = -1
  let b:highScoreByMovePushes = -1
  let b:highScoreByMoveStr = ""
  let b:highScoreByPushMoves = -1
  let b:highScoreByPushPushes = -1
  let b:highScoreByPushStr = ""

  let levelStr = "Level " . a:level . ": "
  " determine the first highscore
  let startPos = match(b:scoreFileContents, levelStr)
  if (startPos != -1)
     let endPos = match(b:scoreFileContents, ";", startPos)
     let len = endPos - startPos + 1
     let scoreStr1 = strcharpart(b:scoreFileContents, startPos, len)
     let scoreMoves1 = <SID>ExtractNumberInStr(scoreStr1, "Moves = ", ",")
     let scorePushes1 = <SID>ExtractNumberInStr(scoreStr1, "Pushes = ", ";")

     " look for the second highscore
     let startPos = match(b:scoreFileContents,levelStr, endPos + 1)
     if (startPos != -1)
        let endPos = match(b:scoreFileContents, ";", startPos)
        let len = endPos - startPos + 1
        let scoreStr2 = strcharpart(b:scoreFileContents, startPos, len)
        let scoreMoves2 = <SID>ExtractNumberInStr(scoreStr2, "Moves = ", ",")
        let scorePushes2 = <SID>ExtractNumberInStr(scoreStr2, "Pushes = ", ";")
        if (scoreMoves1 < scoreMoves2)
           " the first set of scores has the lowest moves
           let b:highScoreByMoveMoves = scoreMoves1
           let b:highScoreByMovePushes = scorePushes1
           let b:highScoreByMoveStr = scoreStr1
           let b:highScoreByPushMoves = scoreMoves2
           let b:highScoreByPushPushes = scorePushes2
           let b:highScoreByPushStr = scoreStr2
        else
           " the first set of scores has the lowest pushes
           let b:highScoreByMoveMoves = scoreMoves2
           let b:highScoreByMovePushes = scorePushes2
           let b:highScoreByMoveStr = scoreStr2
           let b:highScoreByPushMoves = scoreMoves1
           let b:highScoreByPushPushes = scorePushes1
           let b:highScoreByPushStr = scoreStr1
        endif
     else
        let b:highScoreByMoveMoves = scoreMoves1
        let b:highScoreByMovePushes = scorePushes1
        let b:highScoreByMoveStr = scoreStr1
        let b:highScoreByPushMoves = -1
        let b:highScoreByPushPushes = -1
        let b:highScoreByPushStr = ""
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
   let updateMoveRecord = 0
   let updatePushRecord = 0

   let newScoreStr = "Level " . b:level . ": Moves = " . b:moves . ", Pushes = " . b:pushes . ";"

   if (b:moves < b:highScoreByMoveMoves)
      let updateMoveRecord = 1
   endif

   if ((b:moves == b:highScoreByMoveMoves) && (b:pushes < b:highScoreByMovePushes))
      let updateMoveRecord = 1
   endif

   if (b:pushes < b:highScoreByPushPushes)
      let updatePushRecord = 1
   endif

   if ((b:pushes == b:highScoreByPushPushes) && (b:moves < b:highScoreByPushMoves))
      let updatePushRecord = 1
   endif

   if (b:highScoreByMoveStr == "")
      let updateMoveRecord = 1
   endif

   if (b:highScoreByPushStr == "" && b:highScoreByMoveStr != newScoreStr)
      let updatePushRecord = 1
   endif

   if (updateMoveRecord && updatePushRecord)
      "this record beats both high scores
      if (b:highScoreByMoveStr != "")
         let b:scoreFileContents = substitute(b:scoreFileContents, b:highScoreByMoveStr, newScoreStr, "")
      else
         let b:scoreFileContents = b:scoreFileContents . "\n" . newScoreStr
      endif
      if (b:highScoreByPushStr != "")
         let b:scoreFileContents = substitute(b:scoreFileContents, b:highScoreByPushStr, "", "")
      endif
   elseif (updateMoveRecord)
      if (b:highScoreByMoveStr != "")
         let b:scoreFileContents = substitute(b:scoreFileContents, b:highScoreByMoveStr, newScoreStr, "")
      else
         let b:scoreFileContents = b:scoreFileContents . "\n" . newScoreStr
      endif
   elseif (updatePushRecord)
      if (b:highScoreByPushStr != "")
         let b:scoreFileContents = substitute(b:scoreFileContents, b:highScoreByPushStr, newScoreStr, "")
      else
         let b:scoreFileContents = b:scoreFileContents . "\n" . newScoreStr
      endif
   endif
   if (updateMoveRecord || updatePushRecord)
      silent! call <SID>SaveScoresToFile()
   endif
endfunction

function! <SID>SaveCurrentLevelToFile(level)   "{{{1
" About...   {{{2
" Function : SaveCurrentLevelToFile (PRIVATE)
" Purpose  : saves the current level to the high scores file.
" Args     : level - the level number to save to the file
" Returns  : nothing
" Author   : Michael Sharpe (feline@irendi.com)   }}}
   let idx = match(b:scoreFileContents, "CurrentLevel")
   if (idx != -1)
      let b:scoreFileContents = substitute(b:scoreFileContents, "CurrentLevel = [0-9]*;", "CurrentLevel = " . a:level . ";", "")
   else
      let b:scoreFileContents = "CurrentLevel = " . a:level . ";\n" .  b:scoreFileContents
   endif
   silent! call <SID>SaveScoresToFile()
endfunction

function! <SID>DisplayHighScores()   "{{{1
" About...   {{{2
" Function : DisplayHighScores (PRIVATE)
" Purpose  : Displays the high scores for a level under the level when it is
"            loaded.
" Args     : none
" Author   : Michael Sharpe (feline@irendi.com) }}}
   if (b:highScoreByMoveStr != "")
      call append(line("$"), "")
      call append(line("$"), "────────────────────────────────────────────────────────────────────────────────")
      call append(line("$"), "Best Score - by Moves:    " . printf("%6d",b:highScoreByMoveMoves) . " moves      " . printf("%6d",b:highScoreByMovePushes) . " pushes")
      if (b:highScoreByPushStr != "")
         call append(line("$"), "           - by Pushes:   " . printf("%6d",b:highScoreByPushMoves) . " moves      " . printf("%6d",b:highScoreByPushPushes) . " pushes")
      endif
   endif
endfunction

function! <SID>FindOrCreateBuffer(filename, doSplit)   "{{{1
" About...   {{{2
" Function : FindOrCreateBuffer (PRIVATE)
"            found, checks the window list for the buffer. If the buffer is in
"            an already open window, it switches to the window. If the buffer
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
      let level = a:1
   endif
   call <SID>FindOrCreateBuffer('__\.\#\$VimSokoban\$\#\.__', a:splitWindow)
   set modifiable
   call <SID>ClearBuffer()
   if (!exists("b:scoresFileLoaded"))
      let savedLevel = <SID>LoadScoresFile()
      call <SID>ClearBuffer()
      " if there was a saved level and the level was not specified use it now
      if (a:0 == 0 && savedLevel != 0)
         let level = savedLevel
      endif
   endif
   call <SID>DisplayInitialHeader(level)
   call <SID>LoadLevel(level)
   set nomodifiable
   call <SID>SetupMaps()
   " do something with the cursor....
   normal 1G
   normal 0
endfunction

" vim: foldmethod=marker
