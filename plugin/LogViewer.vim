" LogViewer.vim: Comfortable examination of multiple parallel logfiles.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - LogViewer.vim autoload script
"
" Copyright: (C) 2011-2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.00.003	24-Jul-2012	Change LogViewerTarget background highlighting
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
if exists('g:loaded_LogViewer') || (v:version < 700)
    finish
endif
let g:loaded_LogViewer = 1

"- configuration ---------------------------------------------------------------

let s:syncUpdates = ['CursorMoved', 'CursorHold', 'Manual']
if ! exists('g:LogViewer_SyncUpdate')
    let g:LogViewer_SyncUpdate = s:syncUpdates[0]
endif
if ! exists('g:LogViewer_SyncAll')
    let g:LogViewer_SyncAll = 1
endif
if ! exists('g:LogViewer_Filetypes')
    let g:LogViewer_Filetypes = 'log4j'
endif


"- commands --------------------------------------------------------------------

" Turn off syncing in all buffers other that the current one.
command! -bar LogViewerMaster call LogViewer#Master()

" Change g:LogViewer_SyncUpdate
function! s:SetSyncUpdate( syncUpdate )
    if index(s:syncUpdates, a:syncUpdate) == -1
	let v:errmsg = printf('Invalid LogViewer sync update: "%s"; use one of %s', a:syncUpdate, join(s:syncUpdates, ', '))
	echohl ErrorMsg
	echomsg v:errmsg
	echohl None
	return
    endif

    let g:LogViewer_SyncUpdate = a:syncUpdate
endfunction
function! s:SyncUpdateComplete( ArgLead, CmdLine, CursorPos )
    return filter(copy(s:syncUpdates), 'v:val =~ (empty(a:ArgLead) ? ".*" : a:ArgLead)')
endfunction
command! -bar -nargs=1 -complete=customlist,<SID>SyncUpdateComplete LogViewerUpdate call <SID>SetSyncUpdate(<q-args>)

" Set target to current line, [count] timestamps down (from the current target
" timestamp), or the first timestamp that matches {timestamp}.
command! -bar -range=0 -nargs=? LogViewerTarget call LogViewer#SetTarget(<count>, <q-args>)


"- autocmds --------------------------------------------------------------------

if g:LogViewer_SyncAll
    augroup LogViewerAutoSync
	autocmd!
	execute 'autocmd FileType' g:LogViewer_Filetypes 'call LogViewer#InstallLogLineSync()'
    augroup END
endif

if exists('&cursorline') && ! exists('#User#LogviewerSyncWin')
    " The default sign definitions highlight the entire line. For this to have
    " the right effect, the 'cursorline' setting should be turned off.
    augroup LogViewerDefaultSyncWinActions
	autocmd! User LogviewerSyncWin if &l:cursorline | setlocal nocursorline | endif
    augroup END
endif



"- highlightings ---------------------------------------------------------------

highlight def LogViewerFrom   cterm=NONE ctermfg=NONE ctermbg=DarkBlue gui=NONE guifg=NONE guibg=LightCyan
highlight def LogViewerTo     cterm=NONE ctermfg=NONE ctermbg=Blue     gui=NONE guifg=NONE guibg=Cyan
highlight def LogViewerTarget cterm=NONE ctermfg=NONE ctermbg=Yellow   gui=NONE guifg=NONE guibg=LightYellow


"- signs -----------------------------------------------------------------------

sign define LogViewerDummy    text=.
sign define LogViewerNewUp    text=> texthl=LogViewerTo     linehl=LogViewerTo
sign define LogViewerNewDown  text=> texthl=LogViewerTo     linehl=LogViewerTo
sign define LogViewerToUp     text=^ texthl=LogViewerTo     linehl=LogViewerTo
sign define LogViewerToDown   text=V texthl=LogViewerTo     linehl=LogViewerTo
sign define LogViewerFromUp   text=- texthl=LogViewerFrom   linehl=LogViewerFrom
sign define LogViewerFromDown text=- texthl=LogViewerFrom   linehl=LogViewerFrom
sign define LogViewerTarget   text=T texthl=LogViewerTarget linehl=LogViewerTarget

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
