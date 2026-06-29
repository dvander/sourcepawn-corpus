#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required
#pragma semicolon 1

// Store's every player color value;
int EntityTeam[2050];

#define EF_BONEMERGE                (1 << 0)
#define EF_NOSHADOW                 (1 << 4)
#define EF_NORECEIVESHADOW          (1 << 6)

int playerModelsIndex[MAXPLAYERS + 1] =  { -1, ... };
int playerModels[MAXPLAYERS + 1] =  { INVALID_ENT_REFERENCE, ... };
bool has_admflag[MAXPLAYERS+1];
bool nowalive[MAXPLAYERS+1];
int g_iNeon[MAXPLAYERS+1];
int g_iNeonRef[MAXPLAYERS+1] =  { INVALID_ENT_REFERENCE, ... };


public void OnPluginStart()
{
	HookEvent("player_spawn", 	Event_PlayerSpawn);
	HookEvent("player_death", 	Event_PlayerDeath);
	HookEvent("round_end", 		Event_RoundEnd);
}

public void OnClientDisconnect(int client)
{
	RemoveSkin(client);
	ResetSettings(client);
}

public void OnClientPutInServer(int client)
{
	ResetSettings(client);
}

public void OnClientPostAdminCheck(int client)
{
	has_admflag[client] = false;
	int flags = GetUserFlagBits(client);
	
	if(flags & ADMFLAG_BAN || flags & ADMFLAG_ROOT)
	{
		has_admflag[client] = true;
		nowalive[client] = false;
	}
}

public void ResetSettings(int client)
{
	playerModelsIndex[client] = -1;
	playerModels[client] = INVALID_ENT_REFERENCE;
	g_iNeon[client] = -1;
	g_iNeonRef[client] = INVALID_ENT_REFERENCE;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) < 2)
	{
		return;
	}

	if(!nowalive[client] && has_admflag[client])
	{
		CreateTimer(0.1, Timer_ReCreateGlow, client);
		for (int i = 1; i <= MaxClients; i++)
		{
			RemoveSkin(i);
		}	
	}
	else 
	{
		CreateTimer(0.0, Timer_CreateGlow, client);
	}
}

public Action Timer_ReCreateGlow(Handle timer, int client)
{
	nowalive[client] = true;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			CreateGlow(i);
		}	
	}
}

public Action Timer_CreateGlow(Handle timer, int client)
{
	if(IsValidClient(client))
	{
		RemoveSkin(client);
		CreateGlow(client);
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	nowalive[client] = false;
	RemoveSkin(client);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			RemoveSkin(i);
			nowalive[i] = true;
		}
	}
}

public void CreateGlow(int client) 
{
	if(IsPlayerAlive(client))
	{
		char model[PLATFORM_MAX_PATH];
		int skin = -1;
		GetClientModel(client, model, sizeof(model));
		skin = CreatePlayerModelProp(client, model);
		if(skin > MaxClients)
		{
			if(SDKHookEx(skin, SDKHook_SetTransmit, OnSetTransmit_All))
			{
				SetupGlow(skin, client);
			}
		}
	}	
}

public Action OnSetTransmit_All(int entity, int client)
{
	if(has_admflag[client] == true && !nowalive[client]) 
	{
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public void SetupGlow(int entity, int client)
{
	SetEntProp(entity, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(entity, Prop_Send, "m_nGlowStyle", 0);
	SetEntPropFloat(entity, Prop_Send, "m_flGlowMaxDist", 10000.0);
	int zroffset;
	if ((zroffset = GetEntSendPropOffs(entity, "m_clrGlow")) == -1)
		return;
	

	if(EntityTeam[entity] == 2)
	{
		SetEntData(entity, zroffset, 	 255, _, true);
		SetEntData(entity, zroffset + 1, 255, _, true);
		SetEntData(entity, zroffset + 2, 0, _, true);
	}
	else if(EntityTeam[entity] == 3)
	{
		SetEntData(entity, zroffset, 	 65, _, true);
		SetEntData(entity, zroffset + 1, 105, _, true);
		SetEntData(entity, zroffset + 2, 225, _, true);
	}

}

public int CreatePlayerModelProp(int client, char[] sModel)
{
	RemoveSkin(client);
	int skin = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(skin, "model", sModel);
	DispatchKeyValue(skin, "disablereceiveshadows", "1");
	DispatchKeyValue(skin, "disableshadows", "1");
	DispatchKeyValue(skin, "solid", "0");
	DispatchKeyValue(skin, "spawnflags", "256");
	SetEntProp(skin, Prop_Send, "m_CollisionGroup", 0);
	DispatchSpawn(skin);
	SetEntityRenderMode(skin, RENDER_TRANSALPHA);
	SetEntityRenderColor(skin, 0, 0, 0, 0);
	SetEntProp(skin, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_NOSHADOW|EF_NORECEIVESHADOW);
	SetVariantString("!activator");
	AcceptEntityInput(skin, "SetParent", client, skin);
	SetVariantString("primary");
	AcceptEntityInput(skin, "SetParentAttachment", skin, skin, 0);
	playerModels[client] = EntIndexToEntRef(skin);
	playerModelsIndex[client] = skin;
	EntityTeam[skin] = GetClientTeam(client);
	return skin;
}

public void RemoveSkin(int client)
{
	if(playerModelsIndex[client] > 0 && EntIndexToEntRef(playerModelsIndex[client]) == playerModels[client] && IsValidEntity(playerModelsIndex[client]))
	{
		AcceptEntityInput(playerModelsIndex[client], "Kill");
	}
	playerModels[client] = INVALID_ENT_REFERENCE;
	playerModelsIndex[client] = -1;
}

public bool IsValidClient(int client)
{
	return (1 <= client && client <= MaxClients && IsClientInGame(client));
}