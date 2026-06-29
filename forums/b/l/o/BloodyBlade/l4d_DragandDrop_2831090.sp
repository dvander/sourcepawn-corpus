#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

Handle DropTimers[MAXPLAYERS + 1] = {null, ...};
ConVar sm_dad_on, sm_dad_drag, sm_dad_pounce, sm_dad_incap, sm_dad_incap_grenade, sm_dad_pistols, sm_dad_bots;
bool bL4D2 = false, bDadOn = false, bHooked = false, bDadDrag = false, bDadPounce = false, bDadIncap = false, bDadIncapGrenade = false, bDadPistols = false, bDadBots = false;

public Plugin myinfo =
{
	name = "[L4D] Drag and Drop",
	author = "Crimson_Fox(Rewritten by BloodyBlade)",
	description = "Survivors drop equipped item on smoker drag or incap.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=950571"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine == Engine_Left4Dead)
	{
		bL4D2 = false;
	}
	else if(engine == Engine_Left4Dead2)
	{
		bL4D2 = true;
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_dad_version", PLUGIN_VERSION, "[L4D] Drag and Drop plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
	sm_dad_on = CreateConVar("sm_dad_on", "1", "Enable/Disable plugin.", CVAR_FLAGS);
	sm_dad_drag = CreateConVar("sm_dad_drag", "1", "Survivors drop equipped item on smoker drag.", CVAR_FLAGS);
	sm_dad_pounce = CreateConVar("sm_dad_pounce", "0", "Survivors drop equipped item on hunter pounce.", CVAR_FLAGS);
	sm_dad_incap = CreateConVar("sm_dad_incap", "1", "Survivors drop equipped item when they become incapacitated.", CVAR_FLAGS);
	sm_dad_incap_grenade = CreateConVar("sm_dad_incap_grenade", "1", "Survivors drop their grenade when they become incapacitated.", CVAR_FLAGS);
	sm_dad_pistols = CreateConVar("sm_dad_pistols", "0", "Will survivors drop second pistol?", CVAR_FLAGS);
	sm_dad_bots = CreateConVar("sm_dad_bots", "0", "Will bots drop equipped item?", CVAR_FLAGS);

	AutoExecConfig(true, "sm_dad");

	sm_dad_on.AddChangeHook(ConVarPluginOnChanged);
	sm_dad_drag.AddChangeHook(ConVarsChanged);
	sm_dad_pounce.AddChangeHook(ConVarsChanged);
	sm_dad_incap.AddChangeHook(ConVarsChanged);
	sm_dad_incap_grenade.AddChangeHook(ConVarsChanged);
	sm_dad_pistols.AddChangeHook(ConVarsChanged);
	sm_dad_bots.AddChangeHook(ConVarsChanged);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarPluginOnChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
	IsAllowed();
}

void ConVarsChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
	bDadDrag = sm_dad_drag.BoolValue;
	bDadPounce = sm_dad_pounce.BoolValue;
	bDadIncap = sm_dad_incap.BoolValue;
	bDadIncapGrenade = sm_dad_incap_grenade.BoolValue;
	bDadPistols = sm_dad_pistols.BoolValue;
	bDadBots = sm_dad_bots.BoolValue;
}

void IsAllowed()
{
	bDadOn = sm_dad_on.BoolValue;
	if(bDadOn && !bHooked)
	{
		bHooked = true;
		ConVarsChanged(null, "", "");
		HookEvent("tongue_grab", Events, EventHookMode_Post);
		HookEvent("tongue_release", Events, EventHookMode_Post);
		HookEvent("lunge_pounce", Events, EventHookMode_Post);
		HookEvent("player_incapacitated", Events, EventHookMode_Post);
	}
	else if(!bDadOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("tongue_grab", Events, EventHookMode_Post);
		UnhookEvent("tongue_release", Events, EventHookMode_Post);
		UnhookEvent("lunge_pounce", Events, EventHookMode_Post);
		UnhookEvent("player_incapacitated", Events, EventHookMode_Post);
	}
}

Action Events(Event event, const char[] name, bool dontBroadcast)
{
	if (strcmp(name, "tongue_grab") == 0)
	{
		if (bDadDrag)
		{
			int client = GetClientOfUserId(event.GetInt("victim"));
			if(IsValidSurv(client))
			{
				DropTimers[client] = CreateTimer(1.0, DropItemDelay, client);
			}
		}
	}
	else if(strcmp(name, "tongue_release") == 0)
	{
		int client = GetClientOfUserId(event.GetInt("victim"));
		if (IsValidSurv(client) && DropTimers[client] != null)
		{
			delete DropTimers[client];
		}
	}
	else if(strcmp(name, "lunge_pounce") == 0)
	{
		if (bDadPounce)
		{
			int client = GetClientOfUserId(event.GetInt("victim"));
			if(IsValidSurv(client))
			{
				DropItemDelay(INVALID_HANDLE, client);
			}
		}
	}
	else if(strcmp(name, "player_incapacitated") == 0)
	{
		if (bDadIncap)
		{
			int client = GetClientOfUserId(event.GetInt("userid"));
			if(IsValidSurv(client) && (!IsFakeClient(client) || (IsFakeClient(client) && bDadBots)))
			{
				DropItemDelay(INVALID_HANDLE, client);
			}
		}
	}
	return Plugin_Continue;
}

Action DropItemDelay(Handle timer, any client)
{
	if(IsValidSurv(client))
	{
		int iActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		char cWeapon[32];
		GetEntityClassname(iActiveWeapon, cWeapon, sizeof(cWeapon));
		if (!StrEqual(cWeapon, "weapon_pistol") || (StrEqual(cWeapon, "weapon_pistol") && bDadPistols))
		{
			DropItem(client, iActiveWeapon);
		}

		if (bDadIncapGrenade)
		{
			int iSlot2 = GetPlayerWeaponSlot(client, 2);
			GetEntityClassname(iSlot2, cWeapon, sizeof(cWeapon));
			if ((bL4D2 && (StrEqual(cWeapon, "weapon_molotov") || StrEqual(cWeapon, "weapon_vomitjar"))) || StrEqual(cWeapon, "weapon_pipe_bomb"))
			{
				DropItem(client, iSlot2);
			}
		}
		DropTimers[client] = null;			
	}
	return Plugin_Stop;
}

void DropItem(int client, int iWeapon)
{
	SDKHooks_DropWeapon(client, iWeapon, NULL_VECTOR, NULL_VECTOR);
}

bool IsValidSurv(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}
