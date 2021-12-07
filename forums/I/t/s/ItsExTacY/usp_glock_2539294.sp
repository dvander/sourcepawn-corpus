#include <sourcemod>
#include <sdktools>

public Plugin myinfo =  {
	name = "!usp & !glock", 
	author = "S4muRaY'", 
	description = "", 
	version = "1.0", 
	url = "http://steamcommunity.com/id/bravefox"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_glock", GiveGlock);
	RegConsoleCmd("sm_usp", GiveUsp);
}
public Action GiveGlock(int client, int args)
{
	if (IsPlayerAlive(client))
	{
		GivePlayerItem(client, "weapon_glock");
		PrintToChat(client, "[SM]Glock was given!");
	}
	else
		PrintToChat(client, "[SM]This command is for alive players only!");
}
public Action GiveUsp(int client, int args)
{
	if (IsPlayerAlive(client))
	{
		GivePlayerItem(client, "weapon_usp");
		PrintToChat(client, "[SM]Usp was given!");
	}
	else
		PrintToChat(client, "[SM]This command is for alive players only!")
} 