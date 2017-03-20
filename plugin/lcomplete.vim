" autocomplete as you type with fuzzy search

if !has('python')
  finish
endif

function! LCompletePy(base)
python << EOF
import string
import vim

def matches(base, word):
  word = word.lower()
  return base[0] == word[0] and matchesRest(base[1:], word[1:])

def matchesRest(base, word):
  pos = 0
  word_len = len(word)
  for char in base:
    while True:
      if pos >= word_len:
        return False
      if word[pos] == char:
        pos += 1
        break
      pos += 1
  return True

def completion(base, lineNo, text):
  if len(base) < 3:
    return []
  results = []
  keep = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_'
  deletechars = ''.join(chr(c) for c in range(0,256) if chr(c) not in keep)
  table = string.maketrans(deletechars, ' '*len(deletechars))
  for line in text[max(0, lineNo-2000):lineNo+2000]:
    for word in line.translate(table).split():
      if len(word) >= 5 and matches(base, word):
        results.append(word)
        if len(results) > 20:
          return results
  return results

base = vim.eval('a:base').lower()
lineNo = int(vim.eval("line('.')"))
text = vim.current.buffer
vim.command('let g:lcomplete_ret = ' + str(completion(base, lineNo, text)))
EOF
  return {'words': g:lcomplete_ret, 'refresh': 'always'}
endfunction

function! LComplete(findstart, base)
  if a:findstart
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_]'
      let start -= 1
    endwhile
    return start
  else
    return LCompletePy(a:base)
  endif
endfunction

function! LCompleteShow()
  if pumvisible()
  else
    call feedkeys("\<C-x>\<C-u>", 'n')
  end
endfunction

fun! TabComplete()
  if getline('.')[col('.') - 2] =~ '\K' || pumvisible()
    return "\<C-N>"
  else
    return "\<Tab>"
  endif
endfunction

set completeopt=menuone,noinsert,noselect
set completefunc=LComplete
set shortmess+=c

" chose a selection or insert a <tab>
inoremap <expr> <Tab> TabComplete()

" enter will always insert a new line
inoremap <expr> <CR> pumvisible() && !has_key(v:completed_item, 'word') ? "\<C-e>\<CR>" : "<CR>"

augroup LCompleteAuto
  autocmd!
  autocmd TextChangedI * noautocmd call LCompleteShow()
augroup END
