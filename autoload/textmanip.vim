function! s:selected_amount()
  return line("'>") - line("'<") + 1
endfunction

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

    if where > line('$')
      let amount = where - line('$')
      let list = map(range(amount), '""')
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
    try
      silent undojoin
    catch /E790/
      if g:textmanip_debug
        echo "exception E790"
      endif
    endtry
  endif

  if g:textmanip_debug "{{{
    if sequential_execution
      let b:textmanip_continue_count += 1
      echo "Continue: " . b:textmanip_continue_count
      echo "Continue: " . b:textmanip_continue_count
    else
      let b:textmanip_continue_count = 1
      echo "Start: " . b:textmanip_continue_count
      echo "Start: " . b:textmanip_continue_count
    endif
  endif"}}}

  silent execute cmd

  normal! gv
  let cnt -= 1

  let b:textmanip_status = [line("'<"), line("'>"), col("'>") ]
endfun "}}}
" vim: foldmethod=marker
