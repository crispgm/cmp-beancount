# cmp-beancount

nvim-cmp source for beancount accounts.

## Setup

Prerequisites:

- Python3
- Beancount

Install with your favorite package manager:
```lua
use('crispgm/cmp-beancount')
```

Then, add to completion source:
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
