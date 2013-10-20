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
vnoremap <Plug>(textmanip-duplicate-down) <Esc>:<C-u>call textmanip#duplicate('down','v')<CR>
nnoremap <Plug>(textmanip-duplicate-down)      :<C-u>call textmanip#duplicate('down','n')<CR>
vnoremap <Plug>(textmanip-duplicate-up)   <Esc>:<C-u>call textmanip#duplicate('up','v')<CR>
nnoremap <Plug>(textmanip-duplicate-up)        :<C-u>call textmanip#duplicate('up','n')<CR>

vnoremap <Plug>(textmanip-move-up)    :<C-u>call textmanip#move('up')<CR>
vnoremap <Plug>(textmanip-move-down)  :<C-u>call textmanip#move('down')<CR>
vnoremap <Plug>(textmanip-move-right) :<C-u>call textmanip#move('right')<CR>
vnoremap <Plug>(textmanip-move-left)  :<C-u>call textmanip#move('left')<CR>

nnoremap <Plug>(textmanip-debug)   :<C-u>echo textmanip#debug()<CR>

" Experimental
nnoremap <silent> <Plug>(textmanip-kickout)  :<C-u>call textmanip#kickout(0)<CR>
vnoremap <silent> <Plug>(textmanip-kickout)  :call textmanip#kickout(0)<CR>
"}}}
"
if exists("g:textmanip_enable_mappings")
  let g:textmanip_enable_mappings = 0
endif

function! s:set_default_mapping() "{{{
  if has('gui_macvim')
    " '<D-' Command key
    nmap <D-d> <Plug>(textmanip-duplicate-down)
    nmap <D-D> <Plug>(textmanip-duplicate-up)

    xmap <D-d> <Plug>(textmanip-duplicate-down)
    xmap <D-D> <Plug>(textmanip-duplicate-up)
  elseif ( has('win16') || has('win32') || has('win64') )
    " '<M->' Alt key
    nmap <M-d> <Plug>(textmanip-duplicate-down)
    nmap <M-D> <Plug>(textmanip-duplicate-up)

    xmap <M-d> <Plug>(textmanip-duplicate-down)
    xmap <M-D> <Plug>(textmanip-duplicate-up)
  endif

  xmap <C-j> <Plug>(textmanip-move-line-down)
  xmap <C-k> <Plug>(textmanip-move-line-up)
  xmap <C-h> <Plug>(textmanip-move-smart-left)
  xmap <C-l> <Plug>(textmanip-move-smart-right)
endfunction "}}}

if g:textmanip_enable_mappings
  call s:set_default_mapping()
endif

let &cpo = s:old_cpo
" vim: foldmethod=marker
