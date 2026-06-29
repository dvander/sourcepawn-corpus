#pragma semicolon 1

#include <sourcemod>
#include <hooker>

#define VERSION "1.0"

new Handle:Gnd = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Game Name Description Changer",
	author = "Fredd",
	description = "Changes the game name description",
	version = VERSION,
	url = "http://sourcemod.net/"
}
public OnPluginStart()
{
	CreateConVar("gndc_version", VERSION);
	RegisterHook(HK_GameNameDescription, ChangeGND);
	Gnd = CreateConVar("gnd", "");
}
public Action:ChangeGND(String:GameName[], maxlen)
{
	GetConVarString(Gnd, GameName, maxlen);
	
	if(strlen(GameName) == 0)
		return Plugin_Changed;
	
	return Plugin_Continue;
}