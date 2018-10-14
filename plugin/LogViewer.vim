" LogViewer.vim: Comfortable examination of multiple parallel logfiles.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - LogViewer.vim autoload script
"   - ingo/err.vim autoload script
"
" Copyright: (C) 2011-2018 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

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


"- mappings --------------------------------------------------------------------

let s:defaultSync = (g:LogViewer_SyncUpdate ==# 'Manual' ? s:syncUpdates[0] : g:LogViewer_SyncUpdate)
function! s:Toggle()
    if g:LogViewer_SyncUpdate ==# s:defaultSync
	let g:LogViewer_SyncUpdate = 'Manual'
	echomsg 'LogViewer: Syncing needs manual trigger via :LogViewerTarget now'
    else
	let g:LogViewer_SyncUpdate = s:defaultSync
	echomsg printf('LogViewer: Automatic syncing on %s', g:LogViewer_SyncUpdate)
    endif
endfunction
nnoremap <silent> <Plug>(LogViewerToggle) :<C-u>call <SID>Toggle()<CR>
if ! hasmapto('<Plug>(LogViewerToggle)', 'n')
    nmap <Leader>tlv <Plug>(LogViewerToggle)
endif


"- commands --------------------------------------------------------------------

command! -bar LogViewerEnable  let b:LogViewer_Enabled = 1 | if g:LogViewer_SyncAll | call LogViewer#InstallLogLineSync() | endif
command! -bar LogViewerDisable let b:LogViewer_Enabled = 0 | call LogViewer#DeinstallLogLineSync()

" Turn off syncing in all buffers other that the current one.
command! -bar LogViewerMaster if ! LogViewer#Master() | echoerr ingo#err#Get() | endif

" Change g:LogViewer_SyncUpdate
function! s:SetSyncUpdate( syncUpdate )
    if index(s:syncUpdates, a:syncUpdate) == -1
	call ingo#err#Set(printf('Invalid LogViewer sync update: "%s"; use one of %s', a:syncUpdate, join(s:syncUpdates, ', ')))
	return 0
    endif

    let g:LogViewer_SyncUpdate = a:syncUpdate
    return 1
endfunction
function! s:SyncUpdateComplete( ArgLead, CmdLine, CursorPos )
    return filter(copy(s:syncUpdates), 'v:val =~ (empty(a:ArgLead) ? ".*" : a:ArgLead)')
endfunction
command! -bar -nargs=1 -complete=customlist,<SID>SyncUpdateComplete LogViewerUpdate if ! <SID>SetSyncUpdate(<q-args>) | echoerr ingo#err#Get() | endif

" Set target to current line, [count] timestamps down (from the current target
" timestamp), or the first timestamp that matches {timestamp}.
command! -bar -range=0 -nargs=? LogViewerTarget if ! LogViewer#SetTarget(<count>, <q-args>) | echoerr ingo#err#Get() | endif


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
