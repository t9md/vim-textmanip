" Utility: {{{
" =============================
function! s:selected_amount()"{{{
  return line("'>") - line("'<") + 1
endfunction"}}}

function! s:duplicate_visual(direction) "{{{
  let cnt = v:count1

  if a:direction == "down"
    let begin = line("'>") + 1
    let end   = line("'>") + s:selected_amount() * cnt
  else
    let begin = line("'<")
    let end   = begin - 1  + s:selected_amount() * cnt
  endif
  let pos = getpos('.')

  while cnt != 0

    let first_line = line("'<")
    let last_line =  line("'>")

    let copy_to = a:direction == "down" ? last_line : first_line - 1
    silent execute first_line . "," . last_line . "copy " . copy_to
    let cnt -= 1
  endwhile

  let pos[1] = begin
  call setpos('.', pos)
  normal! V
  let pos[1] = end
  call setpos('.', pos)
endfun "}}}

function! s:duplicate_normal(direction)"{{{
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
endfunction"}}}

function! s:textmanip_status()"{{{
  return  {
        \ 'line_start': line("'<"),
        \ 'line_end': line("'>"),
        \ 'lines': getline(line("'<"), line("'>")),
        \ }
endfunction"}}}

function! s:is_sequential_execution()"{{{
  return b:textmanip_status == s:textmanip_status()
endfunction"}}}

function! s:decho(msg) "{{{
  if g:textmanip_debug
    echo a:msg
  endif
endfunction "}}}

function! s:smart_undojoin()"{{{
  if s:is_sequential_execution()
    call s:decho("called undojoin")
    silent undojoin
  endif
endfunction"}}}

function! s:extend_eol(size)"{{{
  call s:decho("  [extended_eol]")
  call append(line('$'), map(range(a:size), '""'))
endfunction"}}}

function! s:left_movable() "{{{
  let lines = getline(line("'<"), line("'>"))
  return !empty(filter(lines,"v:val =~# '^\\s'"))
endfunction "}}}

let s:textmanip_status_default = {
      \ 'line_start': -1,
      \ 'line_end': -1,
      \ 'lines': [],
      \ }
" }}}

" Public API: {{{
" =============================
function! textmanip#duplicate(direction, mode) "{{{
  let org_lazyredraw = &lazyredraw
  set lazyredraw

  if a:mode == "n"
    call s:duplicate_normal(a:direction)
  else
    call s:duplicate_visual(a:direction)
  endif

  let &lazyredraw = org_lazyredraw
  redraw
endfun "}}}

function! textmanip#move(direction) "{{{
  call s:decho(" ")
  if !exists('b:textmanip_status')
    let b:textmanip_status = s:textmanip_status_default
  endif

  if a:direction == "left"
    if ! s:left_movable()
      call s:decho(" can't move left return")
      normal! gv
      return
    endif
  endif

  call s:smart_undojoin()
  if a:direction == "up"
    let address = line("'<") - v:count1 - 1
    let address = address < 0 ? 0 : address
  elseif a:direction == "down"
    let address = line("'>") + v:count1
    let eol_extend_size = address > line('$')
    if eol_extend_size > 0
      call s:extend_eol(eol_extend_size)
    endif
  endif

  let cmd = 
        \ a:direction == "down"  ? "'<,'>move " . address :
        \ a:direction == "up"    ? "'<,'>move " . address :
        \ a:direction == "right" ? "'<,'>" . repeat(">>", v:count1) :
        \ a:direction == "left"  ? "'<,'>" . repeat("<<", v:count1) : ""

  call s:decho("  [executed] " . cmd)
  silent execute cmd
  normal! gv
  let b:textmanip_status = s:textmanip_status()
endfun "}}}

" }}}
" vim: foldmethod=marker
