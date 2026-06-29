#include <sourcemod>

#define BLOCKKILL_VERSION "1.1"
new Handle:blockkill_enabled;

public Plugin:myinfo = 
{
	name = "Block Kill",
	author = "Xuqe Noia",
	description = "Block's the cvar KILL",
	version = BLOCKKILL_VERSION,
	url = "http://LiquidBR.com"
};

public OnPluginStart()
{
	CreateConVar( "blockkill_varsion", BLOCKKILL_VERSION, "KillBlock Version", FCVAR_NOTIFY );
	blockkill_enabled = CreateConVar("blockkill_enabled", "1", "Enable or disable KillBlock; 0 - disabled, 1 - enabled");
	RegConsoleCmd("kill", BlockKill);
}

public Action:BlockKill(client, args)
{
	if (GetConVarInt(blockkill_enabled) == 1)
	{
		PrintToChat(client, "\x04[BlockKill]\x01 The \x05kill\x01 cvar is blocked!");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}