#include <sourcemod>

#define PLUGIN_VERSION 		"1.0.0.0"

public Plugin:myinfo = 
{
	name = "Spectator Kicker",
	author = "Wazz",
	description = "Kicks players that are in spectator",
	version = PLUGIN_VERSION,
};

new Handle:sm_skicker_admins;
new Handle:sm_skicker_time;

public OnPluginStart()
{		
	sm_skicker_admins = CreateConVar("sm_skicker_admins", "1", "If enabled (1) then admins will not be kicked for idling in spectator", 0, true, 0.0);
	sm_skicker_time = CreateConVar("sm_skicker_time", "10", "Time in seconds before spectator is kicked", 0, true, 0.0);
	
	CreateConVar("sm_skicker_version", PLUGIN_VERSION, "Server Spectator Kicker version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookEvent("player_team", OnPlayerTeam);
}

public Action:OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);

	if(IsValidClient(client) && IsClientInGame(client))
	{
		new bool:areAdminsImmune = GetConVarBool(sm_skicker_admins)
		if ((GetUserAdmin(client) != INVALID_ADMIN_ID) && areAdminsImmune)
			return Plugin_Handled;

		new team = GetEventInt(event, "team");
		if (team == 1)
		{
			new Float:time = float(GetConVarInt(sm_skicker_time));
			CreateTimer(time, SpectatorTimer, client);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Handled;
}

public Action:SpectatorTimer(Handle:timer, any:client)
{
	if (!client || !IsClientInGame(client) || (GetClientTeam(client) != 1))
		return Plugin_Handled;
	else	
		KickClient(client, "You are not allowed to idle in spectator");	 				
		
	return Plugin_Handled;
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}