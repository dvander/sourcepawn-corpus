//──────────────────────────────────────────────────────────────────────────────
/*
	Copyright 2006-2013 AlliedModders LLC
	Copyright 2008-2013 pheadxdll http://forums.alliedmods.net/member.php?u=38829
	Copyright 2012 X3Mano https://forums.alliedmods.net/member.php?u=170871
	Copyright 2013 Mitchell http://forums.alliedmods.net/member.php?u=74234
	Copyright 2013 avi9526 <dromaretsky@gmail.com>
	Copyright 2013 FlaminSarge http://forums.alliedmods.net/member.php?u=84304
*/
//──────────────────────────────────────────────────────────────────────────────
/*
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
//──────────────────────────────────────────────────────────────────────────────
#pragma semicolon	1
//──────────────────────────────────────────────────────────────────────────────
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
//──────────────────────────────────────────────────────────────────────────────
#define PLUGIN_VERSION "2.0.5"
//──────────────────────────────────────────────────────────────────────────────
// Amount of effects
#define EFFECTS		18
// Used separating spells and canteen charges
// Increment is NOT +1, but binary shifting
#define SPELL		1	// spell
#define CHARGE		2	// canteen charge
#define BUILD		4	// building
#define ALL			7	// any
// Spell codes
// Currently not all spells used
#define FIREBALL	0
#define BATS 		1
//#define PUMPKIN 	2	// not working properly
#define TELE 		3
#define LIGHTNING 	4
#define BOSS 		5
#define METEOR 		6
//#define ZOMBIEH 	7	// not working properly
#define ZOMBIE 		8
//#define PUMPKIN2 	9	// useless
// Canteen charge codes
#define UBER		0	// uber charge
#define CRIT 		1	// critical charge
#define REGEN	 	2	// refill ammo and health
#define INVIS 		3	// become invisible
#define BASE	 	4	// teleport to base
#define SPEED 		5	// super speed
#define HEAL 		6	// add health
// Building codes
#define SENTRY		0	// sentry
#define DISP 		1	// dispenser
#define KILLSENTRY 	2	// kill all owned sentries
#define KILLDISP 	3	// kill all owned dispensers
//──────────────────────────────────────────────────────────────────────────────
// Max used stings length
#define STR_LEN		100
//──────────────────────────────────────────────────────────────────────────────
// Sounds
//#define SOUND_HEAL		"weapons/vaccinator_heal.wav"
//──────────────────────────────────────────────────────────────────────────────
#define LOG_PREFIX		"[Effects]"
#define CHAT_PREFIX		"\x01[\x07B262FFEffects\x01]"
#define SPELL_PREFIX	"\x01[\x07B262FFSpells\x01]"
#define CHARGE_PREFIX	"\x01[\x07B262FFCanteen\x01]"
#define BUILD_PREFIX	"\x01[\x07B262FFBuilding\x01]"
//──────────────────────────────────────────────────────────────────────────────
public Plugin:myinfo = 
{
	name = "[TF2] Spells",
	author = "Mitch (spells) & avi9526 (menu). See source code for more details",
	description = "Allows players to use some effects",
	version = PLUGIN_VERSION,
	url = "/dev/null"
}
//──────────────────────────────────────────────────────────────────────────────
// Global variables
//──────────────────────────────────────────────────────────────────────────────
new Handle:	hVersion;

new			BuildLimit;
new Handle:	hBuildLimit;

// Store individual player data needed to plugin
enum PlayerData
{
	TimeUsed[EFFECTS]	// when player last time used spell
};

// Effect info
enum Effect
{
	// Identifier
			ID,
	// Group ID (for separation of spells and canteen charges)
			GID,
	// Name
	String:	Name[STR_LEN],
	// Description
	String:	Desc[STR_LEN],
	// Global Handle Console Variable - Delay
	Handle:	hDelay,
	// Delay
			Delay,
	// CVar name
	String:	DelayCVar[STR_LEN]
};
// Array that store info about all available spells and canteen charges
new	Effects[EFFECTS][Effect];

// Array
new Players[MAXPLAYERS+1][PlayerData];
//──────────────────────────────────────────────────────────────────────────────
// Hook functions
//──────────────────────────────────────────────────────────────────────────────
public OnPluginStart()
{
	hVersion = CreateConVar("sm_spells_version", PLUGIN_VERSION, "Spells Version", FCVAR_PLUGIN | FCVAR_NOTIFY);
	if(hVersion != INVALID_HANDLE)
	{
		SetConVarString(hVersion, PLUGIN_VERSION);
	}
	
	HookEvent("player_team", Event_PlayerChangeTeam, EventHookMode_Post);
	
	InitEffectsData();
	
	for(new i = 0; i < EFFECTS; i++)
	{
		Effects[i][hDelay] = CreateConVar(Effects[i][DelayCVar], "60", "How much player must wait before use effect again", _, true, 1.0, false, 100.0);
		Effects[i][Delay] = GetConVarInt(Effects[i][hDelay]);
		HookConVarChange(Effects[i][hDelay], OnConVarChanged);
	}
	
	hBuildLimit = CreateConVar("sm_buildlimit", "1", "Limit amount of one kind of building that are available for player", _, true, 1.0, true, 10.0);
	BuildLimit = GetConVarInt(hBuildLimit);
	HookConVarChange(hBuildLimit, OnConVarChanged);
	
	// Effects menu
	RegConsoleCmd("sm_spells", Command_Menu, "Spells menu");
	RegConsoleCmd("sm_spell", Command_Menu, "Spells menu");
	RegConsoleCmd("sm_canteen", Command_Menu, "Canteen charges menu");
	RegConsoleCmd("sm_build", Command_Menu, "Building menu");
	RegConsoleCmd("sm_effects", Command_MainMenu, "Spells and Canteen charges menu");
	RegConsoleCmd("sm_effect", Command_MainMenu, "Spells and Canteen charges menu");
}
//──────────────────────────────────────────────────────────────────────────────
// Destroy all building when player change team, because game won't do this
public Action:Event_PlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetEventInt(event,"userid");
	KillAllDisp(Client);
	KillAllSentry(Client);
	return Plugin_Continue;
}
//──────────────────────────────────────────────────────────────────────────────
// If console variable changed - need change corresponding internal variables
public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == hBuildLimit)
	{
		BuildLimit = StringToInt(newValue);
		LogAction(-1, -1, "%s %s now is %d", LOG_PREFIX, "sm_buildlimit", BuildLimit);
	}
	else
	{
		for(new i = 0; i < EFFECTS; i++)
		{
			if(convar == Effects[i][hDelay])
			{
				Effects[i][Delay] = StringToInt(newValue);
				LogAction(-1, -1, "%s %s now is %d", LOG_PREFIX, Effects[i][DelayCVar], Effects[i][Delay]);
			}
		}
	}
}
//──────────────────────────────────────────────────────────────────────────────
public OnPluginEnd()
{
	ResetAllData();
}
//──────────────────────────────────────────────────────────────────────────────
public OnMapStart()
{
	ResetAllData();
	//PrecacheSound(SOUND_HEAL);
}
//──────────────────────────────────────────────────────────────────────────────
public OnClientConnected(client)
{
	ResetPlayerData(client);
}
//──────────────────────────────────────────────────────────────────────────────
public OnClientDisconnect(client)
{
	KillAllDisp(client);
	KillAllSentry(client);
	ResetPlayerData(client);
}
//──────────────────────────────────────────────────────────────────────────────
// Stocks
//──────────────────────────────────────────────────────────────────────────────
public bool:TraceFilterIgnorePlayers(entity, contentsMask, any:client)
{
	return (entity <= 0 || entity > MaxClients);
}
//──────────────────────────────────────────────────────────────────────────────
stock GetClientEyeTraceVec(Client, Float:Position[3], Float:Angle[3])
{
	new Float:flEndPos[3];
	new Float:flPos[3];
	new Float:flAng[3];
	GetClientEyePosition(Client, flPos);
	GetClientEyeAngles(Client, flAng);
	new Handle:hTrace = TR_TraceRayFilterEx(flPos, flAng, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, Client);
	if(hTrace != INVALID_HANDLE && TR_DidHit(hTrace))
	{
		TR_GetEndPosition(flEndPos, hTrace);
		flEndPos[2] += 5.0;
	}
	
	Position = flEndPos;
	Angle	 = flAng;
}
//──────────────────────────────────────────────────────────────────────────────
stock BuildSentry(iBuilder,Float:fOrigin[3], Float:fAngle[3],iLevel, bool:bMini = false)
{
	fAngle[0] = 0.0;
	//ShowActivity2(iBuilder, "[SM] ","Spawned a sentry (lvl %d%s)", iLevel, bMini ? ", mini" : "");
	decl String:sModel[64];
	new iTeam = GetClientTeam(iBuilder);
	//new fireattach[3];

	new iShells, iHealth, iRockets;
	switch (iLevel)
	{
		case 1:
		{
			sModel = "models/buildables/sentry1.mdl";
			iShells = 100;
			iHealth = 150;
	//		fireattach[0] = 4;
			if (bMini)
			{
				iShells = 100;
				iHealth = 100;
			}
		}
		case 2:
		{
			sModel = "models/buildables/sentry2.mdl";
			iShells = 120;
			iHealth = 180;
	//		fireattach[0] = 1;
	//		fireattach[1] = 2;
			if (bMini)
			{
				iShells = 120;
				iHealth = 120;
			}
		}
		case 3:
		{
			sModel = "models/buildables/sentry3.mdl";
			iShells = 144;
			iHealth = 216;
			iRockets = 20;
	//		fireattach[0] = 1;
	//		fireattach[1] = 2;
	//		fireattach[2] = 4;
			if (bMini)
			{
				iShells = 144;
				iHealth = 180;
				iRockets = 20;
			}
		}
	}

	new entity = CreateEntityByName("obj_sentrygun");
	if (entity < MaxClients || !IsValidEntity(entity)) return;
	DispatchSpawn(entity);
	TeleportEntity(entity, fOrigin, fAngle, NULL_VECTOR);
	SetEntityModel(entity,sModel);

	SetEntProp(entity, Prop_Send, "m_iAmmoShells", iShells);
	SetEntProp(entity, Prop_Send, "m_iHealth", iHealth);
	SetEntProp(entity, Prop_Send, "m_iMaxHealth", iHealth);
	SetEntProp(entity, Prop_Send, "m_iObjectType", _:TFObject_Sentry);

	SetEntProp(entity, Prop_Send, "m_iTeamNum", iTeam);
	new iSkin = iTeam-2;
	if (bMini && iLevel == 1)
	{
		iSkin = iTeam;
	}

	SetEntProp(entity, Prop_Send, "m_nSkin", iSkin);
	SetEntProp(entity, Prop_Send, "m_iUpgradeLevel", iLevel);
	SetEntProp(entity, Prop_Send, "m_iHighestUpgradeLevel", iLevel);
	SetEntProp(entity, Prop_Send, "m_iAmmoRockets", iRockets);

	SetEntPropEnt(entity, Prop_Send, "m_hBuilder", iBuilder);

	SetEntProp(entity, Prop_Send, "m_iState", 3);
	SetEntPropFloat(entity, Prop_Send, "m_flPercentageConstructed", iLevel == 1 ? 0.99 : 1.0);
	if (iLevel == 1) SetEntProp(entity, Prop_Send, "m_bBuilding", 1);
	SetEntProp(entity, Prop_Send, "m_bPlayerControlled", 1);
	SetEntProp(entity, Prop_Send, "m_bHasSapper", 0);
	SetEntPropVector(entity, Prop_Send, "m_vecBuildMaxs", Float:{ 24.0, 24.0, 66.0 });
	SetEntPropVector(entity, Prop_Send, "m_vecBuildMins", Float:{ -24.0, -24.0, 0.0 });
	if (bMini)
	{
		SetEntProp(entity, Prop_Send, "m_bMiniBuilding", 1);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.75);
	}
	new offs = FindSendPropInfo("CObjectSentrygun", "m_iDesiredBuildRotations");	//2608
	if (offs <= 0) return;
	SetEntData(entity, offs-12, 1, 1, true);
	//new offs = FindSendPropInfo("CObjectSentrygun", "m_nShieldLevel");
	//if (offs <= 0) return Plugin_Handled;
	//SetEntData(entity, offs+12, fireattach[0]);
	//SetEntData(entity, offs+16, fireattach[1]);
	//SetEntData(entity, offs+20, fireattach[2]);
}
//──────────────────────────────────────────────────────────────────────────────
stock BuildDispenser(iBuilder, Float:flOrigin[3], Float:flAngles[3], iLevel)
{
	new String:strModel[100];
	flAngles[0] = 0.0;
	//ShowActivity2(iBuilder, "[SM] ", "Spawned a dispenser (lvl %d)", iLevel);
	new iTeam = GetClientTeam(iBuilder);
	new iHealth;
	new iAmmo = 400;
	switch (iLevel)
	{
		case 3:
		{
			strcopy(strModel, sizeof(strModel), "models/buildables/dispenser_lvl3.mdl");
			iHealth = 216;
		}
		case 2:
		{
			strcopy(strModel, sizeof(strModel), "models/buildables/dispenser_lvl2.mdl");
			iHealth = 180;
		}
		default:
		{
			strcopy(strModel, sizeof(strModel), "models/buildables/dispenser.mdl");
			iHealth = 150;
		}
	}

	new entity = CreateEntityByName("obj_dispenser");
	if (entity < MaxClients || !IsValidEntity(entity)) return;
	DispatchSpawn(entity);

	TeleportEntity(entity, flOrigin, flAngles, NULL_VECTOR);

	SetVariantInt(iTeam);
	AcceptEntityInput(entity, "TeamNum");
	SetVariantInt(iTeam);
	AcceptEntityInput(entity, "SetTeam");

	ActivateEntity(entity);

	SetEntProp(entity, Prop_Send, "m_iAmmoMetal", iAmmo);
	SetEntProp(entity, Prop_Send, "m_iHealth", iHealth);
	SetEntProp(entity, Prop_Send, "m_iMaxHealth", iHealth);
	SetEntProp(entity, Prop_Send, "m_iObjectType", _:TFObject_Dispenser);
	SetEntProp(entity, Prop_Send, "m_iTeamNum", iTeam);
	SetEntProp(entity, Prop_Send, "m_nSkin", iTeam-2);
	SetEntProp(entity, Prop_Send, "m_iUpgradeLevel", iLevel);
	SetEntProp(entity, Prop_Send, "m_iHighestUpgradeLevel", iLevel);
	SetEntProp(entity, Prop_Send, "m_iState", 3);
	SetEntPropVector(entity, Prop_Send, "m_vecBuildMaxs", Float:{ 24.0, 24.0, 55.0 });
	SetEntPropVector(entity, Prop_Send, "m_vecBuildMins", Float:{ -24.0, -24.0, 0.0 });
	SetEntPropFloat(entity, Prop_Send, "m_flPercentageConstructed", iLevel == 1 ? 0.99 : 1.0);
	if (iLevel == 1) SetEntProp(entity, Prop_Send, "m_bBuilding", 1);
	SetEntPropEnt(entity, Prop_Send, "m_hBuilder", iBuilder);
	SetEntityModel(entity, strModel);
	new offs = FindSendPropInfo("CObjectDispenser", "m_iDesiredBuildRotations");	//2608
	if (offs <= 0) return;
	SetEntData(entity, offs-12, 1, 1, true);
}
//──────────────────────────────────────────────────────────────────────────────
stock KillAllSentry(Client)
{
	new index=-1;
	while((index = FindEntityByClassname(index,"obj_sentrygun")) != -1)
	{
		if(GetEntPropEnt(index,Prop_Send,"m_hBuilder") == Client)
		{
			SetVariantInt(9999);
			AcceptEntityInput(index, "RemoveHealth");
		}
	}
}
//──────────────────────────────────────────────────────────────────────────────
stock KillAllDisp(Client)
{
	new index=-1;
	while((index = FindEntityByClassname(index,"obj_dispenser")) != -1)
	{
		if(GetEntPropEnt(index,Prop_Send,"m_hBuilder") == Client)
		{
			SetVariantInt(9999);
			AcceptEntityInput(index, "RemoveHealth");
		}
	}
}
//──────────────────────────────────────────────────────────────────────────────
stock CountAllSentry(Client)
{
	new index=-1;
	new Count = 0;
	while((index = FindEntityByClassname(index,"obj_sentrygun")) != -1)
	{
		if(GetEntPropEnt(index,Prop_Send,"m_hBuilder") == Client)
		{
			Count++;
		}
	}
	return Count;
}
//──────────────────────────────────────────────────────────────────────────────
stock CountAllDisp(Client)
{
	new index=-1;
	new Count = 0;
	while((index = FindEntityByClassname(index,"obj_dispenser")) != -1)
	{
		if(GetEntPropEnt(index,Prop_Send,"m_hBuilder") == Client)
		{
			Count++;
		}
	}
	return Count;
}
//──────────────────────────────────────────────────────────────────────────────
// Check if client is normal player (human) that already in game, not bot or etc
stock IsValidClient(Client)
{
	if ((Client <= 0) || (Client > MaxClients) || (!IsClientInGame(Client)))
	{
		return false;
	}
	if (IsClientSourceTV(Client) || IsClientReplay(Client))
	{
		return false;
	}
	// Skip bots
	new String:Auth[32];
	GetClientAuthString(Client, Auth, sizeof(Auth));
	if (StrEqual(Auth, "BOT", false) || StrEqual(Auth, "STEAM_ID_PENDING", false) || StrEqual(Auth, "STEAM_ID_LAN", false))
	{
		return false;
	}
	return true;
}
//──────────────────────────────────────────────────────────────────────────────
// 0 - ready
// > 0 - delay
// < 0 - effect limited or disabled
// Index here is NOT effect ID
stock IsEffectReady(client, Index)
{
	new Result = 0;
	
	// How much time passed since last use of effect
	new TimePass = GetTime() - Players[client][TimeUsed][Index];
	if(Players[client][TimeUsed][Index] && TimePass < Effects[Index][Delay])
	{
		// If time passed is less than delay - tell player to wait more
		Result = Effects[Index][Delay] - TimePass;
	}
	
	// If effect is sentry or dispenser building - then check how many buildings player own already
	new Count = 0;
	if(Effects[Index][ID] == SENTRY && Effects[Index][GID] == BUILD)
	{
		Count = CountAllSentry(client);
	}
	else if(Effects[Index][ID] == DISP && Effects[Index][GID] == BUILD)
	{
		Count = CountAllDisp(client);
	}
	if(Count != 0 && Count >= BuildLimit)
	{
		Result = BuildLimit - Count - 1;	// negative value
	}
	
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
// Print help
PrintHelp(Client)
{
	PrintToChat(Client, "%s Write \x07FFA500%s\x01 for menu", CHAT_PREFIX, "!spells or !canteen or !build or !effects");
	PrintToChat(Client, "Or use following names with any of commands above");
	for(new Index = 0; Index < EFFECTS; Index++)
	{
		PrintToChat(Client, "\x07FFA500%s\x01 - «%s»", Effects[Index][Name] ,Effects[Index][Desc]);
	}
}
//──────────────────────────────────────────────────────────────────────────────
// Variables support
//──────────────────────────────────────────────────────────────────────────────
InitEffectsData()
{
	new i = 0;
	
	// Amount of this effects must be stored in EFFECTS constant
	
	// Spells
	
	Effects[i][ID] = TELE;
	Effects[i][GID] = SPELL;
	Format(Effects[i][Name], STR_LEN, "transpose");
	Format(Effects[i][Desc], STR_LEN, "Transpose");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_spelldelay_transpose");
	i++;
	
	//Effects[i][ID] = PUMPKIN2;
	//Effects[i][GID] = SPELL;
	//Format(Effects[i][Name], STR_LEN, "pumpkin");
	//Format(Effects[i][Desc], STR_LEN, "Pumpkin");
	//Format(Effects[i][DelayCVar], STR_LEN, "sm_spelldelay_pumpkin");
	//i++;
	
	Effects[i][ID] = FIREBALL;
	Effects[i][GID] = SPELL;
	Format(Effects[i][Name], STR_LEN, "fireball");
	Format(Effects[i][Desc], STR_LEN, "Fireball");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_spelldelay_fireball");
	i++;
	
	Effects[i][ID] = BATS;
	Effects[i][GID] = SPELL;
	Format(Effects[i][Name], STR_LEN, "bats");
	Format(Effects[i][Desc], STR_LEN, "Bats");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_spelldelay_bats");
	i++;
	
	//Effects[i][ID] = PUMPKIN;
	//Effects[i][GID] = SPELL;
	//Format(Effects[i][Name], STR_LEN, "pumpkins");
	//Format(Effects[i][Desc], STR_LEN, "Pumpkins");
	//Format(Effects[i][DelayCVar], STR_LEN, "sm_spelldelay_pumpkins");
	//i++;
	
	Effects[i][ID] = LIGHTNING;
	Effects[i][GID] = SPELL;
	Format(Effects[i][Name], STR_LEN, "lightning");
	Format(Effects[i][Desc], STR_LEN, "Lightning");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_spelldelay_lightning");
	i++;
	
	//Effects[i][ID] = ZOMBIEH;
	//Effects[i][GID] = SPELL;
	//Format(Effects[i][Name], STR_LEN, "skeletons");
	//Format(Effects[i][Desc], STR_LEN, "Skeletons");
	//Format(Effects[i][DelayCVar], STR_LEN, "sm_spelldelay_skeletons");
	//i++;
	
	Effects[i][ID] = ZOMBIE;
	Effects[i][GID] = SPELL;
	Format(Effects[i][Name], STR_LEN, "skeleton");
	Format(Effects[i][Desc], STR_LEN, "Skeleton");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_spelldelay_skeleton");
	i++;
	
	Effects[i][ID] = BOSS;
	Effects[i][GID] = SPELL;
	Format(Effects[i][Name], STR_LEN, "monoculus");
	Format(Effects[i][Desc], STR_LEN, "Monoculus");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_spelldelay_monoculus");
	i++;
	
	Effects[i][ID] = METEOR;
	Effects[i][GID] = SPELL;
	Format(Effects[i][Name], STR_LEN, "meteors");
	Format(Effects[i][Desc], STR_LEN, "Meteor Shower");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_spelldelay_meteors");
	i++;
	
	// Canteen
	
	Effects[i][ID] = UBER;
	Effects[i][GID] = CHARGE;
	Format(Effects[i][Name], STR_LEN, "uber");
	Format(Effects[i][Desc], STR_LEN, "Uber Charge");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_chargedelay_uber");
	i++;
	
	Effects[i][ID] = CRIT;
	Effects[i][GID] = CHARGE;
	Format(Effects[i][Name], STR_LEN, "crit");
	Format(Effects[i][Desc], STR_LEN, "Critical Charge");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_chargedelay_crit");
	i++;
	
	Effects[i][ID] = REGEN;
	Effects[i][GID] = CHARGE;
	Format(Effects[i][Name], STR_LEN, "regen");
	Format(Effects[i][Desc], STR_LEN, "Refill Ammo and Health");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_chargedelay_regen");
	i++;
	
	Effects[i][ID] = INVIS;
	Effects[i][GID] = CHARGE;
	Format(Effects[i][Name], STR_LEN, "cloak");
	Format(Effects[i][Desc], STR_LEN, "Cloak");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_chargedelay_cloak");
	i++;
	
	Effects[i][ID] = BASE;
	Effects[i][GID] = CHARGE;
	Format(Effects[i][Name], STR_LEN, "base");
	Format(Effects[i][Desc], STR_LEN, "Teleport to the Base");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_chargedelay_base");
	i++;
	
	Effects[i][ID] = SPEED;
	Effects[i][GID] = CHARGE;
	Format(Effects[i][Name], STR_LEN, "speed");
	Format(Effects[i][Desc], STR_LEN, "Speed-up");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_chargedelay_speed");
	i++;
	
	Effects[i][ID] = HEAL;
	Effects[i][GID] = CHARGE;
	Format(Effects[i][Name], STR_LEN, "heal");
	Format(Effects[i][Desc], STR_LEN, "Add Health");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_chargedelay_heal");
	i++;
	
	// Building
	
	Effects[i][ID] = SENTRY;
	Effects[i][GID] = BUILD;
	Format(Effects[i][Name], STR_LEN, "sentry");
	Format(Effects[i][Desc], STR_LEN, "Build a Sentry");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_builddelay_sentry");
	i++;
	
	Effects[i][ID] = DISP;
	Effects[i][GID] = BUILD;
	Format(Effects[i][Name], STR_LEN, "disp");
	Format(Effects[i][Desc], STR_LEN, "Build a Dispenser");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_builddelay_disp");
	i++;
	
	Effects[i][ID] = KILLSENTRY;
	Effects[i][GID] = BUILD;
	Format(Effects[i][Name], STR_LEN, "killsentry");
	Format(Effects[i][Desc], STR_LEN, "Kill your Sentries");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_builddelay_killsentry");
	i++;
	
	Effects[i][ID] = KILLDISP;
	Effects[i][GID] = BUILD;
	Format(Effects[i][Name], STR_LEN, "killdisp");
	Format(Effects[i][Desc], STR_LEN, "Kill your Dispensers");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_builddelay_killdisp");
	i++;
}
//──────────────────────────────────────────────────────────────────────────────
ResetPlayerData(client)
{
	for(new Index = 0; Index < EFFECTS; Index++)
	{
		Players[client][TimeUsed][Index] = GetTime();
	}
}
//──────────────────────────────────────────────────────────────────────────────
ResetAllData()
{
	for(new cli=0; cli<MAXPLAYERS+1; cli++)
	{
		ResetPlayerData(cli);
	}
}
//──────────────────────────────────────────────────────────────────────────────
// Menu
//──────────────────────────────────────────────────────────────────────────────
// Console command to call main menu
public Action:Command_MainMenu(client, args)
{
	if (!IsValidClient(client))
	{
		LogAction(-1, -1, "%s Wrong client '%L' triggered this function", LOG_PREFIX, client);
		return Plugin_Handled;
	}
	
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "%s You must be alive", CHAT_PREFIX);
		return Plugin_Handled;
	}
	
	ShowMainMenu(client);

	return Plugin_Handled;
}
//──────────────────────────────────────────────────────────────────────────────
// Function to show main menu
public ShowMainMenu(Client)
{
	new Handle:MainMenu = CreateMenu(MainMenuHandler, MenuAction_Start|MenuAction_Select|MenuAction_Cancel|MenuAction_End);
	
	SetMenuTitle(MainMenu, "!effects");
	
	AddMenuItem(MainMenu, "spells", "!spells");
	AddMenuItem(MainMenu, "canteen", "!canteen");
	AddMenuItem(MainMenu, "build", "!build");
	
	SetMenuExitButton(MainMenu, true);
	DisplayMenu(MainMenu, Client, 20);

	return;
}
//──────────────────────────────────────────────────────────────────────────────
// Main menu action handling
public MainMenuHandler(Handle:Menu, MenuAction:action, param1, param2)
{
	if(action==MenuAction_Select)
		{
			decl String:Info[STR_LEN];
			GetMenuItem(Menu, param2, Info, sizeof(Info));
			
			if(StrEqual(Info, "spells"))
			{
				ShowMenu(param1, SPELL, Menu);
			}
			else if(StrEqual(Info, "canteen"))
			{
				ShowMenu(param1, CHARGE, Menu);
			}
			else if(StrEqual(Info, "build"))
			{
				ShowMenu(param1, BUILD, Menu);
			}
		}

	if(action==MenuAction_End)
	{
		CloseHandle(Menu);
	}
}
//──────────────────────────────────────────────────────────────────────────────
// Console command to call menu
public Action:Command_Menu(client, args)
{
	if (!IsValidClient(client))
	{
		LogAction(-1, -1, "%s Wrong client '%L' triggered this function", LOG_PREFIX, client);
		return Plugin_Handled;
	}
	
	// Get command name
	new String:Command[STR_LEN];
	GetCmdArg(0, Command, sizeof(Command));
	
	// Chat prefix
	new String:ChatPrefix[STR_LEN];
	// Selector for effects (group)
	new Selector = ALL;
	
	if(StrEqual(Command, "sm_spells", false) || StrEqual(Command, "sm_spell", false))
	{
		Selector = SPELL;
		Format(ChatPrefix, sizeof(ChatPrefix), "%s", SPELL_PREFIX);
	}
	else if(StrEqual(Command, "sm_canteen", false))
	{
		Selector = CHARGE;
		Format(ChatPrefix, sizeof(ChatPrefix), "%s", CHARGE_PREFIX);
	}
	else if(StrEqual(Command, "sm_build", false))
	{
		Selector = BUILD;
		Format(ChatPrefix, sizeof(ChatPrefix), "%s", BUILD_PREFIX);
	}
	else
	{
		Selector = ALL;
		Format(ChatPrefix, sizeof(ChatPrefix), "%s", CHAT_PREFIX);
	}
	
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "%s You must be alive", ChatPrefix);
		return Plugin_Handled;
	}
	
	if(args == 0)
	{
		// Command called without arguments - show menu
		ShowMenu(client, Selector, INVALID_HANDLE);
	}
	else
	{
		// Command called with argument - 1st argument must be a effect name
		
		new String:EffectName[STR_LEN];
		GetCmdArg(1, EffectName, sizeof(EffectName));
		
		new bool:Match = false;	// true if 1st argument matched some spell name
		
		// Selector
		// Go through all known spells
		for(new Index = 0; Index < EFFECTS; Index++)
		{
			// Compare for current spell name from list match requested from command line
			if(StrEqual(EffectName, Effects[Index][Name], false))
			{
				// We have match - found requested effect
				Match = true;
				UseEffect(client, Index);
				break;
			}
		}
		// If loop above don't find any spell name that match requested in 1st argument
		// then print all spell names to player
		if(!Match)
		{
			PrintHelp(client);
		}
	}
	
	return Plugin_Handled;
}
//──────────────────────────────────────────────────────────────────────────────
// Function to show menu
public ShowMenu(client, Group, Handle:Parent)
{
	new Handle:Menu = CreateMenu(MenuHandler, MenuAction_Start|MenuAction_Select|MenuAction_Cancel|MenuAction_End);
	
	if(Group == ALL)
	{
		SetMenuTitle(Menu, "All effects");
	}
	else if(Group == SPELL)
	{
		SetMenuTitle(Menu, "Spells");
	}
	else if(Group == CHARGE)
	{
		SetMenuTitle(Menu, "Canteen charges");
	}
	else if(Group == BUILD)
	{
		SetMenuTitle(Menu, "Buildings");
	}
	
	decl String:Msg[STR_LEN];
	new iDelay = 0;
	
	for(new Index = 0; Index < EFFECTS; Index++)
	{
		// Select only required effects
		if(Effects[Index][GID] & Group)
		{
			iDelay = IsEffectReady(client, Index);
			if(iDelay == 0)
			{
				AddMenuItem(Menu, Effects[Index][Name], Effects[Index][Desc]);
			}
			else if(iDelay > 0)
			{
				Format(Msg, sizeof(Msg), "%s (%d sec)", Effects[Index][Desc], iDelay);
				AddMenuItem(Menu, Effects[Index][Name], Msg, ITEMDRAW_DISABLED);
			}
			else //(iDelay < 0)
			{
				Format(Msg, sizeof(Msg), "%s (limit)", Effects[Index][Desc]);
				AddMenuItem(Menu, Effects[Index][Name], Msg, ITEMDRAW_DISABLED);
			}
		}
	}
	
	SetMenuExitButton(Menu, true);
	if(Parent != INVALID_HANDLE)
	{
		SetMenuExitBackButton(Menu, true);
	}
	DisplayMenu(Menu, client, MENU_TIME_FOREVER);

	return;
}
//──────────────────────────────────────────────────────────────────────────────
// Menu action handling
public MenuHandler(Handle:Menu, MenuAction:action, param1, param2)
{
	if(action==MenuAction_Select)
		{
			decl String:Info[STR_LEN];
			GetMenuItem(Menu, param2, Info, sizeof(Info));
			
			// Selector
			// Go through all known spells
			for(new Index = 0; Index < EFFECTS; Index++)
			{
				// Compare for current spell name from list match selected in menu
				if(StrEqual(Info, Effects[Index][Name]) && IsPlayerAlive(param1))
				{
					UseEffect(param1, Index);
					break;
				}
			}
			ShowMainMenu(param1);
		}
	if(action==MenuAction_Cancel && param2==MenuCancel_ExitBack)
	{
		ShowMainMenu(param1);
	}
	if(action==MenuAction_End)
	{
		CloseHandle(Menu);
	}
}
//──────────────────────────────────────────────────────────────────────────────
// Internal routines
//──────────────────────────────────────────────────────────────────────────────
// Shoot effect
UseEffect(Client, Index)
{	
	// Is it ready?
	new TimeWait = IsEffectReady(Client, Index);	// 0 - ready; > 0 - time to wait; < 0 - limit reached or disabled
	if(TimeWait > 0)
	{
		// Effect is not ready - notify player
		PrintToChat(Client, "%s Wait \x07FFA500%d\x01 second(s)", CHAT_PREFIX, TimeWait);
		return;
	}
	if(TimeWait < 0)
	{
		// Effect limited
		PrintToChat(Client, "%s Limit reached", CHAT_PREFIX);
		return;
	}
	if(Effects[Index][GID] == SPELL)
	{
		ShootProjectile(Client, Effects[Index][ID]);
	}
	else if(Effects[Index][GID] == CHARGE)
	{
		ShootCharge(Client, Effects[Index][ID]);
	}
	else if(Effects[Index][GID] == BUILD)
	{
		Build(Client, Effects[Index][ID]);
	}
	
	// Save time when player used effect
	Players[Client][TimeUsed][Index] = GetTime();
}
//──────────────────────────────────────────────────────────────────────────────
Build(Client, BuildingID)
{
	// Variables to store building position and rotation angle
	new Float:Position[3];
	new Float:Angle[3];
	// Select what to do
	switch(BuildingID)
	{
		case SENTRY:
		{
			GetClientEyeTraceVec(Client, Position, Angle);
			BuildSentry(Client, Position, Angle, 3, false);
		}
		case DISP:	
		{
			GetClientEyeTraceVec(Client, Position, Angle);
			BuildDispenser(Client, Position, Angle, 3);
		}
		case KILLSENTRY:
		{
			KillAllSentry(Client);
		}
		case KILLDISP:
		{
			KillAllDisp(Client);
		}
	} 
}
//──────────────────────────────────────────────────────────────────────────────
ShootCharge(Client, Charge)
{
	switch(Charge)
	{
		case UBER:
		{
			TF2_AddCondition(Client, TFCond_UberchargedCanteen, 15.0);
		}
		case CRIT:	
		{
			TF2_AddCondition(Client, TFCond_CritCanteen, 15.0);
		}
		case REGEN:
		{
			TF2_RegeneratePlayer(Client);
		}
		case INVIS:
		{
			TF2_AddCondition(Client, 64, 15.0);
		}
		case BASE:
		{
			TF2_RespawnPlayer(Client);
		}
		case SPEED:
		{
			TF2_AddCondition(Client,  TFCond_SpeedBuffAlly, 15.0);
		}
		case HEAL:
		{
			new Health = GetClientHealth(Client) + 5000;
			SetEntityHealth(Client, Health);
			TF2_AddCondition(Client, TFCond_MegaHeal, 1.0);
		}
	}  
}
//──────────────────────────────────────────────────────────────────────────────
ShootProjectile(client, spell)
{
	new Float:vAngles[3]; // original
	new Float:vPosition[3]; // original
	GetClientEyeAngles(client, vAngles);
	GetClientEyePosition(client, vPosition);
	new String:strEntname[45] = "";
	switch(spell)
	{
		case FIREBALL: 		strEntname = "tf_projectile_spellfireball";
		case LIGHTNING: 	strEntname = "tf_projectile_lightningorb";
		//case PUMPKIN: 		strEntname = "tf_projectile_spellmirv";
		//case PUMPKIN2: 		strEntname = "tf_projectile_spellpumpkin";
		case BATS: 			strEntname = "tf_projectile_spellbats";
		case METEOR: 		strEntname = "tf_projectile_spellmeteorshower";
		case TELE: 			strEntname = "tf_projectile_spelltransposeteleport";
		case BOSS:			strEntname = "tf_projectile_spellspawnboss";
		//case ZOMBIEH:		strEntname = "tf_projectile_spellspawnhorde";
		case ZOMBIE:		strEntname = "tf_projectile_spellspawnzombie";
	}
	new iTeam = GetClientTeam(client);
	new iSpell = CreateEntityByName(strEntname);
	
	if(!IsValidEntity(iSpell))
		return -1;
	
	decl Float:vVelocity[3];
	decl Float:vBuffer[3];
	
	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
	
	vVelocity[0] = vBuffer[0]*1100.0; //Speed of a tf2 rocket.
	vVelocity[1] = vBuffer[1]*1100.0;
	vVelocity[2] = vBuffer[2]*1100.0;
	
	SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(iSpell,    Prop_Send, "m_bCritical", (GetRandomInt(0, 100) <= 5)? 1 : 0, 1);
	SetEntProp(iSpell,    Prop_Send, "m_iTeamNum",     iTeam, 1);
	SetEntProp(iSpell,    Prop_Send, "m_nSkin", (iTeam-2));
	
	TeleportEntity(iSpell, vPosition, vAngles, NULL_VECTOR);
	/*switch(spell)
	{
		case FIREBALL, LIGHTNING:
		{
			TeleportEntity(iSpell, vPosition, vAngles, vVelocity);
		}
		case BATS, METEOR, TELE:
		{
			//TeleportEntity(iSpell, vPosition, vAngles, vVelocity);
			//SetEntPropVector(iSpell, Prop_Send, "m_vecForce", vVelocity);
			
		}
	}*/
	
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "TeamNum", -1, -1, 0);
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "SetTeam", -1, -1, 0); 
	
	DispatchSpawn(iSpell);
	/*
	switch(spell)
	{
		//These spells have arcs.
		case BATS, METEOR, TELE:
		{
			vVelocity[2] += 32.0;
		}
	}*/
	TeleportEntity(iSpell, NULL_VECTOR, NULL_VECTOR, vVelocity);
	
	return iSpell;
}
//──────────────────────────────────────────────────────────────────────────────
