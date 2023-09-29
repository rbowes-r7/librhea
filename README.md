This library is a demonstration of an authentication bypass in TitanMFT, and
the consequences therefrom.

I've implemented two scripts - an arbitrary file write, and an arbitrary file
read - both of which can be executed with or without credentials.

Without credentials, it will wait for an administrator to start a session, at
which point it should just execute. That's an authentication bypass that we've
reported.

With credentials, it will likely just work, because it's not really a
vulnerability - just how the server can be misused.
