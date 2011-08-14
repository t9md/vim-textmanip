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
        \ 'col': col("'>"),
        \ }
        " \ 'lines': getline(line("'<"), line("'>")),
endfunction"}}}

function! s:is_sequential_execution()"{{{
  return b:textmanip_status == s:textmanip_status()
endfunction"}}}

function! s:smart_undojoin()"{{{
  if s:is_sequential_execution()
    silent undojoin
  endif
endfunction"}}}

function! s:smart_extend_eol(address)"{{{
  if a:address > line('$') " require EOL extention?
    " OK. Let's build empty array to extend EOL
    call s:smart_undojoin()
    call append(line('$'), map(range(a:address - line('$')), '""'))
    return 1
  else
    return 0
  endif
endfunction"}}}

let s:textmanip_status_default = {
      \ 'line_start': -1,
      \ 'line_end': -1,
      \ 'col': col("'>"),
      \ }
      " \ 'lines': [],
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
  let amount               = v:count1
  if !exists('b:textmanip_status')
    let b:textmanip_status = s:textmanip_status_default
  endif

  if a:direction == "up"
    let address = line("'<") - amount - 1
    let address = address < 0 ? 0 : address
  elseif a:direction == "down"
    let address = line("'>") + amount
  endif

  " extend_eol
  if a:direction == "down"
    let eol_extended = s:smart_extend_eol(address)
  endif

  if a:direction == "down" && eol_extended "{{{
    try
      call s:smart_undojoin()
    catch /E790/
        " [BUG] in situation , movement to down direction across the original EOL,
        " E790 error raised. so I cant't delete this catch clause.
        if g:textmanip_debug
          echo "exception E790"
        endif
    endtry
  else
      call s:smart_undojoin()
  endif "}}}
  if g:textmanip_debug "{{{
    if s:is_sequential_execution()
      let b:textmanip_continue_count += 1
      echo " "
      echo "Continue: " . b:textmanip_continue_count
    else
      let b:textmanip_continue_count = 1
      echo " "
      echo "Start: " . b:textmanip_continue_count
    endif
  endif"}}}

  let cmd = 
        \ a:direction == "down"  ? "'<,'>move " . address :
        \ a:direction == "up"    ? "'<,'>move " . address :
        \ a:direction == "right" ? "'<,'>" . repeat(">>", amount) :
        \ a:direction == "left"  ? "'<,'>" . repeat("<<", amount) : ""
  silent execute cmd
  normal! gv
  let b:textmanip_status = s:textmanip_status()
endfun "}}}

" }}}
" vim: foldmethod=marker
