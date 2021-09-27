local source = {}

source.new = function()
    local self = setmetatable({}, { __index = source })
    self.items = nil
    return self
end

source.get_trigger_characters = function()
    return { 'Ex', 'In', 'As', 'Li', 'Eq' }
end

source.complete = function(self, request, callback)
    if vim.bo.filetype ~= 'beancount' then
        callback()
        return
    end
    if not self.items then
        self.items = require('cmp_bean_account.items')
    end

    local items = {}
    local count = 0
    for _, item in ipairs(self.items) do
        if vim.startswith(item.label, request.context.cursor_before_line) then
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
