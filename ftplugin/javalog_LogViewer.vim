" javalog_LogViewer.vim Define the timestamp pattern for the LogViewer.vim plugin.
"
" DEPENDENCIES:
"   - ingo/lines/empty.vim autoload script
"
" Copyright: (C) 2018-2023 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

if exists('b:logTimestampExpr') | finish | endif

let s:firstNonEmptyLine = getline(ingo#lines#empty#GetNextNonEmptyLnum(0))
let s:lastNonEmptyLine = getline(ingo#lines#empty#GetPreviousNonEmptyLnum(-1))
    for b:logTimestampExpr in ['\<\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2},\d\{3}\>', '\<\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2}\>', '\<\d\{2}:\d\{2}:\d\{2},\d\{3}\>', '\<\d\{2}:\d\{2}:\d\{2}\>']
	if s:firstNonEmptyLine =~# b:logTimestampExpr || s:lastNonEmptyLine =~# b:logTimestampExpr
	    break
	endif
    endfor
unlet! s:firstNonEmptyLine s:lastNonEmptyLine

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
