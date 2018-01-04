" log4j_LogViewer.vim: Define the timestamp pattern for the LogViewer.vim plugin.
"
" DEPENDENCIES:
"   - ingo/lines/empty.vim autoload script
"
" Copyright: (C) 2011-2018 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.11.002	05-Jan-2018	Don't override existing b:logTimestampExpr.
"				Use first non-empty line in buffer to detect
"				used log4j timestamp format.
"				Add precise pattern for %d log4j format, and
"				check that first.
"   1.00.001	23-Aug-2011	file creation

if exists('b:logTimestampExpr') | finish | endif

let s:firstNonEmptyLine = getline(ingo#lines#empty#GetNextNonEmptyLnum(0))
    " %d, e.g. 2011-08-17 13:08:30,509
    " %r, e.g. 467
    for b:logTimestampExpr in ['^\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2},\d\{3}', '^\d\S\+\d \d\S\+\d\ze\s', '^\d\+\ze\s']
	if s:firstNonEmptyLine =~# b:logTimestampExpr
	    break
	endif
    endfor
unlet! s:firstNonEmptyLine

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
