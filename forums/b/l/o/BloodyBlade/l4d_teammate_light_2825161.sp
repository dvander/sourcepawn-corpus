#define PLUGIN_VERSION 		"1.0"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Teammate Flashlight
*	Author	:	SilverShot, sereky
*	Descrp	:	Teleports a light_dynamic entity to where survivors are pointing with flashlights on.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=186558

========================================================================================
	Change Log:

1.0 (01-Jun-2012)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS	FCVAR_NOTIFY
#define CHAT_TAG	"\x05[Dynamic Light] \x01"

ConVar g_hCvarAllow, g_hCvarAlpha, g_hCvarBright, g_hCvarColor, g_hCvarDist, g_hCvarFade, g_hCvarHide, g_hCvarIgnore, g_hCvarHull, g_hCvarModes, g_hCvarModesOff, g_hMPGameMode;
bool g_bCvarAllow = false, g_bLeft4Dead2 = false;
int g_iCvarAlpha, g_iCvarDist, g_iCvarFade, g_iCvarHide, g_iCvarIgnore, g_iCvarHull, g_iCvarColor;
int g_iTransmit[MAXPLAYERS + 1] = {0, ...}, g_iLightIndex[MAXPLAYERS + 1] = {0, ...}, g_iLightState[MAXPLAYERS + 1] = {0, ...}, g_iPlayerEnum[MAXPLAYERS + 1] = {0, ...}, g_iWeaponIndex[MAXPLAYERS + 1] = {0, ...};
char g_iCvarBright;

enum (<<=1)
{
	ENUM_INCAPPED = 1,
	ENUM_INSTART,
	ENUM_BLOCKED,
	ENUM_POUNCED,
	ENUM_ONLEDGE,
	ENUM_INREVIVE,
	ENUM_DISTANCE,
	ENUM_BLOCK
}

// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Teammate Flashlight",
	author = "SilverShot, sereky",
	description = "Teleports a light_dynamic entity to where survivors are pointing with flashlights on.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=186558"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if( strcmp(sGameName, "left4dead", false) == 0 ) g_bLeft4Dead2 = false;
	else if( strcmp(sGameName, "left4dead2", false) == 0 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarAllow =		CreateConVar(	"l4d_teammate_light_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarBright =		CreateConVar(	"l4d_teammate_light_bright",		"1",			"Brightness of the light.", CVAR_FLAGS);
	g_hCvarAlpha =		CreateConVar(	"l4d_teammate_light_size",			"155.0",		"Size of the light.", CVAR_FLAGS);
	g_hCvarColor =		CreateConVar(	"l4d_teammate_light_color",			"250 250 200",	"The light color. Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", CVAR_FLAGS);
	g_hCvarDist =		CreateConVar(	"l4d_teammate_light_distance",		"500",			"Distance the light shines before not lighting up.", CVAR_FLAGS);
	g_hCvarFade =		CreateConVar(	"l4d_teammate_light_fade",			"0",			"0=Disable fade. Other value starts fading the light brightness from this distance.", CVAR_FLAGS);
	g_hCvarHide =		CreateConVar(	"l4d_teammate_light_hide",			"1",			"0=Show the dynamic light to the owner using it. 1=Hide the dynamic light so only other players can see it.", CVAR_FLAGS);
	g_hCvarIgnore =		CreateConVar(	"l4d_teammate_light_ignore",		"1",			"0=Off. 1=Ignore trace on survivors so the dynamic light will go through them.", CVAR_FLAGS);
	g_hCvarHull =		CreateConVar(	"l4d_teammate_light_hull",			"1",			"0=Trace directly to where they are aiming. 1=Trace hull to detect nearby entities.", CVAR_FLAGS);
	g_hCvarModes =		CreateConVar(	"l4d_teammate_light_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS);
	g_hCvarModesOff =	CreateConVar(	"l4d_teammate_light_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS);
	CreateConVar(						"l4d_teammate_light_version",		PLUGIN_VERSION,	"Dynamic Light plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_teammate_light");

	g_hMPGameMode = FindConVar("mp_gamemode");
	g_hMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarBright.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarAlpha.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDist.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHide.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarIgnore.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHull.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFade.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarColor.AddChangeHook(ConVarChanged_Cvars);
}

public void OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		DeleteLight(i);
	}
}

// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
	for(int i = 1; i <= MaxClients; i++)
	{
		DeleteLight(i);
	}
}

void IsAllowed()
{
	bool bAllowCvar = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();

	if(!g_bCvarAllow && bAllowCvar && bAllowMode)
	{
		g_bCvarAllow = true;
		GetCvars();
		HookEvents();
	}
	else if(g_bCvarAllow && (!bAllowCvar || !bAllowMode))
	{
		g_bCvarAllow = false;
		UnhookEvents();
		for(int i = 1; i <= MaxClients; i++)
		{
			DeleteLight(i);
		}
	}
}

void GetCvars()
{
	char sColor[16];
	g_hCvarColor.GetString(sColor, sizeof(sColor));
	for(int i = 0; i <= MaxClients; i++)
	{
		if(IsValidEntRef(g_iLightIndex[i]))
		{
			SetVariantString(sColor);
			AcceptEntityInput(g_iLightIndex[i], "color");
		}
	}
	g_iCvarColor = GetColor(sColor);
	g_iCvarBright = g_hCvarBright.IntValue;
	g_iCvarAlpha = g_hCvarAlpha.IntValue;
	g_iCvarDist = g_hCvarDist.IntValue;
	g_iCvarFade = g_hCvarFade.IntValue;
	if(g_iCvarFade == 0)
	{
		for(int i = 0; i <= MaxClients; i++)
		{
			if(IsValidEntRef(g_iLightIndex[i]))
			{
				SetVariantInt(g_iCvarAlpha);
				AcceptEntityInput(g_iLightIndex[i], "distance");
			}
		}
	}
	g_iCvarHide = g_hCvarHide.IntValue;
	g_iCvarIgnore = g_hCvarIgnore.IntValue;
	g_iCvarHull = g_hCvarHull.IntValue;
}

int GetColor(char[] sTemp)
{
	char sColors[3][4];
	int color;
	ExplodeString(sTemp, " ", sColors, 3, 4);
	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);
	return color;
}

bool IsAllowedGameMode()
{
	if(g_hMPGameMode == null) return false;

	char sGameModes[64], sGameMode[64];
	g_hMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if(strcmp(sGameModes, ""))
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if(StrContains(sGameModes, sGameMode, false) == -1) return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if(strcmp(sGameModes, ""))
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if(StrContains(sGameModes, sGameMode, false) != -1) return false;
	}

	return true;
}

// ====================================================================================================
//					EVENTS
// ====================================================================================================
void HookEvents()
{
	HookEvent("round_start",			Event_RoundStart,	EventHookMode_PostNoCopy);
	HookEvent("player_ledge_grab",		Event_LedgeGrab);
	HookEvent("player_spawn",			Event_Unblock);
	HookEvent("revive_begin",			Event_ReviveStart);
	HookEvent("revive_end",				Event_ReviveEnd);
	HookEvent("revive_success",			Event_ReviveSuccess);
	HookEvent("player_death",			Event_Unblock);
	HookEvent("lunge_pounce",			Event_BlockHunter);
	HookEvent("pounce_end",				Event_BlockEndHunt);
	HookEvent("tongue_grab",			Event_BlockStart);
	HookEvent("tongue_release",			Event_BlockEnd);

	if( g_bLeft4Dead2 ) 
	{
		HookEvent("charger_pummel_start",	Event_BlockStart);
		HookEvent("charger_carry_start",	Event_BlockStart);
		HookEvent("charger_carry_end",		Event_BlockEnd);
		HookEvent("charger_pummel_end",		Event_BlockEnd);
		HookEvent("jockey_ride",			Event_BlockStart);
		HookEvent("jockey_ride_end",		Event_BlockEnd);
	}
}

void UnhookEvents()
{
	UnhookEvent("round_start",			Event_RoundStart,	EventHookMode_PostNoCopy);
	UnhookEvent("player_ledge_grab",	Event_LedgeGrab);
	UnhookEvent("player_spawn",			Event_Unblock);
	UnhookEvent("revive_begin",			Event_ReviveStart);
	UnhookEvent("revive_end",			Event_ReviveEnd);
	UnhookEvent("revive_success",		Event_ReviveSuccess);
	UnhookEvent("player_death",			Event_Unblock);
	UnhookEvent("lunge_pounce",			Event_BlockHunter);
	UnhookEvent("pounce_end",			Event_BlockEndHunt);
	UnhookEvent("tongue_grab",			Event_BlockStart);
	UnhookEvent("tongue_release",		Event_BlockEnd);

	if( g_bLeft4Dead2 ) 
	{
		UnhookEvent("charger_pummel_start",		Event_BlockStart);
		UnhookEvent("charger_carry_start",		Event_BlockStart);
		UnhookEvent("charger_carry_end",		Event_BlockEnd);
		UnhookEvent("charger_pummel_end",		Event_BlockEnd);
		UnhookEvent("jockey_ride",				Event_BlockStart);
		UnhookEvent("jockey_ride_end",			Event_BlockEnd);
	}
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i < MAXPLAYERS; i++)
	{
		g_iPlayerEnum[i] = 0;
	}
}

void Event_BlockStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if(client > 0) g_iPlayerEnum[client] |= ENUM_BLOCKED;
}

void Event_BlockEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if(client > 0) g_iPlayerEnum[client] &= ~ENUM_BLOCKED;
}

void Event_BlockHunter(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if(client > 0) g_iPlayerEnum[client] |= ENUM_POUNCED;
}

void Event_BlockEndHunt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if(client > 0) g_iPlayerEnum[client] &= ~ENUM_POUNCED;
}

void Event_LedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0) g_iPlayerEnum[client] |= ENUM_ONLEDGE;
}

void Event_ReviveStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if(client > 0) g_iPlayerEnum[client] |= ENUM_INREVIVE;
	client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0) g_iPlayerEnum[client] |= ENUM_INREVIVE;
}

void Event_ReviveEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if(client > 0) g_iPlayerEnum[client] &= ~ENUM_INREVIVE;
	client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0) g_iPlayerEnum[client] &= ~ENUM_INREVIVE;
}

void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if(client > 0)
	{
		g_iPlayerEnum[client] &= ~ENUM_INREVIVE;
		g_iPlayerEnum[client] &= ~ENUM_ONLEDGE;
	}
	client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0) g_iPlayerEnum[client] &= ~ENUM_INREVIVE;
}

void Event_Unblock(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0) g_iPlayerEnum[client] = 0;
}

// ====================================================================================================
//					DYNAMIC LIGHT ON/OFF
// ====================================================================================================
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if( g_bCvarAllow )
	{
		int entity = g_iLightIndex[client];
		if( GetClientTeam(client) != 2 || !IsPlayerAlive(client) )
		{
			if(IsValidEntRef(entity)) DeleteLight(client);
			return Plugin_Stop;
		}

		// Missing light, create entity
		if( IsValidEntRef(entity) == false )
		{
			entity = CreateLight(client);
			g_iLightState[client] = 1;
		}

		// Check the players current weapon
		int index = g_iWeaponIndex[client];
		int active = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

		if( index != active )
		{
			g_iWeaponIndex[client] = active;
			if(active == -1 ) g_iPlayerEnum[client] |= ENUM_BLOCK;
			else
			{
				char sTemp[32];
				GetClientWeapon(client, sTemp, sizeof(sTemp));
				if( strcmp(sTemp, "weapon_melee") == 0 ||
					strcmp(sTemp, "weapon_chainsaw") == 0 ||
					strcmp(sTemp, "weapon_vomitjar") == 0 ||
					strcmp(sTemp, "weapon_pipe_bomb") == 0 ||
					strcmp(sTemp, "weapon_defibrillator") == 0 ||
					strcmp(sTemp, "weapon_first_aid_kit") == 0 ||
					strcmp(sTemp, "weapon_upgradepack_explosive") == 0 ||
					strcmp(sTemp, "weapon_upgradepack_incendiary") == 0 ||
					strcmp(sTemp, "weapon_first_aid_kit") == 0 ||
					strcmp(sTemp, "weapon_pain_pills") == 0 ||
					strcmp(sTemp, "weapon_adrenaline") == 0 ||
					strcmp(sTemp, "cola_bottles") == 0 ||
					strcmp(sTemp, "weapon_fireworkcrate") == 0 ||
					strcmp(sTemp, "weapon_gascan") == 0 ||
					strcmp(sTemp, "weapon_gnome") == 0 ||
					strcmp(sTemp, "weapon_oxygentank") == 0 ||
					strcmp(sTemp, "weapon_propanetank") == 0
				)
				{
					g_iPlayerEnum[client] |= ENUM_BLOCK;
				}
				else g_iPlayerEnum[client] &= ~ENUM_BLOCK;
			}
		}

		// Player has light on or off?
		int playerenum = g_iPlayerEnum[client];
		// Get player light state
		if( playerenum == 0 && GetEntProp(client, Prop_Send, "m_fEffects") & (2<<1) )
		{
			if(g_iLightState[client] == 0)
			{
				AcceptEntityInput(entity, "TurnOn");
				g_iLightState[client] = 1;
			}

			TeleportDynamicLight(client, entity);
		}
		else
		{
			if(g_iLightState[client] == 1)
			{
				AcceptEntityInput(entity, "TurnOff");
				g_iLightState[client] = 0;
			}
		}
	}
	return Plugin_Continue;
}

void DeleteLight(int client)
{
	int entity = g_iLightIndex[client];
	g_iLightIndex[client] = 0;
	if( IsValidEntRef(entity) )
	{
		AcceptEntityInput(entity, "Kill");
		if( g_iTransmit[client] == 1 )
		{
			SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmitLight);
			g_iTransmit[client] = 0;
		}
	}
}

int CreateLight(int client)
{
	int entity = g_iLightIndex[client];
	if(IsValidEntRef(entity)) return 0;
	entity = CreateEntityByName("light_dynamic");
	if( entity == -1)
	{
		LogError("Failed to create 'light_dynamic'");
		return 0;
	}

	char sTemp[5];
	IntToString(g_iCvarBright, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "brightness", sTemp);
	DispatchKeyValueFloat(entity, "spotlight_radius", 32.0);
	DispatchKeyValueFloat(entity, "distance", float(g_iCvarAlpha));
	DispatchKeyValue(entity, "style", "-1");
	SetEntProp(entity, Prop_Send, "m_clrRender", g_iCvarColor);
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "TurnOn");

	g_iTransmit[client] = 0;
	if( g_iCvarHide == 1 )
	{
		SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmitLight);
		g_iTransmit[client] = 1;
	}

	g_iLightIndex[client] = EntIndexToEntRef(entity);
	return entity;
}

Action Hook_SetTransmitLight(int entity, int client)
{
	if(g_iLightIndex[client] == EntIndexToEntRef(entity)) return Plugin_Handled;
	return Plugin_Continue;
}

void TeleportDynamicLight(int client, int entity)
{
	float vLoc[3], vPos[3], vAng[3];

	GetClientEyeAngles(client, vAng);
	GetClientEyePosition(client, vLoc);

	Handle trace;
	if( g_iCvarHull == 0 )
	{
		trace = TR_TraceRayFilterEx(vLoc, vAng, MASK_SHOT, RayType_Infinite, TraceFilter, client);
	}
	else
	{
		float vDir[3], vEnd[3];
		GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
		vEnd = vLoc;
		vEnd[0] += vDir[0] * 5000;
		vEnd[1] += vDir[1] * 5000;
		vEnd[2] += vDir[2] * 5000;
		trace = TR_TraceHullFilterEx(vLoc, vEnd, view_as<float>({ -15.0, -15.0, -15.0 }), view_as<float>({ 15.0, 15.0, 15.0 }), MASK_SHOT, TraceFilter, client);
	}

	if( TR_DidHit(trace) )
	{
		TR_GetEndPosition(vPos, trace);
		float fDist = GetVectorDistance(vLoc, vPos);
		if( fDist <= g_iCvarDist )
		{
			GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
			vPos[0] -= vAng[0] * 50;
			vPos[1] -= vAng[1] * 50;
			vPos[2] -= vAng[2] * 50;
			TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
			if( fDist < g_iCvarFade )
			{
				SetVariantEntity(entity);
				SetVariantInt(g_iCvarAlpha * RoundToNearest(fDist) / g_iCvarFade);
				AcceptEntityInput(entity, "distance");
			}
			else
			{
				SetVariantInt(g_iCvarAlpha);
				AcceptEntityInput(entity, "distance");
			}
		}
		else
		{
			GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
			vLoc[0] += vAng[0] * (g_iCvarDist - 50);
			vLoc[1] += vAng[1] * (g_iCvarDist - 50);
			vLoc[2] += vAng[2] * (g_iCvarDist - 50);
			TeleportEntity(entity, vLoc, NULL_VECTOR, NULL_VECTOR);
			SetVariantInt(g_iCvarAlpha);
			AcceptEntityInput(entity, "distance");
		}
	}
	CloseHandle(trace);
}

public bool TraceFilter(int entity, int contentsMask, any client)
{
	if(entity == client) return false;
	if( g_iCvarIgnore == 1 && entity < MaxClients)
	{
		if (GetClientTeam(entity) == 2) return false;
	}
	return true;
}

bool IsValidEntRef(int entity)
{
	return entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE;
}
