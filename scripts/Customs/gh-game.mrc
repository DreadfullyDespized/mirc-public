alias goblin_horde_init {
  ; Use existing %ghgameDB global variable for database
  var %db = %ghgameDB
  var %db_open = $sqlite_open(%db)
  if (!%db_open) {
    echo %ec_error -a Error opening database %ghgameDB $+ : $sqlite_errstr
    return
  }
  var %dbh = %db_open
  var %debug = $iif($1 == test, 1, 0)
  if (%debug) echo %ec_debug -a Debug mode enabled
  
  ; Create tables with helper alias, exit on failure
  if (!$exec_sql(%dbh, CREATE TABLE IF NOT EXISTS player (player_id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, level INTEGER DEFAULT 1, experience INTEGER DEFAULT 0, health INTEGER DEFAULT 100, gold INTEGER DEFAULT 0), player, %debug)) return
  if (!$exec_sql(%dbh, CREATE TABLE IF NOT EXISTS adventure (adventure_id INTEGER PRIMARY KEY AUTOINCREMENT, player_id INTEGER, location TEXT, progress INTEGER DEFAULT 0, status TEXT DEFAULT 'active', FOREIGN KEY (player_id) REFERENCES player(player_id)), adventure, %debug)) return
  if (!$exec_sql(%dbh, CREATE TABLE IF NOT EXISTS gear (gear_id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, slot TEXT, damage INTEGER DEFAULT 0, defense INTEGER DEFAULT 0, str INTEGER DEFAULT 0, int INTEGER DEFAULT 0, dex INTEGER DEFAULT 0, item_level INTEGER DEFAULT 0, level_req INTEGER DEFAULT 0, extra1 INTEGER DEFAULT 0, extra2 INTEGER DEFAULT 0), gear, %debug)) return
  if (!$exec_sql(%dbh, CREATE TABLE IF NOT EXISTS mobs (mob_id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, level INTEGER, health INTEGER, damage INTEGER, loot_chance REAL), mobs, %debug)) return
  if (!$exec_sql(%dbh, CREATE TABLE IF NOT EXISTS combat (combat_id INTEGER PRIMARY KEY AUTOINCREMENT, player_id INTEGER, mob_id INTEGER, adventure_id INTEGER, player_health INTEGER, mob_health INTEGER, timestamp INTEGER, FOREIGN KEY (player_id) REFERENCES player(player_id), FOREIGN KEY (mob_id) REFERENCES mobs(mob_id), FOREIGN KEY (adventure_id) REFERENCES adventure(adventure_id)), combat, %debug)) return
  if (%debug) echo %ec_debug -a All tables created, starting validation
  
  ; Validate all tables exist
  var %sql = SELECT name FROM sqlite_master WHERE type='table' AND name IN ('player', 'adventure', 'gear', 'mobs', 'combat')
  var %query = $sqlite_query(%dbh, %sql)
  if (%debug) echo %ec_debug -a Starting table validation query: %sql
  if (%query) {
    if (%debug) echo %ec_debug -a Query executed, fetching results
    var %h = goblin_horde_temp
    hmake %h 10
    hfree -w %h
    var %table_count = 0
    while ($sqlite_fetch_row(%query, %h, $SQLITE_ASSOC)) {
      inc %table_count
    }
    if (%table_count == 5) {
      echo %ec_succ -a Successfully verified all 5 database tables exist
    }
    else {
      echo %ec_error -a Failed to verify all tables - only %table_count found
      if (%debug) {
        var %sql = SELECT name FROM sqlite_master WHERE type='table' AND name IN ('player', 'adventure', 'gear', 'mobs', 'combat')
        var %q = $sqlite_query(%dbh, %sql)
        if (%q) {
          var %missing = player adventure gear mobs combat
          while ($sqlite_fetch_row(%q, %h, $SQLITE_ASSOC)) {
            var %name = $hget(%h, name)
            var %missing = $remtok(%missing, %name, 1, 32)
          }
          echo %ec_debug -a Missing tables: %missing
          $sqlite_free(%q)
        }
      }
    }
    hfree %h
    if (%debug) echo %ec_debug -a Before freeing query handle
    noop $sqlite_free(%query)
    if (%debug) echo %ec_debug -a Query handle freed
  }
  else {
    echo %ec_error -a Error checking table existence: $sqlite_errstr
  }
  
  ; Load gear data and validate
  if ($isfile(%ghgeardata)) {
    if (%debug) echo %ec_debug -a Proceeding to load gear data
    load_gear_data %dbh $1
  }
  else if (%debug) {
    echo %ec_debug -a No gear data file found at %ghgeardata
  }
  
  echo %ec_succ -a Goblin Horde Adventure database initialized!
  $sqlite_close(%dbh)
}

alias load_gear_data {
  var %dbh = $1
  var %file = %ghgeardata
  var %debug = $iif($2 == test, 1, 0)
  
  ; Single pass: load gear data into hash table with numeric indices
  var %h_gear = goblin_horde_gear
  hfree -w %h_gear
  hmake %h_gear 100
  var %expected_count = 0
  var %i = 1
  while ($read(%file, n, %i) != $null) {
    var %line = $v1
    if (%debug) echo %ec_debug -a Read line %i $+ : %line
    if (%line) {
      hadd %h_gear %i %line
      inc %expected_count
    }
    inc %i
  }
  if (%debug) echo %ec_debug -a Total gear items loaded into hash table: $hget(%h_gear, 0).item
  
  ; Load existing gear names into hash table for O(1) lookup
  var %h_existing = goblin_horde_existing
  hfree -w %h_existing
  hmake %h_existing 100
  var %h_temp = goblin_horde_temp
  hmake %h_temp 100
  var %sql = SELECT name FROM gear
  var %query = $sqlite_query(%dbh, %sql)
  if (%debug) echo %ec_debug -a Before fetching gear names, hash table exists: $hget(%h_temp, 0).item
  if (%query) {
    while ($sqlite_fetch_row(%query, %h_temp, $SQLITE_ASSOC)) {
      hadd %h_existing $hget(%h_temp, name) 1
    }
    if (%debug) echo %ec_debug -a After fetching gear names, hash table items: $hget(%h_temp, 0).item
    if (%debug) echo %ec_debug -a Before freeing gear query handle
    hfree %h_temp
    noop $sqlite_free(%query)
    if (%debug) echo %ec_debug -a Gear query handle freed
  }
  else if (%debug) {
    echo %ec_debug -a Could not load existing gear for duplicate check: $sqlite_errstr
  }
  
  ; Insert new gear items in a transaction
  var %success = 1
  if ($hget(%h_gear, 0).item) {
    $exec_sql(%dbh, BEGIN TRANSACTION, transaction_start, %debug)
    var %i = 1
    while (%i <= $hget(%h_gear, 0).item) {
      var %item = $hget(%h_gear, %i)
      if (%debug) echo %ec_debug -a Retrieved item %i from hash table: %item
      if (%item) {
        if (%debug) echo %ec_debug -a Processing gear item line: %item
        var %name = $gettok(%item, 1, 44)
        if (!$hget(%h_existing, %name)) {
          var %slot = $gettok(%item, 2, 44)
          var %damage = $gettok(%item, 3, 44)
          var %defense = $gettok(%item, 4, 44)
          var %str = $gettok(%item, 5, 44)
          var %int = $gettok(%item, 6, 44)
          var %dex = $gettok(%item, 7, 44)
          var %item_level = $gettok(%item, 8, 44)
          var %level_req = $gettok(%item, 9, 44)
          var %extra1 = $gettok(%item, 10, 44)
          var %extra2 = $gettok(%item, 11, 44)
          
          set %sql INSERT INTO gear (name, slot, damage, defense, str, int, dex, item_level, level_req, extra1, extra2 $&
            ) VALUES ( $&
            $qt(%name) , $qt(%slot) , %damage , %defense , %str , %int , %dex , %item_level , %level_req , %extra1 , %extra2 )
          if (%debug) echo %ec_debug -a SQL Query: %sql
          if (!$sqlite_exec(%dbh, %sql)) {
            echo %ec_error -a Error inserting gear item %name $+ : $sqlite_errstr
            var %success = 0
            $exec_sql(%dbh, ROLLBACK, transaction_rollback, %debug)
            goto cleanup
          }
        }
        else if (%debug) {
          echo %ec_debug -a Skipping duplicate gear item: $qt(%name)
        }
      }
      inc %i
    }
    if (%success) $exec_sql(%dbh, COMMIT, transaction_commit, %debug)
  }
  
  ; Validate gear count
  var %sql = SELECT COUNT(*) FROM gear
  var %query = $sqlite_query(%dbh, %sql)
  if (%query) {
    var %h = goblin_horde_count
    hfree -w %h
    if ($sqlite_fetch_row(%query, %h, $SQLITE_NUM)) {
      var %gear_count = $hget(%h, 1)
      if (%success && %gear_count >= %expected_count) {
        echo %ec_succ -a Successfully verified all %expected_count gear items (total in DB: %gear_count $+ )
        if (%debug && %gear_count > %expected_count) {
          echo %ec_debug -a Warning: More gear items in DB (%gear_count) than expected (%expected_count)
        }
      }
      else {
        echo %ec_error -a Failed to verify all gear items - %gear_count in database, expected at least %expected_count
      }
    }
    else {
      echo %ec_error -a Error fetching gear count: $sqlite_errstr
    }
    hfree %h
    $sqlite_free(%query)
  }
  else {
    echo %ec_error -a Error checking gear count: $sqlite_errstr
  }
  
  :cleanup
  hfree %h_gear
  hfree %h_existing
  echo %ec_succ -a Gear data loaded from %ghgeardata
}

alias exec_sql {
  var %dbh = $1, %sql = $2, %context = $3, %debug = $4
  var %result = $sqlite_exec(%dbh, %sql)
  if (!%result) {
    echo %ec_error -a Error executing %context SQL: %sql - Error: $sqlite_errstr
    return 0
  }
  return 1
}