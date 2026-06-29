#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new Float:NextUseRock[MAXPLAYERS+1];

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public OnMapStart()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		NextUseRock[i] = 0.0;
	}
}

public Event_PlayerSpawn(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(IsSpitter(client) && GetClientTeam(client) == 3)
	{
		NextUseRock[client] = GetGameTime() + 3.0;
	}
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
		
	if(IsSpitter(client) && !IsGhost(client) && GetClientTeam(client) == 3)
	{
		if ((buttons & IN_ATTACK2) && GetGameTime() > NextUseRock[client])
		{
			NextUseRock[client] = GetGameTime() + 10.0;
			//PrintToChat(client,"rock thrown");
			
			new thrower = CreateEntityByName("env_rock_launcher");
			DispatchKeyValue(thrower,"Rock Damage Override", "10");
			DispatchSpawn(thrower);
			
			decl Float:pos[3];
			decl Float:ang[3];
			decl Float:npos[3];
			GetClientAbsOrigin(client,pos);
			GetClientEyeAngles(client,ang);
			npos[0] = (pos[0] + 50 * Cosine(DegToRad(ang[1])));
			npos[1] = (pos[1] + 50 * Sine(DegToRad(ang[1])));
			npos[2] = (pos[2] + 150);
			
			TeleportEntity(thrower,npos,ang,NULL_VECTOR);
			AcceptEntityInput(thrower, "LaunchRock");
			AcceptEntityInput(thrower, "Kill");			
		}
	}
}

stock IsGhost(client)
{
	return GetEntProp(client, Prop_Send, "m_isGhost");
}

stock bool:IsSpitter(client)
{
    if (GetEntProp(client, Prop_Send, "m_zombieClass") == 4) return true;
    return false;
}

public Plugin:myinfo =
{
	name = "spitter throws rocks",
	author = "spirit",
	description = "spitter throws tank rocks",
	version = "1",
	url = "1.0"
};