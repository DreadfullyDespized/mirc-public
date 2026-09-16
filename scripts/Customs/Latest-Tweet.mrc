; Tweets can be fetched by either typing into channel: !tweetstalker accountname1 accountname2 etc
; or typing in mirc: /tweetstalker #OutputChannel accountname1 accountname2 etc
; Currently it throws a lot of debug messages to status window, that can be eliminated once you've got it working
; Output to @tweetstalker window is:
; #OutputChannel accountname <tweet message | error messages like "no tweets were found" or "that page does not exist">
; Issues I can think of off the top of my head:
; * If !tweetstalker requests in channel are allowed, people will immediately search for obscene words
;   a command to close it, so if there's an error message i don't know about yet, the socket stays open forever
; * if line contains *twitter.com* i assume it's a real tweet, but it may not display anything for error messages
;   i've not yet encountered besides "not an account", "locked private or banned", or "no tweets made".
;   i dunno if it's possible for that guy's query to be seen as blocked.

; FYI: the script makes a queue for incoming requests like: #channel1 acct1 acct2 #channel2 acct3 acct4 acct5
;   so any word beginning with # changes the output, so acct1+2 goes to #channel1 and acct3+4+5 go to #channel2

; This looks for someone typing: !tweetstalker accountname [optional additional account(s) ]
on 10:TEXT:!tweetstalker *:#dreadfullydespized:{
    if ($mod($nick,#dreadfullydespized)) {
        tweetstalker # $2-
    }
}

; can also get tweets by doing: /tweetstalker #OutputChannel accountname [ optional additional accoutname(s) ]

; examples of: 1) active account 2) account with no tweets 3) skipped invalid 4) banned 5) no such account
; //tweetstalker $chan(1) taylorswift13 doesnotexist invalid!string nero euryfhsyatweor

alias tweetstalker {
  if (%tweetstalker_debug) echo 6 -s $scriptline cmd: $1- / PrevQue: %tweetstalker / $iif($sock(tweetstalker),sock open)
  if ($1 == !next) { goto next }
  ; assumes output is only to a #channelname
  if (#* !iswm $1) { tokenize 32 #DefaultChannelNameGoesHere $1- }

  :additemtop
  if (#* iswm $1) goto addparameter
  ;assumes account can contain only letters, numbers, and underscores
  if ($1) {
    if ($remove($1,_) isalnum) {
      :addparameter | echo -s adding $1
      set %tweetstalker %tweetstalker $1
    }
    tokenize 32 $2- | goto additemtop
  }
  if (%tweetstalker_debug) echo 2 -s updated que: %tweetstalker
  :next

  if ($sock(tweetstalker)) { goto exit }
  if (%tweetstalker)  {
    if (!$timer(tweetstalker.next).reps) sockopen -e tweetstalker decapi.me 443
    ;aline @test $scriptline sockopen -e tweetstalker decapi.me 443 / %tweetstalker
  }
  return
  :exit
  echo -s will check again in 10 seconds for socket to be free - if it won't close by itself do: /sockclose tweetstalker
  .timertweetstalker.close 1 10 tweetstalker !next
  return
}

alias tweetstalker.output.handler {
  var %t $line(@tweetstalker,1)
  if (!%t) goto end
  tokenize 32 %t
  ; Note: this is 20 second delay to avoid being seen as flooding - feel free to change this but also
  ; adjust the delay between fetching tweets - see both places in script where [+++] is located
  ; Note that it counts YOUR idle time in that channel, so if you chat or have another output script
  ; they are all competing for that 20 seconds of idle time
  var %tweetstalker.idle 20

  var %idle $nick($1,$me).idle
  if (%idle == $null) { echo -s You are not on $1 - waiting... | goto end }
  if (%idle < %tweetstalker.idle) { .timertweetstalker.idle 1 $calc(%tweetstalker.idle - %idle) tweetstalker.output.handler timer | return }

  dline @tweetstalker 1
  $iif(%tweetstalker_debug,echo 4 -s) msg $1 account: $2 msg: $3-

  :end
  var %t $line(@tweetstalker,1)
  if (%t) { if (!$timer(tweetstalker.output)) timertweetstalker.output 0 %tweetstalker.idle tweetstalker.output.handler timer }
  else { if ($timer(tweetstalker.output)) timertweetstalker.output off }
}

On *:sockopen:tweetstalker:{
  var %t %tweetstalker
  if (%tweetstalker_debug) echo -s $scriptline sockopen queue: %t
  if (!%t) { sockclose $sockname | return }

  :CheckIfChannel
  var %a $gettok(%t,1,32)
  if (#* iswm %a) { set %tweetstalker.output %a | var %t $gettok(%t,2-,32) | goto CheckIfChannel }
  set %tweetstalker %t

  if (!%t) { echo -s 8,4 This should not happen - socket opened without acctname | sockclose $sockname | return }

  sockwrite -nt $sockname GET /twitter/latest?name= $+ $gettok(%t,1,32) $+ $chr(38) $+ no_rts&howlong&url HTTP/1.1
  sockwrite -nt $sockname Host: $sock($sockname).addr
  sockwrite -n $sockname Connection: Close
  ;sockwrite -n $sockname
  sockwrite -nt $sockname $crlf
  if (%tweetstalker_debug) echo 4 -s @test $scriptline sockopen $sockname Host: $sock($sockname).addr GET /twitter/latest?name= $+ $gettok(%t,1,32) $+ $chr(38) $+ no_rts&howlong&url HTTP/1.1 / %t
  if (!$window(@tweetstalker)) window @tweetstalker
  :exit
}

alias tweetstalker.close {
  if (%tweetstalker_debug) echo -s @test $scriptline $event closing socket $sock(tweetstalker)
  if ($sock(tweetstalker)) sockclose tweetstalker

  ; Note: This is a 5 second delay between requests - hoping to avoid being seen as DDOS or spam
  ; should probably be at least 2 seconds less than the interval for spacing output to channel to avoid flooding
  ; see both places in script where [+++] is located
  ; echo -s $asctime fire up tweetstalker.next
  set %tweetstalker $gettok(%tweetstalker,2-,32)
  if (%tweetstalker) .timertweetstalker.next 1 5 tweetstalker !next $unsafe(%tweetstalker)
  tweetstalker.output.handler
}

on *:sockclose:tweetstalker:{ tweetstalker.close }

on *:sockread:tweetstalker:{
  if ($sockerr) { echo -s sockerr $sockerr | return }
  var %TSread
  sockread %TSRead
  if (%tweetstalker_debug isnum 5-) echo -s $sockbr Debug Msg: %TSread
  if (*twitter.com* iswm %TSread) {
    if (!$window(@tweetstalker)) window @tweetstalker
    if (%tweetstalker_debug) echo 12 -s msg %tweetstalker.output $gettok(%tweetstalker,1,32) %TSread
    tweetshows %tweetstalker.output $gettok(%tweetstalker,1,32) %TSread
    return
  }
  elseif ((%TSread == No tweets were found for this user.) || (%TSread == [Error] - [34] Sorry, that page does not exist.) || (%TSread == Not authorized (Normally this means locked/private account))) {
    if (!$window(@tweetstalker)) window @tweetstalker
    if (%tweetstalker_debug) echo 5 -s msg %tweetstalker.output $gettok(%tweetstalker,1,32) %TSread
    tweetshows %tweetstalker.output $gettok(%tweetstalker,1,32) %TSread
    return
  }
}

alias -l tweetshows {
  aline @tweetstalker $1-
  ;echo @test $asctime $1-
}