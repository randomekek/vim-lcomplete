" autocomplete as you type with fuzzy search

if !has('python')
  finish
endif

function! LCompletePy(base)
python << EOF
import string
import vim

min_base_length = 2
max_matches = 6
min_match_length = 5
keep = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_'
search_range_current = 2000
search_range_all = 500

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

def region(buf, center, size):
  return buf[max(0, center-size):center+size]

def cursor(bufinfo):
  result = {}
  for buf in bufinfo:
    if buf['listed'] == '1':
      result[int(buf['bufnr'])-1] = int(buf['lnum'])-1
  return result

def completion(base, current_buffer_index, bufinfo, buffers):
  if len(base) < min_base_length:
    return []
  results = set()
  deletechars = ''.join(chr(c) for c in range(0,256) if chr(c) not in keep)
  table = string.maketrans(deletechars, ' '*len(deletechars))
  line = cursor(bufinfo)
  # not a bug: buffers indexed from 1, enumerate(buffers) indexed from 0
  current_buffer = region(buffers[current_buffer_index+1], line[current_buffer_index], search_range_current)
  search_buffers = [current_buffer] + [
    region(buf, line[idx], search_range_all) for idx, buf in enumerate(buffers) if idx in line]
  for buf in search_buffers:
    for line in buf:
      for word in line.translate(table).split():
        if len(word) >= min_match_length and matches(base, word):
          results.add(word)
          if len(results) >= max_matches:
            return list(results)
  return list(results)

base = vim.eval('a:base').lower()
current_buffer_index = int(vim.eval("bufnr('%')"))-1
bufinfo = vim.eval('getbufinfo()')
buffers = vim.buffers
vim.command('let g:lcomplete_ret = ' + str(completion(base, current_buffer_index, bufinfo, buffers)))
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
  if getline('.')[col('.') - 2] =~ ' ' || pumvisible()
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
