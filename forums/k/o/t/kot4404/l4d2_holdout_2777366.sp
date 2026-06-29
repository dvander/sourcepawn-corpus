/*
*	Survivor Bot Holdout
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



#define PLUGIN_VERSION 		"1.8"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Survivor Bot Holdout
*	Author	:	SilverShot
*	Descrp	:	Create up to 8 bots (Bill, Francis, Louis, Zoey, Nick, Rochelle, Coach, Ellis) to holdout their surrounding area, c6m3_port style.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=188966
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.8 (21-Sep-2021)
	- Now spawns L4D2 Survivors as holdout Survivors!
	- L4D2 Survivors may use some new voice lines when throwing items.
	- Changed from using hard coded offsets for weapon ammo. Thanks to "Root" for the method.
	- Replaced input "Kill" with "RemoveEntity". Now requires SourceMod 1.10 or newer.

1.7 (10-Oct-2020)
	- Added plugin enabled check when using commands to prevent usage if turned off.
	- Automatically detects and blocks the plugin running on maps which spawn their own L4D1 holdout survivors.
	- Changed character number for Louis. Has no affect. Thanks to "Crasher_3637" for reporting.
	- Fixed round restart resetting the blocked map bool.

1.6 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.
	- Various optimizations and fixes.

1.5 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.4.2 (03-Jul-2019)
	- Minor changes to code, has no affect and not required.

1.4.1 (28-Jun-2019)
	- Removed VScript file, directly executes the VScript code instead.

1.4 (03-Jun-2019)
	- Fixed conflicts with playable survivors, holdout survivors should now spawn correctly.
	- Changed cvar "l4d2_holdout_freeze" removed option 2 - memory patching method.
	- Removed cvar "l4d2_holdout_prevent". No longer required thanks to the latest fixes.
	- Removed gamedata dependency.

1.3 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.

1.2.2 (29-Apr-2017)
	- Fixed server crash on certain maps.

1.2.1 (04-Dec-2016)
	- Renamed some variables because of SourceMod updating reserved keywords.

1.2 (11-Jul-2013)
	- Added Bill to spawn list!
	- Updated gamedata txt file.

1.1 (07-Oct-2012)
	- Added cvar "l4d2_holdout_pile" to create ammo piles next to survivors with primary weapons.
	- Added cvar "l4d2_holdout_freeze" to optionally freeze bots in their place.
	- Changed the freeze method to memory patching, which prevents dust under the bots feet.
	- Requires the added gamedata "l4d2_holdout.txt" for memory patching.

1.0 (02-Jul-2012)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define	CONFIG_SPAWNS		"data/l4d2_holdout.cfg"
#define CHAT_TAG			"\x05[SurvivorHoldout] \x01"
#define	MAX_SURVIVORS		8

#define MODEL_MINIGUN		"models/w_models/weapons/w_minigun.mdl"
#define MODEL_FRANCIS		"models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS			"models/survivors/survivor_manager.mdl"
#define MODEL_ZOEY			"models/survivors/survivor_teenangst.mdl"
#define MODEL_BILL			"models/survivors/survivor_namvet.mdl"
#define MODEL_NICK 			"models/survivors/survivor_gambler.mdl"
#define MODEL_ROCHELLE		"models/survivors/survivor_producer.mdl"
#define MODEL_COACH			"models/survivors/survivor_coach.mdl"
#define MODEL_ELLIS			"models/survivors/survivor_mechanic.mdl"

ConVar g_hCvarAllow, g_hCvarFreeze, g_hCvarLasers, g_hCvarMPGameMode, g_hCvarMiniGun, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarPile, g_hCvarThrow, g_hCvarTimeMax, g_hCvarTimeMin;
int g_iAmmoPile[MAX_SURVIVORS], g_iCvarFreeze, g_iCvarLasers, g_iCvarMiniGun, g_iCvarPile, g_iCvarThrow, g_iCvarTimeMax, g_iCvarTimeMin, g_iDeathModel[MAXPLAYERS+1], g_iLogicTimer, g_iMiniGun, g_iOffsetAmmo, g_iPrimaryAmmoType, g_iPlayerSpawn, g_iRoundStart, g_iSurvivors[MAX_SURVIVORS], g_iType, g_iWeapons[MAX_SURVIVORS];
bool g_bCvarAllow, g_bMapStarted, g_bLoaded;
bool g_bBlocked;

char g_sWeaponNames[15][23] = {"autoshotgun","shotgun_chrome","pumpshotgun","shotgun_spas","smg","smg_mp5","smg_silenced","rifle_ak47","rifle_sg552","rifle","rifle_desert","hunting_rifle","sniper_military","sniper_awp","sniper_scout"};

char g_sLines_Nick[17][] =
{
	"AlertGiveItem01",			// It is more blessed to give than to receive.
	"AlertGiveItem02",			// Have this.
	"AlertGiveItem03",			// Just take this.
	"AlertGiveItem04",			// This is for you.
	"AlertGiveItem05",			// Here, I don't need this.
	"AlertGiveItem06",			// Take it, just take it.
	"AlertGiveItemC101",		// Hey you, take this.
	"AlertGiveItemC102",		// What's your name, here you go.
	"AlertGiveItemCombat01",	// Take this.
	"AlertGiveItemCombat02",	// Grab this.
	"AlertGiveItemCombat03",	// Take it.
	"AlertGiveItemStop01",		// Stop, I have something for you.
	"AlertGiveItemStop02",		// Hang on, you need this more than me.
	"AlertGiveItemStop03",		// Hold up, you can have this.
	"AlertGiveItemStop04",		// Hold up, you can have this.
	"AlertGiveItemStop05",		// Hang on, you need this more than me.
	"AlertGiveItemStop06"		// Stop, I have something for you.
};

char g_sLines_Rochelle[16][] =
{
	"AlertGiveItem01",			// You can have this.
	"AlertGiveItem02",			// Got this just for you.
	"AlertGiveItem03",			// Here, you can have this.
	"AlertGiveItem04",			// A little something for you.
	"AlertGiveItem05",			// I picked this up just for you.
	"AlertGiveItemC101",		// You're gonna need this.
	"AlertGiveItemCombat01",	// Here!
	"AlertGiveItemCombat02",	// Take this!
	"AlertGiveItemCombat03",	// Have this!
	"AlertGiveItemCombat04",	// Here, use this.
	"AlertGiveItemCombat05",	// You need this, take this!
	"AlertGiveItemCombat06",	// Here, I'm giving this to you.
	"AlertGiveItemStop01",		// Wait, I have something for you.
	"AlertGiveItemStop02",		// STOP, take this.
	"AlertGiveItemStop03",		// Can you stop for a sec? I got something for you.
	"AlertGiveItemStopC101"		// Hey! Hey, uh, you!  I got something for you.
};

char g_sLines_Coach[18][] =
{
	"AlertGiveItem01",			// Take it. Hell, I don't need it.
	"AlertGiveItem02",			// You make sure you use this now.
	"AlertGiveItem03",			// Ain't no shame in gettin' some help.
	"AlertGiveItem04",			// Take this.
	"AlertGiveItem05",			// Here ya go.
	"AlertGiveItemC101",		// You can have this.
	"AlertGiveItemC102",		// Excuse me, here ya go.
	"AlertGiveItemC103",		// Hey, you can have this.
	"AlertGiveItemCombat01",	// Take it.
	"AlertGiveItemCombat02",	// Here.
	"AlertGiveItemCombat03",	// Have it.
	"AlertGiveItemCombat04",	// Take it.
	"AlertGiveItemCombat05",	// Here.
	"AlertGiveItemStop01",		// Hold on, I got something for you.
	"AlertGiveItemStop02",		// Hold up now, I got something for you.
	"AlertGiveItemStop03",		// Hold up, I got something for you.
	"AlertGiveItemStopC101",	// Yo! I got somethin' for ya.
	"AlertGiveItemStopC102"		// Hey! Hey! Hold up.
};

char g_sLines_Ellis[20][] =
{
	"AlertGiveItem01",			// I got this for ya, man.
	"AlertGiveItem02",			// I want you to have this.
	"AlertGiveItem03",			// Here ya go, I got this for ya.
	"AlertGiveItem04",			// Here ya go, man.
	"AlertGiveItem05",			// Here ya go, man, I want ya to have this.
	"AlertGiveItem06",			// You can have this.
	"AlertGiveItem07",			// Hey, I want you to have this.
	"AlertGiveItem08",			// Hold on now, hold on now, here ya go.
	"AlertGiveItemCombat01",	// Take this!
	"AlertGiveItemCombat02",	// Just take this!
	"AlertGiveItemCombat03",	// Here!, here!
	"AlertGiveItemCombat04",	// Grab this here!
	"AlertGiveItemStop01",		// Wait up, now! I got somethin' for ya.
	"AlertGiveItemStop02",		// Hey! Hey! Got something for ya.
	"AlertGiveItemStop03",		// Hey, stop movin', now! I got somethin' for you right here.
	"AlertGiveItemStop04",		// Wait up! I got somethin' for ya.
	"AlertGiveItemStop05",		// Hey! Hey! Got something for ya.
	"AlertGiveItemStop06",		// Hey, stop movin' I got somethin' for ya
	"AlertGiveItemStopC101",	// Dude, dude, hold up.
	"AlertGiveItemStopC102"		// Hey umm...  you! Hold up!
};



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Survivor Bot Holdout",
	author = "SilverShot",
	description = "Create up to 8 bots (Bill, Francis, Louis, Zoey, Nick, Rochelle, Coach, Ellis) to holdout their surrounding area, c6m3_port style.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=188966"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegAdminCmd("sm_holdout",		CmdHoldoutSave,		ADMFLAG_ROOT,	"Saves to the config for auto spawning or Deletes if already saved. Usage: sm_holdout <1=Francis, 2=Louis, 3=Zoey, 4=Bill, 5=Nick, 6=Rochelle, 7=Coach, 8=Ellis> [weapon name, eg: rifle_ak47].");
	RegAdminCmd("sm_holdout_temp",	CmdHoldoutTemp,		ADMFLAG_ROOT,	"Spawn a temporary survivor (not saved). Usage: sm_holdout_temp <1=Francis, 2=Louis, 3=Zoey, 4=Bill, 5=Nick, 6=Rochelle, 7=Coach, 8=Ellis> [weapon name, eg: rifle_ak47].");
	RegAdminCmd("sm_holdout_give",	CmdHoldoutGive,		ADMFLAG_ROOT,	"Makes one of the survivors give an item.");

	g_hCvarAllow = CreateConVar(	"l4d2_holdout_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes = CreateConVar(	"l4d2_holdout_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(	"l4d2_holdout_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(	"l4d2_holdout_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarFreeze = CreateConVar(	"l4d2_holdout_freeze",			"1",			"0=Allow bots to move and take items. 1=Prevent bots from moving.", CVAR_FLAGS );
	g_hCvarLasers = CreateConVar(	"l4d2_holdout_lasers",			"1",			"0=No. 1=Give the survivors laser sights.", CVAR_FLAGS );
	g_hCvarMiniGun = CreateConVar(	"l4d2_holdout_minigun",			"75",			"0=No. The chance out of 100 for Louis to get a minigun.", CVAR_FLAGS );
	g_hCvarPile = CreateConVar(		"l4d2_holdout_pile",			"1",			"0=Off, 1=Spawn an ammo pile next to a survivor when spawning them.", CVAR_FLAGS );
	g_hCvarThrow = CreateConVar(	"l4d2_holdout_throw",			"-1",			"0=Off, -1=Infinite. How many items can survivors throw in total.", CVAR_FLAGS );
	g_hCvarTimeMax = CreateConVar(	"l4d2_holdout_time_max",		"90",			"0=Off. Maximum time before allowing the survivors to give an item.", CVAR_FLAGS );
	g_hCvarTimeMin = CreateConVar(	"l4d2_holdout_time_min",		"45",			"0=Off. Minimum time before allowing the survivors to give an item.", CVAR_FLAGS );
	CreateConVar(					"l4d2_holdout_version",		PLUGIN_VERSION,		"Survivor Bot Holdout plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"l4d2_holdout");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarFreeze.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarLasers.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMiniGun.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPile.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarThrow.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTimeMax.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTimeMin.AddChangeHook(ConVarChanged_Cvars);

	g_iOffsetAmmo = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
	g_iPrimaryAmmoType = FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType");
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public void OnMapStart()
{
	g_bMapStarted = true;

	// Models
	PrecacheModel(MODEL_MINIGUN);
	PrecacheModel(MODEL_FRANCIS);
	PrecacheModel(MODEL_LOUIS);
	PrecacheModel(MODEL_ZOEY);
	PrecacheModel(MODEL_BILL);
	PrecacheModel(MODEL_NICK);
	PrecacheModel(MODEL_ROCHELLE);
	PrecacheModel(MODEL_COACH);
	PrecacheModel(MODEL_ELLIS);

	// Sounds
	char sTemp[64];
	for( int i = 0; i < sizeof(g_sLines_Nick); i++ )
	{
		Format(sTemp, sizeof(sTemp), "player/survivor/voice/gambler/%s.wav", g_sLines_Nick[GetRandomInt(0, sizeof(g_sLines_Nick) - 1)]);
	}

	for( int i = 0; i < sizeof(g_sLines_Rochelle); i++ )
	{
		Format(sTemp, sizeof(sTemp), "player/survivor/voice/producer/%s.wav", g_sLines_Rochelle[GetRandomInt(0, sizeof(g_sLines_Rochelle) - 1)]);
	}

	for( int i = 0; i < sizeof(g_sLines_Coach); i++ )
	{
		Format(sTemp, sizeof(sTemp), "player/survivor/voice/coach/%s.wav", g_sLines_Coach[GetRandomInt(0, sizeof(g_sLines_Coach) - 1)]);
	}

	for( int i = 0; i < sizeof(g_sLines_Ellis); i++ )
	{
		Format(sTemp, sizeof(sTemp), "player/survivor/voice/mechanic/%s.wav", g_sLines_Ellis[GetRandomInt(0, sizeof(g_sLines_Ellis) - 1)]);
	}

	// Blocked maps
	char sMap[16];
	GetCurrentMap(sMap, sizeof(sMap));
	if( strcmp(sMap, "c6m1_riverbank") == 0 || strcmp(sMap, "c6m3_port") == 0 )
		g_bBlocked = true;
	else
		g_bBlocked = FindEntityByClassname(-1, "info_l4d1_survivor_spawn") != -1;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin();
}

void ResetPlugin()
{
	g_bLoaded = false;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;

	if( IsValidEntRef(g_iLogicTimer) )
		RemoveEntity(g_iLogicTimer);

	if( IsValidEntRef(g_iMiniGun) )
		RemoveEntity(g_iMiniGun);

	int client, entity;
	for( int i = 0; i < MAX_SURVIVORS; i++ )
	{
		entity = g_iWeapons[i];
		g_iWeapons[i] = 0;
		if( IsValidEntRef(entity) )
			RemoveEntity(entity);

		entity = g_iAmmoPile[i];
		g_iAmmoPile[i] = 0;
		if( IsValidEntRef(entity) )
			RemoveEntity(entity);

		client = g_iSurvivors[i];
		g_iSurvivors[i] = 0;
		if( client != 0 && (client = GetClientOfUserId(client)) != 0 )
		{
			if( IsFakeClient(client) )
			{
				RemoveWeapons(client, i+1);
				KickClient(client, "SurvivorHoldout::KickClientA");
			}
			else
			{
				LogError("SurvivorHoldout::A::Prevented kicking %d) %N, why are they using my bot?", client, client);
			}
		}
	}
}

void RemoveWeapons(int client, int type)
{
	if( type == 2 && IsValidEntRef(g_iMiniGun))
	{
		RemoveEntity(g_iMiniGun);
		g_iMiniGun = 0;
	}

	type--;

	if( IsValidEntRef(g_iWeapons[type]) )
		RemoveEntity(g_iWeapons[type]);
	g_iWeapons[type] = 0;

	if( IsValidEntRef(g_iAmmoPile[type]) )
		RemoveEntity(g_iAmmoPile[type]);
	g_iAmmoPile[type] = 0;

	int entity;
	for( int i = 0; i < 5; i++ )
	{
		entity = GetPlayerWeaponSlot(client, 0);
		if( entity != -1 )
		{
			RemovePlayerItem(client, entity);
			RemoveEntity(entity);
		}
	}
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

void GetCvars()
{
	g_iCvarFreeze = g_hCvarFreeze.IntValue;
	g_iCvarLasers = g_hCvarLasers.IntValue;
	g_iCvarMiniGun = g_hCvarMiniGun.IntValue;
	g_iCvarPile = g_hCvarPile.IntValue;
	g_iCvarThrow = g_hCvarThrow.IntValue;
	g_iCvarTimeMax = g_hCvarTimeMax.IntValue;
	g_iCvarTimeMin = g_hCvarTimeMin.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
		HookEvent("round_start",	Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("player_spawn",	Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		HookEvent("player_death",	Event_PlayerDeath,	EventHookMode_Pre);
		HookEvent("weapon_drop",	Event_WeaponDrop,	EventHookMode_Pre);

		char sMap[16];
		GetCurrentMap(sMap, sizeof(sMap));
		if( strcmp(sMap, "c6m1_riverbank") == 0 || strcmp(sMap, "c6m3_port") == 0 )
			g_bBlocked = true;
		else
			CreateTimer(0.5, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		UnhookEvent("round_end",	Event_RoundEnd,		EventHookMode_PostNoCopy);
		UnhookEvent("round_start",	Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("player_spawn",	Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		UnhookEvent("player_death",	Event_PlayerDeath,	EventHookMode_Pre);
		UnhookEvent("weapon_drop",	Event_WeaponDrop,	EventHookMode_Pre);
		ResetPlugin();
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
//					EVENTS - GIVE ITEM
// ====================================================================================================
public void Event_WeaponDrop(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if( client )
	{
		for( int i = 0; i < MAX_SURVIVORS; i++ )
		{
			if( g_iSurvivors[i] == userid )
			{
				static char sTemp[64];

				int character = GetEntProp(client, Prop_Send, "m_survivorCharacter");
				switch( character )
				{
					case 0:		// Nick
					{
						// Sound
						int random = GetRandomInt(0, sizeof(g_sLines_Nick) - 1);

						Format(sTemp, sizeof(sTemp), "player/survivor/voice/gambler/%s.wav", g_sLines_Nick[random]);
						PlaySound(client, sTemp);

						// Captions - (no sound plays from L4D2 Holdout Survivors) - They also don't move their mouth
						Format(sTemp, sizeof(sTemp), "scenes/gambler/%s.vcd", g_sLines_Nick[random]);
						VocalizeScene(client, sTemp);
					}
					case 1:		// Rochelle
					{
						int random = GetRandomInt(0, sizeof(g_sLines_Rochelle) - 1);

						Format(sTemp, sizeof(sTemp), "player/survivor/voice/producer/%s.wav", g_sLines_Rochelle[random]);
						PlaySound(client, sTemp);

						Format(sTemp, sizeof(sTemp), "scenes/producer/%s.vcd", g_sLines_Rochelle[random]);
						VocalizeScene(client, sTemp);
					}
					case 2:		// Coach
					{
						int random = GetRandomInt(0, sizeof(g_sLines_Coach) - 1);

						Format(sTemp, sizeof(sTemp), "player/survivor/voice/coach/%s.wav", g_sLines_Coach[random]);
						PlaySound(client, sTemp);

						Format(sTemp, sizeof(sTemp), "scenes/coach/%s.vcd", g_sLines_Coach[random]);
						VocalizeScene(client, sTemp);
					}
					case 3:		// Ellis
					{
						int random = GetRandomInt(0, sizeof(g_sLines_Ellis) - 1);

						Format(sTemp, sizeof(sTemp), "player/survivor/voice/mechanic/%s.wav", g_sLines_Ellis[random]);
						PlaySound(client, sTemp);

						Format(sTemp, sizeof(sTemp), "scenes/mechanic/%s.vcd", g_sLines_Ellis[random]);
						VocalizeScene(client, sTemp);
					}
				}

				break;
			}
		}
	}
}



// ====================================================================================================
//					EVENTS - DEATH
// ====================================================================================================
// I guess this was written to prevent death models from Holdout bots when slayed.
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if( g_bBlocked == true )
		return;

	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);

	if( client && IsFakeClient(client) )
	{
		int entref, entity = -1;
		while( (entity = FindEntityByClassname(entity, "survivor_death_model")) != INVALID_ENT_REFERENCE )
		{
			entref = EntIndexToEntRef(entity);

			for( int i = 1; i <= MaxClients; i++ )
			{
				if( g_iDeathModel[i] == entref )
				{
					break;
				}
				else if( i == MaxClients )
				{
					g_iDeathModel[client] = entref;
				}
			}
		}

		for( int i = 0; i < MAX_SURVIVORS; i++ )
		{
			if( g_iSurvivors[i] == userid )
			{
				RemoveWeapons(client, i+1);

				if( IsValidEntRef(g_iDeathModel[client]) )
				{
					RemoveEntity(g_iDeathModel[client]);
					g_iDeathModel[client] = 0;
				}
				KickClient(client, "SurvivorHoldout::KickClientD");
			}
		}
	}
}



// ====================================================================================================
//					EVENTS - LOAD
// ====================================================================================================
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

public Action TimerStart(Handle timer)
{
	ResetPlugin();
	LoadSurvivors();
	return Plugin_Continue;
}

void LoadSurvivors()
{
	if( g_bBlocked || g_bLoaded ) return;
	g_bLoaded = true;

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		return;

	KeyValues hFile = new KeyValues("holdout");
	if( !hFile.ImportFromFile(sPath) )
	{
		delete hFile;
		return;
	}

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		delete hFile;
		return;
	}

	char sTemp[64];
	float vPos[3];
	float vAng[3];
	int spawned;

	for( int i = 1; i <= 8; i++ )
	{
		IntToString(i, sTemp, sizeof(sTemp));

		if( hFile.JumpToKey(sTemp) )
		{
			vAng[1] = hFile.GetFloat("ang");
			hFile.GetVector("pos", vPos);
			hFile.GetString("wep", sTemp, sizeof(sTemp));
			SpawnSurvivor(i, vPos, vAng, sTemp);
			hFile.GoBack();
			spawned++;
		}
	}



	if( spawned && g_iCvarThrow && g_iCvarTimeMin && g_iCvarTimeMax )
	{
		g_iLogicTimer = CreateEntityByName("logic_timer");
		DispatchKeyValue(g_iLogicTimer, "spawnflags", "0");
		DispatchKeyValue(g_iLogicTimer, "StartDisabled", "0");
		DispatchKeyValue(g_iLogicTimer, "UseRandomTime", "1");

		IntToString(g_iCvarTimeMin, sTemp, sizeof(sTemp));
		DispatchKeyValue(g_iLogicTimer, "LowerRandomBound", sTemp);
		IntToString(g_iCvarTimeMax, sTemp, sizeof(sTemp));
		DispatchKeyValue(g_iLogicTimer, "UpperRandomBound", sTemp);

		DispatchSpawn(g_iLogicTimer);
		ActivateEntity(g_iLogicTimer);

		HookSingleEntityOutput(g_iLogicTimer, "OnTimer", OnTimer, false);
	}

	delete hFile;
}

public void OnTimer(const char[] output, int caller, int activator, float delay)
{
	int total = GetEntProp(caller, Prop_Data, "m_iHammerID");
	if( g_iCvarThrow != -1 && total >= g_iCvarThrow )
		return;
	SetEntProp(caller, Prop_Data, "m_iHammerID", total + 1);

	total = 0;
	int client;
	for( int i = 0; i < MAX_SURVIVORS; i++ )
	{
		client = g_iSurvivors[i];
		if( client != 0 && (client = GetClientOfUserId(client)) != 0 )
			total++;
		else
			g_iSurvivors[i] = 0;
	}

	if( total == 0 )
	{
		return;
	}

	float vPos[3], vPos1[3], vPos2[3], vPos3[3];
	if( g_iSurvivors[0] )		GetClientAbsOrigin(GetClientOfUserId(g_iSurvivors[0]), vPos1);
	else if( g_iSurvivors[1] )	GetClientAbsOrigin(GetClientOfUserId(g_iSurvivors[1]), vPos2);
	else if( g_iSurvivors[2] )	GetClientAbsOrigin(GetClientOfUserId(g_iSurvivors[2]), vPos3);

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
		{
			GetClientAbsOrigin(i, vPos);

			if( g_iSurvivors[0] && GetVectorDistance(vPos, vPos1) <= 600.0 ||
				g_iSurvivors[1] && GetVectorDistance(vPos, vPos2) <= 600.0 ||
				g_iSurvivors[2] && GetVectorDistance(vPos, vPos3) <= 600.0
			)
			{
				SetVariantString("Director.L4D1SurvivorGiveItem();");
				AcceptEntityInput(g_iLogicTimer, "RunScriptCode");
				return;
			}
		}
	}
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
public Action CmdHoldoutGive(int client, int args)
{
	if( IsValidEntRef(g_iLogicTimer) )
	{
		SetVariantString("Director.L4D1SurvivorGiveItem();");
		AcceptEntityInput(g_iLogicTimer, "RunScriptCode");
	}
	return Plugin_Handled;
}

public Action CmdHoldoutSave(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[SurvivorHoldout] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( g_bBlocked == true )
	{
		ReplyToCommand(client, "[SurvivorHoldout] This map has been blocked by the plugin.");
		return Plugin_Handled;
	}

	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SurvivorHoldout] Plugin is turned off. Re-enable to use.");
		return Plugin_Handled;
	}

	if( args != 1 && args != 2 )
	{
		PrintToChat(client, "%sUsage: sm_holdout <1=Francis, 2=Louis, 3=Zoey, 4=Bill, 5=Nick, 6=Rochelle, 7=Coach, 8=Ellis> [weapon name, eg: rifle_ak47]", CHAT_TAG);
		return Plugin_Handled;
	}

	char sTemp[64];
	GetCmdArg(1, sTemp, sizeof(sTemp));
	int type = StringToInt(sTemp);

	if( type < 1 || type > 8 )
	{
		PrintToChat(client, "%sUsage: sm_holdout <1=Francis, 2=Louis, 3=Zoey, 4=Bill, 5=Nick, 6=Rochelle, 7=Coach, 8=Ellis> [weapon name, eg: rifle_ak47]", CHAT_TAG);
		return Plugin_Handled;
	}

	bool vDelete;

	int target = g_iSurvivors[type-1];
	if( target != 0 && (target = GetClientOfUserId(target)) != 0 )
	{
		if( IsFakeClient(target) )
		{
			vDelete = true;
			RemoveWeapons(target, type);
			KickClient(target, "SurvivorHoldout::KickClientB");
			PrintToChat(client, "%sKicked survivor bot \x04(%d) %N \x01.", CHAT_TAG, target, target);
		}
		else
		{
			PrintToChat(client, "%sError: Prevented kicking \x04%d) %N\x01, why are they using my bot?", CHAT_TAG, target, target);
			LogError("SurvivorHoldout::B::Prevented kicking %d) %N, why are they using my bot?", target, target);
			return Plugin_Handled;
		}
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		File hCfg = OpenFile(sPath, "w");
		hCfg.WriteLine("");
		delete hCfg;
	}

	KeyValues hFile = new KeyValues("holdout");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot read the config, assuming empty file. (\x05%s\x01).", CHAT_TAG, sPath);
	}

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if( !hFile.JumpToKey(sMap, true) )
	{
		PrintToChat(client, "%sError: Failed to add the current map to the config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	if( vDelete )
	{
		if( hFile.JumpToKey(sTemp) == true )
		{
			hFile.GoBack();
			hFile.DeleteKey(sTemp);
			hFile.Rewind();
			hFile.ExportToFile(sPath);
			delete hFile;
			PrintToChat(client, "%sDeleted \x04(%d)\x01 from the config.", CHAT_TAG, target);
		}
		else
		{
			PrintToChat(client, "%sNothing to delete from the config.", CHAT_TAG);
		}
		return Plugin_Handled;
	}

	if( hFile.JumpToKey(sTemp, true) == false )
	{
		PrintToChat(client, "%sError: Failed to add a new index to the config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	float vAng[3], vPos[3];
	GetClientAbsOrigin(client, vPos);
	vAng = vPos;
	vAng[2] += 5.0;
	vPos[2] -= 500.0;

	Handle trace = TR_TraceRayFilterEx(vAng, vPos, MASK_SHOT, RayType_EndPoint, TraceFilter);
	if( TR_DidHit(trace) )
	{
		TR_GetEndPosition(vPos, trace);
		delete trace;
	}
	else
	{
		delete hFile;
		delete trace;
		PrintToChat(client, "%sError: Failed to find the ground.", CHAT_TAG);
		return Plugin_Handled;
	}

	GetClientAbsAngles(client, vAng);
	hFile.SetFloat("ang", vAng[1]);
	hFile.SetVector("pos", vPos);

	if( args == 2 )
	{
		GetCmdArg(2, sTemp, sizeof(sTemp));
		hFile.SetString("wep", sTemp);
	}
	else
	{
		sTemp[0] = 0;
	}

	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	SpawnSurvivor(type, vPos, vAng, sTemp);

	PrintToChat(client, "%sSaved at pos:[\x05%f %f %f\x01]", CHAT_TAG, vPos[0], vPos[1], vPos[2]);
	return Plugin_Handled;
}

public Action CmdHoldoutTemp(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[SurvivorHoldout] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( g_bBlocked == true )
	{
		ReplyToCommand(client, "[SurvivorHoldout] This map has been blocked by the plugin.");
		return Plugin_Handled;
	}

	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SurvivorHoldout] Plugin is turned off. Re-enable to use.");
		return Plugin_Handled;
	}

	if( args != 1 && args != 2 )
	{
		PrintToChat(client, "%sUsage: sm_holdout_temp <1=Francis, 2=Louis, 3=Zoey, 4=Bill, 5=Nick, 6=Rochelle, 7=Coach, 8=Ellis> [weapon name, eg: rifle_ak47]", CHAT_TAG);
		return Plugin_Handled;
	}

	char sTemp[64];
	GetCmdArg(1, sTemp, sizeof(sTemp));
	int type = StringToInt(sTemp);

	if( type < 1 || type > 8 )
	{
		PrintToChat(client, "%sUsage: sm_holdout_temp <1=Francis, 2=Louis, 3=Zoey, 4=Bill, 5=Nick, 6=Rochelle, 7=Coach, 8=Ellis> [weapon name, eg: rifle_ak47]", CHAT_TAG);
		return Plugin_Handled;
	}

	if( args == 2 )
		GetCmdArg(2, sTemp, sizeof(sTemp));
	else
	{
		int randWeap = GetRandomInt(0, sizeof(g_sWeaponNames) - 1);
		sTemp = g_sWeaponNames[randWeap];
	}

	float vAng[3], vPos[3];
	GetClientAbsOrigin(client, vPos);
	vAng = vPos;
	vAng[2] += 5.0;
	vPos[2] -= 500.0;

	Handle trace = TR_TraceRayFilterEx(vAng, vPos, MASK_SHOT, RayType_EndPoint, TraceFilter);
	if( TR_DidHit(trace) == false )
	{
		PrintToChat(client, "%sError: Failed to find the ground.", CHAT_TAG);
		delete trace;
		return Plugin_Handled;
	}
	else
	{
		TR_GetEndPosition(vPos, trace);
		delete trace;
	}

	GetClientAbsAngles(client, vAng);
	SpawnSurvivor(type, vPos, vAng, sTemp);
	return Plugin_Handled;
}



// ====================================================================================================
//					SPAWN
// ====================================================================================================
public void OnClientPutInServer(int client)
{
	if( g_iType )
	{
		g_iSurvivors[g_iType-1] = GetClientUserId(client);
	}
}

public void OnClientDisconnect(int client)
{
	if( IsClientInGame(client) && IsFakeClient(client) )
	{
		int userid = GetClientUserId(client);

		for( int i = 0; i < MAX_SURVIVORS; i++ )
		{
			if( g_iSurvivors[i] == userid )
			{
				RemoveWeapons(client, i+1);
				break;
			}
		}
	}
}

void SpawnSurvivor(int type, float vPos[3], float vAng[3], char sWeapon[64])
{
	int client = g_iSurvivors[type-1];
	if( client != 0 && (client = GetClientOfUserId(client)) != 0 )
	{
		if( IsFakeClient(client) )
		{
			RemoveWeapons(client, type);
			KickClient(client, "SurvivorHoldout::KickClientC");
		}
		else
		{
			LogError("SurvivorHoldout:C:Prevented kicking %d) %N, why are they using my bot?", client, client);
		}
	}

	int entity = CreateEntityByName("info_l4d1_survivor_spawn");
	if( entity == -1 )
	{
		LogError("Failed to create \"info_l4d1_survivor_spawn\"");
		return;
	}

	int character;
	switch( type )
	{
		case 1:		// Francis
		{
			character = 6;
			DispatchKeyValue(entity, "character", "6");
			SetVariantString("OnUser4 silver_francis:SetGlowEnabled:0:1:-1");
		}
		case 2:		// Louis
		{
			character = 7;
			DispatchKeyValue(entity, "character", "7");
			SetVariantString("OnUser4 silver_louis:SetGlowEnabled:0:1:-1");
		}
		case 3:		// Zoey
		{
			character = 5;
			DispatchKeyValue(entity, "character", "5");
			SetVariantString("OnUser4 silver_zoey:SetGlowEnabled:0:1:-1");
		}
		case 4:		// Bill
		{
			character = 4;
			DispatchKeyValue(entity, "character", "4");
			SetVariantString("OnUser4 silver_bill:SetGlowEnabled:0:1:-1");
		}
		case 5:		// Nick
		{
			character = 4;
			DispatchKeyValue(entity, "character", "4");
			SetVariantString("OnUser4 silver_nick:SetGlowEnabled:0:1:-1");
		}
		case 6:		// Rochelle
		{
			character = 5;
			DispatchKeyValue(entity, "character", "5");
			SetVariantString("OnUser4 silver_rochelle:SetGlowEnabled:0:1:-1");
		}
		case 7:		// Coach
		{
			character = 6;
			DispatchKeyValue(entity, "character", "6");
			SetVariantString("OnUser4 silver_coach:SetGlowEnabled:0:1:-1");
		}
		case 8:		// Ellis
		{
			character = 7;
			DispatchKeyValue(entity, "character", "7");
			SetVariantString("OnUser4 silver_ellis:SetGlowEnabled:0:1:-1");
		}
	}

	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser4");
	RemoveEntity(entity);

	vPos[2] += 1.0;
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	DispatchSpawn(entity);

	g_iSurvivors[type-1] = 0;
	g_iType = type;
	AvoidCharacter(character, true);
	AcceptEntityInput(entity, "SpawnSurvivor");
	AvoidCharacter(character, false);
	g_iType = 0;
	client = g_iSurvivors[type-1];

	if( client == 0 || (client = GetClientOfUserId(client)) == 0 )
	{
		LogError("Failed to match survivor (%d), did they not spawn? [%d/%d]", type, client, GetClientOfUserId(client));
		return;
	}

	switch( type )
	{
		case 5:		// Nick
		{
			SetEntProp(client, Prop_Send, "m_survivorCharacter", 0);
			SetEntityModel(client, MODEL_NICK);
			SetClientName(client, "Nick_Holdout");
		}
		case 6:		// Rochelle
		{
			SetEntProp(client, Prop_Send, "m_survivorCharacter", 1);
			SetEntityModel(client, MODEL_ROCHELLE);
			SetClientName(client, "Rochelle_Holdout");
		}
		case 7:		// Coach
		{
			SetEntProp(client, Prop_Send, "m_survivorCharacter", 2);
			SetEntityModel(client, MODEL_COACH);
			SetClientName(client, "Coach_Holdout");
		}
		case 8:		// Ellis
		{
			SetEntProp(client, Prop_Send, "m_survivorCharacter", 3);
			SetEntityModel(client, MODEL_ELLIS);
			SetClientName(client, "Ellis_Holdout");
		}
	}

	switch( type )
	{
		case 1:		DispatchKeyValue(client, "targetname", "silver_francis");
		case 2:		DispatchKeyValue(client, "targetname", "silver_louis");
		case 3:		DispatchKeyValue(client, "targetname", "silver_zoey");
		case 4:		DispatchKeyValue(client, "targetname", "silver_bill");
		case 5:		DispatchKeyValue(client, "targetname", "silver_nick");
		case 6:		DispatchKeyValue(client, "targetname", "silver_rochelle");
		case 7:		DispatchKeyValue(client, "targetname", "silver_coach");
		case 8:		DispatchKeyValue(client, "targetname", "silver_ellis");
	}

	TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
	if( type == 2 && g_iCvarMiniGun && GetRandomInt(1, 100) <= g_iCvarMiniGun )
	{
		float vDir[3];
		GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
		vDir[0] = vPos[0] + (vDir[0] * 50);
		vDir[1] = vPos[1] + (vDir[1] * 50);
		vDir[2] = vPos[2] + 20.0;
		vPos = vDir;
		vPos[2] -= 40.0;

		Handle trace = TR_TraceRayFilterEx(vDir, vPos, MASK_SHOT, RayType_EndPoint, TraceFilter);
		if( TR_DidHit(trace) )
		{
			TR_GetEndPosition(vDir, trace);

			g_iMiniGun = CreateEntityByName("prop_mounted_machine_gun");
			g_iMiniGun = EntIndexToEntRef(g_iMiniGun);
			SetEntityModel(g_iMiniGun, MODEL_MINIGUN);
			DispatchKeyValue(g_iMiniGun, "targetname", "louis_holdout");
			DispatchKeyValueFloat(g_iMiniGun, "MaxPitch", 360.00);
			DispatchKeyValueFloat(g_iMiniGun, "MinPitch", -360.00);
			DispatchKeyValueFloat(g_iMiniGun, "MaxYaw", 90.00);
			vPos[2] += 0.1;
			TeleportEntity(g_iMiniGun, vDir, vAng, NULL_VECTOR);
			DispatchSpawn(g_iMiniGun);

			strcopy(sWeapon, sizeof(sWeapon), "rifle_ak47");
		}

		delete trace;

		if( g_iCvarFreeze == 1 )
			CreateTimer(2.0, TimerMove, g_iSurvivors[type-1]); // Allow Louis to move into MG position
	}
	else
	{
		if( g_iCvarFreeze == 1 )
			CreateTimer(0.5, TimerMove, g_iSurvivors[type-1]);
	}

	if( sWeapon[0] )
	{
		char sTemp[64];
		Format(sTemp, sizeof(sTemp), "weapon_%s", sWeapon);

		entity = CreateEntityByName(sTemp);
		if( entity != -1 )
		{
			g_iWeapons[type-1] = EntIndexToEntRef(entity);
			DispatchSpawn(entity);
			TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

			if( g_iCvarLasers )
				SetEntProp(entity, Prop_Send, "m_upgradeBitVec", 4);

			EquipPlayerWeapon(client, entity);
			GetOrSetPlayerAmmo(client, entity, 9999);


			if( g_iCvarPile && character != 7 )
			{
				float vDir[3];
				GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
				vDir[0] = vPos[0] + (vDir[0] * 40);
				vDir[1] = vPos[1] + (vDir[1] * 40);
				vDir[2] = vPos[2] + 20.0;
				vPos[0] = vDir[0];
				vPos[1] = vDir[1];
				vPos[2] = vDir[2];
				vPos[2] -= 40.0;

				Handle trace = TR_TraceRayFilterEx(vDir, vPos, MASK_SHOT, RayType_EndPoint, TraceFilter);
				if( TR_DidHit(trace) )
				{
					TR_GetEndPosition(vDir, trace);
					delete trace;

					entity = CreateEntityByName("weapon_ammo_spawn");
					if( entity != -1 )
					{
						g_iAmmoPile[type-1] = EntIndexToEntRef(entity);
						TeleportEntity(entity, vDir, vAng, NULL_VECTOR);
						DispatchSpawn(entity);
					}
				}

				delete trace;
			}
		}
	}
}

// Stops teleporting players of the same survivor type when spawning a holdout bot
int g_iAvoidChar[MAXPLAYERS+1] = {-1,...};
void AvoidCharacter(int type, bool avoid)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && (GetClientTeam(i) == 2 || GetClientTeam(i) == 4) )
		{
			if( avoid )
			{
				// Save character type
				g_iAvoidChar[i] = GetEntProp(i, Prop_Send, "m_survivorCharacter");
				int set;
				switch( type )
				{
					case 4: set = 3;	// Bill
					case 5: set = 2;	// Zoey
					case 6: set = 1;	// Francis
					case 7: set = 0;	// Louis
				}
				SetEntProp(i, Prop_Send, "m_survivorCharacter", set);
			} else {
				// Restore player type
				if( g_iAvoidChar[i] != -1 )
				{
					SetEntProp(i, Prop_Send, "m_survivorCharacter", g_iAvoidChar[i]);
					g_iAvoidChar[i] = -1;
				}
			}
		}
	}

	if( !avoid )
	{
		for( int i = 1; i <= MAXPLAYERS; i++ )
			g_iAvoidChar[i] = -1;
	}
}

int GetOrSetPlayerAmmo(int client, int iWeapon, int iAmmo = -1)
{
	int offset = GetEntData(iWeapon, g_iPrimaryAmmoType) * 4; // Thanks to "Root" or whoever for this method of not hard-coding offsets: https://github.com/zadroot/AmmoManager/blob/master/scripting/ammo_manager.sp

	// Get/Set
	if( offset )
	{
		if( iAmmo != -1 ) SetEntData(client, g_iOffsetAmmo + offset, iAmmo);
		else return GetEntData(client, g_iOffsetAmmo + offset);
	}

	return 0;
}

public bool TraceFilter(int entity, int contentsMask)
{
	if( entity <= MaxClients )
		return false;
	return true;
}

public Action TimerMove(Handle timer, any client)
{
	if( (client = GetClientOfUserId(client)) )
	{
		SetEntityMoveType(client, MOVETYPE_NONE);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
	}
	return Plugin_Continue;
}

bool IsValidEntRef(int iEnt)
{
	if( iEnt && EntRefToEntIndex(iEnt) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}



// Taken from:
// [Tech Demo] L4D2 Vocalize ANYTHING
// https://forums.alliedmods.net/showthread.php?t=122270
// author = "AtomicStryker"
// ====================================================================================================
//					VOCALIZE SCENE
// ====================================================================================================
void PlaySound(int client, const char[] sound)
{
	EmitSoundToAll(sound, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

void VocalizeScene(int client, const char[] scenefile)
{
	int entity = CreateEntityByName("instanced_scripted_scene");
	DispatchKeyValue(entity, "SceneFile", scenefile);
	DispatchSpawn(entity);
	SetEntPropEnt(entity, Prop_Data, "m_hOwner", client);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "Start", client, client);
}