function! textmanip#duplicate(direction, mode) "{{{
    let pos = getpos('.')

    if a:mode == 'n'
      let first_line = line('.')
      let last_line =  line('.')
    elseif a:mode == 'v'
      let first_line = line("'<")
      let last_line =  line("'>")
    endif

    let copy_to = a:direction == "down" ? last_line : first_line - 1
    execute first_line . "," . last_line . "copy " . copy_to

    if a:mode ==# 'v'
        normal! `[V`]
    elseif a:mode ==# 'n'
        let pos[1] = line('.')
        call setpos('.', pos)
    endif
endfun "}}}

function! textmanip#move(direction) "{{{
    let action       = {}
    let action.down  = "'<,'>move " . (line("'>") + 1)
    let action.up    = "'<,'>move " . (line("'<") - 2)
    let action.right = "'<,'>>>"
    let action.left  = "'<,'><<"

    if a:direction == 'down' && line("'>") == line('$')
      try
        silent undojoin
      catch /E790/
      finally
        call append(line('$'), "")
      endtry
    endif

    try
      silent undojoin
    catch /E790/
    finally
      silent execute action[a:direction]
    endtry

    normal! gv
endfun "}}}
" vim: foldmethod=marker
