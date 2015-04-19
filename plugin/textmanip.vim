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
let s:plug_suffix = {
      \ "auto":    '',
      \ "insert":  '-i',
      \ "replace": '-r',
      \ }

let s:keymap_config = {}
let s:keymap_config.blank = {
      \ 'emodes': ['auto'],
      \ '^': 'above',
      \ 'v': 'below',
      \ }
let s:keymap_config.default = {
      \ 'emodes': ['auto', 'insert', 'replace'],
      \ '^': 'up',
      \ 'v': 'down',
      \ '>': 'right',
      \ '<': 'left',
      \ }

function! s:keymap(mode, action, dir) "{{{1
  let config = a:action ==# 'blank'
        \ ? s:keymap_config.blank : s:keymap_config.default

  for emode in config.emodes
    let plug = printf('<Plug>(textmanip-%s-%s%s)',
          \ a:action, config[a:dir], s:plug_suffix[emode])

    let key = printf('%snoremap <silent> %s', a:mode, plug)
    let cmd = printf(':<C-u>call textmanip#start("%s", "%s", "%s", "%s")<CR>',
          \ a:action, a:dir, a:mode, emode)
    execute key cmd
  endfor
endfunction "}}}

" Normal:
call s:keymap('n', 'duplicate', 'v')
call s:keymap('n', 'duplicate', '^')
call s:keymap('n', 'move',      'v')
call s:keymap('n', 'move',      '^')

" [TODO]
" call s:keymap('n', 'move',      '>')
" call s:keymap('n', 'move',      '<')

" Visual:
call s:keymap('x', 'duplicate', 'v')
call s:keymap('x', 'duplicate', '^')
call s:keymap('x', 'duplicate', '>')
call s:keymap('x', 'duplicate', '<')

call s:keymap('x', 'move',      'v')
call s:keymap('x', 'move',      '^')
call s:keymap('x', 'move',      '>')
call s:keymap('x', 'move',      '<')
call s:keymap('x', 'move1',     '>')
call s:keymap('x', 'move1',     '<')

call s:keymap('n', 'blank',      '^')
call s:keymap('n', 'blank',      'v')
call s:keymap('x', 'blank',      '^')
call s:keymap('x', 'blank',      'v')

" FIXME
function! s:setup_keymap() "{{{
  for [emode, suffix] in items(s:plug_suffix)
    let R = 'textmanip-move-right-1col' . suffix
    let L = 'textmanip-move-left-1col'  . suffix

    exe "xnoremap <silent> <Plug>(".R.") :<C-u>call <SID>obsolete('1col')<CR>"
    exe "xnoremap <silent> <Plug>(".L.") :<C-u>call <SID>obsolete('1col')<CR>"
  endfor
endfunction "}}}
call s:setup_keymap()

function! s:obsolete(what)
  let msg = "[Obsolete]\n"
  if a:what ==# '1col'
    let msg .= "  '<Plug>(textmanip-move-*-1col)' is obsolete\n"
    let msg .= "  '<Plug>(textmanip-move1-*)' for 1col movement\n"
    echohl ErrorMsg 
    echo msg
    echohl None
  endif
endfunction

nnoremap <Plug>(textmanip-toggle-mode) :<C-u>call textmanip#mode('toggle')<CR>
xnoremap <Plug>(textmanip-toggle-mode) :<C-u>call textmanip#mode('toggle')<CR>gv

" Experimental
nnoremap <silent> <Plug>(textmanip-kickout) :<C-u>call textmanip#kickout(0)<CR>
xnoremap <silent> <Plug>(textmanip-kickout) :call textmanip#kickout(0)<CR>

if g:textmanip_enable_mappings
  xmap <C-j> <Plug>(textmanip-move-down)
  xmap <C-k> <Plug>(textmanip-move-up)
  xmap <C-h> <Plug>(textmanip-move-left)
  xmap <C-l> <Plug>(textmanip-move-right)

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
endif

" COMMAND: {{{1
"=================================================================
" Command [FIXME]
command! -range -nargs=* TextmanipKickout call textmanip#kickout(<q-args>)
command! -range -nargs=* TextmanipToggleMode call textmanip#mode('toggle')
command! TextmanipToggleIgnoreShiftWidth
      \ let g:textmanip_move_ignore_shiftwidth = ! g:textmanip_move_ignore_shiftwidth
      \ <bar> echo g:textmanip_move_ignore_shiftwidth

" FINISH: {{{1
let &cpo = s:old_cpo
" vim: foldmethod=marker
