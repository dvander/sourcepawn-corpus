#pragma semicolon 1
#pragma newdecls required
 
#include <sdktools>
#include <sdkhooks>
 
int viTimerDude[MAXPLAYERS+1], pipebomb[MAXPLAYERS+1];
Handle vTimerPipe[MAXPLAYERS+1], sdkKillPipe;
ConVar iTimerPipeBomb;
Handle gTimer;
bool g_bAllow[MAXPLAYERS + 1];
 
// ====================================================================================================
//				PLUGIN INFO / START / END / CVARS
// ====================================================================================================
 
public Plugin myinfo =
{
	name = "[L4D2] Realistico",
	author = "BHaType",
	description = "Makes pipe bomb more real.",
	version = "0.4",
	url = "https://steamcommunity.com/profiles/76561198865209991/"
}
 
public void OnPluginStart()
{
	Handle hGameConf = LoadGameConfigFile("Realistico.GameData");
	StartPrepSDKCall(view_as<SDKCallType>(1));
	if (!(PrepSDKCall_SetFromConf(hGameConf, view_as<SDKFuncConfSource>(1), "iDetonatePipeBomb")))
		SetFailState("Could not load the \"iDetonatePipeBomb\" gamedata signature.");
	sdkKillPipe = EndPrepSDKCall();
	
	iTimerPipeBomb = FindConVar("pipe_bomb_timer_duration");
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
}
 
public Action Event_RoundEnd(Handle event, const char[] name, bool dontbroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		viTimerDude[i] = 0;
		pipebomb[i] = 0;
		if(vTimerPipe[i] != null)
		{
			KillTimer(vTimerPipe[i]);
			vTimerPipe[i] = null;
		}
		g_bAllow[i] = false;
	}
	if(gTimer != null)
	{
		KillTimer(gTimer);
		gTimer = null;
	}
}
 
public Action TimerOut(Handle timer)
{
	bool set;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && viTimerDude[i] > 0)
		{
			if (!g_bAllow[i])
			{
				int iWeapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
				
				if (iWeapon <= MaxClients || !IsPipe(iWeapon))
					continue;
			}
			
			viTimerDude[i]--;
			PrintHintText(i, "Time to detonate %d", viTimerDude[i]);
			set = true;
		}
	}
 
	if( !set )
	{
		gTimer = null;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
 
// ====================================================================================================
//				Plugin / Hooks
// ====================================================================================================
 
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (vTimerPipe[client] == null)
	{
		int iCurrentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
 
		if (!IsValidEntity(iCurrentWeapon))
			return Plugin_Continue;
 
		char weaponclass[32];
		GetEntityClassname(iCurrentWeapon, weaponclass, sizeof(weaponclass));
		if (buttons & IN_ATTACK)
		{
			if (strcmp(weaponclass, "weapon_pipe_bomb") == 0)
			{
				viTimerDude[client] = iTimerPipeBomb.IntValue;
				vTimerPipe[client] = CreateTimer(float(viTimerDude[client]), timerpipe, GetClientUserId(client));
				if( gTimer == null )
					gTimer = CreateTimer(1.0, TimerOut, _, TIMER_REPEAT);
			}
		}
	}
	else
	{
		if (!(buttons & IN_ATTACK))
		{
			KillTimer(vTimerPipe[client]);
			vTimerPipe[client] = null;
			CreateTimer(float(viTimerDude[client]), TimerBomb, GetClientUserId(client));
			g_bAllow[client] = true;
 		}
		//
	}
	return Plugin_Continue;
}
 
public Action TimerBomb(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	if(!client || !IsClientInGame(client)) return;
	if (IsValidEntRef(pipebomb[client]))
	{
		int entity = EntRefToEntIndex(pipebomb[client]);
		SDKCall(sdkKillPipe, entity);
	}
	g_bAllow[client] = false;
}
 
public Action timerpipe(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	if(!client || !IsClientInGame(client)) return;
	vTimerPipe[client] = null;
	int iPipe = GetPlayerWeaponSlot(client, 2);
	if (IsValidEntity(iPipe))
	{
		RemovePlayerItem(client, iPipe);
		AcceptEntityInput(iPipe, "Kill");
	}
	ForcePlayerSuicide(client);
	float vPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", vPos);
	vPos[2] += 40.0;
	int entity = CreateEntityByName("prop_physics");
	if(IsValidEntity(entity))
	{
		DispatchKeyValue(entity, "model", "models/props_junk/propanecanister001a.mdl");
		DispatchSpawn(entity);
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "break");
	}
}
 
public void OnEntityCreated(int entity, const char[] class)
{
	if (strcmp(class, "pipe_bomb_projectile") == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, SpawnPost);
	}
}
 
public void SpawnPost(int entity)
{
	RequestFrame(nextFrame, EntIndexToEntRef(entity));
}
 
public void nextFrame(int entity)
{
	if( (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
	{
		int client;
		if ((client = GetEntPropEnt(entity, Prop_Data, "m_hThrower")) > 0 && IsClientInGame(client))
		{
			pipebomb[client] = EntIndexToEntRef(entity);
		}
	}
}
 
public Action OnHeSpawned(Handle timer, any ent)
{
	int client;
	if ((ent = EntRefToEntIndex(ent)) > 0 && (client = GetEntPropEnt(ent, Prop_Data, "m_hThrower")) > 0 && IsClientInGame(client))
	{
		pipebomb[client] = EntIndexToEntRef(ent);
	}
}
 
// ====================================================================================================
//				Stocks
// ====================================================================================================

bool IsPipe(int entity)
{
	char szClassname[36];
	GetEntityClassname(entity, szClassname, sizeof szClassname);
	
	if (strcmp(szClassname, "weapon_pipe_bomb") == 0)
		return true;
	return false;
}

bool IsValidEntRef(int iEnt)
{
	if (iEnt && EntRefToEntIndex(iEnt) != INVALID_ENT_REFERENCE)
		return true;
	return false;
}
 
stock bool bIsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && !IsClientInKickQueue(client) && IsPlayerAlive(client);
}