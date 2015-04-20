let s:helper = {}

function! s:helper.indent(tm)
  normal! =
  call a:tm.select()
endfunction

function! s:helper.remove_trailing_WS(tm)
  let tm = a:tm
  let [line_s, line_e] = [tm.pos['^'].line, tm.pos['v'].line]
  if !tm.linewise
    let cmd = printf('%d,%ds!\v\s+$!!', line_s, line_e)
    silent! execute cmd
  endif
  call a:tm.select()
endfunction

function! textmanip#helper#get()
  return s:helper
endfunction
