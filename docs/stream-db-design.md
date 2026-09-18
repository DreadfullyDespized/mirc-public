# Stream DB design (Test2.sqlite)

Full schema reference generated from a `sqlite_master` export (structure only — zero row data). Regenerate with `scripts/generate-stream-db-doc.py` when the schema changes; do not hand-edit the DDL sections.

## Tables

### `Command`
_Custom chat commands (name, response, flood control, rank gate)._

| column | definition |
| --- | --- |
| `idCmd` | `INTEGER UNIQUE NOT NULL PRIMARY KEY AUTOINCREMENT` |
| `rank` | `INTEGER NOT NULL REFERENCES Rank (idRank) DEFAULT (1)` |
| `name` | `TEXT NOT NULL UNIQUE` |
| `response` | `TEXT NOT NULL` |
| `flood` | `INTEGER NOT NULL DEFAULT (0)` |
| `description` | `TEXT` |

References: `Rank`

### `CustomSound`
_Per-user custom sounds._

| column | definition |
| --- | --- |
| `idUser` | `INTEGER REFERENCES User (idUser)` |
| `name` | `TEXT COLLATE NOCASE` |
| `reason` | `TEXT` |
| `file` | `TEXT` |
| `rand` | `INTEGER` |
| `idName` | `TEXT REFERENCES User (name) COLLATE NOCASE` |

References: `User`

### `Dicksword_assoc`
_Dicksword game keyphrase associations._

| column | definition |
| --- | --- |
| `dicksword_id` | `BIGINT UNIQUE` |
| `keyphrase` | `BIGINT` |
| `twitch_user_id` | `BIGINT REFERENCES User (twitch_user_id)` |

References: `User`

### `Giveaway`
_Giveaway tickets per user._

| column | definition |
| --- | --- |
| `idUser` | `INTEGER REFERENCES User (idUser)` |
| `ticket` | `INTEGER` |

References: `User`

### `Highlight`
_Highlight requests (!hl): timestamps, msg, game, payout points, created flag._

| column | definition |
| --- | --- |
| `idHighlight` | `INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL` |
| `idUser` | `INTEGER REFERENCES User (idUser)` |
| `date` | `DATETIME NOT NULL` |
| `time` | `DATETIME NOT NULL` |
| `uptime` | `DATETIME NOT NULL` |
| `msg` | `TEXT NOT NULL` |
| `game` | `TEXT NOT NULL` |
| `points` | `INTEGER NOT NULL` |
| `created` | `INTEGER NOT NULL DEFAULT (0)` |
| `name` | `TEXT` |

References: `User`

### `Holiday`
_Holiday definitions._

| column | definition |
| --- | --- |
| `idHoliday` | `INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE` |
| `holiday_name` | `TEXT NOT NULL UNIQUE` |

### `Info`
_Profile flags (regular/mod/streamer), rank, birthday, lastseen._

| column | definition |
| --- | --- |
| `idUser` | `INTEGER UNIQUE REFERENCES User (idUser) ON DELETE CASCADE ON UPDATE CASCADE` |
| `birthday` | `DATE` |
| `lastseen` | `DATETIME` |
| `is_regular` | `INTEGER DEFAULT (0)` |
| `is_moderator` | `INTEGER DEFAULT (0)` |
| `is_streamer` | `INTEGER DEFAULT (0)` |
| `rank` | `INTEGER DEFAULT (1) REFERENCES Rank (idRank)` |
| `name` | `TEXT COLLATE NOCASE` |

References: `Rank`, `User`

### `Ivy`
_Ivy quotes._

| column | definition |
| --- | --- |
| `idIvy` | `INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE` |
| `idUser` | `INTEGER REFERENCES User (idUser)` |
| `name` | `TEXT REFERENCES User (name)` |
| `date` | `DATETIME NOT NULL` |
| `quote` | `TEXT NOT NULL UNIQUE ON CONFLICT ABORT` |

References: `User`

### `MiniPotato`
_MiniPotato win tiers per user._

| column | definition |
| --- | --- |
| `idUser` | `INTEGER UNIQUE REFERENCES User (idUser) NOT NULL` |
| `win_tier` | `INTEGER` |

References: `User`

### `PR_Rand`
_PotatoRun percent bands with win/fail messages._

| column | definition |
| --- | --- |
| `idPR` | `INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL` |
| `percent_low` | `DECIMAL` |
| `percent_high` | `DECIMAL` |
| `win_msg` | `TEXT` |
| `fail_msg` | `TEXT` |

### `PotatoPick`
_PotatoPick options._

| column | definition |
| --- | --- |
| `id` | `INTEGER PRIMARY KEY AUTOINCREMENT` |
| `success` | `TEXT UNIQUE ON CONFLICT FAIL` |
| `failure` | `TEXT UNIQUE` |
| `hi` | `INTEGER` |

### `PotatoRun`
_PotatoRun gambles (wager, PR band)._

| column | definition |
| --- | --- |
| `idRun` | `INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE` |
| `idUser` | `REFERENCES User (idUser) NOT NULL` |
| `wager` | `INTEGER (1, 2500) NOT NULL DEFAULT (1)` |
| `idPR` | `INTEGER REFERENCES PR_Rand (idPR)` |

References: `PR_Rand`, `User`

### `QSound`
_Quote-linked sounds (ref-counted into Quote.quoterand)._

| column | definition |
| --- | --- |
| `idQuote` | `INTEGER` |
| `filename` | `TEXT` |

### `Qotd`
_Question of the day._

| column | definition |
| --- | --- |
| `idQotd` | `INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL` |
| `idUser` | `BIGINT REFERENCES User (idUser)` |
| `qotd` | `TEXT NOT NULL` |
| `date` | `DATETIME NOT NULL` |
| `name` | `TEXT COLLATE NOCASE` |
| `current` | `INTEGER DEFAULT (0) NOT NULL` |

References: `User`

### `Quote`
_Saved quotes._

| column | definition |
| --- | --- |
| `idQuote` | `INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE` |
| `idUser` | `INTEGER REFERENCES User (idUser)` |
| `date` | `DATETIME NOT NULL` |
| `quote` | `TEXT NOT NULL` |
| `game` | `TEXT NOT NULL` |
| `quoterand` | `INTEGER NOT NULL DEFAULT (0)` |

References: `User`

### `Rank`
_Watch-time ranks (hour bands, titles)._

| column | definition |
| --- | --- |
| `idRank` | `INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE` |
| `title` | `TEXT NOT NULL` |
| `min_hour` | `INTEGER NOT NULL` |
| `max_hour` | `INTEGER NOT NULL` |
| `next_title` | `TEXT NOT NULL` |

### `Roll`
_Dice rolls (current round, victory flag)._

| column | definition |
| --- | --- |
| `idRoll` | `INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE` |
| `idUser` | `INTEGER REFERENCES User (idUser)` |
| `date` | `DATE NOT NULL` |
| `option` | `TEXT NOT NULL` |
| `roll` | `INTEGER NOT NULL DEFAULT (0)` |
| `current` | `INTEGER NOT NULL DEFAULT (0)` |
| `victory` | `INTEGER NOT NULL DEFAULT (0)` |
| `name` | `TEXT COLLATE NOCASE` |

References: `User`

### `Scare`
_Single-column table (idScare only)._

| column | definition |
| --- | --- |
| `idScare` | `INTEGER UNIQUE PRIMARY KEY AUTOINCREMENT NOT NULL` |

### `Seen`
_Attendance: which users were seen in which stream (unique idStream+idUser)._

| column | definition |
| --- | --- |
| `idSeen` | `INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL` |
| `idStream` | `INTEGER REFERENCES Stream (idStream)` |
| `idUser` | `INTEGER REFERENCES User (idUser)` |

References: `Stream`, `User`

### `Sound`
_Sound board entries (rank-gated)._

| column | definition |
| --- | --- |
| `idSound` | `INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE` |
| `idRank` | `INTEGER REFERENCES Rank (idRank)` |
| `name` | `TEXT NOT NULL UNIQUE COLLATE NOCASE` |
| `file` | `TEXT` |
| `rand` | `INTEGER NOT NULL DEFAULT (1)` |

References: `Rank`

### `Stat`
_Per-user counters: points economy, views, speech, donations, highlight totals._

| column | definition |
| --- | --- |
| `idUser` | `INTEGER UNIQUE REFERENCES User (idUser) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL` |
| `points` | `INTEGER DEFAULT (0) NOT NULL` |
| `speech` | `INTEGER DEFAULT (0) NOT NULL` |
| `views` | `INTEGER DEFAULT (0) NOT NULL` |
| `donations` | `INTEGER DEFAULT (0) NOT NULL` |
| `roll_win` | `INTEGER DEFAULT (0) NOT NULL` |
| `quote_total` | `INTEGER DEFAULT (0) NOT NULL` |
| `highlight_point_total` | `INTEGER DEFAULT (0) NOT NULL` |
| `highlight_created_total` | `INTEGER DEFAULT (0) NOT NULL` |
| `mp_4x` | `INTEGER DEFAULT (0)` |
| `mp_3x` | `INTEGER DEFAULT (0)` |
| `mp_2x` | `INTEGER DEFAULT (0)` |
| `mp_1x` | `INTEGER DEFAULT (0)` |
| `giveaway_win` | `INTEGER NOT NULL DEFAULT (0)` |
| `name` | `TEXT COLLATE NOCASE` |

References: `User`

### `Stream`
_Stream sessions: start/end date/time, game, title._

| column | definition |
| --- | --- |
| `idStream` | `INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL` |
| `start_date` | `DATETIME` |
| `start_time` | `DATETIME` |
| `start_song` | `TEXT` |
| `end_date` | `DATETIME` |
| `end_time` | `DATETIME` |
| `game` | `TEXT` |
| `title` | `TEXT` |

### `SubData`
_Subscription data per user (tiers, gifts)._

| column | definition |
| --- | --- |
| `idSubData` | `INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE` |
| `idUser` | `INTEGER UNIQUE REFERENCES User (idUser)` |
| `total_month` | `INTEGER NOT NULL DEFAULT (0)` |
| `tprime` | `INTEGER NOT NULL DEFAULT (0)` |
| `t1000` | `INTEGER NOT NULL DEFAULT (0)` |
| `t2000` | `INTEGER NOT NULL DEFAULT (0)` |
| `t3000` | `INTEGER NOT NULL DEFAULT (0)` |
| `received_gift` | `INTEGER NOT NULL DEFAULT (0)` |
| `gift_total` | `INTEGER NOT NULL DEFAULT (0)` |
| `g1000` | `INTEGER NOT NULL DEFAULT (0)` |
| `g2000` | `INTEGER NOT NULL DEFAULT (0)` |
| `g3000` | `INTEGER NOT NULL DEFAULT (0)` |
| `twitch_user_id` | `INTEGER NOT NULL UNIQUE` |
| `name` | `TEXT COLLATE NOCASE` |
| `lastupdated` | `DATETIME` |

References: `User`

### `User`
_Identity: Twitch user id + unique name._

| column | definition |
| --- | --- |
| `idUser` | `INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE` |
| `twitch_user_id` | `BIGINT UNIQUE` |
| `name` | `TEXT COLLATE NOCASE UNIQUE` |

### `UserHoliday`
_Holiday claims per user/year._

| column | definition |
| --- | --- |
| `idHoliday` | `INTEGER NOT NULL REFERENCES Holiday (holiday_name) ON DELETE CASCADE` |
| `idUser` | `INTEGER REFERENCES User (idUser) NOT NULL` |
| `year` | `INTEGER NOT NULL` |
| `name` | `TEXT COLLATE NOCASE` |

References: `Holiday`, `User`

### `subMessage`
_Sub messages by month count._

| column | definition |
| --- | --- |
| `idSubMsg` | `INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE ON CONFLICT FAIL` |
| `months` | `STRING` |
| `subMessage` | `TEXT` |

## Triggers

### `Info_update_lastseen` (on `Info`)
Stamps Info.lastseen = now whenever profile fields change.

```sql
CREATE TRIGGER Info_update_lastseen AFTER UPDATE OF birthday, is_regular, is_moderator, is_streamer, rank ON Info BEGIN UPDATE Info SET lastseen = datetime('now', 'localtime') WHERE idUser = OLD.idUser; END
```

### `Stat_Update_lastseen` (on `Stat`)
Any Stat update stamps Info.lastseen = now — earning/spending marks you seen.

```sql
CREATE TRIGGER Stat_Update_lastseen AFTER UPDATE ON Stat BEGIN UPDATE Info SET lastseen = datetime('now', 'localtime') WHERE idUser = OLD.idUser; END
```

### `SubData_AFTER_UPDATE` (on `SubData`)
Sub tier changes stamp SubData.lastupdated = now.

```sql
CREATE TRIGGER SubData_AFTER_UPDATE AFTER UPDATE OF total_month, tprime, t1000, t2000, t3000, received_gift, gift_total, g1000, g2000, g3000 ON SubData BEGIN UPDATE SubData SET lastupdated = datetime('now', 'localtime') WHERE idUser = OLD.idUser; END
```

### `Test` (on `QSound`)
QSound insert increments Quote.quoterand (ref-count).

```sql
CREATE TRIGGER Test INSERT ON QSound BEGIN UPDATE Quote SET quoterand = quoterand + 1 WHERE idQuote = NEW.idQuote; END
```

### `Test2` (on `QSound`)
QSound delete decrements Quote.quoterand (ref-count).

```sql
CREATE TRIGGER Test2 DELETE ON QSound BEGIN UPDATE Quote SET quoterand = quoterand - 1 WHERE idQuote = OLD.idQuote; END
```

### `UH_create_name` (on `UserHoliday`)
UserHoliday insert fills name from User.

```sql
CREATE TRIGGER UH_create_name AFTER INSERT ON UserHoliday BEGIN UPDATE UserHoliday SET name = (SELECT name FROM User WHERE User.idUser = UserHoliday.idUser); END
```

### `created_highlight` (on `Highlight`)
Payout trigger: 0->1 flip adds Highlight.points to Stat.points and Stat.highlight_point_total, increments Stat.highlight_created_total. Guarded 2026-09-18 with AND Old.created = 0 after a double-pay bug was found (SQLite fires UPDATE triggers even on same-value assignment).

```sql
CREATE TRIGGER created_highlight AFTER UPDATE OF created ON Highlight WHEN New.created = 1 AND Old.created = 0 BEGIN UPDATE Stat
SET highlight_created_total = highlight_created_total + 1,
points = points + New.points,
highlight_point_total = highlight_point_total + New.points
WHERE idUser = OLD.idUser; END
```

### `cs_name_add` (on `CustomSound`)
CustomSound insert fills idName from User.

```sql
CREATE TRIGGER cs_name_add AFTER INSERT ON CustomSound BEGIN UPDATE CustomSound SET idName = (SELECT name FROM User WHERE User.idUser = CustomSound.idUser); END
```

### `deleted_highlight` (on `Highlight`)
Reverses the payout when a created=1 row is deleted (subtracts points, decrements highlight_created_total). Deleting a created=0 row touches nothing.

```sql
CREATE TRIGGER deleted_highlight AFTER DELETE ON Highlight WHEN Old.created = 1 BEGIN Update Stat
SET highlight_point_total = highlight_point_total - Old.points,
points = points - Old.points,
highlight_created_total = highlight_created_total - 1
WHERE idUser = Old.idUser; END
```

### `highlight_name` (on `Highlight`)
Highlight insert fills name from User.

```sql
CREATE TRIGGER highlight_name AFTER INSERT ON Highlight BEGIN UPDATE Highlight SET name = (SELECT name FROM User WHERE User.idUser = Highlight.idUser); END
```

### `info_create_name` (on `Info`)
Info insert fills name from User.

```sql
CREATE TRIGGER info_create_name AFTER INSERT ON Info BEGIN UPDATE Info SET name = (SELECT name FROM User WHERE User.idUser = Info.idUser); END
```

### `ivy_name_add` (on `Ivy`)
Ivy insert fills name from User.

```sql
CREATE TRIGGER ivy_name_add AFTER INSERT ON Ivy BEGIN UPDATE Ivy SET name = (SELECT name FROM User WHERE User.idUser = Ivy.idUser); END
```

### `new_user` (on `User`)
User insert seeds Stat (points=1, views=1, speech=1) and Info (lastseen=today).

```sql
CREATE TRIGGER new_user AFTER INSERT ON User BEGIN INSERT INTO Stat (idUser, points, views, speech) VALUES (NEW.idUser, 1, 1, 1); INSERT INTO Info (idUser, lastseen) VALUES (NEW.idUser, date('now', 'localtime')); END
```

### `qotd_create_name` (on `Qotd`)
Qotd insert fills name from User.

```sql
CREATE TRIGGER qotd_create_name AFTER INSERT ON Qotd BEGIN UPDATE Qotd SET name = (SELECT name FROM User WHERE User.idUser = Qotd.idUser); END
```

### `quote_add` (on `Quote`)
Quote insert increments Stat.quote_total.

```sql
CREATE TRIGGER quote_add AFTER INSERT ON Quote BEGIN UPDATE Stat SET quote_total = quote_total + 1 WHERE idUser = NEW.idUser; END
```

### `roll_create_name` (on `Roll`)
Roll insert fills name from User.

```sql
CREATE TRIGGER roll_create_name AFTER INSERT ON Roll BEGIN UPDATE Roll SET name = (SELECT name FROM User WHERE User.idUser = Roll.idUser); END
```

### `update_win` (on `Roll`)
Roll victory update increments Stat.roll_win. NOTE: no WHEN guard — same double-count hazard class as created_highlight had; any UPDATE OF victory (even 1->1) increments. Recommend the same Old/new guard if re-flips happen.

```sql
CREATE TRIGGER update_win AFTER UPDATE OF victory ON Roll WHEN New.victory = 1 AND Old.victory = 0 BEGIN UPDATE Stat SET roll_win = roll_win + 1 WHERE idUser = NEW.idUser; END
```

## Indexes (explicit)

(`sqlite_autoindex_*` entries are omitted — they are implied by PRIMARY KEY / UNIQUE constraints.)

- `insert_start` on `Seen`
  ```sql
  CREATE UNIQUE INDEX insert_start ON Seen (idStream, idUser)
  ```

## Views

### `ga_current`
Giveaway tickets with user names.

```sql
CREATE VIEW ga_current AS SELECT
User.name,
Giveaway.idUser,
Giveaway.ticket
FROM Giveaway
JOIN User using (idUser)
```

### `hl_left`
The pending-highlight review queue: all Highlight rows with created = 0.

```sql
CREATE VIEW hl_left AS SELECT *
FROM Highlight
WHERE created = 0
```

### `prend`
Open PotatoRun rounds with wager and win/fail percent bands.

```sql
CREATE VIEW prend AS SELECT
idRun,
PotatoRun.idUser,
User.name,
wager,
PotatoRun.idPR,
PR_Rand.percent_low,
PR_Rand.percent_high,
PR_Rand.win_msg,
PR_Rand.fail_msg
FROM PotatoRun
JOIN User ON ( User.idUser = PotatoRun.idUser )
JOIN PR_Rand ON ( PR_Rand.idPR = PotatoRun.idPR )
```

### `roll_current`
The active roll (current = 1) with user names.

```sql
CREATE VIEW roll_current AS SELECT
User.name,
Roll.roll,
Roll.current,
Roll.option,
Roll.date
FROM Roll
JOIN User using (idUser)
WHERE current = 1
```

### `roll_current_dick`
Active roll joined to dicksword ids.

```sql
CREATE VIEW roll_current_dick AS SELECT
User.name,
Roll.roll,
Roll.current,
Roll.option,
Roll.date,
Dicksword_assoc.dicksword_id
FROM Roll
JOIN User using (idUser)
JOIN Dicksword_assoc using (twitch_user_id)
WHERE current = 1
```

### `row_ivy`
Ivy quotes with row numbers (random-pick-by-number).

```sql
CREATE VIEW row_ivy AS SELECT 
(SELECT count(*) FROM Ivy b WHERE a.idIvy >= b.idIvy) AS rowNUM,
(SELECT count(*) FROM Ivy) AS count,
*
FROM Ivy a
JOIN User using (idUser)
```

### `row_quote`
Eligible quotes (quoterand >= 1) with row numbers.

```sql
CREATE VIEW row_quote AS SELECT 
(SELECT count(*) FROM Quote b WHERE a.idQuote >= b.idQuote AND a.quoterand >= 1) AS rowNUM,
(SELECT count(*) FROM Quote WHERE quoterand >= 1) AS count,
*
FROM Quote a
JOIN User using (idUser)
WHERE quoterand >= 1
```

### `row_quote2`
All quotes with row numbers.

```sql
CREATE VIEW row_quote2 AS SELECT 
(SELECT count(*) FROM Quote b WHERE a.idQuote >= b.idQuote) AS rowNUM,
(SELECT count(*) FROM Quote) AS count,
*
FROM Quote a
JOIN User using (idUser)
```

### `seen_test`
Hardcoded 2019-08-30 lastseen filter — looks like a leftover/debug view.

```sql
CREATE VIEW seen_test AS SELECT * FROM Info WHERE lastseen >= '2019-08-30 19:53:11'
```

### `top_hours`
Top 10 viewers by views, excluding the streamer.

```sql
CREATE VIEW top_hours AS SELECT
User.name,
Stat.views
FROM User
JOIN Stat using (idUser)
WHERE User.name <> 'dreadfullydespized'
ORDER BY views DESC LIMIT 10
```

### `twds_info`
Profile variant with dicksword id and raw view counts.

```sql
CREATE VIEW twds_info AS SELECT 
User.name,
Stat.points,
Stat.speech,
Stat.donations,
Stat.views,
Stat.roll_win,
Stat.quote_total,
Stat.highlight_point_total,
Stat.highlight_created_total,
Info.birthday,
Info.rank,
Rank.title,
Rank.max_hour,
Rank.next_title,
Info.is_regular,
Info.is_moderator,
Dicksword_assoc.dicksword_id,
User.idUser,
Stat.giveaway_win,
Rank.min_hour
FROM User
JOIN Stat using (idUser)
JOIN Info using (idUser)
JOIN Rank ON (Info.rank = Rank.idRank)
JOIN Dicksword_assoc using (twitch_user_id)
```

### `user_holiday`
Holiday claims with user names.

```sql
CREATE VIEW user_holiday AS SELECT
User.name,
UserHoliday.idHoliday,
User.idUser,
UserHoliday.year
FROM User
JOIN UserHoliday using (idUser)
```

### `user_info`
Main user profile: points, hours (views/60), rank resolved from hours, mod/regular flags.

```sql
CREATE VIEW user_info AS SELECT 
User.name,
User.twitch_user_id,
Stat.points,
Stat.speech,
Stat.donations,
ROUND(Stat.views / 60,2) AS views,
Stat.roll_win,
Stat.quote_total,
Stat.highlight_point_total,
Stat.highlight_created_total,
Info.birthday,
Info.rank,
Rank.idRank,
Rank.min_hour,
Rank.max_hour,
Rank.next_title,
Rank.title,
Info.is_regular,
Info.is_moderator,
Stat.giveaway_win
FROM User
JOIN Stat using (idUser)
JOIN Info using (idUser)
JOIN Rank ON (Rank.max_hour > ROUND(Stat.views / 60,2) AND Rank.min_hour <= ROUND(Stat.views / 60,2))
```
