/*

Reverse Friendly-Fire (l4d_reverse_ff) by Mystik Spiral
  
Reverses friendly-fire in Left4Dead(2).
Attacker takes damage, victim does not.

GitHub: https://github.com/Mystik-Spiral/l4d_reverse_ff
AlliedModders: https://forums.alliedmods.net/showthread.php?t=329035

*/

// ====================================================================================================
// Defines for Plugin Info
// ====================================================================================================
#define PLUGIN_NAME               "[L4D & L4D2] Reverse Friendly-Fire"
#define PLUGIN_AUTHOR             "Mystik Spiral"
#define PLUGIN_DESCRIPTION        "Reverses friendly-fire... attacker takes damage, victim does not."
#define PLUGIN_VERSION            "2.9.2"
#define PLUGIN_URL                "https://forums.alliedmods.net/showthread.php?t=329035"

// ====================================================================================================
// Plugin Info
// ====================================================================================================
public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

// ====================================================================================================
// Additional Defines
// ====================================================================================================
#define TRANSLATION_FILENAME      "l4d_reverse_ff.phrases"
#define CVAR_FLAGS                FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

// ====================================================================================================
// Includes
// ====================================================================================================
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// ====================================================================================================
// Pragmas
// ====================================================================================================
#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Global Variables
// ====================================================================================================
ConVar cvar_reverseff_admin;
ConVar cvar_reverseff_multiplier;
ConVar cvar_reverseff_dmgmodifier;
ConVar cvar_reverseff_botdmgmodifier;
ConVar cvar_reverseff_humandmgmodifier;
ConVar cvar_reverseff_dmgmodinfected;
ConVar cvar_reverseff_bot;
ConVar cvar_reverseff_survivormaxdmg;
ConVar cvar_reverseff_infectedmaxdmg;
ConVar cvar_reverseff_tankmaxdmg;
ConVar cvar_reverseff_cooldowntime;
ConVar cvar_reverseff_banduration;
ConVar cvar_reverseff_proximity;
ConVar cvar_reverseff_incapped;
ConVar cvar_reverseff_attackerincapped;
ConVar cvar_reverseff_mountedgun;
ConVar cvar_reverseff_melee;
ConVar cvar_reverseff_chainsaw;
ConVar cvar_reverseff_pullcarry;
ConVar cvar_reverseff_announce;
ConVar cvar_reverseff_chatmsg;
ConVar cvar_reverseff_glstumble;
ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModesOn, g_hCvarModesOff, g_hCvarModesTog;

float g_fCvarDamageMultiplier;
float g_fCvarDamageModifier;
float g_fCvarBotDmgModifier;
float g_fCvarHumanDmgModifier;
float g_fCvarDamageModifierInfected;
float g_fAccumDamage[MAXPLAYERS + 1];
float g_fAccumDamageAsTank[MAXPLAYERS + 1];
float g_fAccumDamageAsInfected[MAXPLAYERS + 1];
float g_fLastShotTime[MAXPLAYERS + 1];
float g_fCooldownTime;
float g_fProximity;
float g_fSurvivorMaxDamage;
float g_fInfectedMaxDamage;
float g_fTankMaxDamage;
float g_fDmgFrc[3] = {0.0, 0.0, 0.0};
float g_fDmgPos[3] = {0.0, 0.0, 0.0};

int g_iBanDuration;

bool g_bCvarReverseIfAdmin;
bool g_bCvarReverseIfBot;
bool g_bCvarReverseIfIncapped;
bool g_bCvarReverseIfAttackerIncapped;
bool g_bCvarReverseIfPullCarry;
bool g_bCvarReverseIfMountedgun;
bool g_bCvarReverseIfMelee;
bool g_bCvarReverseIfChainsaw;
bool g_bCvarAnnounce;
bool g_bCvarChatMsg;
bool g_bCvarGLstumble;
bool g_bGrace[MAXPLAYERS + 1];
bool g_bToggle[MAXPLAYERS + 1];
bool g_bCooldownFlag[MAXPLAYERS + 1];
bool g_bCvarAllow, g_bMapStarted;
bool g_bL4D2;
bool g_bAllReversePlugins;
bool g_bLateLoad;

Handle g_hEndGrace[MAXPLAYERS + 1];

// ====================================================================================================
// Verify game engine
// ====================================================================================================
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

// ====================================================================================================
// Functions
// ====================================================================================================
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
	
	CreateConVar("reverseff_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
	cvar_reverseff_admin = CreateConVar("reverseff_admin", "0", "0=Do not ReverseFF if attacker is admin, 1=ReverseFF if attacker is admin", CVAR_FLAGS);
	cvar_reverseff_bot = CreateConVar("reverseff_bot", "0", "0=Do not ReverseFF if victim is bot, 1=ReverseFF if victim is bot", CVAR_FLAGS);
	cvar_reverseff_incapped = CreateConVar("reverseff_incapped", "0", "0=Do not ReverseFF if victim is incapped, 1=ReverseFF if victim is incapped", CVAR_FLAGS);
	cvar_reverseff_attackerincapped = CreateConVar("reverseff_attackerincapped", "0", "0=Do not ReverseFF if attacker is incapped, 1=ReverseFF if attacker is incapped", CVAR_FLAGS);
	cvar_reverseff_multiplier = CreateConVar("reverseff_multiplier", "1.125", "Special ammo damage multiplier (default=12.5%)", CVAR_FLAGS);
	cvar_reverseff_dmgmodifier = CreateConVar("reverseff_dmgmodifier", "1.0", "0.0=no dmg, 1.0=dmg unmodified, 2.0=double dmg\n0.01=1% real dmg, 0.1=10% real dmg, 0.5=50% real dmg\n1.01=1% more dmg, 1.1=10% more dmg, 1.5=50% more dmg", CVAR_FLAGS);
	cvar_reverseff_botdmgmodifier = CreateConVar("reverseff_botdmgmodifier", "0.0", "Damage bot victim:\n0.0=no dmg, 1.0=dmg unmodified, 2.0=double dmg\n0.01=1% real dmg, 0.1=10% real dmg, 0.5=50% real dmg\n1.01=1% more dmg, 1.1=10% more dmg, 1.5=50% more dmg", CVAR_FLAGS);
	cvar_reverseff_humandmgmodifier = CreateConVar("reverseff_humandmgmodifier", "0.0", "Damage human victim:\n0.0=no dmg, 1.0=dmg unmodified, 2.0=double dmg\n0.01=1% real dmg, 0.1=10% real dmg, 0.5=50% real dmg\n1.01=1% more dmg, 1.1=10% more dmg, 1.5=50% more dmg", CVAR_FLAGS);
	cvar_reverseff_dmgmodinfected = CreateConVar("reverseff_dmgmodinfected", "1.0", "0.0=no dmg, 1.0=dmg unmodified, 2.0=double dmg\n0.01=1% real dmg, 0.1=10% real dmg, 0.5=50% real dmg\n1.01=1% more dmg, 1.1=10% more dmg, 1.5=50% more dmg", CVAR_FLAGS);
	cvar_reverseff_survivormaxdmg = CreateConVar("reverseff_survivormaxdmg", "200", "Maximum damage allowed before kick/ban survivor (0=disable)", CVAR_FLAGS);
	cvar_reverseff_infectedmaxdmg = CreateConVar("reverseff_infectedmaxdmg", "50", "Maximum damage allowed before kick/ban infected (0=disable)", CVAR_FLAGS);
	cvar_reverseff_tankmaxdmg = CreateConVar("reverseff_tankmaxdmg", "300", "Maximum damage allowed before kick/ban tank (0=disable)", CVAR_FLAGS);
	cvar_reverseff_cooldowntime = CreateConVar("reverseff_cooldowntime", "0", "Cool down time in seconds (0=disable)", CVAR_FLAGS);
	cvar_reverseff_banduration = CreateConVar("reverseff_banduration", "10", "Ban duration in minutes (0=permanent ban, -1=kick instead of ban)", CVAR_FLAGS);
	cvar_reverseff_proximity = CreateConVar("reverseff_proximity", "32", "Attacker/victim distance to prevent ReverseFF (0=disable)", CVAR_FLAGS);
	cvar_reverseff_mountedgun = CreateConVar("reverseff_mountedgun", "1", "0=Do not ReverseFF from mountedgun, 1=ReverseFF from mountedgun", CVAR_FLAGS);
	cvar_reverseff_melee = CreateConVar("reverseff_melee", "1", "0=Do not ReverseFF from melee, 1=ReverseFF from melee", CVAR_FLAGS);
	cvar_reverseff_chainsaw = CreateConVar("reverseff_chainsaw", "1", "0=Do not ReverseFF from chainsaw, 1=ReverseFF from chainsaw", CVAR_FLAGS);
	cvar_reverseff_pullcarry = CreateConVar("reverseff_pullcarry", "0", "0=Do not ReverseFF during Smoker pull or Charger carry, 1=ReverseFF from pull/carry", CVAR_FLAGS);
	cvar_reverseff_announce = CreateConVar("reverseff_announce", "1", "0=Do not announce plugin, 1=Announce plugin", CVAR_FLAGS);
	cvar_reverseff_chatmsg = CreateConVar("reverseff_chatmsg", "1", "0=Do not display ReverseFF chat messages, 1=Display ReverseFFchat messages", CVAR_FLAGS);
	cvar_reverseff_glstumble = CreateConVar("reverseff_glstumble", "0", "0=Do not reverse stumble effect from GrenadeLauncher, 1=Reverse stumble effect from GrenadeLauncher", CVAR_FLAGS);
	g_hCvarAllow = CreateConVar("reverseff_enabled", "1", "0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModesOn = CreateConVar("reverseff_modes_on", "", "Game mode names on, comma separated, no spaces. (Empty=all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar("reverseff_modes_off", "", "Game mode names off, comma separated, no spaces. (Empty=none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar("reverseff_modes_tog", "0", "Game type bitflags on, add #s together. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge", CVAR_FLAGS );
	AutoExecConfig(true, "l4d2_reverse_ff");
	
	cvar_reverseff_admin.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_multiplier.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_dmgmodifier.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_botdmgmodifier.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_humandmgmodifier.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_dmgmodinfected.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_bot.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_survivormaxdmg.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_infectedmaxdmg.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_tankmaxdmg.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_cooldowntime.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_banduration.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_proximity.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_incapped.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_attackerincapped.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_mountedgun.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_melee.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_chainsaw.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_pullcarry.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_announce.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_chatmsg.AddChangeHook(action_ConVarChanged);
	cvar_reverseff_glstumble.AddChangeHook(action_ConVarChanged);
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
	HookEvent("lunge_pounce", Event_PounceRide);
	if (g_bL4D2)
	{
		HookEvent("jockey_ride_end", Event_StartGrace);
		HookEvent("charger_pummel_end", Event_StartGrace);
		HookEvent("charger_carry_start", Event_PullCarry);
		HookEvent("jockey_ride", Event_PounceRide);
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

public void action_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bCvarReverseIfAdmin = cvar_reverseff_admin.BoolValue;
	g_fCvarDamageMultiplier = cvar_reverseff_multiplier.FloatValue;
	g_fCvarDamageModifier = cvar_reverseff_dmgmodifier.FloatValue;
	g_fCvarBotDmgModifier = cvar_reverseff_botdmgmodifier.FloatValue;
	g_fCvarHumanDmgModifier = cvar_reverseff_humandmgmodifier.FloatValue;
	g_fCvarDamageModifierInfected = cvar_reverseff_dmgmodinfected.FloatValue;
	g_bCvarReverseIfBot = cvar_reverseff_bot.BoolValue;
	g_fSurvivorMaxDamage = cvar_reverseff_survivormaxdmg.FloatValue;
	g_fInfectedMaxDamage = cvar_reverseff_infectedmaxdmg.FloatValue;
	g_fTankMaxDamage = cvar_reverseff_tankmaxdmg.FloatValue;
	g_fCooldownTime = cvar_reverseff_cooldowntime.FloatValue;
	g_iBanDuration = cvar_reverseff_banduration.IntValue;
	g_fProximity = cvar_reverseff_proximity.FloatValue;
	g_bCvarReverseIfIncapped = cvar_reverseff_incapped.BoolValue;
	g_bCvarReverseIfAttackerIncapped = cvar_reverseff_attackerincapped.BoolValue;
	g_bCvarReverseIfMountedgun = cvar_reverseff_mountedgun.BoolValue;
	g_bCvarReverseIfMelee = cvar_reverseff_melee.BoolValue;
	g_bCvarReverseIfChainsaw = cvar_reverseff_chainsaw.BoolValue;
	g_bCvarReverseIfPullCarry = cvar_reverseff_pullcarry.BoolValue;
	g_bCvarAnnounce = cvar_reverseff_announce.BoolValue;
	g_bCvarChatMsg = cvar_reverseff_chatmsg.BoolValue;
	g_bCvarGLstumble = cvar_reverseff_glstumble.BoolValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if ( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
	}

	else if ( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if ( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if ( iCvarModesTog != 0 && iCvarModesTog != 15 )
	{
		if ( g_bMapStarted == false )
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if ( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if ( IsValidEntity(entity) ) //Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); //Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if ( g_iCurrentMode == 0 )
			return false;

		if ( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModesOn.GetString(sGameModes, sizeof(sGameModes));
	if ( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if ( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if ( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if ( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if ( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if ( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if ( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if ( strcmp(output, "OnScavenge") == 0 )
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
	if (g_bCvarAnnounce)
	{
		CreateTimer(16.0, AnnouncePlugin, client);
	}
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

	//workaround to get weapon index to behave the same in L4D1 as it does in L4D2
	if(!g_bL4D2 && 0 < attacker <= MaxClients && IsClientInGame(attacker) && inflictor > 0 && IsValidEntity(inflictor))
	{
		if(attacker == inflictor && HasEntProp(attacker, Prop_Send, "m_hActiveWeapon"))
		{
			weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		}
	}
	
	//debug damage
	//PrintToServer("Vic: %i, Atk: %i, Inf: %i, Dam: %f, DamTyp: %i, Wpn: %i", victim, attacker, inflictor, damage, damagetype, weapon);

	//get classname of weapon
    static char sInflictorClass[32];
	if (inflictor > MaxClients && IsValidEntity(inflictor))
	{
		GetEntityClassname(inflictor, sInflictorClass, sizeof(sInflictorClass));
	}
	//set reverseff options for grenade launcher, mounted gun, melee, and chainsaw
	//is weapon grenade launcher
	bool bWeaponGL = IsWeaponGrenadeLauncher(sInflictorClass);
	//is weapon mounted gun
	bool bWeaponMG = IsWeaponMinigun(sInflictorClass);
	//should reverse mounted gun
	bool ReverseIfMountedgun = false;
	if (bWeaponMG && !g_bCvarReverseIfMountedgun)
	{
		ReverseIfMountedgun = true;
	}
	//is weapon melee
	bool bWeaponMelee = IsWeaponMelee(sInflictorClass);
	//should reverse melee
	bool ReverseIfMelee = false;
	if (bWeaponMelee && !g_bCvarReverseIfMelee)
	{
		ReverseIfMelee = true;
	}
	//is weapon chainsaw
	bool bWeaponChainsaw = IsWeaponChainsaw(sInflictorClass);
	//should reverse chainsaw
	bool ReverseIfChainsaw = false;
	if (bWeaponChainsaw && !g_bCvarReverseIfChainsaw)
	{
		ReverseIfChainsaw = true;
	}

	//debug weapon
	//PrintToServer("GL: %b, MG: %b, InfCls: %s, weapon: %i", bWeaponGL, bWeaponMG, sInflictorClass, weapon);
	
	//attacker and victim survivor checks
	if (IsValidClientAndInGameAndSurvivor(attacker) && IsValidClientAndInGameAndSurvivor(victim) && victim != attacker)
	{
		if (IsFakeClient(attacker))
		{
			//treat friendly-fire from bot attacker normally, which is 0 damage anyway
			return Plugin_Continue;
		}
		//determine damage for bot victim
		float fBotDamage = 0.0;
		//check if attacker is a non-bot survivor and victim is a bot survivor that will be damaged
		if (IsFakeClient(victim) && !IsFakeClient(attacker) && 0.0 < g_fCvarBotDmgModifier <= 2.0)
		{
			//apply reverseff_botdmgmodifier damage modifier
			fBotDamage = damage * g_fCvarBotDmgModifier;
			//if we are modifying damage ensure damage is at least 1
			if (g_fCvarBotDmgModifier != 1.0 && 0.0 < fBotDamage < 1.0)
			{
				fBotDamage = 1.0;
			}
			//inflict bot victim damage
			if (fBotDamage >= 1.0)
			{
				SDKHooks_TakeDamage(victim, inflictor, attacker, fBotDamage, damagetype, weapon, damageForce, damagePosition);
			}
		}
		//determine damage for human victim
		float fHumanDamage = 0.0;
		//check if attacker is a non-bot survivor and victim is a non-bot survivor that will be damaged
		if (!IsFakeClient(victim) && !IsFakeClient(attacker) && 0.0 < g_fCvarHumanDmgModifier <= 2.0)
		{
			//apply reverseff_humandmgmodifier damage modifier
			fHumanDamage = damage * g_fCvarHumanDmgModifier;
			//if we are modifying damage ensure damage is at least 1
			if (g_fCvarHumanDmgModifier != 1.0 && 0.0 < fHumanDamage < 1.0)
			{
				fHumanDamage = 1.0;
			}
			//inflict human victim damage
			if (fHumanDamage >= 1.0)
			{
				SDKHooks_TakeDamage(victim, inflictor, attacker, fHumanDamage, damagetype, weapon, damageForce, damagePosition);
			}
		}
		//is cooldown feature enabled
		if (g_fCooldownTime > 0.0)
		{
			//debug cooldown parameters
			//PrintToServer("Time: %f, Last: %f, CDflag: %b, Atk: %i", GetGameTime(), g_fLastShotTime[attacker], g_bCooldownFlag[attacker], attacker);

			//cooldown flag is off
			if (!g_bCooldownFlag[attacker])
			{
				//update current damage time and set cooldown flag on
				g_fLastShotTime[attacker] = GetGameTime();
				g_bCooldownFlag[attacker] = true;
				CreateTimer(g_fCooldownTime, CooldownTimer, attacker);
			}
			//cooldown flag is on
			else
			{
				//shotgun pellets from same shot have same time
				if (GetGameTime() != g_fLastShotTime[attacker])
				{
					//do not process damage
					return Plugin_Handled;					
				}
			}
		}

		//debug victim/attacker distance
		//PrintToServer("Distance between victim and attacker: %f", GetClientDist(victim, attacker));
		
		//if weapon not melee or chainsaw
		if (!bWeaponMelee && !bWeaponChainsaw)
		{
			//ignore ff based on reverseff_proximity
			//if reverseff_proximity > 0 ignore ff if distance < reverseff_proximity
			//if reverseff_proximity < 0 ignore ff if distance > abs(reverseff_proximity)
			float fDistance = GetClientDist(victim, attacker);
			if ( (g_fProximity > 0 && fDistance < g_fProximity) || (g_fProximity < 0 && fDistance > FloatAbs(g_fProximity)) )
			{
				return Plugin_Handled;
			}
		}
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
					//damage * reverseff_multiplier
					damage *= g_fCvarDamageMultiplier;
				}
				//reverseff_dmgmodifier min=0 (no reverse damage) max=2 (double reverse damage)
				if (g_fCvarDamageModifier < 0.0)
				{
					g_fCvarDamageModifier = 0.0;
				}
				if (g_fCvarDamageModifier > 2.0)
				{
					g_fCvarDamageModifier = 2.0;
				}
				//apply reverseff_dmgmodifer damage modifier
				damage *= g_fCvarDamageModifier;
				//if we are modifying reverse damage ensure damage is at least 1
				if (g_fCvarDamageModifier > 0.0 && g_fCvarDamageModifier != 1.0 && 0.0 < damage < 1.0)
				{
					damage = 1.0;
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
				//pan0s | 20-Apr-2021 | Fixed: Server crashes if reversing chainsaw damage makes the attacker incapacitated or dead.
				//pan0s | start chainsaw fix part 1
				if (bWeaponChainsaw)
				{
					//Create a DataPack to pass to ChainsawTakeDamageTimer.
					Handle dataPack = CreateDataPack();
					WritePackCell(dataPack, attacker);
					WritePackCell(dataPack, inflictor);
					WritePackCell(dataPack, victim);
					WritePackFloat(dataPack, damage);
					WritePackCell(dataPack, damagetype);
					WritePackCell(dataPack, weapon);
					for (int i=0; i<3; i++)
					{
						WritePackFloat(dataPack, damageForce[i]);
						WritePackFloat(dataPack, damagePosition[i]);
					}
					//adding a timer fixes the bug, reason unknown
					CreateTimer(0.01, ChainsawTakeDamageTimer, dataPack);
				}
				//pan0s | end chainsaw fix part 1
				else
				{
					//inflict (non-chainsaw) damage to attacker
					//if we did not previously damage victim...
					//add 1HP to victim then damage them for 1HP so the displayed message and vocalization order are correct,
					//then damage attacker as self-inflicted for actual damage so there is no vocalization, just pain grunt.
					if (fBotDamage < 1.0 && fHumanDamage < 1.0)
					{
						SetEntityHealth(victim, GetClientHealth(victim) + 1);
						SDKHooks_TakeDamage(victim, inflictor, attacker, 1.0, 0, weapon, g_fDmgFrc, g_fDmgPos);
					}
					//if using grenade launcher and reverseff_glstumble is false then ignore stumble effect, else reverse stumble effect
					if (bWeaponGL && !g_bCvarGLstumble)
					{
						SDKHooks_TakeDamage(attacker, inflictor, attacker, damage, 0, weapon, g_fDmgFrc, g_fDmgPos);
					}
					else
					{
						SDKHooks_TakeDamage(attacker, inflictor, attacker, damage, damagetype, weapon, damageForce, damagePosition);
					}
				}

				if (damage > 0 && !IsFakeClient(attacker) && g_bCvarChatMsg)
				{
					if (!g_bToggle[attacker])
					{
						//PrintToServer("%N %T %N", attacker, "Attacked", LANG_SERVER, victim);
						CPrintToChat(attacker, "{orange}[ReverseFF]{lightgreen} %T", "DmgReversed", attacker, victim);
						g_bToggle[attacker] = true;
						//CreateTimer(0.75, FlipToggle, attacker);
						CreateTimer(10.0, FlipToggle, attacker);
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
				//reverseff_dmgmodinfected min=0 (no reverse damage) max=2 (double reverse damage)
				if (g_fCvarDamageModifierInfected < 0.0)
				{
					g_fCvarDamageModifierInfected = 0.0;
				}
				if (g_fCvarDamageModifierInfected > 2.0)
				{
					g_fCvarDamageModifierInfected = 2.0;
				}
				//apply reverseff_dmgmodinfected damage modifier
				damage *= g_fCvarDamageModifierInfected;
				//if we are modifying reverse damage ensure damage is at least 1
				if (g_fCvarDamageModifierInfected > 0.0 && g_fCvarDamageModifierInfected != 1.0 && 0.0 < damage < 1.0)
				{
					damage = 1.0;
				}
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
				if (((g_fTankMaxDamage > 0 && IsTank(attacker) && g_fAccumDamageAsTank[attacker] > g_fTankMaxDamage) || (g_fInfectedMaxDamage > 0 && !IsTank(attacker) && g_fAccumDamageAsInfected[attacker] > g_fInfectedMaxDamage)) && !IsFakeClient(attacker))
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
				//PrintToServer("%N %T %N", attacker, "Attacked", LANG_SERVER, victim);
				if (g_bCvarChatMsg)
				{
					CPrintToChat(attacker, "{orange}[ReverseFF]{lightgreen} %t {olive}%N{lightgreen}, %t.", "YouAttacked", victim, "InfectedFF");
				}
			}
			//no damage for victim
			return Plugin_Handled;
		}
	}
	//all other damage behaves normal
	return Plugin_Continue;
}

//pan0s | 20-Apr-2021 | Fixed: Server crashes if reversing chainsaw damage makes the attacker incapacitated or dead.
//pan0s | start chainsaw fix part 2
public Action ChainsawTakeDamageTimer(Handle timer, Handle dataPack)
{
	//read the DataPack
	ResetPack(dataPack);
	int attacker = ReadPackCell(dataPack);
	int inflictor = ReadPackCell(dataPack);
	int victim = ReadPackCell(dataPack);
	float damage = ReadPackFloat(dataPack);
	int damagetype = ReadPackCell(dataPack);
	int weapon = ReadPackCell(dataPack);
	float damageForce[3];
	float damagePosition[3];
	for (int i=0; i<3; i++)
	{
		damageForce[i] = ReadPackFloat(dataPack);
		damagePosition[i] = ReadPackFloat(dataPack);
	}
	CloseHandle(dataPack);
	//pan0s | end chainsaw fix part 2
	
	if (IsValidClientAndInGameAndSurvivor(attacker) && IsValidClientAndInGameAndSurvivor(victim) && victim != attacker)
	{
		//inflict (chainsaw) damage to attacker
		//add 1HP to victim then damage them for 1HP so the displayed message and vocalization order are correct,
		//then damage attacker as self damage so there is no vocalization, just pain grunt.
		SetEntityHealth(victim, GetClientHealth(victim) + 1);
		SDKHooks_TakeDamage(victim, inflictor, attacker, 1.0, 0, weapon, g_fDmgFrc, g_fDmgPos);
		SDKHooks_TakeDamage(attacker, inflictor, attacker, damage, damagetype, weapon, damageForce, damagePosition);
	}
		
	return Plugin_Continue;
}

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
	return Plugin_Continue;
}

public Action CooldownTimer(Handle timer, int attacker)
{
	g_bCooldownFlag[attacker] = false;
	return Plugin_Continue;
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
		//PrintToServer("Event_StartGrace");
	}
	return Plugin_Continue;
}

public Action EndGrace (Handle timer, int client)
{
		g_bGrace[client] = false;
		g_hEndGrace[client] = INVALID_HANDLE;
		//PrintToServer("Event_EndGrace");
		return Plugin_Continue;
}

public Action Event_PullCarry (Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (!g_bCvarReverseIfPullCarry)
	{
		g_bGrace[client] = true;
		//PrintToServer("Event_PullCarry");
	}
	return Plugin_Continue;
}

public Action Event_PounceRide (Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bGrace[client] = true;
	//PrintToServer("Event_PounceRide");
	return Plugin_Continue;
}

public Action FlipToggle(Handle timer, int attacker)
{
  g_bToggle[attacker] = false;
  return Plugin_Continue;
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

//gets the distance between victim and attacker
//regardless of any difference in height
stock float GetClientDist(int victim, int attacker)
{
	float attackerPos[3], victimPos[3];
	float mins[3], maxs[3], halfHeight;
	GetClientMins(victim, mins);
	GetClientMaxs(victim, maxs);
	
	halfHeight = maxs[2] - mins[2] + 10;
	
	GetClientAbsOrigin(victim, victimPos);
	GetClientAbsOrigin(attacker, attackerPos);
	
	float posHeightDiff = attackerPos[2] - victimPos[2];
	
	if (posHeightDiff > halfHeight)
	{
		attackerPos[2] -= halfHeight;
	}
	else if (posHeightDiff < (-1.0 * halfHeight))
	{
		victimPos[2] -= halfHeight;
	}
	else
	{
		attackerPos[2] = victimPos[2];
	}
	
	return GetVectorDistance(victimPos, attackerPos, false);
}