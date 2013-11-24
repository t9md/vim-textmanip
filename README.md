# Move/Duplicate text intuitively.
  * move selected lines or block area to specified direction ( up/down/right/left ).
  * duplicate selected lines or block to specified direction ( up/down/right/left ).
  * Two mode: inesrt or replace
  * count support
  * keep original cursor position (include 'o'ther pos in visualmode!) while moving / duplicating.
  * undo with one 'u' by undojoining.

![Example](https://github.com/t9md/t9md/blob/master/img/vim-textmanip_anime.gif?raw=true)
### [help](https://github.com/t9md/vim-textmanip/blob/master/doc/textmanip.txt)

# Configuration example

### GUI macvim ( which I use now )

```Vim
xmap <D-d> <Plug>(textmanip-duplicate-down)
nmap <D-d> <Plug>(textmanip-duplicate-down)
xmap <D-D> <Plug>(textmanip-duplicate-up)
nmap <D-D> <Plug>(textmanip-duplicate-up)

xmap <C-j> <Plug>(textmanip-move-down)
xmap <C-k> <Plug>(textmanip-move-up)
xmap <C-h> <Plug>(textmanip-move-left)
xmap <C-l> <Plug>(textmanip-move-right)

" toggle insert/replace with <F10>
nmap <F10> <Plug>(textmanip-toggle-mode)
xmap <F10> <Plug>(textmanip-toggle-mode)

" use allow key to force replace movement
xmap  <Up>     <Plug>(textmanip-move-up-r)
xmap  <Down>   <Plug>(textmanip-move-down-r)
xmap  <Left>   <Plug>(textmanip-move-left-r)
xmap  <Right>  <Plug>(textmanip-move-right-r)
```

### gVim

```Vim
xmap <M-d> <Plug>(textmanip-duplicate-down)
nmap <M-d> <Plug>(textmanip-duplicate-down)
xmap <M-D> <Plug>(textmanip-duplicate-up)
nmap <M-D> <Plug>(textmanip-duplicate-up)

xmap <C-j> <Plug>(textmanip-move-down)
xmap <C-k> <Plug>(textmanip-move-up)
xmap <C-h> <Plug>(textmanip-move-left)
xmap <C-l> <Plug>(textmanip-move-right)

" toggle insert/replace with <F10>
nmap <F10> <Plug>(textmanip-toggle-mode)
xmap <F10> <Plug>(textmanip-toggle-mode)

" use allow key to force replace movement
xmap  <Up>     <Plug>(textmanip-move-up-r)
xmap  <Down>   <Plug>(textmanip-move-down-r)
xmap  <Left>   <Plug>(textmanip-move-left-r)
xmap  <Right>  <Plug>(textmanip-move-right-r)
```

### vim on terminal

```Vim
xmap <Space>d <Plug>(textmanip-duplicate-down)
nmap <Space>d <Plug>(textmanip-duplicate-down)
xmap <Space>D <Plug>(textmanip-duplicate-up)
nmap <Space>D <Plug>(textmanip-duplicate-up)

xmap <C-j> <Plug>(textmanip-move-down)
xmap <C-k> <Plug>(textmanip-move-up)
xmap <C-h> <Plug>(textmanip-move-left)
xmap <C-l> <Plug>(textmanip-move-right)

" toggle insert/replace with <F10>
nmap <F10> <Plug>(textmanip-toggle-mode)
xmap <F10> <Plug>(textmanip-toggle-mode)
```


### keymap advanced macvim (this is my current configuration).

```Vim
" use Enter and Shift-Enter to insert blank line.
" which is useful since I enforce duplicate with '-r(replace' mode.
nmap <CR>   <Plug>(textmanip-blank-below)
nmap <S-CR> <Plug>(textmanip-blank-above)
xmap <CR>   <Plug>(textmanip-blank-below)
xmap <S-CR> <Plug>(textmanip-blank-above)

" simple duplicate
nmap <D-D> <Plug>(textmanip-duplicate-up)
nmap <D-d> <Plug>(textmanip-duplicate-down)
xmap <D-D> <Plug>(textmanip-duplicate-up)
xmap <D-d> <Plug>(textmanip-duplicate-down)
       
" move with jkhl
xmap <C-k> <Plug>(textmanip-move-up)
xmap <C-j> <Plug>(textmanip-move-down)
xmap <C-h> <Plug>(textmanip-move-left)
xmap <C-l> <Plug>(textmanip-move-right)

" duplicate with COMMAND-SHIFT-jkhl
xmap <D-K> <Plug>(textmanip-duplicate-up)
xmap <D-J> <Plug>(textmanip-duplicate-down)
xmap <D-H> <Plug>(textmanip-duplicate-left)
xmap <D-L> <Plug>(textmanip-duplicate-right)

" use allow key to force replace movement
xmap  <Up>    <Plug>(textmanip-move-up-r)
xmap  <Down>  <Plug>(textmanip-move-down-r)
xmap  <Left>  <Plug>(textmanip-move-left-r)
xmap  <Right> <Plug>(textmanip-move-right-r)

      " toggle insert/replace with <F10>
nmap <F10> <Plug>(textmanip-toggle-mode)
xmap <F10> <Plug>(textmanip-toggle-mode)
```
