" logviewer.vim: summary
"
" IDEAS:
"   - Disable range highlighting via config setting. 
"   - Trigger marking in other buffers only on demand (instead of autocmd), and
"     only when in the source buffer. 
"   - Commands to (un-)freeze the marks. 
"   - Compare and mark current lines that are identical in all logs. Keep those
"     lines so that a full picture emerges when moving along. 
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

sign define logviewerDummy       text=.
sign define logviewerNewUp       text=> linehl=DiffText
sign define logviewerNewDown     text=> linehl=DiffText
sign define logviewerCurrentUp   text=^ linehl=DiffText
sign define logviewerCurrentDown text=V linehl=DiffText
sign define logviewerFromUp      text=- linehl=DiffText
sign define logviewerFromDown    text=- linehl=DiffText
sign define logviewerTarget      text=T linehl=DiffText

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
