"=============================================================================
" File: text_manup.vim
" Author: t9md <taqumd@gmail.com>
" Version: 1.0
" WebPage: http://github.com/t9md/text_manup.vim
" License: BSD
" Usage:
"   set following keymap in your .vimrc
"
"   Duplicete selected text bellow
"   ================================
"   Linux
"   -----------
"   vmap <M-d> <Plug>(TextManup.duplicate_selection_v)
"   nmap <M-d> <Plug>(TextManup.duplicate_selection_n)
"
"   Mac
"   -----------
"   vmap <D-d> <Plug>(TextManup.duplicate_selection_v)
"   nmap <D-d> <Plug>(TextManup.duplicate_selection_n)


"   Move visually selected text with Control and hjkl
"   ===================================================
"   vmap <C-j> <Plug>(TextManup.move_selection_down)
"   vmap <C-k> <Plug>(TextManup.move_selection_up)
"   vmap <C-h> <Plug>(TextManup.move_selection_left)
"   vmap <C-l> <Plug>(TextManup.move_selection_right)

"for line continuation - i.e dont want C in &cpo
let s:old_cpo = &cpo
set cpo&vim


" Main
"=================================================================
let s:mod = {}
fun! s:mod.duplicate_selection(mode) range dict
	let pos = getpos('.')
	let cmd = a:firstline . ",". a:lastline . "copy " . a:lastline
	execute cmd

	if a:mode ==# 'v'
		normal! `[V`]
	elseif a:mode ==# 'n'
		let pos[1] = line('.')
		call setpos('.', pos)
	endif
endfun

fun! s:mod.move_selection(direction) range dict
	let action       = {}
	let action.down  = a:firstline. ",". a:lastline . "move " . (a:lastline  + 1)
	let action.up    = a:firstline. ",". a:lastline . "move " . (a:firstline - 2)
	let action.right = "normal! gv>>"
	let action.left  = "normal! gv<<"
	execute action[a:direction]
	normal! gv
endfun

let g:TextManup = s:mod

" Configure virtual keymap
"=================================================================
vnoremap <silent> <Plug>(TextManup.duplicate_selection_v) :call TextManup.duplicate_selection('v')<CR>
nnoremap <silent> <Plug>(TextManup.duplicate_selection_n) :call TextManup.duplicate_selection('n')<CR>

vnoremap <silent> <Plug>(TextManup.move_selection_up)    :call TextManup.move_selection('up')<CR>
vnoremap <silent> <Plug>(TextManup.move_selection_down)  :call TextManup.move_selection('down')<CR>
vnoremap <silent> <Plug>(TextManup.move_selection_right) :call TextManup.move_selection('right')<CR>
vnoremap <silent> <Plug>(TextManup.move_selection_left)  :call TextManup.move_selection('left')<CR>


"reset &cpo back to users setting
let &cpo = s:old_cpo
