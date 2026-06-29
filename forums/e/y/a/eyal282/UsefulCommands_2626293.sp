// To do: Add weapon stats comparison based on what I used with Big Bertha

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <clientprefs>

#define HEADSHOT_MULTIPLIER 4.0
#define STOMACHE_MULTIPLIER 1.25
#define CHEST_MULTIPLIER 1.0
#define LEGS_MULTIPLIER 0.75 // Also legs are immune to kevlar and yes, bizon is stronger on legs than kevlar chest.

#undef REQUIRE_PLUGIN
#tryinclude <updater>  // Comment out this line to remove updater support by force.
#define UPDATE_URL    "https://raw.githubusercontent.com/eyal282/AlliedmodsUpdater/master/UsefulCommands/updatefile.txt"

//#define TEST

new const String:PLUGIN_VERSION[] = "2.6";

public Plugin:myinfo = 
{
	name = "Useful commands",
	author = "Eyal282",
	description = "Useful commands.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2617618"
}

#define COMMAND_FILTER_NONE 0

#define UC_ADMFLAG_SHOWIP ADMFLAG_ROOT

#define MAX_HUG_DISTANCE 100.0

#define GLOW_WALLHACK 0
#define GLOW_FULLBODY 1
#define GLOW_SURROUNDPLAYER 2
#define GLOW_SURROUNDPLAYER_BLINKING 3 

#define EF_BONEMERGE                (1 << 0)
#define EF_NOSHADOW                 (1 << 4)
#define EF_NORECEIVESHADOW          (1 << 6)
#define EF_PARENT_ANIMATES          (1 << 9)

#define PARTYMODE_NONE 0
#define PARTYMODE_DEFUSE (1<<0)
#define PARTYMODE_ZEUS (1<<1)

new ChickenOriginPosition;


enum FX
{
	FxNone = 0,
	FxPulseFast,
	FxPulseSlowWide,
	FxPulseFastWide,
	FxFadeSlow,
	FxFadeFast,
	FxSolidSlow,
	FxSolidFast,
	FxStrobeSlow,
	FxStrobeFast,
	FxStrobeFaster,
	FxFlickerSlow,
	FxFlickerFast,
	FxNoDissipation,
	FxDistort,               // Distort/scale/translate flicker
	FxHologram,              // kRenderFxDistort + distance fade
	FxExplode,               // Scale up really big!
	FxGlowShell,             // Glowing Shell
	FxClampMinScale,         // Keep this sprite from getting very small (SPRITES only!)
	FxEnvRain,               // for environmental rendermode, make rain
	FxEnvSnow,               //  "        "            "    , make snow
	FxSpotlight,     
	FxRagdoll,
	FxPulseFastWider,
};

enum Render
{
	Normal = 0, 		// src
	TransColor, 		// c*a+dest*(1-a)
	TransTexture,		// src*a+dest*(1-a)
	Glow,				// src*a+dest -- No Z buffer checks -- Fixed size in screen space
	TransAlpha,			// src*srca+dest*(1-srca)
	TransAdd,			// src*a+dest
	Environmental,		// not drawn, used for environmental effects
	TransAddFrameBlend,	// use a fractional frame value to blend between animation frames
	TransAlphaAdd,		// src + dest*(1-a)
	WorldGlow,			// Same as kRenderGlow but not fixed size in screen space
	None,				// Don't render.
};

new const String:PartySound[] = "weapons/party_horn_01.wav";
new const String:ItemPickUpSound[] = "items/pickup_weapon_02.wav";

new bool:g_bCheckedEngine = false;
new bool:g_bNeedsFakePrecache = false;

new Float:DeathOrigin[MAXPLAYERS+1][3];

new bool:UberSlapped[MAXPLAYERS+1], TotalSlaps[MAXPLAYERS+1];

new Handle:hcv_PartyMode = INVALID_HANDLE;
new Handle:hcv_mpAnyoneCanPickupC4 = INVALID_HANDLE;
//new Handle:hcv_svCheats = INVALID_HANDLE;
//new svCheatsFlags = 0;

new Handle:hcv_ucSpecialC4Rules = INVALID_HANDLE;
new Handle:hcv_ucTeleportBomb = INVALID_HANDLE;
new Handle:hcv_ucUseBombPickup = INVALID_HANDLE;
new Handle:hcv_ucAcePriority = INVALID_HANDLE;
new Handle:hcv_ucMaxChickens = INVALID_HANDLE;
new Handle:hcv_ucMinChickenTime = INVALID_HANDLE;
new Handle:hcv_ucMaxChickenTime = INVALID_HANDLE;
new Handle:hcv_ucPartyMode = INVALID_HANDLE;
new Handle:hcv_ucPartyModeDefault = INVALID_HANDLE;
new Handle:hCookie_EnablePM = INVALID_HANDLE;
new Handle:hCookie_AceFunFact = INVALID_HANDLE;

new Handle:TIMER_UBERSLAP[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:TIMER_STUCK[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:TIMER_LIFTOFF[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:TIMER_ROCKETCHECK[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:TIMER_LASTC4[MAXPLAYERS+1] = INVALID_HANDLE;

new AceCandidate[7]; // IDK How many teams there are...

new LastC4Ref[MAXPLAYERS+1] = INVALID_ENT_REFERENCE;

new bool:MapStarted = false, String:MapName[128];

new RoundNumber = 0;

new Handle:TeleportsArray = INVALID_HANDLE;
new Handle:BombResetsArray = INVALID_HANDLE;
new Handle:ChickenOriginArray = INVALID_HANDLE;

new Handle:fw_ucAce = INVALID_HANDLE;
new Handle:fw_ucAcePost = INVALID_HANDLE;

new bool:AceSent = false, TrueTeam[MAXPLAYERS+1];

new Handle:dbLocal;

new bool:FullInGame[MAXPLAYERS+1];

new Float:LastHeight[MAXPLAYERS+1];

new Handle:hRestartTimer = INVALID_HANDLE;

new bool:Restart = false;

new Handle:hcv_TagScale = INVALID_HANDLE;

new bool:UCEdit[MAXPLAYERS+1];

new ClientGlow[MAXPLAYERS+1];

new bool:isHugged[MAXPLAYERS+1];

new EngineVersion:GameName;

new bool:isLateLoaded = false;

new bool:show_timer_defend, bool:show_timer_attack, timer_time, final_event, String:funfact_token[256],
funfact_player, funfact_data1, funfact_data2, funfact_data3;
new bool:BlockedWinPanel;

enum enGlow
{
	String:GlowName[50],
	GlowColorR,
	GlowColorG,
	GlowColorB
};
new const GlowData[][enGlow] =
{
	{ "Red", 255, 0, 0 },
	{ "Blue", 0, 0, 255 },
	{ "TAGrenade", 154, 50, 50 },
	{ "White", 255, 255, 255 } // White won't work in CSS.
};

enum enWepStatsList
{
	wepStatsDamage,
	wepStatsFireRate,
	Float:wepStatsArmorPenetration,
	wepStatsKillAward,
	wepStatsDamageDropoff,
	wepStatsMaxDamageRange,
	wepStatsPalletsPerShot, // For shotguns
	wepStatsTapDistanceNoArmor,
	wepStatsTapDistanceArmor
};	
new wepStatsList[CSWeapon_MAX_WEAPONS_NO_KNIFES][enWepStatsList];

new CSWeaponID:wepStatsIgnore[] =
{
	CSWeapon_C4,
	CSWeapon_KNIFE,
	CSWeapon_SHIELD,
	CSWeapon_KEVLAR,
	CSWeapon_ASSAULTSUIT,
	CSWeapon_NIGHTVISION,
	CSWeapon_KNIFE_GG,
	CSWeapon_DEFUSER,
	CSWeapon_HEAVYASSAULTSUIT,
	CSWeapon_CUTTERS,
	CSWeapon_HEALTHSHOT,
	CSWeapon_KNIFE_T
}
public APLRes:AskPluginLoad2(Handle:myself, bool:bLate, String:error[], length)
{
	isLateLoaded = bLate;
}
public OnPluginStart()
{
	GameName = GetEngineVersion();
	
	//hcv_svCheats = FindConVar("sv_cheats");
	
	//svCheatsFlags = GetConVarFlags(hcv_svCheats);
	

	if(isLateLoaded)
	{

		for(new i=1;i <= MaxClients;i++)
		{	
			if(!IsClientInGame(i))
				continue;
				
			OnClientPutInServer(i);
		}
		
		OnAllPluginsLoaded();
		OnMapStart();
	}
	
	if(isCSGO())
	{
		
		hcv_ucTeleportBomb = CreateConVar("uc_teleport_bomb", "1", "If 1, All trigger_teleport entities will have a trigger_bomb_reset attached to them so bombs never get stuck outside of reach in the game. Set to -1 to destroy this mechanism completely to reserve in entity count.", FCVAR_NOTIFY);
		
		hcv_ucUseBombPickup = CreateConVar("uc_use_bomb", "1", "If 1, Terrorists can pick up C4 by pressing E on it.", FCVAR_NOTIFY);
		
		HookConVarChange(hcv_ucTeleportBomb, OnTeleportBombChanged);
		
		if(TeleportsArray == INVALID_HANDLE)
			TeleportsArray = CreateArray(1);
			
		if(BombResetsArray == INVALID_HANDLE)
			BombResetsArray = CreateArray(1);
		
		if(!IsSoundPrecached(PartySound)) // Problems with the listen server...
			PrecacheSoundAny(PartySound);
		
		if(!IsSoundPrecached(ItemPickUpSound))
			PrecacheSoundAny(ItemPickUpSound);
	}
	
	LoadTranslations("common.phrases");
	
	#if defined _updater_included
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
}

#if defined _updater_included
public Updater_OnPluginUpdated()
{
	ReloadPlugin(INVALID_HANDLE);
}
#endif
public OnLibraryAdded(const String:name[])
{
	#if defined _updater_included
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
}
/*
public Action:Test(  int clients[64],
  int &numClients,
  char sample[PLATFORM_MAX_PATH],
  int &entity,
  int &channel,
  float &volume,
  int &level,
  int &pitch,
  int &flags)
 {

 }
*/
public OnAllPluginsLoaded()
{	
	fw_ucAce = CreateGlobalForward("UsefulCommands_OnPlayerAce", ET_Event, Param_CellByRef, Param_String);
	fw_ucAcePost = CreateGlobalForward("UsefulCommands_OnPlayerAcePost", ET_Ignore, Param_Cell, Param_String);
	
	// public UsefulCommands_OnPlayerAce(&client, String:FunFact[])
	// public UsefulCommands_OnPlayerAcePost(client, const String:FunFact[])
	
	SetConVarString(CreateConVar("uc_version", PLUGIN_VERSION, _, FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_PROTECTED), PLUGIN_VERSION);
	hcv_TagScale = CreateConVar("uc_bullet_tagging_scale", "1.0", "5000000.0 is more than enough to disable tagging completely. Below 1.0 makes tagging stronger. 1.0 for default game behaviour", FCVAR_NOTIFY, true, 0.0);
	hcv_ucSpecialC4Rules = CreateConVar("uc_special_bomb_rules", "0", "If 1, CT can pick-up C4 but can't abuse it in any way ( e.g dropping it in unreachable spots ) and can't get rid of it unless to another player.", FCVAR_NOTIFY);
	hcv_ucAcePriority = CreateConVar("uc_ace_priority", "2", "Prioritize Ace over all other fun facts of a round's end and print a message when a player makes an ace. Set to 2 if you want players to have a custom fun fact on ace.");
	
	if(!CommandExists("sm_revive"))
		RegAdminCmd("sm_revive", Command_Revive, ADMFLAG_BAN, "Respawns a player from the dead");
		
	if(!CommandExists("sm_1up"))
		RegAdminCmd("sm_1up", Command_HardRevive, ADMFLAG_BAN, "Respawns a player from the dead back to his death position");
		
	if(!CommandExists("sm_hrevive"))
		RegAdminCmd("sm_hrevive", Command_HardRevive, ADMFLAG_BAN, "Respawns a player from the dead back to his death position");
		
	if(!CommandExists("sm_bury"))
		RegAdminCmd("sm_bury", Command_Bury, ADMFLAG_BAN, "Buries a player underground");	
		
	if(!CommandExists("sm_unbury"))
		RegAdminCmd("sm_unbury", Command_Unbury, ADMFLAG_BAN, "unburies a player from the ground");	
		
	if(!CommandExists("sm_uberslap"))
		RegAdminCmd("sm_uberslap", Command_UberSlap, ADMFLAG_BAN, "Slaps a player 100 times, leaving him with 1 hp");	
	
	if(!CommandExists("sm_heal"))
		RegAdminCmd("sm_heal", Command_Heal, ADMFLAG_BAN, "Allows to either heal a player, give him armor or a helmet.");
		
	if(!CommandExists("sm_give"))
		RegAdminCmd("sm_give", Command_Give, ADMFLAG_CHEATS, "Give a weapon for a player.");
		
	if(!CommandExists("sm_rr"))
		RegAdminCmd("sm_rr", Command_RestartRound, ADMFLAG_CHANGEMAP, "Restarts the round.");
		
	if(!CommandExists("sm_restart"))
		RegAdminCmd("sm_restart", Command_RestartServer, ADMFLAG_CHANGEMAP, "Restarts the server after 5 seconds. Type again to abort restart.");
		
	if(!CommandExists("sm_glow"))
		RegAdminCmd("sm_glow", Command_Glow, ADMFLAG_BAN, "Puts glow on a player for all to see.");
		
	if(!CommandExists("sm_blink"))
		RegAdminCmd("sm_blink", Command_Blink, ADMFLAG_BAN, "Teleports the player to where you are aiming");
		
	if(!CommandExists("sm_godmode"))
		RegAdminCmd("sm_godmode", Command_Godmode, ADMFLAG_BAN, "Makes player immune to damage, not necessarily to death.");
		
	if(!CommandExists("sm_god"))
		RegAdminCmd("sm_god", Command_Godmode, ADMFLAG_BAN, "Makes player immune to damage, not necessarily to death.");
		
	if(!CommandExists("sm_rocket"))
		RegAdminCmd("sm_rocket", Command_Rocket, ADMFLAG_BAN, "The more handsome sm_slay command");
		
	if(!CommandExists("sm_disarm"))
		RegAdminCmd("sm_disarm", Command_Disarm, ADMFLAG_BAN, "strips all of the player's weapons");	
		
	//if(!CommandExists("sm_cheat"))
		//RegAdminCmd("sm_cheat", Command_Cheat, ADMFLAG_CHEATS, "Writes a command bypassing its cheat flag.");	
		
	if(!CommandExists("sm_last"))
		RegAdminCmd("sm_last", Command_Last, ADMFLAG_BAN, "Shows a full list of every single player that ever visited");
		
	if(!CommandExists("sm_exec"))
		RegAdminCmd("sm_exec", Command_Exec, ADMFLAG_BAN, "Makes a player execute a command. Use !fakeexec if doesn't work.");
		
	if(!CommandExists("sm_fakeexec"))
		RegAdminCmd("sm_fakeexec", Command_FakeExec, ADMFLAG_BAN, "Makes a player execute a command. Use !exec if doesn't work.");
	
	if(!CommandExists("sm_brutexec"))
		RegAdminCmd("sm_brutexec", Command_BruteExec, ADMFLAG_BAN, "Makes a player execute a command with !fakeexec but letting him have admin flags to accomplish the action. Use !exec if doesn't work.");
		
	if(!CommandExists("sm_bruteexec"))
		RegAdminCmd("sm_bruteexec", Command_BruteExec, ADMFLAG_BAN, "Makes a player execute a command with !fakeexec but letting him have admin flags to accomplish the action. Use !exec if doesn't work.");
		
	if(!CommandExists("sm_xyz"))
		RegAdminCmd("sm_xyz", Command_XYZ, ADMFLAG_GENERIC, "Prints your origin.");	
		
	if(!CommandExists("sm_silentcvar"))
		RegAdminCmd("sm_silentcvar", Command_SilentCvar, ADMFLAG_ROOT, "Changes cvar without in-game notification."); // I cannot afford to allow less than Root as I cannot monitor protected cvars. Changing access flag means the admin can get rcon_password.
		
	if(!CommandExists("sm_hug"))
		RegConsoleCmd("sm_hug", Command_Hug, "Hugs a dead player.");
		
	if(isCSGO())
	{
		if(!CommandExists("sm_customace"))
			RegConsoleCmd("sm_customace", Command_CustomAce, "Allows you to set a custom fun fact for ace.");
			
		hcv_PartyMode = FindConVar("sv_party_mode");
		
		hcv_ucPartyMode = CreateConVar("uc_party_mode", "2", "0 = Nobody can access party mode. 1 = You can choose to participate in party mode. 2 = Zeus will cost 100$ as tradition", FCVAR_NOTIFY);
		hcv_ucPartyModeDefault = CreateConVar("uc_party_mode_default", "3", "Party mode cookie to set for new comers. 0 = Disabled, 1 = Defuse balloons only, 2 = Zeus only, 3 = Both.");
	
		hCookie_EnablePM = RegClientCookie("UsefulCommands_PartyMode", "Party Mode flags. 0 = Disabled, 1 = Defuse balloons only, 2 = Zeus only, 3 = Both.", CookieAccess_Public);
		hCookie_AceFunFact = RegClientCookie("UsefulCommands_AceFunFact", "When you make an ace, this will be the fun fact to send to the server. $name -> your name. $team -> your team. $opteam -> your opponent team.", CookieAccess_Public);	
			
		HookEvent("bomb_defused", Event_BombDefused, EventHookMode_Pre);
		HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Pre);
		HookEvent("player_use", Event_PlayerUse, EventHookMode_Post);
		
		SetCookieMenuItem(PartyModeCookieMenu_Handler, 0, "Party Mode");
		
		hcv_mpAnyoneCanPickupC4 = FindConVar("mp_anyone_can_pickup_c4");
		
		HookConVarChange(hcv_ucSpecialC4Rules, OnSpecialC4RulesChanged);
			
		if(!CommandExists("sm_chicken"))
		{
			RegAdminCmd("sm_chicken", Command_Chicken, ADMFLAG_BAN, "Allows you to set up the map's chicken spawns.");	
			RegAdminCmd("sm_ucedit", Command_UCEdit, ADMFLAG_BAN, "Allows you to teleport to the chicken spawner prior to delete.");
			hcv_ucMaxChickens = CreateConVar("uc_max_chickens", "5", "Maximum amount of chickens UC will generate.");
			hcv_ucMinChickenTime = CreateConVar("uc_min_chicken_time", "5.0", "Minimum amount of time between a chicken's death and the recreation.");
			hcv_ucMaxChickenTime = CreateConVar("uc_max_chicken_time", "10.0", "Maximum amount of time between a chicken's death and the recreation.");
		}
		
		if(!CommandExists("sm_wepstats"))
			RegConsoleCmd("sm_wepstats", Command_WepStats, "Shows the stats of all weapons");
	}	
		
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	//HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	HookEvent("cs_win_panel_round", Event_CsWinPanelRound, EventHookMode_Pre);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	
}

public ConnectToDatabase()
{		
	new String:Error[256];
	if((dbLocal = SQLite_UseDatabase("sourcemod-local", Error, sizeof(Error))) == INVALID_HANDLE)
	{
		LogError(Error);
		return;
	}	
	else
	{ 
		SQL_TQuery(dbLocal, SQLCB_Error, "CREATE TABLE IF NOT EXISTS UsefulCommands_LastPlayers (AuthId VARCHAR(32) NOT NULL UNIQUE, LastConnect INT(11) NOT NULL, IPAddress VARCHAR(32) NOT NULL, Name VARCHAR(64) NOT NULL)", DBPrio_High); 
		
		if(isCSGO())
		{
			SQL_TQuery(dbLocal, SQLCB_Error, "CREATE TABLE IF NOT EXISTS UsefulCommands_Chickens (ChickenOrigin VARCHAR(50) NOT NULL, ChickenMap VARCHAR(128), ChickenCreateDate INT(11) NOT NULL, UNIQUE(ChickenOrigin, ChickenMap))", DBPrio_High);		
				
			LoadChickenSpawns();
		}
	}
}

public SQLCB_Error(Handle:db, Handle:hndl, const String:sError[], data)
{
	if(hndl == null)
		ThrowError(sError);
}


LoadChickenSpawns()
{
	new String:sQuery[256];
	Format(sQuery, sizeof(sQuery), "SELECT * FROM UsefulCommands_Chickens WHERE ChickenMap = \"%s\"", MapName);
	SQL_TQuery(dbLocal, SQLCB_LoadChickenSpawns, sQuery);
}
public SQLCB_LoadChickenSpawns(Handle:db, Handle:hndl, const String:sError[], data)
{
	if(hndl == null)
		ThrowError(sError);

	ClearArray(ChickenOriginArray);
	
	while(SQL_FetchRow(hndl))
	{
		new String:sOrigin[50];
		SQL_FetchString(hndl, 0, sOrigin, sizeof(sOrigin));
		
		CreateChickenSpawner(sOrigin);
	}
}

public Event_TeleportSpawnPost(entity)
{
	if(!MapStarted)
	{
		if(TeleportsArray == INVALID_HANDLE)
			TeleportsArray = CreateArray(1);
			
		PushArrayCell(TeleportsArray, EntIndexToEntRef(entity));
		return;
	}
	new bombReset = CreateEntityByName("trigger_bomb_reset");
	
	if(bombReset == -1)
		return;

	new String:Model[PLATFORM_MAX_PATH];
	
	GetEntPropString(entity, Prop_Data, "m_ModelName", Model, sizeof(Model));
	
	DispatchKeyValue(bombReset, "model", Model);
	DispatchKeyValue(bombReset, "targetname", "trigger_bomb_reset");
	DispatchKeyValue(bombReset, "StartDisabled", "0");
	DispatchKeyValue(bombReset, "spawnflags", "64");
	new Float:Origin[3], Float:Mins[3], Float:Maxs[3];

	GetEntPropVector(entity, Prop_Send, "m_vecMins", Mins);
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", Maxs);
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", Origin);
	
	TeleportEntity(bombReset, Origin, NULL_VECTOR, NULL_VECTOR);
	
	DispatchSpawn(bombReset);
	
	ActivateEntity(bombReset);
	
	SetEntPropVector(bombReset, Prop_Send, "m_vecMins", Mins);
	SetEntPropVector(bombReset, Prop_Send, "m_vecMaxs", Maxs);
	
	SetEntProp(bombReset, Prop_Send, "m_nSolidType", 1);
	SetEntProp(bombReset, Prop_Send, "m_usSolidFlags", 524);
	
	SetEntProp(bombReset, Prop_Send, "m_fEffects", GetEntProp(bombReset, Prop_Send, "m_fEffects") | 32);
	
	PushArrayCell(BombResetsArray, EntIndexToEntRef(bombReset));
	
	if(!GetConVarBool(hcv_ucTeleportBomb))
		AcceptEntityInput(bombReset, "Disable");
}


public OnConfigsExecuted()
{
	if(!isCSGO())
		return;
		
	SetConVarInt(hcv_mpAnyoneCanPickupC4, GetConVarInt(hcv_ucSpecialC4Rules));
	
	new Handle:keyValues = CreateKeyValues("items_game")
	
	if(!FileToKeyValues(keyValues, "scripts/items/items_game.txt"))
		return;
	
	if(!KvGotoFirstSubKey(keyValues))
		return;
	
	new WepNone = view_as<int>(CSWeapon_NONE);
	
	new String:buffer[64];
	while(KvGotoNextKey(keyValues))
	{
		KvGetSectionName(keyValues, buffer, sizeof(buffer));
	
		if(StrEqual(buffer, "prefabs"))
		{
			KvGotoFirstSubKey(keyValues);
			break;
		}
	}
	
	// Now we save position of prefabs and find all default values for damage, fire rate, and etc.
	
	KvSavePosition(keyValues);
	
	while(KvGotoNextKey(keyValues))
	{
		KvGetSectionName(keyValues, buffer, sizeof(buffer));
	
		if(StrEqual(buffer, "statted_item_base"))
		{
			KvGotoFirstSubKey(keyValues);
			break;
		}
	}
	
	while(KvGotoNextKey(keyValues))
	{
		KvGetSectionName(keyValues, buffer, sizeof(buffer));
	
		if(StrEqual(buffer, "attributes"))
		{
			KvGotoFirstSubKey(keyValues);
			break;
		}
	}
	
	// Default values.
	wepStatsList[WepNone][wepStatsFireRate] = RoundFloat((1.0 / KvGetFloat(keyValues, "cycletime", -1.0)) * 60.0); // By RPM = Rounds per Minute. Note: NEVER ALLOW DEFAULT VALUE 0.0 WHEN DIVIDING IT!!!
	wepStatsList[WepNone][wepStatsArmorPenetration] = KvGetFloat(keyValues, "armor ratio") * 50.0; // It maxes at 2.000 to be 100% armor penetration.
	wepStatsList[WepNone][wepStatsKillAward] = KvGetNum(keyValues, "kill award");
	wepStatsList[WepNone][wepStatsDamageDropoff] = RoundFloat(100.0 - KvGetFloat(keyValues, "range modifier") * 100.0);
	wepStatsList[WepNone][wepStatsMaxDamageRange] = KvGetNum(keyValues, "range");
	wepStatsList[WepNone][wepStatsPalletsPerShot] = KvGetNum(keyValues, "bullets");
	wepStatsList[WepNone][wepStatsDamage] = KvGetNum(keyValues, "damage");
	
	KvGoBack(keyValues);
	
	new String:CompareBuffer[64], String:Alias[20];
	while(KvGotoNextKey(keyValues))
	{
		KvGetSectionName(keyValues, buffer, sizeof(buffer));

		if(StrContains(buffer, "_prefab") != -1 && strncmp(buffer, "weapon_", 7) == 0)
		{
			new CSWeaponID:i
			for(i=CSWeapon_NONE;i < CSWeapon_MAX_WEAPONS_NO_KNIFES;i++) // Loop all weapons.
			{
				if(CS_IsValidWeaponID(i)) // I don't like using continue in two loops.
				{
					if(CS_WeaponIDToAlias(i, Alias, sizeof(Alias)) != 0) // iDunno...
					{
						Format(CompareBuffer, sizeof(CompareBuffer), "weapon_%s_prefab", Alias);
				
						if(StrEqual(buffer, CompareBuffer)) // We got a match!
						{
							KvSavePosition(keyValues); // Save our position.
							KvGotoFirstSubKey(keyValues);
							
							while(KvGotoNextKey(keyValues)) // Find them attributes.
							{
								KvGetSectionName(keyValues, buffer, sizeof(buffer)); // We can overwrite the last buffer we took, it's irrelevant now :D
	
								if(StrEqual(buffer, "attributes"))
								{
									KvGotoFirstSubKey(keyValues);
									break;
								}
							}
							
							wepStatsList[i][wepStatsFireRate] = RoundFloat((1.0 / KvGetFloat(keyValues, "cycletime", -1.0)) * 60.0); // By RPM = Rounds per Minute. Note: NEVER ALLOW DEFAULT VALUE 0.0 WHEN DIVIDING IT!!!
							
							if(wepStatsList[i][wepStatsFireRate] == -60)
								wepStatsList[i][wepStatsFireRate] = wepStatsList[WepNone][wepStatsFireRate];
							
							wepStatsList[i][wepStatsArmorPenetration] = KvGetFloat(keyValues, "armor ratio", -1.0) * 50.0; // It maxes at 2.000 to be 100% armor penetration.
							
							if(wepStatsList[i][wepStatsArmorPenetration] == -50.0)
								wepStatsList[i][wepStatsArmorPenetration] = wepStatsList[WepNone][wepStatsArmorPenetration];
								
							wepStatsList[i][wepStatsKillAward] = KvGetNum(keyValues, "kill award", wepStatsList[WepNone][wepStatsKillAward]); // It maxes at 2.000 to be 100% armor penetration.
							new Float:Range;
							wepStatsList[i][wepStatsDamageDropoff] = RoundFloat(100.0 - (Range=KvGetFloat(keyValues, "range modifier")) * 100.0);
							
							if(wepStatsList[i][wepStatsDamageDropoff] == 100.0)
							{
								wepStatsList[i][wepStatsDamageDropoff] = wepStatsList[WepNone][wepStatsDamageDropoff];
								Range = (100.0 - float(wepStatsList[i][wepStatsDamageDropoff])) / 100.0;
							}	
							wepStatsList[i][wepStatsMaxDamageRange] = KvGetNum(keyValues, "range", wepStatsList[WepNone][wepStatsMaxDamageRange]);
							wepStatsList[i][wepStatsPalletsPerShot] = KvGetNum(keyValues, "bullets", wepStatsList[WepNone][wepStatsPalletsPerShot]);
							wepStatsList[i][wepStatsDamage] = KvGetNum(keyValues, "damage", wepStatsList[WepNone][wepStatsDamage]) * wepStatsList[i][wepStatsPalletsPerShot];
							// Now we calculate one tap distance. 
							
							if(Range == 0 || Range == 1)
								Range = 0.0001; // Close to zero but nyeahhhh
								
							if(float(wepStatsList[i][wepStatsDamage]) * HEADSHOT_MULTIPLIER < 100.0) // IMPOSSIBLE!!!
								wepStatsList[i][wepStatsTapDistanceNoArmor] = 0; // -1 = impossible to 1 tap.
								
							else
								wepStatsList[i][wepStatsTapDistanceNoArmor] = RoundFloat(Logarithm((100.0 / (wepStatsList[i][wepStatsDamage] * HEADSHOT_MULTIPLIER)) , Range)*500.0);
							
							if(wepStatsList[i][wepStatsTapDistanceNoArmor] > wepStatsList[i][wepStatsMaxDamageRange])
								wepStatsList[i][wepStatsTapDistanceNoArmor] = wepStatsList[i][wepStatsMaxDamageRange];
								
							if(float(wepStatsList[i][wepStatsDamage]) * HEADSHOT_MULTIPLIER * (wepStatsList[i][wepStatsArmorPenetration] / 100.0) < 100.0) // IMPOSSIBLE!!!
								wepStatsList[i][wepStatsTapDistanceArmor] = 0; // -1 = impossible to 1 tap.
								
							else
								wepStatsList[i][wepStatsTapDistanceArmor] = RoundFloat(Logarithm((100.0 / (wepStatsList[i][wepStatsDamage] * HEADSHOT_MULTIPLIER * (wepStatsList[i][wepStatsArmorPenetration] / 100.0))) , Range)*500.0);
								
							if(wepStatsList[i][wepStatsTapDistanceArmor] > wepStatsList[i][wepStatsMaxDamageRange])
								wepStatsList[i][wepStatsTapDistanceArmor] = wepStatsList[i][wepStatsMaxDamageRange];
								
							KvGoBack(keyValues);
							i = CSWeapon_MAX_WEAPONS_NO_KNIFES; // Equivalent of break.
						}
					}
				}
			}
		}
	}

	
	CloseHandle(keyValues);
}
	
public OnSpecialC4RulesChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarString(hcv_mpAnyoneCanPickupC4, newValue);
}

public OnTeleportBombChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StringToInt(oldValue) == -1)
		return;
		
	new iValue = StringToInt(newValue);
	if(iValue == 1)
	{
		for(new i=0; i < GetArraySize(BombResetsArray);i++)
		{
			new entity = EntRefToEntIndex(GetArrayCell(BombResetsArray, i));
			
			if(entity == INVALID_ENT_REFERENCE)
			{
				RemoveFromArray(BombResetsArray, i--);
				continue;
			}
			
			AcceptEntityInput(entity, "Enable");
		}
	}
	else if(iValue == -1)
	{
		for(new i=0; i < GetArraySize(BombResetsArray);i++)
		{
			new entity = EntRefToEntIndex(GetArrayCell(BombResetsArray, i));
			
			if(entity == INVALID_ENT_REFERENCE)
			{
				RemoveFromArray(BombResetsArray, i--);
				continue;
			}
			
			AcceptEntityInput(entity, "Disable");
			AcceptEntityInput(entity, "Kill");
		}
		
		CloseHandle(BombResetsArray);
		BombResetsArray = INVALID_HANDLE;
	}
	else
	{
		for(new i=0; i < GetArraySize(BombResetsArray);i++)
		{
			new entity = EntRefToEntIndex(GetArrayCell(BombResetsArray, i));
			
			if(entity == INVALID_ENT_REFERENCE)
			{
				RemoveFromArray(BombResetsArray, i--);
				continue;
			}
			
			AcceptEntityInput(entity, "Disable");
		}
	}
}

public Action:CS_OnGetWeaponPrice(client, const String:weapon[], &price)
{
	if(StrEqual(weapon, "taser", true) && GetConVarInt(hcv_ucPartyMode) == 2)
	{
		price = 100;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if(!GetConVarBool(hcv_ucSpecialC4Rules))
		return Plugin_Continue;
		
	else if(!(buttons & IN_ATTACK) && !(buttons & IN_USE))
		return Plugin_Continue;
	
	else if(!GetEntProp(client, Prop_Send, "m_bInBombZone"))
		return Plugin_Continue;
		
	else if(GetClientTeam(client) != CS_TEAM_CT)
		return Plugin_Continue;
		
	new curWeapon;
	if((curWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")) == -1)
		return Plugin_Continue;
		
	new String:Classname[50];
	GetEdictClassname(curWeapon, Classname, sizeof(Classname));
	
	if(!StrEqual(Classname, "weapon_c4", true))
		return Plugin_Continue;
	
	buttons &= ~IN_ATTACK;
	buttons &= ~IN_USE;
	
	return Plugin_Changed;
}

/*
public Action:SoundHook_PartyMode(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags) // Fucking prediction...
{	
	if(!StrEqual(sample, PartySound))
		return Plugin_Continue;

	PrintToChatAll("b");
	new numClientsToUse = 0;
	new clientsToUse[64];
	
	for(new i=0;i < numClients;i++)
	{
		new client = clients[i];
		
		if(!IsClientInGame(client))
			continue;
			
		if(!GetClientPartyMode(client))
			continue;
		
		clientsToUse[numClientsToUse++] = client;
	}
	
	if(numClientsToUse != 0)
	{
		clients = clientsToUse;
		numClients = numClientsToUse;
		
		return Plugin_Changed;
	}
	
	return Plugin_Stop;
}
*/
public Action:Event_BombDefused(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{	
	if(!GetConVarBool(hcv_ucPartyMode))	
		return;
		
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	SetConVarBool(hcv_PartyMode, false);
	
	CreateDefuseBalloons(client);
	
	new Float:Origin[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", Origin);
	
	new clients[MaxClients];
	new total = 0;
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if(GetClientPartyMode(i) & PARTYMODE_DEFUSE)
			{
				clients[total++] = i;
			}
		}
	}
	
	if (!total)
	{
		return;
	}
	
	EmitSoundAny(clients, total, PartySound, client, 6, 79, _, 1.0, 100, _, Origin, _, _, _);
	
	
}

public Action:Event_WeaponFire(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{	
	if(!GetConVarBool(hcv_ucPartyMode))	
		return;
		
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		
	new String:WeaponName[50];
	GetEventString(hEvent, "weapon", WeaponName, sizeof(WeaponName));
	
	if(!StrEqual(WeaponName, "weapon_taser", true))
		return;
	
	SetConVarBool(hcv_PartyMode, false); // This will stop client prediction issues.
	
	new Float:Origin[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", Origin);
	
	new clients[MaxClients];
	new total = 0;
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if(GetClientPartyMode(i) & PARTYMODE_ZEUS)
			{
				clients[total++] = i;
			}
		}
	}
		
	if(total)
		EmitSoundAny(clients, total, PartySound, client, 6, 79, _, 1.0, 100, _, Origin, _, _, _);
		
	CreateZeusConfetti(client);

}

public Action:Event_PlayerUse(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	if(!GetConVarBool(hcv_ucUseBombPickup))
		return;
		
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(client == 0)
		return;
		
	else if(!IsPlayerAlive(client))
		return;
	
	new entity = GetEventInt(hEvent, "entity");
	
	if(!IsValidEntity(entity))
		return;
		
	new String:Classname[50];
	GetEntityClassname(entity, Classname, sizeof(Classname));
	
	if(!StrEqual(Classname, "weapon_c4", true))
		return;
		
	else if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") != -1)
		return;
		
	new Team = GetClientTeam(client);
	if(Team != CS_TEAM_T && !GetConVarBool(hcv_mpAnyoneCanPickupC4))
		return;
	
	AcceptEntityInput(entity, "Kill");
	
	if(GetClientTeam(client) == CS_TEAM_CT)
	{
		SetEntProp(client, Prop_Send, "m_iTeamNum", CS_TEAM_T);
				
		GivePlayerItem(client, "weapon_c4");
				
		SetEntProp(client, Prop_Send, "m_iTeamNum", CS_TEAM_CT);
	}
	else
		GivePlayerItem(client, "weapon_c4");
	
	/*
	
	for(new i=0;i < GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");i++)
	{
		new ent = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		
		if(!IsValidEntity(ent))
			continue;
			
		GetEdictClassname(ent, Classname, sizeof(Classname));
		
		if(StrEqual(Classname, "weapon_c4", true))
			return;
	}
	
	new Float:Origin[3];
	
	SetEntPropEnt(entity, Prop_Send, "m_hPrevOwner", -1);
	
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", Origin);
	
	TeleportEntity(entity, Origin, NULL_VECTOR, NULL_VECTOR);
	
	EmitSoundToAllAny(ItemPickUpSound, client, 3, 326, _, 0.5, 100, _, Origin, _, _, _);
	*/
	
}

public Action:Event_RoundEnd(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	if(isCSGO())
		return Plugin_Continue;
	
	else if(!BlockedWinPanel)	
		return Plugin_Continue;
		
		
	new WinningTeam = GetEventInt(hEvent, "winner");
	
	new Handle:hWinEvent = CreateEvent("cs_win_panel_round", true);
	
	SetEventBool(hWinEvent, "show_timer_defend", show_timer_defend);
	SetEventBool(hWinEvent, "show_timer_attack", show_timer_attack);
	SetEventInt(hWinEvent, "timer_time", timer_time);
	SetEventInt(hWinEvent, "final_event", final_event);
	
	SetEventString(hWinEvent, "funfact_token", funfact_token);
	
	SetEventInt(hWinEvent, "funfact_player", funfact_player);
	SetEventInt(hWinEvent, "funfact_data1", funfact_data1);
	SetEventInt(hWinEvent, "funfact_data2", funfact_data2);
	SetEventInt(hWinEvent, "funfact_data3", funfact_data3);
	
	SetEventInt(hWinEvent, "winner", WinningTeam);

	BlockedWinPanel = false;
	
	FireEvent(hWinEvent);
	
	return Plugin_Continue;
	
}
public Action:Event_RoundStart(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	// AceCandidate is -1 for nobody and -2 for disqualification.
	AceCandidate[CS_TEAM_CT] = -1;
	AceCandidate[CS_TEAM_T] = -1;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		TrueTeam[i] = 0;
	}
	AceSent = false;
	RoundNumber++;

	if(!isCSGO())
		return;
		
	new Chicken = -1;
	while((Chicken = FindEntityByClassname(Chicken, "Chicken")) != -1)
	{
		new String:TargetName[100];
		GetEntPropString(Chicken, Prop_Data, "m_iName", TargetName, sizeof(TargetName));
		
		if(StrContains(TargetName, "UsefulCommands_Chickens") != -1)
			AcceptEntityInput(Chicken, "Kill");
	}
	
	new Size = GetArraySize(ChickenOriginArray);
	
	new MaxChickens = GetConVarInt(hcv_ucMaxChickens);
	if(Size <= MaxChickens)
	{
		for(new i=0;i < Size;i++)
		{	
			new String:sOrigin[50];
			GetArrayString(ChickenOriginArray, i, sOrigin, sizeof(sOrigin));
	
			SpawnChicken(sOrigin);
		}
	}
	else
	{
		new Handle:TempChickenOriginArray = CloneArray(ChickenOriginArray);
		
		new String:sOrigin[50];
		new Count = 0;
		while(Count++ < MaxChickens)
		{
			new Winner = GetRandomInt(0, Size-1);
			GetArrayString(TempChickenOriginArray, Winner, sOrigin, sizeof(sOrigin));
	
			RemoveFromArray(TempChickenOriginArray, Winner);
			Size--;
			
			SpawnChicken(sOrigin);
		}
		CloseHandle(TempChickenOriginArray);
	}
}

public Action:Event_PlayerTeam(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		
	new OldTeam = GetEventInt(hEvent, "oldteam");
	
	if(OldTeam <= CS_TEAM_SPECTATOR)	
		return;
		
	TrueTeam[client] = OldTeam;
}

SpawnChicken(const String:sOrigin[])
{
	new Chicken = CreateEntityByName("chicken");
	
	new String:TargetName[100];
	Format(TargetName, sizeof(TargetName), "UsefulCommands_Chickens %s", sOrigin);
	SetEntPropString(Chicken, Prop_Data, "m_iName", TargetName);
	
	DispatchSpawn(Chicken);
	
	new Float:Origin[3];
	GetStringVector(sOrigin, Origin);
	TeleportEntity(Chicken, Origin, NULL_VECTOR, NULL_VECTOR);
	
	HookSingleEntityOutput(Chicken, "OnBreak", Event_ChickenKilled, true)
}

public Event_ChickenKilled(const String:output[], caller, activator, Float:delay)
{
	if(!IsValidEntity(caller))
		return;
		
	// Chicken is dead.
	
	new String:TargetName[100];
	GetEntPropString(caller, Prop_Data, "m_iName", TargetName, sizeof(TargetName));
	
	
	if(StrContains(TargetName, "UsefulCommands_Chickens") != -1)
	{
		ReplaceStringEx(TargetName, sizeof(TargetName), "UsefulCommands_Chickens ", "");
		
		new Handle:DP = CreateDataPack();
		
		WritePackCell(DP, RoundNumber);
		
		CreateTimer(GetRandomFloat(GetConVarFloat(hcv_ucMinChickenTime), GetConVarFloat(hcv_ucMaxChickenTime)), RespawnChicken, RoundNumber, TIMER_FLAG_NO_MAPCHANGE);
		
	}
}

public Action:RespawnChicken(Handle:hTimer, RoundNum)
{
	/*
	ResetPack(DP);
	
	new RoundNum = ReadPackCell(DP);
	
	*/
	if(RoundNum < RoundNumber)
		return Plugin_Continue;
	/*
	new String:sOrigin[50], Float:Origin[3];
	
	ReadPackString(DP, sOrigin, sizeof(sOrigin));
	
	CloseHandle(DP);
	*/
	
	ChickenOriginPosition++;
	
	if(ChickenOriginPosition >= GetArraySize(ChickenOriginArray))
		ChickenOriginPosition = 0;
		
	new String:sOrigin[50];
	GetArrayString(ChickenOriginArray, ChickenOriginPosition, sOrigin, sizeof(sOrigin));
	
	SpawnChicken(sOrigin);
	
	return Plugin_Continue;
}

/*
public Action:Event_OnChickenKilled(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(!IsValidEntity(victim))
		return Plugin_Continue;
		
	// Chicken is dead.
	
	new String:TargetName[100];
	GetEntPropString(victim, Prop_Data, "m_iName", TargetName, sizeof(TargetName));
	
	
	if(StrContains(TargetName, "UsefulCommands_Chickens") != -1)
	{
		ReplaceStringEx(TargetName, sizeof(TargetName), "UsefulCommands_Chickens ", "");
		
		new Float:Origin[3];
		GetStringVector(TargetName, Origin);
		
		SpawnChicken(Origin);
	}
	
	return Plugin_Continue;
}
*/
public PartyModeCookieMenu_Handler(client, CookieMenuAction:action, info, String:buffer[], maxlen)
{
	if(!GetConVarBool(hcv_ucPartyMode))	
	{
		ShowCookieMenu(client);
		PrintToChat(client, "Party mode is disabled by the server.");
		return;
	}	
	ShowPartyModeMenu(client);
} 
public ShowPartyModeMenu(client)
{
	new Handle:hMenu = CreateMenu(PartyModeMenu_Handler);
	
	switch(GetClientPartyMode(client))
	{
		case PARTYMODE_DEFUSE:
		{
			AddMenuItem(hMenu, "", "Party Mode: Defuse only");	
		}	
		
		case PARTYMODE_ZEUS:
		{
			AddMenuItem(hMenu, "", "Party Mode: Zeus only");
		}
		
		case PARTYMODE_DEFUSE|PARTYMODE_ZEUS:
		{
			AddMenuItem(hMenu, "", "Party Mode: Enabled");
		}
		
		default:
		{
			AddMenuItem(hMenu, "", "Party Mode: Disabled");	
		}
	}


	SetMenuExitBackButton(hMenu, true);
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, client, 30);
}


public PartyModeMenu_Handler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_DrawItem)
	{
		return ITEMDRAW_DEFAULT;
	}
	else if(item == MenuCancel_ExitBack)
	{
		ShowCookieMenu(client);
	}
	else if(action == MenuAction_Select)
	{
		if(item == 0)
		{
			if(GetClientPartyMode(client) >= PARTYMODE_DEFUSE|PARTYMODE_ZEUS)
				SetClientPartyMode(client, PARTYMODE_NONE);
				
			else if(GetClientPartyMode(client) == PARTYMODE_NONE)
				SetClientPartyMode(client, PARTYMODE_DEFUSE);
				
			else if(GetClientPartyMode(client) == PARTYMODE_DEFUSE)
				SetClientPartyMode(client, PARTYMODE_ZEUS);
				
			else if(GetClientPartyMode(client) == PARTYMODE_ZEUS)
				SetClientPartyMode(client, PARTYMODE_DEFUSE|PARTYMODE_ZEUS);
		}
	
		CloseHandle(hMenu);
		
		ShowPartyModeMenu(client);
	}
	return 0;
}


public Action:Event_PlayerSpawn(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	UberSlapped[client] = false;
	RequestFrame(ResetTrueTeam, GetClientUserId(client));
	if(TIMER_UBERSLAP[client] != INVALID_HANDLE)
	{
		CloseHandle(TIMER_UBERSLAP[client]);
		TIMER_UBERSLAP[client] = INVALID_HANDLE;
	}
	isHugged[client] = false;
	UC_TryDestroyGlow(client);
}

public ResetTrueTeam(UserId)
{
	TrueTeam[GetClientOfUserId(UserId)] = 0;
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{	
	new clientUserId = GetEventInt(hEvent, "userid");
	
	new client = GetClientOfUserId(clientUserId);

	if(client == 0)
		return;

	new attackerUserId = GetEventInt(hEvent, "attacker");
	new attacker = GetClientOfUserId(attackerUserId);
	
	new Team = GetClientTrueTeam(client);
	
	if(Team != CS_TEAM_CT && Team != CS_TEAM_T)
		return;
		
	new candidateCT = 0;
	
	if(AceCandidate[CS_TEAM_CT] > 0)
		candidateCT = GetClientOfUserId(AceCandidate[CS_TEAM_CT])
		
	new candidateT = 0;

	if(AceCandidate[CS_TEAM_T] > 0)
		candidateT = GetClientOfUserId(AceCandidate[CS_TEAM_T])

	
	if(attacker == 0)
	{
		if(candidateT > 0 && Team == CS_TEAM_CT)
			AceCandidate[CS_TEAM_T] = -2; // Forbid possibility of Ace for the attacker's team.
			
		if(candidateCT > 0 && Team == CS_TEAM_T)
			AceCandidate[CS_TEAM_CT] = -2; // Forbid possibility of Ace for the attacker's team.
	}
	else
	{
		new attackerTeam = GetClientTeam(attacker);
	
		if(candidateT != 0)
		{
			if(candidateT != attacker && Team == CS_TEAM_CT)
			{
				AceCandidate[CS_TEAM_T] = -2; // Forbid possibility of Ace for the attacker's team.
			}
		}
		else if(attackerTeam == CS_TEAM_T && AceCandidate[CS_TEAM_T] == -1)
			AceCandidate[CS_TEAM_T] = attackerUserId; // Ace Candidate is only fullfilled in case all opponents are dead at time of victory.
			
		if(candidateCT != 0)
		{
			if(candidateCT != attacker && Team == CS_TEAM_T)
				AceCandidate[CS_TEAM_CT] = -2; // Forbid possibility of Ace for the attacker's team.
		}
		else if(attackerTeam == CS_TEAM_CT && AceCandidate[CS_TEAM_CT] == -1)
			AceCandidate[CS_TEAM_CT] = attackerUserId; // Ace Candidate is only fullfilled in case all opponents are dead at time of victory.
	}		
	UberSlapped[client] = false;
	if(TIMER_UBERSLAP[client] != INVALID_HANDLE)
	{
		CloseHandle(TIMER_UBERSLAP[client]);
		TIMER_UBERSLAP[client] = INVALID_HANDLE;
	}
	if(TIMER_STUCK[client] != INVALID_HANDLE)
	{
		CloseHandle(TIMER_STUCK[client]);
		TIMER_STUCK[client] = INVALID_HANDLE;
	}
	if(TIMER_LASTC4[client] != INVALID_HANDLE)
	{
		CloseHandle(TIMER_LASTC4[client]);
		TIMER_LASTC4[client] = INVALID_HANDLE;
	}
	
	if(LastC4Ref[client] != INVALID_ENT_REFERENCE)
	{
		new LastC4 = EntRefToEntIndex(LastC4Ref[client]);
		
		if(LastC4 != INVALID_ENT_REFERENCE)
		{
			new String:Classname[50];
			GetEdictClassname(LastC4, Classname, sizeof(Classname));
			
			if(StrEqual(Classname, "weapon_c4", true))
			{
				new Winner = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
					
				if(!IsValidPlayer(Winner) || IsValidPlayer(Winner) && (client == Winner || GetClientTeam(Winner) != CS_TEAM_T) || !IsPlayerAlive(Winner))
					Winner = GetClientOfUserId(GetEventInt(hEvent, "assister"));
					
				if(!IsValidPlayer(Winner) || IsValidPlayer(Winner) && (client == Winner || GetClientTeam(Winner) != CS_TEAM_T) || !IsPlayerAlive(Winner))
				{
					new players[MaxClients+1], count;
					
					Winner = 0;
					for(new i=1;i <= MaxClients;i++)
					{
						if(i == client)
							continue;
							
						else if(!IsClientInGame(i))
							continue;
							
						else if(!IsPlayerAlive(i))
							continue;
							
						else if(GetClientTeam(i) != CS_TEAM_T)
							continue;
							
						
						players[count++] = i;
					}
					
					Winner = players[GetRandomInt(0, count-1)];
				}
				
				if(Winner != 0)
				{
					AcceptEntityInput(LastC4, "Kill");
	
					GivePlayerItem(Winner, "weapon_c4");
				}
			}
		}
		
		LastC4Ref[client] = INVALID_ENT_REFERENCE;
	}
	UC_TryDestroyGlow(client);
	
	TrueTeam[client] = 0;
}

public Action:Event_CsWinPanelRound(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	if(GetConVarInt(hcv_ucAcePriority) == 0)
		return Plugin_Continue;

	new WinningTeam = -1;
	if(isCSGO())
		WinningTeam = GameRules_GetProp("m_iRoundWinStatus");
	
	else
	{
		WinningTeam = GetEventInt(hEvent, "winner", -1);
		
		if(WinningTeam == -1)
		{	
			show_timer_defend = GetEventBool(hEvent, "show_timer_defend");
			show_timer_attack = GetEventBool(hEvent, "show_timer_attack");
			timer_time = GetEventInt(hEvent, "timer_time");
			final_event = GetEventInt(hEvent, "final_event");
			
			GetEventString(hEvent, "funfact_token", funfact_token, sizeof(funfact_token));
			funfact_player = GetEventInt(hEvent, "funfact_player");
			funfact_data1 = GetEventInt(hEvent, "funfact_data1");
			funfact_data2 = GetEventInt(hEvent, "funfact_data2");
			funfact_data3 = GetEventInt(hEvent, "funfact_data3");

			BlockedWinPanel = true;
			return Plugin_Handled;
		}
	}

	new Winner = GetClientOfUserId(AceCandidate[WinningTeam]);
	
	if(Winner == 0)
		return Plugin_Continue;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(!IsPlayerAlive(i))
			continue;
			
		if(GetClientTeam(i) != WinningTeam)
			return Plugin_Continue;
	}	
	
	Call_StartForward(fw_ucAce);
	
	new String:TokenToUse[100];
	GetClientAceFunFact(Winner, TokenToUse, sizeof(TokenToUse));
	Call_PushCellRef(Winner);
	Call_PushStringEx(TokenToUse, sizeof(TokenToUse), SM_PARAM_STRING_COPY|SM_PARAM_STRING_UTF8, SM_PARAM_COPYBACK);
	
	new Action:Result;
	Call_Finish(Result);
	
	if(Result >= Plugin_Changed)
		return Plugin_Continue;
	
	if(Result != Plugin_Changed)
	{
		Winner = GetClientOfUserId(AceCandidate[WinningTeam]);
		GetClientAceFunFact(Winner, TokenToUse, sizeof(TokenToUse));
	}
		
	SetEventInt(hEvent, "funfact_player", Winner);
	
	SetEventString(hEvent, "funfact_token", TokenToUse);
	
	if(isCSGO())
		SetEventInt(hEvent, "funfact_data1", 420); // The percent of players killed ( in theory always 100 in ace but !revive can push it further. )
	
	else
		SetEventInt(hEvent, "funfact_data1", 100); // The percent of players killed ( in theory always 100 in ace but !revive can push it further. )
	
	if(!AceSent)
	{
		AceSent = true;
		
		Call_StartForward(fw_ucAcePost);
		
		Call_PushCell(Winner);
		Call_PushString(TokenToUse);
		
		Call_Finish();
	}
	return Plugin_Changed;
}

public UsefulCommands_OnPlayerAcePost(client, const String:FunFact[])
{
	if(GetConVarInt(hcv_ucAcePriority) > 0)
		PrintToChatAll(" \x01Player\x03 %N\x01 scored an\x05 ACE.", client);
}

public OnClientPutInServer(client)
{
	DeathOrigin[client] = NULL_VECTOR;
	UberSlapped[client] = false;
	isHugged[client] = true;
	
	UCEdit[client] = false;
	FullInGame[client] = true;
	
	
	SDKHook(client, SDKHook_WeaponDropPost, Event_WeaponDropPost);
	SDKHook(client, SDKHook_WeaponEquipPost, Event_WeaponPickupPost);
	SDKHook(client, SDKHook_OnTakeDamagePost, Event_OnTakeDamagePost);
}

public Event_WeaponPickupPost(client, weapon)
{
	if(!GetConVarBool(hcv_ucSpecialC4Rules))
		return;
	
	else if(weapon == -1)
		return;
		
	new String:Classname[50];
	GetEdictClassname(weapon, Classname, sizeof(Classname));
	
	if(!StrEqual(Classname, "weapon_c4", true))
		return;
		
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(!IsPlayerAlive(i))
			continue;
			
		if(EntRefToEntIndex(LastC4Ref[i]) == weapon)
		{
			LastC4Ref[i] = INVALID_ENT_REFERENCE;
			
			if(TIMER_LASTC4[i] != INVALID_HANDLE)
			{
				CloseHandle(TIMER_LASTC4[i]);
				TIMER_LASTC4[i] = INVALID_HANDLE;
			}
		}
	}
	
	if(GetClientTeam(client) == CS_TEAM_CT)
		LastC4Ref[client] = EntIndexToEntRef(weapon);
}
public Event_WeaponDropPost(client, weapon)
{
	if(!GetConVarBool(hcv_ucSpecialC4Rules))
		return;
		
	else if(GetClientTeam(client) != CS_TEAM_CT)
		return;
	
	else if(weapon == -1)
		return;
		
	new String:Classname[50];
	GetEdictClassname(weapon, Classname, sizeof(Classname));
	
	if(!StrEqual(Classname, "weapon_c4", true))
		return;
		
	LastC4Ref[client] = EntIndexToEntRef(weapon);
	
	if(TIMER_LASTC4[client] != INVALID_HANDLE)
	{
		CloseHandle(TIMER_LASTC4[client]);
		TIMER_LASTC4[client] = INVALID_HANDLE;
	}	
	TIMER_LASTC4[client] = CreateTimer(5.0, GiveC4Back, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:GiveC4Back(Handle:hTimer, UserId)
{
	new client = GetClientOfUserId(UserId);
	
	if(client == 0)
		return;
	
	TIMER_LASTC4[client] = INVALID_HANDLE;
	
	if(LastC4Ref[client] == INVALID_ENT_REFERENCE)
		return;
	
	new LastC4 = EntRefToEntIndex(LastC4Ref[client]);
	
	if(!IsValidEntity(LastC4))
	{
		LastC4Ref[client] = INVALID_ENT_REFERENCE;
		return;
	}	
	
	
	AcceptEntityInput(LastC4, "Kill");
	
	GivePlayerItem(client, "weapon_c4");
	
	LastC4Ref[client] = INVALID_ENT_REFERENCE;
}

public Event_OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
	new Float:Scale = GetConVarFloat(hcv_TagScale);
	
	if(Scale == 1.0)
		return;
		
	new Float:TotalVelocity = GetEntPropFloat(victim, Prop_Send, "m_flVelocityModifier") * Scale;
	
	if(TotalVelocity > 1.0)
		TotalVelocity = 1.0;
		
	SetEntPropFloat(victim, Prop_Send, "m_flVelocityModifier", TotalVelocity);
	
	return;
}

public OnClientDisconnect(client)
{
	new candidateCT = 0;
	new candidateT = 0;
	
	if(AceCandidate[CS_TEAM_CT] > 0)
		candidateCT = GetClientOfUserId(AceCandidate[CS_TEAM_CT]);
		
	if(AceCandidate[CS_TEAM_T] > 0)
		candidateT = GetClientOfUserId(AceCandidate[CS_TEAM_T]);
		
	if(candidateT == client)
		AceCandidate[CS_TEAM_T] = -2; // Forbid possibility of Ace for the leaver's team.
	
	if(candidateCT == client)
		AceCandidate[CS_TEAM_CT] = -2; // Forbid possibility of Ace for the leaver's team.
		
	new String:AuthId[32];
	if(GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId)))
	{
        
		new String:sQuery[256];
		
		new String:Name[32], String:IPAddress[32], CurrentTime = GetTime();
		GetClientName(client, Name, sizeof(Name));
		GetClientIP(client, IPAddress, sizeof(IPAddress));
		Format(sQuery, sizeof(sQuery), "INSERT OR IGNORE INTO UsefulCommands_LastPlayers (AuthId, IPAddress, Name, LastConnect) VALUES (\"%s\", \"%s\", \"%s\", %i)", AuthId, IPAddress, Name, CurrentTime);
		SQL_TQuery(dbLocal, SQLCB_Error, sQuery, DBPrio_High);
		
		Format(sQuery, sizeof(sQuery), "UPDATE UsefulCommands_LastPlayers SET IPAddress = \"%s\", Name = \"%s\", LastConnect = %i WHERE AuthId = \"%s\"", IPAddress, Name, CurrentTime, AuthId);
		SQL_TQuery(dbLocal, SQLCB_Error, sQuery, DBPrio_Normal);
	}
}

public OnClientDisconnect_Post(client)
{
	FullInGame[client] = false;
	DeathOrigin[client] = NULL_VECTOR;
	if(TIMER_UBERSLAP[client] != INVALID_HANDLE)
	{
		CloseHandle(TIMER_UBERSLAP[client]);
		TIMER_UBERSLAP[client] = INVALID_HANDLE;
	}
	
	if(LastC4Ref[client] != INVALID_ENT_REFERENCE)
	{
		new LastC4 = EntRefToEntIndex(LastC4Ref[client]);
		
		if(LastC4 != INVALID_ENT_REFERENCE)
		{
			new String:Classname[50];
			GetEdictClassname(LastC4, Classname, sizeof(Classname));
			
			if(StrEqual(Classname, "weapon_c4", true))
			{
				new players[MaxClients+1], count, Winner = 0;
				
				for(new i=1;i <= MaxClients;i++)
				{
					if(!IsClientInGame(i))
						continue;
							
					else if(!IsPlayerAlive(i))
						continue;
							
					else if(GetClientTeam(i) != CS_TEAM_T)
						continue;
					
					players[count++] = i;
				}
					
				Winner = players[GetRandomInt(0, count-1)];
				
				if(Winner != 0)
				{
					AcceptEntityInput(LastC4, "Kill");
		
					GivePlayerItem(Winner, "weapon_c4");
				}
			}
		}
	}
	UberSlapped[client] = false;
	isHugged[client] = true;
	UC_TryDestroyGlow(client);
	UC_SetClientRocket(client, false);
}

public OnPluginEnd()
{
	for(new i=1;i < MAXPLAYERS+1;i++)
	{
		UC_TryDestroyGlow(i);
	}
}

public OnMapEnd()
{
	MapStarted = false;

	if(BombResetsArray != INVALID_HANDLE)
	{
		CloseHandle(BombResetsArray);
		BombResetsArray = INVALID_HANDLE;
	}
}

public OnEntityCreated(entity, const String:Classname[])
{
	if(StrEqual(Classname, "trigger_teleport", true))
		SDKHook(entity, SDKHook_SpawnPost, Event_TeleportSpawnPost);
}

public OnMapStart()
{

	RoundNumber++;
	GetCurrentMap(MapName, sizeof(MapName));
	
	if(isCSGO())
	{
		PrecacheModel("models/chicken/chicken.mdl");
		MapStarted = true;
		
		if(BombResetsArray != INVALID_HANDLE)
		{
			CloseHandle(BombResetsArray);
			BombResetsArray = INVALID_HANDLE;
		}

		BombResetsArray = CreateArray(1);
		
		if(ChickenOriginArray != INVALID_HANDLE)
		{
			CloseHandle(ChickenOriginArray);
			ChickenOriginArray = INVALID_HANDLE;
		}
		ChickenOriginArray = CreateArray(50);
		
		if(TeleportsArray != INVALID_HANDLE)
		{
			for(new i=0; i < GetArraySize(TeleportsArray);i++)
			{
				new entity = EntRefToEntIndex(GetArrayCell(TeleportsArray, i));
				
				if(entity == INVALID_ENT_REFERENCE)
				{
					RemoveFromArray(TeleportsArray, i--);
					continue;
				}
					
				Event_TeleportSpawnPost(entity);
			}
			
			CloseHandle(TeleportsArray);
		
			TeleportsArray = INVALID_HANDLE;
		}
		PrecacheSoundAny(PartySound);
	
		PrecacheSoundAny(ItemPickUpSound);
	}
	
	ConnectToDatabase();
	
	for(new i=1;i < MAXPLAYERS+1;i++)
	{
		TIMER_UBERSLAP[i] = INVALID_HANDLE;
		TIMER_STUCK[i] = INVALID_HANDLE;
		TIMER_LIFTOFF[i] = INVALID_HANDLE;
		TIMER_ROCKETCHECK[i] = INVALID_HANDLE;
	}
	
	hRestartTimer = INVALID_HANDLE;
	Restart = false;
	
}

public OnGameFrame()
{
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(!IsPlayerAlive(i))
			continue;
			
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", DeathOrigin[i]);	
	}
}

public Action:Command_Revive(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_revive <#userid|name>");
		return Plugin_Handled;
	}

	new String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients], target_count, bool:tn_is_ml;

	target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MaxClients,
					COMMAND_FILTER_NONE,
					target_name,
					sizeof(target_name),
					tn_is_ml);


	if(target_count <= COMMAND_TARGET_NONE) 	// If we don't have dead players
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for(new i=0;i < target_count;i++)
	{
		new target = target_list[i];
		
		ShowActivity2(client, "[SM] ", "Respawned %N.", target); 
		
		UC_RespawnPlayer(target);
	}
	
	return Plugin_Handled;
}

public Action:Command_HardRevive(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_hrevive <#userid|name>");
		return Plugin_Handled;
	}

	new String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients], target_count, bool:tn_is_ml;

	target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MaxClients,
					COMMAND_FILTER_NONE,
					target_name,
					sizeof(target_name),
					tn_is_ml);


	if(target_count <= COMMAND_TARGET_NONE) 	// If we don't have dead players
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for(new i=0;i < target_count;i++)
	{
		new target = target_list[i];
		
		new bool:isAlive = IsPlayerAlive(target); // Was he alive before the 1up?
		
		UC_RespawnPlayer(target);
		
		if(!UC_IsNullVector(DeathOrigin[target]) && !isAlive)
		{
		
			ShowActivity2(client, "[SM] ", "Respawned %N at last death position.", target); 
			TeleportEntity(target, DeathOrigin[target], NULL_VECTOR, NULL_VECTOR);
		}
		else
		{
			ShowActivity2(client, "[SM] ", "Respawned %N.", target); 
		}
	}
	
	return Plugin_Handled;
}


public Action:Command_Bury(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_bury <#userid|name> [1/0]");
		return Plugin_Handled;
	}

	new String:arg[65], String:arg2[5];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));

	if(StrEqual(arg2, ""))
		arg2 = "1";
		
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients], target_count, bool:tn_is_ml;

	target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MaxClients,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml);


	if(target_count <= COMMAND_TARGET_NONE)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new bool:bury = (StringToInt(arg2) != 0);
	
	for(new i=0;i < target_count;i++)
	{
		new target = target_list[i];
		
		if(bury)
		{
			if(IsPlayerStuck(target))
			{
				ReplyToCommand(client, "%N is already buried!", target);
				continue;
			}	
			UC_BuryPlayer(target);
			ShowActivity2(client, "[SM] ", "buried %N.", target); 
		}
		else
		{
			if(!IsPlayerStuck(target))
			{
				ReplyToCommand(client, "%N is not buried!", target);
				continue;
			}
			ShowActivity2(client, "[SM] ", "unburied %N.", target); 
			UC_UnburyPlayer(target);
		}
	}
	return Plugin_Handled;
}

public Action:Command_Unbury(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unbury <#userid|name>");
		return Plugin_Handled;
	}

	new String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
		
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients], target_count, bool:tn_is_ml;

	target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MaxClients,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml);


	if(target_count <= COMMAND_TARGET_NONE)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;

	}
	for(new i=0;i < target_count;i++)
	{
		new target = target_list[i];
		
		if(!IsPlayerStuck(target))
		{
			ReplyToCommand(client, "%N is not buried!", target);
			continue;
		}
		ShowActivity2(client, "[SM] ", "unburied %N.", target); 
		UC_UnburyPlayer(target);
	}
	return Plugin_Handled;
}
public Action:Command_UberSlap(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_uberslap <#userid|name> [1/0]");
		return Plugin_Handled;
	}

	new String:arg[65], String:arg2[5];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));

	if(StrEqual(arg2, ""))
		arg2 = "1";
		
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients], target_count, bool:tn_is_ml;

	target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MaxClients,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml);


	if(target_count <= COMMAND_TARGET_NONE)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new bool:slap = (StringToInt(arg2) != 0);
	
	for(new i=0;i < target_count;i++)
	{
		new target = target_list[i];
		
		if(slap)
		{
			if(UberSlapped[target])
			{
				ReplyToCommand(client, "%N is already being uberslapped. Use sm_uberslap <target> 0 to stop uberslap.", target);
				continue;
			}
			UberSlapped[target] = true;
			TotalSlaps[target] = 0;
			
			TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, Float:{0.0, 0.0, 10.0});
			TriggerTimer(TIMER_UBERSLAP[target] = CreateTimer(0.1, Timer_UberSlap, GetClientUserId(target), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE), true);
			
			ShowActivity2(client, "[SM] ", "uberslapping %N", target);
		}
		else
		{
			if(!UberSlapped[target])
			{
				ReplyToCommand(client, "%N is not being uberslapped.", target);
				continue;
			}
			UberSlapped[target] = false;
			if(TIMER_UBERSLAP[target] != INVALID_HANDLE)
			{
				CloseHandle(TIMER_UBERSLAP[target]);
				TIMER_UBERSLAP[target] = INVALID_HANDLE;
			}
			
			ShowActivity2(client, "[SM] ", "stopped uberslap on %N.", target); 
		}
	}
	return Plugin_Handled;
}

public Action:Timer_UberSlap(Handle:hTimer, UserId)
{
	new client = GetClientOfUserId(UserId);
	
	if(client == 0)
	{
		TIMER_UBERSLAP[client] = INVALID_HANDLE;
		UberSlapped[client] = false;
		return Plugin_Stop;
	}
	else if(!UberSlapped[client])
	{
		TIMER_UBERSLAP[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	UC_UnlethalSlap(client, 1);
	TotalSlaps[client]++;
	if(TotalSlaps[client] == 100)
	{
		UberSlapped[client] = false;
		TIMER_UBERSLAP[client] = INVALID_HANDLE;
		PrintToChat(client, "[SM] Uberslap has ended. Prepare your landing!");
		return Plugin_Stop;
	}

	return Plugin_Continue;
}


public Action:Command_Heal(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_heal <#userid|name> [health] [vest] [helmet:1/0]");
		ReplyToCommand(client, "[SM] Note: Use \"max\" to fully heal. Use letters to ignore values.");
		return Plugin_Handled;
	}

	new String:arg[65], String:arg2[11], String:arg3[11], String:arg4[3];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	GetCmdArg(4, arg4, sizeof(arg4));
	StripQuotes(arg2);
		
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients], target_count, bool:tn_is_ml;

	target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MaxClients,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml);


	if(target_count <= COMMAND_TARGET_NONE)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new health = IsStringNumber(arg2) ? StringToInt(arg2) : -1;
	
	if(health > 65535)
		health = 65535;
		
	new armor = IsStringNumber(arg3) ? StringToInt(arg3) : -1;
	
	if(armor > 255)
		armor = 255;
		
	new helmet = IsStringNumber(arg4) ? StringToInt(arg4) : -1;
	
	new String:ActivityBuffer[256];
	
	if(helmet > 2) // The helmet will never be a negative.
		helmet = -1;

	new bool:bHelmet = view_as<bool>(helmet);
	for(new i=0;i < target_count;i++)
	{
		new target = target_list[i];
		
		if(StrEqual(arg2, "max"))
			health = GetEntProp(target, Prop_Data, "m_iMaxHealth");
		
		Format(ActivityBuffer, sizeof(ActivityBuffer), "set %N's", target);
		if(health != -1)
		{
			SetEntityHealth(target, health);
			Format(ActivityBuffer, sizeof(ActivityBuffer), "%s health to %i, ", ActivityBuffer, health);
		}
		if(armor != -1)
		{
			SetClientArmor(target, armor);
			
			Format(ActivityBuffer, sizeof(ActivityBuffer), "%s armor to %i, ", ActivityBuffer, armor);
		}
		if(helmet != -1)
		{
			SetClientHelmet(target, bHelmet);
			
			Format(ActivityBuffer, sizeof(ActivityBuffer), "%s helmet to %i, ", ActivityBuffer, helmet);
		}
		
		new length = strlen(ActivityBuffer);
		ActivityBuffer[length-2] = '.';
		ActivityBuffer[length-1] = EOS;
		ShowActivity2(client, "[SM] ", ActivityBuffer); 
	}
	return Plugin_Handled;
}

public Action:Command_Give(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_give <#userid|name> <weapon_knife>");
		return Plugin_Handled;
	}

	new String:arg[65], String:arg2[65];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients], target_count, bool:tn_is_ml;

	target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MaxClients,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml);


	if(target_count <= COMMAND_TARGET_NONE)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new String:WeaponName[65];
	
	if(StrContains(arg2, "weapon_", false) == -1)
	{
		Format(WeaponName, sizeof(WeaponName), "weapon_%s", arg2);
		Format(arg2, sizeof(arg2), WeaponName);
	}
	else
		Format(WeaponName, sizeof(WeaponName), arg2);
	
	for(new a=0;a < strlen(WeaponName);a++)
	{
		WeaponName[a] = CharToLower(WeaponName[a]);
		
		if(WeaponName[a] == '_')
		{
			new String:TempWeaponName[65];
			Format(TempWeaponName, a+2, WeaponName);
			ReplaceStringEx(WeaponName, sizeof(WeaponName), TempWeaponName, "");
			break;
		}
	}
	
	ReplaceString(arg2, sizeof(arg2), "zeus", "taser");
	ReplaceString(WeaponName, sizeof(WeaponName), "zeus", "taser");
	
	ReplaceString(arg2, sizeof(arg2), "bomb", "c4");
	ReplaceString(WeaponName, sizeof(WeaponName), "bomb", "c4");
	
	new weapon = -1;
	
	for(new count=0;count < target_count;count++)
	{
		new target = target_list[count];
		

		if(StrEqual(arg2, "weapon_c4"))
		{
			if(GetClientTeam(target) == CS_TEAM_CT)
			{
				SetEntProp(target, Prop_Send, "m_iTeamNum", CS_TEAM_T);
				
				weapon = GivePlayerItem(target, arg2);
				
				SetEntProp(target, Prop_Send, "m_iTeamNum", CS_TEAM_CT);
			}
			else
				weapon = GivePlayerItem(target, arg2);
		}
		else if(StrEqual(arg2, "weapon_defuser"))
		{
			arg2 = "item_defuser";
			
			weapon = -1;
		}
		else if((weapon = GivePlayerItem(target, arg2)) == -1)
		{
			ReplyToCommand(client, "[SM] Weapon %s does not exist.", WeaponName);
			
			RemovePlayerItem(target, weapon);
			
			return Plugin_Handled;
		}
		
		if(weapon != -1)
		{
			RemovePlayerItem(target, weapon);
			
			AcceptEntityInput(weapon, "Kill");
		}
		weapon = CreateEntityByName("game_player_equip");
	
		DispatchKeyValue(weapon, arg2, "1");
		
		DispatchKeyValue(weapon, "spawnflags", "1");
		
		AcceptEntityInput(weapon, "use", target);
		
		AcceptEntityInput(weapon, "Kill");
		
		weapon = -1;
		ShowActivity2(client, "[SM] ", "gave weapon %s to %N.", WeaponName, target); 
		
	}

	return Plugin_Handled;
}

public Action:Command_RestartRound(client, args)
{
	ServerCommand("mp_restartgame 1");
	
	PrintToChatAll(" \x01Admin\x03 %N\x01 has\x04 restarted\x01 the round!", client);
	
	return Plugin_Handled;
}

public Action:Command_RestartServer(client, args)
{
	if(!Restart)
	{
		hRestartTimer = CreateTimer(5.0, RestartServer, _, TIMER_FLAG_NO_MAPCHANGE);
		PrintToChatAll(" \x01Admin\x03 %N\x01 will \x04restart\x01 server in 5 seconds!", client);
	}
	else
	{
		if(hRestartTimer != INVALID_HANDLE)
		{
			CloseHandle(hRestartTimer);
			hRestartTimer = INVALID_HANDLE;
		}
		PrintToChatAll(" \x01Admin\x03 %N\x01 has \x04stopped\x01 the server restart!", client);
	}
	Restart = !Restart;
	
	return Plugin_Handled;
}

public Action:RestartServer(Handle:hTimer)
{
	hRestartTimer = INVALID_HANDLE;	
	
	ServerCommand("changelevel \"%s\"", MapName);

}

public Action:Command_Glow(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_glow <#userid|name> [color/off]");
		return Plugin_Handled;
	}
	new String:arg[65], String:arg2[50];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));

	if(StrEqual(arg2, "color", false) || StrEqual(arg2, "colors", false))
	{
		ReplyToCommand(client, "[SM] Check your console for a list of valid colors.");
		
		for(new i=0;i < sizeof(GlowData);i++)
		{
			new bool:isWhite = StrEqual(GlowData[i][GlowName], "White", false);
			if(!isWhite || (isWhite && isCSGO()))
				PrintToConsole(client, GlowData[i][GlowName]);
		}
		return Plugin_Handled;
	}
	new Color[3];
	
	if(StrEqual(arg2, ""))
	{
		if(isCSGO())
			Format(arg2, sizeof(arg2), GlowData[GetRandomInt(0, sizeof(GlowData)-1)][GlowName]);
			
		else
			Format(arg2, sizeof(arg2), GlowData[GetRandomInt(0, sizeof(GlowData)-2)][GlowName]);
	}
	
	new bool:glow = (!StrEqual(arg2, "off", false));
	
	if(glow)
	{
		for(new i=0;i < sizeof(GlowData);i++)
		{
			new bool:isWhite = StrEqual(GlowData[i][GlowName], "White", false);
			if(StrEqual(arg2, GlowData[i][GlowName], false) && (!isWhite || (isWhite && isCSGO())))
			{
				Color[0] = GlowData[i][GlowColorR];
				Color[1] = GlowData[i][GlowColorG];
				Color[2] = GlowData[i][GlowColorB];
				break;
			}
			else if(i == sizeof(GlowData)-1)
			{
				ReplyToCommand(client, "[SM] Glow color is invalid.");
				return Plugin_Handled;
			}
		}
	}
		
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients], target_count, bool:tn_is_ml;

	target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MaxClients,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml);


	if(target_count <= COMMAND_TARGET_NONE)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for(new i=0;i < target_count;i++)
	{
		new target = target_list[i];
		
		if(glow)
		{
			UC_TryDestroyGlow(target);
			

			if(!UC_CreateGlow(target, Color))
			{
				ReplyToCommand(client, "[SM] Couldn't create glow on %N", target);
				continue;
			}
			
			ShowActivity2(client, "[SM] ", "enabled glow on %N.", target); 
		}
		else
		{
			if(ClientGlow[target] == 0)
			{
				ReplyToCommand(client, "%N doesn't have glow.", target);
				continue;
			}	
			
			UC_TryDestroyGlow(target);
			
			ShowActivity2(client, "[SM] ", "disabled glow on %N.", target); 
			
		}
		
	}
	return Plugin_Handled;
}

public Action:Command_Blink(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_blink <#userid|name>");
		return Plugin_Handled;
	}

	new String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients], target_count, bool:tn_is_ml;

	target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MaxClients,
					COMMAND_FILTER_NONE,
					target_name,
					sizeof(target_name),
					tn_is_ml);


	if(target_count <= COMMAND_TARGET_NONE) 	// If we don't have dead players
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for(new i=0;i < target_count;i++)
	{
		new target = target_list[i];
		
		new Float:Origin[3];
		UC_GetAimPositionBySize(client, target, Origin);
		
		TeleportEntity(target, Origin, NULL_VECTOR, NULL_VECTOR);
		
		ShowActivity2(client, "[SM] ", "teleported %N to aim position.", target); 
	}
	
	return Plugin_Handled;
}

public Action:Command_Godmode(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_god <#userid|name> [1/0]");
		return Plugin_Handled;
	}

	new String:arg[65], String:arg2[5];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));

	if(StrEqual(arg2, ""))
		arg2 = "1";
		
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients], target_count, bool:tn_is_ml;

	target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MaxClients,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml);


	if(target_count <= COMMAND_TARGET_NONE)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new bool:god = (StringToInt(arg2) != 0);
	
	for(new i=0;i < target_count;i++)
	{
		new target = target_list[i];
		
		if(god)
		{
			if(UC_GetClientGodmode(target))
			{
				ReplyToCommand(client, "%N is already godmode. Use !god <target> 0 to disable.", target);
				continue;
			}

			UC_SetClientGodmode(target, true);
			
			ShowActivity2(client, "[SM] ", "enabled godmode on %N.", target); 
		}
		else
		{
			if(!UC_GetClientGodmode(target))
			{
				ReplyToCommand(client, "%N is not godmode.", target);
				continue;
			}
			
			UC_SetClientGodmode(target, false);
			ShowActivity2(client, "[SM] ", "disabled godmode on %N.", target); 
		}
	}
	return Plugin_Handled;
}

public Action:Command_Rocket(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_rocket <#userid|name> [1/0]");
		return Plugin_Handled;
	}

	new String:arg[65], String:arg2[65];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));

	if(StrEqual(arg2, ""))
		arg2 = "1";
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients], target_count, bool:tn_is_ml;

	target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MaxClients,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml);


	if(target_count <= COMMAND_TARGET_NONE) 	// If we don't have dead players
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new bool:rocket = (StringToInt(arg2) != 0);
	
	for(new i=0;i < target_count;i++)
	{
		new target = target_list[i];
		
		ShowActivity2(client, "[SM] ", "Set rocket on %N.", target); 
		
		UC_SetClientRocket(target, rocket);
	}
	
	return Plugin_Handled;
}


public Action:Command_Disarm(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_disarm <#userid|name>");
		return Plugin_Handled;
	}

	new String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients], target_count, bool:tn_is_ml;

	target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MaxClients,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml);


	if(target_count <= COMMAND_TARGET_NONE) 	// If we don't have dead players
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for(new i=0;i < target_count;i++)
	{
		new target = target_list[i];
		
		ShowActivity2(client, "[SM] ", "stripped %N's weapons.", target); 
		
		UC_StripPlayerWeapons(target);
	}
	
	return Plugin_Handled;
}


/*
public Action:Command_Cheat(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_cheat <command>");
		return Plugin_Handled;
	}

	new String:arg[100];
	GetCmdArgString(arg, sizeof(arg));
	StripQuotes(arg);

	UC_CheatCommand(client, arg);
	
	return Plugin_Handled;
}
*/
public Action:Command_Last(client, args)
{
	SQL_TQuery(dbLocal, SQLCB_LastConnected, "SELECT * FROM UsefulCommands_LastPlayers ORDER BY LastConnect DESC", GetClientUserId(client)); 
	
	return Plugin_Handled;
}


public Action:Command_Exec(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_exec <#userid|name> <command>");
		return Plugin_Handled;
	}

	new String:arg[65], String:ExecCommand[150];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArgString(ExecCommand, sizeof(ExecCommand));
	StripQuotes(ExecCommand);
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients], target_count, bool:tn_is_ml;
	
	target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MaxClients,
					0,
					target_name,
					sizeof(target_name),
					tn_is_ml);

					
	Format(arg, sizeof(arg), "%s ", arg); // This nullifies the use of arg any longer.
	ReplaceStringEx(ExecCommand, sizeof(ExecCommand), arg, "");

	if(target_count <= COMMAND_TARGET_NONE) 	// If we don't have dead players
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for(new i=0;i < target_count;i++)
	{
		new target = target_list[i];
		
		ShowActivity2(client, "[SM] ", "Executed \"%s\" on %N.", ExecCommand, target); 
		LogAction(client, target, "\"%L\" executed \"%s\" on \"%N\"", client, ExecCommand, target);

		ClientCommand(target, ExecCommand);
	}
	
	return Plugin_Handled;
}


public Action:Command_FakeExec(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fakeexec <#userid|name> <command>");
		return Plugin_Handled;
	}

	new String:arg[65], String:ExecCommand[150];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArgString(ExecCommand, sizeof(ExecCommand));
	StripQuotes(ExecCommand);
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients], target_count, bool:tn_is_ml;
	
	target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MaxClients,
					0,
					target_name,
					sizeof(target_name),
					tn_is_ml);

					
	Format(arg, sizeof(arg), "%s ", arg); // This nullifies the use of arg any longer.
	ReplaceStringEx(ExecCommand, sizeof(ExecCommand), arg, "");

	if(target_count <= COMMAND_TARGET_NONE) 	// If we don't have dead players
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for(new i=0;i < target_count;i++)
	{
		new target = target_list[i];
		
		ShowActivity2(client, "[SM] ", "Executed \"%s\" on %N.", ExecCommand, target); 
		LogAction(client, target, "\"%L\" executed \"%s\" on \"%N\"", client, ExecCommand, target);
		
		FakeClientCommand(target, ExecCommand);
	}
	
	return Plugin_Handled;
}

public Action:Command_BruteExec(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_bruteexec <#userid|name> <command>");
		return Plugin_Handled;
	}

	new String:arg[65], String:ExecCommand[150];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArgString(ExecCommand, sizeof(ExecCommand));
	StripQuotes(ExecCommand);
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients], target_count, bool:tn_is_ml;
	
	target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MaxClients,
					0,
					target_name,
					sizeof(target_name),
					tn_is_ml);

					
	Format(arg, sizeof(arg), "%s ", arg); // This nullifies the use of arg any longer.
	ReplaceStringEx(ExecCommand, sizeof(ExecCommand), arg, "");

	if(target_count <= COMMAND_TARGET_NONE) 	// If we don't have dead players
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new bitsToGive = ADMFLAG_ROOT;
	
	if(client != 0)
		bitsToGive = GetUserFlagBits(client);
	
	for(new i=0;i < target_count;i++)
	{
		new target = target_list[i];
		
		ShowActivity2(client, "[SM] ", "Brutally Executed \"%s\" on %N.", ExecCommand, target); 
		LogAction(client, target, "\"%L\" Brutally Executed \"%s\" on \"%N\"", client, ExecCommand, target);
		
		new bits = GetUserFlagBits(target);
		
		SetUserFlagBits(target, bitsToGive);
		FakeClientCommand(target, ExecCommand);
		SetUserFlagBits(target, bits);
	}
	
	return Plugin_Handled;
}


public Action:Command_UCEdit(client, args)
{
	UCEdit[client] = !UCEdit[client];
	
	new Chicken = -1;
	if(UCEdit[client])
	{
		while((Chicken = FindEntityByClassname(Chicken, "Chicken")) != -1)
			AcceptEntityInput(Chicken, "Kill");
			
		for(new i=0;i < GetArraySize(ChickenOriginArray);i++)
		{
			new String:sOrigin[50];
			GetArrayString(ChickenOriginArray, i, sOrigin, sizeof(sOrigin));
			
			SpawnChicken(sOrigin);
		}
	}

	while((Chicken = FindEntityByClassname(Chicken, "Chicken")) != -1)
	{			
		if(UCEdit[client])
		{
			SetEntProp(Chicken, Prop_Send, "m_bShouldGlow", true, true);
			SetEntProp(Chicken, Prop_Send, "m_nGlowStyle", GLOW_FULLBODY);
			SetEntPropFloat(Chicken, Prop_Send, "m_flGlowMaxDist", 10000.0);
			SetEntityMoveType(Chicken, MOVETYPE_NONE);
		}
		else
		{
			SetEntProp(Chicken, Prop_Send, "m_bShouldGlow", false, true);
			SetEntityMoveType(Chicken, MOVETYPE_FLYGRAVITY);
		}
		
		new VariantColor[4] = {255, 255, 255, 255};
			
		SetVariantColor(VariantColor);
		AcceptEntityInput(Chicken, "SetGlowColor");
	}
	PrintToChat(client, " \x01You have\x05 %sabled\x01 the UC editor.", UCEdit[client] ? "En" : "Dis");
	
	if(UCEdit[client])
		PrintToChat(client, " \x01UC Editor will make all chickens glow and deleting will teleport you to the location.");
		
	Command_Chicken(client, 0);
	
	return Plugin_Handled;
}

public Action:Command_Chicken(client, args)
{

	new Handle:hMenu = CreateMenu(ChickenMenu_Handler);
	
	AddMenuItem(hMenu, "", "Create Chicken Spawner");	
	AddMenuItem(hMenu, "", "Delete Chicken Spawner");
	
	if(UCEdit[client])
		AddMenuItem(hMenu, "", "Delete Spawner On Aim");
	
	SetMenuTitle(hMenu, "Create at 64 units distance from each other and walls");
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}


public ChickenMenu_Handler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
		
	else if(action == MenuAction_Select)
	{
		switch(item)
		{
			case 0:
			{
				CreateChickenSpawn(client);		
				
				Command_Chicken(client, 0);
			}
			
			case 1:
			{
				SetupDeleteChickenSpawnMenu(client);
			}
			
			case 2:
			{
				Command_Chicken(client, 0);
				
				new Chicken = GetClientAimTarget(client, false);
				
				if(Chicken == -1)
				{
					PrintToChat(client, "\x01 Could not find a chicken spawner at aim.");
					return;
				}
				
				new String:Classname[50];
				GetEdictClassname(Chicken, Classname, sizeof(Classname));
				
				if(!StrEqual(Classname, "Chicken", false))
				{
					PrintToChat(client, "\x01 Could not find a chicken spawner at aim.");
					return;
				}
				
				new String:TargetName[100];
				GetEntPropString(Chicken, Prop_Data, "m_iName", TargetName, sizeof(TargetName));
				
				if(StrContains(TargetName, "UsefulCommands_Chickens") == -1)
				{
					PrintToChat(client, "\x01 Could not find a chicken spawner at aim.");
					return;
				}
				
				ReplaceStringEx(TargetName, sizeof(TargetName), "UsefulCommands_Chickens ", "");
				
				new String:sQuery[256];
				
				PrintToChat(client, TargetName);
				Format(sQuery, sizeof(sQuery), "DELETE FROM UsefulCommands_Chickens WHERE ChickenOrigin = \"%s\" AND ChickenMap = \"%s\"", TargetName, MapName);
				SQL_TQuery(dbLocal, SQLCB_Error, sQuery);
				
				new Pos = FindStringInArray(ChickenOriginArray, TargetName);
				if(Pos != -1)
					RemoveFromArray(ChickenOriginArray, Pos);
					
				AcceptEntityInput(Chicken, "Kill");
			}
		}
	}
}


SetupDeleteChickenSpawnMenu(client)
{
	new String:sQuery[256];
	Format(sQuery, sizeof(sQuery), "SELECT * FROM UsefulCommands_Chickens WHERE ChickenMap = \"%s\" ORDER BY ChickenCreateDate DESC", MapName);
	SQL_TQuery(dbLocal, SQLCB_DeleteChickenSpawnMenu, sQuery, GetClientUserId(client));
}
public SQLCB_DeleteChickenSpawnMenu(Handle:db, Handle:hndl, const String:sError[], data)
{
	if(hndl == null)
		ThrowError(sError);
	
	new client = GetClientOfUserId(data);
	
	if(client == 0)
		return;
	
	else if(SQL_GetRowCount(hndl) == 0)
	{
		PrintToChat(client, " \x01This map doesn't have chicken spawners.");
		return;
	}
	
	new Handle:hMenu = CreateMenu(DeleteChickenSpawnMenu_Handler);
	
	while(SQL_FetchRow(hndl))
	{
		new String:sOrigin[50];
		SQL_FetchString(hndl, 0, sOrigin, sizeof(sOrigin));
		
		AddMenuItem(hMenu, "", sOrigin);
	}
	
	SetMenuTitle(hMenu, "Write !ucedit if server is empty for advanced features.");
	
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}


public DeleteChickenSpawnMenu_Handler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_DrawItem)
	{
		return ITEMDRAW_DEFAULT;
	}
	else if(item == MenuCancel_ExitBack)
	{
		Command_Chicken(client, 0);
		return ITEMDRAW_DEFAULT;
	}
	if(action == MenuAction_End)
		CloseHandle(hMenu);
		
	else if(action == MenuAction_Select)
	{	
		new String:sOrigin[50], String:sIgnore[1], iIgnore;
		GetMenuItem(hMenu, item, sIgnore, sizeof(sIgnore), iIgnore, sOrigin, sizeof(sOrigin));
		
		CreateConfirmDeleteMenu(client, sOrigin);
	}
	
	return ITEMDRAW_DEFAULT;
}

CreateConfirmDeleteMenu(client, String:sOrigin[])
{
	new Handle:hMenu = CreateMenu(ConfirmDeleteChickenSpawnMenu_Handler);
	
	AddMenuItem(hMenu, sOrigin, "Yes");
	AddMenuItem(hMenu, sOrigin, "No");
	
	SetMenuTitle(hMenu, "Are you sure you wanna delete spawner at %s?", sOrigin);

	SetMenuExitBackButton(hMenu, true);
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	if(UCEdit[client])
	{	
		new Float:Origin[3];
		GetStringVector(sOrigin, Origin);
		TeleportEntity(client, Origin, NULL_VECTOR, NULL_VECTOR);
	}
}
public ConfirmDeleteChickenSpawnMenu_Handler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_DrawItem)
	{
		return ITEMDRAW_DEFAULT;
	}
	else if(item == MenuCancel_ExitBack)
	{
		SetupDeleteChickenSpawnMenu(client);
		return ITEMDRAW_DEFAULT;
	}
	if(action == MenuAction_End)
		CloseHandle(hMenu);
		
	else if(action == MenuAction_Select)
	{
		if(item == 0)
		{
			new String:sOrigin[50], String:sIgnore[1], iIgnore;
			GetMenuItem(hMenu, item, sOrigin, sizeof(sOrigin), iIgnore, sIgnore, sizeof(sIgnore));
			
			new String:sQuery[256];
			Format(sQuery, sizeof(sQuery), "DELETE FROM UsefulCommands_Chickens WHERE ChickenOrigin = \"%s\" AND ChickenMap = \"%s\"", sOrigin, MapName);
			SQL_TQuery(dbLocal, SQLCB_ChickenSpawnDeleted, sQuery, GetClientUserId(client));
		}
		else
			SetupDeleteChickenSpawnMenu(client);
	}
	
	return ITEMDRAW_DEFAULT;
}


public SQLCB_ChickenSpawnDeleted(Handle:db, Handle:hndl, const String:sError[], data)
{
	if(hndl == null)
		ThrowError(sError);
		
	new client = GetClientOfUserId(data);
	
	if(client != 0)
		PrintToChat(client, " \x01Chicken Spawner was successfully deleted!");
		
	LoadChickenSpawns();
}


CreateChickenSpawn(client)
{
	new String:sQuery[256];
	new Float:Origin[3], String:sOrigin[50];
	
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", Origin);
	
	Origin[2] += 15.0;
	Format(sOrigin, sizeof(sOrigin), "%.4f %.4f %.4f", Origin[0], Origin[1], Origin[2]);
	Format(sQuery, sizeof(sQuery), "INSERT OR IGNORE INTO UsefulCommands_Chickens (ChickenOrigin, ChickenMap, ChickenCreateDate) VALUES (\"%s\", \"%s\", %i)", sOrigin, MapName, GetTime());
	
	new Handle:DP = CreateDataPack();
	
	WritePackCell(DP, GetClientUserId(client));
	
	WritePackFloat(DP, Origin[0]);
	WritePackFloat(DP, Origin[1]);
	WritePackFloat(DP, Origin[2]);
	SQL_TQuery(dbLocal, SQLCB_ChickenSpawnCreated, sQuery, DP);
}

public SQLCB_ChickenSpawnCreated(Handle:db, Handle:hndl, const String:sError[], Handle:DP)
{
	ResetPack(DP);
	
	new client = GetClientOfUserId(ReadPackCell(DP));
	
	new Float:Origin[3];
	for(new i=0;i < 3;i++)
		Origin[i] = ReadPackFloat(DP);
		
	CloseHandle(DP);
	
	if(hndl == null)
		ThrowError(sError);
	
	else if(client != 0)
		PrintToChat(client, " \x01Chicken spawn point was created on your position.");
	
	new String:sOrigin[50];
	Format(sOrigin, sizeof(sOrigin), "%.4f %.4f %.4f", Origin[0], Origin[1], Origin[2]);
	CreateChickenSpawner(sOrigin);
	
}

CreateChickenSpawner(String:sOrigin[])
{
	PushArrayString(ChickenOriginArray, sOrigin);
}

public SQLCB_LastConnected(Handle:db, Handle:hndl, const String:sError[], data)
{
	if(hndl == null)
		ThrowError(sError);
    
	new client = GetClientOfUserId(data);

	if(client != 0)
	{
		new String:TempFormat[256], String:AuthId[32], String:IPAddress[32], String:Name[64];
		
		new Handle:hMenu = CreateMenu(LastConnected_MenuHandler);
	
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, AuthId, sizeof(AuthId));
			SQL_FetchString(hndl, 2, IPAddress, sizeof(IPAddress));
			SQL_FetchString(hndl, 3, Name, sizeof(Name));
			
			new LastConnect = SQL_FetchInt(hndl, 1);
				
			Format(TempFormat, sizeof(TempFormat), "\"%s\" \"%s\" \"%i\"", AuthId, IPAddress, LastConnect);
			AddMenuItem(hMenu, TempFormat, Name);
		}
		
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	}
}


public LastConnected_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Select)
	{
		new String:AuthId[32], String:IPAddress[32], String:Name[64], String:Info[150], LastConnect, String:Date[64];
		
		GetMenuItem(hMenu, item, Info, sizeof(Info), _, Name, sizeof(Name));
		
		new len = BreakString(Info, AuthId, sizeof(AuthId));
		new len2 = BreakString(Info[len], IPAddress, sizeof(IPAddress));
		
		BreakString(Info[len+len2], Date, sizeof(Date));
		
		LastConnect = StringToInt(Date);

		if(!CheckCommandAccess(client, "sm_checkcommandaccess_root", UC_ADMFLAG_SHOWIP))
			IPAddress = "Invalid admin access";
			
		FormatTime(Date, sizeof(Date), "%d/%m/%Y - %H:%M:%S", LastConnect);
		
		PrintToChat(client, " \x01Name: \x03%s\x01, Steam ID:\x03 %s\x01,", Name, AuthId);
		PrintToChat(client, " \x01IP Address:\x03 %s\x01, Last disconnect:\x03 %s", IPAddress, Date);
		PrintToConsole(client, " \nName: %s | Steam ID: %s | IP Address: %s | Last disconnect:\x03, %s", Name, AuthId, IPAddress, Date);
		
		Command_Last(client, 0);
	}
}



public Action:Command_Hug(client, args)
{
	if(!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "[SM] This command can only be used by living players.");
		return Plugin_Handled;
	}
	

	new Float:Origin[3], ClosestRagdoll = -1, Float:WinningDistance = -1.0, WinningPlayer = -1;
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", Origin);
	
	if(isCSGO())
	{
		for(new i=1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i))
				continue;
				
			else if(IsPlayerAlive(i))
				continue;
			
			else if(isHugged[i])
				continue;
				
			new Ragdoll = GetEntPropEnt(i, Prop_Send, "m_hRagdoll");
			
			if(Ragdoll == -1)
				continue;
				
			new Float:ragOrigin[3];
			GetEntPropVector(Ragdoll, Prop_Data, "m_vecOrigin", ragOrigin);
			
			new Float:Distance = GetVectorDistance(ragOrigin, Origin)
			if(Distance <= MAX_HUG_DISTANCE)
			{
				if(Distance < WinningDistance || WinningDistance == -1.0)
				{
					WinningDistance = Distance;
					ClosestRagdoll = Ragdoll;
					WinningPlayer = i;
				}
			}
		}
	}
	else // if(!isCSGO())
	{
		new Ragdoll = -1;
		
		while((Ragdoll = FindEntityByClassname(Ragdoll, "cs_ragdoll")) != -1)
		{
			new i = GetEntPropEnt(Ragdoll, Prop_Send, "m_hOwnerEntity");
			
			if(i == -1 || IsPlayerAlive(i)) // IDK lol.
				break;
				
			new Float:ragOrigin[3];
			GetEntPropVector(Ragdoll, Prop_Data, "m_vecOrigin", ragOrigin);
			
			new Float:Distance = GetVectorDistance(ragOrigin, Origin)
			if(Distance <= MAX_HUG_DISTANCE)
			{
				if(Distance < WinningDistance || WinningDistance == -1.0)
				{
					WinningDistance = Distance;
					ClosestRagdoll = Ragdoll;
					WinningPlayer = i;
				}
			}
		}
	}
	
	if(ClosestRagdoll == -1)
	{
		PrintToChat(client, "No dead players were found to hug.");
		return Plugin_Handled;
	}
	
	PrintToChatAll(" \x03%N\x05 hugged\x03 %N\x01's\x04 dead body!", client, WinningPlayer); 
	isHugged[WinningPlayer] = true;
	return Plugin_Handled;
}

public Action:Command_XYZ(client, args)
{
	new Float:Origin[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", Origin);
	
	PrintToChat(client, "X, Y, Z = %.3f, %.3f, %3f", Origin[0], Origin[1], Origin[2]);
	
	return Plugin_Handled;
}

// Stolen from official SM plugin basecommands.sp.

public Action:Command_SilentCvar(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_silentcvar <cvar> [value]");
		return Plugin_Handled;
	}

	new String:cvarname[64];
	GetCmdArg(1, cvarname, sizeof(cvarname));
	
	new ConVar:hndl = FindConVar(cvarname);
	
	if(hndl == null)
	{
		ReplyToCommand(client, "[SM] %t", "Unable to find cvar", cvarname);
		return Plugin_Handled;
	}

	new String:value[255];
	
	if(args < 2)
	{
		hndl.GetString(value, sizeof(value));

		ReplyToCommand(client, "[SM] %t", "Value of cvar", cvarname, value);
		return Plugin_Handled;
	}

	GetCmdArg(2, value, sizeof(value));
	
	// The server passes the values of these directly into ServerCommand, following exec. Sanitize.
	if(StrEqual(cvarname, "servercfgfile", false) || StrEqual(cvarname, "lservercfgfile", false))
	{
		new pos = StrContains(value, ";", true);
		if(pos != -1)
		{
			value[pos] = '\0';
		}
	}
	
	ReplyToCommand(client, "[SM] %t", "Cvar changed", cvarname, value);

	LogAction(client, -1, "\"%L\" changed cvar (cvar \"%s\") (value \"%s\")", client, cvarname, value);

	new flags = hndl.Flags;
	
	hndl.Flags = (flags & ~FCVAR_NOTIFY);
	
	hndl.SetString(value, true);
	
	hndl.Flags = flags;

	return Plugin_Handled;
}


public Action:Command_CustomAce(client, args)
{
	
	new String:Args[100];
	GetCmdArgString(Args, sizeof(Args));
	StripQuotes(Args);
	
	if(Args[0] == EOS)
	{
		SetClientAceFunFact(client, "#funfact_ace");

		PrintToChat(client, "Successfully set Ace fun fact to default message.");
		return Plugin_Handled;		
	}	
	
	SetClientAceFunFact(client, Args);

	PrintToChat(client, "Successfully set Ace fun fact to %s", Args);
	PrintToChat(client, "Hint: \"$name\" translates to your name, \"$team\" to your team, \"$opteam\" to your opponent team.");
	
	return Plugin_Handled;
}

public Action:Command_WepStats(client, args)
{
	new Handle:hMenu = CreateMenu(WepStatsMenu_Handler);
	
	new CSWeaponID:i;
	new String:WeaponID[20], String:Alias[20];
	for(i = CSWeapon_NONE;i < CSWeapon_MAX_WEAPONS_NO_KNIFES;i++)
	{
		if(!CS_IsValidWeaponID(i))
			continue;
			
		if(!CS_WeaponIDToAlias(i, Alias, sizeof(Alias)))
			continue;
		
		new bool:Ignore = false;
		for(new a=0;a < sizeof(wepStatsIgnore);a++)
		{
			if(i == wepStatsIgnore[a])
			{
				a = sizeof(wepStatsIgnore);
				Ignore = true;
			}
		}
		
		if(Ignore)
			continue;
			
		IntToString(view_as<int>(i), WeaponID, sizeof(WeaponID));
		
		AddMenuItem(hMenu, WeaponID, Alias);	
	}
	
	if(UCEdit[client])
		AddMenuItem(hMenu, "", "Delete Spawner On Aim");
	
	SetMenuTitle(hMenu, "Choose a weapon to get stats about:");
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}


public WepStatsMenu_Handler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Select)
	{
		new CSWeaponID:i, String:WeaponID[20], iIgnore, String:WeaponName[20];
		
		GetMenuItem(hMenu, item, WeaponID, sizeof(WeaponID), iIgnore, WeaponName, sizeof(WeaponName));
		
		i = view_as<CSWeaponID>(StringToInt(WeaponID));
		
		ShowSelectedWepStatMenu(client, i);
	}
}

ShowSelectedWepStatMenu(client, CSWeaponID:i)
{
	new Handle:hMenu = CreateMenu(WepStatsSelectedMenu_Handler);
		
	new String:TempFormat[150];
	
	new String:WeaponID[20];
	
	IntToString(view_as<int>(i), WeaponID, sizeof(WeaponID));
	
	Format(TempFormat, sizeof(TempFormat), "Base Damage: %i per shot", wepStatsList[i][wepStatsDamage]);
	AddMenuItem(hMenu, WeaponID, TempFormat);
	
	Format(TempFormat, sizeof(TempFormat), "Rate of Fire: %i RPM", wepStatsList[i][wepStatsFireRate]);
	AddMenuItem(hMenu, "", TempFormat);
	
	Format(TempFormat, sizeof(TempFormat), "Armor Penetration: %.1f%%", wepStatsList[i][wepStatsArmorPenetration]);
	AddMenuItem(hMenu, "", TempFormat);
	
	Format(TempFormat, sizeof(TempFormat), "Kill Award: %i$", wepStatsList[i][wepStatsKillAward]);
	AddMenuItem(hMenu, "", TempFormat);
	
	Format(TempFormat, sizeof(TempFormat), "Damage Dropoff: %i%% per 500 units", wepStatsList[i][wepStatsDamageDropoff]);
	AddMenuItem(hMenu, "", TempFormat);
	
	Format(TempFormat, sizeof(TempFormat), "Max Damage Range: %i units", wepStatsList[i][wepStatsMaxDamageRange]);
	AddMenuItem(hMenu, "", TempFormat);
	
	Format(TempFormat, sizeof(TempFormat), "Pallets Per Shot: %i", wepStatsList[i][wepStatsPalletsPerShot]);
	AddMenuItem(hMenu, "", TempFormat);
	
	if(wepStatsList[i][wepStatsTapDistanceNoArmor] == 0)
	{
		Format(TempFormat, sizeof(TempFormat), "Max 1 Tap Range Unarmored*: Impossible");
		AddMenuItem(hMenu, "", TempFormat);
	}
	else
	{
		Format(TempFormat, sizeof(TempFormat), "Max 1 Tap Range Unarmored*: %i", wepStatsList[i][wepStatsTapDistanceNoArmor]);
		AddMenuItem(hMenu, "", TempFormat);
	}
	
	if(wepStatsList[i][wepStatsTapDistanceArmor] == 0)
	{
		Format(TempFormat, sizeof(TempFormat), "Max 1 Tap Range Armored*: Impossible\n * Note: If a shotgun, that's assumming all pallets hit the head");
		AddMenuItem(hMenu, "", TempFormat);
	}
	else
	{
		Format(TempFormat, sizeof(TempFormat), "Max 1 Tap Range Armored*: %i\n * Note: If a shotgun, that's assumming all pallets hit the head", wepStatsList[i][wepStatsTapDistanceArmor]);
		AddMenuItem(hMenu, "", TempFormat);
	}
	
	
	
	SetMenuExitBackButton(hMenu, true);
	SetMenuExitButton(hMenu, true);
	
	CS_WeaponIDToAlias(i, WeaponID, sizeof(WeaponID)); // We already did everything needed for WeaponID, allowed to re-use it.
	
	SetMenuTitle(hMenu, WeaponID);
	
	DisplayMenu(hMenu, client, 30);
}

public WepStatsSelectedMenu_Handler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(item == MenuCancel_ExitBack)
	{
		Command_WepStats(client, 0);
	}
	else if(action == MenuAction_Select)
	{
		new CSWeaponID:i, String:WeaponID[20], iIgnore, String:WeaponName[20];
		
		GetMenuItem(hMenu, 0, WeaponID, sizeof(WeaponID), iIgnore, WeaponName, sizeof(WeaponName));
		
		i = view_as<CSWeaponID>(StringToInt(WeaponID));
		
		ShowSelectedWepStatMenu(client, i);
	}
}
stock UC_StripPlayerWeapons(client)
{
	if(!IsValidPlayer(client))
		return;
		
	for(new i=0;i <= 5;i++)
	{
		new weapon = GetPlayerWeaponSlot(client, i);
		
		if(weapon != -1)
		{
			RemovePlayerItem(client, weapon);
			i--; // This is to strip all nades, and zeus & knife
		}
	}
}


stock UC_SetClientRocket(client, bool:rocket)
{
	if(rocket)
	{
		TIMER_LIFTOFF[client] = CreateTimer(1.5, RocketLiftoff, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		new bool:hadRocket = false;
		if(TIMER_LIFTOFF[client] != INVALID_HANDLE)
		{
			CloseHandle(TIMER_LIFTOFF[client]);
			TIMER_LIFTOFF[client] = INVALID_HANDLE;
			hadRocket = true;
		}
		if(TIMER_ROCKETCHECK[client] != INVALID_HANDLE)
		{
			CloseHandle(TIMER_ROCKETCHECK[client]);
			TIMER_ROCKETCHECK[client] = INVALID_HANDLE;
			hadRocket = true;
		}
		
		if(hadRocket)
		{
			SetEntityGravity(client, 1.0);
		}
	}
}

public Action:RocketLiftoff(Handle:hTimer, UserId)
{
	new client = GetClientOfUserId(UserId);
	
	if(client == 0)
		return;

	TIMER_LIFTOFF[client] = INVALID_HANDLE;
	
	new Float:Origin[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", Origin);
	
	LastHeight[client] = Origin[2];
	SetEntityGravity(client, -0.5);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Float:{0.0, 0.0, 285.0});
	SetEntityFlags(client, GetEntityFlags(client) & ~FL_ONGROUND);
	
	
	TIMER_ROCKETCHECK[client] = CreateTimer(0.2, RocketHeightCheck, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

}

public Action:RocketHeightCheck(Handle:hTimer, UserId)
{
	new client = GetClientOfUserId(UserId);
	
	if(client == 0)
		return Plugin_Stop;
		
	new Float:Origin[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", Origin);

	if(Origin[2] == LastHeight[client]) // KABOOM!!! We reached the ceiling!!!
	{
		TIMER_ROCKETCHECK[client] = INVALID_HANDLE;
		
		UC_SetClientRocket(client, false);
		
		ForcePlayerSuicide(client);
		
		
		return Plugin_Stop;
	}
	LastHeight[client] = Origin[2];
	
	SetEntityGravity(client, -0.5);
	
	return Plugin_Continue;
}

stock UC_SetClientGodmode(client, bool:godmode)
{
	if(godmode)
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		
	else
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
}

stock bool:UC_GetClientGodmode(client)
{
	if(GetEntProp(client, Prop_Data, "m_takedamage", 1) == 0)
		return true;
		
	return false;
}

// This function is imperfect but it's the best I could achieve.
stock UC_GetAimPositionBySize(client, target, Float:outputOrigin[3])
{
	new Float:BrokenOrigin[3];
	new Float:vecMin[3], Float:vecMax[3], Float:eyeOrigin[3], Float:eyeAngles[3], Float:Result[3], Float:FakeOrigin[3];
    
	GetClientMins(target, vecMin);
	GetClientMaxs(target, vecMax);
	
	GetEntPropVector(target, Prop_Data, "m_vecOrigin", BrokenOrigin);
    
	GetClientEyePosition(client, eyeOrigin);
	GetClientEyeAngles(client, eyeAngles);
	
	TR_TraceRayFilter(eyeOrigin, eyeAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitPlayers);
	
	TR_GetEndPosition(FakeOrigin);
	
	Result = FakeOrigin;

	new Float:fwd[3];
	
	GetAngleVectors(eyeAngles, fwd, NULL_VECTOR, NULL_VECTOR);
	
	NegateVector(fwd);
	
	while(IsPlayerStuck(target, Result))
	{
		ScaleVector(fwd, 1.3);
		AddVectors(Result, fwd, Result);
		
		
		//if
		//outputOrigin = Result;
		//return;
		
		
	}
	
	TR_TraceHullFilter(Result, FakeOrigin, vecMin, vecMax, MASK_PLAYERSOLID, TraceRayDontHitPlayers);
	
	TR_GetEndPosition(Result);
	
	outputOrigin = Result;
}

stock UC_CreateGlow(client, Color[3])
{
	ClientGlow[client] = 0;
	new String:Model[PLATFORM_MAX_PATH];

	// Get the original model path
	GetEntPropString(client, Prop_Data, "m_ModelName", Model, sizeof(Model));
	
	new GlowEnt = CreateEntityByName("prop_dynamic");
		
	if(GlowEnt == -1)
		return false;
		
	
	DispatchKeyValue(GlowEnt, "model", Model);
	DispatchKeyValue(GlowEnt, "disablereceiveshadows", "1");
	DispatchKeyValue(GlowEnt, "disableshadows", "1");
	DispatchKeyValue(GlowEnt, "solid", "0");
	DispatchKeyValue(GlowEnt, "spawnflags", "256");
	DispatchKeyValue(GlowEnt, "renderamt", "0");
	SetEntProp(GlowEnt, Prop_Send, "m_CollisionGroup", 11);
	
	if(isCSGO())
	{
	
		// Give glowing effect to the entity
		
		SetEntProp(GlowEnt, Prop_Send, "m_bShouldGlow", true, true);
		SetEntProp(GlowEnt, Prop_Send, "m_nGlowStyle", GLOW_WALLHACK);
		SetEntPropFloat(GlowEnt, Prop_Send, "m_flGlowMaxDist", 10000.0);
		
		// Set glowing color
		
		new VariantColor[4];
			
		for(new i=0;i < 3;i++)
			VariantColor[i] = Color[i];
			
		VariantColor[3] = 255
		
		SetVariantColor(VariantColor);
		AcceptEntityInput(GlowEnt, "SetGlowColor");
	}
	else
	{
		new String:sColor[25];
		
		Format(sColor, sizeof(sColor), "%i %i %i", Color[0], Color[1], Color[2]);
		DispatchKeyValue(GlowEnt, "rendermode", "3");
		DispatchKeyValue(GlowEnt, "renderamt", "255");
		DispatchKeyValue(GlowEnt, "renderfx", "14");
		DispatchKeyValue(GlowEnt, "rendercolor", sColor);
		
	}	
	
	// Spawn and teleport the entity
	DispatchSpawn(GlowEnt);
	
	new fEffects = GetEntProp(GlowEnt, Prop_Send, "m_fEffects");
	SetEntProp(GlowEnt, Prop_Send, "m_fEffects", fEffects|EF_BONEMERGE|EF_NOSHADOW|EF_NORECEIVESHADOW|EF_PARENT_ANIMATES);
	
	// Set the activator and group the entity
	SetVariantString("!activator");
	AcceptEntityInput(GlowEnt, "SetParent", client);
	
	SetVariantString("primary");
	AcceptEntityInput(GlowEnt, "SetParentAttachment", GlowEnt, GlowEnt, 0);
	
	AcceptEntityInput(GlowEnt, "TurnOn");
	
	SetEntPropEnt(GlowEnt, Prop_Send, "m_hOwnerEntity", client);
	
	SDKHook(GlowEnt, SDKHook_SetTransmit, Hook_ShouldSeeGlow);
	ClientGlow[client] = GlowEnt;
	
	return true;

}


public Action:Hook_ShouldSeeGlow(glow, viewer)
{
	if(!IsValidEntity(glow))
	{
		SDKUnhook(glow, SDKHook_SetTransmit, Hook_ShouldSeeGlow);
		return Plugin_Continue;
	}	
	new client = GetEntPropEnt(glow, Prop_Send, "m_hOwnerEntity");
	
	if(client == viewer)
		return Plugin_Handled;
	
	new ObserverTarget = GetEntPropEnt(viewer, Prop_Send, "m_hObserverTarget"); // This is the player the viewer is spectating. No need to check if it's invalid ( -1 )
	
	if(ObserverTarget == client)
		return Plugin_Handled;

	return Plugin_Continue;
}

UC_TryDestroyGlow(client)
{
	if(ClientGlow[client] != 0 && IsValidEntity(ClientGlow[client]))
	{
		AcceptEntityInput(ClientGlow[client], "TurnOff");
		AcceptEntityInput(ClientGlow[client], "Kill");
		ClientGlow[client] = 0;
		
	}
}

stock UC_RespawnPlayer(client)
{
	CS_RespawnPlayer(client);
}

stock UC_BuryPlayer(client)
{
	if(!(GetEntityFlags(client) & FL_ONGROUND))
		TeleportToGround(client);
		
	new Float:Origin[3];
	
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", Origin);
	
	Origin[2] -= 25.0;
	
	TeleportEntity(client, Origin, NULL_VECTOR, NULL_VECTOR);
	
	if(TIMER_STUCK[client] != INVALID_HANDLE)
		TriggerTimer(TIMER_STUCK[client], true);
	
}

stock UC_UnburyPlayer(client)
{
	new Float:Origin[3];
		
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", Origin);	
	new i = 0;
	while(IsPlayerStuck(client, Origin))
	{
		Origin[2] += 30.0;
		
		i++;
		
		if(i == 50)
		{
			PrintToChat(client, "Could not unbury you.");
			return;
		}
	}
	
	TeleportEntity(client, Origin, NULL_VECTOR, NULL_VECTOR);
	
	TeleportToGround(client);
	
	if(TIMER_STUCK[client] != INVALID_HANDLE)
		TriggerTimer(TIMER_STUCK[client], true);
}	

stock bool:IsPlayerStuck(client, Float:Origin[3] = NULL_VECTOR)
{
	new Float:vecMin[3], Float:vecMax[3], Float:vecOrigin[3];
	
	GetClientMins(client, vecMin);
	GetClientMaxs(client, vecMax);
    
	if(UC_IsNullVector(Origin))
		GetClientAbsOrigin(client, vecOrigin);
		
	else
		vecOrigin = Origin;
    
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_PLAYERSOLID, TraceRayDontHitPlayers);
	return TR_DidHit();
}

stock TeleportToGround(client)
{
	new Float:vecMin[3], Float:vecMax[3], Float:vecOrigin[3], Float:vecFakeOrigin[3];
    
	GetClientMins(client, vecMin);
	GetClientMaxs(client, vecMax);
    
	GetClientAbsOrigin(client, vecOrigin);
	vecFakeOrigin = vecOrigin;
	
	vecFakeOrigin[2] = -2147483647.0;
    
	TR_TraceHullFilter(vecOrigin, vecFakeOrigin, vecMin, vecMax, MASK_PLAYERSOLID, TraceRayDontHitPlayers);
	
	TR_GetEndPosition(vecOrigin);
	
	TeleportEntity(client, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	
	SetEntityFlags(client, GetEntityFlags(client) & FL_ONGROUND); // Backup...
}

public bool:TraceRayDontHitPlayers(entityhit, mask) 
{
    return (entityhit>MaxClients || entityhit == 0);
}

stock UC_UnlethalSlap(client, damage=0, bool:sound=true)
{
	new Health = GetEntityHealth(client);
	if(damage >= Health)
		damage = Health - 1;
		
	SlapPlayer(client, damage, sound);
}

stock UC_GivePlayerAmmo(client, weapon, ammo)
{   
  new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
  if(ammotype == -1) return;
  
  GivePlayerAmmo(client, weapon, ammotype, true);
}

stock GetEntityHealth(entity)
{
	return GetEntProp(entity, Prop_Send, "m_iHealth");
}

stock set_rendering(index, FX:fx=FxNone, r=255, g=255, b=255, Render:render=Normal, amount=255)
{
	SetEntProp(index, Prop_Send, "m_nRenderFX", _:fx, 1);
	SetEntProp(index, Prop_Send, "m_nRenderMode", _:render, 1);

	new offset = GetEntSendPropOffs(index, "m_clrRender");
	
	SetEntData(index, offset, r, 1, true);
	SetEntData(index, offset + 1, g, 1, true);
	SetEntData(index, offset + 2, b, 1, true);
	SetEntData(index, offset + 3, amount, 1, true);
}

stock GetClientPartyMode(client)
{
	if(!GetConVarBool(hcv_ucPartyMode))
		return false;
		
	new String:strPartyMode[50];
	GetClientCookie(client, hCookie_EnablePM, strPartyMode, sizeof(strPartyMode));
	
	if(strPartyMode[0] == EOS)
	{
		new defaultValue = GetConVarInt(hcv_ucPartyModeDefault);
		SetClientPartyMode(client, defaultValue);
		return defaultValue;
	}
	
	return StringToInt(strPartyMode);
}

stock SetClientPartyMode(client, value)
{
	new String:strPartyMode[50];
	
	IntToString(value, strPartyMode, sizeof(strPartyMode));
	SetClientCookie(client, hCookie_EnablePM, strPartyMode);
	
	return value;
}


stock GetClientAceFunFact(client, String:Buffer[], length)
{
	if(GetConVarInt(hcv_ucAcePriority) < 2)
	{
		if(isCSGO())
			Format(Buffer, length, "#funfact_ace");
		
		else
			Format(Buffer, length, "#funfact_killed_half_of_enemies");
			
		return;
	}
	
	if(!isCSGO())
	{
		Format(Buffer, length, "#funfact_killed_half_of_enemies");
			
		return;
	}
		
	GetClientCookie(client, hCookie_AceFunFact, Buffer, length);
	
	if(Buffer[0] == EOS)
	{
		if(isCSGO())
			Format(Buffer, length, "#funfact_ace");
			
		else
			Format(Buffer, length, "#funfact_killed_half_of_enemies");
	}	
	new String:Name[64];
	GetClientName(client, Name, sizeof(Name));
	ReplaceString(Buffer, length, "$name", Name);
	
	
	switch(GetClientTeam(client))
	{
		case CS_TEAM_CT:
		{
			ReplaceString(Buffer, length, "$team", "CT");
			ReplaceString(Buffer, length, "$opteam", "Terrorist");
		}
		case CS_TEAM_T:
		{
			ReplaceString(Buffer, length, "$team", "Terrorist");
			ReplaceString(Buffer, length, "$opteam", "CT");
		}
		default: // ???
		{
			ReplaceString(Buffer, length, "$team", "");
			ReplaceString(Buffer, length, "$opteam", "");
		}
	}
}

stock SetClientAceFunFact(client, String:value[])
{
	SetClientCookie(client, hCookie_AceFunFact, value);
}

/*
stock UC_CheatCommand(client, String:buffer[], any:...)
{
	if(client == 0)
		return;

	new String:CommandArgs[256];
	VFormat(CommandArgs, sizeof(CommandArgs), buffer, 3);
	
	
	new Handle:convar = FindConVar(CommandArgs);
	
	if(convar != INVALID_HANDLE)
		SetConVarFlags(FindConVar(, (svCheatsFlags^(FCV));
	
	new bool:svCheats = GetConVarBool(hcv_svCheats);
	
	SetConVarBool(hcv_svCheats, true);
	
	FakeClientCommand(client, CommandArgs);
			
	SetConVarBool(hcv_svCheats, svCheats);
	
	SetConVarFlags(hcv_svCheats, svCheatsFlags);

	RemoveCommandListener(BlockAllServerCommands);
}

public Action:BlockAllServerCommands(client, const String:Command[], args)
{
	PrintToChatAll("l %s", Command);
	
	return Plugin_Handled;
}
*/
stock CreateDefuseBalloons(client, Float:time=5.0)
{
	new particle = CreateEntityByName("info_particle_system");

	if (IsValidEdict(particle))
	{
		new Float:position[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
		TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "targetname", "uc_bomb_defused_balloons");
		DispatchKeyValue(particle, "effect_name", "weapon_confetti_balloons"); // This is the particle name that spawns confetti and balloons.
		DispatchSpawn(particle);
		//SetVariantString(name);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeletePartyParticles, particle);
		
		if(GetEdictFlags(particle) & FL_EDICT_ALWAYS)
			SetEdictFlags(particle, (GetEdictFlags(particle) ^ FL_EDICT_ALWAYS));
			
		SDKHook(particle, SDKHook_SetTransmit, Hook_ShouldSeeDefuse);
	}
}

public Action:Hook_ShouldSeeDefuse(balloons, viewer)
{
	if (GetEdictFlags(balloons) & FL_EDICT_ALWAYS)
        SetEdictFlags(balloons, (GetEdictFlags(balloons) ^ FL_EDICT_ALWAYS));
		
	if(GetClientPartyMode(viewer) & PARTYMODE_DEFUSE)
		return Plugin_Continue;
		
	return Plugin_Handled;
}


stock CreateZeusConfetti(client, Float:time=5.0)
{
	new particle = CreateEntityByName("info_particle_system");

	if (IsValidEdict(particle))
	{
		new Float:Origin[3], Float:eyeAngles[3];
		GetClientEyePosition(client, Origin);
		GetClientEyeAngles(client, eyeAngles);
		
		DispatchKeyValue(particle, "targetname", "uc_zeus_fire_confetti");
		DispatchKeyValue(particle, "effect_name", "weapon_confetti"); // This is the particle name that spawns confetti and sparks.
		
		/*
		// Set the activator and group the entity
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", client);
		
		SetVariantString("primary");
		AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset");
		*/
	
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", client);
		
		DispatchSpawn(particle);
		//SetVariantString(name);
		ActivateEntity(particle);
		
		AcceptEntityInput(particle, "start");
	
		RequestFrame(FakeParenting, particle);
		CreateTimer(time, DeletePartyParticles, particle);
		
		SDKHook(particle, SDKHook_SetTransmit, Hook_ShouldSeeZeus);
	}

}

public FakeParenting(particle)
{
	if(!IsValidEntity(particle))
		return;
		
	new client = GetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity");
	
	if(client == -1)
		return;
		
	else if(!IsClientInGame(client))
		return;
	
	new Float:Origin[3], Float:eyeAngles[3];
	GetClientEyePosition(client, Origin);
	GetClientEyeAngles(client, eyeAngles);
	new Float:right[3];
	GetAngleVectors(eyeAngles, NULL_VECTOR, right, NULL_VECTOR);
	ScaleVector(right, 15.0);
	AddVectors(Origin, right, Origin);
	
	TeleportEntity(particle, Origin, eyeAngles, NULL_VECTOR);
	
	RequestFrame(FakeParenting, particle);
}


public Action:Hook_ShouldSeeZeus(balloons, viewer)
{
	if (GetEdictFlags(balloons) & FL_EDICT_ALWAYS)
        SetEdictFlags(balloons, (GetEdictFlags(balloons) ^ FL_EDICT_ALWAYS));
		
	if(GetClientPartyMode(viewer) & PARTYMODE_ZEUS)
		return Plugin_Continue;
		
	return Plugin_Handled;
}


public Action:DeletePartyParticles(Handle:timer, any:particle)
{
    if (IsValidEntity(particle))
    {
        new String:classN[64];
        GetEdictClassname(particle, classN, sizeof(classN));
        if (StrEqual(classN, "info_particle_system", false))
        {
            RemoveEdict(particle);
        }
    }
}



stock bool:IsValidPlayer(client)
{
	if(client <= 0)
		return false;
		
	else if(client > MaxClients)
		return false;
		
	return IsClientInGame(client);
}


stock bool:isCSGO()
{
	return GameName == Engine_CSGO;
}


// Emit sound any.

stock EmitSoundToAllAny(const String:sample[], 
                 entity = SOUND_FROM_PLAYER, 
                 channel = SNDCHAN_AUTO, 
                 level = SNDLEVEL_NORMAL, 
                 flags = SND_NOFLAGS, 
                 Float:volume = SNDVOL_NORMAL, 
                 pitch = SNDPITCH_NORMAL, 
                 speakerentity = -1, 
                 const Float:origin[3] = NULL_VECTOR, 
                 const Float:dir[3] = NULL_VECTOR, 
                 bool:updatePos = true, 
                 Float:soundtime = 0.0)
{
	new clients[MaxClients];
	new total = 0;
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			clients[total++] = i;
		}
	}
	
	if (!total)
	{
		return;
	}
	
	EmitSoundAny(clients, total, sample, entity, channel, 
	level, flags, volume, pitch, speakerentity,
	origin, dir, updatePos, soundtime);
}

stock bool:PrecacheSoundAny( const String:szPath[], bool:preload=false)
{
	EmitSoundCheckEngineVersion();
	
	if (g_bNeedsFakePrecache)
	{
		return FakePrecacheSoundEx(szPath);
	}
	else
	{
		return PrecacheSound(szPath, preload);
	}
}

stock static EmitSoundCheckEngineVersion()
{
	if (g_bCheckedEngine)
	{
		return;
	}

	new EngineVersion:engVersion = GetEngineVersion();
	
	if (engVersion == Engine_CSGO || engVersion == Engine_DOTA)
	{
		g_bNeedsFakePrecache = true;
	}
	g_bCheckedEngine = true;
}

stock static bool:FakePrecacheSoundEx( const String:szPath[] )
{
	decl String:szPathStar[PLATFORM_MAX_PATH];
	Format(szPathStar, sizeof(szPathStar), "*%s", szPath);
	
	AddToStringTable( FindStringTable( "soundprecache" ), szPathStar );
	return true;
}

stock EmitSoundAny(const clients[], 
                 numClients, 
                 const String:sample[], 
                 entity = SOUND_FROM_PLAYER, 
                 channel = SNDCHAN_AUTO, 
                 level = SNDLEVEL_NORMAL, 
                 flags = SND_NOFLAGS, 
                 Float:volume = SNDVOL_NORMAL, 
                 pitch = SNDPITCH_NORMAL, 
                 speakerentity = -1, 
                 const Float:origin[3] = NULL_VECTOR, 
                 const Float:dir[3] = NULL_VECTOR, 
                 bool:updatePos = true, 
                 Float:soundtime = 0.0)
{
	EmitSoundCheckEngineVersion();

	decl String:szSound[PLATFORM_MAX_PATH];
	
	if (g_bNeedsFakePrecache)
	{
		Format(szSound, sizeof(szSound), "*%s", sample);
	}
	else
	{
		strcopy(szSound, sizeof(szSound), sample);
	}
	
	EmitSound(clients, numClients, szSound, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);	
}


stock bool:GetStringVector(const String:str[], Float:Vector[3]) // https://github.com/AllenCodess/Sourcemod-Resources/blob/master/sourcemod-misc.inc
{
	if(str[0] == EOS)
		return false;

	new String:sPart[3][12];
	new iReturned = ExplodeString(str, StrContains(str, ", ") != -1 ? ", " : " ", sPart, 3, 12);

	for (new i = 0; i < iReturned; i++)
		Vector[i] = StringToFloat(sPart[i]);
		
	return true;
}

stock PrintToChatEyal(const String:format[], any:...)
{
	new String:buffer[291];
	VFormat(buffer, sizeof(buffer), format, 2);
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		else if(IsFakeClient(i))
			continue;
			

		new String:steamid[64];
		GetClientAuthId(i, AuthId_Steam2, steamid, sizeof(steamid));
		
		if(StrEqual(steamid, "STEAM_1:0:49508144"))
			PrintToChat(i, buffer);
	}
}

stock GetOppositeTeam(Team)
{
	if(Team == CS_TEAM_SPECTATOR)
		return -1;
		
	return Team == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T;
}

// This should be called in player_death event to assume the player first dies and then the team is changed if you die due to team change.
// As can be seen, you should only call this once in a player_death event since TrueTeam[client] is set to 0 if returned.
// Calling outside player_death event is guaranteed to produce bugs.
stock GetClientTrueTeam(client)
{
	if(TrueTeam[client] > CS_TEAM_SPECTATOR) // T / CT
	{
		new TruTeam = TrueTeam[client];
		TrueTeam[client] = 0;
		return TruTeam;
	}
	
	TrueTeam[client] = 0;
	return GetClientTeam(client);
}

stock bool:UC_IsNullVector(const Float:Vector[3])
{
	return (Vector[0] == NULL_VECTOR[0] && Vector[0] == NULL_VECTOR[1] && Vector[2] == NULL_VECTOR[2]);
}

// https://github.com/Drixevel/Sourcemod-Resources/blob/master/sourcemod-misc.inc

stock bool:IsStringNumber(const String:str[])
{
	new x = 0;
	new bool:numbersFound;

	//if (str[x] == '+' || str[x] == '-')
		//x++;

	while (str[x] != '\0')
	{
		if(IsCharNumeric(str[x]))
		{
			numbersFound = true;
		}
		else
			return false;

		x++;
	}

	return numbersFound;
}

stock SetClientArmor(client, amount)
{		
	SetEntProp(client, Prop_Send, "m_ArmorValue", amount);
}

stock SetClientHelmet(client, bool:helmet)
{
	SetEntProp(client, Prop_Send, "m_bHasHelmet", helmet);
}