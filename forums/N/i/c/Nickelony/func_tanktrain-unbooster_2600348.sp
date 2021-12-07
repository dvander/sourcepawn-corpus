#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required
#pragma semicolon 1

float gF_LastSpeed[MAXPLAYERS + 1];
bool gB_TouchingEntity[MAXPLAYERS + 1];
bool gB_TouchCache[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "func_tanktrain Unbooster",
	author = "Nickelony",
	description = "Makes func_tanktrain not give you an unfair boost after touching it.",
	version = "1.3",
	url = "steamcommunity.com/id/nickelony"
};

public void OnPluginStart()
{
	HookTouch();
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("player_spawn", OnPlayerSpawn);
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	HookTouch();
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	gB_TouchingEntity[client] = false;
}

void HookTouch()
{
	int ent = -1;
	
	while((ent = FindEntityByClassname(ent, "func_tanktrain")) != -1)
	{
		SDKHook(ent, SDKHook_Touch, Entity_Touch);
	}
	
	ent = -1;
	
	while((ent = FindEntityByClassname(ent, "func_tracktrain")) != -1)
	{
		SDKHook(ent, SDKHook_Touch, Entity_Touch);
	}
}

public int Entity_Touch(int entity, int client)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return;
	}
	
	if(!gB_TouchCache[client])
	{
		gB_TouchingEntity[client] = true;
	}
}

public Action OnPlayerRunCmd(int client)
{
	float fVel[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVel);
	
	if(!(GetEntityFlags(client) & FL_ONGROUND))
	{
		gB_TouchingEntity[client] = false;
	}
	
	if(!gB_TouchingEntity[client] && gB_TouchCache[client])
	{
		float fCurrentSpeed = SquareRoot(Pow(fVel[0], 2.0) + Pow(fVel[1], 2.0));
		
		if(fCurrentSpeed > 0.0)
		{
			float x = fCurrentSpeed / gF_LastSpeed[client];
			
			fVel[0] /= x;
			fVel[1] /= x;
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVel);
		}
	}
	
	gF_LastSpeed[client] = SquareRoot(Pow(fVel[0], 2.0) + Pow(fVel[1], 2.0));
	gB_TouchCache[client] = gB_TouchingEntity[client];
}
