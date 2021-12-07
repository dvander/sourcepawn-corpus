#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <csgocolors>
#include <weapons>
#include <cstrike>
#undef REQUIRE_PLUGIN
//#include <updater>
#pragma semicolon 1

#define PLUGIN_VERSION "2.5.2 paint support"
#define PLUGIN_NAME "Knife Upgrade"
//#define UPDATE_URL    "http://jasonkingsley.me/dev/smknifeupgrade/sm_knifeupgrade_update.txt"

new Handle:g_cookieKnife;
new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hSpawnMessage = INVALID_HANDLE;
new Handle:g_hSpawnMenu = INVALID_HANDLE;
new Handle:g_hWelcomeMessage = INVALID_HANDLE;
new Handle:g_hWelcomeMenu = INVALID_HANDLE;
new Handle:g_hWelcomeMenuOnlyNoKnife = INVALID_HANDLE;
new Handle:g_hWelcomeMessageTimer = INVALID_HANDLE;
new Handle:g_hWelcomeMenuTimer = INVALID_HANDLE;
new Handle:g_hKnifeChosenMessage = INVALID_HANDLE;
new Handle:g_hNoKnifeMapDisable = INVALID_HANDLE;
new Handle:g_hNoKnifeMenu = INVALID_HANDLE;
new Handle:g_hNoUpdates = INVALID_HANDLE;
new Handle:g_hHideRestricted = INVALID_HANDLE;
new Handle:g_hGoldKnifeCrash = INVALID_HANDLE;
new Handle:g_hEndRoundCrash = INVALID_HANDLE;

new knife_choice[MAXPLAYERS+1];
new knife_welcome_spawn_menu[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "Klexen",
	description = "Choose and a save custom knife skin for this server.",
	version = PLUGIN_VERSION
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (late){
		for (new i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i)) {
				SDKHook(i, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
			}
		}
	}
	
	CreateNative("K_GetKnife", Native_GetKnife);
	
	RegPluginLibrary("knife_plugin");

	return APLRes_Success;
}

public Native_GetKnife(Handle:plugin, argc)
{  
	return knife_choice[GetNativeCell(1)];
}

public OnPluginStart()
{
	LoadTranslations("knifeupgrade.phrases");
	LoadTranslations("common.phrases");
	
	CreateConVar("sm_knifeupgrade_version", PLUGIN_VERSION, "Knife Upgrade Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cookieKnife = RegClientCookie("knife_choice", "", CookieAccess_Private);
	g_hEnabled = CreateConVar("sm_knifeupgrade_on", "1", "Enable / Disable Plugin", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hSpawnMessage = CreateConVar("sm_knifeupgrade_spawn_message", "0", "Show Plugin Message on Spawn", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hSpawnMenu = CreateConVar("sm_knifeupgrade_spawn_menu", "0", "Show Knife Menu on Spawn", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hWelcomeMessage = CreateConVar("sm_knifeupgrade_welcome_message", "1", "Show Plugin Message on player connect.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hWelcomeMenu = CreateConVar("sm_knifeupgrade_welcome_menu", "0", "Show Knife Menu on player connect.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hWelcomeMenuOnlyNoKnife = CreateConVar("sm_knifeupgrade_welcome_menu_only_no_knife", "1", "Show Knife Menu on player Spawn ONCE and only if they haven't already chosen a knife before.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hWelcomeMessageTimer = CreateConVar("sm_knifeupgrade_welcome_message_timer", "25.0", "When (in seconds) the message should be displayed after the player joins the server.", FCVAR_NONE, true, 25.0, true, 90.0);
	g_hWelcomeMenuTimer = CreateConVar("sm_knifeupgrade_welcome_menu_timer", "8.5", "When (in seconds) AFTER SPAWNING THE FIRST TIME the knife menu should be displayed.", FCVAR_NONE, true, 1.0, true, 90.0);
	g_hKnifeChosenMessage = CreateConVar("sm_knifeupgrade_chosen_message", "1", "Show message to player when player chooses a knife.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hNoKnifeMapDisable = CreateConVar("sm_knifeupgrade_map_disable", "0", "Set to 1 to disable knife on maps not meant to have knives", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hNoKnifeMenu = CreateConVar("sm_knifeupgrade_no_menu", "0", "Set to 1 to disable the knife menu.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hNoUpdates = CreateConVar("sm_knifeupgrade_no_updates", "0", "Set to 1 to disable plugin automatic updates.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hHideRestricted = CreateConVar("sm_knifeupgrade_hide_restricted", "0", "Set to 1 to hide restricted knives from the menu. 0 Shows the knives as disabled.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hEndRoundCrash = CreateConVar("sm_knifeupgrade_round_crash", "0", "Set to 1 to fix crash crashes with end of round **if you have them**.", FCVAR_NONE, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "sm_knifeupgrade");
	
	//Reg Knife Command from translation file
	decl String:knife[32];
	Format(knife, sizeof(knife), "%t", "Knife Menu Command");
	RegConsoleCmd(knife, CreateKnifeMenuTimer);
	
	AddCommandListener(Event_Say, "say");
	AddCommandListener(Event_Say, "say_team");
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
	HookEvent("game_newmap", Event_GameStart);
	HookEvent("player_team",OnChangeTeam, EventHookMode_Pre);
	
/* 	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	} */
	
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i)) {
			OnClientCookiesCached(i);
		}
	}
}

/* public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
} */

/* public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "updater")) Updater_RemovePlugin();
} */

public Event_GameStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Handle:dm_weapons_allow_3rd_party = FindConVar("dm_weapons_allow_3rd_party");
	if(dm_weapons_allow_3rd_party != INVALID_HANDLE && !GetConVarBool(dm_weapons_allow_3rd_party)) SetConVarBool(dm_weapons_allow_3rd_party, true);
}

public Action:Updater_OnPluginChecking() {
	if (GetConVarBool(g_hNoUpdates)) return Plugin_Handled;
	return Plugin_Continue;
}

/* public Updater_OnPluginUpdated() {
	ReloadPlugin();
} */

public OnClientCookiesCached(client)
{
	new String:value[16];
	GetClientCookie(client, g_cookieKnife, value, sizeof(value));
	if(strlen(value) > 0) knife_choice[client] = StringToInt(value);
}

public OnClientAuthorized(client)
{
	knife_welcome_spawn_menu[client] = 0;
}

public Action:OnPostWeaponEquip(client, weapon)
{ 
	new weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	if (weaponindex != 42 && weaponindex != 59) // standard knife || knife t *Thank you Neuro Toxin*
		return Plugin_Continue;
	
	new m_iEntityQuality = GetEntProp(weapon, Prop_Send, "m_iEntityQuality");
	new m_iItemIDHigh = GetEntProp(weapon, Prop_Send, "m_iItemIDHigh");
	new m_iItemIDLow = GetEntProp(weapon, Prop_Send, "m_iItemIDLow");
	new check = m_iEntityQuality + m_iItemIDHigh + m_iItemIDLow;
	
	if (check >= 4)
		return Plugin_Continue;
	
	if (knife_choice[client] < 1) 
		return Plugin_Continue;
	
	CreateTimer(0.0, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	if(!IsFakeClient(client))
		SDKHook(client, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
}

public OnClientDisconnect(client) 
{ 
	SDKUnhook(client, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
}

public Action:OnChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_hGoldKnifeCrash) || GetConVarBool(g_hEndRoundCrash))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if (!IsValidClient(client)) return Plugin_Continue;
		if (knife_choice[client] < 1) return Plugin_Continue;
		
		new team = GetEventInt(event, "team");
		new oldteam = GetClientTeam(client);
		
		if (knife_choice[client] < 9 && !GetConVarBool(g_hEndRoundCrash)) return Plugin_Continue;
		
		if (team == oldteam && team > CS_TEAM_SPECTATOR) return Plugin_Continue;
		
		if (IsPlayerAlive(client)){
			CreateTimer(1.5, TeamSwapKnifeCheck, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
			Client_RemoveWeaponKnife(client, "weapon_knife", true);
		}
		if (IsClientInGame(client)){
			CS_SwitchTeam(client, CS_TEAM_NONE);
		}
	}
	return Plugin_Continue;
}

public Action:TeamSwapKnifeCheck(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	if (!IsPlayerAlive(client)) return;
	
	if (!Client_HasWeaponKnife(client,"weapon_knife", true) && GetClientTeam(client) > CS_TEAM_SPECTATOR)
	{
		CreateTimer(0.0, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}
public Action:CreateKnifeMenuTimer(client, args) {
	
	if (IsValidClient(client)) {
		CreateTimer(0.1, KnifeMenu, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	} else {
		CPrintToChat(client, " %t","Command Access Denied Message");
	}
	return Plugin_Handled;
}

public Action:Event_Say(client, const String:command[], arg)
{
	if (GetConVarBool(g_hEnabled))
	{
		static String:menuTriggers[][] = { "!knief", "!knifes", "!knfie", "!knifw", "!knifew", "!kinfe", "!kinfes", "knife", "/knif", "/knifes", "/knfie", "/knifw", "/knives", "/kinfe", "/kinfes" };
		
		decl String:text[192];
		GetCmdArgString(text, sizeof(text));
		StripQuotes(text);
		TrimString(text);
		
		for(new i = 0; i < sizeof(menuTriggers); i++)
		{
			if (StrEqual(text, menuTriggers[i], false))
			{
				if (IsValidClient(client))
				{
					CreateTimer(0.1, KnifeMenu, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
				} else {
					CPrintToChat(client, " %t","Command Access Denied Message");
				}
				return Plugin_Handled;
			}
		}
		
		//Knife Shortcut Triggers
		//Bayonet
		decl String:Bayonet[32];
		Format(Bayonet, sizeof(Bayonet), "%t", "Knife Trigger Bayonet");
		if (StrEqual(text, Bayonet, false))
		{
			if (IsValidClient(client))
			{
				SetBayonet(client);
			} else {
				CPrintToChat(client, " %t","Command Access Denied Message");
			}
			return Plugin_Handled;
		}
		//Gut
		decl String:Gut[32];
		Format(Gut, sizeof(Gut), "%t", "Knife Trigger Gut");
		if (StrEqual(text, Gut, false))
		{
			if (IsValidClient(client))
			{
				SetGut(client);
			} else {
				CPrintToChat(client, " %t","Command Access Denied Message");
			}
			return Plugin_Handled;
		}
		//Flip
		decl String:Flip[32];
		Format(Flip, sizeof(Flip), "%t", "Knife Trigger Flip");
		if (StrEqual(text, Flip, false))
		{
			if (IsValidClient(client))
			{
				SetFlip(client);
			} else {
				CPrintToChat(client, " %t","Command Access Denied Message");
			}
			return Plugin_Handled;
		}
		//M9
		decl String:M9[32];
		Format(M9, sizeof(M9), "%t", "Knife Trigger M9");
		if (StrEqual(text, M9, false))
		{
			if (IsValidClient(client))
			{
				SetM9(client);
			} else {
				CPrintToChat(client, " %t","Command Access Denied Message");
			}
			return Plugin_Handled;
		}
		//Karambit
		decl String:Karambit[32];
		Format(Karambit, sizeof(Karambit), "%t", "Knife Trigger Karambit");
		if (StrEqual(text, Karambit, false))
		{
			if (IsValidClient(client))
			{
				SetKarambit(client);
			} else {
				CPrintToChat(client, " %t","Command Access Denied Message");
			}
			return Plugin_Handled;
		}
		//Huntsman
		decl String:Huntsman[32];
		Format(Huntsman, sizeof(Huntsman), "%t", "Knife Trigger Huntsman");
		if (StrEqual(text, Huntsman, false))
		{
			if (IsValidClient(client))
			{
				SetHuntsman(client);
			} else {
				CPrintToChat(client, " %t","Command Access Denied Message");
			}
			return Plugin_Handled;
		}
		//Butterfly
		decl String:Butterfly[32];
		Format(Butterfly, sizeof(Butterfly), "%t", "Knife Trigger Butterfly");
		if (StrEqual(text, Butterfly, false))
		{
			if (IsValidClient(client))
			{
				SetButterfly(client);
			} else {
				CPrintToChat(client, " %t","Command Access Denied Message");
			}
			return Plugin_Handled;
		}
		//Default
		decl String:Default[32];
		Format(Default, sizeof(Default), "%t", "Knife Trigger Default");
		if (StrEqual(text, Default, false))
		{
			if (IsValidClient(client))
			{
				SetDefault(client);
			} else {
				CPrintToChat(client, " %t","Command Access Denied Message");
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsValidClient(client)) return;
	
	if (GetConVarBool(g_hSpawnMessage))
	{
		CPrintToChat(client, "%t","Spawn and Welcome Message");
		CPrintToChat(client, "%t", "Chat Triggers Message");
	}
	if (GetConVarBool(g_hSpawnMenu) && IsValidClient(client)) CreateTimer(0.1, KnifeMenu, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	if (GetConVarBool(g_hWelcomeMenu) && IsValidClient(client)) CreateTimer(GetConVarFloat(g_hWelcomeMenuTimer), AfterSpawn, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
}

public OnClientPostAdminCheck(client)
{
	if (GetConVarBool(g_hWelcomeMessage)) CreateTimer(GetConVarFloat(g_hWelcomeMessageTimer), Timer_Welcome_Message, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_Welcome_Message(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (GetConVarBool(g_hWelcomeMessage) && IsValidClient(client))
	{
		CPrintToChat(client, "%t","Spawn and Welcome Message");
		CPrintToChat(client, "%t", "Chat Triggers Message");
	}              
}

public Action:AfterSpawn(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (GetConVarBool(g_hWelcomeMenu) && IsValidClient(client) && knife_welcome_spawn_menu[client] == 0)
	{
		if (GetConVarBool(g_hWelcomeMenuOnlyNoKnife))
		{
			if (knife_choice[client] < 1) CreateTimer(0.1, KnifeMenu, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE); //Only show Knife Welcome Message if a custom knife hasn't been selected yet.
		} else {
			CreateTimer(0.1, KnifeMenu, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	if (knife_welcome_spawn_menu[client] == 0) knife_welcome_spawn_menu[client] = 1;
}

public Action:CheckKnife(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if(IsValidClient(client) && IsPlayerAlive(client) && GetConVarBool(g_hEnabled))
	{
		if(Client_RemoveWeaponKnife(client, "weapon_knife", true)) {
			Equipknife(client);
		} else {
			if (GetConVarBool(g_hNoKnifeMapDisable)) {
				return Plugin_Handled;
			} else {
				Equipknife(client);
			}
		}
	}
	return Plugin_Handled;
}




public Action:Equipknife(client)
{      
	if (knife_choice[client] < 0 || knife_choice[client] > 9) knife_choice[client] = 0;
	if (knife_choice[client] == 8) knife_choice[client] = 0; //Set Default Knife to 0 so default knife users bypass extra strip / equip
	
	//If the player has selected and saved a knife before access to the knife was restricted to player, 
	//the player would still get the knife until they selected a new one. This sets the knife to default in this scenario.
	if (knife_choice[client] > 0) 
	{
		if (!CheckCommandAccess(client, "sm_knifeupgrade_bayonet", 0, true) && knife_choice[client] == 1) {
			knife_choice[client] = 0;
			CPrintToChat(client, " %t","No Longer Has Access to Current Knife");
		}
		
		if (!CheckCommandAccess(client, "sm_knifeupgrade_gut", 0, true) && knife_choice[client] == 2) {
			knife_choice[client] = 0;
			CPrintToChat(client, " %t","No Longer Has Access to Current Knife");
		}
		
		if (!CheckCommandAccess(client, "sm_knifeupgrade_flip", 0, true) && knife_choice[client] == 3) {
			knife_choice[client] = 0;
			CPrintToChat(client, " %t","No Longer Has Access to Current Knife");
		}
		
		if (!CheckCommandAccess(client, "sm_knifeupgrade_m9", 0, true) && knife_choice[client] == 4) {
			knife_choice[client] = 0;
			CPrintToChat(client, " %t","No Longer Has Access to Current Knife");
		}
		
		if (!CheckCommandAccess(client, "sm_knifeupgrade_karambit", 0, true) && knife_choice[client] == 5) {
			knife_choice[client] = 0;
			CPrintToChat(client, " %t","No Longer Has Access to Current Knife");
		}
		
		if (!CheckCommandAccess(client, "sm_knifeupgrade_huntsman", 0, true) && knife_choice[client] == 6) {
			knife_choice[client] = 0;
			CPrintToChat(client, " %t","No Longer Has Access to Current Knife");
		}
		
		if (!CheckCommandAccess(client, "sm_knifeupgrade_butterfly", 0, true) && knife_choice[client] == 7) {
			knife_choice[client] = 0;
			CPrintToChat(client, " %t","No Longer Has Access to Current Knife");
		}
	}
	new iItem;
	switch(knife_choice[client]) {
		case 0:iItem = GivePlayerItem(client, "weapon_knife");
		case 1:iItem = GivePlayerItem(client, "weapon_bayonet");
		case 2:iItem = GivePlayerItem(client, "weapon_knife_gut");
		case 3:iItem = GivePlayerItem(client, "weapon_knife_flip");
		case 4:iItem = GivePlayerItem(client, "weapon_knife_m9_bayonet");
		case 5:iItem = GivePlayerItem(client, "weapon_knife_karambit");
		case 6:iItem = GivePlayerItem(client, "weapon_knife_tactical");
		case 7:iItem = GivePlayerItem(client, "weapon_knife_butterfly");
		case 8:iItem = GivePlayerItem(client, "weapon_knife");
		case 9:iItem = GivePlayerItem(client, "weapon_knifegg");
		default: return;
	}
	if (iItem > 0) 
		EquipPlayerWeapon(client, iItem);
}

SetBayonet(client)
{
	if (knife_choice[client] == 1) return;
	if (CheckCommandAccess(client, "sm_knifeupgrade_bayonet", 0, true))
	{
		knife_choice[client] = 1;
		SetClientCookie(client, g_cookieKnife, "1");
		CreateTimer(0.1, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);   
		if (GetConVarBool(g_hKnifeChosenMessage)) CPrintToChat(client, " %t","Bayonet Given Message");
	} else {
		CPrintToChat(client, "%t", "Knife Access Denied Message");
	}
}

SetGut(client)
{
	if (knife_choice[client] == 2) return;
	if (CheckCommandAccess(client, "sm_knifeupgrade_gut", 0, true))
	{
		knife_choice[client] = 2;
		SetClientCookie(client, g_cookieKnife, "2");
		CreateTimer(0.1, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);    
		if (GetConVarBool(g_hKnifeChosenMessage)) CPrintToChat(client, " %t","Gut Given Message");
	} else {
		CPrintToChat(client, "%t", "Knife Access Denied Message");
	}
}

SetFlip(client)
{
	if (knife_choice[client] == 3) return;
	if (CheckCommandAccess(client, "sm_knifeupgrade_flip", 0, true))
	{
		knife_choice[client] = 3;
		SetClientCookie(client, g_cookieKnife, "3");
		CreateTimer(0.1, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);   
		if (GetConVarBool(g_hKnifeChosenMessage)) CPrintToChat(client, " %t","Flip Given Message");
	} else {
		CPrintToChat(client, "%t", "Knife Access Denied Message");
	}
}

SetM9(client)
{
	if (knife_choice[client] == 4) return;
	if (CheckCommandAccess(client, "sm_knifeupgrade_m9", 0, true))
	{
		knife_choice[client] = 4;
		SetClientCookie(client, g_cookieKnife, "4");
		CreateTimer(0.1, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		if (GetConVarBool(g_hKnifeChosenMessage)) CPrintToChat(client, " %t","M9 Given Message");
	} else {
		CPrintToChat(client, "%t", "Knife Access Denied Message");
	}
}

SetKarambit(client)
{
	if (knife_choice[client] == 5) return;
	if (CheckCommandAccess(client, "sm_knifeupgrade_karambit", 0, true))
	{
		knife_choice[client] = 5;
		SetClientCookie(client, g_cookieKnife, "5");
		CreateTimer(0.1, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);  
		if (GetConVarBool(g_hKnifeChosenMessage)) CPrintToChat(client, " %t","Karambit Given Message");
	} else {
		CPrintToChat(client, "%t", "Knife Access Denied Message");
	}
}

SetHuntsman(client)
{
	if (knife_choice[client] == 6) return;
	if (CheckCommandAccess(client, "sm_knifeupgrade_huntsman", 0, true))
	{
		knife_choice[client] = 6;
		SetClientCookie(client, g_cookieKnife, "6");
		CreateTimer(0.1, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);   
		if (GetConVarBool(g_hKnifeChosenMessage)) CPrintToChat(client, " %t","Huntsman Given Message");
	} else {
		CPrintToChat(client, "%t", "Knife Access Denied Message");
	}
}

SetButterfly(client)
{
	if (knife_choice[client] == 7) return;
	if (CheckCommandAccess(client, "sm_knifeupgrade_butterfly", 0, true))
	{
		knife_choice[client] = 7;
		SetClientCookie(client, g_cookieKnife, "7");
		CreateTimer(0.1, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);   
		if (GetConVarBool(g_hKnifeChosenMessage)) CPrintToChat(client, " %t","Butterfly Given Message");
	} else {
		CPrintToChat(client, "%t", "Knife Access Denied Message");
	}
}

SetDefault(client)
{
	if (knife_choice[client] == 0) return;
	knife_choice[client] = 0;
	SetClientCookie(client, g_cookieKnife, "0");
	CreateTimer(0.1, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	if (GetConVarBool(g_hKnifeChosenMessage)) CPrintToChat(client, " %t","Default Given Message");
}

public Action:KnifeMenu(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (IsValidClient(client) && GetConVarBool(g_hEnabled) && !GetConVarBool(g_hNoKnifeMenu))
	{
		ShowKnifeMenu(client);
	} 
	else if (IsValidClient(client) && GetConVarBool(g_hEnabled) && GetConVarBool(g_hNoKnifeMenu)) 
	{
		CPrintToChat(client, " %t","Knife Menu Disabled Message");
	}
	else if (GetConVarBool(g_hEnabled) && !IsValidClient(client))
	{
		CPrintToChat(client, " %t","Command Access Denied Message");
	}
	return Plugin_Handled;
}

public Action:ShowKnifeMenu(client)
{
	decl String:Bayonet[32];
	decl String:Gut[32];
	decl String:Flip[32];
	decl String:M9[32];
	decl String:Karambit[32];
	decl String:Huntsman[32];
	decl String:Butterfly[32];
	decl String:Default[32];
	
	Format(Bayonet, sizeof(Bayonet), "%t", "Menu Knife Bayonet");
	Format(Gut, sizeof(Gut), "%t", "Menu Knife Gut");
	Format(Flip, sizeof(Flip), "%t", "Menu Knife Flip");
	Format(M9, sizeof(M9), "%t", "Menu Knife M9");
	Format(Karambit, sizeof(Karambit), "%t", "Menu Knife Karambit");
	Format(Huntsman, sizeof(Huntsman), "%t", "Menu Knife Huntsman");
	Format(Butterfly, sizeof(Butterfly), "%t", "Menu Knife Butterfly");
	Format(Default, sizeof(Default), "%t", "Menu Knife Default");
	
	new Handle:menu = CreateMenu(ShowKnifeMenuHandler);
	SetMenuTitle(menu, "%t", "Knife Menu Title");
	
	//Bayonet
	if (CheckCommandAccess(client, "sm_knifeupgrade_bayonet", 0, true)) {
		AddMenuItem(menu, "option2", Bayonet);
	} else {
		if(!GetConVarBool(g_hHideRestricted)) AddMenuItem(menu, "option2", Bayonet,ITEMDRAW_DISABLED);
	}
	//Gut
	if (CheckCommandAccess(client, "sm_knifeupgrade_gut", 0, true)) {
		AddMenuItem(menu, "option3", Gut);
	} else {
		if(!GetConVarBool(g_hHideRestricted)) AddMenuItem(menu, "option3", Gut,ITEMDRAW_DISABLED);
	}
	//Flip
	if (CheckCommandAccess(client, "sm_knifeupgrade_flip", 0, true)) {
		AddMenuItem(menu, "option4", Flip);
	} else {
		if(!GetConVarBool(g_hHideRestricted)) AddMenuItem(menu, "option4", Flip,ITEMDRAW_DISABLED);
	}
	//M9-Bayonet
	if (CheckCommandAccess(client, "sm_knifeupgrade_m9", 0, true)) {
		AddMenuItem(menu, "option5", M9);
	} else {
		if(!GetConVarBool(g_hHideRestricted)) AddMenuItem(menu, "option5", M9,ITEMDRAW_DISABLED);
	}
	//Karambit
	if (CheckCommandAccess(client, "sm_knifeupgrade_karambit", 0, true)) {
		AddMenuItem(menu, "option6", Karambit);
	} else {
		if(!GetConVarBool(g_hHideRestricted)) AddMenuItem(menu, "option6", Karambit,ITEMDRAW_DISABLED);
	}
	//Huntsman
	if (CheckCommandAccess(client, "sm_knifeupgrade_huntsman", 0, true)) {
		AddMenuItem(menu, "option7", Huntsman);
	} else {
		if(!GetConVarBool(g_hHideRestricted)) AddMenuItem(menu, "option7", Huntsman,ITEMDRAW_DISABLED);
	}
	//Butterfly
	if (CheckCommandAccess(client, "sm_knifeupgrade_butterfly", 0, true)) {
		AddMenuItem(menu, "option8", Butterfly);
	} else {
		if(!GetConVarBool(g_hHideRestricted)) AddMenuItem(menu, "option8", Butterfly,ITEMDRAW_DISABLED);
	}
	//Default
	AddMenuItem(menu, "option9", Default);{
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
	return Plugin_Handled;
}

public ShowKnifeMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	switch(action){
		case MenuAction_Select: 
		{
			new String:info[32];
			GetMenuItem(menu, itemNum, info, sizeof(info));
			//Bayonet
			if ( strcmp(info,"option2") == 0 ) SetBayonet(client);
			//Gut
			else if ( strcmp(info,"option3") == 0 ) SetGut(client);     
			//Flip
			else if ( strcmp(info,"option4") == 0 ) SetFlip(client);
			//M9-Bayonet
			else if ( strcmp(info,"option5") == 0 ) SetM9(client);
			//Karambit
			else if ( strcmp(info,"option6") == 0 ) SetKarambit(client);
			//Huntsman
			else if ( strcmp(info,"option7") == 0 ) SetHuntsman(client);
			//Butterfly
			else if ( strcmp(info,"option8") == 0 ) SetButterfly(client);
			//Default
			else if ( strcmp(info,"option9") == 0 ) SetDefault(client);
			
		}
		case MenuAction_End:{CloseHandle(menu);}
	}
}

bool:IsValidClient(client)
{
	if (!(0 < client <= MaxClients)) return false;
	if (!IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	if (!CheckCommandAccess(client, "sm_knifeupgrade", 0, true)) return false;
	return true;
}
