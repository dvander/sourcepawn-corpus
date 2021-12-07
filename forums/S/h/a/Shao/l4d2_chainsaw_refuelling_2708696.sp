/*

	Created by DJ_WEST
	
	Web: http://amx-x.ru
	AMX Mod X and SourceMod Russian Community
	
*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1; // Force strict semicolon mode.
#pragma newdecls required; // Force new-style declarations.

#define PLUGIN_NAME "Chainsaw Refuelling"
#define PLUGIN_VERSION "1.6.1"
#define PLUGIN_AUTHOR "DJ_WEST, Lossy (For Round Start QuickFix), Shao (For downstate support)"

#define CHAINSAW_DISTANCE 50.0
#define CHAINSAW "chainsaw"
#define CHAINSAW_CLASS "weapon_chainsaw"
#define CHAINSAW_SPAWN_CLASS "weapon_chainsaw_spawn"
#define GASCAN_CLASS "weapon_gascan"
#define GASCAN_SKIN 0
#define TEAM_SURVIVOR 2

int g_ActiveWeaponOffset, g_ShotsFiredOffset, g_ClientPour[MAXPLAYERS+1], g_PlayerPistol[MAXPLAYERS+1];
Handle g_Timer[MAXPLAYERS+1], h_CvarEnabled, h_CvarRemove, h_CvarMode, h_CvarDrop;
bool g_ClientInfo[MAXPLAYERS+1], g_b_IsSurvivor[MAXPLAYERS+1], g_b_AllowChecking[MAXPLAYERS+1], g_b_InAction[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = "Allow refuelling of a chainsaw",
	version = PLUGIN_VERSION,
	url = "http://amx-x.ru"
}

public void OnPluginStart()
{
	char s_Game[12];
	Handle h_Version;
	
	GetGameFolderName(s_Game, sizeof(s_Game));
	
	if (!StrEqual(s_Game, "left4dead2"))
	{
		SetFailState("Chainsaw Refuelling will only work with Left 4 Dead 2!");
	}
		
	LoadTranslations("chainsaw_refuelling.phrases");
	
	h_Version = CreateConVar("refuelchainsaw_version", PLUGIN_VERSION, "Chainsaw Refuelling version", /*FCVAR_PLUGIN|*/FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	h_CvarEnabled = CreateConVar("l4d2_refuelchainsaw_enabled", "1", "Chainsaw Refuelling plugin status (0 - disable, 1 - enable)", /*FCVAR_PLUGIN|*/FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_CvarRemove = CreateConVar("l4d2_refuelchainsaw_remove", "0", "Remove a chainsaw if it empty (0 - don't remove, 1 - remove)", /*FCVAR_PLUGIN|*/FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_CvarMode = CreateConVar("l4d2_refuelchainsaw_mode", "2", "Allow refuelling of a chainsaw (0 - on the ground, 1 - on players, 2 - both)", /*FCVAR_PLUGIN|*/FCVAR_NOTIFY, true, 0.0, true, 2.0);
	h_CvarDrop = CreateConVar("l4d2_refuelchainsaw_drop", "1", "Enable dropping a chainsaw (0 - disable, 1 - enable)", /*FCVAR_PLUGIN|*/FCVAR_NOTIFY, true, 0.0, true, 1.0);

	// Moved to OnMapStart()
	//g_ActiveWeaponOffset = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
	//g_ShotsFiredOffset = FindSendPropInfo("CCSPlayer", "m_iShotsFired");
	
	HookEvent("gascan_pour_completed", EventPourCompleted);
	HookEvent("item_pickup", EventItemPickup);
	HookEvent("player_team", EventPlayerTeam);
	HookEvent("player_incapacitated", EventAllowChecking);
	HookEvent("lunge_pounce", EventNotAllowChecking);
	HookEvent("jockey_ride", EventNotAllowChecking);
	HookEvent("tongue_grab", EventNotAllowChecking);
	HookEvent("charger_carry_start", EventNotAllowChecking);
	HookEvent("charger_pummel_start", EventNotAllowChecking);
	HookEvent("player_ledge_grab", EventNotAllowChecking);
	HookEvent("player_death", EventNotAllowChecking);
	HookEvent("revive_success", EventAllowChecking);
	HookEvent("defibrillator_used", EventAllowChecking);
	HookEvent("pounce_stopped", EventAllowChecking);
	HookEvent("jockey_ride_end", EventAllowChecking);
	HookEvent("tongue_release", EventAllowChecking);
	HookEvent("charger_carry_end", EventAllowChecking);
	HookEvent("charger_pummel_end", EventAllowChecking);
	HookEvent("round_start", EventRoundStart);

	
	SetConVarString(h_Version, PLUGIN_VERSION);
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
		g_b_AllowChecking[i] = false;

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			g_b_AllowChecking[i] = true;

	g_ActiveWeaponOffset = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
	g_ShotsFiredOffset = FindSendPropInfo("CCSPlayer", "m_iShotsFired");
}

public void EventRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	OnMapStart();
}

public Action EventNotAllowChecking(Handle h_Event, const char[] s_Name, bool b_DontBroadcast)
{
	int i_UserID, i_Client;
	
	if (GetEventInt(h_Event, "victim"))
		i_UserID = GetEventInt(h_Event, "victim");
	else
		i_UserID = GetEventInt(h_Event, "userid");
	
	i_Client = GetClientOfUserId(i_UserID);
	
	if (g_b_IsSurvivor[i_Client])
		g_b_AllowChecking[i_Client] = false;
}

public Action EventAllowChecking(Handle h_Event, const char[] s_Name, bool b_DontBroadcast)
{
	int i_UserID, i_Client;
	
	if (GetEventInt(h_Event, "victim"))
		i_UserID = GetEventInt(h_Event, "victim");
	else if (GetEventInt(h_Event, "subject"))
		i_UserID = GetEventInt(h_Event, "subject");
	else
		i_UserID = GetEventInt(h_Event, "userid");
	
	i_Client = GetClientOfUserId(i_UserID);
	
	if (g_b_IsSurvivor[i_Client])
		g_b_AllowChecking[i_Client] = true;
	
}

public Action EventPlayerTeam(Handle h_Event, const char[] s_Name, bool b_DontBroadcast)
{
	if (!GetEventBool(h_Event, "isbot"))
	{
		int i_UserID, i_Client;
	
		i_UserID = GetEventInt(h_Event, "userid");
		i_Client = GetClientOfUserId(i_UserID);
		
		if (GetEventInt(h_Event, "team") == TEAM_SURVIVOR)
		{
			g_b_IsSurvivor[i_Client] = true;
			g_b_AllowChecking[i_Client] = true;
		}
		else
		{
			g_b_IsSurvivor[i_Client] = false;
			g_b_AllowChecking[i_Client] = false;
		}
	}
}

public Action EventItemPickup(Handle h_Event, const char[] s_Name, bool b_DontBroadcast)
{
	int i_UserID, i_Client;
	char s_Weapon[16];
	
	i_UserID = GetEventInt(h_Event, "userid");
	i_Client = GetClientOfUserId(i_UserID);

	GetEventString(h_Event, "item", s_Weapon, sizeof(s_Weapon));

	if (StrEqual(s_Weapon, CHAINSAW))
	{
		int i_Pistol;
		
		i_Pistol = g_PlayerPistol[i_Client];
		if (i_Pistol && IsValidEnt(i_Pistol))
		{
			RemoveEdict(i_Pistol);
			g_PlayerPistol[i_Client] = 0;
		}
			
		if (!g_ClientInfo[i_Client] && GetConVarBool(h_CvarEnabled))
		{
			PrintToChat(i_Client, "\x03[%t]\x01 %t.", "Information", "Refuelling");
			PrintToChat(i_Client, "\x03[%t]\x01 %t.", "Information", "Drop");
			g_ClientInfo[i_Client] = true;
		}
	}
}

public Action EventPourCompleted(Handle h_Event, const char[] s_Name, bool b_DontBroadcast)
{
	int i_UserID, i_Client, i_Ent;
	
	i_UserID = GetEventInt(h_Event, "userid");
	i_Client = GetClientOfUserId(i_UserID);
	i_Ent = g_ClientPour[i_Client];
	
	if (i_Ent)
		SetEntProp(i_Ent, Prop_Data, "m_iClip1", 30);
}

public void OnClientPutInServer(int i_Client)
{
	if (IsFakeClient(i_Client))
		return;
		
	g_ClientPour[i_Client] = 0;
	g_PlayerPistol[i_Client] = 0;
	g_ClientInfo[i_Client] = false;
	g_b_IsSurvivor[i_Client] = false;
	g_b_AllowChecking[i_Client] = true;
	g_b_InAction[i_Client] = false;
}

public Action CheckTarget(int i_Client)
{
	int i_Ent, i_Mode;
	char s_Class[64];

	i_Ent = GetClientAimTarget(i_Client, false);
	i_Mode = GetConVarInt(h_CvarMode);
	
	if (IsValidEnt(i_Ent))
	{
		GetEdictClassname(i_Ent, s_Class, sizeof(s_Class));
		
		if (StrEqual(s_Class, CHAINSAW_SPAWN_CLASS) && i_Mode != 1)
		{
			PrintToChat(i_Client, "\x03[%t]\x01 %t.", "Information", "Full");
			return Plugin_Handled;
		}
		else if (StrEqual(s_Class, CHAINSAW_CLASS) && i_Mode != 1)
			CheckChainsaw(i_Client, i_Ent, -1);
		else if (StrEqual(s_Class, "player") && i_Mode != 0)
		{
			int i_Weapon;
			char s_Weapon[32];
			
			i_Weapon = GetEntDataEnt2(i_Ent, g_ActiveWeaponOffset);
			GetEdictClassname(i_Weapon, s_Weapon, sizeof(s_Weapon));
			
			if (StrEqual(s_Weapon, CHAINSAW_CLASS))
				CheckChainsaw(i_Client, i_Weapon, i_Ent);
		}
	}
	
	return Plugin_Continue;
}

public Action CheckChainsaw(int i_Client, int i_Weapon, int i_Ent)
{
	float f_EntPos[3], f_ClientPos[3];
	
	GetEntPropVector(i_Ent == -1 ? i_Weapon : i_Ent, Prop_Send, "m_vecOrigin", f_EntPos);
	GetClientAbsOrigin(i_Client, f_ClientPos);
			
	if (GetVectorDistance(f_EntPos, f_ClientPos) <= CHAINSAW_DISTANCE)
	{
		int i_PointEnt, i_ChainsawPointEnt, i_Clip;
				
		i_Clip = GetEntProp(i_Weapon, Prop_Data, "m_iClip1");
				
		if (i_Clip == 30)
		{
			PrintToChat(i_Client, "\x03[%t]\x01 %t.", "Information", "Full");
			return Plugin_Handled;
		}
				
		i_ChainsawPointEnt = GetEntProp(i_Weapon, Prop_Data, "m_iClip2");
				
		if (i_ChainsawPointEnt == -1)
		{
			i_PointEnt = (i_Ent == -1) ? CreatePointEntity(i_Weapon, 10.0) : CreatePointEntity(i_Ent, 50.0);
				
			if (IsValidEnt(i_PointEnt))
			{
				SetEntProp(i_Weapon, Prop_Data, "m_iClip2", i_PointEnt);
				g_ClientPour[i_Client] = i_Weapon;
					
				Handle h_Pack;
				h_Pack = CreateDataPack();
				WritePackCell(h_Pack, i_Client);
				WritePackCell(h_Pack, i_Weapon);
				g_Timer[i_Client] = CreateTimer(0.5, CheckPourGascan, h_Pack, TIMER_REPEAT);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action CheckPourGascan(Handle h_Timer, Handle h_Pack)
{
	int i_Client, i_Ent, i_PointEnt, i_ShotsFired;
	
	ResetPack(h_Pack, false);
	i_Client = ReadPackCell(h_Pack);
	i_Ent = ReadPackCell(h_Pack);
	
	i_PointEnt = GetEntProp(i_Ent, Prop_Data, "m_iClip2");
	i_ShotsFired = GetEntData(i_Client, g_ShotsFiredOffset);
	
	if (i_ShotsFired == 0)
	{
		CloseHandle(h_Pack);
		RemoveEdict(i_PointEnt);
		SetEntProp(i_Ent, Prop_Data, "m_iClip2", -1);
		
		if (g_Timer[i_Client] != INVALID_HANDLE)
		{
			KillTimer(g_Timer[i_Client]);
			g_Timer[i_Client] = INVALID_HANDLE;
		}	
		
		g_ClientPour[i_Client] = 0	;
	}
}

public int CreatePointEntity(int i_Ent, float f_Add)
{
	float f_Position[3];
	int i_PointEnt;
	
	GetEntPropVector(i_Ent, Prop_Send, "m_vecOrigin", f_Position);
	f_Position[2] += f_Add;
	
	i_PointEnt = CreateEntityByName("point_prop_use_target");
	DispatchKeyValueVector(i_PointEnt, "origin", f_Position);
	DispatchKeyValue(i_PointEnt, "nozzle", "gas_nozzle");
	DispatchSpawn(i_PointEnt);
	
	return i_PointEnt;
}

public Action OnPlayerRunCmd(int i_Client, int &i_Buttons, int &i_Impulse, float f_Velocity[3], float f_Angles[3], int &i_Wpn)
{
	if (!GetConVarBool(h_CvarEnabled))
		return Plugin_Continue;
		
	if (!g_b_AllowChecking[i_Client])
		return Plugin_Continue;
		
	if (g_b_InAction[i_Client] && (i_Buttons & IN_ATTACK || i_Buttons & IN_USE || i_Buttons & IN_RELOAD))
		return Plugin_Continue;
	else if (g_b_InAction[i_Client])
		g_b_InAction[i_Client] = false;

	if (g_ClientPour[i_Client])
		return Plugin_Continue;
	
	int i_Weapon;
	
	if (i_Buttons & IN_ATTACK)
	{
		char s_Weapon[32];
		int i_Skin;
		
		i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset);
		
		if (IsValidEnt(i_Weapon))
		{
			GetEdictClassname(i_Weapon, s_Weapon, sizeof(s_Weapon));
			i_Skin = GetEntProp(i_Weapon, Prop_Send, "m_nSkin");
		}
		
		if (StrEqual(s_Weapon, GASCAN_CLASS) && i_Skin == GASCAN_SKIN)
			CheckTarget(i_Client);
		else if (StrEqual(s_Weapon, CHAINSAW_CLASS) && !GetConVarBool(h_CvarRemove))
		{
			int i_Clip;

			if (!IsValidEnt(i_Weapon))
				return Plugin_Continue;
				
			i_Clip = GetEntProp(i_Weapon, Prop_Data, "m_iClip1");
			
			if (i_Clip <= 1)
				i_Buttons &= ~IN_ATTACK;
		}
		else
			g_b_InAction[i_Client] = true;
	}
	
	if (i_Buttons & IN_USE)
	{
		i_Weapon = GetClientAimTarget(i_Client, false);
		
		g_b_InAction[i_Client] = true;
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (g_ClientPour[i] == i_Weapon)
			{
				i_Buttons &= ~IN_USE;
				break;
			}
		}
			
		return Plugin_Continue;
	}
	
	if (i_Buttons & IN_RELOAD)
	{
		char s_Weapon[32];
		
		i_Weapon = GetEntDataEnt2(i_Client, g_ActiveWeaponOffset);
		
		if (g_PlayerPistol[i_Client] && i_Weapon == -1)
			return Plugin_Continue;
		
		if (IsValidEnt(i_Weapon))
			GetEdictClassname(i_Weapon, s_Weapon, sizeof(s_Weapon));
		
		if (StrEqual(s_Weapon, CHAINSAW_CLASS) && GetConVarBool(h_CvarDrop))
		{
			int i_Ent;
			
			i_Ent = CreateEntityByName("weapon_pistol");
			DispatchSpawn(i_Ent);
			EquipPlayerWeapon(i_Client, i_Ent);
			
			g_PlayerPistol[i_Client] = i_Ent;
		}
		else
			g_b_InAction[i_Client] = true;
	}
	
	return Plugin_Continue;
}

stock bool IsValidEnt(int i_Ent)
{
	return (IsValidEdict(i_Ent) && IsValidEntity(i_Ent));
}