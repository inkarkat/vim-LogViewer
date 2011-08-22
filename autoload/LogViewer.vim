" logviewer.vim: summary
"
" DESCRIPTION:
" USAGE:
" INSTALLATION:
"   Put the script into your user or system Vim plugin directory (e.g.
"   ~/.vim/plugin). 

" DEPENDENCIES:
"   - Requires Vim 7.0 or higher. 

" CONFIGURATION:
" INTEGRATION:
" LIMITATIONS:
" ASSUMPTIONS:
" KNOWN PROBLEMS:
" TODO:
"
" Copyright: (C) 2011 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	001	23-Aug-2011	file creation

let s:save_cpo = &cpo
set cpo&vim

function! s:GetTimestamp( lnum )
    let l:logTimestampExpr = (exists('b:logTimestampExpr') ? b:logTimestampExpr : '^\d\+\ze\s')
    return matchstr(getline(a:lnum), l:logTimestampExpr)
endfunction

function! s:IsLogBuffer()
    return (index(split(g:logviewer_filetypes, ','), &l:filetype) != -1)
endfunction

function! s:GetNextTimestamp( startLnum, offset )
    let l:lnum = a:startLnum + a:offset
    while l:lnum >= 1 && l:lnum <= line('$')
	let l:timestamp = s:GetTimestamp(l:lnum)
	if ! empty(l:timestamp)
	    return [l:lnum, l:timestamp]
	endif

	let l:lnum += a:offset
    endwhile
    return [0, '']
endfunction
function! s:Match( isBackward, offset, targetTimestamp, currentTimestamp )
    if a:isBackward
	return a:currentTimestamp >= a:targetTimestamp
    else
	return a:currentTimestamp <= a:targetTimestamp
    endif
endfunction
function! s:JumpToTimestamp( timestamp, isBackward )
    let l:offset = (a:isBackward ? -1 : 1)

    " Try to get the next timestamp in the opposite direction. 
    let [l:lnum, l:nearestTimestamp] = s:GetNextTimestamp(line('.'), -1 * l:offset)
    if l:lnum == 0
	" No timestamp; try the other direction. 
	let l:offset = -1 * l:offset
	let [l:lnum, l:nearestTimestamp] = s:GetNextTimestamp(line('.'), l:offset)
    endif
    if l:lnum == 0
	" No timestamp at all, give up. 
	return
    endif

    if a:isBackward
	if l:offset > 0
	    let l:offset = (l:nearestTimestamp >= a:timestamp ? -1 : 1)
	elseif l:nearestTimestamp <= a:timestamp
	    let l:offset = 1
	else
	    return
	endif
    endif


    echomsg '**** start'
    let l:updatedLnum = 0
    while 1
	let [l:lnum, l:nextTimestamp] = s:GetNextTimestamp(l:lnum, l:offset)
	echomsg '****' l:lnum l:nextTimestamp
	if empty(l:nextTimestamp) || ! s:Match(a:isBackward, l:offset, a:timestamp, l:nextTimestamp)
	    break
	endif

	let l:updatedLnum = l:lnum
    endwhile

    if l:updatedLnum > 0 && l:updatedLnum != line('.')
	let w:persistent_cursorline = 1
	echomsg '****' bufname('') 'move from' line('.') 'to' l:updatedLnum
	execute l:updatedLnum
    endif
endfunction

function! s:SyncToTimestamp( timestamp, isBackward )
    " Sync every buffer only once when it appears in multiple windows, to avoid
    " a 'scrollbind'-like effect and allow for research in multiple parts of the
    " same buffer. 
    let l:syncedBufNrs = [bufnr('')]

    let l:originalWindowLayout = winrestcmd()
	let l:originalWinNr = winnr()

	    noautocmd windo
	    \	if (
	    \	    winnr() != l:originalWinNr &&
	    \	    s:IsLogBuffer() &&
	    \	    index(l:syncedBufNrs, bufnr('') == -1)
	    \	) |
	    \	    call s:JumpToTimestamp(a:timestamp, a:isBackward) |
	    \	    call add(l:syncedBufNrs, bufnr('')) |
	    \	endif

	execute 'noautocmd' l:originalWinNr . 'wincmd w'
    silent! execute l:originalWindowLayout
endfunction

function! logviewer#LineSync()
    if ! s:IsLogBuffer()
	" The filetype must have changed to a non-logfile. 
	call s:DeinstallLogLineSync()
	return
    endif

    let l:isBackward = 0
    if exists('b:logviewer_prevline')
	if b:logviewer_prevline == line('.')
	    " Only horizontal cursor movement within the same line, skip processing. 
	    return
	endif
	let l:isBackward = (b:logviewer_prevline > line('.'))
    endif
    let b:logviewer_prevline = line('.')

    let l:timestamp = s:GetTimestamp('.')
    if ! empty(l:timestamp)
	call s:SyncToTimestamp(l:timestamp, l:isBackward)
    endif
endfunction

function! logviewer#InstallLogLineSync()
    " Sync the current log line via the timestamp to the cursor positions in all
    " other open log windows. Do this now and update when the cursor isn't
    " moved. 
    call logviewer#LineSync()

    augroup logviewerSync
	autocmd! * <buffer>
	autocmd CursorMoved,CursorHold <buffer> call logviewer#LineSync()
    augroup END
endfunction
function! s:DeinstallLogLineSync()
    autocmd! logviewerSync * <buffer>
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
