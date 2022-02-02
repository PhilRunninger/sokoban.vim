execute 'syn match SokobanMan /'.g:charSoko.'/'
execute 'syn match SokobanPackage /'.g:charPackage.'/'
execute 'syn match SokobanPackageHome /'.g:charPackageHome.'/'
execute 'syn match SokobanWall /'.g:charWall.'/'
execute 'syn match SokobanHome /'.g:charHome.'/'

highlight link SokobanPackage Constant
highlight link SokobanPackageHome Statement
highlight link SokobanMan Label
highlight link SokobanWall Comment
highlight link SokobanHome Statement
