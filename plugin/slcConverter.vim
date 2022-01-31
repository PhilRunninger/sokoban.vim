" A zip file of many collections of sokoban levels can be downloaded from
" here: http://www.sourcecode.se/sokoban/download/Levels. They are XML files
" with the extension "slc". The SLCtoJSON function does a good job of
" converting them to JSON format with mostly search and replace commands. You
" will need to replace any XML character entity references: &apos; &quot;
" &amp; &lt; &gt;. The rest of the file should be OK, but it doesn't hurt to
" give it a once-over to be sure.

" This function assumes the following workflow:
"       :e FooBar.json
"       :r Foobar.slc
"       :call SLCtoJSON()
function! SLCtoJSON()
    g/<?xml/d
    %s/<SokobanLevels.*/{/
    %s/<\/SokobanLevels>/}/
    %s/<LevelCollection\(.*\)>/"levelCollection":{\r\1,\r"levels":[/
    %s/<\/LevelCollection>/]\r}/
    %s/<Title>\(.*\)<\/Title>/"title":"\1",/
    %s/<Email>\(.*\)<\/Email>/"email":"\1",/
    %s/<Url>\(.*\)<\/Url>/"url":"\1",/
    /<Description>/,/<\/Description>/join
    %s/<Description>\s*/"description":"/
    %s/\s*<\/Description>/",/
    %s/<Level\(.*\)>/{\r\1,\r"room":[/
    %s/<\/Level>/},/
    %s/Copyright=/,\r"copyright":/
    %s/MaxWidth=/,\r"maxWidth":/
    %s/MaxHeight=/,\r"maxHeight":/
    %s/Id=/,\r"id":/
    %s/Width=/,\r"width":/
    %s/Height=/,\r"height":/
    %s/<L>/"/
    %s/<\/L>/",/
    %s/,\n\s*}/]\r}/
    %s/,\n\s*]/\r]/
    %s/\(width\|height\)":\s*"\(\d\+\)"/\1": \2/
    g/^\s*,$/d
    g/^$/d
endfunction
