#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <steamtools>

#define PLUGIN_VERSION	"0.2.1"


new gVelocityOffset;
new g_EntList[MAXPLAYERS + 1];
new String:g_sSpritePrem[PLATFORM_MAX_PATH+1];
new String:g_sSpriteFree[PLATFORM_MAX_PATH+1];

new Handle:g_hStatusVersion = INVALID_HANDLE;
new Handle:g_hStatusEnable = INVALID_HANDLE;
new Handle:g_hPremSprite = INVALID_HANDLE;
new Handle:g_hFreeSprite = INVALID_HANDLE;
new Handle:g_hPremAnimated = INVALID_HANDLE;
new Handle:g_hPremFramerate = INVALID_HANDLE;
new Handle:g_hFreeAnimated = INVALID_HANDLE;
new Handle:g_hFreeFramerate = INVALID_HANDLE;

new bool:g_bRoundEnded = false;

public Plugin:myinfo = 
{
	name = "[TF2] Status Reveal",
	author = "gH0sTy",
	description = "Reveal the premium or F2P status.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=162395"
}

IsFree2Play(client)
{
	new result = -1;
	
	if(!client || !IsClientInGame(client))
		result = -1;
	else if (Steam_CheckClientSubscription(client, 0) && !Steam_CheckClientDLC(client, 459))
		result = 1;
	else
		result = 0;
		
	return result;
}

public OnAllPluginsLoaded()
{
	decl String:extError[265];
	
	new extStatus = GetExtensionFileStatus("steamtools.ext", extError, sizeof(extError));
	
	if(extStatus == -2)
		SetFailState("SteamTools extension was not found.");
	else if(extStatus == -1)
		SetFailState("SteamTools extension was found but failed to load (%s).",extError);
	else if(extStatus == 0)
		SetFailState("SteamTools extension loaded but reported an error (%s).",extError);
	
}

public OnPluginStart()
{
	g_hStatusVersion	= CreateConVar("tf2_status_reveal_version", PLUGIN_VERSION, "Status Reveal Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hStatusEnable		= CreateConVar("tf2_status_reveal_enable","1","Enable/Disable Status Reveal",FCVAR_PLUGIN);
	g_hPremSprite		= CreateConVar("tf2_srs_premium","custom/premium","Set the sprite to use for Premium players, relative to the materials folder. \n>>> DO NOT INCLUDE THE .vtf .vmt file extension! <<<",FCVAR_PLUGIN);
	g_hFreeSprite		= CreateConVar("tf2_srs_free","custom/free","Set the sprite to use for F2P players, relative to the materials folder. \n>>> DO NOT INCLUDE THE .vtf .vmt file extension! <<<",FCVAR_PLUGIN);
	g_hPremAnimated		= CreateConVar("tf2_srs_prem_animated","0","Set to 1 if the Premium sprite is animated.",FCVAR_PLUGIN);
	g_hPremFramerate	= CreateConVar("tf2_srs_prem_framerate","4.0","Rate at which the Premium sprite should animate. \nIncrease if the it animates to slow, decrease if it animates to fast",FCVAR_PLUGIN);
	g_hFreeAnimated		= CreateConVar("tf2_srs_free_animated","0","Set to 1 if the F2P sprite is animated.",FCVAR_PLUGIN);
	g_hFreeFramerate	= CreateConVar("tf2_srs_free_framerate","4.0","Rate at which the F2P sprite should animate. \nIncrease if the it animates to slow, decrease if it animates to fast",FCVAR_PLUGIN);
	
	
	if(GetConVarBool(g_hStatusEnable)) 
	{
		HookEventEx("teamplay_round_start", hook_Start, EventHookMode_PostNoCopy);
		HookEventEx("arena_round_start", hook_Start, EventHookMode_PostNoCopy);
		HookEventEx("teamplay_round_win", hook_Win, EventHookMode_PostNoCopy);
		HookEventEx("arena_win_panel", hook_Win, EventHookMode_PostNoCopy);
		HookEventEx("player_death", event_player_death, EventHookMode_Post);
	}
	
	HookConVarChange(g_hStatusEnable, EnableChanged);
	
	SetConVarString(g_hStatusVersion, PLUGIN_VERSION, true, true);
	
	gVelocityOffset = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	AutoExecConfig(true, "tf2_status_reveal");
}

public EnableChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new intNewValue = StringToInt(newValue);
	new intOldValue = StringToInt(oldValue);
	
	if(intNewValue == 1 && intOldValue == 0) 
	{
		HookEventEx("teamplay_round_start", hook_Start, EventHookMode_PostNoCopy);
		HookEventEx("arena_round_start", hook_Start, EventHookMode_PostNoCopy);
		HookEventEx("teamplay_round_win", hook_Win, EventHookMode_PostNoCopy);
		HookEventEx("arena_win_panel", hook_Win, EventHookMode_PostNoCopy);
		HookEventEx("player_death", event_player_death, EventHookMode_Post);
	}
	else if(intNewValue == 0 && intOldValue == 1) 
	{
		UnhookEvent("teamplay_round_start", hook_Start, EventHookMode_PostNoCopy);
		UnhookEvent("arena_round_start", hook_Start, EventHookMode_PostNoCopy);
		UnhookEvent("teamplay_round_win", hook_Win, EventHookMode_PostNoCopy);
		UnhookEvent("arena_win_panel", hook_Win, EventHookMode_PostNoCopy);
		UnhookEvent("player_death", event_player_death, EventHookMode_Post);
		
		if(g_bRoundEnded) {
			for(new i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i)) continue;
				KillSprite(i);
			}
		}
	}
}

public OnMapStart()
{
	decl String:szBuffer[128];
	
	GetConVarString(g_hPremSprite,g_sSpritePrem, sizeof(g_sSpritePrem));
	GetConVarString(g_hFreeSprite,g_sSpriteFree, sizeof(g_sSpriteFree));
	
	// Premium
	FormatEx(szBuffer, sizeof(szBuffer), "materials/%s.vmt", g_sSpritePrem);
	PrecacheGeneric(szBuffer, true);
	AddFileToDownloadsTable(szBuffer);
	FormatEx(szBuffer, sizeof(szBuffer), "materials/%s.vtf", g_sSpritePrem);
	PrecacheGeneric(szBuffer, true);
	AddFileToDownloadsTable(szBuffer);
	// Free to Play
	FormatEx(szBuffer, sizeof(szBuffer), "materials/%s.vmt", g_sSpriteFree);
	PrecacheGeneric(szBuffer, true);
	AddFileToDownloadsTable(szBuffer);
	FormatEx(szBuffer, sizeof(szBuffer), "materials/%s.vtf", g_sSpriteFree);
	PrecacheGeneric(szBuffer, true);
	AddFileToDownloadsTable(szBuffer);
}

public hook_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		KillSprite(i);
	}
	g_bRoundEnded = false;
}

public hook_Win(Handle:event, const String:name[], bool:dontBroadcast)
{	
	decl String:szBuffer[128];
	new String:sRate[4];
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || IsClientObserver(i)) continue;
		
		if (IsFree2Play(i) == 1)
		{	// Free To Play
			FormatEx(szBuffer, sizeof(szBuffer), "%s.vmt", g_sSpriteFree);
			if(GetConVarBool(g_hFreeAnimated)) {
				GetConVarString(g_hFreeFramerate,sRate, sizeof(sRate));
				CreateSprite(i, szBuffer, 25.0, sRate);
			}
			else
				CreateSprite(i, szBuffer, 25.0, "no");
		}
		else if (IsFree2Play(i) == 0)
		{	// Premium
			FormatEx(szBuffer, sizeof(szBuffer), "%s.vmt", g_sSpritePrem);
			if(GetConVarBool(g_hPremAnimated)) {
				GetConVarString(g_hPremFramerate,sRate, sizeof(sRate));
				CreateSprite(i, szBuffer, 25.0, sRate);
			}
			else
				CreateSprite(i, szBuffer, 25.0, "no");
		}
	}
	g_bRoundEnded = true;
	
	CreateTimer(0.1, updatePosition, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnClientDisconnect(client)
{
	if(g_bRoundEnded)
		KillSprite(client);
}

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bRoundEnded) return Plugin_Continue;
	KillSprite(GetClientOfUserId(GetEventInt(event, "userid")));
	return Plugin_Continue;
}

stock CreateSprite(iClient, String:sprite[], Float:offset, String:rate[])
{
	new String:szTemp[64]; 
	Format(szTemp, sizeof(szTemp), "client%i", iClient);
	DispatchKeyValue(iClient, "targetname", szTemp);
	
	new Float:vOrigin[3];
	GetClientAbsOrigin(iClient, vOrigin);
	vOrigin[2] += offset;
	new ent = CreateEntityByName("env_sprite_oriented");
	if (ent)
	{
		DispatchKeyValue(ent, "model", sprite);
		DispatchKeyValue(ent, "classname", "env_sprite_oriented");
		if(!StrEqual(rate, "no"))
			DispatchKeyValue(ent, "framerate", rate);
		DispatchKeyValue(ent, "spawnflags", "1");
		DispatchKeyValue(ent, "scale", "0.1");
		DispatchKeyValue(ent, "rendermode", "1");
		DispatchKeyValue(ent, "rendercolor", "255 255 255");
		DispatchKeyValue(ent, "targetname", "status_spr");
		DispatchKeyValue(ent, "parentname", szTemp);
		DispatchSpawn(ent);
		
		TeleportEntity(ent, vOrigin, NULL_VECTOR, NULL_VECTOR);

		g_EntList[iClient] = ent;
	}
}

stock KillSprite(iClient)
{
	if (g_EntList[iClient] > 0 && IsValidEntity(g_EntList[iClient]))
	{
		AcceptEntityInput(g_EntList[iClient], "kill");
		g_EntList[iClient] = 0;
	}
}

public Action:updatePosition(Handle:timer)
{
	if (!g_bRoundEnded) return Plugin_Stop;
	
	new ent, Float:vOrigin[3], Float:vVelocity[3];
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if ((ent = g_EntList[i]) > 0)
		{
			if (!IsValidEntity(ent))
				g_EntList[i] = 0;
			else
				if ((ent = EntRefToEntIndex(ent)) > 0)
				{
					GetClientEyePosition(i, vOrigin);
					vOrigin[2] += 25.0;
					GetEntDataVector(i, gVelocityOffset, vVelocity);
					TeleportEntity(ent, vOrigin, NULL_VECTOR, vVelocity);
				}
		}
	}
	return Plugin_Continue;
}
