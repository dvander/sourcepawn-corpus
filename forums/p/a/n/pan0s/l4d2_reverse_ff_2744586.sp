/*

Reverse Friendly-Fire (l4d_reverse_ff) by Mystik Spiral

This Left4Dead2 SourceMod plugin reverses friendly-fire... the attacker takes all of the damage and the victim takes none.
This forces players to be more precise with their shots... or they will spend a lot of time on the ground.

Although this plugin discourages griefers/team killers since they can only damage themselves and no one else, the first objective is to force players to improve their shooting tatics and aim. The second objective is to encourage new/inexperienced players to only join games with a difficulty that match their skillset, rather than trying to play at a difficulty above their ability and constantly incapping their teammates.

This plugin reverses damage from the grenade launcher, but does not otherwise reverse explosion damage. This plugin does not reverse molotov/gascan damage and I do not intend to add it, though I may make a separate plugin to handle molotov/gascan damage.  Now reverses "friendly-fire for infected team too.

    Option to specify extra damage if attacker is using explosive/incendiary ammo. [reverseff_multiplier (default: 1.125 {12.5%})]
    Option to reverse friendly-fire when attacker is admin. [reverseff_admin (default: false)]
    Option to reverse friendly-fire when victim is a bot. [reverseff_bot (default: false)]
    Option to reverse friendly-fire when victim is incapacitated. [reverseff_incapped (default: false)]
    Option to reverse friendly-fire when attacker is incapacitated. [reverseff_attackerincapped (default: false)]
    Option to reverse friendly-fire when damage from mounted gun. [reverseff_mountedgun (default: true)]
    Option to reverse friendly-fire when damage from melee weapon. [reverseff_melee (default: true)]
    Option to reverse friendly-fire when damage from chainsaw. [reverseff_chainsaw (default: true)]
    Option to reverse friendly-fire during Smoker pull or Charger carry. [reverseff_pullcarry (default: false)]
    Option to treat friendly-fire as self damage (or reversed accusations). [reverseff_self (default: false)]
    Option to specify maximum survivor damage allowed per chapter before ban. [reverseff_survivormaxdmg (default: 200)]
    Option to specify maximum infected damage allowed per chapter before ban. [reverseff_infectedmaxdmg (default: 50)]
    Option to specify maximum tank damage allowed per chapter before ban. [reverseff_tankmaxdmg (default: 300)]
    Option to specify ban duration in minutes (0=permanent, -1=kick). [reverseff_banduration (default: 10)]
    Option to enable/disable plugin by game mode. [reverseff_modes_on, reverseff_modes_off, reverseff_modes_tog (default: enabled for all game modes)]


Suggestion:

To minimize griefer impact, use this plugin along with...

ReverseBurn and ExplosionAnnouncer (l4d_ReverseBurn_and_ExplosionAnnouncer)
...and...
ReverseBurn and ThrowableAnnouncer (l4d_ReverseBurn_and_ThrowableAnnouncer)

When these plugins are combined, griefers cannot inflict friendly-fire, and it minimizes damage to victims for molotov and explodable burn types (gascans, fireworks, etc.).
Although griefers will take significant damage, other players may not notice any difference in game play.

Want to contribute code enhancements?
Create a pull request using this GitHub repository: https://github.com/Mystik-Spiral/l4d_reverse_ff

Plugin discussion: https://forums.alliedmods.net/showthread.php?t=329035

*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.5"
#define CVAR_FLAGS FCVAR_NOTIFY
#define TRANSLATION_FILENAME "l4d_reverse_ff.phrases"

ConVar cvar_reverseff_admin;
ConVar cvar_reverseff_multiplier;
ConVar cvar_reverseff_bot;
ConVar cvar_reverseff_survivormaxdmg;
ConVar cvar_reverseff_infectedmaxdmg;
ConVar cvar_reverseff_tankmaxdmg;
ConVar cvar_reverseff_banduration;
ConVar cvar_reverseff_incapped;
ConVar cvar_reverseff_attackerincapped;
ConVar cvar_reverseff_self;
ConVar cvar_reverseff_mountedgun;
ConVar cvar_reverseff_melee;
ConVar cvar_reverseff_chainsaw;
ConVar cvar_reverseff_pullcarry;
ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModesOn, g_hCvarModesOff, g_hCvarModesTog;

float g_fCvarDamageMultiplier;
float g_fAccumDamage[MAXPLAYERS + 1];
float g_fAccumDamageAsTank[MAXPLAYERS + 1];
float g_fAccumDamageAsInfected[MAXPLAYERS + 1];
float g_fSurvivorMaxDamage;
float g_fInfectedMaxDamage;
float g_fTankMaxDamage;

int g_iBanDuration;

bool g_bCvarReverseIfAdmin;
bool g_bCvarReverseIfBot;
bool g_bCvarReverseIfIncapped;
bool g_bCvarReverseIfAttackerIncapped;
bool g_bCvarReverseIfPullCarry;
bool g_bCvarSelfDamage;
bool g_bCvarReverseIfMountedgun;
bool g_bCvarReverseIfMelee;
bool g_bCvarReverseIfChainsaw;
bool g_bGrace[MAXPLAYERS + 1];
bool g_bToggle[MAXPLAYERS + 1];
bool g_bCvarAllow, g_bMapStarted;
bool g_bL4D2;
bool g_bAllReversePlugins;
bool g_bLateLoad;

Handle g_hEndGrace[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "[L4D & L4D2] Reverse Friendly-Fire",
	author = "Mystic Spiral, chainsaw damange bug fixed by pan0s",
	description = "Reverses friendly-fire... attacker takes damage, victim does not.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2727641#post2727641"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2)
	{
		g_bL4D2 = true;
		g_bLateLoad = late;
		return APLRes_Success;
	}
	if ( test == Engine_Left4Dead )
	{
		g_bL4D2 = false;
		g_bLateLoad = late;
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
	return APLRes_SilentFailure;
}

public void OnAllPluginsLoaded()
{
	if (FindConVar("RBaEA_version") != null)
	{
		if (FindConVar("RBaTA_version") != null)
		{
			g_bAllReversePlugins = true;
		}
	}
}

public void OnPluginStart()
{
	LoadPluginTranslations();
	
	CreateConVar("reverseff_version", PLUGIN_VERSION, "Reverse Friendly-Fire", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_reverseff_admin = CreateConVar("reverseff_admin", "1", "0=Do not ReverseFF if attacker is admin, 1=ReverseFF if attacker is admin", CVAR_FLAGS);
	cvar_reverseff_bot = CreateConVar("reverseff_bot", "1", "0=Do not ReverseFF if victim is bot, 1=ReverseFF if victim is bot", CVAR_FLAGS);
	cvar_reverseff_incapped = CreateConVar("reverseff_incapped", "0", "0=Do not ReverseFF if victim is incapped, 1=ReverseFF if victim is incapped", CVAR_FLAGS);
	cvar_reverseff_attackerincapped = CreateConVar("reverseff_attackerincapped", "0", "0=Do not ReverseFF if attacker is incapped, 1=ReverseFF if attacker is incapped", CVAR_FLAGS);
	cvar_reverseff_self = CreateConVar("reverseff_self", "0", "0=Treat ReverseFF as reversed accusations, 1=Treat ReverseFF as self damage", CVAR_FLAGS);
	cvar_reverseff_multiplier = CreateConVar("reverseff_multiplier", "1.125", "Special ammo damage multiplier (default=12.5%)", CVAR_FLAGS);
	cvar_reverseff_survivormaxdmg = CreateConVar("reverseff_survivormaxdmg", "0", "Maximum damage allowed before kick/ban survivor, 0=no action", CVAR_FLAGS);
	cvar_reverseff_infectedmaxdmg = CreateConVar("reverseff_infectedmaxdmg", "50", "Maximum damage allowed before kick/ban infected", CVAR_FLAGS);
	cvar_reverseff_tankmaxdmg = CreateConVar("reverseff_tankmaxdmg", "300", "Maximum damage allowed before kick/ban tank", CVAR_FLAGS);
	cvar_reverseff_banduration = CreateConVar("reverseff_banduration", "10", "Ban duration in minutes (0=permanent, -1=kick)", CVAR_FLAGS);
	cvar_reverseff_mountedgun = CreateConVar("reverseff_mountedgun", "1", "0=Do not ReverseFF from mountedgun, 1=ReverseFF from mountedgun", CVAR_FLAGS);
	cvar_reverseff_melee = CreateConVar("reverseff_melee", "1", "0=Do not ReverseFF from melee, 1=ReverseFF from melee", CVAR_FLAGS);
	cvar_reverseff_chainsaw = CreateConVar("reverseff_chainsaw", "1", "0=Do not ReverseFF from chainsaw, 1=ReverseFF from chainsaw", CVAR_FLAGS);
	cvar_reverseff_pullcarry = CreateConVar("reverseff_pullcarry", "0", "0=Do not ReverseFF during Smoker pull or Charger carry, 1=ReverseFF from pull/carry", CVAR_FLAGS);
	g_hCvarAllow = CreateConVar("reverseff_enabled", "1", "0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModesOn = CreateConVar("reverseff_modes_on", "", "Game mode names on, comma separated, no spaces. (Empty=all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar("reverseff_modes_off", "", "Game mode names off, comma separated, no spaces. (Empty=none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar("reverseff_modes_tog", "0", "Game type bitflags on, add #s together. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge", CVAR_FLAGS );
	AutoExecConfig(true, "l4d2_reverse_ff");
	
	cvar_reverseff_admin.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_multiplier.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_bot.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_survivormaxdmg.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_infectedmaxdmg.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_tankmaxdmg.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_banduration.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_incapped.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_attackerincapped.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_self.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_mountedgun.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_melee.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_chainsaw.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_pullcarry.AddChangeHook(action_ConVarChanged);
	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOn.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	
	HookEvent("choke_stopped", Event_StartGrace);
	HookEvent("tongue_release", Event_StartGrace);
	HookEvent("pounce_stopped", Event_StartGrace);
	HookEvent("tongue_grab", Event_PullCarry);
	if (g_bL4D2)
	{
		HookEvent("jockey_ride_end", Event_StartGrace);
		HookEvent("charger_pummel_end", Event_StartGrace);
		HookEvent("charger_carry_start", Event_PullCarry);
	}
	
	if (g_bLateLoad)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
				OnClientPutInServer(client);
		}
	}
}

public void LoadPluginTranslations()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/%s.txt", TRANSLATION_FILENAME);
    if (FileExists(path))
    {
    	LoadTranslations(TRANSLATION_FILENAME);
    }
    else
    {
    	if (g_bL4D2)
    	{
    		SetFailState("Missing required translation file \"<left4dead2>\\%s\", please download.", path, TRANSLATION_FILENAME);
    	}
    	else
    	{
    		SetFailState("Missing required translation file \"<left4dead>\\%s\", please download.", path, TRANSLATION_FILENAME);
    	}
    }
        
}

public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public int action_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bCvarReverseIfAdmin = cvar_reverseff_admin.BoolValue;
	g_fCvarDamageMultiplier = cvar_reverseff_multiplier.FloatValue;
	g_bCvarReverseIfBot = cvar_reverseff_bot.BoolValue;
	g_fSurvivorMaxDamage = cvar_reverseff_survivormaxdmg.FloatValue;
	g_fInfectedMaxDamage = cvar_reverseff_infectedmaxdmg.FloatValue;
	g_fTankMaxDamage = cvar_reverseff_tankmaxdmg.FloatValue;
	g_iBanDuration = cvar_reverseff_banduration.IntValue;
	g_bCvarReverseIfIncapped = cvar_reverseff_incapped.BoolValue;
	g_bCvarReverseIfAttackerIncapped = cvar_reverseff_attackerincapped.BoolValue;
	g_bCvarSelfDamage = cvar_reverseff_self.BoolValue;
	g_bCvarReverseIfMountedgun = cvar_reverseff_mountedgun.BoolValue;
	g_bCvarReverseIfMelee = cvar_reverseff_melee.BoolValue;
	g_bCvarReverseIfChainsaw = cvar_reverseff_chainsaw.BoolValue;
	g_bCvarReverseIfPullCarry = cvar_reverseff_pullcarry.BoolValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 && iCvarModesTog != 15 )
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

	g_hCvarModesOn.GetString(sGameModes, sizeof(sGameModes));
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

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	g_bGrace[client] = false;
	g_fAccumDamage[client] = 0.0;
	g_fAccumDamageAsTank[client] = 0.0;
	g_fAccumDamageAsInfected[client] = 0.0;
}

public void OnClientPostAdminCheck(int client)
{
	CreateTimer(16.0, AnnouncePlugin, client);
}

public void OnClientDisconnect(int client)
{
	g_bGrace[client] = false;
	g_fAccumDamage[client] = 0.0;
	g_fAccumDamageAsTank[client] = 0.0;
	g_fAccumDamageAsInfected[client] = 0.0;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	//debug plugin enabled flag
	//PrintToServer("g_bCvarAllow: %b", g_bCvarAllow);
	if (!g_bCvarAllow)
	{
		return Plugin_Continue;
	}
	//debug damage
	//PrintToServer("Vic: %i, Atk: %i, Inf: %i, Dam: %f, DamTyp: %i, Wpn: %i", victim, attacker, inflictor, damage, damagetype, weapon);
	//attacker and victim survivor checks
	if (IsValidClientAndInGameAndSurvivor(attacker) && IsValidClientAndInGameAndSurvivor(victim) && victim != attacker)
	{
		char sInflictorClass[64];
		if (inflictor > MaxClients)
		{
			GetEdictClassname(inflictor, sInflictorClass, sizeof(sInflictorClass));
		}
		//is weapon grenade launcher
		bool bWeaponGL = IsWeaponGrenadeLauncher(sInflictorClass);
		//is weapon minigun
		bool bWeaponMG = IsWeaponMinigun(sInflictorClass);
		bool ReverseIfMountedgun = false;
		if (bWeaponMG && !g_bCvarReverseIfMountedgun)
		{
			ReverseIfMountedgun = true;
		}
		bool bWeaponMelee = IsWeaponMelee(sInflictorClass);
		bool ReverseIfMelee = false;
		if (bWeaponMelee && !g_bCvarReverseIfMelee)
		{
			ReverseIfMelee = true;
		}
		bool bWeaponChainsaw = IsWeaponChainsaw(sInflictorClass);
		bool ReverseIfChainsaw = false;
		if (bWeaponChainsaw && !g_bCvarReverseIfChainsaw)
		{
			ReverseIfChainsaw = true;
		}
		//debug weapon
		// PrintToServer("GL: %b, MG: %b, InfCls: %s, weapon: %i", bWeaponGL, bWeaponMG, sInflictorClass, weapon);
		//if weapon caused damage
		if (weapon > 0 || bWeaponGL || bWeaponMG)
		{
			//check reverse friendly-fire parameters for: attacker=admin, victim=bot, victim=incapped, attacker=incapped, damage from mountedgun, melee, or chainsaw
			//regardless of the above settings, do not reverse friendly-fire during grace period after victim freed from SI
			if (!(ReverseIfAttackerAdmin(attacker) || ReverseIfVictimBot(victim) || ReverseIfVictimIncapped(victim) || ReverseIfAttackerIncapped(attacker) || ReverseIfMountedgun || ReverseIfMelee || ReverseIfChainsaw) && (!g_bGrace[victim]))
			{
				//special ammo checks
				if (IsSpecialAmmo(weapon, attacker, inflictor, damagetype, bWeaponGL))
				{
					//damage * "reverseff_multiplier"
					damage *= g_fCvarDamageMultiplier;
				}
				//accumulate damage total for attacker
				g_fAccumDamage[attacker] += damage;
				//debug acculated damage
				//PrintToServer("Survivor Atk: %N, Dmg: %f, AcmDmg: %f, SurvMaxDmg: %f", attacker, damage, g_fAccumDamage[attacker], g_fSurvivorMaxDamage);
				//does accumulated damage exceed "reverseff_survivormaxdamage"
				if (g_fSurvivorMaxDamage > 0 && (g_fAccumDamage[attacker] > g_fSurvivorMaxDamage) && !IsFakeClient(attacker))
				{
					if (g_iBanDuration == -1)
					{
						//kick attacker
						KickClient(attacker, "%t", "ExcessiveFF");
					}
					else
					{
						//ban attacker for "reverseff_banduration"
						char BanMsg[50];
						Format(BanMsg, sizeof(BanMsg), "%t", "ExcessiveFF", attacker);
						BanClient(attacker, g_iBanDuration, BANFLAG_AUTO, "ExcessiveFF", BanMsg, _, attacker);
					}
					//reset accumulated damage
					g_fAccumDamage[attacker] = 0.0;
					g_fAccumDamageAsTank[attacker] = 0.0;
					g_fAccumDamageAsInfected[attacker] = 0.0;
					//do not inflict damage since player was kicked/banned
					return Plugin_Handled;
				}
				//check whether to treat FF as self-damage
				int vicatk = victim;
				if (g_bCvarSelfDamage)
				{
					vicatk = attacker;
				}

				///////////////////////////////////////////////////////////////////////////////////////////////////////////////
				// pan0s | 2021-04-20 | Fixed: Server crashes if reversing chainsaw damage makes the attacker incapacitated or dead.
				// No bug will incur normally.
				bool bIsFixed = true;
				char sWeaponName[32];
				// Get the weapon name.
				GetEdictClassname(weapon, sWeaponName, 32);
				if(StrEqual(sWeaponName, "weapon_chainsaw"))
				{
					// Create a data pick for storage data to use the function SDKHooks_TakeDamage.
					Handle dataPack = CreateDataPack();
					WritePackCell(dataPack, attacker);
					WritePackCell(dataPack, inflictor);
					WritePackCell(dataPack, vicatk);
					WritePackFloat(dataPack, damage);
					WritePackCell(dataPack, damagetype);
					WritePackCell(dataPack, weapon);
					for(int i=0; i<3; i++){
						WritePackFloat(dataPack, damageForce[i]);
					}
					for(int i=0; i<3; i++){
						WritePackFloat(dataPack, damagePosition[i]);
					}
					// Add a timer can fix the bug. Do ask me why, the soluation is just found by test cases.
					CreateTimer(0.01, HandleTakeDamageTimer, dataPack);
					bIsFixed = false;
				}
				if(bIsFixed)
				{
					//inflict damage to attacker
					SDKHooks_TakeDamage(attacker, inflictor, vicatk, damage, damagetype, weapon, damageForce, damagePosition);
				}
				/////////////////////////////////////////////////////////////////////////////////////////////

				if (damage > 0 && !IsFakeClient(attacker))
				{
					if (!g_bToggle[attacker])
					{
						PrintToServer("%N %T %N", attacker, "Attacked", LANG_SERVER, victim);
						CPrintToChat(attacker, "{orange}[ReverseFF]{lightgreen} %t {olive}%N{lightgreen}, %t.", "YouAttacked", victim, "SurvivorFF");
						g_bToggle[attacker] = true;
						CreateTimer(0.15, FlipToggle, attacker);
					}
				}
			}
			//no damage for victim
			return Plugin_Handled;
		}
	}
	else
	{
		//attacker and victim infected checks
		if (IsValidClientAndInGameAndInfected(attacker) && IsValidClientAndInGameAndInfected(victim) && victim != attacker)
		{
			//check reverse friendly-fire parameters for: attacker=admin, victim=bot
			if (!(ReverseIfAttackerAdmin(attacker) || ReverseIfVictimBot(victim)))
			{
				//accumulate damage total for infected/tank attacker
				if (IsTank(attacker))
				{
					g_fAccumDamageAsTank[attacker] += damage;
				}
				else
				{
					g_fAccumDamageAsInfected[attacker] += damage;
				}
				//debug acculated damage
				//PrintToServer("Infected Atk: %N, Dmg: %f, AcmDmgTank: %f, TankMaxDmg %f, AcmDmgInf: %f, InfMaxDmg: %f", attacker, damage, g_fAccumDamageAsTank[attacker], g_fTankMaxDamage, g_fAccumDamageAsInfected[attacker], g_fInfectedMaxDamage);
				//does accumulated damage exceed "reverseff_tankmaxdamage" or "reverseff_infectedmaxdamage"
				if (((IsTank(attacker) && g_fAccumDamageAsTank[attacker] > g_fTankMaxDamage) || (!IsTank(attacker) && g_fAccumDamageAsInfected[attacker] > g_fInfectedMaxDamage)) && !IsFakeClient(attacker))
				{
					if (g_iBanDuration == -1)
					{
						//kick attacker
						KickClient(attacker, "%t", "ExcessiveTA");
					}
					else
					{
						//ban attacker for "reverseff_banduration"
						char BanMsg[50];
						Format(BanMsg, sizeof(BanMsg), "%t", "ExcessiveTA", attacker);
						BanClient(attacker, g_iBanDuration, BANFLAG_AUTO, "ExcessiveTA", BanMsg, _, attacker);
					}
					//reset accumulated damage
					g_fAccumDamage[attacker] = 0.0;
					g_fAccumDamageAsTank[attacker] = 0.0;
					g_fAccumDamageAsInfected[attacker] = 0.0;
					//do not inflict damage since player was kicked/banned
					return Plugin_Handled;
				}
				//inflict damage to attacker
				SDKHooks_TakeDamage(attacker, inflictor, victim, damage, damagetype, weapon, damageForce, damagePosition);
				PrintToServer("%N %T %N", attacker, "Attacked", LANG_SERVER, victim);
				CPrintToChat(attacker, "{orange}[ReverseFF]{lightgreen} %t {olive}%N{lightgreen}, %t.", "YouAttacked", victim, "InfectedFF");
			}
			//no damage for victim
			return Plugin_Handled;
		}
	}
	//all other damage behaves normal
	return Plugin_Continue;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// pan0s | 2021-04-20 | Fixed: Server crashes if reversing chainsaw damage makes the attacker incapacitated or dead.
public Action HandleTakeDamageTimer(Handle timer, Handle dataPack)
{
	// Read the data pack.
	ResetPack(dataPack);
	int attacker = ReadPackCell(dataPack);
	int inflictor = ReadPackCell(dataPack);
	int vicatk = ReadPackCell(dataPack);
	float damage = ReadPackFloat(dataPack);
	int damagetype = ReadPackCell(dataPack);
	int weapon = ReadPackCell(dataPack);
	float damageForce[3];
	float damagePosition[3];
	for(int i=0; i<3; i++) damageForce[i] = ReadPackFloat(dataPack);
	for(int i=0; i<3; i++) damagePosition[i] = ReadPackFloat(dataPack);
	SDKHooks_TakeDamage(attacker, inflictor, vicatk, damage, damagetype, weapon, damageForce, damagePosition);
	// Dispose the datapack.
	CloseHandle(dataPack);
}
/////////////////////////////////////////////////////////////////////////////////////////////

stock bool IsWeaponGrenadeLauncher(char[] sInflictorClass)
{
	return (StrEqual(sInflictorClass, "grenade_launcher_projectile"));
}

stock bool IsWeaponMinigun(char[] sInflictorClass)
{
	return (StrEqual(sInflictorClass, "prop_minigun") || StrEqual(sInflictorClass, "prop_minigun_l4d1") || StrEqual(sInflictorClass, "prop_mounted_machine_gun"));
}

stock bool IsWeaponMelee(char[] sInflictorClass)
{
	return (StrEqual(sInflictorClass, "weapon_melee"));
}

stock bool IsWeaponChainsaw(char[] sInflictorClass)
{
	return (StrEqual(sInflictorClass, "weapon_chainsaw"));
}

stock bool IsSpecialAmmo(int weapon, int attacker, int inflictor, int damagetype, bool bWeaponGL)
{
	//damage from gun with special ammo
	if ((weapon > 0 && attacker == inflictor) && (damagetype & DMG_BURN || damagetype & DMG_BLAST))
	{
		return true;
	}
	//damage from grenade launcher with incendiary ammo
	if ((bWeaponGL) && (damagetype & DMG_BURN))
	{
		return true;
	}
	//damage from melee weapon or weapon with regular ammo
	return false;
}

stock bool IsClientAdmin(int client)
{
    return CheckCommandAccess(client, "generic_admin", ADMFLAG_GENERIC, false);
}

stock bool IsValidClientAndInGameAndSurvivor(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

stock bool IsValidClientAndInGameAndInfected(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3);
}

stock bool IsClientIncapped(int client)
{
	//convert integer to boolean for return value
	return !!GetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
}

public Action AnnouncePlugin(Handle timer, int client)
{
	if (IsClientInGame(client) && g_bCvarAllow)
	{
		if (g_bAllReversePlugins)
		{
			CPrintToChat(client, "%T", "AnnounceAll", client);
		}
		else
		{
			CPrintToChat(client, "%T", "Announce", client);
		}
	}
}

public Action Event_StartGrace (Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (client > 0)
	{
		if (g_bGrace[client])
		{
			if (g_hEndGrace[client] != INVALID_HANDLE)
			{
				KillTimer(g_hEndGrace[client]);
				g_hEndGrace[client] = INVALID_HANDLE;
			}
		}
		else
		{
			g_bGrace[client] = true;
		}
		g_hEndGrace[client] = CreateTimer(2.0, EndGrace, client);
	}
}

public Action EndGrace (Handle timer, int client)
{
		g_bGrace[client] = false;
		g_hEndGrace[client] = INVALID_HANDLE;
}

public Action Event_PullCarry (Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (!g_bCvarReverseIfPullCarry)
	{
		g_bGrace[client] = true;
	}
}

public Action FlipToggle(Handle timer, int attacker)
{
  g_bToggle[attacker] = false;
}

stock bool IsTank(int client)
{
	char sNetClass[32];
	GetEntityNetClass(client, sNetClass, sizeof(sNetClass));
	return (StrEqual(sNetClass, "Tank", false));
}

stock bool ReverseIfAttackerAdmin(int attacker)
{
	return (IsClientAdmin(attacker) && !g_bCvarReverseIfAdmin);
}

stock bool ReverseIfVictimBot (int victim)
{
	return (IsFakeClient(victim) && !g_bCvarReverseIfBot);
}

stock bool ReverseIfVictimIncapped (int victim)
{
	return (IsClientIncapped(victim) && !g_bCvarReverseIfIncapped);
}

stock bool ReverseIfAttackerIncapped (int attacker)
{
	return (IsClientIncapped(attacker) && !g_bCvarReverseIfAttackerIncapped);
}

public void CPrintToChat(int client, char[] message, any ...)
{
    static char buffer[512];
    VFormat(buffer, sizeof(buffer), message, 3);

    ReplaceString(buffer, sizeof(buffer), "{white}", "\x01");
    ReplaceString(buffer, sizeof(buffer), "{lightgreen}", "\x03");
    ReplaceString(buffer, sizeof(buffer), "{orange}", "\x04");
    ReplaceString(buffer, sizeof(buffer), "{olive}", "\x05");

    PrintToChat(client, buffer);
}