local source = {}
local cmp = require('cmp')

source.new = function()
    local self = setmetatable({}, { __index = source })
    self.items = nil
    return self
end

source.get_trigger_characters = function()
    return {
        'Ex',
        'In',
        'As',
        'Li',
        'Eq',
        'E:',
        'I:',
        'A:',
        'L:',
    }
end

local ltrim = function(s)
    return s:match('^%s*(.*)')
end

local get_items = function(account_path)
    -- improved version is based on https://github.com/nathangrigg/vim-beancount/blob/master/autoload/beancount.vim
    vim.api.nvim_exec(
        string.format(
            [[python3 <<EOB
from beancount.loader import load_file
from beancount.core import data

accounts = set()
entries, _, _ = load_file('%s')
for index, entry in enumerate(entries):
    if isinstance(entry, data.Open):
        accounts.add(entry.account)
vim.command('let b:beancount_accounts = [{}]'.format(','.join(repr(x) for x in sorted(accounts))))
EOB]],
            account_path
        ),
        true
    )
    local items = {}
    for _, s in ipairs(vim.b.beancount_accounts) do
        table.insert(items, {
            label = s,
            kind = cmp.lsp.CompletionItemKind.Property,
        })
    end

    return items
end

local split_accounts = function(str)
    local sep = ':'
    local t = {}
    for s in string.gmatch(str, '([^' .. sep .. ']+)') do
        table.insert(t, s)
    end
    return t
end

source.complete = function(self, request, callback)
    if vim.bo.filetype ~= 'beancount' then
        callback()
        return
    end
    local account_path = request.option.account
    if account_path == nil or not vim.fn.filereadable(account_path) then
        vim.api.nvim_echo({
            { 'cmp_beancount', 'ErrorMsg' },
            { ' ' .. 'Accounts file is not set' },
        }, true, {})
        callback()
        return
    end
    if not self.items then
        self.items = get_items(request.option.account)
    end

    local prefix_mode = false
    local input = ltrim(request.context.cursor_before_line):lower()
    local prefixes = split_accounts(input)
    local pattern = ''

    for i, prefix in ipairs(prefixes) do
        if i == 1 then
            pattern = string.format('%s%%a*', prefix:lower())
        else
            pattern = string.format('%s:%s%%a*', pattern, prefix:lower())
        end
    end
    if #prefixes > 1 and pattern ~= '' then
        prefix_mode = true
    end

    local items = {}
    local count = 0
    for _, item in ipairs(self.items) do
        if prefix_mode then
            if string.match(item.label:lower(), pattern) then
                table.insert(items, {
                    word = item.label,
                    label = item.label,
                    kind = item.kind,
                    textEdit = {
                        filterText = input,
                        newText = item.label,
                        range = {
                            start = {
                                line = request.context.cursor.row - 1,
                                character = request.offset - string.len(input),
                            },
                            ['end'] = {
                                line = request.context.cursor.row - 1,
                                character = request.context.cursor.col - 1,
                            },
                        },
                    },
                })
                count = count + 1
            end
        else
            if vim.startswith(item.label:lower(), input) then
                table.insert(items, item)
                count = count + 1
            end
        end
        if count >= 10 then
            break
        end
    end
    callback(items)
end

return source
