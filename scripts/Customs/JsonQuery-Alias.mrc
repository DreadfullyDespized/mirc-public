/*
JSON QUERY TWITCH API INFO:
  800 points per minute rate limit.
  When Pulling Information you can pull up to 100 in a single pull
*/



; Format: /jsonwhisper ID Message Nickname
; Should send a whisper message to the user id specified.
alias jsonwhisper {
  if ($json(jsonwhisper)) {
    JSONClose jsonwhisper
  }
  var %target $1
  var %tmessage $2
  var %nickname $3
  echo %ec_debug -s --Whisper--: $+(%target,$chr(32),|,$chr(32),%nickname,$chr(32),-,$chr(32),%tmessage)
  var %whisp = https://api.twitch.tv/helix/whispers?from_user_id= $+ %botid $+ $chr(38) $+ to_user_id= $+ %target
  JSONOpen -duw jsonwhisper %whisp
  JSONHttpMethod jsonwhisper POST
  if ($JSONError) {
    echo %ec_error -a JSONOpen Error jsonwhisper: $v1
    JSONClose jsonwhisper
    return
  }
  JSONHttpHeader jsonwhisper Client-ID %clientid
  JSONHttpHeader jsonwhisper Authorization Bearer %oauthtoken
  if ($JSONError) {
    echo %ec_error -a JSON Header Error jsonwhisper: $v1
    JSONClose jsonwhisper
    return
  }
  ; This sends the joined message requirement
  JSONHttpFetch jsonwhisper message= $+ %tmessage
  ; if ($JSONError) {
  ;   echo %ec_error -a JSON Fetch Error jsonwhisper: $v1
  ;   JSONClose jsonwhisper
  ;   return
  ; }
  JSONClose jsonwhisper
  return
}

; Format: /jsonshoutout nickname test
; Should send a shoutout for the user specified.
; This will only work if the broadcaster is live and has at least 1 viewer.
; Test is an optional parameter to display debug information.
alias jsonshoutout {
  if ($json(jsonshoutout)) JSONClose jsonshoutout
  
  var %nick = $1
  var %soid = $jsongetuserid(%nick)
  if (!%soid) {
    echo %ec_error -a Unable to get user ID for %nick
    return Failed: Could not find user %nick
  }
  
  ; Validate required IDs
  if (!%twstreamid) {
    echo %ec_error -a Missing broadcaster ID
    return Failed: Broadcaster ID not configured
  }
  if (!%botid) {
    echo %ec_error -a Missing moderator ID
    return Failed: Moderator ID not configured
  }
  
  ; Check if broadcaster is live first
  JSONOpen -uw jsonshoutout https://api.twitch.tv/helix/streams?user_id= $+ %soid
  JSONHttpHeader jsonshoutout Client-ID %clientid
  JSONHttpHeader jsonshoutout Authorization Bearer %oauthtoken
  JSONHttpFetch jsonshoutout
  
  if ($JSONError) {
    echo %ec_error -a Stream Check Error: $v1
    JSONClose jsonshoutout
    return Failed: Error checking stream status - $v1
  }
  
  var %is_live = $json(jsonshoutout,data,0,type).string
  var %viewers = $iif($json(jsonshoutout,data,0,viewer_count).value isnum,$v1,0)
  
  ;if (%is_live != live || %viewers < 1) {
  if (%viewers < 1) {
    echo %ec_error -a Cannot send shoutout: Channel must be live with at least 1 viewer
    if ($2 == test) {
      echo %ec_debug -a is_live: $iif(%is_live,%is_live,Offline) - viewer_count: %viewers
    }
    JSONClose jsonshoutout
    return Failed: Channel must be live with at least 1 viewer (Current: $iif(%is_live,%is_live,Offline) - %viewers viewers)
  }
  
  ; Proceed with shoutout
  JSONClose jsonshoutout
  var %url = https://api.twitch.tv/helix/chat/shoutouts
  var %params = from_broadcaster_id= $+ %twstreamid $+ &to_broadcaster_id= $+ %soid $+ &moderator_id= $+ %botid
  
  JSONOpen -duw jsonshoutout %url $+ ? $+ %params
  JSONHttpMethod jsonshoutout POST
  JSONHttpHeader jsonshoutout Client-ID %clientid
  JSONHttpHeader jsonshoutout Authorization Bearer %oauthtoken
  JSONHttpHeader jsonshoutout Content-Type application/json
  JSONHttpFetch jsonshoutout
  
  if ($JSONError) {
    echo %ec_error -a JSON Error: $v1
    JSONClose jsonshoutout
    return Failed: JSON processing error - $v1
  }
  
  var %status_code = $json(jsonshoutout).HttpStatus
  var %response = $json(jsonshoutout).HttpBody
  
  if (%status_code == 204) {
    var %status = Shoutout to %nick successfully sent!
  }
  elseif (%status_code == 400) {
    var %error_message = $json(jsonshoutout,error).string
    var %error_detail = $json(jsonshoutout,message).string
    echo %ec_error -a Bad Request: %error_message - %error_detail
    echo %ec_error -a Params: %params
    var %status = Failed: %error_message - %error_detail
  }
  elseif (%status_code == 401) {
    echo %ec_error -a Authentication Error: Check OAuth token/scope
    var %status = Failed: Authentication error - Check bot credentials
  }
  elseif (%status_code == 403) {
    echo %ec_error -a Forbidden: Bot lacks moderator permissions
    var %status = Failed: Bot lacks moderator permissions
  }
  elseif (%status_code == 429) {
    echo %ec_error -a Rate Limit Exceeded
    var %status = Failed: Rate limit exceeded - Try again later
  }
  else {
    echo %ec_error -a Unexpected Status: %status_code - %response
    var %status = Failed: Unexpected error (Status: %status_code)
  }
  
  if ($2 == test) {
    echo %ec_debug -a URL: %url $+ ? $+ %params
    echo %ec_debug -a Status: %status_code
    echo %ec_debug -a Response: %response
    echo %ec_debug -a Live Status: %is_live - Viewers: %viewers
  }
  
  JSONClose jsonshoutout
  return %status
}

; Format: /jsongetmods
; Should pull a json list of all moderators for the channel
alias jsongetmods {
  if ($json(jsongetmods)) {
    JSONClose jsongetmods
  }
  JSONOpen -duw jsongetmods https://api.twitch.tv/helix/moderation/moderators?broadcaster_id= $+ %twstreamid
  if ($JSONError) {
    echo %ec_error -a JSONOpen Error jsongetmods: $v1
  }
  JSONHttpHeader jsongetmods Client-ID %clientid
  JSONHttpHeader jsongetmods Authorization Bearer %streamer_oauthtoken
  if ($JSONError) {
    echo %ec_error -a JSON Header Error jsongetmods: $v1
    JSONClose jsongetmods
    return
  }
  JSONHttpFetch jsongetmods
  if ($JSONError) {
    echo %ec_error -a JSON Fetch Error jsongetmods: $v1
    JSONClose jsongetmods
    return
  }
  ; echo %ec_supp -a $json(jsongetmods).HttpBody

  ; Grabs the querable length of the json object
  var %modcount = $json(jsongetmods,data).length - 1
  ; echo %ec_debug -a Mod Count: %modcount
  
  var %moddata = $json(jsongetmods,data)
  if (%moddata != $null) {
    ; Successful response: two-way sync. Clear stale flags first so
    ; demodded users stop getting the mod bonus, then set the current list.
    ; The data-array guard means a failed API call can never wipe flags.
    var %cdb = $sqlite_open(%testDB2)
    if (%cdb) {
      if ($sqlite_exec(%cdb,UPDATE Info SET is_moderator = 0 WHERE is_moderator != 0)) {
        echo %ec_debug -a Mod sync: cleared stale is_moderator flags
      }
      else {
        echo %ec_error -a Mod sync clear failed: $sqlite_errstr
      }
      sqlite_close %cdb
    }
    noop $JSONForEach(%moddata, makeitwork)
  }
  else {
    echo %ec_error -a jsongetmods: no data array in response, keeping existing mod flags
  }
  JSONClose jsongetmods
  return
}

; Format /makeitwork JSONData
; This is to be used with a JSONForEach statement to parse the loopable data.
; This will update the moderators per the list of mods that twitch has.
; jsongetmods clears stale flags before this loop, so the sync is two-way.
alias makeitwork {
  var %tw_user_id = $remove($json($1, user_id).string,$chr(34))
  var %tw_user_login = $remove($json($1, user_login).string,$chr(34))
  $sqlumod(%tw_user_login,is_moderator,1)
}

; Format: /jsongetprediction predictionID
; Should pull prediction information of the stream
alias jsongetprediction {
  if ($json(jsongetprediction)) {
    JSONClose jsongetprediction
  }
  ; Prediction ID if presented to filter
  var %pred_id = $1
  var %predict_data = https://api.twitch.tv/helix/predictions?broadcaster_id= $+ %twstreamid $+ $chr(38) $+ first=1
  if ($1) {
    var %predict_data = https://api.twitch.tv/helix/predictions?broadcaster_id= $+ %twstreamid $+ $chr(38) $+ id= $+ %pred_id
  }
  JSONOpen -duw jsongetprediction %predict_data
  if ($JSONError) {
    echo %ec_error -a JSONOpen Error jsongetprediction: $v1
    JSONClose jsongetprediction
    return
  }
  JSONHttpHeader jsongetprediction Client-ID %clientid
  JSONHttpHeader jsongetprediction Authorization Bearer %streamer_oauthtoken
  JSONHttpHeader jsongetprediction Content-Type application/json
  if ($JSONError) {
    echo %ec_error -a JSON Header Error jsongetprediction: $v1
    JSONClose jsongetprediction
    return
  }
  JSONHttpFetch jsongetprediction
  echo %ec_debug -s $json(jsongetprediction).HttpBody
  echo %ec_debug -s $json(jsongetprediction).HttpResponse
  JSONClose jsongetprediction
  return
}

; Format: /jsonchatanno color message
; This should show an announcement on the chat for the stream.
alias jsonchatanno {
  if ($json(jsonchatanno)) {
    JSONClose jsonchatanno
  }
  var %color = $1
  var %message = $2-
  JSONOpen -duw jsonchatanno https://api.twitch.tv/helix/chat/announcements?broadcaster_id= $+ %twstreamid $+ $chr(38) $+ moderator_id= $+ %botid
  JSONHttpMethod jsonchatanno POST
  if ($JSONError) {
    echo %ec_error -a JSONOpen Error jsonchatanno: $v1
    JSONClose jsonchatanno
    return
  }
  JSONHttpHeader jsonchatanno Client-ID %clientid
  JSONHttpHeader jsonchatanno Authorization Bearer %oauthtoken
  JSONHttpHeader jsonchatanno Content-Type application/json
  if ($JSONError) {
    echo %ec_error -a JSON Header Error jsonchatanno: $v1
    JSONClose jsonchatanno
    return
  }
  JSONHttpFetch jsonchatanno {"message": " $+ %message $+ ", "color": " $+ %color $+ "}
  ; if ($JSONError) {
  ;   echo %ec_error -a JSON Fetch Error jsonchatanno: $v1
  ;   JSONClose jsonchatanno
  ;   return
  ; }
  echo %ec_debug -s $json(jsonchatanno).HttpBody
  echo %ec_debug -s $json(jsonchatanno).HttpResponse
  JSONClose jsonchatanno
  return
}

; Format: /jsonclearchat
; Should clear the entire twitch chat.
alias jsonclearchat {
  if ($json(jsonclearchat)) {
    JSONClose jsonclearchat
  }
  JSONOpen -duw jsonclearchat https://api.twitch.tv/helix/moderation/chat?broadcaster_id= $+ %twstreamid $+ $chr(38) $+ moderator_id= $+ %botid
  JSONHttpMethod jsonclearchat DELETE
  if ($JSONError) {
    echo %ec_error -a JSONOpen Error jsonclearchat: $v1
    JSONClose jsonclearchat
    return
  }
  JSONHttpHeader jsonclearchat Client-ID %clientid
  JSONHttpHeader jsonclearchat Authorization Bearer %oauthtoken
  if ($JSONError) {
    echo %ec_error -a JSON Header Error jsonclearchat: $v1
    JSONClose jsonclearchat
    return
  }
  JSONHttpFetch jsonclearchat
  ; if ($JSONError) {
  ;   echo %ec_error -a JSON Fetch Error jsonclearchat: $v1
  ;   JSONClose jsonclearchat
  ;   return
  ; }
  JSONClose jsonclearchat
  return
}

; Format: /jsonlf
; Grabs the latest follower of my channel: displayname, id, notification settings
alias jsonlf {
  if ($json(test)) {
    JSONClose test
  }
  JSONOpen -uw test https://api.twitch.tv/helix/users/follows?to_id= $+ %twstreamid $+ &first=1
  if ($JSONError) {
    echo %ec_error -a JSONOpen Error jsonlf: $v1
    JSONClose test
    return
  }
  JSONHttpHeader test Client-ID %clientid
  JSONHttpHeader test Authorization Bearer %oauthtoken
  if ($JSONError) {
    echo %ec_error -a JSON Header Error jsonlf: $v1
    JSONClose test
    return
  }
  JSONHttpFetch test
  if ($JSONError) {
    echo %ec_error -a JSON Fetch Error jsonlf: $v1
    JSONClose test
    return
  }
  echo %ec_supp -a $json(test).HttpBody
  var %testy = $readini($+(%dataSet,mIRCFiles\follower.ini),n,LatestFollow,lfid)
  var %lfname = $json(test,data,0,from_name).value
  var %lfid = $json(test,data,0,from_id).value
  var %followedat = $json(test,data,0,followed_at).value
  if (%testy == %lfid) {
    ; echo %ec_succ %test == %lfid
  }
  else {
    ; Add 10 potatoes for following the channel
    $sqlumodpvd(%lfname,+,10)
    writeini -n $+(%dataSet,mIRCFiles\follower.ini) LatestFollow lfdn %lfname
    writeini -n $+(%dataSet,mIRCFiles\follower.ini) LatestFollow lfid %lfid
    writeini -n $+(%dataSet,mIRCFiles\follower.ini) LatestFollow lastupdated $asctime(yyyy-mm-dd-HH:nn:ss)
  }
  JSONClose test
  return
}

; Format: /jsontest
; Tests to see if json is functioning. grabs basic channel info from my channel id
alias jsontest {
  if ($json(jsontest)) {
    JSONClose jsontest
  }
  JSONOpen -uw jsontest https://api.twitch.tv/helix/channels?broadcaster_id= $+ %twstreamid
  if ($JSONError) {
    echo %ec_error -a JSONOpen Error jsontest: $v1
    JSONClose jsontest
    return
  }
  JSONHttpHeader jsontest Client-ID %clientid
  JSONHttpHeader jsontest Authorization Bearer %oauthtoken
  if ($JSONError) {
    echo %ec_error -a JSON Header Error jsontest: $v1
    JSONClose jsontest
    return
  }
  JSONHttpFetch jsontest
  if ($JSONError) {
    echo %ec_error -a JSON Fetch Error jsontest: $v1
    JSONClose jsontest
    return
  }
  ; The following data points come from the channel information
  set %streamgame $json(jsontest,data,0,game_name).value
  set %title $json(jsontest,data,0,title).value
  JSONClose jsontest
  if ($JSON(jsontest)) {
    JSONClose jsontest
  }

  JSONOpen -uw jsontest https://api.twitch.tv/helix/follows?to_id= $+ %twstreamid
  if ($JSONError) {
    echo %ec_error -a JSONOpen Error jsontest: $v1
    JSONClose jsontest
    return
  }
  JSONHttpHeader jsontest Client-ID %clientid
  JSONHttpHeader jsontest Authorization Bearer %oauthtoken
  if ($JSONError) {
    echo %ec_error -a JSON Header Error jsontest: $v1
    JSONClose jsontest
    return
  }
  JSONHttpFetch jsontest
  if ($JSONError) {
    echo %ec_error -a JSON Fetch Error jsontest: $v1
    JSONClose jsontest
    return
  }
  ; The following data points came from the follows information
  set %streamfollowers $json(jsontest,data,0,total).value
  JSONClose jsontest
  if ($JSON(test)) {
    JSONClose jsontest
  }

  JSONOpen -uw jsontest https://api.twitch.tv/helix/users?id= $+ %twstreamid
  if ($JSONError) {
    echo %ec_error -a JSONOpen Error jsontest: $v1
    JSONClose jsontest
    return
  }
  JSONHttpHeader jsontest Client-ID %clientid
  JSONHttpHeader jsontest Authorization Bearer %oauthtoken
  if ($JSONError) {
    echo %ec_error -a JSON Header Error jsontest: $v1
    JSONClose jsontest
    return
  }
  JSONHttpFetch jsontest
  if ($JSONError) {
    echo %ec_error -a JSON Fetch Error jsontest: $v1
    JSONClose jsontest
    return
  }
  ; The following data points came from the users information
  set %streamviews $json(jsontest,data,0,view_count).value
  var %wonky = $json(jsontest,data,0,created_at).value
  var %year = $left(%wonky, 4)
  var %month = $mid(%wonky, 6, 2)
  var %day = $mid(%wonky, 9, 2)
  set %streamcreated $+(%year,-,%month,-,%day)
  JSONClose jsontest
  if ($JSON(jsontest)) {
    JSONClose jsontest
  }

  JSONOpen -uw jsontest https://api.twitch.tv/helix/streams?user_id= $+ %twstreamid
  if ($JSONError) {
    echo %ec_error -a JSONOpen Error jsontest: $v1
    JSONClose jsontest
    return
  }
  JSONHttpHeader jsontest Client-ID %clientid
  JSONHttpHeader jsontest Authorization Bearer %oauthtoken
  if ($JSONError) {
    echo %ec_error -a JSON Header Error jsontest: $v1
    JSONClose jsontest
    return
  }
  JSONHttpFetch jsontest
  if ($JSONError) {
    echo %ec_error -a JSON Fetch Error jsontest: $v1
    JSONClose jsontest
    return
  }
  ; The following data points come from the stream information
  ; Checks to see if a stream exists or not
  set %streamstatus $json(jsontest,data,0,id).value
  if (!%streamstatus) {
    echo %ec_error -a Unable to find Twitch Stream ID : $v1
    echo %ec_succ -a %streamgame - %streamfollowers - %streamviews - %streamcreated
    JSONClose jsontest
    return
  }
  echo %ec_succ -a %streamstatus - %streamgame - %streamfollowers - %streamviews - %streamcreated - %title
  JSONClose jsontest
  return
}

; Format: /jsonname userid
; Provide the twitch_user_id to then get the users name from json data
alias jsonname {
  if ($JSON(test)) {
    JSONClose test
  }
  JSONOpen -uw test https://api.twitch.tv/helix/users?id= $+ $1
  if ($JSONError) {
    echo %ec_error -a JSONOpen Error jsonname: $v1
    JSONClose test
    return
  }
  JSONHttpHeader test Client-ID %clientid
  JSONHttpHeader test Authorization Bearer %oauthtoken
  if ($JSONError) {
    echo %ec_error -a JSON Header Error jsonname: $v1
    JSONClose test
    return
  }
  JSONHttpFetch test
  if ($JSONError) {
    echo %ec_error -a JSON Fetch Error jsonname: $v1
    JSONClose test
    return
  }
  var %name = $json(test,data,0,login).value
  if (!%name) {
    echo %ec_error -a JSON Twitch User ID Not Found jsonname : $v1
    JSONClose test
    return
  }
  echo %ec_succ -a %name
  JSONClose test
  return %name
}

; Format: /jsongetuserid username test
; Displays the userid of the user in question using HELIX
alias jsongetuserid {
  if ($JSON(userid)) {
    JSONClose userid
  }
  var %name = $1
  JSONOpen -uw userid https://api.twitch.tv/helix/users?login= $+ %name
  if ($JSONError) {
    echo %ec_error -a JSONOpen Error jsongetuserid: $v1
    JSONClose userid
    return
  }
  JSONHttpHeader userid Client-ID %clientid
  JSONHttpHeader userid Authorization Bearer %oauthtoken
  if ($JSONError) {
    echo %ec_error -a JSON Header Error jsongetuserid: $v1
    JSONClose userid
    return
  }
  JSONHttpFetch userid
  if ($JSONError) {
    echo %ec_error -a JSON Fetch Error jsongetuserid: $v1
    JSONClose userid
    return
  }
  ; echo %ec_supp -a $json(userid).HttpBody
  var %userid = $json(userid,data,0,id).value
  if ($2) {
    echo %ec_succ -a %userid
  }
  JSONClose userid
  if (%userid) {
    return %userid
  }
  else {
    ; echo %ec_error -a $1 was not found on twitch
  }
}

;Format: /jsont
;Checks if the stream is online or offline and reports it
alias jsont {
  if ($JSON(test)) {
    JSONClose test
  }
  var %name = $1
  var %uid = $jsongetuserid(%name)
  JSONOpen -uw test https://api.twitch.tv/helix/streams?user_id= $+ %uid
  if ($JSONError) {
    echo %ec_error -a JSONOpen Error jsont: $v1
    JSONClose test
    return
  }
  JSONHttpHeader test Client-ID %clientid
  JSONHttpHeader test Authorization Bearer %oauthtoken
  if ($JSONError) {
    echo %ec_error -a JSON Header Error jsont: $v1
    JSONClose test
    return
  }
  JSONHttpFetch test
  if ($JSONError) {
    echo %ec_error -a JSON Fetch Error jsont: $v1
    JSONClose test
    return
  }
  ; echo %ec_supp -a $json(test).HttpBody
  var %id = $json(test,data,0,id).value
  if (!%id) {
    var %status = OFFLINE
  }
  elseif (%id) {
    var %status = ONLINE
  }
  JSONClose test
  ; echo %ec_succ -a %status
  return %status
}

;Format: /jsonuptime streamername
;Displays the uptime for the stream specified.
alias jsonuptime {
  if ($JSON(jsonuptime)) {
    JSONClose jsonuptime
  }
  var %caster = $1
  var %userid = $jsongetuserid(%caster)
  JSONOpen -uw jsonuptime https://api.twitch.tv/helix/streams?user_id= $+ %userid
  if ($JSONError) {
    echo %ec_error -a JSONOpen Error jsonuptime: $v1
    JSONClose jsonuptime
    return
  }
  JSONHttpHeader jsonuptime Client-ID %clientid
  JSONHttpHeader jsonuptime Authorization Bearer %oauthtoken
  if ($JSONError) {
    echo %ec_error -a JSON Header Error jsonuptime: $v1
    JSONClose jsonuptime
    return
  }
  JSONHttpFetch jsonuptime
  if ($JSONError) {
    echo %ec_error -a JSON Fetch Error jsonuptime: $v1
    JSONClose jsonuptime
    return
  }
  var %id = $json(jsonuptime,data,0,id).value
  if (!%id) {
    var %status = %caster is currently OFFLINE.
    ; echo -a %status
     return %status
  }
  var %created = $json(jsonuptime,data,0,started_at).value
  var %start = $ctime($remove($replace(%created,T,$chr(32)),Z))
  var %uptime = $duration($calc($gmt - %start))
  var %status = %caster :: Stream has been online for :: %uptime
  echo %ec_succ -a 11 %caster 8 :: 11 Stream has been online for 8 :: 7 %uptime
  JSONClose jsonuptime
  return %status
}


; Format: /created username
; Pulls the created_at date from the users account
alias jsoncreated {
  if ($JSON(jsoncreated)) {
    JSONClose jsoncreated
  }
  var %caster = $1
  var %uid = $jsongetuserid(%caster)
  JSONOpen -uw jsoncreated https://api.twitch.tv/helix/users?id= $+ %uid
  if ($JSONError) {
    echo %ec_error -a JSONOpen Error jsoncreated: $v1
    JSONClose jsoncreated
    return
  }
  JSONHttpHeader jsoncreated Client-ID %clientid
  JSONHttpHeader jsoncreated Authorization Bearer %oauthtoken
  if ($JSONError) {
    echo %ec_error -a JSON Header Error jsoncreated: $v1
    JSONClose jsoncreated
    return
  }
  JSONHttpFetch jsoncreated
  if ($JSONError) {
    echo %ec_error -a JSON Fetch Error jsoncreated: $v1
    JSONClose jsoncreated
    return
  }
  ; echo %ec_supp -a $json(jsoncreated).HttpBody
  var %wonky = $json(jsoncreated,data,0,created_at).value
  var %followedyear = $left(%wonky, 4)
  var %followedmonth = $mid(%wonky, 6, 2)
  var %followedday = $mid(%wonky, 9, 2)
  var %start $ctime($remove($replace(%wonky,T,$chr(32)),Z))
  var %duration $duration($calc($gmt - %start))
  if (%wonky) {
    var %userdata = %followedmonth $+ $chr(126) $+ %followedday $+ $chr(126) $+ %followedyear $+ $chr(126) $+ %duration
  }
  JSONClose jsoncreated
  echo %ec_succ -a %userdata
  return %userdata
}

; Format: /jsonhighlight username message
; Will create a highlight with the date,time,uptime,points,etc
; Currently works with the DB and the TotalHighlights trigger
alias jsonhighlight {
  if ($JSON(jsonhighlight)) {
    JSONClose jsonhighlight
  }
  var %name = $1
  var %msg = $2-
  JSONOpen -uw jsonhighlight https://api.twitch.tv/helix/streams?user_id= $+ %twstreamid
  JSONHttpHeader jsonhighlight Client-ID %clientid
  JSONHttpHeader jsonhighlight Authorization Bearer %oauthtoken
  if ($JSONError) {
    echo %ec_error -a JSON Header Error jsonhighlight: $v1
    JSONClose jsonhighlight
    return
  }
  JSONHttpFetch jsonhighlight
  if ($JSONError) {
    echo %ec_error -a JSON Fetch Error jsonhighlight: $v1
    JSONClose jsonhighlight
    return
  }
  ; echo %ec_supp -a $json(jsonhighlight).HttpBody
  var %id $json(jsonhighlight,data,0,id).value
  if (!%id) {
    var %status = [DreadfullyDespized] is currently [OFFLINE].
    ; echo -a %status
    splay %sounds $+ death.mp3
    return %status
  }
  var %created = $json(jsonhighlight,data,0,started_at).value
  var %game = $json(jsonhighlight,data,0,game_name).value
  var %start = $ctime($remove($replace(%created,T,$chr(32)),Z))
  var %uptime = $duration($calc($gmt - %start),3)
  splay %sounds $+ baymax1.mp3
  echo -a 11 %name 8 :: 11 Highlight created 8 :: 7 %uptime
  var %points = $rand(1,10)
  $sqlhighlight(%name,$asctime(mm/dd/yyyy),$time,%uptime,%msg,%points,%game)
  var %status =  Highlight requested by %name $+ $chr(46) Rewarded $iif(%points > 1,%points potatoes, %points potato).
  JSONClose jsonhighlight
  echo -a %status
  return %status
}

; Format: /jsonlh
; Pulls the latest highlight from my stream
alias jsonlh {
  if ($JSON(jsonlh)) {
    JSONClose jsonlh
  }
  JSONOpen -uw jsonlh https://api.twitch.tv/helix/videos?user_id= $+ %twstreamid $+ &first=1&type=highlight
  JSONHttpHeader jsonlh Client-ID %clientid
  JSONHttpHeader jsonlh Authorization Bearer %oauthtoken
  if ($JSONError) {
    echo %ec_error -a JSON Header Error jsonlh: $v1
    JSONClose jsonlh
    return
  }
  JSONHttpFetch jsonlh
  if ($JSONError) {
    echo %ec_error -a JSON Fetch Error jsonlh: $v1
    JSONClose jsonlh
    return
  }
  ; echo %ec_supp -a $json(jsonlh).HttpBody
  var %name = $json(jsonlh,data,0,user_name).value
  var %title = $json(jsonlh,data,0,title).value
  var %url = $json(jsonlh,data,0,url).value
  var %count = $json(jsonlh,data,0,view_count).value
  var %created = $json(jsonlh,data,0,created_at).value
  var %published = $json(jsonlh,data,0,published_at).value
  var %duration = $json(jsonlh,data,0,duration).value
  if (%name) {
    %userdata = %name $+ $chr(126) $+ %title $+ $chr(126) $+ %url $+ $chr(126) $+ %count $+ $chr(126) $+ %created $+ $chr(126) $+ %published $+ $chr(126) $+ %duration
  }
  echo %ec_succ -a %userdata
  return %userdata
  JSONClose jsonlh
}

}