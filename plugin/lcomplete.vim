" autocomplete as you type with fuzzy search

if !has('python3')
  finish
endif

let g:lcomplete_chars = get(g:, 'lcomplete_chars', 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_.:@')
let g:lcomplete_end_strip = get(g:, 'lcomplete_end_strip', '.:@')

function! LCompletePy(base)
python3 << EOF
import vim

min_base_length = 2
max_matches = 6
min_match_length = 5
max_line_scan = 160
search_range_current = 2000
search_range_all = 500

def matches(base, word):
  if len(word) < min_match_length:
    return False
  return charMatch(base[0], word[0]) and matchesRest(base[1:], word[1:])

def matchesRest(base, word):
  pos = 0
  word_len = len(word)
  for char in base:
    while True:
      if pos >= word_len:
        return False
      if charMatch(char, word[pos]):
        pos += 1
        break
      pos += 1
  return pos + 1

def charMatch(char, match):
  if char.islower():
    return char == match.lower()
  else:
    return char == match

def cursor(bufinfo):
  result = {}
  for buf in bufinfo:
    if buf['listed'] == '1':
      result[int(buf['bufnr'])] = int(buf['lnum'])-1
  return result

def maketrans(kept_chars):
  deletechars = ''.join(chr(c) for c in range(0,256) if chr(c) not in kept_chars)
  return str.maketrans(deletechars, ' '*len(deletechars))

def completion(base, current_buffer_index, bufinfo, buffers, chars, end_strip):
  if len(base) < min_base_length:
    return []
  results = set()
  line = cursor(bufinfo)
  def region(idx, size):
    return buffers[idx][max(0, line[idx]-size):line[idx]+size]
  current_buffer = region(current_buffer_index, search_range_current)
  search_buffers = [current_buffer] + [region(idx, search_range_all) for idx in line if idx != current_buffer_index]
  for buf in search_buffers:
    for line in buf:
      for word in line[:max_line_scan].translate(chars).split():
        word = word.rstrip(end_strip)
        match = matches(base, word)
        if match:
          results.add((match, word))
          if len(results) >= max_matches:
            return list(results)
  return list(results)

def sort(results):
  return list(map(
    lambda x: x[1],
    sorted(results, key=lambda x: (x[0], len(x[1]), x[1]), reverse=False)))

def run():
  base = vim.eval('a:base')
  current_buffer_index = int(vim.eval("bufnr('%')"))
  bufinfo = vim.eval('getbufinfo()')
  buffers = vim.buffers
  chars = maketrans(vim.eval('g:lcomplete_chars'))
  end_strip = vim.eval('g:lcomplete_end_strip')
  vim.command('let g:lcomplete_ret = ' + str(sort(completion(base, current_buffer_index, bufinfo, buffers, chars, end_strip))))

run()
EOF
  return {'words': g:lcomplete_ret, 'refresh': 'always'}
endfunction

function! LComplete(findstart, base)
  if a:findstart
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ ('[' . g:lcomplete_chars . ']')
      let start -= 1
    endwhile
    if col('.') - start < 3
      return -3
    else
      return start
    endif
  else
    return LCompletePy(a:base)
  endif
endfunction

function! LCompleteShow()
  if getline('.')[col('.') - 2] == ' ' || pumvisible()
  else
    call feedkeys("\<C-x>\<C-u>", 'n')
  end
endfunction

set completeopt=menuone,noinsert,noselect
set completefunc=LComplete
set shortmess+=c

" chose a selection or insert a <tab>
inoremap <expr> <tab> pumvisible() ? "\<C-N>" : "\<tab>"
inoremap <expr> <S-tab> pumvisible() ? "\<C-P>" : "\<tab>"

" enter will always insert a new line
inoremap <expr> <CR> pumvisible() && !has_key(v:completed_item, 'word') ? "\<C-e>\<CR>" : "<CR>"

augroup LCompleteAuto
  autocmd!
  autocmd TextChangedI * noautocmd call LCompleteShow()
augroup END
