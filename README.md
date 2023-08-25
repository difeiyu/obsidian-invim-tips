# obsidian-in-nvim-tips
A little trick to edit obsidian in nvim

-----
## Requirements
[plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
------
## link jump
- `require 'obsidian`
- `nnoremap <silent> <expr> <enter>  &filetype=='markdown' ? ':Olink<cr>': '<enter>'`
