alias mpstart {
    $wsobssetsceneip(MiniPotato,true,minipotato)
    msg %mychan MiniPotato sighted!!!!
}

on *:SIGNAL:WEBSOCKET_DATA_obsws: {
    noop $WebSockFrame(&obsws)
    JSONOpen -db obsws &obsws
    var %msgid = $json(obsws, message-id).value
    ; This will only happen if on the Game Scene
    if (($JSON(obsws, scene-name).value === $+(Game,$chr(32),$chr(45),$chr(32),2)) || ($JSON(obsws, name).value === $+(Game,$chr(32),$chr(45),$chr(32),2))) {
        if ($gettok(%msgid,1,126) === check) {
            var %name = $gettok(%msgid,3,126)
            ; Initial Payload reading
            if ($gettok(%msgid,2,126) === minipotato) {
                var %payload = $+($v1,~,%name)
                ; payload is minipotato~dreadfullydespized
                $wsobsgetsceneip(MiniPotato,%payload)
            }
        }
        ; If there is no timer then create one to check
        ; This is the first thing to happen
        elseif (!$timer(minipotato)) {
            $+(timer,minipotato-check) 1 30 wsobsgetcurscene dreadfullydespized minipotato
        }
    }
    ; This will fire off for all scenes
    elseif ($gettok(%msgid,1,126) === minipotato) {
        if ($JSON(obsws, visible).value === $false) {
            if (!$timer(minipotato).secs) || (!$timer(minipotato-off).secs) {
                var %minipotatotimer = $rand(1200,2400)
                var %mpcleantimer = %minipotatotimer - 30
                var %minipotatotimer2 = %minipotatotimer + 40
                $+(timer,minipotato-clean) 1 %mpcleantimer sqlmpclean
                $+(timer,minipotato) 1 %minipotatotimer mpstart
                $+(timer,minipotato-off) 1 %minipotatotimer2 wsobssetsceneip MiniPotato false minipotato
                $+(timer,minipotato-check) 0 300 wsobsgetcurscene dreadfullydespized minipotato
            }
        }
    }
}

; This handles if I manually disconnect from obs before closing it
on *:SIGNAL:WebSocket_CLOSE_obsws:{
    $+(timer,minipotato-check) off
    $+(timer,minipotato-off) off
    $+(timer,minipotato) off
}

; This handles if I just close obs
on *:SIGNAL:WebSocket_FINISHED_obsws:{
    $+(timer,minipotato-clean) off
    $+(timer,minipotato-check) off
    $+(timer,minipotato-off) off
    $+(timer,minipotato) off
}