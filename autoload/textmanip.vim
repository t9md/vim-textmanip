" Utility: {{{
" =============================
function! s:duplicate_visual(direction) "{{{
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

function! s:duplicate_normal(direction) "{{{
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

function! s:up_movable() "{{{
  return s:textmanip_status().start_linenr != 1
endfunction "}}}



function! s:_kickout(num, guide) "{{{
  let orig_str = getline(a:num)
  let s1 = strpart(orig_str, 0, col('.') - 1)
  let s2 = strpart(orig_str, col('.') - 1)

  let pad = &textwidth - len(orig_str)
  let pad = ' ' . repeat(a:guide, pad - 2) . ' '
  let new_str = join([s1, pad, s2],'')
  return new_str
endfunction "}}}
" }}}

" Public API: {{{
" =============================
function! textmanip#duplicate(direction, mode) "{{{
  if a:mode == "n"
    call s:duplicate_normal(a:direction)
  elseif a:mode == "v"
    call s:duplicate_visual(a:direction)
  endif
endfun "}}}

function! textmanip#kickout(ask) range "{{{
  let answer = a:ask ? input("guide?:") : ''
  let guide = !empty(answer) ? answer : ' '
  let orig_pos = getpos('.')
  if !(a:firstline == a:lastline)
    normal! gvv
  endif
  for n in range(a:firstline,a:lastline)
    call setline(n, s:_kickout(n, guide))
  endfor
  call setpos('.', orig_pos)
endfunction "}}}

function! textmanip#move_block(direction) "{{{
  if a:direction ==# "left" && col("'<") ==# 1
    normal! gv
    return
  endif
  if ( a:direction ==# "right" ) && ( col("'>") == (col("$") - 1) )
    substitute/\v$/ /
  endif

  let save_z = getreg('z', 1)
  let save_z_type = getregtype('z')
  try
    normal! gv"zd
    if a:direction ==# 'right'
      normal! p
    elseif a:direction ==# 'left'
      if col('.') ==# col("'<")
        " if col("'>") is the last printable char, we can't put cursor on same
        " pos of col("'<") after delete. so we neeed ensure it.
        normal! h
      endif
      normal! P
    endif
    execute "normal! `[" . visualmode() . "`]"
  finally
    call setreg('z', save_z, save_z_type)
  endtry
endfunction "}}}

function! textmanip#move_smart(direction) "{{{
  let vmode =  visualmode()
  if vmode ==# 'V'
    call textmanip#move_line(a:direction)
  elseif vmode == 'v'
    if line("'<") ==# line("'>")
      call textmanip#move_block(a:direction)
    else
      call textmanip#move_line(a:direction)
    endif
  else
    call textmanip#move_block(a:direction)
  endif
endfunction "}}}

function! textmanip#move_line(direction) "{{{
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

" function! textmanip#move()
" endfunction
" }}}
" vim: foldmethod=marker
