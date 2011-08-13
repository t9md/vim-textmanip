"=============================================================================
" File: textmanip.vim
" Author: t9md <taqumd@gmail.com>
" WebPage: http://github.com/t9md/textmanip.vim
" License: BSD
" Version: 0.3

" GUARD: {{{
"============================================================
if exists('g:loaded_textmanip')
  finish
endif

let s:old_cpo = &cpo
set cpo&vim
"}}}

" KEYMAP: {{{
"=================================================================
vnoremap <silent> <Plug>(textmanip-duplicate-v) :call textmanip#duplicate('v')<CR>
nnoremap <silent> <Plug>(textmanip-duplicate-n) :call textmanip#duplicate('n')<CR>

vnoremap <silent> <Plug>(textmanip-move-up)     :call textmanip#move('up')<CR>
vnoremap <silent> <Plug>(textmanip-move-down)   :call textmanip#move('down')<CR>
vnoremap <silent> <Plug>(textmanip-move-right)  :call textmanip#move('right')<CR>
vnoremap <silent> <Plug>(textmanip-move-left)   :call textmanip#move('left')<CR>
"}}}

let &cpo = s:old_cpo
" vim: foldmethod=marker
