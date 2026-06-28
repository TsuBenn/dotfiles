vim.g.mapleader = " "

vim.keymap.set({'x','o'}, 'in', 'h')
vim.keymap.del({'x','o'}, 'in')

local inlay_hint = false

vim.keymap.set('n', 'h', function()
    vim.lsp.inlay_hint.enable(inlay_hint)
    inlay_hint = not inlay_hint
end)

--[[ Hover check type ]]--
--vim.keymap.set('n', 'h', vim.lsp.buf.hover, {})

-- Show diagnostics in a floating window
--vim.keymap.set('n', ';', vim.diagnostic.open_float)
--
-- Move to the PREVIOUS diagnostic
--vim.keymap.set('n', ',', function()
--  vim.diagnostic.jump({ count = -1, float = true })
--end)
--
-- Move to the NEXT diagnostic
--vim.keymap.set('n', '.', function()
--  vim.diagnostic.jump({ count = 1, float = true })
--end)

--[[ Quit Neovim ]]--
vim.keymap.set('n','ZZ', function()
    local quit = string.lower(vim.fn.input("Quit Neovim? (Y/N) > "))
    if quit == 'y' then return 'ZZ'
    else return ':lua print("Did not quit Neovim!")<CR>'
    end
end, {expr = true})


--[[ Program runner ]]--
vim.keymap.set({'x','n','i'},'<C-r>', function()
    --[[ Compiler's Language ]]
    local file = vim.fn.expand("%:p")
    local output = vim.fn.expand("%:p:r")
    local exten = vim.fn.expand("%:e")
    local lang = {
        -- <input> = { "<run cmd>", "<name>"} --
        py = {"python "..file.."<CR>","Python"},
        lua ={"so<CR>", "Lua"},
        cpp ={"clang++ "..file.." -o "..output..".exe && "..output..".exe<CR>", "C++"},
        c ={"clang "..file.." -o "..output..".exe && "..output..".exe<CR>", "C"},
        js ={"node "..file.."<CR>", "JavaScript"},
        rb ={"ruby "..file.."<CR>", "Ruby"},
        rs = {
            vim.fn.filereadable(vim.fn.getcwd() .. "/Cargo.toml") == 1
                and "cargo run<CR>"
                or "rustc "..file.." -o "..output.." && "..output.."<CR>",
            "Rust"
        },

    }
    --local ask = vim.fn.input("Language > ")

    if lang[exten] then
        if exten == "lua" then
            return ':'..lang[exten][1]
        else
            return "<ESC>:tabnew | term "..lang[exten][1].."A"
        end
    end
end, {expr = true, silent = true})

--[[ Execute macro ]]--
vim.keymap.set('n','e','@') -- [E]xecute Macro

--[[ Enter Explorer ]]--
vim.keymap.set('n','we', vim.cmd.Ex)

--[[ Close Window ]]--
vim.keymap.set('n','wq', function()
    if vim.fn.winnr("$") > 1 or vim.fn.tabpagenr("$") > 1 or vim.bo.readonly == true then
        return ":wq<CR>"
    else
        return ':w<CR>:Ex<CR>'
    end
end, {expr = true, silent = true}) -- Save then Exit
vim.keymap.set('n','wQ',':q<CR>') -- Discard then Exit

--[[ Switch Window ]]--
vim.keymap.set('n','w<leader>','<C-w>w') -- Switch Window in general
vim.keymap.set('n','wi','<C-w>k') -- Switch to the Window above
vim.keymap.set('n','wj','<C-w>h') -- Switch to the left Window 
vim.keymap.set('n','wk','<C-w>j') -- Switch to the Window below
vim.keymap.set('n','wl','<C-w>l') -- Switch to the right Window
vim.keymap.set('n','wI', function()
    if vim.fn.winnr('$') > 1 then
        return '<C-w>k:Ex<CR>'
    else return '<C-w>k'
    end
end,{expr = true}) -- Switch to the Window above then open Explorer
vim.keymap.set('n','wJ',function()
    if vim.fn.winnr('$') > 1 then
        return '<C-w>h:Ex<CR>'
    else return '<C-w>h'
    end
end,{expr = true}) -- Switch to the left Window then open Explorer
vim.keymap.set('n','wK',function()
    if vim.fn.winnr('$') > 1 then
        return '<C-w>j:Ex<CR>'
    else return '<C-w>j'
    end
end,{expr = true}) -- Switch to the Window below then open Explorer
vim.keymap.set('n','wL',function()
    if vim.fn.winnr('$') > 1 then
        return '<C-w>l:Ex<CR>'
    else return '<C-w>l'
    end
end,{expr = true}) -- Switch to the right Window then open Explorer

--[[ Adjust Window ]]--
vim.keymap.set('n','ww=','<C-w>=') -- Equalize Windows' sizes
vim.keymap.set('n','<S-Up>',':resize +1<CR>',{silent = true}) -- Add Window's height by 1
vim.keymap.set('n','<C-Up>',':resize +5<CR>',{silent = true}) -- Add Window's height by 5
vim.keymap.set('n','<S-Down>',':resize -1<CR>',{silent = true}) -- Remove Window's height by 1
vim.keymap.set('n','<C-Down>',':resize -5<CR>',{silent = true}) -- Remove Window's height by 5
vim.keymap.set('n','<S-Right>',':vertical resize +1<CR>',{silent = true}) -- Add Window's width by 1
vim.keymap.set('n','<C-Right>',':vertical resize +5<CR>',{silent = true}) -- Add Window's width by 5
vim.keymap.set('n','<S-Left>',':vertical resize -1<CR>',{silent = true}) -- Remove Window's width by 1
vim.keymap.set('n','<C-Left>',':vertical resize -5<CR>',{silent = true}) -- Remove Window's width by 5

--[[ Move Window ]]--
vim.keymap.set('n','wwx','<C-w>x<C-w>w') -- Exchange current Window with the next one
vim.keymap.set('n','wwi','<C-w>K') -- Move current Window to the top
vim.keymap.set('n','wwj','<C-w>H') -- Move current Window to the left
vim.keymap.set('n','wwk','<C-w>J') -- Move current Window to the bottom
vim.keymap.set('n','wwl','<C-w>L') -- Move current Window to the right

--[[ Split Windows ]]--
vim.keymap.set('n','Wj','<C-w>v') -- Add Left
vim.keymap.set('n','Wl','<C-w>v<C-w>w') -- Add Right
vim.keymap.set('n','Wi','<C-w>s') -- Add Top
vim.keymap.set('n','Wk','<C-w>s<C-w>w') -- Add Top

--[[ Split Windows and enter Explorer ]]--
vim.keymap.set('n','WJ','<C-w>v:Ex<CR>') -- Add Left
vim.keymap.set('n','WL','<C-w>v<C-w>w:Ex<CR>') -- Add Right
vim.keymap.set('n','WI','<C-w>s:Ex<CR>') -- Add Top
vim.keymap.set('n','WK','<C-w>s<C-w>w:Ex<CR>') -- Add Top

--[[ New Tab ]]--
vim.keymap.set('n','Wt',':tabnew<CR>:Ex<CR>')

--[[ Close Tab ]]--
-- vim.keymap.set('n','tQ',':tabo<CR>') -- Close all except current tab
-- vim.keymap.set('n','tq',':tabc<CR>') -- Close current tab

--[[ Move current Window to new Tab ]]--
vim.keymap.set('n','WT','<C-w>T')

--[[ Tab navigation ]]--
vim.keymap.set('n','>','gt') -- Next Tab
vim.keymap.set('n','<','gT') -- Prev Tab
--[[ vim.keymap.set('n','wt', function()
    local num = vim.fn.input("Jump to tab > ")
    if tonumber(num) then
        return num .. "gt"
    else
        return ":echo 'Invalid Number<CR>'"
    end
end, {expr = true}) ]]--

--[[ Tab Adjustment ]]--
vim.keymap.set('n','wT', function()
    local num = vim.fn.input("Move tab to position > ")

    if num == "1" then num = "0" end

    return ":tabm "..num.."<CR>"
end, {expr = true}) -- New tab

--[[ Save Files ]]--
vim.keymap.set('n', '<C-s>', ':w<CR>')
vim.keymap.set({'i','x'}, '<C-s>', '<ESC>:w<CR>')


--[[ Undo ]]--
vim.keymap.set('n', '<c-z>', 'u')
vim.keymap.set('i', '<c-z>', '<ESC>u')
vim.keymap.set('n', '<c-y>', '<C-r>')

--[[ Copying ]]--
vim.keymap.set('n', 'c' , 'yy') -- Copy whole line(normal)
vim.keymap.set('n', 'C' , 'yyp') -- Copy whole line(normal)
vim.keymap.set('x', 'C' , '<ESC>`<^V`>y`>p') -- Copy whole line(normal)
vim.keymap.set('x', 'c' , 'y') -- Copy whole line(visual)

--[[ Basic movement ]]--
vim.keymap.set({'n','x'},'i',"v:count == 0 ? 'gk' : 'k'", { expr = true })
vim.keymap.set({'n','x'},'j','h')
vim.keymap.set({'n','x'},'l','l')
vim.keymap.set({'n','x'},'k',"v:count == 0 ? 'gj' : 'j'", { expr = true })

--[[ Word jump ]]--
vim.keymap.set({'n','x'},'J','b')
vim.keymap.set({'n','x'},'L','w')
vim.keymap.set({'n','x'},'<M-l>','e')
vim.keymap.set({'n','x'},'<M-j>','ge')

--[[ Scrolling ]]--
vim.keymap.set({'n','x','i'},'<C-w>i','<C-y>')
vim.keymap.set({'n','x','i'},'<C-w>I','5<C-y>')
vim.keymap.set({'n','x','i'},'<C-w>k','<C-e>')
vim.keymap.set({'n','x','i'},'<C-w>K','5<C-e>')

--[[ Multi-line jumping ]]--
local mul_ln_jmp = 3
vim.keymap.set({'n','x'},'I', function()
    return mul_ln_jmp.."k"
end, {expr = true})
vim.keymap.set({'n','x'},'K', function()
    return mul_ln_jmp.."j"
end, {expr = true})

--[[ Paragraph jumping ]]--
-- vim.keymap.set({'n','x'},'.','}')
-- vim.keymap.set({'n','x'},',','{')

--[[ Jump to the start and end of document ]]--
vim.keymap.set({'n','x'},'<leader>i','gg')
vim.keymap.set({'n','x'},'<leader>k','G')

--[[ Jump to the start and end of line  ]]--
vim.keymap.set({'n'},'<leader>l','$')
vim.keymap.set({'x'},'<leader>l','$h')
vim.keymap.set({'n','x'},'<leader>j','^')


--[[Move line ]]--
vim.keymap.set('n','<M-i>',"V:m '<-2<CR>gv=gv<ESC>")
vim.keymap.set('n','<M-k>',"V:m '>+1<CR>gv=gv<ESC>")
vim.keymap.set('x','<M-i>', ":m '<-2<CR>gv=gv")
vim.keymap.set('x','<M-k>', ":m '>+1<CR>gv=gv")

--[[ Insert mode ]]--
vim.keymap.set('n','a','i')
vim.keymap.set('n','d','a')

--[[ Insert to the end of word ]]--
vim.keymap.set('n','A','viwb<ESC>i')
vim.keymap.set('x','A', function()
    if vim.fn.mode() == 'v' or vim.fn.mode() == 'V' then return 'iwb<ESC>i'
    else return 'I'
    end
end, {expr = true})
vim.keymap.set('n','D','viwA')
vim.keymap.set('x','D', function()
    if vim.fn.mode() == 'v' or vim.fn.mode() == 'V' then return 'iwA'
    else return 'A'
    end
end, {expr = true})


--[[ Insert to the end of line ]]--
vim.keymap.set({'n','x'},'E','<ESC>A')
vim.keymap.set({'n','x'},'Q','<ESC>I')

--[[ Tab then enter insert mode ]]--
vim.keymap.set({'n','x'}, '<TAB>', 'i<TAB>')

--[[ Indent Selected Line ]]--
vim.keymap.set('x', '<TAB>', function()
    vim.cmd([[execute "normal! \<ESC>"]])
    local start_pos = vim.fn.line("'<")
    local end_pos = vim.fn.line("'>")

    local h = end_pos - start_pos

    vim.api.nvim_feedkeys("`<","n",false)

    for i = 0, h do vim.api.nvim_feedkeys(">>j","n",false) end
    vim.api.nvim_feedkeys("`<V`>","n",false)
end)
vim.keymap.set('x', '<leader><TAB>', function()
    vim.cmd([[execute "normal! \<ESC>"]])
    local start_pos = vim.fn.line("'<")
    local end_pos = vim.fn.line("'>")

    local h = end_pos - start_pos

    vim.api.nvim_feedkeys("`<","n",false)

    for i = 0, h do vim.api.nvim_feedkeys("<<j","n",false) end

    vim.api.nvim_feedkeys("`<V`>","n",false)
end)


--[[ Create new line above and enter insert mode ]]--
vim.keymap.set({'n','x'},"<leader><CR>",'<ESC>O')

--[[ Backspace enter insert mode ]]--
vim.keymap.set({'n','x'},'<BS>','s')

--[[ Backspace(normal) and Cut(visual) ]]--
vim.keymap.set('n','f','a<BS><ESC>') -- BS
vim.keymap.set('x','f','x') -- Cut selected letter(s)
vim.keymap.set('x','F',function()
    if vim.fn.mode() == "v" then
        vim.cmd([[execute "normal! \<ESC>"]])
        local start_pos = vim.fn.col("'<")
        local end_pos = vim.fn.col("'>")

        local len = end_pos - start_pos + 1

        if len <= 1 then vim.cmd("normal! viwx")
        else
            if vim.fn.getpos(".")[3] == start_pos then
                vim.cmd("normal! `>viwo`<liw")
                vim.api.nvim_feedkeys("x","n",false)
            else
                vim.cmd("normal! `<viw`>hiw")
                vim.api.nvim_feedkeys("x","n",false)
            end
        end
    end
end) -- Cut selected word(s)

--[[ Delete ]]--
vim.keymap.set('n','X','Vx') -- Delete whole line
vim.keymap.set('x','x','x') -- Delete selected letter(s)
vim.keymap.set('x','X', function()
    if vim.fn.mode() == "v" then
        vim.cmd([[execute "normal! \<ESC>"]])
        local start_pos = vim.fn.col("'<")
        local end_pos = vim.fn.col("'>")

        local len = end_pos - start_pos + 1

        if len <= 1 then vim.cmd("normal! viwx")
        else
            if vim.fn.getpos(".")[3] == start_pos then
                vim.cmd("normal! `>viwo`<liw")
                vim.api.nvim_feedkeys("x","n",false)
            else
                vim.cmd("normal! `<viw`>hiw")
                vim.api.nvim_feedkeys("x","n",false)
            end
        end
    end
end) -- Delete selected word(s)




--[[ Remove word(normal) and enter Insert mode ]]--
vim.keymap.set('n','S','viws')
vim.keymap.set({'n', 'x'},'<leader>e','<ESC>v$hxA')
vim.keymap.set({'n', 'x'},'<leader>q','<ESC>hv^xI')

--[[ Remove selected words then enter insert mode ]]--
vim.keymap.set('x','S',function()
    if vim.fn.mode() == "v" then
        vim.cmd([[execute "normal! \<ESC>"]])
        local start_pos = vim.fn.col("'<")
        local end_pos = vim.fn.col("'>")

        local len = end_pos - start_pos + 1

        if len <= 1 then
            vim.cmd("normal! viw")
            vim.api.nvim_feedkeys("s","n",false)
        else
            if vim.fn.getpos(".")[3] == start_pos then
                vim.cmd("normal! `>viwo`<liw")
                vim.api.nvim_feedkeys("s","n",false)
            else
                vim.cmd("normal! `<viw`>hiw")
                vim.api.nvim_feedkeys("s","n",false)
            end
        end
    end
end)

--[[ Remove selected letters and enter insert mode ]]--
vim.keymap.set('x','s','s')

--[[ Remove line and enter Insert mode ]]--
vim.keymap.set({'n','x'}, 'F', 'S')

--[[ Backspace/Delete in Insert Mode ]]--
vim.keymap.set('i','<C-l>','<DEL>')
vim.keymap.set('i','<C-j>','<BS>')
vim.keymap.set('i','<C-i>','<ESC>viws')
vim.keymap.set('i','<C-k>','<ESC>llviws')

--[[ Enter Visual block mode ]]--
vim.keymap.set({'n','x'},'<M-v>','<C-v>')

--[[ Center Screen ]]--
vim.keymap.set({'n','x'},'<C-f>', 'zz')

--[[ Open and close brackets selected words ]]--
vim.keymap.set('x','a{', "<ESC>`>a}<ESC>`<i{<ESC>")
vim.keymap.set('x','a(', "<ESC>`>a)<ESC>`<i(<ESC>")
vim.keymap.set('x','a[', "<ESC>`>a]<ESC>`<i[<ESC>")
vim.keymap.set('x','a<', "<ESC>`>a><ESC>`<i<<ESC>")
vim.keymap.set('x','a"', '<ESC>`>a"<ESC>`<i"<ESC>')
vim.keymap.set('x',"a'", "<ESC>`>a'<ESC>`<i'<ESC>")
vim.keymap.set('x',"a-", "<ESC>`>a<leader>]]--<ESC>`<i--[[<leader><ESC>")

--[[ Check char behind/after curstor Func ]]--
local function char_behind_cursor()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    if col == 0 then return nil end
    local line = vim.api.nvim_get_current_line()
    local char = line:sub(col,col)
    return char
end
local function char_behind_behind_cursor()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    if col == 0 then return nil end
    local line = vim.api.nvim_get_current_line()
    local char = line:sub(col-1,col-1)
    return char
end
local function char_after_cursor()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    --if col == 0 then return nil end
    local line = vim.api.nvim_get_current_line()
    local char = line:sub(col+1,col+1)
    return char
end

--[[ Brackets and Quotes Table ]]--
local bracket = {}
bracket["{"] = "}"
bracket["("] = ")"
bracket["["] = "]"
--bracket["<"] = ">"
local quote = {'"',"'"}

--[[ Remove empty brackets ]]--
vim.keymap.set({'i'},'<BS>',function()
    for b, a in pairs(bracket) do
        if char_behind_cursor() == b and char_after_cursor() == a then
            return "<BS><DEL>"
        end
    end
    for i, q in pairs(quote) do
        if char_behind_cursor() == q and char_after_cursor() == q then
            return "<BS><DEL>"
        end
    end
    return "<BS>"
end, {expr = true})

--[[ Create new line and enter insert mode ]]--
vim.keymap.set('n','<CR>',function()
    if char_after_cursor() == bracket[char_behind_cursor()] then
        return 'i<CR><ESC>O'
    else return 'o'
    end
end, {expr = true})
vim.keymap.set('x','<CR>','s<CR>')

--[[ Squeeze into between brackets when Enter inside them ]]--
vim.keymap.set('i','<CR>',function()
    if char_after_cursor() == bracket[char_behind_cursor()] then
        return '<CR><ESC>O'
    elseif char_behind_cursor() then
        if char_behind_cursor() == bracket[char_behind_behind_cursor()] then
            return '<Left><CR><ESC>O'
        end
        return '<CR>'
    else return '<CR>'
    end
end, {expr = true})

--[[ Select within brackets ]]--
vim.keymap.set('x','(','ib')
vim.keymap.set('x','<leader>(','ab')
vim.keymap.set('x','[','i[')
vim.keymap.set('x','<leader>[','a[')
vim.keymap.set('x','{','iB')
vim.keymap.set('x','<leader>{','aB')
vim.keymap.set('x',"'","<ESC>F'lvf'h")
vim.keymap.set('x',"<leader>'","<ESC>F'vf'")
vim.keymap.set('x','"','<ESC>F"lvf"h')
vim.keymap.set('x','<leader>"','<ESC>F"vf"')

--[[ Backspace in insert mode ]]--
vim.keymap.set('i','<C-BS>','<ESC>viws')

--[[ Select word ]]--
vim.keymap.set('x','v', function()
    if vim.fn.mode() == "v" then
        vim.cmd([[execute "normal! \<ESC>"]])
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")

        local len = end_pos[3] - start_pos[3] + 1

        if len <= 1 then vim.cmd("normal! viw")
        else
            if vim.fn.getpos(".")[3] == start_pos[3] then
                vim.cmd("normal! `>viwo`<liw")
            else
                vim.cmd("normal! `<viw`>hiw")
            end
        end
    end
end)
vim.keymap.set('x','V',function()
    if vim.fn.mode() == "v" then
        vim.cmd([[execute "normal! \<ESC>"]])
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")

        local len = end_pos[3] - start_pos[3] + 1

        if len <= 1 then vim.cmd("normal! viW")
        else
            if vim.fn.getpos(".")[3] == start_pos[3] then
                vim.cmd("normal! `>viWo`<liW")
            else
                vim.cmd("normal! `<viW`>hiW")
            end
        end
    end
end)


--[[ Select Paragraph ]]--
vim.keymap.set({'n','x', 'i'},'<C-a>',function()
    if vim.api.nvim_buf_line_count(0) == 1 then
        return '<ESC>V'
    elseif vim.fn.mode() ~= 'V' then
        return '<ESC>{jV}k$'
    else
        return '<ESC>GVgg'
    end
end, {expr = true})

--[[ Find next occurence or next bracket pair ]]--
vim.keymap.set({'n','x'},'<c-l>', function()
    for b, a in pairs(bracket) do
        if char_after_cursor() == b or char_after_cursor() == a then
            return '%'
        end
    end
    return 'g*'
end, {expr = true})
vim.keymap.set({'n','x'},'<c-j>', function()
    for b, a in pairs(bracket) do
        if char_after_cursor() == b or char_after_cursor() == a then
            return '%'
        end
    end
    return 'g#'
end, {expr = true})


--[[ Connecting lines ]]--
vim.keymap.set('n', 'u', 'kJ') -- Bring current line up with space
vim.keymap.set('n', 'U', 'J')  -- Bring line below up
vim.keymap.set('n', '<C-u>', 'kgJ') -- Bring current line up without space

--[[ Break line ]]--
vim.keymap.set('n', 'o', 'i<CR><ESC>') -- Break line at cursor and move cursor down
vim.keymap.set('n', 'O', 'i<CR><ESC>k$')  -- Break line at cursor and don't move cursor down
vim.keymap.set('n', '<C-o>', '<ESC>i<CR><ESC>O') -- Break line then squeeze in between two line (Normal)
vim.keymap.set('i', '<C-o>', '<ESC>a<CR><ESC>O') -- Break line then squeeze in between two line (Insert)

--[[ Indentation Correction ]]--
vim.keymap.set('n', '<leader>=', 'maggVG=`a')

--[[ Netrw  Keymapping ]]--
vim.api.nvim_create_autocmd("FileType", {
    pattern = "netrw",
    callback = function()
        local opts = {buffer = true, silent = true, remap = true}

        --[[ Basic Movement ]]--
        vim.keymap.set('n','i','<Up>', opts)
        vim.keymap.set('n','j','-', opts)
        vim.keymap.set('n','k','<Down>', opts)
        vim.keymap.set('n','l','<CR>', opts)

        --[[ Big Movement ]]--
        vim.keymap.set('n','I','3<Up>', opts)
        vim.keymap.set('n','K','3<Down>', opts)

        --[[ Exit Explorer ]]--
        vim.keymap.set('n','wq',':bd<CR>', opts)

        --[[ Split Windows ]]--
        vim.keymap.set('n','Wj','v<C-w>w', opts) -- Add Left
        vim.keymap.set('n','Wl','v<C-w>x', opts) -- Add Right
        vim.keymap.set('n','Wi','o<C-w>w', opts) -- Add Top
        vim.keymap.set('n','Wk','o<C-w>x', opts) -- Add Top

        --[[ Split Windows ]]--
        vim.keymap.set('n','WJ','v', opts) -- Add Left
        vim.keymap.set('n','WL','v<C-w>x<C-w>w', opts) -- Add Right
        vim.keymap.set('n','WI','o', opts) -- Add Top
        vim.keymap.set('n','WK','o<C-w>x<C-w>w', opts) -- Add Top

        --[[ Split Windows ]]--
        vim.keymap.set('n','Wt','v<C-w>TgT', opts) -- Add Left
        vim.keymap.set('n','WT','v<C-w>T', opts) -- Add Left

        --[[ Adjust Window ]]--
        vim.keymap.set('n','ww=','<C-w>=',opts) -- Equalize Windows' sizes
        vim.keymap.set('n','wwx','<C-w>x<C-w>w',opts) -- Exchange current Window with the next one
        vim.keymap.set('n','wwi','<C-w>K',opts) -- Move current Window to the top
        vim.keymap.set('n','wwj','<C-w>H',opts) -- Move current Window to the left
        vim.keymap.set('n','wwk','<C-w>J',opts) -- Move current Window to the bottom
        vim.keymap.set('n','wwl','<C-w>L',opts) -- Move current Window to the right

        vim.keymap.set('n','<S-Up>',':resize +1<CR>',opts) -- Add Window's height by 1
        vim.keymap.set('n','<C-Up>',':resize +5<CR>',opts) -- Add Window's height by 5
        vim.keymap.set('n','<S-Down>',':resize -1<CR>',opts) -- Remove Window's height by 1
        vim.keymap.set('n','<C-Down>',':resize -5<CR>',opts) -- Remove Window's height by 5
        vim.keymap.set('n','<S-Right>',':vertical resize +1<CR>',opts) -- Add Window's width by 1
        vim.keymap.set('n','<C-Right>',':vertical resize +5<CR>',opts) -- Add Window's width by 5
        vim.keymap.set('n','<S-Left>',':vertical resize -1<CR>',opts) -- Remove Window's width by 1
        vim.keymap.set('n','<C-Left>',':vertical resize -5<CR>',opts) -- Remove Window's width by 5


    end})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "undotree",
    callback = function()
        local opts = {buffer = true, silent = true, remap = false}

        --[[ Basic Movement ]]--
        vim.keymap.set('n','i','<Up>', opts)
        vim.keymap.set('n','j','<Left>', opts)
        vim.keymap.set('n','k','<Down>', opts)
        vim.keymap.set('n','l','<Right>', opts)
    end})


