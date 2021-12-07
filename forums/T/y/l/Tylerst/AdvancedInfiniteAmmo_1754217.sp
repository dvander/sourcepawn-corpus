#pragma semicolon 1

#include <tf2_stocks>
#include <sdkhooks>
#include <adminmenu>

#pragma newdecls required

#define PLUGIN_VERSION "1.5.3"

#define AMMOFLAG_NONE			0
#define AMMOFLAG_CLIP			(1 << 0)
#define AMMOFLAG_AMMO			(1 << 1) 
#define AMMOFLAG_EXTRA			(1 << 2)
#define AMMOFLAG_METAL			(1 << 3)
#define AMMOFLAG_SENTRY			(1 << 4)
#define AMMOFLAG_CLOAK			(1 << 5)
#define AMMOFLAG_SPELLS			(1 << 6)
#define AMMOFLAG_ALL			AMMOFLAG_CLIP|AMMOFLAG_AMMO|AMMOFLAG_EXTRA|AMMOFLAG_METAL|AMMOFLAG_SENTRY|AMMOFLAG_CLOAK|AMMOFLAG_SPELLS

#define AMMOSOURCE_NONE				0
#define AMMOSOURCE_COMMAND			(1 << 0)
#define AMMOSOURCE_TIMER			(1 << 1)  
#define AMMOSOURCE_CVAR_ALL			(1 << 2) 
#define AMMOSOURCE_CVAR_ROUNDWIN		(1 << 3) 
#define AMMOSOURCE_CVAR_WAITINGFORPLAYERS	(1 << 4)
#define AMMOSOURCE_PLUGIN			(1 << 5)


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
	
	CreateNative("AIA_HasAIA", Native_AIA_HasAIA);
	CreateNative("AIA_SetAIA", Native_AIA_SetAIA);
	CreateNative("AIA_GetAmmoFlags", Native_AIA_GetAmmoFlags);
	CreateNative("AIA_SetAmmoFlags", Native_AIA_SetAmmoFlags);
	
	
	return APLRes_Success;
}


int g_iAmmoFlags[MAXPLAYERS+1][2]; //[0] Flag [1] Source
int g_iClientWeapons[MAXPLAYERS+1][4]; //Primary, Secondary, Melee, Spellbook

int g_iGlobalFlags[2] = {AMMOFLAG_ALL, AMMOSOURCE_NONE};

bool g_bWaitingForPlayers;

Handle g_hOnAIAChanged = INVALID_HANDLE;

ConVar g_hAllInfiniteAmmo;
ConVar g_hRoundWin;
ConVar g_hWaitingForPlayers;
ConVar g_hAdminOnly;
ConVar g_hBots;
ConVar g_hChat;
ConVar g_hLog;
ConVar g_hDisabledWeapons;

ConVar g_hClip;
ConVar g_hAmmo;
ConVar g_hExtra;
ConVar g_hMetal;
ConVar g_hSentry;
ConVar g_hCloak;
ConVar g_hSpells;

public void OnPluginStart()
{
	CreateConVar("sm_aia_version", PLUGIN_VERSION, "Advanced Infinite Ammo", FCVAR_DONTRECORD);
	LoadTranslations("common.phrases");
	g_hOnAIAChanged = CreateGlobalForward("AIA_OnAIAChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

	RegAdminCmd("sm_aia", Command_SetAIA, ADMFLAG_SLAY, "Give Advanced Infinite Ammo to the target(s) - Usage: sm_aia \"target\" \"1/0\"");
	RegAdminCmd("sm_aia2", Command_SetAIATimed, ADMFLAG_SLAY, "Give Advanced Infinite Ammo to the target(s) for a limited time - Usage: sm_aia2 \"target\" \"time(in seconds)\"");
	RegAdminCmd("sm_aiamenu", Command_AIAMenu, ADMFLAG_SLAY, "Show menu to set target's ammo flags");

	g_hAllInfiniteAmmo = CreateConVar("sm_aia_all", "0", "Advanced Infinite Ammo for everyone");
	g_hAdminOnly = CreateConVar("sm_aia_adminonly", "0", "Advanced Infinite Ammo will work for admins only, 1 = Completely Admin Only, 2 = Admin Only but the commands will work on non-admins");
	g_hBots = CreateConVar("sm_aia_bots", "1", "Advanced Infinite Ammo will work for bots");
	g_hRoundWin = CreateConVar("sm_aia_roundwin", "1", "Advanced Infinite Ammo for everyone on round win");
	g_hWaitingForPlayers = CreateConVar("sm_aia_waitingforplayers", "1", "Advanced Infinite Ammo for everyone during waiting for players phase");
	g_hChat = CreateConVar("sm_aia_chat", "1", "Show Advanced Infinite Ammo changes in chat");
	g_hLog = CreateConVar("sm_aia_log", "1", "Log Advanced Infinite Ammo commands");
	g_hDisabledWeapons = CreateConVar("sm_aia_disabledweapons", "", "Weapons indexes to not give infinite ammo, separated by semicolons");

	g_hAllInfiniteAmmo.AddChangeHook(CvarChange_AllInfiniteAmmo);
	g_hAdminOnly.AddChangeHook(CvarChange_AdminOnly);
	g_hBots.AddChangeHook(CvarChange_Bots);
	g_hWaitingForPlayers.AddChangeHook(CvarChange_WaitingForPlayers);
	g_hDisabledWeapons.AddChangeHook(CvarChange_DisabledWeapons);



	g_hClip = CreateConVar("sm_aia_clip", "1", "Infinite Clip will be globally disabled");
	g_hAmmo = CreateConVar("sm_aia_ammo", "1", "Infinite Ammo will be globally disabled");
	g_hExtra = CreateConVar("sm_aia_extrastuff", "1", "Infinite Extra Stuff will be globally disabled");
	g_hMetal = CreateConVar("sm_aia_metal", "1", "Infinite Metal will be globally disabled");
	g_hSentry = CreateConVar("sm_aia_sentryammo", "1", "Infinite Sentry Ammo will be globally disabled");
	g_hCloak = CreateConVar("sm_aia_cloak", "1", "Infinite Cloak will be globally disabled");
	g_hSpells = CreateConVar("sm_aia_spells", "1", "Infinite Spells will be globally disabled");

	g_hClip.AddChangeHook(CvarChange_AmmoFlag);
	g_hAmmo.AddChangeHook(CvarChange_AmmoFlag);
	g_hExtra.AddChangeHook(CvarChange_AmmoFlag);
	g_hMetal.AddChangeHook(CvarChange_AmmoFlag);
	g_hSentry.AddChangeHook(CvarChange_AmmoFlag);
	g_hCloak.AddChangeHook(CvarChange_AmmoFlag);
	g_hSpells.AddChangeHook(CvarChange_AmmoFlag);


	HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("mvm_begin_wave", Event_RoundStart, EventHookMode_PostNoCopy);

	if(g_bLateLoad)
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			OnClientPostAdminCheck(client);
		}
	}

	AutoExecConfig(true, "AdvancedInfiniteAmmo");
}

////////////
//Forwards//
////////////

public void OnConfigsExecuted()
{
	if(g_hAllInfiniteAmmo.BoolValue) g_iGlobalFlags[1]= g_iGlobalFlags[1]|AMMOSOURCE_CVAR_ALL;
	SetAmmoFlags();
	
	if(g_bLateLoad)
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			OnClientPostAdminCheck(client);
		}
	}
}


public void OnClientPostAdminCheck(int client)
{
	if(IsValidClient(client, false))
	{
		SDKHook(client, SDKHook_PreThink, SDKHooks_OnPreThink);
		SDKHook(client, SDKHook_WeaponEquipPost, SDKHooks_OnWeaponEquipPost);
		SDKHook(client, SDKHook_OnTakeDamage, SDKHooks_OnTakeDamage);
	}

	g_iAmmoFlags[client][0] = g_iGlobalFlags[0];
	g_iAmmoFlags[client][1] = g_iGlobalFlags[1];
}


public void TF2_OnWaitingForPlayersStart()
{
	g_bWaitingForPlayers = true;
	if(g_hWaitingForPlayers.BoolValue)
	{
		for(int client; client <= MaxClients; client++)
		{
			g_iGlobalFlags[1] = g_iGlobalFlags[1]|AMMOSOURCE_CVAR_WAITINGFORPLAYERS;
			SetInfiniteAmmo(client, true, AMMOSOURCE_CVAR_WAITINGFORPLAYERS);
			
		}
		if(g_hChat.BoolValue) PrintToChatAll("[SM] Waiting For Players Started - Advanced Infinite Ammo enabled");
	}	
}

public void TF2_OnWaitingForPlayersEnd()
{
	g_bWaitingForPlayers = false;
	if(g_hWaitingForPlayers.BoolValue)
	{
		for(int client; client <= MaxClients; client++)
		{
			g_iGlobalFlags[1] = g_iGlobalFlags[1]&~AMMOSOURCE_CVAR_WAITINGFORPLAYERS;
			SetInfiniteAmmo(client, false, AMMOSOURCE_CVAR_WAITINGFORPLAYERS);
			
		}
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if(g_iAmmoFlags[client][0]&AMMOFLAG_EXTRA && condition == TFCond_Charging && CheckInfiniteAmmoAccess(client))
	{
		SetChargeMeter(client);
	}
}

public void OnPluginEnd()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		SetInfiniteAmmo(client, false, AMMOSOURCE_NONE, true);
	}
}



////////////////
//Cvar Changes//
////////////////
public void CvarChange_AllInfiniteAmmo(ConVar convar, char[] oldValue, char[] newValue)
{
	int iNewValue = StringToInt(newValue);

	if(iNewValue)
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			g_iGlobalFlags[1] = g_iGlobalFlags[1]|AMMOSOURCE_CVAR_ALL;
			SetInfiniteAmmo(client, true, AMMOSOURCE_CVAR_ALL);
		}

		if(g_hAdminOnly.BoolValue) PrintToChatAll("[SM] Advanced Infinite Ammo for admins enabled");
		else PrintToChatAll("[SM] Advanced Infinite Ammo for everyone enabled");
	}

	else
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			g_iGlobalFlags[1] = g_iGlobalFlags[1]&~AMMOSOURCE_CVAR_ALL;
			SetInfiniteAmmo(client, false, AMMOSOURCE_CVAR_ALL);
		}

		PrintToChatAll("[SM] Advanced Infinite Ammo for everyone disabled");		
	}
}

public void CvarChange_AdminOnly(ConVar convar, char[] oldValue, char[] newValue)
{
	int iNewValue = StringToInt(newValue);

	for(int client = 1; client <= MaxClients; client++)

	{
		if(iNewValue && !CheckCommandAccess(client, "sm_aia_adminflag", ADMFLAG_GENERIC)) ResetAmmo(client);	
	}
}

public void CvarChange_Bots(ConVar convar, char[] oldValue, char[] newValue)
{
	int iNewValue = StringToInt(newValue);	
	for(int client = 1; client <= MaxClients; client++)

	{
		if(IsClientInGame(client) && IsFakeClient(client)) 
		{
			if(iNewValue) SetInfiniteAmmo(client, true, g_iGlobalFlags[1], false);
			else
			{
				SetInfiniteAmmo(client, false, g_iGlobalFlags[1], false);
				if(IsPlayerAlive(client))
				{
					SetRevengeCrits(client, 1);
					SetDecapitations(client, 0);
					int iClientHealth = GetClientHealth(client);
					TF2_RegeneratePlayer(client);
					SetEntityHealth(client, iClientHealth);
				}
			}
		}
	}
}

public void CvarChange_WaitingForPlayers(ConVar convar, char[] oldValue, char[] newValue)
{
	int iNewValue = StringToInt(newValue);

	if(g_bWaitingForPlayers && !g_hAllInfiniteAmmo.BoolValue)
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			if(iNewValue)
			{
				g_iGlobalFlags[1] = g_iGlobalFlags[1]|AMMOSOURCE_CVAR_WAITINGFORPLAYERS;
				SetInfiniteAmmo(client, true, AMMOSOURCE_CVAR_WAITINGFORPLAYERS);
			}
			else
			{
				g_iGlobalFlags[1] = g_iGlobalFlags[1]&~AMMOSOURCE_CVAR_WAITINGFORPLAYERS;
				SetInfiniteAmmo(client, false, AMMOSOURCE_CVAR_WAITINGFORPLAYERS);
			}		
		}
	}
	
}

public void CvarChange_DisabledWeapons(ConVar convar, char[] oldValue, char[] newValue)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		ResetAmmo(client);
	}
}


public void CvarChange_AmmoFlag(ConVar convar, char[] oldValue, char[] newValue)
{
	SetAmmoFlags();
	for(int client = 1; client <= MaxClients; client++)
	{
		g_iAmmoFlags[client][0] = g_iGlobalFlags[0];
		if(CheckInfiniteAmmoAccess(client)) ResetAmmo(client);
	}
}

public void SetAmmoFlags()
{
	if(g_hClip.BoolValue) g_iGlobalFlags[0] = g_iGlobalFlags[0]|AMMOFLAG_CLIP;
	else g_iGlobalFlags[0] = g_iGlobalFlags[0]&~AMMOFLAG_CLIP;

	if(g_hAmmo.BoolValue) g_iGlobalFlags[0] = g_iGlobalFlags[0]|AMMOFLAG_AMMO;
	else g_iGlobalFlags[0] = g_iGlobalFlags[0]&~AMMOFLAG_AMMO;

	if(g_hExtra.BoolValue) g_iGlobalFlags[0] = g_iGlobalFlags[0]|AMMOFLAG_EXTRA;
	else g_iGlobalFlags[0] = g_iGlobalFlags[0]&~AMMOFLAG_EXTRA;

	if(g_hMetal.BoolValue) g_iGlobalFlags[0] = g_iGlobalFlags[0]|AMMOFLAG_METAL;
	else g_iGlobalFlags[0] = g_iGlobalFlags[0]&~AMMOFLAG_METAL;

	if(g_hSentry.BoolValue) g_iGlobalFlags[0] = g_iGlobalFlags[0]|AMMOFLAG_SENTRY;
	else g_iGlobalFlags[0] = g_iGlobalFlags[0]&~AMMOFLAG_SENTRY;

	if(g_hCloak.BoolValue) g_iGlobalFlags[0] = g_iGlobalFlags[0]|AMMOFLAG_CLOAK;
	else g_iGlobalFlags[0] = g_iGlobalFlags[0]&~AMMOFLAG_CLOAK;

	if(g_hSpells.BoolValue) g_iGlobalFlags[0] = g_iGlobalFlags[0]|AMMOFLAG_SPELLS;
	else g_iGlobalFlags[0] = g_iGlobalFlags[0]&~AMMOFLAG_SPELLS;	
}

//////////
//Events//
//////////
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{	
	if(!g_bWaitingForPlayers)
	{
		for(int client; client <= MaxClients; client++)
		{
			g_iGlobalFlags[1] = g_iGlobalFlags[1]&~(AMMOSOURCE_CVAR_ROUNDWIN|AMMOSOURCE_CVAR_WAITINGFORPLAYERS);
			SetInfiniteAmmo(client, false, AMMOSOURCE_CVAR_ROUNDWIN|AMMOSOURCE_CVAR_WAITINGFORPLAYERS);
		}
		if(g_hChat.BoolValue) PrintToChatAll("[SM] Round Start - Advanced Infinite Ammo disabled");
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_hAllInfiniteAmmo.BoolValue && g_hRoundWin.BoolValue)
	{
		for(int client; client <= MaxClients; client++)
		{
			g_iGlobalFlags[1] = g_iGlobalFlags[1]|AMMOSOURCE_CVAR_ROUNDWIN;
			SetInfiniteAmmo(client, true, AMMOSOURCE_CVAR_ROUNDWIN);
		}	
		if(g_hChat.BoolValue) PrintToChatAll("[SM] Round Win - Advanced Infinite Ammo enabled");
	}
}



////////////
//Commands//
////////////

public Action Command_SetAIA(int client, int args)
{
	bool bOnOff;
	switch(args)
	{
		
		case 0:
		{
			bOnOff = !(view_as<bool>(g_iAmmoFlags[client][1]&AMMOSOURCE_COMMAND));
			SetInfiniteAmmo(client, bOnOff, AMMOSOURCE_COMMAND);
			if(g_hLog.BoolValue) LogAction(client, client, "\"%L\" %s Advanced Infinite Ammo for  \"%L\"", client, bOnOff ? "Enabled":"Disabled", client);			
			if(g_hChat.BoolValue) ShowActivity2(client, "[SM] ","Advanced Infinite Ammo for %N %s", client, bOnOff ? "enabled":"disabled");			
	
		}
		case 2:
		{
			char strTarget[MAX_TARGET_LENGTH]; char strOnOff[2]; char target_name[MAX_TARGET_LENGTH]; int target_list[MAXPLAYERS]; int target_count; bool tn_is_ml;
			GetCmdArg(1, strTarget, sizeof(strTarget));
			if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}

			if((target_count > 1 || target_list[0] != client) && !CheckCommandAccess(client, "sm_aia_targetflag", ADMFLAG_SLAY))
			{
				ReplyToCommand(client, "[SM] You do not have access to targeting others");
				return Plugin_Handled;
			}

			GetCmdArg(2, strOnOff, sizeof(strOnOff));
			bOnOff = view_as<bool>(StringToInt(strOnOff));

			bool bLogging = g_hLog.BoolValue;

			for(int i = 0; i < target_count; i++)
			{
				SetInfiniteAmmo(target_list[i], bOnOff, AMMOSOURCE_COMMAND);				
				if(bLogging) LogAction(client, target_list[i], "\"%L\" %s Advanced Infinite Ammo for  \"%L\"", client, bOnOff ? "Enabled":"Disabled", target_list[i]);
			}
			
			if(g_hChat.BoolValue) ShowActivity2(client, "[SM] ","Advanced Infinite Ammo for %s %s", target_name, bOnOff ? "enabled":"disabled");

		}
		default:
		{
			ReplyToCommand(client, "[SM] Usage: sm_aia \"target\" \"1/0\"");
		}
	}

	return Plugin_Handled;
}

public Action Command_SetAIATimed(int client, int args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_aia2 \"target\" \"time(in seconds)\"");
		return Plugin_Handled;
	}

	char strTarget[MAX_TARGET_LENGTH];
	char strTime[8];
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	float time;
	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	if((target_count > 1 || target_list[0] != client) && !CheckCommandAccess(client, "sm_aia_targetflag", ADMFLAG_SLAY))
	{
		ReplyToCommand(client, "[SM] You do not have access to targeting others");
		return Plugin_Handled;
	}

	GetCmdArg(2, strTime, sizeof(strTime));
	time = StringToFloat(strTime);

	bool bLogging = g_hLog.BoolValue;
	for(int i = 0; i < target_count; i++)
	{
		SetInfiniteAmmo(target_list[i], true, AMMOSOURCE_TIMER);
		CreateTimer(time, Timer_RemoveAIA, target_list[i], TIMER_FLAG_NO_MAPCHANGE);
		if(bLogging) LogAction(client, target_list[i], "\"%L\" Advanced Infinite Ammo enabled for \"%L\" for %f Seconds", client, target_list[i], time); 
	}
	if(g_hChat.BoolValue) ShowActivity2(client, "[SM] ","Advanced Infinite Ammo enabled for %s for %-.2f seconds", target_name, time);

	return Plugin_Handled;
}

public Action Timer_RemoveAIA(Handle timer, any client)
{
	SetInfiniteAmmo(client, false, AMMOSOURCE_TIMER);
}


//////////////
//Menu Stuff//
//////////////
public Action Command_AIAMenu(int client, int args)
{
	ShowAmmoMenu(client);	
	return Plugin_Handled;
}

void ShowAmmoMenu(int client)
{
	Menu TargetMenu = new Menu(Menu_TargetMenu);
	if(g_hBots.BoolValue) TargetMenu.SetTitle("Choose Player:");
	else TargetMenu.SetTitle("Choose Player(Bots Disabled):");

	if(g_hBots.BoolValue) AddTargetsToMenu2(TargetMenu, client, 0);
	else AddTargetsToMenu2(TargetMenu, client, COMMAND_FILTER_NO_BOTS);
	TargetMenu.ExitButton = true;
	TargetMenu.Display(client, MENU_TIME_FOREVER);
}

int MenuTarget[MAXPLAYERS+1];

public int Menu_TargetMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		int client = param1; int target; char info[32];
		menu.GetItem(param2, info, sizeof(info));
		target = GetClientOfUserId(StringToInt(info));
		if(IsValidClient(target, false))
		{
			MenuTarget[client] = target;
			ShowMenu_AIAFlags(client, target);
		}
		else
		{
			PrintToChat(client, "Target not valid, please re-choose");
			delete menu;
			ShowAmmoMenu(client);
		}
		
	}	
}

public Action ShowMenu_AIAFlags(int client, int target)
{
	Menu AIAFlags = new Menu(Menu_AIAFlags);

	char buffer[128];


	bool bOnOff = CheckInfiniteAmmoAccess(target);
	Format(buffer, sizeof(buffer), "AIA: %s", bOnOff ? "Enabled":"Disabled");
	AIAFlags.SetTitle("Set AIA Flags: %N\n%s\n  ", target, buffer);

	if(g_hClip.BoolValue)
	{
		bOnOff = view_as<bool> (g_iAmmoFlags[target][0]&AMMOFLAG_CLIP);
		Format(buffer, sizeof(buffer), "Clip: %s", bOnOff ? "Enabled":"Disabled");
		AIAFlags.AddItem("1", buffer);
	}
	else AIAFlags.AddItem("1", "Clip: (Globally Disabled)", ITEMDRAW_DISABLED);

	if(g_hAmmo.BoolValue)
	{
		bOnOff = view_as<bool> (g_iAmmoFlags[target][0]&AMMOFLAG_AMMO);
		Format(buffer, sizeof(buffer), "Ammo: %s", bOnOff ? "Enabled":"Disabled");
		AIAFlags.AddItem("2", buffer);
	}
	else AIAFlags.AddItem("1", "Ammo: (Globally Disabled)", ITEMDRAW_DISABLED);

	if(g_hExtra.BoolValue)
	{
		bOnOff = view_as<bool> (g_iAmmoFlags[target][0]&AMMOFLAG_EXTRA);
		Format(buffer, sizeof(buffer), "Extra Stuff: %s", bOnOff ? "Enabled":"Disabled");
		AIAFlags.AddItem("3", buffer);
	}
	else AIAFlags.AddItem("1", "Extra Stuff: (Globally Disabled)", ITEMDRAW_DISABLED);

	if(g_hMetal.BoolValue)
	{
		bOnOff = view_as<bool> (g_iAmmoFlags[target][0]&AMMOFLAG_METAL);
		Format(buffer, sizeof(buffer), "Metal: %s", bOnOff ? "Enabled":"Disabled");
		AIAFlags.AddItem("4", buffer);
	}
	else AIAFlags.AddItem("1", "Metal: (Globally Disabled)", ITEMDRAW_DISABLED);

	if(g_hSentry.BoolValue)
	{
		bOnOff = view_as<bool> (g_iAmmoFlags[target][0]&AMMOFLAG_SENTRY);
		Format(buffer, sizeof(buffer), "Sentry Ammo: %s", bOnOff ? "Enabled":"Disabled");
		AIAFlags.AddItem("5", buffer);
	}
	else AIAFlags.AddItem("1", "Sentry Ammo: (Globally Disabled)", ITEMDRAW_DISABLED);

	if(g_hCloak.BoolValue)
	{
		bOnOff = view_as<bool> (g_iAmmoFlags[target][0]&AMMOFLAG_CLOAK);
		Format(buffer, sizeof(buffer), "Cloak: %s", bOnOff ? "Enabled":"Disabled");
		AIAFlags.AddItem("6", buffer);
	}
	else AIAFlags.AddItem("1", "Cloak: (Globally Disabled)", ITEMDRAW_DISABLED);

	if(g_hSpells.BoolValue)
	{
		bOnOff = view_as<bool> (g_iAmmoFlags[target][0]&AMMOFLAG_SPELLS);
		Format(buffer, sizeof(buffer), "Spells: %s", bOnOff ? "Enabled":"Disabled");
		AIAFlags.AddItem("7", buffer);
	}
	else AIAFlags.AddItem("1", "Spells: (Globally Disabled)", ITEMDRAW_DISABLED);

	AIAFlags.ExitBackButton = true;
	AIAFlags.ExitButton = true;

	AIAFlags.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int Menu_AIAFlags(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{

			int client = param1;
			int target = MenuTarget[client];
			if(!IsValidClient(target, false))
			{
				PrintToChat(client, "Target no longer available");
				delete menu;
			}
			char buffer[16];
			menu.GetItem(param2, buffer, sizeof(buffer));
			int iSelection = StringToInt(buffer);
			
			switch(iSelection)
			{
				case 1: //Clip
				{
					ToggleAmmoFlag(target, AMMOFLAG_CLIP);	
				}
				case 2: //Ammo
				{
					ToggleAmmoFlag(target, AMMOFLAG_AMMO);
				}
				case 3: //Extra
				{
					ToggleAmmoFlag(target, AMMOFLAG_EXTRA);
				}
				case 4: //Metal
				{
					ToggleAmmoFlag(target, AMMOFLAG_METAL);
				}
				case 5: //Sentry Ammo
				{
					ToggleAmmoFlag(target, AMMOFLAG_SENTRY);
				}
				case 6: //Cloak
				{
					ToggleAmmoFlag(target, AMMOFLAG_CLOAK);
				}
				case 7: //Spells
				{
					ToggleAmmoFlag(target, AMMOFLAG_SPELLS);
				}
			}
			ShowMenu_AIAFlags(client, target);			
		}

		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack) ShowAmmoMenu(param1);
		}
	}
}

///////////////////
//Main Ammo Stuff//
///////////////////
public void SDKHooks_OnWeaponEquipPost(int client, int weapon)
{
	if(IsValidClient(client))
	{
		g_iClientWeapons[client][0] = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		g_iClientWeapons[client][1] = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		g_iClientWeapons[client][2] = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		g_iClientWeapons[client][3] = GetSpellBook(client);
	}
}

public void SDKHooks_OnPreThink(int client)
{
	if(IsValidClient(client) && CheckInfiniteAmmoAccess(client))
	{
		if(IsValidWeapon(g_iClientWeapons[client][0])) GiveInfiniteAmmo(client, g_iClientWeapons[client][0]);
		if(IsValidWeapon(g_iClientWeapons[client][1])) GiveInfiniteAmmo(client, g_iClientWeapons[client][1]);
		if(IsValidWeapon(g_iClientWeapons[client][2])) GiveInfiniteAmmo(client, g_iClientWeapons[client][2]);

		if(g_iAmmoFlags[client][0]&AMMOFLAG_CLOAK) SetCloak(client);
		if(g_iAmmoFlags[client][0]&AMMOFLAG_SPELLS) SetSpellUses(client, g_iClientWeapons[client][3], 1);
	}
}

public Action SDKHooks_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(IsValidClient(victim) && damagecustom == TF_CUSTOM_BACKSTAB && CheckInfiniteAmmoAccess(victim) && HasRazorback(victim))
	{
		return Plugin_Handled;	
	}
	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	RequestFrame(OnEntityCreated_NextFrame, entity);
}

public void OnEntityCreated_NextFrame(any data)
{
	char strClassname[128];
	if(IsValidEntity(data)) GetEntityClassname(data, strClassname, sizeof(strClassname));
	else return;
	if(strcmp(strClassname, "obj_sentrygun", false) == 0)
	{
		int client = GetEntPropEnt(data, Prop_Send, "m_hBuilder");
		if(IsValidClient(client) && CheckInfiniteAmmoAccess(client) && g_iAmmoFlags[client][0]&AMMOFLAG_SENTRY)
		{
			int flags = GetEntProp(data, Prop_Data, "m_spawnflags");
			SetEntProp(data, Prop_Data, "m_spawnflags", flags|1<<3);
		}
	}	
}

bool CheckInfiniteAmmoAccess(int client)
{
	switch(g_hAdminOnly.IntValue)
	{
		case 1:
		{
			if(!CheckCommandAccess(client, "sm_aia_adminflag", ADMFLAG_GENERIC)) return false;
		}
		case 2:
		{
			if(!CheckCommandAccess(client, "sm_aia_adminflag", ADMFLAG_GENERIC) && !(g_iAmmoFlags[client][1]&AMMOSOURCE_COMMAND)) return false;
		}
	}
	if(g_iAmmoFlags[client][1]) return true;
	return false;
}


void SetInfiniteAmmo(int client, bool bOnOff, int iSourceFlag, bool bDoReset = true)
{
	if(!IsValidClient(client, false)) return;
	if(bOnOff)
	{
		g_iAmmoFlags[client][1] = g_iAmmoFlags[client][1]|iSourceFlag;
		SetSentryInfiniteAmmoFlags(client, true);
		AIA_OnAIAChanged(client, iSourceFlag, true);
		
	}
	else
	{
		if(!g_iAmmoFlags[client][1]) return;
		g_iAmmoFlags[client][1] = g_iAmmoFlags[client][1]&~iSourceFlag;
		SetSentryInfiniteAmmoFlags(client);
		if(bDoReset) ResetAmmo(client);
		AIA_OnAIAChanged(client, iSourceFlag, false);
	}
	
}

void ToggleAmmoFlag(int client, int iFlags)
{
	if(g_iAmmoFlags[client][0]&iFlags)
	{
		g_iAmmoFlags[client][0] = g_iAmmoFlags[client][0]&~iFlags;
		if(iFlags == AMMOFLAG_SENTRY) SetSentryInfiniteAmmoFlags(client);
	}
	else
	{
		g_iAmmoFlags[client][0] = g_iAmmoFlags[client][0]|iFlags;
		if(iFlags == AMMOFLAG_SENTRY) SetSentryInfiniteAmmoFlags(client, true);
	}
	ResetAmmo(client);
}

void ResetAmmo(int client)
{
	if(IsValidClient(client))
	{		
		SetRevengeCrits(client, 1);
		SetDecapitations(client, 0);
		int iClientHealth = GetClientHealth(client);
		TF2_RegeneratePlayer(client);
		SetEntityHealth(client, iClientHealth);
	}
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

void GiveInfiniteAmmo(int client, int iWeapon)
{
	int iWeaponIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
	if(IsWeaponDisabled(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"))) return;
	bool bSetClip = view_as<bool> (g_iAmmoFlags[client][0]&AMMOFLAG_CLIP);
	bool bSetAmmo = view_as<bool> (g_iAmmoFlags[client][0]&AMMOFLAG_AMMO);
	bool bExtraStuff = view_as<bool> (g_iAmmoFlags[client][0]&AMMOFLAG_EXTRA);
	bool bSetMetal = view_as<bool> (g_iAmmoFlags[client][0]&AMMOFLAG_METAL);
	switch(iWeaponIndex)
	{
		/////////////////////
		/////Multi Class/////
		/////////////////////


		////////////////////All Class////////////////////

		case 264,423,474,880,939,954,1013,1071,1123,1127:{}


		////////////////////Pistol/Lugermorph/Vintage Lugermorph(Scout/Engineer)////////////////////
		case 209,160,294,15013,15018,15035,15041,15056,30666:
		{
			if(bSetClip) SetClip(iWeapon);
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		////////////////////Shotgun/Festive Shotgun/Panic Attack(Soldier/Pyro/Heavy/Engineer)////////////////////

		case 199,1141,1153,15003,15016,15044:
		{
			if(bSetClip) SetClip(iWeapon);
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		////////////////////Reserve Shooter(Soldier/Pyro)////////////////////
			
		case 415:
		{
			if(bSetClip) SetClip(iWeapon);
			if(bSetAmmo) SetAmmo(client, iWeapon);
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
			if(bSetAmmo) SetAmmo(client, iWeapon);
			if(bExtraStuff) SetHypeMeter(client);
		}

		case 448,772:
		{
			if(bSetClip) SetClip(iWeapon);
			if(bSetAmmo) SetAmmo(client, iWeapon);
			if(bExtraStuff) SetHypeMeter(client);
		}

		////////////////////Secondary////////////////////

		case 23,449,773:
		{
			if(bSetClip) SetClip(iWeapon);
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		case 222,812,833,1121:
		{
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		case 46,163,1145:
		{			
			if(bSetAmmo)SetAmmo(client, iWeapon);
			if(bExtraStuff) SetDrinkMeter(client);
		}

		////////////////////Melee////////////////////

		case 0,190,221,317,325,349,355,450,452,572,660,999,30667:{}

		case 44,648:
		{
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		/////////////////
		/////Soldier/////
		/////////////////

		////////////////////Primary////////////////////

		case 18,205,127,228,237,414,513,658,800,809,889,898,907,916,965,974,1085,1104,15006,15014,15028,15043,15052,15057:
		{
			if(bSetClip) SetClip(iWeapon);
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		//Cow Mangler, Bison, Pomson - Energy Ammo
		case 441:
		{
			if(bSetClip) SetEnergyAmmo(iWeapon);
		}

		case 730:
		{
			if(bSetClip && bExtraStuff) if(GetClientButtons(client) & IN_ATTACK2) SetClip(iWeapon, 3);
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		////////////////////Secondary////////////////////

		case 10:
		{
			if(bSetClip) SetClip(iWeapon);
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		case 133,444:{}

		case 442:
		{
			if(bSetClip) SetEnergyAmmo(iWeapon);
		}

		case 129,226,354,1001: 
		{
			if(bExtraStuff && !GetRageMeter(client)) SetRageMeter(client);
		}

		////////////////////Melee////////////////////

		case 6,196,128,416,447,775:{}

		//////////////
		/////Pyro/////
		//////////////

		////////////////////Primary////////////////////

		case 21,208,40,215,659,741,798,807,887,896,905,914,963,972,1146,30474,15005,15017,15030,15034,15049,15054:
		{
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		case 594: 
		{
			if(bSetAmmo) SetAmmo(client, iWeapon);
			if(bExtraStuff && !GetRageMeter(client)) SetRageMeter(client);
		}

		////////////////////Secondary////////////////////

		case 12:
		{
			if(bSetClip) SetClip(iWeapon);
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		case 39,351,740,1081:
		{
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		case 595:
		{
			if(bExtraStuff) SetRevengeCrits(client);
		}

		////////////////////Melee////////////////////

		case 2,192,38,153,217,326,348,457,466,593,739,813,834,1000:{}

		/////////////////
		/////Demoman/////
		/////////////////

		////////////////////Primary////////////////////

		case 19,206,308,996,1007,1151:
		{
			if(bSetClip) SetClip(iWeapon);
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		case 405,608:{}

		////////////////////Secondary////////////////////

		case 20,207,130,265,661,797,806,886,895,904,913,962,971,1150,15009,15012,15024,15038,15048:
		{
			if(bSetClip) SetClip(iWeapon);
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		case 131,406,1099,1144:{}

		////////////////////Melee////////////////////

		case 1,191,172,327,404,609:{}

		case 132,266,482,1082:
		{
			if(bExtraStuff) SetDecapitations(client);
		}


		case 307:
		{
			if(bExtraStuff) ResetCaber(iWeapon);					
		}



		///////////////
		/////Heavy/////
		///////////////

		////////////////////Primary////////////////////

		case 15,202,41,298,312,424,654,793,802,811,832,850,882,891,900,909,958,967,15004,15020,15026,15031,15040,15055:
		{
			if(bSetAmmo) SetAmmo(client, iWeapon);
			if(bExtraStuff && !GetRageMeter(client)) SetRageMeter(client);
		}

		////////////////////Secondary////////////////////

		case 11,425:
		{
			if(bSetClip) SetClip(iWeapon);
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		case 42,159,311,433,863,1002:
		{
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		////////////////////Melee////////////////////

		case 5,195,239,310,331,426,587,656,1084,1100:{}

		case 43:
		{
			if(bExtraStuff) TF2_AddCondition(client, TFCond_CritOnKill, 5.0);
		}

		//////////////////
		/////Engineer/////
		//////////////////

		////////////////////Primary////////////////////

		case 9,997:
		{
			if(bSetClip) SetClip(iWeapon);
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		case 527:
		{
			if(bSetMetal) SetMetal(client);
		}

		case 588:
		{
			if(bSetClip) SetEnergyAmmo(iWeapon);
		}

		case 141,1004:
		{
			if(bSetClip) SetClip(iWeapon);
			if(bSetAmmo) SetAmmo(client, iWeapon);
			if(bExtraStuff) SetRevengeCrits(client);	
		}

		////////////////////Secondary////////////////////

		case 22:
		{
			if(bSetClip) SetClip(iWeapon);
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		case 528:
		{
			if(bSetMetal) SetMetal(client);
		}

		case 140,1086,30668:{}

		////////////////////Melee////////////////////

		case 7,197,142,155,169,329,589,662,795,804,884,893,902,911,960,969:
		{
			if(bSetMetal) SetMetal(client);
		}

		///////////////
		/////Medic/////
		///////////////

		////////////////////Primary////////////////////

		case 17,204,36,305,412,1079:
		{
			if(bSetClip) SetClip(iWeapon);
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		////////////////////Secondary////////////////////

		case 29,211,35,411,663,796,805,885,894,903,912,961,970,998,15008,15010,15025,15039,15050:
		{
			if(bExtraStuff)
			{
				if(!GetUberCharge(iWeapon)) SetUberCharge(iWeapon);
				if(!GetRageMeter(client)) SetRageMeter(client);
			}
		}

		////////////////////Melee////////////////////

		case 8,198,37,173,304,413,1003,1143:{}

		////////////////
		/////Sniper/////
		////////////////

		////////////////////Primary////////////////////


		case 14,201,230,526,664,792,801,851,881,890,899,908,957,966,1098,15000,15007,15019,15023,15033,15059,30665:
		{
			if(bSetAmmo) SetAmmo(client, iWeapon);
			if(bExtraStuff) SetSniperRifleCharge(iWeapon);
		}

		case 56,1005,1092:
		{
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		case 402:
		{
			if(bSetAmmo) SetAmmo(client, iWeapon);
			if(bExtraStuff)
			{
				SetDecapitations(client);
				SetSniperRifleCharge(iWeapon);
			} 
		}
		case 752: 
		{
			if(bSetAmmo) SetAmmo(client, iWeapon);
			if(bExtraStuff)
			{
				SetSniperRifleCharge(iWeapon);
				if(!GetRageMeter(client)) SetRageMeter(client);
			}
		}

		////////////////////Secondary////////////////////

		case 16,203,1149,15001,15022,15032,15058:
		{
			if(bSetClip) SetClip(iWeapon);
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		case 57,231,642:{}

		case 58,1083,1105:
		{
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		case 751:
		{
			if(bSetClip) SetClip(iWeapon);
			if(bSetAmmo) SetAmmo(client, iWeapon);
			if(bExtraStuff) TF2_AddCondition(client, TFCond_CritCola, 8.0);			
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
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}

		case 525:
		{
			if(bSetClip) SetClip(iWeapon);
			if(bSetAmmo) SetAmmo(client, iWeapon);
			if(bExtraStuff) SetRevengeCrits(client);	
		}

		////////////////////Secondary////////////////////

		case 735,736,810,831,933,1080,1102:
		{
			if(bSetAmmo) SetEntPropFloat(iWeapon, Prop_Send, "m_flEffectBarRegenTime", 0.1);
		}

		////////////////////Melee////////////////////

		case 4,194,225,356,574,638,665,727,794,803,883,892,901,910,959,968:{}

		case 649:
		{
			if(bExtraStuff) SetEntPropFloat(iWeapon, Prop_Send, "m_flKnifeRegenerateDuration", 0.0);
		}

		case 461:
		{
			if(bExtraStuff) TF2_AddCondition(client, TFCond_SpeedBuffAlly, 3.0);	
		}


		//Everything Else(Usually new weapons added to TF2 since last plugin update)
		default:
		{
			if(bSetClip) SetClip(iWeapon);
			if(bSetAmmo) SetAmmo(client, iWeapon);
		}
	}	
}

//////////
//Stocks//
//////////
stock bool IsValidClient(int client, bool bCheckAlive=true)
{
	if(client < 1 || client > MaxClients) return false;
	if(!IsClientInGame(client)) return false;
	if(IsClientSourceTV(client) || IsClientReplay(client)) return false;
	if(!g_hBots.BoolValue && IsFakeClient(client)) return false;
	if(bCheckAlive) return IsPlayerAlive(client);
	return true;
}

stock bool IsValidWeapon(int iEntity)
{
	char strClassname[128];
	if(IsValidEntity(iEntity) && GetEntityClassname(iEntity, strClassname, sizeof(strClassname)) && StrContains(strClassname, "tf_weapon_", false) != -1) return true;
	return false;
}

stock void SetAmmo(int client, int iWeapon, int iAmmo = 500)
{
	int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
	if(iAmmoType != -1) SetEntProp(client, Prop_Data, "m_iAmmo", iAmmo, _, iAmmoType);
}

stock void SetEnergyAmmo(int iWeapon, float flEnergyAmmo = 100.0)
{
	SetEntPropFloat(iWeapon, Prop_Send, "m_flEnergy", flEnergyAmmo);
}

stock void SetClip(int iWeapon, int iClip = 99)
{
	SetEntProp(iWeapon, Prop_Data, "m_iClip1", iClip);

}

stock void SetDrinkMeter(int client, float flDrinkMeter = 100.0)
{
	SetEntPropFloat(client, Prop_Send, "m_flEnergyDrinkMeter", flDrinkMeter);
}

stock void SetHypeMeter(int client, float flHypeMeter = 100.0)
{
	SetEntPropFloat(client, Prop_Send, "m_flHypeMeter", flHypeMeter);
}

stock float GetRageMeter(int client)
{
	return GetEntPropFloat(client, Prop_Send, "m_flRageMeter");
}

stock void SetRageMeter(int client, float flRage = 100.0)
{
	SetEntPropFloat(client, Prop_Send, "m_flRageMeter", flRage);
}

stock float GetUberCharge(int iWeapon)
{
	return GetEntPropFloat(iWeapon, Prop_Send, "m_flChargeLevel");
}

stock void SetUberCharge(int iWeapon, float flUberCharge = 1.00)
{
	SetEntPropFloat(iWeapon, Prop_Send, "m_flChargeLevel", flUberCharge);
}

stock void SetChargeMeter(int client, float flChargeMeter = 100.0)
{
	SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", flChargeMeter);
}

stock void SetSniperRifleCharge(int iWeapon, float flCharge = 150.0)
{
	SetEntPropFloat(iWeapon, Prop_Send, "m_flChargedDamage", flCharge);
}

stock void SetRevengeCrits(int client, int iAmount = 99)
{
	SetEntProp(client, Prop_Send, "m_iRevengeCrits", iAmount);
}

stock void SetDecapitations(int client, int iAmount = 99)
{
	SetEntProp(client, Prop_Send, "m_iDecapitations", iAmount);
}

stock void ResetCaber(int iWeapon)
{
	SetEntProp(iWeapon, Prop_Send, "m_bBroken", 0);

	SetEntProp(iWeapon, Prop_Send, "m_iDetonated", 0);
}

stock void SetSentryInfiniteAmmoFlags(int client, bool bSetAmmo = false)
{
	int iSentrygun = -1; 
	while((iSentrygun = FindEntityByClassname(iSentrygun, "obj_sentrygun")) != INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(iSentrygun) && GetEntPropEnt(iSentrygun, Prop_Send, "m_hBuilder") == client)
		{
			int flags = GetEntProp(iSentrygun, Prop_Data, "m_spawnflags");
			if(IsValidClient(client, false) && CheckInfiniteAmmoAccess(client) && g_iAmmoFlags[client][0]&AMMOFLAG_SENTRY)
			{
				SetEntProp(iSentrygun, Prop_Data, "m_spawnflags", flags|1<<3);
				if(bSetAmmo)
				{
					switch (GetEntProp(iSentrygun, Prop_Send, "m_iUpgradeLevel"))
					{
						case 1:
						{
							SetEntProp(iSentrygun, Prop_Send, "m_iAmmoShells", 150);
						}
						case 2:
						{
							SetEntProp(iSentrygun, Prop_Send, "m_iAmmoShells", 200);
						}
						case 3:
						{
							SetEntProp(iSentrygun, Prop_Send, "m_iAmmoShells", 200);
							SetEntProp(iSentrygun, Prop_Send, "m_iAmmoRockets", 20);
						}
					}
				}
			}
			else SetEntProp(iSentrygun, Prop_Data, "m_spawnflags", flags&~1<<3);
		}
	}
}

stock void SetMetal(int client, int iMetal = 999)
{
	SetEntProp(client, Prop_Data, "m_iAmmo", iMetal, 4, 3);
}

stock void SetCloak(int client, float flCloak = 100.0)
{
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", flCloak);	
}

stock bool HasRazorback(int client)
{
	int entity = -1;
	while((entity = FindEntityByClassname(entity, "tf_wearable")) != INVALID_ENT_REFERENCE)
	{
		if(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex") == 57 && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
		{
			return true;
		}
	}
	return false;
}

stock void SetSpellUses(int client, int iSpellbook, int iUses = 99)
{
	if(!IsValidWeapon(iSpellbook) || iSpellbook <= MaxClients) return;
	if(IsWeaponDisabled(GetEntProp(iSpellbook, Prop_Send, "m_iItemDefinitionIndex"))) return;
	if(GetClientButtons(client) & IN_RELOAD)
	{
		SetEntProp(iSpellbook, Prop_Send, "m_iSelectedSpellIndex", -1);
		SetEntProp(iSpellbook, Prop_Send, "m_iSpellCharges", 0);
	}
	if((GetEntProp(iSpellbook, Prop_Send, "m_iSelectedSpellIndex") >= 0))
	{
		SetEntProp(iSpellbook, Prop_Send, "m_iSpellCharges", iUses);
	}
}

stock int GetSpellBook(int client)
{
	int entity = -1;
	while((entity = FindEntityByClassname(entity, "tf_weapon_spellbook")) != INVALID_ENT_REFERENCE)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client) return entity;
	}
	return -1;
}

///////////
//Natives//
///////////
public int Native_AIA_HasAIA(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if(!IsValidClient(client, false)) return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);

	return CheckInfiniteAmmoAccess(client);
}

public int Native_AIA_SetAIA(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	bool bOnOff = GetNativeCell(2);

	if(!IsValidClient(client)) return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);

	if(bOnOff) SetInfiniteAmmo(client, true, AMMOSOURCE_PLUGIN);
	else SetInfiniteAmmo(client, false, AMMOSOURCE_PLUGIN);
	
	return 0;
}

public int Native_AIA_GetAmmoFlags(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if(!IsValidClient(client, false)) return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);

	return g_iAmmoFlags[client][0];
}

public int Native_AIA_SetAmmoFlags(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int flags = GetNativeCell(2);
	bool onoff = GetNativeCell(3);

	if(!IsValidClient(client, false)) return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);


	if(onoff) g_iAmmoFlags[client][0] = g_iAmmoFlags[client][0]|flags;
	else g_iAmmoFlags[client][0] = g_iAmmoFlags[client][0]&~flags;

	ResetAmmo(client);

	return 0;
}

void AIA_OnAIAChanged(int client, int iFlags, bool bOnOff)
{
	Call_StartForward(g_hOnAIAChanged);
   	Call_PushCell(client);
	Call_PushCell(iFlags);
	Call_PushCell(bOnOff);
	Call_Finish();
}











