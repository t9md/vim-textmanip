# Move/Duplicate text intuitively.
  * move visually selected text easily ( linewise / blockwise )
  * duplicate text easily ( linewise / blockwise )
  * count support
  * keep original cursor position (include 'o'ther pos in visualmode!) while moving / duplicating.
  * undo with one 'u' by undojoining.

![Example](https://github.com/t9md/t9md/blob/master/img/vim-textmanip_anime.gif?raw=true)
### [help](https://github.com/t9md/vim-textmanip/blob/master/doc/textmanip.txt)

# Configuration example

### GUI macvim ( which I use now )

    xmap <D-d> <Plug>(textmanip-duplicate-down)
    nmap <D-d> <Plug>(textmanip-duplicate-down)
    xmap <D-D> <Plug>(textmanip-duplicate-up)
    nmap <D-D> <Plug>(textmanip-duplicate-up)

    xmap <C-j> <Plug>(textmanip-move-down)
    xmap <C-k> <Plug>(textmanip-move-up)
    xmap <C-h> <Plug>(textmanip-move-left)
    xmap <C-l> <Plug>(textmanip-move-right)

### gVim

    Tasks:
    xmap <M-d> <Plug>(textmanip-duplicate-down)
    nmap <M-d> <Plug>(textmanip-duplicate-down)
    xmap <M-D> <Plug>(textmanip-duplicate-up)
    nmap <M-D> <Plug>(textmanip-duplicate-up)

    xmap <C-j> <Plug>(textmanip-move-down)
    xmap <C-k> <Plug>(textmanip-move-up)
    xmap <C-h> <Plug>(textmanip-move-left)
    xmap <C-l> <Plug>(textmanip-move-right)

### vim on terminal

    xmap <Space>d <Plug>(textmanip-duplicate-down)
    nmap <Space>d <Plug>(textmanip-duplicate-down)
    xmap <Space>D <Plug>(textmanip-duplicate-up)
    nmap <Space>D <Plug>(textmanip-duplicate-up)

    xmap <C-j> <Plug>(textmanip-move-down)
    xmap <C-k> <Plug>(textmanip-move-up)
    xmap <C-h> <Plug>(textmanip-move-left)
    xmap <C-l> <Plug>(textmanip-move-right)

