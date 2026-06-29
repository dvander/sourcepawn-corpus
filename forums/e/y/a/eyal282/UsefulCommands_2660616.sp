// To do: Add weapon stats comparison based on what I used with Big Bertha

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <cURL>
#tryinclude <socket>
#tryinclude <steamtools>
#tryinclude <SteamWorks>
#tryinclude <updater>  // Comment out this line to remove updater support by force.
#tryinclude <autoexecconfig>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS

new const String:PLUGIN_VERSION[] = "4.0";

public Plugin:myinfo = 
{
	name = "Useful commands",
	author = "Eyal282",
	description = "Useful commands.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2617618"
}

#define FPERM_ULTIMATE (FPERM_U_READ|FPERM_U_WRITE|FPERM_U_EXEC|FPERM_G_READ|FPERM_G_WRITE|FPERM_G_EXEC|FPERM_O_READ|FPERM_O_WRITE|FPERM_O_EXEC)

#define MAX_CSGO_LEVEL 40

#define ITEMS_GAME_PATH "scripts/items/items_game.txt"
#define CACHE_ITEMS_GAME_PATH "data/UsefulCommands"

#define MAX_INTEGER 2147483647
#define MIN_FLOAT -2147483647.0 // I think -2147483648 is lowest but meh, same thing.

#define CHRISTMASS_PRESENT_BODYINDEX 1

#define MAX_POSSIBLE_HP 65535
#define MAX_POSSIBLE_MONEY 65535
// I'll redefine these if needed. I doubt they'll change.

#define HEADSHOT_MULTIPLIER 4.0
#define STOMACHE_MULTIPLIER 1.25
#define CHEST_MULTIPLIER 1.0
#define LEGS_MULTIPLIER 0.75 // Also legs are immune to kevlar and yes, bizon is stronger on legs than kevlar chest.

#define HUD_PRINTCENTER        4 

#define GAME_RULES_CVARS_PATH "gamerulescvars.txt"

#define UPDATE_URL    "https://raw.githubusercontent.com/eyal282/AlliedmodsUpdater/master/UsefulCommands/updatefile.txt"

#define COMMAND_FILTER_NONE 0

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

#define CURL_AVAILABLE()		(GetFeatureStatus(FeatureType_Native, "curl_easy_init") == FeatureStatus_Available)
#define SOCKET_AVAILABLE()		(GetFeatureStatus(FeatureType_Native, "SocketCreate") == FeatureStatus_Available)
#define STEAMTOOLS_AVAILABLE()	(GetFeatureStatus(FeatureType_Native, "Steam_CreateHTTPRequest") == FeatureStatus_Available)
#define STEAMWORKS_AVAILABLE()	(GetFeatureStatus(FeatureType_Native, "SteamWorks_WriteHTTPResponseBodyToFile") == FeatureStatus_Available)

#define EXTENSION_ERROR		"This plugin requires one of the cURL, Socket, SteamTools, or SteamWorks extensions to function."

new String:UCTag[65];

new ChickenOriginPosition;

new const String:Colors[][] = 
{
	"{NORMAL}", "{RED}", "{GREEN}", "{LIGHTGREEN}", "{OLIVE}", "{LIGHTRED}", "{GRAY}", "{YELLOW}", "{ORANGE}", "{BLUE}", "{PINK}"
}

new const String:ColorEquivalents[][] =
{
	"\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08", "\x09", "\x10", "\x0C", "\x0E"
}

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

//new LastHolidayCvar = 0;

new Handle:Trie_UCCommands = INVALID_HANDLE;
new Handle:Trie_CoinLevelValues = INVALID_HANDLE;

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
new Handle:hcv_ucAnnouncePlugin = INVALID_HANDLE;
new Handle:hcv_ucReviveOnTeamChange = INVALID_HANDLE;
new Handle:hcv_ucPacketNotifyCvars = INVALID_HANDLE;
new Handle:hcv_ucGlowType = INVALID_HANDLE;
new Handle:hcv_ucTag = INVALID_HANDLE;
new Handle:hcv_ucRestartRoundOnMapStart = INVALID_HANDLE;

new Handle:hCookie_EnablePM = INVALID_HANDLE;
new Handle:hCookie_AceFunFact = INVALID_HANDLE;

new Handle:TIMER_UBERSLAP[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:TIMER_STUCK[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:TIMER_LIFTOFF[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:TIMER_ROCKETCHECK[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:TIMER_LASTC4[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:TIMER_ANNOUNCEPLUGIN[MAXPLAYERS+1] = INVALID_HANDLE;

new AceCandidate[7]; // IDK How many teams there are...

new LastC4Ref[MAXPLAYERS+1] = INVALID_ENT_REFERENCE;

new bool:MapStarted = false, String:MapName[128];

new RoundNumber = 0;

new Handle:TeleportsArray = INVALID_HANDLE;
new Handle:BombResetsArray = INVALID_HANDLE;
new Handle:ChickenOriginArray = INVALID_HANDLE;

new Handle:fw_ucAce = INVALID_HANDLE;
new Handle:fw_ucAcePost = INVALID_HANDLE;
new Handle:fw_ucWeaponStatsRetrievedPost = INVALID_HANDLE;

new bool:AceSent = false, TrueTeam[MAXPLAYERS+1];

new Handle:dbLocal, Handle:dbClientPrefs;

new bool:FullInGame[MAXPLAYERS+1];

new String:LastAuthStr[MAXPLAYERS+1][64];

new Float:LastHeight[MAXPLAYERS+1];

new Handle:hRestartTimer = INVALID_HANDLE;
new Handle:hRRTimer = INVALID_HANDLE;

new bool:RestartNR = false;

new Handle:hcv_TagScale = INVALID_HANDLE;

new bool:UCEdit[MAXPLAYERS+1];

new ClientGlow[MAXPLAYERS+1];

new RoundKills[MAXPLAYERS+1];

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
	Float:wepStatsWallPenetration,
	wepStatsDamageDropoff,
	wepStatsMaxDamageRange,
	wepStatsPalletsPerShot, // For shotguns
	wepStatsDamagePerPallet,
	wepStatsTapDistanceNoArmor,
	wepStatsTapDistanceArmor,
	bool:wepStatsIsAutomatic,
	wepStatsDamagePerSecondNoArmor,
	wepStatsDamagePerSecondArmor
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
	CSWeapon_KNIFE_T,
	CSWeapon_HEGRENADE,
	CSWeapon_TAGGRENADE,
	CSWeapon_FLASHBANG,
	CSWeapon_DECOY,
	CSWeapon_SMOKEGRENADE,
	CSWeapon_INCGRENADE,
	CSWeapon_MOLOTOV
}
public APLRes:AskPluginLoad2(Handle:myself, bool:bLate, String:error[], length)
{
	isLateLoaded = bLate;
	
	CreateNative("UsefulCommands_GetWeaponStats", Native_GetWeaponStatsList);
	CreateNative("UsefulCommands_ApproximateClientRank", Native_ApproximateClientRank);
}

// native int UsefulCommands_GetWeaponStats(CSWeaponID WeaponID, int &StatsList[])

public Native_GetWeaponStatsList(Handle:caller, numParams)
{
	new CSWeaponID:WeaponID = GetNativeCell(1);
		
	if(!CS_IsValidWeaponID(WeaponID))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid weapon ID %i", WeaponID);
		return false;
	}
	
	SetNativeArray(2, wepStatsList[WeaponID], sizeof(wepStatsList[]));
	return true;
}

// native int UsefulCommands_ApproximateClientRank(int client);

// returns approximate rank.
// Note: if client has no service medals, returns exact rank.
// Note: if client has one medal, returns exact rank ONLY if it's equipped.
// Note: if client has more than one medal, does not return exact rank, however if you wanna filter out newbies, will work fine.
// Note: if you kick a client based on his rank, you should ask him to temporarily equip a service medal if he reset his rank recently, and you should cache that his steam ID is an acceptable rank.
// Note: don't use this on Counter-Strike: Source lol.

public Native_ApproximateClientRank(Handle:caller, numParams)
{	
	new PlayerResourceEnt = GetPlayerResourceEntity();
	
	new client = GetNativeCell(1);
	
	if(!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %i", client);
		return -1;
	}
	
	new String:sCoin[64], value, rank = GetEntProp(PlayerResourceEnt, Prop_Send, "m_nPersonaDataPublicLevel", _, client);
	IntToString(GetEntProp(PlayerResourceEnt, Prop_Send, "m_nActiveCoinRank", _, client), sCoin, sizeof(sCoin));
	
	if(rank == -1)
		rank = 0;
		
	if(GetTrieValue(Trie_CoinLevelValues, sCoin, value))
		rank += value;
	
	return rank;
}

public OnPluginStart()
{
	GameName = GetEngineVersion();
	
	#if defined _autoexecconfig_included
	
	AutoExecConfig_SetFile("UsefulCommands");
	
	#endif
	
	Trie_UCCommands = CreateTrie();
	Trie_CoinLevelValues = CreateTrie();
	
	LoadTranslations("UsefulCommands.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("clientprefs.phrases");
	
	fw_ucAce = CreateGlobalForward("UsefulCommands_OnPlayerAce", ET_Event, Param_CellByRef, Param_String, Param_CellByRef);
	fw_ucAcePost = CreateGlobalForward("UsefulCommands_OnPlayerAcePost", ET_Ignore, Param_Cell, Param_String, Param_Cell);
	fw_ucWeaponStatsRetrievedPost = CreateGlobalForward("UsefulCommands_OnWeaponStatsRetrievedPost", ET_Ignore);
	
	// public UsefulCommands_OnPlayerAce(&client, String:FunFact[], Kills)
	
	// param &client = Client that made an ace.
	// param String:FunFact[] = Copyback fun fact for the client.
	// param Kills = Amount of kills the client made in the round.
	
	// return = Plugin_Changed when changing a parameter, Plugin_Handled to block fun fact change, Plugin_Stop to stop both fun fact change and the post forward.
	// Note: this forward may call more than once during a single ace.
	
	// public UsefulCommands_OnPlayerAcePost(client, const String:FunFact[], Kills)
	// param &client = Client that made an ace.
	// param String:FunFact[] = Copyback fun fact for the client.
	// param Kills = Amount of kills the client made in the round.
	
	// return = No return.
	// Note: Although the pre ace forward may call more than once in a single ace, this forward will only call once per ace.
	
	// public UsefulCommands_OnWeaponStatsRetrievedPost()

	
	//hcv_svCheats = FindConVar("sv_cheats");
	
	//svCheatsFlags = GetConVarFlags(hcv_svCheats);
	
	
	hcv_ucTag = UC_CreateConVar("uc_tag", "[{RED}UC{NORMAL}] {NORMAL}", _, FCVAR_PROTECTED);
	hcv_TagScale = UC_CreateConVar("uc_bullet_tagging_scale", "1.0", "5000000.0 is more than enough to disable tagging completely. Below 1.0 makes tagging stronger. 1.0 for default game behaviour", FCVAR_NOTIFY, true, 0.0);
	hcv_ucSpecialC4Rules = UC_CreateConVar("uc_special_bomb_rules", "0", "If 1, CT can pick-up C4 but can't abuse it in any way ( e.g dropping it in unreachable spots ) and can't get rid of it unless to another player.", FCVAR_NOTIFY);
	hcv_ucAcePriority = UC_CreateConVar("uc_ace_priority", "2", "Prioritize Ace over all other fun facts of a round's end and print a message when a player makes an ace. Set to 2 if you want players to have a custom fun fact on ace.");
	hcv_ucReviveOnTeamChange = UC_CreateConVar("uc_revive_on_team_change", "1", "Revive the player when an admin sets his team.");
	hcv_ucRestartRoundOnMapStart = UC_CreateConVar("uc_restart_round_on_map_start", "1", "Restart the round when the map starts to block bug where round_start is never called on the first round.");
	hcv_ucAnnouncePlugin = UC_CreateConVar("uc_announce_plugin", "36.5", "Announces to joining players that the best utility plugin is running, this cvar's value when after a player joins he'll get the message. 0 to disable.");
	
	GetConVarString(hcv_ucTag, UCTag, sizeof(UCTag));
	HookConVarChange(hcv_ucTag, hcvChange_ucTag);
	
	if(isCSGO())
	{
		
		hcv_ucTeleportBomb = UC_CreateConVar("uc_teleport_bomb", "1", "If 1, All trigger_teleport entities will have a trigger_bomb_reset attached to them so bombs never get stuck outside of reach in the game. Set to -1 to destroy this mechanism completely to reserve in entity count.", FCVAR_NOTIFY);
		
		hcv_ucUseBombPickup = UC_CreateConVar("uc_use_bomb", "1", "If 1, Terrorists can pick up C4 by pressing E on it.", FCVAR_NOTIFY);
		
		hcv_ucPacketNotifyCvars = UC_CreateConVar("uc_packet_notify_cvars", "2", "If 2, acts like 1 but also deletes the gamerulescvars.txt file before doing it. If 1, UC will put all FCVAR_NOTIFY cvars in gamerulescvars.txt", FCVAR_NOTIFY);
		
		hcv_ucGlowType = UC_CreateConVar("uc_glow_type", "1", "0 = Wallhack, 1 = Fullbody, 2 = Surround Player, 3 = Blinking and Surround Player");
		
		HookConVarChange(hcv_ucTeleportBomb, OnTeleportBombChanged);
				
			
		HookEvent("bomb_defused", Event_BombDefused, EventHookMode_Pre);
		HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Pre);
		HookEvent("player_use", Event_PlayerUse, EventHookMode_Post);
		
		SetCookieMenuItem(PartyModeCookieMenu_Handler, 0, "Party Mode");
		
		if(TeleportsArray == INVALID_HANDLE)
			TeleportsArray = CreateArray(1);
			
		if(BombResetsArray == INVALID_HANDLE)
			BombResetsArray = CreateArray(1);
		
		if(!IsSoundPrecached(PartySound)) // Problems with the listen server...
			PrecacheSoundAny(PartySound);
		
		if(!IsSoundPrecached(ItemPickUpSound))
			PrecacheSoundAny(ItemPickUpSound);
	}
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	//HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	HookEvent("cs_win_panel_round", Event_CsWinPanelRound, EventHookMode_Pre);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	
	#if defined _updater_included
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
	
	if(isLateLoaded)
	{
		for(new i=1;i <= MaxClients;i++)
		{	
			if(!IsClientInGame(i))
				continue;
				
			OnClientPutInServer(i);
		}
		
		OnMapStart();
	}
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
	
	if(!CommandExists("sm_revive"))
		UC_RegAdminCmd("sm_revive", Command_Revive, ADMFLAG_BAN, "Respawns a player from the dead");

	if(!CommandExists("sm_1up"))
		UC_RegAdminCmd("sm_1up", Command_HardRevive, ADMFLAG_BAN, "Respawns a player from the dead back to his death position");
		
	if(!CommandExists("sm_hrevive"))
		UC_RegAdminCmd("sm_hrevive", Command_HardRevive, ADMFLAG_BAN, "Respawns a player from the dead back to his death position");
		
	if(!CommandExists("sm_bury"))
		UC_RegAdminCmd("sm_bury", Command_Bury, ADMFLAG_BAN, "Buries a player underground");	
		
	if(!CommandExists("sm_unbury"))
		UC_RegAdminCmd("sm_unbury", Command_Unbury, ADMFLAG_BAN, "unburies a player from the ground");	
		
	if(!CommandExists("sm_uberslap"))
		UC_RegAdminCmd("sm_uberslap", Command_UberSlap, ADMFLAG_BAN, "Slaps a player 100 times, leaving him with 1 hp");	
	
	if(!CommandExists("sm_heal"))
		UC_RegAdminCmd("sm_heal", Command_Heal, ADMFLAG_BAN, "Allows to either heal a player, give him armor or a helmet.");
		
	if(!CommandExists("sm_give"))
		UC_RegAdminCmd("sm_give", Command_Give, ADMFLAG_CHEATS, "Give a weapon for a player.");
		
	if(!CommandExists("sm_rr"))
		UC_RegAdminCmd("sm_rr", Command_RestartRound, ADMFLAG_CHANGEMAP, "Restarts the round.");
		
	if(!CommandExists("sm_restartround"))
		UC_RegAdminCmd("sm_restartround", Command_RestartRound, ADMFLAG_CHANGEMAP, "Restarts the round.");
		
	if(!CommandExists("sm_rg"))
		UC_RegAdminCmd("sm_rg", Command_RestartGame, ADMFLAG_CHANGEMAP, "Restarts the game.");
		
	if(!CommandExists("sm_restartgame"))
		UC_RegAdminCmd("sm_restartgame", Command_RestartGame, ADMFLAG_CHANGEMAP, "Restarts the game.");
		
	if(!CommandExists("sm_restart"))
		UC_RegAdminCmd("sm_restart", Command_RestartServer, ADMFLAG_CHANGEMAP, "Restarts the server after 5 seconds. Type again to abort restart.");
		
	if(!CommandExists("sm_restartserver"))
		UC_RegAdminCmd("sm_restartserver", Command_RestartServer, ADMFLAG_CHANGEMAP, "Restarts the server after 5 seconds. Type again to abort restart.");
		
	if(!CommandExists("sm_glow"))
		UC_RegAdminCmd("sm_glow", Command_Glow, ADMFLAG_BAN, "Puts glow on a player for all to see.");
		
	if(!CommandExists("sm_blink"))
		UC_RegAdminCmd("sm_blink", Command_Blink, ADMFLAG_BAN, "Teleports the player to where you are aiming");
		
	if(!CommandExists("sm_godmode"))
		UC_RegAdminCmd("sm_godmode", Command_Godmode, ADMFLAG_BAN, "Makes player immune to damage, not necessarily to death.");
		
	if(!CommandExists("sm_god"))
		UC_RegAdminCmd("sm_god", Command_Godmode, ADMFLAG_BAN, "Makes player immune to damage, not necessarily to death.");
		
	if(!CommandExists("sm_rocket"))
		UC_RegAdminCmd("sm_rocket", Command_Rocket, ADMFLAG_BAN, "The more handsome sm_slay command");
		
	if(!CommandExists("sm_disarm"))
		UC_RegAdminCmd("sm_disarm", Command_Disarm, ADMFLAG_BAN, "strips all of the player's weapons");	
		
	if(!CommandExists("sm_markofdeath"))
		UC_RegAdminCmd("sm_markofdeath", Command_MarkOfDeath, ADMFLAG_BAN, "marks the target with the mark of death, slowly murdering him");
	
	//if(!CommandExists("sm_cheat"))
		//UC_RegAdminCmd("sm_cheat", Command_Cheat, ADMFLAG_CHEATS, "Writes a command bypassing its cheat flag.");	
		
	if(!CommandExists("sm_last"))
	{
		UC_RegAdminCmd("sm_last", Command_Last, ADMFLAG_BAN, "sm_last [steamid/name/ip] Shows a full list of every single player that ever visited");
		RegAdminCmd("sm_uc_last_showip", Command_Last, ADMFLAG_ROOT);
	}	
	if(!CommandExists("sm_exec"))
		UC_RegAdminCmd("sm_exec", Command_Exec, ADMFLAG_BAN, "Makes a player execute a command. Use !fakeexec if doesn't work.");
		
	if(!CommandExists("sm_fakeexec"))
		UC_RegAdminCmd("sm_fakeexec", Command_FakeExec, ADMFLAG_BAN, "Makes a player execute a command. Use !exec if doesn't work.");
	
	if(!CommandExists("sm_brutexec"))
		UC_RegAdminCmd("sm_brutexec", Command_BruteExec, ADMFLAG_BAN, "Makes a player execute a command with !fakeexec but letting him have admin flags to accomplish the action. Use !exec if doesn't work.");
		
	if(!CommandExists("sm_bruteexec"))
		UC_RegAdminCmd("sm_bruteexec", Command_BruteExec, ADMFLAG_BAN, "Makes a player execute a command with !fakeexec but letting him have admin flags to accomplish the action. Use !exec if doesn't work.");
		
	if(!CommandExists("sm_money"))
		UC_RegAdminCmd("sm_money", Command_Money, ADMFLAG_GENERIC, "Sets a player's money.");
		
	if(!CommandExists("sm_team"))
		UC_RegAdminCmd("sm_team", Command_Team, ADMFLAG_GENERIC, "Sets a player's team.");
		
	if(!CommandExists("sm_xyz"))
		UC_RegAdminCmd("sm_xyz", Command_XYZ, ADMFLAG_GENERIC, "Prints your origin.");	
		
	if(!CommandExists("sm_silentcvar"))
		UC_RegAdminCmd("sm_silentcvar", Command_SilentCvar, ADMFLAG_ROOT, "Changes cvar without in-game notification."); // I cannot afford to allow less than Root as I cannot monitor protected cvars. Changing access flag means the admin can get rcon_password.
		
	if(!CommandExists("sm_acookies"))
		UC_RegAdminCmd("sm_acookies", Command_AdminCookies, ADMFLAG_ROOT, "Powerful cookie editing abilities");
		
	if(!CommandExists("sm_admincookies"))
		UC_RegAdminCmd("sm_admincookies", Command_AdminCookies, ADMFLAG_ROOT, "Powerful cookie editing abilities");
	
	if(!CommandExists("sm_findcvar"))
		UC_RegAdminCmd("sm_findcvar", Command_FindCvar, ADMFLAG_ROOT, "Finds a cvar, even if it's hidden. Searches for commands as well.");
		
	if(!CommandExists("sm_hug"))
		UC_RegConsoleCmd("sm_hug", Command_Hug, "Hugs a dead player.");
		
	UC_RegConsoleCmd("sm_uc", Command_UC, "Shows a list of UC commands.");
	
	if(isCSGO())
	{
		if(!CommandExists("sm_customace"))
			UC_RegConsoleCmd("sm_customace", Command_CustomAce, "Allows you to set a custom fun fact for ace.");
			
		hcv_PartyMode = FindConVar("sv_party_mode");
		
		hcv_ucPartyMode = UC_CreateConVar("uc_party_mode", "2", "0 = Nobody can access party mode. 1 = You can choose to participate in party mode. 2 = Zeus will cost 100$ as tradition", FCVAR_NOTIFY);
		hcv_ucPartyModeDefault = UC_CreateConVar("uc_party_mode_default", "3", "Party mode cookie to set for new comers. 0 = Disabled, 1 = Defuse balloons only, 2 = Zeus only, 3 = Both.");
	
		hCookie_EnablePM = RegClientCookie("UsefulCommands_PartyMode", "Party Mode flags. 0 = Disabled, 1 = Defuse balloons only, 2 = Zeus only, 3 = Both.", CookieAccess_Public);
		hCookie_AceFunFact = RegClientCookie("UsefulCommands_AceFunFact", "When you make an ace, this will be the fun fact to send to the server. $name -> your name. $team -> your team. $opteam -> your opponent team.", CookieAccess_Public);	
		
		hcv_mpAnyoneCanPickupC4 = FindConVar("mp_anyone_can_pickup_c4");
		
		HookConVarChange(hcv_ucSpecialC4Rules, OnSpecialC4RulesChanged);
			
		if(!CommandExists("sm_chicken"))
		{
			UC_RegAdminCmd("sm_chicken", Command_Chicken, ADMFLAG_BAN, "Allows you to set up the map's chicken spawns.");	
			UC_RegAdminCmd("sm_ucedit", Command_UCEdit, ADMFLAG_BAN, "Allows you to teleport to the chicken spawner prior to delete.");
			hcv_ucMaxChickens = UC_CreateConVar("uc_max_chickens", "5", "Maximum amount of chickens UC will generate.");
			hcv_ucMinChickenTime = UC_CreateConVar("uc_min_chicken_time", "5.0", "Minimum amount of time between a chicken's death and the recreation.");
			hcv_ucMaxChickenTime = UC_CreateConVar("uc_max_chicken_time", "10.0", "Maximum amount of time between a chicken's death and the recreation.");
		}
		
		if(!CommandExists("sm_wepstats"))
			UC_RegConsoleCmd("sm_wepstats", Command_WepStats, "Shows the stats of all weapons");
			
		if(!CommandExists("sm_weaponstats"))
			UC_RegConsoleCmd("sm_weaponstats", Command_WepStats, "Shows the stats of all weapons");
			
		//if(!CommandExists("sm_wepstatsvs"))
			//UC_RegConsoleCmd("sm_wepstatsvs", Command_WepStatsVS, "Compares the stats of 2 weapons");
			
		//if(!CommandExists("sm_weaponstatsvs"))
			//UC_RegConsoleCmd("sm_weaponstatsvs", Command_WepStatsVS, "Compares the stats of 2 weapons");
			
		
	}	
	
	
	#if defined _autoexecconfig_included
	
	AutoExecConfig_ExecuteFile();

	AutoExecConfig_CleanFile();
	
	#endif
}

public hcvChange_ucTag(Handle:convar, const String:oldValue[], const String:newValue[])
{
	FormatEx(UCTag, sizeof(UCTag), newValue);
}

public ConnectToDatabase()
{		
	new String:Error[256];
	if((dbLocal = SQLite_UseDatabase("sourcemod-local", Error, sizeof(Error))) == INVALID_HANDLE)
		LogError(Error);
	
	else
	{ 
		SQL_TQuery(dbLocal, SQLCB_Error, "CREATE TABLE IF NOT EXISTS UsefulCommands_LastPlayers (AuthId VARCHAR(32) NOT NULL UNIQUE, LastConnect INT(11) NOT NULL, IPAddress VARCHAR(32) NOT NULL, Name VARCHAR(64) NOT NULL)", DBPrio_High); 
		
		if(isCSGO())
		{
			SQL_TQuery(dbLocal, SQLCB_Error, "CREATE TABLE IF NOT EXISTS UsefulCommands_Chickens (ChickenOrigin VARCHAR(50) NOT NULL, ChickenMap VARCHAR(128), ChickenCreateDate INT(11) NOT NULL, UNIQUE(ChickenOrigin, ChickenMap))", DBPrio_High);		
				
			LoadChickenSpawns();
		}
	}
	
	if((dbClientPrefs = SQLite_UseDatabase("clientprefs-sqlite", Error, sizeof(Error))) == INVALID_HANDLE)
	{
		LogError(Error);
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

public OnEntityCreated(entity, const String:Classname[])
{
	if(StrEqual(Classname, "trigger_teleport", true))
		SDKHook(entity, SDKHook_SpawnPost, Event_TeleportSpawnPost);
	
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
	SetConVarString(CreateConVar("uc_version", PLUGIN_VERSION, _, FCVAR_NOTIFY), PLUGIN_VERSION); // Last resort due to past mistake.
	
	if(!isCSGO())
		return;
	
	new bool:Exists = FileExists(GAME_RULES_CVARS_PATH);
	
	new ucPacketNotifyCvars = GetConVarInt(hcv_ucPacketNotifyCvars);
	if( ucPacketNotifyCvars != 0 && ( !Exists || ( Exists && ucPacketNotifyCvars == 2 ) ) )
	{
		
		new Handle:SortArray = CreateArray(128);
		new Handle:keyValues = CreateKeyValues("NotifyRulesCvars");
		
		new String:CvarName[128], bool:bCommand, flags, String:sDummy_Value[1];
		new Handle:iterator = FindFirstConCommand(CvarName, sizeof(CvarName), bCommand, flags, sDummy_Value, 0)
		
		if(iterator != INVALID_HANDLE)
		{
			if(!bCommand && (flags & FCVAR_NOTIFY) && !(flags & FCVAR_PROTECTED))
				PushArrayString(SortArray, CvarName);
				
			while(FindNextConCommand(iterator, CvarName, sizeof(CvarName), bCommand, flags, sDummy_Value, 0))
			{
				if(bCommand)
					continue;
					
				else if(flags & FCVAR_NOTIFY && !(flags & FCVAR_PROTECTED))
					PushArrayString(SortArray, CvarName);
			}
			
			CloseHandle(iterator);
			
			SortADTArray(SortArray, Sort_Ascending, Sort_String);
			
			new size = GetArraySize(SortArray);
			
			for(new i=0;i < size;i++)
			{
				GetArrayString(SortArray, i, CvarName, sizeof(CvarName));
					
				KvSetNum(keyValues, CvarName, 1);
			}
			
			KvRewind(keyValues);
			
			KeyValuesToFile(keyValues, GAME_RULES_CVARS_PATH);
		}
		
		CloseHandle(SortArray);
	}	
	if(GetConVarBool(hcv_ucSpecialC4Rules))
		SetConVarBool(hcv_mpAnyoneCanPickupC4, true);
	
	new KeyValues:keyValues = CreateKeyValues("items_game");
	new KeyValues:CacheKeyValues = CreateKeyValues("items_game");
	
	new String:CachePath[256];
	BuildPath(Path_SM, CachePath, sizeof(CachePath), CACHE_ITEMS_GAME_PATH);
	
	CreateDirectory(CachePath, FPERM_ULTIMATE);
	
	SetFilePermissions(CachePath, FPERM_ULTIMATE); // Actually allow us to enter.
	
	Format(CachePath, sizeof(CachePath), "%s/items_game.txt", CachePath);
	
	new bool:ShouldCache = true;
	
	if(!FileExists(CachePath))
		ShouldCache = false;
	
	new CacheLastEdited = GetFileTime(CachePath, FileTime_LastChange);
	
	if(CacheLastEdited == -1)
		ShouldCache = false;
		
	new LastEdited = GetFileTime(ITEMS_GAME_PATH, FileTime_LastChange);
	
	if(LastEdited == -1)
		return;

	if(LastEdited > CacheLastEdited)
		ShouldCache = false;
		
	if(ShouldCache)
	{
		if(!FileToKeyValues(keyValues, CachePath))
		{
			if(!FileToKeyValues(keyValues, ITEMS_GAME_PATH))
				return;
			
			DeleteFile(CachePath);
			
			UC_CreateEmptyFile(CachePath);
			
			ShouldCache = false;
		}
	}
	else
	{		
		if(!FileToKeyValues(keyValues, ITEMS_GAME_PATH))
			return;
		
		DeleteFile(CachePath);
		
		UC_CreateEmptyFile(CachePath);
	}
	
	if(!KvGotoFirstSubKey(keyValues))
		return;

	new String:buffer[64], String:levelValue[64], position;
	
	KvSavePosition(keyValues);
	
	if(!ShouldCache)
		KvSavePosition(CacheKeyValues);
		
	do
	{
		KvGetSectionName(keyValues, buffer, sizeof(buffer));
		
		if(StrEqual(buffer, "items"))
		{
			KvGotoFirstSubKey(keyValues);
			
			if(!ShouldCache)
				KvJumpToKey(CacheKeyValues, "items", true);
				
			break;
		}
	}
	while(KvGotoNextKey(keyValues))
	
	do
	{
		KvGetSectionName(keyValues, buffer, sizeof(buffer));
		
		if(UC_IsStringNumber(buffer))
		{
			KvGetString(keyValues, "name", levelValue, sizeof(levelValue));
			
			position = StrContains(levelValue, "prestige", false);
			
			if(position != -1 && !ShouldCache)
			{	
				UC_KvCopyChildren(keyValues, CacheKeyValues, buffer);
			}	
			if(position == -1)
				SetTrieValue(Trie_CoinLevelValues, buffer, 0);
				
			else if((position = StrContains(levelValue, "level", false)) == -1)
			{
				IntToString(MAX_CSGO_LEVEL, levelValue, sizeof(levelValue));
				SetTrieValue(Trie_CoinLevelValues, buffer, StringToInt(levelValue));
			}
			else
			{
				SetTrieValue(Trie_CoinLevelValues, buffer, StringToInt(levelValue[position]));
			}
		}
	}
	while(KvGotoNextKey(keyValues))
	
	KvRewind(keyValues);
	KvGotoFirstSubKey(keyValues);
	
	if(!ShouldCache)
	{
		KvRewind(CacheKeyValues);
		KvGotoFirstSubKey(keyValues);
	}

	new WepNone = view_as<int>(CSWeapon_NONE);
	
	do
	{
		KvGetSectionName(keyValues, buffer, sizeof(buffer));
		
		if(StrEqual(buffer, "prefabs"))
		{
			KvGotoFirstSubKey(keyValues);
			
			if(!ShouldCache)
				KvJumpToKey(CacheKeyValues, "prefabs", true);
				
			break;
		}
	}
	while(KvGotoNextKey(keyValues))
	
	// Now we save position of prefabs and find all default values for damage, fire rate, and etc.
	
	KvSavePosition(keyValues);
	
	if(!ShouldCache)
		KvSavePosition(CacheKeyValues);

	do
	{
		KvGetSectionName(keyValues, buffer, sizeof(buffer));
		
		if(StrEqual(buffer, "statted_item_base"))
		{
			KvGotoFirstSubKey(keyValues);
			
			if(!ShouldCache)
			{
				KvJumpToKey(CacheKeyValues, "statted_item_base", true);
			}	
			break;
		}
	}
	while(KvGotoNextKey(keyValues))
	
	do
	{
		KvGetSectionName(keyValues, buffer, sizeof(buffer));
	
		if(StrEqual(buffer, "attributes"))
		{
			KvGotoFirstSubKey(keyValues);
				
			if(!ShouldCache)
			{
				UC_KvCopyChildren(keyValues, CacheKeyValues, "attributes");
			}	
			
			break;
		}
	}
	while(KvGotoNextKey(keyValues))
	
	// Default values.
	wepStatsList[WepNone][wepStatsFireRate] = RoundFloat((1.0 / KvGetFloat(keyValues, "cycletime", -1.0)) * 60.0); // By RPM = Rounds per Minute. Note: NEVER ALLOW DEFAULT VALUE 0.0 WHEN DIVIDING IT!!!
	wepStatsList[WepNone][wepStatsArmorPenetration] = KvGetFloat(keyValues, "armor ratio") * 50.0; // It maxes at 2.000 to be 100% armor penetration.
	wepStatsList[WepNone][wepStatsKillAward] = KvGetNum(keyValues, "kill award");
	wepStatsList[WepNone][wepStatsWallPenetration] = KvGetFloat(keyValues, "penetration");
	wepStatsList[WepNone][wepStatsDamageDropoff] = RoundFloat(100.0 - KvGetFloat(keyValues, "range modifier") * 100.0);
	wepStatsList[WepNone][wepStatsMaxDamageRange] = KvGetNum(keyValues, "range");
	wepStatsList[WepNone][wepStatsPalletsPerShot] = KvGetNum(keyValues, "bullets");
	wepStatsList[WepNone][wepStatsDamage] = KvGetNum(keyValues, "damage");
	wepStatsList[WepNone][wepStatsIsAutomatic] = view_as<bool>(KvGetNum(keyValues, "is full auto"));
	
	KvGoBack(keyValues);
	
	if(!ShouldCache)
		KvGoBack(CacheKeyValues);

	new String:CompareBuffer[64], String:Alias[64];
	do
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
							
							if(!ShouldCache)
								KvJumpToKey(CacheKeyValues, buffer, true);
							
							new bool:bBreak = false;
							do
							{
								KvGetSectionName(keyValues, buffer, sizeof(buffer)); // We can overwrite the last buffer we took, it's irrelevant now :D
	
								if(StrEqual(buffer, "attributes"))
								{
									KvGotoFirstSubKey(keyValues);
									bBreak = true;
								}
							}
							while(!bBreak && KvGotoNextKey(keyValues)) // Find them attributes.
						
							new Float:cycletime;
							wepStatsList[i][wepStatsFireRate] = RoundFloat((1.0 / (cycletime=KvGetFloat(keyValues, "cycletime", -1.0))) * 60.0); // By RPM = Rounds per Minute. Note: NEVER ALLOW DEFAULT VALUE 0.0 WHEN DIVIDING IT!!!
							
							if(wepStatsList[i][wepStatsFireRate] == -60)
							{
								wepStatsList[i][wepStatsFireRate] = wepStatsList[WepNone][wepStatsFireRate];
								cycletime = (1.0 / (wepStatsList[i][wepStatsFireRate] / 60.0));
							}
							wepStatsList[i][wepStatsArmorPenetration] = KvGetFloat(keyValues, "armor ratio", -1.0) * 50.0; // It maxes at 2.000 to be 100% armor penetration.
							
							if(wepStatsList[i][wepStatsArmorPenetration] == -50.0)
								wepStatsList[i][wepStatsArmorPenetration] = wepStatsList[WepNone][wepStatsArmorPenetration];
								
							wepStatsList[i][wepStatsKillAward] = KvGetNum(keyValues, "kill award", wepStatsList[WepNone][wepStatsKillAward]); // It maxes at 2.000 to be 100% armor penetration.
							
							wepStatsList[i][wepStatsWallPenetration] = KvGetFloat(keyValues, "penetration", wepStatsList[WepNone][wepStatsWallPenetration]);
							
							new Float:Range;
							wepStatsList[i][wepStatsDamageDropoff] = RoundFloat(100.0 - (Range=KvGetFloat(keyValues, "range modifier")) * 100.0);
							
							if(Range == 0.0)
							{
								wepStatsList[i][wepStatsDamageDropoff] = wepStatsList[WepNone][wepStatsDamageDropoff];
								Range = (100.0 - float(wepStatsList[i][wepStatsDamageDropoff])) / 100.0;
							}
								
							wepStatsList[i][wepStatsMaxDamageRange] = KvGetNum(keyValues, "range", wepStatsList[WepNone][wepStatsMaxDamageRange]);
							wepStatsList[i][wepStatsPalletsPerShot] = KvGetNum(keyValues, "bullets", wepStatsList[WepNone][wepStatsPalletsPerShot]);
							wepStatsList[i][wepStatsDamage] = (wepStatsList[i][wepStatsDamagePerPallet] = KvGetNum(keyValues, "damage", wepStatsList[WepNone][wepStatsDamage])) * wepStatsList[i][wepStatsPalletsPerShot];
							
							wepStatsList[i][wepStatsIsAutomatic] = view_as<bool>(KvGetNum(keyValues, "is full auto", wepStatsList[WepNone][wepStatsIsAutomatic]));
							// Now we calculate one tap distance. 
							
							if(FloatCompare(Range, 0.0) == 0 || FloatCompare(Range, 1.0) == 0)
								Range = 0.000001; // Close to zero but nyeahhhh
								
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
							
							wepStatsList[i][wepStatsDamagePerSecondNoArmor] = RoundFloat((1.0 / cycletime) * wepStatsList[i][wepStatsDamage]);
							wepStatsList[i][wepStatsDamagePerSecondArmor] = RoundFloat((1.0 / cycletime) * wepStatsList[i][wepStatsDamage] * (wepStatsList[i][wepStatsArmorPenetration]/100));
							
							if(!ShouldCache)
							{
								UC_KvCopyChildren(keyValues, CacheKeyValues, "attributes");
								KvGoBack(CacheKeyValues);
							}
							KvGoBack(keyValues);
							
							
							
							i = CSWeapon_MAX_WEAPONS; // Equivalent of break.
						}
					}
				}
			}
		}
	}
	while(KvGotoNextKey(keyValues))

	if(!ShouldCache)
	{	
		KvRewind(CacheKeyValues);
		KeyValuesToFile(CacheKeyValues, CachePath); // Note to self: KvRewind always when using KeyValuesToFile because it uses current position.
	}	
	
	CloseHandle(keyValues);
	CloseHandle(CacheKeyValues);
	
	Call_StartForward(fw_ucWeaponStatsRetrievedPost);
	
	Call_Finish(keyValues); // keyValues was already disposed.

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

	UC_PrintToChatAll("b");
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
	
	new clients[MaxClients+1];
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
	
	new clients[MaxClients+1];
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
	if(RestartNR)
	{
		CreateTimer(0.5, RestartServer, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	// AceCandidate is -1 for nobody and -2 for disqualification of the team.
	AceCandidate[CS_TEAM_CT] = -1;
	AceCandidate[CS_TEAM_T] = -1;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		TrueTeam[i] = 0;
		RoundKills[i] = 0;
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
		UC_PrintToChat(client, "%T", "Party Mode is Disabled", client);
		return;
	}	
	ShowPartyModeMenu(client);
} 
public ShowPartyModeMenu(client)
{
	new Handle:hMenu = CreateMenu(PartyModeMenu_Handler);
	
	new String:TempFormat[64];
	switch(GetClientPartyMode(client))
	{
		case PARTYMODE_DEFUSE:
		{
			Format(TempFormat, sizeof(TempFormat), "%T", "Party Mode Cookie Menu: Defuse Only", client);
			AddMenuItem(hMenu, "", TempFormat);	
		}	
		
		case PARTYMODE_ZEUS:
		{
			Format(TempFormat, sizeof(TempFormat), "%T", "Party Mode Cookie Menu: Zeus Only", client);
			AddMenuItem(hMenu, "", TempFormat);	
		}
		
		case PARTYMODE_DEFUSE|PARTYMODE_ZEUS:
		{
			Format(TempFormat, sizeof(TempFormat), "%T", "Party Mode Cookie Menu: Enabled", client);
			AddMenuItem(hMenu, "", TempFormat);
		}
		
		default:
		{
			Format(TempFormat, sizeof(TempFormat), "%T", "Party Mode Cookie Menu: Disabled", client);
			AddMenuItem(hMenu, "", TempFormat);
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
		
		ShowPartyModeMenu(client);
	}
	return 0;
}


public Action:Event_PlayerSpawn(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	SDKUnhook(client, SDKHook_PostThink, Hook_PostThink);
	
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
	
	RoundKills[attacker]++;
	
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
					
				if(Winner == 0 ||	Winner != 0 && (client == Winner || GetClientTeam(Winner) != CS_TEAM_T) || !IsPlayerAlive(Winner))
					Winner = GetClientOfUserId(GetEventInt(hEvent, "assister"));
					
				if(Winner == 0 || Winner != 0 && (client == Winner || GetClientTeam(Winner) != CS_TEAM_T) || !IsPlayerAlive(Winner))
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
	
	if(Winner == 0 || RoundKills[Winner] == 0)
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
	Call_PushCellRef(RoundKills[Winner]);
	
	new Action:Result;
	Call_Finish(Result);
	
	if(Result == Plugin_Stop)
		return Plugin_Continue;
	
	if(Result != Plugin_Changed)
	{
		Winner = GetClientOfUserId(AceCandidate[WinningTeam]);
		GetClientAceFunFact(Winner, TokenToUse, sizeof(TokenToUse));
	}
	
	if(Result != Plugin_Handled)
	{
		SetEventInt(hEvent, "funfact_player", Winner);
		
		SetEventString(hEvent, "funfact_token", TokenToUse);
		
		if(isCSGO())
			SetEventInt(hEvent, "funfact_data1", 420); // The percent of players killed ( in theory always 100 in ace but !revive can push it further. )
		
		else
			SetEventInt(hEvent, "funfact_data1", 100); // The percent of players killed ( in theory always 100 in ace but !revive can push it further. )
	}
	if(!AceSent)
	{
		AceSent = true;
		
		Call_StartForward(fw_ucAcePost);
		
		Call_PushCell(Winner);
		Call_PushString(TokenToUse);
		Call_PushCell(RoundKills[Winner]);
		
		Call_Finish();
	}
	return Plugin_Changed;
}

public UsefulCommands_OnPlayerAcePost(client, const String:FunFact[])
{
	if(GetConVarInt(hcv_ucAcePriority) > 0)
	{
		UC_PrintToChatAll("%s%t", UCTag, "Scored an Ace", client);
	}
}

public OnClientPutInServer(client)
{
	DeathOrigin[client] = NULL_VECTOR;
	UberSlapped[client] = false;
	isHugged[client] = true;
	
	UCEdit[client] = false;
	FullInGame[client] = true;
	
	if(TIMER_ANNOUNCEPLUGIN[client] != INVALID_HANDLE)
	{
		CloseHandle(TIMER_ANNOUNCEPLUGIN[client]);
		TIMER_ANNOUNCEPLUGIN[client] = INVALID_HANDLE;
	}
	
	new Float:AnnounceTimer = GetConVarFloat(hcv_ucAnnouncePlugin);
	
	if(AnnounceTimer != 0.0)
		TIMER_ANNOUNCEPLUGIN[client] = CreateTimer(AnnounceTimer, Timer_AnnounceUCPlugin, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		
	SDKHook(client, SDKHook_WeaponDropPost, Event_WeaponDropPost);
	SDKHook(client, SDKHook_WeaponEquipPost, Event_WeaponPickupPost);
	SDKHook(client, SDKHook_OnTakeDamagePost, Event_OnTakeDamagePost);
}


public Action:Timer_AnnounceUCPlugin(Handle:hTimer, UserId)
{
	new client = GetClientOfUserId(UserId);
	
	if(client == 0)
		return Plugin_Continue;

	TIMER_ANNOUNCEPLUGIN[client] = INVALID_HANDLE;
	UC_PrintToChat(client, "%t", "UC Advertise");
	UC_PrintToChat(client, "%t", "UC Advertise 2");
	return Plugin_Continue;
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
	if(TIMER_LIFTOFF[client] != INVALID_HANDLE)
	{
		CloseHandle(TIMER_LIFTOFF[client]);
		TIMER_LIFTOFF[client] = INVALID_HANDLE;
	}
	if(TIMER_ROCKETCHECK[client] != INVALID_HANDLE)
	{
		CloseHandle(TIMER_ROCKETCHECK[client]);
		TIMER_ROCKETCHECK[client] = INVALID_HANDLE;
	}
	if(TIMER_LASTC4[client] != INVALID_HANDLE)
	{
		CloseHandle(TIMER_LASTC4[client]);
		TIMER_LASTC4[client] = INVALID_HANDLE;
	}	
	if(TIMER_ANNOUNCEPLUGIN[client] != INVALID_HANDLE)
	{
		CloseHandle(TIMER_ANNOUNCEPLUGIN[client]);
		TIMER_ANNOUNCEPLUGIN[client] = INVALID_HANDLE;
	}
	new String:AuthId[32];
	if(!IsFakeClient(client) && GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId)))
	{
		new String:sQuery[256];
		
		new String:Name[32], String:IPAddress[32], CurrentTime = GetTime();
		GetClientName(client, Name, sizeof(Name));
		GetClientIP(client, IPAddress, sizeof(IPAddress));
		Format(sQuery, sizeof(sQuery), "INSERT OR IGNORE INTO UsefulCommands_LastPlayers (AuthId, IPAddress, Name, LastConnect) VALUES (\"%s\", \"%s\", \"%s\", %i)", AuthId, IPAddress, Name, CurrentTime);
		SQL_TQuery(dbLocal, SQLCB_Error, sQuery, DBPrio_High);
		
		Format(sQuery, sizeof(sQuery), "UPDATE UsefulCommands_LastPlayers SET IPAddress = \"%s\", Name = \"%s\", LastConnect = %i WHERE AuthId = \"%s\"", IPAddress, Name, CurrentTime, AuthId);
		SQL_TQuery(dbLocal, SQLCB_Error, sQuery, _, DBPrio_Normal);
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

public OnMapStart()
{
	RestartNR = true;
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
		TIMER_LASTC4[i] = INVALID_HANDLE;
		TIMER_ANNOUNCEPLUGIN[i] = INVALID_HANDLE;
	}
	
	hRestartTimer = INVALID_HANDLE;
	hRRTimer = INVALID_HANDLE;
	RestartNR = false;
	
	RequestFrame(RestartRoundOnMapStart, 0);
}

public RestartRoundOnMapStart(dummy_value)
{
	if(!isLateLoaded && GetConVarBool(hcv_ucRestartRoundOnMapStart))
		CS_TerminateRound(0.1, CSRoundEnd_Draw, true);
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
		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Target", arg0);
		return Plugin_Handled;
	}

	new String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients+1], target_count, bool:tn_is_ml;

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
		
		UC_RespawnPlayer(target);
	}
	
	UC_ShowActivity2(client, UCTag, "%t", "Player Respawned", target_name);
	
	return Plugin_Handled;
}

public Action:Command_HardRevive(client, args)
{	
	if (args < 1)
	{
		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Target", arg0);
		return Plugin_Handled;
	}

	new String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients+1], target_count, bool:tn_is_ml;

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
			TeleportEntity(target, DeathOrigin[target], NULL_VECTOR, NULL_VECTOR);
	}
	
	UC_ShowActivity2(client, UCTag, "%t", "Player Hard Respawned", target_name);
	
	return Plugin_Handled;
}


public Action:Command_Bury(client, args)
{	
	if (args < 1)
	{
		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Target Toggle", arg0);
		return Plugin_Handled;
	}

	new String:arg[65], String:arg2[5];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));

	if(StrEqual(arg2, ""))
		arg2 = "1";
		
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients+1], target_count, bool:tn_is_ml;

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
			if(IsPlayerStuck(target) && target_count == 1)
			{
				UC_ReplyToCommand(client, "%s%t", UCTag, "Already Buried", target);
				return Plugin_Handled;
			}	
			UC_BuryPlayer(target);
		}
		else
		{
			if(!IsPlayerStuck(target))
			{
				if(target_count == 1)
				{
					UC_ReplyToCommand(client, "%s%t", UCTag, "Already Not Buried", target);
					return Plugin_Handled;
				}
				
				continue;
			}
			UC_UnburyPlayer(target);
		}
	}
	
	if(bury)
		UC_ShowActivity2(client, UCTag, "%t", "Player Buried", target_name);
		
	else
		UC_ShowActivity2(client, UCTag, "%t", "Player Unburied", target_name);
		
	return Plugin_Handled;
}

public Action:Command_Unbury(client, args)
{	
	if (args < 1)
	{
		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Target", arg0);
		return Plugin_Handled;
	}

	new String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
		
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients+1], target_count, bool:tn_is_ml;

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
			if(target_count == 1)
			{
				UC_ReplyToCommand(client, "%s%t", UCTag, "Already Not Buried", target);
				return Plugin_Handled;
			}
			
			continue;
		}
		UC_UnburyPlayer(target);
	}
	
	UC_ShowActivity2(client, UCTag, "%t", "Player Unburied", target_name);
	return Plugin_Handled;
}
public Action:Command_UberSlap(client, args)
{
	if (args < 1)
	{
		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Target Toggle", arg0);
		return Plugin_Handled;
	}

	new String:arg[65], String:arg2[5];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));

	if(StrEqual(arg2, ""))
		arg2 = "1";
		
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients+1], target_count, bool:tn_is_ml;

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
				if(target_count == 1)
				{
					UC_ReplyToCommand(client, "%s%t", UCTag, "Player Already Uberslapped", target);
					return Plugin_Handled;
				}
				
				continue;
			}
			UberSlapped[target] = true;
			TotalSlaps[target] = 0;
			
			TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, Float:{0.0, 0.0, 10.0});
			TriggerTimer(TIMER_UBERSLAP[target] = CreateTimer(0.1, Timer_UberSlap, GetClientUserId(target), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE), true);
		}
		else
		{
			if(!UberSlapped[target])
			{
				if(target_count == 1)
				{
					UC_ReplyToCommand(client, "%s%t", UCTag, "Player Already Not Uberslapped", target);
					return Plugin_Handled;
				}
				
				continue;
			}
			UberSlapped[target] = false;
			if(TIMER_UBERSLAP[target] != INVALID_HANDLE)
			{
				CloseHandle(TIMER_UBERSLAP[target]);
				TIMER_UBERSLAP[target] = INVALID_HANDLE;
			}
		}
		
		if(slap)
			UC_ShowActivity2(client, UCTag, "%t", "Player Uberslapped", target_name);
			
		else
			UC_ShowActivity2(client, UCTag, "%t", "Player Stop Uberslap", target_name);
	}
	return Plugin_Handled;
}

public Action:Timer_UberSlap(Handle:hTimer, UserId)
{
	new client = GetClientOfUserId(UserId);
	
	if(client == 0)
		return Plugin_Stop;

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
		UC_PrintToChat(client, "%s\x02Uberslap has ended.\x04 Prepare your landing!", UCTag);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}


public Action:Command_Heal(client, args)
{
	if (args < 1)
	{
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Heal");
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Note Heal");
		return Plugin_Handled;
	}

	new String:arg[65], String:arg2[11], String:arg3[11], String:arg4[3];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	GetCmdArg(4, arg4, sizeof(arg4));
	StripQuotes(arg2);
		
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients+1], target_count, bool:tn_is_ml;

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

	if(args == 1)
		arg2 = "max";
		
	new health = UC_IsStringNumber(arg2) ? StringToInt(arg2) : -1;

	if(health > MAX_POSSIBLE_HP)
		health = MAX_POSSIBLE_HP;
		
	new armor = UC_IsStringNumber(arg3) ? StringToInt(arg3) : -1;
	
	if(armor > 255 || StrEqual(arg3, "max"))
		armor = 255;
		
	new helmet = UC_IsStringNumber(arg4) ? StringToInt(arg4) : -1;
	
	new String:ActivityBuffer[256];
	
	if(helmet > 2) // The helmet will never be a negative.
		helmet = -1;

	new bool:bHelmet = view_as<bool>(helmet);
	for(new i=0;i < target_count;i++)
	{
		new target = target_list[i];
		
		if(StrEqual(arg2, "max"))
			health = GetEntProp(target, Prop_Data, "m_iMaxHealth");
		
		Format(ActivityBuffer, sizeof(ActivityBuffer), "%t", "Heal Admin Set", target);
		
		if(health != -1)
		{
			SetEntityHealth(target, health);
			Format(ActivityBuffer, sizeof(ActivityBuffer), "%s%t", ActivityBuffer, "Heal Admin Set Health", health);
		}
		if(armor != -1)
		{
			SetClientArmor(target, armor);
			Format(ActivityBuffer, sizeof(ActivityBuffer), "%s%t", ActivityBuffer, "Heal Admin Set Armor", armor);
		}
		if(helmet != -1)
		{
			SetClientHelmet(target, bHelmet);
			
			Format(ActivityBuffer, sizeof(ActivityBuffer), "%s%t", ActivityBuffer, "Heal Admin Set Helmet", helmet);
		}
		
		new length = strlen(ActivityBuffer);
		ActivityBuffer[length-2] = '.';
		ActivityBuffer[length-1] = EOS;
		UC_ShowActivity2(client, UCTag, ActivityBuffer); 
	}
	return Plugin_Handled;
}

public Action:Command_Give(client, args)
{
	if (args < 2)
	{
		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Give", arg0);
		return Plugin_Handled;
	}

	new String:arg[65], String:arg2[65];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients+1], target_count, bool:tn_is_ml;

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
	
	new length = strlen(WeaponName);
	
	for(new a=0;a < length;a++)
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

		if(StrEqual(arg2, "weapon_defuse", false) || StrEqual(arg2, "weapon_defuser", false) || StrEqual(arg2, "weapon_kit", false))
		{
			arg2 = "item_defuser";
			
			weapon = -1;
		}
		else if((weapon = GivePlayerItem(target, arg2)) == -1)
		{
			UC_ReplyToCommand(client, "%s%t", UCTag, "Command Give Invalid Weapon", WeaponName);
			
			return Plugin_Handled;
		}
		
		if(weapon != -1)
		{
			RemovePlayerItem(target, weapon);
			
			AcceptEntityInput(weapon, "Kill");
		}
		
		if(StrEqual(arg2, "weapon_c4"))
		{
			if(GetClientTeam(target) == CS_TEAM_CT)
			{	
				
				if(isCSGO())
				{
					new String:OldValue[32];
					GetConVarString(hcv_mpAnyoneCanPickupC4, OldValue, sizeof(OldValue));
					
					if(!GetConVarBool(hcv_mpAnyoneCanPickupC4))
					{
						SetConVarString(hcv_mpAnyoneCanPickupC4, "1UsefulCommands1");
					
						new Handle:DP = CreateDataPack();
						
						WritePackCell(DP, target);
						WritePackString(DP, OldValue);
						RequestFrame(EquipBombToPlayer, DP);
					}
					else
						GivePlayerItem(target, "weapon_c4");
				}
				else
				{
				
					SetEntProp(target, Prop_Send, "m_iTeamNum", CS_TEAM_T);
					
					GivePlayerItem(target, "weapon_c4");
					
					SetEntProp(target, Prop_Send, "m_iTeamNum", CS_TEAM_CT);
				}
			}
			else
				weapon = GivePlayerItem(target, arg2);
		}
		else
		{
			weapon = CreateEntityByName("game_player_equip");
		
			DispatchKeyValue(weapon, arg2, "1");
			
			DispatchKeyValue(weapon, "spawnflags", "1");
			
			AcceptEntityInput(weapon, "use", target);
			
			AcceptEntityInput(weapon, "Kill");
			
			weapon = -1;
		}
		
	}
	
	UC_ShowActivity2(client, UCTag, "%t", "Player Given Weapon", WeaponName, target_name); 

	return Plugin_Handled;
}

public EquipBombToPlayer(Handle:DP)
{
	ResetPack(DP);
	
	new target = ReadPackCell(DP);
	
	new String:OldValue[32];
	ReadPackString(DP, OldValue, sizeof(OldValue));
	
	CloseHandle(DP);
	GivePlayerItem(target, "weapon_c4");
	
	SetConVarString(hcv_mpAnyoneCanPickupC4, OldValue);
}

public Action:Command_RestartRound(client, args)
{
	if(hRRTimer != INVALID_HANDLE)
	{
		CloseHandle(hRestartTimer);
		hRestartTimer = INVALID_HANDLE;
	}
	
	new Float:SecondsBeforeRestart;
	new String:Arg[15];
	if(args > 0)
	{
		GetCmdArg(1, Arg, sizeof(Arg));
	
		SecondsBeforeRestart = StringToFloat(Arg);
	}
	else
		SecondsBeforeRestart = 1.0;
		
	
	if(SecondsBeforeRestart > 0.3)
	{
		new iSecondsBeforeRestart = RoundFloat(SecondsBeforeRestart);
		
		new String:strSecondsBeforeRestart[11];
		IntToString(iSecondsBeforeRestart, strSecondsBeforeRestart, sizeof(strSecondsBeforeRestart));
		
		switch(isCSGO())
		{
			case true:
			{
				if(iSecondsBeforeRestart == 1)
					Format(Arg, sizeof(Arg), "#SFUI_Second");
					
				else 
					Format(Arg, sizeof(Arg), "#SFUI_Seconds");
			}
			case false:
			{
				if(iSecondsBeforeRestart == 1)
					Format(Arg, sizeof(Arg), "SECOND"); // It won't even translate the word "seconds" lmao.
					
				else 
					Format(Arg, sizeof(Arg), "SECONDS");
			}
		}	
		
		UC_PrintCenterTextAll("#Game_will_restart_in", strSecondsBeforeRestart, Arg);
	
		if(iSecondsBeforeRestart == 1)
			Format(Arg, sizeof(Arg), "Second");
			
		else 
			Format(Arg, sizeof(Arg), "Seconds");

		UC_PrintToChatAll("%s%t", UCTag, "Admin Restart Round", client, iSecondsBeforeRestart, Arg);
		hRRTimer = CreateTimer(SecondsBeforeRestart, RestartRound, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		if(hRRTimer != INVALID_HANDLE)
		{
			CloseHandle(hRRTimer);
			hRRTimer = INVALID_HANDLE;
		}
		UC_PrintToChatAll("%s%t", UCTag, "Admin Stopped Restart Round", client);
	}
	return Plugin_Handled;
}

public Action:RestartRound(Handle:hTimer)
{
	hRRTimer = INVALID_HANDLE;	
	
	CS_TerminateRound(0.1, CSRoundEnd_Draw, true);
}

public Action:Command_RestartGame(client, args)
{
	new SecondsBeforeRestart;
	
	new String:Arg[11];
	
	if(args > 0)
	{
		GetCmdArg(1, Arg, sizeof(Arg));
		
		SecondsBeforeRestart = StringToInt(Arg);
	}
	else
		SecondsBeforeRestart = 1;
	
	ServerCommand("mp_restartgame %i", SecondsBeforeRestart);
	
	if(SecondsBeforeRestart != 0)
	{
		if(SecondsBeforeRestart == 1)
			Format(Arg, sizeof(Arg), "Second");
			
		else 
			Format(Arg, sizeof(Arg), "Seconds");
		
		UC_PrintToChatAll("%s%t", UCTag, "Admin Restart Game", client, SecondsBeforeRestart, Arg);
	}	
	else
	{
		if(isCSGO())
		{
			GameRules_SetProp("m_bGameRestart", 0);
			GameRules_SetPropFloat("m_flRestartRoundTime", 0.0);
		}	
		UC_PrintToChatAll("%s%t", UCTag, "Admin Stopped Restart Game", client);
	}
	return Plugin_Handled;
}

public Action:Command_RestartServer(client, args)
{
	if(hRestartTimer == INVALID_HANDLE && !RestartNR)
	{
		new String:Arg[15];

		GetCmdArg(1, Arg, sizeof(Arg));

		new SecondsBeforeRestart;
		if(!StrEqual(Arg, "NR", false) && !StrEqual(Arg, "Next Round", false) && !StrEqual(Arg, "NextRound", false))
		{	
			if(args > 0)
				SecondsBeforeRestart = StringToInt(Arg);

			else
				SecondsBeforeRestart = 5;
			
			if(SecondsBeforeRestart == 0)
			{
				if(hRestartTimer != INVALID_HANDLE)
				{
					CloseHandle(hRestartTimer);
					hRestartTimer = INVALID_HANDLE;
				}
				return Plugin_Handled;
			}
			
			hRestartTimer = CreateTimer(float(SecondsBeforeRestart), RestartServer, _, TIMER_FLAG_NO_MAPCHANGE);
			
			if(SecondsBeforeRestart == 1)
				Format(Arg, sizeof(Arg), "Second");
				
			else 
				Format(Arg, sizeof(Arg), "Seconds");
				
			UC_PrintToChatAll("%s%t", UCTag, "Admin Restart Server", client, SecondsBeforeRestart, Arg);
		}
		else
		{
			RestartNR = true;
			UC_PrintToChatAll("%s%t", UCTag, "Admin Restart Server Next Round", client);
		}
	}
	else
	{
		CloseHandle(hRestartTimer);
		hRestartTimer = INVALID_HANDLE;
		
		RestartNR = false;
		UC_PrintToChatAll("%s%t", UCTag, "Admin Stopped Restart Server", client);
	}
	
	return Plugin_Handled;
}

public Action:RestartServer(Handle:hTimer)
{
	hRestartTimer = INVALID_HANDLE;	
	
	UC_RestartServer();
}

public Action:Command_Glow(client, args)
{
	if (args < 1)
	{
		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Glow", arg0);
		return Plugin_Handled;
	}
	new String:arg[65], String:arg2[50];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));

	if(StrEqual(arg2, "color", false) || StrEqual(arg2, "colors", false))
	{
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Glow List");
		
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
				UC_ReplyToCommand(client, "%s%t", UCTag, "Command Glow Invalid");
				return Plugin_Handled;
			}
		}
	}
		
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients+1], target_count, bool:tn_is_ml;

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
			

			if(!UC_CreateGlow(target, Color) && target_count == 1)
			{
				UC_ReplyToCommand(client, "%s%t", UCTag, "Command Glow Failed to Give");
				return Plugin_Handled;
			}
		}
		else
		{
			if(!UC_TryDestroyGlow(target) && target_count == 1)
			{
				UC_ReplyToCommand(client, "%s%t", UCTag, "Command Glow Failed to Remove", target);
				return Plugin_Handled;
			}	
		}
	}
	
	
	if(glow)
		UC_ShowActivity2(client, UCTag, "%t", "Player Given Glow", target_name); 
		
	else
		UC_ShowActivity2(client, UCTag, "%t", "Player Removed Glow", target_name); 
		
	return Plugin_Handled;
}

public Action:Command_Blink(client, args)
{
	if (args < 1)
	{
		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Target", arg0);
		return Plugin_Handled;
	}

	new String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients+1], target_count, bool:tn_is_ml;

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
		
		new Float:Origin[3];
		if(!UC_GetAimPositionBySize(client, target, Origin))
		{
			ReplyToCommand(client, "Cannot teleport");
			return Plugin_Handled;
		}
		
		TeleportEntity(target, Origin, NULL_VECTOR, NULL_VECTOR);
	}
	
	UC_ShowActivity2(client, UCTag, "%t", "Player Blinked", target_name); 
	
	return Plugin_Handled;
}

public Action:Command_Godmode(client, args)
{
	if (args < 1)
	{
		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Target Toggle", arg0);
		return Plugin_Handled;
	}

	new String:arg[65], String:arg2[5];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));

	if(StrEqual(arg2, ""))
		arg2 = "1";
		
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients+1], target_count, bool:tn_is_ml;

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
			if(UC_GetClientGodmode(target) && target_count == 1)
			{
				UC_ReplyToCommand(client, "%s%t", UCTag, "Already Godmode", target);
				return Plugin_Handled;
			}

			UC_SetClientGodmode(target, true);
		}
		else
		{
			if(!UC_GetClientGodmode(target) && target_count == 1)
			{
				UC_ReplyToCommand(client, "%s%t", UCTag, "Already Not Godmode", target);
				return Plugin_Handled;
			}
			
			UC_SetClientGodmode(target, false);
		}
	}
	
	if(god)
		UC_ShowActivity2(client, UCTag, "%t", "Player Given Godmode", target_name);
		
	else
		UC_ShowActivity2(client, UCTag, "%t", "Player Removed Godmode", target_name);
		
	return Plugin_Handled;
}

public Action:Command_Rocket(client, args)
{
	if (args < 1)
	{
		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Target Toggle", arg0);
		return Plugin_Handled;
	}

	new String:arg[65], String:arg2[65];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));

	if(StrEqual(arg2, ""))
		arg2 = "1";
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients+1], target_count, bool:tn_is_ml;

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
		
		UC_SetClientRocket(target, rocket);
	}
	
	if(rocket)
		UC_ShowActivity2(client, UCTag, "%t", "Player Given Rocket", target_name); 
	
	else 
		UC_ShowActivity2(client, UCTag, "%t", "Player Removed Rocket", target_name);
		
	return Plugin_Handled;
}


public Action:Command_Disarm(client, args)
{
	if (args < 1)
	{
		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Target", arg0);
		return Plugin_Handled;
	}

	new String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients+1], target_count, bool:tn_is_ml;

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
		
		UC_StripPlayerWeapons(target);
	}
	
	UC_ShowActivity2(client, UCTag, "%t", "Player Stripped", target_name);
	
	return Plugin_Handled;
}


public Action:Command_MarkOfDeath(client, args)
{	
	if (args < 1)
	{
		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Target Toggle", arg0);
		return Plugin_Handled;
	}

	new String:arg[65], String:arg2[5];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));

	if(StrEqual(arg2, ""))
		arg2 = "1";
		
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients+1], target_count, bool:tn_is_ml;

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
	
	new bool:mark = (StringToInt(arg2) != 0);
	
	for(new i=0;i < target_count;i++)
	{
		new target = target_list[i];
		
		UC_DeathMarkPlayer(target, mark);
	}
	
	if(mark)
		UC_ShowActivity2(client, UCTag, "%t", "Player Marked", target_name);
		
	else
		UC_ShowActivity2(client, UCTag, "%t", "Player Unmarked", target_name);
		
	return Plugin_Handled;
}

public Hook_PostThink(client)
{
	SetEntProp(client, Prop_Data, "m_nWaterLevel", 3);
}	
public Action:Command_Exec(client, args)
{
	if (args < 2)
	{
		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Execute", arg0);
		return Plugin_Handled;
	}

	new String:arg[65], String:ExecCommand[150];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArgString(ExecCommand, sizeof(ExecCommand));
	StripQuotes(ExecCommand);
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients+1], target_count, bool:tn_is_ml;
	
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

		ClientCommand(target, ExecCommand);
	}
	
	UC_ShowActivity2(client, UCTag, "%t", "Player Executed", ExecCommand, target_name);
	LogAction(client, -1, "\"%L\" executed \"%s\" on \"%s\"", client, ExecCommand, target_name);
	
	return Plugin_Handled;
}


public Action:Command_FakeExec(client, args)
{
	if (args < 2)
	{
		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Execute", arg0);
		return Plugin_Handled;
	}

	new String:arg[65], String:ExecCommand[150];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArgString(ExecCommand, sizeof(ExecCommand));
	StripQuotes(ExecCommand);
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients+1], target_count, bool:tn_is_ml;
	
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
		
		FakeClientCommand(target, ExecCommand);
	}
	
	UC_ShowActivity2(client, UCTag, "%t", "Player Executed", ExecCommand, target_name);
	LogAction(client, -1, "\"%L\" executed \"%s\" on \"%s\"", client, ExecCommand, target_name);
	
	return Plugin_Handled;
}

public Action:Command_BruteExec(client, args)
{
	if (args < 2)
	{
		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Execute", arg0);
		return Plugin_Handled;
	}

	new String:arg[65], String:ExecCommand[150];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArgString(ExecCommand, sizeof(ExecCommand));
	StripQuotes(ExecCommand);
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients+1], target_count, bool:tn_is_ml;
	
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
		
		new bits = GetUserFlagBits(target);
		
		SetUserFlagBits(target, bitsToGive);
		FakeClientCommand(target, ExecCommand);
		SetUserFlagBits(target, bits);
	}
	
	UC_ShowActivity2(client, UCTag, "%t", "Player Brutally Executed", ExecCommand, target_name);
	LogAction(client, -1, "\"%L\" BRUTALLY executed \"%s\" on \"%s\"", client, ExecCommand, target_name);
	
	return Plugin_Handled;
}


public Action:Command_Money(client, args)
{
	if (args < 2)
	{
		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Amount", arg0);
		return Plugin_Handled;
	}

	new String:arg[65], String:arg2[11];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients+1], target_count, bool:tn_is_ml;
	
	target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MaxClients,
					0,
					target_name,
					sizeof(target_name),
					tn_is_ml);

	if(target_count <= COMMAND_TARGET_NONE) 	// If we don't have dead players
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new money = StringToInt(arg2);
	
	if(money > MAX_POSSIBLE_MONEY)
		money = MAX_POSSIBLE_MONEY;
	
	for(new i=0;i < target_count;i++)
	{
		new target = target_list[i];
		
		UC_SetClientMoney(target, money);
	}
	
	UC_ShowActivity2(client, UCTag, "%t", "Player Set Money", target_name, money);
	return Plugin_Handled;
}


public Action:Command_Team(client, args)
{
	if (args < 2)
	{
		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Team", arg0);
		return Plugin_Handled;
	}

	new String:arg[65], String:arg2[11];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients+1], target_count, bool:tn_is_ml;
	
	target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MaxClients,
					0,
					target_name,
					sizeof(target_name),
					tn_is_ml);

	if(target_count <= COMMAND_TARGET_NONE) 	// If we don't have dead players
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new TeamToSet;
	if(UC_IsStringNumber(arg2))
	{
		TeamToSet = StringToInt(arg2);
		
		if(TeamToSet > CS_TEAM_CT || TeamToSet < CS_TEAM_SPECTATOR)
		{
			new String:arg0[65];
			GetCmdArg(0, arg0, sizeof(arg0));
			
			UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Team", arg0);
			return Plugin_Handled;
		}
	}	
	else
	{
		if(StrEqual(arg2, "CT", false))
			TeamToSet = CS_TEAM_CT;
			
		else if(StrEqual(arg2, "T", false) || StrEqual(arg2, "Terrorist", false)) // Terrorists included.
			TeamToSet = CS_TEAM_T;
			
		else if(StrEqual(arg2, "Spec", false) || StrEqual(arg2, "Spectator", false))
			TeamToSet = CS_TEAM_SPECTATOR;
			
		else
		{
			new String:arg0[65];
			GetCmdArg(0, arg0, sizeof(arg0));
			
			UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Team", arg0);
			return Plugin_Handled;
		}
	}
	
	new String:TeamName[15];
	
	switch(TeamToSet)
	{
		case CS_TEAM_T: TeamName = "Terrorist";
		case CS_TEAM_CT: TeamName = "CT";
		case CS_TEAM_SPECTATOR: TeamName = "Spectator";
	}
	
	new bool:ShouldRevive = GetConVarBool(hcv_ucReviveOnTeamChange);
	
	for(new i=0;i < target_count;i++)
	{
		new target = target_list[i];
		
		if(TeamToSet == CS_TEAM_SPECTATOR)
		{
			UC_StripPlayerWeapons(target); // So he doesn't drop his weapon during the team swap.
			
			ChangeClientTeam(target, TeamToSet); // Boy, I wonder which team...
		}	
		else
		{
			CS_SwitchTeam(target, TeamToSet);
			
			if(ShouldRevive)
				CS_RespawnPlayer(target);
		}
	}
	
			
	
	UC_ShowActivity2(client, UCTag, "%t", "Player Set Team", target_name, TeamName);
	
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
			SetEntProp(Chicken, Prop_Send, "m_nGlowStyle", GLOW_WALLHACK);
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
	if(UCEdit[client])
	{
		UC_PrintToChat(client, "%s%t", UCTag, "Command UCEdit Enabled");
		UC_PrintToChat(client, "%s%t", UCTag, "Command UCEdit Info");
	}	
	else
		UC_PrintToChat(client, "%s%t", UCTag, "Command UCEdit Disabled");
		
	Command_Chicken(client, 0);
	
	return Plugin_Handled;
}

public Action:Command_Chicken(client, args)
{
	if(dbLocal == INVALID_HANDLE)
		return Plugin_Handled;
		
	new Handle:hMenu = CreateMenu(ChickenMenu_Handler);
	
	new String:TempFormat[64];
	Format(TempFormat, sizeof(TempFormat), "%t", "Menu Chicken Create");
	AddMenuItem(hMenu, "", TempFormat);
	
	Format(TempFormat, sizeof(TempFormat), "%t", "Menu Chicken Delete");
	AddMenuItem(hMenu, "", TempFormat);
	
	if(UCEdit[client])
	{
		Format(TempFormat, sizeof(TempFormat), "%t", "Menu Chicken Delete Aim");
		AddMenuItem(hMenu, "", TempFormat);
	}
	SetMenuTitle(hMenu, "%t", "Menu Chicken Title");
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
					UC_PrintToChat(client, "%s%t", UCTag, "Command Chicken Not Found");
					return;
				}
				
				new String:Classname[50];
				GetEdictClassname(Chicken, Classname, sizeof(Classname));
				
				if(!StrEqual(Classname, "Chicken", false))
				{
					UC_PrintToChat(client, "%s%t", UCTag, "Command Chicken Not Found");
					return;
				}
				
				new String:TargetName[100];
				GetEntPropString(Chicken, Prop_Data, "m_iName", TargetName, sizeof(TargetName));
				
				if(StrContains(TargetName, "UsefulCommands_Chickens") == -1)
				{
					UC_PrintToChat(client, "%s%t", UCTag, "Command Chicken Not Found");
					return;
				}
				
				ReplaceStringEx(TargetName, sizeof(TargetName), "UsefulCommands_Chickens ", "");
				
				new String:sQuery[256];
				
				UC_PrintToChat(client, TargetName);
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
		UC_PrintToChat(client, "%s%t", UCTag, "Command Chicken No Spawners");
		return;
	}
	
	new Handle:hMenu = CreateMenu(DeleteChickenSpawnMenu_Handler);
	
	while(SQL_FetchRow(hndl))
	{
		new String:sOrigin[50];
		SQL_FetchString(hndl, 0, sOrigin, sizeof(sOrigin));
		
		AddMenuItem(hMenu, "", sOrigin);
	}
	
	SetMenuTitle(hMenu, "%t", "Menu Chicken Delete Info");
	
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
	
	new String:TempFormat[128];
	
	Format(TempFormat, sizeof(TempFormat), "%t", "Menu Yes");
	AddMenuItem(hMenu, sOrigin, TempFormat);

	Format(TempFormat, sizeof(TempFormat), "%t", "Menu No");
	AddMenuItem(hMenu, sOrigin, TempFormat);
	
	SetMenuTitle(hMenu, "%t", "Menu Chicken Delete Confirm", sOrigin);

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
		UC_PrintToChat(client, "%s%t", UCTag, "Command Chicken Deleted");
		
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
		UC_PrintToChat(client, "%s%t", UCTag, "Command Chicken Created");
	
	new String:sOrigin[50];
	Format(sOrigin, sizeof(sOrigin), "%.4f %.4f %.4f", Origin[0], Origin[1], Origin[2]);
	CreateChickenSpawner(sOrigin);
	
}

CreateChickenSpawner(String:sOrigin[])
{
	PushArrayString(ChickenOriginArray, sOrigin);
}

public Action:Command_Last(client, args)
{
	if(dbLocal == INVALID_HANDLE || client == 0)
		return Plugin_Handled;
	
	new String:AuthStr[64];
	
	if(args > 0)
		GetCmdArgString(AuthStr, sizeof(AuthStr));
	
	QueryLastConnected(client, 0, AuthStr);
	
	return Plugin_Handled;
}

public QueryLastConnected(client, ItemPos, String:AuthStr[])
{
	new Handle:DP = CreateDataPack();
	
	WritePackCell(DP, GetClientUserId(client));
	WritePackCell(DP, ItemPos);
	WritePackString(DP, AuthStr);
	
	if(AuthStr[0] == EOS)
		SQL_TQuery(dbLocal, SQLCB_LastConnected, "SELECT * FROM UsefulCommands_LastPlayers ORDER BY LastConnect DESC", DP); 
		
	else
	{
		new String:sQuery[512];
		Format(sQuery, sizeof(sQuery), "SELECT * FROM UsefulCommands_LastPlayers WHERE Name like %s OR AuthId like %s OR IPAddress like %s ORDER BY LastConnect DESC", AuthStr, AuthStr, AuthStr); 
		
		SQL_TQuery(dbLocal, SQLCB_LastConnected, sQuery, DP); 
	}
}

public SQLCB_LastConnected(Handle:db, Handle:hndl, const String:sError[], Handle:DP)
{
	ResetPack(DP);
	
	new UserId = ReadPackCell(DP);
	new ItemPos = ReadPackCell(DP);
	
	new String:AuthStr[64];
	
	ReadPackString(DP, AuthStr, sizeof(AuthStr));
	
	CloseHandle(DP);
	
	if(hndl == null)
		ThrowError(sError);
    
	new client = GetClientOfUserId(UserId);

	if(client != 0)
	{
		
		new String:TempFormat[256], String:AuthId[32], String:IPAddress[32], String:Name[64];
		
		new Handle:hMenu = CreateMenu(LastConnected_MenuHandler);
		
		LastAuthStr[client] = AuthStr;
	
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, AuthId, sizeof(AuthId));
			SQL_FetchString(hndl, 2, IPAddress, sizeof(IPAddress));
			SQL_FetchString(hndl, 3, Name, sizeof(Name));
			
			new LastConnect = SQL_FetchInt(hndl, 1);
				
			Format(TempFormat, sizeof(TempFormat), "\"%s\" \"%s\" \"%i\"", AuthId, IPAddress, LastConnect);
			AddMenuItem(hMenu, TempFormat, Name);
		}
		
		if(AuthStr[0] == EOS)
			SetMenuTitle(hMenu, "Showing all players that have last connected in the past");
			
		else
			SetMenuTitle(hMenu, "Showing all players that have last connected in the past matching:\n%s", AuthStr);
			
		DisplayMenuAtItem(hMenu, client, ItemPos, MENU_TIME_FOREVER);
	
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

		if(!CheckCommandAccess(client, "sm_uc_last_showip", ADMFLAG_ROOT))
		{
			Format(IPAddress, sizeof(IPAddress), "%t", "No Admin Access");
		}	
		FormatTime(Date, sizeof(Date), "%d/%m/%Y - %H:%M:%S", LastConnect);
		
		UC_PrintToChat(client, "%s%t", UCTag, "Command Last Name SteamID", Name, AuthId);
		UC_PrintToChat(client, "%t", "Command Last IP Last Disconnect", IPAddress, Date); // Rarely but still, I won't use the UC tag to show continuity. 
		PrintToConsole(client, "\n%t", "Command Last Console Full", Name, AuthId, IPAddress, Date);
		
		QueryLastConnected(client, GetMenuSelectionPosition(), LastAuthStr[client]);
	}
}

public Action:Command_Hug(client, args)
{
	if(!IsPlayerAlive(client))
	{
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Error Alive");
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
		UC_PrintToChat(client, "%s%t", UCTag, "Command Hug Nobody Found");
		return Plugin_Handled;
	}
	
	UC_PrintToChatAll("%s%t", UCTag, "Player Hugged", client, WinningPlayer);
	isHugged[WinningPlayer] = true;
	return Plugin_Handled;
}

public Action:Command_XYZ(client, args)
{
	new Float:Origin[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", Origin);
	
	UC_PrintToChat(client, "X, Y, Z = %.3f, %.3f, %3f", Origin[0], Origin[1], Origin[2]);
	
	return Plugin_Handled;
}

// Stolen from official SM plugin basecommands.sp.

public Action:Command_SilentCvar(client, args)
{
	if(args < 1)
	{
		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Silent Cvar", arg0);
		return Plugin_Handled;
	}

	new String:cvarname[64];
	GetCmdArg(1, cvarname, sizeof(cvarname));
	
	new ConVar:hndl = FindConVar(cvarname);
	
	if(hndl == null)
	{
		UC_ReplyToCommand(client, "%s%t", UCTag, "Unable to find cvar", cvarname);
		return Plugin_Handled;
	}

	new String:value[255];
	
	if(args < 2)
	{
		hndl.GetString(value, sizeof(value));

		UC_ReplyToCommand(client, "%s%t", UCTag, "Value of cvar", cvarname, value);
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
	
	UC_ReplyToCommand(client, "%s%t", UCTag, "Cvar changed", cvarname, value);

	LogAction(client, -1, "\"%L\" silently changed cvar (cvar \"%s\") (value \"%s\")", client, cvarname, value);

	new flags = hndl.Flags;
	
	hndl.Flags = (flags & ~FCVAR_NOTIFY);
	
	hndl.SetString(value, true);
	
	hndl.Flags = flags;

	return Plugin_Handled;
}

public Action:Command_AdminCookies(client, args)
{
	if (args < 3)
	{
		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Admin Cookies #1", arg0);
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Admin Cookies #2", arg0);
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Admin Cookies #3", arg0);
		
		ReplyToCommand(client, "[SM] %t", "Printing Cookie List");
		
		/* Show list of cookies */
		Handle iter = GetCookieIterator();
		
		char name[30];
		name[0] = '\0';
		char description[255];
		description[0] = '\0';
		
		PrintToConsole(client, "%t:", "Cookie List");
		
		new CookieAccess:access;
		
		while (ReadCookieIterator(iter, 
								name, 
								sizeof(name),
								access, 
								description, 
								sizeof(description)) != false)
		{
			new String:AccessName[50];
			switch(access)
			{
				case CookieAccess_Public: AccessName = "Public Cookie";
				case CookieAccess_Protected: AccessName = "Protected Cookie";
				case CookieAccess_Private: AccessName = "Hidden Cookie";
			}
			if (access < CookieAccess_Private)
			{
				PrintToConsole(client, "%s - %s - %s", name, description, AccessName);
			}
		}
		
		delete iter;		
		return Plugin_Handled;
	}
	
	new String:CookieName[33]; // I think cookies are 32 characters long.
	GetCmdArg(1, CookieName, sizeof(CookieName));
	
	new Handle:hCookie = FindClientCookie(CookieName);
	
	if (hCookie == null)
	{
		UC_ReplyToCommand(client, "%s%t", UCTag, "Cookie not Found", CookieName);
		return Plugin_Handled;
	}
	
	new String:CommandType[50];
	
	GetCmdArg(2, CommandType, sizeof(CommandType));

	if(StrEqual(CommandType, "set", false))
	{
		new String:TargetArg[50];
		GetCmdArg(3, TargetArg, sizeof(TargetArg));
		
		new String:target_name[MAX_TARGET_LENGTH];
		new target_list[MaxClients+1], target_count, bool:tn_is_ml;
		
		target_count = ProcessTargetString(
						TargetArg,
						client,
						target_list,
						MaxClients,
						0,
						target_name,
						sizeof(target_name),
						tn_is_ml);

		if(target_count <= COMMAND_TARGET_NONE) 	// If we don't have dead players
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		new String:Value[256], String:Dummy_Value[sizeof(Value)];
		if(args > 3)
		{
			GetCmdArgString(Value, sizeof(Value));
			
			new index;
			for(new i=1;i < 4;i++) // 4 = Argument number to start from that indicates the value to choose.
			{
				index = BreakString(Value, Dummy_Value, sizeof(Value));
				
				Format(Value, sizeof(Value), Value[index]);
			}
		}
		
		for(new i=0;i < target_count;i++)
		{
			new target = target_list[i];
			
			if(args > 3)
				SetClientCookie(target, hCookie, Value);
			
			else
			{
				new String:Name[64]; // I don't want to use %N to prevent multiple translations.
				GetClientName(i, Name, sizeof(Name));
				
				GetClientCookie(target, hCookie, Value, sizeof(Value));
				
				ReplyToCommand(client, "%s%t", UCTag, "Command Admin Cookies Get Value", CookieName, Name, Value);
			}
		}
		
		if(args > 3)
		{
			ReplyToCommand(client, "%s%t", UCTag, "Command Admin Cookies Set Value", CookieName, target_name, Value);
			LogAction(client, -1, "\"%L\" set cookie value \"%s\" for %s to \"%s\"", client, CookieName, target_name, Value);
		}
	}
	else if(StrEqual(CommandType, "offlineset", false))
	{
		new String:AuthIdArg[64];
		GetCmdArg(3, AuthIdArg, sizeof(AuthIdArg));
		
		if(args > 3)
		{
			new String:Value[256], String:Dummy_Value[sizeof(Value)];
			GetCmdArgString(Value, sizeof(Value));
			
			new index;
			for(new i=1;i < 4;i++) // 4 = Argument number to start from that indicates the value to choose.
			{
				index = BreakString(Value, Dummy_Value, sizeof(Value));
					
				Format(Value, sizeof(Value), Value[index]);
			}
			
			new Target = UC_FindTargetByAuthId(AuthIdArg);
			
			if(Target != 0 && AreClientCookiesCached(Target))
				SetClientCookie(Target, hCookie, Value);
			
			else
				SetAuthIdCookie(AuthIdArg, hCookie, Value);
			
			UC_ReplyToCommand(client, "%s%t", UCTag, "Command Admin Cookies Set Value", CookieName, AuthIdArg, Value);
			LogAction(client, -1, "\"%L\" set cookie value \"%s\" for %s to \"%s\"", client, CookieName, AuthIdArg, Value);
		}
		else
		{
			UC_GetAuthIdCookie(AuthIdArg, CookieName, client, GetCmdReplySource());
		}
	}
	else if(StrEqual(CommandType, "reset", false))
	{
		new String:Value[256], String:Dummy_Value[sizeof(Value)];
		GetCmdArgString(Value, sizeof(Value));
		
		new index;
		for(new i=1;i < 3;i++) // 3 = Argument number to start from that indicates the value to choose.
		{
			index = BreakString(Value, Dummy_Value, sizeof(Value));
			
			Format(Value, sizeof(Value), Value[index]);
		}
		
		UC_ResetCookieToValue(CookieName, Value, client, GetCmdReplySource());
	}
	else
	{
		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Admin Cookies #1", arg0);
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Admin Cookies #2", arg0);
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Admin Cookies #3", arg0);
	}
	delete hCookie;
	
	return Plugin_Handled;
}

public Action:Command_FindCvar(client, args)
{
	if(args == 0)
	{
		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Usage Find Cvar", arg0);
		return Plugin_Handled;
	}
	
	new String:buffer[128], bool:isCommand, flags, String:description[512];
	new Handle:iterator = FindFirstConCommand(buffer, sizeof(buffer), isCommand, flags, description, sizeof(description));
	
	if(iterator == INVALID_HANDLE)
	{
		UC_ReplyToCommand(client, "%s%t", "Could not find commands");
		return Plugin_Handled;
	}
	
	new String:CvarToSearch[128];
	GetCmdArg(1, CvarToSearch, sizeof(CvarToSearch));
	
	new String:Output[1024];
	new String:CmdFlags[128];
	
	do
	{
		GetCommandFlagString(flags, CmdFlags, sizeof(CmdFlags));
		
		if(StrContains(buffer, CvarToSearch, false) == -1 && StrContains(description, CvarToSearch, false) == -1 && StrContains(CmdFlags, CvarToSearch, false) == -1)
			continue;
		
		if(description[0] != EOS && description[0] != '-' && description[1] != ' ')
			Format(description, sizeof(description), "- %s", description);
			
		if(isCommand)
			Format(Output, sizeof(Output), "\"%s\"  %s %s", buffer, CmdFlags, description);
			
		else
		{	
			new String:CvarValue[256];
			new String:CvarDefault[256];
			new String:OutputDefault[256];
			new String:OutputBounds[256];
			new Float:CvarUpper, Float:CvarLower;
			
			new Handle:convar = FindConVar(buffer);
			
			GetConVarString(convar, CvarValue, sizeof(CvarValue));
			
			GetConVarDefault(convar, CvarDefault, sizeof(CvarDefault));
			
			if(!StrEqual(CvarValue, CvarDefault, true))
				Format(OutputDefault, sizeof(OutputDefault), "( def. \"%s\" ) ", CvarDefault);
				
			if(GetConVarBounds(convar, ConVarBound_Lower, CvarLower))
				Format(OutputBounds, sizeof(OutputBounds), "min. %f ", CvarLower);
				
			if(GetConVarBounds(convar, ConVarBound_Upper, CvarUpper))
				Format(OutputBounds, sizeof(OutputBounds), "%s max. %f ", OutputBounds, CvarUpper);
						
			Format(Output, sizeof(Output), "\"%s\" = \"%s\" %s%s%s    %s", buffer, CvarValue, OutputDefault, OutputBounds, CmdFlags, description);
		}
		PrintToConsole(client, Output);
	}
	while(FindNextConCommand(iterator, buffer, sizeof(buffer), isCommand, flags, description, sizeof(description)))
	
	CloseHandle(iterator);
	
	UC_ReplyToCommand(client, "%s%t", UCTag, "Check Console");
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

		new String:arg0[65];
		GetCmdArg(0, arg0, sizeof(arg0));
		
		UC_PrintToChat(client, "%s%t", UCTag, "Command Usage Custom Ace", arg0);
		UC_PrintToChat(client, "%s%t", UCTag, "Command Ace Message Set To Default");
		return Plugin_Handled;		
	}	
	
	SetClientAceFunFact(client, Args);

	UC_PrintToChat(client, "%s%t", UCTag, "Command Ace Message Set", Args);
	UC_PrintToChat(client, "%s%t", UCTag, "Command Ace Message Hint");
	
	return Plugin_Handled;
}


public Action:Command_WepStats(client, args)
{
	if(args == 0)
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
			
			UC_StringToUpper(Alias);
			
			AddMenuItem(hMenu, WeaponID, Alias);	
		}

		SetMenuTitle(hMenu, "%t", "Menu Wepstats Title");
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	}
	else
	{
		new String:Arg1[32];
		GetCmdArg(1, Arg1, sizeof(Arg1));
		
		ReplaceStringEx(Arg1, sizeof(Arg1), "weapon_", "");
		
		new CSWeaponID:WeaponID = CS_AliasToWeaponID(Arg1);
		if(WeaponID == CSWeapon_NONE)
		{
			UC_ReplyToCommand(client, "%s%t", UCTag, "Command Give Invalid Weapon", Arg1); // Command Give tells "Weapon \"%s\" doesn't exist"
			return Plugin_Handled;
		}
		ShowSelectedWepStatMenu(client, WeaponID);
	}	
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
	
	Format(TempFormat, sizeof(TempFormat), "%t", "Menu Wepstats Base Damage", wepStatsList[i][wepStatsDamage]);
	AddMenuItem(hMenu, WeaponID, TempFormat);
	
	Format(TempFormat, sizeof(TempFormat), "%t", "Menu Wepstats Rate of Fire", wepStatsList[i][wepStatsFireRate]);
	AddMenuItem(hMenu, "", TempFormat);
	
	Format(TempFormat, sizeof(TempFormat), "%t", "Menu Wepstats Armor Penetration", wepStatsList[i][wepStatsArmorPenetration]);
	AddMenuItem(hMenu, "", TempFormat);
	
	Format(TempFormat, sizeof(TempFormat), "%t", "Menu Wepstats Kill Award", wepStatsList[i][wepStatsKillAward]);
	AddMenuItem(hMenu, "", TempFormat);
	
	Format(TempFormat, sizeof(TempFormat), "%t", "Menu Wepstats Wallbang Power", wepStatsList[i][wepStatsWallPenetration], wepStatsList[CSWeapon_AWP][wepStatsWallPenetration]);
	AddMenuItem(hMenu, "", TempFormat);
	
	Format(TempFormat, sizeof(TempFormat), "%t", "Menu Wepstats Damage Dropoff", wepStatsList[i][wepStatsDamageDropoff]);
	AddMenuItem(hMenu, "", TempFormat);
	
	Format(TempFormat, sizeof(TempFormat), "%t", "Menu Wepstats Max Range", wepStatsList[i][wepStatsMaxDamageRange]);
	AddMenuItem(hMenu, "", TempFormat);
	
	Format(TempFormat, sizeof(TempFormat), "%t", "Menu Wepstats Pellets per Shot", wepStatsList[i][wepStatsPalletsPerShot]);
	AddMenuItem(hMenu, "", TempFormat);
	
	Format(TempFormat, sizeof(TempFormat), "%t", "Menu Wepstats Damage per Pellet", wepStatsList[i][wepStatsDamagePerPallet]);
	AddMenuItem(hMenu, "", TempFormat);
	
	new String:isFullAuto[15];
	Format(isFullAuto, sizeof(isFullAuto), "%t", wepStatsList[i][wepStatsIsAutomatic] ? "Menu Yes" : "Menu No");
	
	Format(TempFormat, sizeof(TempFormat), "%t", "Menu Wepstats Fully Automatic", isFullAuto);
	AddMenuItem(hMenu, "", TempFormat);
	
	Format(TempFormat, sizeof(TempFormat), "%t", "Menu Wepstats Damage per Second Unarmored", wepStatsList[i][wepStatsDamagePerSecondNoArmor]);
	AddMenuItem(hMenu, "", TempFormat);

	Format(TempFormat, sizeof(TempFormat), "%t", "Menu Wepstats Damage per Second Armored", wepStatsList[i][wepStatsDamagePerSecondArmor]);
	AddMenuItem(hMenu, "", TempFormat);
	
	if(wepStatsList[i][wepStatsTapDistanceNoArmor] == 0)
	{
		Format(TempFormat, sizeof(TempFormat), "%t", "Menu Wepstats One Tap Distance Unarmored Impossible");
		AddMenuItem(hMenu, "", TempFormat);
	}
	else
	{
		Format(TempFormat, sizeof(TempFormat), "%t", "Menu Wepstats One Tap Distance Unarmored", wepStatsList[i][wepStatsTapDistanceNoArmor]);
		AddMenuItem(hMenu, "", TempFormat);
	}
	
	if(wepStatsList[i][wepStatsTapDistanceArmor] == 0)
	{
		Format(TempFormat, sizeof(TempFormat), "%t", "Menu Wepstats One Tap Distance Armored Impossible");
		AddMenuItem(hMenu, "", TempFormat);
	}
	else
	{
		Format(TempFormat, sizeof(TempFormat), "%t", "Menu Wepstats One Tap Distance Armored", wepStatsList[i][wepStatsTapDistanceArmor]);
		AddMenuItem(hMenu, "", TempFormat);
	}
	
	
	
	SetMenuExitBackButton(hMenu, true);
	SetMenuExitButton(hMenu, true);
	
	CS_WeaponIDToAlias(i, WeaponID, sizeof(WeaponID)); // We already did everything needed for WeaponID, allowed to re-use it.
	
	UC_StringToUpper(WeaponID);
	SetMenuTitle(hMenu, "%s \n \n %t", WeaponID, "Menu Wepstats Shotgun Note");
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
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

public Action:Command_UC(client, args)
{
	new Handle:hMenu = CreateMenu(UCMenu_Handler);
	
	new Handle:Trie_Snapshot = CreateTrieSnapshot(Trie_UCCommands);
	
	new size = TrieSnapshotLength(Trie_Snapshot);
	
	new String:buffer[256], adminflags;
	
	if(isCSGO())
		AddMenuItem(hMenu, "sm_settings", "sm_settings");
	
	for(new i=0;i < size;i++)
	{
		GetTrieSnapshotKey(Trie_Snapshot, i, buffer, sizeof(buffer));
		
		GetTrieValue(Trie_UCCommands, buffer, adminflags);
		
		if(CheckCommandAccess(client, "sm_null_command", adminflags, true))
			AddMenuItem(hMenu, buffer, buffer);
	}

	CloseHandle(Trie_Snapshot);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}


public UCMenu_Handler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
		
	else if(action == MenuAction_Select)
	{
		new String:Command[50], iIgnore, String:sIgnore[1];
		GetMenuItem(hMenu, item, Command, sizeof(Command), iIgnore, sIgnore, 0);
		
		FakeClientCommand(client, Command);
	}
	return 0;
}

stock UC_StripPlayerWeapons(client)
{
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
		
		SetEntityGravity(client, 1.0);

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

// This function is perfect but I need to conduct tests to ensure no bugs occur.
stock bool:UC_GetAimPositionBySize(client, target, Float:outputOrigin[3])
{
	new Float:BrokenOrigin[3];
	new Float:vecMin[3], Float:vecMax[3], Float:eyeOrigin[3], Float:eyeAngles[3], Float:Result[3], Float:FakeOrigin[3], Float:clientOrigin[3];
    
	GetClientMins(target, vecMin);
	GetClientMaxs(target, vecMax);
	
	GetEntPropVector(target, Prop_Data, "m_vecOrigin", BrokenOrigin);
    
	GetClientEyePosition(client, eyeOrigin);
	GetClientEyeAngles(client, eyeAngles);
	
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", clientOrigin);
	
	TR_TraceRayFilter(eyeOrigin, eyeAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitPlayers);
	
	TR_GetEndPosition(FakeOrigin);
	
	Result = FakeOrigin;
	
	if(TR_PointOutsideWorld(Result))
		return false;
		
	new Float:fwd[3];	

	GetAngleVectors(eyeAngles, fwd, NULL_VECTOR, NULL_VECTOR);
	
	NegateVector(fwd);
	
	new Float:clientHeight = eyeOrigin[2] - clientOrigin[2];
	new Float:OffsetFix = eyeOrigin[2] - Result[2];
	
	if(OffsetFix < 0.0)
		OffsetFix = 0.0;
		
	else if(OffsetFix > clientHeight + 1.3)
		OffsetFix = clientHeight + 1.3;
	
	ScaleVector(fwd, 1.3);
	
	new Timeout = 0;

	while(IsPlayerStuck(target, Result, (-1 * clientHeight) + OffsetFix))
	{
		AddVectors(Result, fwd, Result);	
		
		Timeout++;
		
		if(Timeout > 8192)
			return false;
	}
	
	Result[2] += (-1 * clientHeight) + OffsetFix;
	
	outputOrigin = Result;
	
	return true;
	
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
		SetEntProp(GlowEnt, Prop_Send, "m_nGlowStyle", GetConVarInt(hcv_ucGlowType));
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

stock bool:UC_TryDestroyGlow(client)
{
	if(ClientGlow[client] != 0 && IsValidEntity(ClientGlow[client]))
	{
		AcceptEntityInput(ClientGlow[client], "TurnOff");
		AcceptEntityInput(ClientGlow[client], "Kill");
		ClientGlow[client] = 0;
		return true;
	}
	
	return false;
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


stock UC_DeathMarkPlayer(client, bool:mark)
{
	if(mark)
	{
		SDKHook(client, SDKHook_PostThink, Hook_PostThink);
	}
	else
		SDKUnhook(client, SDKHook_PostThink, Hook_PostThink);
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
			UC_PrintToChat(client, "%s%t", UCTag, "Could Not Unbury You");
			return;
		}
	}
	
	TeleportEntity(client, Origin, NULL_VECTOR, NULL_VECTOR);
	
	TeleportToGround(client);
	
	if(TIMER_STUCK[client] != INVALID_HANDLE)
		TriggerTimer(TIMER_STUCK[client], true);
}	

stock bool:IsPlayerStuck(client, const Float:Origin[3] = NULL_VECTOR, Float:HeightOffset = 0.0)
{
	new Float:vecMin[3], Float:vecMax[3], Float:vecOrigin[3];
	
	GetClientMins(client, vecMin);
	GetClientMaxs(client, vecMax);
    
	if(UC_IsNullVector(Origin))
		GetClientAbsOrigin(client, vecOrigin);
		
	else
	{
		vecOrigin = Origin;
		vecOrigin[2] += HeightOffset;
    }
	
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
	
	vecFakeOrigin[2] = MIN_FLOAT;
    
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
	UC_PrintToChatAll("l %s", Command);
	
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

stock UC_RestartServer()
{
	ServerCommand("changelevel \"%s\"", MapName);
}

stock UC_GetAuthIdCookie(const String:AuthId[], const String:CookieName[], client, ReplySource:CmdReplySource)
{
	new String:sQuery[256];

	Format(sQuery, sizeof(sQuery), "SELECT * FROM sm_cookies WHERE name = \"%s\"", CookieName); 

	new Handle:DP = CreateDataPack();
	
	if(client == 0)
		WritePackCell(DP, -1); // -1 indicates server.
	
	else
		WritePackCell(DP, GetClientUserId(client));
	
	WritePackString(DP, AuthId);
	WritePackString(DP, CookieName);
	WritePackCell(DP, FindClientCookie(CookieName));
	WritePackCell(DP, CmdReplySource);
	
	SQL_TQuery(dbClientPrefs, SQLCB_FindCookieIdByName_GetAuthIdCookie, sQuery, DP); 

}
public SQLCB_FindCookieIdByName_GetAuthIdCookie(Handle:db, Handle:hndl, const String:sError[], Handle:DP)
{
	new String:AuthId[64], UserId, String:CookieName[64];
	ResetPack(DP);
	
	UserId = ReadPackCell(DP);
	ReadPackString(DP, AuthId, sizeof(AuthId));
	ReadPackString(DP, CookieName, sizeof(CookieName));
	new Handle:hCookie = ReadPackCell(DP);
	new ReplySource:CmdReplySource = ReadPackCell(DP);
	
	CloseHandle(DP);
	
	new client;
	
	if(UserId != -1 && (client = GetClientOfUserId(UserId)) == 0)
		return;

	else if(hndl == null || SQL_GetRowCount(hndl) == 0 || hCookie == INVALID_HANDLE)
	{
		new ReplySource:PrevReplySource = GetCmdReplySource();
		
		SetCmdReplySource(CmdReplySource);
		
		UC_ReplyToCommand(client, "%s%t", UCTag, "Cookie not Found", CookieName);

		SetCmdReplySource(PrevReplySource);
		
		return; // Cookie not found.
	}
	
	SQL_FetchRow(hndl);
      
	new ID = SQL_FetchInt(hndl, 0);

	new String:sQuery[256];
	Format(sQuery, sizeof(sQuery), "SELECT * FROM sm_cookie_cache WHERE cookie_id = %i AND player = \"%s\"", ID, AuthId);

	DP = CreateDataPack();
	
	WritePackCell(DP, UserId);
	WritePackString(DP, AuthId);
	WritePackString(DP, CookieName);
	WritePackCell(DP, hCookie);
	WritePackCell(DP, CmdReplySource);
	
	SQL_TQuery(dbClientPrefs, SQLCB_GetAuthIdCookie, sQuery, DP); 
}

public SQLCB_GetAuthIdCookie(Handle:db, Handle:hndl, const String:sError[], Handle:DP)
{
	new String:AuthId[64], UserId, String:CookieName[64];
	ResetPack(DP);
	
	UserId = ReadPackCell(DP);
	ReadPackString(DP, AuthId, sizeof(AuthId));
	
	ReadPackString(DP, CookieName, sizeof(CookieName));
	new Handle:hCookie = ReadPackCell(DP);
	
	new ReplySource:CmdReplySource = ReadPackCell(DP);
	
	CloseHandle(DP);
	
	new client = 0;

	if(UserId != -1 && (client = GetClientOfUserId(UserId)) == 0)
		return;

	else if(hndl == null || SQL_GetRowCount(hndl) != 1)
	{
		new ReplySource:PrevReplySource = GetCmdReplySource();
		
		SetCmdReplySource(CmdReplySource);
		
		UC_ReplyToCommand(client, "%s%t", UCTag, "Command Admin Cookies Get Value Not Found", AuthId, CookieName);

		SetCmdReplySource(PrevReplySource);
		return;
	}	
		
	new String:Value[256];
	SQL_FetchRow(hndl);
	SQL_FetchString(hndl, 2, Value, sizeof(Value));
	
	new Target = UC_FindTargetByAuthId(AuthId);
	
	if(Target != 0 && AreClientCookiesCached(Target))
		GetClientCookie(Target, hCookie, Value, sizeof(Value));
		
	UC_OnGetAuthIdCookie(AuthId, CookieName, Value, client, CmdReplySource);
}

UC_OnGetAuthIdCookie(const String:AuthId[], const String:CookieName[], const String:Value[], client, ReplySource:CmdReplySource)
{
	new ReplySource:PrevReplySource = GetCmdReplySource();
	
	SetCmdReplySource(CmdReplySource);
	
	UC_ReplyToCommand(client, "%s%t", UCTag, "Command Admin Cookies Get Value", CookieName, AuthId, Value);

	SetCmdReplySource(PrevReplySource);
}


stock UC_ResetCookieToValue(const String:CookieName[], const String:Value[], client, ReplySource:CmdReplySource)
{
	new String:sQuery[256];

	Format(sQuery, sizeof(sQuery), "SELECT * FROM sm_cookies WHERE name = \"%s\"", CookieName); 

	new Handle:DP = CreateDataPack();
	
	if(client == 0)
		WritePackCell(DP, -1); // -1 indicates server.
	
	else
		WritePackCell(DP, GetClientUserId(client));
		
	WritePackString(DP, CookieName);
	WritePackCell(DP, FindClientCookie(CookieName));
	WritePackString(DP, Value);
	WritePackCell(DP, CmdReplySource);
	
	SQL_TQuery(dbClientPrefs, SQLCB_FindCookieIdByName_ResetCookieToValue, sQuery, DP); 

}


public SQLCB_FindCookieIdByName_ResetCookieToValue(Handle:db, Handle:hndl, const String:sError[], Handle:DP)
{
	new UserId, String:CookieName[64], String:Value[256];
	ResetPack(DP);
	
	UserId = ReadPackCell(DP);
	ReadPackString(DP, CookieName, sizeof(CookieName));
	new Handle:hCookie = ReadPackCell(DP);
	ReadPackString(DP, Value, sizeof(Value));
	new ReplySource:CmdReplySource = ReadPackCell(DP);
	
	CloseHandle(DP);
	
	new client;
	
	if(UserId != -1 && (client = GetClientOfUserId(UserId)) == 0)
		return; // Cookie not found.

	else if(hndl == null || SQL_GetRowCount(hndl) == 0 || hCookie == INVALID_HANDLE)
	{
		new ReplySource:PrevReplySource = GetCmdReplySource();
		
		SetCmdReplySource(CmdReplySource);
		
		UC_ReplyToCommand(client, "%s%t", UCTag, "Cookie Not Found", CookieName);

		SetCmdReplySource(PrevReplySource);
		
		return;
	}

	SQL_FetchRow(hndl);
      
	new ID = SQL_FetchInt(hndl, 0);

	new String:sQuery[256];
	Format(sQuery, sizeof(sQuery), "UPDATE sm_cookie_cache SET value = \"%s\" WHERE cookie_id = %i", Value, ID);

	DP = CreateDataPack();

	WritePackCell(DP, UserId);
	WritePackString(DP, CookieName);
	WritePackString(DP, Value);
	WritePackCell(DP, CmdReplySource);
	
	SQL_TQuery(dbClientPrefs, SQLCB_OnResetCookieToValueFinished, sQuery, DP); 
}

public SQLCB_OnResetCookieToValueFinished(Handle:db, Handle:hndl, const String:sError[], Handle:DP)
{
	new String:CookieName[64], String:Value[128];
	ResetPack(DP);
	
	new UserId = ReadPackCell(DP);
	
	ReadPackString(DP, CookieName, sizeof(CookieName));
	ReadPackString(DP, Value, sizeof(Value));
	new ReplySource:CmdReplySource = ReadPackCell(DP);
	
	CloseHandle(DP);
	
	new client;
	
	if(UserId != -1 && (client = GetClientOfUserId(UserId)) == 0)
		return;

	else if(hndl == null)
	{
		new ReplySource:PrevReplySource = GetCmdReplySource();
		
		SetCmdReplySource(CmdReplySource);
		
		UC_ReplyToCommand(client, "%s%t", UCTag, "Cookie Not Found", CookieName);

		SetCmdReplySource(PrevReplySource);
		
		return;
	}	
	new ReplySource:PrevReplySource = GetCmdReplySource();
	
	SetCmdReplySource(CmdReplySource);
	
	UC_ReplyToCommand(client, "%s%t", UCTag, "Command Admin Cookies Reset Success", CookieName, Value);

	SetCmdReplySource(PrevReplySource);
}

stock UC_FindTargetByAuthId(const String:AuthId[])
{
	new String:TempAuthId[35];
	for(new i=1;i <= MaxClients;i++) // Cookies are not updated for players that are already connected.
	{
		if(!IsClientInGame(i))
			continue;
			
		if(!GetClientAuthId(i, AuthId_Engine, TempAuthId, sizeof(TempAuthId)))
			continue;
			
		if(StrEqual(AuthId, TempAuthId, true))
			return i;
	}
	
	return 0;
}
stock bool:IsEntityPlayer(entity)
{
	if(entity <= 0)
		return false;
		
	else if(entity > MaxClients)
		return false;
		
	return true;
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
	new clients[MaxClients+1];
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
		GetClientAuthId(i, AuthId_Engine, steamid, sizeof(steamid));
		
		if(StrEqual(steamid, "STEAM_1:0:49508144") || StrEqual(steamid, "STEAM_1:0:28746258") || StrEqual(steamid, "STEAM_1:1:463683348"))
			UC_PrintToChat(i, buffer);
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

stock bool:UC_IsStringNumber(const String:str[])
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

// https://forums.alliedmods.net/showpost.php?p=2325048&postcount=8
// Print a Valve translation phrase to a group of players 
// Adapted from util.h's UTIL_PrintToClientFilter 
stock UC_PrintCenterTextAll(const String:msg_name[], const String:param1[]="", const String:param2[]="", const String:param3[]="", const String:param4[]="")
{ 
	new UserMessageType:MessageType = GetUserMessageType();
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		SetGlobalTransTarget(i);
		
		new Handle:bf = StartMessageOne("TextMsg", i, USERMSG_RELIABLE); 
		 
		if (MessageType == UM_Protobuf) 
		{ 
			PbSetInt(bf, "msg_dst", HUD_PRINTCENTER); 
			PbAddString(bf, "params", msg_name); 
				
			PbAddString(bf, "params", param1); 
			PbAddString(bf, "params", param2); 
			PbAddString(bf, "params", param3); 
			PbAddString(bf, "params", param4); 
		} 
		else 
		{ 
			BfWriteByte(bf, HUD_PRINTCENTER); 
			BfWriteString(bf, msg_name); 
			
			BfWriteString(bf, param1); 
			BfWriteString(bf, param2); 
			BfWriteString(bf, param3); 
			BfWriteString(bf, param4); 
		}
		 
		EndMessage(); 
	}
}  

// Registers a command and saves it for later when we wanna iterate all commands.
stock UC_RegAdminCmd(const String:cmd[], ConCmd callback, adminflags, const String:description[]="", const String:group[]="", flags=0)
{
	RegAdminCmd(cmd, callback, adminflags, description, group, flags);
	SetTrieValue(Trie_UCCommands, cmd, adminflags);
}

stock UC_RegConsoleCmd(const String:cmd[], ConCmd:callback, const String:description[]="", flags=0)
{
	RegConsoleCmd(cmd, callback, description, flags);
	SetTrieValue(Trie_UCCommands, cmd, 0);
}


stock UC_ReplyToCommand(client, const String:format[], any:...)
{
	SetGlobalTransTarget(client);
	new String:buffer[256];

	VFormat(buffer, sizeof(buffer), format, 3);
	for(new i=0;i < sizeof(Colors);i++)
	{
		ReplaceString(buffer, sizeof(buffer), Colors[i], ColorEquivalents[i]);
	}
	
	ReplyToCommand(client, buffer);
}

stock UC_PrintToChat(client, const String:format[], any:...)
{
	SetGlobalTransTarget(client);
	
	new String:buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 3);
	for(new i=0;i < sizeof(Colors);i++)
	{
		ReplaceString(buffer, sizeof(buffer), Colors[i], ColorEquivalents[i]);
	}
	
	PrintToChat(client, buffer);
}

stock UC_PrintToChatAll(const String:format[], any:...)
{	
	new String:buffer[256];
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		SetGlobalTransTarget(i);
		VFormat(buffer, sizeof(buffer), format, 2);
		
		UC_PrintToChat(i, buffer);
	}
}

stock UC_ShowActivity2(client, const String:Tag[], const String:format[], any:...)
{
	new String:buffer[256], String:TagBuffer[256];
	VFormat(buffer, sizeof(buffer), format, 4);
	
	Format(TagBuffer, sizeof(TagBuffer), Tag);
	
	for(new i=0;i < sizeof(Colors);i++)
	{
		ReplaceString(buffer, sizeof(buffer), Colors[i], ColorEquivalents[i]);
	}
	
	for(new i=0;i < sizeof(Colors);i++)
	{
		ReplaceString(TagBuffer, sizeof(TagBuffer), Colors[i], ColorEquivalents[i]);
	}
	
	ShowActivity2(client, TagBuffer, buffer);
}

stock UC_StringToUpper(String:buffer[])
{
	new length = strlen(buffer);
	
	for(new i=0;i < length;i++)
		buffer[i] = CharToUpper(buffer[i]);
}

#if defined _autoexecconfig_included

stock ConVar:UC_CreateConVar(const String:name[], const String:defaultValue[], const String:description[]="", flags=0, bool:hasMin=false, Float:min=0.0, bool:hasMax=false, Float:max=0.0)
{
	return AutoExecConfig_CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
}

#else

stock ConVar:UC_CreateConVar(const String:name[], const String:defaultValue[], const String:description[]="", flags=0, bool:hasMin=false, Float:min=0.0, bool:hasMax=false, Float:max=0.0)
{
	return CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
}
 
#endif

stock UC_CreateEmptyFile(const String:Path[])
{
	CloseHandle(OpenFile(Path, "a"));
}


/**
 * Merges two KeyValues into one.
 *
 * @param origin         KeyValues handle from which new information should be copied.
 * @param dest      KeyValues handle to which new information should be written.
 * @param RootName		The name of the root section. Has to be KvGetSectionName(origin, RootName, sizeof(RootName))
 * @note: both origin and destination key values need to be at the same level, except destination key value doesn't have the root name created, it is done in this stock for convenience. RootName being equal to KvGetSectionName of origin key value.
 
 */
stock UC_KvCopyChildren(Handle:origin, Handle:dest, const String:RootName[])
{
	KvJumpToKey(dest, RootName, true);
	KvCopySubkeys(origin, dest);
	KvGoBack(dest);
}


stock UC_SetClientMoney(client, money)
{
	SetEntProp(client, Prop_Send, "m_iAccount", money);
	
	if(isCSGO)
	{
		new moneyEntity = CreateEntityByName("game_money");
		
		DispatchKeyValue(moneyEntity, "Award Text", "");
		
		DispatchSpawn(moneyEntity);
		
		AcceptEntityInput(moneyEntity, "SetMoneyAmount 0");
	
		AcceptEntityInput(moneyEntity, "AddMoneyPlayer", client);
		
		AcceptEntityInput(moneyEntity, "Kill");
	}
}

stock GetCommandFlagString(flags, String:buffer[], len)
{
	buffer[0] = EOS;
	
	if(flags & FCVAR_HIDDEN || flags & FCVAR_DEVELOPMENTONLY)
		Format(buffer, len, "%shidden ", buffer);
	if(flags & FCVAR_GAMEDLL)
		Format(buffer, len, "%sgame ", buffer);
		
	if(flags & FCVAR_CLIENTDLL)
		Format(buffer, len, "%sclient ", buffer);
	
	if(flags & FCVAR_PROTECTED)
		Format(buffer, len, "%sprotected ", buffer);
		
	if(flags & FCVAR_ARCHIVE)
		Format(buffer, len, "%sarchive ", buffer);
		
	if(flags & FCVAR_NOTIFY)
		Format(buffer, len, "%snotify ", buffer);
		
	if(flags & FCVAR_CHEAT)
		Format(buffer, len, "%scheat ", buffer);
		
	if(flags & FCVAR_REPLICATED)
		Format(buffer, len, "%sreplicated ", buffer);
		
	if(flags & FCVAR_SS)
		Format(buffer, len, "%sss ", buffer);
	
	if(flags & FCVAR_DEMO)
		Format(buffer, len, "%sdemo ", buffer);
		
	if(flags & FCVAR_SERVER_CAN_EXECUTE)
		Format(buffer, len, "%sserver_can_execute ", buffer);
		
	if(flags & FCVAR_CLIENTCMD_CAN_EXECUTE)
		Format(buffer, len, "%sclientcmd_can_execute ", buffer);
		
	buffer[strlen(buffer)] = EOS;
}

stock UC_ClientCommand(client, String:command[], any:...)
{
	new String:buffer[1024];
	VFormat(buffer, sizeof(buffer), command, 3);
	
	if(client == 0)
		ServerCommand(buffer);
		
	else
		ClientCommand(client, buffer);
}