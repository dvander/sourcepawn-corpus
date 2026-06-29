#define PLUGIN_VERSION 		"1.6"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Survivor Bot Holdout
*	Author	:	SilverShot
*	Descrp	:	Create up to 4 bots (Bill, Francis, Louis and Zoey) to holdout their surrounding area, c6m3_port style.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=188966
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

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
#define	MAX_SURVIVORS		4

#define MODEL_MINIGUN		"models/w_models/weapons/w_minigun.mdl"
#define MODEL_FRANCIS		"models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS			"models/survivors/survivor_manager.mdl"
#define MODEL_ZOEY			"models/survivors/survivor_teenangst.mdl"
#define MODEL_BILL			"models/survivors/survivor_namvet.mdl"


ConVar g_hCvarAllow, g_hCvarFreeze, g_hCvarLasers, g_hCvarMPGameMode, g_hCvarMiniGun, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarPile, g_hCvarThrow, g_hCvarTimeMax, g_hCvarTimeMin;
int g_iAmmoPile[MAX_SURVIVORS], g_iCvarFreeze, g_iCvarLasers, g_iCvarMiniGun, g_iCvarPile, g_iCvarThrow, g_iCvarTimeMax, g_iCvarTimeMin, g_iDeathModel[MAXPLAYERS+1], g_iLogicTimer, g_iMiniGun, g_iOffsetAmmo, g_iPlayerSpawn, g_iRoundStart, g_iSurvivors[MAX_SURVIVORS], g_iType, g_iWeapons[MAX_SURVIVORS];
bool g_bCvarAllow, g_bMapStarted, g_bLoaded;
bool g_bBlocked;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Survivor Bot Holdout",
	author = "SilverShot",
	description = "Create up to 4 bots (Bill, Francis, Louis and Zoey) to holdout their surrounding area, c6m3_port style.",
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
	RegAdminCmd("sm_holdout",		CmdHoldoutSave,		ADMFLAG_ROOT,	"Saves to the config for auto spawning or Deletes if already saved. Usage: sm_holdout <1=Francis, 2=Louis, 3=Zoey, 4=Bill> [weapon name, eg: rifle_ak47].");
	RegAdminCmd("sm_holdout_temp",	CmdHoldoutTemp,		ADMFLAG_ROOT,	"Spawn a temporary survivor (not saved). Usage: sm_holdout_temp <1=Francis, 2=Louis, 3=Zoey, 4=Bill> [weapon name, eg: rifle_ak47].");
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
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public void OnMapStart()
{
	g_bMapStarted = true;

	PrecacheModel(MODEL_MINIGUN);
	PrecacheModel(MODEL_FRANCIS);
	PrecacheModel(MODEL_LOUIS);
	PrecacheModel(MODEL_ZOEY);
	PrecacheModel(MODEL_BILL);

	char sMap[16];
	GetCurrentMap(sMap, sizeof(sMap));
	if( strcmp(sMap, "c6m1_riverbank") == 1 || strcmp(sMap, "c6m3_port") == 1 )
		g_bBlocked = false;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin();
}

void ResetPlugin()
{
	g_bBlocked = false;
	g_bLoaded = false;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;

	if( IsValidEntRef(g_iLogicTimer) )
		AcceptEntityInput(g_iLogicTimer, "Kill");

	if( IsValidEntRef(g_iMiniGun) )
		AcceptEntityInput(g_iMiniGun, "Kill");

	int client, entity;
	for( int i = 0; i < MAX_SURVIVORS; i++ )
	{
		entity = g_iWeapons[i];
		g_iWeapons[i] = 0;
		if( IsValidEntRef(entity) )
			AcceptEntityInput(entity, "Kill");

		entity = g_iAmmoPile[i];
		g_iAmmoPile[i] = 0;
		if( IsValidEntRef(entity) )
			AcceptEntityInput(entity, "Kill");

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
		AcceptEntityInput(g_iMiniGun, "Kill");
		g_iMiniGun = 0;
	}

	type--;

	if( IsValidEntRef(g_iWeapons[type]) )
		AcceptEntityInput(g_iWeapons[type], "Kill");
	g_iWeapons[type] = 0;

	if( IsValidEntRef(g_iAmmoPile[type]) )
		AcceptEntityInput(g_iAmmoPile[type], "Kill");
	g_iAmmoPile[type] = 0;

	int entity;
	for( int i = 0; i < 5; i++ )
	{
		entity = GetPlayerWeaponSlot(client, 0);
		if( entity != -1 )
		{
			RemovePlayerItem(client, entity);
			AcceptEntityInput(entity, "Kill");
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

		char sMap[16];
		GetCurrentMap(sMap, sizeof(sMap));
		if( strcmp(sMap, "c6m1_riverbank") == 1 || strcmp(sMap, "c6m3_port") == 1 )
			g_bBlocked = false;
		else
			CreateTimer(0.5, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		UnhookEvent("round_end",	Event_RoundEnd,		EventHookMode_PostNoCopy);
		UnhookEvent("round_start",	Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("player_spawn",	Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		UnhookEvent("player_death",	Event_PlayerDeath,	EventHookMode_Pre);
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
//					EVENTS - LOAD
// ====================================================================================================
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
					AcceptEntityInput(g_iDeathModel[client], "Kill");
					g_iDeathModel[client] = 0;
				}
				KickClient(client, "SurvivorHoldout::KickClientD");
			}
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(1.0, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(1.0, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

public Action tmrStart(Handle timer)
{
	ResetPlugin();
	LoadSurvivors();
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

	if( hFile.JumpToKey("1") )
	{
		vAng[1] = hFile.GetFloat("ang");
		hFile.GetVector("pos", vPos);
		hFile.GetString("wep", sTemp, sizeof(sTemp));
		SpawnSurvivor(1, vPos, vAng, sTemp);
		hFile.GoBack();
		spawned++;
	}

	if( hFile.JumpToKey("2") )
	{
		vAng[1] = hFile.GetFloat("ang");
		hFile.GetVector("pos", vPos);
		hFile.GetString("wep", sTemp, sizeof(sTemp));
		SpawnSurvivor(2, vPos, vAng, sTemp);
		hFile.GoBack();
		spawned++;
	}

	if( hFile.JumpToKey("3") )
	{
		vAng[1] = hFile.GetFloat("ang");
		hFile.GetVector("pos", vPos);
		hFile.GetString("wep", sTemp, sizeof(sTemp));
		SpawnSurvivor(3, vPos, vAng, sTemp);
		hFile.GoBack();
		spawned++;
	}

	if( hFile.JumpToKey("4") )
	{
		vAng[1] = hFile.GetFloat("ang");
		hFile.GetVector("pos", vPos);
		hFile.GetString("wep", sTemp, sizeof(sTemp));
		SpawnSurvivor(4, vPos, vAng, sTemp);
		spawned++;
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

	if( args != 1 && args != 2 )
	{
		PrintToChat(client, "%sUsage: sm_holdout <1=Francis, 2=Louis, 3=Zoey, 4=Bill> [weapon name, eg: rifle_ak47]", CHAT_TAG);
		return Plugin_Handled;
	}

	char sTemp[64];
	GetCmdArg(1, sTemp, sizeof(sTemp));
	int type = StringToInt(sTemp);

	if( type < 1 || type > 4 )
	{
		PrintToChat(client, "%sUsage: sm_holdout <1=Francis, 2=Louis, 3=Zoey, 4=Bill> [weapon name, eg: rifle_ak47]", CHAT_TAG);
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

	if( args != 1 && args != 2 )
	{
		PrintToChat(client, "%sUsage: sm_holdout_temp <1=Francis, 2=Louis, 3=Zoey, 4=Bill> [weapon name, eg: rifle_ak47]", CHAT_TAG);
		return Plugin_Handled;
	}

	char sTemp[64];
	GetCmdArg(1, sTemp, sizeof(sTemp));
	int type = StringToInt(sTemp);

	if( type < 1 || type > 4 )
	{
		PrintToChat(client, "%sUsage: sm_holdout_temp <1=Francis, 2=Louis, 3=Zoey, 4=Bill> [weapon name, eg: rifle_ak47]", CHAT_TAG);
		return Plugin_Handled;
	}

	if( args == 2 )
		GetCmdArg(2, sTemp, sizeof(sTemp));
	else
		sTemp[0] = 0;

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
	}

	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser4");
	AcceptEntityInput(entity, "Kill");

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
		case 1:		DispatchKeyValue(client, "targetname", "silver_francis");
		case 2:		DispatchKeyValue(client, "targetname", "silver_louis");
		case 3:		DispatchKeyValue(client, "targetname", "silver_zoey");
		case 4:		DispatchKeyValue(client, "targetname", "silver_bill");
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
g_iAvoidChar[MAXPLAYERS+1] = {-1,...};
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
					case 7: set = 1;	// Francis
					case 6: set = 0;	// Louis
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
	// Offsets
	static StringMap hOffsets;
	if( hOffsets == null )
	{
		hOffsets = new StringMap();
		// L4D1 + L4D2
		hOffsets.SetValue("weapon_rifle", 12);
		hOffsets.SetValue("weapon_smg", 20);
		hOffsets.SetValue("weapon_pumpshotgun", 28);
		hOffsets.SetValue("weapon_shotgun_chrome", 28);
		hOffsets.SetValue("weapon_autoshotgun", 32);
		hOffsets.SetValue("weapon_hunting_rifle", 36);
		// L4D2
		hOffsets.SetValue("weapon_rifle_sg552", 12);
		hOffsets.SetValue("weapon_rifle_desert", 12);
		hOffsets.SetValue("weapon_rifle_ak47", 12);
		hOffsets.SetValue("weapon_smg_silenced", 20);
		hOffsets.SetValue("weapon_smg_mp5", 20);
		hOffsets.SetValue("weapon_shotgun_spas", 32);
		hOffsets.SetValue("weapon_sniper_scout", 40);
		hOffsets.SetValue("weapon_sniper_military", 40);
		hOffsets.SetValue("weapon_sniper_awp", 40);
		hOffsets.SetValue("weapon_grenade_launcher", 68);
	}

	// Get/Set
	char sWeapon[32];
	GetEdictClassname(iWeapon, sWeapon, sizeof(sWeapon));

	int offset;
	hOffsets.GetValue(sWeapon, offset);

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
}

bool IsValidEntRef(int iEnt)
{
	if( iEnt && EntRefToEntIndex(iEnt) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}