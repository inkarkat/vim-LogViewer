" log4j_LogViewer.vim: Define the timestamp pattern for the LogViewer.vim plugin.
"
" DEPENDENCIES:
"
" Copyright: (C) 2011-2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.00.001	23-Aug-2011	file creation

let b:logTimestampExpr = '^\d\S\+\d \d\S\+\d\ze\s' " %d, e.g. 2011-08-17 13:08:30,509
if getline(1) !~# b:logTimestampExpr
    let b:logTimestampExpr = '^\d\+\ze\s' " %r, e.g. 467
endif

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
