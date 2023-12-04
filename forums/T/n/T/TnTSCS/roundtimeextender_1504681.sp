#include <sourcemod>

public Plugin:myinfo = 
{
    name = "Round time extender",
    author = "Richard Helgeby",
    description = "Extends the upper limit of mp_roundtime to 346 minutes (credit to DMExtra plugin)",
    version = "1.0",
    url = "http://forums.alliedmods.net/showthread.php?p=1467169"
}

/*
 * Source: http://forums.alliedmods.net/showthread.php?p=1455313
 * From DMExtra plugin.
 */

public OnPluginStart()
{
    new Handle:mp_roundtime = INVALID_HANDLE;
    mp_roundtime = FindConVar("mp_roundtime");
    SetConVarBounds(mp_roundtime, ConVarBound_Upper, true, 346.0);
}
