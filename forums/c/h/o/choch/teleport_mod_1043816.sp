#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.0.2"

new Float:g_Location[33][3];
new Handle:c_Enabled = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Teleport Mod",
	author = "Peter Maciocia (original by Dean Poot)",
	description = "Teleport Mod - This mod is ment to be used on jump servers so players can save there location using !saveloc and teleport to there location using !teleport",
	version = PL_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("teleport_mod_version", PL_VERSION, "Teleport Mod", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	c_Enabled   = CreateConVar("sm_teleport_enable",    "0",        "<0/1> Enable teleport mod");
	RegConsoleCmd("sm_saveloc", Save_Loc);
	RegConsoleCmd("sm_teleport", Teleport_User);

	HookEvent("player_team", Event_PlayerTeam);

	new maxClients = GetMaxClients();		
	for (new i=1; i<=maxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		g_Location[i][0] = 0.0;
		g_Location[i][1] = 0.0;
		g_Location[i][2] = 0.0;
	}
}

public OnClientPutInServer(client)
{
		g_Location[client][0] = 0.0;
		g_Location[client][1] = 0.0;
		g_Location[client][2] = 0.0;
}

public Action:Save_Loc(client,args)
{
	if(GetConVarInt(c_Enabled)) {
		GetClientAbsOrigin(client, g_Location[client]);
		ReplyToCommand(client, "[SM] Your location has been saved");
	}

	return Plugin_Handled;

}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);

	g_Location[client][0] = 0.0;
	g_Location[client][1] = 0.0;
	g_Location[client][2] = 0.0;
}
	

public Action:Teleport_User(client,args)
{
	if(GetConVarInt(c_Enabled)) {
		if( IsPlayerAlive(client) ) {
			if (g_Location[client][1] != 0) {

				ReplyToCommand (client, "[SM] You have been teleported");

				TeleportEntity(client, g_Location[client], NULL_VECTOR, NULL_VECTOR);
			} else {
				ReplyToCommand (client, "[SM] You have not saved a location (use sm_saveloc)");
			}
		} else {
			ReplyToCommand (client, "[SM] Cannot teleport while dead");
		}
	}
	
	return Plugin_Handled;
}
