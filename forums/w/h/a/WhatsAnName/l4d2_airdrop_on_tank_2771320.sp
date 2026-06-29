#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

native bool CreateAirdrop( const float vOrigin[3], const float vAngles[3], int initiator = 0, bool trace_to_sky = true );

ConVar TankChance;

public void OnPluginStart()
{
	TankChance = CreateConVar("airdrop_tank_chance", "25", "Chace airdrop of tank", FCVAR_NONE);
	HookEvent("tank_killed", tank_killed);
	AutoExecConfig(true, "Airdrop_ontank");
}

public void tank_killed( Event event, const char[] name, bool noReplicate )
{
	if(GetRandomInt(1, 100) <= TankChance.IntValue)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if ( !client || !IsClientInGame(client) )
			return;
		
		float vOrigin[3], vAngles[3];
	
		GetClientEyePosition(client, vOrigin);
		GetClientEyeAngles(client, vAngles);

		CreateAirdrop(vOrigin, vAngles, .trace_to_sky = true);
		
	}
}
