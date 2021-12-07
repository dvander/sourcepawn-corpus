#pragma semicolon 1

#include <tf2_stocks>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#tryinclude <friendly>

#pragma newdecls required

#define PLUGIN_VERSION "1.4.5"


public Plugin myinfo = 
{
	name = "Advanced Infinite Ammo",
	author = "Tylerst",
	
	description = "Infinite usage for just about everything",
	
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=190562"
}

bool g_bLateLoad = false;


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(late) g_bLateLoad = true;
	if(GetEngineVersion() != Engine_TF2)
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}


bool g_bClipAmmoOnly[MAXPLAYERS+1] = false;
bool g_bInfiniteAmmo[MAXPLAYERS+1] = false;
bool g_bInfiniteAmmoToggle = false;
bool g_bWaitingForPlayers;
bool g_bFriendlyAmmoOnly = true;
bool g_bFriendlyInfiniteAmmo = true;
int g_iClientWeapons[MAXPLAYERS+1][3];

ConVar g_hAllInfiniteAmmo;
ConVar g_hRoundWin;
ConVar g_hWaitingForPlayers;
ConVar g_hAdminOnly;
ConVar g_hBots;
ConVar g_hChat;
ConVar g_hLog;
ConVar g_hAmmoOnly;
ConVar g_hExtraStuff;
ConVar g_hDisabledWeapons;
ConVar g_hMvM;
ConVar g_hFriendlyInfiniteAmmo;
ConVar g_hFriendlyAmmoOnly;


public void OnPluginStart()
{
	CreateConVar("sm_aia_version", PLUGIN_VERSION, "Advanced Infinite Ammo", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	LoadTranslations("common.phrases");

	g_hAllInfiniteAmmo = CreateConVar("sm_aia_all", "0", "Advanced Infinite Ammo for everyone", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hAdminOnly = CreateConVar("sm_aia_adminonly", "0", "Advanced Infinite Ammo will work for admins only, 1 = Completely Admin Only, 2 = Admin Only but the commands will work on non-admins", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	g_hBots = CreateConVar("sm_aia_bots", "1", "Advanced Infinite Ammo will work for bots", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hRoundWin = CreateConVar("sm_aia_roundwin", "1", "Advanced Infinite Ammo for everyone on round win", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hWaitingForPlayers = CreateConVar("sm_aia_waitingforplayers", "1", "Advanced Infinite Ammo for everyone during waiting for players phase", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hChat = CreateConVar("sm_aia_chat", "1", "Show Advanced Infinite Ammo changes in chat - 1 = Show chat to everyone - 0 = Show chat to only the person activating the command", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hLog = CreateConVar("sm_aia_log", "1", "Log Advanced Infinite Ammo commands", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hAmmoOnly = CreateConVar("sm_aia_ammoonly", "0", "Sets how to give ammo, 0 = Infinite Clip and Ammo(default behavior), 1 = Infinite Ammo but must still reload clip", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hExtraStuff = CreateConVar("sm_aia_extrastuff", "1", "Whether to add non-ammo related things such as infinite Ubercharge, shield charge, rage, bonk, etc", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hDisabledWeapons = CreateConVar("sm_aia_disabledweapons", "", "Weapons indexes to not give infinite ammo, separated by semicolons");
	g_hMvM = CreateConVar("sm_aia_mvmcash", "0", "Whether to set a players cash or not for MvM", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hFriendlyInfiniteAmmo = CreateConVar("sm_aia_friendly", "1", "Automatically give infinite ammo for friendly players. 0 = disabled | 1 = enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hFriendlyAmmoOnly = CreateConVar("sm_aia_friendlyclip", "1", "Sets how to give ammo to friendlies, 0 = Infinite Clip and Ammo(default behavior), 1 = Infinite Ammo but must still reload clip", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	g_hFriendlyInfiniteAmmo.AddChangeHook(CvarChange_Friendly);
	g_hFriendlyAmmoOnly.AddChangeHook(CvarChange_Friendly);
	g_hAllInfiniteAmmo.AddChangeHook(CvarChange_AllInfiniteAmmo);
	g_hAdminOnly.AddChangeHook(CvarChange_AdminOnly);
	g_hBots.AddChangeHook(CvarChange_Bots);
	g_hAmmoOnly.AddChangeHook(CvarChange_AmmoOnly);
	g_hExtraStuff.AddChangeHook(CvarChange_ExtraStuff);
	g_hWaitingForPlayers.AddChangeHook(CvarChange_WaitingForPlayers);
	g_hDisabledWeapons.AddChangeHook(CvarChange_DisabledWeapons);
	g_hMvM.AddChangeHook(CvarChange_MvMCash);

	RegAdminCmd("sm_aia", Command_SetAIA, ADMFLAG_SLAY, "Give Advanced Infinite Ammo to the target(s) - Usage: sm_aia \"target\" \"1/0\"");
	RegAdminCmd("sm_aia2", Command_SetAIATimed, ADMFLAG_SLAY, "Give Advanced Infinite Ammo to the target(s) for a limited time - Usage: sm_aia2 \"target\" \"time(in seconds)\"");
	RegAdminCmd("sm_aia3", Command_SetAIAAlternate, ADMFLAG_SLAY, "Give Advanced Infinite Ammo to the target(s), but works opposite to your sm_aia_ammoonly cvar - Usage: sm_aia3 \"target\" \"1/0\"");
	RegAdminCmd("sm_aia4", Command_SetAIATimedAlternate, ADMFLAG_SLAY, "Give Advanced Infinite Ammo to the target(s) for a limited time, but works opposite to your sm_aia_ammoonly cvar - Usage: sm_aia4 \"target\" \"time(in seconds)\"");
	RegAdminCmd("sm_advanced_infinite_ammo", Command_SetAIA, ADMFLAG_SLAY, "Give Advanced Infinite Ammo to the target(s) - Usage: sm_advanced_infinite_ammo \"target\" \"1/0\"");
	RegAdminCmd("sm_advanced_infinite_ammo_timed", Command_SetAIATimed, ADMFLAG_SLAY, "Give Advanced Infinite Ammo to the target(s) for a limited time - Usage: sm_advanced_infinite_ammo_timed \"target\" \"time(in seconds)\"");

	HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", Event_ArenaRoundStart, EventHookMode_PostNoCopy);
	HookEvent("mvm_begin_wave", Event_MVMWaveStart, EventHookMode_PostNoCopy);
	HookEvent("player_builtobject", Event_ObjectBuilt);

	if(g_bLateLoad)
		for(int iClient = 1; iClient <= MaxClients; iClient++)
			OnClientPostAdminCheck(iClient);

	AutoExecConfig(true, "AdvancedInfiniteAmmo");
}

public int TF2Friendly_OnEnableFriendly_Post(int iClient) {
	g_bInfiniteAmmo[iClient] = g_bFriendlyInfiniteAmmo ? true : false;
	g_bClipAmmoOnly[iClient] = g_bFriendlyAmmoOnly ? true : false;
}

public int TF2Friendly_OnDisableFriendly_Post(int iClient) {
	g_bInfiniteAmmo[iClient] = false;
	g_bClipAmmoOnly[iClient] = false;
}

public void OnConfigsExecuted() {
	if(g_bLateLoad)
		for(int iClient = 1; iClient <= MaxClients; iClient++)
			OnClientPostAdminCheck(iClient);
}

public void OnPluginEnd() {
	for(int iClient = 1; iClient <= MaxClients; iClient++)
		if(IsValidClient(iClient))
			SetInfiniteAmmo(iClient, false);
}

////////////////
//Cvar Changes//
////////////////



public void CvarChange_Friendly(ConVar Cvar, char[] oldValue, char[] newValue) {
	g_bFriendlyInfiniteAmmo = GetConVarBool(g_hFriendlyInfiniteAmmo);
	g_bFriendlyAmmoOnly = GetConVarBool(g_hFriendlyAmmoOnly);
}

public void CvarChange_MvMCash(ConVar Cvar, char[] oldValue, char[] newValue) {
	for(int iClient = 1; iClient <= MaxClients; iClient++)
		ResetAmmo(iClient);
}

public void CvarChange_AllInfiniteAmmo(ConVar Cvar, char[] oldValue, char[] newValue)
{
	int iNewValue = StringToInt(newValue);

	if(iNewValue)
	{
		int iAdminOnly = g_hAdminOnly.IntValue;
		for(int iClient = 1; iClient <= MaxClients; iClient++)
		{
			if(IsValidClient(iClient, false))
			{
				switch(iAdminOnly)
				{
					case 1,2:
					{
						if(CheckCommandAccess(iClient, "sm_aia_adminflag", ADMFLAG_GENERIC)) SetInfiniteAmmo(iClient, true);
						else SetInfiniteAmmo(iClient, false);						
					}
					default:
					{
						SetInfiniteAmmo(iClient, true);					
					}
				}
			}
		}
		if(iAdminOnly == 1 || iAdminOnly == 2) PrintToChatAll("[SM] Advanced Infinite Ammo for admins enabled");
		else PrintToChatAll("[SM] Advanced Infinite Ammo for everyone enabled");
	}
	else
	{
		for(int iClient = 1; iClient <= MaxClients; iClient++)

		{
			SetInfiniteAmmo(iClient, false);
			
		}
		PrintToChatAll("[SM] Advanced Infinite Ammo for everyone disabled");
	}
}

public void CvarChange_AdminOnly(ConVar Cvar, char[] oldValue, char[] newValue)
{
	int iNewValue = StringToInt(newValue);

	if(!iNewValue)
	{
		if(g_hAllInfiniteAmmo.BoolValue)
		{
			for(int iClient = 1; iClient <= MaxClients; iClient++)

			{
				SetInfiniteAmmo(iClient, true);
			}
		}
	}
	else
	{
		if(g_hAllInfiniteAmmo.BoolValue)
		{
			for(int iClient = 1; iClient <= MaxClients; iClient++)
			{
				if(!CheckCommandAccess(iClient, "sm_aia_adminflag", ADMFLAG_GENERIC)) SetInfiniteAmmo(iClient, false);
			}
		}
	}
}

public void CvarChange_Bots(ConVar Cvar, char[] oldValue, char[] newValue)
{
	int iNewValue = StringToInt(newValue);

	if(iNewValue)
	{
		for(int iClient = 1; iClient <= MaxClients; iClient++)

		{
			if(IsClientInGame(iClient) && IsFakeClient(iClient) && g_hAllInfiniteAmmo.BoolValue) SetInfiniteAmmo(iClient, true);
		}
	}
	else
	{
		for(int iClient = 1; iClient <= MaxClients; iClient++)

		{
			if(IsClientInGame(iClient) && IsFakeClient(iClient))
			{
				SetInfiniteAmmo(iClient, false, false);
				if(IsPlayerAlive(iClient))
				{
					SetRevengeCrits(iClient, 1);
					SetDecapitations(iClient, 0);
					int iClientHealth = GetClientHealth(iClient);
					TF2_RegeneratePlayer(iClient);
					SetEntityHealth(iClient, iClientHealth);
				}			
			}
		}
	}
}

public void CvarChange_AmmoOnly(ConVar Cvar, char[] oldValue, char[] newValue)
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		ResetAmmo(iClient);
	}
}

public void CvarChange_ExtraStuff(ConVar Cvar, char[] oldValue, char[] newValue)
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		ResetAmmo(iClient);
	}
}

public void CvarChange_WaitingForPlayers(ConVar Cvar, char[] oldValue, char[] newValue)
{
	int iNewValue = StringToInt(newValue);

	if(!iNewValue)
	{
		if(g_bWaitingForPlayers && !g_hAllInfiniteAmmo.BoolValue)
		{
			g_bInfiniteAmmoToggle = false;
			for(int iClient = 1; iClient <= MaxClients; iClient++)

			{
				ResetAmmo(iClient);			
			}
		} 
	}
	else
	{
		if(g_bWaitingForPlayers && !g_hAllInfiniteAmmo.BoolValue) g_bInfiniteAmmoToggle = true;
	}	
}

public void CvarChange_DisabledWeapons(ConVar Cvar, char[] oldValue, char[] newValue)
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		ResetAmmo(iClient);
	}
}

////////////
//Commands//
////////////


public Action Command_SetAIA(int iClient, int args)
{
	switch(args)
	{
		case 0:
		{
			if(g_bInfiniteAmmo[iClient])
			{
				SetInfiniteAmmo(iClient, false, true);
				if(g_hLog.BoolValue) LogAction(iClient, iClient, "\"%L\" Disabled Advanced Infinite Ammo for  \"%L\"", iClient, iClient);		
				if(g_hChat.BoolValue) ShowActivity2(iClient, "[SM] ","Advanced Infinite Ammo for %N disabled", iClient);
			}
			else
			{
				SetInfiniteAmmo(iClient, true, false);
				if(g_hLog.BoolValue) LogAction(iClient, iClient, "\"%L\" Enabled Advanced Infinite Ammo for  \"%L\"", iClient, iClient);
				if(g_hChat.BoolValue) ShowActivity2(iClient, "[SM] ","Advanced Infinite Ammo for %N enabled", iClient);
			}			
		}
		case 2:
		{
			char strTarget[MAX_TARGET_LENGTH], strOnOff[2], target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml, bOnOff;
			GetCmdArg(1, strTarget, sizeof(strTarget));
			if((target_count = ProcessTargetString(strTarget, iClient, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(iClient, target_count);
				return Plugin_Handled;
			}

			if((target_count > 1 || target_list[0] != iClient) && !CheckCommandAccess(iClient, "sm_aia_targetflag", ADMFLAG_SLAY))
			{
				ReplyToCommand(iClient, "[SM] You do not have access to targeting others");
				return Plugin_Handled;
			}

			GetCmdArg(2, strOnOff, sizeof(strOnOff));
			bOnOff = view_as<bool>StringToInt(strOnOff);
			bool bLogging = g_hLog.BoolValue;
			if(bOnOff)
			{
				for(int i = 0; i < target_count; i++)
				{
					SetInfiniteAmmo(target_list[i], true, false);
					if(bLogging) LogAction(iClient, target_list[i], "\"%L\" enabled Advanced Infinite Ammo for  \"%L\"", iClient, target_list[i]);
				}
				if(g_hChat.BoolValue) ShowActivity2(iClient, "[SM] ","Advanced Infinite Ammo for %s enabled", target_name);
			}
			else 
			{
				for(int i = 0; i < target_count; i++)
				{
					SetInfiniteAmmo(target_list[i], false, true);
					if(bLogging) LogAction(iClient, target_list[i], "\"%L\" disabled Advanced Infinite Ammo for  \"%L\"", iClient, target_list[i]);
				}
				if(g_hChat.BoolValue) ShowActivity2(iClient, "[SM] ","Advanced Infinite Ammo for %s disabled", target_name);			
			}
		}
		default:
		{
			ReplyToCommand(iClient, "[SM] Usage: sm_aia \"target\" \"1/0\"");
		}
	}

	return Plugin_Handled;
}

public Action Command_SetAIAAlternate(int iClient, int args)
{
	switch(args)
	{
		case 0:
		{
			if(g_bInfiniteAmmo[iClient])
			{
				SetInfiniteAmmo(iClient, false, true, false);
				if(g_hLog.BoolValue) LogAction(iClient, iClient, "\"%L\" Disabled Advanced Infinite Ammo for  \"%L\"", iClient, iClient);		
				if(g_hChat.BoolValue) ShowActivity2(iClient, "[SM] ","Advanced Infinite Ammo for %N disabled", iClient);
				
			}
			else
			{
				SetInfiniteAmmo(iClient, true, false, true);
				if(g_hLog.BoolValue) LogAction(iClient, iClient, "\"%L\" Enabled Advanced Infinite Ammo for  \"%L\"", iClient, iClient);
				if(g_hChat.BoolValue) ShowActivity2(iClient, "[SM] ","Advanced Infinite Ammo for %N enabled", iClient);
			}			
		}
		case 2:
		{
			char strTarget[MAX_TARGET_LENGTH], strOnOff[2], target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml, bOnOff;
			GetCmdArg(1, strTarget, sizeof(strTarget));
			if((target_count = ProcessTargetString(strTarget, iClient, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(iClient, target_count);
				return Plugin_Handled;
			}

			if((target_count > 1 || target_list[0] != iClient) && !CheckCommandAccess(iClient, "sm_aia_targetflag", ADMFLAG_SLAY))
			{
				ReplyToCommand(iClient, "[SM] You do not have access to targeting others");
				return Plugin_Handled;
			}

			GetCmdArg(2, strOnOff, sizeof(strOnOff));
			bOnOff = view_as<bool>StringToInt(strOnOff);
			bool bLogging = g_hLog.BoolValue;
			if(bOnOff)
			{
				for(int i = 0; i < target_count; i++)
				{
					SetInfiniteAmmo(target_list[i], true, false, true);
					if(bLogging) LogAction(iClient, target_list[i], "\"%L\" enabled Advanced Infinite Ammo for  \"%L\"", iClient, target_list[i]);
				}
				if(GetConVarBool(g_hChat)) ShowActivity(iClient, "[SM] ","Advanced Infinite Ammo for %s enabled", target_name);
				ReplyToCommand(iClient, "[SM] Advanced Infinite Ammo for %s enabled", target_name);
			}
			else 
			{
				for(int i = 0; i < target_count; i++)
				{
					SetInfiniteAmmo(target_list[i], false, true, false);
					if(bLogging) LogAction(iClient, target_list[i], "\"%L\" disabled Advanced Infinite Ammo for  \"%L\"", iClient, target_list[i]);
				}
				if(GetConVarBool(g_hChat)) ShowActivity(iClient, "[SM] ","Advanced Infinite Ammo for %s disabled", target_name);				
				ReplyToCommand(iClient, "[SM] Advanced Infinite Ammo for %s disabled", target_name);
			}
		}
		default:
		{
			ReplyToCommand(iClient, "[SM] Usage: sm_aia3 \"target\" \"1/0\"");
		}
	}

	return Plugin_Handled;
}

public Action Command_SetAIATimed(int iClient, int args)
{
	if(args != 2)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_aia2 \"target\" \"time(in seconds)\"");
		return Plugin_Handled;
	}

	char strTarget[MAX_TARGET_LENGTH], strTime[8], target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	float flTime;
	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, iClient, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(iClient, target_count);
		return Plugin_Handled;
	}

	if((target_count > 1 || target_list[0] != iClient) && !CheckCommandAccess(iClient, "sm_aia_targetflag", ADMFLAG_SLAY))
	{
		ReplyToCommand(iClient, "[SM] You do not have access to targeting others");
		return Plugin_Handled;
	}

	GetCmdArg(2, strTime, sizeof(strTime));
	flTime = StringToFloat(strTime);

	bool bLogging = g_hLog.BoolValue;
	for(int i = 0; i < target_count; i++)
	{
		SetInfiniteAmmo(target_list[i], true, false);
		CreateTimer(flTime, Timer_RemoveAIA, target_list[i], TIMER_FLAG_NO_MAPCHANGE);
		if(bLogging) LogAction(iClient, target_list[i], "\"%L\" Advanced Infinite Ammo enabled for \"%L\" for %f Seconds", iClient, target_list[i], flTime); 
	}
	if(g_hChat.BoolValue) ShowActivity2(iClient, "[SM] ","Advanced Infinite Ammo enabled for %s for %-.2f seconds", target_name, flTime);

	return Plugin_Handled;	
}

public Action Command_SetAIATimedAlternate(int iClient, int args)
{
	if(args != 2)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_aia2 \"target\" \"time(in seconds)\"");
		return Plugin_Handled;
	}

	char strTarget[MAX_TARGET_LENGTH], strTime[8], target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	float flTime;
	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, iClient, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(iClient, target_count);
		return Plugin_Handled;
	}

	if((target_count > 1 || target_list[0] != iClient) && !CheckCommandAccess(iClient, "sm_aia_targetflag", ADMFLAG_SLAY))
	{
		ReplyToCommand(iClient, "[SM] You do not have access to targeting others");
		return Plugin_Handled;
	}

	GetCmdArg(2, strTime, sizeof(strTime));
	flTime = StringToFloat(strTime);

	bool bLogging = g_hLog.BoolValue;
	for(int i = 0; i < target_count; i++)
	{
		SetInfiniteAmmo(target_list[i], true, false, true);
		CreateTimer(flTime, Timer_RemoveAIA, target_list[i], TIMER_FLAG_NO_MAPCHANGE);
		if(bLogging) LogAction(iClient, target_list[i], "\"%L\" Advanced Infinite Ammo enabled for \"%L\" for %f Seconds", iClient, target_list[i], flTime); 
	}
	if(g_hChat.BoolValue) ShowActivity2(iClient, "[SM] ","Advanced Infinite Ammo enabled for %s for %-.2f seconds", target_name, flTime);

	return Plugin_Handled;	
}

public Action Timer_RemoveAIA(Handle hTimer, any iClient) {
	SetInfiniteAmmo(iClient, false, true, false);
}

//////////
//Events//
//////////

public void Event_RoundStart(Event hEvent, const char[] strName, bool bDontBroadcast)
{	
	if(g_bInfiniteAmmoToggle && !g_bWaitingForPlayers)
	{
		g_bInfiniteAmmoToggle = false;
		if(g_hChat.BoolValue) PrintToChatAll("[SM] Round Start - Advanced Infinite Ammo disabled");
	}
}

public void Event_MVMWaveStart(Event hEvent, const char[] strName, bool bDontBroadcast)
{	
	if(g_bInfiniteAmmoToggle && !g_bWaitingForPlayers)
	{
		g_bInfiniteAmmoToggle = false;
		if(g_hChat.BoolValue) PrintToChatAll("[SM] Round Start - Advanced Infinite Ammo disabled");
		for(int iClient = 1; iClient <= MaxClients; iClient++)
			ResetAmmo(iClient);
	}
}

public void Event_RoundEnd(Event hEvent, const char[] strName, bool bDontBroadcast)
{
	if(!g_hAllInfiniteAmmo.BoolValue && g_hRoundWin.BoolValue)
	{
		g_bInfiniteAmmoToggle = true;	
		if(g_hChat.BoolValue) PrintToChatAll("[SM] Round Win - Advanced Infinite Ammo enabled");
	}
}

public void Event_ArenaRoundStart(Event hEvent, const char[] strName, bool bDontBroadcast)
{	
	if(g_bInfiniteAmmoToggle && !g_bWaitingForPlayers)
	{
		g_bInfiniteAmmoToggle = false;
		if(g_hChat.BoolValue) PrintToChatAll("[SM] Round Start - Advanced Infinite Ammo disabled");
	}
}

public void Event_ObjectBuilt(Event hEvent, const char[] strName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	int iBuilding = hEvent.GetInt("index");
	int iBuildType = hEvent.GetInt("object");
	if((iBuildType == 2) && CheckInfiniteAmmoAccess(iClient))
	if(CheckInfiniteAmmoAccess(iClient))
		SetEntProp(iBuilding, Prop_Data, "m_spawnflags", 1<<3);
}

////////////
//Forwards//
////////////

public void OnClientPostAdminCheck(int iClient)
{
	if(IsValidClient(iClient, false))
	{
		SDKHook(iClient, SDKHook_PreThink, SDKHooks_OnPreThink);
		SDKHook(iClient, SDKHook_WeaponEquipPost, SDKHooks_OnWeaponEquipPost);
		SDKHook(iClient, SDKHook_OnTakeDamage, SDKHooks_OnTakeDamage);
	}

	if(g_hAllInfiniteAmmo.BoolValue)
	{
		switch(g_hAdminOnly.IntValue)
		{
			case 1,2: {
				if(CheckCommandAccess(iClient, "sm_aia_adminflag", ADMFLAG_GENERIC)) SetInfiniteAmmo(iClient, true);
				else SetInfiniteAmmo(iClient, false);
			}
			default: SetInfiniteAmmo(iClient, true);
		}
	}
	else SetInfiniteAmmo(iClient, false, false);
}

public void TF2_OnWaitingForPlayersStart()
{
	g_bWaitingForPlayers = true;
	if(!g_hAllInfiniteAmmo.BoolValue && g_hWaitingForPlayers.BoolValue) 
	{
		g_bInfiniteAmmoToggle = true;
		if(g_hChat.BoolValue) PrintToChatAll("[SM] Waiting For Players Started - Advanced Infinite Ammo enabled");
	}
}

public void TF2_OnWaitingForPlayersEnd() {
	g_bWaitingForPlayers = false;
}

public void TF2_OnConditionRemoved(int iClient, TFCond hCondition) {
	if(g_hExtraStuff.BoolValue && hCondition == TFCond_Charging && CheckInfiniteAmmoAccess(iClient))
		SetChargeMeter(iClient);
}

public void OnEntityCreated(int iEntity, const char[] strClassname) {
	RequestFrame(OnEntityCreated_NextFrame, iEntity);
}

public void OnEntityCreated_NextFrame(any iData)
{
	char strClassname[128];
	if(IsValidEntity(iData)) GetEntityClassname(iData, strClassname, sizeof(strClassname));
	else return;
	if(strcmp(strClassname, "obj_sentrygun", false) == 0)
	{
		int iClient = GetEntPropEnt(iData, Prop_Send, "m_hBuilder");
		if(IsValidClient(iClient) && CheckInfiniteAmmoAccess(iClient))
		{
			int iFlags = GetEntProp(iData, Prop_Data, "m_spawnflags");
			SetEntProp(iData, Prop_Data, "m_spawnflags", iFlags|1<<3);
		}
	}	
}


///////////////////
//Main Ammo Stuff//
///////////////////

public void SDKHooks_OnWeaponEquipPost(int iClient, int iWeapon)
{
	if(IsValidClient(iClient))
	{
		g_iClientWeapons[iClient][0] = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary);
		g_iClientWeapons[iClient][1] = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Secondary);
		g_iClientWeapons[iClient][2] = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee);
	}
}

public void SDKHooks_OnPreThink(int iClient)
{
	if(IsValidClient(iClient) && CheckInfiniteAmmoAccess(iClient))
	{
		if(IsValidWeapon(g_iClientWeapons[iClient][0]))
			GiveInfiniteAmmo(iClient, g_iClientWeapons[iClient][0]);
		if(IsValidWeapon(g_iClientWeapons[iClient][1]))
			GiveInfiniteAmmo(iClient, g_iClientWeapons[iClient][1]);
		if(IsValidWeapon(g_iClientWeapons[iClient][2]))
			GiveInfiniteAmmo(iClient, g_iClientWeapons[iClient][2]);

		int iDispenser = -1; 
		while((iDispenser = FindEntityByClassname(iDispenser, "obj_dispenser")) != INVALID_ENT_REFERENCE)
			if(IsValidEntity(iDispenser) && GetEntPropEnt(iDispenser, Prop_Send, "m_hBuilder") == iClient)
				if(!GetDispenserAmmo(iDispenser)) 
					SetDispenserAmmo(iDispenser);
		
		if(GetConVarBool(g_hExtraStuff)) SetCloak(iClient);
		SetSpellUses(iClient, 1);
		if(IsMvM(true)) SetCash(iClient);
	}
}

public Action SDKHooks_OnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &flDamage, int &DmgType, int &iWep, float flDmgForce[3], float flDmgPos[3], int DmgCustom)
{
	if(IsValidClient(iVictim) && DmgCustom == TF_CUSTOM_BACKSTAB && CheckInfiniteAmmoAccess(iVictim) && HasRazorback(iVictim))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

bool CheckInfiniteAmmoAccess(int iClient)
{
	switch(g_hAdminOnly.IntValue)
	{
		case 1:
			if(CheckCommandAccess(iClient, "sm_aia_adminflag", ADMFLAG_GENERIC) && (g_bInfiniteAmmo[iClient] || g_bInfiniteAmmoToggle)) 
				return true;
		case 2:
			if(g_bInfiniteAmmo[iClient] || (CheckCommandAccess(iClient, "sm_aia_adminflag", ADMFLAG_GENERIC) && g_bInfiniteAmmoToggle)) 
				return true;
		default:
			if(g_bInfiniteAmmo[iClient] || g_bInfiniteAmmoToggle) 
				return true;
	}
	return false;
}


bool IsWeaponDisabled(int iWeaponIndex)
{
	char strWeaponList[1024];
	char strWeaponIndex[8];
	g_hDisabledWeapons.GetString(strWeaponList, sizeof(strWeaponList));
	Format(strWeaponList, sizeof(strWeaponList), ";%s;", strWeaponList);
	IntToString(iWeaponIndex, strWeaponIndex, sizeof(strWeaponIndex));
	Format(strWeaponIndex, sizeof(strWeaponIndex), ";%s;", strWeaponIndex);
	if(StrContains(strWeaponList, strWeaponIndex) != -1) return true;
	else return false;	
}

void GiveInfiniteAmmo(int iClient, int iWeapon)
{
	int iWeaponIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
	if(IsWeaponDisabled(iWeaponIndex)) return;
	bool bSetClip = g_bClipAmmoOnly[iClient] ? g_hAmmoOnly.BoolValue : !g_hAmmoOnly.BoolValue;
	bool bExtraStuff = g_hExtraStuff.BoolValue;
	switch(iWeaponIndex)
	{

		/////////////////////
		/////Multi Class/////
		/////////////////////


		////////////////////All Class////////////////////

		case 264,423,474,880,939,954,1013,1071,1123,1127:{}


		////////////////////Pistol/Lugermorph/Vintage Lugermorph(Scout/Engineer)////////////////////
		case 209,160,294,15013,15018,15035,15041,15056:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(iClient, iWeapon);
		}

		////////////////////Shotgun/Festive Shotgun/Panic Attack(Soldier/Pyro/Heavy/Engineer////////////////////

		case 199,1141,1153,15003,15016,15044:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(iClient, iWeapon);
		}

		////////////////////Reserve Shooter(Soldier/Pyro)////////////////////
			
		case 415:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(iClient, iWeapon);
		}


		////////////////////Pain Train/Half-Zatoichi/B.A.S.E. Jumper(Soldier/Demoman)////////////////////

		case 154,357,1101:{}

		///////////////
		/////Scout/////
		///////////////

		////////////////////Primary////////////////////

		case 13,200,45,220,669,799,808,888,897,906,915,964,973,1078,1103,15002,15015,15021,15029,15036,15053:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(iClient, iWeapon);
			if(bExtraStuff) SetHypeMeter(iClient);
		}

		case 448,772:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(iClient, iWeapon);
			if(bExtraStuff) SetHypeMeter(iClient);
		}

		////////////////////Secondary////////////////////

		case 23,449,773:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(iClient, iWeapon);
		}

		case 222,812,833,1121:
			SetAmmo(iClient, iWeapon);

		case 46,163,1145:
		{
			if(bExtraStuff)
			{
				SetAmmo(iClient, iWeapon);
				SetDrinkMeter(iClient);
				//if(GetClientButtons(iClient) & IN_ATTACK2) TF2_RemoveCondition(iClient, TFCond_Bonked);
			}
		}

		////////////////////Melee////////////////////

		case 0,190,221,317,325,349,355,450,452,572,660,999:{}

		case 44,648:
			SetAmmo(iClient, iWeapon);

		/////////////////
		/////Soldier/////
		/////////////////

		////////////////////Primary////////////////////

		case 18,205,127,228,237,414,513,658,800,809,889,898,907,916,965,974,1085,1104,15006,15014,15028,15043,15052,15057:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(iClient, iWeapon);
		}

		//Cow Mangler, Bison, Pomson - Energy Ammo
		case 441:
			if(bSetClip) 
				SetEnergyAmmo(iWeapon);

		case 730:
		{
			if(bSetClip && bExtraStuff) if(GetClientButtons(iClient) & IN_ATTACK2) SetClip(iWeapon, 3);
			SetAmmo(iClient, iWeapon);
		}

		////////////////////Secondary////////////////////

		case 10:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(iClient, iWeapon);
		}

		case 133,444:{}

		case 442:
			if(bSetClip) 
				SetEnergyAmmo(iWeapon);

		case 129,226,354,1001: 
			if(bExtraStuff && !GetRageMeter(iClient)) 
				SetRageMeter(iClient);

		////////////////////Melee////////////////////

		case 6,196,128,416,447,775:{}

		//////////////
		/////Pyro/////
		//////////////

		////////////////////Primary////////////////////

		case 21,208,40,215,659,741,798,807,887,896,905,914,963,972,1146,30474,15005,15017,15030,15034,15049,15054:
			SetAmmo(iClient, iWeapon);

		case 594: 
		{
			SetAmmo(iClient, iWeapon);
			if(bExtraStuff && !GetRageMeter(iClient)) 
				SetRageMeter(iClient);
		}

		////////////////////Secondary////////////////////

		case 12:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(iClient, iWeapon);
		}

		case 39,351,740,1081:
			SetAmmo(iClient, iWeapon);

		case 595:
			if(bExtraStuff) 
				SetRevengeCrits(iClient);

		////////////////////Melee////////////////////

		case 2,192,38,153,217,326,348,457,466,593,739,813,834,1000:{}

		/////////////////
		/////Demoman/////
		/////////////////

		////////////////////Primary////////////////////

		case 19,206,405,996,1007,1151:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(iClient, iWeapon);
		}

		case 308,608:{}

		////////////////////Secondary////////////////////

		case 20,207,130,265,661,797,806,886,895,904,913,962,971,1150,15009,15012,15024,15038,15048:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(iClient, iWeapon);
		}

		case 131,406,1099,1144:{}

		////////////////////Melee////////////////////

		case 1,191,172,327,404,609:{}

		case 132,266,482,1082:
			if(bExtraStuff)
				SetDecapitations(iClient);


		case 307:
			if(bExtraStuff)
				ResetCaber(iWeapon);					



		///////////////
		/////Heavy/////
		///////////////

		////////////////////Primary////////////////////

		case 15,202,41,298,312,424,654,793,802,811,832,850,882,891,900,909,958,967,15004,15020,15026,15031,15040,15055:
		{
			SetAmmo(iClient, iWeapon);
			if(bExtraStuff && !GetRageMeter(iClient)) SetRageMeter(iClient);
		}

		////////////////////Secondary////////////////////

		case 11,425:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(iClient, iWeapon);
		}

		case 42,159,311,433,863,1002:
			SetAmmo(iClient, iWeapon);

		////////////////////Melee////////////////////

		case 5,195,239,310,331,426,587,656,1084,1100:{}

		case 43:
			if(bExtraStuff)
				TF2_AddCondition(iClient, TFCond_CritOnKill, 5.0);

		//////////////////
		/////Engineer/////
		//////////////////

		////////////////////Primary////////////////////

		case 9,997:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(iClient, iWeapon);
		}

		case 527:
			SetMetal(iClient);

		case 588:
			if(bSetClip) 
				SetEnergyAmmo(iWeapon);

		case 141,1004:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(iClient, iWeapon);
			if(bExtraStuff) SetRevengeCrits(iClient);	
		}

		////////////////////Secondary////////////////////

		case 22:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(iClient, iWeapon);
		}

		case 528:
			SetMetal(iClient);

		case 140,1086:{}

		////////////////////Melee////////////////////

		case 7,197,142,155,169,329,589,662,795,804,884,893,902,911,960,969:
			SetMetal(iClient);

		///////////////
		/////Medic/////
		///////////////

		////////////////////Primary////////////////////

		case 17,204,36,305,412,1079:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(iClient, iWeapon);
		}

		////////////////////Secondary////////////////////

		case 29,211,35,411,663,796,805,885,894,903,912,961,970,998,15008,15010,15025,15039,15050:
		{
			if(bExtraStuff)
			{
				if(!GetUberCharge(iWeapon))
					SetUberCharge(iWeapon);
				if(!GetRageMeter(iClient))
					SetRageMeter(iClient);
			}
		}

		////////////////////Melee////////////////////

		case 8,198,37,173,304,413,1003,1143:{}

		////////////////
		/////Sniper/////
		////////////////

		////////////////////Primary////////////////////

		case 14,201,56,230,526,664,792,801,851,881,890,899,908,957,966,1005,1092,1098,15000,15007,15019,15023,15033,15037,15059:
		{
			SetAmmo(iClient, iWeapon);
			if(bExtraStuff)
				SetSniperRifleCharge(iWeapon);
		}

		case 402:
		{
			SetAmmo(iClient, iWeapon);
			if(bExtraStuff)
			{
				SetDecapitations(iClient);
				SetSniperRifleCharge(iWeapon);
			} 
		}
		case 752: 
		{
			SetAmmo(iClient, iWeapon);
			if(bExtraStuff)
			{
				SetSniperRifleCharge(iWeapon);
				if(!GetRageMeter(iClient))
					SetRageMeter(iClient);
			}
		}

		////////////////////Secondary////////////////////

		case 16,203,1149,15001,15022,15032,15058:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(iClient, iWeapon);
		}

		case 57,231,642:{}

		case 58,1083,1105:
			SetAmmo(iClient, iWeapon);

		case 751:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(iClient, iWeapon);
			if(bExtraStuff) TF2_AddCondition(iClient, TFCond_CritCola, 8.0);			
		}

		////////////////////Melee////////////////////

		case 3,193,171,232,401:{}

		//////////////
		/////Spy//////
		//////////////

		////////////////////Primary////////////////////

		case 24,210,61,161,224,460,1006,1142,15011,15027,15042,15051:
		{

			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(iClient, iWeapon);
		}

		case 525:
		{
			if(bSetClip) SetClip(iWeapon);
			else SetAmmo(iClient, iWeapon);
			if(bExtraStuff) SetRevengeCrits(iClient);	
		}

		////////////////////Secondary////////////////////

		case 735,736,810,831,933,1080,1102:
			SetEntPropFloat(iWeapon, Prop_Send, "m_flEffectBarRegenTime", 0.1);

		////////////////////Melee////////////////////

		case 4,194,225,356,574,638,665,727,794,803,883,892,901,910,959,968:{}

		case 649:
			if(bExtraStuff) 
				SetEntPropFloat(iWeapon, Prop_Send, "m_flKnifeRegenerateDuration", 0.0);

		case 461:
			if(bExtraStuff) 
				TF2_AddCondition(iClient, TFCond_SpeedBuffAlly, 3.0);	


		//Everything Else(Usually new weapons added to TF2 since last plugin update)
		default:
		{
			//if(bSetClip) SetClip(iWeapon);
			//SetAmmo(iClient, iWeapon);
		}
	}
}

void SetInfiniteAmmo(int iClient, bool bOnOff, bool bDoReset = true, bool bClip = false)
{
	if(bOnOff)
	{
		g_bInfiniteAmmo[iClient] = true;
		if(bClip) g_bClipAmmoOnly[iClient] = true;
		SetSentryInfiniteAmmoFlags(iClient, true);
	}
	else
	{
		g_bInfiniteAmmo[iClient] = false;
		g_bClipAmmoOnly[iClient] = false;
		SetSentryInfiniteAmmoFlags(iClient, false);
		if(bDoReset) ResetAmmo(iClient);
	}	
}

void ResetAmmo(int iClient)
{
	if(IsValidClient(iClient))
	{		
		SetRevengeCrits(iClient, 1);
		SetDecapitations(iClient, 0);
		int iClientHealth = GetClientHealth(iClient);
		TF2_RegeneratePlayer(iClient);
		SetEntityHealth(iClient, iClientHealth);
	}
}

//////////
//Stocks//
//////////

bool IsValidClient(int iClient, bool bCheckAlive=true)
{
	if(iClient < 1 || iClient > MaxClients) return false;
	if(!IsClientInGame(iClient)) return false;
	if(IsClientSourceTV(iClient) || IsClientReplay(iClient)) return false;
	if(!GetConVarBool(g_hBots) && IsFakeClient(iClient)) return false;
	if(bCheckAlive) return IsPlayerAlive(iClient);
	return true;
}

bool IsValidWeapon(int iEntity) {
	char strClassname[128];
	if(IsValidEntity(iEntity) && GetEntityClassname(iEntity, strClassname, sizeof(strClassname)) && StrContains(strClassname, "tf_weapon_", false) != -1) return true;
	return false;
}

stock void SetAmmo(int iClient, int iWeapon, int iAmmo = 300) {
	if(IsMvM(true)) iAmmo = 500;
	int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
	if(iAmmoType != -1) SetEntProp(iClient, Prop_Data, "m_iAmmo", iAmmo, _, iAmmoType);
}

stock void SetEnergyAmmo(int iWeapon, float flEnergyAmmo = 100.0) {
	SetEntPropFloat(iWeapon, Prop_Send, "m_flEnergy", flEnergyAmmo);
}

stock void SetClip(int iWeapon, int iClip = 99) {
	SetEntProp(iWeapon, Prop_Data, "m_iClip1", iClip);
}

stock void SetDrinkMeter(int iClient, float flDrinkMeter = 100.0) {
	SetEntPropFloat(iClient, Prop_Send, "m_flEnergyDrinkMeter", flDrinkMeter);
}

stock void SetHypeMeter(int iClient, float flHypeMeter = 100.0) {
	SetEntPropFloat(iClient, Prop_Send, "m_flHypeMeter", flHypeMeter);
}

stock float GetRageMeter(int iClient) {
	return GetEntPropFloat(iClient, Prop_Send, "m_flRageMeter");
}
stock void SetRageMeter(int iClient, float flRage = 100.0) {
	SetEntPropFloat(iClient, Prop_Send, "m_flRageMeter", flRage);
}

stock float GetUberCharge(int iWeapon) {
	return GetEntPropFloat(iWeapon, Prop_Send, "m_flChargeLevel");
}
stock void SetUberCharge(int iWeapon, float flUberCharge = 1.00) {
	SetEntPropFloat(iWeapon, Prop_Send, "m_flChargeLevel", flUberCharge);
}

stock void SetChargeMeter(int iClient, float flChargeMeter = 100.0) {
	SetEntPropFloat(iClient, Prop_Send, "m_flChargeMeter", flChargeMeter);
}

stock void SetSniperRifleCharge(int iWeapon, float flCharge = 150.0) {
	SetEntPropFloat(iWeapon, Prop_Send, "m_flChargedDamage", flCharge);
}

stock void SetRevengeCrits(int iClient, int iAmount = 99) {
	SetEntProp(iClient, Prop_Send, "m_iRevengeCrits", iAmount);
}

stock void SetDecapitations(int iClient, int iAmount = 99) {
	SetEntProp(iClient, Prop_Send, "m_iDecapitations", iAmount);
}

stock void ResetCaber(int iWeapon) {
	SetEntProp(iWeapon, Prop_Send, "m_bBroken", 0);
	SetEntProp(iWeapon, Prop_Send, "m_iDetonated", 0);
}

stock void SetSentryInfiniteAmmoFlags(int iClient, bool bOnOff = true)
{
	int iSentrygun = -1; 
	while((iSentrygun = FindEntityByClassname(iSentrygun, "obj_sentrygun")) != INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(iSentrygun) && GetEntPropEnt(iSentrygun, Prop_Send, "m_hBuilder") == iClient)
		{
			int iFlags = GetEntProp(iSentrygun, Prop_Data, "m_spawnflags");
			if(bOnOff) SetEntProp(iSentrygun, Prop_Data, "m_spawnflags", iFlags|1<<3);
			else SetEntProp(iSentrygun, Prop_Data, "m_spawnflags", iFlags&~1<<3);
		}
	}
}

stock int GetDispenserAmmo(int iDispenser) {
	return GetEntProp(iDispenser, Prop_Send, "m_iAmmoMetal");
}
stock void SetDispenserAmmo(int iDispenser, int iAmmo = 400) {
	SetEntProp(iDispenser, Prop_Send, "m_iAmmoMetal", iAmmo);
}

stock void SetMetal(int iClient, int iMetal = 200) {
	if(IsMvM(true)) iMetal = 600;
	SetEntProp(iClient, Prop_Data, "m_iAmmo", iMetal, 4, 3);
}

stock void SetCloak(int iClient, float flCloak = 100.0) {
	SetEntPropFloat(iClient, Prop_Send, "m_flCloakMeter", flCloak);	
}

stock void SetCash(int iClient, int iCash = 2000) {
	SetEntProp(iClient, Prop_Send, "m_nCurrency", iCash);
}

stock bool HasRazorback(int iClient)
{
	int entity = -1;
	while((entity = FindEntityByClassname(entity, "tf_wearable")) != INVALID_ENT_REFERENCE)
		if(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex") == 57 && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == iClient)
			return true;
	
	return false;
}

stock int GetSpellBook(int iClient)
{
	int iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, "tf_weapon_spellbook")) != INVALID_ENT_REFERENCE)
		if(GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == iClient) 
			return iEntity;
	
	return -1;
}
stock void SetSpellUses(int iClient, int iUses = 99)
{
	int iEnt = GetSpellBook(iClient);
	if(!IsValidEntity(iEnt)) return;
	if(IsWeaponDisabled(GetEntProp(iEnt, Prop_Send, "m_iItemDefinitionIndex"))) return;
	if(GetClientButtons(iClient) & IN_RELOAD)
	{
		SetEntProp(iEnt, Prop_Send, "m_iSelectedSpellIndex", -1);
		SetEntProp(iEnt, Prop_Send, "m_iSpellCharges", 0);
	}
	if((GetEntProp(iEnt, Prop_Send, "m_iSelectedSpellIndex") >= 0) && (GetEntProp(iEnt, Prop_Send, "m_iSelectedSpellIndex") <= 11))
	{
		SetEntProp(iEnt, Prop_Send, "m_iSpellCharges", iUses);
	}
}

bool IsMvM(bool bRecalc = false)
{
	bool bChecked = false;
	bool bMannVsMachines = false;
	
	if(bRecalc || !bChecked)
	{
		int iEnt = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
		bMannVsMachines = (iEnt > MaxClients && IsValidEntity(iEnt));
		bChecked = true;
	}
	
	return bMannVsMachines;
}