function! s:function(name) abort
  return function(substitute(a:name,'^s:',matchstr(expand('<sfile>'), '<SNR>\d\+_'),''))
endfunction

function! s:bitbucket_url(opts, ...) abort
  if a:0 || type(a:opts) != type({})
    return ''
  endif
  let path = a:opts.path
  let domain_pattern = 'bitbucket\.org'
  let domains = exists('g:fugitive_bitbucket_domains') ? g:fugitive_bitbucket_domains : []
  for domain in domains
    let domain_pattern .= '\|' . escape(split(domain, '://')[-1], '.')
  endfor
  let repo = matchstr(a:opts.remote,'^\%(https\=://\|git://\|\(ssh://\)\=git@\)\zs\('.domain_pattern.'\)[/:].\{-\}\ze\%(\.git\)\=$')
  if repo ==# ''
    return ''
  endif
  if index(domains, 'http://' . matchstr(repo, '^[^:/]*')) >= 0
    let root = 'http://' . substitute(repo,':','/','')
  else
    let root = 'https://' . substitute(repo,':','/','')
  endif
  if path =~# '^\.git/refs/heads/'
    let branch = a:opts.repo.git_chomp('config','branch.'.path[16:-1].'.merge')[11:-1]
    if branch ==# ''
      return root . '/commits/' . path[16:-1]
    else
      return root . '/commits/' . branch
    endif
  elseif path =~# '^\.git/refs/.'
    return root . '/commits/' . matchstr(path,'[^/]\+$')
  elseif path =~# '.git/\%(config$\|hooks\>\)'
    return root . '/admin'
  elseif path =~# '^\.git\>'
    return root
  endif
  if a:opts.revision =~# '^[[:alnum:]._-]\+:'
    let commit = matchstr(a:opts.revision,'^[^:]*')
  elseif a:opts.commit =~# '^\d\=$'
    let local = matchstr(a:opts.repo.head_ref(),'\<refs/heads/\zs.*')
    let commit = a:opts.repo.git_chomp('config','branch.'.local.'.merge')[11:-1]
    if commit ==# ''
      let commit = local
    endif
  else
    let commit = a:opts.commit
  endif
  if a:opts.type == 'tree'
    let url = s:sub(root . '/src/' . commit . '/' . path,'/$','')
  elseif a:opts.type == 'blob'
    let url = root . '/src/' . commit . '/' . path
    if get(a:opts, 'line1')
      let url .= '#' . fnamemodify(path, ':t') . '-' . a:opts.line1
    endif
  elseif a:opts.type == 'tag'
    let commit = matchstr(getline(3),'^tag \zs.*')
    let url = root . '/src/' . commit
  else
    let url = root . '/commits/' . commit
  endif
  return url
endfunction

if !exists('g:fugitive_browse_handlers')
  let g:fugitive_browse_handlers = []
endif

call insert(g:fugitive_browse_handlers, s:function('s:bitbucket_url'))
