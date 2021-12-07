/**
* HandiCap
*
* Description:
*	Allows the hidden to give himself certain handicaps
*
* Commands:
* hsm_handicap_version : Prints current version
* hsm_handicap_enable (1/0) : Enables/Disables plugin
* hsm_handicap_healthreduction : Used for reporting, can not be used to adjust anything
* hsm_handicap_damagereduction : Used for reporting, can not be used to adjust anything
* hsm_handicap_isdrugged : Used for reporting, can not be used to adjust anything
* HandiCap (Chat command) : Opens the handicap menu
* HandiCap d (10,25,50,75,90) : reduces damage to specified value
* HandiCap h (25,50,75) : reduces health by specified value
* Unhandicap (Chat command) : Removes all handicaps
*
*	
*  
* Version History
* 	1.5 Working version
*   1.7 Removed beacon, added reduce health
*	2.0 Added support for hiddenranks, made plugin auto disable on overun maps
* 
* Contact:
* Ice: Alex_leem@hotmail.com
* Hidden:Source: http://forum.hidden-source.com/
*
* Thanks to:
* phaedrus and paegus for the pigshove mod, as the damage
* changing system is modified off of paegus's plugin hsm_pigshove
*/

// General includes
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>

// 2 is IRIS's unique team ID so define it
#define HDN_TEAM_IRIS 2
#define HDN_TEAM_HIDDEN 3
#define CD_VERSION "2.0.0"
#define MAX_FILE_LEN 80

new Handle:cvarEnable;
new Handle:HealthReduction;
new Handle:DamageReduction;
new Handle:IsDrugged;
new bool:g_isHooked;

new ClientID;
new String:ClientIDName[64];
new String:ClientName[64];
new HasDrugged;
new HasReducedDamage;
new IsInReduceDamage;
new IsInReduceHealth;
new HasAlreadyReduced;
new Float:DamageModify = 1.0;

public Plugin:myinfo = 
{
	name = "Hidden Handicap",
	author = "Ice",
	description = "Allows the hidden to give himself handicaps",
	version = CD_VERSION,
	url = "http://www.google.com"
};

public OnPluginStart()
{
	CreateConVar("hsm_handicap_version", CD_VERSION, _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	cvarEnable = CreateConVar("hsm_handicap_enable","1","Enable/disable handicap plugin",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	HealthReduction = CreateConVar("hsm_handicap_healthreduction","0.0","Used for reporting, can not be used to adjust anything",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,75.0);
	DamageReduction = CreateConVar("hsm_handicap_damagereduction","0.0","Used for reporting, can not be used to adjust anything",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,90.0);
	IsDrugged = CreateConVar("hsm_handicap_isdrugged","0.0","Used for reporting, can not be used to adjust anything",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	CreateTimer(3.0, OnPluginStart_Delayed);
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	// Lets hook the plugin enable so it can be disabled at any time
	HookConVarChange(cvarEnable,CvarEnableChange);
}

public Action:OnPluginStart_Delayed(Handle:timer){
	if(GetConVarInt(cvarEnable) > 0)
	{
		g_isHooked = true;
		HookEvent("game_round_start",ev_RoundStart);
		HookEvent("player_hurt", ev_PlayerHurt);
		HookEvent("game_round_end",ev_RoundEnd);
		DamageModify = 1.0;
		
		LogMessage("[Hidden Handicap] - Loaded");
	}
}

public OnConfigsExecuted(){
	if (GetConVarInt(cvarEnable) == 0)
		{
			return;
		}
	new String:MapName[4];
	GetCurrentMap(MapName, sizeof(MapName));
	if(strcmp(MapName,"ovr", false) == 0){
		//Do this because listenserver.cfg isnt included in this callback, after 3 seconds listenserver.cfg should have already executed
		CreateTimer(3.0, PluginUnloadOVR_Delayed);
	}
}

public Action:PluginUnloadOVR_Delayed(Handle:timer){
	SetConVarInt(cvarEnable,0,false,false);
	LogMessage("[Hidden Handicap] - UnLoaded, OVR map being played");
}

public CvarEnableChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// Okay someone changed the plugin enable cvar lets see if they turned it on or off
	if(GetConVarInt(cvarEnable) <= 0)
	{
		if(g_isHooked)
		{
		g_isHooked = false;
		UnhookEvent("game_round_end",ev_RoundEnd);
		UnhookEvent("game_round_start",ev_RoundStart);
		UnhookEvent("player_hurt", ev_PlayerHurt);
		LogMessage("[Hidden Handicap] - UnLoaded");
		}
	}
	else if(!g_isHooked)
	{
		g_isHooked = true;
		HookEvent("game_round_start",ev_RoundStart);
		HookEvent("game_round_end",ev_RoundEnd);
		HookEvent("player_hurt", ev_PlayerHurt);
		LogMessage("[Hidden Handicap] - Loaded");
	}
}

bool:IsPlayer(client) {
	if (client >= 1 && client <= MaxClients) {
		if(IsValidEntity(client) && !IsFakeClient(client) && IsClientConnected(client) && IsClientInGame(client)){
			return true;
		}
	}
	return false;
}


public ev_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check if enabled, if not bail out
	if (GetConVarInt(cvarEnable) == 0)
	{
		return;
	}
	DamageModify = 1.0;
	HasReducedDamage = 0;
	IsInReduceHealth = 0;
	IsInReduceDamage = 0;
	HasAlreadyReduced = 0;
	SetConVarFloat(HealthReduction,0.0,false,false);
	SetConVarFloat(DamageReduction,0.0,false,false);
	SetConVarInt(IsDrugged,0,false,false);

	// Find the ClientID of the hidden
	for(new i = 1; i < MaxClients; i++)
		{
			if(IsPlayer(i) && GetClientTeam(i) == HDN_TEAM_HIDDEN)
			{
				ClientID = i;
				new Useridnumber = GetClientUserId(ClientID);
				Format(ClientIDName,sizeof(ClientIDName),"#%d",Useridnumber);
				GetClientName(ClientID,ClientName,sizeof(ClientName));
				i = MaxClients;
			}
		}
}

public ev_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
// Round ended, so lets set hidden to normal
	if (HasDrugged == 1){
		HasDrugged = 0;
		ServerCommand("sm_drug %s",ClientIDName);
	}
	DamageModify = 1.0;
	HasReducedDamage = 0;
	IsInReduceDamage = 0;
	SetConVarFloat(HealthReduction,0.0,false,false);
	SetConVarFloat(DamageReduction,0.0,false,false);
	SetConVarInt(IsDrugged,0,false,false);
	
}

public Action:ev_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check if enabled, if not bail out
	if (GetConVarInt(cvarEnable) == 0)
	{
		return Plugin_Continue;
	}
	new iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!iAttacker) {	// World attacked so we're done here.
		return Plugin_Continue;
	}
	if(IsPlayer(iAttacker) && GetClientTeam(iAttacker) == HDN_TEAM_HIDDEN)
		{
			new Float:iDamage = GetEventFloat(event, "damage"); // Get damage done.
			new Float:Damage2 = GetEventFloat(event, "damage"); // Get damage done.
			new iVictim = GetClientOfUserId(GetEventInt(event, "userid")); // Get victim.
			iDamage *= DamageModify;
			Damage2 -= iDamage;
			new Float:iHealth = GetClientHealth(iVictim) + Damage2; // Get their adjusted health.
			new iHealthInt = RoundFloat(iHealth);
			SetEntData(iVictim, FindDataMapOffs(iVictim, "m_iHealth"), iHealthInt,	4, true);
			
			return Plugin_Changed;
		}
	return Plugin_Continue;
}

public Action:Command_Say(client, args)
{
	// Check if enabled, if not bail out
	if (GetConVarInt(cvarEnable) == 0)
	{
		return Plugin_Continue;
	}

	// Get as little info as possible here
	new String:Chat[64];
	GetCmdArgString(Chat, sizeof(Chat));
	
	new startidx;
	if (Chat[strlen(Chat)-1] == '"')
	{
		Chat[strlen(Chat)-1] = '\0';
		startidx = 1;
	}
	
	if (strcmp(Chat[startidx],"HandiCap", false) == 0 && GetClientTeam(client) == HDN_TEAM_HIDDEN)
		{
			new Player = client;
			IsInReduceDamage = 0;
			IsInReduceHealth = 0;
			HandiCapMenu(Player);
			return Plugin_Continue;
			
		} else if(strcmp(Chat[startidx],"HandiCap d 10", false) == 0 && GetClientTeam(client) == HDN_TEAM_HIDDEN)
		{
			DamageModify = 0.9;
			HasAlreadyReduced = 1;
			HasReducedDamage = 1;
			SetConVarFloat(DamageReduction,10.0,false,false);
			PrintToChatAll("[HandiCap]\x03 %s has reduced his damage to 90 percent!", ClientName);
			return Plugin_Continue;
		} else if(strcmp(Chat[startidx],"HandiCap d 25", false) == 0 && GetClientTeam(client) == HDN_TEAM_HIDDEN)
		{
			DamageModify = 0.75;
			HasReducedDamage = 1;
			SetConVarFloat(DamageReduction,25.0,false,false);
			PrintToChatAll("[HandiCap]\x03 %s has reduced his damage to 75 percent!", ClientName);
			HasAlreadyReduced = 1;
			return Plugin_Continue;
		} else if(strcmp(Chat[startidx],"HandiCap d 50", false) == 0 && GetClientTeam(client) == HDN_TEAM_HIDDEN)
		{
			DamageModify = 0.5;
			HasReducedDamage = 1;
			SetConVarFloat(DamageReduction,50.0,false,false);
			PrintToChatAll("[HandiCap]\x03 %s has reduced his damage to 50 percent!", ClientName);
			HasAlreadyReduced = 1;
			return Plugin_Continue;
		} else if(strcmp(Chat[startidx],"HandiCap d 75", false) == 0 && GetClientTeam(client) == HDN_TEAM_HIDDEN)
		{
			DamageModify = 0.25;
			HasReducedDamage = 1;
			SetConVarFloat(DamageReduction,75.0,false,false);
			PrintToChatAll("[HandiCap]\x03 %s has reduced his damage to 25 percent!", ClientName);
			HasAlreadyReduced = 1;
			return Plugin_Continue;
		} else if(strcmp(Chat[startidx],"HandiCap d 90", false) == 0 && GetClientTeam(client) == HDN_TEAM_HIDDEN)
		{
			DamageModify = 0.1;
			HasReducedDamage = 1;
			SetConVarFloat(DamageReduction,90.0,false,false);
			PrintToChatAll("[HandiCap]\x03 %s has reduced his damage to 10 percent!", ClientName);
			HasAlreadyReduced = 1;
			return Plugin_Continue;
		} else if(strcmp(Chat[startidx],"HandiCap h 25", false) == 0 && GetClientTeam(client) == HDN_TEAM_HIDDEN)
		{
			if(GetClientHealth(ClientID) > 25){
				new Float:fHealth = GetClientHealth(ClientID) - 25.0; // Get their adjusted health.
				new iHealth = RoundFloat(fHealth);
				SetEntData(ClientID, FindDataMapOffs(ClientID, "m_iHealth"), iHealth,	4, true);
				SetConVarFloat(HealthReduction,25.0,false,false);
				PrintToChatAll("[HandiCap]\x03 %s has reduced his health by 25!", ClientName);
			} else {
				PrintToChat(ClientID, "[HandiCap]\x03 You cannot reduce your health to 0!");
			}
			return Plugin_Continue;
		} else if(strcmp(Chat[startidx],"HandiCap h 50", false) == 0 && GetClientTeam(client) == HDN_TEAM_HIDDEN)
		{
			if(GetClientHealth(ClientID) > 50){
				new Float:fHealth = GetClientHealth(ClientID) - 50.0; // Get their adjusted health.
				new iHealth = RoundFloat(fHealth);
				SetEntData(ClientID, FindDataMapOffs(ClientID, "m_iHealth"), iHealth,	4, true);
				SetConVarFloat(HealthReduction,50.0,false,false);
				PrintToChatAll("[HandiCap]\x03 %s has reduced his health by 50!", ClientName);
			} else {
				PrintToChat(ClientID, "[HandiCap]\x03 You cannot reduce your health to 0!");
			}
			return Plugin_Continue;
		} else if(strcmp(Chat[startidx],"HandiCap h 75", false) == 0 && GetClientTeam(client) == HDN_TEAM_HIDDEN)
		{
			if(GetClientHealth(ClientID) > 75){
				new Float:fHealth = GetClientHealth(ClientID) - 75.0; // Get their adjusted health.
				new iHealth = RoundFloat(fHealth);
				SetEntData(ClientID, FindDataMapOffs(ClientID, "m_iHealth"), iHealth,	4, true);
				SetConVarFloat(HealthReduction,75.0,false,false);
				PrintToChatAll("[HandiCap]\x03 %s has reduced his health by 75!", ClientName);
			} else {
				PrintToChat(ClientID, "[HandiCap]\x03 You cannot reduce your health to 0!");
			}
			return Plugin_Continue;
		} else if(strcmp(Chat[startidx],"UnHandiCap", false) == 0 && GetClientTeam(client) == HDN_TEAM_HIDDEN)
		{
			if (HasDrugged == 1){
			HasDrugged = 0;
			ServerCommand("sm_drug %s",ClientIDName);
			}
			if (HasReducedDamage == 1){
			HasReducedDamage = 0;
			HasAlreadyReduced = 0;
			DamageModify = 1.0;
			}
			PrintToChatAll("[HandiCap]\x03 %s has disabled all of his HandiCaps!", ClientName);
			SetConVarFloat(HealthReduction,0.0,false,false);
			SetConVarFloat(DamageReduction,0.0,false,false);
			SetConVarInt(IsDrugged,0,false,false);
			return Plugin_Continue;
		}
		else{
		return Plugin_Continue;
		}
}

HandiCapMenu(client)
{
	//2. build panel
	new Handle:HandiCap = CreatePanel(GetMenuStyleHandle(MenuStyle_Radio));
	
	if (IsInReduceDamage == 0 && IsInReduceHealth == 0){
		DrawPanelItem(HandiCap, "Reduce Health",ITEMDRAW_DEFAULT);
		if (HasDrugged == 0){
		DrawPanelItem(HandiCap, "Drug",ITEMDRAW_DEFAULT);
		} else {
		DrawPanelItem(HandiCap, "UnDrug",ITEMDRAW_DEFAULT);
		} 
		if (HasAlreadyReduced == 0){
		DrawPanelItem(HandiCap, "Reduce damage",ITEMDRAW_DEFAULT);
		} else {
		DrawPanelItem(HandiCap, "Normalize damage",ITEMDRAW_DEFAULT);
		}
	} else if(IsInReduceDamage == 1 && IsInReduceHealth == 0){
		DrawPanelItem(HandiCap, "10%",ITEMDRAW_DEFAULT);
		DrawPanelItem(HandiCap, "25%",ITEMDRAW_DEFAULT);
		DrawPanelItem(HandiCap, "50%",ITEMDRAW_DEFAULT);
		DrawPanelItem(HandiCap, "75%",ITEMDRAW_DEFAULT);
		DrawPanelItem(HandiCap, "90%",ITEMDRAW_DEFAULT);
		DrawPanelItem(HandiCap, "Back",ITEMDRAW_DEFAULT);
	} else if(IsInReduceHealth == 1 && IsInReduceDamage == 0){
		DrawPanelItem(HandiCap, "Reduce by 25",ITEMDRAW_DEFAULT);
		DrawPanelItem(HandiCap, "Reduce by 50",ITEMDRAW_DEFAULT);
		DrawPanelItem(HandiCap, "Reduce by 75",ITEMDRAW_DEFAULT);
		DrawPanelItem(HandiCap, "Back",ITEMDRAW_DEFAULT);
	}
	
	//3. print panel
	SetPanelTitle(HandiCap, "HandiCap Menu \nClick a button \nto handicap yourself");
	
	SendPanelToClient(HandiCap, client, HandiCapMenuHandler, 30);
	
	CloseHandle(HandiCap);
}

public HandiCapMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
	{
		if (IsInReduceDamage == 0 && IsInReduceHealth == 0)
		{
			if (param2==1) //ReduceHealth
			{
				IsInReduceHealth = 1;
				HandiCapMenu(param1);
			} else if (param2==2) //Drug
			{
				if (HasDrugged == 0){
				HasDrugged = 1;
				SetConVarInt(IsDrugged,1,false,false);
				ServerCommand("sm_drug %s",ClientIDName);
				PrintToChatAll("[HandiCap]\x03 %s has drugged himself!", ClientName);
				} else {
				HasDrugged = 0;
				ServerCommand("sm_drug %s",ClientIDName);
				SetConVarInt(IsDrugged,0,false,false);
				PrintToChatAll("[HandiCap]\x03 %s has disabled drug on himself!", ClientName);
				} 
				HandiCapMenu(param1);
			} else if (param2==3) //ReduceDamage
			{
				if (HasAlreadyReduced == 0){
				IsInReduceDamage = 1;
				} else {
				IsInReduceDamage = 0;
				HasAlreadyReduced = 0;
				DamageModify = 1.0;
				SetConVarFloat(DamageReduction,0.0,false,false);
				PrintToChatAll("[HandiCap]\x03 %s has set his damage to normal!", ClientName);
				}
				HandiCapMenu(param1);
			}
		} else if(IsInReduceDamage == 1 && IsInReduceHealth == 0){
		if (param2==1) //10%
			{
				DamageModify = 0.9;
				HasAlreadyReduced = 1;
				HasReducedDamage = 1;
				SetConVarFloat(DamageReduction,10.0,false,false);
				PrintToChatAll("[HandiCap]\x03 %s has reduced his damage to 90 percent!", ClientName);
				HandiCapMenu(param1);
			} else if (param2==2) //25%
			{
				DamageModify = 0.75;
				HasReducedDamage = 1;
				SetConVarFloat(DamageReduction,25.0,false,false);
				PrintToChatAll("[HandiCap]\x03 %s has reduced his damage to 75 percent!", ClientName);
				HasAlreadyReduced = 1;
				HandiCapMenu(param1);
			} else if (param2==3) //50%
			{
				DamageModify = 0.5;
				HasReducedDamage = 1;
				SetConVarFloat(DamageReduction,50.0,false,false);
				PrintToChatAll("[HandiCap]\x03 %s has reduced his damage to 50 percent!", ClientName);
				HasAlreadyReduced = 1;
				HandiCapMenu(param1);
			} else if (param2==4) //75%
			{
				DamageModify = 0.25;
				HasReducedDamage = 1;
				SetConVarFloat(DamageReduction,75.0,false,false);
				PrintToChatAll("[HandiCap]\x03 %s has reduced his damage to 25 percent!", ClientName);
				HasAlreadyReduced = 1;
				HandiCapMenu(param1);
			} else if (param2==5) //90%
			{
				DamageModify = 0.1;
				HasReducedDamage = 1;
				SetConVarFloat(DamageReduction,90.0,false,false);
				PrintToChatAll("[HandiCap]\x03 %s has reduced his damage to 10 percent!", ClientName);
				HasAlreadyReduced = 1;
				HandiCapMenu(param1);
			}else if (param2==6) //Back
			{
				IsInReduceDamage = 0;
				HandiCapMenu(param1);
			}
		} else if(IsInReduceHealth == 1 && IsInReduceDamage == 0){
		if (param2==1) //25
			{
				if(GetClientHealth(ClientID) > 25){
				new Float:fHealth = GetClientHealth(ClientID) - 25.0; // Get their adjusted health.
				new iHealth = RoundFloat(fHealth);
				SetEntData(ClientID, FindDataMapOffs(ClientID, "m_iHealth"), iHealth,	4, true);
				SetConVarFloat(HealthReduction,25.0,false,false);
				PrintToChatAll("[HandiCap]\x03 %s has reduced his health by 25!", ClientName);
				} else {
				PrintToChat(ClientID, "[HandiCap]\x03 You cannot reduce your health to 0!");
				}
				HandiCapMenu(param1);
			} else if (param2==2) //50
			{
				if(GetClientHealth(ClientID) > 50){
				new Float:fHealth = GetClientHealth(ClientID) - 50.0; // Get their adjusted health.
				new iHealth = RoundFloat(fHealth);
				SetEntData(ClientID, FindDataMapOffs(ClientID, "m_iHealth"), iHealth,	4, true);
				SetConVarFloat(HealthReduction,50.0,false,false);
				PrintToChatAll("[HandiCap]\x03 %s has reduced his health by 50!", ClientName);
				} else {
				PrintToChat(ClientID, "[HandiCap]\x03 You cannot reduce your health to 0!");
				}
				HandiCapMenu(param1);
			} else if (param2==3) //75
			{
				if(GetClientHealth(ClientID) > 75){
				new Float:fHealth = GetClientHealth(ClientID) - 75.0; // Get their adjusted health.
				new iHealth = RoundFloat(fHealth);
				SetEntData(ClientID, FindDataMapOffs(ClientID, "m_iHealth"), iHealth,	4, true);
				SetConVarFloat(HealthReduction,75.0,false,false);
				PrintToChatAll("[HandiCap]\x03 %s has reduced his health by 75!", ClientName);
				} else {
				PrintToChat(ClientID, "[HandiCap]\x03 You cannot reduce your health to 0!");
				}
				HandiCapMenu(param1);
			} else if (param2==4) //back
			{
				IsInReduceHealth = 0;
				HandiCapMenu(param1);
			}
		}
	} 
}