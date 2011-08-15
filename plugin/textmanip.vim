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

vnoremap <silent> <Plug>(textmanip-move-up)     :<C-u>call textmanip#move('up')<CR>
vnoremap <silent> <Plug>(textmanip-move-down)   :<C-u>call textmanip#move('down')<CR>
vnoremap <silent> <Plug>(textmanip-move-right)  :<C-u>call textmanip#move('right')<CR>
vnoremap <silent> <Plug>(textmanip-move-left)   :<C-u>call textmanip#move('left')<CR>
"}}}

let &cpo = s:old_cpo
" vim: foldmethod=marker
