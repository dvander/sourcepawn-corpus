/*
*	Health Vending Machines
*	Copyright (C) 2021 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION 		"1.10"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Health Vending Machines
*	Author	:	SilverShot
*	Descrp	:	Auto-spawn vending machines which supply health when used.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=179265
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.10 (10-Apr-2021)
	- Increased the interaction range of Vending Machines. This allows positioning over a maps vendors. Thanks to "Shao" for reporting.

1.9 (30-Sep-2020)
	- Fixed compile errors on SM 1.11.

1.8 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.
	- Various optimizations and fixes.

1.7 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.6 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.
	- Changed cvar "l4d_vendor_modes_tog" now supports L4D1.

1.5 (25-Aug-2013)
	- Fixed the plugin crashing or not working on some maps.

1.4 (21-Jul-2013)
	- Removed Sort_Random work-around. This was fixed in SourceMod 1.4.7, all should update or spawning issues will occur.

1.3 (01-Jul-2012)
	- Fixed healing players above 100 HP - Thanks to "adrianman" for reporting.

1.2 (01-Jun-2012)
	- Added cvar "l4d_vendor_glow_color" to set the glow color, L4D2 only.
	- Text corrections to the cvars - Thanks to "The 5th Survivor".
	- Restricted command "sm_vendorglow" to L4D2 only.
	- Restricted cvar "l4d_vendor_glow" to L4D2 only.

1.1 (10-May-2012)
	- Added 2 new models, Coffee and Snacks - Thanks to "JoBarfCreepy".
	- Added 4 new cvars for the above addition.
	- Added cvar "l4d_vendor_modes_off" to control which game modes the plugin works in.
	- Added cvar "l4d_vendor_modes_tog" same as above, but only works for L4D2.
	- Changed cvar "l4d_vendor_modes" to enable the plugin on specified modes.
	- Removed max entity check and related error logging.

1.0 (28-Feb-2012)
	- Initial release.

========================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	"AtomicStryker" for "[Tech Demo] L4D2 Vocalize ANYTHING" - Modified VocalizeScene function.
	https://forums.alliedmods.net/showthread.php?t=122270

*	"Zuko & McFlurry" for "[L4D2] Weapon/Zombie Spawner" - Modified SetTeleportEndPoint function.
	https://forums.alliedmods.net/showthread.php?t=109659

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CHAT_TAG			"\x04[\x05Vendor\x04] \x01"
#define CONFIG_SPAWNS		"data/l4d_vendor.cfg"
#define MAX_VENDORS			32

#define MODEL_COOLER		"models/props_interiors/water_cooler.mdl"
#define MODEL_DISPENSER		"models/props_equipment/fountain_drinks.mdl"
#define MODEL_FOUNTAIN		"models/props_interiors/drinking_fountain.mdl"
#define MODEL_VENDING		"models/props_office/vending_machine01.mdl"
#define MODEL_COFFEE		"models/props_unique/coffeemachine01.mdl"
#define MODEL_SNACKS		"models/props_equipment/snack_machine.mdl"
#define SOUND_CAN			"physics/metal/soda_can_impact_hard1.wav"
#define SOUND_BUTTON		"buttons/button4.wav"
#define SOUND_VENDOR1		"ambient/spacial_loops/vendingmachinehum_loop.wav"
#define SOUND_VENDOR2		"ambient/ambience/generator_amb01_loop.wav"
#define SOUND_VENDOR3		"ambient/spacial_loops/fluorescent_lights_loop.wav"
#define SOUND_WATER			"ambient/spacial_loops/4b_hospatrium_waterleak.wav"
#define SOUND_DROP1			"doors/door_metal_medium_close1.wav"
#define SOUND_DROP2			"doors/door1_stop.wav"
#define SOUND_DROP3			"doors/door_metal_thin_move1.wav"


ConVar g_hCvarAllow, g_hCvarGlow, g_hCvarGlowCol, g_hCvarHealthC, g_hCvarHealthCo, g_hCvarHealthD, g_hCvarHealthF, g_hCvarHealthS, g_hCvarHealthV, g_hCvarMPGameMode, g_hCvarMaxC, g_hCvarMaxCo, g_hCvarMaxD, g_hCvarMaxF, g_hCvarMaxS, g_hCvarMaxV, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarRandom, g_hCvarTemp, g_hCvarTimed, g_hDecayRate;
Menu g_hMenuAng, g_hMenuPos;
float g_fCvarTimed, g_fDecayRate;
bool g_bCvarAllow, g_bMapStarted, g_bGlow, g_bLoaded;
int g_iCvarGlow, g_iCvarGlowCol, g_iCvarHealthC, g_iCvarHealthCo, g_iCvarHealthD, g_iCvarHealthF, g_iCvarHealthS, g_iCvarHealthV, g_iCvarMaxC, g_iCvarMaxCo, g_iCvarMaxD, g_iCvarMaxF, g_iCvarMaxS, g_iCvarMaxV, g_iCvarRandom, g_iCvarTemp, g_iVendorCount;
bool g_bLeft4Dead2; int g_iVendors[MAX_VENDORS][5];	// [0] prop_dynamic, [1] = func_button_timed, [2] = Type, [3] = Used count, [4] = Cfg Index.


enum
{
	TYPE_COOLER = 1,
	TYPE_FOUNTAIN,
	TYPE_DRINKS,
	TYPE_VENDOR,
	TYPE_SNACKS,
	TYPE_COFFEE
}



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Health Vending Machine",
	author = "SilverShot",
	description = "Spawn vending machines which supply health when used.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=179265"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarAllow =			CreateConVar(	"l4d_vendor_allow",				"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	if( g_bLeft4Dead2 )
	{
		g_hCvarGlow =		CreateConVar(	"l4d_vendor_glow",				"100",			"0=Off. Any other value is the range at which the glow will turn on.", CVAR_FLAGS );
		g_hCvarGlowCol =	CreateConVar(	"l4d_vendor_glow_color",		"255 150 0",	"0=Default glow color. Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", CVAR_FLAGS );
	}
	g_hCvarHealthCo =		CreateConVar(	"l4d_vendor_health_coffee",		"5",			"The health given to players when using the Coffee Machines (6).", CVAR_FLAGS );
	g_hCvarHealthC =		CreateConVar(	"l4d_vendor_health_cooler",		"2",			"The health given to players when using the Water Coolers (1).", CVAR_FLAGS );
	g_hCvarHealthD =		CreateConVar(	"l4d_vendor_health_drinks",		"5",			"The health given to players when using the Small Drink vendor (3).", CVAR_FLAGS );
	g_hCvarHealthF =		CreateConVar(	"l4d_vendor_health_fountain",	"2",			"The health given to players when using the Water Fountains (2).", CVAR_FLAGS );
	g_hCvarHealthS =		CreateConVar(	"l4d_vendor_health_snacks",		"5",			"The health given to players when using the Snack Vendors (5).", CVAR_FLAGS );
	g_hCvarHealthV =		CreateConVar(	"l4d_vendor_health_vendor",		"5",			"The health given to players when using the Drink Vendors (4).", CVAR_FLAGS );
	g_hCvarMaxCo =			CreateConVar(	"l4d_vendor_max_coffee",		"10",			"0=Infinite. Maximum number of times a Coffee Machine can be used.", CVAR_FLAGS );
	g_hCvarMaxC =			CreateConVar(	"l4d_vendor_max_cooler",		"15",			"0=Infinite. Maximum number of times a Water Cooler can be used.", CVAR_FLAGS );
	g_hCvarMaxD =			CreateConVar(	"l4d_vendor_max_drinks",		"10",			"0=Infinite. Maximum number of times a Small Drink vendor can be used.", CVAR_FLAGS );
	g_hCvarMaxF =			CreateConVar(	"l4d_vendor_max_fountain",		"15",			"0=Infinite. Maximum number of times a Water Fountain can be used.", CVAR_FLAGS );
	g_hCvarMaxS =			CreateConVar(	"l4d_vendor_max_snacks",		"10",			"0=Infinite. Maximum number of times a Snack vendor can be used.", CVAR_FLAGS );
	g_hCvarMaxV =			CreateConVar(	"l4d_vendor_max_vendor",		"10",			"0=Infinite. Maximum number of times a Drink vendor can be used.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d_vendor_modes",				"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d_vendor_modes_off",			"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d_vendor_modes_tog",			"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarRandom =			CreateConVar(	"l4d_vendor_random",			"-1",			"-1=All, 0=None. Otherwise randomly select this many vendors to spawn from the maps config.", CVAR_FLAGS );
	g_hCvarTemp =			CreateConVar(	"l4d_vendor_temp",				"25",			"-1=Add temporary health, 0=Add to normal health. Values between 1 and 100 creates a chance to give normal health.", CVAR_FLAGS );
	g_hCvarTimed =			CreateConVar(	"l4d_vendor_timed",				"1.0",			"How many seconds it takes to use a vending machine.", CVAR_FLAGS, true, 1.0, true, 20.0 );
	CreateConVar(							"l4d_vendor_version",			PLUGIN_VERSION, "Vending Machine plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d_vendor");

	g_hDecayRate = FindConVar("pain_pills_decay_rate");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarHealthC.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHealthD.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHealthF.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHealthV.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHealthCo.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHealthS.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMaxC.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMaxD.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMaxF.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMaxV.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMaxCo.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMaxS.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRandom.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTemp.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTimed.AddChangeHook(ConVarChanged_Cvars);
	g_hDecayRate.AddChangeHook(ConVarChanged_Cvars);
	if( g_bLeft4Dead2 )
	{
		g_hCvarGlow.AddChangeHook(ConVarChanged_Glow);
		g_hCvarGlowCol.AddChangeHook(ConVarChanged_Glow);
	}

	RegAdminCmd("sm_vendor",		CmdVendorTemp,		ADMFLAG_ROOT, 	"Spawns a temporary vending machine at your crosshair. Usage: sm_vendor <1|2|3|4|5|6>.");
	RegAdminCmd("sm_vendorsave",	CmdVendorSave,		ADMFLAG_ROOT, 	"Spawns a vending machine at your crosshair and saves to config. Usage: sm_vendorsave <1|2|3|4|5|6>.");
	RegAdminCmd("sm_vendordel",		CmdVendorDelete,	ADMFLAG_ROOT, 	"Removes the vending machine your crosshair is pointing at and deletes from the config if saved.");
	RegAdminCmd("sm_vendorwipe",	CmdVendorWipe,		ADMFLAG_ROOT, 	"Removes all vendors from the current map and deletes them from the config.");
	if( g_bLeft4Dead2 )
		RegAdminCmd("sm_vendorglow",CmdVendorGlow,		ADMFLAG_ROOT, 	"Toggle to enable glow on all vendors to see where they are placed.");
	RegAdminCmd("sm_vendorlist",	CmdVendorList,		ADMFLAG_ROOT, 	"Display a list vending machine positions and the total number of.");
	RegAdminCmd("sm_vendorang",		CmdVendorAng,		ADMFLAG_ROOT, 	"Displays a menu to adjust the vendor angles your crosshair is over.");
	RegAdminCmd("sm_vendorpos",		CmdVendorPos,		ADMFLAG_ROOT, 	"Displays a menu to adjust the vendor origin your crosshair is over.");
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

public void OnMapStart()
{
	g_bMapStarted = true;
	PrecacheSound(SOUND_CAN);
	PrecacheSound(SOUND_WATER);
	PrecacheSound(SOUND_DROP1);
	PrecacheSound(SOUND_DROP2);
	PrecacheSound(SOUND_DROP3);
	PrecacheSound(SOUND_VENDOR1);
	PrecacheSound(SOUND_VENDOR2);
	PrecacheSound(SOUND_VENDOR3);
	PrecacheModel(MODEL_COOLER, true);
	PrecacheModel(MODEL_DISPENSER, true);
	PrecacheModel(MODEL_FOUNTAIN, true);
	PrecacheModel(MODEL_VENDING, true);
	PrecacheModel(MODEL_COFFEE, true);
	PrecacheModel(MODEL_SNACKS, true);
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

public void ConVarChanged_Glow(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_iCvarGlow = g_hCvarGlow.IntValue;
	g_iCvarGlowCol = GetColor(g_hCvarGlowCol);
	VendorGlow(g_bGlow);
}

int GetColor(ConVar hCvar)
{
	char sTemp[12];
	hCvar.GetString(sTemp, sizeof(sTemp));

	if( sTemp[0] == 0 )
		return 0;

	char sColors[3][4];
	int color = ExplodeString(sTemp, " ", sColors, sizeof(sColors), sizeof(sColors[]));

	if( color != 3 )
		return 0;

	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);

	return color;
}

void GetCvars()
{
	if( g_bLeft4Dead2 )
	{
		g_iCvarGlow = g_hCvarGlow.IntValue;
		g_iCvarGlowCol = GetColor(g_hCvarGlowCol);
	}

	g_iCvarHealthC = g_hCvarHealthC.IntValue;
	g_iCvarHealthD = g_hCvarHealthD.IntValue;
	g_iCvarHealthF = g_hCvarHealthF.IntValue;
	g_iCvarHealthV = g_hCvarHealthV.IntValue;
	g_iCvarHealthCo = g_hCvarHealthCo.IntValue;
	g_iCvarHealthS = g_hCvarHealthS.IntValue;
	g_iCvarMaxC = g_hCvarMaxC.IntValue;
	g_iCvarMaxD = g_hCvarMaxD.IntValue;
	g_iCvarMaxF = g_hCvarMaxF.IntValue;
	g_iCvarMaxV = g_hCvarMaxV.IntValue;
	g_iCvarMaxCo = g_hCvarMaxCo.IntValue;
	g_iCvarMaxS = g_hCvarMaxS.IntValue;
	g_iCvarRandom = g_hCvarRandom.IntValue;
	g_iCvarTemp = g_hCvarTemp.IntValue;
	g_fCvarTimed = g_hCvarTimed.FloatValue;
	g_fDecayRate = g_hDecayRate.FloatValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		LoadVendors();
		HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		ResetPlugin();
		UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if( g_bMapStarted == false )
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
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
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.4, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TimerStart(Handle timer)
{
	ResetPlugin();
	LoadVendors();
}



// ====================================================================================================
//					LOAD VENDORS
// ====================================================================================================
void LoadVendors()
{
	if( g_bLoaded || g_iCvarRandom == 0 ) return;
	g_bLoaded = true;

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		return;

	// Load config
	KeyValues hFile = new KeyValues("vendors");
	if( !hFile.ImportFromFile(sPath) )
	{
		delete hFile;
		return;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		delete hFile;
		return;
	}

	// Retrieve how many vendors to display
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return;
	}

	// Spawn only a select few vendors?
	int iIndexes[MAX_VENDORS+1];
	if( iCount > MAX_VENDORS )
		iCount = MAX_VENDORS;


	// Spawn saved vendors or create random
	int iRandom = g_iCvarRandom;
	if( iRandom == -1 || iRandom > iCount)
		iRandom = iCount;
	if( iRandom != -1 )
	{
		for( int i = 1; i <= iCount; i++ )
			iIndexes[i-1] = i;

		SortIntegers(iIndexes, iCount, Sort_Random);
		iCount = iRandom;
	}

	// Get the vendor origins and spawn
	char sTemp[4];
	float vPos[3], vAng[3];
	int index, iType;
	for( int i = 1; i <= iCount; i++ )
	{
		if( iRandom != -1 ) index = iIndexes[i-1];
		else index = i;

		IntToString(index, sTemp, sizeof(sTemp));

		if( hFile.JumpToKey(sTemp) )
		{
			hFile.GetVector("angle", vAng);
			hFile.GetVector("origin", vPos);
			iType = hFile.GetNum("type");

			if( vPos[0] == 0.0 && vPos[0] == 0.0 && vPos[0] == 0.0 ) // Should never happen.
				LogError("Error: 0,0,0 origin. Iteration=%d. Index=%d. Random=%d. Count=%d.", i, index, iRandom, iCount);
			else
				CreateVendor(vPos, vAng, iType, index);
			hFile.GoBack();
		}
	}

	delete hFile;
}



// ====================================================================================================
//					CREATE VENDOR
// ====================================================================================================
int GetVendorID()
{
	for( int i = 0; i < MAX_VENDORS; i++ )
		if( g_iVendors[i][0] == 0 || EntRefToEntIndex(g_iVendors[i][0]) == INVALID_ENT_REFERENCE )
			return i;
	return -1;
}

void CreateVendor(const float vOrigin[3], const float vAngles[3], int iType, int index = 0)
{
	if( g_iVendorCount >= MAX_VENDORS )
		return;

	int iVendorIndex = GetVendorID();
	if( iVendorIndex == -1 )
		return;

	if( iType < 1 || iType > 6 ) iType = GetRandomInt(1, 6);
	g_iVendors[iVendorIndex][2] = iType;
	g_iVendors[iVendorIndex][3] = 0;
	g_iVendors[iVendorIndex][4] = index;

	char sTemp[64];
	float vPos[3], vAng[3];
	vPos = vOrigin;


	// -------------------------------------------------------------------
	//	CREATE PROP_DYNAMIC
	// -------------------------------------------------------------------
	int entity = CreateEntityByName("prop_dynamic");
	if( entity == -1 )
		ThrowError("Failed to create vendor model.");

	g_iVendors[iVendorIndex][0] = EntIndexToEntRef(entity);
	switch( iType )
	{
		case TYPE_COOLER:		DispatchKeyValue(entity, "model", MODEL_COOLER);
		case TYPE_FOUNTAIN:		DispatchKeyValue(entity, "model", MODEL_FOUNTAIN);
		case TYPE_DRINKS:		DispatchKeyValue(entity, "model", MODEL_DISPENSER);
		case TYPE_VENDOR:		DispatchKeyValue(entity, "model", MODEL_VENDING);
		case TYPE_SNACKS:		DispatchKeyValue(entity, "model", MODEL_SNACKS);
		case TYPE_COFFEE:		DispatchKeyValue(entity, "model", MODEL_COFFEE);
	}

	Format(sTemp, sizeof(sTemp), "fl%d-vendor", iVendorIndex);
	DispatchKeyValue(entity, "targetname", sTemp);
	DispatchKeyValue(entity, "solid", "6");
	DispatchKeyValue(entity, "fademaxdist", "1920");
	DispatchKeyValue(entity, "fademindist", "1501");
	TeleportEntity(entity, vPos, vAngles, NULL_VECTOR);
	DispatchSpawn(entity);

	// Enable Glow
	if( g_bLeft4Dead2 && g_iCvarGlow )
	{
		SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarGlowCol);
		SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iCvarGlow);
	}

	if( iType >= TYPE_DRINKS )
	{
		int random = GetRandomInt(1, 3);
		switch( random )
		{
			case 1:		EmitSoundToAll(SOUND_VENDOR1, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, g_fCvarTimed);
			case 2:		EmitSoundToAll(SOUND_VENDOR2, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, g_fCvarTimed);
			case 3:		EmitSoundToAll(SOUND_VENDOR3, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, g_fCvarTimed);
		}
	}


	// -------------------------------------------------------------------
	//	CREATE FUNC_BUTTON
	// -------------------------------------------------------------------
	int button = CreateEntityByName("func_button_timed");
	if( button != -1 )
	{
		g_iVendors[iVendorIndex][1] = EntIndexToEntRef(button);
		DispatchKeyValue(button, "glow", sTemp);
		DispatchKeyValue(button, "rendermode", "3");
		DispatchKeyValue(button, "spawnflags", "0");
		DispatchKeyValue(button, "auto_disable", "1");
		Format(sTemp, sizeof(sTemp), "%0.1f", g_fCvarTimed);
		DispatchKeyValue(button, "use_time", sTemp);

		Format(sTemp, sizeof(sTemp), "fl%d-button_vendor", iVendorIndex);
		DispatchKeyValue(button, "targetname", sTemp);

		vAng = vAngles;
		vPos[2] += 10.0;

		switch( iType )
		{
			case TYPE_COOLER:			MoveForward(vPos, vAng, vPos, -15.0);
			case TYPE_DRINKS:			MoveForward(vPos, vAng, vPos, -25.0);
			case TYPE_FOUNTAIN:			MoveForward(vPos, vAng, vPos, -5.0);
			case TYPE_VENDOR:			MoveSideway(vPos, vAng, vPos, -15.0);
			case TYPE_SNACKS:			MoveSideway(vPos, vAng, vPos, -15.0);
			case TYPE_COFFEE:			MoveSideway(vPos, vAng, vPos, -5.0);
		}

		TeleportEntity(button, vPos, vAng, NULL_VECTOR);
		DispatchSpawn(button);
		AcceptEntityInput(button, "Enable");
		ActivateEntity(button);

		float vMins[3];
		float vMaxs[3];
		vMins = view_as<float>({-15.0, -15.0, -30.0});
		vMaxs = view_as<float>({15.0, 15.0, 30.0});
		SetEntPropVector(button, Prop_Send, "m_vecMins", vMins);
		SetEntPropVector(button, Prop_Send, "m_vecMaxs", vMaxs);
	}


	// -------------------------------------------------------------------
	//	HOOK, GIVE HEALTH
	// -------------------------------------------------------------------
	SetVariantString("OnTimeUp !self:Enable::1:-1");
	AcceptEntityInput(button, "AddOutput");
	HookSingleEntityOutput(button, "OnPressed", OnPressed);
	HookSingleEntityOutput(button, "OnUnpressed", OnUnpressed);
	HookSingleEntityOutput(button, "OnTimeUp", OnTimeUp);

	g_iVendorCount++;
}



// ====================================================================================================
//					ON PRESSED
// ====================================================================================================
public void OnPressed(const char[] output, int caller, int client, float delay)
{
	int entity = EntIndexToEntRef(caller);
	for( int i = 0; i < MAX_VENDORS; i++ )
	{
		if( entity == g_iVendors[i][1] )
		{
			int type = g_iVendors[i][2];
			if( type < TYPE_DRINKS || type == TYPE_COFFEE )
				EmitSoundToAll(SOUND_WATER, caller, SNDCHAN_AUTO, SNDLEVEL_TRAIN, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, g_fCvarTimed);
			else
			{
				int random = GetRandomInt(0, 2);
				switch( random )
				{
					case 1:			EmitSoundToAll(SOUND_DROP1, caller, SNDCHAN_AUTO, SNDLEVEL_TRAIN, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true);
					case 2:			EmitSoundToAll(SOUND_DROP2, caller, SNDCHAN_AUTO, SNDLEVEL_TRAIN, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true);
					default:		EmitSoundToAll(SOUND_DROP3, caller, SNDCHAN_AUTO, SNDLEVEL_TRAIN, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true);
				}
			}
			break;
		}
	}
}

public void OnUnpressed(const char[] output, int caller, int client, float delay)
{
	StopSound(caller, SNDCHAN_AUTO, SOUND_WATER);
}

public void OnTimeUp(const char[] output, int caller, int client, float delay)
{
	caller = EntIndexToEntRef(caller);

	int iHealth = GetClientHealth(client);
	if( iHealth >= 100 )
		return;

	for( int i = 0; i < MAX_VENDORS; i++ )
	{
		if( g_iVendors[i][1] == caller )
		{
			int entity = g_iVendors[i][0];
			int type = g_iVendors[i][2];
			bool kill;

			if( type == TYPE_COOLER && g_iCvarMaxC && g_iVendors[i][3]++ >= g_iCvarMaxC )
				kill = true;
			else if( type == TYPE_DRINKS && g_iCvarMaxD && g_iVendors[i][3]++ >= g_iCvarMaxD )
				kill = true;
			else if( type == TYPE_FOUNTAIN && g_iCvarMaxF && g_iVendors[i][3]++ >= g_iCvarMaxF )
				kill = true;
			else if( type == TYPE_VENDOR && g_iCvarMaxV && g_iVendors[i][3]++ >= g_iCvarMaxV )
				kill = true;
			else if( type == TYPE_SNACKS && g_iCvarMaxS && g_iVendors[i][3]++ >= g_iCvarMaxS )
				kill = true;
			else if( type == TYPE_COFFEE && g_iCvarMaxCo && g_iVendors[i][3]++ >= g_iCvarMaxCo )
				kill = true;
			if( kill )
			{
				AcceptEntityInput(entity, "StopGlowing");
				AcceptEntityInput(caller, "Kill");

				StopSound(entity, SNDCHAN_AUTO, SOUND_VENDOR1);
				StopSound(entity, SNDCHAN_AUTO, SOUND_VENDOR2);
				StopSound(entity, SNDCHAN_AUTO, SOUND_VENDOR3);
				StopSound(entity, SNDCHAN_AUTO, SOUND_WATER);
			}

			int iBuff;

			switch( type )
			{
				case TYPE_COOLER:		iBuff = g_iCvarHealthC;
				case TYPE_DRINKS:		iBuff = g_iCvarHealthD;
				case TYPE_FOUNTAIN:		iBuff = g_iCvarHealthF;
				case TYPE_VENDOR:		iBuff = g_iCvarHealthV;
				case TYPE_SNACKS:		iBuff = g_iCvarHealthS;
				case TYPE_COFFEE:		iBuff = g_iCvarHealthCo;
			}

			bool bTempHealth;

			if( g_iCvarTemp == -1 )
				bTempHealth = true;
			else if( g_iCvarTemp == 0 )
				bTempHealth = false;
			else if( GetRandomInt(1, 100) > g_iCvarTemp )
				bTempHealth = true;

			float fGameTime = GetGameTime();
			float fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
			float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
			fHealth -= (fGameTime - fHealthTime) * g_fDecayRate;

			if( bTempHealth )
			{
				if( fHealth < 0.0 )
					fHealth = 0.0;

				if( fHealth + iHealth + iBuff > 100 )
					SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 100.1 - float(iHealth));
				else
					SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth + iBuff);
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fGameTime);
			}
			else
			{
				iHealth += iBuff;
				if( iHealth >= 100 )
				{
					iHealth = 100;
					SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
					SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fGameTime);
				}
				else if( iHealth + fHealth >= 100 )
				{
					SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 100.1 - iHealth);
					SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fGameTime);
				}

				SetEntityHealth(client, iHealth);
			}

			VocalizeScene(client);
			break;
		}
	}
}



// ======================================================================================
//					VOCALIZE SCENE
// ======================================================================================
void VocalizeScene(int client)
{
	int iRandom;
	char sTemp[48];
	GetEntPropString(client, Prop_Data, "m_ModelName", sTemp, sizeof(sTemp));
	Format(sTemp, sizeof(sTemp), sTemp[26]); // get the model name only
	ReplaceStringEx(sTemp, sizeof(sTemp), ".mdl", "");

	bool bL4D2 = true;

	switch( sTemp[3] )
	{
		case 'c':		iRandom = GetRandomInt(1, 6);		// Coach
		case 'b':		iRandom = GetRandomInt(1, 5);		// Gambler
		case 'h':		iRandom = GetRandomInt(1, 8);		// Mechanic
		case 'd':		iRandom = GetRandomInt(1, 5);		// Producer
		case 'e':		// Biker
		{
			bL4D2 = false;
			iRandom = GetRandomInt(1, 5);
		}
		case 'a':		// Manager
		{
			bL4D2 = false;
			iRandom = GetRandomInt(1, 5);
		}
		case 'v':		// Namvet
		{
			bL4D2 = false;
			iRandom = GetRandomInt(1, 4);
		}
		case 'n':		// Teengirl
		{
			bL4D2 = false;
			iRandom = GetRandomInt(1, 5);
			if( iRandom == 3 )
				iRandom = 8;
			else if( iRandom > 3 )
				iRandom += 6;
			sTemp = "teengirl";
		}
		default: return;
	}

	if( bL4D2 )
		Format(sTemp, sizeof(sTemp), "scenes/%s/painrelieftpills%s%d.vcd", sTemp, iRandom < 10 ? "0" : "", iRandom);
	else
		Format(sTemp, sizeof(sTemp), "scenes/%s/painreliefsigh%s%d.vcd", sTemp, iRandom < 10 ? "0" : "", iRandom);

	int tempent = CreateEntityByName("instanced_scripted_scene");
	DispatchKeyValue(tempent, "SceneFile", sTemp);
	DispatchSpawn(tempent);
	SetEntPropEnt(tempent, Prop_Data, "m_hOwner", client);
	ActivateEntity(tempent);
	AcceptEntityInput(tempent, "Start", client, client);
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
//					sm_vendor
// ====================================================================================================
public Action CmdVendorTemp(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Vendor] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}
	else if( g_iVendorCount >= MAX_VENDORS )
	{
		PrintToChat(client, "%sError: Cannot add anymore vendors. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iVendorCount, MAX_VENDORS);
		return Plugin_Handled;
	}

	int iType;
	if( args == 1 )
	{
		char sBuff[4];
		GetCmdArg(1, sBuff, sizeof(sBuff));
		iType = StringToInt(sBuff);
	}

	float vPos[3], vAng[3];
	if( !SetTeleportEndPoint(client, vPos, vAng, iType) )
	{
		PrintToChat(client, "%sCannot place vendor, please try again.", CHAT_TAG);
		return Plugin_Handled;
	}

	CreateVendor(vPos, vAng, iType);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_vendorsave
// ====================================================================================================
public Action CmdVendorSave(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Vendor] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}
	else if( g_iVendorCount >= MAX_VENDORS )
	{
		PrintToChat(client, "%sError: Cannot add anymore vendors. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iVendorCount, MAX_VENDORS);
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		File hCfg = OpenFile(sPath, "w");
		hCfg.WriteLine("");
		delete hCfg;
	}

	// Load config
	KeyValues hFile = new KeyValues("vendors");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot read the vendor config, assuming empty file. (\x05%s\x01).", CHAT_TAG, sPath);
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if( !hFile.JumpToKey(sMap, true) )
	{
		PrintToChat(client, "%sError: Failed to add map to vendor spawn config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many vendors are saved
	int iCount = hFile.GetNum("num", 0);
	if( iCount >= MAX_VENDORS )
	{
		PrintToChat(client, "%sError: Cannot add anymore vendors. Used: (\x05%d/%d\x01).", CHAT_TAG, iCount, MAX_VENDORS);
		delete hFile;
		return Plugin_Handled;
	}

	// Save count
	iCount++;
	hFile.SetNum("num", iCount);

	int iType;
	char sTemp[4], sBuff[4];

	IntToString(iCount, sTemp, sizeof(sTemp));
	if( hFile.JumpToKey(sTemp, true) )
	{
		if( args == 1 )
		{
			GetCmdArg(1, sBuff, 4);
			iType = StringToInt(sBuff);
			if( iType < 1 || iType > 6 )
				iType = GetRandomInt(1, 6);
			hFile.SetNum("type", iType);
		}
		else
		{
			iType = GetRandomInt(1, 6);
			hFile.SetNum("type", iType);
		}

		// Set player position as vendor spawn location
		float vPos[3], vAng[3];
		if( !SetTeleportEndPoint(client, vPos, vAng, iType) )
		{
			PrintToChat(client, "%sCannot place vendor, please try again.", CHAT_TAG);
			delete hFile;
			return Plugin_Handled;
		}

		// Save angle / origin
		hFile.SetVector("angle", vAng);
		hFile.SetVector("origin", vPos);

		CreateVendor(vPos, vAng, iType, iCount);

		// Save cfg
		hFile.Rewind();
		hFile.ExportToFile(sPath);

		PrintToChat(client, "%s(\x05%d/%d\x01) - Saved at pos:[\x05%f %f %f\x01] ang:[\x05%f %f %f\x01]", CHAT_TAG, iCount, MAX_VENDORS, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to save Vendor.", CHAT_TAG, iCount, MAX_VENDORS);

	delete hFile;
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_vendordel
// ====================================================================================================
public Action CmdVendorDelete(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Vendor] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	int entity = GetClientAimTarget(client, false);
	if( entity == -1 ) return Plugin_Handled;
	entity = EntIndexToEntRef(entity);

	int cfgindex, index = -1;
	for( int i = 0; i < MAX_VENDORS; i++ )
	{
		if( g_iVendors[i][0] == entity )
		{
			index = i;
			break;
		}
	}

	if( index == -1 )
		return Plugin_Handled;

	cfgindex = g_iVendors[index][4];
	if( cfgindex == 0 )
	{
		RemoveVendor(index);
		return Plugin_Handled;
	}

	for( int i = 0; i < MAX_VENDORS; i++ )
	{
		if( g_iVendors[i][4] > cfgindex )
			g_iVendors[i][4]--;
	}

	g_iVendorCount--;

	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the vendor config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	KeyValues hFile = new KeyValues("vendors");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the vendor config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the vendor config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many vendors
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return Plugin_Handled;
	}

	bool bMove;
	char sTemp[4];

	// Move the other entries down
	for( int i = cfgindex; i <= iCount; i++ )
	{
		IntToString(i, sTemp, sizeof(sTemp));
		if( hFile.JumpToKey(sTemp) )
		{
			if( !bMove )
			{
				bMove = true;
				hFile.DeleteThis();
				RemoveVendor(index);
			}
			else
			{
				IntToString(i-1, sTemp, sizeof(sTemp));
				hFile.SetSectionName(sTemp);
			}
		}

		hFile.Rewind();
		hFile.JumpToKey(sMap);
	}

	if( bMove )
	{
		iCount--;
		hFile.SetNum("num", iCount);

		// Save to file
		hFile.Rewind();
		hFile.ExportToFile(sPath);

		PrintToChat(client, "%s(\x05%d/%d\x01) - Vendor removed from config.", CHAT_TAG, iCount, MAX_VENDORS);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to remove Vendor from config.", CHAT_TAG, iCount, MAX_VENDORS);

	delete hFile;
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_vendorwipe
// ====================================================================================================
public Action CmdVendorWipe(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Vendor] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the vendor config (\x05%s\x01).", CHAT_TAG, sPath);
		return Plugin_Handled;
	}

	// Load config
	KeyValues hFile = new KeyValues("vendors");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the vendor config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap, false) )
	{
		PrintToChat(client, "%sError: Current map not in the vendor config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	hFile.DeleteThis();
	ResetPlugin();

	// Save to file
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	PrintToChat(client, "%s(0/%d) - All vending machines removed from config, add with \x05sm_vendorsave\x01.", CHAT_TAG, MAX_VENDORS);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_vendorglow / sm_vendorlist
// ====================================================================================================
public Action CmdVendorGlow(int client, int args)
{
	g_bGlow = !g_bGlow;
	PrintToChat(client, "%sGlow has been turned %s", CHAT_TAG, g_bGlow ? "on" : "off");

	VendorGlow(g_bGlow);
	return Plugin_Handled;
}

void VendorGlow(int glow)
{
	int entity;

	for( int i = 0; i < MAX_VENDORS; i++ )
	{
		entity = g_iVendors[i][0];
		if( IsValidEntRef(entity) )
		{
			SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
			SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarGlowCol);
			SetEntProp(entity, Prop_Send, "m_nGlowRange", glow ? 0 : g_iCvarGlow);
			if( glow )
				AcceptEntityInput(entity, "StartGlowing");
			else if( !glow && !g_iCvarGlow )
				AcceptEntityInput(entity, "StopGlowing");
		}
	}
}

public Action CmdVendorList(int client, int args)
{
	float vPos[3];
	int count;
	for( int i = 0; i < MAX_VENDORS; i++ )
	{
		if( IsValidEntRef(g_iVendors[i][0]) )
		{
			count++;
			GetEntPropVector(g_iVendors[i][0], Prop_Data, "m_vecOrigin", vPos);
			PrintToChat(client, "%s%d) %f %f %f", CHAT_TAG, i+1, vPos[0], vPos[1], vPos[2]);
		}
	}
	PrintToChat(client, "%sTotal: %d.", CHAT_TAG, count);
	return Plugin_Handled;
}

// ====================================================================================================
//					MENU ANGLE
// ====================================================================================================
public Action CmdVendorAng(int client, int args)
{
	ShowMenuAng(client);
	return Plugin_Handled;
}

void ShowMenuAng(int client)
{
	CreateMenus();
	g_hMenuAng.Display(client, MENU_TIME_FOREVER);
}

public int AngMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Select )
	{
		if( index == 6 )
			SaveData(client);
		else
			SetAngle(client, index);
		ShowMenuAng(client);
	}
}

void SetAngle(int client, int index)
{
	int aim = GetClientAimTarget(client, false);
	if( aim != -1 )
	{
		float vAng[3];
		int entity;
		aim = EntIndexToEntRef(aim);

		for( int i = 0; i < MAX_VENDORS; i++ )
		{
			entity = g_iVendors[i][0];

			if( entity == aim  )
			{
				GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

				switch( index )
				{
					case 0: vAng[0] += 5.0;
					case 1: vAng[1] += 5.0;
					case 2: vAng[2] += 5.0;
					case 3: vAng[0] -= 5.0;
					case 4: vAng[1] -= 5.0;
					case 5: vAng[2] -= 5.0;
				}

				TeleportEntity(entity, NULL_VECTOR, vAng, NULL_VECTOR);

				PrintToChat(client, "%sNew angles: %f %f %f", CHAT_TAG, vAng[0], vAng[1], vAng[2]);
				break;
			}
		}
	}
}

// ====================================================================================================
//					MENU ORIGIN
// ====================================================================================================
public Action CmdVendorPos(int client, int args)
{
	ShowMenuPos(client);
	return Plugin_Handled;
}

void ShowMenuPos(int client)
{
	CreateMenus();
	g_hMenuPos.Display(client, MENU_TIME_FOREVER);
}

public int PosMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Select )
	{
		if( index == 6 )
			SaveData(client);
		else
			SetOrigin(client, index);
		ShowMenuPos(client);
	}
}

void SetOrigin(int client, int index)
{
	int aim = GetClientAimTarget(client, false);
	if( aim != -1 )
	{
		float vPos[3];
		int entity;
		aim = EntIndexToEntRef(aim);

		for( int i = 0; i < MAX_VENDORS; i++ )
		{
			entity = g_iVendors[i][0];

			if( entity == aim  )
			{
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

				switch( index )
				{
					case 0: vPos[0] += 0.5;
					case 1: vPos[1] += 0.5;
					case 2: vPos[2] += 0.5;
					case 3: vPos[0] -= 0.5;
					case 4: vPos[1] -= 0.5;
					case 5: vPos[2] -= 0.5;
				}

				TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

				PrintToChat(client, "%sNew origin: %f %f %f", CHAT_TAG, vPos[0], vPos[1], vPos[2]);
				break;
			}
		}
	}
}

void SaveData(int client)
{
	int entity, index;
	int aim = GetClientAimTarget(client, false);
	if( aim == -1 )
		return;

	aim = EntIndexToEntRef(aim);

	for( int i = 0; i < MAX_VENDORS; i++ )
	{
		entity = g_iVendors[i][0];

		if( entity == aim  )
		{
			index = g_iVendors[i][4];
			break;
		}
	}

	if( index == 0 )
		return;

	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the vendor config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return;
	}

	KeyValues hFile = new KeyValues("vendors");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the vendor config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the vendor config.", CHAT_TAG);
		delete hFile;
		return;
	}

	float vAng[3], vPos[3];
	char sTemp[4];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

	IntToString(index, sTemp, sizeof(sTemp));
	if( hFile.JumpToKey(sTemp) )
	{
		hFile.SetVector("angle", vAng);
		hFile.SetVector("origin", vPos);

		// Save cfg
		hFile.Rewind();
		hFile.ExportToFile(sPath);

		PrintToChat(client, "%sSaved origin and angles to the data config", CHAT_TAG);
	}
}

void CreateMenus()
{
	if( g_hMenuAng == null )
	{
		g_hMenuAng = new Menu(AngMenuHandler);
		g_hMenuAng.AddItem("", "X + 5.0");
		g_hMenuAng.AddItem("", "Y + 5.0");
		g_hMenuAng.AddItem("", "Z + 5.0");
		g_hMenuAng.AddItem("", "X - 5.0");
		g_hMenuAng.AddItem("", "Y - 5.0");
		g_hMenuAng.AddItem("", "Z - 5.0");
		g_hMenuAng.AddItem("", "SAVE");
		g_hMenuAng.SetTitle("Set Angle");
		g_hMenuAng.ExitButton = true;
	}

	if( g_hMenuPos == null )
	{
		g_hMenuPos = new Menu(PosMenuHandler);
		g_hMenuPos.AddItem("", "X + 0.5");
		g_hMenuPos.AddItem("", "Y + 0.5");
		g_hMenuPos.AddItem("", "Z + 0.5");
		g_hMenuPos.AddItem("", "X - 0.5");
		g_hMenuPos.AddItem("", "Y - 0.5");
		g_hMenuPos.AddItem("", "Z - 0.5");
		g_hMenuPos.AddItem("", "SAVE");
		g_hMenuPos.SetTitle("Set Position");
		g_hMenuPos.ExitButton = true;
	}
}



// ====================================================================================================
//					STUFF
// ====================================================================================================
bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

void ResetPlugin()
{
	g_bGlow = false;
	g_bLoaded = false;
	g_iVendorCount = 0;

	for( int i = 0; i < MAX_VENDORS; i++ )
		RemoveVendor(i);
}

void RemoveVendor(int index)
{
	int i, entity;
	for( i = 0; i < 2; i++ )
	{
		entity = g_iVendors[index][i];
		g_iVendors[index][i] = 0;

		StopSound(entity, SNDCHAN_AUTO, SOUND_VENDOR1);
		StopSound(entity, SNDCHAN_AUTO, SOUND_VENDOR2);
		StopSound(entity, SNDCHAN_AUTO, SOUND_VENDOR3);
		StopSound(entity, SNDCHAN_AUTO, SOUND_WATER);

		if( IsValidEntRef(entity) )
			AcceptEntityInput(entity, "kill");
	}

	g_iVendors[i][2] = 0;
}



// ====================================================================================================
//					POSITION
// ====================================================================================================
void MoveForward(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance)
{
	fDistance *= -1.0;
	float vDir[3];
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
}

stock void MoveSideway(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance)
{
	fDistance *= -1.0;
	float vDir[3];
	GetAngleVectors(vAng, NULL_VECTOR, vDir, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
}

bool SetTeleportEndPoint(int client, float vPos[3], float vAng[3], int iType)
{
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, _TraceFilter);

	if( TR_DidHit(trace) )
	{
		float vNorm[3];
		TR_GetEndPosition(vPos, trace);
		TR_GetPlaneNormal(trace, vNorm);
		GetVectorAngles(vNorm, vAng);
		if( vNorm[2] == 1.0 )
		{
			vAng[0] = 0.0;
			vAng[1] = 180.0;
		}
		else
		{
			switch( iType )
			{
				case TYPE_COOLER:			MoveForward(vPos, vAng, vPos, -10.0);
				case TYPE_DRINKS:			MoveForward(vPos, vAng, vPos, -15.0);
				case TYPE_FOUNTAIN:			vPos[2] -= 5.0;
				case TYPE_VENDOR:
				{
					vAng[1] += 90.0;
					MoveSideway(vPos, vAng, vPos, -35.0);
				}
				case TYPE_SNACKS:			MoveForward(vPos, vAng, vPos, -20.0);
				case TYPE_COFFEE:			MoveForward(vPos, vAng, vPos, -10.0);
			}
		}
	}
	else
	{
		delete trace;
		return false;
	}

	delete trace;
	return true;
}

public bool _TraceFilter(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}