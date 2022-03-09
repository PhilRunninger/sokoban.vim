execute 'syn match SokobanMan /'.g:charSoko.'/'
execute 'syn match SokobanPackage /'.g:charPackage.'/'
execute 'syn match SokobanPackageHome /'.g:charPackageHome.'/'
execute 'syn match SokobanWall /'.g:charWall.'/'
execute 'syn match SokobanHome /'.g:charHome.'/'
syn match SokobanLabels /\(Set\|Level #\|Name\|Score\|Fewest Moves\|Fewest Pushes\|Legend\|Keys\|Sequence\):/
syn match SokobanTitle /VIM SOKOBAN, v\S*/

highlight SokobanTitle guifg=#af0000 ctermfg=124
highlight SokobanLabels guifg=#d78700 ctermfg=172
highlight SokobanPackage guifg=#ff5f00 ctermfg=202
highlight SokobanPackageHome guifg=#00d700 ctermfg=40
highlight SokobanMan guifg=#0087ff ctermfg=33
highlight SokobanWall guifg=#808080 ctermfg=244
highlight SokobanHome guifg=#d78700 ctermfg=172
