" Standard Neovim Configuration
" Basic settings for usability and appearance

" Editor behavior
set number
set relativenumber
set cursorline
set wrap
set scrolloff=8
set sidescrolloff=8

" Search settings
set ignorecase
set smartcase
set incsearch
set hlsearch

" Indentation
set expandtab
set tabstop=4
set shiftwidth=4
set smartindent
set autoindent

" File handling
set hidden
set backup
set backupdir=~/.config/nvim/backup//
set directory=~/.config/nvim/swap//
set undofile
set undodir=~/.config/nvim/undo//

" Create backup directories if they don't exist
if !isdirectory(expand('~/.config/nvim/backup'))
    call mkdir(expand('~/.config/nvim/backup'), 'p')
endif
if !isdirectory(expand('~/.config/nvim/swap'))
    call mkdir(expand('~/.config/nvim/swap'), 'p')
endif
if !isdirectory(expand('~/.config/nvim/undo'))
    call mkdir(expand('~/.config/nvim/undo'), 'p')
endif

" UI improvements
set termguicolors
set signcolumn=yes
set updatetime=300
set timeoutlen=500

" Custom color scheme to match kitty Deep Space theme
highlight Normal guifg=#b3c2e4 guibg=#12070a
highlight CursorLine guibg=#1a0c0f
highlight LineNr guifg=#5a4b52 guibg=#12070a
highlight CursorLineNr guifg=#f47d74 guibg=#1a0c0f gui=bold
highlight Visual guifg=#deb9d0 guibg=#461f28
highlight Search guifg=#12070a guibg=#f47d74
highlight IncSearch guifg=#12070a guibg=#5aa7ff
highlight StatusLine guifg=#b3c2e4 guibg=#2a1a1f
highlight StatusLineNC guifg=#5a4b52 guibg=#1a0c0f
highlight VertSplit guifg=#461f28 guibg=#12070a
highlight Pmenu guifg=#b3c2e4 guibg=#2a1a1f
highlight PmenuSel guifg=#deb9d0 guibg=#461f28
highlight Comment guifg=#7a6b72 gui=italic
highlight String guifg=#8fb5a8
highlight Number guifg=#f47d74
highlight Function guifg=#5aa7ff
highlight Keyword guifg=#d4a574 gui=bold
highlight Type guifg=#c78bcc
highlight Special guifg=#f47d74
highlight Error guifg=#ff6b6b guibg=#2a0a0a
highlight Warning guifg=#ffa500 guibg=#2a1a00

" Cursor styling to match kitty
set guicursor=n-v-c:block-Cursor/lCursor
set guicursor+=i:ver25-Cursor/lCursor
set guicursor+=r-cr:hor20-Cursor/lCursor

" Split behavior
set splitright
set splitbelow

" Mouse support
set mouse=a

" Clear search highlighting with Escape
nnoremap <Esc> :nohlsearch<CR>

" Better window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Quick save
nnoremap <C-s> :w<CR>

" Better yanking (copy to system clipboard)
vnoremap <leader>y "+y
nnoremap <leader>Y "+yg_
nnoremap <leader>y "+y

" Paste from system clipboard
nnoremap <leader>p "+p
nnoremap <leader>P "+P
vnoremap <leader>p "+p
vnoremap <leader>P "+P