function! textmanip#duplicate(direction, mode) "{{{
  let org_lazyredraw = &lazyredraw
  set lazyredraw

  let cnt = v:count1
  while cnt != 0

    let pos = getpos('.')

    if a:mode == 'n'
      let first_line = line('.')
      let last_line =  line('.')
    elseif a:mode == 'v'
      let first_line = line("'<")
      let last_line =  line("'>")
    endif

    let copy_to = a:direction == "down" ? last_line : first_line - 1
    silent execute first_line . "," . last_line . "copy " . copy_to
    let cnt -= 1
  endwhile

  if a:mode ==# 'v'
    normal! `[V`]
  elseif a:mode ==# 'n'
    let pos[1] = line('.')
    call setpos('.', pos)
  endif

  let &lazyredraw = org_lazyredraw
  redraw
endfun "}}}

let g:textmanip_debug = 0
function! textmanip#move(direction) "{{{
  if !exists('b:textmanip_status')
    let b:textmanip_status = [ -1, -1, -1 ]
  endif

  let sequential_execution = 0
  if b:textmanip_status == [line("'<"), line("'>"), col("'>") ]
    let sequential_execution = 1
  endif

  let cnt = v:count1

  if a:direction == "up"
    let where = line("'<") - cnt - 1
    if where < 0
      let where = 0
    endif
  elseif a:direction == "down"
    let where = line("'>") + cnt

    let add_lines = where - line('$')
    if add_lines > 0
      let list = []
      for i in range(add_lines)
        call add(list, '')
      endfor
      if sequential_execution
        silent undojoin
      endif
      call append(line('$'), list)
    endif
  endif

  let cmd = 
        \ a:direction == "down"  ? "'<,'>move " . where :
        \ a:direction == "up"    ? "'<,'>move " . where :
        \ a:direction == "right" ? "'<,'>" . repeat(">>",cnt) :
        \ a:direction == "left"  ? "'<,'>" . repeat("<<",cnt) : ""


  if sequential_execution
    if g:textmanip_debug
      let b:textmanip_continue_count += 1
      echo "Continue: " . b:textmanip_continue_count
      echo "Continue: " . b:textmanip_continue_count
    endif
    try
      silent undojoin
    catch /E790/
      if g:textmanip_debug
        echo "exception E790"
      endif
    endtry
  else
    if g:textmanip_debug
      let b:textmanip_continue_count = 1
      echo "Start: " . b:textmanip_continue_count
      echo "Start: " . b:textmanip_continue_count
    endif
  endif

  silent execute cmd

  normal! gv
  let cnt -= 1

  let b:textmanip_status = [line("'<"), line("'>"), col("'>") ]
endfun "}}}
" vim: foldmethod=marker
