" logviewer.vim: summary
"
" DEPENDENCIES:
"
" Copyright: (C) 2011 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	001	23-Aug-2011	file creation

" Avoid installing twice or when in unsupported Vim version. 
if exists('g:loaded_logviewer') || (v:version < 700)
    finish
endif
let g:loaded_logviewer = 1

if ! exists('g:logviewer_filetypes')
    let g:logviewer_filetypes = 'log4j'
endif

augroup logviewer
    autocmd!
    execute 'autocmd FileType' g:logviewer_filetypes 'call logviewer#InstallLogLineSync()'
augroup END

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
