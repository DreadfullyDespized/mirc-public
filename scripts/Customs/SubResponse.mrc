#raw on
/*
##########################################################################################################################
This section is the speech based aliases.
##########################################################################################################################
*/

alias getNameFromTags {
    if ($msgtags(display-name).key != $null) {
        return $replace($msgtags(display-name).key,\s,$chr(32))
    }
    elseif ($msgtags(login).key != $null) {
        return $msgtags(login).key
    }
    return $nick
}
/*
##########################################################################################################################
This section is the raw based aliases.
##########################################################################################################################
# user-id														> User id of the subscriber/gifter
# login															> User name of the subscriber/gifter
# display-name											> Display name of the subscriber/gifter
# msg-id														> Type of notice; sub, resub, charity, subgift
# msg-param-cumulative-months                       > Amount of consecutive months
# msg-param-multimonth-duration
# msg-param-multimonth-tenure
# msg-param-should-share-streak
# msg-param-streak-months                           > Amount of months in sub streak
# msg-param-sub-plan								> sub plan; prime, 1000, 2000, 3000
# msg-param-recipient-id 						> user id of the gift receiver
# msg-param-recipient-user-name			> user name of the gift receiver
# msg-param-recipient-display-name	> display name of the gift receiver
*/

/*
Example to parse:

This is a resub.
display-name=Raas2627;
msg-id=resub;
msg-param-cumulative-months=16;
msg-param-months=0;
msg-param-multimonth-duration=0;
msg-param-multimonth-tenure=0;
msg-param-should-share-streak=1;
msg-param-streak-months=14;
msg-param-sub-plan-name=Tiny\sPotato;
msg-param-sub-plan=1000;
msg-param-was-gifted=false;
system-msg=Raas2627\ssubscribed\sat\sTier\s1.\sThey've\ssubscribed\sfor\s16\smonths,\scurrently\son\sa\s14\smonth\sstreak!;
PRIVMSG #dreadfullydespized :04Raas2627 subscribed at Tier 1. They've subscribed for 16 months, currently on a 14 month streak!

This is a sub gifted from anonymous to move_37
display-name=AnAnonymousGifter;
msg-id=subgift;
msg-param-gift-months=1;
msg-param-months=2;
msg-param-origin-id=80\sbe\s9c\s87\sf3\s59\sf1\s00\sd8\s18\s92\sa6\s75\sb8\saf\s55\s4e\s34\sd5\see;
msg-param-recipient-display-name=move_37;
msg-param-recipient-id=449977924;
msg-param-recipient-user-name=move_37;
msg-param-sub-plan-name=Tiny\sPotato;
msg-param-sub-plan=1000;
system-msg=An\sanonymous\suser\sgifted\sa\sTier\s1\ssub\sto\smove_37!\s;

*/

alias sqlresubhandler {
    var %subplan = $1
    var %uid = $2
    var %nick = $3
    var %total = $4
    if (%subplan == prime) {
        $sqlsubhandler(%uid,%nick,%total,1,0,0,0,0,0,0,0,0)
    }
    elseif (%subplan == 1000) {
        $sqlsubhandler(%uid,%nick,%total,0,1,0,0,0,0,0,0,0)
    }
    elseif (%subplan == 2000) {
        $sqlsubhandler(%uid,%nick,%total,0,0,1,0,0,0,0,0,0)
    }
    elseif (%subplan == 3000) {
        $sqlsubhandler(%uid,%nick,%total,0,0,0,1,0,0,0,0,0)
    }
}

/*
##########################################################################################################################
Commands that would use the aliases
##########################################################################################################################
*/
; Room-id is correct in terms of the numerical id being presented.
; msg-id == sub or resub or subgift is correct in terms of getting the right parameter.
; $msgtags returns the @ prefixed tags (IRCv3 message tags) which are removed from incoming server messages.

alias checksub {
    var %nick = $1
    IF ((%nick == %streamer) || ($isMTSub(%nick))) {
        RETURN $true
    } 
}

alias isMTSub {
    IF (($IIF($1,$1,$nick) == %streamer) || ($msgtags(subscriber).key)) {
        RETURN $true
    }
}

raw USERNOTICE:*:{
    ; This checks to see if you are in #dreadfullydespized
    var %reason = Twitch Subscription
    if ($msgtags(msg-id).key == subgift) {
        var %praise = Please say this with me.  Praise be to the Peel!!!!!
        var %userid_from = $msgtags(user-id).key
        var %userid_to = $msgtags(msg-param-recipient-id).key
        var %nick_from = $iif($msgtags(display-name).key,$v1,$msgtags(login).key)
        var %nick_to = $msgtags(msg-param-recipient-user-name).key
        var %cumu_months = $msgtags(msg-param-cumulative-months).key
        var %stre_months = $msgtags(msg-param-streak-months).key
        var %months = $msgtags(msg-param-months).key
        var %sub_plan = $msgtags(msg-param-sub-plan).key
        $sqlcsu(%nick_to,%reason)
        ; t1
        if (%sub_plan == 1000) {
            ; Update the Gifter
            $sqlsubhandler(%userid_from,%nick_from,0,0,0,0,0,0,1,1,0,0)
            ; Update the Recipient
            $sqlsubhandler(%userid_to,%nick_to,%cumu_months,0,1,0,0,1,0,0,0,0)
            var %message = %nick_from, You are extremely kind. Thank you for giving %nick_to this wonderful gift.  Axomamma thanks you.  %praise
            $+(timer,t1subgift) 1 20 speak %message
            echo %ec_debug -a Tier 1 Gift Sub - %nick_from - %nick_to
        }
        ; t2
        elseif (%sub_plan == 2000) {
            $sqlsubhandler(%userid_from,%nick_from,0,0,0,0,0,0,1,0,1,0)
            $sqlsubhandler(%userid_to,%nick_to,%cumu_months,0,0,1,0,1,0,0,0,0)
            var %message = %nick_from, I am sincerely impressed with that you have done for %nick_to. Truly Thank you.  Axomamma thanks you.  %praise
            $+(timer,t2subgift) 1 20 speak %message
            echo %ec_debug -a Tier 2 Gift Sub - %nick_from - %nick_to
        }
        ; t3
        elseif (%sub_plan == 3000) {
            $sqlsubhandler(%userid_from,%nick_from,0,0,0,0,0,0,1,0,0,1)
            $sqlsubhandler(%userid_to,%nick_to,%cumu_months,0,0,0,1,1,0,0,0,0)
            var %message = %nick_from, This level of a gift is insane!!!! %nick_to you are very very fortunate.  Axomamma thanks you from the bottom of her heart!!! Truly a remarkable moment. %praise
            $+(timer,t3subgift) 1 20 speak %message
            echo %ec_debug -a Tier 3 Gift Sub - %nick_from - %nick_to
        }
    }
    elseif ($msgtags(msg-id).key == resub) {
        var %praise = Please say this with me.  Praise be to the Peel!!!!!
        var %userid = $msgtags(user-id).key
        var %nick = $msgtags(display-name).key
        var %cumu_months = $msgtags(msg-param-cumulative-months).key
        var %stre_months = $msgtags(msg-param-streak-months).key
        var %months = $msgtags(msg-param-months).key
        var %sub_plan = $msgtags(msg-param-sub-plan).key
        $sqlresubhandler(%sub_plan,%userid,%nick,%cumu_months)
        $sqlcsu(%nick,%reason)
        ; month 2
        ; if ($msgtags(msg-param-months).key == 2) {
        if (%cumu_months == 2) {
            $+(timer,m2sub) 1 20 sqlsubsay %nick %cumu_months
            echo %ec_debug -a 2 Month Resub - %nick
        }
        ; month 6
        elseif (%cumu_months == 6) {
            $+(timer,m6sub) 1 20 sqlsubsay %nick %cumu_months
            echo %ec_debug -a 6 Month Resub - %nick
        }
        ; month 9
        elseif (%cumu_months == 9) {
            $+(timer,m9sub) 1 20 sqlsubsay %nick %cumu_months
            echo %ec_debug -a 9 Month Resub - %nick
        }
        ; month 12
        elseif (%cumu_months == 12) {
            $+(timer,m12sub) 1 20 sqlsubsay %nick %cumu_months
            echo %ec_debug -a 12 Month Resub - %nick
        }
        ; month 24
        elseif (%cumu_months == 24) {
            $+(timer,m24sub) 1 20 sqlsubsay %nick %cumu_months
            echo %ec_debug -a 24 Month Resub - %nick
        }
        ; month 36
        elseif (%cumu_months == 36) {
            $+(timer,m36sub) 1 20 sqlsubsay %nick %cumu_months
            echo %ec_debug -a 36 Month Resub - %nick
        }
        ; month 48
        elseif (%cumu_months == 48) {
            $+(timer,m48sub) 1 20 sqlsubsay %nick %cumu_months
            echo %ec_debug -a 48 Month Resub - %nick
        }
        ; month 60
        elseif (%cumu_months == 60) {
            $+(timer,m60sub) 1 20 sqlsubsay %nick %cumu_months
            echo %ec_debug -a 60 Month Resub - %nick
        }
        ; month 84
        elseif (%cumu_months == 84) {
            $+(timer,m84sub) 1 20 sqlsubsay %nick %cumu_months
            echo %ec_debug -a 84 Month Resub - %nick
        }
        ; month 100
        elseif (%cumu_months == 100) {
            $+(timer,m100sub) 1 20 sqlsubsay %nick %cumu_months
            echo %ec_debug -a 100 Month Resub - %nick
        }
    }
    elseif ($msgtags(msg-id).key == sub) {
        var %praise = Please say this with me.  Praise be to the Peel!!!!!
        var %userid = $msgtags(user-id).key
        var %nick = $msgtags(display-name).key
        var %cumu_months = $msgtags(msg-param-cumulative-months).key
        var %stre_months = $msgtags(msg-param-streak-months).key
        var %months = $msgtags(msg-param-months).key
        var %sub_plan = $msgtags(msg-param-sub-plan).key
        $sqlcsu(%nick,%reason)
        ; prime
        if (%sub_plan == Prime) {
            $sqlsubhandler(%userid,%nick,%cumu_months,1,0,0,0,0,0,0,0,0)
            $+(timer,primesub) 1 20 sqlsubsay %nick prime
            echo %ec_debug -a Prime Sub - %nick
        }
        ; t1
        elseif (%sub_plan == 1000) {
            $sqlsubhandler(%userid,%nick,%cumu_months,0,1,0,0,0,0,0,0,0)
            $+(timer,t1sub) 1 20 sqlsubsay %nick t1
            echo %ec_debug -a Tier 1 Sub - %nick
        }
        ; t2
        elseif (%sub_plan == 2000) {
            $sqlsubhandler(%userid,%nick,%cumu_months,0,0,1,0,0,0,0,0,0)
            $+(timer,t2sub) 1 20 sqlsubsay %nick t2
            echo %ec_debug -a Tier 2 Sub - %nick
        }
        ; t3
        elseif (%sub_plan == 3000) {
            $sqlsubhandler(%userid,%nick,%cumu_months,0,0,0,1,0,0,0,0,0)
            $+(timer,t3sub) 1 20 sqlsubsay %nick t3
            echo %ec_debug -a Tier 3 Sub - %nick
        }
    }
}

#raw end