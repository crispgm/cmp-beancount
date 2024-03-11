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
        '#',
        '^',
    }
end

local ltrim = function(s)
    return s:match('%s*(%S+)%s*$')
end

local get_items = function(account_path)
    vim.api.nvim_exec2(
        string.format(
            [[python3 <<EOB
from beancount.loader import load_file
from beancount.core import getters

entries, _, _ = load_file('%s')
accounts = getters.get_accounts(entries)
links = getters.get_all_links(entries)
tags = getters.get_all_tags(entries)
f = lambda l: ','.join(f'"{s}"' for s in sorted(l))
vim.command('let b:beancount_accounts = [{}]'.format(f(accounts)))
vim.command('let b:beancount_tags = [{}]'.format(f(tags)))
vim.command('let b:beancount_links = [{}]'.format(f(links)))
EOB]],
            account_path
        ),
        { output = true }
    )

    local items = {}

    items.accounts = {}
    for _, s in ipairs(vim.b.beancount_accounts) do
        table.insert(items.accounts, {
            label = s,
            kind = cmp.lsp.CompletionItemKind.Interface,
        })
    end

    items.tags = {}
    for _, s in ipairs(vim.b.beancount_tags) do
        table.insert(items.tags, {
            label = '#' .. s,
            kind = cmp.lsp.CompletionItemKind.Property,
        })
    end

    items.links = {}
    for _, s in ipairs(vim.b.beancount_links) do
        table.insert(items.links, {
            label = '^' .. s,
            kind = cmp.lsp.CompletionItemKind.Reference,
        })
    end

    return items
end

local split_accounts = function(str)
    local t = {}
    for s in string.gmatch(str, '([^:]+)') do
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

    local items = {}

    local input = ltrim(request.context.cursor_before_line):lower()

    if string.match(input, '^#') then
        for _, tag in ipairs(self.items.tags) do
            if vim.startswith(tag.label:lower(), input) then
                table.insert(items, tag)
            end
        end

        return callback(items)
    end

    if string.match(input, '^%^') then
        for _, link in ipairs(self.items.links) do
            if vim.startswith(link.label:lower(), input) then
                table.insert(items, link)
            end
        end

        return callback(items)
    end

    local prefix_mode = false
    local pattern = ''
    local prefixes = split_accounts(input)

    for i, prefix in ipairs(prefixes) do
        if i == 1 then
            pattern = string.format('%s[%%w%%-]*', prefix:lower())
        else
            pattern = string.format('%s:%s[%%w%%-]*', pattern, prefix:lower())
        end
    end
    if #prefixes > 1 and pattern ~= '' then
        prefix_mode = true
    end

    for _, account in ipairs(self.items.accounts) do
        if prefix_mode then
            if string.match(account.label:lower(), pattern) then
                table.insert(items, {
                    word = account.label,
                    label = account.label,
                    kind = account.kind,
                    textEdit = {
                        filterText = input,
                        newText = account.label,
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
            end
        else
            if vim.startswith(account.label:lower(), input) then
                table.insert(items, account)
            end
        end
    end

    callback(items)
end

return source
