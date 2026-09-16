; These are mainly for examples.  Since they don't work anymore with the encrypted DB

;Format: /ankhbotsqliterank nickname
;This will return the username/nickname's current rank from Ankhbot db
alias ankhbotsqliterank {
  var %db = $sqlite_open(%sqlitecurrencyDB)
  if (%db) {
    ; echo -a Database opened
    var %donationname = $1
    var %safe_donationname = $replace($sqlite_escape_string(%donationname),*,%,?,_)
    var %user = $sqlite_qt(%safe_donationname)
    var %sql = SELECT * FROM currencyuser where name = %user
    var %request = $sqlite_query(%db, %sql)
    if (%request) {
      ; echo -a Request opened
      var %frank = $sqlite_result(%request, rank)
      ; echo -a %frank
      sqlite_free %request
      sqlite_close %db
      return %frank
    }
  }
}

;Format: /ankhbotsqlitepoints nickname
;This will return the username/nickname's current points from Ankhbot db
alias ankhbotsqlitepoints {
  var %db = $sqlite_open(%sqlitecurrencyDB)
  if (%db) {
    var %donationname = $1
    var %safe_donationname = $replace($sqlite_escape_string(%donationname),*,%,?,_)
    var %user = $sqlite_qt(%safe_donationname)
    var %sql = SELECT * FROM currencyuser where name = %user
    var %request = $sqlite_query(%db, %sql)
    if (%request) {
      echo -a Fetch Points: $sqlite_result(%request, points)
      var %fpoints = $sqlite_result(%request, points)
      sqlite_free %request
      sqlite_close %db
      return %fpoints
    }
  }
}

;Format: /ankhbotsqlitecheck nickname
;READ ONLY USAGE NOT FOR REMOTE COMMANDS
;This will echo the username/rank/points/hours of specified user.
alias ankhbotsqlitecheck {
  var %db = $sqlite_open(%sqlitecurrencyDB)
  if (%db) {
    var %donationname = $1
    var %safe_donationname = $replace($sqlite_escape_string(%donationname),*,%,?,_)
    var %user = $sqlite_qt(%safe_donationname)
    var %sql = SELECT * FROM currencyuser where name = %user
    var %request = $sqlite_query(%db, %sql)
    if (%request) {
      var %fname = $sqlite_result(%request, name)
      var %frank = $sqlite_result(%request, rank)
      var %fpoints = $sqlite_result(%request, points)
      var %fhours = $sqlite_result(%request, hours)
      var %fminuteswatched = $sqlite_result(%request, minuteswatched)
      echo -a %fname - %frank - %fpoints - %fhours - %fminuteswatched
      sqlite_free %request
      sqlite_close %db
    }
  }
}

;Format: /ankhbotsqlitehours nickname
;This will return the total amount of calculated hours the viewer has been in the stream
alias ankhbotsqlitehours {
  var %db = $sqlite_open(%sqlitecurrencyDB)
  if (%db) {
    var %donationname = $1
    var %safe_donationname = $replace($sqlite_escape_string(%donationname),*,%,?,_)
    var %user = $sqlite_qt(%safe_donationname)
    var %sql = SELECT * FROM currencyuser where name = %user
    var %request = $sqlite_query(%db, %sql)
    if (%request) {
      var %fname = $sqlite_result(%request, name)
      var %frank = $sqlite_result(%request, rank)
      var %fpoints = $sqlite_result(%request, points)
      var %fminuteswatched = $sqlite_result(%request, minuteswatched)
      var %totaltime = $round($calc(%fminuteswatched / 60),2)
      sqlite_free %request
      sqlite_close %db
      sqliteuserchange $1 views %userhours
      return %totaltime
    }
  }
}

;Format: /ankhbotsqlitequery nickname
;Will return multiple users if found with name and points
alias ankhbotsqlitequery {
  var %db = $sqlite_open(%sqlitecurrencyDB)
  if (%db) {
    ; echo -a Database opened successfully
    var %donationname = $1
    ; Replaces wildcard * with % and escape nick
    var %safe_donationname = $replace($sqlite_escape_string(%donationname),*,%,?,_)
    ; Takes normal variable and adds sqlite quotes to it
    var %user = $sqlite_qt(%safe_donationname)


    ; Construct query and execute it
    var %sql = SELECT * FROM currencyuser where name = %user
    var %request = $sqlite_query(%db, %sql)
    if (%request) {

      ; For each row display the nick and greet
      while ($sqlite_fetch_row(%request, row)) {
        echo -a $hget(row, name) - $hget(row, points)
      }

      ; free's the result
      sqlite_free %request
    }
    else {
      echo 4 -a Error executing query: %sqlite_errstr
    }
  }
  else {
    echo 4 -a Error opening database: %sqlite_errstr
  }
}

;Format: /ankhbotsqliteinject nickname +/- points.
;This will add or subtract points from the username/nickname in the Ankhbot DB.
alias ankhbotsqliteinject {
  var %db = $sqlite_open(%sqlitecurrencyDB)
  if (%db) {
    ; echo -a Database opened successfully
    var %donationname = $1
    var %donationtype = $2
    var %donationpoints = $3
    var %safe_donationname = $replace($sqlite_escape_string(%donationname),*,%,?,_)
    var %user = $sqlite_qt(%safe_donationname), %points = $sqlite_qt(%donationpoints)
    var %sql = SELECT * FROM currencyuser where name = %user
    sqlite_exec %db update currencyuser set points = points %donationtype %points where name = %user
    ; This line is to see if 0 or more changes were made in green color.
    ; echo 3 -a $sqlite_changes(%db)
    sqlite_close %db
  }
}
