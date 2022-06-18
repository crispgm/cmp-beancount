# cmp-beancount

nvim-cmp source for beancount accounts.

## Setup

Clone the repo, and use packer.nvim to load locally.

```lua
use('crispgm/cmp-beancount')
```

Then, edit your nvim config:

```lua
require('cmp').setup {
  sources = {
    {
      name = 'beancount',
      option = {
        account = '/path/to/account.bean'
      }
    }
  }
}
```
