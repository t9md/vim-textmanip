"=============================================================================
" File: textmanip.vim
" Author: t9md <taqumd@gmail.com>
" WebPage: http://github.com/t9md/textmanip.vim
" License: BSD

" GUARD: {{{1
"============================================================
if expand("%:p") ==# expand("<sfile>:p")
  unlet! g:loaded_textmanip
endif
if exists('g:loaded_textmanip')
  finish
endif
let g:loaded_textmanip = 1

let s:old_cpo = &cpo
set cpo&vim

" VARIABLES: {{{1
"=================================================================
let g:textmanip_debug = 0
let s:global_variables = {
      \ "textmanip_enable_mappings" : 0,
      \ "textmanip_startup_mode"    : "insert",
      \ "textmanip_move_ignore_shiftwidth" : 0,
      \ "textmanip_move_shiftwidth" : 1,
      \ }

function! s:set_default(dict) "{{{
  for [name, val] in items(a:dict)
    let g:{name} = get(g:, name, val)
    unlet name val
  endfor
endfunction "}}}

call s:set_default(s:global_variables)
let g:textmanip_current_mode = g:textmanip_startup_mode

" KEYMAP: {{{1
"=================================================================
function! s:setup_keymap() "{{{
  let plug_suffix = {
        \ "auto": '',
        \ "insert": '-i',
        \ "replace": '-r',
        \ }
  for [mode, suffix] in items(plug_suffix)

    let dup_u = 'textmanip-duplicate-up'    . suffix
    let dup_d = 'textmanip-duplicate-down'  . suffix
    let dup_l = 'textmanip-duplicate-left'  . suffix
    let dup_r = 'textmanip-duplicate-right' . suffix

    let mov_u = 'textmanip-move-up'    . suffix
    let mov_d = 'textmanip-move-down'  . suffix
    let mov_r = 'textmanip-move-right' . suffix
    let mov_l = 'textmanip-move-left'  . suffix

    let mov_r_1 = 'textmanip-move-right-1col' . suffix
    let mov_l_1 = 'textmanip-move-left-1col'  . suffix

    " echo '"#' mode
    " echo '"normal'
    exe "nnoremap <silent> <Plug>(" . dup_u . ") :<C-u>call textmanip#do('dup', 'u', 'n', '" . mode . "')<CR>"
    exe "nnoremap <silent> <Plug>(" . dup_d . ") :<C-u>call textmanip#do('dup', 'd', 'n', '" . mode . "')<CR>"

    " echo '"dup-visual'
    exe "xnoremap <silent> <Plug>(" . dup_u . ") :<C-u>call textmanip#do('dup', 'u', 'v', '" . mode . "')<CR>"
    exe "xnoremap <silent> <Plug>(" . dup_d . ") :<C-u>call textmanip#do('dup', 'd', 'v', '" . mode . "')<CR>"
    exe "xnoremap <silent> <Plug>(" . dup_l . ") :<C-u>call textmanip#do('dup', 'l', 'v', '" . mode . "')<CR>"
    exe "xnoremap <silent> <Plug>(" . dup_r . ") :<C-u>call textmanip#do('dup', 'r', 'v', '" . mode . "')<CR>"

    " move: visual'
    exe "xnoremap <silent> <Plug>(" . mov_u . ") :<C-u>call textmanip#do('move', 'u', 'v', '" . mode . "')<CR>"
    exe "xnoremap <silent> <Plug>(" . mov_d . ") :<C-u>call textmanip#do('move', 'd', 'v', '" . mode . "')<CR>"
    exe "xnoremap <silent> <Plug>(" . mov_l . ") :<C-u>call textmanip#do('move', 'l', 'v', '" . mode . "')<CR>"
    exe "xnoremap <silent> <Plug>(" . mov_r . ") :<C-u>call textmanip#do('move', 'r', 'v', '" . mode . "')<CR>"

    " move: normal
    exe "nnoremap <silent> <Plug>(" . mov_u . ") :<C-u>call textmanip#do('move', 'u', 'n', '" . mode . "')<CR>"
    exe "nnoremap <silent> <Plug>(" . mov_d . ") :<C-u>call textmanip#do('move', 'd', 'n', '" . mode . "')<CR>"
    " exe "nnoremap <silent> <Plug>(" . mov_l . ") :<C-u>call textmanip#do('move', 'l', 'n', '" . mode . "')<CR>"
    " exe "nnoremap <silent> <Plug>(" . mov_r . ") :<C-u>call textmanip#do('move', 'r', 'n', '" . mode . "')<CR>"

    exe "xnoremap <silent> <Plug>(" . mov_l_1 . ") :<C-u>call textmanip#do1('move', 'l', 'v', '" . mode . "')<CR>"
    exe "xnoremap <silent> <Plug>(" . mov_r_1 . ") :<C-u>call textmanip#do1('move', 'r', 'v', '" . mode . "')<CR>"
    " echo ''
  endfor
endfunction "}}}

call s:setup_keymap()

nnoremap <silent> <Plug>(textmanip-blank-above)  :<C-u>call textmanip#do('blank', 'u', 'n', 'auto')<CR>
nnoremap <silent> <Plug>(textmanip-blank-below)  :<C-u>call textmanip#do('blank', 'd', 'n', 'auto')<CR>

xnoremap <silent> <Plug>(textmanip-blank-above)  :<C-u>call textmanip#do('blank', 'u', 'v', 'auto')<CR>
xnoremap <silent> <Plug>(textmanip-blank-below)  :<C-u>call textmanip#do('blank', 'd', 'v', 'auto')<CR>

nnoremap <Plug>(textmanip-debug) :<C-u>call textmanip#debug()<CR>
xnoremap <Plug>(textmanip-debug) :<C-u>call textmanip#debug()<CR>

nnoremap <Plug>(textmanip-toggle-mode) :<C-u>call textmanip#toggle_mode()<CR>
xnoremap <Plug>(textmanip-toggle-mode) :<C-u>call textmanip#toggle_mode()<CR>gv

" Experimental
nnoremap <silent> <Plug>(textmanip-kickout) :<C-u>call textmanip#kickout(0)<CR>
xnoremap <silent> <Plug>(textmanip-kickout) :call textmanip#kickout(0)<CR>

if g:textmanip_enable_mappings
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
endif

" COMMAND: {{{1
"=================================================================
" Command [FIXME]
command! -range -nargs=* TextmanipKickout call textmanip#kickout(<q-args>)
command! -range -nargs=* TextmanipToggleMode call textmanip#toggle_mode()
command! TextmanipToggleIgnoreShiftWidth
      \ let g:textmanip_move_ignore_shiftwidth = ! g:textmanip_move_ignore_shiftwidth
      \ <bar> echo g:textmanip_move_ignore_shiftwidth

" FINISH: {{{1
let &cpo = s:old_cpo
" vim: foldmethod=marker
