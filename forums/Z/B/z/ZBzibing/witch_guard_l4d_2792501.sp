#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <sdkhooks>

#define MODEL_GUARD1             "models/infected/witch.mdl"
#define MODEL_GUARD1             "models/infected/witch.mdl"
//#define MODEL_GUARD2             "models/infected/witch_bride.mdl"
#define MODEL_W_MOLOTOV          "models/w_models/weapons/w_eq_molotov.mdl"
#define SPRITE_ARROW_DOWN        "materials/vgui/scroll_down.vmt"
#define DEBUG 0

#define MAXENTITIES              2048
#define L4DTEAM_SURVIVOR         2

/** defines from "Silvers [L4D & L4D2] Achievement Trophy" Plugin */
#define PARTICLE_ACHIEVED        "achieved"
#define PARTICLE_FIREWORK        "mini_fireworks"
#define SOUND_ACHIEVEMENT        "ui/pickup_misc42.wav"

float fButtonTime = 1.5;
int best_anim_onback = 0;
int best_anim_down = 0;
int Anim[90];
int AnimCount = 2;
int GuardEnt[MAXPLAYERS+1];
int GuardEntSpawned[MAXPLAYERS+1];
int ClientIN_USE[MAXPLAYERS+1];
float PressTime[MAXPLAYERS+1];
float LastTime[MAXPLAYERS+1];
int WeaponFireEnt[MAXPLAYERS+1];
bool GuardViewOff[MAXPLAYERS+1];
bool bThirdPersonFix[MAXPLAYERS+1];
bool bThirdPerson[MAXPLAYERS+1];
float OffSets[100][3];
int lastAttacker[MAXENTITIES+1];
int lastHumanAttacker[MAXENTITIES+1];
int g_guardDamage[MAXENTITIES+1][MAXPLAYERS+1][2];
int GuardEntMap[MAXPLAYERS+1];

bool bL4D2Version;

public Plugin myinfo =
{
    name = "Witch Guard",
    author = "Pan XiaoHai (fork by Dragokas & Mart)",
    description = "<- Description ->",
    version = "1.4.9.8",
    url = "<- URL ->"
}

ConVar l4d_witch_guard_bestpose_onback;
ConVar l4d_witch_guard_bestpose_ondown;
ConVar l4d_witch_guard_pose_onback;
ConVar l4d_witch_guard_pose_down;
ConVar l4d_witch_guard_damage;
ConVar l4d_witch_guard_range;
ConVar l4d_witch_guard_gun_count;
ConVar l4d_witch_guard_shotonback;
ConVar l4d_witch_guard_steal;
ConVar l4d_witch_guard_spriteowner;
ConVar l4d_witch_guard_lose_in_death;
ConVar l4d_witch_guard_lose_in_afk;
ConVar l4d_witch_guard_bots;
ConVar l4d_witch_guard_prioritize_human_players;
ConVar l4d_witch_guard_give_random;
ConVar l4d_witch_guard_weapon_type;
ConVar l4d_witch_guard_arc;
ConVar l4d_witch_guard_glowtype;
ConVar l4d_witch_guard_glowflashing;
ConVar l4d_witch_guard_glowminrange;
ConVar l4d_witch_guard_glowmaxrange;
ConVar l4d_witch_guard_showbar;
ConVar l4d_witch_guard_mode;
ConVar l4d_witch_guard_scoredamage;
ConVar l4d_witch_guard_chance;
ConVar l4d_witch_guard_saferoom;
ConVar l4d_witch_guard_gamemodeson;
ConVar l4d_witch_guard_gamemodesoff;
ConVar l4d_witch_guard_gamemodestoggle;
ConVar l4d_witch_guard_mapson;
ConVar l4d_witch_guard_mapsoff;
ConVar l4d_witch_guard_model;

ConVar hCvar_MPGameMode;

static char sCurrentMap[256];
static char sCvar_MPGameMode[16];
static char sCvar_GameModesOn[256];
static char sCvar_GameModesOff[256];
static char sCvar_MapsOn[256];
static char sCvar_MapsOff[256];
static int iCvar_GameModesToggle;
static int iCvar_CurrentMode;

int GuardButton[MAXPLAYERS+1];
int WitchGuardEnt[MAXPLAYERS+1];
int GuardType[MAXPLAYERS+1];
int GuardWeaponEnt[MAXPLAYERS+1][21];
int GuardCount = 0;
int GuardModel1 = -1;
int GuardModel2 = -1;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in the \"Left 4 Dead\" and \"Left 4 Dead 2\" game.");
        return APLRes_SilentFailure;
    }

    bL4D2Version = (engine == Engine_Left4Dead2);

    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("witch_guard.phrases");

    if (bL4D2Version)
        SetAnimL4d2();
    else
        SetAnimL4d1();

    char sBestAnimOnBack[3];
    Format(sBestAnimOnBack, sizeof(sBestAnimOnBack), "%i", best_anim_onback);

    char sBestAnimDown[3];
    Format(sBestAnimDown, sizeof(sBestAnimDown), "%i", best_anim_down);

    hCvar_MPGameMode = FindConVar("mp_gamemode"); // Native Game Mode ConVar

    l4d_witch_guard_bestpose_onback = CreateConVar("l4d_witch_guard_bestpose_onback", "1", "0: random pose, 1: best pose, 2: specific pose (uses pose_onback cvars)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
    l4d_witch_guard_bestpose_ondown = CreateConVar("l4d_witch_guard_bestpose_ondown", "1", "0: random pose, 1: best pose, 2: specific pose (uses pose_down cvars)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
    l4d_witch_guard_pose_onback = CreateConVar("l4d_witch_guard_pose_onback", sBestAnimOnBack, "0: off, 1-82: default witch pose while on back. (l4d_witch_guard_bestpose_onback must be: 2)", FCVAR_NOTIFY, true, 0.0, true, 82.0);
    l4d_witch_guard_pose_down = CreateConVar("l4d_witch_guard_pose_down", sBestAnimDown, "0: off, 1-82: default witch pose while down. (l4d_witch_guard_bestpose_onback must be: 2)", FCVAR_NOTIFY, true, 0.0, true, 82.0);
    l4d_witch_guard_damage = CreateConVar("l4d_witch_guard_damage", "0.5", "attack dmage, 1.0: normal [0.1, 1.0]", FCVAR_NOTIFY);
    l4d_witch_guard_range = CreateConVar("l4d_witch_guard_range", "600.0", "attack range", FCVAR_NOTIFY);
    l4d_witch_guard_gun_count = CreateConVar("l4d_witch_guard_gun_count", "3", "gun count [0, 6]", FCVAR_NOTIFY);
    l4d_witch_guard_shotonback = CreateConVar("l4d_witch_guard_shotonback", "0", "0: do not shot on back, 1: shot", FCVAR_NOTIFY);
    l4d_witch_guard_steal = CreateConVar("l4d_witch_guard_steal", "0", "Enables/Disables other clients to steal(pick up) a Witch from other owners while on the ground. 0 = Disable, 1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    l4d_witch_guard_spriteowner = CreateConVar("l4d_witch_guard_spriteowner", "1", "Show/Hide the sprite indicating which Witch in the ground is from the owner. 0 = Hide, 1 = Show.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    l4d_witch_guard_lose_in_death = CreateConVar("l4d_witch_guard_lose_in_death", "0", "Lose witch when player dies. 0 = Disable, 1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    l4d_witch_guard_lose_in_afk = CreateConVar("l4d_witch_guard_lose_in_afk", "0", "Lose witch when player goes afk. 0 = Disable, 1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    l4d_witch_guard_bots = CreateConVar("l4d_witch_guard_bots", "0", "Allow bots to get Witch Guard. 0 = Disable, 1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    l4d_witch_guard_prioritize_human_players = CreateConVar("l4d_witch_guard_prioritize_human_players", "0", "Prioritize human players. 0 = Disable, 1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    l4d_witch_guard_give_random = CreateConVar("l4d_witch_guard_give_random", "0", "Give witch to a random player if the killer already has one. 0 = Disable, 1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    l4d_witch_guard_weapon_type = CreateConVar("l4d_witch_guard_weapon_type", "0", "Weapon type given to the witch. 0 = Random, 1 = Assault Rifle, 2 = Hunting Rifle, 3 = Auto Shotgun.", FCVAR_NOTIFY, true, 0.0, true, 3.0);
    l4d_witch_guard_arc = CreateConVar("l4d_witch_guard_arc", "360", "The arc that the witch guard will search for targets.", FCVAR_NOTIFY, true, 0.0, true, 360.0);
    l4d_witch_guard_glowtype = CreateConVar("l4d_witch_guard_glowtype", "3", "The Witch Guard glow outline type. (0 = None, 1 = On Use, 2 = On Look At, 3 = Constant.", FCVAR_NOTIFY, true, 0.0, true, 3.0);
    l4d_witch_guard_glowflashing = CreateConVar("l4d_witch_guard_glowflashing", "0", "The Witch Guard will have a glow outline flashing.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    l4d_witch_guard_glowminrange = CreateConVar("l4d_witch_guard_glowminrange", "0", "The minimum range that a client can be away from the Witch Guard until the glow starts to outline.", FCVAR_NOTIFY, true, 0.0);
    l4d_witch_guard_glowmaxrange = CreateConVar("l4d_witch_guard_glowmaxrange", "0", "The maximum range that a client can be away from the Witch Guard until the glow stops to outline.", FCVAR_NOTIFY, true, 0.0);
    l4d_witch_guard_showbar = CreateConVar("l4d_witch_guard_showbar", "1", "Shows a progress bar while putting the Witch Guard down (L4D2 only). 0 = Disable, 1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    l4d_witch_guard_mode = CreateConVar("l4d_witch_guard_mode", "1", "Criteria based on to give the Witch Guard. 0 = Last Hit, 1 = Most Damage.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    l4d_witch_guard_scoredamage = CreateConVar("l4d_witch_guard_scoredamage", "1", "Enables the Witch Guard hits and kills count as the owner.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    l4d_witch_guard_chance = CreateConVar("l4d_witch_guard_chance", "100.0", "% chance to get a Witch Guard when a witch is killed.", FCVAR_NOTIFY, true, 0.0, true, 100.0);
    l4d_witch_guard_saferoom = CreateConVar("l4d_witch_guard_saferoom", "0", "Enables carrying the Witch Guard across maps when reaches alive to the saferoom with it on back. Removes on map change. 0 = Disable, 1 = Enable", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    l4d_witch_guard_gamemodeson = CreateConVar("l4d_witch_guard_gamemodes_on", "", "Turn on the plugin in these game modes, separate by commas (no spaces). Empty = all.\nKnown values: coop,realism,versus,survival,scavenge,teamversus,teamscavenge,\nmutation[1-20],community[1-6],gunbrain,l4d1coop,l4d1vs,holdout,dash,shootzones.", FCVAR_NOTIFY);
    l4d_witch_guard_gamemodesoff = CreateConVar("l4d_witch_guard_gamemodes_off", "", "Turn off the plugin in these game modes, separate by commas (no spaces). Empty = none.\nKnown values: coop,realism,versus,survival,scavenge,teamversus,teamscavenge,\nmutation[1-20],community[1-6],gunbrain,l4d1coop,l4d1vs,holdout,dash,shootzones.", FCVAR_NOTIFY);
    l4d_witch_guard_gamemodestoggle = CreateConVar("l4d_witch_guard_gamemodes_toggle", "0", "Turn on the plugin in these game modes.\nKnown values: 0 = all, 1 = coop, 2 = survival, 4 = versus, 8 = scavenge.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for \"coop\" (1) and \"survival\" (2).", FCVAR_NOTIFY, true, 0.0, true, 15.0);
    l4d_witch_guard_mapson = CreateConVar("l4d_witch_guard_mapson", "", "Allow the plugin being loaded on these maps, separate by commas (no spaces). Empty = all.\nExample: \"l4d_hospital01_apartment,c1m1_hotel\"", FCVAR_NOTIFY);
    l4d_witch_guard_mapsoff = CreateConVar("l4d_witch_guard_mapsoff", "", "Prevent the plugin being loaded on these maps, separate by commas (no spaces). Empty = none.\nExample: \"l4d_hospital01_apartment,c1m1_hotel\"", FCVAR_NOTIFY);
    l4d_witch_guard_model = CreateConVar("l4d_witch_guard_model", "1", "Witch model given on kill. 0 = Random, 1 = Model from killed witch.", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    // Hook Plugin ConVars Change
    hCvar_MPGameMode.AddChangeHook(Event_ConVarChanged);
    l4d_witch_guard_gamemodeson.AddChangeHook(Event_ConVarChanged);
    l4d_witch_guard_gamemodesoff.AddChangeHook(Event_ConVarChanged);
    l4d_witch_guard_gamemodestoggle.AddChangeHook(Event_ConVarChanged);
    l4d_witch_guard_mapson.AddChangeHook(Event_ConVarChanged);
    l4d_witch_guard_mapsoff.AddChangeHook(Event_ConVarChanged);

    #if DEBUG
        RegConsoleCmd("sm_w", CmdTest);
    #endif

    AutoExecConfig(true, "witch_guard_l4d");

    HookEvent("infected_hurt", infected_hurt);
    HookEvent("witch_killed", witch_killed, EventHookMode_Pre);
    HookEvent("player_bot_replace", player_bot_replace);
    HookEvent("round_start", round_end);
    HookEvent("round_end", round_end);
    HookEvent("finale_win", round_end);
    HookEvent("mission_lost", round_end);
    HookEvent("map_transition", round_end);
    HookEvent("player_death", player_death);
    HookEvent("player_team", eTeamChange);
    HookEvent("survivor_rescued", eSurvivorRescued);
    HookEvent("player_spawn", player_spawn);

    RegConsoleCmd("sm_witchoff", sm_witchoff);
    RegConsoleCmd("sm_witchon", sm_witchon);
    RegConsoleCmd("sm_witchpose", sm_witchpose);
    RegConsoleCmd("sm_witchpose2", sm_witchpose2);

    RegAdminCmd("sm_givewitch", sm_givewitch, ADMFLAG_ROOT, "Gives a Witch to the target");
    ResetAllState();
}

/****************************************************************************************************/

void Event_ConVarChanged(Handle convar, const char[] sOldValue, const char[] sNewValue)
{
    GetCvars();
}

/****************************************************************************************************/

void GetCvars()
{
    GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
    hCvar_MPGameMode.GetString(sCvar_MPGameMode, sizeof(sCvar_MPGameMode));
    TrimString(sCvar_MPGameMode);
    l4d_witch_guard_gamemodeson.GetString(sCvar_GameModesOn, sizeof(sCvar_GameModesOn));
    ReplaceString(sCvar_GameModesOn, sizeof(sCvar_GameModesOn), " ", "", false);
    l4d_witch_guard_gamemodesoff.GetString(sCvar_GameModesOff, sizeof(sCvar_GameModesOff));
    ReplaceString(sCvar_GameModesOff, sizeof(sCvar_GameModesOff), " ", "", false);
    iCvar_GameModesToggle = l4d_witch_guard_gamemodestoggle.IntValue;
    l4d_witch_guard_mapson.GetString(sCvar_MapsOn, sizeof(sCvar_MapsOn));
    ReplaceString(sCvar_MapsOn, sizeof(sCvar_MapsOn), " ", "", false);
    l4d_witch_guard_mapsoff.GetString(sCvar_MapsOff, sizeof(sCvar_MapsOff));
    ReplaceString(sCvar_MapsOff, sizeof(sCvar_MapsOn), " ", "", false);
}

/****************************************************************************************************/

public void player_spawn(Event event, const char[] name, bool dontBroadcast)
{
    int clientID = event.GetInt("userid");
    int client = GetClientOfUserId(clientID);

    if (l4d_witch_guard_saferoom.IntValue == 1)
    {
        if (GuardEntMap[client] == 1 && IsValidClient(client))
        {
            CreateDecoration(client, false);
            GuardEntMap[client] = 0;
        }
    }
}

public void OnEntityDestroyed(int entity)
{
    if (entity > 0 && entity <= MAXENTITIES)
    {
        for (int i = 0; i <= MAXPLAYERS; i++)
        {
            g_guardDamage[entity][i][0] = 0;
            g_guardDamage[entity][i][1] = 0;
        }
    }
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrEqual(classname, "tank", false) || StrEqual(classname, "witch", false) || StrEqual(classname, "infected", false) || StrEqual(classname, "player", false))
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);

    if (StrEqual(classname, "witch", false))
        SDKHook(entity, SDKHook_OnTakeDamageAlive, OnWitchTakeDamage);
}

public Action OnWitchTakeDamage(int witch, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if (!IsValidClient(attacker))
        return Plugin_Continue;

    g_guardDamage[witch][attacker][0] += RoundFloat(damage);
    g_guardDamage[witch][attacker][1] = attacker;

    return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (l4d_witch_guard_scoredamage.IntValue == 0)
		return Plugin_Continue;

	if (victim && attacker)
	{
		char classname[64];
		GetEntityClassname(attacker, classname, sizeof(classname));

		if (StrEqual(classname, "env_weaponfire", false))
		{
			char targetname[64];
			GetEntPropString(attacker, Prop_Data, "m_iName", targetname, sizeof(targetname));
			ReplaceString(targetname, sizeof(targetname), "clientwitchguard", "");

			int client = EntRefToEntIndex(StringToInt(targetname));

			if (IsValidClient(client))
			{
				SDKHooks_TakeDamage(victim, client, client, damage, DMG_BULLET, -1, NULL_VECTOR, NULL_VECTOR);
				damage = 0.0;
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}
/*
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (GetConVarInt(l4d_witch_guard_scoredamage) == 0)
        return Plugin_Continue;

    if (victim <= 0)
        return Plugin_Continue;

    if (!IsValidClient(attacker))
        return Plugin_Continue;

    char classname[64];
    GetEntityClassname(attacker, classname, sizeof(classname));

    if (StrEqual(classname, "env_weaponfire", false))
    {
        char targetname[64];
        GetEntPropString(attacker, Prop_Data, "m_iName", targetname, sizeof(targetname));
        ReplaceString(targetname, sizeof(targetname), "clientwitchguard", "");

        int client = EntRefToEntIndex(StringToInt(targetname));

        if (IsValidClient(client))
        {
            SDKHooks_TakeDamage(victim, client, client, damage, DMG_BULLET, -1, NULL_VECTOR, NULL_VECTOR);
            damage = 0.0;
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}
*/
Action sm_givewitch(int client, int args)
{
    if (args == 0)
    {
        if (IsValidClient(client))
            PrintToChat(client, "\x05Usage: \x04!givewitch \x03<target>");
        return Plugin_Handled;
    }

    char sArg[256];
    GetCmdArg(1, sArg, sizeof(sArg));

    int target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;
    char target_name[MAX_TARGET_LENGTH];

    target_count = ProcessTargetString(sArg,
                                       client,
                                       target_list,
                                       MAXPLAYERS,
                                       COMMAND_FILTER_CONNECTED,
                                       target_name,
                                       sizeof(target_name),
                                       tn_is_ml);

    if (target_count <= 0)
    {
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }

    for (int i = 0; i < target_count; i++)
    {
        if (IsValidClient(target_list[i]) && GetClientTeam(target_list[i]) == L4DTEAM_SURVIVOR)
        {
            GuardType[target_list[i]] = GetRandomInt(0,1);
            CreateDecoration(target_list[i], true);
        }
    }

    return Plugin_Handled;
}

public Action CmdTest(int client, int args)
{
    PrintToChat(client, "Enumerating witch");

    char sName[256];
    int ent = -1;
    while (-1 != (ent = FindEntityByClassname(ent, "prop_dynamic"))) {

        GetEntPropString(ent, Prop_Data, "m_ModelName", sName, sizeof(sName));
        if (StrEqual(sName, MODEL_GUARD1, false)) {
            PrintToChat(client, "find the witch guard: %i, owner: %i", ent, GetGuardOwner(ent));
        }
        if (StrEqual(sName, MODEL_GUARD2, false)) {
            PrintToChat(client, "find the witch guard: %i, owner: %i", ent, GetGuardOwner(ent));
        }
    }

    return Plugin_Handled;
}

stock int GetGuardOwner(int entity)
{
    for (int i = 1; i <= MaxClients; i++)
        if (WitchGuardEnt[i] == entity)
            return i;

    for (int i = 1; i <= MaxClients; i++)
        if (GuardEnt[i] == entity)
            return i;

    return 0;
}

public void OnMapStart()
{
    GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));

    GuardModel1 = PrecacheModel(MODEL_GUARD1, true);
    GuardModel2 = PrecacheModel(MODEL_GUARD2, true);
    PrecacheModel(MODEL_W_MOLOTOV, true);
    PrecacheModel(SPRITE_ARROW_DOWN, true);
    CreateTimer(1.0, tThirdPersonCheck, INVALID_HANDLE, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

    /** precaches from "Silvers [L4D & L4D2] Achievement Trophy" Plugin */
    PrecacheParticle(PARTICLE_ACHIEVED);
    PrecacheParticle(PARTICLE_FIREWORK);
    PrecacheSound(SOUND_ACHIEVEMENT);
}

public Action tThirdPersonCheck(Handle hTimer)
{
    static int i;
    for(i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && !IsFakeClient(i))
        {
            QueryClientConVar(i, "c_thirdpersonshoulder", QueryClientConVarCallback);
        }
    }
}

public void QueryClientConVarCallback(QueryCookie sCookie, int iClient, ConVarQueryResult sResult, const char[] sCvarName, const char[] sCvarValue)
{
    //THIRDPERSON
    if (!StrEqual(sCvarValue, "0"))
    {
        if (bThirdPersonFix[iClient])
        {
            bThirdPerson[iClient] = false;
        }
        else
            bThirdPerson[iClient] = true;
    }
    //FIRSTPERSON
    else
    {
        bThirdPerson[iClient] = false;
        bThirdPersonFix[iClient] = false;
    }
}

void SetAnimL4d2()
{
    OffSets[1] = view_as<float>({-5.000000,26.000000,-100.000000});
    OffSets[2] = view_as<float>({-3.000000,32.000000,-100.000000});
    OffSets[3] = view_as<float>({-1.000000,28.000000,-100.000000});
    OffSets[5] = view_as<float>({-1.000000,28.000000,-100.000000});
    OffSets[7] = view_as<float>({1.000000,26.000000,-100.000000});
    OffSets[8] = view_as<float>({-3.000000,26.000000,-100.000000});
    OffSets[10] = view_as<float>({-3.000000,24.000000,-100.000000});
    OffSets[16] = view_as<float>({1.000000,28.000000,-100.000000});
    OffSets[18] = view_as<float>({1.000000,32.000000,-100.000000});
    OffSets[35] = view_as<float>({-5.000000,4.000000,-100.000000});
    OffSets[37] = view_as<float>({1.000000,28.000000,-100.000000});
    OffSets[44] = view_as<float>({-1.000000,28.000000,-100.000000});
    OffSets[45] = view_as<float>({-1.000000,30.000000,-100.000000});
    OffSets[46] = view_as<float>({-1.000000,32.000000,-100.000000});
    OffSets[49] = view_as<float>({-3.000000,32.000000,-100.000000});
    OffSets[51] = view_as<float>({-1.000000,30.000000,-100.000000});
    OffSets[54] = view_as<float>({3.000000,32.000000,-100.000000});
    OffSets[55] = view_as<float>({-1.000000,30.000000,-100.000000});
    OffSets[59] = view_as<float>({-1.000000,28.000000,-100.000000});
    OffSets[61] = view_as<float>({-5.000000,24.000000,-100.000000});
    OffSets[62] = view_as<float>({-5.000000,22.000000,-100.000000});
    OffSets[66] = view_as<float>({-5.000000,30.000000,-100.000000});
    OffSets[73] = view_as<float>({-5.000000,0.000000,-100.000000});
    OffSets[74] = view_as<float>({1.000000,10.000000,-100.000000});
    OffSets[76] = view_as<float>({-5.000000,32.000000,-100.000000});
    OffSets[77] = view_as<float>({-5.000000,34.000000,-100.000000}); //best
    OffSets[79] = view_as<float>({-9.000000,20.000000,-100.000000});
    OffSets[80] = view_as<float>({-15.000000,18.000000,-100.000000});
    OffSets[81] = view_as<float>({-15.000000,18.000000,-100.000000});
    OffSets[82] = view_as<float>({-15.000000,18.000000,-100.000000});
    AnimCount = 0;
    for(int i = 0;i<90; i++)
    {
        if (OffSets[i][2] == -100.0)
        {
            Anim[AnimCount] = i;
            AnimCount++;
        }
    }

    best_anim_onback = 77;
    best_anim_down = 3;

}
void SetAnimL4d1()
{
    OffSets[1] = view_as<float>({1.000000,32.000000,-100.000000});
    OffSets[3] = view_as<float>({-1.000000,28.000000,-100.000000});
    OffSets[4] = view_as<float>({1.000000,28.000000,-100.000000});
    OffSets[5] = view_as<float>({1.000000,32.000000,-100.000000});
    OffSets[6] = view_as<float>({1.000000,22.000000,-100.000000});
    OffSets[9] = view_as<float>({3.000000,26.000000,-100.000000});
    OffSets[29] = view_as<float>({-1.000000,30.000000,-100.000000});
    OffSets[32] = view_as<float>({-1.000000,30.000000,-100.000000});
    OffSets[36] = view_as<float>({1.000000,32.000000,-100.000000});
    OffSets[37] = view_as<float>({-1.000000,32.000000,-100.000000});
    OffSets[41] = view_as<float>({-1.000000,32.000000,-100.000000});
    OffSets[43] = view_as<float>({-1.000000,32.000000,-100.000000});
    OffSets[46] = view_as<float>({1.000000,32.000000,-100.000000});
    OffSets[47] = view_as<float>({1.000000,26.000000,-100.000000});
    OffSets[51] = view_as<float>({1.000000,24.000000,-100.000000});
    OffSets[53] = view_as<float>({-1.000000,20.000000,-100.000000});
    OffSets[54] = view_as<float>({-5.000000,20.000000,-100.000000});
    OffSets[57] = view_as<float>({-3.000000,20.000000,-100.000000});
    OffSets[65] = view_as<float>({-9.000000,2.000000,-100.000000});
    OffSets[66] = view_as<float>({-1.000000,14.000000,-100.000000});
    OffSets[68] = view_as<float>({-1.000000,36.000000,-100.000000});
    OffSets[69] = view_as<float>({-3.000000,32.000000,-100.000000}); //best
    OffSets[70] = view_as<float>({-1.000000,32.000000,-100.000000});
    OffSets[72] = view_as<float>({-9.0,18.0,-100.0});
    AnimCount = 0;
    for(int i = 0;i<90; i++)
    {
        if (OffSets[i][2] == -100.0)
        {
            Anim[AnimCount] = i;
            AnimCount++;
        }
    }
    best_anim_onback = 69;
    best_anim_down = 1;
}

public Action sm_witchpose(int client, int args)
{
    for(int i = 1; i<= MaxClients; i++)
    {
        if (IsGuard(GuardEnt[i]))
        {
            client = i;
            if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == L4DTEAM_SURVIVOR)
            {
                int anim = Anim[ GetRandomInt(0,AnimCount-1) ];
                float ang[3];
                SetVector(ang, 0.0, 0.0, 90.0);
                float pos[3];
                pos[0] = OffSets[anim][0];
                pos[1] = OffSets[anim][1];

                TeleportEntity(GuardEnt[client], pos, ang, NULL_VECTOR);

                SetEntProp(GuardEnt[client], Prop_Send, "m_nSequence", anim);
                SetEntPropFloat(GuardEnt[client], Prop_Send, "m_flPlaybackRate", 1.0);
            }
        }
    }
    return Plugin_Continue;

}

public Action sm_witchpose2(int client, int args)
{
    char sArg[256];
    GetCmdArg(1, sArg, sizeof(sArg));

    int anim = StringToInt(sArg);

    if (IsGuard(GuardEnt[client]))
    {
        if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == L4DTEAM_SURVIVOR)
        {
            float ang[3];
            SetVector(ang, 0.0, 0.0, 90.0);
            float pos[3];
            pos[0] = OffSets[anim][0];
            pos[1] = OffSets[anim][1];

            TeleportEntity(GuardEnt[client], pos, ang, NULL_VECTOR);

            SetEntProp(GuardEnt[client], Prop_Send, "m_nSequence", anim);
            SetEntPropFloat(GuardEnt[client], Prop_Send, "m_flPlaybackRate", 1.0);
        }
    }

    for(int i = 0; i<GuardCount; i++)
    {
        if (!IsValidEntity(WitchGuardEnt[i])) continue;

        SetEntProp(WitchGuardEnt[i], Prop_Send, "m_nSequence", anim);
        SetEntPropFloat(WitchGuardEnt[i], Prop_Send, "m_flPlaybackRate", 1.0);
    }

    return Plugin_Continue;
}

public Action sm_witchoff(int client, int args)
{
    if (IsValidClient(client))
    {
        GuardViewOff[client] = true;
        CPrintToChat(client, "%t", "View_Off"); // \x04witch \x03view is \x04off, \x03but others still can see it on your back");
    }
}

public Action sm_witchon(int client, int args)
{
    if (IsValidClient(client))
    {
        GuardViewOff[client] = false;
        CPrintToChat(client, "%t", "View_On"); // \x04witch \x03view is \x04on");
    }
}

public void infected_hurt(Handle event, char[] name, bool dontBroadcast)
{
    int entityid = GetEventInt(event, "entityid");

    if (!IsGuardEntity(entityid))
        return;

    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

    if (IsValidClient(attacker) && GetClientTeam(attacker) == L4DTEAM_SURVIVOR && !IsGuard(GuardEnt[attacker]))
    {
        lastAttacker[entityid] = attacker;

        if (!IsFakeClient(attacker))
            lastHumanAttacker[entityid] = attacker;
    }
}

public Action player_death(Event hEvent, const char[] strName, bool DontBroadcast)
{
    int victim = GetClientOfUserId(hEvent.GetInt("userid"));
    if (IsValidClient(victim) && GetClientTeam(victim) == L4DTEAM_SURVIVOR)
    {
        if (l4d_witch_guard_lose_in_death.IntValue == 1)
        {
            DeleteDecoration(victim);
            SDKUnhook(victim, SDKHook_PreThink, PreThinkClient);
        }

        if (!IsFakeClient(victim))
            bThirdPersonFix[victim] = true;
    }
    return Plugin_Continue;
}
public void player_bot_replace(Event Spawn_Event, const char[] Spawn_Name, bool Spawn_Broadcast)
{
    if (l4d_witch_guard_lose_in_afk.IntValue == 1)
    {
        int client = GetClientOfUserId(Spawn_Event.GetInt("player"));
        int bot = GetClientOfUserId(Spawn_Event.GetInt("bot"));
        if (client>0)
        {
            if (GuardEnt[client]>0)DeleteDecoration(client);
            SDKUnhook(client, SDKHook_PreThink, PreThinkClient);
        }
        if (bot>0)
        {
            if (GuardEnt[bot]>0)DeleteDecoration(bot);
            SDKUnhook(client, SDKHook_PreThink, PreThinkClient);
        }
    }
}

public Action witch_killed(Event hEvent, const char[] strName, bool DontBroadcast)
{
    if (!IsAllowedMap())
        return Plugin_Continue;

    if (!IsAllowedGameMode())
        return Plugin_Continue;

    int witch = hEvent.GetInt("witchid");

    if (GetRandomFloat(0.1, 100.0) > GetConVarFloat(l4d_witch_guard_chance))
        return Plugin_Continue;

    if (witch > 0 && IsValidEntity(witch))
    {
        int attacker = 0;

        switch (l4d_witch_guard_mode.IntValue)
        {
            case 0:
            {
                attacker = GetClientOfUserId(hEvent.GetInt("userid"));

                if (attacker == 0)
                    attacker = lastAttacker[witch];
                else if (l4d_witch_guard_bots.IntValue == 0 && IsValidClient(attacker) && IsFakeClient(attacker))
                    attacker = lastHumanAttacker[witch];
                else if (l4d_witch_guard_prioritize_human_players.IntValue == 1 && IsValidClient(attacker) && IsFakeClient(attacker) && IsValidClient(lastHumanAttacker[witch]))
                    attacker = lastHumanAttacker[witch];
            }
            case 1:
            {
                //PrintToServer("RESULT BEFORE SORTING:");
                //PrintToServer("-------------------------------------------------------------------");
                //for (int i = 0; i < sizeof(g_guardDamage[]); i++)
                //{
                //    PrintToServer("g_guardDamage[witch = %i][i = %i][0] = %i | %i | %N", witch, i, g_guardDamage[witch][i][0], g_guardDamage[witch][i][1],  g_guardDamage[witch][i][1]);
                //}

                SortCustom2D(g_guardDamage[witch], sizeof(g_guardDamage[]), SortByDamageDesc);

                //PrintToServer("RESULT AFTER SORTING:");
                //PrintToServer("-------------------------------------------------------------------");
                //for (int i = 0; i < 8; i++)
                //{
                //    PrintToServer("g_guardDamage[witch = %i][i = %i][0] = %i | %i | %N", witch, i, g_guardDamage[witch][i][0], g_guardDamage[witch][i][1],  g_guardDamage[witch][i][1]);
                //}

                int tempAttacker;
                int tempAttacker2;
                int tempAttacker3;

                for (int i = 0; i < sizeof(g_guardDamage[]); i++)
                {
                    if (g_guardDamage[witch][i][0] <= 0)
                        continue;

                    tempAttacker = g_guardDamage[witch][i][1];

                    if (!IsValidClient(tempAttacker))
                        continue;

                    if (GetClientTeam(tempAttacker) != 2)
                        continue;

                    if (!IsPlayerAlive(tempAttacker))
                        continue;

                    if (l4d_witch_guard_bots.IntValue == 0 && IsValidClient(tempAttacker) && IsFakeClient(tempAttacker))
                        continue;

                    if (l4d_witch_guard_give_random.IntValue == 1)
                    {
                        if (IsGuard(GuardEnt[tempAttacker]) || GuardEntSpawned[tempAttacker] == 1)
                        {
                            if (GuardEntSpawned[tempAttacker] == 1 && tempAttacker3 == 0)
                                tempAttacker3 = tempAttacker;

                            continue;
                        }
                    }

                    if (l4d_witch_guard_prioritize_human_players.IntValue == 1 && IsFakeClient(tempAttacker))
                    {
                        if (tempAttacker2 == 0)
                            tempAttacker2 = tempAttacker;

                        continue;
                    }

                    attacker = tempAttacker;
                    break;
                }

                if (attacker == 0 && tempAttacker2 != 0)
                    attacker = tempAttacker2;

                if (attacker == 0 && tempAttacker3 != 0)
                    attacker = tempAttacker3;
            }
        }

        if (l4d_witch_guard_give_random.IntValue == 1)
        {
            if (attacker == 0)
                attacker = GetRandomPlayer(attacker);
            else if (attacker != 0 && IsGuard(GuardEnt[attacker]))
                attacker = GetRandomPlayer(attacker);
        }

        lastAttacker[witch] = 0;
        lastHumanAttacker[witch] = 0;

        if (IsValidClient(attacker) && IsPlayerAlive(attacker) && GetClientTeam(attacker) == L4DTEAM_SURVIVOR)
        {
            if (l4d_witch_guard_model.IntValue == 0)
            {
                GuardType[attacker] = GetRandomInt(0,1);
            }
            else
            {
                int modelIndex = GetEntProp(witch, Prop_Send, "m_nModelIndex");

                if (modelIndex == GuardModel1)
                    GuardType[attacker] = 0;
                else if (modelIndex == GuardModel2)
                    GuardType[attacker] = 1;
                else
                    GuardType[attacker] = 0;
            }

            CreateDecoration(attacker, true);

            char sName[32];
            GetClientName(attacker, sName, sizeof(sName));
            switch (GetRandomInt(0, 4))
            {
                case 0: CPrintToChatAll("%t", "Witch_on_back0", sName); // \x04%N \x03put witch on his back", attacker);
                case 1: CPrintToChatAll("%t", "Witch_on_back1", sName); // \x04%N \x03put witch on his back", attacker);
                case 2: CPrintToChatAll("%t", "Witch_on_back2", sName); // \x04%N \x03put witch on his back", attacker);
                case 3: CPrintToChatAll("%t", "Witch_on_back3", sName); // \x04%N \x03put witch on his back", attacker);
                case 4: CPrintToChatAll("%t", "Witch_on_back4", sName); // \x04%N \x03put witch on his back", attacker);
            }

            CPrintToChat(attacker, "%t", "Keys1"); // "\x03press\x04!use button \x03to put witch down");
            //CPrintToChat(attacker, "%t", "Keys2"); // "\x04!witch \x03 - toggle to see or hide your own witch");
        }
    }
    return Plugin_Continue;
}

public Action round_end(Event event, const char[] name, bool dontBroadcast)
{
    if (StrEqual(name, "round_start", false))
    {
        return;
    }

    if (StrEqual(name, "finale_win", false))
    {
        for (int i = 0; i <= MAXPLAYERS; i++)
        {
            GuardEnt[i] = 0;
            GuardEntMap[i] = 0;
        }
    }
    else
    {
        for (int i = 0; i <= MAXPLAYERS; i++)
        {
            if (GuardEnt[i] != 0)
                GuardEntMap[i] = 1;
        }
    }

    ResetAllState();
}

void ResetAllState()
{
    for (int entity = 0; entity <= MAXENTITIES; entity++)
    {
        for (int i = 0; i <= MAXPLAYERS; i++)
        {
            g_guardDamage[entity][i][0] = 0;
            g_guardDamage[entity][i][1] = 0;
        }
    }

    GuardCount = 0;
    for(int i = 0; i<= MaxClients; i++)
    {
        GuardEnt[i] = 0;
        GuardType[i] = 0;
        GuardEntSpawned[i] = 0;
        WeaponFireEnt[i] = 0;
        GuardButton[i] = 0;
        ClientIN_USE[i] = 0;
        for(int j = 0; j<21; j++)
        {
             GuardWeaponEnt[i][j] = 0;
        }
    }
}

void ResetStateClient(int client)
{
    for (int entity = 0; entity <= MAXENTITIES; entity++)
    {
        g_guardDamage[entity][client][0] = 0;
        g_guardDamage[entity][client][1] = 0;
    }

    GuardViewOff[client] = false;
    GuardEntMap[client] = 0;
    GuardEnt[client] = 0;
    GuardType[client] = 0;
    GuardEntSpawned[client] = 0;
    WeaponFireEnt[client] = 0;
    GuardButton[client] = 0;
    ClientIN_USE[client] = 0;
    for(int j = 0; j<21; j++)
    {
         GuardWeaponEnt[client][j] = 0;
    }
}

public void OnClientDisconnect(int client)
{
    ResetStateClient(client);
}

void DeleteDecoration(int client)
{
    int entity = GuardEnt[client];
    int fireent = WeaponFireEnt[client];

    GuardEnt[client] = 0;
    WeaponFireEnt[client] = 0;

    if (IsGuard(entity))
    {
        AcceptEntityInput(entity, "kill");
    }
    if (fireent>0 && IsValidEdict(fireent) && IsValidEntity(fireent))
    {
        AcceptEntityInput(fireent, "kill");
    }
    if (IsValidClient(client))
    {
        SDKUnhook(client, SDKHook_PreThink,  PreThinkClient);
    }
}
void CreateDecoration(int client, bool showTrophy)
{
    if (IsGuard(GuardEnt[client])) return;

    if (showTrophy)
        CreateEffects(client, false);

    char model[64];
    if (GuardType[client] == 0)
        model = MODEL_GUARD1;
    else if (GuardType[client] == 1)
        model = MODEL_GUARD2;
    else
        model = MODEL_GUARD1;

    int witch = CreateEntityByName("prop_dynamic_override");
    DispatchKeyValue(witch, "model", model);
    DispatchSpawn(witch);

    char tname[60];
    Format(tname, sizeof(tname), "target%i", client);
    DispatchKeyValue(client, "targetname", tname);
    DispatchKeyValue(witch, "parentname", tname);

    SetVariantString(tname);
    AcceptEntityInput(witch, "SetParent",witch, witch, 0);
    SetVariantString("medkit");
    AcceptEntityInput(witch, "SetParentAttachment");

    int anim = 0;
    switch (l4d_witch_guard_bestpose_onback.IntValue)
    {
        case 0: anim = Anim[GetRandomInt(0,AnimCount-1)];
        case 1: anim = best_anim_onback;
        case 2: anim = l4d_witch_guard_pose_onback.IntValue;
    }

    float pos[3];
    float ang[3];
    SetVector(pos, -5.0, 32.0, 0.0);
    pos[0] = OffSets[anim][0];
    pos[1] = OffSets[anim][1];
    SetVector(ang, 0.0, 00.0, 90.0);

    TeleportEntity(witch, pos, ang, NULL_VECTOR);
    //SetEntityRenderMode(witch, RENDER_TRANSCOLOR);
    //SetEntityRenderColor(witch, 255,0,0,255);
    SetEntProp(witch, Prop_Send, "m_CollisionGroup", 2);

    SetEntProp(witch, Prop_Send, "m_nSequence", anim);
    SetEntPropFloat(witch, Prop_Send, "m_flPlaybackRate", 1.0);

    GuardEnt[client] = witch;

    //if (l4d_witch_guard_bestpose_onback.IntValue == 0)
    //    CreateTimer(15.0, TimerAnimWitch, client, TIMER_FLAG_NO_MAPCHANGE| TIMER_REPEAT);

    if (bL4D2Version)
    {
        int red = 0;
        int green = 150;
        int blue = 0;

        SetEntProp(witch, Prop_Send, "m_iGlowType", l4d_witch_guard_glowtype.IntValue);
        SetEntProp(witch, Prop_Send, "m_bFlashing", l4d_witch_guard_glowflashing.IntValue);
        SetEntProp(witch, Prop_Send, "m_nGlowRangeMin", l4d_witch_guard_glowminrange.IntValue);
        SetEntProp(witch, Prop_Send, "m_nGlowRange", l4d_witch_guard_glowmaxrange.IntValue);

        int clientGlowColor = GetEntProp(client, Prop_Send, "m_glowColorOverride");
        int clientGlowFlashing = GetEntProp(client, Prop_Send, "m_bFlashing");

        if (clientGlowColor > 0)
        {
            SetEntProp(witch, Prop_Send, "m_glowColorOverride", clientGlowColor);
            SetEntProp(witch, Prop_Send, "m_bFlashing", clientGlowFlashing);
            CreateTimer(0.1, tWitchGlow, EntIndexToEntRef(witch), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
        else
        {
            SetEntProp(witch, Prop_Send, "m_glowColorOverride", red + (green * 256) + (blue* 65536));
        }
    }

    SDKHook(GuardEnt[client], SDKHook_SetTransmit, Hook_SetTransmit);

    int ent = CreateEntityByName("env_weaponfire");

    float eye[3];
    GetClientEyePosition(client, eye);
    DispatchSpawn(ent);

    char tName[128];
    Format(tName, sizeof(tName), "target%i",client);
    DispatchKeyValue(client , "targetname", tName);

    DispatchKeyValueFloat(ent, "targetarc", l4d_witch_guard_arc.FloatValue);
    DispatchKeyValueFloat(ent, "targetrange", l4d_witch_guard_range.FloatValue);

    //1 : Assault Rifle
    //2 : Hunting Rifle
    //3 : Auto Shotgun
    char sWeaponType[2];
    if (l4d_witch_guard_weapon_type.IntValue == 0)
        Format(sWeaponType, sizeof(sWeaponType), "%i", GetRandomInt(1,3));
    else
        Format(sWeaponType, sizeof(sWeaponType), "%i", l4d_witch_guard_weapon_type.IntValue);

    DispatchKeyValue(ent, "weapontype", sWeaponType);

    // if (GetClientButtons(client) & IN_DUCK)
        // DispatchKeyValue(ent, "weapontype", "1");
    // else
        // DispatchKeyValue(ent, "weapontype", "3");

    DispatchKeyValue(ent, "targetteam", "3");
    DispatchKeyValueFloat(ent, "damagemod", l4d_witch_guard_damage.FloatValue);

    DispatchKeyValue(ent, "parentname", tName);
    SetVariantString(tName);
    AcceptEntityInput(ent, "SetParent", ent, ent, 0);
    SetVariantString("eyes"); //muzzle_flash
    AcceptEntityInput(ent, "SetParentAttachment");

    SetVector(eye, 0.0, 0.0, 15.0);
    TeleportEntity(ent, eye,NULL_VECTOR, NULL_VECTOR);
    if (l4d_witch_guard_shotonback.IntValue == 1)AcceptEntityInput(ent, "Enable");
    else AcceptEntityInput(ent, "Disable");
    WeaponFireEnt[client] = ent;

    PressTime[client] = GetEngineTime();
    LastTime[client] = GetEngineTime();
    SDKUnhook(client, SDKHook_PreThink,  PreThinkClient);
    SDKHook(client, SDKHook_PreThink,  PreThinkClient);

    #if DEBUG
    PrintToChatAll("Created witch decoration: %i", witch);
    #endif
}
void CreateGuard(int client)
{
    int anim = 0;
    switch (l4d_witch_guard_bestpose_ondown.IntValue)
    {
        case 0: anim = Anim[GetRandomInt(0,AnimCount-1)];
        case 1: anim = best_anim_down;
        case 2: anim = l4d_witch_guard_pose_down.IntValue;
    }

    float pos[3];
    float ang[3];
    float t[3];
    GetClientAbsOrigin(client, pos);
    GetClientEyeAngles(client, ang);
    ang[0] = 0.0;
    GetAngleVectors(ang, t, NULL_VECTOR,NULL_VECTOR);
    NormalizeVector(t, t);
    ScaleVector(t, 20.0);
    AddVectors(pos, t, pos);

    GetClientEyeAngles(client, t);
    t[0] = 0.0;
    t[1]+= 90.0;

    int witch = CreateEntityByName("prop_dynamic_override");
    DispatchKeyValue(witch, "model", GuardType[client] ? MODEL_GUARD2 : MODEL_GUARD1);
    DispatchKeyValueFloat(witch, "fademindist", 10000.0);
    DispatchKeyValueFloat(witch, "fademaxdist", 20000.0);
    DispatchKeyValueFloat(witch, "fadescale", 0.0);

    DispatchSpawn(witch);

    //TeleportEntity(witch, Float:{0.0, 0.0, 0.0}, NULL_VECTOR, NULL_VECTOR);
    TeleportEntity(witch, pos, ang, NULL_VECTOR);

    SetEntProp(witch, Prop_Send, "m_nSequence", anim);
    SetEntPropFloat(witch, Prop_Send, "m_flPlaybackRate", 1.0);
    SetEntPropEnt(witch, Prop_Send, "m_hOwnerEntity", client);

    //RENDER_NORMAL
    //SetEntityRenderMode(witch, RENDER_TRANSCOLOR);
    //SetEntityRenderColor(witch, 255, 0, 0, 255);

    if (bL4D2Version)
    {
        int red = 0;
        int green = 150;
        int blue = 0;

        SetEntProp(witch, Prop_Send, "m_iGlowType", l4d_witch_guard_glowtype.IntValue);
        SetEntProp(witch, Prop_Send, "m_bFlashing", l4d_witch_guard_glowflashing.IntValue);
        SetEntProp(witch, Prop_Send, "m_nGlowRangeMin", l4d_witch_guard_glowminrange.IntValue);
        SetEntProp(witch, Prop_Send, "m_nGlowRange", l4d_witch_guard_glowmaxrange.IntValue);

        int clientGlowColor = GetEntProp(client, Prop_Send, "m_glowColorOverride");
        int clientGlowFlashing = GetEntProp(client, Prop_Send, "m_bFlashing");

        if (clientGlowColor > 0)
        {
            SetEntProp(witch, Prop_Send, "m_glowColorOverride", clientGlowColor);
            SetEntProp(witch, Prop_Send, "m_bFlashing", clientGlowFlashing);
            CreateTimer(0.1, tWitchGlow, EntIndexToEntRef(witch), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
        else
        {
            SetEntProp(witch, Prop_Send, "m_glowColorOverride", red + (green * 256) + (blue* 65536));
        }
    }

    char tName[128];
    Format(tName, sizeof(tName), "target%i",witch);
    DispatchKeyValue(witch , "targetname", tName);

    DispatchKeyValue(witch, "parentname", tName);
    SetVariantString(tName);
    AcceptEntityInput(witch, "SetParent", witch, witch, 0);

    if (l4d_witch_guard_spriteowner.IntValue == 1)
    {
        int env_sprite = CreateEntityByName("env_sprite");

        if (!IsValidEntity(env_sprite))
            return;

        DispatchKeyValue(env_sprite, "model", SPRITE_ARROW_DOWN);
        DispatchKeyValue(env_sprite, "rendermode", "1");
        //DispatchKeyValue(env_sprite, "rendercolor", "0 0 255");
        DispatchKeyValue(env_sprite, "renderamt", "240");
        DispatchKeyValue(env_sprite, "disablereceiveshadows", "1");
        DispatchKeyValue(env_sprite, "spawnflags", "1");
        DispatchKeyValueFloat(env_sprite, "fademindist", 0.0);
        DispatchKeyValueFloat(env_sprite, "fademaxdist", 250.0);

        DispatchSpawn(env_sprite);

        SetVariantString("!activator");
        AcceptEntityInput(env_sprite, "SetParent", witch);

        char tNameSprite[64];
        Format(tNameSprite, sizeof(tNameSprite), "witchguardsprite%i", client);
        DispatchKeyValue(env_sprite, "targetname", tNameSprite);
        SDKHook(env_sprite, SDKHook_SetTransmit, SetTransmitSprite);

        float vPos[3];
        vPos[2] = 70.0;

        TeleportEntity(env_sprite, vPos, NULL_VECTOR, NULL_VECTOR);
    }

    //float front = 0.0;
    //float up = 35.0;
    //float side = 25.0;

    float pos2[3];
    int count = l4d_witch_guard_gun_count.IntValue;
    if (count<1)count = 1;
    if (count>21)count = 21;
    for(int i = 0; i<count; i++)
    {
        int ent = CreateEntityByName("env_weaponfire");
        DispatchSpawn(ent);
        DispatchKeyValueFloat(ent, "targetarc", 360.0);
        DispatchKeyValueFloat(ent, "targetrange", l4d_witch_guard_range.FloatValue);

        char sWeaponType[2];
        if (l4d_witch_guard_weapon_type.IntValue == 0)
            Format(sWeaponType, sizeof(sWeaponType), "%i", GetRandomInt(1,3));
        else
            Format(sWeaponType, sizeof(sWeaponType), "%i", l4d_witch_guard_weapon_type.IntValue);

        DispatchKeyValue(ent, "weapontype", sWeaponType);

        // if (GetClientButtons(client) & IN_DUCK)
            // DispatchKeyValue(ent, "weapontype", "1");
        // else
            // DispatchKeyValue(ent, "weapontype", "3");

        DispatchKeyValue(ent, "targetteam", "3");
        DispatchKeyValueFloat(ent, "damagemod", l4d_witch_guard_damage.FloatValue);

        float p[3];
        p[0] = 0.0;
        p[1] = 0.0;
        p[2] = 0.0;

        char targetName[64];
        Format(targetName, sizeof(targetName), "clientwitchguard%i", EntIndexToEntRef(client));
        DispatchKeyValue(ent, "targetname", targetName);

        DispatchKeyValue(ent, "parentname", tName);
        SetVariantString(tName);
        AcceptEntityInput(ent, "SetParent", witch, witch, 0);

        if (i%3 == 0) SetVariantString("forward");
        else if (i%3 == 1) SetVariantString("lhand");
        else if (i%3 == 2) SetVariantString("rhand");

        AcceptEntityInput(ent, "SetParentAttachment");

        //if (i%3 == 0)SetVector(pos2, 0.0,0.0, 55.0);
        //else if (i%3 == 1)SetVector(pos2, front,  side,up);
        //else if (i%3 == 2)SetVector(pos2, front, 0.0- side,up);

        //if (i%3 == 0)CalcOffset(p, ang, 0.0,55.0, 0.0, pos2);
        //else if (i%3 == 1)CalcOffset(p, ang, front, up, side, pos2);
        //else if (i%3 == 2)CalcOffset(p, ang, front, up, 0.0-side, pos2);

        //pos2[0]+= GetRandomFloat(-2.0, 2.0);
        //pos2[1]+= GetRandomFloat(-2.0, 2.0);
        //pos2[2]+= GetRandomFloat(-2.0, 2.0);

        //TeleportEntity(ent, pos2,NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(ent, "Enable");

        GuardWeaponEnt[GuardCount][i] = ent;
    }
    CalcOffset(pos, ang, 0.0,50.0, 0.0, pos2);

    DataPack pack;
    CreateDataTimer(fButtonTime, tmrCreateButton, pack);
    pack.WriteCell(GuardCount);
    pack.WriteCell(client);
    pack.WriteFloat(pos2[0]);
    pack.WriteFloat(pos2[1]);
    pack.WriteFloat(pos2[2]);

    GuardEntSpawned[client] = 1;
    WitchGuardEnt[GuardCount] = witch;
    GuardCount++;

    #if DEBUG
    PrintToChatAll("Created witch guard: %i", witch);
    #endif
}

public Action tWitchGlow(Handle timer, int iEntRef)
{
    if (!IsValidEntRef(iEntRef))
        return Plugin_Stop;

    int entity = EntRefToEntIndex(iEntRef);

    int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

    if (!IsValidClient(owner))
        return Plugin_Stop;

    int clientGlowColor = GetEntProp(owner, Prop_Send, "m_glowColorOverride");
    int clientGlowFlashing = GetEntProp(owner, Prop_Send, "m_bFlashing");

    if (clientGlowColor > 0)
    {
        SetEntProp(entity, Prop_Send, "m_glowColorOverride", clientGlowColor);
        SetEntProp(entity, Prop_Send, "m_bFlashing", clientGlowFlashing);
    }

    return Plugin_Continue;
}

public Action tmrCreateButton(Handle timer, DataPack pack)
{
    pack.Reset();

    int iGuardCount = pack.ReadCell();
    int client = pack.ReadCell();
    float pos2[3];
    pos2[0] = pack.ReadFloat();
    pos2[1] = pack.ReadFloat();
    pos2[2] = pack.ReadFloat();

    int b = CreateButton(pos2, client);
    GuardButton[iGuardCount] = b;
}

public Action SetTransmitSprite(int entity, int client)
{
    char tName[32];
    Format(tName, sizeof(tName), "witchguardsprite%i", client);

    char targetname[32];
    GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

    if (StrEqual(targetname, tName, false))
        return Plugin_Continue;

    return Plugin_Handled;
}

int CreateButton(float pos[3], int client)
{
    char sTemp[64];
    int button;
    bool type = false;
    if (type)button = CreateEntityByName("func_button");
    else button = CreateEntityByName("func_button_timed");

    DispatchKeyValue(button, "rendermode", "3");

    if (type)
    {
        DispatchKeyValue(button, "spawnflags", "1025");
        DispatchKeyValue(button, "wait", "1");
    }
    else
    {
        DispatchKeyValue(button, "spawnflags", "0");
        DispatchKeyValue(button, "auto_disable", "1");
        Format(sTemp, sizeof(sTemp), "%f", fButtonTime);
        DispatchKeyValue(button, "use_time", sTemp);
        Format(sTemp, sizeof(sTemp), "%N's Witch", client);
        DispatchKeyValue(button, "use_sub_string", sTemp);
        DispatchKeyValue(button, "use_string", "Witch Guard");
    }
    DispatchSpawn(button);

    SetEntityModel(button, GuardType[client] ? MODEL_GUARD2 : MODEL_GUARD1);
    int Effects = GetEntProp(button, Prop_Send, "m_fEffects");
    Effects |= 32;
    SetEntProp(button, Prop_Send, "m_fEffects", Effects);

    AcceptEntityInput(button, "Enable");
    ActivateEntity(button);

    TeleportEntity(button, pos, NULL_VECTOR, NULL_VECTOR);

    SetEntProp(button, Prop_Send, "m_nSolidType", 0, 1);
    SetEntProp(button, Prop_Send, "m_usSolidFlags", 4, 2);

    float vMins[3] = {-5.0, -5.0, -5.0}, vMaxs[3] = {10.0, 10.0, 10.0};
    SetEntPropVector(button, Prop_Send, "m_vecMins", vMins);
    SetEntPropVector(button, Prop_Send, "m_vecMaxs", vMaxs);

    SetEntPropEnt(button, Prop_Send, "m_hOwnerEntity", client);

    if (bL4D2Version)
    {
        SetEntProp(button, Prop_Data, "m_CollisionGroup", 1);
        SetEntProp(button, Prop_Send, "m_CollisionGroup", 1);
    }
    if (type)
    {
        HookSingleEntityOutput(button, "OnPressed", OnPressed);
    }
    else
    {
        SetVariantString("OnTimeUp !self:Enable::1:-1");
        AcceptEntityInput(button, "AddOutput");
        HookSingleEntityOutput(button, "OnTimeUp", OnPressed);
    }
    return button;
}

int CreateButton2(float pos[3], int client)
{
    char sTemp[64];
    int button;
    bool type = false;
    if (type)button = CreateEntityByName("func_button");
    else button = CreateEntityByName("func_button_timed");

    DispatchKeyValue(button, "rendermode", "3");

    if (type)
    {
        DispatchKeyValue(button, "spawnflags", "1025");
        DispatchKeyValue(button, "wait", "1");
    }
    else
    {
        DispatchKeyValue(button, "spawnflags", "0");
        DispatchKeyValue(button, "auto_disable", "1");
        Format(sTemp, sizeof(sTemp), "%f", fButtonTime);
        DispatchKeyValue(button, "use_time", sTemp);
        Format(sTemp, sizeof(sTemp), "%N's Witch", client);
        DispatchKeyValue(button, "use_sub_string", sTemp);
        DispatchKeyValue(button, "use_string", "Witch Guard");
    }
    DispatchSpawn(button);

    SetEntityModel(button, MODEL_GUARD1);
    int Effects = GetEntProp(button, Prop_Send, "m_fEffects");
    Effects |= 32;
    SetEntProp(button, Prop_Send, "m_fEffects", Effects);

    AcceptEntityInput(button, "Enable");
    ActivateEntity(button);

    SetVariantString("!activator");
    AcceptEntityInput(button, "SetParent", client);
    SetVariantString("forward");
    AcceptEntityInput(button, "SetParentAttachment");
    pos[0] = 5.0;
    pos[2] = -5.0;

    TeleportEntity(button, pos, NULL_VECTOR, NULL_VECTOR);

    SetEntProp(button, Prop_Send, "m_nSolidType", 0, 1);
    SetEntProp(button, Prop_Send, "m_usSolidFlags", 4, 2);

    float vMins[3] = {-5.0, -5.0, -5.0}, vMaxs[3] = {10.0, 10.0, 10.0};
    SetEntPropVector(button, Prop_Send, "m_vecMins", vMins);
    SetEntPropVector(button, Prop_Send, "m_vecMaxs", vMaxs);

    SetEntPropEnt(button, Prop_Send, "m_hOwnerEntity", client);

    if (bL4D2Version)
    {
        SetEntProp(button, Prop_Data, "m_CollisionGroup", 1);
        SetEntProp(button, Prop_Send, "m_CollisionGroup", 1);
    }
    if (type)
    {
        HookSingleEntityOutput(button, "OnPressed", OnPressed);
    }
    else
    {
        SetVariantString("OnTimeUp !self:Enable::1:-1");
        AcceptEntityInput(button, "AddOutput");
        HookSingleEntityOutput(button, "OnTimeUp", OnPressed);
    }

    AcceptEntityInput(button, "Press", client, client);
    SetVariantString("OnUser1 !self:Kill::6.5.0:1");
    AcceptEntityInput(button, "AddOutput");
    AcceptEntityInput(button, "FireUser1");

    return button;
}

public void OnPressed(const char[] output, int caller, int activator, float delay)
{
    if (IsValidClient(activator))
    {
        if (IsGuard(GuardEnt[activator]))return;

        int owner = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");

        if (l4d_witch_guard_steal.IntValue == 0 && IsValidClient(owner))
        {
            if (!IsValidClient(owner))
                return;

            if (activator != owner)
            {
                CPrintToChat(activator, "%t", "Steal_Witch", owner);
                return;
            }
        }

        AcceptEntityInput(caller, "kill");
        int find = -1;
        for(int i = 0; i<GuardCount; i++)
        {
            if (GuardButton[i] == caller)
            {
                find = i;
                break;
            }
        }
        if (find == -1)return;
        for(int i = 0; i<21; i++)
        {
            if (GuardWeaponEnt[find][i] > 0 && IsValidEntity(GuardWeaponEnt[find][i]))
                AcceptEntityInput(GuardWeaponEnt[find][i], "kill");

            GuardWeaponEnt[find][i] = 0;
        }

        if (IsValidEntity(WitchGuardEnt[find]))
        {
            int modelIndex = GetEntProp(WitchGuardEnt[find], Prop_Send, "m_nModelIndex");

            if (modelIndex == GuardModel1)
                GuardType[owner] = 0;
            else if (modelIndex == GuardModel2)
                GuardType[owner] = 1;
            else
                GuardType[owner] = 0;

            AcceptEntityInput(WitchGuardEnt[find], "kill");
        }
        GuardEntSpawned[activator] = 0;

        for(int i = find; i<GuardCount; i++)
        {
            WitchGuardEnt[i] = WitchGuardEnt[i+1];
            GuardButton[i] = GuardButton[i+1];
            for(int j = 0; j<21; j++)
            {
                GuardWeaponEnt[i][j] = GuardWeaponEnt[i+1][j];
            }
        }
        GuardCount--;
        CreateDecoration(activator, false);
        PrintHintText(activator, "%t", "Put_back"); // "you put witch on back"
    }
}

void CalcOffset(float pos[3], float ang[3], float front, float up, float right, float ret[3])
{
    float t[3];
    GetAngleVectors(ang, t, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(t, t);
    ScaleVector(t, front);
    AddVectors(pos, t, ret);

    GetAngleVectors(ang, NULL_VECTOR,t, NULL_VECTOR);
    NormalizeVector(t, t);
    ScaleVector(t, right);
    AddVectors(ret, t, ret);

    GetAngleVectors(ang, NULL_VECTOR,NULL_VECTOR, t);
    NormalizeVector(t, t);
    ScaleVector(t, up);
    AddVectors(ret, t, ret);
}

public void PreThinkClient(int client)
{
    if (GuardEnt[client] == 0)return;
    int button = GetClientButtons(client);

    if (button & IN_USE)
    {
        int targetRevive = GetEntPropEnt(client, Prop_Send, "m_reviveTarget");

        if (targetRevive != -1)
        {
            PressTime[client] = GetEngineTime();
            return;
        }

        if (bL4D2Version)
        {
            int targetUseAction = GetEntPropEnt(client, Prop_Send, "m_useActionTarget");

            if (targetUseAction != -1)
            {
                PressTime[client] = GetEngineTime();
                return;
            }
        }

        if (!(GetEntityFlags(client) & FL_ONGROUND))
            return;

        if (!ClientIN_USE[client])
        {
            if (bL4D2Version)
            {
                if (l4d_witch_guard_showbar.IntValue == 1)
                {
                    SetupProgressBar(client, fButtonTime);

                    float position[3];
                    GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
                    CreateButton2(position, client);
                }
            }
            ClientIN_USE[client] = true;
        }

        if (GetEngineTime() - PressTime[client] > fButtonTime)
        {
            ClientIN_USE[client] = false;
            DeleteDecoration(client);
            CreateGuard(client);
            PrintHintText(client, "%t", "Put_down"); // "you put witch down"
        }
    }
    else
    {
        if (ClientIN_USE[client])
        {
            if (bL4D2Version)
            {
                if (l4d_witch_guard_showbar.IntValue == 1)
                    KillProgressBar(client);
            }
        }

        ClientIN_USE[client] = false;
        PressTime[client] = GetEngineTime();
    }

}

//public Action TimerAnimWitch(Handle timer, any client)
//{
//    if (IsGuard(GuardEnt[client]))
//    {
//        if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == L4DTEAM_SURVIVOR)
//        {
//            int anim = Anim[ GetRandomInt(0,AnimCount-1) ];
//
//            float ang[3];
//            SetVector(ang, 0.0, 0.0, 90.0);
//            float pos[3];
//            pos[0] = OffSets[anim][0];
//            pos[1] = OffSets[anim][1];
//
//            TeleportEntity(GuardEnt[client], pos, ang, NULL_VECTOR);
//
//            SetEntProp(GuardEnt[client], Prop_Send, "m_nSequence", anim);
//            SetEntPropFloat(GuardEnt[client], Prop_Send, "m_flPlaybackRate", 1.0);
//
//            return Plugin_Continue;
//        }
//        else
//        {
//            DeleteDecoration(client);
//        }
//    }
//    GuardEnt[client] = 0;
//    return Plugin_Stop;
//}

public Action Hook_SetTransmit(int entity, int client)
{
    if (GuardViewOff[client])
        return Plugin_Handled;

    if (entity == GuardEnt[client])
    {
        if (IsSurvivorThirdPerson(client, false))
            return Plugin_Continue;
        else
            return Plugin_Handled;
    }
    return Plugin_Continue;
}
void SetVector(float target[3], float x, float y, float z)
{
    target[0] = x;
    target[1] = y;
    target[2] = z;
}

public void OnClientPutInServer(int iClient)
{
    bThirdPersonFix[iClient] = true;
}

public void eSurvivorRescued(Event hEvent, char[] sName, bool bDontBroadcast)
{
    static int iClient;
    iClient = GetClientOfUserId(hEvent.GetInt("victim"));

    if (!IsValidClient(iClient) || IsFakeClient(iClient))
        return;

    bThirdPersonFix[iClient] = true;
}

public void eTeamChange(Event hEvent, char[] sName, bool bDontBroadcast)
{
    static int iClient;
    iClient = GetClientOfUserId(hEvent.GetInt("userid"));

    if (!IsValidClient(iClient) || IsFakeClient(iClient))
        return;

    bThirdPersonFix[iClient] = true;
}

bool IsValidClient(int iClient)
{
    return (iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient));
}

stock void CPrintToChat(int client, const char[] format, any ...)
{
    char buffer[192];
    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), format, 3);
    ReplaceColor(buffer, sizeof(buffer));
    PrintToChat(client, "\x01%s", buffer);
}

stock void CPrintToChatAll(const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && !IsFakeClient(i))
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            ReplaceColor(buffer, sizeof(buffer));
            PrintToChat(i, "\x01%s", buffer);
        }
    }
}

stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}

bool IsGuard(int ent)
{
    if (ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
        return true;

    return false;
}

stock bool IsGuardEntity(int iEntity)
{
    if (IsValidEntity(iEntity))
    {
        char sClassname[64];
        GetEntityClassname(iEntity, sClassname, sizeof(sClassname));
        return StrEqual(sClassname, "witch");
    }
    return false;
}

stock int GetRandomPlayer(int attacker)
{
    int tempAttacker;
    int tempAttacker2;
    int tempAttacker3;

    for(int client = 1; client <= MaxClients; client++)
    {
        tempAttacker = client;

        if (!IsValidClient(tempAttacker))
            continue;

        if (GetClientTeam(tempAttacker) != 2)
            continue;

        if (!IsPlayerAlive(tempAttacker))
            continue;

        if (l4d_witch_guard_bots.IntValue == 0 && IsValidClient(tempAttacker) && IsFakeClient(tempAttacker))
            continue;

        if (l4d_witch_guard_give_random.IntValue == 1)
        {
            if (IsGuard(GuardEnt[tempAttacker]) || GuardEntSpawned[tempAttacker] == 1)
            {
                if (GuardEntSpawned[tempAttacker] == 1 && tempAttacker3 == 0)
                    tempAttacker3 = tempAttacker;

                continue;
            }
        }

        if (l4d_witch_guard_prioritize_human_players.IntValue == 1 && IsFakeClient(tempAttacker))
        {
            if (tempAttacker2 == 0)
                tempAttacker2 = tempAttacker;

            continue;
        }

        attacker = tempAttacker;
        break;
    }

    if (attacker == 0 && tempAttacker2 != 0)
        attacker = tempAttacker2;

    if (attacker == 0 && tempAttacker3 != 0)
        attacker = tempAttacker3;

    return attacker;
}

stock bool IsSurvivorThirdPerson(int iClient, bool bSpecCheck)
{
    if (bL4D2Version)
        return IsSurvivorThirdPersonL4D2(iClient, bSpecCheck);
    else
        return IsSurvivorThirdPersonL4D1(iClient, bSpecCheck);
}

stock bool IsSurvivorThirdPersonL4D1(int iClient, bool bSpecCheck)
{
    if (IsFakeClient(iClient))
        return false;

    if (!bSpecCheck)
    {
        if (GetEntProp(iClient, Prop_Send, "m_iObserverMode") == 1)
            return true;
    }
    if (GetEntPropEnt(iClient, Prop_Send, "m_hViewEntity") > 0)
        return true;
    if (GetEntPropEnt(iClient, Prop_Send, "m_pounceAttacker") > 0)
        return true;
    if (GetEntProp(iClient, Prop_Send, "m_isHangingFromLedge") > 0)
        return true;
    if (GetEntPropEnt(iClient, Prop_Send, "m_reviveTarget") > 0)
        return true;
    if (GetEntPropEnt(iClient, Prop_Send, "m_healTarget") > 0)
        return true;
    if (GetEntPropFloat(iClient, Prop_Send, "m_staggerTimer", 1) > GetGameTime())
        return true;

    static char sModel[31];
    GetEntPropString(iClient, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

    switch(sModel[29])
    {
        case 'v'://bill
        {
            switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
            {
                case 535, 537, 539, 540, 541:
                    return true;
            }
        }
        case 'n'://zoey
        {
            switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
            {
                case 517, 519, 521, 522, 523:
                    return true;
            }
        }
        case 'e'://francis
        {
            switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
            {
                case 536, 538, 540, 541, 542:
                    return true;
            }
        }
        case 'a'://louis
        {
            switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
            {
                case 535, 537, 539, 540, 541:
                    return true;
            }
        }
    }
    return false;
}

stock bool IsSurvivorThirdPersonL4D2(int iClient, bool bSpecCheck)
{
    if (IsFakeClient(iClient))
        return false;

    if (!bSpecCheck)
    {
        if (GetEntProp(iClient, Prop_Send, "m_iObserverMode") == 1)
            return true;
    }
    if (GetEntPropEnt(iClient, Prop_Send, "m_hViewEntity") > 0)
        return true;
    if (GetEntPropFloat(iClient, Prop_Send, "m_TimeForceExternalView") > GetGameTime())
        return true;
    if (GetEntPropEnt(iClient, Prop_Send, "m_pummelAttacker") > 0)
        return true;
    if (GetEntPropEnt(iClient, Prop_Send, "m_carryAttacker") > 0)
        return true;
    if (GetEntPropEnt(iClient, Prop_Send, "m_pounceAttacker") > 0)
        return true;
    if (GetEntPropEnt(iClient, Prop_Send, "m_jockeyAttacker") > 0)
        return true;
    if (GetEntProp(iClient, Prop_Send, "m_isHangingFromLedge") > 0)
        return true;
    if (GetEntPropEnt(iClient, Prop_Send, "m_reviveTarget") > 0)
        return true;
    if (GetEntPropFloat(iClient, Prop_Send, "m_staggerTimer", 1) > -1.0)
        return true;

    switch(GetEntProp(iClient, Prop_Send, "m_iCurrentUseAction"))
    {
        case 1:
        {
            static int iTarget;
            iTarget = GetEntPropEnt(iClient, Prop_Send, "m_useActionTarget");

            if (iTarget == GetEntPropEnt(iClient, Prop_Send, "m_useActionOwner"))
                    return true;
            else if (iTarget != iClient)
                    return true;
        }
        case 4, 5, 6, 7, 8, 9, 10:
            return true;
    }

    static char sModel[31];
    GetEntPropString(iClient, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

    switch(sModel[29])
    {
        case 'b'://nick
        {
            switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
            {
                case 626, 625, 624, 623, 622, 621, 661, 662, 664, 665, 666, 667, 668, 670, 671, 672, 673, 674, 620, 680, 616:
                    return true;
            }
        }
        case 'd', 'w'://rochelle, adawong
        {
            switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
            {
                case 674, 678, 679, 630, 631, 632, 633, 634, 668, 677, 681, 680, 676, 675, 673, 672, 671, 670, 687, 629, 625, 616:
                    return true;
            }
        }
        case 'c'://coach
        {
            switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
            {
                case 656, 622, 623, 624, 625, 626, 663, 662, 661, 660, 659, 658, 657, 654, 653, 652, 651, 621, 620, 669, 615:
                    return true;
            }
        }
        case 'h'://ellis
        {
            switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
            {
                case 625, 675, 626, 627, 628, 629, 630, 631, 678, 677, 676, 575, 674, 673, 672, 671, 670, 669, 668, 667, 666, 665, 684, 621:
                    return true;
            }
        }
        case 'v'://bill
        {
            switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
            {
                case 528, 759, 763, 764, 529, 530, 531, 532, 533, 534, 753, 676, 675, 761, 758, 757, 756, 755, 754, 527, 772, 762, 522:
                    return true;
            }
        }
        case 'n'://zoey
        {
            switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
            {
                case 537, 819, 823, 824, 538, 539, 540, 541, 542, 543, 813, 828, 825, 822, 821, 820, 818, 817, 816, 815, 814, 536, 809, 572:
                    return true;
            }
        }
        case 'e'://francis
        {
            switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
            {
                case 532, 533, 534, 535, 536, 537, 769, 768, 767, 766, 765, 764, 763, 762, 761, 760, 759, 758, 757, 756, 531, 530, 775, 525:
                    return true;
            }
        }
        case 'a'://louis
        {
            switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
            {
                case 529, 530, 531, 532, 533, 534, 766, 765, 764, 763, 762, 761, 760, 759, 758, 757, 756, 755, 754, 753, 527, 772, 528, 522:
                    return true;
            }
        }
    }
    return false;
}

stock void SetupProgressBar(int client, float time)
{
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", time);
}

stock void KillProgressBar(int client)
{
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
    SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
}

/**
 * Validates if is a valid entity reference.
 *
 * @param client        Entity reference.
 * @return                True if entity reference is valid, false otherwise.
 */
bool IsValidEntRef(int iEntRef)
{
    return iEntRef != 0 && EntRefToEntIndex(iEntRef) != INVALID_ENT_REFERENCE;
}

public int SortByDamageDesc(int[] x, int[] y, const int[][] array, Handle data)
{
    if (x[0] > y[0])
        return -1;

    if (x[0] < y[0])
        return 1;

    return 0;
}

/** Codes above copied from "Silvers [L4D & L4D2] Achievement Trophy" Plugin */
float g_fCvarThird = 1.5;
int g_iCvarSound = 3;
int g_iCvarEffects = 3;
float g_fCvarWait = 3.5;
float g_fCvarTime = 3.5;

void CreateEffects(int client, bool event)
{
    if (client && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) != 1)
    {
        // Thirdperson view
        if (bL4D2Version && g_fCvarThird != 0.0)
        {
            // Survivor Thirdperson plugin sets 99999.3.
            if (GetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView") != 99999.3)
                SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", GetGameTime() + g_fCvarThird);
        }

        // Sound
        if (g_iCvarSound == 3 || (!event && g_iCvarSound == 1) || (event && g_iCvarSound == 2))
        {
            EmitSoundToAll(SOUND_ACHIEVEMENT, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
        }

        // Effect
        int entity;
        if (g_iCvarEffects == 3 || g_iCvarEffects == 1)
        {
            entity = CreateEntityByName("info_particle_system");
            if (entity != INVALID_ENT_REFERENCE)
            {
                DispatchKeyValue(entity, "effect_name", PARTICLE_ACHIEVED);
                DispatchSpawn(entity);
                ActivateEntity(entity);
                AcceptEntityInput(entity, "start");

                // Attach to survivor
                SetVariantString("!activator");
                AcceptEntityInput(entity, "SetParent", client);
                TeleportEntity(entity, view_as<float>({ 0.0, 0.0, 50.0 }), NULL_VECTOR, NULL_VECTOR);

                // Loop
                char sTemp[64];
                SetVariantString("OnUser1 !self:Start::0.0:-1");
                AcceptEntityInput(entity, "AddOutput");
                Format(sTemp, sizeof(sTemp), "OnUser2 !self:Stop::%f:-1", g_fCvarWait);
                SetVariantString(sTemp);
                AcceptEntityInput(entity, "AddOutput");
                Format(sTemp, sizeof(sTemp), "OnUser2 !self:FireUser1::%f:-1", g_fCvarWait + 0.1);
                SetVariantString(sTemp);
                AcceptEntityInput(entity, "AddOutput");
                Format(sTemp, sizeof(sTemp), "OnUser2 !self:FireUser2::%f:-1", g_fCvarWait + 0.1);
                SetVariantString(sTemp);
                AcceptEntityInput(entity, "AddOutput");

                AcceptEntityInput(entity, "FireUser1");
                AcceptEntityInput(entity, "FireUser2");

                // Remove
                Format(sTemp, sizeof(sTemp), "OnUser3 !self:Kill::%f:-1", g_fCvarTime);
                SetVariantString(sTemp);
                AcceptEntityInput(entity, "AddOutput");
                AcceptEntityInput(entity, "FireUser3");
            }
        }

        if (g_iCvarEffects == 3 || g_iCvarEffects == 2)
        {
            entity = CreateEntityByName("info_particle_system");
            {
                DispatchKeyValue(entity, "effect_name", PARTICLE_FIREWORK);
                DispatchSpawn(entity);
                ActivateEntity(entity);
                AcceptEntityInput(entity, "start");

                // Attach to survivor
                SetVariantString("!activator");
                AcceptEntityInput(entity, "SetParent", client);
                TeleportEntity(entity, view_as<float>({ 0.0, 0.0, 50.0 }), NULL_VECTOR, NULL_VECTOR);

                // Loop
                char sTemp[64];
                SetVariantString("OnUser1 !self:Start::0.0:-1");
                AcceptEntityInput(entity, "AddOutput");
                SetVariantString("OnUser2 !self:Stop::4.0:-1");
                AcceptEntityInput(entity, "AddOutput");
                SetVariantString("OnUser2 !self:FireUser1::4.0:-1");
                AcceptEntityInput(entity, "AddOutput");

                AcceptEntityInput(entity, "FireUser1");
                AcceptEntityInput(entity, "FireUser2");

                // Remove
                Format(sTemp, sizeof(sTemp), "OnUser3 !self:Kill::%f:-1", g_fCvarTime);
                SetVariantString(sTemp);
                AcceptEntityInput(entity, "AddOutput");
                AcceptEntityInput(entity, "FireUser3");
            }
        }
    }
}

void PrecacheParticle(const char[] sEffectName)
{
    static int table = INVALID_STRING_TABLE;

    if (table == INVALID_STRING_TABLE)
    {
        table = FindStringTable("ParticleEffectNames");
    }

    if (FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX)
    {
        bool save = LockStringTables(false);
        AddToStringTable(table, sEffectName);
        LockStringTables(save);
    }
}

/****************************************************************************************************/

bool IsAllowedMap()
{
    char sMap[256], sMaps[256];
    Format(sMap, sizeof(sMap), ",%s,", sCurrentMap);

    GetConVarString(l4d_witch_guard_mapson, sCvar_MapsOn, sizeof(sCvar_MapsOn));
    GetConVarString(l4d_witch_guard_mapsoff, sCvar_MapsOff, sizeof(sCvar_MapsOff));
    ReplaceString(sCvar_MapsOn, sizeof(sCvar_MapsOn), " ", "", false);
    ReplaceString(sCvar_MapsOff, sizeof(sCvar_MapsOff), " ", "", false);

    strcopy(sMaps, sizeof(sMaps), sCvar_MapsOn);
    if (!StrEqual(sMaps, "", false))
    {
        Format(sMaps, sizeof(sMaps), ",%s,", sMaps);
        if (StrContains(sMaps, sMap, false) == -1)
            return false;
    }

    strcopy(sMaps, sizeof(sMaps), sCvar_MapsOff);
    if (!StrEqual(sMaps, "", false))
    {
        Format(sMaps, sizeof(sMaps), ",%s,", sMaps);
        if (StrContains(sMaps, sMap, false) != -1)
            return false;
    }

    return true;
}

/****************************************************************************************************/

/**
 * Validates if the current game mode is valid to run the plugin.
 *
 * @return              True if game mode is valid, false otherwise.
 */
bool IsAllowedGameMode()
{
    if (hCvar_MPGameMode == null)
        return false;

    if (iCvar_GameModesToggle != 0)
    {
        int entity = CreateEntityByName("info_gamemode");
        if (entity == -1)
        {
            LogError("Failed to create 'info_gamemode' entity");
            return false;
        }

        DispatchSpawn(entity);
        HookSingleEntityOutput(entity, "OnCoop", OnGameMode, true);
        HookSingleEntityOutput(entity, "OnSurvival", OnGameMode, true);
        HookSingleEntityOutput(entity, "OnVersus", OnGameMode, true);
        HookSingleEntityOutput(entity, "OnScavenge", OnGameMode, true);
        ActivateEntity(entity);
        AcceptEntityInput(entity, "PostSpawnActivate");
        AcceptEntityInput(entity, "Kill");

        if (iCvar_CurrentMode == 0)
            return false;

        if (!(iCvar_GameModesToggle & iCvar_CurrentMode))
            return false;
    }

    char sGameMode[256], sGameModes[256];
    Format(sGameMode, sizeof(sGameMode), ",%s,", sCvar_MPGameMode);

    strcopy(sGameModes, sizeof(sGameModes), sCvar_GameModesOn);
    if (!StrEqual(sGameModes, "", false))
    {
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if (StrContains(sGameModes, sGameMode, false) == -1)
            return false;
    }

    strcopy(sGameModes, sizeof(sGameModes), sCvar_GameModesOff);
    if (!StrEqual(sGameModes, "", false))
    {
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if (StrContains(sGameModes, sGameMode, false) != -1)
            return false;
    }

    return true;
}

/****************************************************************************************************/

/**
 * Sets the running game mode int value.
 *
 * @param output        output.
 * @param caller        caller.
 * @param activator     activator.
 * @param delay         delay.
 * @noreturn
 */
int OnGameMode(const char[] output, int caller, int activator, float delay)
{
    if (StrEqual(output, "OnCoop", false))
        iCvar_CurrentMode = 1;
    else if (StrEqual(output, "OnSurvival", false))
        iCvar_CurrentMode = 2;
    else if (StrEqual(output, "OnVersus", false))
        iCvar_CurrentMode = 4;
    else if (StrEqual(output, "OnScavenge", false))
        iCvar_CurrentMode = 8;
    else
        iCvar_CurrentMode = 0;
}

/****************************************************************************************************/