-- Storage for renamed tab titles
_G.custom_tabnames = {}

-- Function to build the tabline
function MyTabLine()
  local s = ""
  local num_tabs = vim.fn.tabpagenr('$')

  for i = 1, num_tabs do
    local win = vim.fn.tabpagewinnr(i)
    local bufnr = vim.fn.tabpagebuflist(i)[win]
    local fname = vim.fn.bufname(bufnr)
    fname = fname ~= "" and vim.fn.fnamemodify(fname, ":t") or "No Name"

    -- Use custom name if it exists
    local display_name = _G.custom_tabnames[i] or fname

    local label = string.format("[%d - %s]", i, display_name)

    if i == vim.fn.tabpagenr() then
      s = s .. "%#TabLineSel#" .. " " .. label .. " "
    else
      s = s .. "%#TabLine#" .. " " .. label .. " "
    end
  end
    s = s .. "%#TabLineFill#"
  return s
end

vim.o.tabline = "%!v:lua.MyTabLine()"

-- Command to rename the current tab's custom name
function RenameTab()
  local tabnr = vim.fn.tabpagenr()
  local current = _G.custom_tabnames[tabnr] or ""
  vim.ui.input({ prompt = "Rename tab to > ", default = current }, function(input)
    if input ~= nil then
      _G.custom_tabnames[tabnr] = input ~= "" and input or nil
      vim.cmd("redrawtabline")
    end
  end)
end

-- Reset function: remove custom name
function ResetTabName()
  local tabnr = vim.fn.tabpagenr()
  _G.custom_tabnames[tabnr] = nil
  vim.cmd("redrawtabline")
end

-- Keymaps
vim.keymap.set("n", "tt", function() RenameTab() end, { noremap = true, silent = true })
vim.keymap.set("n", "tT", function() ResetTabName() end, { noremap = true, silent = true })


vim.api.nvim_create_autocmd("FileType", {
	pattern = "netrw",
	callback = function()
		local opts = {buffer = true, silent = true, remap = true}
		vim.keymap.set("n", "tt", function() RenameTab() end, opts)
		vim.keymap.set("n", "tT", function() ResetTabName() end, opts)
	end})
