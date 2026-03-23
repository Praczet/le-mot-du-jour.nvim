# le-mot-du-jour.nvim

**Mot‑du‑Jour for Neovim.**

A small plugin that fetches a **French word of the day**, shows its **definition**, and provides an **English translation** — directly inside Neovim.

The word is fetched from:

→ <https://trouve-mot.fr/api/daily>

Definitions are fetched locally using `sdcv`.  
Translations use `dict` (preferred) or `trans` as fallback.

The result is cached daily.

---

## Features

- Fetches **French word of the day**
- Shows **French definition**
- Shows **English translation**
- Caches results per day
- Maintains a simple history log
- Dashboard‑friendly formatted output
- Async execution (Neovim stays responsive)
- Fallback logic for missing tools

---

## Requirements

External tools:

- `curl`
- `sdcv`
- `jq` *(optional but recommended)*
- `dict` *(preferred translator)*
- `trans` *(fallback translator)*

Example install (Arch):

```bash
sudo pacman -S curl sdcv jq dictd
yay -S translate-shell
```

---

## Installation

Using lazy.nvim:

```lua
{
    "yourname/le-mot-du-jour.nvim",
    config = function()
        require("mdj").setup()
    end
}
```

---

## Configuration

Default configuration:

```lua
require("mdj").setup({
    cache_dir = vim.fn.stdpath("data") .. "/mdj",
    rows = 3,
    width = 60,
    dashboard = "snacks.dashboard",
    highlights = {
        word = "Title",
        definition = "Normal",
        last_def = "Special",
        translation = "Comment",
    },
})
```

---

## Usage

### Update word manually

```vim
:MotDuJourUpdate
```

Or force specific word:

```vim
:MotDuJourUpdate maison
```

---

### Dashboard integration

Example with snacks.dashboard:

```lua
local mdj = require("mdj")

dashboard.section.mdj = function()
    return le-mot-du-jour.get_mdj_for_dashboard(60)
end
```

On first load the plugin shows:

```
Loading word of the day...
```

Then updates automatically.

---

## Cache

Daily cache file:

```
~/.local/share/nvim/mdj/mdj_YYYYMMDD.json
```

History log:

```
~/.local/share/nvim/mdj/mdj_log.json
```

---

## Translation logic

1. Try `dict`
2. Fallback to `trans`
3. If both missing → translation disabled

`dict` provides dictionary‑style definitions.  
`trans` provides sentence‑style translation.

---

## Definition logic

Definition is extracted using:

```
sdcv → JSON → jq → sed → pandoc
```

This pipeline may change in future versions.

---

## Future ideas

- Floating window viewer
- Hover word translation
- Treesitter word detection
- Weekly / monthly word modes
- Offline word database fallback
- Pronunciation support
- TUI history picker

---

## License

MIT

---

## Philosophy

This plugin does one thing:

> It reminds you that languages exist.

And occasionally teaches one word.
