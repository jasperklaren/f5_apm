when RULE_INIT {
    set static::access_debug 1
    #The logonpage and logoffURI must be entered in all lower case below so when the stringtolower command compares the real path with the static variables, they match correctly
    #Do not set loginpage variable to my.policy, let the APM redirects occur
    set static::logonpage "https://fqdn"
    set static::logoffURI "/citrix/remoteweb/authentication/logoff" 

}
when CLIENT_ACCEPTED {
    #Set this variable early on to avoid TCL errors
    set ctxloggedoutsessions 0
}

when ACCESS_ACL_ALLOWED {
    if {$static::access_debug > 1 } { log local0. "client=[IP::client_addr] uri=[HTTP::uri] | session=[ACCESS::session sid] | client=[IP::client_addr]:[TCP::client_port]" }


    # Has the user logged off? (Changed to http_uri instead of http_path 6-17-2014)
    if {[string tolower [HTTP::uri]] eq $static::logoffURI } {
        if {$static::access_debug == 1 } { log local0. "client=[IP::client_addr] Detected logoff!" }

        # need to track the sessionID because after the redirect has been sent, the browser may use an
        # already established (access granted) tcp connection that will be allowed through ACCESS_ACL_ALLOWED.

        set ctxloggedoutsessions ctxloggedoutsessions_[ACCESS::session sid]

        table add $ctxloggedoutsessions 1 60 90

        # store the APM session cookies from the request.
        if {[HTTP::cookie exists "MRHSession"]} {
            set MRHSession [HTTP::cookie MRHSession]
            if {$static::access_debug} { log local0. "client=[IP::client_addr] MRHSession=$MRHSession" }
        }

        if {[HTTP::cookie exists "LastMRH_Session"]} {
            set LastMRH_Session [HTTP::cookie LastMRH_Session]
            if {$static::access_debug} { log local0. "client=[IP::client_addr] LastMRH_Session =$LastMRH_Session " }
        }
    }

    set type [ACCESS::session data get session.client.type]
    if { !($type starts_with "citrix") } {
        if { [HTTP::uri] == "/" } {
            log local0. "client=[IP::client_addr] Redirecting to /Citrix/RemoteWeb/"
            ACCESS::respond 302 Location "https://[HTTP::host]/Citrix/RemoteWeb"
        }
    }
}

when HTTP_REQUEST {
    if { ( [HTTP::cookie exists MRHSession] ) and ( [ACCESS::session exists -state_allow [HTTP::cookie value MRHSession]] ) } {
        # authenticated request, do nothing
    }
    else {
        if {$static::access_debug == 1 } { log local0. "client=[IP::client_addr] non-authenticated request" }
        # non-authenticated request
        if {[string tolower [HTTP::uri]] eq "/citrix/remoteweb" } {
            HTTP::respond 302 noserver Location "$static::logonpage" "X-OLL-CTX-LOGOUT" "1" "Connection" "Close"
            TCP::close
        }
    }
}

when HTTP_RESPONSE {

    set sessionstatus [table lookup $ctxloggedoutsessions]

    # check if this reponse is for a session that has been marked as logged off.
    if {$sessionstatus == 1} {
        # yes, user has logged off.

        if {$static::access_debug} { log local0. "client=[IP::client_addr] Found session [ACCESS::session sid] in table" }
        set cookieheaders ""

        # prepare the APM session cookies to be expired by setting the date to UNIX TS 0
        if { [info exists MRHSession] } {
            set cookieheaders "MRHSession=$MRHSession;expires=Thu, 01-Jan-1970 00:00:00 GMT;path=/;"
            if {$static::access_debug} { log local0. "client=[IP::client_addr] setting cookie, MRHSession" }
            unset MRHSession
        }

        if { [info exists LastMRH_Session] } {
            set cookieheaders "$cookieheaders\r\nSet-Cookie: LastMRH_Session=$LastMRH_Session;expires=Thu, 01-Jan-1970 00:00:00 GMT;path=/;"
            if {$static::access_debug} { log local0. "client=[IP::client_addr] setting cookie, LastMRH_Session" }
            unset LastMRH_Session
        }

        if {$static::access_debug > 0 } { log local0. "client=[IP::client_addr] Custom cookies: $cookieheaders" }

            # Send a redirect response to the client. With Connection: Close!
            if { $cookieheaders != "" } {
                HTTP::respond 302 noserver Location "$static::logonpage" "Set-Cookie" $cookieheaders "X-OLL-CTX-LOGOUT" "1" "Connection" "Close"
                TCP::close
            } else {
                HTTP::respond 302 noserver Location "$static::logonpage" "X-OLL-CTX-LOGOUT" "1" "Connection" "Close"
                TCP::close
        }
    }
}
