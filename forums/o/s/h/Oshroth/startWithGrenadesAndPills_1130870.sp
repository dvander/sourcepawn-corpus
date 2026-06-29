/*
* 1.1.2
*  - Update URL in plugin info.
*  - Cleaned up some more code.
* 1.1.1
*  - Cleaned up some code.
* 1.1
*  - Added admin command sm_givepills.
* 1.0.1
*  - Increased timer so plugin will work on 16 player servers.
* 1.0
*  - Initial release.
*/

#include <sourcemod>
#include <sdktools> 
public Plugin:myinfo =
{
	name = "[L4D] Pills Here",
	author = "Crimson_Fox",
	description = "Gives pills to survivors at the start of each round.",
	version = "1.1.2",
	url = "http://forums.alliedmods.net/showthread.php?p=915033"
}

public OnPluginStart()
{
	HookEvent("round_start", EventGivePills, EventHookMode_Post);
	RegAdminCmd("sm_givepills", Command_GivePills, ADMFLAG_KICK, "Gives pills to survivors.");
}

public EventGivePills(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(30.0, GivePillsDelay);
}

public Action:GivePillsDelay(Handle:timer)
{
	GivePillsAll()
}

public Action:Command_GivePills(client, args)
{
	GivePillsAll()
}

public GivePillsAll()
{
	new flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i)==2)
		{
			FakeClientCommand(i, "give pain_pills");
			FakeClientCommand(i, "give molotov");
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}