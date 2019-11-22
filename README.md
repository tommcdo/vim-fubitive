fubitive.vim
============

Extend [fugitive.vim](https://github.com/tpope/vim-fugitive) to support
Bitbucket URLs in `:Gbrowse`.

## Configuration

The default domain when searching remotes is `bitbucket.org`. To make this
plugin work with a Bitbucket instance under a different domain, simply add the
following to your `.vimrc` (taking care to escape special characters):

```vim
let g:fubitive_domain_pattern = 'code\.example\.com'
```
