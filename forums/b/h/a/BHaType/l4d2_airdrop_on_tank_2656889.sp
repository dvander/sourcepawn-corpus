#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

native bool CreateAirdrop( const float vOrigin[3], const float vAngles[3], int initiator = 0, bool trace_to_sky = true );

public void OnPluginStart()
{
	HookEvent("tank_killed", tank_killed);
}

public void tank_killed( Event event, const char[] name, bool noReplicate )
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if ( !client || !IsClientInGame(client) )
		return;
		
	float vOrigin[3], vAngles[3];
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	CreateAirdrop(vOrigin, vAngles, .trace_to_sky = true);
}
