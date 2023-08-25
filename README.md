# obsidian-invim-tips
A little trick to edit obsidian in nvim

------
# link jump
- `require 'obsidian`
- `nnoremap <silent> <expr> <enter>  &filetype=='markdown' ? ':Olink<cr>': '<enter>'`
