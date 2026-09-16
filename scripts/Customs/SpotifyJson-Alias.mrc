; Helper alias to check token validity
alias spotify_token_valid { return $iif(!%spotify_token || $ctime >= %spotify_token_expires, $false, $true) }
alias spotify_oauth_token_valid { 
  if (!%spotify_access_token) { return $false }
  if ($ctime >= %spotify_token_expires) { return $false }
  return $true 
}

; Main authorization alias
alias spotify_auth {
  var %auth_string = $+(%spot_cl,:,%spot_sec)
  var %encoded_auth = $encode(%auth_string, m)
  
  JSONOpen -duw spotify https://accounts.spotify.com/api/token
  JSONHttpMethod spotify POST
  JSONHttpHeader spotify Authorization Basic %encoded_auth
  JSONHttpHeader spotify Content-Type application/x-www-form-urlencoded
  JSONHttpFetch spotify grant_type=client_credentials
  
  if ($JSONError) {
    echo %ec_error -a Request Error: $v1
    JSONClose spotify
    return
  }
  
  set %spotify_token $remove($json(spotify,access_token).string,")
  set %spotify_token_type $remove($json(spotify,token_type).string,")
  set %spotify_token_expires $calc($ctime + $json(spotify,expires_in).value)
  
  echo %ec_succ -a Auth Token Obtained
  JSONClose spotify
}

; Current track display alias
alias spotify_current_track {
  if (!$spotify_oauth_token_valid) {
    echo %ec_error -a OAuth token expired or missing. Run /spotify_setup_oauth
    return
  }
  
  ; Create the HTTP request
  JSONOpen -duw spotifyCurrentTrack https://api.spotify.com/v1/me/player/currently-playing
  JSONHttpHeader spotifyCurrentTrack Authorization Bearer $remove(%spotify_access_token,")
  JSONHttpFetch spotifyCurrentTrack
  
  if ($1 == test) {
    echo %ec_debug -a Token used: $remove(%spotify_access_token,")
    echo %ec_debug -a Response: $json(spotifyCurrentTrack).HttpBody
  }
  
  ; Check for empty response or no content first
  if ($JSON(spotifyCurrentTrack).HttpStatus == 204) {
    echo %ec_debug -a No track currently playing
    JSONClose spotifyCurrentTrack
    return
  }
  
  ; Check for JSON errors after confirming response exists
  if ($JSONError) {
    echo %ec_error -a No active playback session
    JSONClose spotifyCurrentTrack
    return
  }
  
  if ($json(spotifyCurrentTrack,error)) {
    echo %ec_error -a API Error: $json(spotifyCurrentTrack,error,message).string
    JSONClose spotifyCurrentTrack
    return
  }
  
  var %track = $remove($json(spotifyCurrentTrack,item,name).string,")
  var %artist = $remove($json(spotifyCurrentTrack,item,artists,0,name).string,")
  var %album = $remove($json(spotifyCurrentTrack,item,album,name).string,")
  var %prog = $calc($json(spotifyCurrentTrack,progress_ms).value / 1000)
  var %dur = $calc($json(spotifyCurrentTrack,item,duration_ms).value / 1000)
  
  echo %ec_succ -a Currently Playing:
  echo %ec_debug -a Track: %track
  echo %ec_debug -a Artist: %artist
  echo %ec_debug -a Album: %album
  echo %ec_debug -a Status: $iif($json(spotifyCurrentTrack,is_playing).value,Playing,Paused)
  echo %ec_debug -a Time: $duration(%prog) / $duration(%dur)
  
  JSONClose spotifyCurrentTrack
}

; Add new formatting alias
alias spotify_format_song {
  ; Check and handle OAuth token
  if (!$spotify_oauth_token_valid) {
    echo %ec_debug -a Token expired, attempting refresh...
    if (!$spotify_refresh_token) {
      echo %ec_error -a No refresh token available, running OAuth setup
      spotify_setup_oauth
      return No Song Playing
    }
    
    ; Attempt token refresh
    if (!$spotify_refresh_token) {
      spotify_setup_oauth
      return No Song Playing
    }
  }
  
  ; Continue with existing functionality
  JSONOpen -duw spotifyFormatSong https://api.spotify.com/v1/me/player/currently-playing
  JSONHttpHeader spotifyFormatSong Authorization Bearer $remove(%spotify_access_token,")
  JSONHttpFetch spotifyFormatSong
  
  if ($JSONError || $JSON(spotifyFormatSong).HttpStatus == 204) {
    JSONClose spotifyFormatSong
    return No Song Playing
  }
  
  var %track = $remove($json(spotifyFormatSong,item,name).string,")
  var %artist = $remove($json(spotifyFormatSong,item,artists,0,name).string,")
  var %album = $remove($json(spotifyFormatSong,item,album,name).string,")
  
  ; Format the song string // made on 11/13/2025, will need to check next stream entry to validate
  var %song = $chr(39) $+ %track $+ $chr(39) $+ - $+ $chr(39) $+ %artist $+ $chr(39) $+ - $+ $chr(39) $+ %album $+ $chr(39)
  echo %ec_debug -a Formatted: %song
  
  JSONClose spotifyFormatSong
  return %song
}

; OAuth setup alias
alias spotify_setup_oauth {
  ; Close any existing sockets first
  sockclose spotify_oauth_server
  sockclose spotify_oauth_callback
  
  var %url = https://accounts.spotify.com/authorize?client_id= $+ %spot_cl
  var %url = %url $+ &response_type=code&redirect_uri=http://127.0.0.1:8888/callback
  var %url = %url $+ &scope=user-read-currently-playing
  
  socklisten spotify_oauth_server 8888
  run $qt(%url)
  echo %ec_debug -a Waiting for callback...
}

; Modify OAuth token exchange to prevent window creation
alias spotify_oauth_token {
  ; Process token exchange
  var %auth = $encode($+(%spot_cl,:,%spot_sec),m)
  var %body = grant_type=authorization_code&code= $+ $1 $+ &redirect_uri=http://127.0.0.1:8888/callback
  
  JSONOpen -duw spotify_oauth https://accounts.spotify.com/api/token
  JSONHttpMethod spotify_oauth POST
  JSONHttpHeader spotify_oauth Authorization Basic %auth
  JSONHttpHeader spotify_oauth Content-Type application/x-www-form-urlencoded
  JSONHttpFetch spotify_oauth %body
  
  if ($JSONError || $json(spotify_oauth,error)) {
    echo %ec_error -a OAuth Error: $iif($JSONError,$v1,$json(spotify_oauth,error_description).string)
    JSONClose spotify_oauth
    return
  }
  
  set %spotify_access_token $remove($json(spotify_oauth,access_token).string,")
  set %spotify_refresh_token $remove($json(spotify_oauth,refresh_token).string,")
  set %spotify_token_expires $calc($ctime + $json(spotify_oauth,expires_in).value)
  
  ; Add expiration time debug info
  var %expires_in_min = $calc($json(spotify_oauth,expires_in).value / 60)
  echo %ec_debug -a Token expires in: %expires_in_min minutes
  echo %ec_debug -a Expiration time: $asctime(%spotify_token_expires,HH:nn:ss)
  
  echo %ec_succ -a OAuth Complete
  JSONClose spotify_oauth
}

; Add socket handling for OAuth callback
on *:socklisten:spotify_oauth_server:{ sockaccept spotify_oauth_callback }

; Modify socket callback to prevent window creation
on *:sockread:spotify_oauth_callback:{
  var %req
  sockread %req
  if ($regex(%req,^GET /callback\?code=([^ ]+) HTTP/)) {
    var %code = $regml(1)
    
    ; Process OAuth token first
    spotify_oauth_token %code
    
    ; Send simple response
    sockwrite -n $sockname HTTP/1.1 200 OK
    sockwrite -n $sockname Content-Type: text/html
    sockwrite -n $sockname Connection: close
    sockwrite -n $sockname 
    sockwrite -n $sockname <!DOCTYPE html>
    sockwrite -n $sockname <html><head><title>Spotify Authorization</title></head>
    sockwrite -n $sockname <body><h2>Authorization Complete!</h2>
    sockwrite -n $sockname <p>You may close this window.</p></body></html>
    
    ; Clean up sockets
    sockclose spotify_oauth_callback
    sockclose spotify_oauth_server
    
    ; Set flag to prevent window creation
    set %prevent_window 1
    
    halt
  }
}

; Add proper socket error events
on *:SOCKOPEN:spotify_oauth_*:{ 
  if ($sockerr) { 
    echo %ec_error Socket Open Error: $sockerr
    sockclose $sockname 
  }
}

on *:SOCKCLOSE:spotify_oauth_*:{ 
  if ($sockerr) {
    echo %ec_error Socket Close Error: $sockerr
  }
}

; Add new window display alias
alias spotify_window {
  ; Check prevention flag
  if ($isset(%prevent_window)) { 
    unset %prevent_window
    return 
  }
  
  ; Create window only if it doesn't exist
  if (!$window(@Spotify)) {
    ; Create new separate window with increased height (from 100 to 150)
    window -d @Spotify 10 10 370 125
    
    ; Set window properties
    window -aBpn @Spotify
    titlebar @Spotify Now Playing
  }
  
  ; Clear existing content without closing window
  clear -l @Spotify
  
  ; Exit if no valid token
  if (!$spotify_oauth_token_valid) {
    aline -h @Spotify Not connected to Spotify
    return
  }
  
  ; Get current track info
  JSONOpen -duw spotifyWindow https://api.spotify.com/v1/me/player/currently-playing
  JSONHttpHeader spotifyWindow Authorization Bearer $remove(%spotify_access_token,")
  JSONHttpFetch spotifyWindow
  
  if ($JSONError || $JSON(spotifyWindow).HttpStatus == 204) {
    aline -h @Spotify No track playing
    JSONClose spotifyWindow
    return
  }
  
  ; Get track info and update display
  var %track = $remove($json(spotifyWindow,item,name).string,")
  var %artist = $remove($json(spotifyWindow,item,artists,0,name).string,")
  var %prog = $calc($json(spotifyWindow,progress_ms).value / 1000)
  var %dur = $calc($json(spotifyWindow,item,duration_ms).value / 1000)
  var %percent = $round($calc((%prog / %dur) * 30),0) 
  
  ; Create progress bar with increased width of 30 (changed from 20)
  var %bar = $str(=,%percent)
  var %space = $str(-,$calc(30 - %percent))
  
  ; Update window content
  aline -h @Spotify Track: %track
  aline -h @Spotify Artist: %artist
  aline -h @Spotify $+([,%bar,%space,]) $+($round($calc((%prog / %dur) * 100),0),%)
  aline -h @Spotify $floor($calc(%prog / 60)) $+ : $+ $iif($floor($calc(%prog % 60)) < 10,0) $+ $floor($calc(%prog % 60)) / $floor($calc(%dur / 60)) $+ : $+ $iif($floor($calc(%dur % 60)) < 10,0) $+ $floor($calc(%dur % 60))
  
  ; Update timer using correct syntax
  if ($json(spotifyWindow,is_playing).value) {
    $+(timer,spotify) 1 5 spotify_window
  }
  
  JSONClose spotifyWindow
}

; Update timer stop on window close
on *:CLOSE:@Spotify:{ $+(timer,spotify) off }