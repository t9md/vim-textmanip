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

let s:direction_map = {
      \ '^': 'up',
      \ 'v': 'down',
      \ '>': 'right',
      \ '<': 'left',
      \ }

function! s:keymap(mode, action, dir) "{{{1
  for [emode, suffix] in items(s:plug_suffix)
    let plug = printf('<Plug>(textmanip-%s-%s%s)',
          \ a:action, s:direction_map[a:dir], suffix )

    let action_short = a:action is 'duplicate' ? 'dup' : a:action

    let key = printf('%snoremap <silent> %s', a:mode, plug)
    let cmd = printf(':<C-u>call textmanip#do("%s", "%s", "%s", "%s")<CR>',
          \ action_short, a:dir, a:mode, emode)
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


" FIXME
function! s:setup_keymap() "{{{
  for [emode, suffix] in items(s:plug_suffix)
    let mov_r_1 = 'textmanip-move-right-1col' . suffix
    let mov_l_1 = 'textmanip-move-left-1col'  . suffix

    exe "xnoremap <silent> <Plug>(" . mov_l_1 . ") :<C-u>call textmanip#do1('move', '<', 'x', '" . emode . "')<CR>"
    exe "xnoremap <silent> <Plug>(" . mov_r_1 . ") :<C-u>call textmanip#do1('move', '>', 'x', '" . emode . "')<CR>"
  endfor
endfunction "}}}
call s:setup_keymap()

nnoremap <silent> <Plug>(textmanip-blank-above)  :<C-u>call textmanip#do('blank', '^', 'n', 'auto')<CR>
nnoremap <silent> <Plug>(textmanip-blank-below)  :<C-u>call textmanip#do('blank', 'v', 'n', 'auto')<CR>

xnoremap <silent> <Plug>(textmanip-blank-above)  :<C-u>call textmanip#do('blank', '^', 'x', 'auto')<CR>
xnoremap <silent> <Plug>(textmanip-blank-below)  :<C-u>call textmanip#do('blank', 'v', 'x', 'auto')<CR>

nnoremap <Plug>(textmanip-debug) :<C-u>call textmanip#debug()<CR>
xnoremap <Plug>(textmanip-debug) :<C-u>call textmanip#debug()<CR>

nnoremap <Plug>(textmanip-toggle-mode) :<C-u>call textmanip#toggle_mode()<CR>
xnoremap <Plug>(textmanip-toggle-mode) :<C-u>call textmanip#toggle_mode()<CR>gv

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
command! -range -nargs=* TextmanipToggleMode call textmanip#toggle_mode()
command! TextmanipToggleIgnoreShiftWidth
      \ let g:textmanip_move_ignore_shiftwidth = ! g:textmanip_move_ignore_shiftwidth
      \ <bar> echo g:textmanip_move_ignore_shiftwidth

" FINISH: {{{1
let &cpo = s:old_cpo
" vim: foldmethod=marker
