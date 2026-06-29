//──────────────────────────────────────────────────────────────────────────────
/*
	Copyright 2006-2014 AlliedModders LLC
	Copyright 2008-2009 Nicholas Hastings	
	Copyright 2007-2009 TTS Oetzel & Goerz GmbH
	Copyright 2008-2013 pheadxdll http://forums.alliedmods.net/member.php?u=38829
	Copyright 2012 X3Mano https://forums.alliedmods.net/member.php?u=170871
	Copyright 2013 Mitchell http://forums.alliedmods.net/member.php?u=74234
	Copyright 2013-2014 avi9526 <dromaretsky@gmail.com>
	Copyright 2013-2014 FlaminSarge http://forums.alliedmods.net/member.php?u=84304
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
#define PLUGIN_VERSION "2.1.2"
//──────────────────────────────────────────────────────────────────────────────
// Amount of effects
#define EFFECTS		21
// Flags used for separating spells and canteen charges
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
#define SENTRY1		0	// sentry level 1
#define SENTRY2		1	// sentry level 2
#define SENTRY3		2	// sentry level 3
#define SENTRYMIN	3	// sentry mini
#define DISP 		4	// dispenser
#define KILLAIM 	5	// kill building at aim
#define KILLBUILD 	6	// kill all owned buildings
//──────────────────────────────────────────────────────────────────────────────
// Some codes
#define READY		0	// effect is ready
#define LIMIT		-1	// limit reached
#define DISABLED	-2	// effect disabled
// Max used strings length
#define STR_LEN		128
// Admin flag
#define ADMFLAG_NONE	0
//──────────────────────────────────────────────────────────────────────────────
// Sounds
//#define SOUND_HEAL		"weapons/vaccinator_heal.wav"
//──────────────────────────────────────────────────────────────────────────────
#define LOG_PREFIX		"[Effects]"
#define TAG				"effects"
#define CHAT_PREFIX		"\x01[\x07B262FFEffects\x01]"
#define SPELL_PREFIX	"\x01[\x07B262FFSpells\x01]"
#define CHARGE_PREFIX	"\x01[\x07B262FFCanteen\x01]"
#define BUILD_PREFIX	"\x01[\x07B262FFBuilding\x01]"
//──────────────────────────────────────────────────────────────────────────────
// Non-existent commands to check who is admin and who is premium and etc.
#define CMD_ADMIN		"sm_effects_admin"
#define CMD_PREMIUM		"sm_effects_premium"
#define CMD_ACCESS		"sm_effects_access"
//──────────────────────────────────────────────────────────────────────────────
public Plugin:myinfo = 
{
	name = "[TF2] Effects",
	author = "avi9526. See source code for more details",
	description = "Allows players to use some effects",
	version = PLUGIN_VERSION,
	url = "/dev/null"
}
//──────────────────────────────────────────────────────────────────────────────
// Global variables
//──────────────────────────────────────────────────────────────────────────────
new Handle:	hVersion;
// Used to limit amount of buildings
new			BuildLimit;
new Handle:	hBuildLimit;
// Allow to lower wait times for admins and privileged players
// Premium player wait time multiplier (recommended value 0..1)
new	Float:	WaitMultPrem;
new Handle:	hWaitMultPrem;
// Admin player wait time multiplier (recommended value 0..1)
new	Float:	WaitMultAdmin;
new Handle:	hWaitMultAdmin;

// Store individual player data needed to plugin
enum PlayerData
{
	TimeUsed[EFFECTS],	// when player last time used spell
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
	hVersion = CreateConVar("sm_effects_version", PLUGIN_VERSION, "Effects Version", FCVAR_PLUGIN | FCVAR_NOTIFY);
	if(hVersion != INVALID_HANDLE)
	{
		SetConVarString(hVersion, PLUGIN_VERSION);
	}
	
	//HookEvent("player_team", Event_PlayerChangeTeam, EventHookMode_Post);
	
	InitEffectsData();
	
	//new String: DefVal[STR_LEN];
	for(new i = 0; i < EFFECTS; i++)
	{
		//Format(DefVal, STR_LEN, "%d", Effects[i][Delay]);	// convert delay value to string for ConVar initialization
		Effects[i][hDelay] = CreateConVar(Effects[i][DelayCVar], "60", "How much player must wait before use effect again", _, true, -1.0, false, 100.0);
		Effects[i][Delay] = GetConVarInt(Effects[i][hDelay]);
		HookConVarChange(Effects[i][hDelay], OnConVarChanged);
	}
	
	hBuildLimit = CreateConVar("sm_buildlimit", "1", "Limit amount of one kind of building that are available for player", _, true, 1.0, true, 100.0);
	BuildLimit = GetConVarInt(hBuildLimit);
	HookConVarChange(hBuildLimit, OnConVarChanged);
	
	hWaitMultAdmin = CreateConVar("sm_waitmult_admin", "0.5", "Admin players wait time multiplier for effects", _, true, 0.0, true, 10.0);
	WaitMultAdmin = GetConVarFloat(hWaitMultAdmin);
	HookConVarChange(hWaitMultAdmin, OnConVarChanged);
	
	hWaitMultPrem = CreateConVar("sm_waitmult_premium", "0.75", "Premium players wait time multiplier for effects", _, true, 0.0, true, 10.0);
	WaitMultPrem = GetConVarFloat(hWaitMultPrem);
	HookConVarChange(hWaitMultPrem, OnConVarChanged);
	
	// Effects menu
	RegConsoleCmd("sm_spells", Command_Menu, "Spells menu");
	RegConsoleCmd("sm_spell", Command_Menu, "Spells menu");
	RegConsoleCmd("sm_canteen", Command_Menu, "Canteen charges menu");
	RegConsoleCmd("sm_build", Command_Menu, "Building menu");
	RegConsoleCmd("sm_effects", Command_MainMenu, "Spells and Canteen charges menu");
	RegConsoleCmd("sm_effect", Command_MainMenu, "Spells and Canteen charges menu");
}
//──────────────────────────────────────────────────────────────────────────────
//
// BUG: sometimes this event called even if player don't change team
//
// Destroy all building when player change team, because game won't do this
//public Action:Event_PlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
//{
	//new Client = GetEventInt(event,"userid");
	//KillAllDisp(Client);
	//KillAllSentry(Client);
	//LogAction(-1, -1, "%s Player %L changed team - kill all his buildings", LOG_PREFIX, Client);
	//return Plugin_Continue;
//}
//──────────────────────────────────────────────────────────────────────────────
// If console variable changed - need change corresponding internal variables
public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == hBuildLimit)
	{
		BuildLimit = StringToInt(newValue);
		LogAction(-1, -1, "%s %s now is %d", LOG_PREFIX, "sm_buildlimit", BuildLimit);
	}
	else if(convar == hWaitMultAdmin)
	{
		WaitMultAdmin = StringToFloat(newValue);
		LogAction(-1, -1, "%s %s now is %f", LOG_PREFIX, "sm_waitmult_admin", WaitMultAdmin);
	}
	else if(convar == hWaitMultPrem)
	{
		WaitMultPrem = StringToFloat(newValue);
		LogAction(-1, -1, "%s %s now is %f", LOG_PREFIX, "sm_waitmult_premium", WaitMultPrem);
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
// This function returns particle entity reference
// See https://wiki.alliedmods.net/Entity_References_%28SourceMod%29
stock ParticleCreate
(
	const String: NameID[],					// unique particle name
	Float: Position[3] = {0.0, 0.0, 0.0},	// position to spawn (relative to parent if exist)
											// **NOT** include rotation angle of parent entity
	Float: LifeTime = 0.0,					// life time of particle, 0.0 for uncontrolled
	ParentEntity = 0,						// parent entity
	bool: SetParent = true,					// if false - parent used only to calculate relative position		
	const String: AttachTo[] = ""			// name of part of parent entity where attach particle
)
{
	// Create variables
	
	new bool: HasParent = false;	// store fact of parent entity presence
	new bool: Result = true;		// error flag - used to stop execution if any error occurred
	new Particle = 0;				// store particle entity ID
	new Float: SpawnPos[3] = {0.0, 0.0, 0.0};	// store position where particle should be spawned
	new Float: SpawnAng[3] = {0.0, 0.0, 0.0};	// store angles for spawn
	new Ref = INVALID_ENT_REFERENCE;	// store reference for created particle entity
	
	// Check parameters
	
	if (ParentEntity > 0)	// if parent entity specified
	{
		HasParent = true;	// set flag variable
		Result &= IsValidEntity(ParentEntity);	// check if parent entity is valid
	}
	
	if (LifeTime < 0.0)	// negative life time is non-sense
	{
		Result &= false;
	}
	
	// Create particle
	
	if (Result)	// if no error in code above
	{
		if (HasParent)
		{
			// Save parent entity location to SpawnPos variable
			GetEntPropVector(ParentEntity, Prop_Send, "m_vecOrigin", SpawnPos);
			// Save rotation of parent entity
			// This is required if you want attach eye light to player correctly
			GetEntPropVector(ParentEntity, Prop_Send, "m_angRotation", SpawnAng);
			SpawnPos[0] += Position[0];
			SpawnPos[1] += Position[1];
			SpawnPos[2] += Position[2];
		}
		else
		{
			SpawnPos = Position;
		}
		
		Particle = CreateEntityByName("info_particle_system");	// create particle entity
		
		// Place particle in spawn point
		TeleportEntity(Particle, SpawnPos, SpawnAng, NULL_VECTOR);
		
		// Set particle style
		DispatchKeyValue(Particle, "effect_name", NameID);
		// Spawn particle
		DispatchSpawn(Particle);
		
		if (HasParent && SetParent)
		{
			// Set parent entity 
			SetVariantString("!activator");
			AcceptEntityInput(Particle, "SetParent", ParentEntity);
			// Attach particle to part of parent entity
			if (strlen(AttachTo) > 0)
			{
				SetVariantString(AttachTo);
				AcceptEntityInput(Particle, "SetParentAttachmentMaintainOffset");
			}
		}
		
		// Initialize particle
		ActivateEntity(Particle);
		AcceptEntityInput(Particle, "start");
		
		Ref = EntIndexToEntRef(Particle);
		
		// Create destroy timer if required
		if (LifeTime > 0.0)
		{
			// We use conversion of entity ID to entity reference
			// because entity ID can change and it's reliable only in short amount of time
			CreateTimer(LifeTime, Timer_DeleteParticle, Ref);
		}
	}
	
	return Ref;
}
//──────────────────────────────────────────────────────────────────────────────
// Kill particle by entity reference
// If you have problems like weapons or etc. got disappear - this function probably the reason
// Be careful with it
// Recommend to manually set Refer variable to INVALID_ENT_REFERENCE after calling this function
stock ParticleDestroy(Refer)
{
	// Once I was trying to store and remove particles by its entity ID
	// but it's caused problems since entity ID is changing a lot
	// and this function has remove weapons, etc.
	// Use entity reference when need to save entity ID for long time
	// See https://wiki.alliedmods.net/Entity_References_%28SourceMod%29
	new Particle = EntRefToEntIndex(Refer);
	// Don't remove this log line - just left it commented
	//LogAction(-1, -1, "%s destroy particle %d", LOG_PREFIX, Particle);
	if(Particle > MaxClients && IsValidEntity(Particle))
	{
		//LogAction(-1, -1, "%s done", LOG_PREFIX, Particle);
		AcceptEntityInput(Particle, "Kill");
		Refer = INVALID_ENT_REFERENCE;	// this won't work sometimes somehow
		// probably because of multi-threading
	}
}
//──────────────────────────────────────────────────────────────────────────────
public Action:Timer_DeleteParticle(Handle: hTimer, any: EntRef)
{
	ParticleDestroy(EntRef);
	return Plugin_Handled;
}
//──────────────────────────────────────────────────────────────────────────────
stock DecorHeal(Client)
{
	if (IsPlayerAlive(Client))
	{
		new Team = GetClientTeam(Client);
		if (Team == _:TFTeam_Red)
		{
			ParticleCreate("spell_overheal_red", _, 0.0, Client);
		}
		if (Team == _:TFTeam_Blue)
		{
			ParticleCreate("spell_overheal_blue", _, 0.0, Client);
		}
	}
}
//──────────────────────────────────────────────────────────────────────────────
stock DecorSpell(Client)
{
	if (IsPlayerAlive(Client))
	{
		new Team = GetClientTeam(Client);
		if (Team == _:TFTeam_Red)
		{
			ParticleCreate("spell_cast_wheel_red", _, 0.0, Client);
		}
		if (Team == _:TFTeam_Blue)
		{
			ParticleCreate("spell_cast_wheel_blue", _, 0.0, Client);
		}
	}
}
//──────────────────────────────────────────────────────────────────────────────
// Decorate building appear
stock DecorBuild(Ent)
{
	if (Ent > MaxClients && IsValidEntity(Ent))
	{
		new String: ClassName[STR_LEN];
		GetEntityClassname(Ent, ClassName, STR_LEN);
		if(StrEqual(ClassName, "obj_dispenser") || StrEqual(ClassName, "obj_sentrygun"))
		{
			ParticleCreate("heavy_ring_of_fire_fp_child03", _, 2.0, Ent);
			new Team = GetEntProp(Ent, Prop_Send, "m_iTeamNum");
			if (Team == _:TFTeam_Red)
			{
				ParticleCreate("teleportedin_red", _, 0.0, Ent);
				ParticleCreate("player_recent_teleport_red", _, 1.5, Ent);
			}
			if (Team == _:TFTeam_Blue)
			{
				ParticleCreate("teleportedin_blue", _, 0.0, Ent);
				ParticleCreate("player_recent_teleport_blue", _, 1.5, Ent);
			}
		}
	}
}
//──────────────────────────────────────────────────────────────────────────────
// Decorate building kill
stock DecorBuildKill(Ent)
{
	if (Ent > MaxClients && IsValidEntity(Ent))
	{
		new String: ClassName[STR_LEN];
		GetEntityClassname(Ent, ClassName, STR_LEN);
		if(StrEqual(ClassName, "obj_dispenser") || StrEqual(ClassName, "obj_sentrygun"))
		{
			ParticleCreate("bot_death", _, 0.0, Ent, false);
			new Team = GetEntProp(Ent, Prop_Send, "m_iTeamNum");
			if (Team == _:TFTeam_Red)
			{
				ParticleCreate("teleported_red", _, 0.0, Ent, false);
				ParticleCreate("player_recent_teleport_red", _, 0.5, Ent, false);
			}
			if (Team == _:TFTeam_Blue)
			{
				ParticleCreate("teleported_blue", _, 0.0, Ent, false);
				ParticleCreate("player_recent_teleport_blue", _, 0.5, Ent, false);
			}
		}
	}
}
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
		flEndPos[2] += 0.1;
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
	SetEntityModel(entity, sModel);

	SetEntProp(entity, Prop_Send, "m_iAmmoShells", iShells);
	SetEntProp(entity, Prop_Send, "m_iHealth", iHealth);
	SetEntProp(entity, Prop_Send, "m_iMaxHealth", iHealth);
	SetEntProp(entity, Prop_Send, "m_iObjectType", _:TFObject_Sentry);

	SetEntProp(entity, Prop_Send, "m_iTeamNum", iTeam);
	new iSkin = iTeam - 2;
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
	if (offs > 0)
	{
		SetEntData(entity, offs-12, 1, 1, true);
	}
	
	//new offs = FindSendPropInfo("CObjectSentrygun", "m_nShieldLevel");
	//if (offs <= 0) return Plugin_Handled;
	//SetEntData(entity, offs+12, fireattach[0]);
	//SetEntData(entity, offs+16, fireattach[1]);
	//SetEntData(entity, offs+20, fireattach[2]);
	
	// Shot event to notify about building object
	// It's required for correct working of mvm_redblu mod
	new Handle: Event = CreateEvent("player_builtobject");
	if (Event != INVALID_HANDLE)
	{
		SetEventInt(Event, "userid", GetClientUserId(iBuilder));
		SetEventInt(Event, "index", entity);
		FireEvent(Event);
	}
	
	DecorBuild(entity);
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
	if (offs > 0)
	{
		SetEntData(entity, offs-12, 1, 1, true);
	}
	
	// Shot event to notify about building object
	// It's required for correct working of mvm_redblu mod
	new Handle: Event = CreateEvent("player_builtobject");
	if (Event != INVALID_HANDLE)
	{
		SetEventInt(Event, "userid", GetClientUserId(iBuilder));
		SetEventInt(Event, "index", entity);
		FireEvent(Event);
	}
	
	DecorBuild(entity);
}
//──────────────────────────────────────────────────────────────────────────────
stock KillAllSentry(Client)
{
	new Ent = -1;
	while((Ent = FindEntityByClassname(Ent, "obj_sentrygun")) != -1)
	{
		if(GetEntPropEnt(Ent, Prop_Send,"m_hBuilder") == Client)
		{
			DecorBuildKill(Ent);
			AcceptEntityInput(Ent, "Kill");
		}
	}
}
//──────────────────────────────────────────────────────────────────────────────
// Destroy building at aim position
stock KillAim(Client)
{
	//var
	new bool: Result = false;
	new Ent = GetClientAimTarget(Client, false);
	new String: ClassName[STR_LEN];

	if(IsValidEntity(Ent))
	{
		GetEntityClassname(Ent, ClassName, STR_LEN);
		if(StrEqual(ClassName, "obj_dispenser") || StrEqual(ClassName, "obj_sentrygun"))
		{
			if(GetEntPropEnt(Ent, Prop_Send, "m_hBuilder") == Client)
			{
				DecorBuildKill(Ent);
				AcceptEntityInput(Ent, "Kill");
				Result = true;
			}
			else
			{
				ReplyToCommand(Client, "%s This building is not yours!", CHAT_PREFIX);
			}
		}
		else
		{
			ReplyToCommand(Client, "%s Not a building", CHAT_PREFIX);
		}
	}
	else
	{
		ReplyToCommand(Client, "%s No building found at aim", CHAT_PREFIX);
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
stock KillAllDisp(Client)
{
	new Ent = -1;
	while((Ent = FindEntityByClassname(Ent, "obj_dispenser")) != -1)
	{
		if(GetEntPropEnt(Ent, Prop_Send,"m_hBuilder") == Client)
		{
			DecorBuildKill(Ent);
			AcceptEntityInput(Ent, "Kill");
		}
	}
}
//──────────────────────────────────────────────────────────────────────────────
stock CountAllSentry(Client)
{
	new index = -1;
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
// Check if client is normal player that already in game
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
	
	return true;
}
//──────────────────────────────────────────────────────────────────────────────
stock IsValidBot(Client)
{
	if(!IsValidClient(Client))
	{
		return false;
	}
	
	if(GetClientTeam(Client) <= 1)	// unassigned or spectators
	{
		return false;
	}
	
	return IsFakeClient(Client);
}
//──────────────────────────────────────────────────────────────────────────────
// Get client wait time multiplier - used to lower wait time for admins and premium players
stock Float: GetMult(Client)
{
	new Float: Result = 1.0;
	if (CheckCommandAccess(Client, CMD_ADMIN, ADMFLAG_ROOT, true))
	{
		Result = WaitMultAdmin;
	}
	else if (CheckCommandAccess(Client, CMD_PREMIUM, ADMFLAG_ROOT, true))
	{
		Result = WaitMultPrem;
	}
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
// 0 - ready
// > 0 - delay
// -1 - effect limited
// < -1 -  disabled
// Index here is NOT effect ID
// Multiplier - to get lower wait time - use GetMult function for this
// GetMult is separated function because we don't want
// check Multiplier for every effect in menu, we check once and re-use value
stock IsEffectReady(client, Index, Float: Mult = 1.0)
{
	new Result = READY;
		
	// How much time passed since last use of effect
	new TimePass = GetTime() - Players[client][TimeUsed][Index];
	if(Players[client][TimeUsed][Index] && TimePass < Effects[Index][Delay])
	{
		// If time passed is less than delay - tell player to wait more
		Result = RoundToNearest(float(Effects[Index][Delay]) * Mult) - TimePass;
		// Avoid errors with negative values here
		if (Result < 0)
		{
			Result = 0;
		}
	}
	
	// If effect is sentry or dispenser building - then check how many buildings player own already
	new Count = 0;
	if(Effects[Index][GID] == BUILD)
	{
		if(Effects[Index][ID] == SENTRY1 || Effects[Index][ID] == SENTRY2 || Effects[Index][ID] == SENTRY3 || Effects[Index][ID] == SENTRYMIN)
		{
			Count = CountAllSentry(client);
		}
		else if(Effects[Index][ID] == DISP)
		{
			Count = CountAllDisp(client);
		}
	}
	if(Count != 0 && Count >= BuildLimit)
	{
		Result = LIMIT;
	}
	
	// Check if effect enabled
	if(Effects[Index][Delay] < 0)
	{
		Result = DISABLED;
	}
	
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
// Print help
PrintHelp(Client)
{
	PrintToChat(Client, "%s Write \x07FFA500!spells\x01 or \x07FFA500!canteen\x01 or \x07FFA500!build\x01 or \x07FFA500!effects\x01 for menu", CHAT_PREFIX);
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
	Effects[i][Delay] = 1;
	Format(Effects[i][Name], STR_LEN, "transpose");
	Format(Effects[i][Desc], STR_LEN, "Transpose");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_spelldelay_transpose");
	i++;
	
	//Effects[i][ID] = PUMPKIN2;
	//Effects[i][GID] = SPELL;
	//Effects[i][Delay] = 1;
	//Format(Effects[i][Name], STR_LEN, "pumpkin");
	//Format(Effects[i][Desc], STR_LEN, "Pumpkin");
	//Format(Effects[i][DelayCVar], STR_LEN, "sm_spelldelay_pumpkin");
	//i++;
	
	Effects[i][ID] = FIREBALL;
	Effects[i][GID] = SPELL;
	Effects[i][Delay] = 10;
	Format(Effects[i][Name], STR_LEN, "fireball");
	Format(Effects[i][Desc], STR_LEN, "Fireball");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_spelldelay_fireball");
	i++;
	
	Effects[i][ID] = BATS;
	Effects[i][GID] = SPELL;
	Effects[i][Delay] = 12;
	Format(Effects[i][Name], STR_LEN, "bats");
	Format(Effects[i][Desc], STR_LEN, "Bats");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_spelldelay_bats");
	i++;
	
	//Effects[i][ID] = PUMPKIN;
	//Effects[i][GID] = SPELL;
	//Effects[i][Delay] = 10;
	//Format(Effects[i][Name], STR_LEN, "pumpkins");
	//Format(Effects[i][Desc], STR_LEN, "Pumpkins");
	//Format(Effects[i][DelayCVar], STR_LEN, "sm_spelldelay_pumpkins");
	//i++;
	
	Effects[i][ID] = LIGHTNING;
	Effects[i][GID] = SPELL;
	Effects[i][Delay] = 45;
	Format(Effects[i][Name], STR_LEN, "lightning");
	Format(Effects[i][Desc], STR_LEN, "Lightning");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_spelldelay_lightning");
	i++;
	
	//Effects[i][ID] = ZOMBIEH;
	//Effects[i][GID] = SPELL;
	//Effects[i][Delay] = 180;
	//Format(Effects[i][Name], STR_LEN, "skeletons");
	//Format(Effects[i][Desc], STR_LEN, "Skeletons");
	//Format(Effects[i][DelayCVar], STR_LEN, "sm_spelldelay_skeletons");
	//i++;
	
	Effects[i][ID] = ZOMBIE;
	Effects[i][GID] = SPELL;
	Effects[i][Delay] = 55;
	Format(Effects[i][Name], STR_LEN, "skeleton");
	Format(Effects[i][Desc], STR_LEN, "Skeleton");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_spelldelay_skeleton");
	i++;
	
	Effects[i][ID] = BOSS;
	Effects[i][GID] = SPELL;
	Effects[i][Delay] = 240;
	Format(Effects[i][Name], STR_LEN, "monoculus");
	Format(Effects[i][Desc], STR_LEN, "Monoculus");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_spelldelay_monoculus");
	i++;
	
	Effects[i][ID] = METEOR;
	Effects[i][GID] = SPELL;
	Effects[i][Delay] = 180;
	Format(Effects[i][Name], STR_LEN, "meteors");
	Format(Effects[i][Desc], STR_LEN, "Meteor Shower");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_spelldelay_meteors");
	i++;
	
	// Canteen
	
	Effects[i][ID] = UBER;
	Effects[i][GID] = CHARGE;
	Effects[i][Delay] = 60;
	Format(Effects[i][Name], STR_LEN, "uber");
	Format(Effects[i][Desc], STR_LEN, "Uber Charge");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_chargedelay_uber");
	i++;
	
	Effects[i][ID] = CRIT;
	Effects[i][GID] = CHARGE;
	Effects[i][Delay] = 75;
	Format(Effects[i][Name], STR_LEN, "crit");
	Format(Effects[i][Desc], STR_LEN, "Critical Charge");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_chargedelay_crit");
	i++;
	
	Effects[i][ID] = REGEN;
	Effects[i][GID] = CHARGE;
	Effects[i][Delay] = 100;
	Format(Effects[i][Name], STR_LEN, "regen");
	Format(Effects[i][Desc], STR_LEN, "Refill Ammo and Health");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_chargedelay_regen");
	i++;
	
	Effects[i][ID] = INVIS;
	Effects[i][GID] = CHARGE;
	Effects[i][Delay] = 15;
	Format(Effects[i][Name], STR_LEN, "cloak");
	Format(Effects[i][Desc], STR_LEN, "Cloak");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_chargedelay_cloak");
	i++;
	
	Effects[i][ID] = BASE;
	Effects[i][GID] = CHARGE;
	Effects[i][Delay] = 25;
	Format(Effects[i][Name], STR_LEN, "base");
	Format(Effects[i][Desc], STR_LEN, "Teleport to the Base");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_chargedelay_base");
	i++;
	
	Effects[i][ID] = SPEED;
	Effects[i][GID] = CHARGE;
	Effects[i][Delay] = 35;
	Format(Effects[i][Name], STR_LEN, "speed");
	Format(Effects[i][Desc], STR_LEN, "Speed-up");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_chargedelay_speed");
	i++;
	
	Effects[i][ID] = HEAL;
	Effects[i][GID] = CHARGE;
	Effects[i][Delay] = 520;
	Format(Effects[i][Name], STR_LEN, "heal");
	Format(Effects[i][Desc], STR_LEN, "Add Health");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_chargedelay_heal");
	i++;
	
	// Building
	
	Effects[i][ID] = SENTRY1;
	Effects[i][GID] = BUILD;
	Effects[i][Delay] = 15;
	Format(Effects[i][Name], STR_LEN, "sentry1");
	Format(Effects[i][Desc], STR_LEN, "Build Sentry Level 1");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_builddelay_sentry1");
	i++;
	
	Effects[i][ID] = SENTRY2;
	Effects[i][GID] = BUILD;
	Effects[i][Delay] = 30;
	Format(Effects[i][Name], STR_LEN, "sentry2");
	Format(Effects[i][Desc], STR_LEN, "Build Sentry Level 2");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_builddelay_sentry2");
	i++;
	
	Effects[i][ID] = SENTRY3;
	Effects[i][GID] = BUILD;
	Effects[i][Delay] = 60;
	Format(Effects[i][Name], STR_LEN, "sentry3");
	Format(Effects[i][Desc], STR_LEN, "Build Sentry Level 3");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_builddelay_sentry3");
	i++;
	
	Effects[i][ID] = SENTRYMIN;
	Effects[i][GID] = BUILD;
	Effects[i][Delay] = 15;
	Format(Effects[i][Name], STR_LEN, "sentrymini");
	Format(Effects[i][Desc], STR_LEN, "Build Sentry Mini");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_builddelay_sentrymini");
	i++;
	
	Effects[i][ID] = DISP;
	Effects[i][GID] = BUILD;
	Effects[i][Delay] = 10;
	Format(Effects[i][Name], STR_LEN, "disp");
	Format(Effects[i][Desc], STR_LEN, "Build Dispenser");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_builddelay_disp");
	i++;
	
	Effects[i][ID] = KILLAIM;
	Effects[i][GID] = BUILD;
	Effects[i][Delay] = 1;
	Format(Effects[i][Name], STR_LEN, "killaim");
	Format(Effects[i][Desc], STR_LEN, "Destroy Building at Aim");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_builddelay_killaim");
	i++;
	
	Effects[i][ID] = KILLBUILD;
	Effects[i][GID] = BUILD;
	Effects[i][Delay] = 1;
	Format(Effects[i][Name], STR_LEN, "killbuild");
	Format(Effects[i][Desc], STR_LEN, "Destroy All Buildings");
	Format(Effects[i][DelayCVar], STR_LEN, "sm_builddelay_killbuild");
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
	
	if (!CheckCommandAccess(client, CMD_ACCESS, ADMFLAG_NONE, true))
	{
		ReplyToCommand(client, "%s You don't have access to this command", CHAT_PREFIX);
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
	DisplayMenu(MainMenu, Client, MENU_TIME_FOREVER);

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
	
	if (!CheckCommandAccess(client, CMD_ACCESS, ADMFLAG_NONE, true))
	{
		ReplyToCommand(client, "%s You don't have access to this command", CHAT_PREFIX);
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
	
	// Get player wait time multiplier
	new Float: Mult = GetMult(client);
	
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
			iDelay = IsEffectReady(client, Index, Mult);
			if(iDelay == READY)
			{
				AddMenuItem(Menu, Effects[Index][Name], Effects[Index][Desc]);
			}
			else if(iDelay > 0)
			{
				Format(Msg, sizeof(Msg), "%s (%d sec)", Effects[Index][Desc], iDelay);
				AddMenuItem(Menu, Effects[Index][Name], Msg, ITEMDRAW_DISABLED);
			}
			else if(iDelay == LIMIT)
			{
				Format(Msg, sizeof(Msg), "%s (limit)", Effects[Index][Desc]);
				AddMenuItem(Menu, Effects[Index][Name], Msg, ITEMDRAW_DISABLED);
			}
			else if(iDelay == DISABLED)
			{
				Format(Msg, sizeof(Msg), "%s (disabled)", Effects[Index][Desc]);
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
	// Get player wait time multiplier
	new Float: Mult = GetMult(Client);
	// Is it ready?
	new TimeWait = IsEffectReady(Client, Index, Mult);	// 0 - ready; > 0 - time to wait; -1 - limit reached; < -1 - disabled
	if(TimeWait > 0)
	{
		// Effect is not ready - notify player
		PrintToChat(Client, "%s Wait \x07FFA500%d\x01 second(s)", CHAT_PREFIX, TimeWait);
		return;
	}
	else if(TimeWait == LIMIT)
	{
		// Effect limited
		PrintToChat(Client, "%s Limit reached", CHAT_PREFIX);
		return;
	}
	else if(TimeWait == DISABLED)
	{
		// Effect disabled
		PrintToChat(Client, "%s Effect disabled", CHAT_PREFIX);
		return;
	}
	
	if(Effects[Index][GID] == SPELL)
	{
		ShootProjectile(Client, Effects[Index][ID]);
		DecorSpell(Client);
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
		case SENTRY1:
		{
			GetClientEyeTraceVec(Client, Position, Angle);
			BuildSentry(Client, Position, Angle, 1, false);
		}
		case SENTRY2:
		{
			GetClientEyeTraceVec(Client, Position, Angle);
			BuildSentry(Client, Position, Angle, 2, false);
		}
		case SENTRY3:
		{
			GetClientEyeTraceVec(Client, Position, Angle);
			BuildSentry(Client, Position, Angle, 3, false);
		}
		case SENTRYMIN:
		{
			GetClientEyeTraceVec(Client, Position, Angle);
			BuildSentry(Client, Position, Angle, 1, true);
		}
		case DISP:	
		{
			GetClientEyeTraceVec(Client, Position, Angle);
			BuildDispenser(Client, Position, Angle, 3);
		}
		case KILLBUILD:
		{
			KillAllSentry(Client);
			KillAllDisp(Client);
		}
		case KILLAIM:
		{
			KillAim(Client);
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
			// Visual decoration for this effect done in TF2_OnConditionAdded event
			TF2_AddCondition(Client, TFCond_UberchargedCanteen, 15.0);
		}
		case CRIT:	
		{
			// Visual decoration for this effect done in TF2_OnConditionAdded event
			TF2_AddCondition(Client, TFCond_CritCanteen, 15.0);
		}
		case REGEN:
		{
			TF2_RegeneratePlayer(Client);
		}
		case INVIS:
		{
			TF2_AddCondition(Client, TFCond_Stealthed, 15.0);
		}
		case BASE:
		{
			TF2_RespawnPlayer(Client);
		}
		case SPEED:
		{
			TF2_AddCondition(Client,  TFCond_SpeedBuffAlly, 15.0);
			ParticleCreate("sapper_coreflash", _, _, Client);
			ParticleCreate("sapper_flash", _, _, Client);
			ParticleCreate("sapper_flashup", _, _, Client);
			ParticleCreate("sapper_flyingembers", _, _, Client);
			ParticleCreate("sapper_smoke", _, _, Client);
		}
		case HEAL:
		{
			new Health = GetClientHealth(Client) + 5000;
			SetEntityHealth(Client, Health);
			DecorHeal(Client);
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
