#define PLUGIN_VERSION 		"1.2"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Lamp
*	Author	:	SilverShot
*	Descrp	:	Spawns various Lamps.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=179268

========================================================================================
	Change Log:

1.2 (21-Jul-2013)
	- Removed Sort_Random work-around. This was fixed in SourceMod 1.4.7, all should update or spawning issues will occur.

1.1 (10-May-2012)
	- Added cvar "l4d2_lamp_modes_off" to control which game modes the plugin works in.
	- Added cvar "l4d2_lamp_modes_tog" same as above.

1.0 (28-Feb-2012)
	- Initial release.

======================================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_NOTIFY
#define CHAT_TAG			"\x05[Lamp] \x01"
#define CONFIG_SPAWNS		"data/l4d2_lamp.cfg"
#define MAX_ALLOWED			32
#define	MAX_LAMPS			39
#define MAX_INDEX			9

#define MODEL_LIGHT1		"models/props/de_train/light_inset.mdl"
#define MODEL_LIGHT2		"models/props/de_nuke/wall_light_off.mdl"
#define MODEL_LIGHT6		"models/props_lighting/light_construction.mdl"
#define MODEL_LIGHT19		"models/props_c17/lamppost03a_off.mdl"
#define PARTICLE_SPARK		"sparks_generic_random"
#define PARTICLE_STROBE		"emergency_light_strobe"
#define SOUND_STATIC		"ambient/ambience/tv_static_loop2.wav"


static 	Handle:g_hCvarAllow, Handle:g_hCvarBreak, Handle:g_hCvarBright, Handle:g_hCvarColor, Handle:g_hCvarModes, Handle:g_hCvarModesOff,
		Handle:g_hCvarModesTog, Handle:g_hCvarRandom, bool:g_bCvarAllow, g_iCvarBreak, Float:g_fCvarBright, g_iCvarColor, String:g_sCvarColor[12], g_iCvarRandom,
		bool:g_bLoaded, g_iPlayerSpawn, g_iRoundStart, g_iEntities[MAX_ALLOWED][MAX_INDEX], Handle:g_hMPGameMode,
		Handle:g_hMenuMain, Handle:g_hMenuTemp, Handle:g_hMenuSave, Handle:g_hMenuColor, Handle:g_hMenuBrightness, Handle:g_hMenuAng, Handle:g_hMenuPos;

static const String:g_sSoundsZap[5][32]	=
{
	"ambient/energy/spark5.wav",
	"ambient/energy/spark6.wav",
	"ambient/energy/zap1.wav",
	"ambient/energy/zap2.wav",
	"ambient/energy/zap3.wav"
};

static const String:g_sModels[MAX_LAMPS][64] =
{
	"models/props_lighting/light_battery_rigged_01.mdl",
	"models/props_lighting/spotlight_dropped_01.mdl",
	"models/props_unique/spawn_apartment/lantern.mdl",
	"models/props_equipment/light_floodlight.mdl",
	"models/props_vehicles/floodlight_generator_pose01_static.mdl",
	"models/props_vehicles/floodlight_generator_pose02_static.mdl",
	"models/props_vehicles/radio_generator.mdl",
	"models/props_interiors/tv.mdl",
	"models/props_urban/emergency_light001.mdl",
	"models/props/cs_office/exit_ceiling.mdl",
	"models/props_urban/exit_sign001.mdl",
	"models/props_lighting/searchlight_small_01.mdl",
	"models/props_wasteland/light_spotlight01_lamp.mdl",
	"models/props_vehicles/police_car_lightbar.mdl",
	"models/props/cs_office/light_inset.mdl",
	"models/props/de_nuke/wall_light.mdl",
	"models/props_lighting/lightfixture05.mdl",
	"models/props_interiors/lightsconce01.mdl",
	"models/props_interiors/lightsconce02.mdl",
	"models/props_lighting/light_construction02.mdl",
	"models/props_mall/cage_light_fixture.mdl",
	"models/props_lighting/light_porch.mdl",
	"models/props_fairgrounds/single_light.mdl",
	"models/props/de_nuke/floodlight.mdl",
	"models/props_urban/light_fixture01.mdl",
	"models/props_lighting/lightfixture04.mdl",
	"models/props_lighting/lightfixture03.mdl",
	"models/props/de_nuke/emergency_lighta.mdl",
	"models/props/cs_assault/floodlight02.mdl",
	"models/props/cs_office/light_security.mdl",
	"models/props_urban/ceiling_light001.mdl",
	"models/props_lighting/lights_industrialcluster01a.mdl",
	"models/props_c17/lamppost03a_on.mdl",
	"models/props_urban/parkinglot_light001.mdl",
	"models/props/cs_assault/streetlight.mdl",
	"models/props_interiors/lamp_floor_arch.mdl",
	"models/props_interiors/lamp_floor.mdl",
	"models/props_interiors/lamp_table01.mdl",
	"models/props_interiors/lamp_table02.mdl"
};

static const String:g_sLampNames[MAX_LAMPS][64] =
{
	"Battery",			"Dropped",			"Lantern",			"Floodlight",		"Generator 1",		"Generator 2",		"Generator 3",
	"Television",		"Emergency",		"Exit 1",			"Exit 2",			"Searchlight",		"Spinning",			"Police Lights",
	"Inset",			"Tube",				"Work",				"Sconce 1",			"Sconce 2",			"Construction 1",	"Construction 2",
	"Porch",			"Spotlight 1",		"Spotlight 2",		"Fixture 1",		"Fixture 2",		"Fixture 3",		"Red Alarm",
	"2 Spotlights",		"Security",			"Shade",			"Street 1",			"Street 2",			"Street 3",			"Street 4",
	"Lamp 1",			"Lamp 2",			"Lamp 3",			"Lamp 4"
};

enum ()
{
	TYPE_BATTERY = 1,	TYPE_DROPPED,		TYPE_LANTERN,		TYPE_FLOOD,			TYPE_GENERATOR1,	TYPE_GENERATOR2,	TYPE_GENERATOR3,
	TYPE_TV,			TYPE_EMERGENCY,		TYPE_EXIT1,			TYPE_EXIT2,			TYPE_SEARCH,		TYPE_SPIN,			TYPE_POLICE,
	TYPE_LIGHT1,		TYPE_LIGHT2,		TYPE_LIGHT3,		TYPE_LIGHT4,		TYPE_LIGHT5,		TYPE_LIGHT6,		TYPE_LIGHT7,
	TYPE_LIGHT8,		TYPE_LIGHT9,		TYPE_LIGHT10,		TYPE_LIGHT11,		TYPE_LIGHT12,		TYPE_LIGHT13,		TYPE_LIGHT14,
	TYPE_LIGHT15,		TYPE_LIGHT16,		TYPE_LIGHT17,		TYPE_LIGHT18,		TYPE_LIGHT19,		TYPE_LIGHT20,		TYPE_LIGHT21,
	TYPE_LIGHT22,		TYPE_LIGHT23,		TYPE_LIGHT24,		TYPE_LIGHT25
}



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin:myinfo =
{
	name = "[L4D2] Lamp",
	author = "SilverShot",
	description = "Spawns various Lamps.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=179268"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if( strcmp(sGameName, "left4dead", false) )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	SetupMenus();

	g_hCvarAllow =		CreateConVar(	"l4d2_lamp_allow",		"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarBreak =		CreateConVar(	"l4d2_lamp_break",		"0",			"0=No. 1=Yes. Lights can break when damaged.", CVAR_FLAGS);
	g_hCvarBright =		CreateConVar(	"l4d2_lamp_bright",		"150.0",		"Brightness of new lamps.", CVAR_FLAGS);
	g_hCvarColor =		CreateConVar(	"l4d2_lamp_color",		"255 255 200",	"The beam color. RGB (red, green, blue) values (0-255).", CVAR_FLAGS);
	g_hCvarModes =		CreateConVar(	"l4d2_lamp_modes",		"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d2_lamp_modes_off",	"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d2_lamp_modes_tog",	"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarRandom =		CreateConVar(	"l4d2_lamp_random",		"-1",			"-1=All, 0=Off, other value randomly spawns that many from the config.", CVAR_FLAGS);
	CreateConVar(						"l4d2_lamp_version",	PLUGIN_VERSION,	"Lamp plugin version.", CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d2_lamp");

	g_hMPGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hMPGameMode,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarAllow,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarModes,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesOff,	ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesTog,	ConVarChanged_Allow);
	HookConVarChange(g_hCvarBreak,		ConVarChanged_Cvars);
	HookConVarChange(g_hCvarBright,		ConVarChanged_Cvars);
	HookConVarChange(g_hCvarColor,		ConVarChanged_Cvars);
	HookConVarChange(g_hCvarRandom,		ConVarChanged_Cvars);

	RegAdminCmd("sm_lamp",			CmdLamp,			ADMFLAG_ROOT,	"Spawns a temporary Lamp at your crosshair.");
	RegAdminCmd("sm_lampset",		CmdLampSet,			ADMFLAG_ROOT, 	"Will save temp lamps to the map. 0 args = sm_lampset (save origin/angles/color/brightness). 2 args = sm_lampset <break|bright|beam|glow|halo|length|width|speed> <value>. 3 args = sm_set <R> <G> <B> (color255)");
	RegAdminCmd("sm_lampdel",		CmdLampDelete,		ADMFLAG_ROOT, 	"Removes the Lamp you are pointing at and deletes from the config if saved.");
	RegAdminCmd("sm_lampclear",		CmdLampClear,		ADMFLAG_ROOT, 	"Removes all lamps from the current map.");
	RegAdminCmd("sm_lampwipe",		CmdLampWipe,		ADMFLAG_ROOT, 	"Removes all lamps from the current map and deletes them from the config.");
	RegAdminCmd("sm_lamprefresh",	CmdLampRefresh,		ADMFLAG_ROOT, 	"Removes all lamps from the current map and reloads the maps config.");
}

public OnPluginEnd()
{
	ResetPlugin();
}

public OnMapStart()
{
	for( new i = 0; i < MAX_LAMPS; i++ )
		PrecacheModel(g_sModels[i], true);
	PrecacheModel(MODEL_LIGHT1, true);
	PrecacheModel(MODEL_LIGHT2, true);
	PrecacheModel(MODEL_LIGHT6, true);
	PrecacheModel(MODEL_LIGHT19, true);

	PrecacheParticle(PARTICLE_SPARK);
	PrecacheParticle(PARTICLE_STROBE);

	for( new i = 0; i < 5; i++ )
		PrecacheSound(g_sSoundsZap[i], true);
	PrecacheSound(SOUND_STATIC, true);
}

public OnMapEnd()
{
	ResetPlugin();

	g_bLoaded = false;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
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
	g_fCvarBright =		GetConVarFloat(g_hCvarBright);
	g_iCvarBreak =		GetConVarInt(g_hCvarBreak);
	g_iCvarRandom =		GetConVarInt(g_hCvarRandom);

	GetConVarString(g_hCvarColor, g_sCvarColor, sizeof(g_sCvarColor));
	g_iCvarColor = GetColor(g_sCvarColor);
}

IsAllowed()
{
	new bool:bCvarAllow = GetConVarBool(g_hCvarAllow);
	new bool:bAllowMode = IsAllowedGameMode();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		g_bLoaded = false;
		GetCvars();
		LoadLamps();
		HookEvents();
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		ResetPlugin();
		UnhookEvents();
	}
}

static g_iCurrentMode;

bool:IsAllowedGameMode()
{
	if( g_hMPGameMode == INVALID_HANDLE )
		return false;

	new iCvarModesTog = GetConVarInt(g_hCvarModesTog);
	if( iCvarModesTog != 0 )
	{
		g_iCurrentMode = 0;

		new entity = CreateEntityByName("info_gamemode");
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
		AcceptEntityInput(entity, "PostSpawnActivate");
		AcceptEntityInput(entity, "Kill");

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	decl String:sGameModes[64], String:sGameMode[64];
	GetConVarString(g_hMPGameMode, sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	GetConVarString(g_hCvarModes, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	GetConVarString(g_hCvarModesOff, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public OnGamemode(const String:output[], caller, activator, Float:delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
HookEvents()
{
	HookEvent("round_start",			Event_RoundStart,	EventHookMode_PostNoCopy);
	HookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("player_spawn",			Event_PlayerSpawn,	EventHookMode_PostNoCopy);
}

UnhookEvents()
{
	UnhookEvent("round_start",			Event_RoundStart,	EventHookMode_PostNoCopy);
	UnhookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
	UnhookEvent("player_spawn",			Event_PlayerSpawn,	EventHookMode_PostNoCopy);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		LoadLamps();

	g_iRoundStart = 1;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetPlugin();

	g_bLoaded = false;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		LoadLamps();

	g_iPlayerSpawn = 1;
}



// ====================================================================================================
//					LOAD LIGHTS
// ====================================================================================================
LoadLamps()
{
	if( g_bLoaded == true || g_iCvarRandom == 0 ) return;
	g_bLoaded = true;

	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		return;

	// Load config
	new Handle:hFile = CreateKeyValues("lamps");
	if( !FileToKeyValues(hFile, sPath) )
	{
		CloseHandle(hFile);
		return;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !KvJumpToKey(hFile, sMap) )
	{
		CloseHandle(hFile);
		return;
	}

	// Retrieve how many to display
	new iCount = KvGetNum(hFile, "num", 0);
	if( iCount == 0 )
	{
		CloseHandle(hFile);
		return;
	}

	// Spawn only a select few?
	new index, i, iRandom = g_iCvarRandom;
	new iIndexes[MAX_ALLOWED+1];
	if( iCount > MAX_ALLOWED )
		iCount = MAX_ALLOWED;

	// Spawn all saved or create random
	if( iRandom > iCount)
		iRandom = iCount;
	if( iRandom != -1 )
	{
		for( i = 1; i <= iCount; i++ )
			iIndexes[i-1] = i;

		SortIntegers(iIndexes, iCount, Sort_Random);
		iCount = iRandom;
	}

	// Get the origins and spawn
	for( i = 1; i <= iCount; i++ )
	{
		if( iRandom != -1 ) index = iIndexes[i-1];
		else index = i;

		SpawnData(index, hFile, sMap, i, iCount);
		KvRewind(hFile);
	}

	CloseHandle(hFile);
}

SpawnData(index, Handle:hFile, String:sMap[], i = -1, iCount = -1)
{
	new color, type, Float:brightness, Float:glow, halo, beam, length, width, speed, breakable;
	decl String:sTemp[16], Float:vPos[3], Float:vAng[3];

	KvJumpToKey(hFile, sMap);
	IntToString(index, sTemp, sizeof(sTemp));
	if( KvJumpToKey(hFile, sTemp) )
	{
		KvGetVector(hFile, "origin", vPos);

		if( vPos[0] == 0.0 && vPos[0] == 0.0 && vPos[0] == 0.0 ) // Should never happen.
			LogError("Error: 0,0,0 origin. Iteration=%d. Index=%d. Count=%d.", i, index, iCount);
		else
		{
			KvGetVector(hFile, "angle", vAng);
			KvGetString(hFile, "color", sTemp, sizeof(sTemp));
			color = GetColor(sTemp);
			type = KvGetNum(hFile, "type");
			brightness = KvGetFloat(hFile, "brightness", g_fCvarBright);
			glow = KvGetFloat(hFile, "glow", 0.3);
			halo = KvGetNum(hFile, "halo", 100);
			beam = KvGetNum(hFile, "beam", 100);
			length = KvGetNum(hFile, "length", 100);
			width = KvGetNum(hFile, "width", 40);
			speed = KvGetNum(hFile, "speed", 30);
			breakable = KvGetNum(hFile, "breakable", g_iCvarBreak);

			SpawnLamp(vPos, vAng, color, type, index, brightness, glow, halo, beam, length, width, speed, breakable);
		}
	}
}

GetColor(String:sTemp[])
{
	decl String:sColors[3][4];
	ExplodeString(sTemp, " ", sColors, 3, 4);

	new color;
	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);
	return color;
}



// ====================================================================================================
//					SPAWN LIGHT
// ====================================================================================================
SpawnLamp(const Float:vOrigin[3], const Float:vAngles[3], color, type, cfgindex, Float:brightness, Float:glow, halo, beam, length, width, speed, breakable)
{
	// CHECK VALID TYPE
	if( type < 1 || type > MAX_LAMPS )
	{
		LogError("Invalid type %d", type);
		return -1;
	}

	// GET INDEX
	new index = -1;
	for( new i = 0; i < MAX_ALLOWED; i++ )
	{
		if( !IsValidEntRef(g_iEntities[i][0]) )
		{
			index = i;
			break;
		}
	}

	if( index == -1 )
		return -1;

	// CREATE ENTITY
	new entity;

	if( type == TYPE_FLOOD || type == TYPE_TV )
	{
		entity = CreateEntityByName("prop_physics_override");
		DispatchKeyValue(entity, "solid", "0");
	}
	else
	{
		entity = CreateEntityByName("prop_dynamic");
		DispatchKeyValue(entity, "solid", "6");
	}

	// SET MODEL
	DispatchKeyValue(entity, "model", g_sModels[type - 1]);

	// SET SKIN
	if( type >= TYPE_LIGHT1 )
		SetEntProp(entity, Prop_Send, "m_nSkin", 1);

	// DISPATCH
	DispatchKeyValue(entity, "health", "50");
	DispatchSpawn(entity);

	// SAVE INDEX
	g_iEntities[index][0] = EntIndexToEntRef(entity);
	g_iEntities[index][MAX_INDEX-2] = type;
	g_iEntities[index][MAX_INDEX-1] = cfgindex;

	// HOOK HEALTH
	if( g_iCvarBreak && breakable )
	{
		HookSingleEntityOutput(entity, "OnTakeDamage", OnBreak);
		HookSingleEntityOutput(entity, "OnHealthChanged", OnBreak);
	}

	// SET POSITION
	new Float:vAng[3];
	new target = entity;


	// SETUP UNIQUE LAMP TYPES


	// TYPE: TELEVISION - SOUND/SKIN
	if( type == TYPE_TV )
	{
		if( GetRandomInt(0, 1) )
			SetEntProp(target, Prop_Send, "m_nSkin", 1);
		else
			SetEntProp(target, Prop_Send, "m_nSkin", 2);

		TeleportEntity(target, vOrigin, vAngles, NULL_VECTOR);
		EmitSoundToAll(SOUND_STATIC, target, SNDCHAN_AUTO, SNDLEVEL_CONVO, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);

		return index;
	}

	// TYPE: BATTERY
	else if( type == TYPE_BATTERY )
	{
		entity = MakeLightDynamic(Float:{ 0.0, 0.0, 10.0 }, vAng, color, brightness);
	}

	// TYPE: EMERGENCY STROBE
	else if( type == TYPE_EMERGENCY )
	{
		entity = CreateEntityByName("info_particle_system");
		if( entity != -1 )
		{
			g_iEntities[index][1] = EntIndexToEntRef(entity);
			DispatchKeyValue(entity, "effect_name", PARTICLE_STROBE);
			DispatchSpawn(entity);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "Start");
		}

		TeleportEntity(entity, Float:{ 0.0, 5.0, 0.0 }, vAngles, NULL_VECTOR);
		ParentEntities(target, entity);
		TeleportEntity(target, vOrigin, vAngles, NULL_VECTOR);

		return index;
	}

	// TYPE: POLICE LIGHTS
	else if( type == TYPE_POLICE )
	{
		SetEntProp(target, Prop_Send, "m_nSkin", 1);
		vAng[1] = -90.0;

		// BLUE LIGHT
		new rotating = CreateEntityByName("func_rotating");
		DispatchKeyValue(rotating, "spawnflags", "65");
		decl String:sTemp[8];
		IntToString(speed, sTemp, sizeof(sTemp));
		DispatchKeyValue(rotating, "maxspeed", sTemp);
		DispatchKeyValue(rotating, "fanfriction", "20");
		DispatchSpawn(rotating);
		TeleportEntity(rotating, Float:{ -15.0, -10.0, 65.0 }, vAng, NULL_VECTOR);
		g_iEntities[index][1] = EntIndexToEntRef(rotating);

		entity = MakePointSpotlight(Float:{ -15.0, -10.0, 65.0 }, vAng, 16711680, rotating, glow, halo, beam, length, width);
		if( entity )
			g_iEntities[index][2] = EntIndexToEntRef(entity);

		entity = MakeLightDynamic(Float:{ -15.0, -10.0, 75.0 }, vAng, 16711680, brightness);
		g_iEntities[index][3] = EntIndexToEntRef(entity);
		ParentEntities(rotating, entity);
		ParentEntities(target, rotating);


		// RED LIGHT
		vAng[0] = 180.0;

		rotating = CreateEntityByName("func_rotating");
		DispatchKeyValue(rotating, "spawnflags", "65");
		DispatchKeyValue(rotating, "maxspeed", sTemp);
		DispatchKeyValue(rotating, "fanfriction", "20");
		DispatchSpawn(rotating);
		TeleportEntity(rotating, Float:{ 15.0, -10.0, 65.0 }, vAng, NULL_VECTOR);
		g_iEntities[index][4] = EntIndexToEntRef(entity);

		entity = MakePointSpotlight(Float:{ 15.0, -10.0, 65.0 }, vAng, 255, rotating, glow, halo, beam, length, width);
		if( entity )
			g_iEntities[index][5] = EntIndexToEntRef(entity);

		entity = MakeLightDynamic(Float:{ 15.0, -10.0, 75.0 }, vAng, 255, brightness);
		g_iEntities[index][6] = EntIndexToEntRef(entity);
		ParentEntities(rotating, entity);
		ParentEntities(target, rotating);
		TeleportEntity(target, vOrigin, vAngles, NULL_VECTOR);

		return index;
	}

	// TYPE: SPIN - ATTACH TO FUNC_ROTATING
	else if( type == TYPE_SPIN )
	{
		new rotating = CreateEntityByName("func_rotating");
		DispatchKeyValue(rotating, "spawnflags", "65");
		decl String:sTemp[8];
		IntToString(speed, sTemp, sizeof(sTemp));
		DispatchKeyValue(rotating, "maxspeed", sTemp);
		DispatchKeyValue(rotating, "fanfriction", "20");
		DispatchSpawn(rotating);
		g_iEntities[index][2] = EntIndexToEntRef(rotating);


		entity = MakeBeamSpotlight(Float:{ 0.0, 0.0, 4.0 }, vAng, color, glow, halo, beam, length, width, true);
		g_iEntities[index][3] = EntIndexToEntRef(entity);
		ParentEntities(rotating, entity);

		entity = MakeLightDynamic(Float:{ 40.0, 0.0, 25.0 }, vAng, color, brightness);
		g_iEntities[index][1] = EntIndexToEntRef(entity);
		ParentEntities(rotating, entity);

		TeleportEntity(target, NULL_VECTOR, vAng, NULL_VECTOR);
		ParentEntities(rotating, target);
		TeleportEntity(rotating, vOrigin, vAngles, NULL_VECTOR);

		return index;
	}

	// TYPE: FLOODLIGHT - CREATE 2 SPOTLIGHTS
	else if( type == TYPE_FLOOD && beam )
	{
		SetEntProp(target, Prop_Send, "m_nSkin", 1);
		entity = MakePointSpotlight(Float:{ 0.0, 12.0, 80.0 }, vAng, color, target, glow, halo, beam, length, width);
		g_iEntities[index][2] = EntIndexToEntRef(entity);

		entity = MakePointSpotlight(Float:{ 0.0, -10.99, 79.59 }, vAng, color, target, glow, halo, beam, length, width);
		g_iEntities[index][3] = EntIndexToEntRef(entity);

		entity = MakeLightDynamic(Float:{ 40.0, -1.0, 79.77 }, vAng, color, brightness);
	}

	// TYPE: GENERATOR - CREATE 4 SPOTLIGHTS
	else if( type == TYPE_GENERATOR1 || type == TYPE_GENERATOR2 || type == TYPE_GENERATOR3 )
	{
		vAng[1] = 90.0;
		if( type == TYPE_GENERATOR2 )
			vAng[0] = 35.0;

		if( type == TYPE_GENERATOR1 )
		{
			entity = MakePointSpotlight(Float:{ -18.0, 30.0, 185.52 }, Float:{ -5.0, 95.0, 0.0 }, color, target, glow, halo, beam, length, width);
			g_iEntities[index][2] = EntIndexToEntRef(entity);
			entity = MakePointSpotlight(Float:{ 18.0, 29.72, 185.52 }, Float:{ -5.0, 85.0, 0.0 }, color, target, glow, halo, beam, length, width);
			g_iEntities[index][3] = EntIndexToEntRef(entity);
			entity = MakePointSpotlight(Float:{ -17.0, 30.0, 152.52 }, Float:{ 5.0, 95.0, 0.0 }, color, target, glow, halo, beam, length, width);
			g_iEntities[index][4] = EntIndexToEntRef(entity);
			entity = MakePointSpotlight(Float:{ 17.0, 29.72, 152.52 }, Float:{ 5.0, 85.0, 0.0 }, color, target, glow, halo, beam, length, width);
			g_iEntities[index][5] = EntIndexToEntRef(entity);
		}
		else if( type == TYPE_GENERATOR2 )
		{
			entity = MakePointSpotlight(Float:{ -18.0, 40.0, 276.70 }, Float:{ 30.0, 95.0, 0.0 }, color, target, glow, halo, beam, length, width);
			g_iEntities[index][2] = EntIndexToEntRef(entity);
			entity = MakePointSpotlight(Float:{ 18.0, 40.0, 276.70 }, Float:{ 30.0, 85.0, 0.0 }, color, target, glow, halo, beam, length, width);
			g_iEntities[index][3] = EntIndexToEntRef(entity);
			entity = MakePointSpotlight(Float:{ -17.0, 20.0, 245.34 }, Float:{ 40.0, 95.0, 0.0 }, color, target, glow, halo, beam, length, width);
			g_iEntities[index][4] = EntIndexToEntRef(entity);
			entity = MakePointSpotlight(Float:{ 17.0, 20.0, 245.34 }, Float:{ 40.0, 85.0, 0.0 }, color, target, glow, halo, beam, length, width);
			g_iEntities[index][5] = EntIndexToEntRef(entity);
		}
		else
		{
			entity = MakePointSpotlight(Float:{ -12.0, 14.0, 98.0 }, Float:{ 20.0, -90.0, 0.0 }, color, target, glow, halo, beam, length, width);
			g_iEntities[index][2] = EntIndexToEntRef(entity);

			entity = MakePointSpotlight(Float:{ 10.0, 5.0, 228.0 }, Float:{ 20.0, 15.0, 0.0 }, color, target, glow, halo, beam, length, width);
		}

		vAng[0] = 0.0;

		if( type == TYPE_GENERATOR1 )
			entity = MakeLightDynamic(Float:{ 0.0, 100.0, 170.0 }, vAng, color, brightness);
		else if( type == TYPE_GENERATOR2 )
			entity = MakeLightDynamic(Float:{ 0.0, 100.0, 240.0 }, vAng, color, brightness);
	}

	// TYPE: DROPPED FLASHLIGHT - CREATE 1 BEAM SPOTLIGHT
	else if( type == TYPE_DROPPED )
	{
		entity = MakeBeamSpotlight(Float:{ 1.0, 5.0, 4.0 }, Float:{ 0.0, 90.0, 0.0 }, color, glow, halo, beam, length, width, false);
		if( entity )
		{
			g_iEntities[index][2] = EntIndexToEntRef(entity);
			ParentEntities(target, entity);
		}

		vAng[0] = -90.0;
		entity = MakeLightDynamic(Float:{ 0.0, 25.0, 16.0 }, NULL_VECTOR, color, brightness);
	}

	// MOVE BEAM AWAY FROM MODEL
	else if( type == TYPE_EXIT1 )
		entity = MakeLightDynamic(Float:{ 0.0, 0.0, -15.0 }, vAng, color, brightness);

	else if( type == TYPE_EXIT2 )
		entity = MakeLightDynamic(Float:{ 0.0, 0.0, -5.0 }, vAng, color, brightness);

	else if( type == TYPE_SEARCH )
		entity = MakeLightDynamic(Float:{ 0.0, 15.0, -10.0 }, vAng, color, brightness);

	else if( type == TYPE_LIGHT7 || type == TYPE_LIGHT8 )
		entity = MakeLightDynamic(Float:{ 0.0, 15.0, -10.0 }, vAng, color, brightness);

	else if( type == TYPE_LANTERN )
		entity = MakeLightDynamic(Float:{ 0.0, 0.0, 15.0 }, vAng, color, brightness);

	else if( type == TYPE_LIGHT1 )
		entity = MakeLightDynamic(Float:{ 0.0, 0.0, -20.0 }, vAng, color, brightness);

	else if( type == TYPE_LIGHT2 || type == TYPE_LIGHT4 || type == TYPE_LIGHT5 )
		entity = MakeLightDynamic(Float:{ 15.0, 0.0, 0.0 }, vAng, color, brightness);

	else if( type == TYPE_LIGHT6 )
		entity = MakeLightDynamic(Float:{ 0.0, 0.0, -10.0 }, NULL_VECTOR, color, brightness);

	else if( type == TYPE_LIGHT9 )
		entity = MakeLightDynamic(Float:{ -15.0, 0.0, -20.0 }, vAng, color, brightness);

	else if( type == TYPE_LIGHT10 || type == TYPE_LIGHT12 )
		entity = MakeLightDynamic(Float:{ 15.0, 0.0, -10.0 }, vAng, color, brightness);

	else if( type == TYPE_LIGHT14 )
	{
		SetEntProp(target, Prop_Send, "m_nSkin", 3);
		entity = MakeLightDynamic(Float:{ 0.0, 0.0, 5.0 }, vAng, color, brightness);
	}

	// TYPE: 2 SPOTLIGHTS
	else if( type == TYPE_LIGHT15 )
	{
		entity = MakePointSpotlight(Float:{ 8.0, -8.0, 0.0 }, Float:{ 20.0, -30.0, 0.0 }, color, target, glow, halo, beam, length, width);
		if( entity )
			g_iEntities[index][2] = EntIndexToEntRef(entity);

		entity = MakePointSpotlight(Float:{ 7.0, 9.0, 0.0 }, Float:{ 35.0, 65.0, 0.0 }, color, target, glow, halo, beam, length, width);
		if( entity )
			g_iEntities[index][3] = EntIndexToEntRef(entity);

		entity = MakeLightDynamic(Float:{ 20.0, 0.0, -20.0 }, vAng, color, brightness);
	}

	else if( type == TYPE_LIGHT16 )
	{
		SetEntProp(target, Prop_Send, "m_nSkin", 0);
		entity = MakeLightDynamic(Float:{ 20.0, 0.0, 0.0 }, vAng, color, brightness);
	}

	else if( type == TYPE_LIGHT17 )
	{
		SetEntProp(target, Prop_Send, "m_nSkin", 0);
		entity = MakeLightDynamic(Float:{ 0.0, 0.0, -20.0 }, vAng, color, brightness);
	}

	// TYPE: STREET LIGHT
	else if( type == TYPE_LIGHT18 )
	{
		entity = MakePointSpotlight(Float:{ -25.0, 0.0, 375.0 }, Float:{ 45.0, 180.0, 0.0 }, color, target, glow, halo, beam, length, width);
		if( entity )
		{
			g_iEntities[index][2] = EntIndexToEntRef(entity);
			ParentEntities(target, entity);
		}

		entity = MakePointSpotlight(Float:{ 25.0, 0.0, 375.0 }, Float:{ 45.0, 0.0, 90.0 }, color, target, glow, halo, beam, length, width);
		if( entity )
		{
			g_iEntities[index][3] = EntIndexToEntRef(entity);
			ParentEntities(target, entity);
		}

		entity = MakeLightDynamic(Float:{ 0.0, 0.0, 400.0 }, vAng, color, brightness);
	}

	else if( type == TYPE_LIGHT19 )
	{
		entity = MakePointSpotlight(Float:{ 0.0, 95.0, 445.0 }, Float:{ 90.0, 0.0, 0.0 }, color, target, glow, halo, beam, length, width);
		if( entity )
		{
			g_iEntities[index][2] = EntIndexToEntRef(entity);
			ParentEntities(target, entity);
		}

		entity = MakeLightDynamic(Float:{ 0.0, 100.0, 350.0 }, vAng, color, brightness);
	}

	else if( type == TYPE_LIGHT20 )
	{
		entity = MakePointSpotlight(Float:{ 0.0, 40.0, 570.0 }, Float:{ 90.0, 0.0, 0.0 }, color, target, glow, halo, beam, length, width);
		if( entity )
		{
			g_iEntities[index][2] = EntIndexToEntRef(entity);
			ParentEntities(target, entity);
		}

		entity = MakePointSpotlight(Float:{ 0.0, -40.0, 570.0 }, Float:{ 90.0, 0.0, 0.0 }, color, target, glow, halo, beam, length, width);
		if( entity )
		{
			g_iEntities[index][3] = EntIndexToEntRef(entity);
			ParentEntities(target, entity);
		}

		entity = MakeLightDynamic(Float:{ 0.0, 0.0, 450.0 }, vAng, color, brightness);
	}

	else if( type == TYPE_LIGHT21 )
		entity = MakeLightDynamic(Float:{ 40.0, 0.0, 40.0 }, vAng, color, brightness);

	else if( type == TYPE_LIGHT22 )
		entity = MakeLightDynamic(Float:{ 40.0, 0.0, 50.0 }, vAng, color, brightness);

	else if( type == TYPE_LIGHT23 || type == TYPE_LIGHT24 || type == TYPE_LIGHT25 )
		entity = MakeLightDynamic(Float:{ 0.0, 0.0, 15.0 }, vAng, color, brightness);

	else
		entity = MakeLightDynamic(Float:{ 10.0, 0.0, 0.0 }, vAng, color, brightness);

	g_iEntities[index][1] = EntIndexToEntRef(entity);
	ParentEntities(target, entity);
	TeleportEntity(target, vOrigin, vAngles, NULL_VECTOR);

	return index;
}

ParentEntities(target, entity)
{
	SetVariantString("!activator"); 
	AcceptEntityInput(entity, "SetParent", target);
}



// ====================================================================================================
//					BREAK
// ====================================================================================================
public OnBreak(const String:output[], caller, activator, Float:delay)
{
	new entity = EntIndexToEntRef(caller);
	for( new i = 0; i < MAX_ALLOWED; i++ )
	{
		if( entity == g_iEntities[i][0] )
		{
			new type = g_iEntities[i][MAX_INDEX-2];
			UnhookSingleEntityOutput(entity, "OnTakeDamage", OnBreak);
			UnhookSingleEntityOutput(entity, "OnHealthChanged", OnBreak);

			// SET MODEL
			if( type == TYPE_SPIN )
				SetEntProp(caller, Prop_Send, "m_nSkin", 1);
			else if( type == TYPE_LIGHT16 || type == TYPE_LIGHT17)
				SetEntProp(caller, Prop_Send, "m_nSkin", 1);
			else if( type == TYPE_LIGHT1 )
				SetEntityModel(caller, MODEL_LIGHT1);
			else if( type == TYPE_LIGHT2 )
				SetEntityModel(caller, MODEL_LIGHT2);
			else if( type == TYPE_LIGHT19 )
				SetEntityModel(caller, MODEL_LIGHT19);
			else if( type == TYPE_LIGHT6 )
			{
				SetEntityModel(caller, MODEL_LIGHT6);
				SetEntProp(caller, Prop_Send, "m_nSkin", 0);
			}
			else
				SetEntProp(caller, Prop_Send, "m_nSkin", 0);

			// SOUND
			new iType = GetRandomInt(0, 4);
			EmitSoundToAll(g_sSoundsZap[iType], entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);

			// PARTICLE SPARKS
			entity = CreateEntityByName("info_particle_system");
			if( entity != -1 )
			{
				DispatchKeyValue(entity, "effect_name", PARTICLE_SPARK);
				DispatchSpawn(entity);
				ActivateEntity(entity);
				AcceptEntityInput(entity, "Start");

				decl Float:vPos[3];
				GetEntPropVector(caller, Prop_Data, "m_vecOrigin", vPos);
				if( type == TYPE_TV )
					vPos[2] += 30.0;
				else if( type == TYPE_FLOOD )
					vPos[2] += 80.0;
				else if( type == TYPE_GENERATOR1 || type == TYPE_GENERATOR2  || type == TYPE_GENERATOR3 )
					vPos[2] += 65.0;
				else if( type == TYPE_POLICE )
				{
					vPos[1] -= 10.0;
					vPos[2] += 70.0;
				}
				else
					vPos[2] += 5.0;

				TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
				SetVariantString("OnUser1 !self:Stop::0.2:1");
				AcceptEntityInput(entity, "AddOutput");
				SetVariantString("OnUser1 !self:Kill::0.3:1");
				AcceptEntityInput(entity, "AddOutput");
				AcceptEntityInput(entity, "FireUser1");
			}

			// TURN OFF LIGHTS
			DeleteLamp(i, false);

			return;
		}
	}
}



// ====================================================================================================
//					MAKE LIGHTS
// ====================================================================================================
MakeLightDynamic(Float:vOrigin[3], Float:vAngles[3], color, Float:brightness)
{
	new entity = CreateEntityByName("light_dynamic");
	if( entity == -1)
		return 0;

	DispatchKeyValue(entity, "_light", "0 0 0 255");
	DispatchKeyValue(entity, "brightness", "1");
	DispatchKeyValueFloat(entity, "spotlight_radius", 32.0);
	DispatchKeyValueFloat(entity, "distance", brightness);
	DispatchKeyValue(entity, "style", "0");
	SetEntProp(entity, Prop_Send, "m_clrRender", color);

	DispatchSpawn(entity);
	AcceptEntityInput(entity, "TurnOn");
	TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);

	return entity;
}

MakeBeamSpotlight(Float:vOrigin[3], Float:vAngles[3], color, Float:glow, halo, beam, length, width, bool:rotate)
{
	new entity = CreateEntityByName("beam_spotlight");
	if( entity == -1)
		return 0;

	if( rotate )
		DispatchKeyValue(entity, "SpotlightWidth", "40");
	else
		DispatchKeyValue(entity, "SpotlightWidth", "15");
	DispatchKeyValue(entity, "spawnflags", "3");// spawnflags 5: 1=Start On, 2=No Dynamic Light, 4=Start rotation on

	decl String:sTemp[8];
	IntToString(halo, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "HaloScale", sTemp);
	IntToString(width, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "SpotlightWidth", sTemp);
	IntToString(length, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "SpotlightLength", sTemp);
	IntToString(beam, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "renderamt", sTemp);
	DispatchKeyValueFloat(entity, "HDRColorScale", glow);
	SetEntProp(entity, Prop_Send, "m_clrRender", color);

	DispatchSpawn(entity);
	AcceptEntityInput(entity, "TurnOn");
	TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);

	return entity;
}

MakePointSpotlight(Float:vOrigin[3], Float:vAngles[3], color, target, Float:glow, halo, beam, length, width)
{
	new entity = CreateEntityByName("point_spotlight");
	if( entity == -1)
		return 0;

	decl String:sTemp[16];
	Format(sTemp,sizeof(sTemp), "%d %d %d", color & 0xFF, (color & 0xFF00) / 256, color / 65536);
	DispatchKeyValue(entity, "rendercolor", sTemp);
	DispatchKeyValue(entity, "rendermode", "9");
	IntToString(width, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "SpotlightWidth", sTemp);
	IntToString(length, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "SpotlightLength", sTemp);
	IntToString(halo, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "HaloScale", sTemp);
	IntToString(beam, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "renderamt", sTemp);
	DispatchKeyValue(entity, "spawnflags", "1");
	DispatchKeyValueFloat(entity, "HDRColorScale", glow);

	DispatchSpawn(entity);
	AcceptEntityInput(entity, "TurnOn");
	TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
	ParentEntities(target, entity);

	return entity;
}



// ====================================================================================================
//					MENUS
// ====================================================================================================
SetupMenus()
{
	g_hMenuMain = CreateMenu(MainMenuHandler);
	AddMenuItem(g_hMenuMain, "", "Temp Lamp");
	AddMenuItem(g_hMenuMain, "", "Save Lamp");
	AddMenuItem(g_hMenuMain, "", "Brightness");
	AddMenuItem(g_hMenuMain, "", "Color");
	AddMenuItem(g_hMenuMain, "", "Angle");
	AddMenuItem(g_hMenuMain, "", "Origin");
	AddMenuItem(g_hMenuMain, "", "Delete");
	AddMenuItem(g_hMenuMain, "", "Refresh");
	AddMenuItem(g_hMenuMain, "", "List");
	AddMenuItem(g_hMenuMain, "", "Clear");
	AddMenuItem(g_hMenuMain, "", "Wipe");
	SetMenuTitle(g_hMenuMain, "Lamp Spawner");
	SetMenuExitButton(g_hMenuMain, true);

	g_hMenuTemp = CreateMenu(TempMenuHandler);
	AddMenuList(g_hMenuTemp);
	SetMenuTitle(g_hMenuTemp, "Temp Lamp");
	SetMenuExitBackButton(g_hMenuTemp, true);

	g_hMenuSave = CreateMenu(SaveMenuHandler);
	AddMenuList(g_hMenuSave);
	SetMenuTitle(g_hMenuSave, "Save Lamp");
	SetMenuExitBackButton(g_hMenuSave, true);

	g_hMenuBrightness = CreateMenu(BrightnessMenuHandler);
	AddMenuItem(g_hMenuBrightness, "", "50");
	AddMenuItem(g_hMenuBrightness, "", "100");
	AddMenuItem(g_hMenuBrightness, "", "200");
	AddMenuItem(g_hMenuBrightness, "", "250");
	AddMenuItem(g_hMenuBrightness, "", "300");
	AddMenuItem(g_hMenuBrightness, "", "500");
	AddMenuItem(g_hMenuBrightness, "", "SAVE");
	SetMenuTitle(g_hMenuBrightness, "Lamp Brightness");
	SetMenuExitBackButton(g_hMenuBrightness, true);

	g_hMenuColor = CreateMenu(ColorMenuHandler);
	AddMenuItem(g_hMenuColor, "", "Red");
	AddMenuItem(g_hMenuColor, "", "Green");
	AddMenuItem(g_hMenuColor, "", "Blue");
	AddMenuItem(g_hMenuColor, "", "Purple");
	AddMenuItem(g_hMenuColor, "", "Orange");
	AddMenuItem(g_hMenuColor, "", "White");
	AddMenuItem(g_hMenuColor, "", "SAVE");
	SetMenuTitle(g_hMenuColor, "Lamp Color");
	SetMenuExitBackButton(g_hMenuColor, true);

	g_hMenuAng = CreateMenu(AngMenuHandler);
	AddMenuItem(g_hMenuAng, "", "X + 5.0");
	AddMenuItem(g_hMenuAng, "", "Y + 5.0");
	AddMenuItem(g_hMenuAng, "", "Z + 5.0");
	AddMenuItem(g_hMenuAng, "", "X - 5.0");
	AddMenuItem(g_hMenuAng, "", "Y - 5.0");
	AddMenuItem(g_hMenuAng, "", "Z - 5.0");
	AddMenuItem(g_hMenuAng, "", "SAVE");
	SetMenuTitle(g_hMenuAng, "Lamp Angle.");
	SetMenuExitBackButton(g_hMenuAng, true);

	g_hMenuPos = CreateMenu(PosMenuHandler);
	AddMenuItem(g_hMenuPos, "", "X + 0.5");
	AddMenuItem(g_hMenuPos, "", "Y + 0.5");
	AddMenuItem(g_hMenuPos, "", "Z + 0.5");
	AddMenuItem(g_hMenuPos, "", "X - 0.5");
	AddMenuItem(g_hMenuPos, "", "Y - 0.5");
	AddMenuItem(g_hMenuPos, "", "Z - 0.5");
	AddMenuItem(g_hMenuPos, "", "SAVE");
	SetMenuTitle(g_hMenuPos, "Lamp Origin");
	SetMenuExitBackButton(g_hMenuPos, true);
}

AddMenuList(Handle:menu)
{
	for( new i = 0; i < MAX_LAMPS; i++ )
		AddMenuItem(menu, "", g_sLampNames[i]);
}



// ====================================================================================================
//					MENU :: MAIN
// ====================================================================================================
ShowMenuMain(client)
{
	DisplayMenu(g_hMenuMain, client, MENU_TIME_FOREVER);
}

public MainMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Select )
	{
		if( index == 0 )
			ShowMenuTemp(client);
		else if( index == 1 )
			ShowMenuSave(client);
		else if( index == 2 )
			ShowMenuBrightness(client);
		else if( index == 3 )
			ShowMenuColor(client);
		else if( index == 4 )
			ShowMenuAng(client);
		else if( index == 5 )
			ShowMenuPos(client);
		else if( index == 6 )
			ConfirmDelete(client);
		else if( index == 7 )
		{
			CmdLampRefresh(client, 0);
			ShowMenuMain(client);
		}
		else if( index == 8 )
		{
			ListLamps(client);
			ShowMenuMain(client);
		}
		else if( index == 9 )
		{
			ResetPlugin();
			PrintToChat(client, "%sAll Lamps cleared from the map.", CHAT_TAG);
			ShowMenuMain(client);
		}
		else if( index == 10 )
			ConfirmWipe(client);
	}
}

ConfirmDelete(client)
{
	new Handle:hMenu = CreateMenu(DeleteMenuHandler);
	AddMenuItem(hMenu, "", "Yes");
	AddMenuItem(hMenu, "", "No");
	SetMenuTitle(hMenu, "Delete lamp from the config?");
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public DeleteMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowMenuMain(client);
	}
	else if( action == MenuAction_End )
	{
		CloseHandle(menu);
	}
	else if( action == MenuAction_Select )
	{
		if( index == 0 )
		{
			CmdLampDelete(client, 0);
			ShowMenuMain(client);
		}
		else if( index == 1 )
		{
			ShowMenuMain(client);
		}
	}
}

ConfirmWipe(client)
{
	new Handle:hMenu = CreateMenu(WipeMenuHandler);
	AddMenuItem(hMenu, "", "Yes");
	AddMenuItem(hMenu, "", "No");
	SetMenuTitle(hMenu, "Delete all lamps from this maps config?");
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public WipeMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowMenuMain(client);
	}
	else if( action == MenuAction_End )
	{
		CloseHandle(menu);
	}
	else if( action == MenuAction_Select )
	{
		if( index == 0 )
		{
			WipeLamps(client);
			ShowMenuMain(client);
		}
		else if( index == 1 )
		{
			ShowMenuMain(client);
		}
	}
}

ListLamps(client)
{
	decl Float:vPos[3];
	new i,  entity, count;

	for( i = 0; i < MAX_ALLOWED; i++ )
	{
		entity = g_iEntities[i][0];

		if( IsValidEntRef(entity) )
		{
			count++;
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
			if( client == 0 )
				ReplyToCommand(client, "[Lamp] %d) %f %f %f", i+1, vPos[0], vPos[1], vPos[2]);
			else
				PrintToChat(client, "%s%d) %f %f %f", CHAT_TAG, i+1, vPos[0], vPos[1], vPos[2]);
		}
	}

	if( client == 0 )
		PrintToChat(client, "[Lamp] Total: %d.", count);
	else
		ReplyToCommand(client, "%sTotal: %d.", CHAT_TAG, count);
}

WipeLamps(client)
{
	for( new i = 0; i < MAX_ALLOWED; i++ )
		g_iEntities[i][MAX_INDEX-1] = 0;

	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Lamp config (\x05%s\x01).", CHAT_TAG, sPath);
		return;
	}

	// Load config
	new Handle:hFile = CreateKeyValues("lamps");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Lamp config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !KvJumpToKey(hFile, sMap, false) )
	{
		PrintToChat(client, "%sError: Current map not in the Lamp config.", CHAT_TAG);
		CloseHandle(hFile);
		return;
	}

	KvDeleteThis(hFile);

	// Save to file
	KvRewind(hFile);
	KeyValuesToFile(hFile, sPath);
	CloseHandle(hFile);

	PrintToChat(client, "%s(0/%d) - All Lamps removed from config, add new with \x05sm_lampsave\x01.", CHAT_TAG, MAX_ALLOWED);
}



// ====================================================================================================
//					MENU :: TEMP
// ====================================================================================================
ShowMenuTemp(client)
{
	DisplayMenu(g_hMenuTemp, client, MENU_TIME_FOREVER);
}

public TempMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowMenuMain(client);
	}
	else if( action == MenuAction_Select )
	{
		decl Float:vPos[3], Float:vAng[3];

		if( index + 1 == TYPE_EXIT1 || index + 1 == TYPE_EXIT2 )
			SetupLamp(client, vPos, vAng, 65280, index + 1);
		else if( index + 1 == TYPE_FLOOD || index + 1 == TYPE_GENERATOR1 || index + 1 == TYPE_GENERATOR2 || index + 1 == TYPE_SPIN )
			SetupLamp(client, vPos, vAng, 16777215, index + 1);
		else if( index + 1 == TYPE_GENERATOR3 )
			SetupLamp(client, vPos, vAng, 255, index + 1);
		else
			SetupLamp(client, vPos, vAng, g_iCvarColor, index + 1);

		new menupos = GetMenuSelectionPosition();
		DisplayMenuAtItem(menu, client, menupos, MENU_TIME_FOREVER);
	}
}



// ====================================================================================================
//					MENU :: SAVE
// ====================================================================================================
ShowMenuSave(client)
{
	DisplayMenu(g_hMenuSave, client, MENU_TIME_FOREVER);
}

public SaveMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowMenuMain(client);
	}
	else if( action == MenuAction_Select )
	{
		if( index + 1 == TYPE_EXIT1 || index + 1 == TYPE_EXIT2 )
		{
			SaveLampSpawn(client, index + 1, 65280, "0 255 0");
		}
		else if( index + 1 == TYPE_FLOOD || index + 1 == TYPE_GENERATOR1 || index + 1 == TYPE_GENERATOR2 || index + 1 == TYPE_SPIN )
			SaveLampSpawn(client, index + 1, 16777215, "255 255 255");
		else if( index + 1 == TYPE_GENERATOR3 )
			SaveLampSpawn(client, index + 1, 255, "255 0 0");
		else
			SaveLampSpawn(client, index + 1, g_iCvarColor, g_sCvarColor);

		new menupos = GetMenuSelectionPosition();
		DisplayMenuAtItem(menu, client, menupos, MENU_TIME_FOREVER);
	}
}

SaveLampSpawn(client, type, color, String:sColor[12])
{
	decl Float:vPos[3], Float:vAng[3];
	new index = SetupLamp(client, vPos, vAng, color, type);
	if( index != -1 )
	{
		new cfgindex = SaveLampNew(client, vPos, vAng, type, sColor);
		g_iEntities[index][MAX_INDEX-1] = cfgindex;
	}
}

SaveLampNew(client, Float:vPos[3], Float:vAng[3], type, String:sColor[12])
{
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		new Handle:hCfg = OpenFile(sPath, "w");
		WriteFileLine(hCfg, "");
		CloseHandle(hCfg);
	}

	// Load config
	new Handle:hFile = CreateKeyValues("lamps");
	FileToKeyValues(hFile, sPath);

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if( !KvJumpToKey(hFile, sMap, true) )
	{
		PrintToChat(client, "%sError: Failed to add map to Lamp spawn config.", CHAT_TAG);
		CloseHandle(hFile);
		return 0;
	}

	// Retrieve how many are saved
	new iCount = KvGetNum(hFile, "num", 0);
	if( iCount >= MAX_ALLOWED )
	{
		PrintToChat(client, "%sError: Cannot add anymore Lamps. Used: (\x05%d/%d\x01).", CHAT_TAG, iCount, MAX_ALLOWED);
		CloseHandle(hFile);
		return 0;
	}

	// Save count
	iCount++;
	KvSetNum(hFile, "num", iCount);

	new Float:glow, halo, beam, length, width, speed;
	if( type == TYPE_POLICE )
	{
		length = 7;
		width = 10;
		speed = 800;
	}
	else if( type == TYPE_SPIN )
	{
		length = 200;
		width = 40;
		speed = 100;
	}
	else if( type == TYPE_FLOOD )
	{
		glow = 0.2;
		halo = 50;
		beam = 100;
		length = 300;
		width = 40;
	}
	else if( type == TYPE_GENERATOR1 || type == TYPE_GENERATOR2 || type == TYPE_GENERATOR3 )
	{
		glow = 0.2;
		halo = 50;
		beam = 50;
		length = 400;
		width = 40;
	}
	else if( type == TYPE_DROPPED )
	{
		glow = 0.2;
		halo = 50;
		length = 100;
		width = 20;
	}
	else if( type == TYPE_LIGHT15 )
	{
		glow = 0.2;
		halo = 10;
		length = 100;
		width = 30;
	}
	else if( type == TYPE_LIGHT18 || type == TYPE_LIGHT19 || type == TYPE_LIGHT20 )
	{
		if( type == TYPE_LIGHT18 )
			width = 350;
		else if( type == TYPE_LIGHT19 )
			width = 50;
		else if( type == TYPE_LIGHT20 )
			width = 150;

		glow = 0.2;
		halo = 50;
		beam = 50;
		length = 800;
	}

	// Save angle / origin
	decl String:sTemp[12];
	IntToString(iCount, sTemp, sizeof(sTemp));
	if( KvJumpToKey(hFile, sTemp, true) )
	{
		KvSetVector(hFile, "origin", vPos);
		KvSetVector(hFile, "angle", vAng);
		KvSetNum(hFile, "type", type);
		KvSetString(hFile, "color", sColor);
		if( glow )
			KvSetFloat(hFile, "glow", glow);
		if( halo )
			KvSetNum(hFile, "halo", halo);
		if( beam )
			KvSetNum(hFile, "beam", beam);
		if( length )
			KvSetNum(hFile, "length", length);
		if( width )
			KvSetNum(hFile, "width", width);
		if( speed )
			KvSetNum(hFile, "speed", speed);
	}

	// Save cfg
	KvRewind(hFile);
	KeyValuesToFile(hFile, sPath);
	CloseHandle(hFile);

	PrintToChat(client, "%s(\x05%d/%d\x01) - Saved at pos:[\x05%f %f %f\x01]", CHAT_TAG, iCount, MAX_ALLOWED, vPos[0], vPos[1], vPos[2]);

	return iCount;
}



// ====================================================================================================
//					SETUP POSITION
// ====================================================================================================
SetupLamp(client, Float:vPos[3] = NULL_VECTOR, Float:vAng[3] = NULL_VECTOR, color, type, cfgindex = 0)
{
	GetClientEyeAngles(client, vAng);
	GetClientEyePosition(client, vPos);

	new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilter, client);

	if( TR_DidHit(trace) == false )
	{
		CloseHandle(trace);
		return -1;
	}

	TR_GetEndPosition(vPos, trace);
	TR_GetPlaneNormal(trace, vAng);
	CloseHandle(trace);

	GetVectorAngles(vAng, vAng);
	decl Float:vDir[3];


	if( type == TYPE_BATTERY || type == TYPE_LANTERN || type == TYPE_FLOOD || type == TYPE_TV ||
		type == TYPE_GENERATOR1 || type == TYPE_GENERATOR2 || type == TYPE_GENERATOR3 )
	{
		vAng[0] += 90.0;
		vPos[2] += 0.2;
	}
	else if( type == TYPE_DROPPED )
		vAng[0] -= 270.0;
	else if( type == TYPE_SPIN )
	{
		vAng[0] += 90.0;
		vPos[2] += 5.0;
	}
	else if( type == TYPE_SEARCH )
	{
		vAng[1] -= 90.0;
		vAng[0] += 270.0;
		vPos[2] += 8.0;
	}
	else if( type == TYPE_EXIT1 )
		vAng[0] -= 90.0;
	else if( type == TYPE_EMERGENCY )
		vAng[1] -= 90.0;
	else if( type == TYPE_EXIT2 )
	{
		GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
		vPos[0] += vDir[0] * 8.0;
		vPos[1] += vDir[1] * 8.0;
		vPos[2] += vDir[2] * 8.0;
		vAng[0] -= 90.0;
	}
	else if( type == TYPE_POLICE )
	{
		GetAngleVectors(vAng, NULL_VECTOR, NULL_VECTOR, vDir);
		vAng[0] += 90.0;
		vPos[2] -= 62.0;
	}
	else if( type == TYPE_FLOOD )
		vPos[2] += 81.0;
	else if( type == TYPE_LIGHT1 )
	{
		vAng[0] -= 90.0;
		GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
		vPos[0] += vDir[0] * 5.0;
		vPos[1] += vDir[1] * 5.0;
	}
	else if( type == TYPE_LIGHT4 )
	{
		GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
		vPos[0] += vDir[0] * 5.0;
		vPos[1] += vDir[1] * 5.0;
	}
	else if( type == TYPE_LIGHT6 )
	{
		vAng[0] -= 90.0;
		GetAngleVectors(vAng, NULL_VECTOR, NULL_VECTOR, vDir);
		vPos[0] += vDir[0] * -5.0;
		vPos[1] += vDir[1] * -5.0;
		vPos[2] += vDir[2] * -5.0;
	}
	else if( type == TYPE_LIGHT7 || type == TYPE_LIGHT8 )
		vAng[1] -= 90.0;
	else if( type == TYPE_LIGHT5 )
	{
		GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
		vPos[0] += vDir[0] * 4.0;
		vPos[1] += vDir[1] * 4.0;
	}
	else if( type == TYPE_LIGHT9 )
		vAng[0] -= 90.0;
	else if( type == TYPE_LIGHT11 )
	{
		GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
		vPos[0] += vDir[0] * 16.0;
		vPos[1] += vDir[1] * 16.0;
	}
	else if( type == TYPE_LIGHT14 )
	{
		GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
		vPos[0] += vDir[0] * 10.0;
		vPos[1] += vDir[1] * 10.0;
		vPos[2] += vDir[2] * 10.0;
		vAng[0] += 90.0;
	}
	else if( type == TYPE_LIGHT17 )
		vAng[0] -= 90.0;
	else if( type == TYPE_LIGHT18 || type == TYPE_LIGHT19 || type == TYPE_LIGHT20 )
		vAng[0] += 90.0;
	else if( type >= TYPE_LIGHT22 )
		vAng[0] += 90.0;


	new Float:glow = 0.3, halo = 100, beam = 100, length, width, speed;
	if( type == TYPE_POLICE )
	{
		length = 7;
		width = 10;
		speed = 800;
	}
	else if( type == TYPE_SPIN )
	{
		length = 200;
		width = 40;
		speed = 100;
	}
	else if( type == TYPE_FLOOD )
	{
		glow = 0.2;
		halo = 50;
		length = 300;
		width = 40;
	}
	else if( type == TYPE_GENERATOR1 || type == TYPE_GENERATOR2 || type == TYPE_GENERATOR3 )
	{
		glow = 0.2;
		halo = 50;
		beam = 50;
		length = 400;
		width = 40;
	}
	else if( type == TYPE_DROPPED )
	{
		halo = 50;
		length = 100;
		width = 20;
	}
	else if( type == TYPE_LIGHT15 )
	{
		glow = 0.2;
		halo = 10;
		length = 100;
		width = 30;
	}
	else if( type == TYPE_LIGHT18 || type == TYPE_LIGHT19 || type == TYPE_LIGHT20 )
	{
		if( type == TYPE_LIGHT18 )
			width = 350;
		else if( type == TYPE_LIGHT19 )
			width = 50;
		else if( type == TYPE_LIGHT20 )
			width = 150;

		glow = 0.2;
		halo = 50;
		beam = 50;
		length = 800;
	}

	new index = SpawnLamp(vPos, vAng, color, type, cfgindex, g_fCvarBright, glow, halo, beam, length, width, speed, g_iCvarBreak);
	return index;
}

public bool:TraceFilter(entity, contentsMask, any:client)
{
	if( entity == client )
		return false;
	return true;
}



// ====================================================================================================
//					MENU :: BRIGHTNESS
// ====================================================================================================
ShowMenuBrightness(client)
{
	DisplayMenu(g_hMenuBrightness, client, MENU_TIME_FOREVER);
}

public BrightnessMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowMenuMain(client);
	}
	else if( action == MenuAction_Select )
	{
		if( index == 0 )
			SetBrightness(client, 50);
		else if( index == 1 )
			SetBrightness(client, 100);
		else if( index == 2 )
			SetBrightness(client, 200);
		else if( index == 3 )
			SetBrightness(client, 250);
		else if( index == 4 )
			SetBrightness(client, 300);
		else if( index == 5 )
			SetBrightness(client, 500);
		else if( index == 6 )
			SaveLampData(client, 0, 1);
		ShowMenuBrightness(client);
	}
}

SetBrightness(client, brightness)
{
	new entity, index = -1;

	entity = GetClientAimTarget(client, false);
	if( entity == -1 ) return;
	entity = EntIndexToEntRef(entity);

	for( new i = 0; i < MAX_ALLOWED; i++ )
	{
		if( g_iEntities[i][0] == entity )
		{
			index = i;
			break;
		}
	}

	if( index == -1 )
	{
		return;
	}

	entity = g_iEntities[index][1];
	if( IsValidEntRef(entity) )
	{
		SetVariantEntity(entity);
		SetVariantInt(brightness);
		AcceptEntityInput(entity, "distance");
	}
}

// ====================================================================================================
//					MENU :: COLOR
// ====================================================================================================
ShowMenuColor(client)
{
	DisplayMenu(g_hMenuColor, client, MENU_TIME_FOREVER);
}

public ColorMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowMenuMain(client);
	}
	else if( action == MenuAction_Select )
	{
		if( index == 0 )
			SetLampColor(client, "255", "0", "0");
		else if( index == 1 )
			SetLampColor(client, "0", "255", "0");
		else if( index == 2 )
			SetLampColor(client, "0", "0", "255");
		else if( index == 3 )
			SetLampColor(client, "255", "0", "255");
		else if( index == 4 )
			SetLampColor(client, "255", "150", "0");
		else if( index == 5 )
			SetLampColor(client, "255", "255", "255");
		else if( index == 6 )
			SaveLampData(client, 1, 0);
		ShowMenuColor(client);
	}
}

// ====================================================================================================
//					MENU :: ANGLE
// ====================================================================================================
ShowMenuAng(client)
{
	DisplayMenu(g_hMenuAng, client, MENU_TIME_FOREVER);
}

public AngMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowMenuMain(client);
	}
	else if( action == MenuAction_Select )
	{
		if( index == 6 )
			SaveLampData(client, 0, 0);
		else
			SetAngle(client, index);
		ShowMenuAng(client);
	}
}

SetAngle(client, index)
{
	new aim = GetClientAimTarget(client, false);
	if( aim != -1 )
	{
		new Float:vAng[3], entity;
		aim = EntIndexToEntRef(aim);

		for( new i = 0; i < MAX_ALLOWED; i++ )
		{
			entity = g_iEntities[i][0];

			if( entity == aim  )
			{
				if( g_iEntities[i][MAX_INDEX-2] == TYPE_SPIN )
					entity = g_iEntities[i][2];

				GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

				if( index == 0 ) vAng[0] += 5.0;
				else if( index == 1 ) vAng[1] += 5.0;
				else if( index == 2 ) vAng[2] += 5.0;
				else if( index == 3 ) vAng[0] -= 5.0;
				else if( index == 4 ) vAng[1] -= 5.0;
				else if( index == 5 ) vAng[2] -= 5.0;

				TeleportEntity(entity, NULL_VECTOR, vAng, NULL_VECTOR);

				PrintToChat(client, "%sNew angles: %f %f %f", CHAT_TAG, vAng[0], vAng[1], vAng[2]);
				break;
			}
		}
	}
}

// ====================================================================================================
//					MENU :: ORIGIN
// ====================================================================================================
ShowMenuPos(client)
{
	DisplayMenu(g_hMenuPos, client, MENU_TIME_FOREVER);
}

public PosMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )
			ShowMenuMain(client);
	}
	else if( action == MenuAction_Select )
	{
		if( index == 6 )
			SaveLampData(client, 0, 0);
		else
			SetOrigin(client, index);
		ShowMenuPos(client);
	}
}

SetOrigin(client, index)
{
	new aim = GetClientAimTarget(client, false);
	if( aim != -1 )
	{
		new Float:vPos[3], entity;
		aim = EntIndexToEntRef(aim);

		for( new i = 0; i < MAX_ALLOWED; i++ )
		{
			entity = g_iEntities[i][0];

			if( entity == aim  )
			{
				if( g_iEntities[i][MAX_INDEX-2] == TYPE_SPIN )
					entity = g_iEntities[i][2];

				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

				if( index == 0 ) vPos[0] += 0.5;
				else if( index == 1 ) vPos[1] += 0.5;
				else if( index == 2 ) vPos[2] += 0.5;
				else if( index == 3 ) vPos[0] -= 0.5;
				else if( index == 4 ) vPos[1] -= 0.5;
				else if( index == 5 ) vPos[2] -= 0.5;

				TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

				PrintToChat(client, "%sNew origin: %f %f %f", CHAT_TAG, vPos[0], vPos[1], vPos[2]);
				break;
			}
		}
	}
}



// ====================================================================================================
//					COMMANDS - TEMP, SAVE, DELETE, CLEAR, WIPE
// ====================================================================================================
//					sm_lamp
// ====================================================================================================
public Action:CmdLamp(client, args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Lamp] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	ShowMenuMain(client);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_lampdel
// ====================================================================================================
public Action:CmdLampDelete(client, args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Lamp] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	new entity, index = -1;

	entity = GetClientAimTarget(client, false);
	if( entity == -1 ) return Plugin_Handled;
	entity = EntIndexToEntRef(entity);

	new cfgindex;
	for( new i = 0; i < MAX_ALLOWED; i++ )
	{
		if( g_iEntities[i][0] == entity )
		{
			index = i;
			break;
		}
	}

	if( index == -1 )
		return Plugin_Handled;

	cfgindex = g_iEntities[index][MAX_INDEX-1];
	if( cfgindex == 0 )
	{
		DeleteLamp(index);
		return Plugin_Handled;
	}

	for( new i = index + 1; i < MAX_ALLOWED; i++ )
	{
		if( g_iEntities[i][MAX_INDEX-1] )
			g_iEntities[i][MAX_INDEX-1]--;
	}
	
	DeleteLamp(index);

	// Load config
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		return Plugin_Handled;
	}

	new Handle:hFile = CreateKeyValues("lamps");
	if( !FileToKeyValues(hFile, sPath) )
	{
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Check for current map in the config
	decl String:sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !KvJumpToKey(hFile, sMap) )
	{
		CloseHandle(hFile);
		return Plugin_Handled;
	}

	// Retrieve how many
	new iCount = KvGetNum(hFile, "num", 0);
	if( iCount == 0 )
	{
		CloseHandle(hFile);
		return Plugin_Handled;
	}


	new bool:bMove;
	decl String:sTemp[16];

	// Move the other entries down
	for( new i = cfgindex; i <= iCount; i++ )
	{
		IntToString(i, sTemp, sizeof(sTemp));
		if( KvJumpToKey(hFile, sTemp) )
		{
			if( !bMove )
			{
				bMove = true;
				KvDeleteThis(hFile);
			}
			else
			{
				IntToString(i-1, sTemp, sizeof(sTemp));
				KvSetSectionName(hFile, sTemp);
			}
		}

		KvRewind(hFile);
		KvJumpToKey(hFile, sMap);
	}

	iCount--;
	KvSetNum(hFile, "num", iCount);

	// Save to file
	KvRewind(hFile);
	KeyValuesToFile(hFile, sPath);
	CloseHandle(hFile);

	PrintToChat(client, "%s(\x05%d/%d\x01) - Lamp removed from config.", CHAT_TAG, iCount, MAX_ALLOWED);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_lamprefresh
// ====================================================================================================
public Action:CmdLampRefresh(client, args)
{
	g_bLoaded = false;
	ResetPlugin();
	LoadLamps();
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_lampclear
// ====================================================================================================
public Action:CmdLampClear(client, args)
{
	ResetPlugin();
	PrintToChat(client, "%sAll Lamps cleared from the map.", CHAT_TAG);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_lampwipe
// ====================================================================================================
public Action:CmdLampWipe(client, args)
{
	WipeLamps(client);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_lampset
// ====================================================================================================
public Action:CmdLampSet(client, args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Lamp] Commands may only be used in-game on a dedicated server..");
		return Plugin_Handled;
	}

	if( args == 0 )
	{
		SaveLampData(client, 1, 1);
		return Plugin_Handled;
	}

	if( args == 2 )
	{
		decl String:sTemp[16];
		GetCmdArg(1, sTemp, sizeof(sTemp));

		if( strcmp(sTemp, "bright") == 0 )
		{
			GetCmdArg(2, sTemp, sizeof(sTemp));
			SaveLampData(client, 0, StringToInt(sTemp));
		}
		else if( strcmp(sTemp, "glow") == 0 )
		{
			GetCmdArg(2, sTemp, sizeof(sTemp));
			SaveLampData(client, 0, 0, StringToFloat(sTemp));
		}
		else if( strcmp(sTemp, "beam") == 0 )
		{
			GetCmdArg(2, sTemp, sizeof(sTemp));
			SaveLampData(client, 0, 0, -1.0, StringToInt(sTemp));
		}
		else if( strcmp(sTemp, "length") == 0 )
		{
			GetCmdArg(2, sTemp, sizeof(sTemp));
			SaveLampData(client, 0, 0, -1.0, -1, StringToInt(sTemp));
		}
		else if( strcmp(sTemp, "width") == 0 )
		{
			GetCmdArg(2, sTemp, sizeof(sTemp));
			SaveLampData(client, 0, 0, -1.0, -1, -1, StringToInt(sTemp));
		}
		else if( strcmp(sTemp, "speed") == 0 )
		{
			GetCmdArg(2, sTemp, sizeof(sTemp));
			SaveLampData(client, 0, 0, -1.0, -1, -1, -1, StringToInt(sTemp));
		}
		else if( strcmp(sTemp, "break") == 0 )
		{
			GetCmdArg(2, sTemp, sizeof(sTemp));
			SaveLampData(client, 0, 0, -1.0, -1, -1, -1, -1, StringToInt(sTemp));
		}
		else if( strcmp(sTemp, "halo") == 0 )
		{
			GetCmdArg(2, sTemp, sizeof(sTemp));
			SaveLampData(client, 0, 0, -1.0, -1, -1, -1, -1, -1, StringToInt(sTemp));
		}

		return Plugin_Handled;
	}

	if( args == 3 )
	{
		decl String:sRed[4], String:sGreen[4], String:sBlue[4];
		GetCmdArg(1, sRed, sizeof(sRed));
		GetCmdArg(2, sGreen, sizeof(sGreen));
		GetCmdArg(3, sBlue, sizeof(sBlue));

		SetLampColor(client, sRed, sGreen, sBlue);
		SaveLampData(client, 1);
	}

	return Plugin_Handled;
}

SetLampColor(client, String:sRed[4], String:sGreen[4], String:sBlue[4])
{
	new entity, index = -1;

	entity = GetClientAimTarget(client, false);
	if( entity == -1 ) return;
	entity = EntIndexToEntRef(entity);

	for( new i = 0; i < MAX_ALLOWED; i++ )
	{
		if( g_iEntities[i][0] == entity )
		{
			index = i;
			break;
		}
	}

	if( index == -1 )
		return;

	entity = g_iEntities[index][1];
	if( IsValidEntRef(entity) )
	{
		new color;
		color = StringToInt(sRed);
		color += 256 * StringToInt(sGreen);
		color += 65536 * StringToInt(sBlue);
		SetEntProp(entity, Prop_Send, "m_clrRender", color);
		PrintToChat(client, "%sLamp color set to '\x05%s %s %s\x01'.", CHAT_TAG, sRed, sGreen, sBlue);
	}
}

SaveLampData(client, color = 0, brightness = 0, Float:glow = -1.0, beam = -1, length = -1, width = -1, speed = -1, breakable = -1, halo = -1 )
{
	new entity, index = -1;

	entity = GetClientAimTarget(client, false);
	if( entity == -1 ) return;
	entity = EntIndexToEntRef(entity);

	for( new i = 0; i < MAX_ALLOWED; i++ )
	{
		if( g_iEntities[i][0] == entity )
		{
			index = i;
			break;
		}
	}

	if( index == -1 )
		return;

	new cfgindex = g_iEntities[index][MAX_INDEX-1];
	if( cfgindex == 0 )
	{
		decl Float:vPos[3], Float:vAng[3], String:sColor[12];

		new type = g_iEntities[index][MAX_INDEX-2];
		if( type == TYPE_SPIN )
			entity = g_iEntities[index][2];

		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
		GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

		entity = g_iEntities[index][1];
		color = GetEntProp(entity, Prop_Send, "m_clrRender");
		Format(sColor,sizeof(sColor), "%d %d %d", color & 0xFF, (color & 0xFF00) / 256, color / 65536);

		cfgindex = SaveLampNew(client, vPos, vAng, type, sColor);
		g_iEntities[index][MAX_INDEX-1] = cfgindex;

		if( cfgindex == 0 )
		{
			PrintToChat(client, "%sError saving temporary lamp.", CHAT_TAG);
			return;
		}
		else
			PrintToChat(client, "%sTemporary lamp now saved to the data config", CHAT_TAG);
	}

	// FileExists
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the config (\x05%s\x01).", CHAT_TAG, sPath);
		return;
	}

	// Load KV
	new Handle:hFile = CreateKeyValues("lamps");
	if( !FileToKeyValues(hFile, sPath) )
	{
		PrintToChat(client, "%sError: Cannot read the config (\x05%s\x01).", CHAT_TAG, sPath);
		CloseHandle(hFile);
		return;
	}

	// Check for current map in the config
	decl String:sTemp[64], String:sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if( !KvJumpToKey(hFile, sMap) )
	{
		PrintToChat(client, "%sError: Cannot find the current map in the config.", CHAT_TAG);
		CloseHandle(hFile);
		return;
	}

	KvJumpToKey(hFile, sMap);
	IntToString(cfgindex, sTemp, sizeof(sTemp));

	if( KvJumpToKey(hFile, sTemp) )
	{
		if( glow != -1.0 || beam != -1 || length != -1 || width != -1 || speed != -1 || breakable != -1 || halo != -1 )
		{
			if( glow != -1.0 )
			{
				KvSetFloat(hFile, "glow", glow);
				PrintToChat(client, "%sSaved \x03glow\x01 to the config.", CHAT_TAG);
			}
			else if( beam != -1 )
			{
				KvSetNum(hFile, "beam", beam);
				PrintToChat(client, "%sSaved \x03beam\x01 to the config.", CHAT_TAG);
			}
			else if( length != -1 )
			{
				KvSetNum(hFile, "length", length);
				PrintToChat(client, "%sSaved \x03length\x01 to the config.", CHAT_TAG);
			}
			else if( width != -1 )
			{
				KvSetNum(hFile, "width", width);
				PrintToChat(client, "%sSaved \x03width\x01 to the config.", CHAT_TAG);
			}
			else if( speed != -1 )
			{
				KvSetNum(hFile, "speed", speed);
				PrintToChat(client, "%sSaved \x03speed\x01 to the config.", CHAT_TAG);
			}
			else if( halo != -1 )
			{
				KvSetNum(hFile, "halo", halo);
				PrintToChat(client, "%sSaved \x03halo\x01 to the config.", CHAT_TAG);
			}
			else if( breakable != -1 )
			{
				KvSetNum(hFile, "halo", breakable);
				if( breakable == 0 )
					PrintToChat(client, "%sSaved as not \x03breakable\x01.", CHAT_TAG);
				else
					PrintToChat(client, "%sSaved as \x03breakable\x01.", CHAT_TAG);
			}

			KvRewind(hFile);
			KeyValuesToFile(hFile, sPath);

			DeleteLamp(index);
			SpawnData(cfgindex, hFile, sMap);
			g_iEntities[index][MAX_INDEX-1] = cfgindex;

			CloseHandle(hFile);
			return;
		}


		if( (brightness == 0 && color == 0) || (brightness == 1 && color == 1) )
		{
			decl Float:vPos[3], Float:vAng[3];

			if( g_iEntities[index][MAX_INDEX-2] == TYPE_SPIN )
				entity = g_iEntities[index][2];

			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
			GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

			KvSetVector(hFile, "angle", vAng);
			KvSetVector(hFile, "origin", vPos);
		}

		if( brightness == 1 )
		{
			new type = g_iEntities[index][MAX_INDEX-2];
			if( type == TYPE_GENERATOR3 || type == TYPE_TV || type == TYPE_EMERGENCY )
			{
				PrintToChat(client, "%sNo dynamic light to set brightness");
				return;
			}

			entity = g_iEntities[index][1];
			if( IsValidEntRef(entity) )
			{
				new Float:radius = GetEntPropFloat(entity, Prop_Send, "m_Radius");
				if( radius != 150.0 )
					KvSetFloat(hFile, "brightness", radius);
			}
		}

		if( color == 1 )
		{
			entity = g_iEntities[index][1];
			if( IsValidEntRef(entity) )
			{
				color = GetEntProp(entity, Prop_Send, "m_clrRender");
				decl String:sColor[12];
				Format(sColor,sizeof(sColor), "%d %d %d", color & 0xFF, (color & 0xFF00) / 256, color / 65536);
				KvSetString(hFile, "color", sColor);
			}
		}

		KvRewind(hFile);
		KeyValuesToFile(hFile, sPath);

		if( color && brightness == 0 )
			PrintToChat(client, "%sSaved color to the config.", CHAT_TAG);
		else if( brightness == 1 && color == 0 )
			PrintToChat(client, "%sSaved brightness to the config.", CHAT_TAG);
		else if( brightness == 1 && color )
			PrintToChat(client, "%sSaved angles, origin, brightness and color to the config.", CHAT_TAG);
		else
			PrintToChat(client, "%sSaved angles and origin to the config.", CHAT_TAG);
	}

	CloseHandle(hFile);
}

ResetPlugin()
{
	for( new i = 0; i < MAX_ALLOWED; i++ )
		DeleteLamp(i);
}

DeleteLamp(index, bool:all = true)
{
	new entity;

	KillEntity(g_iEntities[index][1]);
	g_iEntities[index][1] = 0;

	KillEntity(g_iEntities[index][2]);
	g_iEntities[index][2] = 0;

	KillEntity(g_iEntities[index][3]);
	g_iEntities[index][3] = 0;

	KillEntity(g_iEntities[index][4]);
	g_iEntities[index][4] = 0;

	KillEntity(g_iEntities[index][5]);
	g_iEntities[index][5] = 0;

	KillEntity(g_iEntities[index][6]);
	g_iEntities[index][6] = 0;

	if( g_iEntities[index][MAX_INDEX-2] == TYPE_TV )
	{
		entity = g_iEntities[index][0];
		if( IsValidEntRef(entity) )
		{
			StopSound(entity, SNDCHAN_AUTO, SOUND_STATIC);
			UnhookSingleEntityOutput(entity, "OnTakeDamage", OnBreak);
			UnhookSingleEntityOutput(entity, "OnHealthChanged", OnBreak);
		}
	}

	entity = g_iEntities[index][0];

	if( IsValidEntRef(entity) )
	{
		AcceptEntityInput(entity, "ClearParent");

		if( all )
		{
			g_iEntities[index][0] = 0;
			UnhookSingleEntityOutput(entity, "OnTakeDamage", OnBreak);
			UnhookSingleEntityOutput(entity, "OnHealthChanged", OnBreak);
			AcceptEntityInput(entity, "Kill");
		}
	}
}

KillEntity(entity)
{
	if( IsValidEntRef(entity) )
	{
		AcceptEntityInput(entity, "ClearParent");
		AcceptEntityInput(entity, "LightOff");
		AcceptEntityInput(entity, "TurnOff");
		SetVariantString("OnUser1 !self:Kill::0.5:1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
}

bool:IsValidEntRef(entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

PrecacheParticle(const String:ParticleName[])
{
	new particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", ParticleName);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	SetVariantString("OnUser1 !self:Kill::0.1:1");
	AcceptEntityInput(particle, "AddOutput");
	AcceptEntityInput(particle, "FireUser1");
}