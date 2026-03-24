# le-mot-du-jour.nvim

A Neovim plugin that politely reminds you that learning French vocabulary
is still a thing you decided to do.

It fetches a **French word of the day**, extracts a definition from Wiktionary,
attempts a translation using whatever CLI translator you have installed,
caches everything, and displays the result on your dashboard.

No drama. No AI hype. Just words.

---

## What it does

- Fetches a **daily French word** from an external API
- Pulls **definitions from Wiktionary** (and cleans the wikicode mess)
- Translates using:
  - `dict` (civilized choice)
  - `trans` (acceptable fallback)
- Caches results locally so you don’t DOS Wiktionary
- Renders nicely formatted output for dashboards
- Runs everything **asynchronously** so Neovim remains usable

---

## Requirements

Hard requirements:

- Neovim **0.9+**
- `curl`

Strongly recommended for better life decisions:

- `dict`
- `trans`
- `jq` (pretty JSON makes debugging less depressing)

---

## Installation

### lazy.nvim

```lua
{
  "yourname/le-mot-du-jour.nvim",
  config = function()
    require("le-mot-du-jour").setup()
  end,
}
```

If you use another plugin manager, you already know what to do.

---

## Configuration

Default configuration is intentionally boring:

```lua
require("le-mot-du-jour").setup({
  cache_dir = vim.fn.stdpath("data") .. "/mdj",
  rows = 3,
  width = 60,
  dashboard = "snacks.dashboard",
  highlights = {
    word = "key",
    definition = "text",
    last_def = "dir",
    translation = "dir",
  },
})
```

You may tweak it. You probably won’t.

---

## Usage

### Dashboard

Example for Snacks dashboard:

```lua
{
  text = function()
    return require("le-mot-du-jour").get_mdj_for_dashboard(60)
  end,
}
```

Result:

- A French word
- A definition
- Some meanings
- Maybe a translation
- A vague sense of linguistic progress

### Manual update

```
:MotDuJourUpdate
```

Force a specific word:

```
:MotDuJourUpdate bonjour
```

Useful for testing.
Also useful for cheating.

---

## Cache

Stored in:

```
~/.local/share/nvim/mdj/
```

Files:

- `mdj_YYYYMMDD.json` — daily cache
- `mdj_log.json` — historical record of your vocabulary journey

One day you might read it.  
Today is not that day.

---

## Architecture (calm and predictable)

Modules:

- `api.lua` — talks to the internet so you don’t have to
- `parse.lua` — removes Wiktionary’s creative formatting
- `cache.lua` — writes JSON like a responsible adult
- `dashboard.lua` — builds pretty lines
- `commands.lua` — defines `:MotDuJourUpdate`
- `util.lua` — async jobs + helpers
- `init.lua` — orchestration layer
- `config.lua` — defaults nobody reads

Flow:

```
daily word → definition → translation → cache → dashboard
```

Nothing magical happens here.

---

## Philosophy

- Terminal tools first
- Async always
- Small surface area
- No unnecessary abstractions
- No startup cost beyond your own expectations

---

## License

MIT

Do whatever you want.  
Just don’t blame the plugin if your French is still terrible.
