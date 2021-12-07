/**	Description::
* 	Forces the player into a random team as soon as he connects.
*  	(Client will miss the motd windowso the first screen he will see is the
*	"Choose model" menu. 
*/
/*	Console Variables::
	sm_autojoin_enabled (Default 1) 		Turn on/off plugin.
	sm_autojoin_adminsimmune (Default 0) 	Turn on/off Admin immunity (Admins can choose team)
	------------ Waiting to be added ------------
*/
/*	Todo::
*/

#include <sourcemod>
#define PLUGIN_VERSION "1.1.0.0"
new Handle:enabled = INVALID_HANDLE;
new Handle:admin_immun = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Autojoin",
	author = "Lindgren",
	description = "Force player into a team as soon as they connect.",
	version = PLUGIN_VERSION,
	url = "http://www.swestrike.com"
}

public OnPluginStart()
{	
	CreateConVar("sm_autojoin_version", PLUGIN_VERSION, "Current Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	enabled = CreateConVar("sm_autojoin_enabled", "1", "Enable/Disable plugin");
	admin_immun = CreateConVar("sm_autojoin_adminsimmune", "0", "Admin immunity On/Off", 0, true, 0.0, true, 1.0);
}

public OnClientPutInServer(client) 
{
	// if (GetUserAdmin (i) != INVALID_ADMIN_ID)
	if (GetConVarInt(admin_immun) == 1)
	{
		if ((GetConVarInt(enabled) == 1) && (!IsFakeClient(client) && (GetUserAdmin(client) == INVALID_ADMIN_ID)))
			CreateTimer(0.1, Timer_1, any:client)	
	}
	else
	{
		if ((GetConVarInt(enabled) == 1) && (!IsFakeClient(client)))
			CreateTimer(0.1, Timer_1, any:client)
	}
}
	
public Action:Timer_1(Handle:timer, any:client)
{
	FakeClientCommand(client,"joingame");
	CreateTimer(1.0, Timer_2, any:client)
}

public Action:Timer_2(Handle:timer, any:client)
{
	ChangeClientTeam(client, 1) // Moves player back to spectator to skip the double-choice-bug
}