alias clearchannel {
  clear
  echo 3DreadfullyDespized 13Cleared 8Channel
  jsonclearchat
}

alias startstream {
  resetotimer
  enable #points
  clearchannel
  $+(timer, getthemodslist) 1 40 jsongetmods
  $+(timer, getthemodslist-repeat) 0 1800 jsongetmods
}

alias stopstream {
  disable #points
  timers off
}

alias subtest {
  var %nick = 'dreadfullydespized'
  var %cumu_months = 60
  $+(timer,m60sub) 1 20 sqlsubsay %nick %cumu_months
  echo %ec_debug -a 60 Month Resub - %nick
}

alias timerdown {
  ; set some value
  set %gatimer Countdown:
  ; print the value
  echo -a %gatimer
  ; set the value to 30, decrease once per second
  set -zs %gatimer 30
}

alias checktimer {
  if (%gatimer) {
    msg $chan --> Giveaway Timer is currently active.
  }
  else {
    msg $chan --> Giveaway timer is currently not active.
  }
}

; FORMAT: /wsobsgetcurscene name command test
; This will then get the current scene being asked for status
alias wsobsgetcurscene {
  var %name = $1
  var %cmd = $2
  var %payload = $+(check~,%cmd,~,%name)
  WebSockWrite -t+t obsws {"request-type":"GetCurrentScene","message-id":" $+ %payload $+ "}
  if ($3) {
    echo %ec_debug -a wsobsgetcurscene Payload: %payload
  }
}

; FORMAT: /wsobsgetsceneip item_name payload test
; This will get the current scene’s item properties from OBS
alias wsobsgetsceneip {
  var %item_name = $1
  var %payload = $2
  WebSockWrite -t+t obsws {"request-type":"GetSceneItemProperties","item":" $+ %item_name $+ ","message-id":" $+ %payload $+ "}
  if ($3) {
    echo %ec_debug -a wsobsgetsceneip Payload: %item_name %payload
  }
}

; FORMAT /wsobssetsceneip item_name item_vis payload test
; This will set the current scene’s item properties, currently only using visibility true or false.
alias wsobssetsceneip {
  var %item_name = $1
  var %item_vis = $2
  var %payload = $3
  WebSockWrite -t+t obsws {"request-type":"SetSceneItemProperties","item":" $+ %item_name $+ ","visible": $+ %item_vis $+ ,"message-id":" $+ %payload $+ "}
  if ($4) {
    echo %ec_debug -a wsobssetsceneip Payload: %item_name %item_vis %payload
  }
}

alias mpstart {
  $wsobssetsceneip(MiniPotato,true,minipotato)
  msg %mychan MiniPotato sighted!!!!
}

alias minipotatostop {
  sqlmpclean
  wsobssetsceneip MiniPotato false minipotato
  $+(timer,minipotato-clean) off
  $+(timer,minipotato-check) off
  $+(timer,minipotato-off) off
  $+(timer,minipotato) off
}

on *:SIGNAL:WEBSOCKET_DATA_obsws: {
  noop $WebSockFrame(&obsws)
  JSONOpen -db obsws &obsws
  var %msgid = $json(obsws, message-id).value
  if ($JSON(obsws, scene-name).value === Game) || ($JSON(obsws, name).value === Game) {
    if ($gettok(%msgid,1,126) === check) {
      var %name = $gettok(%msgid,3,126)
      if ($gettok(%msgid,2,126) === biggiantchest) {
        var %payload = $+($v1,~,%name)
        $wsobsgetsceneip(BigGiantChest,%payload)
      }
      elseif ($gettok(%msgid,2,126) === sharknado) {
        var %payload = $+($v1,~,%name)
        $wsobsgetsceneip(Sharknado,%payload)
      }
      elseif ($gettok(%msgid,2,126) === drplunder) {
        var %payload = $+($v1,~,%name)
        $wsobsgetsceneip(DrThunder,%payload)
      }
      elseif ($gettok(%msgid,2,126) === potatochallenge) {
        var %payload = $+($v1,~,%name)
        $wsobsgetsceneip(PotatoChallenge,%payload)
      }
      elseif ($gettok(%msgid,2,126) === hbday) {
        var %payload = $+($v1,~,%name)
        $wsobsgetsceneip(HBDAY,%payload)
      }
      elseif ($gettok(%msgid,2,126) === minipotato) {
        var %payload = $+($v1,~,%name)
        $wsobsgetsceneip(MiniPotato,%payload)
      }
    }
    elseif (!$timer(minipotato)) {
      if (%StreamStarted === 1) {
        ; echo %ec_succ -a On Game Scene starting minipotato
        $+(timer,minipotato-check) 1 30 wsobsgetcurscene dreadfullydespized minipotato
      }
    }
  }
  elseif ($gettok(%msgid,1,126) === biggiantchest) {
    var %cmd = $v1
    var %name = $gettok(%msgid,2,126)
    if ((%floodbiggiantchest) && ($nick != dreadfullydespized)) {
      msg %mychan %name --> %cmd is on cooldown for $var(%floodbiggiantchest, 1).secs seconds.
    }
    elseif ($JSON(obsws, visible).value === $false) {
      msg %mychan %name --> Has found a Big Giant Chest!!!!!!!
      $wsobssetsceneip(BigGiantChest,true,biggiantchest-run)
      splay %otherSounds $+ BigGiantChestTotal.mp3
      $+(timer, biggiantchest) 1 6 wsobssetsceneip BigGiantChest false biggiantchest-stop
      if (%name != dreadfullydespized) {
        set -eu45 %floodbiggiantchest On
      }
    }
  }
  elseif ($gettok(%msgid,1,126) === drplunder) {
    var %cmd = $v1
    var %name = $gettok(%msgid,2,126)
    if (%flooddrplunder) {
      msg %mychan %name --> %cmd is on cooldown for $var(%flooddrplunder, 1).secs seconds.
    }
    elseif ($JSON(obsws, visible).value === $false) {
      msg %mychan %name --> Has initiated the Dr. Thunder Love!!!
      $wsobssetsceneip(DrThunder,true,drplunder-run)
      $+(timer, drplunder) 1 53 wsobssetsceneip DrThunder false drplunder-stop
      if (%name != dreadfullydespized) {
        set -eu900 %flooddrplunder On
      }
    }
  }
  elseif ($gettok(%msgid,1,126) === hbday) {
    var %cmd = $v1
    var %name = $gettok(%msgid,2,126)
    if ((%floodhbday) && (%name != dreadfullydespized)) {
      msg %mychan %name --> %cmd is on cooldown for $var(%floodhbday, 1).secs seconds.
    }
    elseif ($($+(%,floodhbday.,%name),2)) {
    }
    elseif ($JSON(obsws, visible).value === $false) {
      msg %mychan %name --> $sqlbirth
      $wsobssetsceneip(HBDAY,true,hbday-run)
      $+(timer, hbday) 1 22 wsobssetsceneip HBDAY false hbday-stop
      if (%name != dreadfullydespized) {
        set -eu900 %floodhbday On
        set -eu84600 %floodhbday. $+ %name On
      }
    }
  }
  elseif ($gettok(%msgid,1,126) === potatochallenge) {
    var %cmd = $v1
    var %name = $gettok(%msgid,2,126)
    if ((%floodpotatochallenge) && (%name != dreadfullydespized)) {
      msg %mychan %name --> %cmd is on cooldown for $var(%floodpotatochallenge, 1).secs seconds.
    }
    elseif ($JSON(obsws, visible).value === $false) {
      msg %mychan %name --> Calls forth the Potato Love!!!!
      $wsobssetsceneip(PotatoChallenge,true,potatochallenge-run)
      $+(timer, potatochallenge) 1 59 wsobssetsceneip PotatoChallenge false potatochallenge-run
      if (%name != dreadfullydespized) {
        set -eu900 %floodpotatochallenge On
      }
    }
  }
  elseif ($gettok(%msgid,1,126) === sharknado) {
    var %cmd = $v1
    var %name = $gettok(%msgid,2,126)
    if ((%floodsharknado) && (%name != dreadfullydespized)) {
      msg %mychan %name --> %cmd is on cooldown for $var(%floodsharknado, 1).secs seconds.
    }
    elseif ($JSON(obsws, visible).value === $false) {
      var %fpointy = $sqlite_result($sqluname(%name),points)
      if (%fpointy >= 200) {
        msg %mychan %name --> Call forth the mighty SharkNado!!!!!!!!
        $wsobssetsceneip(Sharknado,true,sharknado-run)
        $wsobssetsceneip(SharknadoGIF,true,sharknadogif-run)
        $+(timer, sharknado) 1 5 wsobssetsceneip Sharknado false sharknado-run
        $+(timer, sharknadogif) 1 5 wsobssetsceneip SharknadoGIF false sharknadogif-run
        $sqlumodpvd(%name,-,200,0,0)
        if (%name != dreadfullydespized) {
          set -eu900 %floodsharknado On
        }
      }
    }
  }
  elseif ($gettok(%msgid,1,126) === minipotato) {
    if ($JSON(obsws, visible).value === $false) {
      if (!$timer(minipotato).secs) || (!$timer(minipotato-off).secs) {
        var %minipotatotimer = $rand(1200,3500)
        ; var %minipotatotimer = $rand(40,60)
        var %mpcleantimer = %minipotatotimer - 30
        var %minipotatotimer2 = %minipotatotimer + 40
        $+(timer,minipotato-clean) 1 %mpcleantimer sqlmpclean
        $+(timer,minipotato) 1 %minipotatotimer mpstart
        $+(timer,minipotato-off) 1 %minipotatotimer2 wsobssetsceneip MiniPotato false minipotato
        $+(timer,minipotato-check) 0 300 wsobsgetcurscene dreadfullydespized minipotato
      }
    }
  }
  elseif ($JSON(obsws, scene-name).value === Intro) || ($JSON(obsws, scene-name).value === AFK) || ($JSON(obsws, scene-name).value === Main) || ($JSON(obsws, scene-name).value === End) {
    if ($timer(minipotato-check)) {
      echo %ec_debug -a No longer on game scene stopping minipotato
      minipotatostop
    }
  }
}

; This handles if I manually disconnect from obs before closing it
on *:SIGNAL:WebSocket_CLOSE_obsws:{
  minipotatostop
}
; This handles if I just close obs
on *:SIGNAL:WebSocket_FINISHED_obsws:{
  minipotatostop
}

alias gatimeupdate {
  write -l4 giveaway1.txt Timer: $+($chr(91),%gatimer,$chr(93)) remaining
}

/*
##########################################################################################################################
This is the various commands that are for everyone in the stream
##########################################################################################################################
*/

; on $*:TEXT:/^!(banana|boobies|boysboys|doink|bruce|dp|dripotato|f0osterisback|farty|getnuts|groovy|hi5|laugh|law|lotion|predator|refuel|train|trouble|tryit|viva|weewoo|imapotato)?$/i:?,#dreadfullydespized: {
;   msg $chan $nick --> $1 is no longer the proper way to use this command, try $+("!c,$chr(32),$replace($1,!,),") instead.
; }

on $*:TEXT:/^!c\s\w+?$/i:?,#dreadfullydespized: {
  msg $chan $nick --> $1- is no longer requiring the !c in front of it, try $remove($1-,$+(c,$chr(32)),) instead.
}

on $*:TEXT:/^!\S.+$/i:?,#dreadfullydespized: {
  ; First thing needed to do is to gather from the db table of commands.
  ; This needs to be identified by checking the $1 against the names of the DB.
  ; I will need a secondary if statement to be handling if using certain commands.
  var %ud = $sqluname($nick)
  var %twuid = $sqlite_result(%ud,twitch_user_id)
  var %rank = $sqlite_result(%ud,rank)
  var %p = $sqlite_result(%ud,points)
  var %rcur = $sqlite_result(%ud,title)
  var %b = $sqlite_result(%ud,birthday)
  var %sp = $sqlite_result(%ud,speech)
  var %bcheck = $+($gettok(%b,2,45),-,$gettok(%b,3,45))
  var %cmdcheck = $sqlcheckcmd($replace($1,!,),Command)
  echo %ec_supp -a CMD: $1
  if ($2) {
    echo %ec_supp -a OPT: $2
  }
  if ($1 == $+(!,$sqlite_result(%cmdcheck,name))) {
    msg $chan $nick --> $sqlite_result(%cmdcheck,response)
    ; echo %ec_debug -a CMD Request Released
    sqlite_free %request
  }
  elseif ($1 == !gaclean) {
    if ($nick == dreadfullydespized) {
      msg $chan $nick --> $sqlgaclean
      wsobssetsceneip Giveaway false
      wsobssetsceneip Giveaway-Entries false
      write -c giveaway1.txt
      write -c giveaway2.txt
      timergaendingtimer off
      $+(timer,gaendingtimer) off
      timericktimer off
      $+(timer,icktimer) off
      unset -slg %gatimer
    }
  }
  ; FORMAT: !gastart {time in minutes} {max tickets} {cost per ticket} {Item}
  elseif ($1 == !gastart) {
    if ($nick == dreadfullydespized) {
      if ($2 isnum) {
        var %gatime = $2 * 60
        var %derptime = %gatime / 60
        if ($3 isnum) {
          set %gamaxticket $3
          if ($4 isnum) {
            set %gacost $4
            var %gaitem = $5-
            var %message = Giveaway for $+($chr(91),%gaitem,$chr(93)) has started! Type [!! ###] $&
              in the chat for how many tickets! Max ticket entry is $&
              $chr(91) $+ %gamaxticket $+ $chr(93) $iif(%gamaxticket >= 2,Tickets,Ticket) with a cost of $&
              $chr(91) $+ %gacost $+ $chr(93) $iif(%gacost >= 2,Potatoes,Potato) per ticket and you have $&
              $chr(91) $+ $2 $+ $chr(93) $iif($2 >= 2,Minutes,Minute) to enter!! Hurry!!
            msg $chan --> %message
            speak -ls 55 %message
            ; -e unsets variable with mirc exits
            ; -z switch decreases %var until it reaches zero and then unsets it.
            set -ezs %gatimer %gatime
            write -c giveaway1.txt Giveaway for the following $+($chr(91),%gaitem,$chr(93))
            write -c giveaway2.txt
            write giveaway1.txt Conditions: $+($chr(91),$2,$chr(93),:Minutes,$chr(32),$chr(91),$3,$chr(93),:TicketsMax,$chr(34),$chr(91),$4,$chr(93),:CostPerTicket)
            write giveaway1.txt Type [!! ###] in the chat for how many tickets you wish to purchase!
            write giveaway1.txt Timer: $+($chr(91),%gatime,$chr(93)) remaining
            write giveaway1.txt Entries:
            wsobssetsceneip Giveaway true
            wsobssetsceneip Giveaway-Entries true
            $+(timer,gaendingtimer) 1 %gatime sqlgawin
            $+(timer,icktimer) %gatime 1 gatimeupdate
          }
        }
      }
      else {
        msg $chan $nick -->  The correct format for this command as follows !gastart {time in minutes} {max tickets} {cost per ticket} {Item}.
      }
    }
    else {
      msg $chan $nick --> I am sorry, you don't have permission to use this. Beg the streamer next time.
    }
  }
  elseif ($1 == !gawin) {
    if ($nick == dreadfullydespized) {
      ; msg $chan $nick --> $sqlgawin
      $sqlgawin
    }
  }
  elseif ($1 == !linkdicksword) {
    var %msg = $addtok(%msg, -->,32)
    %msg = $addtok(%msg,$linkdicksword($nick,$2-),32)
    $jsonwhisper(%twuid,%msg,$nick)
  }
  elseif ($1 == !potato) {
    if (!$timer($nick $+ .speech)) {
      $+(timer, $nick $+ .speech) 0 900 sqltickettimer $nick
    }
    if (!$timer($nick $+ .points)) {
      $+(timer, $nick $+ .points) 0 300 sqltimeadd $nick
    }
    if ((%floodpotato) && ($nick != dreadfullydespized)) {
      msg $chan $nick --> $1 is on cooldown for $var(%floodpotato,1).secs seconds.
    }
    else {
      ; Need to add a timer check section within this command to check if timer is enabled.
      ; If so then do nothing.  If not then start it.
      var %d = $sqlite_result(%ud,donations)
      var %v = $sqlite_result(%ud,views)
      var %rw = $sqlite_result(%ud,roll_win)
      var %qt = $sqlite_result(%ud,quote_total)
      var %hlpt = $sqlite_result(%ud,highlight_point_total)
      var %hlct = $sqlite_result(%ud,highlight_created_total)
      var %idRank = $sqlite_result(%ud,idRank)
      var %hbegin = $sqlite_result(%ud,min_hour)
      var %hend = $sqlite_result(%ud,max_hour)
      var %rnex = $sqlite_result(%ud,next_title)
      var %reg = $sqlite_result(%ud,is_regular)
      var %mod = $sqlite_result(%ud,is_moderator)
      var %gw = $sqlite_result(%ud,giveaway_win)
      $jsonwhisper(%twuid,$+([,%p,:,$iif(%p >= 2,Potatoes,Potato),],$chr(32),-,$chr(32), $&
        [,%sp,:,$iif(%sp >= 2,Speeches,Speech),],$chr(32),-,$chr(32), $&
        [,%v,:,Hours,],$chr(32),-,$chr(32),[,%b,:,Birthday,],$chr(32),-,$chr(32), $&
        [,%rw,:,Rolls Won,],$chr(32),-,$chr(32), $&
        [,%qt,:,Total Quotes,],$chr(32),-,$chr(32), $&
        [,%hlpt,:,Total Highlight Points Earned,],$chr(32),-,$chr(32), $&
        [,%hlct,:,Total Highlights Created,],$chr(32),-,$chr(32), $&
        [,%gawin,:,Total Giveaways Won,]),$nick)
      if (%v isnum 0-2.99) {
        var %hleft = $calc(3 - %v)
        msg $chan $nick --> You are a †Niblet† with %v $iif(%v == 1,hour,hours). $&
          Earn %hleft $iif(%hleft == 1,more hour,more hours) to become a †Spud†.
        $sqlumod($nick,rank,1)
      }
      elseif (%v isnum 21850-) {
        msg $chan $nick --> You are a †Grand Puuba Elite Potato of the Dek† with %v hours.
        if (%rank != 60) {
          $sqlumod($nick,rank,60)
          splay $+(%lsounds,Level-GrandPuubaElitePotatooftheDek.mp3)
          guser -a 60 $nick
        }
      }
      else {
        if (%v isnum %hbegin - %hend) {
          if (%v isnum 1000-) {
            var %reason = 1000 hrs
            if ($nick != dreadfullydespized) {
              $sqlcsu($nick,%reason)
            }
          }
          if (%reg != 1) {
            msg $chan $nick --> Has achieved regular status.  Welcome them with a dreadfDeeTee !!!!
            splay $+(%lsounds,Level-Spud.mp3)
            $sqlumod($nick,is_regular,1)
            guser -a 1 $nick
          }
          var %hleft = $calc(%hend - %v)
          msg $chan $nick --> You are a $+(†,%rcur,†) with %v hours. $&
            Earn %hleft $iif(%hleft == 1,more hour,more hours) to become a $+(†,%rnex,†).
          if ($ulevel != %idRank) {
            echo -a UserLevel: $ulevel and idRank: %idRank
            guser -a %idRank $nick
          }
          if (%rank != %idRank) {
            var %rcurstrip = $remove(%rcur,$chr(32))
            $sqlumod($nick,rank,%idRank)
            guser -a %idrank $nick
            splay $+(%lsounds,Level-,%rcurstrip,.mp3)
          }
        }
      }
      if ($nick != dreadfullydespized) {
        set -eu5 %floodpotato On
      }
    }
    sqlite_free %request
  }
  elseif ($1 == !minipotato) {
    if ($timer(minipotato-off).secs <= 40) {
      var %reply = $sqlmpadd($nick)
      if (!%reply) {
        msg $chan $sqlmppo($nick)
      }
      else {
        msg $chan $nick --> You have already recieved your reward.
      }
    }
    else {
      msg $chan $nick --> The minipotato window is closed.
    }
  }
  elseif ($1 == !multi) {
    if (%linky) {
      msg $chan $nick --> Multitwitch: %linky
    }
    else {
      msg $chan $nick --> No Multitwitch link set.  Please set with !setmulti streamname1 streamname2 etc
    }
  }
  elseif ($1 == !rollcur) {
    if ($nick == dreadfullydespized) {
      msg $chan $nick --> $rollcur
    }
  }
  elseif ($1 == !rollpurge) {
    if ($nick == dreadfullydespized) {
      msg $chan $nick --> $rollpurge
    }
  }
  elseif ($1 == !song) {
    msg $chan $nick --> Current Spotify Song: $read(%snipFile,1)
  }
  elseif ($1 == !sounds) {
    var %msg = $addtok(%msg, -->,32)
    %msg = $addtok(%msg,Sound Cmds:,32)
    %msg = $addtok(%msg,$sqlsounds($nick),32)
    $jsonwhisper(%twuid,%msg,$nick)
  }
  elseif ($1 == !uptime) {
    msg $chan --> $jsonuptime(dreadfullydespized)
  }
  /*
  ##########################################################################################################################
  REGULAR and above Status Section
  ##########################################################################################################################
  */
  elseif (%rank isnum 1-) {
    echo %ec_supp -s Rank Passed Regular check: $nick - %rank
    var %csndcheck = $sqlcheckcmd($replace($1,!,),CustomSound)
    var %rsndcheck = $sqlcheckcmd($replace($1,!,),Sound)

    if ($1 == $+(!,$sqlite_result(%csndcheck,name))) {
      if ($2) {
        ; Minor issue, if sound command is identical it won't work, even with two different people having the same command name.
        var %msg = $addtok(%msg, -->,32)
        %msg = $addtok(%msg,$sqlcustomsound($nick,$replace($1,!,),$2),32)
        $jsonwhisper(%twuid,%msg,$nick)
        sqlite_free %request
      }
      else {
        var %msg = $addtok(%msg, -->,32)
        %msg = $addtok(%msg,$sqlcustomsound($nick,$replace($1,!,)),32)
        $jsonwhisper(%twuid,%msg,$nick))
        sqlite_free %request
      }
    }
    elseif ($1 == $+(!,$sqlite_result(%rsndcheck,name))) {
      if ($2) {
        var %msg = $addtok(%msg, -->,32)
        %msg = $addtok(%msg,$sqlranksound($nick,$replace($1,!,),%rcur,%rank,$2),32)
        $jsonwhisper(%twuid,%msg,$nick)
        sqlite_free %request
      }
      else {
        var %msg = $addtok(%msg, -->,32)
        %msg = $addtok(%msg,$sqlranksound($nick,$replace($1,!,),%rcur,%rank),32)
        $jsonwhisper(%twuid,%msg,$nick)
        sqlite_free %request 
      }
    }
    elseif ($1 == !!) {
      if ($2 isnum 1 - %gamaxticket) {
        if (%gatimer) {
          var %owchy = $calc($2 * %gacost)
          if (%p >= %owchy) {
            var %msg = $addtok(%msg, -->,32)
            %msg = $addtok(%msg,$sqlga($nick,$2,%gacost),32)
            $jsonwhisper(%twuid,%msg,$nick)
            write giveaway2.txt $nick $2
            $sqlumodpvd($nick,-,%owchy,0,0)
          }
          else {
            var %msg = $addtok(%msg, -->,32)
            %msg = $addtok(%msg,You don't have enough currency to make that purchase.,32)
            $jsonwhisper(%twuid,%msg,$nick)
          }
        }
        else {
          var %msg = $addtok(%msg, -->,32)
          %msg = $addtok(%msg,Giveaway is currently not running.,32)
          $jsonwhisper(%twuid,%msg,$nick)
        }
      }
      else {
        var %msg = $addtok(%msg, -->,32)
        %msg = $addtok(%msg,Please enter an amount between the range of 1,32)
        %msg = $addtok(%msg,-,32)
        %msg = $addtok(%msg,%gamaxticket,32)
        $jsonwhisper(%twuid,%msg,$nick)
      }
    }
    elseif ($1 == !askivy) {
      if ((%floodivysay) && ($nick != dreadfullydespized)) {
        msg $chan $nick --> $1 is on cooldown for $var(%floodivysay,1).secs seconds.
      }
      else {
        msg $chan $nick --> AskIvy has been disabled.  If you would like it to contniue to be used.  Let DD know pwease.
        if ($nick != dreadfullydespized) {
          set -eu60 %floodivysay On
        }
        /*
        if (!$2) {
          msg $chan $nick --> You did not provide anything after $1, don't forget the space after. Example: $1 What is Potato?
        }
        if (%sp >= 200) {
          $sqlticketmod($nick, -, 200, 0)
          var %speechleft = $sqlite_result($sqluname($nick),speech)
          var %msg = $addtok(%msg, -->,32)
          %msg = $addtok(%msg,You have,32)
          %msg = $addtok(%msg,%speechleft,32)
          %msg = $addtok(%msg,speech tickets left.,32)
          $jsonwhisper(%twuid,%msg,$nick)
          var %reply = $jsonopenai($2-,%twuid,$nick)
          ; msg $chan $nick --> %reply
          speak -l %reply
          $sqlivyqins($nick,%reply)
          if ($nick != dreadfullydespized) {
            set -eu60 %floodivysay On
          }
        }
        else {
          var %msg = $addtok(%msg, -->,32)
          %msg = $addtok(%msg,200 speech tickets required for this command.,32)
          $jsonwhisper(%twuid,%msg,$nick)
        }
        }
        */
      }
    }
    elseif ($1 == !biggiantchest) {
      $wsobsgetcurscene($nick,biggiantchest)
    }
    elseif ($1 == !birthday) {
      ; b = yyyy-mm-dd, bcehck = mm-dd
      var %msg = $addtok(%msg, -->,32)
      %msg = $addtok(%msg,$birthday($nick,$2),32)
      $jsonwhisper(%twuid,%msg,$nick)
    }
    elseif ($1 == !boobs) {
      if (%p isnum 10-) {
        var %boobs (  .  Y  .  ),(.)(.),( . )( . ),(.Y.),( . Y . )
        msg $chan /me shakes his $gettok(%boobs,$rand(1,$numtok(%boobs,44)),44) for $nick
        $sqlumodpvd($nick,-,10,0,0)
      }
      else {
        msg $chan $nick --> You need 10 or more potatoes.
      }
    }
    elseif ($1 == !christmas) {
      if ((%floodholiday) && ($nick != dreadfullydespized)) {
        msg $chan $nick --> $1 is on cooldown for $var(%floodholiday, 1).secs seconds.
      }
      else {
        var %year = $sqlholcmdcheck($nick,Christmas)
        if ($nick != dreadfullydespized) {
          set -eu360 %floodholiday On
        }
        var %audio = $+(%sounds,Holiday-Christmas,%year,.mp3)
        echo %ec_succ -a %audio
        msg $chan $nick --> For Gift Giving Times we played $+(Holiday-Christmas,%year,.mp3)
        splay %audio
      }
    }
    elseif ($1 == !created) {
      var %stuffs = $jsoncreated($nick)
      var %followedmonth = $gettok(%stuffs,1,126)
      var %followedday = $gettok(%stuffs,2,126)
      var %followedyear = $gettok(%stuffs,3,126)
      var %duration = $gettok(%stuffs,4,126)
      msg $chan $nick --> Was created on $+($chr(91),%followedmonth,/,%followedday,/,%followedyear,$chr(93),.) If you would like to be anal. You are $+($chr(91),%duration,$chr(93)) old.
    }
    elseif ($1 == !dread) {
      if ((%flooddread) && ($nick != dreadfullydespized)) {
        msg $chan $nick --> $1 is on cooldown for $var(%flooddread, 1).secs seconds.
        return
      }
      else {
        if ($nick != dreadfullydespized) {
          set -eu15 %flooddread On
        }
        splay $+(%sounds,SoundHorror1.mp3)
        echo -a 11 $nick 8 :: 11 Message 8 :: 7 $2-
        write %notesFile $time :: $date(mm/dd/yyyy) :: $nick :: $2-
      }
    }
    elseif ($1 == !ghjoin) {
      ghjoin $nick
    }
    elseif ($1 == !ghlockpick) {
      ghlockpick $nick
    }
    elseif ($1 == !ghfight) {
      ghfight $nick
    }
    elseif ($1 == !ghrevive) {
      ghrevive $nick $2
    }
    elseif ($1 == !gghstay) {
      ghstay $nick
    }
    elseif ($1 == !ghleave) {
      ghleave $nick
    }
    elseif ($1 == !halloween) {
      if ((%floodholiday) && ($nick != dreadfullydespized)) {
        msg $chan $nick --> $1 is on cooldown for $var(%floodholiday, 1).secs seconds.
        return
      }
      else {
        var %year = $sqlholcmdcheck($nick,Halloween)
        if ($nick != dreadfullydespized) {
          set -eu360 %floodholiday On
        }
        var %audio = $+(%sounds,Holiday-Halloween,%year,.mp3)
        echo %ec_succ -a %audio
        msg $chan $nick --> For Spooooky Times we played $+(Holiday-Halloween,%year,.mp3)
        splay %audio
      }
    }
    elseif ($1 == !hbday) {
      var %today = $date(mm-dd)
      var %birthcheck = $sqlbirth($nick)
      ; sqlbirth provides the reply response that is supposed to be for the message. Success example "Todays Happy Birthday wishes go to $+(%bnames,!!!!!!!)"
      if ($mod($nick,#dreadfullydespized)) {
        ; msg $chan $nick --> $gettok(%birthcheck,3,126)
        $wsobsgetcurscene($nick,hbday)
      }
      else if ($gettok(%birthcheck,2,126) == %today) {
        msg $chan $nick --> $gettok(%birthcheck,3,126)
        $wsobsgetcurscene($nick,hbday)
      }
      else {
        ; Response indicating that no permission due to not being your birthday.
        msg $chan $nick --> Today....is not....your....birthday
      }
    }
    elseif ($1 == !hl) {
      if ((%floodhl) && ($nick != dreadfullydespized)) {
        msg $chan $nick --> $1 is on cooldown for $var(%floodhl, 1).secs seconds.
      }
      else {
        var %status = $jsonhighlight($nick,$2-)
        msg $chan $nick --> %status
        if ($nick != dreadfullydespized) {
          set -eu45 %floodhl On
        }
      }
    }
    elseif ($1 == !hug) {
      if (!$2) {
        msg $chan $nick --> You did not provide who to hug?  Why would you do that. Example: !hug dahauk
      }
      elseif ($2 == dahauk) {
        msg $chan /me hugs himself in all of the right places..mmmmmMMMMmmm for $nick
      }
      elseif ($2 != dahauk) {
        var %hug head,face,groin,knee,shin,nose,eye,ear,hand,butt,kneepit,armpit,toe,foot,taint,stomach,chest,neck,mouth
        msg $chan /me hugs $+($2,'s) $gettok(%hug,$rand(1,$numtok(%hug,44)),44) for $nick
      }
    }
    elseif ($1 == !ivy) {
      if ((%floodivysay) && ($nick != dreadfullydespized)) {
        msg $chan $nick --> $1 is on cooldown for $var(%floodivysay, 1).secs seconds.
      }
      else {
        if (!$2) {
          msg $chan $nick --> You did not provide anything after $1, don't forget the space after. Example: $1 poopypants!
        }
        if (%sp >= 20) {
          $sqlticketmod($nick, -, 20, 0)
          var %speechleft = $sqlite_result($sqluname($nick),speech)
          var %msg = $addtok(%msg, -->,32)
          %msg = $addtok(%msg,You have,32)
          %msg = $addtok(%msg,%speechleft,32)
          %msg = $addtok(%msg,speech tickets left.,32)
          $jsonwhisper(%twuid,%msg,$nick)
          speak -l $2-
          $sqlivyqins($nick,$2-)
          if ($nick != dreadfullydespized) {
            set -eu60 %floodivysay On
          }
        }
        else {
          var %msg = $addtok(%msg, -->,32)
          %msg = $addtok(%msg,20 speech tickets required for this command.,32)
          $jsonwhisper(%twuid,%msg,$nick)
        }
      }
    }
    elseif ($1 == !ivyq) {
      if ((%floodquotes) && ($nick != dreadfullydespized)) {
        msg $chan $nick --> $1 is on cooldown for $var(%floodquotes, 1).secs seconds.
      }
      else {
        if ($2 isnum) {
          msg $chan $nick --> $sqlqnum(row_ivy,$2,$nick)
        }
        elseif ($2 == with) {
          msg $chan $nick --> $sqlqwith(row_ivy,$nick,$3-)
        }
        elseif ($2 == rand) {
          msg $chan $nick --> $sqlqrand(row_ivy,$nick)
        }
        elseif ($2 == year) {
          if ($3 <= 2017) { 
            msg $chan $nick --> The year must be within the range of $+(2018,-,$date(yyyy))
          }
          elseif ($3 > $date(yyyy)) {
            msg $chan $nick --> One cannot hear what is said in the future.
          }
          elseif ($regex($3, (19|20)\d{2}$)) {
            msg $chan $nick --> $sqlqyrand(row_ivy,$nick,$3)
          }
        }
        elseif ($2 == del) {
          if ($nick == dreadfullydespized) {
            ; I believe the original idea was to let people delete the most recent IVY they posted
            ; Going forward, will have it work that it allows me to delete similar to the normal quote delete
            msg $chan $nick --> $sqlqdelete($nick,row_ivy,$3)
            ; msg $chan $nick --> $sqlqdel($3)
          }
        }
      }
    }
    elseif ($1 == !kdr) {
      if ((%floorkdr) && ($nick != dreadfullydespized)) {
        msg $chan $nick --> $1 is currently on cooldown for $var(%floodkdr,1)secs seconds.
      }
      else {
        if ($2 == kill) {
          inc %kills 1
          set %kdr $calc(%kills / %deaths)
          msg $chan $nick --> KDR updated to %kdr with %kills kills.
        }
        elseif ($2 == death) {
          inc %deaths 1
          set %kdr $calc(%kills / %deaths)
          msg $chan $nick --> KDR updated to %kdr with %deaths deaths.
          splay $+(%sounds,death.mp3)
        }
        else {
          msg $chan $nick --> Current KDR is %kdr with %kills kills and %deaths deaths.
        }
        if ($nick != dreadfullydespized) {
          set -eu10 %floodkdr On
        }
      }
    }
    elseif ($1 == !kick) {
      var %kick head,face,groin,knee,shin,nose,eye,ear,hand,butt,kneepit,armpit,toe,foot,taint,stomach,chest,neck,mouth
      msg $chan /me kicks $2 in the $gettok(%kick,$rand(1,$numtok(%kick,44)),44) for $nick
    }
    elseif ($1 == !latesthighlight) {
      var %stuffs = $jsonlh
      var %name = $gettok(%stuffs,1,126)
      var %title = $gettok(%stuffs,2,126)
      ; var %game = $gettok(%stuffs,3,126) while playing $+($chr(91),%game,$chr(93))
      var %url = $gettok(%stuffs,3,126)
      var %count = $gettok(%stuffs,4,126)
      ; for the times listed below, could translate to non-zulu
      var %created = $gettok(%stuffs,5,126)
      var %published = $gettok(%stuffs,6,126)
      var %duration = $gettok(%stuffs,7,126)
      msg $chan $nick --> Latest highlight is $+($chr(91),%title,$chr(93)) at $+($chr(91),$chr(32),%url,$chr(32),$chr(93)) with a runtime of $+($chr(91),%duration,$chr(93))
    }
    elseif ($1 == !pocharity) {
      if ((%floodpocharity) && ($nick != dreadfullydespized)) {
        msg $chan $nick --> $1 is on cooldown for $var(%floodpocharity, 1).secs seconds.
      }
      else {
        var %amount = $2
        if (%amount isnum 1-1500) {
          if (%p >= %amount) {
            var %n = $nick(#,0)
            while (1) {
              var %nrand $rand(1,%n)
              var %nupt = $nick(#,%nrand)
              var %ignore = %bots + dreadfullydespized
              if (%nupt isin %ignore) {
              }
              else {
                $sqlumodpvd($nick,-,%amount,0,0)
                $sqlumodpvd(%nupt,+,%amount,0,0)
                msg $chan $nick --> Pocharity: Gave $iif(%amount == 1,%amount potato, %amount potatoes) to %nupt
                break
              }
              if ($nick != dreadfullydespized) {
                set -eu900 %floodpocharity On
              }
            }
          }
          else {
            msg $chan $nick --> You currently don't have enough potatoes.
          }
        }
        else {
          msg $chan $nick --> You didn't specify a number or you went beyond the 1500 Potato cap.
        }
      }
    }
    elseif ($1 == !potatopick) {
      ; Check for cooldown
      if (%floodpick && $nick != dreadfullydespized) {
        msg $chan $nick --> !potatopick is on cooldown for $var(%floodpick,1).secs seconds.
      }
      else {
        ; Send message to channel
        var %dabass = $sqlpotatopick($nick,%p)
        ; speak -l $+($nick,$chr(44),%dabass)
        msg $chan $nick --> %dabass
        ; Set cooldown
        if ($nick != dreadfullydespized) {
          set -eu1300 %floodpick On
        }
      }
    }
    elseif ($1 == !potatorun) {
      if ((%floodrun) && ($nick != dreadfullydespized)) {
        msg $chan $nick --> $1 is on cooldown for $var(%floodrun,1).secs seconds.
      }
      else {
        if ($2 isnum 1 - 2500) {
          if (%p isnum $2 -) {
            if ((!$timer(prmsg1)) && (!$timer(prmsg2))) {
              msg $chan $nick --> Started a PotatoRun! If you wish to join in the adventure, !potatorun (amount of potatoes in the chat!)
              $+(timer,prmsg1) 1 60 msg $chan --> PotatoRun has ended, please standby for the results!
              $+(timer,prmsg2) 1 120 sqlprend
              if ($nick != dreadfullydespized) {
                $+(timer,runtimer1) 1 61 set -eu1300 %floodrun On
              }
              $sqlpradds($nick,$2)
            }
            elseif ($timer(prmsg1)) {
              msg $chan $nick --> Entered with $timer(prmsg1).secs seconds left in the PotatoRun!
              $sqlpradds($nick,$2)
            }
          }
          else {
            var %msg = $addtok(%msg, -->,32)
            %msg = $addtok(%msg,You need more potatoes to enter the PotatoRun.,32)
            $jsonwhisper(%twuid,%msg,$nick)
          }
        }
        else {
          var %msg = $addtok(%msg, -->,32)
          %msg = $addtok(%msg,You have to submit an amount within the following range 1-2500.,32)
          $jsonwhisper(%twuid,%msg,$nick)
        }
      }
    }
    elseif ($1 == !q) {
      if ((%floodquotes) && ($nick != dreadfullydespized)) {
        msg $chan --> $1 is on cooldown for $var(%floodquotes, 1).secs seconds.
      }
      else {
        if ($2 isnum) {
          msg $chan $nick --> $sqlqnum(row_quote,$2,$nick)
        }
        elseif ($2 == add) {
          msg $chan $nick --> $sqlqadd($nick,$3-)
        }
        elseif ($2 == with) {
          msg $chan $nick --> $sqlqwith(row_quote,$nick,$3-)
        }
        elseif ($2 == rand) {
          msg $chan $nick --> $sqlqrand(row_quote,$nick)
        }
        elseif ($2 == year) {
          if ($3 <= 2013) { 
            msg $chan $nick --> The year must be within the range of $+(2014,-,$date(yyyy))
          }
          elseif ($3 > $date(yyyy)) {
            msg $chan $nick --> One cannot hear what is said in the future.
          }
          elseif ($regex($3, (19|20)\d{2}$)) {
            msg $chan $nick --> $sqlqyrand(row_quote,$nick,$3)
          }
        }
        elseif ($2 == del) {
          if ($nick == dreadfullydespized) {
            msg $chan $nick --> $sqlqdelete($nick,row_quote2,$3)
          }
        }
      }
    }
    elseif ($1 == !qotd) {
      if ($2 == del) {
        if ($nick == dreadfullydespized) {
          msg $chan $nick --> $sqlqotddel
        }
      }
      elseif ($2 == add) {
        var %question = $3-
        var %total = $numtok(%question,32)
        var %wordy = $gettok(%question,%total,32)
        if (? isin %wordy) {
          msg $chan $nick --> $sqlqotdadd($nick,$3-)
        }
        else {
          msg $chan $nick --> You must provide it in the format of a question.
        }
      }
      else {
        var %qotds = $sqlqotd($nick)
        msg $chan $nick --> %qotds
      }
    }
    elseif ($1 == !roll) {
      if (!$2-) {
        msg $chan $nick --> you need to provide an option to roll for. Example "!roll potatoes"
      }
      else {
        msg $chan $nick --> $roll($nick,$2-)
      }
    }
    elseif ($1 == !scare) {
      if ((%floodscare) && ($nick != dreadfullydespized)) {
        msg $chan $nick --> $1 is on cooldown for $var(%floodscare, 1).secs seconds.
      }
      else {
        if ($2 isnum 1-) {
          if (%p isnum 2500-) {
            $sqlumodpvd($nick,-,2500,0,0)
            msg $chan --> $nick $sqlscare($2)
            if ($nick != dreadfullydespized) {
              set -eu300 %floodscare On
            }
          }
          else {
            msg $chan $nick --> You need 2500 or more potatoes.
          }
        }
        else {
          msg $chan $nick --> The correct syntax is !scare {number}.
        }
      }
    }
    elseif ($1 == !sharknado) {
      $wsobsgetcurscene($nick,sharknado)
    }
    elseif ($1 == !tophours) {
      if ($2 isnum 1-10) {
        msg $chan $nick --> Top Hours: $sqltophours($2)
      }
      else {
        var %default = 5
        msg $chan $nick --> Top Hours: $sqltophours(%default) || To view a different amount of hours, use !tophours $chr(123) $+ 1-10 $+ $chr(125)
      }
    }
    elseif ($1 == !tts) {
      if ((%floodivysay) && ($nick != dreadfullydespized)) {
        msg $chan $nick --> $1 is on cooldown for $var(%floodivysay, 1).secs seconds.
      }
      else {
        if (!$2) {
          msg $chan $nick --> You need to provide a number after !tts. Exmaple !tts 25 30 poopypants. Speed 0-100 50 is normal rate, pitch 0-100 50 is normal rate.
        }
        else {
          if ($2 isalnum) && ($3 isalnum) {
            if (!$4) {
              msg $chan $nick --> You didn't specify anything to be said. Example: !tts 20 20 potato! Speed 0-100 50 is normal rate, pitch 0-100 50 is normal rate.
            }
            if (%sp >= 20) {
              ;Need to use the -s for speed 0-100 50 is normal rate
              ;Need to use the -p for pitch 0-100 50 is normal rate
              ;Combined it is -sp
              $sqlticketmod($nick, -, 20, 0)
              var %speechleft = $sqlite_result($sqluname($nick))
              var %msg = $addtok(%msg, -->,32)
              %msg = $addtok(%msg,You have,32)
              %msg = $addtok(%msg,%speechleft,32)
              %msg = $addtok(%msg,tickets left.,32)
              $jsonwhisper(%twuid,%msg,$nick)
              speak -lsp $2 $3 $4- 
              if ($nick != dreadfullydespized) {
                set -eu120 %floodivysay On
              }
            }
            else {
              var %msg = $addtok(%msg, -->,32)
              %msg = $addtok(%msg,20 speech tickets required for this command.,32)
              $jsonwhisper(%twuid,%msg,$nick)
            }
          }
        }
      }
    }
    /*
    ##########################################################################################################################
    MODERATOR and above Status Section
    ##########################################################################################################################
    */
    elseif ($mod($nick,#dreadfullydespized)) {
      if ($1 == !break) {
        set %breakmsg Please take some time to take care of yourself! Go get something to eat or drink! Go to the bathroom. Possibly even stand up and stretch! Thank you, this has been a public service announcement from the DreadCast system.
        msg $chan --> Dread Says, %breakmsg
        set %ivybreak The Mighty Potato Says, %breakmsg
        speak -l %ivybreak
      }
      elseif ($1 == !clear) {
        jsonclearchat
        /clear #dreadfullydespized
        ; echo $chan 7 $nick 13Cleared 8Chat
        msg $chan $nick --> Cleared Chat
      }
      elseif ($1 == !anno) {
        if (!$2) {
          msg $chan $nick --> Format: (!anno color announcement) Please provide a color, one of the following: primary, purple, blue, green, orange.
        }
        if (!$3-) {
          msg $chan $nick --> Format: (!anno color announcement) Please provide the announcement statement that you wish to promote
        }
        $jsonchatanno($2,$3-)
      }
      elseif ($1 == !drplunder) {
        $wsobsgetcurscene($nick,drplunder)
      }
      elseif ($1 == !potatochallenge) {
        $wsobsgetcurscene($nick,potatochallenge)
      }
      elseif ($1 == !setmulti) {
        set %linky http://kadgar.net/live/dreadfullydespized/ $+ $2/ $+ $3/ $+ $4/ $+ $5/ $+ $6
        msg $chan $nick --> Multitwitch: %linky
      }
      elseif ($1 == !so) {
        if (!$2) {
          msg $chan $nick --> Please provide a valid Twitch nickname.
        }
        else {
          msg $chan $nick --> $jsonshoutout($2)
        }
      }
      elseif ($1 == !subsay) {
        ; Check for $2 to be username
        ; Check for $3 to be a digit
        if ($nick == dreadfullydespized) {
          if ($2 isalpha) {
            if ($3 isnum 1-999) {
              msg $chan $nick --> $sqlsubsay($2,$3)
            }
            else {
              msg $chan $nick --> Please provide the amount of months, between 1-999.
            }
          }
          else {
            msg $chan $nick --> Please provide a proper username.
          }
        }
        else {
          msg $chan $nick --> Well it appears you are a moderator, but you are not the DD so no for you.
        }
      }
      elseif ($1 == !bot) {
        if ($2) {
          set %bots %bots $2
          msg $chan $nick --> Added $2 to the list of known bots to ignore.
        }
        else {
          msg $chan $nick --> Please supply a name for a bot to be added to the ignore list.
        }
      }
    }
    ; Need to look into why this message was not proposed when jennyjenz tried it.
    elseif (!$mod($nick,#dreadfullydespized)) {
      var %modcmds = !break !clear !anno !drplunder !potatochallenge !setmulti !so !subsay !bot
      if ($1 == %modcmds) {
        msg $chan $nick --> You are currently not a moderator.
      }
    }
    elseif (%rank isnum -1) {
      var %regcmds = !! !biggiantchest !birthday !boobs !c !christmas !created !dread !halloween !hbday !hl !ivy !ivyq !kdr !kick !latesthighlight !pocharity !potatopick !potatorun !q !qotd !r !roll !scare !sharknado !tophours !tts 
      if ($1 == %regcmds) {
        msg $chan $nick --> You have not achieved Newb Rank.
      }
    }
  }
}

on *:TEXT:*:?,#dreadfullydespized: {
  if ($timer($nick $+ .gawintimer).secs) {
    msg $chan $nick --> Yay! we have confirmed that your are not AFK!
    $+(timer,$nick,.gawintimer) off
  }
}

#points off

on *:JOIN:#dreadfullydespized: {
  if (!$istok(%bots,$nick,32)) {
    if ($group(#points) == on) {
      $+(timer, $nick $+ .speech) 0 900 sqltickettimer $nick
      $+(timer, $nick $+ .points) 0 300 sqltimeadd $nick
    }
    var %month = $mid($date,4,2)
    var %year = $right($date,4)
    if (%month == 10) {
      var %halloween = $sqlholcheck($nick,Halloween,%year)
      if (%halloween == $false) {
        ; msg $nick You unlocked !halloween !!!! For tuning in during the October of %year $+ $chr(33) $+ $chr(33) $+ You must be a regular to use the command!
        sqlholmod $nick Halloween %year
      }
    }
    if (%month == 12) {
      var %christmas = $sqlholcheck($nick,Christmas,%year)
      if (%christmas == $false) {
        ; msg $nick You unlocked !christmas !!!! For tuning in during the month of December of %year $+ $chr(33) $+ $chr(33) $+ You must be a regular to use the command!
        sqlholmod $nick Christmas %year
      }
    }
  }
}

#points end

on *:PART:#dreadfullydespized: {
  $+(timer, $nick $+ .points) off
  $+(timer, $nick $+ .speech) off
}


/*
on 10:TEXT:!8ball *:?,#dreadfullydespized:{
  var %8ball It is certain,It is decidedly so,Without a doubt,Yes definitely,You may rely on it,As I see it, yes,Most likely,Outlook good,Yes,Signs point to yes,Reply hazy try again,Ask again later,Better not tell you now,Cannot predict now,Concentrate and ask again,Don't count on it,My reply is no,My sources say no,Outlook not so good,Very doubtful
  ;msg $chan /me 8Ball: $gettok(%8ball,$rand(1,$numtok(%8ball,44)),44)
  msg $chan /me $nick asks: $2- ..The magic 8-ball says: $gettok(%8ball,$rand(1,$numtok(%8ball,44)),44)
}

on *:TEXT:!kdrrules:?,#dreadfullydespized:{
  msg $chan  Must be 2 or more Squad Members to count.  Glitches/Bugs/Bambi's don't count unless circumstances warrant it.
}

;on *:TEXT:!kdr:?,#dreadfullydespized:{
if ($nick != dreadfullydespized) {
  if (%floodkdr) {
    msg $chan --> $1 is on cooldown for $var(%floodkdr, 1).secs seconds.
  }
  set -eu15 %floodkdr On
}
var %kills $read(kdr.txt,0)
var %deaths $read(kdr.txt,1)
var %kdr $calc(%kills / %deaths)
msg $chan K: %kills D: %deaths R: %kdr
}

alias timerdown {
; set some value
set %gatimer Countdown:
; print the value
echo -a %gatimer
; set the value to 3, decrease once per second
set -zs %gatimer 30
}
*/

; Format: /dirtest quotenumber
alias dirtest {
  echo %ec_succ -a $1
  $findfile($+(%sounds,Quotes2\),$+(Q,$1,-,$chr(42),.mp3),0,0,remove -b $iif($!isFile($1),$1-))
  run -n powershell.exe -noprofile -file $+(%dataSet,Quote-Rename.ps1,$chr(32),1)
}
