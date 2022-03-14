execute 'syn match SokobanMan /'.g:charSoko.'/'
execute 'syn match SokobanPackage /'.g:charPackage.'/'
execute 'syn match SokobanPackageHome /'.g:charPackageHome.'/'
execute 'syn match SokobanWall /'.g:charWall.'/'
execute 'syn match SokobanHome /'.g:charHome.'/'
syn match SokobanLabels /\(Set\|Level\|Score\|Fewest Moves\|Fewest Pushes\|Legend\|Keys\|Sequence\):/
syn match SokobanTitle /VIM SOKOBAN, v\S*/
syn match SokobanWinner / \zs *LEVEL COMPLETE! *\ze /
syn match SokobanBox /[╔═╡╞╗╚╝╰─╯║╣╩]/
syn match SokobanKeys /^  \(h j k l\|u r\|s\|0-9\|n p\) /

if &background == 'dark'
    highlight SokobanTitle       guifg=#0087ff ctermfg=33
    highlight SokobanWinner      guifg=#000000 ctermfg=16 guibg=#00d700 ctermbg=40
    highlight SokobanLabels      guifg=#ffaf5f ctermfg=215
    highlight SokobanKeys        guifg=#ffd700 ctermfg=220
    highlight SokobanBox         guifg=#3e3e3e ctermfg=236
    highlight SokobanPackage     guifg=#ff005f ctermfg=197
    highlight SokobanPackageHome guifg=#008700 ctermfg=28
    highlight SokobanMan         guifg=#ffd700 ctermfg=220
    highlight SokobanWall        guifg=#808080 ctermfg=244
    highlight SokobanHome        guifg=#d78700 ctermfg=172
else
    highlight SokobanTitle       guifg=#0087ff ctermfg=33
    highlight SokobanWinner      guifg=#000000 ctermfg=16 guibg=#00d700 ctermbg=40
    highlight SokobanLabels      guifg=#ff5fd7 ctermfg=206
    highlight SokobanKeys        guifg=#af00af ctermfg=220
    highlight SokobanBox         guifg=#c6c6c6 ctermfg=236
    highlight SokobanPackage     guifg=#ff005f ctermfg=197
    highlight SokobanPackageHome guifg=#008700 ctermfg=28
    highlight SokobanMan         guifg=#af00af ctermfg=220
    highlight SokobanWall        guifg=#808080 ctermfg=244
    highlight SokobanHome        guifg=#d78700 ctermfg=172
endif
