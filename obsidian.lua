local scandir = require('plenary.scandir')

local obsidian_tips = {}
local ERROR = vim.log.levels.ERROR
local WARN  = vim.log.levels.WARN
local INFO  = vim.log.levels.INFO


local function buf_vtext()
  local a_orig = vim.fn.getreg('a')
  local mode = vim.fn.mode()
  if mode ~= 'v' and mode ~= 'V' then
    vim.cmd([[normal! gv]])
  end
  vim.cmd([[silent! normal! "aygv]])
  local text = vim.fn.getreg('a')
  vim.fn.setreg('a', a_orig)
  return text
end

--open link_file and try jump to title--
---@param filename string:  full file path 
---@param title string   :  title
local function locate_title(filename, title)
  if not title then
    vim.cmd('edit '..filename)
    return
  end
  local handle = io.open(filename)
  if not handle then
    vim.notify("read "..filename.."failed", ERROR)
    return
  end
  local luare
  local line_number = 1
  if string.match(title, '^%^') then
    luare = '%^('..string.rep("%w", #title-1)..')'
    title = string.sub(title, 2, -1)
  else
    luare = '^#+ +('..string.rep('.', #title)..')$'
  end
  for line in handle:lines() do
    local match = string.match(line, luare)
    if match and match==title then
      vim.cmd('edit +'..line_number..' '..filename)
      io.close(handle)
      return
    end
    line_number = line_number + 1
  end
  io.close(handle)
  vim.notify("bug not match "..title, ERROR)
  vim.cmd('edit '..filename)
end

---@param str string:  [[str]]
local function link_note(str)
  local cwd = vim.loop.cwd()
  local buf_path = string.sub(vim.fn.expand("%:p"), #cwd, -1)
  local root = vim.fn.expand("%:p:h")

  local title = string.match(str, "#([^|]*)")
  local path = string.match(str, "([^#|]*)")
  local name = string.match(path, "([^/\\]*)$")
  local filename

  --try to read the file directly--
  for _ in string.gmatch(buf_path, "[\\/]") do
    filename = root..'/'..path
    if vim.fn.filereadable(filename)==1 then
      vim.cmd('edit '..filename)
      return filename
    elseif vim.fn.filereadable(filename..'.md')==1 then
      locate_title(filename..'.md', title)
      return filename
    end
    --try failed then scandir--
    for _, files_path in ipairs(scandir.scan_dir(root, {hidden=false, add_dirs=false})) do
      local file_name = string.match(files_path,'.*[\\/](.*)')
      if file_name == name then
        vim.cmd('edit '..files_path)
        return files_path
      elseif file_name == name..'.md' then
        locate_title(files_path, title)
        return files_path
      end
    end
    root = string.match(root, "(.*)[/\\]")
  end

  vim.notify("No file "..str, ERROR)
end

---@param url string:  [...](url)
local function link_url(url)
  local TRUE
  if vim.fn.filereadable(url)==1 then
    vim.cmd("edit "..url)
  else
    vim.ui.input({ prompt = "Do you want open "..url.." input(y):" },
    function(input)
      if input == 'y' then
        TRUE = true
      end
    end)
    if TRUE then
      os.execute("start "..url)
      vim.notify("start "..url, INFO)
    end
  end
end

---@param str string:  [^str] or ^[str]
local function link_footnote(str)
  local content = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)
  for line_number,line in pairs(content) do
    if string.match(line, '^%[%^'..str..'%]:') then
      vim.cmd('silent! normal! '..line_number..'gg')
      break
    end
  end
end

-- open obsidian link :link_note, link_url, link_footnote
function obsidian_tips.obsidianopenlink()
  local start_line_number, start_line_col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.cmd([[silent! normal! va[loh]])
  local v_select_origin = buf_vtext()
  local last_c = string.sub(v_select_origin, -1, -1)
  local double_brackets=string.match(v_select_origin,'%[%[([^%[%]]*)%]%]')
  local is_foot_link = string.match(v_select_origin, '[[^][%^[]([^%]]*)')
    
  vim.cmd([[silent! exec "normal! \<esc>l"]])
  if vim.fn.getpos('.')[2] ~= start_line_number then
    vim.notify("not valid link.", WARN)
  elseif double_brackets then
    return link_note(double_brackets)
  elseif is_foot_link then
    return link_footnote(is_foot_link)
  elseif last_c == '(' then
    vim.cmd([[silent! normal! vi(]])
    link_url(buf_vtext())
  else
    vim.notify("not valid link.", WARN)
  end
  vim.api.nvim_win_set_cursor(0,{start_line_number, start_line_col})
  vim.cmd([[silent! exec "normal! \<esc>"]])
end

vim.api.nvim_create_user_command('Olink', obsidian_tips.obsidianopenlink, { nargs = 0, bang = true })
return obsidian_tips
