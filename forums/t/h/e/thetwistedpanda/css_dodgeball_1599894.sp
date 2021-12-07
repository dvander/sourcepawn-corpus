/*
	Random notes, just ignore, you don't need them:

	Integrated Spawn Protection
	- Lose protection after x seconds, after throwing grenade, both

	g_iTeam
	g_iLast 
	spectate/join_team, manual fires
	- fires player_team
		- if manual, remove from team
		- if automatic
			- remove from team
			- if alive, remove from alive
	- fires player_death
		- if manual, remove from alive 
	
	join_class, manual fires 
	- player_spawn (if possible)
	- if not manual, prevent suicide attempt
	
	player_death
	
	
	- Support for being spawned mid rounds (breaks detection)
	- spawning_mode 3 doesn't work 
	- remove fire sound from grenades
	- support for spawning midround
	
	- CSS Dodgeball RPG:
		- Points: Amount | Convert Points
			- X / X Kills Available
			- == X Points @ X Ratio
			- Convert? Yes | No		
		- Level Player Perks
			- Player Health (Level 1 - 3 - ~ 1.0 ~ 1hp|3hp)
			- Player Gravity (Level 1 - 50 ~ 0.01 ~ 1.0|1.5)
			- Player Speed (Level 1 - 50 ~ 0.01 ~ 1.0|1.5)
			- Player Spawns (Level 1 - 5 ~ 1 ~ x|x+5)
			- Long Jump: (Level 1 - 10 ~ 100 ~ 100 | 1000)
			- Vampire: Chance of gaining 1 health for killing enemy. Max 3HP (Level 1 - 100 ~ 0.001 ~ 0.0001%|0.01%)
			- Mirror: Chance of returning the damage dealt. (Level 1 - 100 ~ 0.001 ~ 0.0001%|0.01%)
		- Toggle Player Perks
			- Enable / Disable / Select Gravity Mode / Select Speed Mode
		- Level Dodgeball Perks
			- Dodgeball Damage (Level 1 - 3 ~ 1.0 ~ 1dmg|3dmg)
			- Decrease Supply Speed (Level 1 - 28 ~ 0.025 ~ 0.9secs|0.2secs)
			- Explode: Chance of having dodgeball explode, radius damage, rather than sitting. (Level 1 - 100 ~ 0.001 ~ 0.001%|0.1%)
			- Bounce: Chance of having dodgeball bounce rather than sitting there. (Level 1 - 100 ~ 0.001 ~ 0.001%|0.1%)
		- Toggle Dodgeball Perks
			- Enable / Disable
		- Select Dodgeball Color
			- Red Amount | Option to purchase if currently not owned.
			- Blue Amount | Option to purchase if currently not owned.
			- Green Amount | Option to purchase if currently not owned.
		- Select Dodgeball Effect
			- List Effects | Option to purchase if currently not owned.
				- Attach Tesla 
				- Attach Trail (~ Several Trails)
				- Attach Fire
		- Help
			- Information
			- Missing Points?
			- Purchase Points?
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <colors>

#define PLUGIN_VERSION "1.0.7"

//The limit of entities the Source engine can handle without going splat.
#define MAX_SERVER_ENTITIES 2048

//The hardcoded limit to the number of grenade models allowed; saves memory for unnecessary reasons, increase define to allow more.
#define MAX_MODELS_ALLOWED 64

//Slot for the client's knife, since cstrike.inc doesn't have it for some odd reason
#define CS_SLOT_KNIFE 2

//The rate at which grenades are checked for no velocity
#define TIMER_REFRESH 0.5

//The mode(s) available for the integrated spawning system
#define SPAWNING_DISABLED 0
#define SPAWNING_TIMER 1
#define SPAWNING_PLAYER 2

//Defines which grenade the plugin will use.
new String:g_sGrenadeShor[] = { "flashbang" };
new String:g_sGrenadeLong[] = { "weapon_flashbang" };
new String:g_sGrenadeProj[] = { "flashbang_projectile" };

//Defines that control which slot a grenade occupies in m_iAmmo
#define AMMO_HEGRENADE 11
#define AMMO_FLASHBANG 12
#define AMMO_SMOKEGRENADE 13

//Cosmetics: the number of grenades to show the client has, if supplies are unlimited
#define AMMO_COUNT 3

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hGrenadeBounce = INVALID_HANDLE;
new Handle:g_hGrenadeString = INVALID_HANDLE;
new Handle:g_hGrenadeLife = INVALID_HANDLE;
new Handle:g_hSupplyDelay = INVALID_HANDLE;
new Handle:g_hSupplyCount = INVALID_HANDLE;
new Handle:g_hPlayerHealth = INVALID_HANDLE;
new Handle:g_hGrenadeDamage = INVALID_HANDLE;
new Handle:g_hKnifeLeft = INVALID_HANDLE;
new Handle:g_hKnifeRight = INVALID_HANDLE;
new Handle:g_hKnifeBack = INVALID_HANDLE;
new Handle:g_hPreventRadio = INVALID_HANDLE;
new Handle:g_hPreventSuicide = INVALID_HANDLE;
new Handle:g_hPreventDamage = INVALID_HANDLE;
new Handle:g_hPreventFalling = INVALID_HANDLE;
new Handle:g_hStripObjectives = INVALID_HANDLE;
new Handle:g_hStripEquipment = INVALID_HANDLE;
new Handle:g_hStripDeath = INVALID_HANDLE;
new Handle:g_hExtraSpawns = INVALID_HANDLE;
new Handle:g_hScrambleTeams = INVALID_HANDLE;
new Handle:g_hMaintainTeams = INVALID_HANDLE;
new Handle:g_hMaxRoundsAfk = INVALID_HANDLE;
new Handle:g_hSupplyEquip = INVALID_HANDLE;
new Handle:g_hGrenadeIgnite = INVALID_HANDLE;
new Handle:g_hSpawningMode = INVALID_HANDLE;
new Handle:g_hSpawningDelay = INVALID_HANDLE;
new Handle:g_hSpawningIgnore = INVALID_HANDLE;
new Handle:g_hSpawningFactor = INVALID_HANDLE;
new Handle:g_hSpawningNew = INVALID_HANDLE;
new Handle:g_hDisplay = INVALID_HANDLE;
new Handle:g_hGrenadeDissolve = INVALID_HANDLE;
new Handle:g_hLimitTeams = INVALID_HANDLE;
new Handle:g_hRoundRestart = INVALID_HANDLE;
new Handle:g_hRoundTime = INVALID_HANDLE;
new Handle:g_hIgnoreConditions = INVALID_HANDLE;
new Handle:g_hTimer_EndRound = INVALID_HANDLE;
new Handle:g_hTimer_DisplayScore = INVALID_HANDLE;

new bool:g_bEnding, bool:g_bEnabled, bool:g_bLateLoad, bool:g_bPreventRadio, bool:g_bPreventSuicide, bool:g_bPreventDamage, bool:g_bStripObjectives, bool:g_bSpawningIgnore, 
bool:g_bStripEquipment, bool:g_bGrenadeString, bool:g_bExtraSpawns, bool:g_bStripDeath, bool:g_bMaintainTeams, bool:g_bPreventFalling, bool:g_bSupplyEquip,
bool:g_bSpawningDynamic, bool:g_bDisplay, bool:g_bModels, bool:g_bSpawning, bool:g_bIgnite;
new g_iGrenadeLife, g_iSupplyCount, g_iPlayerHealth, g_iNumRedSpawns, g_iNumBlueSpawns, g_iLimitTeams, g_iLastScramble, g_iCurrentRound, g_iWinner,
g_iTeamsScramble, g_iMaxRoundsAfk, g_iNumModels, g_iGrenadeModel, g_iSpawningMode, g_iGrenadeDissolve, g_iGrenadeBounce, g_iSpawningFactor, g_iRedKills, g_iRedDeaths, g_iBlueKills, 
g_iBlueDeaths, g_iSpawningNew, g_iSpawningTime;
new String:g_sPrefixChat[32], String:g_sPrefixHint[32], String:g_sGrenadeString[32], String:g_sGrenadeDissolve[3];
new Float:g_fSupplyDelay, Float:g_fRedTeleports[MAXPLAYERS][3], Float:g_fBlueTeleports[MAXPLAYERS][3], Float:g_fRoundRestart, Float:g_fRoundLeft, 
Float:g_fGrenadeDamage, Float:g_fKnifeLeft, Float:g_fKnifeRight, Float:g_fKnifeBack, Float:g_fRoundTime, Float:g_fSpawningDelay;

new g_iRedPlayerSpawns, g_iBluePlayerSpawns;
new g_iRedPlayersTotal, g_iBluePlayersTotal, g_iRedPlayersAlive, g_iBluePlayersAlive;

new g_iGrenLife[MAX_SERVER_ENTITIES + 1];
new g_iGrenOwner[MAX_SERVER_ENTITIES + 1];
new g_iGrenBounce[MAX_SERVER_ENTITIES + 1];
new g_iGrenIndex[MAX_SERVER_ENTITIES + 1];
new bool:g_bGrenValid[MAX_SERVER_ENTITIES + 1];
new Handle:g_hGrenTimer[MAX_SERVER_ENTITIES + 1] = { INVALID_HANDLE, ... };
new String:g_sModelName[MAX_MODELS_ALLOWED][64];
new String:g_sModelPath[MAX_MODELS_ALLOWED][256];

new g_iClass[MAXPLAYERS + 1] = { 0, ... };
new g_iTeam[MAXPLAYERS + 1] = { 0, ... };
new g_iCount[MAXPLAYERS + 1] = { 0, ... };
new bool:g_bAlive[MAXPLAYERS + 1] = { false, ... };
new Handle:g_hSupply[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
new Float:g_fSpawning[MAXPLAYERS + 1];
new Handle:g_hSpawning[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
new bool:g_bActivity[MAXPLAYERS + 1] = { false, ... };
new g_iRoundsAfk[MAXPLAYERS + 1];
new bool:g_bManual[MAXPLAYERS + 1];

new bool:g_bSpawns[MAXPLAYERS + 1];
new g_iSpawns[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "CSS Dodgeball",
	author = "Twisted|Panda",
	description = "Provides basic Dodgeball gameplay for Counter-Strike: Source.",
	version = PLUGIN_VERSION,
	url = "http://ominousgaming.com/"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("css_dodgeball.phrases");

	CreateConVar("css_dodgeball_version", PLUGIN_VERSION, "CSS Dodgeball: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("css_dodgeball_enabled", "1", "Enables/disables all functionality of the plugin. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnSettingsChange);
	g_hSupplyDelay = CreateConVar("css_dodgeball_delay", "0.5", "The delay, in seconds, players must wait before receiving a new grenade. (#.# = Delay)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hSupplyDelay, OnSettingsChange);
	g_hGrenadeBounce = CreateConVar("css_dodgeball_bounce", "1", "The number of bounces each grenade is allowed to make. (-1 = Bounce until css_dodgeball_life, 0 = Disabled, # = Bounce Count)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hGrenadeBounce, OnSettingsChange);
	g_hGrenadeString = CreateConVar("css_dodgeball_weapon", "weapon_dodgeball", "The weapon string to be used to signify kills made in dodgeball, mainly for stat tracking purposes. (\"\" = Disabled, Example: \"weapon_ball\")", FCVAR_NONE);
	HookConVarChange(g_hGrenadeString, OnSettingsChange);
	g_hGrenadeLife = CreateConVar("css_dodgeball_life", "10", "The maximum lifetime of a thrown grenade, to ensure all grenades are always deleted. Keep around 5.0 to ensure normal gameplay.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hGrenadeLife, OnSettingsChange);
	g_hSupplyCount = CreateConVar("css_dodgeball_grenades", "0", "The number of grenades players will receive. (0 = Infinite, # = Limited)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hSupplyCount, OnSettingsChange);
	g_hPlayerHealth = CreateConVar("css_dodgeball_health", "100", "The amount of health players will spawn with. (# = Amount)", FCVAR_NONE, true, 1.0);
	HookConVarChange(g_hPlayerHealth, OnSettingsChange);
	g_hGrenadeDamage = CreateConVar("css_dodgeball_damage", "100", "The amount of health grenades will do to players. (# = Amount)", FCVAR_NONE, true, 1.0);
	HookConVarChange(g_hGrenadeDamage, OnSettingsChange);
	g_hKnifeLeft = CreateConVar("css_dodgeball_knife_left", "5", "The amount of damage knives will do to opponents when left clicking. (# = Amount)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hKnifeLeft, OnSettingsChange);
	g_hKnifeRight = CreateConVar("css_dodgeball_knife_right", "15", "The amount of damage knives will do to opponents when right clicking. (# = Amount)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hKnifeRight, OnSettingsChange);
	g_hKnifeBack = CreateConVar("css_dodgeball_knife_back", "40", "The amount of damage knives will do to opponents when stabbing them in the back. (# = Amount)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hKnifeBack, OnSettingsChange);
	g_hPreventRadio = CreateConVar("css_dodgeball_prevent_radio", "1", "Prevents players from issuing radio commands. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hPreventRadio, OnSettingsChange);
	g_hPreventSuicide = CreateConVar("css_dodgeball_prevent_suicide", "1", "Prevents players from killing themselves. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hPreventSuicide, OnSettingsChange);
	g_hPreventDamage = CreateConVar("css_dodgeball_prevent_damage", "0", "Prevents players from taking damage from any source other than an enemy grenade. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hPreventDamage, OnSettingsChange);
	g_hPreventFalling = CreateConVar("css_dodgeball_prevent_falling", "1", "Prevents players from taking falling damage. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hPreventFalling, OnSettingsChange);
	g_hStripObjectives = CreateConVar("css_dodgeball_strip_objectives", "1", "If enabled, objectives will be stripped from the map. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hStripObjectives, OnSettingsChange);
	g_hStripEquipment = CreateConVar("css_dodgeball_strip_equipment", "1", "If enabled, existing grenades will be removed from the map. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hStripEquipment, OnSettingsChange);
	g_hStripDeath = CreateConVar("css_dodgeball_strip_death", "1", "If enabled, players will be stripped when they die to prevent their equipment from cluttering ground. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hStripDeath, OnSettingsChange);
	g_hExtraSpawns = CreateConVar("css_dodgeball_extra_spawns", "1", "If enabled, the mod will ensure there are enough spawn points for each team based on slot size. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hExtraSpawns, OnSettingsChange);
	g_hScrambleTeams = CreateConVar("css_dodgeball_scramble_teams", "1", "If greater than zero, teams will be randomly scrambled every x rounds, where x is the cvar value. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hScrambleTeams, OnSettingsChange);
	g_hMaintainTeams = CreateConVar("css_dodgeball_maintain_teams", "1", "If enabled, team sizes will be maintained to prevent team imbalances when the teams are not scrambled. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hMaintainTeams, OnSettingsChange);
	g_hMaxRoundsAfk = CreateConVar("css_dodgeball_max_rounds_afk", "3", "The number of rounds a player can be afk before they're thrown into spectate. (0 = Disabled)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hMaxRoundsAfk, OnSettingsChange);
	g_hSupplyEquip = CreateConVar("css_dodgeball_supply_equip", "1", "If enabled, the plugin will automatically equip a new grenade for the player after throwing. (0 = Disabled, 1 = Disabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hSupplyEquip, OnSettingsChange);
	g_hGrenadeIgnite = CreateConVar("css_dodgeball_ignite", "1", "If enabled, thrown grenades will be caught on fire. (0 = Disabled, 1 = Disabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hGrenadeIgnite, OnSettingsChange);
	g_hDisplay = CreateConVar("css_dodgeball_display", "1", "If enabled, the current score will be displayed in a KeyHint to the right of player's screens. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hDisplay, OnSettingsChange);
	g_hGrenadeDissolve = CreateConVar("css_dodgeball_dissolve", "3", "The dissolve effect to be used for removing grenades. (-1 = Disabled, 0 = Energy, 1 = Light, 2 = Heavy, 3 = Core)", FCVAR_NONE, true, -1.0, true, 3.0);
	HookConVarChange(g_hGrenadeDissolve, OnSettingsChange);

	g_hSpawningMode = CreateConVar("css_dodgeball_spawning_mode", "0", "Determines functionality of the integrated spawning system. (0 = Disabled, 1 = Round Time, 2 = Player Spawns)", FCVAR_NONE, true, 0.0, true, 2.0);
	HookConVarChange(g_hSpawningMode, OnSettingsChange);
	g_hSpawningDelay = CreateConVar("css_dodgeball_spawning_delay", "-1.0", "Delay, in seconds, players must wait to respawn. ( < 0.0 = Dynamic (abs(cvar) * players), 0.0 = Instant, #.# = Delay)", FCVAR_NONE);
	HookConVarChange(g_hSpawningDelay, OnSettingsChange);
	g_hSpawningIgnore = CreateConVar("css_dodgeball_spawning_ignore", "0", "If enabled, the plugin will control mp_ignore_round_win_conditions to prevent 1v1 matches ending the round. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hSpawningIgnore, OnSettingsChange);
	g_hSpawningFactor = CreateConVar("css_dodgeball_spawning_factor", "2", "The number of spawns to be given to each player if the spawning mode is set to player spawns.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hSpawningFactor, OnSettingsChange);
	g_hSpawningNew = CreateConVar("css_dodgeball_spawning_new", "-1.0", "The number of seconds after the start of a round to prevent spawning new players. (-1 = Disabled, 0 = Infinite, # = Seconds)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hSpawningNew, OnSettingsChange);
	AutoExecConfig(true, "css_dodgeball");

	g_hLimitTeams = FindConVar("mp_limitteams");
	HookConVarChange(g_hLimitTeams, OnSettingsChange);
	g_hRoundRestart = FindConVar("mp_round_restart_delay");
	HookConVarChange(g_hRoundRestart, OnSettingsChange);
	g_hRoundTime = FindConVar("mp_roundtime");
	HookConVarChange(g_hRoundTime, OnSettingsChange);
	g_hIgnoreConditions = FindConVar("mp_ignore_round_win_conditions");
	
	AddCommandListener(Command_Kill, "kill");
	AddCommandListener(Command_Kill, "explode");
	AddCommandListener(Command_Join, "jointeam");
	AddCommandListener(Command_Class, "joinclass");
	AddCommandListener(Command_Radio, "coverme");
	AddCommandListener(Command_Radio, "takepoint");
	AddCommandListener(Command_Radio, "holdpos");
	AddCommandListener(Command_Radio, "regroup");
	AddCommandListener(Command_Radio, "followme");
	AddCommandListener(Command_Radio, "takingfire");
	AddCommandListener(Command_Radio, "go");
	AddCommandListener(Command_Radio, "getout");
	AddCommandListener(Command_Radio, "fallback");
	AddCommandListener(Command_Radio, "sticktog");
	AddCommandListener(Command_Radio, "getinpos");
	AddCommandListener(Command_Radio, "stormfront");
	AddCommandListener(Command_Radio, "report");
	AddCommandListener(Command_Radio, "roger");
	AddCommandListener(Command_Radio, "enemyspot");
	AddCommandListener(Command_Radio, "needbackup");
	AddCommandListener(Command_Radio, "sectorclear");
	AddCommandListener(Command_Radio, "inposition");
	AddCommandListener(Command_Radio, "reportingin");
	AddCommandListener(Command_Radio, "negative");
	AddCommandListener(Command_Radio, "enemydown");

	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("round_start", Event_OnRoundStart);
	HookEvent("player_team", Event_OnPlayerTeam);
	HookEvent("weapon_fire", Event_OnWeaponFire, EventHookMode_Post);	
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Pre);
	HookEvent("player_death", Event_OnPlayerDeath);
}

public OnPluginEnd()
{
	if(g_bEnabled)
	{
		for(new i = 1; i <= MaxClients; i++)
			if(!g_bAlive[i] && g_iTeam[i] >= CS_TEAM_T && IsClientInGame(i))
				CS_RespawnPlayer(i);

		for(new i = MaxClients + 1; i < MAX_SERVER_ENTITIES; i++)
			if(g_bGrenValid[i])
				Void_Remove(i, true);
	}
}

public OnMapStart()
{
	Void_SetDefaults();
	if(g_bEnabled)
	{
		Void_Downloads();
		Void_Models();
		if(g_bModels)
			g_iGrenadeModel = GetRandomInt(0, (g_iNumModels - 1));
		
		if(g_bExtraSpawns)
			CreateTimer(0.1, Timer_OnMapStart);
	}
}

public OnMapEnd()
{
	if(g_bEnabled)
	{
		g_bEnding = true;

		if(g_bDisplay)
			if(g_hTimer_DisplayScore != INVALID_HANDLE && CloseHandle(g_hTimer_DisplayScore))
				g_hTimer_DisplayScore = INVALID_HANDLE;
		
		if(g_iSpawningMode == SPAWNING_TIMER)
			if(g_hTimer_EndRound != INVALID_HANDLE && CloseHandle(g_hTimer_EndRound))
				g_hTimer_EndRound = INVALID_HANDLE;
				
		g_iCurrentRound = g_iLastScramble = 0;
		g_iRedKills = g_iBlueKills = g_iRedDeaths = g_iBlueDeaths = 0;
		g_iBluePlayerSpawns = g_iRedPlayerSpawns = 0;
		g_iRedPlayersTotal = g_iBluePlayersTotal = g_iRedPlayersAlive = g_iBluePlayersAlive = 0;		
	}
}

public Action:Timer_OnMapStart(Handle:timer)
{
	Void_SetSpawns();
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		Format(g_sPrefixChat, 32, "%T", "Prefix_Chat", LANG_SERVER);
		Format(g_sPrefixHint, 32, "%T", "Prefix_Hint", LANG_SERVER);
		
		Void_Downloads();
		Void_Models();
		if(g_bModels)
			g_iGrenadeModel = GetRandomInt(0, (g_iNumModels - 1));

		if(g_bLateLoad)
		{
			if(g_bExtraSpawns)
				CreateTimer(0.1, Timer_OnMapStart);

			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_iTeam[i] = GetClientTeam(i);
					g_bAlive[i] = IsPlayerAlive(i) ? true : false;
					g_iClass[i] = g_iTeam[i] == CS_TEAM_T ? GetRandomInt(1, 4) : GetRandomInt(5, 8);

					switch(g_iTeam[i])
					{
						case CS_TEAM_T:
						{
							g_iRedPlayersTotal++;
							g_iClass[i] = GetRandomInt(1, 4);

							if(g_bAlive[i])
								g_iRedPlayersAlive++;
						}
						case CS_TEAM_CT:
						{
							g_iBluePlayersTotal++;
							g_iClass[i] = GetRandomInt(5, 8);

							if(g_bAlive[i])
								g_iBluePlayersAlive++;
						}
					}
					
					SDKHook(i, SDKHook_PostThinkPost, Hook_PostThinkPost);
					SDKHook(i, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
					SDKHook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
					SDKHook(i, SDKHook_WeaponDrop, Hook_WeaponDrop);
				}
			}

			g_bLateLoad = false;
			CS_TerminateRound(g_fRoundRestart, CSRoundEnd_GameStart);
		}
	}
}

public OnGameFrame()
{
	if(g_bEnabled)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(g_bAlive[i] && !g_bActivity[i])
			{
				if(GetClientButtons(i))
					g_bActivity[i] = true;
			}
		}
	}
}						

public OnEntityDestroyed(entity)
{
	if(g_bEnabled && entity >= 0)
	{
		if(g_bGrenValid[entity])
		{
			g_bGrenValid[entity] = false;
			g_iGrenOwner[entity] = 0;
			
			if(g_hGrenTimer[entity] != INVALID_HANDLE && CloseHandle(g_hGrenTimer[entity]))
				g_hGrenTimer[entity] = INVALID_HANDLE;
		}
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if(g_bEnabled && !g_bEnding && entity >= 0)
	{
		if(StrEqual(classname, g_sGrenadeProj))
		{
			g_iGrenBounce[entity] = 0;
			g_iGrenLife[entity] = 0;
			g_iGrenIndex[entity] = entity;
			g_bGrenValid[entity] = true;

			if(g_bIgnite)
				IgniteEntity(entity, 60.0);
			SDKHook(entity, SDKHook_StartTouch, Hook_StartTouch);
			SDKHook(entity, SDKHook_EndTouch, Hook_EndTouch);
		
			CreateTimer(0.1, Timer_OnEntityCreated, EntIndexToEntRef(entity));
		}
	}
}

public Action:Timer_OnEntityCreated(Handle:timer, any:ref)
{
	new entity = EntRefToEntIndex(ref);
	if(entity != INVALID_ENT_REFERENCE)
	{
		g_iGrenOwner[entity] = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
		g_hGrenTimer[entity] = CreateTimer(TIMER_REFRESH, Timer_Check, entity, TIMER_REPEAT);
		SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);

		if(g_iGrenadeBounce == -1)
			SetEntPropFloat(entity, Prop_Data, "m_flElasticity", 1.0);
		else
			SetEntPropFloat(entity, Prop_Data, "m_flElasticity", 0.5);

		if(g_bModels)
			SetEntityModel(entity, g_sModelPath[g_iGrenadeModel]);
		switch(g_iTeam[g_iGrenOwner[entity]])
		{
			case CS_TEAM_T:
				SetEntityRenderColor(entity, 255, 125, 125, 255);
			case CS_TEAM_CT:
				SetEntityRenderColor(entity, 125, 125, 255, 255);
		}
		
		if(g_iGrenadeDissolve >= 0)
		{
			decl String:_sBuffer[16];
			Format(_sBuffer, sizeof(_sBuffer), "Grenade_%d", g_iGrenIndex[entity]);
			DispatchKeyValue(entity, "targetname", _sBuffer);
		}
	}
	
	return Plugin_Continue;
}

public Action:Hook_StartTouch(entity, other)
{
	if(g_bGrenValid[entity])
	{
		if(g_bGrenValid[other])
		{
			SetEntProp(entity, Prop_Data, "m_CollisionGroup", 2);
			ChangeEdictState(entity, FL_EDICT_CHANGED);
		}
		else
		{
			g_iGrenBounce[entity]++;
			if(g_iGrenadeBounce >= 0)
				if(g_iGrenBounce[entity] > g_iGrenadeBounce)
					Void_Remove(entity, false);
		
			if(other && other <= MaxClients)
			{
				if(!g_iGrenOwner[entity] && g_iGrenadeDissolve >= 0)
				{
					decl String:_sBuffer[16];
					Format(_sBuffer, sizeof(_sBuffer), "Grenade_%d", g_iGrenIndex[entity]);
					DispatchKeyValue(entity, "targetname", _sBuffer);
				}
				
				Void_Remove(entity, false);
			}
		}
	}
}

public Action:Hook_EndTouch(entity, other)
{
	if(g_bGrenValid[entity] && g_bGrenValid[other])
	{
		SetEntProp(entity, Prop_Data, "m_CollisionGroup", 5);
		ChangeEdictState(entity, FL_EDICT_CHANGED);
	}
}

public Action:Timer_Check(Handle:timer, any:entity)
{
	g_iGrenLife[entity]++;
	if(g_iGrenLife[entity] < g_iGrenadeLife)
	{
		decl Float:_fTemp[3];
		GetEntPropVector(entity, Prop_Data, "m_vecVelocity", _fTemp);
	
		if(_fTemp[0] || _fTemp[1] || _fTemp[2])
			return Plugin_Continue;
	}

	g_hGrenTimer[entity] = INVALID_HANDLE;
	Void_Remove(entity, false);
	return Plugin_Stop;
}

public OnClientPutInServer(client)
{
	if(g_bEnabled)
	{
		SDKHook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
		SDKHook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
		SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
		SDKHook(client, SDKHook_WeaponDrop, Hook_WeaponDrop);
		
		if(IsFakeClient(client))
			g_iClass[client] = GetRandomInt(1, 8);
	}
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		if(!g_bEnding)
		{
			switch(g_iTeam[client])
			{
				case CS_TEAM_T:
				{
					g_iRedPlayersTotal--;
					if(g_bAlive[client])
						g_iRedPlayersAlive--;
						
					if(g_iSpawningMode == SPAWNING_PLAYER)
					{
						if(g_iSpawns[client] > 0 || ((g_bAlive[client] || g_hSpawning[client] != INVALID_HANDLE) && !g_iSpawns[client]))
							g_iRedPlayerSpawns--;

						if(g_bSpawningIgnore && !g_bEnding && !g_iRedPlayerSpawns)
							CS_TerminateRound(g_fRoundRestart, CSRoundEnd_CTWin);
					}
				}
				case CS_TEAM_CT:
				{
					g_iBluePlayersTotal--;
					if(g_bAlive[client])
						g_iBluePlayersAlive--;
						
					if(g_iSpawningMode == SPAWNING_PLAYER)
					{
						if(g_iSpawns[client] > 0 || ((g_bAlive[client] || g_hSpawning[client] != INVALID_HANDLE) && !g_iSpawns[client]))
							g_iBluePlayerSpawns--;

						if(g_bSpawningIgnore && !g_bEnding && !g_iBluePlayerSpawns)
							CS_TerminateRound(g_fRoundRestart, CSRoundEnd_TerroristWin);
					}
				}
			}
		}

		g_iTeam[client] = 0;
		g_iClass[client] = 0;
		g_bActivity[client] = false;
		g_iRoundsAfk[client] = 0;
		g_bAlive[client] = false;
		g_bSpawns[client] = false;
			
		if(g_iSpawningMode)
			if(g_hSpawning[client] != INVALID_HANDLE && CloseHandle(g_hSpawning[client]))
				g_hSpawning[client] = INVALID_HANDLE;
			
		if(g_hSupply[client] != INVALID_HANDLE && CloseHandle(g_hSupply[client]))
			g_hSupply[client] = INVALID_HANDLE;
	}
}

public Hook_PostThinkPost(entity)
{
	SetEntProp(entity, Prop_Send, "m_bInBuyZone", 0);
}

public Action:Hook_WeaponCanUse(client, weapon)
{
	if(weapon > 0)
	{
		decl String:_sClassname[32];
		GetEdictClassname(weapon, _sClassname, sizeof(_sClassname));
		
		if(StrEqual(_sClassname, "weapon_knife"))
			return Plugin_Continue;
		else
		{
			if(StrEqual(_sClassname, g_sGrenadeLong))
				return Plugin_Continue;
			else
			{
				AcceptEntityInput(weapon, "Kill");
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

public Action:Hook_WeaponDrop(client, weapon)
{
	if(g_bStripDeath && weapon > 0)
	{
		AcceptEntityInput(weapon, "Kill");
	}

	return Plugin_Continue;
}

public Action:Hook_OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(g_bEnabled)
	{
		if(0 < client <= MaxClients)
		{
			if(g_bPreventFalling && !attacker && damagetype == DMG_FALL)
			{
				damage = 0.0;
				return Plugin_Changed;
			}

			if(attacker == inflictor && damagetype == 4098)
			{
				if(damage > 100.0)
					damage = g_fKnifeBack;
				else if(damage > 50.0)
					damage = g_fKnifeRight;
				else
					damage = g_fKnifeLeft;

				return Plugin_Changed;
			}
			
			if(IsValidEntity(inflictor))
			{
				decl String:_sClassname[64];
				GetEdictClassname(inflictor, _sClassname, sizeof(_sClassname));
				if(!StrEqual(_sClassname, g_sGrenadeProj))
				{
					if(g_bPreventDamage)
					{
						damage = 0.0;
						return Plugin_Changed;
					}
				}
				else
				{
					damage = g_fGrenadeDamage;
					return Plugin_Changed;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bEnding = true;
		if(g_bDisplay)
		{
			g_iWinner = GetEventInt(event, "winner");
			if(g_hTimer_DisplayScore != INVALID_HANDLE)
				CloseHandle(g_hTimer_DisplayScore);

			g_fRoundLeft = g_fRoundRestart;
			Void_DisplayScore();
			g_hTimer_DisplayScore = CreateTimer(1.0, Timer_DisplayScore, _, TIMER_REPEAT);
		}

		if(g_hTimer_EndRound != INVALID_HANDLE && CloseHandle(g_hTimer_EndRound))
			g_hTimer_EndRound = INVALID_HANDLE;

		g_iCurrentRound++;
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				if(g_iSpawningMode == SPAWNING_PLAYER)
					g_bSpawns[i] = false;

				if(g_hSpawning[i] != INVALID_HANDLE && CloseHandle(g_hSpawning[i]))
					g_hSpawning[i] = INVALID_HANDLE;
				if(g_hSupply[i] != INVALID_HANDLE && CloseHandle(g_hSupply[i]))
					g_hSupply[i] = INVALID_HANDLE;

				if(g_bAlive[i])
				{
					new _iTemp;
					while((_iTemp = GetPlayerWeaponSlot(i, CS_SLOT_GRENADE)) != -1)
					{
						RemovePlayerItem(i, _iTemp);
						RemoveEdict(_iTemp);
					}
				}
			}
		}
		
		for(new i = MaxClients + 1; i < MAX_SERVER_ENTITIES; i++)
			if(g_bGrenValid[i])
				Void_Remove(i);

		CreateTimer((g_fRoundRestart * 0.5), Timer_PostRoundEnd, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action:Timer_PostRoundEnd(Handle:timer)
{
	if(g_iTeamsScramble && g_iCurrentRound >= (g_iTeamsScramble + g_iLastScramble))
	{
		g_iLastScramble = g_iCurrentRound;

		new _iRed, _iBlue, Handle:_hTemp = CreateArray();
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				switch(g_iTeam[i])
				{
					case CS_TEAM_T:
					{
						PushArrayCell(_hTemp, i);
						_iRed++;
					}
					case CS_TEAM_CT:
					{
						PushArrayCell(_hTemp, i);
						_iBlue++;
					}
				}
			}
		}

		if(_iRed >= 1 && _iBlue >= 1)
		{
			new bool:_bTemp = false;
			SortADTArray(_hTemp, Sort_Random, Sort_Integer);

			for(new i = 0; i <= ((_iRed + _iBlue) - 1); i++)
			{
				new client = GetArrayCell(_hTemp, i);
				if(_bTemp)
				{
					if(g_iTeam[client] != CS_TEAM_T)
						CS_SwitchTeam(client, CS_TEAM_T);
				}
				else
				{
					if(g_iTeam[client] != CS_TEAM_CT)
						CS_SwitchTeam(client, CS_TEAM_CT);
				}
				_bTemp = !_bTemp;
			}
		}
		
		CloseHandle(_hTemp);
	}
	else if(g_bMaintainTeams)
	{
		new _iRed, Handle:_hRed = CreateArray();
		new _iBlue, Handle:_hBlue = CreateArray();
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				switch(g_iTeam[i])
				{
					case CS_TEAM_T:
					{
						PushArrayCell(_hRed, i);
						_iRed++;
					}
					case CS_TEAM_CT:
					{
						PushArrayCell(_hBlue, i);
						_iBlue++;
					}
				}
			}
		}
		if(_iRed >= 1 && _iBlue >= 1)
		{
			SortADTArray(_hRed, Sort_Random, Sort_Integer);
			SortADTArray(_hBlue, Sort_Random, Sort_Integer);
			
			if(_iRed > _iBlue)
			{
				new _iDiff = _iRed - _iBlue;
				if(_iDiff > g_iLimitTeams)
				{
					_iDiff = (GetRandomInt(0, 1)) ? RoundToFloor(float(_iDiff) / 2.0) : RoundToCeil(float(_iDiff) / 2.0);
					for(new i = 1; i <= _iDiff; i++)
					{
						new client = GetArrayCell(_hRed, GetRandomInt(0, (_iRed - 1)));
						CS_SwitchTeam(client, CS_TEAM_CT);
						
						RemoveFromArray(_hRed, FindValueInArray(_hRed, client));
						_iRed--;
					}
				} 
			}
			else if(_iBlue > _iRed)
			{
				new _iDiff = _iBlue - _iRed;
				if(_iDiff > g_iLimitTeams)
				{
					_iDiff = (GetRandomInt(0, 1)) ? RoundToFloor(float(_iDiff) / 2.0) : RoundToCeil(float(_iDiff) / 2.0);
					for(new i = 1; i <= _iDiff; i++)
					{
						new client = GetArrayCell(_hBlue, GetRandomInt(0, (_iBlue - 1)));
						CS_SwitchTeam(client, CS_TEAM_T);
						
						RemoveFromArray(_hBlue, FindValueInArray(_hBlue, client));
						_iBlue--;
					}
				}
			}
		}
	}
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_iRedKills = g_iBlueKills = g_iRedDeaths = g_iBlueDeaths = 0;
		g_iRedPlayersTotal = g_iBluePlayersTotal = g_iRedPlayersAlive = g_iBluePlayersAlive = 0;
		switch(g_iSpawningMode)
		{
			case SPAWNING_PLAYER:
				g_iBluePlayerSpawns = g_iRedPlayerSpawns = 0;
		}
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				if(g_iSpawningMode)
					Void_OnPlayerSpawn(i);

				switch(g_iTeam[i])
				{
					case CS_TEAM_T:
					{
						g_iRedPlayersTotal++;
						g_iRedPlayersAlive++;
					}
					case CS_TEAM_CT:
					{
						g_iBluePlayersTotal++;
						g_iBluePlayersAlive++;
					}
				}
			}
		}
		
		g_bEnding = false;
		if(g_bStripObjectives || g_bStripEquipment)
			Void_Strip();

		if(g_bDisplay)
		{
			if(g_hTimer_DisplayScore != INVALID_HANDLE)
				CloseHandle(g_hTimer_DisplayScore);

			Void_DisplayScore();
			g_hTimer_DisplayScore = CreateTimer(1.0, Timer_DisplayScore, _, TIMER_REPEAT);
		}
		
		if(g_iSpawningMode != SPAWNING_DISABLED)
		{
			if(g_iSpawningNew > 0)
				g_iSpawningTime = GetTime() + g_iSpawningNew;

			if(g_bSpawningIgnore)
				SetConVarInt(g_hIgnoreConditions, 1);

			g_bSpawning = true;
			if(g_iSpawningMode == SPAWNING_TIMER)
				g_hTimer_EndRound = CreateTimer(g_fRoundTime * 60.0, Timer_EndRound);
			
			for(new i = 1; i <= MaxClients; i++)
			{
				if(g_iTeam[i] >= CS_TEAM_T && !g_bAlive[i] && IsClientInGame(i))
				{
					if(!g_iClass[i])
						g_iClass[i] = g_iTeam[i] == CS_TEAM_T ? GetRandomInt(1, 4) : GetRandomInt(5, 8);

					CS_RespawnPlayer(i);
				}
			}
		}
	}
}

public Action:Timer_EndRound(Handle:timer)
{
	g_bSpawning = false;
	g_hTimer_EndRound = INVALID_HANDLE;

	if(g_iRedKills > g_iBlueKills || (g_iRedKills == g_iBlueKills && g_iBlueDeaths > g_iRedDeaths))
	{
		SetTeamScore(CS_TEAM_T, (GetTeamScore(CS_TEAM_T) + 1));
		CS_TerminateRound(g_fRoundRestart, CSRoundEnd_TerroristWin);
	}
	else if(g_iBlueKills > g_iRedKills || (g_iRedKills == g_iBlueKills && g_iRedDeaths > g_iBlueDeaths))
	{
		SetTeamScore(CS_TEAM_CT, (GetTeamScore(CS_TEAM_CT) + 1));
		CS_TerminateRound(g_fRoundRestart, CSRoundEnd_CTWin);
	}
	else
	{
		if(g_iRedPlayersTotal >= 1 && g_iBluePlayersTotal >= 1)
		{
			SetTeamScore(CS_TEAM_T, (GetTeamScore(CS_TEAM_T) + 1));
			SetTeamScore(CS_TEAM_CT, (GetTeamScore(CS_TEAM_CT) + 1));
		}

		CS_TerminateRound(g_fRoundRestart, CSRoundEnd_Draw);
	}
}

public Action:Timer_DisplayScore(Handle:timer)
{
	Void_DisplayScore();
	return Plugin_Continue;
}

Void_DisplayScore()
{
	if(!g_bEnding)
	{
		decl String:_sBuffer[256];
		Format(_sBuffer, 256, "%T", "Phrase_Display_Title", LANG_SERVER);

		switch(g_iSpawningMode)
		{
			case SPAWNING_TIMER:
			{
				decl String:_sSpace[8];
				Format(_sBuffer, 256, "%s%T", _sBuffer, "Phrase_Display_Score", LANG_SERVER);
				Format(_sSpace, 8, "%s%s%s", g_iRedKills < 1000 ? "  " : "", g_iRedKills < 100 ? "  " : "", g_iRedKills < 10 ? "  " : "");
				Format(_sBuffer, 256, "%s%T", _sBuffer, "Phrase_Display_Score_Red", LANG_SERVER, _sSpace, g_iRedKills, g_iRedDeaths);
				Format(_sSpace, 8, "%s%s%s", g_iBlueKills < 1000 ? "  " : "", g_iBlueKills < 100 ? "  " : "", g_iBlueKills < 10 ? "  " : "");
				Format(_sBuffer, 256, "%s%T", _sBuffer, "Phrase_Display_Score_Blue", LANG_SERVER, _sSpace, g_iBlueKills, g_iBlueDeaths);
			}
			case SPAWNING_PLAYER:
			{
				decl String:_sRedSpace[8], String:_sBlueSpace[8];
				Format(_sRedSpace, 8, "%s%s", g_iRedPlayerSpawns < 100 ? " " : "", g_iRedPlayerSpawns < 10 ? " " : "");
				Format(_sBlueSpace, 8, "%s%s", g_iBluePlayerSpawns < 100 ? " " : "", g_iBluePlayerSpawns < 10 ? " " : "");
				Format(_sBuffer, 256, "%s%T", _sBuffer, "Phrase_Display_Players", LANG_SERVER, _sRedSpace, g_iRedPlayerSpawns, _sBlueSpace, g_iBluePlayerSpawns);
			}
		}

		new Handle:_hMessage = StartMessageAll("KeyHintText");
		BfWriteByte(_hMessage, 1);
		BfWriteString(_hMessage, _sBuffer); 
		EndMessage();
	}
	else if(g_fRoundRestart >= 1.0)
	{
		decl String:_sBuffer[128];
		Format(_sBuffer, 128, "%T", "Phrase_Display_Title", LANG_SERVER);
		if(g_iWinner == CS_TEAM_T)
			Format(_sBuffer, 128, "%s%T", _sBuffer, "Phrase_Display_Intermission_Red", LANG_SERVER, g_fRoundLeft);
		else if(g_iWinner == CS_TEAM_CT)
			Format(_sBuffer, 128, "%s%T", _sBuffer, "Phrase_Display_Intermission_Blue", LANG_SERVER, g_fRoundLeft);
		else
			Format(_sBuffer, 128, "%s%T", _sBuffer, "Phrase_Display_Intermission", LANG_SERVER, g_fRoundLeft);
		new Handle:_hMessage = StartMessageAll("KeyHintText");
		BfWriteByte(_hMessage, 1);
		BfWriteString(_hMessage, _sBuffer); 
		EndMessage();

		g_fRoundLeft -= 1.0;
	}
}


public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new userid = GetEventInt(event, "userid");
		new client = GetClientOfUserId(userid);
		if(!client || !IsClientInGame(client) || g_iTeam[client] < CS_TEAM_T)
			return Plugin_Continue;
			
		new _iEntity;
		g_bAlive[client] = true;
		g_bActivity[client] = false;
		for(new i = 0; i < 5; i++)
		{
			while(i != CS_SLOT_KNIFE && (_iEntity = GetPlayerWeaponSlot(client, i)) != -1)
			{
				RemovePlayerItem(client, _iEntity);
				AcceptEntityInput(_iEntity, "Kill");
			}
		}

		SetEntityHealth(client, g_iPlayerHealth);
		if(g_iSupplyCount)
			g_iCount[client] = g_iSupplyCount;

		GivePlayerItem(client, g_sGrenadeLong);
		SetEntData(client, (FindDataMapOffs(client, "m_iAmmo") + (AMMO_FLASHBANG * 4)), g_iSupplyCount > 0 ? g_iSupplyCount : AMMO_COUNT);

		if(!g_bEnding && g_iSpawningMode)
			Void_OnPlayerSpawn(client);
			
		switch(g_iTeam[client])
		{
			case CS_TEAM_T:
				g_iRedPlayersAlive++;
			case CS_TEAM_CT:
				g_iBluePlayersAlive++;
		}
	}
	
	return Plugin_Continue;
}

Void_OnPlayerSpawn(client)
{		
	switch(g_iSpawningMode)
	{
		case SPAWNING_PLAYER:
		{
			if(!g_bSpawns[client])
			{
				g_bSpawns[client] = true;
				g_iSpawns[client] = g_iSpawningFactor;

				switch(g_iTeam[client])
				{
					case CS_TEAM_T:
						g_iRedPlayerSpawns++;
					case CS_TEAM_CT:
						g_iBluePlayerSpawns++;
				}
			}
		}
	}
}

public Action:Timer_OnPlayerSpawn(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client && g_bAlive[client] && IsClientInGame(client))
	{
		GivePlayerItem(client, "weapon_knife");
		GivePlayerItem(client, g_sGrenadeLong);

		SetEntData(client, (FindDataMapOffs(client, "m_iAmmo") + (AMMO_FLASHBANG * 4)), g_iSupplyCount > 0 ? g_iSupplyCount : AMMO_COUNT);
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		if(g_bGrenadeString)
		{
			decl String:_sWeapon[32];
			GetEventString(event, "weapon", _sWeapon, sizeof(_sWeapon));
			if(StrEqual(_sWeapon, g_sGrenadeShor))
				SetEventString(event, "weapon", g_sGrenadeString);
		}
		
		if(g_iMaxRoundsAfk)
		{
			if(!g_bActivity[client])
			{
				g_iRoundsAfk[client]++;
				if(g_iRoundsAfk[client] >= g_iMaxRoundsAfk)
				{
					g_iRoundsAfk[client] = 0;
					ChangeClientTeam(client, CS_TEAM_SPECTATOR);

					CPrintToChat(client, "%s%t", g_sPrefixChat, "Phrase_Afk_Spectate");
				}
			}
			else
				g_iRoundsAfk[client] = 0;
		}
			
		g_bAlive[client] = false;
		if(g_hSupply[client] != INVALID_HANDLE && CloseHandle(g_hSupply[client]))
			g_hSupply[client] = INVALID_HANDLE;

		switch(g_iTeam[client])
		{
			case CS_TEAM_T:
				g_iRedPlayersAlive--;
			case CS_TEAM_CT:
				g_iBluePlayersAlive--;
		}
		
		if(!g_bEnding && g_iSpawningMode && g_iClass[client])
		{
			switch(g_iSpawningMode)
			{
				case SPAWNING_TIMER:
				{
					new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
					if(attacker && attacker <= MaxClients)
					{
						switch(g_iTeam[client])
						{
							case CS_TEAM_T:
							{
								g_iBlueKills++;
								g_iRedDeaths++;
							}
							case CS_TEAM_CT:
							{
								g_iRedKills++;
								g_iBlueDeaths++;
							}
						}
					}

					g_hSpawning[client] = CreateTimer(0.1, Timer_CheckSpawn, client);
				}
				case SPAWNING_PLAYER:
				{
					if(!g_iRedPlayersTotal || !g_iBluePlayersTotal)
						g_hSpawning[client] = CreateTimer(0.1, Timer_CheckSpawn, client);
					else
					{
						if(g_iSpawns[client] > 0)
						{
							g_iSpawns[client]--;
							g_hSpawning[client] = CreateTimer(0.1, Timer_CheckSpawn, client);
						}
						else if(!g_iSpawns[client])
						{
							switch(g_iTeam[client])
							{
								case CS_TEAM_T:
								{
									g_iRedPlayerSpawns--;

									if(g_bSpawningIgnore && !g_bEnding && !g_iRedPlayerSpawns)
										CS_TerminateRound(g_fRoundRestart, CSRoundEnd_CTWin);
								}
								case CS_TEAM_CT:
								{
									g_iBluePlayerSpawns--;

									if(g_bSpawningIgnore && !g_bEnding && !g_iBluePlayerSpawns)
										CS_TerminateRound(g_fRoundRestart, CSRoundEnd_TerroristWin);
								}
							}
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;
		
		g_iTeam[client] = GetEventInt(event, "team");
		new _iPrevious = GetEventInt(event, "oldteam");
		if(g_iTeam[client] == _iPrevious)
			return Plugin_Handled;
		else if(!g_bEnding)
		{
			if(!g_bManual[client])
				if(g_hSpawning[client] != INVALID_HANDLE && CloseHandle(g_hSpawning[client]))
					g_hSpawning[client] = INVALID_HANDLE;

			switch(_iPrevious)
			{
				case CS_TEAM_T:
				{
					g_iRedPlayersTotal--;
					if(!g_bManual[client])
					{
						if(g_iSpawningMode == SPAWNING_PLAYER)
							if(g_iSpawns[client] >= 0)
								g_iRedPlayerSpawns--;
					
						if(g_bAlive[client])
							g_iRedPlayersAlive--;
					}
				}
				case CS_TEAM_CT:
				{
					g_iBluePlayersTotal--;
					if(!g_bManual[client])
					{
						if(g_iSpawningMode == SPAWNING_PLAYER)
							if(g_iSpawns[client] >= 0)
								g_iBluePlayerSpawns--;
					
						if(g_bAlive[client])
							g_iBluePlayersAlive--;
					}
				}
			}

			switch(g_iTeam[client])
			{
				case CS_TEAM_T:
				{
					g_iRedPlayersTotal++;
					if(!g_bManual[client])
					{
						if(g_iSpawningMode == SPAWNING_PLAYER)
							if(g_iSpawns[client] >= 0)
								g_iRedPlayerSpawns++;
					
						if(g_bAlive[client])
							g_iRedPlayersAlive++;
					}
				}
				case CS_TEAM_CT:
				{
					g_iBluePlayersTotal++;
					if(!g_bManual[client])
					{
						if(g_iSpawningMode == SPAWNING_PLAYER)
							if(g_iSpawns[client] >= 0)
								g_iBluePlayerSpawns++;
					
						if(g_bAlive[client])
							g_iBluePlayersAlive++;
					}
				}
				case CS_TEAM_SPECTATOR:
				{
					if(!g_bManual[client])
						g_bAlive[client] = false;
					else
						g_bManual[client] = false;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_CheckSpawn(Handle:timer, any:client)
{
	if(g_bAlive[client] || !g_bSpawning || g_iTeam[client] <= CS_TEAM_SPECTATOR)
		g_hSpawning[client] = INVALID_HANDLE;
	else
	{
		if(!g_iRedPlayersTotal || !g_iBluePlayersTotal)
			g_fSpawning[client] = g_fSpawningDelay;
		else
		{
			switch(g_iSpawningMode)
			{
				case SPAWNING_PLAYER:
				{
					switch(g_iTeam[client])
					{
						case CS_TEAM_T:
							g_fSpawning[client] = g_bSpawningDynamic ? (g_fSpawningDelay * g_iRedPlayerSpawns) : g_fSpawningDelay;
						case CS_TEAM_CT:
							g_fSpawning[client] = g_bSpawningDynamic ? (g_fSpawningDelay * g_iBluePlayerSpawns) : g_fSpawningDelay;
					}
				}
				default:
				{
					switch(g_iTeam[client])
					{
						case CS_TEAM_T:
							g_fSpawning[client] = g_bSpawningDynamic ? (g_fSpawningDelay * g_iRedPlayersTotal) : g_fSpawningDelay;
						case CS_TEAM_CT:
							g_fSpawning[client] = g_bSpawningDynamic ? (g_fSpawningDelay * g_iBluePlayersTotal) : g_fSpawningDelay;
					}
				}
			}
		}

		if(g_fSpawning[client] >= 1.0)
		{
			PrintCenterText(client, "%t", "Phrase_Spawn_Notify", g_fSpawning[client]);
			g_hSpawning[client] = CreateTimer(1.0, Timer_SpawnNotify, client, TIMER_REPEAT);
		}
		else
			g_hSpawning[client] = CreateTimer(g_fSpawning[client], Timer_SpawnPlayer, client);
	}
}


public Action:Timer_SpawnNotify(Handle:timer, any:client)
{
	if(g_bAlive[client])
		g_hSpawning[client] = INVALID_HANDLE;
	else
	{
		g_fSpawning[client] -= 1.0;
		if(g_fSpawning[client] <= 0.0)
			g_hSpawning[client] = CreateTimer(g_fSpawning[client], Timer_SpawnPlayer, client);
		else
		{
			PrintCenterText(client, "%t", "Phrase_Spawn_Notify", g_fSpawning[client]);
			return Plugin_Continue;
		}
	}

	return Plugin_Stop;
}

public Action:Timer_SpawnPlayer(Handle:timer, any:client)
{
	g_hSpawning[client] = INVALID_HANDLE;
	if(!g_bAlive[client])
		CS_RespawnPlayer(client);
}

public Action:Event_OnWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;
		
		decl String:_sBuffer[32];
		GetEventString(event, "weapon", _sBuffer, sizeof(_sBuffer));
		if(StrEqual(_sBuffer, g_sGrenadeShor))
		{
			if(g_iSupplyCount)
			{
				if(g_iCount[client] > 0)
				{
					g_iCount[client]--;
					g_hSupply[client] = CreateTimer(g_fSupplyDelay, Timer_OnWeaponFire, client);
				}
			}
			else
				g_hSupply[client] = CreateTimer(g_fSupplyDelay, Timer_OnWeaponFire, client);
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_OnWeaponFire(Handle:timer, any:client)
{
	if(g_bAlive[client])
	{
		if(!g_iSupplyCount)
			SetEntData(client, (FindDataMapOffs(client, "m_iAmmo") + (AMMO_FLASHBANG * 4)), AMMO_COUNT);

		if(g_bSupplyEquip)
			CreateTimer(0.1, Timer_Auto, client);

		if(g_iSupplyCount)
			PrintHintText(client, "%s%t", g_sPrefixHint, g_iCount[client] ? "Phrase_Remaining" : "Phase_Remaining_Empty", g_iCount[client]);
	}
	
	g_hSupply[client] = INVALID_HANDLE;
}

public Action:Timer_Auto(Handle:timer, any:client)
{
	FakeClientCommandEx(client, "use weapon_knife");
	FakeClientCommandEx(client, "use weapon_flashbang");
}

public Action:Command_Kill(client, const String:command[], argc)
{
	if(g_bEnabled && g_bPreventSuicide)
	{
		if(client && g_bAlive[client] && IsClientInGame(client))
		{
			CPrintToChat(client, "%s%t", g_sPrefixChat, "Phrase_Prevent_Suicide");
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action:Command_Join(client, const String:command[], argc)
{
	if(g_bEnabled && client && IsClientInGame(client))
	{
		decl String:_sTemp[3];
		GetCmdArg(1, _sTemp, sizeof(_sTemp));
		new _iTemp = StringToInt(_sTemp);

		if(_iTemp == g_iTeam[client])
			return Plugin_Handled;
		else
			g_bManual[client] = true;
	}
	
	return Plugin_Continue;
}

public Action:Command_Class(client, const String:command[], argc)
{
	if(g_bEnabled && client && IsClientInGame(client))
	{
		decl String:_sTemp[3];
		GetCmdArg(1, _sTemp, sizeof(_sTemp));
		//new _iTemp = StringToInt(_sTemp);
		
		if(!g_bManual[client])
		{
			if(g_bPreventSuicide && g_bAlive[client])
				CPrintToChat(client, "%s%t", g_sPrefixChat, "Phrase_Prevent_Suicide");

			return Plugin_Handled;
		}
		else
		{
			if(!g_bEnding && g_iSpawningMode)
			{
				if(g_bSpawningIgnore && g_iRedPlayersTotal == 1 && g_iBluePlayersTotal == 1)
				{
					SetTeamScore(CS_TEAM_T, 0);
					SetTeamScore(CS_TEAM_CT, 0);
					for(new i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i))
						{
							SetEntProp(i, Prop_Data, "m_iFrags", 0);
							SetEntProp(i, Prop_Data, "m_iDeaths", 0);
						}
					}
					
					CS_TerminateRound(g_fRoundRestart, CSRoundEnd_GameStart);
					return Plugin_Handled;
				}
				else
				{
					switch(g_iSpawningMode)
					{
						case SPAWNING_TIMER:
						{
							if(g_bSpawning)
								g_hSpawning[client] = CreateTimer(0.1, Timer_CheckSpawn, client);
						}
						case SPAWNING_PLAYER:
						{
							if(g_iSpawns[client] > 0 || (!g_iRedPlayersTotal || !g_iBluePlayersTotal))
								g_hSpawning[client] = CreateTimer(0.1, Timer_CheckSpawn, client);
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Command_Radio(client, const String:command[], argc)
{
	if(g_bEnabled && g_bPreventRadio)
	{
		if(client && IsClientInGame(client))
		{
			CPrintToChat(client, "%s%t", g_sPrefixChat, "Phrase_Prevent_Radio");
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

Void_SetDefaults()
{
	g_bEnabled = GetConVarInt(g_hEnabled) ? true : false;
	if(g_bEnabled)
	{
		g_fSupplyDelay = GetConVarFloat(g_hSupplyDelay);
		g_iGrenadeBounce = GetConVarInt(g_hGrenadeBounce);
		GetConVarString(g_hGrenadeString, g_sGrenadeString, sizeof(g_sGrenadeString));
		g_bGrenadeString = StrEqual(g_sGrenadeString, "") ? false : true;
		g_iGrenadeLife = GetConVarInt(g_hGrenadeLife);
		g_iSupplyCount = GetConVarInt(g_hSupplyCount);
		g_iPlayerHealth = GetConVarInt(g_hPlayerHealth);
		g_fGrenadeDamage = GetConVarFloat(g_hGrenadeDamage);
		g_fKnifeLeft = GetConVarFloat(g_hKnifeLeft);
		g_fKnifeRight = GetConVarFloat(g_hKnifeRight);
		g_fKnifeBack = GetConVarFloat(g_hKnifeBack);
		g_bPreventRadio = GetConVarInt(g_hPreventRadio) ? true : false;
		g_bPreventSuicide = GetConVarInt(g_hPreventSuicide) ? true : false;
		g_bPreventDamage = GetConVarInt(g_hPreventDamage) ? true : false;
		g_bStripObjectives = GetConVarInt(g_hStripObjectives) ? true : false;
		g_bStripEquipment = GetConVarInt(g_hStripEquipment) ? true : false;
		g_bStripDeath = GetConVarInt(g_hStripDeath) ? true : false;
		g_bExtraSpawns = GetConVarInt(g_hExtraSpawns) ? true : false;
		g_iTeamsScramble = GetConVarInt(g_hScrambleTeams);
		g_bMaintainTeams = GetConVarInt(g_hMaintainTeams) ? true : false;
		g_bSupplyEquip = GetConVarInt(g_hSupplyEquip) ? true : false;
		g_bIgnite = GetConVarInt(g_hGrenadeIgnite) ? true : false;
		g_iMaxRoundsAfk = GetConVarInt(g_hMaxRoundsAfk);
		g_iSpawningMode = GetConVarInt(g_hSpawningMode);
		g_fSpawningDelay = GetConVarFloat(g_hSpawningDelay);
		g_bSpawningDynamic = g_fSpawningDelay >= 0.0 ? false : true;
		g_fSpawningDelay = FloatAbs(g_fSpawningDelay);
		g_bSpawningIgnore = GetConVarInt(g_hSpawningIgnore) ? true : false;
		g_iSpawningFactor = GetConVarInt(g_hSpawningFactor);
		g_iSpawningNew = GetConVarInt(g_hSpawningNew);
		if(g_iSpawningNew > 0)
			g_iSpawningTime = GetTime() + g_iSpawningNew;
		g_bDisplay = GetConVarInt(g_hDisplay) ? true : false;
		g_iGrenadeDissolve = GetConVarInt(g_hGrenadeDissolve);
		IntToString(g_iGrenadeDissolve, g_sGrenadeDissolve, sizeof(g_sGrenadeDissolve));
		g_iLimitTeams = GetConVarInt(g_hLimitTeams);
		g_fRoundRestart = GetConVarFloat(g_hRoundRestart);
		g_fRoundTime = GetConVarFloat(g_hRoundTime);
	}
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
	{
		g_bEnabled = StringToInt(newvalue) ? true : false;
		if(!g_bEnabled)
		{
			if(StringToInt(oldvalue))
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i))
					{
						SDKUnhook(i, SDKHook_PostThinkPost, Hook_PostThinkPost);
						SDKUnhook(i, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
						SDKUnhook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
						SDKUnhook(i, SDKHook_WeaponDrop, Hook_WeaponDrop);
					}
				}
			}
		}
		else if(!StringToInt(oldvalue))
		{
			Void_SetDefaults();
			Void_Downloads();
			Void_Models();
			if(g_bModels)
				g_iGrenadeModel = GetRandomInt(0, (g_iNumModels - 1));

			if(g_bExtraSpawns)
				CreateTimer(0.1, Timer_OnMapStart);

			if(g_bStripObjectives || g_bStripEquipment)
				Void_Strip();
				
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_iTeam[i] = GetClientTeam(i);
					g_bAlive[i] = IsPlayerAlive(i) ? true : false;
					g_iClass[i] = g_iTeam[i] == CS_TEAM_T ? GetRandomInt(1, 4) : GetRandomInt(5, 8);

					SDKHook(i, SDKHook_PostThinkPost, Hook_PostThinkPost);
					SDKHook(i, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
					SDKHook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
					SDKHook(i, SDKHook_WeaponDrop, Hook_WeaponDrop);
				}
			}
				
			CS_TerminateRound(g_fRoundRestart, CSRoundEnd_GameStart);
		}
	}
	else if(cvar == g_hSupplyDelay)
		g_fSupplyDelay = StringToFloat(newvalue);
	else if(cvar == g_hGrenadeBounce)
		g_iGrenadeBounce = StringToInt(newvalue);
	else if(cvar == g_hGrenadeString)
	{
		Format(g_sGrenadeString, sizeof(g_sGrenadeString), "%s", newvalue);
		g_bGrenadeString = StrEqual(g_sGrenadeString, "") ? false : true;
	}
	else if(cvar == g_hGrenadeLife)
		g_iGrenadeLife = StringToInt(newvalue);
	else if(cvar == g_hSupplyCount)
		g_iSupplyCount = StringToInt(newvalue);
	else if(cvar == g_hPlayerHealth)
		g_iPlayerHealth = StringToInt(newvalue);
	else if(cvar == g_hGrenadeDamage)
		g_fGrenadeDamage = StringToFloat(newvalue);
	else if(cvar == g_hKnifeLeft)
		g_fKnifeLeft = StringToFloat(newvalue);
	else if(cvar == g_hKnifeRight)
		g_fKnifeRight = StringToFloat(newvalue);
	else if(cvar == g_hKnifeBack)
		g_fKnifeBack = StringToFloat(newvalue);
	else if(cvar == g_hPreventRadio)
		g_bPreventRadio = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hPreventSuicide)
		g_bPreventSuicide = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hPreventDamage)
		g_bPreventDamage = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hPreventFalling)
		g_bPreventFalling = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hStripObjectives)
		g_bStripObjectives = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hStripEquipment)
		g_bStripEquipment = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hStripDeath)
		g_bStripDeath = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hExtraSpawns)
		g_bExtraSpawns = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hScrambleTeams)
		g_iTeamsScramble = StringToInt(newvalue);
	else if(cvar == g_hMaintainTeams)
		g_bMaintainTeams = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hSupplyEquip)
		g_bSupplyEquip = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hGrenadeIgnite)
		g_bIgnite = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hMaxRoundsAfk)
		g_iMaxRoundsAfk = StringToInt(newvalue);
	else if(cvar == g_hSpawningMode)
		g_iSpawningMode = StringToInt(newvalue);
	else if(cvar == g_hSpawningDelay)
	{
		g_fSpawningDelay = StringToFloat(newvalue);
		g_bSpawningDynamic = g_fSpawningDelay >= 0.0 ? false : true;
		g_fSpawningDelay = FloatAbs(g_fSpawningDelay);
	}
	else if(cvar == g_hSpawningIgnore)
		g_bSpawningIgnore = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hSpawningFactor)
		g_iSpawningFactor = StringToInt(newvalue);
	else if(cvar == g_hSpawningNew)
	{
		g_iSpawningNew = StringToInt(newvalue);
		if(g_iSpawningNew > 0)
			g_iSpawningTime = GetTime() + g_iSpawningNew;
	}		
	else if(cvar == g_hDisplay)
		g_bDisplay = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hGrenadeDissolve)
	{
		g_iGrenadeDissolve = StringToInt(newvalue);
		IntToString(g_iGrenadeDissolve, g_sGrenadeDissolve, sizeof(g_sGrenadeDissolve));
	}
	else if(cvar == g_hLimitTeams)
		g_iLimitTeams = StringToInt(newvalue);
	else if(cvar == g_hRoundRestart)
		g_fRoundRestart = StringToFloat(newvalue);
	else if(cvar == g_hRoundTime)
		g_fRoundTime = StringToFloat(newvalue);
}

Void_Models()
{
	g_iNumModels = 0;
	decl String:_sPath[256];
	new Handle:_hKV = CreateKeyValues("CSSDodgeball_Models");
	BuildPath(Path_SM, _sPath, 256, "configs/dodgeball/css_dodgeball.models.txt");
	if(FileToKeyValues(_hKV, _sPath))
	{
		KvGotoFirstSubKey(_hKV);
		do
		{
			KvGetSectionName(_hKV, g_sModelName[g_iNumModels], 64);
			KvGetString(_hKV, "path", g_sModelPath[g_iNumModels], 256);
			PrecacheModel(g_sModelPath[g_iNumModels]);

			g_iNumModels++;
		}
		while (KvGotoNextKey(_hKV));
	}

	CloseHandle(_hKV);
	g_bModels = g_iNumModels ? true : false;
}

Void_Downloads()
{
	new String:_sBuffer[256];
	BuildPath(Path_SM, _sBuffer, sizeof(_sBuffer), "configs/dodgeball/css_dodgeball.downloads.txt");
	new Handle:_hTemp = OpenFile(_sBuffer, "r");

	if(_hTemp != INVALID_HANDLE) 
	{
		new _iLength;
		while (ReadFileLine(_hTemp, _sBuffer, sizeof(_sBuffer)))
		{	
			_iLength = strlen(_sBuffer);
			if (_sBuffer[(_iLength - 1)] == '\n')
				_sBuffer[--_iLength] = '\0';

			TrimString(_sBuffer);
			if (!StrEqual(_sBuffer, "", false))
				Void_ReadFileFolder(_sBuffer);

			if (IsEndOfFile(_hTemp))
				break;
		}

		CloseHandle(_hTemp);
	}
}

Void_ReadFileFolder(String:_sPath[])
{
	new Handle:_hTemp = INVALID_HANDLE;
	new _iLength, FileType:_iFileType = FileType_Unknown;
	decl String:_sBuffer[256], String:_sLine[256];
	
	_iLength = strlen(_sPath);
	if (_sPath[_iLength-1] == '\n')
		_sPath[--_iLength] = '\0';

	TrimString(_sPath);
	if(DirExists(_sPath))
	{
		_hTemp = OpenDirectory(_sPath);
		while(ReadDirEntry(_hTemp, _sBuffer, sizeof(_sBuffer), _iFileType))
		{
			_iLength = strlen(_sBuffer);
			if (_sBuffer[_iLength-1] == '\n')
				_sBuffer[--_iLength] = '\0';
			TrimString(_sBuffer);

			if (!StrEqual(_sBuffer, "") && !StrEqual(_sBuffer, ".", false) && !StrEqual(_sBuffer,"..",false))
			{
				strcopy(_sLine, sizeof(_sLine), _sPath);
				StrCat(_sLine, sizeof(_sLine), "/");
				StrCat(_sLine, sizeof(_sLine), _sBuffer);

				if(_iFileType == FileType_File)
					Void_ReadItem(_sLine);
				else
					Void_ReadFileFolder(_sLine);
			}
		}
	}
	else
		Void_ReadItem(_sPath);

	if(_hTemp != INVALID_HANDLE)
		CloseHandle(_hTemp);
}

Void_ReadItem(String:_sBuffer[])
{
	decl String:_sTemp[3];
	new _iLength = strlen(_sBuffer);
	if (_sBuffer[_iLength-1] == '\n')
		_sBuffer[--_iLength] = '\0';
	TrimString(_sBuffer);

	strcopy(_sTemp, sizeof(_sTemp), _sBuffer);
	if(!StrEqual(_sBuffer, "") && StrContains(_sBuffer, "//") == -1)
	{
		if (FileExists(_sBuffer))
		{
			if((StrContains(_sBuffer, ".wav") >= 0) || (StrContains(_sBuffer, ".mp3") >= 0))
				PrecacheSound(_sBuffer);
			else if(StrContains(_sBuffer, ".mdl") >= 0)
				PrecacheModel(_sBuffer);

			AddFileToDownloadsTable(_sBuffer);
		}
	}
}

Void_Strip()
{
	decl String:_sBuffer[64];
	for(new i = MaxClients + 1; i <= 2048; i++)
	{
		if(!IsValidEdict(i) || !IsValidEntity(i))
			continue;

		GetEdictClassname(i, _sBuffer, sizeof(_sBuffer));
		if(g_bStripObjectives && StrContains("func_bomb_target|func_hostage_rescue|c4|hostage_entity", _sBuffer) >= 0)
			RemoveEdict(i);
		if(g_bStripEquipment && StrContains("weapon_", _sBuffer) >= 0 && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") <= 0)
			RemoveEdict(i);
	}
}

Void_SetSpawns()
{
	decl _iNeeded, entity, Float:_fTemp[3];

	entity = -1;
	g_iNumRedSpawns = 0;
	while((entity = FindEntityByClassname(entity, "info_player_terrorist")) != -1)
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", g_fRedTeleports[g_iNumRedSpawns]);
		g_iNumRedSpawns++;
	}

	_iNeeded = RoundToCeil(float(MaxClients) / 2.0) - g_iNumRedSpawns;
	while(_iNeeded > 0)
	{
		_fTemp = g_fRedTeleports[GetRandomInt(0, (g_iNumRedSpawns - 1))];
		_fTemp[2] += 1.0;
				
		entity = CreateEntityByName("info_player_terrorist");
		DispatchSpawn(entity);
		TeleportEntity(entity, _fTemp, NULL_VECTOR, NULL_VECTOR);
		_iNeeded--;
	}

	entity = -1;
	g_iNumBlueSpawns = 0;
	while((entity = FindEntityByClassname(entity, "info_player_counterterrorist")) != -1)
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", g_fBlueTeleports[g_iNumBlueSpawns]);
		g_iNumBlueSpawns++;
	}

	_iNeeded = RoundToCeil(float(MaxClients) / 2.0) - g_iNumBlueSpawns;
	while(_iNeeded > 0)
	{
		_fTemp = g_fBlueTeleports[GetRandomInt(0, (g_iNumBlueSpawns - 1))];
		_fTemp[2] += 1.0;

		entity = CreateEntityByName("info_player_counterterrorist");
		DispatchSpawn(entity);
		TeleportEntity(entity, _fTemp, NULL_VECTOR, NULL_VECTOR);
		_iNeeded--;
	}
}

Void_Remove(entity, bool:_bKill = false)
{
	if(g_hGrenTimer[entity] != INVALID_HANDLE && CloseHandle(g_hGrenTimer[entity]))
		g_hGrenTimer[entity] = INVALID_HANDLE;

	if(IsValidEntity(entity))
	{
		if(g_iGrenadeDissolve >= 0 && !_bKill)
		{
			new _iDissolve = CreateEntityByName("env_entity_dissolver");
			if(_iDissolve > 0)
			{
				decl String:_sName[16];
				GetEntPropString(entity, Prop_Data, "m_iName", _sName, 16);

				DispatchKeyValue(_iDissolve, "dissolvetype", g_sGrenadeDissolve);
				DispatchKeyValue(_iDissolve, "target", _sName);
				AcceptEntityInput(_iDissolve, "Dissolve");

				CreateTimer(0.1, Timer_KillEntity, EntIndexToEntRef(_iDissolve));
				return;
			}
		}
			
		AcceptEntityInput(entity, "Kill");
	}
}

public Action:Timer_KillEntity(Handle:timer, any:ref)
{
	new entity = EntRefToEntIndex(ref);
	if(entity != INVALID_ENT_REFERENCE)
		AcceptEntityInput(entity, "Kill");
}