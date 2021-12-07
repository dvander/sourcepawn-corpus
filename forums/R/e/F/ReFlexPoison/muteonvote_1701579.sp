#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <basecomm>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION "2.2.0"

// ====[ HANDLES | CVARS ]=====================================================
new Handle:cvarEnabled;
new Handle:cvarImmunity;

// ====[ VARIABLES ]===========================================================
new g_iEnabled;
new bool:g_bImmunity;
new bool:g_bVoteInProgress;
new bool:g_bMuted[MAXPLAYERS + 1];
new bool:g_bGagged[MAXPLAYERS + 1];

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Mute On Vote",
	author = "ReFlexPoison",
	description = "Mute, gag, or silence players after a vote is started",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=184334"
}

// ====[ FUNCTIONS ]===========================================================
public OnPluginStart()
{
	CreateConVar("sm_muteonvote_version", PLUGIN_VERSION, "Mute On Vote Version", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	cvarEnabled = CreateConVar("sm_muteonvote_enabled", "1", "Enable Mute On Vote\n0 = Disabled\n1 = Mute\n2 = Gag\n3 = Silence", FCVAR_NONE, true, 0.0, true, 3.0);
	g_iEnabled = GetConVarInt(cvarEnabled);
	cvarImmunity = CreateConVar("sm_muteonvote_immunity", "1", "Enable admin immunity\n0 = Disabled\n1 = Enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	g_bImmunity = GetConVarBool(cvarImmunity);

	HookConVarChange(cvarEnabled, CVarChanged);
	HookConVarChange(cvarImmunity, CVarChanged);

	LoadTranslations("muteonvote.phrases");

	CreateTimer(0.1, Timer_Mute, _, TIMER_REPEAT);
}

public CVarChanged(Handle:hConvar, const String:strOldVal[], const String:strNewVal[])
{
	if(hConvar == cvarEnabled)
	{
		g_iEnabled = GetConVarInt(cvarEnabled);
		for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
		{
			UnmutePlayer(i);
			UngagPlayer(i);
		}
	}
	if(hConvar == cvarImmunity)
		g_bImmunity = GetConVarBool(cvarImmunity);
}

// ====[ TIMERS ]==============================================================
public Action:Timer_Mute(Handle:hTimer)
{
	if(g_iEnabled <= 0)
		return Plugin_Continue;

	if(IsVoteInProgress() && !g_bVoteInProgress)
	{
		switch(g_iEnabled)
		{
			case 1:
			{
				PrintToChatAll("[SM] %t", "muteall");
				LogMessage("%t", "muteall");
			}
			case 2:
			{
				PrintToChatAll("[SM] %t", "gagall");
				LogMessage("%t", "gagall");
			}
			case 3:
			{
				PrintToChatAll("[SM] %t", "silenceall");
				LogMessage("%t", "silenceall");
			}
		}
		for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
		{
			if(g_bImmunity && IsAdmin(i))
				PrintToChat(i, "[SM] %t", "immunity");
			else switch(g_iEnabled)
			{
				case 1: MutePlayer(i);
				case 2: GagPlayer(i);
				case 3:
				{
					MutePlayer(i);
					GagPlayer(i);
				}
			}
			g_bVoteInProgress = true;
		}
	}
	else if(!IsVoteInProgress() && g_bVoteInProgress)
	{
		PrintToChatAll("[SM] %t", "restore");
		LogMessage("%t", "restore_server");
		for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
		{
			UnmutePlayer(i);
			UngagPlayer(i);
		}
		g_bVoteInProgress = false;
	}
	return Plugin_Continue;
}

// ====[ STOCKS ]==============================================================
stock bool:IsValidClient(iClient, bool:bReplay = true)
{
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}

stock bool:IsAdmin(iClient)
{
	if(CheckCommandAccess(iClient, "muteonvote_flag", ADMFLAG_GENERIC))
		return true;
	return false;
}

stock MutePlayer(iClient)
{
	g_bMuted[iClient] = BaseComm_IsClientMuted(iClient);
	if(!g_bMuted[iClient])
		BaseComm_SetClientMute(iClient, true);
}

stock UnmutePlayer(iClient)
{
	if(!g_bMuted[iClient])
		BaseComm_SetClientMute(iClient, false);
}

stock GagPlayer(iClient)
{
	g_bGagged[iClient] = BaseComm_IsClientGagged(iClient);
	if(!g_bGagged[iClient])
		BaseComm_SetClientGag(iClient, true);
}

stock UngagPlayer(iClient)
{
	if(!g_bGagged[iClient])
		BaseComm_SetClientGag(iClient, false);
}

stock ClearTimer(&Handle:hTimer)
{
	if(hTimer != INVALID_HANDLE)
	{
		KillTimer(hTimer);
		hTimer = INVALID_HANDLE;
	}
}