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
    " Outer tag becomes start/end of JSON object.
    %s/<SokobanLevels.*/{/
    %s/<\/SokobanLevels>/}/

    " Uppermost elements to JSON data.
    %s/<Title>\(.*\)<\/Title>/"title":"\1",/
    %s/<Email>\(.*\)<\/Email>/"email":"\1",/
    %s/<Url>\(.*\)<\/Url>/"url":"\1",/
    /<Description>/,/<\/Description>/join
    %s/<Description>\s*/"description":"/
    %s/\s*<\/Description>/",/

    " LevelCollection element removed as unnecessary.
    %s/<LevelCollection\(.*\)>/\1,\r"levels":[/
    %s/<\/LevelCollection>/]/

    " Promote some lower-level attributes to the top level data.
    %s/Copyright=/,\r"copyright":/
    %s/MaxWidth=/,\r"maxWidth":/
    %s/MaxHeight=/,\r"maxHeight":/

    " Level becomes a nested JSON object.
    %s/<Level\(.*\)>/{\r\1,\r"room":[/
    %s/<\/Level>/},/

    " Convert level attributes to JSON data.
    %s/Id=/,\r"id":/
    %s/Width=/,\r"width":/
    %s/Height=/,\r"height":/

    " Convert <L> elements to string array items.
    %s/<L>/"/
    %s/<\/L>/",/

    " Remove trailing commas from final array elements.
    %s/,\n\s*}/]\r}/
    %s/,\n\s*]/\r]/

    " Remove quotes around integer values.
    %s/\(width\|height\)":\s*\zs"\(\d\+\)"/\2/

    " Remove blank lines, stray commas, and <?xml> tag.
    g/^$/d
    g/^\s*,$/d
    g/<?xml/d
endfunction
