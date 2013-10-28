"=============================================================================
" File: textmanip.vim
" Author: t9md <taqumd@gmail.com>
" WebPage: http://github.com/t9md/textmanip.vim
" License: BSD

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
vnoremap <silent> <Plug>(textmanip-duplicate-down) <Esc>:<C-u>call textmanip#do('dup', 'down','v')<CR>
nnoremap <silent> <Plug>(textmanip-duplicate-down)      :<C-u>call textmanip#do('dup', 'down','n')<CR>
vnoremap <silent> <Plug>(textmanip-duplicate-up)   <Esc>:<C-u>call textmanip#do('dup', 'up','v')<CR>
nnoremap <silent> <Plug>(textmanip-duplicate-up)        :<C-u>call textmanip#do('dup', 'up','n')<CR>

vnoremap <silent> <Plug>(textmanip-move-up)    :<C-u>call textmanip#do('move', 'up', 'v')<CR>
vnoremap <silent> <Plug>(textmanip-move-down)  :<C-u>call textmanip#do('move', 'down', 'v')<CR>
vnoremap <silent> <Plug>(textmanip-move-right) :<C-u>call textmanip#do('move', 'right', 'v')<CR>
vnoremap <silent> <Plug>(textmanip-move-left)  :<C-u>call textmanip#do('move', 'left', 'v')<CR>

" experimental dirty hack
vnoremap <silent> <Plug>(textmanip-move-right-1col) :<C-u>call textmanip#do1('move', 'right', 'v')<CR>
vnoremap <silent> <Plug>(textmanip-move-left-1col)  :<C-u>call textmanip#do1('move', 'left', 'v')<CR>

nnoremap <Plug>(textmanip-debug) :<C-u>echo textmanip#debug()<CR>
" Experimental
nnoremap <silent> <Plug>(textmanip-kickout) :<C-u>call textmanip#kickout(0)<CR>
vnoremap <silent> <Plug>(textmanip-kickout) :call textmanip#kickout(0)<CR>

" Command [FIXME]
command! -range -nargs=* TextmanipKickout call textmanip#kickout(<q-args>)
command! TextmanipToggleIgnoreShiftWidth
      \ let g:textmanip_move_ignore_shiftwidth = ! g:textmanip_move_ignore_shiftwidth
      \ <bar> echo g:textmanip_move_ignore_shiftwidth
"}}}

if !exists("g:textmanip_enable_mappings")
  let g:textmanip_enable_mappings = 0
endif
if !exists("g:textmanip_move_ignore_shiftwidth")
  let g:textmanip_move_ignore_shiftwidth = 0
endif
if !exists("g:textmanip_move_shiftwidth")
  let g:textmanip_move_shiftwidth = 1
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
