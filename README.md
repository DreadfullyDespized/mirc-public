# Dread's Dungeon — Twitch mIRC Bot

Public release copy of the mIRC script set behind the **dreadfullydespized**
Twitch channel, including **Dread's Dungeon**, the persistent chat RPG.

This repository is a **release mirror**. Active development and the live
production bot live in a private repository; this public copy only receives
snapshots that are known-good and tested. If you run this code, you are
running a stable release — not the bleeding edge.

## What's in here

- `scripts/aliases.ini` — `/loadscripts` and `/reloadscripts` entry points
- `scripts/mrcs/` — core libraries (mTwitch chat core, msqlite, JSON, WebSocket)
- `scripts/Customs/` — channel features: Dread's Dungeon RPG, quotes, custom
  sounds, Spotify now-playing, song requests, giveaways, chat minigames
- `perform.ini`, `channels.ini`, `remote.ini` — connection and startup config

## Setup

1. Install mIRC on the PC that will run the bot.
2. Clone this repository and place the `scripts/` folder where your mIRC
   install can reach it.
3. Set the `%mrcs` and `%customs` variables to the `scripts/mrcs/` and
   `scripts/Customs/` folders, then run `/loadscripts`.
4. Provide your own secrets **locally** (they are never committed — see
   `.gitignore`):
   - `%streamer_oauthtoken` — Twitch OAuth token for chat
   - `%clientid` — your Twitch application client ID
   - `%spot_cl` / `%spot_sec` — Spotify application credentials
   - `$yapi` — YouTube Data API key (for song requests)
   - `%obspass` — OBS WebSocket password
5. The bot reads and writes its own SQLite database (`test2.sqlite`, also never
   committed). Database setup helpers live in `SqliteUserDB-Alias.mrc`.

## Release discipline

- `main` here always mirrors a tested state of the private production repo.
- Development branches are never published here.
- The public copy may lag behind private development — that is intentional.

## License

MIT — see [LICENSE](LICENSE).

---

Built live on [twitch.tv/dreadfullydespized](https://www.twitch.tv/dreadfullydespized).
