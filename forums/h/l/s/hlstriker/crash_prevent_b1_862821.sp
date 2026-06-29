#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Crash Prevent",
	author = "hlstriker",
	description = "Trying to prevent server crash",
	version = "1.0",
	url = "None"
}

new Handle:sv_rcon_minfailuretime;
new Handle:sv_rcon_minfailures;
new Handle:sv_rcon_maxfailures;

public OnPluginStart()
{
	sv_rcon_minfailuretime = FindConVar("sv_rcon_minfailuretime");
	sv_rcon_minfailures = FindConVar("sv_rcon_minfailures");
	sv_rcon_maxfailures = FindConVar("sv_rcon_maxfailures");
	SetConVarBounds(sv_rcon_minfailures, ConVarBound_Upper, false);
	SetConVarBounds(sv_rcon_maxfailures, ConVarBound_Upper, false);
}

public OnConfigsExecuted()
{
	SetConVarInt(sv_rcon_minfailuretime, 1);
	SetConVarInt(sv_rcon_minfailures, 9999999999);
	SetConVarInt(sv_rcon_maxfailures, 9999999999);
}