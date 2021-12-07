#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{	RegConsoleCmd("sm_knife", Knife, "Get a knife");
}
public Action:Knife(client, args)
{
	if (IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_knife")
		}
			else PrintToChat(client, "\x03 You must be alive to get a knife");
}
