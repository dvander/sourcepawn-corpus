// Original Creator "Blueraja"
// www.blueraja.com/blog


#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

#define SNOW_MODEL		"particle/snow.vmt"

int g_SnowFlake[MAXPLAYERS+1] = {-1,...};
int g_SnowFlake2[MAXPLAYERS+1] = {-1,...};
int g_SnowFlake3[MAXPLAYERS+1] = {-1,...};
int g_SnowDust[MAXPLAYERS+1] = {-1,...};

Handle g_SnowEnabled;
ConVar g_ConVar_prevent_edict_crash;

public Plugin myinfo = 
{
	name = "SM SNOWEFFECTS",
	author = "Andi67,Blueraja",
	description = "Let it snow!!",
	version = "1.0",
	url = "http://www.andi67-blog.de.vu , www.blueraja.com/blog"
	
}

public OnPluginStart()
{
	CreateConVar("sm_snoweffects", PLUGIN_VERSION, " SM SNOWEFFECTS Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_SnowEnabled	= CreateConVar("sm_snoweffects_enabled", "1", "Enables the plugin", _, true, 0.0, true, 1.0);	
	g_ConVar_prevent_edict_crash = CreateConVar("sm_snoweffects_prevent_edict_crash", "1200", "how many edicts allow display (prevent crash) 0 = disable", _, true, 0.0, true, 2048.0);	
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
}

public void OnMapStart()
{
	PrecacheModel(SNOW_MODEL);
}

public Action Event_PlayerSpawn(Handle event, const char[]name, bool dontBroadcast)
{
	if (GetConVarInt(g_SnowEnabled) == 1)	
	{
		int userid = GetEventInt(event, "userid");
		int client = GetClientOfUserId(userid);
		
		if (!IsFakeClient(client) && IsValidClient(client))
		{		
			KillSnow(client);	
			if(g_ConVar_prevent_edict_crash.IntValue != 0 && CurrentEntities() > g_ConVar_prevent_edict_crash.IntValue)
			{	
				return;
			}	
			CreateTimer(1.0, CreateSnow,userid,TIMER_FLAG_NO_MAPCHANGE);	
		}
	}
}

public Action Event_PlayerDeath(Handle event, const char[]name, bool dontBroadcast)
{
	int userid = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userid);
	
	KillSnow(client);
}

public Action CreateSnow(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (IsValidClient(client) && !IsFakeClient(client))
	{
		float vecOrigin[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", vecOrigin);
		
		g_SnowFlake[client] = CreateEntityByName("env_smokestack");
		if(g_SnowFlake[client] != -1)
		{
			DispatchKeyValueFloat(g_SnowFlake[client],"BaseSpread", 400.0);
			DispatchKeyValue(g_SnowFlake[client],"SpreadSpeed", "100");
			DispatchKeyValue(g_SnowFlake[client],"Speed", "25");
			DispatchKeyValueFloat(g_SnowFlake[client],"StartSize", 1.0);
			DispatchKeyValueFloat(g_SnowFlake[client],"EndSize", 1.0);
			DispatchKeyValue(g_SnowFlake[client],"Rate", "125");
			DispatchKeyValue(g_SnowFlake[client],"JetLength", "200");
			DispatchKeyValueFloat(g_SnowFlake[client],"Twist", 1.0);
			DispatchKeyValue(g_SnowFlake[client],"RenderColor", "255 255 255");
			DispatchKeyValue(g_SnowFlake[client],"RenderAmt", "200");
			DispatchKeyValue(g_SnowFlake[client],"RenderMode", "18");
			DispatchKeyValue(g_SnowFlake[client],"SmokeMaterial", SNOW_MODEL);
			DispatchKeyValue(g_SnowFlake[client],"Angles", "180 0 0");
			DispatchSpawn(g_SnowFlake[client]);
			ActivateEntity(g_SnowFlake[client]);
			vecOrigin[2] += 20;
			TeleportEntity(g_SnowFlake[client], vecOrigin, NULL_VECTOR, NULL_VECTOR);
			SetVariantString("!activator");
			AcceptEntityInput(g_SnowFlake[client], "SetParent", client);
			AcceptEntityInput(g_SnowFlake[client], "TurnOn");		
			
			g_SnowFlake[client] = EntIndexToEntRef(g_SnowFlake[client]);
		}
		
		g_SnowFlake2[client] = CreateEntityByName("env_smokestack");
		if(g_SnowFlake2[client] != -1)
		{
			DispatchKeyValueFloat(g_SnowFlake2[client],"BaseSpread", 300.0);
			DispatchKeyValue(g_SnowFlake2[client],"SpreadSpeed", "200");
			DispatchKeyValue(g_SnowFlake2[client],"Speed", "50");
			DispatchKeyValueFloat(g_SnowFlake2[client],"StartSize", 1.0);
			DispatchKeyValueFloat(g_SnowFlake2[client],"EndSize", 1.0);
			DispatchKeyValue(g_SnowFlake2[client],"Rate", "200");
			DispatchKeyValue(g_SnowFlake2[client],"JetLength", "200");
			DispatchKeyValueFloat(g_SnowFlake2[client],"Twist", 1.0);
			DispatchKeyValue(g_SnowFlake2[client],"RenderColor", "255 255 255");
			DispatchKeyValue(g_SnowFlake2[client],"RenderAmt", "200");
			DispatchKeyValue(g_SnowFlake2[client],"RenderMode", "18");
			DispatchKeyValue(g_SnowFlake2[client],"SmokeMaterial", SNOW_MODEL);
			DispatchKeyValue(g_SnowFlake2[client],"Angles", "180 0 0");
			
			DispatchSpawn(g_SnowFlake2[client]);
			ActivateEntity(g_SnowFlake2[client]);
			vecOrigin[2] += 85;
			TeleportEntity(g_SnowFlake2[client], vecOrigin, NULL_VECTOR, NULL_VECTOR);
			SetVariantString("!activator");
			AcceptEntityInput(g_SnowFlake2[client], "SetParent", client);
			AcceptEntityInput(g_SnowFlake2[client], "TurnOn");
			
			g_SnowFlake2[client] = EntIndexToEntRef(g_SnowFlake2[client]);
		}
		g_SnowFlake3[client] = CreateEntityByName("env_smokestack");
		if(g_SnowFlake3[client] != -1)
		{
			DispatchKeyValueFloat(g_SnowFlake3[client],"BaseSpread", 200.0);
			DispatchKeyValue(g_SnowFlake3[client],"SpreadSpeed", "300");
			DispatchKeyValue(g_SnowFlake3[client],"Speed", "75");
			DispatchKeyValueFloat(g_SnowFlake3[client],"StartSize", 1.0);
			DispatchKeyValueFloat(g_SnowFlake3[client],"EndSize", 1.0);
			DispatchKeyValue(g_SnowFlake3[client],"Rate", "250");
			DispatchKeyValue(g_SnowFlake3[client],"JetLength", "200");
			DispatchKeyValueFloat(g_SnowFlake3[client],"Twist", 1.0);
			DispatchKeyValue(g_SnowFlake3[client],"RenderColor", "255 255 255");
			DispatchKeyValue(g_SnowFlake3[client],"RenderAmt", "200");
			DispatchKeyValue(g_SnowFlake3[client],"RenderMode", "18");
			DispatchKeyValue(g_SnowFlake3[client],"SmokeMaterial", SNOW_MODEL);
			DispatchKeyValue(g_SnowFlake3[client],"Angles", "180 0 0");
			
			DispatchSpawn(g_SnowFlake3[client]);
			ActivateEntity(g_SnowFlake3[client]);
			vecOrigin[2] += 160;
			TeleportEntity(g_SnowFlake3[client], vecOrigin, NULL_VECTOR, NULL_VECTOR);
			SetVariantString("!activator");
			AcceptEntityInput(g_SnowFlake3[client], "SetParent", client);
			AcceptEntityInput(g_SnowFlake3[client], "TurnOn");		
			
			g_SnowFlake3[client] = EntIndexToEntRef(g_SnowFlake3[client]);
		}	
		CreateTimer(15.0 , CreateSnowDust, userid);		
	}		
}

public Action CreateSnowDust(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if(!IsValidClient(client))
		return Plugin_Stop;

	float m_vecOrigin[3];	
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", m_vecOrigin);
	
	g_SnowDust[client] = CreateEntityByName("info_particle_system");
	if(g_SnowDust[client] != -1)
	{
		SetEntPropEnt(g_SnowDust[client], Prop_Data, "m_hOwnerEntity", client);
		DispatchKeyValue(g_SnowDust[client], "effect_name", "snow_drift_128");
		DispatchSpawn(g_SnowDust[client]);
		
		if(IsValidEntity(g_SnowDust[client]))
		{
			TeleportEntity(g_SnowDust[client], m_vecOrigin, NULL_VECTOR, NULL_VECTOR);
			SetVariantString("!activator");
			AcceptEntityInput(g_SnowDust[client], "SetParent", client);
			AcceptEntityInput(g_SnowDust[client], "start");
			ActivateEntity(g_SnowDust[client]);			
		}
		g_SnowDust[client] = EntIndexToEntRef(g_SnowDust[client]);
	}
	return Plugin_Stop;
}

public void OnClientDisconnect(int client)
{
	KillSnow(client);
}

KillSnow(client)
{
	g_SnowFlake[client] = EntRefToEntIndex(g_SnowFlake[client]);
	
	if(g_SnowFlake[client] != INVALID_ENT_REFERENCE && IsValidEntity(g_SnowFlake[client]))
	{	
		AcceptEntityInput(g_SnowFlake[client], "Kill");
	}
	g_SnowFlake[client] = INVALID_ENT_REFERENCE;
	
	g_SnowFlake2[client] = EntRefToEntIndex(g_SnowFlake2[client]);
	if(g_SnowFlake2[client] != INVALID_ENT_REFERENCE && IsValidEntity(g_SnowFlake2[client]))
	{	
		AcceptEntityInput(g_SnowFlake2[client], "Kill");
		//PrintToChat(client,"g_SnowFlake2 kill %d",g_SnowFlake2[client]);
	}
	g_SnowFlake2[client] = INVALID_ENT_REFERENCE;
	
	g_SnowFlake3[client] = EntRefToEntIndex(g_SnowFlake3[client]);
	if(g_SnowFlake3[client] != INVALID_ENT_REFERENCE && IsValidEntity(g_SnowFlake3[client]))
	{	
		AcceptEntityInput(g_SnowFlake3[client], "Kill");
		//PrintToChat(client,"g_SnowFlake3 kill %d",g_SnowFlake3[client]);
	}	
	g_SnowFlake3[client] = INVALID_ENT_REFERENCE;
	
	g_SnowDust[client] = EntRefToEntIndex(g_SnowDust[client]);
	if(g_SnowDust[client] != INVALID_ENT_REFERENCE && IsValidEntity(g_SnowDust[client]))
	{	
		AcceptEntityInput(g_SnowDust[client], "Kill");
		//PrintToChat(client,"g_SnowDust kill %d",g_SnowDust[client]);
	}		
	g_SnowDust[client] = INVALID_ENT_REFERENCE; 
}


public Action DeleteParticle(Handle timer, any client)
{
	g_SnowDust[client] = EntRefToEntIndex(g_SnowDust[client]);
	if(g_SnowDust[client] != INVALID_ENT_REFERENCE && IsValidEntity(g_SnowDust[client]))
	{
		AcceptEntityInput(g_SnowDust[client], "Kill");
		g_SnowDust[client] = INVALID_ENT_REFERENCE;
	}
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

int CurrentEntities()
{
	int entitys = 0;
	for (int i=1;i<GetMaxEntities();i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i)) 
		{
			entitys++;
		}
	}
	return entitys;
}
