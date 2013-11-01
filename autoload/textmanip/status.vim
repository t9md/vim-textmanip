let s:status = {}

function! s:status.continuous() "{{{1
  if !exists("b:textmanip_status")
    return 0
  endif
  if b:textmanip_status != self.selected()
    return 0
  endif

  return 1
endfunction

function! s:status.update() "{{{1
  let b:textmanip_status = self.selected()
endfunction

function! s:status.selected() "{{{1
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
endfunction

function! textmanip#status#update() "{{{1
  call s:status.update()
endfunction

function! textmanip#status#continuous() "{{{1
  return s:status.continuous()
endfunction

" vim: foldmethod=marker
