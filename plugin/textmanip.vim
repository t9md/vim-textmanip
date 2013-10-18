"=============================================================================
" File: textmanip.vim
" Author: t9md <taqumd@gmail.com>
" WebPage: http://github.com/t9md/textmanip.vim
" License: BSD
" Version: 0.7

" GUARD: {{{
"============================================================
if exists('g:loaded_textmanip')
  finish
endif
let g:loaded_textmanip = 1

let s:old_cpo = &cpo
set cpo&vim
"}}}

let g:textmanip_debug = 0

" KEYMAP: {{{
"=================================================================
vnoremap <silent> <Plug>(textmanip-duplicate-down) <Esc>:<C-u>call textmanip#duplicate('down','v')<CR>
nnoremap <silent> <Plug>(textmanip-duplicate-down)      :<C-u>call textmanip#duplicate('down','n')<CR>
vnoremap <silent> <Plug>(textmanip-duplicate-up)   <Esc>:<C-u>call textmanip#duplicate('up','v')<CR>
nnoremap <silent> <Plug>(textmanip-duplicate-up)        :<C-u>call textmanip#duplicate('up','n')<CR>

vnoremap <silent> <Plug>(textmanip-move-up)     :<C-u>call textmanip#move_l('up')<CR>
vnoremap <silent> <Plug>(textmanip-move-down)   :<C-u>call textmanip#move_l('down')<CR>
vnoremap <silent> <Plug>(textmanip-move-right)  :<C-u>call textmanip#move_l('right')<CR>
vnoremap <silent> <Plug>(textmanip-move-left)   :<C-u>call textmanip#move_l('left')<CR>

vnoremap <silent> <Plug>(textmanip-move-s-right)  :<C-u>call textmanip#move_smart('right')<CR>
vnoremap <silent> <Plug>(textmanip-move-s-left)   :<C-u>call textmanip#move_smart('left')<CR>

vnoremap <silent> <Plug>(textmanip-move-l-up)     :<C-u>call textmanip#move_l('up')<CR>
vnoremap <silent> <Plug>(textmanip-move-l-down)   :<C-u>call textmanip#move_l('down')<CR>
vnoremap <silent> <Plug>(textmanip-move-l-right)  :<C-u>call textmanip#move_l('right')<CR>
vnoremap <silent> <Plug>(textmanip-move-l-left)   :<C-u>call textmanip#move_l('left')<CR>

vnoremap <silent> <Plug>(textmanip-move-b-right)  :<C-u>call textmanip#move_b('right')<CR>
vnoremap <silent> <Plug>(textmanip-move-b-left)   :<C-u>call textmanip#move_b('left')<CR>

" Experimental
nnoremap <silent> <Plug>(textmanip-kickout)  :<C-u>call textmanip#kickout(0)<CR>
vnoremap <silent> <Plug>(textmanip-kickout)  :call textmanip#kickout(0)<CR>
"}}}

let &cpo = s:old_cpo
" vim: foldmethod=marker
