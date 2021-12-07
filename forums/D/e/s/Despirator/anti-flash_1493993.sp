#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

#define ALPHA_SET 0.5
#define DURATION_SET 0.0

public Plugin:myinfo = 
{
	name = "Anti-Flash",
	author = "FrozDark (HLModders LLC)",
	description = "This plugin will prevents players to be blinded and (or) deafened",
	version = PLUGIN_VERSION,
	url = "www.hlmod.ru"
};

new g_iFlashAlpha = -1;
new g_iFlashDuration = -1;

new Handle:h_AntiFlashVersion,
	Handle:h_AntiFlashEnable, bool:b_enabled,
	Handle:h_AntiFlashBlind, bool:b_blind,
	Handle:h_AntiFlashDeafen, bool:b_deafen,
	Handle:h_AntiTeamFlash, bool:b_antiteam,
	Handle:h_AntiOwnerFlash, bool:b_antiowner,
Handle:h_AntiDeadFlash, bool:b_antidead;

public OnPluginStart()
{
	h_AntiFlashVersion = CreateConVar("sm_antiflash_version", PLUGIN_VERSION, "The plugin's version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	h_AntiFlashEnable = CreateConVar("sm_antiflash_enable", "1", "Enables/Disables the plugin", 0, true, 0.0, true, 1.0);
	h_AntiFlashBlind = CreateConVar("sm_antiflash_blind", "1", "Enables/Disables flashbangs to blind players", 0, true, 0.0, true, 1.0);
	h_AntiFlashDeafen = CreateConVar("sm_antiflash_deafen", "1", "Enables/Disables flashbangs to deafen players", 0, true, 0.0, true, 1.0);
	h_AntiTeamFlash = CreateConVar("sm_antiflash_team", "1", "Prevents teammates to be flashed", 0, true, 0.0, true, 1.0);
	h_AntiOwnerFlash = CreateConVar("sm_antiflash_owner", "0", "Prevents an owner to be flashed", 0, true, 0.0, true, 1.0);
	h_AntiDeadFlash = CreateConVar("sm_antiflash_dead", "1", "Prevents dead players to be flashed", 0, true, 0.0, true, 1.0);
	
	b_enabled = GetConVarBool(h_AntiFlashEnable);
	b_blind = GetConVarBool(h_AntiFlashBlind);
	b_deafen = GetConVarBool(h_AntiFlashDeafen);
	b_antiteam = GetConVarBool(h_AntiTeamFlash);
	b_antiowner = GetConVarBool(h_AntiOwnerFlash);
	b_antidead = GetConVarBool(h_AntiDeadFlash);
	
	HookConVarChange(h_AntiFlashVersion, CvarChanges);
	HookConVarChange(h_AntiFlashEnable, CvarChanges);
	HookConVarChange(h_AntiFlashBlind, CvarChanges);
	HookConVarChange(h_AntiFlashDeafen, CvarChanges);
	HookConVarChange(h_AntiTeamFlash, CvarChanges);
	HookConVarChange(h_AntiOwnerFlash, CvarChanges);
	HookConVarChange(h_AntiDeadFlash, CvarChanges);
	
	AutoExecConfig(true, "plugin.anti-flash");
	
	if ((g_iFlashDuration = FindSendPropOffs("CCSPlayer", "m_flFlashDuration")) == -1)
		SetFailState("Failed to find CCSPlayer::m_flFlashDuration offset");
	
	if ((g_iFlashAlpha = FindSendPropOffs("CCSPlayer", "m_flFlashMaxAlpha")) == -1)
		SetFailState("Failed to find CCSPlayer::m_flFlashMaxAlpha offset");
	
	HookEvent("flashbang_detonate", OnFlashDetonate);
	HookEvent("player_blind", OnPlayerBlind);
}

public CvarChanges(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == h_AntiFlashEnable)
	{
		if (bool:StringToInt(newValue) != b_enabled)
		{
			b_enabled = !b_enabled;
			if (b_enabled)
			{
				HookEvent("flashbang_detonate", OnFlashDetonate);
				HookEvent("player_blind", OnPlayerBlind);
			}
			else
			{
				UnhookEvent("flashbang_detonate", OnFlashDetonate);
				UnhookEvent("player_blind", OnPlayerBlind);
			}
		}
	} else
	if (convar == h_AntiFlashBlind)
		b_blind = bool:StringToInt(newValue); else
	if (convar == h_AntiFlashDeafen)
		b_deafen = bool:StringToInt(newValue); else
	if (convar == h_AntiTeamFlash)
		b_antiteam = bool:StringToInt(newValue); else
	if (convar == h_AntiOwnerFlash)
		b_antiowner = bool:StringToInt(newValue); else
	if (convar == h_AntiDeadFlash)
		b_antidead = bool:StringToInt(newValue);
}

public OnFlashDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team;
	new owner = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if (IsClientInGame(owner))
	{
		team = GetClientTeam(owner);
	}
			
	decl Float:DetonateOrigin[3];
	DetonateOrigin[0] = GetEventFloat(event, "x"); 
	DetonateOrigin[1] = GetEventFloat(event, "y"); 
	DetonateOrigin[2] = GetEventFloat(event, "z");
	
	decl Float:EyePosition[3];
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		new targetteam;
		if ((targetteam = GetClientTeam(client)) <= 1)
			continue;
		
		GetClientEyePosition(client, EyePosition);
		
		if (GetVectorDistance(DetonateOrigin, EyePosition) <= 1500.0)
		{
			EyePosition[2] -= 0.5;
		
			new Handle:trace = TR_TraceRayFilterEx(DetonateOrigin, EyePosition, CONTENTS_SOLID, RayType_EndPoint, FilterTarget, client);
			if ((TR_DidHit(trace) && TR_GetEntityIndex(trace) == client) || (GetVectorDistance(DetonateOrigin, EyePosition) <= 100.0))
			{
				if (b_antiteam && targetteam == team && client != owner)
					StopFlash(client);
				else if (b_antiowner && client == owner)
					StopFlash(client);
				else if (b_antidead && !IsPlayerAlive(client))
					StopFlash(client);
				else
				{
					if (!b_blind)
						RemoveBlind(client);
					if (!b_deafen)
						RemoveDeafen(client);
				}
			}
			
			CloseHandle(trace);
		}
	}
}

public OnPlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (b_antidead && IsClientObserver(client))
	{
		StopFlash(client);
	}
}

public bool:FilterTarget(entity, contentsMask, any:data)
{
	return (data == entity);
} 

StopFlash(client)
{
	RemoveBlind(client);
	RemoveDeafen(client);
}

RemoveBlind(client)
{
	SetEntDataFloat(client, g_iFlashAlpha, ALPHA_SET);
	SetEntDataFloat(client, g_iFlashDuration, DURATION_SET);
}

RemoveDeafen(client)
{
	ClientCommand(client, "dsp_player 0.0");
}