if exists( 'g:fubitive_loaded' )
    finish
endif
let g:fubitive_loaded = 1

function! s:function(name) abort
  return function(substitute(a:name,'^s:',matchstr(expand('<sfile>'), '<SNR>\d\+_'),''))
endfunction

function! s:default_protocol()
  return exists('g:fubitive_default_protocol')
    \ ? g:fubitive_default_protocol
    \ : 'https://'
endfunction

function! s:domain_context_path()
  return exists('g:fubitive_domain_context_path')
    \ ? '/' . g:fubitive_domain_context_path
    \ : ''
endfunction

function! s:bitbucket_url(opts, ...) abort
  if a:0 || type(a:opts) != type({})
    return ''
  endif
  let path = substitute(a:opts.path, '^/', '', '')
  let domain_pattern = exists('g:fubitive_domain_pattern') ? g:fubitive_domain_pattern : 'bitbucket\.org'
  let domains = exists('g:fugitive_bitbucket_domains') ? g:fugitive_bitbucket_domains : []
  for domain in domains
    let domain_pattern .= '\|' . escape(split(domain, '://')[-1], '.')
  endfor
  let repo = matchstr(a:opts.remote,'^\%(https\=://\|git://\|\(ssh://\)\=git@\)\%(.\{-\}@\)\=\zs\('.domain_pattern.'\)[/:].\{-\}\ze\%(\.git\)\=$')
  let domain = matchstr(a:opts.remote,'^\%(https\=://\|git://\|\(ssh://\)\=git@\)\%(.\{-\}@\)\=\zs\('.domain_pattern.'\)\ze[/:].\{-\}\%(\.git\)\=$')
  if repo ==# ''
    return ''
  endif
  let is_cloud = domain =~? 'bitbucket\.org'
  if !is_cloud
    let project = matchstr(repo, '\zs\([^/]*\)\ze/[^/]*$')
    let repo = matchstr(repo, '/\zs\([^/]*\)$')
  endif
  let protocol = matchstr(a:opts.remote,'^\(https\=://\)')
  if empty(protocol)
      let protocol = s:default_protocol()
  endif
  let root = protocol . (is_cloud
        \ ? substitute(repo, ':', '/', '')
        \ : domain . s:domain_context_path() . '/projects/' . project . '/repos/' .  repo)
  if path =~# '^\.git/refs/heads/'
    return root . '/commits/' . path[16:-1]
  elseif path =~# '^\.git/refs/tags/'
    return root . '/src/' .path[15:-1]
  elseif path =~# '.git/\%(config$\|hooks\>\)'
    return root . '/admin'
  elseif path =~# '^\.git\>'
    return root
  endif
  if a:opts.commit =~# '^\d\=$'
    let commit = a:opts.repo.rev_parse('HEAD')
  else
    let commit = a:opts.commit
  endif
  if get(a:opts, 'type', '') ==# 'tree' || a:opts.path =~# '/$'
    let url = is_cloud
          \ ? substitute(root . '/src/' . commit . '/' . path, '/$', '', '')
          \ : substitute(root . '/browse/' . path . '?at=' . commit, '/$', '', '')
  elseif get(a:opts, 'type', '') ==# 'blob' || a:opts.path =~# '[^/]$'
    let objSpec = split(fugitive#Object(), ':')
    let commit = len(objSpec) == 2 ? objSpec[0] : fugitive#RevParse('HEAD')
    let url = is_cloud
          \ ? root . '/src/' . commit . '/' . path
          \ : root . '/browse/' . path . '?until=' . commit
    if get(a:opts, 'line1')
      let url .= is_cloud
            \ ? '#' . fnamemodify(path, ':t') . '-' . a:opts.line1
            \ : '#' . a:opts.line1
      if get(a:opts, 'line2')
        let url .= (is_cloud ? ':' : '-') . a:opts.line2
      endif
    endif
  else
    let url = root . '/commits/' . commit
  endif
  return url
endfunction

if !exists('g:fugitive_browse_handlers')
  let g:fugitive_browse_handlers = []
endif

call insert(g:fugitive_browse_handlers, s:function('s:bitbucket_url'))
