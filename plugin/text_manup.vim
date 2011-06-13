"=============================================================================
" File: textmanip.vim
" Author: t9md <taqumd@gmail.com>
" WebPage: http://github.com/t9md/textmanip.vim
" License: BSD
" Version: 0.2

" GUARD: {{{
"============================================================
" if exists('g:loaded_textmanip')
  " finish
" endif

"for line continuation - i.e dont want C in &cpo
let s:old_cpo = &cpo
set cpo&vim
"}}}

" Main
"=================================================================
let s:mod = {}
fun! s:mod.duplicate_selection(mode) range "{{{
	let pos = getpos('.')
	let cmd = a:firstline . ",". a:lastline . "copy " . a:lastline
	execute cmd

	if a:mode ==# 'v'
		normal! `[V`]
	elseif a:mode ==# 'n'
		let pos[1] = line('.')
		call setpos('.', pos)
	endif
endfun "}}}

fun! s:mod.move_selection(direction) range "{{{
	let action       = {}
	let action.down  = a:firstline. ",". a:lastline . "move " . (a:lastline  + 1)
	let action.up    = a:firstline. ",". a:lastline . "move " . (a:firstline - 2)
	let action.right = "normal! gv>>"
	let action.left  = "normal! gv<<"

  if a:direction == 'down' && a:lastline == line('$')
    call append(line('$'), "")
  endif

	execute action[a:direction]
	normal! gv
endfun "}}}

let g:Textmanip= s:mod

" Configure virtual keymap "{{{
"=================================================================
vnoremap <silent> <Plug>(Textmanip.duplicate_selection_v) :call Textmanip.duplicate_selection('v')<CR>
nnoremap <silent> <Plug>(Textmanip.duplicate_selection_n) :call Textmanip.duplicate_selection('n')<CR>

vnoremap <silent> <Plug>(Textmanip.move_selection_up)     :call Textmanip.move_selection('up')<CR>
vnoremap <silent> <Plug>(Textmanip.move_selection_down)   :call Textmanip.move_selection('down')<CR>
vnoremap <silent> <Plug>(Textmanip.move_selection_right)  :call Textmanip.move_selection('right')<CR>
vnoremap <silent> <Plug>(Textmanip.move_selection_left)   :call Textmanip.move_selection('left')<CR>
"}}}

"reset &cpo back to users setting
let &cpo = s:old_cpo

" vim: foldmethod=marker
