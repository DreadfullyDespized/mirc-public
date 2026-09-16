; Format: /oncheck
; Will check to see if the stream is running or not and toggle points
alias oncheck {
  var %check = $jsont(dreadfullydespized)
  if ($group(#points) == on) {
    ; echo %ec_error -a Group is currently on
    if (%check == OFFLINE) {
      echo %ec_debug -a Points turned off
      /disable #points
      /timer*.speech off
      /timer*.points off
    }
  }
  if ($group(#points) == off) {
    ; echo %ec_error -a Group is currently off
    if (%check == ONLINE) {
      echo %ec_debug -a Points turned on
      /enable #points
    }
  }
}

; Format: /sqlupdateuser username
; Compares to see if the current username is the same in the DB.
; If not then it will rename it accordingly
alias sqlupdateuser {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlupdateuser db: %sqlite_errstr
  }
  var %uname = $1
  var %name = $qt($sqlite_escape_string(%uname))
  var %uid = $jsongetuserid(%uname)
  var %sql SELECT name FROM User WHERE twitch_user_id = %uid
  var %request = $sqlite_query(%db,%sql)
  if (!%request) {
    echo %ec_error -a Error executing sqlupdateuser query: %sqlite_errstr
  }
  var %oldname = $sqlite_result(%request,name)
  if (%uname === %oldname) {
    echo %ec_succ -a names are the same
  }
  else {
    echo %ec_succ -a names are different
    var %sql = UPDATE User SET name = %name WHERE twitch_user_id = %uid
    echo %ec_succ -a %sql
    if ($sqlite_exec(%db,%sql)) {
      ; echo %ec_succ -a Number of rows affected sqlupdateuser: $sqlite_changes(%db)
      echo %ec_succ -a %oldname changed to %uname
    }
    else {
      echo %ec_error -a Error executing sqlupdateuser update: %sqlite_errstr
    }
  }
  sqlite_free %request
  sqlite_close %db
}

; Format: /sqluadd username
; Should add user to the users sqlite db
alias sqluadd {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqluadd db: %sqlite_errstr
  }
  var %name = $qt($sqlite_escape_string($1))
  var %twitch_user_id = $jsongetuserid($1)
  if (%twitch_user_id) {
    set %sql INSERT INTO User ( name,twitch_user_id ) VALUES ( %name , %twitch_user_id )
    if ($sqlite_exec(%db,%sql)) {
      echo %ec_succ -a Query executed succesfully sqluadd: %name
    }
    else {
      echo %ec_error -a Error executing sqluadd insert: %sqlite_errstr
      $sqlupdateuser($1)
    }
  }
  else {
    echo %ec_error -a Error NoID sqluadd insert: $1
  }
  sqlite_close %db
}

; Format: /sqluname username
; This will check to see if user is in the User DB and then report back their info.
; This is actually going against the View user_info
alias sqluname {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqluname db: %sqlite_errstr
  }
  ;#1
  var %name = $qt($sqlite_escape_string($1))
  var %sql = SELECT * FROM user_info WHERE name = %name
  var %request = $sqlite_query(%db,%sql)
  if (!%request) {
    echo %ec_error -a Error executing sqluname query: %sqlite_errstr
  }
  else {
    if ($sqlite_num_rows(%request) isnum 1) {
        var %ud = %request
        ; echo %ec_succ -a %ud
        ; Returns:
        ; name|points|speech|donations|views|roll_win|quote_total|highlight_point_total|highlight_created_total|birthday|rank|is_regular|is_moderator|giveaway_win
    }
    else {
      echo %ec_error -a Error at sqluname Name: $1
      echo %ec_error -a Error at sqluname check: $sqlite_num_rows(%request) %request
      sqlite_free %request
      sqluadd $1
    }
  }
  ; sqlite_free %request
  sqlite_close %db
  return %ud
}

; Format: /sqltophours (number of top)
; This alias is used to pull out the top 5 or 10
; Set limit on the chat command
; Displays username and total hours
alias sqltophours {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqltophours db: %sqlite_errstr
  }
  var %top = $sqlite_escape_string($1)
  var %sql = SELECT * FROM top_hours LIMIT %top
  var %request = $sqlite_query(%db,%sql)
  if (!%request) {
    echo %ec_error -a Error executing sqltophours query: %sqlite_errstr
  }
  var %x = 1
  while ($sqlite_fetch_row(%request,row)) {
    var %topname = $hget(row,name)
    var %topviews = $round($calc($hget(row,views) / 60),2)
    var %tableviews = $+(%tableviews,$chr(32),$chr(32),-,$chr(32),$chr(35),%x,$chr(32),%topname,$chr(61),$chr(40),%topviews,$chr(41))
    INC %x
  }
  ; echo %ec_succ -a Top Hours: %tableviews
  sqlite_free %request
  sqlite_close %db
  return %tableviews
}

; Format: /sqltimeadd nickname
; This alias adds timer points to the users if they meet the criteria
; This was previously known as sqliteuserpoints
alias sqltimeadd {
  var %indb = $sqluname($1)
  if (%indb != Failed) {
    var %reg = $sqlite_result(%indb,is_regular)
    var %mod = $sqlite_result(%indb,is_moderator)
    var %pv = 5
    ; Fixed 2026-09-16: was testing %regular/%moderator (never set), so the
    ; regular/mod +1 bonuses never applied. Test %reg/%mod as assigned above.
    if (%reg == 1) {
      var %pv = $calc(%pv + 1)
    }
    if (%mod == 1) {
      var %pv = $calc(%pv + 1)
    }
    ; Will need to look into a way to evaluate the current status of sub.
    ; Future idea to add subscription into this.
    ; Tier 1 = +1 potato
    ; Tier 2 = +2 potato
    ; Tier 3 = +3 potato
    ; Nick,+-/*,points,views,donations
    $sqlumodpvd($1,+,%pv,5,0)
  }
  else {
    ; if user not in the database then add user into the database.
    echo %ec_error -a $1 is not in the db
    $sqlupdateuser($1)
    $sqluadd($1)
  }
  sqlite_free %request
}

; Format: /sqlumod username field value test
; Format: /sqliteuserchange username field value
; Handles the following mods that were removed: sqliteuserrankmod, sqliteusermodmod, sqliteuserregmod
; Should update the existing record with correct information to the users sqlite db
alias sqlumod {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlumod db: %sqlite_errstr
  }
  var %name = $qt($sqlite_escape_string($1))
  var %field = $sqlite_escape_string($2)
  var %value = $sqlite_escape_string($3)
  var %sql = UPDATE Info SET %field = %value WHERE idUser = ( SELECT idUser FROM User WHERE name = %name ) $&
  AND %field != %value
  if ($sqlite_exec(%db,%sql)) {
    if ($4) {
      echo %ec_debug -a SQL: %sql
      echo %ec_succ -a Number of rows affected: $sqlite_changes(%db)
    }
  }
  else {
    echo %ec_error -a Error executing sqlumod update : %sqlite_errstr
  }
  sqlite_close %db
  return
}

; Format: /sqlstreamseen
; Will automatically add users to the currently running stream.
; This is handled on it's own so it doesn't need any input, it uses the lastseen change.
; Requires user's stats to change in some way shape or form for their lastseen to be updated.
alias sqlstreamseen {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
      echo %ec_error -a Error at sqlstreamseen db: %sqlite_errstr
  }
  var %sql = SELECT start_date,start_time,end_date,end_time FROM Stream WHERE idStream = %streamid
  var %request = $sqlite_query(%db,%sql) 
  if (!%request) {
    echo %ec_error -a Error executing sqlstreamseen query: %sqlite_errstr
  }
  elseif ($sqlite_result(%request,start_date) == $null) {
    echo %ec_error -a Error executing sqlstreamseen check: %sqlite_errstr
  }
  else {
    var %start_date = $sqlite_result(%request,start_date)
    var %start_time = $sqlite_result(%request,start_time)
    var %end_date = $sqlite_result(%request,end_date)
    var %end_time = $sqlite_result(%request,end_time)
    if (!%end_date || !%end_time) {
      var %sql = SELECT * FROM Info WHERE lastseen >= $qt($+(%start_date,$chr(32),%start_time))
      var %request = $sqlite_query(%db,%sql)
      if (!%request) {
        if (%sqlite_errstr != no more rows available) {
          echo %ec_error -a Error executing sqlstreamseen query2: %sqlite_errstr
        }
      }
      elseif ($sqlite_result(%request,idUser) == $null) {
        ; echo %ec_error -a Error executing sqlstreamseen check2: %sqlite_errstr
      }
      while ($sqlite_fetch_row(%request, row, $SQLITE_ASSOC)) {
        var %idUser = $hget(row,idUser)
        var %sql2 = SELECT idUser FROM Seen WHERE idUser = %idUser AND idStream = %streamid
        ; echo %ec_succ -a %sql2
        var %request2 = $sqlite_query(%db,%sql2)
        if (!%request2) {
          echo %ec_error -a Error executing sqlstreamseen query3: %sqlite_errstr
        }
        if ($sqlite_result(%request2,idUser) == %idUser) {
          ; echo %ec_succ -a Users match: $sqlite_result(%request2,idUser) %idUser and will not be inserted
        }
        else {
          set %sql INSERT OR IGNORE INTO Seen ( idStream,idUser ) VALUES ( %streamid , %idUser )
          ; echo %ec_succ -a %sql
          if ($sqlite_exec(%db,%sql)) {
            ; echo %ec_succ -a Last Inserted sqlstreamseen RowID: $sqlite_last_insert_rowid(%db)
            echo %ec_succ -a Inserted idUser: %iduser to the stream
          }
        }
      }
    }
    else {
      ; echo %ec_error -a %end_date - %end_time - STREAM ENDED
    }
  }
  sqlite_free %request
  sqlite_free %request2
  sqlite_close %db
}

; Format: /sqlstreamcheck test
; Checks the stream id to see what the previous stream id was playing game wise
alias sqlstreamcheck {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlstreamcheck db: %sqlite_errstr
  }
  var %old_stream_id = %streamid - 1
  if ($1) {
    echo %ec_succ -a OldStreamID: %old_stream_id
    echo %ec_succ -a CurStreamID: %streamid
  }
  var %sql2 = SELECT * FROM STREAM WHERE idStream = %old_stream_id $&
  AND end_date IS NOT NULL
  var %request = $sqlite_query(%db,%sql2)
  if (!%request) {
    echo %ec_error -a Error executing sqlstreamcheck query: %sqlite_errstr
  }
  var %gameText = $+(%dataSet,gameName.txt)
  if ($fopen(gameFile)) {
    echo %ec_error -a gameFile was open and closed
    fclose gameFile
  }
  fopen -o gameFile %gameText
  if ($sqlite_result(%request,idStream)) {
    var %addText = It appears that we will be continuing with
    var %addText2 = $+(Since My Creator played it last on,$chr(32),$sqlite_result(%request,start_date))
    fwrite gameFile $+(%addText,$chr(44),$chr(32),%streamgame,$chr(46),$chr(32),%addText2,$chr(46))
    fclose gameFile
  } 
  else {
    fopen gameFile %gameText
    fwrite gameFile %streamgame
    fclose gameFile
  }
  sqlite_free %request
  sqlite_close %db
  return
}

; Format: /sqlstreamcreate test
; Should add into the Stream table when the stream was started/created.
; Added abilty to generate gameName.txt file for IVY reading on intro.
alias sqlstreamcreate {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlstreamcreate db: %sqlite_errstr
  }
  var %start_date = $qt($asctime(yyyy-mm-dd))
  var %start_time = $qt($time)
  var %game = $qt($sqlite_escape_string(%streamgame))
  var %title = $qt($sqlite_escape_string(%title))
  var %song = $qt($sqlite_escape_string($spotify_format_song))
  set %sql INSERT INTO Stream ( start_date,start_time,start_song,game,title $&
  ) VALUES ( $&
  %start_date , %start_time , %song , %game , %title )
  echo %ec_succ -a %sql
  if ($sqlite_exec(%db,%sql)) {
    if ($2) {
      echo %ec_succ -a Query executed successfully %game
    }
    var %sql = SELECT idStream FROM STREAM WHERE start_date = %start_date $&
    AND end_date IS NULL
    var %request = $sqlite_query(%db,%sql)
    if (!%request) {
      echo %ec_error -a Error executing sqlstreamcreate query: %sqlite_errstr
    }
    ; Set permanently sets the variable
    set %streamid $sqlite_result(%request,idStream)
    echo %ec_succ -a Stream id: %streamid

    var %old_stream_id = %streamid - 1
    var %sql2 = SELECT * FROM STREAM WHERE idStream = %old_stream_id $&
    AND end_date IS NOT NULL
    var %request2 = $sqlite_query(%db,%sql2)
    if (!%request2) {
      echo %ec_error -a Error executing sqlstreamcreate query2: %sqlite_errstr
    }
    var %gameText = $+(%dataSet,gameName.txt)
    fopen -o gameFile %gameText
    if ($sqlite_result(%request2,idStream)) {
      var %addText = It appears that we will be continuing with
      var %addText2 = $+(Since My Creator played it last on,$chr(32),$sqlite_result(%request,start_date))
      fwrite gameFile $+(%addText,$chr(44),$chr(32),%streamgame,$chr(46),$chr(32),%addText2,$chr(46))
      fclose gameFile
    }
    else {
      fopen gameFile %gameText
      fwrite gameFile %streamgame
      fclose gameFile
    }
  }
  else {
    echo %ec_error -a Error executing sqlstreamcreate insert: %sqlite_errstr
  }
  sqlite_free %request
  sqlite_free %request2
  sqlite_close %db
}

; Format: /sqlstreamend
; Should update the same stream record that it is now ended.
alias sqlstreamend {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlstreamend db: %sqlite_errstr
  }
  var %sql = SELECT end_date,end_time FROM Stream WHERE idStream = %streamid
  var %request = $sqlite_query(%db,%sql)
  if (!%request) {
    echo %ec_error -a Error executing sqlstreamend query: %sqlite_errstr
  }
  elseif ($sqlite_result(%request,end_date) == $null) {
    var %end_date = $qt($asctime(yyyy-mm-dd))
    var %end_time = $qt($time)
    var %sql =  UPDATE Stream SET end_date = %end_date , $&
    end_time = %end_time $&
    WHERE idStream = %streamid
    echo %ec_succ -a %sql
    if ($sqlite_exec(%db,%sql)) {
      echo %ec_succ -a Number of rows affected: $sqlite_changes(%db)
    }
    else {
      echo %ec_error -a Error executing sqlstreamend update: %sqlite_errstr
    }
  }
  else {
    echo %ec_succ -a Stream end didn't update due to existing record
  }
  sqlite_close %db
}

; Format: /sqljsonname
; Runs a while statement through all of the twitch_user_id's and then updates the name field to match
alias sqljsonname {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqljsonname db: %sqlite_errstr
  }
  var %sql = SELECT twitch_user_id,name FROM User WHERE twitch_user_id IS NOT NULL and name IS NULL
  var %request = $sqlite_query(%db,%sql)
  if (!%request) {
    echo %ec_error -a Error executing sqljsonname query: %sqlite_errstr
  }
  var %x = 1
  while ($sqlite_fetch_row(%request,row)) {
    var %twitch_user_id = $hget(row,twitch_user_id)
    echo %ec_succ -a %twitch_user_id - %x
    var %whilename = $jsonname(%twitch_user_id)
    var %queryname = $qt(%whilename)
    var %whilesql = UPDATE User SET name = %queryname WHERE twitch_user_id = %twitch_user_id
    if ($sqlite_exec(%db,%whilesql)) {
      ; echo %ec_succ -a Number of rows affected: $sqlite_changes(%db)
    }
    else {
      echo %ec_error -a Error executing sqljsonname update: %sqlite_errstr
    }
    echo %ec_succ -a %whilename ~ %twitch_user_id ~ %x
    INC %x
  }
  sqlite_free %request
  sqlite_close %db
}

; Format: /sqljsonuid
; Runs a while statement through all NULL valued twitch_user_id's in the User Table
; Updates the twitch_user_id based on the name column.  if the name column is correct
alias sqljsonuid {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqljsonuid db: %sqlite_errstr
  }
  var %sql = SELECT name,twitch_user_id FROM User WHERE twitch_user_id IS NULL and name IS NOT NULL
  var %request = $sqlite_query(%db,%sql)
  if (!%request) {
    echo %ec_error -a Error executing sqljsonuid query: %sqlite_errstr
  }
  var %x = 1
  while ($sqlite_fetch_row(%request,row)) {
    var %whilename = $hget(row,name)
    echo %ec_succ -a %whilename
    var %twitch_user_id = $jsongetuserid(%whilename)
    ; Need to create logic around that if twitch user id cannot be found.  Purge the account
    ; This will need to be looked into very carefully and probably a manual effort
    echo %ec_succ -a %twitch_user_id
    var %queryname = $qt(%whilename)
    var %whilesql = UPDATE User SET twitch_user_id = %twitch_user_id WHERE name = %queryname
    if ($sqlite_exec(%db,%whilesql)) {
      ; echo %ec_succ -a Number of rows affected: $sqlite_changes(%db)
    }
    else {
      echo %ec_error -a Error executing sqljsonuid update: %sqlite_errstr
    }
    echo %ec_succ -a %whilename ~ %twitch_user_id ~ %x
    INC %x
  }
  sqlite_free %request
  sqlite_close %db
}

;Format: /sqlumodpvd username +/- points views donations
;This will add or subtract points/views from a viewer.
alias sqlumodpvd {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlumodpvd db: %sqlite_errstr
  }
  var %name = $qt($sqlite_escape_string($1))
  var %sql = UPDATE Stat SET points = points $2 $3 , $&
  views = views $2 $4 , $&
  donations = donations $2 $5 WHERE idUser = ( SELECT idUser FROM User WHERE name = %name )
  if ($sqlite_exec(%db,%sql)) {
    ; echo %ec_succ -a Number of rows affected: $sqlite_changes(%db)
  }
  else {
    echo %ec_error -a Error executing sqlumodpvd update: %sqlite_errstr
  }
  sqlite_close %db
}

; Format: /sqlholcmdcheck username idHoliday
; Checks to see if the user has unlocked any of the holiday commmands
alias sqlholcmdcheck {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlholcmdcheck db: %sqlite_errstr
  }
  var %name = $qt($sqlite_escape_string($1))
  var %holiday = $qt($sqlite_escape_string($2))
  var %sql = SELECT * FROM user_holiday WHERE name = %name AND idHoliday = %holiday LIMIT 1 $&
  OFFSET ABS( RANDOM() % ( SELECT COUNT(*) FROM user_holiday WHERE name = %name AND idHoliday = %holiday ) );
  var %request = $sqlite_query(%db,%sql)
  if (!%request) {
    echo %ec_error -a Error executing sqlholcmdcheck query first: %sqlite_errstr
  }
  elseif (%request) {
    ; while ($sqlite_fetch_row(%request, row, $SQLITE_ASSOC)) {
    ;   var %year = $hget(row,year)
    ;   echo %ec_succ -a Year for Holiday %holiday : %year
    ;   var %years = $+(%years,$chr(126),%year)
    ; }
    %years = $sqlite_result(%request,year)
  }
  echo %ec_succ -a %years
  sqlite_free %request
  sqlite_close %db
  return %years
}

; Format: /sqlholcheck username idHoliday year
; Should check if the user has already unlocked the holiday command for the month/year combination
alias sqlholcheck {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlholcheck db: %sqlite_errstr
  }
  var %name = $qt($sqlite_escape_string($1))
  var %idHoliday = $qt($sqlite_escape_string($2))
  var %year = $sqlite_escape_string($3)
  var %sql = SELECT * FROM user_holiday WHERE name = %name AND idHoliday = %idHoliday AND year = %year
  var %request = $sqlite_query(%db,%sql)
  if (!%request) {
    echo %ec_error -a Error executing sqlholcheck query: %sqlite_errstr
  }
  var %hid = $sqlite_result(%request,idHoliday)
  if (!%hid) {
    ; echo %ec_succ -a False
    sqlite_free %request
    sqlite_close %db
    return $false
  }
  else {
    ; echo %ec_succ -a True
    sqlite_free %request
    sqlite_close %db
    return $true
  }
  sqlite_free %request
  sqlite_close %db
}

; Format: /sqlholmod username holidayid year
; This will add the holiday and year to the users info
alias sqlholmod {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlholmod db: %sqlite_errstr
  }
  var %name = $qt($sqlite_escape_string($1))
  var %holiday = $qt($sqlite_escape_string($2))
  var %year = $sqlite_escape_string($3)
  set %sql $&
  INSERT INTO UserHoliday ( $&
  idHoliday,idUser,year $&
  ) VALUES ( $&
  %holiday , ( SELECT idUser FROM User WHERE name = %name ) , %year $&
  )
  if ($sqlite_exec(%db,%sql)) {
    ; echo %ec_succ -a Query executed succesfully.
  }
  else {
    echo %ec_error -a Error executing sqlholmod insert: %sqlite_errstr - %name
  }
  sqlite_close %db
}

; Format: /sqlsubsay username months
; Will be used to play the sqlite DB'd message for the Sub/GiftSub/ReSub.
; Need to look into way to mute/stop playing /splay while Ivy is speaking.
/*
Possible Options:
  1 = Mute is on, 2 = Mute is off
  Specifies $vol(wave | midi | song | master) for volume levels.
  /vol -u1 | /vol -u2

  /splay stop - could stop currently playing, may not work for new sounds.
  /splay pause - would pause currently playing, would potentially stop future sounds, since they are not queue configured.

  Other option would be to disable the sounds group while this runs and then enable 
  when complete.
*/
alias sqlsubsay {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlsubsay db: %sqlite_errstr
  }
  var %nick = $1
  var %months = $qt($sqlite_escape_string($2))
  var %praise = Please say this with me.  Praise be to the Peel!!!!!
  var %sql = SELECT subMessage FROM subMessage WHERE months = %months
  var %request = $sqlite_query(%db,%sql)
  if (!%request) {
    echo %ec_error -a Error executing sqlsubsay query: %sqlite_errstr
    sqlite_free %request
    sqlite_close %db
    return
  }
  var %sub_message = $sqlite_result(%request,subMessage)
  var %found_tok_nick = $wildtok(%sub_message, NICK?, 1, 32)
  if ($gettok(%found_tok_nick, 2, 75)) {
    %nick = $+(%nick,$chr(44))
  }
  else {
    %nick = $+(%nick,$chr(46))
  }
  var %sub_message = $reptokcs(%sub_message, %found_tok_nick, %nick, 1, 32)
  var %sub_message = $reptokcs(%sub_message, PRAISE, %praise, 0, 32)
  echo %ec_debug -s subMessage: %sub_message
  speak -ls 47 %sub_message
  sqlite_free %request
  sqlite_close %db
  var %status = Replaying Sub message for %nick for a total of $2 months.
  return %status
}

; Format: /sqlsubhandler userid username total tprime t1000 t2000 t3000 rgifts gtotal g1000 g2000 g3000
; Checks if the userid is in the SubData database.
; Updates the Subdata DB info related to the userid if they already exist.
; Inserts the new userdata into the SubData DB if the userid does not already exist.
; 50895536 = dreadfullydespized nick/channel
alias sqlsubhandler {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlsubhandler db: %sqlite_errstr
  }
  var %uid = $sqlite_escape_string($1)
  var %sql = SELECT * FROM SubData WHERE twitch_user_id = %uid
  var %request = $sqlite_query(%db,%sql)
  if (!%request) {
    echo %ec_error -a Error executing sqlsubhandler query: %sqlite_errstr
    sqlite_free %request
    sqlite_close %db
    return
  }
  var %isgood =  $sqlite_num_rows(%request)
  var %name = $qt($sqlite_escape_string($2))
  var %idUser = $sqlite_result(%request,idUser)
  var %total = $sqlite_result(%request,total_month)
  var %prime = $sqlite_result(%request,tprime)
  var %1000 = $sqlite_result(%request,t1000)
  var %2000 = $sqlite_result(%request,t2000)
  var %3000 = $sqlite_result(%request,t3000)
  var %rgifts = $sqlite_result(%request,received_gift)
  var %gtotal = $sqlite_result(%request,gift_total)
  var %g1000 = $sqlite_result(%request,g1000)
  var %g2000 = $sqlite_result(%request,g2000)
  var %g3000 = $sqlite_result(%request,g3000)
  var %n3 = $sqlite_escape_string($3)
  var %n4 = $sqlite_escape_string($4)
  var %n5 = $sqlite_escape_string($5)
  var %n6 = $sqlite_escape_string($6)
  var %n7 = $sqlite_escape_string($7)
  var %n8 = $sqlite_escape_string($8)
  var %n9 = $sqlite_escape_string($9)
  var %n10 = $sqlite_escape_string($10)
  var %n11 = $sqlite_escape_string($11)
  var %n12 = $sqlite_escape_string($12)
  if (%n3) {
    var %total = %n3
  }
  if (%n4 == 1) {
    var %tprime = %tprime + %n4
  }
  if (%n5 == 1) {
    var %1000 = %1000 + %n5
  }
  if (%n6 == 1) {
    var %2000 = %2000 + %n6
  }
  if (%n7 == 1) {
    var %3000 = %3000 + %n7
  }
  if (%n8 == 1) {
    var %rgifts = %rgifts + %n8
  }
  if (%n9 == 1) {
    var %gtotal = %gtotal + %n9
  }
  if (%n10 == 1) {
    var %g1000 = %g1000 + %n10
  }
  if (%n11 == 1) {
    var %g2000 = %g2000 + %n11
  }
  if (%n12 == 1) {
    var %g3000 = %g3000 + %n12
  }
  if (%isgood) {
    ; This means that they are in the DB
    var %sql = UPDATE SubData SET total_month = %total , tprime = %tprime ,  t1000 = %1000 , $&
    t2000 = %2000 , t3000 = %3000 , received_gift = %rgifts , gift_total = %gtotal , $&
    g1000 = %g1000 , g2000 = %g2000 , g3000 = %g3000 WHERE twitch_user_id = %uid
    echo %ec_succ -a %sql
    if ($sqlite_exec(%db,%sql)) {
      ; echo %ec_succ -a Number of rows affected: $sqlite_changes(%db)
    }
    else {
      echo %ec_error -a Error executing sqlsubhandler update: %sqlite_errstr
    }
  }
  else {
    ; This means they are not in the DB
    set %sql $&
    INSERT INTO SubData ( $&
    twitch_user_id, idUser, total_month, tprime, t1000, t2000, t3000, received_gift, gift_total, g1000, g2000, g3000 $&
    ) VALUES ( $&
    $1 , (SELECT idUser FROM User WHERE name = %name ) , %n3 , %n4 , %n5 , %n6 , %n7 , %n8 , %n9 , %n10 , %n11 , %n12 $&
    )
    echo %ec_succ -a %sql
    if ($sqlite_exec(%db,%sql)) {
      ; echo %ec_succ -a Query executed succesfully.
    }
    else {
      echo %ec_error -a Error executing sqlsubhandler insert: %sqlite_errstr
    }
  }
  sqlite_free %request
  sqlite_close %db
  return
}

; FORMAT: /sqlsounds username test
; Checks to see what sounds commands you have based on rank and name
; This also shows the Custom sounds for each user
alias sqlsounds {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlsounds db: %sqlite_errstr
  }
  var %name = $qt($sqlite_escape_string($1))
  var %sql = $&
    SELECT CustomSound.name FROM User $&
    JOIN CustomSound using (idUser) $&
    WHERE User.name = %name $&
    UNION ALL $&
    SELECT name FROM Sound WHERE idRank <= $&
    (SELECT rank FROM Info WHERE idUser = $&
    (SELECT idUser FROM User WHERE name = %name ))
  var %request = $sqlite_query(%db,%sql)
  if (!%request) {
    echo %ec_error -a Error executing sqlsounds query: %sqlite_errstr
  }
  while ($sqlite_fetch_row(%request,row,$SQLITE_ASSOC)) {
    var %sname = $hget(row,name)
    ; Joins the sname value together with character 32 being the separator.
    var %snds = $addtok(%snds,%sname,32)
  }
  if (%snds) {
    ; The default is an alphabetic sort, however you can specify
    ; n = numeric sort, c = channel nick prefix sort, r = reverse sort, a = alphanumeric sort.
    ; 32 is the spacer,deliminator
    %snds = $sorttok(%snds,32,1)
  }
  else {
    echo %ec_error -a No sound commands for %name
  }
  if ($2) {
    echo %ec_succ -a Sound Cmds: %snds
  }
  sqlite_free %request
  sqlite_close %db
  return %snds
}

; FORMAT: /sqlcustomsound nickname soundname randN test
; Should pull the proper custom sound information to play back
alias sqlcustomsound {
  if ($($+(%,csound.,$1),2) && ($1 != dreadfullydespized)) {
    var %reply = $1 --> $2 is on cooldown for $var($+(%,csound.,$1), 1).secs seconds.
    return %reply
  }
  else {
    var %db = $sqlite_open(%testDB2)
    if (!%db) {
      echo %ec_error -a Error at db sqlcustomsound: %sqlite_errstr
    }
    var %uname = $qt($sqlite_escape_string($1))
    var %cuscmd = $qt($sqlite_escape_string($2))
    var %randN = $3
    if ($1 == dreadfullydespized) {
      var %sql = SELECT * FROM CustomSound WHERE name = %cuscmd
    }
    else {
      var %sql = SELECT * FROM CustomSound WHERE idUser = ( SELECT idUser FROM User WHERE name = %uname ) AND name = %cuscmd
    }
    ; echo %ec_succ -a %sql
    var %request = $sqlite_query(%db,%sql)
    if (!%request) {
      echo %ec_error -a Error executing sqlcustomsound query: %sqlite_errstr
    }
    var %cmdname = $sqlite_result(%request,name)
    var %reason = $sqlite_result(%request,reason)
    var %file = $sqlite_result(%request,file)
    var %rand = $sqlite_result(%request,rand)
    var %rCheck = %rand + 1
    if (%rand) {
      if (%randN isnum 1- %rand) {
        var %filepath = $+(%csounds,%file,%randN,.mp3)
        var %file = $+(%file,%randN,.mp3)
      }
      else {
        var %randy = $rand(1, %rand )
        var %filepath = $+(%csounds,%file,%randy,.mp3)
        var %file = $+(%file,%randy,.mp3)
      }
    }
    else {
      var %filepath = $+(%csounds,%file,.mp3)
      var %file = $+(%file,.mp3)
    }
    if (%cmdname) {
      splay %filepath
      if ($1 != dreadfullydespized) {
        set -eu60 $+(%,csound.,$1) On
      }
      if (%randN isnum %rCheck -) {
        var %reply = Please be advised that $+([,!,$2,]) is limited to $+([,1-,%rand,],.)
      }
      else {
        var %reply = played $+([,%file,],.) Earned due to $+([,%reason,],.)
      }
      msg $chan $1 --> %reply
      if ($4) {
        echo %ec_succ -a %reply
      }
      sqlite_free %request
      sqlite_close %db
      return %reply
    }
    else {
      var %reply = I am sorry, I was not able to find the requested sound.
      ; echo %ec_succ -a %reply
      sqlite_free %request
      sqlite_close %db
      return %reply
    }
    sqlite_free %request
    sqlite_close %db
  }
}

; FORMAT: /sqlcsu username reason
; Used to evaluate if the 1000+ hours have been hit
; This needs to handle twitch subs as well for any new/recurring/gifted subs
alias sqlcsu {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at db sqlcsu: %sqlite_errstr
  }
  var %name = $qt($sqlite_escape_string($1))
  var %reason = $qt($sqlite_escape_string($2-))
  var %sql = SELECT * FROM CustomSound WHERE idUser = ( SELECT idUser FROM User WHERE name = %name ) AND reason = %reason
  var %request = $sqlite_query(%db,%sql)
  if (!%request) {
    echo %ec_error -a Error executing sqlcsu query: %sqlite_errstr
  }
  else {
    if ($sqlite_num_rows(%request) isnum 1-) {
      if ($sqlite_result(%request,name) == $null ) {
        echo %ec_debug -a The Name is Null: $sqlite_result(%request,idUser) - $sqlite_result(%request,name) - $sqlite_result(%request,idName)
        ; msg $1 $1 --> You unlocked the custom audio for $+($chr(32),%reason) . Please goto this link for dicksword https://discord.gg/e2NwTSnN4j and click on the envelope to submit for a custom audio.
        var %msg = $addtok(%msg, -->,32)
          %msg = $addtok(%msg,You unlocked the customer audio for,32)
          %msg = $addtok(%msg,%reason,32)
          %msg = $addtok(%msg,. Please goto this link for dicksword http://discord.gg/e2NwTSnN4j and click on the envelope to submit for a custom audio.,32)
        $jsonwhisper(%twuid,%msg,$1)
      }
      else {
        echo %ec_succ -a %name you have already unlocked the custom audio for %reason
      }
    }
    else {
      set %sql INSERT INTO CustomSound ( idUser,reason ) VALUES ( ( SELECT idUser FROM User WHERE name = %name ) , %reason )
      if ($sqlite_exec(%db,%sql)) {
        echo %ec_succ -a Insert via sqlcsu completed
        msg $chan $1 --> Thank you for supporting the stream with $+($chr(32),%reason) . Please goto this link for dicksword https://discord.gg/e2NwTSnN4j and click on the envelope to submit for a custom audio.
      }
      else {
      echo %ec_error -a Error executing sqlcsu insert: %sqlite_errstr
      }
    }
  }
  sqlite_free %request
  sqlite_close %db
  return
}

; FORMAT: /sqlranksound nickname soundname title rank randN
; Should pull the proper rank sound information to play back
alias sqlranksound {
  if ($($+(%,rsound.,$1),2) && ($1 != dreadfullydespized)) {
    var %reply = --> $2 is on cooldown for $var($+(%,rsound.,$1), 1).secs seconds.
    return %reply
  }
  else {
    var %db = $sqlite_open(%testDB2)
    if (!%db) {
      echo %ec_error -a Error at db sqlranksound: %sqlite_errstr
    }
    var %uname = $qt($sqlite_escape_string($1))
    var %cmd = $qt($sqlite_escape_string($2))
    var %rcur = $3
    var %rank = $4
    var %randN = $5
    var %sql = SELECT * FROM Sound WHERE name = %cmd
    var %request = $sqlite_query(%db,%sql)
    if (!%request) {
      echo %ec_error -a Error executing sqlranksound query: %sqlite_errstr
    }
    var %idRank = $sqlite_result(%request,idRank)
    var %cmdname = $sqlite_result(%request,name)
    var %file = $+(Achieved-,$sqlite_result(%request,file))
    var %rand = $sqlite_result(%request,rand)
    var %rCheck = %rand + 1
    if (%rand) {
      if (%randN isnum 1- %rand) {
        var %filepath = $+(%asounds,%file,%randN,.mp3)
        var %file = $+(%file,%randN,.mp3)
      }
      else {
        var %randy = $rand(1, %rand )
        var %filepath = $+(%asounds,%file,%randy,.mp3)
        var %file = $+(%file,%randy,.mp3)
      }
    }
    else {
      var %filepath = $+(%asounds,%file,.mp3)
      var %file = $+(%file,.mp3)
    }
    if (%idRank) {
      var %sql = SELECT title FROM Rank WHERE idRank = %idRank
      var %request2 = $sqlite_query(%db,%sql)
      if (!%request2) {
        echo %ec_error -a Error executing sqlranksound query2: %sqlite_errstr
      }
      var %titleneed = $sqlite_result(%request2,title)
    }
    if (%rank isnum %idRank -) {
      splay %filepath
      if ($1 != dreadfullydespized) {
        set -eu60 $+(%,rsound.,$1) On
      }
      if ($2 == chicken) {
        msg $chan $1 --> calls forth the Chicken BACOCK!!!!
      }
      if (%randN isnum %rCheck -) {
        var %reply = Please be advised that $+([,!,$2,]) is limited to $+([,1-,%rand,],.)
      }
      else {
        var %reply = You have summoned the $+([,%file,]) earned at $+(†,%titleneed,†) rank.
        echo %ec_succ -a playing %file
      }
    }
    else {
      var %reply = You are currently $+(†,%rcur,†) and you must be $+(†,%titleneed,†) to achieve this command.
    }
  }
  sqlite_free %request
  sqlite_free %request2
  sqlite_free %request3
  sqlite_close %db
  return %reply
}

; FORMAT: /sqlscare scarenumber
; Should pull the correct scare file name from the
; scare table
alias sqlscare {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at db scaretest: %sqlite_errstr
  }
  var %scarecmd = $1
  var %sql = SELECT idScare FROM Scare WHERE idScare = $1
  var %request = $sqlite_query(%db,%sql)
  if (!%request) {
    echo %ec_error -a Error executing scaretest query: %sqlite_errstr
  }
  var %idScare = $sqlite_result(%request,idScare)
  if (%idScare) {
    splay $+(%scaresounds,scare,%idScare,.mp3)
    var %reply = used 2500 potatoes to play $+(scare,%idScare,.mp3)
  }
  else {
    var %reply = It appears that DreadfullyDespized needs more scare commands.  Please send ideas to him.
  }
  echo %ec_succ -a %reply
  sqlite_free %request
  sqlite_close %db
  return %reply
}

; FORMAT: /sqlgaadd username tickets gacost
; Adds user to the sqlite Giveaway table
alias sqlgaadd {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
      echo %ec_error -a Error at db sqlgaadd: %sqlite_errstr
  }
  var %name = $1
  var %tickets = $2
  var %line = 1
  set %sql $&
  INSERT INTO Giveaway ( $&
  idUser,ticket $&
  ) VALUES ( $&
  ( SELECT idUser FROM User WHERE name = %name ) , %tickets $&
  )
  ; echo %ec_succ -a %sql
  while (%line <= %tickets) {
      if ($sqlite_exec(%db,%sql)) {
          ; echo %ec_succ -a Query executed succesfully.
      }
      else {
      echo %ec_error -a Error executing sqlgaadd insert: %sqlite_errstr
      }
      inc %line
  }
  sqlite_close %db
}

; FORMAT: /sqlga username tickets gacost
; Used to begin the process of adding user entries for the giveaway
alias sqlga {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at db sqlga: %sqlite_errstr
  }
  var %name = $qt($sqlite_escape_string($1))
  var %tickets = $sqlite_escape_string($2)

  var %sql = SELECT * FROM ga_current WHERE name = %name
  var %request = $sqlite_query(%db,%sql)
  if (!%request) {
    echo %ec_error -a Error executing sqlga query: %sqlite_errstr
  }
  else {
    ; Gets max ticket entry minus how many entries already made
    ; If first entry is 7 and max is 12 that leaves 5
    var %tickdiff = $calc(%gamaxticket - $sqlite_num_rows(%request))
    echo %ec_supp -a sqlga ROWS: $sqlite_num_rows(%request) and %tickdiff left


    ; This does come up as how many entries row made
    ; This needs to be a check of how many total entries
    if ($sqlite_num_rows(%request) == 1- %tickdiff) {
      var %response = You are already in the Giveaway with $+($chr(91),$sqlite_result(%request,ticket),$chr(93),$chr(32),$iif($sqlite_result(%request,ticket) >= 2,tickets,ticket),.) With a cost of $+($chr(91),$calc($2 * $3),$chr(93),$chr(32),$iif($calc($2 * $3) >= 2,potatos,potato),.)
    }
    elseif ($2 > %tickdiff) {
      var %response = You submitted too many ticket entries for the Giveaway, $iif(%tickdiff == 0,You have achieved maximum participation.,Please submit $+($chr(91),%tickdiff,$chr(93),$chr(32),$iif(%tickdiff >= 2,tickets,ticket)) or less, to add entries.)
    }
    else {
      $sqlgaadd(%name,%tickets,$3)
      var %response = YAY! You entered the Giveaway using $+($chr(91),$2,$chr(93),$chr(32),$iif($2 >= 2,tickets,ticket),.) With a cost of $+($chr(91),$calc($2 * $3),$chr(93),$chr(32),$iif($calc($2 * $3) >= 2,potatos,potato),.)
    }
  }
  sqlite_free %request
  sqlite_close %db
  echo %ec_succ -a %response
  return %response
}

; FORMAT: /sqlgawin
; Should pick a winner at random from the DB entries.
; Should also update the user's Stat table for total giveaways won.
alias sqlgawin {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
      echo %ec_error -a Error at db sqlgawin: %sqlite_errstr
  }
  var %sql = SELECT name,idUser FROM ga_current LIMIT 1 OFFSET ABS( RANDOM() % ( SELECT COUNT(*) FROM ga_current ) )
  var %request = $sqlite_query(%db,%sql)
  if (!%request) {
      echo %ec_error -a Error executing sqlgawin-SELECT query: %sqlite_errstr
      sqlite_free %request
      sqlite_close %db
      var %response = No winner's found in the DB table.
      return %response
  }
  var %name = $sqlite_result(%request,name)
  var %userid = $sqlite_result(%request,idUser)
  var %name2 = $qt($sqlite_escape_string(%name))
  sqlite_free %request
  var %sql = UPDATE Stat SET giveaway_win = giveaway_win + 1 $&
  WHERE idUser = ( SELECT idUser FROM User where name = %name2 )
  if ($sqlite_exec(%db,%sql)) {
    ; echo %ec_succ -a Number of rows affected: $sqlite_changes(%db)
  }
  else {
    echo %ec_error -a Error executing sqlgawin update: %sqlite_errstr
  }
  set %sql DELETE FROM Giveaway WHERE idUser = %userid
  if ($sqlite_exec(%db,%sql)) {
    ; echo %ec_succ -a %userid was wiped from table
    write $+(-ds,$chr(34),%name,$chr(34)) giveaway2.txt
    $+(timer,%name,.gawintimer) 1 65 sqlgawin
  }
  else {
    echo %ec_error -a Error executing sqlgawin Delete: %sqlite_errstr
  }
  sqlite_close %db
  var %response = %name --> Is the winner!!! you have 60 seconds to comply!
  speak -l %response
  msg %mychan %response
  return %response
}

; FORMAT: /sqlgaclean
; Should clean out the Giveaway table.  So that new users can be put into it.
alias sqlgaclean {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
      echo %ec_error -a Error at db sqlgaclean: %sqlite_errstr
  }
  set %sql DELETE FROM Giveaway
  if ($sqlite_exec(%db,%sql)) {
      var %reply = Giveaway table has been cleaned
      echo %ec_succ -a %reply
  }
  else {
      echo %ec_error -a Error executing sqlgaclean Delete: %sqlite_errstr
  }
  sqlite_close %db
  return %reply
}

; Format: /sqlhighlight username date time uptime message game
; Adds the requested highlight to the database.
alias sqlhighlight {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at db sqlhighlight: %sqlite_errstr
  }
  else {
    var %name = $qt($sqlite_escape_string($1))
    var %date = $qt($2)
    var %time = $qt($3)
    var %uptime = $qt($4)
    var %msg = $qt($sqlite_escape_string($5))
    var %game = $qt($7)
    echo -a %name %date %time %uptime %msg $6 %game
    set %sql $&
      INSERT INTO highlight ( $&
      idUser, date, time, uptime, msg, points, game $&
      ) VALUES ( $&
      ( SELECT idUser FROM User WHERE name = %name ) , %date , %time , %uptime , %msg , $6 , %game $&
      )
    if ($sqlite_exec(%db,%sql)) {
      echo %ec_succ -a Query executed succesfully.
    }
    else {
      echo %ec_succ -a Error executing sqlhighlight insert: %sqlite_errstr
    }
  }
  sqlite_close %db
}

; Format: /rollpurge
; Used to clear all rolls that are not in play
alias rollpurge {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at db rollpurge: %sqlite_errstr
  }
  else {
    var %date = $qt($date(yyyy-mm-dd))
    set %sql DELETE FROM Roll WHERE current = 1 AND date = %date
    if ($sqlite_exec(%db,%sql)) {
      var %reply = Ze Boss has purged all bad rolls!!! - Take that!!!
      echo %ec_succ -a %reply
    }
    else {
      echo %ec_error -a Error executing rollpurge delete: %sqlite_errstr
    }
  }
  sqlite_close %db
  return %reply
}
  
; Format: /rollinsert username currentdate message/option roll
; Used to insert into the DB the new roll of the user.
; This should only be called by the roll alias
alias rollinsert {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at db rollinsert: %sqlite_errstr
  }
  else {
    var %name = $1
    var %date = $2
    var %msg = $3
    var %rollrand = $4
    set %sql $&
    INSERT INTO Roll ( $&
      idUser, date, option, roll, current $&
      ) VALUES ( $&
      ( SELECT idUser FROM User WHERE name = %name ) , %date , %msg , %rollrand , 1 $&
      )
    echo %ec_succ -a %sql
    if ($sqlite_exec(%db,%sql)) {
      echo %ec_succ -a Query executed succesfully.
    }
    else {
      echo %ec_error -a Error executing rollinsert insert: %sqlite_errstr
    }
  }
  sqlite_close %db
  return
}
  
; Format: /roll username message/option
; Used to begin the insert of the roll for the user
alias roll {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at db roll: %sqlite_errstr
  }
  else {
    var %name = $qt($sqlite_escape_string($1))
    var %msg = $qt($sqlite_escape_string($2-))
    var %date = $qt($asctime(yyyy-mm-dd))
    var %request = $rollaction(1,%name,%date)
    var %sql = SELECT * FROM roll_current WHERE name = %name AND date = %date and current = 1
    ; echo %ec_succ -a %sql
    var %request = $sqlite_query(%db,%sql)
    if (!%request) {
      echo %ec_error -a Error executing roll query: %sqlite_errstr
    }
    else {
      if ($sqlite_num_rows(%request) isnum 1) {
        var %rollresponse = why you do that.. wait your turn!!! Or wait for a !rollcur to happen.
      }
      else {
        var %rollrand = $rand(1,20)
        if (%rollrand isnum 1) {
          var %rollresponse = critical failure!!! with a roll of %rollrand
          $rollinsert(%name,%date,%msg,%rollrand)
          splay %ssounds $+ criticalfail.mp3
        }
        elseif (%rollrand isnum 20) {
          var %rollresponse = critical success!!! with a roll of %rollrand
          $rollinsert(%name,%date,%msg,%rollrand)
          splay %ssounds $+ criticalsuccess.mp3
        }
        else {
          var %rollresponse = has rolled a %rollrand
          $rollinsert(%name,%date,%msg,%rollrand)
        }
      }
    }
  }
  sqlite_free %request
  sqlite_close %db
  echo %ec_succ -a %rollresponse
  return %rollresponse
}
  
; Format: /rollcur
; This command is streamer only.  Checks for current rolls and compares to find winner
alias rollcur {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at db rollcur: %sqlite_errstr
  }
  else {
    var %date = $qt($date(yyyy-mm-dd))
    var %sql = SELECT * FROM roll_current WHERE date = %date AND roll = (SELECT max(roll) FROM roll_current)
    echo -a %sql
    var %request = $sqlite_query(%db,%sql)
    if (!%request) {
      echo %ec_error -a Error executing rollcur query: %sqlite_errstr
    }
    var %name1 = $sqlite_result(%request,name)
    var %name = $qt($sqlite_result(%request,name))
    var %maxroll = $sqlite_result(%request,roll)
    var %option = $sqlite_result(%request,option)
    var %sql = $&
      UPDATE Roll SET victory = 1 WHERE idUser = ( $&
      SELECT idUser FROM Info WHERE name = %name $&
      ) AND roll = %maxroll AND current = 1
    if ($sqlite_exec(%db,%sql)) {
      echo -a Number of rows affected victory: $sqlite_changes(%db)
    }
    else {
      echo %ec_error -a Error executing rollcur victory update: %sqlite_errstr
      echo %ec_error -a %sql
    }
    var %sql = UPDATE Roll SET current = 0 WHERE date = %date AND current = 1
    if ($sqlite_exec(%db,%sql)) {
      echo %ec_succ -a Number of rows affected current: $sqlite_changes(%db)
    }
    else {
      echo %ec_error -a Error executing rollcur update: %sqlite_errstr
    }
    if ($sqlite_changes(%db) == 0) {
      var %rollresponse = No current rolled users found.
    }
    var %rollresponse = $+([,%name1,]) rolled a winning $+([,%maxroll,]) with option $+([,%option,],!!)
  }  
  echo %ec_succ -a %rollresponse
  sqlite_free %request
  sqlite_close %db
  return %rollresponse
}

; Format: /sqlqadd username quotetext
; This should add a fully completed new quote to the sqlite db
alias sqlqadd {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlqadd db: %sqlite_errstr
  }
  else {
    var %name = $1
    var %user = $qt($sqlite_escape_string($1))
    var %date = $qt($asctime(yyyy-mm-dd - HH:nn:ss))
    var %quote = $qt($sqlite_escape_string($2-))
    var %sql = SELECT count from row_quote
    var %request = $sqlite_query(%db,%sql)
    if (!%request) {
      echo %ec_error -a Error executing sqlqadd count: %sqlite_errstr
    }
    else {
      var %qtotalrows = $sqlite_result(%request,count) + 1
      $jsontest
      var %game = $qt($sqlite_escape_string(%streamgame))
      set %sql $&
        INSERT INTO Quote ( $&
        idUser, date, quote, game $&
        ) VALUES ( $&
        ( SELECT idUser FROM User WHERE name = %user ) , %date , %quote , %game $&
        )
      if ($sqlite_exec(%db,%sql)) {
        ; echo %ec_succ -a Last Inserted RowID: $sqlite_last_insert_rowid(%db)
      }
      else {
        echo %ec_error -a Error executing sqlqadd insert: %sqlite_errstr
      }
      var %quoteadded = Quote $+([,%qtotalrows,]) from $+([,%name,]) was added.
      if (%name != dreadfullydespized) {
        set -eu15 %floodquotes On
      }
    }
  }
  ; echo %ec_succ -a %quoteadded
  sqlite_free %request
  sqlite_close %db
  return %quoteadded
}

; FORMAT: /sqlivyqins username quote
; This will add the previously stated message by ivy into the db table
; builds the date/time in the alias
alias sqlivyqins {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlivyqins db: %sqlite_errstr
  }
  else {
    var %name = $1
    var %user = $qt($sqlite_escape_string($1))
    var %date = $qt($asctime(yyyy-mm-dd - HH:nn:ss))
    var %quote = $qt($sqlite_escape_string($2))
    set %sql $&
      INSERT INTO Ivy ( $&
      idUser, date, quote $&
      ) VALUES ( $&
      (SELECT idUser FROM User WHERE name = %user ) , %date , %quote $&
      )
    if ($sqlite_exec(%db, %sql)) {
    ; echo %ec_succ -a Last Inserted RowID: $sqlite_last_insert_rowid(%db)
    }
    else {
      echo %ec_error -a Error executing sqlivyqins insert: %sqlite_errstr
    }
  }
  sqlite_close %db
}

; Format: /sqlqotdadd username qotdtext
; This will add the entered qotd into the database table and set as current
alias sqlqotdadd {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlqotdadd db: %sqlite_errstr
  }
  else {
    var %name = $1
    var %user = $qt($sqlite_escape_string($1))
    var %date = $qt($asctime(yyyy-mm-dd - HH:nn:ss))
    var %qotd = $qt($sqlite_escape_string($2-))
    set %sql INSERT INTO Qotd ( $&
      idUser, qotd, date, current $&
      ) VALUES ( $&
      ( SELECT idUser FROM User WHERE name = %user ) , %qotd , %date , 1 $&
      )
    if ($sqlite_exec(%db,%sql)) {
      ; echo %ec_succ -a Last Inserted RowID: $sqlite_last_insert_rowid(%db)
    }
    else {
      echo %ec_error -a Error executing sqlqotdadd insert: %sqlite_errstr
    }
    var %qotdmessage = QOTD has been added to the DB %user
    if (%name != dreadfullydespized) {
      set -eu15 %floodqotd On
    }
  }
  sqlite_close %db
  return %qotdmessage
}

; Format: /sqlqdel quotenumber
; This will delete the quote with the specified ROWSID from the db
; This will purge from the DB.  Though the file system still needs to be handled
alias sqlqdel {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlqdel db: %sqlite_errstr
  }
  else {
    var %row = $1
    var %sql = SELECT count FROM row_quote
    var %request = $sqlite_query(%db,%sql)
    if (!%request) {
      echo %ec_error -a Error at request sqlqdel: %sqlite_errstr
    }
    else {
      var %qtotalrows = $sqlite_result(%request,count)
      if (%row isnum %qtotalrows -) {
        set %sql DELETE FROM Quote WHERE idQuote = ( SELECT idQuote FROM row_quote WHERE rowNUM = %row )
        if ($sqlite_exec(%db,%sql)) {
          var %quotedeleted = Quote %row was deleted
          ; This will delete the files related to the quote to be removed
          $findfile(%qsounds,$+(Q,$1,-,$chr(42),.mp3),0,0,remove $iif($!isFile($1),$1-))
        }
        else {
          echo %ec_error -a Error executing sqlqdel delete: %sqlite_errstr
        }
      }
      else {
        var %quotedeleted = Quote %row was not found
      }
    }
  }
  sqlite_free %request
  sqlite_close %db
  ; echo %ec_succ -a %quotedeleted
  return %quotedeleted
}

; Format: /sqlqotddel
; This will expire the current Question of the day but it will not remove it
alias sqlqotddel {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlqotddel db: %sqlite_errstr
  }
  else {
    var %sql = SELECT idQotd FROM Qotd WHERE current = 1 ORDER BY idQotd ASC LIMIT 1
    var %request = $sqlite_query(%db,%sql)
    if (!%request) {
      echo %ec_error -a Error at request sqlqotddel: %sqlite_errstr
    }
    else {
      var %idQotd = $sqlite_result(%request,idQotd)
      var %sql = UPDATE Qotd SET current = 0 WHERE idQotd = %idQotd
      if ($sqlite_exec(%db,%sql)) {
        ; echo %ec_succ -a Number of rows affected: $sqlite_changes(%db)
        var %qotdupdated = Current Qotd has been updated
      }
      else {
        echo %ec_error -a Error executing sqlqotddel update: %sqlite_errstr
      }
    }
  }
  ; echo %ec_succ -a %idQotd
  sqlite_free %request
  sqlite_close %db
  return %qotdupdated
}

;Format: /sqlqwith table username {phrase or word}
;This will return a random quote that has the requested word in it.
alias sqlqwith {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlqwith db: %sqlite_errstr
  }
  else {
    var %name = $2
    var %question = $qt($+(%,$sqlite_escape_string($3-),%))
    var %sql = SELECT * FROM $1 WHERE quote LIKE %question ORDER BY random() LIMIT 1
    var %request = $sqlite_query(%db,%sql)
    if (!%request) {
      echo %ec_error -a Error executing sqlqwith query: %sqlite_errstr
    }
    else {
      var %qtotalrows = $sqlite_result(%request,count)
      var %rowNUM = $sqlite_result(%request,rowNUM)
      if (!%rowNUM) {
        var %quotemsg = $+([,$3-,]) was not found in any quotes.
      }
      else {
        var %qdate = $sqlite_result(%request,date)
        var %quser = $sqlite_result(%request,name)
        var %qquote = $sqlite_result(%request,quote)
        if ($1 == row_ivy) {
          var %quotemsg = Ivy Says $+([,$chr(35),%rowNUM,/,%qtotalrows,]) added by $+([,%quser,]) on $+([,%qdate,]) - $+(",%qquote,")
          speak -l %qquote
        }
        elseif ($1 == row_quote) {
          var %idQuote = $sqlite_result(%request,idQuote)
          var %qgame = $sqlite_result(%request, game)
          var %qquoterand = $sqlite_result(%request,quoterand)
          var %quotemsg = Quote $+([,$chr(35),%rowNUM,/,%qtotalrows,]) added by $+([,%quser,]) on $+([,%qdate,]) while playing $+([,%qgame,]) - $+(",%qquote,")
          if (%name != dreadfullydespized) {
            set -eu60 %floodquotes On
          }
          var %qr1 = $rand(1,%qquoterand)
          var %soundFile = $+(%qsounds,q,%idQuote,-,%qr1,.mp3)
          splay %soundFile
        }
      }
    }
  }
  echo %ec_succ -a %quotemsg
  sqlite_free %request
  sqlite_close %db
  return %quotemsg
}

; Format: /sqlqnum table numberofquote username
; returns the quote based on number from any table provided
alias sqlqnum {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlqnum db: %sqlite_errstr
  }
  else {
    var %qnumber = $2
    var %table = $1
    var %name = $3
    var %sql = SELECT * FROM %table WHERE rowNUM = %qnumber
    var %request = $sqlite_query(%db,%sql)
    if (!%request) {
      echo %ec_error -a Error executing sqlqnum query: %sqlite_errstr
    }
    else {
      var %qdate = $sqlite_result(%request,date)
      var %qquote = $sqlite_result(%request,quote)
      var %qtotalrows = $sqlite_result(%request,count)
      var %rowNUM = $sqlite_result(%request,rowNUM)
      var %quser = $sqlite_result(%request,name)
    }
    var %sql2 = SELECT count FROM %table LIMIT 1
    var %request2 = $sqlite_query(%db,%sql2)
    if (!%request2) {
      echo %ec_error -a Error executing sqlqnum query2: %sqlite_errstr
    }
    else {
      var %qtotalrows = $sqlite_result(%request2,count)
    }
    if ($2 <= %qtotalrows) {
      if ($1 == row_ivy) {
        var %quotemsg = Ivy Says $+([,$chr(35),%rowNUM,/,%qtotalrows,]) added by $+([,%quser,]) on $+([,%qdate,]) - $+(",%qquote,")
        if (%name != dreadfullydespized) {
          set -eu60 %floodquotes On
        }
        speak -l %qquote
      }
      elseif ($1 == row_quote) {
        var %user = $sqlite_result(%request,idUser)
        var %qgame = $sqlite_result(%request,game)
        var %qquoterand = $sqlite_result(%request,quoterand)
        var %quotemsg = Quote $+([,$chr(35),%rowNUM,/,%qtotalrows,]) added by $+([,%quser,]) on $+([,%qdate,]) while playing $+([,%qgame,]) - $+(",%qquote,")
        if (%name != dreadfullydespized) {
          set -eu60 %floodquotes On
        }
        if (%qquoterand > 0) {
          var %qr1 $rand(1,%qquoterand)
          var %soundFile = $+(%qsounds,q,$2,-,%qr1,.mp3)
          splay %soundFile
        }
      }
    }
    else {
      var %quotemsg = Quote Request failed. $+([,$2,]) goes over max quotes of $+([,%qtotalrows,]).
      if (%name != dreadfullydespized) {
        set -eu5 %floodquotes On
      }
    }
  }
  sqlite_free %request
  sqlite_free %request2
  sqlite_close %db
  return %quotemsg
}

; FORMAT: /sqlqotd nick
; Will query the QoTD table for the latest or current qotd.
alias sqlqotd {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlqotd db: %sqlite_errstr
  }
  else {
    var %name = $1
    var %sql = SELECT qotd,name FROM Qotd WHERE current = 1 ORDER BY idQotd ASC LIMIT 1
    var %request = $sqlite_query(%db,%sql)
    echo %ec_debug -a %request
    if (!%request) {
      echo %ec_error -a Error executing sqlqotd query: %sqlite_errstr
    }
    else {
      if ($sqlite_result(%request,qotd)) {
        var %qotd = $sqlite_result(%request,qotd)
        var %qname = $sqlite_result(%request,name)
        var %qotdmessage = QoTD: %qotd : %qname
        var %ivyqotd The Question of the day is, $deltok(%qotdmessage,1,32)
        speak -l %ivyqotd
        if (%name != dreadfullydespized) {
          set -eu15 %floodqotd On
        }
      }
      else {
        var %qotdmessage = %name --> It appears that there isn't a question of the day. Would you entertain the thought of adding one? Do so by !qotd add (your qotd?).
        var %ivyqotd $deltok(%qotdmessage,2,32)
        speak -l %ivyqotd
        if (%name != dreadfullydespized) {
          set -eu5 %floodqotd On
        }
      }
    }
  }
  echo %ec_succ -a %qotdmessage
  sqlite_free %request
  sqlite_close %db
  return %qotdmessage
}

;FORMAT: /sqlqyrand table nickname year
alias /sqlqyrand {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlqrand db: %sqlite_errstr
  }
  else {
    var %name = $2
    var %year = $qt($+($sqlite_escape_string($3),-,%))
    var %sql = SELECT * FROM $1 WHERE date LIKE %year ORDER BY random() LIMIT 1
    var %request = $sqlite_query(%db, %sql)
    if (!%request) {
      echo %ec_error -a Error executing sqlqrand query: %sqlite_errstr
    }
    else {
      var %qtotalrows = $sqlite_result(%request,count)
      var %rowNUM = $sqlite_result(%request,rowNUM)
      if (!%rowNUM) {
        var %quotemsg = $+([,$3-,]) was not found in any quotes.
      }
      else {
        var %qdate = $sqlite_result(%request,date)
        var %quser = $sqlite_result(%request,name)
        var %qquote = $sqlite_result(%request,quote)
        if ($1 == row_ivy) {
          var %quotemsg = Ivy Says $+([,$chr(35),%rowNUM,/,%qtotalrows,]) added by $+([,%quser,]) on $+([,%qdate,]) - $+(",%qquote,")
          if (%name != dreadfullydespized) {
            set -eu60 %floodquotes On
          }
          speak -l %qquote
        }
        elseif ($1 == row_quote) {
          var %idQuote = $sqlite_result(%request,idQuote)
          var %qgame = $sqlite_result(%request, game)
          var %qquoterand = $sqlite_result(%request,quoterand)
          var %quotemsg = Quote $+([,$chr(35),%rowNUM,/,%qtotalrows,]) added by $+([,%quser,]) on $+([,%qdate,]) while playing $+([,%qgame,]) - $+(",%qquote,")
          if (%name != dreadfullydespized) {
            set -eu60 %floodquotes On
          }
          var %qr1 = $rand(1,%qquoterand)
          var %soundFile = $+(%qsounds,q,%idQuote,-,%qr1,.mp3)
          splay %soundFile
        }
      }
    }
  }
  echo %ec_succ -a %quotemsg
  sqlite_free %request
  sqlite_close %db
  return %quotemsg
}

; FORMAT: /sqlqrand table nickname
; Will query DB for total count of quotes and then use sqlqnum
; to query the info for the random quote.
alias sqlqrand {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlqrand db: %sqlite_errstr
  }
  else {
    var %name = $2
    var %sql = SELECT count FROM $1 LIMIT 1
    var %request = $sqlite_query(%db, %sql)
    if (!%request) {
      echo %ec_error -a Error executing sqlqrand query: %sqlite_errstr
    }
    else {
      var %count = $sqlite_result(%request,count)
      var %qrand = $rand(1,%count)
      var %taco = $sqlqnum($1,%qrand,$2)
    }
  }
  sqlite_free %request
  sqlite_close %db
  return %taco
}

; Format: /sqlqdelete nickname table quotenumber
; This will delete the quote with the specified ROWSID from the db
; This will purge from the DB. Though the file system still needs to be handled
alias sqlqdelete {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlqdel db: %sqlite_errstr
  }
  else {
    var %name = $qt($sqlite_escape_string($1))
    var %row = $3
    if ($2 == row_quote2) {
      var %table = Quote
      var %column = idQuote
    } else {
      var %table = Ivy
      var %column = idIvy
    }
    var %sql = SELECT count FROM $2
    var %request = $sqlite_query(%db,%sql)
    if (!%request) {
      echo %ec_error -a Error at request sqlqdel: %sqlite_errstr
    }
    else {
      var %qtotalrows = $sqlite_result(%request,count)
      if (%row isnum %qtotalrows -) {
        set %sql DELETE FROM %table WHERE %column = ( SELECT %column FROM $2 WHERE rowNUM = %row )
        if ($sqlite_exec(%db,%sql)) {
          var %quotedeleted = %table %row was deleted
          ; This will delete the files related to the quote to be removed
          if (%table == Quote) {
            $findfile(%qsounds,$+(Q,$3,-,$chr(42),.mp3),0,0,remove $iif($!isFile($3),$3-))
          }
        }
        else {
          echo %ec_error -a Error executing sqlqdelete delete: %sqlite_errstr
        }
      }
      else {
        var %quotedeleted = %table %row was not found
      }
    }
  }
  sqlite_free %request
  sqlite_close %db
  echo %ec_succ -a %quotedeleted
  return %quotedeleted
}

; FORMAT: /sqlulqdel username
; Will search for the id to find with your name on it and delete it
alias sqlulqdel {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlulqdel db: %sqlite_errstr
  }
  else {
    var %name = $qt($sqlite_escape_string($1))
    var %sql = SELECT * FROM row_ivy WHERE name = %name ORDER BY idIvy DESC LIMIT 1
    var %request = $sqlite_query(%db, %sql)
    if (!%request) {
      echo %ec_error -a Error executing sqlulqdel query: %sqlite_errstr
    }
    else {
      var %idIvy = $sqlite_result(%request,idIvy)
      var %rowNUM = $sqlite_result(%request,rowNUM)
      set %sql DELETE FROM Ivy WHERE idIvy = %idIvy
      if ($sqlite_exec(%db, %sql)) {
        var %quotedeleted = Ivy Say %rowNUM was deleted
      }
      else {
        echo %ec_error -a Error executing sqlulqdel delete: %sqlite_errstr
      }
    }
  }
  ; echo %ec_succ -a %quotedeleted
  sqlite_free %request
  sqlite_close %db
  return %quotedeleted
}

; FORMAT: /sqlpradds username potatoes
; Will check to see if they have already been entered into the db, if not then add them.
alias sqlpradds {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at db sqlpradds: %sqlite_errstr
  }
  else {
    var %name = $qt($sqlite_escape_string($1))
    var %currency = $sqlite_escape_string($2)
    var %sql = SELECT * FROM PotatoRun
    var %request = $sqlite_query(%db,%sql)
    if (!%request) {
      echo %ec_error -a Error executing sqlpradds query: %sqlite_errstr
    }
    else {
      if ($sqlite_num_rows(%request) isnum 5-) {
        var %response = PotatoRun has reached the max entries of 5.
      }
      else {
        var %sql = SELECT name FROM prend WHERE name = %name
        var %request = $sqlite_query(%db,%sql)
        if (!%request) {
          echo %ec_error -a Error executing sqlpradds query2: %sqlite_errstr
        }
        else {
          if ($sqlite_num_rows(%request) isnum 1-) {
            var %response = $1 You have already entered into the PotatoRun
          }
          else {
            var %rand = $rand(1,5)
            echo %ec_debug -a Stuff: %name - %currency - %rand
            set %sql $&
              INSERT INTO PotatoRun ( idUser,wager,idPR ) VALUES ( $&
              ( SELECT idUser FROM User WHERE name = %name ), %currency , %rand $&
              )
            echo %ec_succ -a %sql
            if ($sqlite_exec(%db,%sql)) {
              echo %ec_succ -a Last Inserted sqlpradds RowID: $sqlite_last_insert_rowid(%db)
              ; This will remove the currency that the user requested to use. This should be commented out when testin the system.
              $sqlumodpvd($1,-,$2,0,0)
            }
            else {
              echo %ec_error -a Error executing sqlpradds Insert: %sqlite_errstr
            }
          }
        }
      }
    }
  }
  sqlite_free %request
  sqlite_close %db
  return %response
}

; FORMAT: /sqlprend test
; This alias is used to finish the potatorun, this will calculate who is all in the potatorun and who won or lost based on percentages
alias sqlprend {
  var %db = $sqlite_open(%testDB2)
  var %sql = SELECT * FROM prend
  var %request = $sqlite_query(%db,%sql)
  if (!%request) {
    echo %ec_error -a Error executing sqlprend query: %sqlite_errstr
  }
  else {
    while ($sqlite_fetch_row(%request,row)) {
      var %name = $hget(row,name)
      var %idUser = $hget(row,idUser)
      var %wager = $hget(row,wager)
      var %percent_low = $calc($hget(row,percent_low) * %wager + %wager)
      var %percent_high = $calc($hget(row,percent_high) * %wager + %wager)
      var %win_msg = $hget(row,win_msg)
      var %fail_msg = $hget(row,fail_msg)
      var %pramount = $rand(%percent_low,%percent_high)
      if (%sub = 1) {
        var %prsplit = 45
      }
      else {
        var %prsplit = 50
      }
      var %prsuccess = $rand(1,100)
      if (%prsuccess > %prsplit) {
        var %response = $+(%name,$chr(32),%win_msg,$chr(32),%pramount,$chr(32),potatoes.)
        ; msg %name --> %response
        var %msg = $addtok(%msg, -->,32)
          %msg = $addtok(%msg,%response,32)
        $jsonwhisper(%twuid,%msg,%name)
        var %prvictory = $+(%prvictory,$chr(126),%name,:,$chr(40),%pramount,$chr(41))
        ; This will pay out the winning amount to the user, it will be kept commented out for testing
        $sqlumodpvd(%name,+,%pramount,0,0)
      }
      else {
        var %response = $+(%name,$chr(32),%fail_msg)
        ; msg %name --> %response
        var %msg = $addtok(%msg, -->,32)
          %msg = $addtok(%msg,%response,32)
        $jsonwhisper(%twuid,%msg,%name)
        var %prfailure = $+(%prfailure,$chr(126),%name)
      }
    }
    var %response = PotatoRun Results [Followers of the Potato: $+($replace(%prvictory,~,$chr(32)),]) ---------- [Defiled peelings of Shade: $+($replace(%prfailure,~,$chr(32)),],.)
    if ($2) {
      echo %ec_succ -a ResponseEnd: %response
    }
    ; speak -l %response
    msg %mychan --> %response
    var %msg = $addtok(%msg, -->,32)
      %msg = $addtok(%msg,%response,32)
    $jsonwhisper(%twuid,%msg,%name)
    set %sql DELETE FROM PotatoRun
    if ($sqlite_exec(%db,%sql)) {
      echo %ec_succ -a PotatoRun table has been cleaned
    }
    else {
      echo %ec_error -a Error executing sqlprend Delete: %sqlite_errstr
    }
  }
  sqlite_free %request
  sqlite_close %db
}
  
; FORMAT: /sqlbirth
; Will select all names from todays date and then display them in the chat to
; report the birthdays of today.  While playing the !hbday command video.
; Current issue is that the year is not current year.  Need to filter that out
; Possibly use todays date throught script and the put it into query as a variable.
; Need a while statement to build the list of names to be presented
; '%06-14'
alias sqlbirth {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at db sqlbirth: %sqlite_errstr
  }
  else {
    var %name = $1
    var %curtime = $date(mm-dd)
    var %query = $qt($+(%,$sqlite_escape_string(%curtime)))
    echo %ec_succ -a Query: %query
    var %sql = SELECT name FROM user_info WHERE birthday LIKE %query
    var %request = $sqlite_query(%db,%sql)
    if (!%request) {
      echo %ec_error -a Error executing sqlbirth query: %sqlite_errstr
    }
    else {
      while ($sqlite_fetch_row(%request,row)) {
        var %bname = $hget(row,name)
        var %bnames = $+(%bnames,$chr(32),%bname)
        echo %ec_succ -a %bname
      }
      if (%bnames) {
        var %reply = %name $+ $chr(126) $+ %curtime $+ $chr(126) $+ Todays Happy Birthday wishes go to $+(%bnames,!!!!!!!)
      }
      else {
        var %reply = %name $+ $chr(126) $+ %curtime $+ $chr(126) $+ Sorry, No Birthdays to celebrate today.
      }
    }
  }
  echo %ec_succ -a Reply: %reply
  sqlite_free %request
  sqlite_close %db
  return %reply
}
  
; Format: /birthday username birthday
; (YYYY-MM-DD)
; User provides a birthday format if they wish to update it. Format is checked.
; Max allowed month is 12
; Max allowed year is 122 years old
; Max allowed day is 31
; Minimal age is %d1 which is currently at 18 years of age.
alias birthday {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at db birthday: %sqlite_errstr
  }
  else {
    var %name = $qt($sqlite_escape_string($1))
    if ($2) {
      var %checkm = $gettok($2,2,45)
      var %checky = $gettok($2,1,45)
      var %checkd = $gettok($2,3,45)
      var %d1 = $calc($asctime(yyyy)-18)
      var %d2 = $calc($asctime(yyyy)-122)
      if ((%checkm isnum 1-12) && (%checky < %d1) && (%checky > %d2) && (%checkd isnum 1-31)) {
        var %sql = UPDATE Info SET birthday = $qt($2) WHERE idUser = $&
          ( SELECT idUser FROM User WHERE name = %name )
        if ($sqlite_exec(%db,%sql)) {
          ; Indicates that the birthday was updated correctly.
          echo %ec_succ -a Number of rows affected: $sqlite_changes(%db)
          var %reply = Your birthday was updated to $+(",$2,"). $&
            If you wish to update it. Please type !birthday "YYYY-MM-DD" to update your birthday.
        }
        else {
          echo %ec_error -a Error executing birthday update: %sqlite_errstr
        }
      }
      else {
        msg $chan %name --> You did not provide a proper date.
      }
    }
    else {
      var %sql = SELECT birthday FROM user_info WHERE name = %name
      var %request = $sqlite_query(%db,%sql)
      if (!%request) {
        echo %ec_error -a Error executing birthday query: %sqlite_errstr
      }
      else {
        var %birthy = $sqlite_result(%request,birthday)
        if (%birthy == $null) {
          var %reply = You currently don't have a birthday set. $&
            Please type in !birthday "YYYY-MM-DD" to add your birthday.
        }
        else {
          var %reply = Your birthday is currently set to $+(",%birthy,"). $&
            If you wish to update it.  Please type in !birthday "YYYY-MM-DD" to update your birthday.
        }
      }
    }
  }
  sqlite_free %request
  sqlite_close %db
  return %reply
}

; Format: /linkdicksword (keyphrase)
; This alias is used to link the dicksword user id to the twitch user id
alias linkdicksword {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
      echo %ec_error -a Error at db linkdicksword: %sqlite_errstr
  }
  else {
    var %name = $qt($sqlite_escape_string($1))
    var %twitch_user_id = $jsongetuserid($1)
    var %keyphrase = $qt($2)
    var %sql = UPDATE Dicksword_assoc SET twitch_user_id = %twitch_user_id WHERE keyphrase = %keyphrase
    if ($sqlite_exec(%db,%sql)) {
        echo %ec_succ -a Number of rows affected: $sqlite_changes(%db)
        var %dicksword_response = %name your dicksword id has been linked to your twitch id.
    }
    else {
        echo %ec_error -a Error executing linkdicksword update : %sqlite_errstr
    }
  }
  sqlite_close %db
  return %dicksword_response
}

; Format: /sqlticketmod username +-*/ speech test
; This will add or subtract points/views from a viewer.
alias sqlticketmod {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at db sqlticketmod: %sqlite_errstr
  }
  else {
    if ($2 isin +-*/) {
      var %name = $qt($sqlite_escape_string($1))
      var %sql = UPDATE Stat SET speech = speech $2 $3 WHERE idUser = ( SELECT idUser FROM User WHERE name = %name )
      if ($sqlite_exec(%db, %sql)) {
        ; echo %ec_succ -a Number of rows affected: $sqlite_changes(%db)
      }
      else {
        echo %ec_error -a Error executing sqlticketmod update: %sqlite_errstr
      }
    }
  }
  sqlite_close %db
}

; Format: /sqltickettimer username
; This will add 1 test and speech ticket every 15 minutes
alias sqltickettimer {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at db sqltickettimer: %sqlite_errstr
  }
  else {
    var %name = $qt($sqlite_escape_string($1))
    var %sql = UPDATE Stat SET speech = speech + 1 WHERE idUser = ( SELECT idUser FROM User WHERE name = %name )
    if ($sqlite_exec(%db, %sql)) {
      ; echo %ec_succ -a Number of rows affected: $sqlite_changes(%db)
    }
    else {
      echo %ec_error -a Error executing sqltickettimer update: %sqlite_errstr
    }
  }
  sqlite_close %db
}

; FORMAT: /sqlmpadd username
; Adds user to the sqlite minipotato table
alias sqlmpadd {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at db sqlmpadd: %sqlite_errstr
  }
  else {
    var %name = $qt($sqlite_escape_string($1))
    set %sql $&
      INSERT INTO MiniPotato ( $&
      idUser $&
      ) VALUES ( $&
      ( SELECT idUser FROM User WHERE name = %name ) $&
      )
    echo -a %sql
    if ($sqlite_exec(%db,%sql)) {
      echo %ec_succ -a Query executed succesfully.
    }
    else {
      echo %ec_error -a Error executing sqlmpadd insert: %sqlite_errstr
      var %reply = Failed
    }
  }
  sqlite_close %db
  return %reply
}
  
  ;FORMAT: /sqlmppo username
  ; Pays out to the user that used the command based on their rowid
  ; Adds points to the Stats Table
  ; Adds counter to how many minipotato wins the user has had and what tier of a win
  ; When this system goes live.  I will need to purge the entries
alias sqlmppo {
  var %pamount = 10
  var %samount = 3
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at db sqlmppo: %sqlite_errstr
  }
  else {
    var %name = $qt($sqlite_escape_string($1))
    var %sql = SELECT rowid FROM MiniPotato $&
      WHERE idUser = ( SELECT idUser FROM User WHERE name = %name )
    var %request = $sqlite_query(%db,%sql)
    if (!%request) {
      echo %ec_error -a Error executing sqlmppo-SELECT query: %sqlite_errstr
    }
    else {
      var %rowid = $sqlite_result(%request,rowid)
      if (%rowid == 1) {
        var %m = 4
      }
      elseif (%rowid == 2) {
        var %m = 3
      }
      elseif (%rowid == 3) {
        var %m = 2
      }
      elseif (%rowid >= 4) {
        var %m = 1
      }
      var %tink = $+(mp_,%m,x)
      var %sql = UPDATE Stat SET %tink = %tink + 1 WHERE idUser = ( SELECT idUser FROM User WHERE name = %name )
      if ($sqlite_exec(%db,%sql)) {
        echo %ec_succ -a Number of rows affected: $sqlite_changes(%db)
      }
      else {
        echo %ec_error -a Error executing sqlmppo-Stat update: %sqlite_errstr
      }
      var %ptotal = $calc(%pamount * %m)
      var %stotal = $calc(%samount * %m)
      var %sql = UPDATE MiniPotato SET win_tier = %m $&
        WHERE idUser = ( SELECT idUser FROM User WHERE name = %name )
      if ($sqlite_exec(%db,%sql)) {
        echo %ec_succ -a Number of rows affected: $sqlite_changes(%db)
      }
      else {
        echo %ec_error -a Error executing sqlmppo-MiniPotato update: %sqlite_errstr
      }
      var %sql = UPDATE Stat SET $&
        points = points + %ptotal , speech = speech + %stotal $&
        WHERE idUser = ( SELECT idUser FROM User WHERE name = %name )
      if ($sqlite_exec(%db,%sql)) {
        echo %ec_succ -a Number of rows affected: $sqlite_changes(%db)
      }
      else {
        echo %ec_error -a Error executing sqlmppo-Points update: %sqlite_errstr
      }
      var %reply = $1 has received $+(%m,x) reward! %ptotal potatoes. %stotal tickets.
    }
  }
  echo %ec_succ -a sqlmppo %reply
  sqlite_free %request
  sqlite_close %db
  return %reply
}
  
; FORMAT: /sqlmpclean
; Should clean out the MiniPotato table.  So that new users can be put into it.
alias sqlmpclean {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at db sqlmpclean: %sqlite_errstr
  }
  else {
    set %sql DELETE FROM MiniPotato
    if ($sqlite_exec(%db,%sql)) {
      var %reply = MiniPotato table has been cleaned
    }
    else {
      echo %ec_error -a Error executing sqlmpclean delete: %sqlite_errstr
    }
  }
  echo %ec_succ -a %reply
  sqlite_close %db
  return %reply
}

alias mpstart {
  $wsobssetsceneip(MiniPotato,true,minipotato)
  msg %mychan MiniPotato sighted!!!!
}

; FORMAT: /sqlcheckcmd command table
; Used to get all of the information on a command within the Command DB Table.
alias sqlcheckcmd {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlcheckcmd db: %sqlite_errstr
  }
  else {
    var %cmd = $qt($sqlite_escape_string($1))
    var %sql = SELECT * FROM $2 WHERE name = %cmd
    var %request = $sqlite_query(%db,%sql)
    if (!%request) {
      echo %ec_error -a Error executing sqlcheckcmd query: %sqlite_errstr
    }
    else {
      if ($sqlite_num_rows(%request) isnum 1) {
        var %response = %request
        echo %ec_succ -a Response: %response
      }
      else {
        ; echo %ec_error -a Error at sqlcheckcmd check: $sqlite_num_rows(%request)
      }
    }
  }
  sqlite_close %db
  return %response
}

; FORMAT: /sqlpotatopick nickname points test
; Used to attempt to run a user through the potato pick and spit out a db backed response
; points is %p which is needed to identify current point count before subtraction
alias sqlpotatopick {
  var %db = $sqlite_open(%testDB2)
  if (!%db) {
    echo %ec_error -a Error at sqlpotatopick db: %sqlite_errstr
  }
  else {
    var %potatopick_points = $2
    var %sql = SELECT * FROM PotatoPick ORDER BY RANDOM() LIMIT 1
    var %request = $sqlite_query(%db,%sql)
    if (!%request) {
      echo %ec_error -a Error executing sqlpotatopick query: %sqlite_errstr
    }
    else {
      if ($sqlite_num_rows(%request) isnum 1) {
        var %success_stmt = $sqlite_result(%request,success)
        var %failure_stmt = $sqlite_result(%request,failure)
        var %hi_amt = $sqlite_result(%request,hi)
        ; Generate random amount between 2-1000
        var %amount = $rand(2,%hi_amt)
        ; Generate random change 1-10
        var %success_chance = $rand(1,10)
        if (%success_chance isnum 6-10) {
          ; Add amount to user balance
          $sqlumodpvd($nick, +, %amount, 0, 0)
          var %response = $+(%success_stmt,$chr(32),[,%amount,],$chr(32),potatoes.)
        }
        elseif (%success_chance isnum 1-5) {
          ; Balance protection to prevent over subtracting
          if (%potatopick_points <= %amount) {
            %amount = %potatopick_points
          }
          ; Subtract amount from user balance
          $sqlumodpvd($nick, -, %amount, 0, 0)
          var %response = $+(%failure_stmt,$chr(32),[,%amount,],$chr(32),potatoes.)
        }
        if ($3) {
          echo %ec_debug -a %success_chance
          echo %ec_succ -a Response: %response
        }
      }
    }
  }
  sqlite_free %request
  sqlite_close %db
  return %response
}















; FORMAT: /modkill {number}
; Sets the kills to the number provided
alias modkill {
  set %kills $1
  var %kdr $calc(%kills / %deaths)
  msg $chan $nick --> Modified Kills to %kills
}

; FORMAT: /moddeath {number}
; Sets the deaths to the number provided
alias moddeath {
  set %deaths $1
  var %kdr $calc(%kills / %deaths)
  msg $chan $nick --> Modified Deaths to %deaths
}

alias kdrtest {
  var %kdr $calc(%kills / %deaths)
  window -bn @kdr
  echo @kdr 8--------------------------------
  echo @kdr 9KILLS:   %kills
  echo @kdr 4DEATHS: %deaths
  echo @kdr 11KDR:    %kdr
  echo @kdr 8--------------------------------
}