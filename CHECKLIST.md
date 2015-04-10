 CeckList:
=====================
 restore original vim options
 restore original visual mode
 restore original cursor pos including where 'o'posit pos in visual mode.
 count aware
 undoable for continuous move by one 'undo' command.
 care when move across corner( TOF,EOF, BOL, EOL )
  - by adjusting cursor to appropriate value
  u => TOF
  d => EOF
  r => EOL(but be care this!)
  l => BOF

 Supported: [O: Finish][X: Not Yet][P: Partially impremented]
 * normal_mode:
 [O] duplicate line to above, below

 * visual_line('V', or multiline 'v':
 [O] duplicate line to above, below
 [O] move righ/left
 [O] undoable/count

 * visual_block(C-v):
 [O] move selected block to up/down/right/left.
   ( but not multibyte char aware ).
 [X] count support, not undoable

Test
==================================
  111111|BBBBBB|111111
  000000|AAAAAA|000000
  666665|FFFFFF|666666
  777777|CCCCCC|777777
  888888|DDDDDD|888888
  222222|000000|222222
  555556|000000|555555
  333333|000000|333333
  444444|000000|444444
  000000|000000|000000
  111111|000000|111111
  333333|NNNNNN|333333
  444444|OOOOOO|444444
