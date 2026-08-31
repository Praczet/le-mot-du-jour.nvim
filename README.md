# le-mot-du-jour.nvim

A Neovim plugin that politely reminds you that learning French vocabulary is still a thing you decided to do.

It fetches a daily or random French word from [Trouve-mot.fr](https://trouve-mot.fr/), extracts a definition from [Wiktionnaire](https://fr.wiktionary.org/), attempts an English translation using whatever supported CLI translator you have installed, caches everything, and displays the result on your dashboard.

No drama. No AI hype. Just words.

---

## What it does

* Fetches a daily or random French word from [Trouve-mot.fr](https://trouve-mot.fr/)
* Pulls French definitions from [Wiktionnaire](https://fr.wiktionary.org/) through the MediaWiki API
* Cleans up Wiktionnaire's creative wikicode for compact dashboard display
* Translates French → English using:

  * `dict` with the FreeDict `fd-fra-eng` dictionary — preferred
  * `trans` / Translate Shell — fallback
* Caches results locally so you don't DOS Wiktionnaire
* Renders nicely formatted output for dashboards
* Runs everything asynchronously so Neovim remains usable

---

## Requirements

### Required

* Neovim 0.9+
* `curl`

### Translation

Translation is optional.

If you want English translations, install at least one of:

* `dict` + the FreeDict `fd-fra-eng` dictionary — preferred translation backend
* [`trans`](https://github.com/soimort/translate-shell) / Translate Shell — fallback translation backend

The plugin checks for `dict` first and falls back to `trans` when `dict` is unavailable.

### Optional

* `jq` — pretty JSON makes debugging less depressing

---

## Installation

### lazy.nvim

```lua
{
  "Praczet/le-mot-du-jour.nvim",
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
  daily_random = "random",
  dashboard = "snacks.dashboard",
  highlights = {
    word = "key",
    definition = "text",
    last_def = "dir",
    translation = "dir",
  },
})
```

You may tweak it. You probably won't.

> [!NOTE]
> `daily_random` controls where the displayed word comes from.
>
> Set it to `"daily"` to use the Trouve-mot.fr word of the day, or `"random"` to request a random word.
>
> The API has occasionally remained stuck on the same daily word, so `"random"` is currently the safer option if variety is more important than strict word-of-the-day semantics.

---

## Usage

### Dashboard

Example for [Snacks.nvim](https://github.com/folke/snacks.nvim) dashboard:

```lua
{
  text = function()
    return require("le-mot-du-jour").get_mdj_for_dashboard(60)
  end,
}
```

Result:

* A French word
* A definition
* Some meanings
* Maybe a translation
* A vague sense of linguistic progress

### Manual update

```vim
:MotDuJourUpdate
```

Force a specific word:

```vim
:MotDuJourUpdate bonjour
```

Useful for testing. Also useful for cheating.

---

## Cache

By default, cached data is stored in:

```text
~/.local/share/nvim/mdj/
```

or, more precisely:

```lua
vim.fn.stdpath("data") .. "/mdj"
```

Files:

* `mdj_YYYYMMDD.json` — daily cache
* `mdj_log.json` — historical record of your vocabulary journey

One day you might read it.

Today is not that day.

---

## Architecture

Calm and predictable.

### Modules

* `api.lua` — talks to the internet so you don't have to
* `parse.lua` — removes Wiktionnaire's creative formatting
* `cache.lua` — writes JSON like a responsible adult
* `dashboard.lua` — builds pretty lines
* `commands.lua` — defines `:MotDuJourUpdate`
* `util.lua` — async jobs + helpers
* `init.lua` — orchestration layer
* `config.lua` — defaults nobody reads

### Flow

```text
word → definition → translation → cache → dashboard
```

Nothing magical happens here.

---

## Data sources & acknowledgements

`le-mot-du-jour.nvim` is the glue. The vocabulary, definitions, and optional translations come from external projects and services.

### Trouve-mot.fr

[trouve-mot.fr](https://trouve-mot.fr/) provides the French word used by the plugin.

The plugin currently uses:

```text
https://trouve-mot.fr/api/daily
https://trouve-mot.fr/api/random
```

The daily endpoint provides the word of the day, while the random endpoint provides a random French word.

Trouve-mot.fr is an independent service and is not affiliated with this project.

### Wiktionnaire

French definitions are retrieved from [Wiktionnaire](https://fr.wiktionary.org/), the French-language edition of Wiktionary.

The plugin queries the MediaWiki API at:

```text
https://fr.wiktionary.org/w/api.php
```

It retrieves the source wikitext for the selected word and locally extracts and simplifies definitions for compact dashboard display.

Wiktionnaire content is provided under Wikimedia's applicable content licensing terms. When redistributing or reusing Wiktionnaire material, consult:

* [Wiktionnaire](https://fr.wiktionary.org/)
* [Wiktionnaire: Réutilisation du contenu](https://fr.wiktionary.org/wiki/Wiktionnaire:R%C3%A9utilisation_du_contenu_du_Wiktionnaire)
* [Wikimedia Terms of Use](https://foundation.wikimedia.org/wiki/Policy:Terms_of_Use)

Definitions displayed by this plugin may therefore contain adapted material originating from Wiktionnaire.

The plugin modifies the original representation by stripping wiki markup and extracting only the portions useful for compact display.

Wikimedia Foundation and Wiktionnaire are not affiliated with and do not endorse this plugin.

### FreeDict

When the `dict` command is available, the plugin uses the:

```text
fd-fra-eng
```

French → English dictionary.

This dictionary is part of the [FreeDict](https://freedict.org/) project.

The exact packaging and installation procedure depends on your operating system.

For example, after installation you can check available dictionaries with:

```bash
dict -D
```

and look for:

```text
fd-fra-eng
```

FreeDict is an independent project and is not affiliated with this plugin.

### Translate Shell

If `dict` is unavailable, the plugin can fall back to [`trans`](https://github.com/soimort/translate-shell), provided by Translate Shell.

The equivalent command executed by the plugin is:

```bash
trans -b fr:en <word>
```

Translate Shell may itself use different translation providers depending on its version and configuration.

For that reason, `le-mot-du-jour.nvim` does not claim that translations originate from any particular online translation service.

Translate Shell is an independent project and is not affiliated with this plugin.

---

## External requests

For transparency, the plugin may make network requests to:

```text
https://trouve-mot.fr/
https://fr.wiktionary.org/
```

Translation through `trans` may make additional network requests depending on how Translate Shell is configured.

Translation through `dict` may use a local or remote DICT server depending on your system configuration.

Cached results reduce repeated requests.

No analytics, telemetry, or user tracking are implemented by `le-mot-du-jour.nvim`.

---

## Third-party licenses

The MIT license in this repository applies to the `le-mot-du-jour.nvim` source code itself.

It does **not** replace or override the licenses or terms of third-party services, software, dictionaries, or content used by the plugin.

In particular:

* Trouve-mot.fr data remains subject to the terms of Trouve-mot.fr
* Wiktionnaire content remains subject to Wikimedia/Wiktionnaire licensing terms
* FreeDict dictionaries retain their respective licenses
* Translate Shell retains its own license and the terms of any translation services it accesses

If you redistribute cached data, definitions, dictionaries, or other third-party content, check the corresponding source's licensing requirements.

---

## Philosophy

* Terminal tools first
* Async always
* Small surface area
* No unnecessary abstractions
* No startup cost beyond your own expectations
* Give credit to the people and projects supplying the useful bits

---

## License

`le-mot-du-jour.nvim` itself is released under the MIT License.

See [LICENSE](LICENSE).

Do whatever you want.

Just don't blame the plugin if your French is still terrible.

---

## Thanks

This tiny plugin would be considerably less useful without:

* [Trouve-mot.fr](https://trouve-mot.fr/) for finding French words
* [Wiktionnaire](https://fr.wiktionary.org/) and its contributors for definitions
* [FreeDict](https://freedict.org/) and its contributors for dictionary data
* [Translate Shell](https://github.com/soimort/translate-shell) for the translation fallback
* [Neovim](https://neovim.io/) for providing somewhere unnecessarily elaborate to learn the word *pamplemousse*

Merci.
