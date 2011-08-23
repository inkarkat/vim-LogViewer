" logviewer.vim: summary
"
" DEPENDENCIES:

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
function! s:Match( isBackward, targetTimestamp, currentTimestamp )
    if a:isBackward
	return a:currentTimestamp >= a:targetTimestamp
    else
	return a:currentTimestamp <= a:targetTimestamp
    endif
endfunction
let s:signStartId = 456
function! s:DummySign( isOn )
    " To avoid flickering of the sign column when all signs are temporarily
    " removed. 
    if a:isOn
	execute printf('sign place %i line=1 name=logviewerDummy buffer=%i',
	\   s:signStartId -1,
	\   bufnr('')
	\)
    else
	execute printf('sign unplace %i buffer=%i', s:signStartId - 1, bufnr(''))
    endif
endfunction
function! s:Sign( lnum, name )
    execute printf('sign place %i line=%i name=%s buffer=%i',
    \	s:signStartId + b:logviewer_signCnt,
    \	a:lnum,
    \	a:name,
    \	bufnr('')
    \)
    let b:logviewer_signCnt += 1
endfunction
function! s:SignClear()
    if ! exists('b:logviewer_signCnt') | let b:logviewer_signCnt = 0 | endif

    for l:signId in range(s:signStartId, s:signStartId + b:logviewer_signCnt - 1)
	execute printf('sign unplace %i buffer=%i', l:signId, bufnr(''))
    endfor

    let b:logviewer_signCnt = 0
endfunction
function! s:MarkTarget()
    call s:DummySign(1)
    call s:SignClear()
    call s:Sign(line('.'), 'logviewerTarget')
    call s:DummySign(0)
endfunction
function! s:Mark( fromLnum, toLnum )
    " Move cursor to the final log entry. 
    execute a:toLnum

    " Mark the borders of the range of log entries that fall within the time
    " range of the move to the target timestamp. 

    " Signs aren't displayed in closed folds, so need to open them. 
    for l:lnum in [a:fromLnum, a:toLnum]
	if foldclosed(l:lnum) != -1
	    execute l:lnum . 'foldopen'
	endif
    endfor

    let l:isDown = (a:toLnum > a:fromLnum)
    call s:DummySign(1)
    call s:SignClear()
    if a:fromLnum == a:toLnum
	call s:Sign(a:toLnum, 'logviewerNew' . (l:isDown ? 'Down' : 'Up'))
    else
	call s:Sign(a:toLnum, 'logviewerCurrent' . (l:isDown ? 'Down' : 'Up'))
	call s:Sign(a:fromLnum, 'logviewerFrom'. (l:isDown ? 'Down' : 'Up'))
    endif
    call s:DummySign(0)
endfunction
function! s:JumpToTimestamp( timestamp, isBackward )
    let l:originalLnum = line('.')
    " The current timestamp is either on the current line or above it. 
    let [l:lnum, l:currentTimestamp] = s:GetNextTimestamp(l:originalLnum + 1, -1)

    let l:offset = (a:isBackward ? -1 : 1) * (s:Match(a:isBackward, a:timestamp, l:currentTimestamp) ? 1 : -1)

    let l:updatedLnum = 0
    while 1
	let [l:lnum, l:nextTimestamp] = s:GetNextTimestamp(l:lnum, l:offset)
"****D echomsg '****' l:lnum l:nextTimestamp
	if empty(l:nextTimestamp) || ! s:Match(a:isBackward, a:timestamp, l:nextTimestamp)
	    break
	endif

	let l:updatedLnum = l:lnum
    endwhile

    if l:updatedLnum > 0 && l:updatedLnum != l:originalLnum
	let b:logviewer_fromLnum = l:originalLnum + 1
	let b:logviewer_toLnum = l:updatedLnum

	echo bufname('') 'move from' l:originalLnum 'to' l:updatedLnum
    endif

    " Always update the marks; the target may have changed by switching windows. 
    call s:Mark(b:logviewer_fromLnum, b:logviewer_toLnum)
endfunction

function! s:SyncToTimestamp( timestamp, isBackward )
    call s:MarkTarget()

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
	    \	    index(l:syncedBufNrs, bufnr('')) == -1
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

function! logviewer#TargetEnter()
    " Clear away any range signs from a synced buffer, and mark the new target
    " line. 
    call s:MarkTarget()
endfunction
function! logviewer#TargetLeave()
    " Restore this as a synced buffer from the persisted data. 
    call s:Mark(b:logviewer_fromLnum, b:logviewer_toLnum)
endfunction

function! logviewer#InstallLogLineSync()
    " Sync the current log line via the timestamp to the cursor positions in all
    " other open log windows. Do this now and update when the cursor isn't
    " moved. 
    call logviewer#LineSync()

    augroup logviewerSync
	autocmd! * <buffer>
	autocmd CursorMoved,CursorHold <buffer> call logviewer#LineSync()
	autocmd WinEnter <buffer> call logviewer#TargetEnter()
	autocmd WinLeave <buffer> call logviewer#TargetLeave()
    augroup END
endfunction
function! s:DeinstallLogLineSync()
    autocmd! logviewerSync * <buffer>
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
