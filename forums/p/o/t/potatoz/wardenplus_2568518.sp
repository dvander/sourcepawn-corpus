/*                                  _                        
 *	 __      __   __ _   _ __    __| |   ___   _ __      _   
 *	 \ \ /\ / /  / _` | | '__|  / _` |  / _ \ | '_ \   _| |_ 
 *	  \ V  V /  | (_| | | |    | (_| | |  __/ | | | | |_   _|
 *	   \_/\_/    \__,_| |_|     \__,_|  \___| |_| |_|   |_|  
 *                                                         
 * 		    Copyright (C) 2018 Adam "Potatoz" Ericsson
 * 
 * 	This program is free software: you can redistribute it and/or modify it
 * 	under the terms of the GNU General Public License as published by the Free
 * 	Software Foundation, either version 3 of the License, or (at your option) 
 * 	any later version.
 *
 * 	This program is distributed in the hope that it will be useful, but WITHOUT 
 * 	ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * 	FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * 	See http://www.gnu.org/licenses/. for more information
 */
 
#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

// These are needed for successful compiling
#include <hosties>
#include <smartjaildoors>
#include <lastrequest>
#include <ccc>

#define VERSION "1.0"
#define HIDE_RADAR_CSGO 1<<12

new Warden = -1;

bool NoBlock = true,
	HnsEnabled = false,
	WarEnabled = false,
	FreezeEnabled = false,
	WardenPicked = false,
	PlayerHasFreeday[MAXPLAYERS+1] = false,
	IsHnsClient[MAXPLAYERS+1] = false,
	BecomeWarden[MAXPLAYERS+1] = false,
	IsFreezed[MAXPLAYERS+1] = false,
	LaserEnabled[MAXPLAYERS+1] = false,
	ColorDivided = false,
	TimerUsed = false,
	DamageProtection = false,
	TimerUsed2 = false;
int PrimaryChoice[MAXPLAYERS+1];
	SecondaryChoice[MAXPLAYERS+1],
	iClients[MAXPLAYERS+1],
	HasAccepted[MAXPLAYERS+1],
	iTimer = 40,
	HnsCount = 0,
	FreezeCount = 0,
	TotalFreezeCount = 0,
	HnsWinners = 0,
	iNumClients,
	SpecialDayRounds = 0,
	g_MarkerColor[] = {25,255,25,255};
Menu g_PrimaryMenu,
	g_SecondaryMenu;


public Plugin:myinfo =
{
	name = "Warden+",
	author = "Potatoz (base by ecca)",
	description = "",
	version = VERSION,
	url = ""
};

float g_fMakerPos[3];

int g_iBeamSprite = -1;
int g_iHaloSprite = -1;

/*
 * ----------------------------------------------------------------------
 *   ____                                                       _       
 *  / ___|   ___    _ __ ___    _ __ ___     __ _   _ __     __| |  ___ 
 * | |      / _ \  | '_ ` _ \  | '_ ` _ \   / _` | | '_ \   / _` | / __|
 * | |___  | (_) | | | | | | | | | | | | | | (_| | | | | | | (_| | \__ \
 *  \____|  \___/  |_| |_| |_| |_| |_| |_|  \__,_| |_| |_|  \__,_| |___/
 * 
 * ----------------------------------------------------------------------- 
 */

public OnPluginStart()
{	
	LoadTranslations("common.phrases");
	
	// Warden Commands
	RegConsoleCmd("sm_w", Command_BecomeWarden);
	RegConsoleCmd("sm_uw", Command_ExitWarden);
	RegConsoleCmd("sm_c", Command_BecomeWarden);
	RegConsoleCmd("sm_uc", Command_ExitWarden);
	
	// Other
	RegConsoleCmd("sm_noblock", Command_ToggleNoBlock);
	RegConsoleCmd("sm_givefreeday", Command_GiveFreeday);
	RegConsoleCmd("sm_colordivide", Command_ColorDivide);
	RegConsoleCmd("sm_cells", Command_Cells);
	RegConsoleCmd("sm_marker", Command_PlaceMarker);
	RegConsoleCmd("sm_random", Command_RandomPlayer);
	RegConsoleCmd("+laser", Command_WardenLaserOn);
	RegConsoleCmd("-laser", Command_WardenLaserOff);
	
	// Warden Menu
	RegConsoleCmd("sm_wmenu", Command_WardenMenu);
	RegConsoleCmd("sm_cmenu", Command_WardenMenu);
	RegConsoleCmd("sm_misc", Command_WardenMenu);
	RegConsoleCmd("buyammo1", Command_WardenMenu);
	
	// Days Menu
	RegConsoleCmd("sm_days", Command_DaysMenu);
	
	// For Admins
	RegAdminCmd("sm_rrc", Command_RemoveRandomCT, ADMFLAG_GENERIC);
	RegAdminCmd("sm_src", Command_SetRandomCT, ADMFLAG_GENERIC);
	RegAdminCmd("sm_rc", Command_RemoveWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_rw", Command_RemoveWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_sc", Command_SetWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_sw", Command_SetWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_abortdays", Command_AbortDays, ADMFLAG_GENERIC);
	RegAdminCmd("sm_abortday", Command_AbortDays, ADMFLAG_GENERIC);
	
	// Events
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_death", Event_PrePlayerDeath, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_spawn", Event_PlayerSpawn);
	AddCommandListener(Command_JoinTeam, "jointeam");	
	
	// Warday Stuff
	g_PrimaryMenu = BuildPrimaryMenu();
	g_SecondaryMenu = BuildSecondaryMenu();
	
	// Timers
	CreateTimer(1.0, Timer_DrawMakers, _, TIMER_REPEAT);
	
	// Reset Settings
	Warden = -1;
	SetCvar("mp_solid_teammates", "0");
	SetCvar("sm_hosties_lr", "1");
	SetCvar("mp_forcecamera", "0");
	SetCvar("sv_gravity", "780");
	SetCvar("mp_friendlyfire", "0");
	WarEnabled = false;
	HnsEnabled = false;
	FreezeEnabled = false;
	DamageProtection = false;
	NoBlock = true;
	WardenPicked = true;
	iTimer = 0;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
		OnClientPutInServer(i);
		
		if(IsPlayerAlive(i))
		{
		SetEntityMoveType(i, MOVETYPE_WALK);
		}

		SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
		SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
		PlayerHasFreeday[i] = false;
		SetEntityRenderColor(i, 255, 255, 255, 255);
		SetEntProp(i, Prop_Data, "m_CollisionGroup", 2);
		LaserEnabled[i] = false;
		BecomeWarden[i] = false;
		IsFreezed[i] = false;
		}
	}
	
	// Targeting
	AddMultiTargetFilter("@warden", ProcessWarden, "Warden", false);
	AddMultiTargetFilter("@!warden", ProcessNotWarden, "everyone but the Warden", false);
}

/*
 * -------------------------------------------
 *  _____                          _         
 * | ____| __   __   ___   _ __   | |_   ___ 
 * |  _|   \ \ / /  / _ \ | '_ \  | __| / __|
 * | |___   \ V /  |  __/ | | | | | |_  \__ \
 * |_____|   \_/    \___| |_| |_|  \__| |___/    
 * 
 * -------------------------------------------
 */

// ON PLAYER CONNECT
public OnClientPutInServer(client) 
{
	if(!IsValidClient(client)) return;
	
	HasAccepted[client] = false;
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);
} 

// BEFORE PLAYER SWITCH TEAM
public Action Command_JoinTeam(client, const String:command[], args)
{
	if(!IsValidClient(client) || IsFakeClient(client))
		return Plugin_Continue;
		
	char teamString[3];
	GetCmdArg(1, teamString, sizeof(teamString));
	new target_team = StringToInt(teamString);
	new current_team = GetClientTeam(client);

	new Ts = 0;
	new CTs = 0;

	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if(GetClientTeam(i) == 3) 
				CTs++;

			if (GetClientTeam(i) == 2)
				Ts++;	
		}
	}
	
	CTs++;
	
	if(target_team == current_team)
		return Plugin_Handled;
	else if(target_team == 3 && !CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))
	{
		if(CTs <= 1) return Plugin_Continue;
	
		float fNumPrisonersPerGuard = float(Ts) / float(CTs);
		if(fNumPrisonersPerGuard < 3.0)
		{
			PrintToChat(client, " \x07* There is too many CTs at the moment, running 1:3 ratio");
			return Plugin_Handled;
		}
	
		int iGuardsNeeded = RoundToCeil(fNumPrisonersPerGuard - 3.0);
		if(iGuardsNeeded < 1)
			iGuardsNeeded = 1;

		if(iGuardsNeeded > 0)
			return Plugin_Continue;
			
		PrintToChat(client, " \x07* There is too many CTs at the moment, running 1:3 ratio");
		return Plugin_Handled;
	}
	else if(target_team == 1 && HnsEnabled && !CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true) && !IsClientSourceTV(client))
	{
		PrintToChat(client, " \x07* You can't join spectators during Hide'n'Seek");		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

// ON PLAYER SWITCH TEAM
public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client  = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client))
	{
		CreateTimer(0.2, CheckTeam, client);
		
		if(IsPlayerAlive(client))
			ForcePlayerSuicide(client);
		else if(!CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true)) 
			SetClientListeningFlags(client, VOICE_MUTED);
		
		IsFreezed[client] = false;	
		if(client == Warden)
		{
			PrintToChatAll(" \x06* %N \x01has retired as commander, you may now choose a new one", client);
			Warden = -1;
			SetEntityRenderColor(client, 255, 255, 255, 255);
		} else if(IsHnsClient[client] && HnsEnabled) {
			--HnsCount;
			IsHnsClient[client] = false;
		}
	}
}


// SEND MESSAGE UPON JOINING CT
public Action CheckTeam(Handle timer, int client)
{
	if(IsValidClient(client) && GetClientTeam(client) == 3 && !CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))
	{
		PrintToChat(client, " \x07* By joining CT you agree to having read and agreed to our rules");
	}
	else if(IsValidClient(client) && HnsEnabled && !CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true) && !IsClientSourceTV(client))
	{
		PrintToChat(client, " \x07* You can't join spectators during Hide'n'Seek, switched to T");		
		ChangeClientTeam(client, 2);
	}
}

// ON PLAYER SPAWN
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client_id = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_id);
	
	CreateTimer(0.2, PlayerSpawn, client, TIMER_FLAG_NO_MAPCHANGE);
}

// ON ROUND START
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	Warden = -1;
	SetCvar("mp_solid_teammates", "0");
	SetCvar("sm_hosties_lr", "1");
	SetCvar("mp_forcecamera", "0");
	SetCvar("sv_gravity", "780");
	SetCvar("mp_friendlyfire", "0");
	g_MarkerColor = {25,255,25,255};
	ResetMarker();
	NoBlock = true;
	ColorDivided = false;

	++SpecialDayRounds;

	WarEnabled = false;
	HnsEnabled = false;
	FreezeEnabled = false;
	DamageProtection = false;
	iTimer = 0;
	
	WardenPicked = false;
	CreateTimer(6.5, PickWarden);
	CreateTimer(0.2, ShowCommanderMenu);
	CreateTimer(0.2, StartRound);
	
	new CTs = 0;
	new Ts = 0;	
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			OnClientPutInServer(i);
			
			if(IsPlayerAlive(i))
				SetEntityMoveType(i, MOVETYPE_WALK);

			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
			SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
			SetEntityRenderColor(i, 255, 255, 255, 255);
			SetEntProp(i, Prop_Data, "m_CollisionGroup", 2);
			PlayerHasFreeday[i] = false;
			LaserEnabled[i] = false;
			BecomeWarden[i] = false;
			IsFreezed[i] = false;
			IsHnsClient[i] = false;
			
			if(GetClientTeam(i) == 3) 	
			{
				if(!CheckCommandAccess(i, "sm_slay", ADMFLAG_GENERIC, true))
					CTs++;
				if(SpecialDayRounds >= 5) 
					PrintToChat(i, " \x06* \x01Special days are available! Type \x06!days\x01 in chat as warden to start one.");
			}
			else if(GetClientTeam(i) == 2)
				Ts++;
		}
	}
	
	Ts++;
	
	if(CTs <= 1)
	{} else if(CTs <= RoundToFloor(float(Ts) / 3.0))
	{} else SwitchRandomCT();
}

public void SwitchRandomCT()
{	
	for(new i=1; i<=MaxClients; i++)
		if(IsValidClient(i) && GetClientTeam(i) == 3 && !CheckCommandAccess(i, "sm_slay", ADMFLAG_GENERIC, true))
			iClients[iNumClients++] = i;
		
	if(iNumClients != 0)
	{
		new iRandomClient = iClients[GetRandomInt(0, iNumClients-1)];
		if(IsValidClient(iRandomClient) && GetClientTeam(iRandomClient) == 3 && !CheckCommandAccess(iRandomClient, "sm_slay", ADMFLAG_GENERIC, true))
		{
			CreateTimer(0.2, RespawnPlayer, iRandomClient);
			PrintToChatAll(" \x06* %N \x01has been randomly switched to balance out the teams", iRandomClient);
			ChangeClientTeam(iRandomClient, 2);
		}
	}
	
	new CTs = 0;
	new Ts = 0;	
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if(GetClientTeam(i) == 3 && !CheckCommandAccess(i, "sm_slay", ADMFLAG_GENERIC, true)) 
				CTs++;
			else if (GetClientTeam(i) == 2)
				Ts++;	
		}
	}
	
	Ts++;
	
	if(CTs <= 1)
	{} else if(CTs <= RoundToFloor(float(Ts) / 3.0))
	{} else SwitchRandomCT();
}

// ON MAP START
public void OnMapStart()
{
	ResetMarker();
	SpecialDayRounds = 0;
	
	if (GetEngineVersion() == Engine_CSS)
	{
		g_iBeamSprite = PrecacheModel("materials/sprites/laser.vmt");
		g_iHaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	}
	else if (GetEngineVersion() == Engine_CSGO)
	{
		g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
		g_iHaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
	}
}

// ON PLAYER DISCONNECT
public OnClientDisconnect(client)
{
	IsFreezed[client] = false;
	HasAccepted[client] = false;
	if(client == Warden)
	{
		Warden = -1;
		PrintToChatAll(" \x06* \x01The warden disconnected. you may now choose a new one");
	} else if(IsHnsClient[client]) {
		--HnsCount;
		IsHnsClient[client] = false;
	}

	SDKUnhook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);
}

// ON TAKE DAMAGE
public Action:OnTakeDamagePre(client, &attacker, &inflictor, &Float:damage, &damagetype)
{	
	if(DamageProtection)
	{
		if(attacker == client)
		{
			damage = 0.0;
			return Plugin_Handled;
		}
		else if(damagetype & DMG_FALL
		|| damagetype & DMG_GENERIC
		|| damagetype & DMG_CRUSH
		|| damagetype & DMG_BURN
		|| damagetype & DMG_BLAST
		|| damagetype & DMG_SLOWBURN)
			return Plugin_Continue;
		else if(FreezeEnabled)
		{
			if(GetClientTeam(client) == 2)
			{
				if(GetClientTeam(attacker) == GetClientTeam(client) && IsFreezed[client] && !IsFreezed[attacker])
				{
				SetEntityMoveType(client, MOVETYPE_WALK);
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
				SetEntityRenderColor(client, 255, 255, 255, 255);
				IsFreezed[client] = false;
				--FreezeCount;
				} 
				else if(GetClientTeam(attacker) != GetClientTeam(client) && !IsFreezed[client])
				{
				SetEntityMoveType(client, MOVETYPE_NONE);
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0);
				SetEntityRenderColor(client, 0, 0, 255, 255);
				IsFreezed[client] = true;
				++FreezeCount;
				}
			}
		}
		else if(HnsEnabled && GetClientTeam(client) == 2)
			return Plugin_Continue;

		damage = 0.0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

// BEFORE PLAYER DEATH
public Action:Event_PrePlayerDeath(Event ev, char [] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(ev, "userid"));   
	int attacker = GetClientOfUserId(GetEventInt(ev, "attacker"));

	if(victim == attacker) return Plugin_Handled;
	
	return Plugin_Continue;
}

// ON PLAYER DEATH
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	char cname[32], aname[32];
	GetClientName(client, cname, 32);
	GetClientName(attacker, aname, 32);	
	IsFreezed[client] = false;
	
	if(!CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))
		SetClientListeningFlags(client, VOICE_MUTED);
	
	if(Warden == -1 && IsValidClient(attacker) && GetClientTeam(attacker) == 3 && client != attacker)
	{
	PrintToChatAll(" \x06* %s \x01killed \x06%s \x01without an existing warden", aname, cname);
	}
	
	if(client == Warden)
	{
		PrintToChatAll(" \x06* \x01The warden has died. you may now choose a new one");
		SetEntityRenderColor(client, 255, 255, 255, 255);
		Warden = -1;
	}
	if(PlayerHasFreeday[client])
		PlayerHasFreeday[client] = false;
	if(IsHnsClient[client]) {
		--HnsCount;
		IsHnsClient[client] = false;
	}
}

/*
 * ------------------------------------------------------------------------------------------------------------
 *   ____                                                       _     _____                          _         
 *  / ___|   ___    _ __ ___    _ __ ___     __ _   _ __     __| |   | ____| __   __   ___   _ __   | |_   ___ 
 * | |      / _ \  | '_ ` _ \  | '_ ` _ \   / _` | | '_ \   / _` |   |  _|   \ \ / /  / _ \ | '_ \  | __| / __|
 * | |___  | (_) | | | | | | | | | | | | | | (_| | | | | | | (_| |   | |___   \ V /  |  __/ | | | | | |_  \__ \
 *  \____|  \___/  |_| |_| |_| |_| |_| |_|  \__,_| |_| |_|  \__,_|   |_____|   \_/    \___| |_| |_|  \__| |___/
 *
 * -------------------------------------------------------------------------------------------------------------
 */
 
 // BECOME WARDEN (sm_c | sm_w)
public Action:Command_BecomeWarden(client, args) 
{
	if(Warden != -1)
	{
	PrintToChat(client, " \x06* \x01Your current warden is \x06%N", Warden);
	return Plugin_Handled;
	}
	
	if(!WardenPicked) {
	PrintToChat(client, " \x07* There is a commander vote in progress");
	return Plugin_Handled;
	}
	
	if (Warden == -1) 
	{
		if (GetClientTeam(client) == 3) 
		{
			if (IsPlayerAlive(client)) 
				SetTheWarden(client);
			else
				PrintToChat(client, " \x07* You must be alive to become commander!");
		}
	}
	else
	{
		PrintToChat(client, " \x06* \x01Your current warden is \x06%N", Warden);
	}
	
	return Plugin_Handled;
}

// LEAVE WARDEN (sm_uc | sm_uw)
public Action:Command_ExitWarden(client, args) 
{
	if(client == Warden)
	{
		PrintToChatAll(" \x06* %N \x01has retired as commander, you may now choose a new one", client);
		Warden = -1;
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	
	return Plugin_Handled;
}

// REMOVE WARDEN (sm_rc | sm_rw)
public Action:Command_RemoveWarden(client, args)
{
	if(Warden != -1)
		RemoveTheWarden(client);
	else
		PrintToChat(client, " \x07* There is no warden to fire");
		
	return Plugin_Handled;
}

// SET WARDEN (sm_sc | sm_sw)
public Action:Command_SetWarden(client, args)
{
	char arg1[32];
	
	if(args < 1) {
	PrintToChat(client, " \x06* \x01Usage: \x06sm_sw/sm_sc <#userid|client>");
	return Plugin_Handled;
	}
	
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1);
	if (target == -1)
	{
		return Plugin_Handled;
	}
	
	if(GetClientTeam(target) != 3) {
		PrintToChat(client, " \x07* Your target must be a CT");
		return Plugin_Handled;
	}
	
	if(!IsPlayerAlive(target)) {
		PrintToChat(client, " \x07* Your target must be alive");
		return Plugin_Handled;
	}
	
	if(Warden == -1)
	{
		PrintToChatAll(" \x06* \x01ADMIN: \x06%N \x01has appointed \x06%N \x01to warden", client, target);
		WardenPicked = true;
		Warden = target;
		SetEntityRenderColor(target, 0, 0, 255, 255);
		SetClientListeningFlags(target, VOICE_NORMAL);
	}
	else
	{
		PrintToChat(client, " \x07* You must fire the current warden first");
	}
		
	return Plugin_Handled;
}

// SET RANDOM WARDEN (sm_src)
public Action:Command_SetRandomCT(client, args)
{	
	if(Warden != -1)
	{
		PrintToChat(client, " \x07* You must fire the current warden first");
		return Plugin_Handled;
	}
	
	int availabletargets = 0;
		
	for (new i = 1; i <= MaxClients; i++)
		if(IsValidClient(i) && GetClientTeam(i) == 3)		
			++availabletargets;
		
	if(availabletargets == 0) {
	PrintToChat(client, " \x07* No CT's found");
	return Plugin_Handled;
	} else {
	iNumClients = 0;
	
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
		{
		iClients[iNumClients++] = i;
		}
	}
		
	if(iNumClients != 0)
	{
	new iRandomClient = iClients[GetRandomInt(0, iNumClients-1)];
	WardenPicked = true;
	Warden = iRandomClient;
	SetEntityRenderColor(iRandomClient, 0, 0, 255, 255);
	SetClientListeningFlags(iRandomClient, VOICE_NORMAL);
	PrintToChatAll(" \x06* \x01ADMIN: \x06%N \x01has randomly appointed \x06%N \x01to Warden", client, iRandomClient);
	} else PrintToChat(client, " \x07* No CT's found");
	}

	return Plugin_Handled;
}

// REMOVE RANDOM CT (sm_rrc)
public Action:Command_RemoveRandomCT(client, args)
{	
	int availabletargets = 0;
		
	for (new i = 1; i <= MaxClients; i++)
		if(IsValidClient(i) && GetClientTeam(i) == 3 && !CheckCommandAccess(i, "sm_slay", ADMFLAG_GENERIC, true))		
			++availabletargets;
		
	if(availabletargets == 0) {
	PrintToChat(client, " \x07* No CT's found");
	return Plugin_Handled;
	} else {
	iNumClients = 0;
	
	for(new i=1; i<=MaxClients; i++)
		if(IsValidClient(i) && GetClientTeam(i) == 3 && !CheckCommandAccess(i, "sm_slay", ADMFLAG_GENERIC, true))
			iClients[iNumClients++] = i;
		
	if(iNumClients != 0)
	{
	new iRandomClient = iClients[GetRandomInt(0, iNumClients-1)];
	if(IsValidClient(iRandomClient) && GetClientTeam(iRandomClient) == 3 && !CheckCommandAccess(iRandomClient, "sm_slay", ADMFLAG_GENERIC, true))
	{
		PrintToChatAll(" \x06* \x01ADMIN: \x06%N \x01has randomly switched \x06%N \x01to balance out the teams", client, iRandomClient);
		ChangeClientTeam(iRandomClient, 2);
	}
	} else PrintToChat(client, " \x07* No CT's found");
	}

	return Plugin_Handled;
}

// RESPAWN AUTO-SWITCHED PLAYER
public Action RespawnPlayer(Handle timer, int client)
{
	if(!IsPlayerAlive(client))
		CS_RespawnPlayer(client);
}

// COLOR DIVIDE PLAYERS (sm_colordivide)
public Action:Command_ColorDivide(client, args)
{
	if(HnsEnabled || WarEnabled || FreezeEnabled) {
	PrintToChat(client, " \x07* You don't have access to that command during a special day!");
	return Plugin_Handled;
	}
	
	if (client == Warden)
	{
		int availabletargets = 0;
		
		for (new i = 1; i <= MaxClients; i++)
			if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !PlayerHasFreeday[i])		
				++availabletargets;
		
		if(availabletargets == 0) {
		PrintToChat(client, " \x07* No prisoners found");
		return Plugin_Handled;
		} else if(ColorDivided){
		ColorDivided = false;
		PrintToChatAll(" \x06* \x01Warden \x06%N \x01has reset the colors", client);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !PlayerHasFreeday[i])
			{
				SetEntityRenderColor(i, 255, 255, 255, 255);
			}
		}
		return Plugin_Handled;
		} else {
		ColorDivided = true;
		PrintToChatAll(" \x06* \x01Warden \x06%N \x01has randomized prisoners into teams", client);
		PrintToChatAll(" \x06* \x01Check chat to see which team you're in");
		
		new bool:TeamSelect = false;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !PlayerHasFreeday[i])
			{
				if (TeamSelect)
				{
					SetEntityRenderColor(i, 255, 0, 0, 255);
					PrintToChat(i, " \x06* \x01You have been randomly chosen for the \x06RED \x01team");
					TeamSelect = false;
				} 
				else
				{
					SetEntityRenderColor(i, 0, 255, 0, 255);
					PrintToChat(i, " \x06* \x01You have been randomly chosen for the \x06GREEN \x01team");
					TeamSelect = true;
				}
			}
		}
		return Plugin_Handled;
		}
	} else PrintToChat(client, " \x07* You must be warden to do that");

	return Plugin_Handled;
}

// PICK RANDOM PLAYER (sm_random)
public Action:Command_RandomPlayer(client, args)
{
	if(HnsEnabled || WarEnabled || FreezeEnabled) {
	PrintToChat(client, " \x07* You don't have access to that command during a special day!");
	return Plugin_Handled;
	}
	
	if (client == Warden)
	{
		int availabletargets = 0;
		
		for (new i = 1; i <= MaxClients; i++)
			if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !PlayerHasFreeday[i])		
				++availabletargets;
		
		if(availabletargets == 0) {
		PrintToChat(client, " \x07* No prisoners found");
		return Plugin_Handled;
		} else {
		iNumClients = 0;
	
		for(new i=1; i<=MaxClients; i++)
		{
			if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !PlayerHasFreeday[i])
			{
			iClients[iNumClients++] = i;
			}
		}
		
		if(iNumClients != 0)
		{
		PrintToChatAll(" \x06* \x01Warden \x06%N \x01has chosen to pick a random player", Warden);
		new iRandomClient = iClients[GetRandomInt(0, iNumClients-1)];
		PrintToChatAll(" \x06* \x01And the random player is... \x06%N\x01!", iRandomClient);
		} else PrintToChat(client, " \x07* No prisoners found");
		}
	} else PrintToChat(client, " \x07* You must be warden to do that");

	return Plugin_Handled;
}

// OPEN CELL MANAGEMENT (sm_cells)
public Action:Command_Cells(client, args)
{
	if (client == Warden || CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))
	{		
		if(!SJD_IsCurrentMapConfigured()) 
		{
			PrintToChat(client, " \x07* Cell management isn't configured for this map yet");
		} else {
			new Handle:menu = CreateMenu(CellMenuHandler);
			SetMenuTitle(menu, "Cell Management");
			AddMenuItem(menu, "open", "Open Cells");
			AddMenuItem(menu, "close", "Close Cells");
			AddMenuItem(menu, "toggle", "Toggle Cells");
			AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
			SetMenuExitBackButton(menu, true);
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		}
		
		return Plugin_Handled;
	} else PrintToChat(client, " \x07* You must be warden to do that");

	return Plugin_Handled;
}

 // ABORT DAYS (sm_abortdays)
public Action:Command_AbortDays(client, args) 
{
	if(!(HnsEnabled || WarEnabled || FreezeEnabled))
	{
	PrintToChat(client, " \x07* There is no special day active");
	return Plugin_Handled;
	}
	
	if(HnsEnabled)
		PrintToChatAll(" \x06* \x01ADMIN: \x06%N \x01aborted Hide'n'Seek", client);
	else if(WarEnabled)
		PrintToChatAll(" \x06* \x01ADMIN: \x06%N \x01aborted War Day", client);
	else if(FreezeEnabled)
		PrintToChatAll(" \x06* \x01ADMIN: \x06%N \x01aborted Freeze Tag", client);
	
	SetCvar("mp_solid_teammates", "0");
	SetCvar("sm_hosties_lr", "1");
	SetCvar("mp_forcecamera", "0");
	SetCvar("sv_gravity", "780");
	SetCvar("mp_friendlyfire", "0");
	NoBlock = true;
	HnsEnabled = false;
	WarEnabled = false;
	FreezeEnabled = false;
	
	return Plugin_Handled;
}

// CELL MANAGEMENT
public CellMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if (action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		if(!SJD_IsCurrentMapConfigured())
		{
			PrintToChat(client, " \x07* Cell management isn't configured for this map yet");
		}
		else if (strcmp(info,"open") == 0 ) 
		{
			SJD_OpenDoors();
			
			if(client == Warden)
				PrintToChatAll(" \x06* \x01Warden \x06%N \x01has opened the cell doors", client);
			else if(CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))
				PrintToChatAll(" \x06* \x01ADMIN: \x06%N \x01has opened the cell doors", client);
				
			FakeClientCommand(client, "sm_cells");
		}
		else if (strcmp(info,"close") == 0) 
		{
			SJD_CloseDoors();
			
			if(client == Warden)
				PrintToChatAll(" \x06* \x01Warden \x06%N \x01has closed the cell doors", client);
			else if(CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))
				PrintToChatAll(" \x06* \x01ADMIN: \x06%N \x01has closed the cell doors", client);

			FakeClientCommand(client, "sm_cells");
		}
		else if (strcmp(info,"toggle") == 0) 
		{
			SJD_ToggleDoors();
			
			if(client == Warden)
				PrintToChatAll(" \x06* \x01Warden \x06%N \x01has toggled the cell doors", client);
			else if(CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))
				PrintToChatAll(" \x06* \x01ADMIN: \x06%N \x01has toggled the cell doors", client);

			FakeClientCommand(client, "sm_cells");
		}		
	}
	else if (action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack) { 
            FakeClientCommand(client, "sm_cmenu");
        } 
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// TOGGLE NOBLOCK (sm_noblock)
public Action:Command_ToggleNoBlock(client, args)
{
	if(HnsEnabled || WarEnabled || FreezeEnabled) {
	PrintToChat(client, " \x07* You don't have access to that command during a special day!");
	return Plugin_Handled;
	}
	
	if (client == Warden || CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))
	{
		if (!NoBlock) 
		{
			NoBlock = true;
			if(client == Warden)
				PrintToChatAll(" \x06* \x01Warden has \x06enabled \x01noblock");
			else if(CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))
				PrintToChatAll(" \x06* \x01ADMIN: \x06%N \x01has \x06enabled \x01noblock", client);
			
			SetCvar("mp_solid_teammates", "0");
			for (new i = 1; i <= MaxClients; i++)
			{
			if(IsValidClient(i))
				SetEntProp(i, Prop_Data, "m_CollisionGroup", 2);
			}
			return Plugin_Handled;
		} else {
			NoBlock = false;
			if(client == Warden)
				PrintToChatAll(" \x06* \x01Warden has \x06disabled \x01noblock");
			else if(CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))
				PrintToChatAll(" \x06* \x01ADMIN: \x06%N \x01has \x06disabled \x01noblock", client);
				
			SetCvar("mp_solid_teammates", "1");
			for (new i = 1; i <= MaxClients; i++)
			{
			if(IsValidClient(i))
				SetEntProp(i, Prop_Data, "m_CollisionGroup", 5);
			}
			return Plugin_Handled;
		}
	} else PrintToChat(client, " \x07* You must be warden to do that");

	return Plugin_Handled;
}

// OPEN MARKER MENU (sm_marker)
public Action Command_PlaceMarker(int client, int args)
{
	if(HnsEnabled || FreezeEnabled) {
	PrintToChat(client, " \x07* You don't have access to that command during a special day!");
	return Plugin_Handled;
	}
	
	if (client == Warden)
	{
	
	new Handle:menu = CreateMenu(MarkerMenuHandler);
	SetMenuTitle(menu, "Marker Management");
	AddMenuItem(menu, "", "Set Color:", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "red", "RED");
	AddMenuItem(menu, "green", "GREEN");
	AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
	AddMenuItem(menu, "new", "Place Marker");
	AddMenuItem(menu, "remove", "Remove Marker");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
	} else PrintToChat(client, " \x07* You must be warden to do that");
	
	return Plugin_Handled;
}

// PLACE MARKER
public PlaceMarker(client)
{
	GetClientAimTargetPos(client, g_fMakerPos);
	g_fMakerPos[2] += 10.0;
}

// MARKER MENU HANDLER
public MarkerMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if (action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, sizeof(info));

		if (strcmp(info,"red") == 0 ) 
		{
			g_MarkerColor = {255,25,25,255};
			Draw_Markers();
			FakeClientCommand(client, "sm_marker");
		}
		else if (strcmp(info,"green") == 0) 
		{
			g_MarkerColor = {25,255,25,255};
			Draw_Markers();
			FakeClientCommand(client, "sm_marker");
		}
		else if (strcmp(info,"new") == 0) 
		{
			PlaceMarker(client);
			FakeClientCommand(client, "sm_marker");
		}
		else if (strcmp(info,"remove") == 0) 
		{
			ResetMarker();
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack) { 
            FakeClientCommand(client, "sm_cmenu");
        } 
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

/*
 * -------------------------------------------
 *  _____   _                                 
 * |_   _| (_)  _ __ ___     ___   _ __   ___ 
 *   | |   | | | '_ ` _ \   / _ \ | '__| / __|
 *   | |   | | | | | | | | |  __/ | |    \__ \
 *   |_|   |_| |_| |_| |_|  \___| |_|    |___/
 *
 * --------------------------------------------
 */ 

// RUN THROUGH ALL THE SETTINGS ON START OF THE ROUND
public Action StartRound(Handle timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			OnClientPutInServer(i);
			
			if(IsPlayerAlive(i))
				SetEntityMoveType(i, MOVETYPE_WALK);
			else if(!CheckCommandAccess(i, "sm_slay", ADMFLAG_GENERIC, true) && GetClientTeam(i) != 3)
				SetClientListeningFlags(i, VOICE_MUTED);
			
			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
			SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
			SetEntityRenderColor(i, 255, 255, 255, 255);
			SetEntProp(i, Prop_Data, "m_CollisionGroup", 2);
			PlayerHasFreeday[i] = false;
			LaserEnabled[i] = false;
			BecomeWarden[i] = false;
			IsFreezed[i] = false;
			IsHnsClient[i] = false;
		}
	}
}

// RUN THROUGH ALL THE SETTINGS FOR PLAYER ON SPAWN
public Action PlayerSpawn(Handle timer, any client)
{	
	if(!IsValidClient(client)) return;
	OnClientPutInServer(client);
	
	SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR_CSGO);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	PlayerHasFreeday[client] = false;
	BecomeWarden[client] = false;
	LaserEnabled[client] = false;
	IsFreezed[client] = false;
	IsHnsClient[client] = false;
	if(NoBlock) SetEntProp(client, Prop_Data, "m_CollisionGroup", 2);
	if(GetClientTeam(client) == 3 && !WardenPicked) BecomeWardenMenu(client);
	if(HnsEnabled && GetClientTeam(client) == 2 && !IsHnsClient[client]) { ++HnsCount; IsHnsClient[client] = true; }
}

// SHOW COMMANDER MENU ON ROUND START
public Action:ShowCommanderMenu(Handle:Timer, any:data) 
{
	for (new i = 1; i <= MaxClients; i++)
	{	
	if(IsValidClient(i))
	{
		BecomeWarden[i] = false;
		
		if(GetClientTeam(i) == 3) {
			BecomeWardenMenu(i);
		}
	}
	}
	return Plugin_Handled;
}

// RANDOM PICK WARDEN
public Action:PickWarden(Handle:Timer, any:data) 
{
	if(Warden == -1)
	{
		iNumClients = 0;
	
		for(new i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && BecomeWarden[i])
			{
			iClients[iNumClients++] = i;
			}
		}
	
		if(iNumClients != 0)
		{
			new iRandomClient = iClients[GetRandomInt(0, iNumClients-1)];
			SetTheWarden(iRandomClient);
			WardenPicked = true;
		}

		if(Warden == -1)
		{
			PrintToChatAll(" \x06* \x01Nobody has chosen to become commander, type \x06!c \x01in chat to claim the position");
			WardenPicked = true;
		}
	}
	return Plugin_Handled;
}

/*
 * ----------------------------------------
 *   ____   __  __   _____   _   _   _   _ 
 *  / ___| |  \/  | | ____| | \ | | | | | |
 * | |     | |\/| | |  _|   |  \| | | | | |
 * | |___  | |  | | | |___  | |\  | | |_| |
 *  \____| |_|  |_| |_____| |_| \_|  \___/ 
 *
 * -----------------------------------------                                         
 */

 // WARDEN MENU (sm_cmenu | sm_wmenu | sm_misc)
public Action:Command_WardenMenu(client,args)
{	
	new Handle:menu = CreateMenu(WardenMenuHandler);
	if(client == Warden) 
	{
		if(CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))
		SetMenuTitle(menu, "Warden Menu | ADMIN");
		else SetMenuTitle(menu, "Warden Menu");
		if(!(HnsEnabled || WarEnabled || FreezeEnabled)) AddMenuItem(menu, "days", "Special Days");
		if(CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true) && (HnsEnabled || WarEnabled || FreezeEnabled)) AddMenuItem(menu, "abortdays", "Abort Special Day");
		AddMenuItem(menu, "cells", "Cell Management");
		if(!(HnsEnabled || WarEnabled || FreezeEnabled)) AddMenuItem(menu, "noblock", "Toggle NoBlock");
		if(!(HnsEnabled || WarEnabled || FreezeEnabled)) AddMenuItem(menu, "freeday", "Give Player Freeday");
		if(!(HnsEnabled || WarEnabled || FreezeEnabled)) AddMenuItem(menu, "color", "Color Divide Players");
		if(!(HnsEnabled || WarEnabled || FreezeEnabled)) AddMenuItem(menu, "random", "Pick Random Player");
		if(CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true)) AddMenuItem(menu, "switchrandom", "Remove Random CT");
		AddMenuItem(menu, "marker", "Place Marker");
		AddMenuItem(menu, "retire", "Retire");
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	} 
	else if(CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))
	{
		SetMenuTitle(menu, "Warden Menu | ADMIN");
		if(!(HnsEnabled || WarEnabled || FreezeEnabled)) AddMenuItem(menu, "days", "Special Days");
		if(HnsEnabled || WarEnabled || FreezeEnabled) AddMenuItem(menu, "abortdays", "Abort Special Day");
		AddMenuItem(menu, "cells", "Cell Management");
		if(Warden != -1 && !(HnsEnabled || WarEnabled || FreezeEnabled)) AddMenuItem(menu, "noblock", "Toggle NoBlock");
		if(!(HnsEnabled || WarEnabled || FreezeEnabled)) AddMenuItem(menu, "freeday", "Give Player Freeday");
		AddMenuItem(menu, "switchrandom", "Remove Random CT");
		if(Warden == -1) AddMenuItem(menu, "setrandom", "Set Random Warden");
		if(Warden != -1) AddMenuItem(menu, "removewarden", "Fire Warden");
		if(Warden == -1) AddMenuItem(menu, "setwarden", "Set Warden");
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	} 
	else if(IsValidClient(client)) PrintToChat(client, " \x07* You must be warden to do that");
	
	return Plugin_Handled;
}

// WARDEN MENU HANDLER
public WardenMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if (action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, sizeof(info));

		if (strcmp(info,"cells") == 0 ) 
		{
			if(SJD_IsCurrentMapConfigured())
			{
			FakeClientCommand(client, "sm_cells");
			}
			else 
			{
			PrintToChat(client, " \x07* Cell management isn't configured for this map yet");
			FakeClientCommand(client, "sm_cmenu");
			}
		}
		else if (strcmp(info,"noblock") == 0) 
		{
			FakeClientCommand(client, "sm_noblock");
			FakeClientCommand(client, "sm_cmenu");
		}
		else if (strcmp(info,"freeday") == 0) 
		{
			FakeClientCommand(client, "sm_givefreeday");
		}
		else if (strcmp(info,"color") == 0) 
		{
			FakeClientCommand(client, "sm_colordivide");
			FakeClientCommand(client, "sm_cmenu");
		}
		else if (strcmp(info,"random") == 0) 
		{
			FakeClientCommand(client, "sm_random");
			FakeClientCommand(client, "sm_cmenu");
		}
		else if (strcmp(info,"switchrandom") == 0) 
		{
			FakeClientCommand(client, "sm_rrc");
			FakeClientCommand(client, "sm_cmenu");
		}
		else if (strcmp(info,"setrandom") == 0) 
		{
			FakeClientCommand(client, "sm_src");
			FakeClientCommand(client, "sm_cmenu");
		}
		else if (strcmp(info,"marker") == 0) 
		{
			PlaceMarker(client);
			FakeClientCommand(client, "sm_marker");
		}
		else if (strcmp(info,"retire") == 0) 
		{
			FakeClientCommand(client, "sm_uc");
		}	
		else if (strcmp(info,"removewarden") == 0) 
		{
			FakeClientCommand(client, "sm_rc");
			FakeClientCommand(client, "sm_cmenu");
		}
		else if (strcmp(info,"days") == 0) 
		{
			if(!CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true) && SpecialDayRounds < 5)
			{
			PrintToChat(client, " \x07* You must wait more rounds before starting a special day");
			FakeClientCommand(client, "sm_cmenu");
			} else FakeClientCommand(client, "sm_days");
		}
		else if (strcmp(info,"abortdays") == 0) 
		{
			FakeClientCommand(client, "sm_abortdays");
			FakeClientCommand(client, "sm_cmenu");
		}
		else if (strcmp(info,"setwarden") == 0) 
		{
			if(Warden == -1)
			{
				SetWardenMenu(client);
			}
			else
			{
			PrintToChat(client, " \x07* You must fire the current warden before setting a new one");
			FakeClientCommand(client, "sm_cmenu");
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// FREEDAY MENU (sm_givefreeday)
public Action:Command_GiveFreeday(client,args)
{
	if(HnsEnabled || WarEnabled || FreezeEnabled) {
	PrintToChat(client, " \x07* You don't have access to that command during a special day!");
	return Plugin_Handled;
	}
	
	new Handle:menu = CreateMenu(FreedayMenuHandler);
	SetMenuTitle(menu, "Give Player Freeday");
	if(client == Warden || CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true)) 
	{
		char target[50];
		int availabletargets = 0;
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !PlayerHasFreeday[i])		
			{
				GetClientName(i, target, sizeof(target));
				AddMenuItem(menu, target, target);
				++availabletargets;
			}
		}
		
		if(availabletargets == 0) {
		PrintToChat(client, " \x07* No available targets found. Either there are no prisoners, or all prisoners already has freedays.");
		return Plugin_Handled;
		}

		SetMenuExitBackButton(menu, true);
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
			
		
	} else PrintToChat(client, " \x07* You must be warden to do that");
	
	return Plugin_Handled;
}

// FREEDAY MENU HANDLER
public FreedayMenuHandler(Handle:menu, MenuAction:action, client, param2) 
{
	if (action == MenuAction_Select) 
	{
		char arg1[50];
		GetMenuItem(menu, param2, arg1, sizeof(arg1));
		int target = FindTarget(client, arg1, true, false);
		if (target != -1) 
		{
		if(client == Warden)
			PrintToChatAll(" \x06* \x01Warden \x06%N \x01has given \x06%N \x01a freeday", client, target);
		else if(CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))
			PrintToChatAll(" \x06* \x01ADMIN: \x06%N \x01has given \x06%N \x01a freeday", client, target);
			
		SetEntityRenderColor(target, 255, 255, 0, 255);
		PlayerHasFreeday[target] = true;
		}
		FakeClientCommand(client, "sm_givefreeday");
	}
	else if (action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack) { 
            FakeClientCommand(client, "sm_cmenu");
        } 
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// SET WARDEN MENU
public Action:SetWardenMenu(client)
{	
	new Handle:menu = CreateMenu(SetWardenMenuHandler);
	SetMenuTitle(menu, "Set Warden");
	
	char target[50];
	int availabletargets = 0;
		
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))		
		{
			GetClientName(i, target, sizeof(target));
			AddMenuItem(menu, target, target);
			++availabletargets;
		}
	}
		
	if(availabletargets == 0) {
	PrintToChat(client, " \x07* No available targets found. There must be at least 1 CT alive to set a warden");
	return Plugin_Handled;
	}
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

// SET WARDEN MENU HANDLER
public SetWardenMenuHandler(Handle:menu, MenuAction:action, client, param2) 
{
	if (action == MenuAction_Select) 
	{
		char arg1[50];
		GetMenuItem(menu, param2, arg1, sizeof(arg1));
		int target = FindTarget(client, arg1, true, false);
		if (target != -1) 
		{
			PrintToChatAll(" \x06* \x01ADMIN: \x06%N \x01has appointed \x06%N \x01to warden", client, target);
			WardenPicked = true;
			Warden = target;
			SetEntityRenderColor(target, 0, 0, 255, 255);
			SetClientListeningFlags(target, VOICE_NORMAL);
		}
		FakeClientCommand(client, "sm_cmenu");
	}
	else if (action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack) { 
            FakeClientCommand(client, "sm_cmenu");
        } 
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// BECOME WARDEN MENU TO DISPLAY AT ROUND START
public Action:BecomeWardenMenu(client)
{
	new Handle:menu = CreateMenu(BecomeWardenMenuHandler);
	SetMenuTitle(menu, "Do you wish to become warden?");
	AddMenuItem(menu, "", "By becoming warden you agree to having", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "read and agreed to our rules", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
	AddMenuItem(menu, "yes", "Confirm");
	AddMenuItem(menu, "no", "Exit");
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 4);
	
	return Plugin_Handled;
}

// BECOME WARDEN MENU HANDLER
public BecomeWardenMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if (action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, sizeof(info));

		if (strcmp(info,"yes") == 0 ) 
		{
			BecomeWarden[client] = true;
		}
		if (strcmp(info,"no") == 0 ) 
		{
			BecomeWarden[client] = false;
		}
	}
}
 
/*
 * ---------------------------------
 *  ____       _     __   __  ____  
 * |  _ \     / \    \ \ / / / ___| 
 * | | | |   / _ \    \ V /  \___ \ 
 * | |_| |  / ___ \    | |    ___) |
 * |____/  /_/   \_\   |_|   |____/ 
 * 
 * --------------------------------- 
 */

// DAYS MENU (sm_days)
public Action:Command_DaysMenu(client,args)
{
	if(HnsEnabled) {
	PrintToChat(client, " \x06* \x01Currently Playing: \x06Hide'n'Seek");
	return Plugin_Handled;
	} else if(WarEnabled) {
	PrintToChat(client, " \x06* \x01Currently Playing: \x06War");
	return Plugin_Handled;
	} else if(FreezeEnabled) {
	PrintToChat(client, " \x06* \x01Currently Playing: \x06Freeze Tag");
	return Plugin_Handled;
	}
	
	if(client == Warden && SpecialDayRounds < 5 && !CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true)) {
		PrintToChat(client, " \x07* You must wait more rounds before starting a special day");
		return Plugin_Handled;
	} 
	
	new Handle:menu = CreateMenu(DaysMenuHandler);
	if(client == Warden) 
	{
		SetMenuTitle(menu, "Days Menu");
		AddMenuItem(menu, "grav", "Gravity Freeday");
		AddMenuItem(menu, "hns", "Hide'n'Seek");
		AddMenuItem(menu, "war", "War Day");
		if(CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true)) AddMenuItem(menu, "freeze", "Freeze Tag");
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	} else if(CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))
	{
		SetMenuTitle(menu, "Days Menu | ADMIN");
		AddMenuItem(menu, "grav", "Gravity Freeday");
		AddMenuItem(menu, "hns", "Hide'n'Seek");
		AddMenuItem(menu, "war", "War Day");
		AddMenuItem(menu, "freeze", "Freeze Tag");
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else PrintToChat(client, " \x07* You must be warden to do that");
	
	return Plugin_Handled;
}

// DAYS MENU HANDLER
public DaysMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if (action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		if (strcmp(info,"grav") == 0 ) 
		{
			PrintToChatAll(" \x06* \x01Gravity freeday started, have fun!");
			SetCvar("sv_gravity", "300");
			SpecialDayRounds = 0;
		}
		else if (strcmp(info,"hns") == 0 ) 
		{
			int availabletargets = 0;
		
			for (new i = 1; i <= MaxClients; i++)
			{
			if(IsValidClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))		
			{
			++availabletargets;
			}
			}
			
			if(availabletargets >= 10 || availabletargets >= 0 && CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))
			{
			WinnersMenu(client);
			}
			else if(CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))
			{
			PrintToChat(client, " \x07* You need at least 2 prisoners to start Hide'n'Seek");
			FakeClientCommand(client, "sm_days");
			}
			else
			{
			PrintToChat(client, " \x07* You need at least 10 prisoners to start Hide'n'Seek");
			FakeClientCommand(client, "sm_days");
			}
		}
		else if (strcmp(info,"war") == 0) 
		{
			int availabletargets = 0;
		
			for (new i = 1; i <= MaxClients; i++)
			{
			if(IsValidClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))		
			{
			++availabletargets;
			}
			}
			
			if(availabletargets >= 4 || availabletargets >= 2 && CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))
			{
			StartWar();
			}
			else if(CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))
			{
			PrintToChat(client, " \x07* You need at least 2 prisoners to start a War Day");
			FakeClientCommand(client, "sm_days");
			}
			else
			{
			PrintToChat(client, " \x07* You need at least 4 prisoners to start a War Day");
			FakeClientCommand(client, "sm_days");
			}
		}
		else if (strcmp(info,"freeze") == 0) 
		{
			int availabletargets = 0;
		
			for (new i = 1; i <= MaxClients; i++)
			{
			if(IsValidClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))		
			{
			++availabletargets;
			}
			}
			
			if(availabletargets >= 6 || availabletargets >= 2 && CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))
			{
			StartFreeze();
			}
			else if(CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))
			{
			PrintToChat(client, " \x07* You need at least 2 prisoners to start Freeze Tag");
			FakeClientCommand(client, "sm_days");
			}
			else
			{
			PrintToChat(client, " \x07* You need at least 6 prisoners to start Freeze Tag");
			FakeClientCommand(client, "sm_days");
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

/*
 * ----------------------
 *  _   _   _   _   ____  
 * | | | | | \ | | / ___| 
 * | |_| | |  \| | \___ \ 
 * |  _  | | |\  |  ___) |
 * |_| |_| |_| \_| |____/ 
 *
 * -----------------------                      
 */
 
// START HIDE'N'SEEK
public StartHNS()
{
	if(!HnsEnabled) 
	{
		HnsEnabled = true;
		DamageProtection = true;
		TimerUsed = false;
		TimerUsed2 = false;
		SpecialDayRounds = 0;
		HnsCount = 0;
		iTimer = 40;
		PrintToChatAll(" \x06* \x01Hide'n'Seek countdown started, run and hide!");
		PrintToChatAll(" \x06* \x01You have 40 seconds to hide, there will be %d winner(s)", HnsWinners);
		CreateTimer(1.0, Timer_HnS, _, TIMER_REPEAT);
		CreateTimer(0.2, Timer_HnsSettings);
		SJD_OpenDoors();
		
		SetCvar("sm_show_activity", "0");
		SetCvar("mp_solid_teammates", "0");
		SetCvar("mp_forcecamera", "1");
		SetCvar("sm_hosties_lr", "0");
	}
}

// HNS START SETTINGS
public Action:Timer_HnsSettings(Handle:Timer, any:data) 
{
	for (new i = 1; i <= MaxClients; i++)
	{
	if(IsValidClient(i))
	{
		if(GetClientTeam(i) == 1 && !CheckCommandAccess(i, "sm_slay", ADMFLAG_GENERIC, true) && !IsClientSourceTV(i))
			ChangeClientTeam(i, 2);
		
		if(GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			RemoveAllWeapons(i);
			int weapon = GetPlayerWeaponSlot(i, CS_SLOT_KNIFE);
			if (weapon == -1) {		
				GivePlayerItem(i, "weapon_knife");
			}
			
			IsHnsClient[i] = true;
			++HnsCount;
		}
			
		if(GetClientTeam(i) == 3 && IsPlayerAlive(i) && i != Warden)
		{
			SetEntityMoveType(i, MOVETYPE_NONE);
			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 0.0);
			ServerCommand("sm_blind %N 5000", i);
		}
	}
	}
		
	return Plugin_Handled;
}

// SHOW ALIVE PLAYERS WHILST PLAYING
public Action:Timer_HnSHUD(Handle:Timer, any:data) 
{
	if(HnsEnabled)
	{
	if(TimerUsed && HnsCount <= HnsWinners && !TimerUsed2) 
	{
		TimerUsed2 = true;
		PrintToChatAll(" \x06* \x01Hide'n'seek finished, congratulations to the winners!");
		HnsEnabled = false;
		HnsCount = 0;
		SetCvar("mp_forcecamera", "0");
		SetCvar("sm_hosties_lr", "1");
		
		PrintCenterTextAll("Hide'n'Seek finished!");

		return Plugin_Stop;
	}
	else if(TimerUsed && HnsCount > HnsWinners && !TimerUsed2)
	{
		int TotalHnsCount = 0; 
		SetCvar("sm_show_activity", "13");
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && GetClientTeam(i) == 2)		
			{
				++TotalHnsCount;
			}
		}
		
		PrintCenterTextAll("%d/%d alive | %d winner(s)", HnsCount, TotalHnsCount, HnsWinners);
		
		return Plugin_Continue;
	}
	}
	return Plugin_Stop;
}

// TIME UNTIL STARTING ROUND
public Action:Timer_HnS(Handle:Timer, any:data) 
{
	if(HnsEnabled)
	{
	if(iTimer == 0 && !TimerUsed) 
	{
		TimerUsed = true;
		int TotalHnsCount = 0; 
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && GetClientTeam(i) == 2)		
			{
				++TotalHnsCount;
			}
		}
		PrintToChatAll(" \x06* \x01Ready or not, here we come!");
		PrintToChatAll(" \x06* \x01There will be \x06%d winner(s) \x01amongst %d players", HnsWinners, TotalHnsCount);
		CreateTimer(0.5, Timer_HnSHUD, _, TIMER_REPEAT);
		CreateTimer(10.0, Timer_DisableProtection, _, TIMER_REPEAT);
			
		for (new i = 1; i <= MaxClients; i++)
		{
		if(IsValidClient(i) && IsPlayerAlive(i))
		{
			if(GetClientTeam(i) == 3)
			{
				SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
				SetEntityMoveType(i, MOVETYPE_WALK);
				SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
				ServerCommand("sm_blind %N", i);
			}
		}
		}
			
		return Plugin_Stop;
	}
	else if(iTimer != 0 && !TimerUsed)
	{		
		for (new i = 1; i <= MaxClients; i++)
		{
		if(IsValidClient(i) && IsPlayerAlive(i))
		{
			if(GetClientTeam(i) == 2)
			{
				int weapon = GetPlayerWeaponSlot(i, CS_SLOT_KNIFE);
				if (weapon == -1) {		
				GivePlayerItem(i, "weapon_knife");
				}
			}
		}
		}
		
		iTimer--;

		PrintCenterTextAll("Hide'n'Seek starting in %02i:%02i", iTimer / 60, iTimer % 60);
		
		return Plugin_Continue;
	}
	}
	return Plugin_Stop;
} 

public Action:Timer_DisableProtection(Handle timer)
{
	DamageProtection = false;
}
 
// CHOOSE HNS WINNERS
public Action:WinnersMenu(client)
{
	int availabletargets = 0;
		
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))		
			++availabletargets;
	}
			
	new Handle:menu = CreateMenu(WinnersMenuHandler);
	SetMenuTitle(menu, "Choose winners");
	if(client == Warden || CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true)) 
	{
		if(availabletargets < 25 || CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true)) AddMenuItem(menu, "1", "1");
		if((availabletargets >= 12 && availabletargets < 32) || (availabletargets >= 3 && CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))) AddMenuItem(menu, "2", "2");
		if(availabletargets >= 18 || (availabletargets >= 6 && CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))) AddMenuItem(menu, "3", "3");
		if(availabletargets >= 30 || (availabletargets >= 10 && CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))) AddMenuItem(menu, "4", "4");
		if(availabletargets >= 35 || (availabletargets >= 15 && CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true))) AddMenuItem(menu, "5", "5");
		SetMenuExitBackButton(menu, true);
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	} else PrintToChat(client, " \x07* You must be warden to do that");
	
	return Plugin_Handled;
}

// CHOOSE HNS WINNERS HANDLER
public WinnersMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if (action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, sizeof(info));

		if (strcmp(info,"1") == 0 ) 
		{
			HnsWinners = 1;
			StartHNS();
		}
		else if (strcmp(info,"2") == 0) 
		{
			HnsWinners = 2;
			StartHNS();
		}
		else if (strcmp(info,"3") == 0) 
		{
			HnsWinners = 3;
			StartHNS();
		}
		else if (strcmp(info,"4") == 0) 
		{
			HnsWinners = 4;
			StartHNS();
		}
		else if (strcmp(info,"5") == 0) 
		{
			HnsWinners = 5;
			StartHNS();
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack) { 
            FakeClientCommand(client, "sm_days");
        } 
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}


/*
 * -------------------------------------------------------------------
 *  _____                                       _____                 
 * |  ___|  _ __    ___    ___   ____   ___    |_   _|   __ _    __ _ 
 * | |_    | '__|  / _ \  / _ \ |_  /  / _ \     | |    / _` |  / _` |
 * |  _|   | |    |  __/ |  __/  / /  |  __/     | |   | (_| | | (_| |
 * |_|     |_|     \___|  \___| /___|  \___|     |_|    \__,_|  \__, |
 *                                                              |___/ 
 *
 * --------------------------------------------------------------------
 */

// START FREEZETAG
public StartFreeze()
{
	if(!FreezeEnabled) 
	{
		FreezeEnabled = true;
		DamageProtection = true;
		TimerUsed = false;
		SpecialDayRounds = 0;
		FreezeCount = 0;
		TotalFreezeCount = 0;
		iTimer = 600;
		PrintToChatAll(" \x06* \x01Freeze Tag initiated, run!");
		PrintToChatAll(" \x06* \x01CT has 10 minutes to hunt down all the terrorists");
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))		
			{
				IsFreezed[i] = false;
				++TotalFreezeCount;
			}
			
			if(IsValidClient(i) && IsPlayerAlive(i))
			{
				RemoveAllWeapons(i);
				int weapon = GetPlayerWeaponSlot(i, CS_SLOT_KNIFE);
				if (weapon == -1) {		
					GivePlayerItem(i, "weapon_knife");
				}
			}
		}
		CreateTimer(1.0, Timer_Freeze, _, TIMER_REPEAT);
		SJD_OpenDoors();

		SetCvar("mp_solid_teammates", "0");
		SetCvar("mp_friendlyfire", "1");
		SetCvar("sm_hosties_lr", "0");
	}
}

// FREEZE TAG HUD
public Action:Timer_Freeze(Handle:Timer, any:data) 
{
	if(FreezeEnabled)
	{
	if(iTimer == 0 && !TimerUsed || FreezeCount == TotalFreezeCount) 
	{
		TimerUsed = true;
		SetCvar("mp_friendlyfire", "0");
		SetCvar("sm_hosties_lr", "1");
		
		if(FreezeCount == TotalFreezeCount)
		{
			for (new i = 1; i <= MaxClients; i++)
				if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
					ForcePlayerSuicide(i);

			PrintToChatAll(" \x06* \x01Congratulations, CT's win!");
		} else {
			for (new i = 1; i <= MaxClients; i++)
				if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
					ForcePlayerSuicide(i);

			PrintToChatAll(" \x06* \x01Time is up, CT's lose!");
		}
			
		return Plugin_Stop;
	}
	else if(iTimer != 0 && !TimerUsed)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
		if(IsValidClient(i) && IsPlayerAlive(i))
		{
				int weapon = GetPlayerWeaponSlot(i, CS_SLOT_KNIFE);
				if (weapon == -1) {		
				GivePlayerItem(i, "weapon_knife");
				}
		}
		}

		PrintCenterTextAll("%d/%d caught | %02i:%02i", FreezeCount, TotalFreezeCount, iTimer / 60, iTimer % 60);
	
		iTimer--;

		return Plugin_Continue;
	}
	}
	return Plugin_Stop;
}

/*
 * --------------------------------
 * __        __     _      ____  
 * \ \      / /    / \    |  _ \ 
 *  \ \ /\ / /    / _ \   | |_) |
 *   \ V  V /    / ___ \  |  _ < 
 *    \_/\_/    /_/   \_\ |_| \_\
 *
 * --------------------------------                              
 */

 // START WARDAY
public StartWar()
{
	if(!WarEnabled) 
	{
		WarEnabled = true;
		DamageProtection = true;
		SpecialDayRounds = 0;
		PrintToChatAll(" \x06* \x01Warday will start in 30 seconds!");
		PrintToChatAll(" \x07* Everyone must actively participate in the warday!");
		CreateTimer(30.0, Timer_War);
		CreateTimer(0.2, Timer_WarSettings);
		SJD_OpenDoors();

		SetCvar("mp_solid_teammates", "0");
		SetCvar("sm_hosties_lr", "0");
	}
}

// OPEN GUN MENU
public Action:Timer_WarSettings(Handle:Timer, any:data) 
{		
		for (new i = 1; i <= MaxClients; i++)
		{
		if(IsValidClient(i))
		{
			if(GetClientTeam(i) == 2)
			{
				SetEntityMoveType(i, MOVETYPE_NONE);
				SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 0.0);
				RemoveAllWeapons(i);
			}
			
			if(IsPlayerAlive(i))
			{
				Menu_PrimaryWeapon(i);
			}
		}
		}
			
		return Plugin_Handled;
}

// TIME UNTIL STARTING ROUND
public Action:Timer_War(Handle:Timer, any:data) 
{
	if(WarEnabled)
	{
		PrintToChatAll(" \x06* \x01Warday has begun, last team standing wins!");
		DamageProtection = false;	
		
		for (new i = 1; i <= MaxClients; i++)
		{
		if(IsValidClient(i))
		{
			if(GetClientTeam(i) == 2)
			{
				SetEntityMoveType(i, MOVETYPE_WALK);
				SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
			}
		}
		}
	}
	return Plugin_Handled;
}

// PRIMARY WEAPON MENU
Menu BuildPrimaryMenu()
{
	Menu menu = new Menu(MenuHandler1);

	menu.SetTitle("Choose Primary Weapon:");
	menu.AddItem("1", "M4A4 / AK-47");
	menu.AddItem("2", "M4A1-S / AK-47");
	menu.AddItem("3", "Galil AR / Famas");
	menu.AddItem("4", "UMP-45");
	menu.AddItem("5", "AWP");

	return menu;
}

// DISPLAY PRIMARY WEAPON MENU
public Action Menu_PrimaryWeapon(int client)
{
	if(!WarEnabled) {
	PrintToChat(client, " \x07* It's not a warday!");
	return Plugin_Handled;
	}
	
	g_PrimaryMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

// PRIMARY WEAPON HANDLER
public int MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		PrimaryChoice[param1] = param2;
		g_SecondaryMenu.Display(param1, MENU_TIME_FOREVER);
	}
}

// SECONDARY WEAPON MENU
Menu BuildSecondaryMenu()
{
	Menu menu = new Menu(MenuHandler2);

	menu.SetTitle("Choose Secondary Weapon:");
	menu.AddItem("1", "P2000 / Glock");
	menu.AddItem("2", "USP-S / Glock");
	menu.AddItem("3", "Dual Berettas");
	menu.AddItem("4", "P250");
	menu.AddItem("5", "Tec-9 / Five-SeveN");
	menu.AddItem("6", "Deagle");

	return menu;
}

// DISPLAY SECONDARY WEAPON MENU
public Action Menu_SecondaryWeapon(int client, int args)
{
	g_SecondaryMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

// SECONDARY WEAPON HANDLER
public int MenuHandler2(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		SecondaryChoice[param1] = param2;
		GiveEquipment(param1);
	}
}

// GIVE WEAPONS
public Action GiveEquipment(int client)
{
	if(IsValidClient(client))
	{
		RemoveAllWeapons(client);
		switch(PrimaryChoice[client])
		{
			case 0:
			{
				switch(GetClientTeam(client))
				{
					case CS_TEAM_T:		GivePlayerItem(client, "weapon_ak47");
					case CS_TEAM_CT:	GivePlayerItem(client, "weapon_m4a1");
				}
			}
			case 1:
			{
				switch(GetClientTeam(client))
				{
					case CS_TEAM_T:		GivePlayerItem(client, "weapon_ak47");
					case CS_TEAM_CT:	GivePlayerItem(client, "weapon_m4a1_silencer");
				}
			}
			case 2:
			{
				switch(GetClientTeam(client))
				{
					case CS_TEAM_T:		GivePlayerItem(client, "weapon_galilar");
					case CS_TEAM_CT:	GivePlayerItem(client, "weapon_famas");
				}
			}
			case 3:	GivePlayerItem(client, "weapon_ump45");
			case 4:	GivePlayerItem(client, "weapon_awp");
		}

		switch(SecondaryChoice[client])
		{
			case 0:
			{
				switch(GetClientTeam(client))
				{
					case CS_TEAM_T:		GivePlayerItem(client, "weapon_glock");
					case CS_TEAM_CT:	GivePlayerItem(client, "weapon_hkp2000");
				}
			}
			case 1:
			{
				switch(GetClientTeam(client))
				{
					case CS_TEAM_T:		GivePlayerItem(client, "weapon_glock");
					case CS_TEAM_CT:	GivePlayerItem(client, "weapon_usp_silencer");
				}
			}
			case 2:	GivePlayerItem(client, "weapon_elite");
			case 3:	GivePlayerItem(client, "weapon_p250");
			case 4:
			{
				switch(GetClientTeam(client))
				{
					case CS_TEAM_T:		GivePlayerItem(client, "weapon_tec9");
					case CS_TEAM_CT:	GivePlayerItem(client, "weapon_fiveseven");
				}
			}
			case 5:	GivePlayerItem(client, "weapon_deagle");
		}

		switch(GetRandomInt(0, 10))
		{
			case 2:	GivePlayerItem(client, "weapon_hegrenade");
			case 9:	GivePlayerItem(client, "weapon_smokegrenade");
		}
		
		switch(GetRandomInt(0, 1))
		{
			case 1:	GivePlayerItem(client, "weapon_flashbang");
		}

		GivePlayerItem(client, "weapon_knife");
		GivePlayerItem(client, "item_assaultsuit");
	}
}

/*
 * ---------------------------------------
 *   ___    _____   _   _   _____   ____  
 *  / _ \  |_   _| | | | | | ____| |  _ \ 
 * | | | |   | |   | |_| | |  _|   | |_) |
 * | |_| |   | |   |  _  | | |___  |  _ < 
 *  \___/    |_|   |_| |_| |_____| |_| \_\
 * 
 * ---------------------------------------- 
 */

// WARDEN CHATTAG
public Action:CCC_OnColor(client)
{
	if(Warden == client && client != 0 && IsPlayerAlive(client))
	{
		char commandertag[20];
		Format(commandertag, sizeof(commandertag), "\x06COMMANDER\x01 ");
		CCC_SetTag(client, commandertag);
	}
	
	return Plugin_Continue;
}

// ADD WARDEN
public SetTheWarden(client)
{
	PrintToChatAll(" \x06* %N \x01has become the warden of this prison", client);
	WardenPicked = true;
	Warden = client;
	SetEntityRenderColor(client, 0, 0, 255, 255);
	SetClientListeningFlags(client, VOICE_NORMAL);
	PrintToChat(client, " \x07* Type !cmenu or !wmenu in chat to open up the warden menu");
}

// REMOVE WARDEN
public RemoveTheWarden(client)
{
	PrintToChatAll(" \x06* \x01ADMIN: \x06%N \x01has fired \x06%N \x01from warden", client, Warden);
	SetEntityRenderColor(Warden, 255, 255, 255, 255);
	Warden = -1;
}

// SET CVAR
stock SetCvar(String:scvar[], String:svalue[])
{
    new Handle:cvar = FindConVar(scvar);
    SetConVarString(cvar, svalue, true);
}

// REMOVE ALL WEAPONS
void RemoveAllWeapons(int client)
{
	if(IsValidClient(client))
	{
		int ent;
		for(int i; i < 4; i++)
		{
			if((ent = GetPlayerWeaponSlot(client, i)) != -1)
			{
				RemovePlayerItem(client, ent);
				RemoveEdict(ent);
			}
		}
	}
}

// CHECK IF CLIENT IS VALID
bool IsValidClient(int client)
{
	return (0 < client <= MaxClients && IsClientInGame(client));
}

// GET CLIENT AIM POSITION
int GetClientAimTargetPos(int client, float pos[3]) 
{
	if (!client) 
		return -1;
	
	float vAngles[3]; float vOrigin[3];
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilterAllEntities, client);
	
	TR_GetEndPosition(pos, trace);
	pos[2] += 5.0;
	
	int entity = TR_GetEntityIndex(trace);
	
	CloseHandle(trace);
	
	return entity;
}

// RESET MARKERS
void ResetMarker()
{
	for(int i = 0; i < 3; i++)
		g_fMakerPos[i] = 0.0;
}

// TRACE ENTITIES
public bool TraceFilterAllEntities(int entity, int contentsMask, any client)
{
	if (entity == client)
		return false;
	if (entity > MaxClients)
		return false;
	if(!IsClientInGame(entity))
		return false;
	if(!IsPlayerAlive(entity))
		return false;
	
	return true;
}

// DRAW THE ACTUAL MARKER
public Action Timer_DrawMakers(Handle timer, any data)
{
	Draw_Markers();
	return Plugin_Continue;
}

// DRAW THE ACTUAL MARKER
void Draw_Markers()
{	
	if (g_fMakerPos[0] == 0.0)
		return;
	
	TE_SetupBeamRingPoint(g_fMakerPos, 155.0, 155.0+0.3, g_iBeamSprite, g_iHaloSprite, 0, 10, 1.0, 6.0, 0.0, g_MarkerColor, 2, 0);
	TE_SendToAll();
}

public Action Command_WardenLaserOn(int client, int args)
{
	if((client == Warden || CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true)) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
		LaserEnabled[client] = true;
	else if(!IsPlayerAlive(client))
		PrintToChat(client, " \x07* You must be alive to do that");
	else if(GetClientTeam(client) != 3)
		PrintToChat(client, " \x07* You must be CT to do that");
	else PrintToChat(client, " \x07* You must be warden to do that");
	
	return Plugin_Handled;
}

public Action Command_WardenLaserOff(int client, int args)
{
	LaserEnabled[client] = false;
	return Plugin_Handled;
}

// WARDEN LASER POINTER
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) 
{    
	
	if((client == Warden || CheckCommandAccess(client, "sm_slay", ADMFLAG_GENERIC, true)) && LaserEnabled[client] && IsPlayerAlive(client) && GetClientTeam(client) == 3) 
	{
		float origin[3], end[3], fwd[3];
		
		GetClientEyePosition(client, origin);
		
		GetAngleVectors(angles, fwd, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(fwd, 10000.0);
		end = origin;
		AddVectors(end, fwd, end);
		TR_TraceRayFilter(origin, end, MASK_ALL, RayType_EndPoint, NotMeFilter, client);
		
		if (TR_DidHit())
		{
			TR_GetEndPosition(end);
		}
		
		new color[4] =  { 156, 244, 70, 128 };
		TE_SetupBeamPoints(origin, end, g_iBeamSprite, 0, 0, 0, 0.1, 0.6, 0.6, 10, 0.0, color, 0);
		TE_SendToAll();
	} else LaserEnabled[client] = false;

	return Plugin_Continue;
} 

// WARDEN LASER FILTER
public bool NotMeFilter(int entity, int contentsMask, any data) 
{ 
    return entity != data; 
} 

// DISABLE PICKING UP WEAPONS
public Action:OnWeaponEquip(client, weapon) 
{
	decl String:sWeapon[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
	if(HnsEnabled)
	{
		if(StrEqual(sWeapon, "weapon_knife") || StrEqual(sWeapon, "weapon_hegrenade") || StrEqual(sWeapon, "weapon_taser") || StrEqual(sWeapon, "weapon_molotov") || StrEqual(sWeapon, "weapon_smokegrenade") || StrEqual(sWeapon, "weapon_incgrenade") || StrEqual(sWeapon, "weapon_decoy") || StrEqual(sWeapon, "weapon_flashbang"))
			return Plugin_Continue; 
		else if(GetClientTeam(client) == 2) 
			return Plugin_Handled; 
	}
	
	if(FreezeEnabled)
	{
		if(StrEqual(sWeapon, "weapon_knife"))
			return Plugin_Continue; 	
		else return Plugin_Handled;
	}
	
	if (StrEqual(sWeapon, "weapon_negev") || StrEqual(sWeapon, "weapon_scar20") || StrEqual(sWeapon, "weapon_g3sg1") || StrEqual(sWeapon, "weapon_m249"))
    {
		if(HnsEnabled && GetClientTeam(client) == 3 
		|| WarEnabled || IsClientInLastRequest(client) || IsClientRebel(client)) 
		{
			return Plugin_Continue; 
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

// GUN PLANT PREVENTION
public Action:CS_OnCSWeaponDrop(client, weapon)
{
	if (IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		new Handle:data = CreateDataPack();
		WritePackCell(data, client);
		WritePackCell(data, weapon);

		CreateTimer(1.337, Timer_GunPlantPrevention, data);
	}
}

// GUN PLANT PREVENTION TIMER
public Action:Timer_GunPlantPrevention(Handle:timer, any:data)
{
	ResetPack(data);
	new original_owner = ReadPackCell(data);
	new weapon = ReadPackCell(data);
	
	if (!IsValidEdict(weapon) || !IsClientInGame(original_owner) || !IsPlayerAlive(original_owner))
		return Plugin_Stop;
		
	new new_owner = GetEntPropEnt(weapon, Prop_Data, "m_hOwnerEntity");
	if (new_owner == -1 || original_owner == -1)
		return Plugin_Stop;
	
	char oname[60], nname[60], wep[32];
	GetClientName(original_owner, oname, sizeof(oname));
	GetClientName(new_owner, nname, sizeof(nname));
	GetEdictClassname(weapon, wep, sizeof(wep));
	
	if(StrEqual(wep, "weapon_c4") || StrEqual(wep, "weapon_knife"))
		return Plugin_Handled;
	
	if (IsClientInGame(new_owner) && GetClientTeam(new_owner) != GetClientTeam(original_owner) && !IsClientInLastRequest(original_owner))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if(CheckCommandAccess(i, "sm_slay", ADMFLAG_GENERIC, true))
				PrintToChat(i, " \x06* %s \x01suspected for gunplanting \x06%s \x01with \x06%s", oname, nname, wep);
		}
	}
	return Plugin_Handled;
}

// TARGET WARDEN
public bool:ProcessWarden(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && Warden == i)
			PushArrayCell(clients, i);
	}
	return true;
}

// TARGET EVERYONE BUT WARDEN
public bool:ProcessNotWarden(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && Warden != i && !GetAdminFlag(GetUserAdmin(i), Admin_Generic))
			PushArrayCell(clients, i);
	}
	return true;
}