local source = {}
local cmp = require('cmp')

source.new = function()
    local self = setmetatable({}, { __index = source })
    self.items = nil
    return self
end

source.get_trigger_characters = function()
    return { 'Ex', 'In', 'As', 'Li', 'Eq' }
end

local ltrim = function(s)
    return s:match('^%s*(.*)')
end

local get_items = function(account_path)
    local output = vim.api.nvim_exec(
        string.format(
            [[python3 <<EOB
from beancount.loader import load_file
f = load_file('%s')
for item in f[0]:
    print(item.account)
EOB]],
            account_path
        ),
        true
    )
    local items = {}
    for s in output:gmatch('[^\r\n]+') do
        table.insert(items, {
            label = s,
            kind = cmp.lsp.CompletionItemKind.Property,
        })
    end

    return items
end

source.complete = function(self, request, callback)
    if vim.bo.filetype ~= 'beancount' then
        callback()
        return
    end
    if not self.items then
        self.items = get_items(request.option.account)
    end

    local items = {}
    local count = 0
    for _, item in ipairs(self.items) do
        if
            vim.startswith(
                item.label:lower(),
                ltrim(request.context.cursor_before_line):lower()
            )
        then
            table.insert(items, item)
            count = count + 1
        end
        if count >= 10 then
            break
        end
    end
    callback(items)
end

return source
