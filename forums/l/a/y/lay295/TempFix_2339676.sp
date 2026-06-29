#include <sourcemod>

public OnMapStart()
{
	CreateTimer(5.0, LoadStuff);
}

public Action:LoadStuff(Handle:timer)
{
	ServerCommand("mp_restartgame 1");
	ServerCommand("sm plugins unload TempFix");
}