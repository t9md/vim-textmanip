" Utility:
"=================================================================
function! s:textmanip_status() "{{{
  let lines = getline(line("'<"), line("'>"))
  return  {
        \ 'start_linenr': line("'<"),
        \ 'end_linenr': line("'>"),
        \ 'lines': lines,
        \ 'len': len(lines),
        \ }
endfunction "}}}

function! s:is_continuous_execution() "{{{
  if !exists('b:textmanip_status')
    return 0
  else
    return b:textmanip_status == s:textmanip_status()
  endif
endfunction "}}}

let g:textmanip_debug = 0
function! s:decho(msg) "{{{
  if g:textmanip_debug
    echo a:msg
  endif
endfunction "}}}

function! s:smart_undojoin() "{{{
  if s:is_continuous_execution()
    call s:decho("called undojoin")
    silent undojoin
  endif
endfunction "}}}

function! s:extend_eol(size) "{{{
  call s:decho("  [extended_eol]")
  call append(line('$'), map(range(a:size), '""'))
endfunction "}}}

function! s:left_movable() "{{{
  return !empty(filter(
        \  s:textmanip_status().lines,
        \ "v:val =~# '^\\s'")
        \ )
endfunction "}}}

function! s:vblock_workaround() "{{{
  " [FIXME] darty workaround. When virtualedit='all' "`[" pos is one char right of
  " actuall changed, so need to adjust with 'h'.
  return char2nr(visualmode()) ==# char2nr("\<C-v>") ? "h" : ""
endfunction "}}}

function! s:up_movable() "{{{
  return s:textmanip_status().start_linenr != 1
endfunction "}}}

function! s:is_linewise() "{{{
  let vmode = visualmode()
  return vmode ==# 'V' ||
        \ vmode ==# 'v' && ( line("'<") !=# line("'>") ) 
endfunction "}}}

" Object:
"=================================================================
let s:textmanip = {}

" Move:
function! s:textmanip.move_smart(direction) "{{{
  " [FIXME] need imprement blockwise movement for up/down
  " if a:direction ==# "up"
  " " if a:direction ==# "up" || a:direction ==# "down"
    " call self.move_line(a:direction)
    " return
  " endif

  if s:is_linewise()
    call self.move_line(a:direction)
  else
    call self.move_block(a:direction)
  endif
endfunction "}}}

function! s:textmanip.move_line(direction) "{{{
  call s:decho(" ")
  let movable =
        \ a:direction == "left" ? s:left_movable() :
        \ a:direction == "up"   ? s:up_movable()   :
        \ 1
  if !movable
      call s:decho(" can't move " . a:direction . "; return")
      normal! gv
      return
  endif

  let status = s:textmanip_status()
  call s:smart_undojoin()
  if a:direction == "up"
    let address = status.start_linenr - v:count1 - 1
    let address = address < 0 ? 0 : address
  elseif a:direction == "down"
    let address = status.end_linenr + v:count1
    let eol_extend_size = address - line('$')
    if eol_extend_size > 0
      call s:extend_eol(eol_extend_size)
    endif
  endif

  let cmd =
        \ a:direction == "down"  ? "'<,'>move " . address           :
        \ a:direction == "up"    ? "'<,'>move " . address           :
        \ a:direction == "right" ? "'<,'>" . repeat(">", v:count1) :
        \ a:direction == "left"  ? "'<,'>" . repeat("<", v:count1) :
        \ ""

  call s:decho("  [executed] " . cmd)
  silent execute cmd
  normal! gv
  let b:textmanip_status = s:textmanip_status()
endfun "}}}

function! s:textmanip.virtualedit() "{{{
  let self._virtualedit = &virtualedit
  let &virtualedit = 'all'
endfunction "}}}

function! s:textmanip.restore_virtualedit() "{{{
  let &virtualedit = self._virtualedit
endfunction "}}}

function! s:textmanip.move_block(direction) "{{{
  if a:direction ==# 'left' || a:direction ==# 'right'
    call s:textmanip.move_block_hl(a:direction)
  elseif a:direction ==# 'up' || a:direction ==# 'down'
    call s:textmanip.move_block_jk(a:direction)
  endif
endfunction "}}}


" RegisterManagement:
let s:register = {}
let s:register._data = {}
function! s:register.save(...) "{{{
  for r in a:000
    let s:register._data[r] = { "content": getreg(r, 1), "type": getregtype(r) }
  endfor
endfunction "}}}

function! s:register.restore() "{{{
  for [r, val] in items(self._data)
    call setreg(r, val.content, val.type)
  endfor
  let self._data = {}
endfunction "}}}

function! s:register.dump() "{{{
  echo PP(self._save)
endfunction "}}}

function! s:textmanip.move_block_hl(direction) "{{{
  if a:direction ==# "left" && col("'<") ==# 1
    normal! gv
    return
  endif

  call s:smart_undojoin()
  call s:register.save("z")
  try
    call self.virtualedit()
    execute 'normal! gv"zd' . (a:direction ==# "right" ? "p" : "hP" )
    execute "normal! `[" .
          \ ( a:direction ==# 'left' ? s:vblock_workaround() : '' ) .
          \ visualmode() . "`]"
  finally
    let b:textmanip_status = s:textmanip_status() "{{{
    call s:register.restore()
    call self.restore_virtualedit() "}}}
  endtry
endfunction "}}}

function! s:textmanip.move_block_jk(direction) "{{{
  " call s:smart_undojoin()
  call s:register.save("w", "x", "y", "z")
  try
    " call self.virtualedit()
    if visualmode() ==# 'v' && line("'<") ==# line("'>")
      normal! my
      normal! gv"zd
      let num = len(@z) - 1
      exe "normal! " . (a:direction ==# "down" ? "j" : "k" ) . "P"
      exe "normal! lv" . num . "l"
      normal! "zd`yP
      exe "normal! ". (a:direction ==# "down" ? "j" : "k") . "v" .num ."ho"
    else
      let height = line("'>") - line("'<") + 1
      let width = col("'>") - col("'<") + 1
      if a:direction ==# "up"
        normal! gv"xy
        exe 'normal! k"yy' . width . "l"
        call setreg("z", @x . "\n" . @y, getregtype("x"))
        exe "normal! " . visualmode() . '`>"zp'
        normal! gvk
      elseif a:direction ==# "down"
        normal! gv"xy
        exe "normal! " . height . "j"
        exe 'normal! "yy' . width . "l"
        call setreg("z", @y . "\n" . @x, getregtype("x"))
        exe 'normal! ' . (width-1). "l"
        exe 'normal! `<' . visualmode() . "`>j"
        normal! "zp
        exe 'normal! `<j' . visualmode() . "`>"
      endif
    endif
  finally
    " let b:textmanip_status = s:textmanip_status()
    " echo s:textmanip_status()
    call s:register.restore()
    " call self.restore_virtualedit()
  endtry
endfunction "}}}

" Duplicate:
function! s:textmanip.duplicate_visual(direction) "{{{
  let pos = getpos('.')
  let status = s:textmanip_status()

  let loop = v:prevcount ? v:prevcount : 1
  while loop != 0
    let copy_to = a:direction == "down"
          \ ? status.end_linenr
          \ : status.start_linenr - 1
    let cmd = status.start_linenr . "," . status.end_linenr . "copy " . copy_to
    silent execute cmd
    call s:decho("  [executed] " . cmd)
    let loop -= 1
  endwhile

  let cnt = v:prevcount ? v:prevcount : 1
  if a:direction == "down"
    let begin_line = status.end_linenr + 1
    let end_line   = status.end_linenr + (status.len * cnt)
  elseif a:direction == "up"
    let begin_line = status.start_linenr
    let end_line   = status.start_linenr - 1 + (status.len * cnt)
  endif

  let pos[1] = begin_line
  call setpos('.', pos)
  normal! V
  let pos[1] = end_line
  call setpos('.', pos)
endfun "}}}

function! s:textmanip.duplicate_normal(direction) "{{{
  let cnt = v:count1
  while cnt != 0
    let pos = getpos('.')

    let first_line = line('.')
    let last_line =  line('.')

    let copy_to = a:direction == "down" ? last_line : first_line - 1
    silent execute first_line . "," . last_line . "copy " . copy_to
    let cnt -= 1
  endwhile

  let pos[1] = line('.')
  call setpos('.', pos)
endfunction "}}}

function! s:textmanip.duplicate(direction, mode) "{{{
  if a:mode     ==# "n"
    call self.duplicate_normal(a:direction)
  elseif a:mode ==# "v"
    call self.duplicate_visual(a:direction)
  endif
endfunction "}}}

" Other:
function! s:textmanip.kickout(num, guide) "{{{
  let orig_str = getline(a:num)
  let s1 = strpart(orig_str, 0, col('.') - 1)
  let s2 = strpart(orig_str, col('.') - 1)

  let pad = &textwidth - len(orig_str)
  let pad = ' ' . repeat(a:guide, pad - 2) . ' '
  let new_str = join([s1, pad, s2],'')
  return new_str
endfunction "}}}

" PlublicInterface:
"=================================================================
" Move:
function! textmanip#move(direction, wise) "{{{
  if a:wise ==# 'line'
    call s:textmanip.move_line(a:direction)
  elseif a:wise ==# 'block'
    call s:textmanip.move_block(a:direction)
  elseif a:wise ==# 'smart'
    call s:textmanip.move_smart(a:direction)
  endif
endfunction "}}}

" Duplicate:
function! textmanip#duplicate(direction, mode) "{{{
  call s:textmanip.duplicate(a:direction, a:mode)
endfun "}}}

" Other:
function! textmanip#kickout(ask) range "{{{
  let answer = a:ask ? input("guide?:") : ''
  let guide = !empty(answer) ? answer : ' '
  let orig_pos = getpos('.')
  if !(a:firstline == a:lastline)
    normal! gvv
  endif
  for n in range(a:firstline,a:lastline)
    call setline(n, s:textmanip.kickout(n, guide))
  endfor
  call setpos('.', orig_pos)
endfunction "}}}

function! textmanip#debug()
  return PP(s:textmanip)
endfunction

" vim: foldmethod=marker
