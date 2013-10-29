" Private:
let s:status = {}
function! s:status.undojoin() "{{{
  if !exists("b:textmanip_status") | return 0 | endif
  if b:textmanip_status != self.selected() | return 0 | endif

  try
    silent undojoin
  catch /E790/
    " after move and exit at the same position(actully at cosmetic level no
    " change you made), and 'u'(undo), then restart move.
    " This read to situation 'undojoin is not allowed after undo' error.
    " But this cannot detect, so simply suppress this error.
  endtry
  return 1
endfunction "}}}

function! s:status.update() "{{{
  " echo "== in update"
  let b:textmanip_status = self.selected()
endfunction "}}}

function! s:status.selected() "{{{
  let content = getline(line("'<"), line("'>"))
  if char2nr(visualmode()) ==# char2nr("\<C-v>")
    let s = col("'<")
    let e = col("'>")
    let content = map(content, 'v:val[s-1:e-1]')
  endif
  let v =  {
        \ 'mode': visualmode(),
        \ 'line_start': line("'<"),
        \ 'line_end': line("'>"),
        \ 'len': len(content),
        \ 'content': content,
        \ }
  if g:textmanip_debug > 3
    echo PP(v)
  endif
  return v
endfunction "}}}

" Public:
function! textmanip#status#update() "{{{
  call s:status.update()
endfunction "}}}

function! textmanip#status#undojoin() "{{{
  return s:status.undojoin()
endfunction "}}}
" vim: foldmethod=marker
