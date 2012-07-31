" logviewer.vim: Comfortable examination of multiple parallel logfiles.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - logviewer.vim autoload script
"
" Copyright: (C) 2011-2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"	003	24-Jul-2012	Change logviewerTarget background highlighting
"				to LightYellow; the original Orange looks too
"				similar to my log4j syntax highlighting of WARN
"				entries.
"				Turn off 'cursorline' setting for log windows
"				participating in the sync via a newly introduced
"				LogviewerSyncWin User autocmd hook.
"	002	24-Aug-2011	Add commands for setting the master and sync
"				update method and corresponding configuration.
"	001	23-Aug-2011	file creation

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_logviewer') || (v:version < 700)
    finish
endif
let g:loaded_logviewer = 1

"- configuration ---------------------------------------------------------------

let s:syncUpdates = ['CursorMoved', 'CursorHold', 'Manual']
if ! exists('g:logviewer_syncUpdate')
    let g:logviewer_syncUpdate = s:syncUpdates[0]
endif
if ! exists('g:logviewer_syncAll')
    let g:logviewer_syncAll = 1
endif
if ! exists('g:logviewer_filetypes')
    let g:logviewer_filetypes = 'log4j'
endif


"- commands --------------------------------------------------------------------

" Turn off syncing in all buffers other that the current one.
command! -bar LogViewerMaster call logviewer#Master()

" Change g:logviewer_syncUpdate
function! s:SetSyncUpdate( syncUpdate )
    if index(s:syncUpdates, a:syncUpdate) == -1
	let v:errmsg = printf('Invalid logviewer sync update: "%s"; use one of %s', a:syncUpdate, join(s:syncUpdates, ', '))
	echohl ErrorMsg
	echomsg v:errmsg
	echohl None
	return
    endif

    let g:logviewer_syncUpdate = a:syncUpdate
endfunction
function! s:SyncUpdateComplete( ArgLead, CmdLine, CursorPos )
    return filter(copy(s:syncUpdates), 'v:val =~ (empty(a:ArgLead) ? ".*" : a:ArgLead)')
endfunction
command! -bar -nargs=1 -complete=customlist,<SID>SyncUpdateComplete LogViewerUpdate call <SID>SetSyncUpdate(<q-args>)

" Set target to current line, [count] timestamps down (from the current target
" timestamp), or the first timestamp that matches {timestamp}.
command! -bar -range=0 -nargs=? LogViewerTarget call logviewer#SetTarget(<count>, <q-args>)


"- autocmds --------------------------------------------------------------------

if g:logviewer_syncAll
    augroup logviewerAutoSync
	autocmd!
	execute 'autocmd FileType' g:logviewer_filetypes 'call logviewer#InstallLogLineSync()'
    augroup END
endif

if exists('&cursorline') && ! exists('#User#LogviewerSyncWin')
    " The default sign definitions highlight the entire line. For this to have
    " the right effect, the 'cursorline' setting should be turned off.
    augroup logviewerDefaultSyncWinActions
	autocmd! User LogviewerSyncWin if &l:cursorline | setlocal nocursorline | endif
    augroup END
endif



"- highlightings ---------------------------------------------------------------

highlight def logviewerFrom   cterm=NONE ctermfg=NONE ctermbg=DarkBlue gui=NONE guifg=NONE guibg=LightCyan
highlight def logviewerTo     cterm=NONE ctermfg=NONE ctermbg=Blue     gui=NONE guifg=NONE guibg=Cyan
highlight def logviewerTarget cterm=NONE ctermfg=NONE ctermbg=Yellow   gui=NONE guifg=NONE guibg=LightYellow


"- signs -----------------------------------------------------------------------

sign define logviewerDummy    text=.
sign define logviewerNewUp    text=> texthl=logviewerTo     linehl=logviewerTo
sign define logviewerNewDown  text=> texthl=logviewerTo     linehl=logviewerTo
sign define logviewerToUp     text=^ texthl=logviewerTo     linehl=logviewerTo
sign define logviewerToDown   text=V texthl=logviewerTo     linehl=logviewerTo
sign define logviewerFromUp   text=- texthl=logviewerFrom   linehl=logviewerFrom
sign define logviewerFromDown text=- texthl=logviewerFrom   linehl=logviewerFrom
sign define logviewerTarget   text=T texthl=logviewerTarget linehl=logviewerTarget

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
