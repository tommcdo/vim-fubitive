function! s:function(name) abort
  return function(substitute(a:name,'^s:',matchstr(expand('<sfile>'), '<SNR>\d\+_'),''))
endfunction

function! s:bitbucket_url(repo,url,rev,commit,path,type,line1,line2) abort
  let path = a:path
  let domain_pattern = 'bitbucket\.org'
  let domains = exists('g:fugitive_bitbucket_domains') ? g:fugitive_bitbucket_domains : []
  for domain in domains
    let domain_pattern .= '\|' . escape(split(domain, '://')[-1], '.')
  endfor
  let repo = matchstr(a:url,'^\%(https\=://\|git://\|git@\)\zs\('.domain_pattern.'\)[/:].\{-\}\ze\%(\.git\)\=$')
  if repo ==# ''
    return ''
  endif
  if index(domains, 'http://' . matchstr(repo, '^[^:/]*')) >= 0
    let root = 'http://' . substitute(repo,':','/','')
  else
    let root = 'https://' . substitute(repo,':','/','')
  endif
  if path =~# '^\.git/refs/heads/'
    let branch = a:repo.git_chomp('config','branch.'.path[16:-1].'.merge')[11:-1]
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
  if a:rev =~# '^[[:alnum:]._-]\+:'
    let commit = matchstr(a:rev,'^[^:]*')
  elseif a:commit =~# '^\d\=$'
    let local = matchstr(a:repo.head_ref(),'\<refs/heads/\zs.*')
    let commit = a:repo.git_chomp('config','branch.'.local.'.merge')[11:-1]
    if commit ==# ''
      let commit = local
    endif
  else
    let commit = a:commit
  endif
  if a:type == 'tree'
    let url = s:sub(root . '/src/' . commit . '/' . path,'/$','')
  elseif a:type == 'blob'
    let url = root . '/src/' . commit . '/' . path
    if a:line2 > 0 && a:line1 == a:line2
      let url .= '#cl-' . a:line1
    elseif a:line2 > 0
      " There doesn't seem to be support for multi-line linking; just link to first line.
      let url .= '#cl-' . a:line1
    endif
  elseif a:type == 'tag'
    let commit = matchstr(getline(3),'^tag \zs.*')
    let url = root . '/src/' . commit
  else
    let url = root . '/commits/' . commit
  endif
  return url
endfunction

if !exists('g:fugitive_experimental_browse_handlers')
  let g:fugitive_experimental_browse_handlers = []
endif

call insert(g:fugitive_experimental_browse_handlers, s:function('s:bitbucket_url'))
