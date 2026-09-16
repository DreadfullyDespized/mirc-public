; /obsws password
alias obsws {
  if ($websock(obsws)) {
    websockclose -f obsws
  }
  if ($JSON(obsws)) {
    jsonclose obsws
  }
  websockopen obsws localhost:4455
  websockmark obsws password %obspass
}

;; REQSENT event raised when the HTTP request has been sent and the script
;; is waiting for a response from the server
on *:SIGNAL:WebSocket_REQSENT_obsws:{
  echo %ec_debug -s [obsws>REQSENT] Request sent
}

;; READY event raised after the handshake has successuflly completed and
;; the connection is ready to transfer websocket frame data.
;;
;; /WebSockWrite can be used to send data frames to the server
on *:SIGNAL:WEBSOCKET_READY_obsws:{
  echo %ec_succ -s [obsws>READY] Handshake Complete
  echo %ec_succ -s Connected to obs
  WebSockWrite -t+t obsws {"request-type":"GetAuthRequired","message-id":"auth_details_response"}
}

on *:SIGNAL:WEBSOCKET_DATA_obsws:{
  noop $WebSockFrame(&obsws)
  JSONOpen -db obsws &obsws
  var %msgid = $json(obsws, message-id).value
  var %update = $json(obsws, update-type).value
  ; check if the message-id is a response to GetAuthRequired
  if (%msgid === auth_details_response) {
    echo -s GetAuthRequired response recieved
    if ($JSON(obsws, authRequired).value === $false) {
      echo %ec_succ -s No Auth required
    }
    else {
      bunset &obswsAuth
      var %pass      = $WebSockMark(obsws, password)
      var %salt      = $JSON(obsws, salt).value
      var %challenge = $JSON(obsws, challenge).value
      var %auth
      ;; append salt to pass
      %auth = %pass $+ %salt
      ;; hash and base64
      %auth = $SHA256ToMime(%auth)
      ;; append challenge
      %auth = %auth $+ %challenge
      ;; hash and base64
      %auth = $Sha256ToMime(%auth)
      ;; send auth
      WebSockWrite -t+t obsws {"request-type":"Authenticate","message-id":"auth_response","auth":" $+  %auth $+ "}
      echo %ec_succ -s Sending auth
    }
  }
  elseif (%msgid === auth_response) {
    echo %ec_succ -s > Auth Response:
    echo %ec_succ -s > $JSON(obsws).String
  }
  ; This one was commented out, due to the fact it is literally every second that it pops up.
  elseif (%update === StreamStatus) {
    ; echo %ec_succ -s $JSON(obsws).String
  }
  elseif (%update === StreamStarted) {
    if (!$timer(streamstarting).secs) {
      echo %ec_supp -s $JSON(obsws).String
      $+(timer,beginjsontest) 1 30 jsontest
      $+(timer,streamcreate) 1 35 sqlstreamcreate
      $+(timer,streamlastseen) 0 180 sqlstreamseen
      $+(timer,streamstarting) 1 10 echo %ec_succ -a Stream Starting: Completed
      set -g %StreamStarted 1
    }
    else {
      echo %ec_error -a Error: Stream is already starting...
    }
  }
  elseif (%update === StreamStopped) {
    if (!$timer(streamstopping).secs) {
      echo %ec_supp -s $JSON(obsws).String
      $sqlstreamend
      $+(timer,streamlastseen) off
      $+(timer,streamstopping) 1 10 echo %ec_succ -a Stream Stopping: Completed
      set -g %StreamStarted 0
      WebSockClose obsws
    }
    else {
      echo %ec_error -a Error: Stream is already stopping...
    }
  }
  else {
    ; echo %ec_debug -s $JSON(obsws).String
  }
  JSONClose obsws
}

;; CLOSING event raised when the server sends a close frame. As with the
;; data frame, $WebSockFrame can be used to retrieve information about
;; the frame
on *:SIGNAL:WebSocket_CLOSING_obsws:{
  echo %ec_debug -s [obsws>DATA] $WebSockFrame(TypeText) $+ ( $+ $WebSockFrame(Type) $+ ) frame recieved $+ $iif($WebSockFrame, : $v1, .)
}

;; CLOSED event raised when the connection has successfully been closed by
;; the server
on *:SIGNAL:WebSocket_CLOSE_obsws:{
  echo %ec_debug -s [obsws>CLOSE] Connection closed.
}

;; ERROR event raised when the connection suffers from an error.
;; $WebSockErr and $WebSockErrMsg can be used to identify the issue
on *:SIGNAL:WebSocket_ERROR_obsws:{
  echo %ec_error -s [obsws>ERROR] Error: $WebSockErr > $WebSockErrMsg
}

;; FINISHED event raised when the connection has been completely closed
;; and all resources related to the event have been freed
on *:SIGNAL:WebSocket_FINISHED_obsws:{
  echo %ec_succ -s [obsws>FINISHED] All resources freed
}

/* Returns a base64 encoded sha256 for the input text
*   mIRC's $sha256 returns the result as hex-encoded
*   this alias converts that result back to binary then base64 encodes it
*/
alias -l Sha256toMime {
  bunset &SHA256ToMime
  ;; sha256 the input
  tokenize 32 $sha256($1-, 0)
  var %res
  var %n = 1
  var %l = $len($1-)
  ;; $sha256 outputs the result as hex encoded, so we need to convert it back to binary
  while (%n < %l) {
    ;; convert the 2-character hex value back to decimal and append the result to a binary variable
    bset &SHA256ToMime -1 $base($mid($1-, %n, 2), 16, 10)
    inc %n 2
  }
  ;; base64 encode the binary variable and retrieve the result
  noop $encode(&SHA256ToMime, mb)
  %res = $bvar(&SHA256ToMime, 1-).text
  ;; cleanup and return the result
  bunset &SHA256ToMime
  return %res
}