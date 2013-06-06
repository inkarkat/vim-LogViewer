" LogViewer.vim: Comfortable examination of multiple parallel logfiles.
"
" DEPENDENCIES:
"   - EchoWithoutScrolling.vim autoload script

" Copyright: (C) 2011-2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.00.005	01-Aug-2012	Clear the collective summary when no syncing was
"				done; keeping the previous summary around is
"				confusing.
"   1.00.004	31-Jul-2012	Print the collective summary for all moves in
"				all log buffers. Print relative line offsets
"				instead of absolute from..to line numbers; it's
"				shorter and more expressive. Since this output
"				should never interfere with cursor movement, and
"				therefore must not provoke the hit-enter prompt,
"				use EchoWithoutScrolling for it.
"	003	24-Jul-2012	Allow customization of the window where log
"				lines are synced via User autocmd.
"	002	24-Aug-2011	Implement marking of target line in master
"				buffer, correct updating when moving across
"				windows, auto-sync and manual setting of a
"				master buffer.
"	001	23-Aug-2011	file creation

let s:save_cpo = &cpo
set cpo&vim

function! s:GetTimestamp( lnum )
    let l:logTimestampExpr = (exists('b:logTimestampExpr') ? b:logTimestampExpr : '^\d\+\ze\s')
    return matchstr(getline(a:lnum), l:logTimestampExpr)
endfunction

function! s:IsLogBuffer()
    return (index(split(g:LogViewer_Filetypes, ','), &l:filetype) != -1)
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
	execute printf('sign place %i line=1 name=LogViewerDummy buffer=%i',
	\   s:signStartId -1,
	\   bufnr('')
	\)
    else
	execute printf('sign unplace %i buffer=%i', s:signStartId - 1, bufnr(''))
    endif
endfunction
function! s:Sign( lnum, name )
    execute printf('sign place %i line=%i name=%s buffer=%i',
    \	s:signStartId + b:LogViewer_signCnt,
    \	a:lnum,
    \	a:name,
    \	bufnr('')
    \)
    let b:LogViewer_signCnt += 1
endfunction
function! s:SignClear()
    if ! exists('b:LogViewer_signCnt') | let b:LogViewer_signCnt = 0 | endif

    for l:signId in range(s:signStartId, s:signStartId + b:LogViewer_signCnt - 1)
	execute printf('sign unplace %i buffer=%i', l:signId, bufnr(''))
    endfor

    let b:LogViewer_signCnt = 0
endfunction
function! s:MarkTarget()
    call s:DummySign(1)
    call s:SignClear()
    call s:Sign(line('.'), 'LogViewerTarget')
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

    let l:suffix = (a:toLnum > a:fromLnum ? 'Down' : 'Up')
    call s:DummySign(1)
    call s:SignClear()
    if a:fromLnum == a:toLnum
	call s:Sign(a:toLnum, 'LogViewerNew'   . l:suffix)
    else
	call s:Sign(a:toLnum, 'LogViewerTo'    . l:suffix)
	call s:Sign(a:fromLnum, 'LogViewerFrom'. l:suffix)
    endif
    call s:DummySign(0)
endfunction
function! s:MarkBuffer()
    if exists('b:LogViewer_fromLnum') && exists('b:LogViewer_toLnum')
	call s:Mark(b:LogViewer_fromLnum, b:LogViewer_toLnum)
    endif
endfunction
function! s:AdvanceToTimestamp( timestamp, isBackward )
    let l:summary = ''
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
	let b:LogViewer_fromLnum = l:originalLnum + 1
	let b:LogViewer_toLnum = l:updatedLnum

	let l:summary = printf('%s: %+d', bufname(''), (l:updatedLnum - l:originalLnum))
    endif

    " Always update the marks; the target may have changed by switching windows.
    call s:MarkBuffer()

    return l:summary
endfunction

function! s:OnSyncWin()
    " Allow customization of the window where log lines are synced.
    " For example, when the sign highlights the entire line, the 'cursorline'
    " setting should be turned off.
    silent doautocmd User LogviewerSyncWin
endfunction
function! s:SyncToTimestamp( timestamp, isBackward )
    call s:MarkTarget()
    call s:OnSyncWin()

    " Sync every buffer only once when it appears in multiple windows, to avoid
    " a 'scrollbind'-like effect and allow for research in multiple parts of the
    " same buffer.
    let l:syncedBufNrs = [bufnr('')]

    let l:summaries = []
    let l:originalWindowLayout = winrestcmd()
	let l:originalWinNr = winnr()

	    noautocmd windo
	    \	if (
	    \	    winnr() != l:originalWinNr &&
	    \	    s:IsLogBuffer() &&
	    \	    index(l:syncedBufNrs, bufnr('')) == -1
	    \	) |
	    \	    call add(l:summaries, s:AdvanceToTimestamp(a:timestamp, a:isBackward)) |
	    \	    call add(l:syncedBufNrs, bufnr('')) |
	    \       call s:OnSyncWin() |
	    \	endif

	execute 'noautocmd' l:originalWinNr . 'wincmd w'
    silent! execute l:originalWindowLayout

    if ! empty(l:summaries)
	" We have found other log buffers, print their summaries or clear the
	" last summary when no syncing was done.
	call EchoWithoutScrolling#Echo(join(filter(l:summaries, '! empty(v:val)'), '; '))
    endif
endfunction

function! LogViewer#LineSync( syncEvent )
    if ! empty(a:syncEvent) && a:syncEvent !=# g:LogViewer_SyncUpdate
	return
    endif

    if ! s:IsLogBuffer()
	" The filetype must have changed to a non-logfile.
	call s:DeinstallLogLineSync()
	return
    endif

    let l:isBackward = 0
    if exists('b:LogViewer_prevline')
	if b:LogViewer_prevline == line('.')
	    " Only horizontal cursor movement within the same line, skip processing.
	    return
	endif
	let l:isBackward = (b:LogViewer_prevline > line('.'))
    endif
    let b:LogViewer_prevline = line('.')

    let l:timestamp = s:GetTimestamp('.')
    if ! empty(l:timestamp)
	call s:SyncToTimestamp(l:timestamp, l:isBackward)
    endif
endfunction

function! s:ExprMatch( timestamp, timestampExpr )
    if a:timestamp =~# '^\d\+$'
	" Use numerical compare for integer timestamps.
	return (str2nr(a:timestamp) <= str2nr(a:timestampExpr))
    else
	return a:timestamp <=# a:timestampExpr
    endif
endfunction
function! s:FindTimestamp( timestampExpr )
    " First search from the current cursor position to the end of the buffer,
    " then wrap around.
    for [l:lnum, l:stopLnum] in [[line('.'), line('$')], [1, line('.')]]
	while 1
	    let [l:lnum, l:nextTimestamp] = s:GetNextTimestamp(l:lnum, 1)
	    if empty(l:nextTimestamp)
		break
	    elseif ! s:ExprMatch(l:nextTimestamp, a:timestampExpr)
		return l:lnum
	    elseif l:lnum >= l:stopLnum
		break
	    endif
	endwhile
    endfor

    return -1
endfunction
function! s:JumpToTimestampOffset( startLnum, offset )
    let l:lnum = a:startLnum
    for l:i in range(a:offset)
	let [l:newLnum, l:nextTimestamp] = s:GetNextTimestamp(l:lnum, 1)
	if empty(l:nextTimestamp)
	    break
	endif
	let l:lnum = l:newLnum
    endfor

    execute l:lnum
endfunction
function! LogViewer#SetTarget( timestampOffset, targetSpec )
    if ! s:IsLogBuffer()
	let v:errmsg = 'Not in log buffer'
	echohl ErrorMsg
	echomsg v:errmsg
	echohl None

	return
    endif

    if ! empty(a:targetSpec)
	" Search for a timestamp matching the passed target specification.
	let l:lnum = s:FindTimestamp(a:targetSpec)
	if l:lnum == -1
	    let v:errmsg = 'No timestamp matching "' . a:targetSpec . '" found'
	    echohl ErrorMsg
	    echomsg v:errmsg
	    echohl None

	    return
	endif

	if a:timestampOffset != 0
	    " Apply the offset to the matched position.
	    call s:JumpToTimestampOffset(l:lnum, a:timestampOffset)
	else
	    execute l:lnum
	endif
    else
	if a:timestampOffset != 0
	    call s:JumpToTimestampOffset(
	    \   (exists('b:LogViewer_prevline') ? b:LogViewer_prevline : line('.')),
	    \   a:timestampOffset
	    \)
	endif
    endif

    call LogViewer#LineSync('')
endfunction

function! LogViewer#MasterEnter()
    " Clear away any range signs from a synced buffer, and mark the new target
    " line.
    call s:MarkTarget()
endfunction
function! LogViewer#MasterLeave()
    " Restore this as a synced buffer from the persisted data.
    call s:MarkBuffer()
endfunction

let s:masterBufnr = -1
function! s:IsMaster()
    return (s:masterBufnr == -1 || bufnr('') == s:masterBufnr)
endfunction
function! s:HasFixedMaster()
    return (s:masterBufnr != -1)
endfunction
function! LogViewer#InstallLogLineSync()
    " Sync the current log line via the timestamp to the cursor positions in all
    " other open log windows. Do this now and update when the cursor isn't
    " moved.
    call LogViewer#LineSync('')

    augroup LogViewerSync
	autocmd! * <buffer>

	" To allow dynamic changing of the sync update (without having to
	" re-apply the changed autocmds to all individual log buffers), we
	" always register for all events, and ignore non-matches inside the
	" event handler.
	autocmd CursorMoved <buffer> if <SID>IsMaster() | call LogViewer#LineSync('CursorMoved') | endif
	autocmd CursorHold  <buffer> if <SID>IsMaster() | call LogViewer#LineSync('CursorHold')  | endif

	" Handle change of master buffer containing the target timestamp.
	autocmd WinEnter <buffer> if ! <SID>HasFixedMaster() | call LogViewer#MasterEnter() | endif
	autocmd WinLeave <buffer> if ! <SID>HasFixedMaster() | call LogViewer#MasterLeave() | endif
    augroup END
endfunction
function! s:DeinstallLogLineSync()
    autocmd! LogViewerSync * <buffer>
endfunction

function! LogViewer#Master()
    call LogViewer#LineSync('')

    if g:LogViewer_SyncAll
	" Set the master buffer and ignore non-matches inside the event
	" handlers.
	let s:masterBufnr = bufnr('')
    else
	" Create the autocmds just for this master buffer.
	augroup LogViewerSync
	    " Delete all autocmds, either from a previous master buffer, or from
	    " all log buffers via the auto-sync.
	    autocmd!

	    autocmd CursorMoved <buffer> call LogViewer#LineSync('CursorMoved')
	    autocmd CursorHold  <buffer> call LogViewer#LineSync('CursorHold')

	    " The master buffer containing the target timestamp is fixed, no
	    " need to adapt when jumping around windows.
	augroup END
    endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
