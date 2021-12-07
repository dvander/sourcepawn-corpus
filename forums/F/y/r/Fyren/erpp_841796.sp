#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "ent_remove player protection",
	author = "",
	description = "",
	version = "",
	url = ""
}

public OnPluginStart()
{
	RegConsoleCmd("ent_remove", er);
}

public Action:er(client, args)
{
	new target = GetClientAimTarget(client, false);

	/* Ha ha!  You can do this in Pawn! */
	if (1 <= target <= MaxClients)
	{
		PrintToChat(client, "Stopped you from removing %N.", target);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
