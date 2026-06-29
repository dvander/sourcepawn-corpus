#define PLUGIN_VERSION		"1.6y"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Fireworks Party
*	Author	:	SilverShot (idea by jjjapan) Crate Spawn mod by YoNer
*	Descrp	:	Adds fireworks to the firework crate explosions.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=153783

========================================================================================
	Change Log:

1.6y (03-03-2017)
	- Added sm_fxbow command to manually spawn crates
	- Improved spawn position code   

1.6 (10-May-2012)
	- Added cvar "l4d2_fireworks_modes" to control which game modes the plugin works in.
	- Added cvar "l4d2_fireworks_modes_off" same as above.
	- Added cvar "l4d2_fireworks_modes_tog" same as above.
	- Optimized the plugin by hooking cvar changes.
	- Fixed a bug which could cause a server to lock up.
	- Removed max entity check and related error logging.

1.5 (22-May-2011)
	- Added check for scavenge items to disable converting of gascans.
	- Added check to not spawn fireworks when GetEntityCount reaches MAX_ENTITIES.
	- Added 6 second delay after the first player spawns or round_start to convert items to firework crates.
	- Changed cvar defaults for "l4d2_fireworks_convert_propane", "l4d2_fireworks_convert_oxygen", "l4d2_fireworks_convert_gas" to "50".
	- Changed cvar default for "l4d2_fireworks_chase" from 10 to 15.
	- Changed cvar default for "l4d2_fireworks_allow_gas" from 1 to 0.

1.4 (18-May-2011)
	- Added cvar "l4d2_fireworks_chase" - which controls how long zombies are attracted to firework explosions.

1.3 (10-Apr-2011)
	- Added admin command "sm_fw" or "sm_fireworks" to spawn fireworks on crosshair position.

1.2 (03-Apr-2011)
	- Added cvar "l4d2_fireworks_allow_gas" to display fireworks on gascan explosions.
	- Added cvar "l4d2_fireworks_allow_oxygen" to display fireworks on oxygen tank explosions.
	- Added cvar "l4d2_fireworks_allow_propane" to display fireworks on propane tank explosions.
	- Added cvar "l4d2_fireworks_convert_oxygen" to convert a percentage of oxygen tanks into firework crates.
	- Added cvar "l4d2_fireworks_convert_propane" to convert a percentage of propane tanks into firework crates.

1.1 (02-Apr-2011)
	- Added cvar "l4d2_fireworks_convert_gas" to convert a percentage of gascans into firework crates.
	- Changed various default cvars and cvar limits.

1.0 (29-Mar-2011)
	- Initial release.

========================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Thanks to "honorcode23" for PrecacheParticle()

*	"Zuko & McFlurry" for "[L4D2] Weapon/Zombie Spawner" - Modified the SetTeleportEndPoint()
	http://forums.alliedmods.net/showthread.php?t=109659

======================================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS				FCVAR_NOTIFY
#define MAX_PARTICLES			50 // WARNING: excessive amounts of fireworks can crash the game!

#define MODEL_CRATE				"models/props_junk/explosive_box001.mdl"
#define MODEL_GASCAN			"models/props_junk/gascan001a.mdl"
#define MODEL_OXYGEN			"models/props_equipment/oxygentank01.mdl"
#define MODEL_PROPANE			"models/props_junk/propanecanister001a.mdl"


// Cvar handles
static	Handle:g_hCvarAllow, Handle:g_hCvarGas, Handle:g_hCvarOxy, Handle:g_hCvarPro, Handle:g_hCvarChase, Handle:g_hCvarInitMax, Handle:g_hCvarInitMin,
		Handle:g_hCvarModes, Handle:g_hCvarModesOff, Handle:g_hCvarModesTog, Handle:g_hCvarDelayMax, Handle:g_hCvarDelayMin, Handle:g_hCvarDelayRan,
		Handle:g_hCvarMaxTime, Handle:g_hCvarMinTime, Handle:g_hCvarType, Handle:g_hCvarConvert1, Handle:g_hCvarConvert2, Handle:g_hCvarConvert3,

		bool:g_bCvarAllow, g_iCvarGas, g_iCvarOxy, g_iCvarPro, g_iCvarChase, g_iCvarInitMax, g_iCvarInitMin,
		g_iCvarDelayMax, g_iCvarDelayMin, g_iCvarDelayRan, Float:g_fCvarMaxTime, Float:g_fCvarMinTime, g_iCvarType,
		g_iCvarConvert1, g_iCvarConvert2, g_iCvarConvert3,

// Globals
		Handle:g_hMPGameMode, g_iParticleCount, Float:g_fLastPlayed, g_iPlayerSpawn, g_iRoundStart;


// Firework types
enum (<<=1)
{
	TYPE_RED = 1,
	TYPE_BLUE,
	TYPE_GOLD,
	TYPE_FLASH
}

static const String:g_sParticles[4][16] =
{
	"fireworks_01",
	"fireworks_02",
	"fireworks_03",
	"fireworks_04"
};

static const String:g_sSoundsLaunch[6][45] =
{
	"ambient/atmosphere/firewerks_launch_01.wav",
	"ambient/atmosphere/firewerks_launch_02.wav",
	"ambient/atmosphere/firewerks_launch_03.wav",
	"ambient/atmosphere/firewerks_launch_04.wav",
	"ambient/atmosphere/firewerks_launch_05.wav",
	"ambient/atmosphere/firewerks_launch_06.wav"
};

static const String:g_sSoundsBursts[4][45] =
{
	"ambient/atmosphere/firewerks_burst_01.wav",
	"ambient/atmosphere/firewerks_burst_02.wav",
	"ambient/atmosphere/firewerks_burst_03.wav",
	"ambient/atmosphere/firewerks_burst_04.wav"
};



// ====================================================================================================
//					EVENTS
// ====================================================================================================
// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin:myinfo =
{
	name = "[L4D2] Fireworks Party",
	author = "SilverShot",
	description = "Adds fireworks to the firework crate explosions.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=153783"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if( strcmp(sGameName, "left4dead2", false) )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	g_hCvarAllow =		CreateConVar(	"l4d2_fireworks_allow",				"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarGas =		CreateConVar(	"l4d2_fireworks_allow_gas",			"0",			"Allow gascan explosions to display fireworks (only works on cans which have not been picked up).", CVAR_FLAGS);
	g_hCvarOxy =		CreateConVar(	"l4d2_fireworks_allow_oxygen",		"0",			"Allow oxygen tank explosions to display fireworks.", CVAR_FLAGS);
	g_hCvarPro =		CreateConVar(	"l4d2_fireworks_allow_propane",		"0",			"Allow propane tank explosions to display fireworks.", CVAR_FLAGS);
	g_hCvarChase =		CreateConVar(	"l4d2_fireworks_chase",				"10",			"0=Off. How long zombies are attracted to firework explosions.", CVAR_FLAGS, true, 0.0, true, 20.0);
	g_hCvarConvert1 =	CreateConVar(	"l4d2_fireworks_convert_gas",		"50",			"Percentage of gascans to convert into firework crates.", CVAR_FLAGS, true, 0.0, true, 100.0);
	g_hCvarConvert2 =	CreateConVar(	"l4d2_fireworks_convert_oxygen",	"50",			"Percentage of oxygen tanks to convert into firework crates.", CVAR_FLAGS, true, 0.0, true, 100.0);
	g_hCvarConvert3 =	CreateConVar(	"l4d2_fireworks_convert_propane",	"50",			"Percentage of propane tanks to convert into firework crates.", CVAR_FLAGS, true, 0.0, true, 100.0);
	g_hCvarDelayMax =	CreateConVar(	"l4d2_fireworks_delay_max",			"10",			"Maximum delayed fireworks to display (0 disables delayed).", CVAR_FLAGS, true, 0.0, true, 20.0);
	g_hCvarDelayMin =	CreateConVar(	"l4d2_fireworks_delay_min",			"3",			"Minimum delayed fireworks to display.", CVAR_FLAGS, true, 0.0, true, 10.0);
	g_hCvarDelayRan =	CreateConVar(	"l4d2_fireworks_delay_ran",			"1",			"Randomise how many delayed fireworks display. 0=Max, 1=Random.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarMaxTime =	CreateConVar(	"l4d2_fireworks_delay_time_max",	"10.0",			"Max time after explosion for delayed fireworks to be created.", CVAR_FLAGS, true, 2.0, true, 20.0);
	g_hCvarMinTime =	CreateConVar(	"l4d2_fireworks_delay_time_min",	"0.2",			"Min time after explosion before delayed fireworks can show.", CVAR_FLAGS, true, 0.1, true, 15.0);
	g_hCvarInitMax =	CreateConVar(	"l4d2_fireworks_init_max",			"3",			"Maximum fireworks to display on initial explosion (0 disables).", CVAR_FLAGS, true, 0.0, true, 10.0);
	g_hCvarInitMin =	CreateConVar(	"l4d2_fireworks_init_min",			"0",			"Minimum fireworks to display on initial explosion.", CVAR_FLAGS, true, 0.0, true, 10.0);
	g_hCvarModes =		CreateConVar(	"l4d2_fireworks_modes",				"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d2_fireworks_modes_off",			"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d2_fireworks_modes_tog",			"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarType =		CreateConVar(	"l4d2_fireworks_type",				"15",			"Which fireworks to display. Bit flags, add up the numbers. 1=Red; 2=Blue; 4=Gold; 8=Flash", CVAR_FLAGS);
	CreateConVar(						"l4d2_fireworks_version",			PLUGIN_VERSION,	"Fireworks Party plugin version.", CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d2_fireworks_party");

	g_hMPGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hMPGameMode,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarAllow,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarModes,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesOff,	ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesTog,	ConVarChanged_Allow);
	HookConVarChange(g_hCvarGas,		ConVarChanged_Cvars);
	HookConVarChange(g_hCvarOxy,		ConVarChanged_Cvars);
	HookConVarChange(g_hCvarPro,		ConVarChanged_Cvars);
	HookConVarChange(g_hCvarChase,		ConVarChanged_Cvars);
	HookConVarChange(g_hCvarInitMax,	ConVarChanged_Cvars);
	HookConVarChange(g_hCvarInitMin,	ConVarChanged_Cvars);
	HookConVarChange(g_hCvarDelayMax,	ConVarChanged_Cvars);
	HookConVarChange(g_hCvarDelayMin,	ConVarChanged_Cvars);
	HookConVarChange(g_hCvarDelayRan,	ConVarChanged_Cvars);
	HookConVarChange(g_hCvarMaxTime,	ConVarChanged_Cvars);
	HookConVarChange(g_hCvarMinTime,	ConVarChanged_Cvars);
	HookConVarChange(g_hCvarType,		ConVarChanged_Cvars);
	HookConVarChange(g_hCvarConvert1,	ConVarChanged_Cvars);
	HookConVarChange(g_hCvarConvert2,	ConVarChanged_Cvars);
	HookConVarChange(g_hCvarConvert3,	ConVarChanged_Cvars);

	RegAdminCmd("sm_fireworks", CmdFireworks, ADMFLAG_ROOT);
	RegAdminCmd("sm_fw", CmdFireworks, ADMFLAG_ROOT);
	RegAdminCmd("sm_fwbox", CmdCrate, ADMFLAG_ROOT);
}

public OnMapStart()
{
	new i;
	for( i = 0; i <= 3; i++ ) PrecacheParticle(g_sParticles[i]);
	for( i = 0; i <= 3; i++ ) PrecacheSound(g_sSoundsBursts[i], true);
	for( i = 0; i <= 5; i++ ) PrecacheSound(g_sSoundsLaunch[i], true);
	PrecacheModel(MODEL_CRATE, true);
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public OnConfigsExecuted()
{
	GetCvars();
	IsAllowed();
}

public ConVarChanged_Cvars(Handle:convar, const String:oldValue[], const String:newValue[])
	GetCvars();

public ConVarChanged_Allow(Handle:convar, const String:oldValue[], const String:newValue[])
	IsAllowed();

GetCvars()
{
	g_iCvarGas = GetConVarInt(g_hCvarGas);
	g_iCvarOxy = GetConVarInt(g_hCvarOxy);
	g_iCvarPro = GetConVarInt(g_hCvarPro);
	g_iCvarChase = GetConVarInt(g_hCvarChase);
	g_iCvarInitMax = GetConVarInt(g_hCvarInitMax);
	g_iCvarInitMin = GetConVarInt(g_hCvarInitMin);
	g_iCvarDelayMax = GetConVarInt(g_hCvarDelayMax);
	g_iCvarDelayMin = GetConVarInt(g_hCvarDelayMin);
	g_iCvarDelayRan = GetConVarInt(g_hCvarDelayRan);
	g_fCvarMaxTime = GetConVarFloat(g_hCvarMaxTime);
	g_fCvarMinTime = GetConVarFloat(g_hCvarMinTime);
	g_iCvarType = GetConVarInt(g_hCvarType);
	g_iCvarConvert1 = GetConVarInt(g_hCvarConvert1);
	g_iCvarConvert2 = GetConVarInt(g_hCvarConvert2);
	g_iCvarConvert3 = GetConVarInt(g_hCvarConvert3);
}

IsAllowed()
{
	new bool:bCvarAllow = GetConVarBool(g_hCvarAllow);
	new bool:bAllowMode = IsAllowedGameMode();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvents();
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		UnhookEvents();
	}
}

bool:IsAllowedGameMode()
{
	if( g_hMPGameMode == INVALID_HANDLE )
		return false;

	// Get game mode cvars, if empty allow.
	decl String:sGameModes[64], String:sGameMode[64];
	GetConVarString(g_hCvarModes, sGameModes, sizeof(sGameModes));
	if( strlen(sGameModes) == 0 )
		return true;

	// Better game mode check: ",versus," instead of "versus", which would return true for "teamversus" for example.
	GetConVarString(g_hMPGameMode, sGameMode, sizeof(sGameMode));
	Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);
	return (StrContains(sGameModes, sGameMode, false) != -1);
}



// ====================================================================================================
//					ADMIN COMMANDS
// ====================================================================================================
public Action:CmdFireworks(client, args)
{
	if( client && IsClientInGame(client) )
	{
		decl Float:vPos[3];
		decl Float:vAng[3];
	
		if( SetTeleportEndPoint(client, vPos, vAng) )
			MakeFireworks(vPos);
	}
	return Plugin_Handled;
}

public Action:CmdCrate(client, args)
{
	new entity;
	if( client && IsClientInGame(client) )
	{
		decl Float:vPos[3];
		decl Float:vAng[3];
		if( SetTeleportEndPoint(client, vPos, vAng) )
			
		entity = CreateEntityByName("physics_prop");
		if( entity != -1 )
		{
			vPos[2] += 3;
			SetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);
			SetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vAng);
			
			
			SetEntityModel(entity, MODEL_CRATE);
			DispatchSpawn(entity);
		}
			
			
			
	}
	return Plugin_Handled;
}

SetTeleportEndPoint(client, Float:vPos[3] = NULL_VECTOR, Float:vAng[3] = NULL_VECTOR)
{
	
	GetClientEyeAngles(client, vAng);
	GetClientEyePosition(client, vPos);


	new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer,client);

	if(TR_DidHit(trace))
	{
		
		TR_GetEndPosition(vPos, trace);
		CloseHandle(trace);

		vAng[0] = 0.0;
		vAng[1] += 90.0;
		vAng[2] = 0.0;
		
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	return true;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask, any:client)
{
	if( entity == client )
		return false;
	return true;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
HookEvents()
{
	HookEvent("break_prop",			Event_BreakProp,		EventHookMode_Pre);
	HookEvent("player_spawn",		Event_PlayerSpawn,		EventHookMode_PostNoCopy);
	HookEvent("round_start",		Event_RoundStart,		EventHookMode_PostNoCopy);
	HookEvent("round_end",			Event_RoundEnd,			EventHookMode_PostNoCopy);
}

UnhookEvents()
{
	UnhookEvent("break_prop",		Event_BreakProp,		EventHookMode_Pre);
	UnhookEvent("player_spawn",		Event_PlayerSpawn,		EventHookMode_PostNoCopy);
	UnhookEvent("round_start",		Event_RoundStart,		EventHookMode_PostNoCopy);
	UnhookEvent("round_end",		Event_RoundEnd,			EventHookMode_PostNoCopy);
}

public Event_BreakProp(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:sTemp[42], Float:vPos[3];
	new entity = GetEventInt(event, "entindex");
	GetEdictClassname(entity, sTemp, sizeof(sTemp));

	if( strcmp(sTemp, "prop_physics") == 0 )
	{
		GetEntPropString(entity, Prop_Data, "m_ModelName", sTemp, sizeof(sTemp));

		if( strcmp(sTemp, MODEL_CRATE) == 0 ||
			(g_iCvarGas && strcmp(sTemp, MODEL_GASCAN) == 0 ) ||
			(g_iCvarOxy && strcmp(sTemp, MODEL_OXYGEN) == 0 ) ||
			(g_iCvarPro && strcmp(sTemp, MODEL_PROPANE) == 0 )
		)
		{
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
			MakeFireworks(vPos);

			if( g_iCvarChase )
			{
				entity = CreateEntityByName("info_goal_infected_chase");
				if( entity != -1 )
				{
					DispatchSpawn(entity);
					vPos[2] += 2.0;
					TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
					Format(sTemp, sizeof(sTemp), "OnUser1 !self:kill::%d:1", g_iCvarChase);
					SetVariantString(sTemp);
					AcceptEntityInput(entity, "AddOutput");
					AcceptEntityInput(entity, "FireUser1");
					AcceptEntityInput(entity, "Enable");
				}
			}
		}
	}
}

public OnMapEnd()
{
	g_iParticleCount = 0;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iParticleCount = 0;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
	{
		CreateTimer(8.0, tmrConvert);
	}

	if( g_iPlayerSpawn == 0 )
	{
		g_iPlayerSpawn = 1;
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
	{
		CreateTimer(8.0, tmrConvert);
	}

	if( g_iRoundStart == 0 )
	{
		g_iRoundStart = 1;
	}
}

public Action:tmrConvert(Handle:timer)
{
	ConvertToCrates();
}

ConvertToCrates()
{
	new iReplace1 = g_iCvarConvert1;
	new iReplace2 = g_iCvarConvert2;
	new iReplace3 = g_iCvarConvert3;

	if( iReplace1 + iReplace2 + iReplace3 == 0 )
		return;

	decl String:sTemp[64];
	new entity, iCount1, iCount2, iCount3, iDone, iResult;


	// ======================================================================================
	// Do not replace gascans if 'gas_nozzle' is found
	// ======================================================================================
	if( iReplace1 )
	{
		entity = -1;
		while( (entity = FindEntityByClassname(entity, "point_prop_use_target") ) != -1 )
		{
			GetEntPropString(entity, Prop_Data, "m_sGasNozzleName", sTemp, 64);
			if( strcmp(sTemp, "gas_nozzle") == 0 )
			{
				iReplace1 = 0;
				break;
			}
		}
	}


	// ======================================================================================
	// Find 'prop_physics', gascan/oxygen/propane - COUNT
	// ======================================================================================
	entity = -1;

	while( (entity = FindEntityByClassname(entity, "prop_physics") ) != -1 )
	{
		GetEntPropString(entity, Prop_Data, "m_ModelName", sTemp, sizeof(sTemp));
		if( iReplace1 && strcmp(sTemp, MODEL_GASCAN) == 0 )
			iCount1++;
		else if( iReplace2 && strcmp(sTemp, MODEL_OXYGEN) == 0 )
			iCount2++;
		else if( iReplace3 && strcmp(sTemp, MODEL_PROPANE) == 0 )
			iCount3++;
	}


	// Percentage to replace
	if( iReplace1 && iCount1 )
		iResult = (iReplace1 * iCount1) / 100;
	if( iReplace2 )
		iResult += (iReplace2 * iCount2) / 100;
	if( iReplace3 )
		iResult += (iReplace3 * iCount3) / 100;


	// ======================================================================================
	// Find 'prop_physics', gascan/oxygen/propane - REPLACE
	// ======================================================================================
	iReplace1 = 0;
	iReplace2 = 0;
	iReplace3 = 0;
	entity = -1;

	while( (entity = FindEntityByClassname(entity, "prop_physics")) != -1 )
	{
		if( iDone < iResult )
		{
			GetEntPropString(entity, Prop_Data, "m_ModelName", sTemp, sizeof(sTemp));

			if( iReplace1 < iCount1 && strcmp(sTemp, MODEL_GASCAN) == 0 )
			{
				iReplace1++;
				iDone++;
				ReplaceCan(entity);
			}
			else if( iReplace2 < iCount2 && strcmp(sTemp, MODEL_OXYGEN) == 0 )
			{
				iReplace2++;
				iDone++;
				ReplaceCan(entity);
			}
			else if( iReplace3 < iCount3 && strcmp(sTemp, MODEL_PROPANE) == 0 )
			{
				iReplace3++;
				iDone++;
				ReplaceCan(entity);
			}
		}
		else
			break;
	}
}

ReplaceCan(entity)
{
	decl Float:vPos[3], Float:vAng[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vAng);
	AcceptEntityInput(entity, "kill");

	vAng[0] += 90;
	vPos[2] += 5.0;

	entity = CreateEntityByName("physics_prop");
	if( entity != -1 )
	{
		SetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);
		SetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vAng);
		SetEntityModel(entity, MODEL_CRATE);
		DispatchSpawn(entity);
	}
	return entity;
}



// ====================================================================================================
//					FIREWORKS
// ====================================================================================================
MakeFireworks(const Float:vOrigin[3])
{
	decl Float:vPos[3];
	vPos = vOrigin;
	new iAmount;
	// Display fireworks on initial explosion?
	if( g_iCvarInitMax )
	{
		iAmount = GetRandomInt(g_iCvarInitMin, g_iCvarInitMax);

		if( iAmount > 0 )
		{
			new iFirework, Float:fHeight, Float:vAng[3];

			for( new i = 0; i < iAmount; i++ )
			{
				fHeight = GetRandomFloat(300.0, 1400.0);
				vPos[2] -= fHeight;
				vAng[0] = GetRandomFloat(-10.0, 10.0);
				vAng[1] = GetRandomFloat(-10.0, 10.0);
				vAng[2] = GetRandomFloat(-10.0, 10.0);

				// Show fireworks and play sound
				iFirework = GetRandomFirework();
				ShowParticle(vPos, vAng, g_sParticles[iFirework]);
				PlaySound(vPos);

				// Reset origin
				vPos[2] += fHeight;
			}
		}
	}

	// Display random delayed fireworks?
	iAmount = g_iCvarDelayMax;
	if( iAmount )
	{
		// Random amount of fireworks? Or fixed amount?
		if( g_iCvarDelayRan )
			iAmount = GetRandomInt(g_iCvarDelayMin, iAmount);

		if( iAmount > 0 )
		{
			new Float:fTime, Handle:hPack;
			for( new i = 0; i < iAmount; i++ )
			{
				// Create timers to make delayed fireworks
				fTime = GetRandomFloat( g_fCvarMinTime, g_fCvarMaxTime );
				hPack = INVALID_HANDLE;
				CreateDataTimer(fTime, tmrRandomFirework, hPack);
				WritePackFloat(hPack, vPos[0]);
				WritePackFloat(hPack, vPos[1]);
				WritePackFloat(hPack, vPos[2]);
			}
		}
	}
}

public Action:tmrRandomFirework(Handle:timer, Handle:hPack)
{
	decl Float:vPos[3], Float:vAng[3];

	ResetPack(hPack);
	vPos[0] = ReadPackFloat(hPack);
	vPos[1] = ReadPackFloat(hPack);
	vPos[2] = ReadPackFloat(hPack);

	new i = GetRandomFirework();
	vPos[2] -= GetRandomFloat(300.0, 1400.0);

	vAng[0] = GetRandomFloat(-10.0, 10.0);
	vAng[1] = GetRandomFloat(-10.0, 10.0);
	vAng[2] = GetRandomFloat(-10.0, 10.0);
	ShowParticle(vPos, vAng, g_sParticles[i]);

	PlaySound(vPos); // Play whistle now and explosion sound in 2 seconds.
}

// Get a random firework type from the cvars enum and display
GetRandomFirework()
{
	new iCount, iArray[4], iType = g_iCvarType;

	if( iType & TYPE_RED )
	{
		iArray[iCount] = 0;
		iCount++;
	}
	if( iType & TYPE_BLUE )
	{
		iArray[iCount] = 1;
		iCount++;
	}
	if( iType & TYPE_GOLD )
	{
		iArray[iCount] = 2;
		iCount++;
	}
	if( iType & TYPE_FLASH )
	{
		iArray[iCount] = 3;
		iCount++;
	}

	iType = GetRandomInt(0, iCount -1);
	return iArray[iType];
}



// ====================================================================================================
//					PARTICLES
// ====================================================================================================
PrecacheParticle(const String:sParticle[])
{
	new entity = CreateEntityByName("info_particle_system");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "effect_name", sParticle);
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "start");
		CreateTimer(0.5, tmrRemoveEnt, EntIndexToEntRef(entity));
		g_iParticleCount++;
	}
}

ShowParticle(Float:vPos[3], Float:vAng[3], String:sParticle[])
{
	if( g_iParticleCount >= MAX_PARTICLES )
		return;

	new entity = CreateEntityByName("info_particle_system");
	if( entity != -1 )
	{
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		DispatchKeyValue(entity, "effect_name", sParticle);
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "start");
		CreateTimer(5.0, tmrRemoveEnt, EntIndexToEntRef(entity));
		g_iParticleCount++;
	}
}

public Action:tmrRemoveEnt(Handle:timer, any:entity)
{
	g_iParticleCount--;
	entity = EntRefToEntIndex(entity);
	if( entity != INVALID_ENT_REFERENCE )
		AcceptEntityInput(entity, "kill");
}



// ====================================================================================================
//					SOUNDS
// ====================================================================================================
PlaySound(Float:vPos[3])
{
	// Limit sounds so they are not played more than once during 0.3 seconds.
	new Float:fTime = GetGameTime();
	if( (fTime - g_fLastPlayed) <= 0.3 )
		return;
	g_fLastPlayed = fTime;

	new iChance = 3;

	// Whistle sound
	if( GetRandomInt(1, 5) <= iChance )	// 3/5 chance to play sound
		PlayAmbient(g_sSoundsLaunch[GetRandomInt(0, 5)], vPos);

	// Explosion sound (in 2 seconds when the particle explodes)
	if( GetRandomInt(1, 5) <= iChance )	// 3/5 chance to play fireworks explosion sound
	{
		new Handle:hPack;
		CreateDataTimer(2.0, tmrPlayBurst, hPack);
		WritePackFloat(hPack, vPos[0]);
		WritePackFloat(hPack, vPos[1]);
		WritePackFloat(hPack, vPos[2]);
	}
}

public Action:tmrPlayBurst(Handle:timer, Handle:hPack)
{
	decl Float:vPos[3];

	ResetPack(hPack);
	vPos[0] = ReadPackFloat(hPack);
	vPos[1] = ReadPackFloat(hPack);
	vPos[2] = ReadPackFloat(hPack) + 400.0;

	PlayAmbient(g_sSoundsBursts[GetRandomInt(0, 3)], vPos);
}

PlayAmbient(String:sName[], Float:vPos[3])
{
	vPos[2] += 200.0;
	EmitAmbientSound(sName, vPos, SOUND_FROM_WORLD, SNDLEVEL_HELICOPTER, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
}