#include <clientprefs>
#include <colors>
#include <cstrike>
#include <nstocks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

// *** [ Defines ] ***
#define PLUGIN_VERSION "2.0.0"

// *** [ Globals ] ***
Handle g_hCookie = null;
bool g_bHideKnife[MAXPLAYERS+1] = {false, ...};

// *** [ ConVars ] ***
ConVar g_cGiveKnifeOnly = null;
ConVar g_cRemoveOtherWeapons = null;
ConVar g_cShowInfoMessage = null;

public Plugin myinfo = 
{
	name = "[CS:GO] Noknife",
	author = "n0:name",
	description = "Allows players to entirely hide their knives and weapons",
	version = PLUGIN_VERSION,
	url = "www.f-o-g.eu"
}

public void OnPluginStart()
{
	// cvar's
	CreateConVar("sm_noknife_version", PLUGIN_VERSION, "Noknife version", FCVAR_NOTIFY);
	g_cGiveKnifeOnly = CreateConVar("sm_noknife_knife_only", "1", "Enable/disable only giving a knife by default (no primaries/secondaries)");
	g_cRemoveOtherWeapons = CreateConVar("sm_noknife_strip_other", "0", "Enable/disable stripping a player's entire inventory");
	g_cShowInfoMessage = CreateConVar("sm_noknife_removal_info", "1", "Behaviour of the !knife command. 0 = do nothing \"invalid command\", 1 = show info message, 2 = alias for !noknife");
	
	// events
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_PostNoCopy);
	HookEvent("item_pickup", Event_ItemPickup);
	
	// commands
	if(g_cShowInfoMessage.IntValue == 1)
	{
		RegConsoleCmd("sm_knife", Command_Knife);
	}
	else if(g_cShowInfoMessage.IntValue == 2)
	{
		RegConsoleCmd("sm_knife", Command_NoKnife);
	}
	RegConsoleCmd("sm_noknife", Command_NoKnife);
	RegConsoleCmd("sm_disarm", Command_NoKnife);
	
	// other stuff
	g_hCookie = RegClientCookie("sm_noknife_hidden", "State of noknife", CookieAccess_Protected);
	
	LoadTranslations("noknife.phrases");
	AutoExecConfig(true);
}

public void OnClientCookiesCached(int iClient)
{
	char szBuffer[2];
	GetClientCookie(iClient, g_hCookie, szBuffer, sizeof(szBuffer));
	
	g_bHideKnife[iClient] = view_as<bool>(StringToInt(szBuffer));
	
	// account for "late" loading (i.e. cookies loading very late - mostly seen with mySQL hosted clientprefs)
	if(g_bHideKnife[iClient] && IsValidClient(iClient) && IsPlayerAlive(iClient))
	{
		HideKnife(iClient);
	}
}

public void OnClientDisconnect(int iClient)
{
	g_bHideKnife[iClient] = false;
}

public void OnMapStart()
{
	if(!g_cGiveKnifeOnly.BoolValue)
	{
		return;
	}
	
	// CT
	SetConVarString(FindConVar("mp_ct_default_primary"), "");
	SetConVarString(FindConVar("mp_ct_default_secondary"), "");
	SetConVarString(FindConVar("mp_ct_default_grenades"), "");
	
	// T
	SetConVarString(FindConVar("mp_t_default_primary"), "");
	SetConVarString(FindConVar("mp_t_default_secondary"), "");
	SetConVarString(FindConVar("mp_t_default_grenades"), "");
}

public Action Command_Knife(int iClient, int iArgs)
{
	if(!IsValidClient(iClient))
	{
		return Plugin_Handled;
	}
	
	CPrintToChat(iClient, "{lightred}%t", "Fake econ item info");
	return Plugin_Handled;
}

public Action Command_NoKnife(int iClient, int iArgs)
{
	if(!IsValidClient(iClient))
	{
		return Plugin_Handled;
	}
	
	char szBuffer[2];
	char szCommand[32];
	GetCmdArg(0, szCommand, sizeof(szCommand));
	
	if(g_bHideKnife[iClient])
	{
		CReplyToCommand(iClient, "{green}[SM]{default} %t", "Knife visible");
		
		g_bHideKnife[iClient] = false;
		GiveKnife(iClient);
	}
	else
	{
		CPrintToChat(iClient, "{green}[SM]{default} %t", "Knife hidden 1");
		CPrintToChat(iClient, "{green}[SM]{default} %t", "Knife hidden 2", szCommand, szCommand);

		g_bHideKnife[iClient] = true;
		HideKnife(iClient);
	}
	
	IntToString(g_bHideKnife[iClient], szBuffer, sizeof(szBuffer));
	SetClientCookie(iClient, g_hCookie, szBuffer);
	
	return Plugin_Handled;
}


public Action Event_PlayerSpawn(Handle hEvent, const char[] szName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(!IsValidClient(iClient)) return;
	if(GetClientTeam(iClient) <= CS_TEAM_SPECTATOR) return;
	
	if(g_bHideKnife[iClient])
	{
		CreateTimer(0.1, Timer_HideKnife, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Event_ItemPickup(Handle hEvent, const char[] szName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(!IsValidClient(iClient)) return;
	if(!g_bHideKnife[iClient]) return;
	
	CreateTimer(0.2, Timer_HideKnife, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);	
}

public Action Timer_HideKnife(Handle hTimer, any iData)
{
	int iClient = GetClientOfUserId(iData);
	if(!IsValidClient(iClient) || !IsPlayerAlive(iClient)) return Plugin_Stop;
	
	HideKnife(iClient);
	return Plugin_Continue;
}

public void GiveKnife(int iClient)
{
	int iKnife = GetPlayerWeaponSlot(iClient, CS_SLOT_KNIFE);
	if(IsValidEntity(iKnife) && iKnife != INVALID_ENT_REFERENCE)
	{
		return;
	}
	
	iKnife = GivePlayerItem(iClient, "weapon_knife");
	EquipPlayerWeapon(iClient, iKnife);
}

public void HideKnife(int iClient)
{
	int iKnife = GetPlayerWeaponSlot(iClient, CS_SLOT_KNIFE);
	if(IsValidEntity(iKnife) && iKnife != INVALID_ENT_REFERENCE)
	{
		RemovePlayerItem(iClient, iKnife);
		AcceptEntityInput(iKnife, "Kill");
	}
	
	if(!g_cRemoveOtherWeapons.BoolValue)
	{
		return;
	}
	
	int iOther;
		
	for(int i = 0; i <= 4; i++)
	{
		iOther = GetPlayerWeaponSlot(iClient, i);
		if(!IsValidEntity(iOther)) continue;
			
		RemovePlayerItem(iClient, iOther);
		AcceptEntityInput(iOther, "Kill");
		
		// more grenades to remove
		if(i == view_as<int>(CS_SLOT_GRENADE) && IsValidEntity(GetPlayerWeaponSlot(iClient, CS_SLOT_GRENADE))) i = view_as<int>(CS_SLOT_GRENADE);
	}
}