/**
 * vim: set ai et ts=4 sw=4 :
 * File: tripmines.sp
 * Description: Tripmines for TF2
 * Author(s): L. Duke
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION  "4.0"

#define MAXENTITIES     2048

#define MAX_LINE_LEN    256

#define TRACE_START     24.0
#define TRACE_END       64.0

#define LASER_SPRITE    "sprites/laser.vmt"

// settings for m_takedamage
#define	DAMAGE_NO				0
#define DAMAGE_EVENTS_ONLY		1		// Call damage functions, but don't modify health
#define	DAMAGE_YES				2
#define	DAMAGE_AIM				3

new const String:gSndBuy[]                    = "items/itempickup.wav";
new const String:gSndError[]                  = "common/wpn_denyselect.wav";
new const String:gSndCantBuy[]                = "buttons/weapon_cant_buy.wav";

new String:gSndPlaced[PLATFORM_MAX_PATH]      = "npc/roller/blade_cut.wav";
new String:gSndActivated[PLATFORM_MAX_PATH]   = "npc/roller/mine/rmine_blades_in2.wav";
new String:gSndReactivated[PLATFORM_MAX_PATH] = "npc/roller/mine/rmine_blades_in2.wav";
new String:gSndRemoved[PLATFORM_MAX_PATH]     = "ui/hint.wav";

// Colors
new String:gMineColor[4][16] = { "255 255 255", // Unassigned
                                 "0 255 255",   // Spectator
                                 "255 0 0",     // Red  / Allies / Terrorists
                                 "0 0 255"      // Blue / Axis   / Counter-Terrorists
                               };

new String:gBeamColor[4][16] = { "255 255 255", // Unassigned
                                 "0 255 255",   // Spectator
                                 "255 0 0",     // Red  / Allies / Terrorists
                                 "0 0 255"      // Blue / Axis   / Counter-Terrorists
                               };

// globals
new gRemaining[MAXPLAYERS+1];    // how many tripmines player has this spawn
new gMaximum[MAXPLAYERS+1];      // how many tripmines player can have active at once
new gCount = 1;

new gTeamSpecific = 1;
new bool:gAllowSpectators = false;
new bool:gTouch = false;

// for buy
new gInBuyZone = -1;
new gAccount = -1;

new bool:gNativeControl = false;
new bool:gChangingClass[MAXPLAYERS+1];
new gAllowed[MAXPLAYERS+1];    // how many tripmines player allowed

new gTripmineModelIndex;
new gLaserModelIndex;

new g_SavedEntityRef[MAXENTITIES+1];
new g_TripmineOfBeam[MAXENTITIES+1];

new String:mdlMine[256] = "models/props_lab/tpplug.mdl";

// forwards
new Handle:fwdOnSetTripmine;

// convars
new Handle:cvActTime = INVALID_HANDLE;
new Handle:cvReactTime = INVALID_HANDLE;
new Handle:cvModel = INVALID_HANDLE;
new Handle:cvMineCost = INVALID_HANDLE;
new Handle:cvAllowSpectators = INVALID_HANDLE;
new Handle:cvTeamRestricted = INVALID_HANDLE;
new Handle:cvTeamSpecific = INVALID_HANDLE;
new Handle:cvAdmin = INVALID_HANDLE;
new Handle:cvRadius = INVALID_HANDLE;
new Handle:cvDamage = INVALID_HANDLE;
new Handle:cvHealth = INVALID_HANDLE;
new Handle:cvType = INVALID_HANDLE;
new Handle:cvStay = INVALID_HANDLE;
new Handle:cvTouch = INVALID_HANDLE;
new Handle:cvFriendlyFire = INVALID_HANDLE;

new Handle:cvPlacedSound = INVALID_HANDLE;
new Handle:cvActivatedSound = INVALID_HANDLE;
new Handle:cvReactivatedSound = INVALID_HANDLE;
new Handle:cvRemovedSound = INVALID_HANDLE;

new Handle:cvMaxMines = INVALID_HANDLE;
new Handle:cvNumMines = INVALID_HANDLE;
new Handle:cvNumMinesScout = INVALID_HANDLE;
new Handle:cvNumMinesSniper = INVALID_HANDLE;
new Handle:cvNumMinesSoldier = INVALID_HANDLE;
new Handle:cvNumMinesDemoman = INVALID_HANDLE;
new Handle:cvNumMinesMedic = INVALID_HANDLE;
new Handle:cvNumMinesHeavy = INVALID_HANDLE;
new Handle:cvNumMinesPyro = INVALID_HANDLE;
new Handle:cvNumMinesSpy = INVALID_HANDLE;
new Handle:cvNumMinesEngi = INVALID_HANDLE;

new Handle:cvBeamColor[4] = { INVALID_HANDLE, ... };
new Handle:cvMineColor[4] = { INVALID_HANDLE, ... };

public Plugin:myinfo = {
    name = "Tripmines",
    author = "L. Duke and Naris",
    description = "Plant a trip mine",
    version = PLUGIN_VERSION,
    url = "http://www.lduke.com/"
};

/**
 * Description: Function to determine game/mod type
 */
#tryinclude <gametype>
#if !defined _gametype_included
    enum Game { undetected, tf2, cstrike, dod, hl2mp, insurgency, zps, l4d, l4d2, other_game };
    stock Game:GameType = undetected;

    stock Game:GetGameType()
    {
        if (GameType == undetected)
        {
            new String:modname[30];
            GetGameFolderName(modname, sizeof(modname));
            if (StrEqual(modname,"cstrike",false))
                GameType=cstrike;
            else if (StrEqual(modname,"tf",false)) 
                GameType=tf2;
            else if (StrEqual(modname,"dod",false)) 
                GameType=dod;
            else if (StrEqual(modname,"hl2mp",false)) 
                GameType=hl2mp;
            else if (StrEqual(modname,"Insurgency",false)) 
                GameType=insurgency;
            else if (StrEqual(modname,"left4dead", false)) 
                GameType=l4d;
            else if (StrEqual(modname,"left4dead2", false)) 
                GameType=l4d2;
            else if (StrEqual(modname,"zps",false)) 
                GameType=zps;
            else
                GameType=other_game;
        }
        return GameType;
    }
#endif

/**
 * Description: Function to check the entity limit.
 *              Use before spawning an entity.
 */
#tryinclude <entlimit>
#if !defined _entlimit_included
    stock bool:IsEntLimitReached(warn=20,critical=16,client=0,const String:message[]="")
    {
        return (EntitiesAvailable(warn,critical,client,message) < warn);
    }

    stock EntitiesAvailable(warn=20,critical=16,client=0,const String:message[]="")
    {
        new max = GetMaxEntities();
        new count = GetEntityCount();
        new remaining = max - count;
        if (remaining <= critical)
        {
            PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
            LogError("Entity limit is nearly reached: %d/%d (%d):%s", count, max, remaining, message);

            if (client > 0)
            {
                PrintToConsole(client, "Entity limit is nearly reached: %d/%d (%d):%s",
                               count, max, remaining, message);
            }
        }
        else if (remaining <= warn)
        {
            PrintToServer("Caution: Entity count is getting high!");
            LogMessage("Entity count is getting high: %d/%d (%d):%s", count, max, remaining, message);

            if (client > 0)
            {
                PrintToConsole(client, "Entity count is getting high: %d/%d (%d):%s",
                               count, max, remaining, message);
            }
        }
        return remaining;
    }
#endif

/**
 * Description: Manage precaching resources.
 */
#tryinclude "ResourceManager"
#if !defined _ResourceManager_included
	// Trie to hold precache status of sounds
	new Handle:g_precacheTrie = INVALID_HANDLE;

	stock PrepareSound(const String:sound[], bool:preload=false)
	{
    		// If the sound hasn't been played yet, precache it first
    		// :( IsSoundPrecached() doesn't work ):
    		//if (!IsSoundPrecached(sound))
    		new bool:value;
    		if (!GetTrieValue(g_precacheTrie, sound, value))
    		{
			    PrecacheSound(sound,preload);
			    SetTrieValue(g_precacheTrie, sound, true);
    		}
	}

	stock SetupSound(const String:sound[], download=1,
	                  bool:precache=false, bool:preload=false)
	{
		decl String:dl[PLATFORM_MAX_PATH+1];
		Format(dl, sizeof(dl), "sound/%s", sound);

		if (download && FileExists(dl))
            AddFileToDownloadsTable(dl);

		if (precache)
			PrecacheSound(sound, preload);
	}

    stock SetupModel(const String:model[], &index, bool:download,
                     bool:precache, bool:preload=false)
    {
        if (download && FileExists(model))
            AddFileToDownloadsTable(model);

        if (precache)
            index = PrecacheModel(model,preload);
        else
            index = 0;
    }

    stock PrepareModel(const String:model[], &index, bool:preload=false)
    {
        if (index <= 0)
            index = PrecacheModel(model,preload);

        return index;
    }
#endif

/**
 * Description: Stocks to return information about TF2 player condition, etc.
 */
#tryinclude <tf2_player>
#if !defined _tf2_player_included
    #define TF2_IsDisguised(%1)         (((%1) & TF_CONDFLAG_DISGUISED) != TF_CONDFLAG_NONE)
    #define TF2_IsCloaked(%1)           (((%1) & TF_CONDFLAG_CLOAKED) != TF_CONDFLAG_NONE)
    #define TF2_IsUbercharged(%1)       (((%1) & TF_CONDFLAG_UBERCHARGED) != TF_CONDFLAG_NONE)
    #define TF2_IsBonked(%1)            (((%1) & TF_CONDFLAG_BONKED) != TF_CONDFLAG_NONE)
    #define TF2_IsDeadRingered(%1)      (((%1) & TF_CONDFLAG_DEADRINGERED) != TF_CONDFLAG_NONE)

    #define TF2_IsPlayerUbercharged(%1) TF2_IsUbercharged(TF2_GetPlayerConditionFlags(%1))
    #define TF2_IsPlayerBonked(%1)      TF2_IsBonked(TF2_GetPlayerConditionFlags(%1))
#endif

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    // Register Natives
    CreateNative("ControlTripmines",Native_ControlTripmines);
    CreateNative("GiveTripmines",Native_GiveTripmines);
    CreateNative("TakeTripmines",Native_TakeTripmines);
    CreateNative("AddTripmines",Native_AddTripmines);
    CreateNative("SubTripmines",Native_SubTripmines);
    CreateNative("HasTripmines",Native_HasTripmines);
    CreateNative("SetTripmine",Native_SetTripmine);
    CreateNative("CountTripmines",Native_CountTripmines);

    // Register Forwards
    fwdOnSetTripmine=CreateGlobalForward("OnSetTripmine",ET_Hook,Param_Cell);

    RegPluginLibrary("tripmines");
    return APLRes_Success;
}

public OnPluginStart()
{
    // translations
    LoadTranslations("plugin.tripmines"); 

    // events
    HookEvent("player_death", PlayerDeath);
    HookEvent("player_spawn", PlayerSpawn);

    switch (GetGameType())
    {
        case tf2:
        {
            HookEvent("arena_win_panel", RoundEnd);
            HookEvent("teamplay_round_win", RoundEnd);
            HookEvent("teamplay_round_stalemate", RoundEnd);
            HookEvent("player_changeclass", PlayerChange);

            cvNumMinesScout = CreateConVar("sm_tripmines_scout_limit", "-1", "Number of tripmines allowed per life for Scouts (-1=use generic variable)");
            cvNumMinesSniper = CreateConVar("sm_tripmines_sniper_limit", "-1", "Number of tripmines allowed per life for Snipers");
            cvNumMinesSoldier = CreateConVar("sm_tripmines_soldier_limit", "-1", "Number of tripmines allowed per life For Soldiers");
            cvNumMinesDemoman = CreateConVar("sm_tripmines_demoman_limit", "-1", "Number of tripmines allowed per life for Demomen");
            cvNumMinesMedic = CreateConVar("sm_tripmines_medic_limit", "-1", "Number of tripmines allowed per life for Medics");
            cvNumMinesHeavy = CreateConVar("sm_tripmines_heavy_limit", "-1", "Number of tripmines allowed per life for Heavys");
            cvNumMinesPyro = CreateConVar("sm_tripmines_pyro_limit", "-1", "Number of tripmines allowed per life for Pyros");
            cvNumMinesSpy = CreateConVar("sm_tripmines_spy_limit", "-1", "Number of tripmines allowed per life for Spys");
            cvNumMinesEngi = CreateConVar("sm_tripmines_engi_limit", "-1", "Number of tripmines allowed per life for Engineers");
        }
        case dod:
        {
            HookEvent("dod_round_win", RoundEnd);
            HookEvent("dod_game_over", RoundEnd);
        }
        case cstrike:
        {
            HookEvent("round_end", RoundEnd);

            cvMineCost = CreateConVar("sm_tripmines_cost", "50", "Price to purchase Tripmines in Counter-Strike (0=give mines at round start,-1=also disable buying mines)");

            // prop offset
            gInBuyZone = FindSendPropOffs("CCSPlayer", "m_bInBuyZone");
            gAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
            RegConsoleCmd("sm_buytripmines", Command_BuyTripMines);
        }
        default:
        {
            HookEvent("round_end", RoundEnd);
        }
    }

    // convars
    CreateConVar("sm_tripmines_version", PLUGIN_VERSION, "Tripmines", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    cvActTime = CreateConVar("sm_tripmines_activate_time", "2.0", "Tripmine activation time.");
    cvReactTime = CreateConVar("sm_tripmines_reactivate_time", "0.0", "Tripmine reactivation time, after touched by a teammate (0.0=instant).");
    cvModel = CreateConVar("sm_tripmines_model", mdlMine, "Tripmine model");
    cvAllowSpectators = CreateConVar("sm_tripmines_allowspec", "0", "Allow spectators to use tripmines", _, true, 0.0, true, 3.0);
    cvTeamRestricted = CreateConVar("sm_tripmines_restrictedteam", "0", "Team that does NOT get any tripmines", _, true, 0.0, true, 3.0);
    cvTeamSpecific = CreateConVar("sm_tripmines_teamspecific", "1", "Allow teammates of planter to pass (0=no|1=yes|2=also allow planter to pass)", _, true, 0.0, true, 2.0);
    cvAdmin = CreateConVar("sm_tripmines_admin", "", "Admin flag required to use tripmines (empty=anyone can use tripmines)");
    cvType = CreateConVar("sm_tripmines_type","1","Explosion type of Tripmines (0=normal explosion|1=fire explosion)", _, true, 0.0, true, 1.0);
    cvStay = CreateConVar("sm_tripmines_stay","1","Tripmines stay if the owner dies. (0=no|1=yes|2=destruct)", _, true, 0.0, true, 2.0);
    cvTouch = CreateConVar("sm_tripmines_touch","0","Tripmines explode when touched. (0=no|1=yes)", _, true, 0.0, true, 1.0);
    cvRadius = CreateConVar("sm_tripmines_radius", "256.0", "Tripmines Explosion Radius");
    cvDamage = CreateConVar("sm_tripmines_damage", "200", "Tripmines Explosion Damage");
    cvHealth = CreateConVar("sm_tripmines_health", "10", "Tripmines Health");

    cvFriendlyFire = FindConVar("mp_friendlyfire");

    cvPlacedSound = CreateConVar("sm_tripmines_placed_sound", gSndPlaced, "Sound when a tripmine is placed");
    cvRemovedSound = CreateConVar("sm_tripmines_removed_sound", gSndRemoved, "Sound when a tripmine is removed");
    cvActivatedSound = CreateConVar("sm_tripmines_activated_sound", gSndActivated, "Sound when a tripmine is activated");
    cvReactivatedSound = CreateConVar("sm_tripmines_reactivated_sound", gSndReactivated, "Sound when a tripmine is reactivated, after touched by a teammate");

    cvMineColor[1] = CreateConVar("sm_tripmines_mine_color_1", gMineColor[1], "Mine Color (can include alpha) for team 1 (Spectators)");
    cvMineColor[2] = CreateConVar("sm_tripmines_mine_color_2", gMineColor[2], "Mine Color (can include alpha) for team 2 (Red  / Allies / Terrorists)");
    cvMineColor[3] = CreateConVar("sm_tripmines_mine_color_3", gMineColor[3], "Mine Color (can include alpha) for team 3 (Blue / Axis   / Counter-Terrorists)");

    cvBeamColor[1] = CreateConVar("sm_tripmines_beam_color_1", gBeamColor[1], "Beam Color (can include alpha) for team 1 (Spectators)");
    cvBeamColor[2] = CreateConVar("sm_tripmines_beam_color_2", gBeamColor[2], "Beam Color (can include alpha) for team 2 (Red  / Allies / Terrorists)");
    cvBeamColor[3] = CreateConVar("sm_tripmines_beam_color_3", gBeamColor[3], "Beam Color (can include alpha) for team 3 (Blue / Axis   / Counter-Terrorists)");

    cvMaxMines = CreateConVar("sm_tripmines_maximum", "6", "Maximum Number of tripmines allowed to be active per client (-1=unlimited)");
    cvNumMines = CreateConVar("sm_tripmines_allowed", "3", "Number of tripmines allowed per life (-1=unlimited)");

    HookConVarChange(cvPlacedSound, CvarChange);
    HookConVarChange(cvRemovedSound, CvarChange);
    HookConVarChange(cvActivatedSound, CvarChange);
    HookConVarChange(cvReactivatedSound, CvarChange);
    HookConVarChange(cvAllowSpectators, CvarChange);
    HookConVarChange(cvTeamSpecific, CvarChange);
    HookConVarChange(cvMineColor[1], CvarChange);
    HookConVarChange(cvMineColor[2], CvarChange);
    HookConVarChange(cvMineColor[3], CvarChange);
    HookConVarChange(cvBeamColor[1], CvarChange);
    HookConVarChange(cvBeamColor[2], CvarChange);
    HookConVarChange(cvBeamColor[3], CvarChange);

    // commands
    RegConsoleCmd("sm_tripmine", Command_TripMine);
    RegConsoleCmd("tripmine", Command_TripMine);

    AutoExecConfig( true, "plugin.tripmines");
}

/*
public OnPluginEnd()
{
	UnhookEvent("player_changeclass", PlayerChange);
	UnhookEvent("player_death", PlayerDeath);
	UnhookEvent("player_spawn",PlayerSpawn);
}
*/

public OnConfigsExecuted()
{
    #if !defined _ResourceManager_included
        // Setup trie to keep track of precached sounds
        if (g_precacheTrie == INVALID_HANDLE)
            g_precacheTrie = CreateTrie();
        else
            ClearTrie(g_precacheTrie);
    #endif

    // Get the Allow Spectator setting
    gAllowSpectators = GetConVarBool(cvAllowSpectators);
    gTeamSpecific = GetConVarInt(cvTeamSpecific);
    gTouch = GetConVarBool(cvTouch);

    // Get the color settings
    GetConVarString(cvMineColor[1], gMineColor[1], sizeof(gMineColor[]));
    GetConVarString(cvMineColor[2], gMineColor[2], sizeof(gMineColor[]));
    GetConVarString(cvMineColor[3], gMineColor[3], sizeof(gMineColor[]));

    GetConVarString(cvBeamColor[1], gBeamColor[1], sizeof(gBeamColor[]));
    GetConVarString(cvBeamColor[2], gBeamColor[2], sizeof(gBeamColor[]));
    GetConVarString(cvBeamColor[3], gBeamColor[3], sizeof(gBeamColor[]));

    // Get Sounds
    GetConVarString(cvPlacedSound, gSndPlaced, sizeof(gSndPlaced));
    GetConVarString(cvRemovedSound, gSndRemoved, sizeof(gSndRemoved));
    GetConVarString(cvActivatedSound, gSndActivated, sizeof(gSndActivated));
    GetConVarString(cvReactivatedSound, gSndReactivated, sizeof(gSndReactivated));

    // Set model based on cvar
    GetConVarString(cvModel, mdlMine, sizeof(mdlMine));

    // precache models
    gTripmineModelIndex = 0; // PrecacheModel(mdlMine, true);
    gLaserModelIndex = 0;    // PrecacheModel(LASER_SPRITE, true);
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (convar == cvAllowSpectators)
        gAllowSpectators = bool:StringToInt(newValue);
    else if (convar == cvTeamSpecific)
        gTeamSpecific = bool:StringToInt(newValue);
    else if (convar == cvTeamSpecific)
        gTouch = bool:StringToInt(newValue);
    else if (convar == cvPlacedSound)
        strcopy(gSndPlaced, sizeof(gSndPlaced), newValue);
    else if (convar == cvRemovedSound)
        strcopy(gSndRemoved, sizeof(gSndRemoved), newValue);
    else if (convar == cvActivatedSound)
        strcopy(gSndActivated, sizeof(gSndActivated), newValue);
    else if (convar == cvReactivatedSound)
        strcopy(gSndReactivated, sizeof(gSndReactivated), newValue);
    else if (convar == cvMineColor[1])
        strcopy(gMineColor[1], sizeof(gMineColor[]), newValue);
    else if (convar == cvMineColor[2])
        strcopy(gMineColor[2], sizeof(gMineColor[]), newValue);
    else if (convar == cvMineColor[3])
        strcopy(gMineColor[3], sizeof(gMineColor[]), newValue);
    else if (convar == cvBeamColor[1])
        strcopy(gBeamColor[1], sizeof(gBeamColor[]), newValue);
    else if (convar == cvBeamColor[2])
        strcopy(gBeamColor[2], sizeof(gBeamColor[]), newValue);
    else if (convar == cvBeamColor[3])
        strcopy(gBeamColor[3], sizeof(gBeamColor[]), newValue);
}

// When a new client is put in the server we reset their mines count
public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
    if (client && !IsFakeClient(client))
    {
        gChangingClass[client]=false;
        gRemaining[client] = gAllowed[client] = gMaximum[client] = 0;
    }
    return true;
}

public Action:PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
    RemoveTripmines(GetClientOfUserId(GetEventInt(event, "userid")), false);
    return Plugin_Continue;
}    

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new amount = -1;
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (gChangingClass[client])
        gChangingClass[client]=false;
    else
    {
        if (gNativeControl)
            amount = gRemaining[client] = gAllowed[client];
        else            
            gMaximum[client] = GetConVarInt(cvMaxMines);

        if (amount == -1)
        {
            if (GameType == tf2)
            {
                switch (TF2_GetPlayerClass(client))
                {
                    case TFClass_Scout: amount = GetConVarInt(cvNumMinesScout);
                    case TFClass_Sniper: amount = GetConVarInt(cvNumMinesSniper);
                    case TFClass_Soldier: amount = GetConVarInt(cvNumMinesSoldier);
                    case TFClass_DemoMan: amount = GetConVarInt(cvNumMinesDemoman);
                    case TFClass_Medic: amount = GetConVarInt(cvNumMinesMedic);
                    case TFClass_Heavy: amount = GetConVarInt(cvNumMinesHeavy);
                    case TFClass_Pyro: amount = GetConVarInt(cvNumMinesPyro);
                    case TFClass_Spy: amount = GetConVarInt(cvNumMinesSpy);
                    case TFClass_Engineer: amount = GetConVarInt(cvNumMinesEngi);
                }
                if (amount < 0)
                    amount = GetConVarInt(cvNumMines);
            }
            else
                amount = GetConVarInt(cvNumMines);

            gAllowed[client] = amount;
            gRemaining[client] = (cvMineCost == INVALID_HANDLE || GetConVarInt(cvMineCost) <= 0) ? amount : 0;
        }
    }

    return Plugin_Continue;
}

public Action:PlayerChange(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    gChangingClass[client]=true;
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (GameType == tf2)
    {
        // Skip feigned deaths.
        if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
            return Plugin_Continue;

        // Skip fishy deaths.
        if (GetEventInt(event, "weaponid") == TF_WEAPON_BAT_FISH &&
            GetEventInt(event, "customkill") != TF_CUSTOM_FISH_KILL)
        {
            return Plugin_Continue;
        }
    }

    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    gChangingClass[client]=false;
    gRemaining[client] = 0;

    new stay = GetConVarInt(cvStay);
    if (stay != 1)
	{
		new Handle:pack;
		CreateDataTimer(0.1, RemovePlayersTripmines, pack, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(pack, client);
		WritePackCell(pack, (stay > 1));
	}

    return Plugin_Continue;
}

public Action:RemovePlayersTripmines(Handle:timer, Handle:pack)
{ 
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new bool:explode = bool:ReadPackCell(pack);
	RemoveTripmines(client, explode);
	return Plugin_Stop;
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    decl String:classname[64];
    new maxents = GetMaxEntities();
    for (new c = MaxClients; c < maxents; c++)
    {
        new ref = g_SavedEntityRef[c];
        if (ref != 0 && EntRefToEntIndex(ref) == c) // it's an entity we created
        {
            new beam_ent, mine_ent;
            GetEntityNetClass(c, classname, sizeof(classname));
            if (StrEqual(classname, "CBeam")) // it's a beam
            {
                beam_ent = c;
                mine_ent = EntRefToEntIndex(g_TripmineOfBeam[c]);
            }
            else // it must be a tripmine
            {
                mine_ent = c;
                beam_ent = GetEntPropEnt(mine_ent, Prop_Send, "m_hEffectEntity");
            }

            RemoveBeamEntity(beam_ent);
            RemoveMineEntity(mine_ent);
        }
    }
}

RemoveTripmines(client, bool:explode=false)
{
    new Float:time=0.1;
    decl String:classname[64];
    new maxents = GetMaxEntities();
    for (new c = MaxClients; c < maxents; c++)
    {
        new ref = g_SavedEntityRef[c];
        if (ref != 0 && EntRefToEntIndex(ref) == c) // it's an entity we created
        {
            GetEntityNetClass(c, classname, sizeof(classname));
            if (StrEqual(classname, "CBeam")) // it's a beam
            {
                new mine_ent = EntRefToEntIndex(g_TripmineOfBeam[c]);
                if (mine_ent > 0 && GetEntPropEnt(mine_ent, Prop_Send, "m_hOwnerEntity") == client)
                {
                    RemoveEntities(mine_ent, c, explode, time);
                }
            }
            else // it must be a tripmine
            {
                if (GetEntPropEnt(c, Prop_Send, "m_hOwnerEntity") == client)
                {
                    RemoveEntities(c, GetEntPropEnt(c, Prop_Send, "m_hEffectEntity"), explode,time);
                }
            }
        }
    }
}

RemoveEntities(mine_ent, beam_ent, bool:explode,&Float:time)
{
    RemoveBeamEntity(beam_ent);

    if (mine_ent > 0 && IsValidEntity(mine_ent))
    {
        if (explode)
        {
            CreateTimer(time, ExplodeMine, g_SavedEntityRef[mine_ent]);
            time += 0.1;
        }
        else
        {
            if (gSndRemoved[0])
            {
                PrepareSound(gSndRemoved);
                EmitSoundToAll(gSndRemoved, mine_ent, _, _, _, 0.75);
            }

            RemoveMineEntity(mine_ent);
        }
    }
}

RemoveBeamEntity(beam_ent)
{
    if (beam_ent > 0 && IsValidEntity(beam_ent))
    {
        UnhookSingleEntityOutput(beam_ent, "OnBreak", beamBreak);

        if (gTeamSpecific > 0)
            UnhookSingleEntityOutput(beam_ent, "OnTouchedByEntity", beamTouched);

        //RemoveEdict(beam_ent);
        AcceptEntityInput(beam_ent, "Kill");
        g_SavedEntityRef[beam_ent] = 0;
        g_TripmineOfBeam[beam_ent] = 0;
    }
}

RemoveMineEntity(mine_ent)
{
    if (mine_ent > 0 && IsValidEntity(mine_ent))
    {
        UnhookSingleEntityOutput(mine_ent, "OnBreak", mineBreak);

        if (gTouch && gTeamSpecific > 0)
        {
            UnhookSingleEntityOutput(mine_ent, "OnTouchedByEntity", mineTouched);
        }

        //RemoveEdict(mine_ent);
        AcceptEntityInput(mine_ent, "Kill");
        g_SavedEntityRef[mine_ent] = 0;
    }
}

public Action:ExplodeMine(Handle:timer, any:ref)
{
    new ent = EntRefToEntIndex(ref);
    if (ent > 0)
    {
        AcceptEntityInput(ent, "Break");
    }
    return Plugin_Stop;
}

public Action:Command_TripMine(client, args)
{
    // make sure client is not spectating
    if (!IsPlayerAlive(client))
        return Plugin_Handled;

    // check restricted team 
    new team = GetClientTeam(client);
    if (team == GetConVarInt(cvTeamRestricted) ||
        (team == 1 && !gAllowSpectators))
    {
        PrintHintText(client, "%t", "notallowed");
        return Plugin_Handled;
    }

    // check admin flag (if any)
    decl String:adminFlag[2];
    GetConVarString(cvAdmin, adminFlag, sizeof(adminFlag));
    if (adminFlag[0] != '\0')
    {
        new AdminFlag:flag;
        if (FindFlagByChar(adminFlag[0], flag))
        {
            new AdminId:aid = GetUserAdmin(client);
            if (aid == INVALID_ADMIN_ID || !GetAdminFlag(aid, flag, Access_Effective))
            {
                PrintHintText(client, "%t", "notallowed");
                return Plugin_Handled;
            }
        }
    }

    SetMine(client);
    return Plugin_Handled;
}

SetMine(client)
{
    if (gRemaining[client] == 0)
    {
        PrintHintText(client, "%t", "nomines");
        return;
    }

    if (IsEntLimitReached(100, .message="unable to create tripmine"))
        return;

    new max = gMaximum[client];
    if (max > 0)
    {
        new count = CountMines(client);
        if (count > max)
        {
            PrintHintText(client, "%t", "toomany", count);
            return;
        }
    }

    new Action:res = Plugin_Continue;
    Call_StartForward(fwdOnSetTripmine);
    Call_PushCell(client);
    Call_Finish(res);
    if (res != Plugin_Continue)
        return;

    if (GameType == tf2)
    {
        switch (TF2_GetPlayerClass(client))
        {
            case TFClass_Spy:
            {
                new pcond = TF2_GetPlayerConditionFlags(client);
                if (TF2_IsCloaked(pcond) || TF2_IsDeadRingered(pcond))
                {
                    PrepareSound(gSndError);
                    EmitSoundToClient(client, gSndError);
                    return;
                }
                else if (TF2_IsDisguised(pcond))
                    TF2_RemovePlayerDisguise(client);
            }
            case TFClass_Scout:
            {
                if (TF2_IsPlayerBonked(client))
                {
                    PrepareSound(gSndError);
                    EmitSoundToClient(client, gSndError);
                    return;
                }
            }
        }
    }

    // trace client view to get position and angles for tripmine

    decl Float:start[3], Float:angle[3], Float:end[3], Float:normal[3], Float:beamend[3];
    GetClientEyePosition( client, start );
    GetClientEyeAngles( client, angle );
    GetAngleVectors(angle, end, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(end, end);

    start[0]=start[0]+end[0]*TRACE_START;
    start[1]=start[1]+end[1]*TRACE_START;
    start[2]=start[2]+end[2]*TRACE_START;

    end[0]=start[0]+end[0]*TRACE_END;
    end[1]=start[1]+end[1]*TRACE_END;
    end[2]=start[2]+end[2]*TRACE_END;

    TR_TraceRayFilter(start, end, CONTENTS_SOLID, RayType_EndPoint, FilterAll, 0);

    if (TR_DidHit(INVALID_HANDLE))
    {
        // update client's inventory
        if (gRemaining[client] > 0)
            gRemaining[client]--;

        // find angles for tripmine
        TR_GetEndPosition(end, INVALID_HANDLE);
        TR_GetPlaneNormal(INVALID_HANDLE, normal);
        GetVectorAngles(normal, normal);

        // trace laser beam
        TR_TraceRayFilter(end, normal, CONTENTS_SOLID, RayType_Infinite, FilterAll, 0);
        TR_GetEndPosition(beamend, INVALID_HANDLE);

        new team = GetClientTeam(client);

        // setup unique target names for entities to be created with
        decl String:beamname[16];
        decl String:minename[16];
        decl String:tmp[64];
        Format(beamname, sizeof(beamname), "tripbeam%d", gCount);
        Format(minename, sizeof(minename), "tripmine%d", gCount);
        gCount++;
        if (gCount > 10000)
            gCount = 1;


        // create tripmine model
        new mine_ent = CreateEntityByName("prop_physics_override");
        if (mine_ent > 0 && IsValidEdict(mine_ent))
        {
            PrepareModel(mdlMine, gTripmineModelIndex);
            SetEntityModel(mine_ent,mdlMine);

            DispatchKeyValue(mine_ent, "spawnflags", "152");
            DispatchKeyValue(mine_ent, "StartDisabled", "false");

            if (gMineColor[team][0] != '\0')
            {
                decl String:color[4][4];
                if (ExplodeString(gMineColor[team], " ", color, sizeof(color), sizeof(color[])) <= 3)
                    strcopy(color[3], sizeof(color[]), "255");

                SetEntityRenderMode(mine_ent, RENDER_TRANSCOLOR);
                SetEntityRenderColor(mine_ent, StringToInt(color[0]), StringToInt(color[1]),
                                               StringToInt(color[2]), StringToInt(color[3]));
            }

            if (DispatchSpawn(mine_ent))
            {
                SetEntProp(mine_ent, Prop_Data, "m_takedamage", DAMAGE_YES); //  DAMAGE_AIM);
                SetEntProp(mine_ent, Prop_Send, "m_usSolidFlags", 152);
                //DispatchKeyValue(mine_ent, "physdamagescale", "1.0");

                TeleportEntity(mine_ent, end, normal, NULL_VECTOR);
                DispatchKeyValue(mine_ent, "targetname", minename);
                DispatchKeyValue(mine_ent, "classname", "tripmine");

                SetEntProp(mine_ent, Prop_Data, "m_MoveCollide", 0);

                SetEntProp(mine_ent, Prop_Send, "m_nSolidType", 6);
                SetEntProp(mine_ent, Prop_Send, "m_iTeamNum", team, 4);
                SetEntProp(mine_ent, Prop_Send, "m_CollisionGroup", 1); // 2);

                SetEntPropEnt(mine_ent, Prop_Data, "m_hLastAttacker", client);
                SetEntPropEnt(mine_ent, Prop_Data, "m_hPhysicsAttacker", client);
                SetEntPropEnt(mine_ent, Prop_Send, "m_hOwnerEntity", client);

                AcceptEntityInput(mine_ent, "DisableMotion");
                //SetEntityMoveType(mine_ent, MOVETYPE_NONE);

                GetConVarString(cvRadius, tmp, sizeof(tmp));
                DispatchKeyValue(mine_ent, "ExplodeRadius", tmp);

                GetConVarString(cvDamage, tmp, sizeof(tmp));
                DispatchKeyValue(mine_ent, "ExplodeDamage", tmp);

                //DispatchKeyValue(mine_ent, "SetHealth", "10");
                new health = GetConVarInt(cvHealth);
                if (health > 0)
                    SetEntProp(mine_ent, Prop_Data, "m_iHealth", health);
                SetEntPropEnt(mine_ent, Prop_Data, "m_hOwnerEntity", client);

                HookSingleEntityOutput(mine_ent, "OnBreak", mineBreak, true);

                if (gTouch)
                {
                    if (gTeamSpecific > 0)
                        HookSingleEntityOutput(mine_ent, "OnTouchedByEntity", mineTouched, true);
                    else
                        DispatchKeyValue(mine_ent, "OnTouchedByEntity", "!self,Break,,0,-1");
                }

                new prop_ref = EntIndexToEntRef(mine_ent);
                g_SavedEntityRef[mine_ent] = prop_ref;

                // create laser beam
                new beam_ent = CreateEntityByName("env_beam");
                if (beam_ent > 0 && IsValidEdict(beam_ent))
                {
                    DispatchKeyValueVector(beam_ent, "origin", end);
                    SetEntPropVector(beam_ent, Prop_Send, "m_vecEndPos", beamend);

                    PrepareModel(LASER_SPRITE, gLaserModelIndex);
                    SetEntityModel(beam_ent, LASER_SPRITE);

                    SetEntPropFloat(beam_ent, Prop_Send, "m_fWidth", 4.0);

                    DispatchKeyValue(beam_ent, "texture", LASER_SPRITE);
                    //DispatchKeyValue(beam_ent, "parentname", minename);
                    DispatchKeyValue(beam_ent, "targetname", beamname);
                    DispatchKeyValue(beam_ent, "LightningStart", beamname);
                    DispatchKeyValue(beam_ent, "TouchType", "4");
                    DispatchKeyValue(beam_ent, "BoltWidth", "4.0");
                    DispatchKeyValue(beam_ent, "life", "0");
                    DispatchKeyValue(beam_ent, "rendercolor", "0 0 0");
                    DispatchKeyValue(beam_ent, "renderamt", "0");
                    DispatchKeyValue(beam_ent, "HDRColorScale", "1.0");
                    DispatchKeyValue(beam_ent, "decalname", "Bigshot");
                    DispatchKeyValue(beam_ent, "StrikeTime", "0");
                    DispatchKeyValue(beam_ent, "TextureScroll", "35");

                    if (DispatchSpawn(mine_ent))
                    {
                        if (gTeamSpecific > 0)
                            HookSingleEntityOutput(beam_ent, "OnTouchedByEntity", beamTouched, false);
                        else
                        {
                            Format(tmp, sizeof(tmp), "%s,Break,,0,-1", minename);
                            DispatchKeyValue(beam_ent, "OnTouchedByEntity", tmp);
                        }

                        HookSingleEntityOutput(beam_ent, "OnBreak", beamBreak, true);
                        AcceptEntityInput(beam_ent, "TurnOff");

                        // Set the mine's m_hEffectEntity to point at the beam
                        SetEntPropEnt(mine_ent, Prop_Send, "m_hEffectEntity", beam_ent);

                        AcceptEntityInput(mine_ent, "Enable");
                        SetEntProp(mine_ent, Prop_Data, "m_takedamage", DAMAGE_YES);

                        new beam_ref = EntIndexToEntRef(beam_ent);
                        g_SavedEntityRef[beam_ent] = beam_ref;
                        g_TripmineOfBeam[beam_ent] = prop_ref;

                        new Handle:data;
                        new Float:delay = GetConVarFloat(cvActTime);
                        CreateDataTimer(delay, ActivateTripmine, data,
                                        TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);

                        WritePackCell(data, client);
                        WritePackCell(data, prop_ref);
                        WritePackCell(data, beam_ref);
                        WritePackFloat(data, end[0]);
                        WritePackFloat(data, end[1]);
                        WritePackFloat(data, end[2]);

                        // play sound
                        if (gSndPlaced[0])
                        {
                            PrepareSound(gSndPlaced);
                            EmitSoundToAll(gSndPlaced, beam_ent, SNDCHAN_AUTO,
                                           SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
                                           100, beam_ent, end, NULL_VECTOR, true, 0.0);
                        }                           

                        // send message
                        if (gRemaining[client] >= 0)
                            PrintHintText(client, "%t", "left", gRemaining[client]);
                    }
                    else
                        LogError("Unable to spawn a beam_ent");
                }
                else
                    LogError("Unable to create a beam_ent");
            }
            else
                LogError("Unable to spawn a mine_ent");
        }
        else
            LogError("Unable to create a mine_ent");
    }
    else
    {
        PrintHintText(client, "%t", "locationerr");
    }
}

public Action:ActivateTripmine(Handle:timer, Handle:data)
{
    ResetPack(data);
    new client = ReadPackCell(data);
    new prop_ref = ReadPackCell(data);
    new beam_ref = ReadPackCell(data);

    new mine_ent = EntRefToEntIndex(prop_ref);
    new beam_ent = EntRefToEntIndex(beam_ref);
    if (mine_ent > 0 && beam_ent > 0 && client > 0 && IsClientInGame(client))
    {
        if (IsPlayerAlive(client))
        {
            new team = GetEntProp(mine_ent, Prop_Send, "m_iTeamNum");

            new String:color[4][4];
            if (ExplodeString(gBeamColor[team], " ", color, sizeof(color), sizeof(color[])) > 3)
            {
                SetEntityRenderMode(beam_ent, RENDER_TRANSCOLOR);
                SetEntityRenderColor(beam_ent, StringToInt(color[0]), StringToInt(color[1]),
                                               StringToInt(color[2]), StringToInt(color[3]));
            }
            else
                DispatchKeyValue(beam_ent, "rendercolor", gBeamColor[team]);

            DispatchKeyValue(mine_ent, "OnHealthChanged", "!self,Break,,0,-1");
            DispatchKeyValue(mine_ent, "OnTakeDamage", "!self,Break,,0,-1");

            AcceptEntityInput(beam_ent, "TurnOn");

            if (gSndActivated[0])
            {
                new Float:end[3];
                end[0] = ReadPackFloat(data);
                end[1] = ReadPackFloat(data);
                end[2] = ReadPackFloat(data);

                PrepareSound(gSndActivated);
                EmitSoundToAll(gSndActivated, beam_ent, SNDCHAN_AUTO,
                               SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
                               100, beam_ent, end, NULL_VECTOR, true, 0.0);
            }

            return Plugin_Stop;
        }
    }

    // Player died before activation or something happened to the tripmine,
    RemoveBeamEntity(beam_ent);
    RemoveMineEntity(mine_ent);
    return Plugin_Stop;
}

public Action:TurnBeamOn(Handle:timer, Handle:data)
{
    ResetPack(data);
    new client = ReadPackCell(data);
    new prop_ref = ReadPackCell(data);
    new beam_ref = ReadPackCell(data);

    new mine_ent = EntRefToEntIndex(prop_ref);
    new beam_ent = EntRefToEntIndex(beam_ref);
    if (mine_ent > 0 && beam_ent > 0 && client > 0 && IsClientInGame(client))
    {
        AcceptEntityInput(beam_ent, "TurnOn");

        if (gSndReactivated[0])
        {
            decl Float:end[3];
            GetEntPropVector(beam_ent, Prop_Send, "m_vecEndPos", end);

            PrepareSound(gSndReactivated);
            EmitSoundToAll(gSndReactivated, beam_ent, SNDCHAN_AUTO,
                           SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
                           100, beam_ent, end, NULL_VECTOR, true, 0.0);
        }                       
        return Plugin_Stop;
    }

    // Player left or something happened to the tripmine,
    RemoveBeamEntity(beam_ent);
    RemoveMineEntity(mine_ent);
    return Plugin_Stop;
}

CountMines(client)
{
    decl String:classname[64];

    new count = 0;
    new maxents = GetMaxEntities();
    for (new c = MaxClients; c < maxents; c++)
    {
        new ref = g_SavedEntityRef[c];
        if (ref != 0 && EntRefToEntIndex(ref) == c) // it's an entity we created
        {
            GetEntityNetClass(c, classname, sizeof(classname));
            if (!StrEqual(classname, "CBeam")) // It's not a beam, must be a tripmine
            {
                if (GetEntPropEnt(c, Prop_Send, "m_hOwnerEntity") == client)
                    count++;
            }
        }
    }
    return count;
}

public beamTouched(const String:output[], caller, activator, Float:delay)
{
    new ref = g_SavedEntityRef[caller];
    if (ref != 0 && EntRefToEntIndex(ref) == caller) // it's an entity we created
    {
        new mine_ent = EntRefToEntIndex(g_TripmineOfBeam[caller]);
        if (mine_ent > 0 && IsValidEntity(mine_ent))
        {
            new owner = GetEntPropEnt(mine_ent, Prop_Send, "m_hOwnerEntity");
            new team = (owner > 0 && gAllowSpectators && IsClientInGame(owner))
                       ? GetClientTeam(owner) : GetEntProp(mine_ent, Prop_Send, "m_iTeamNum");

            if (activator > MaxClients || (activator == owner && gTeamSpecific < 2) ||
                team != GetClientTeam(activator))
            {
                AcceptEntityInput(mine_ent, "Break");
            }
            else if (owner > 0 && IsClientInGame(owner))
            {
                new Float:reactTime = GetConVarFloat(cvReactTime);
                if (reactTime > 0.0)
                {
                    decl Float:end[3];
                    GetEntPropVector(caller, Prop_Send, "m_vecEndPos", end);
                    AcceptEntityInput(caller, "TurnOff");

                    new Handle:data;
                    CreateDataTimer(reactTime, TurnBeamOn, data,
                                    TIMER_FLAG_NO_MAPCHANGE);

                    WritePackCell(data, owner);
                    WritePackCell(data, g_TripmineOfBeam[caller]);
                    WritePackCell(data, g_SavedEntityRef[caller]);
                }
                else
                {
                    decl String:input[128];
                    AcceptEntityInput(caller, "TurnOff");
                    Format(input, sizeof(input), "OnUser1 !self:TurnOn::0.0:1");
                    SetVariantString(input);
                    AcceptEntityInput(caller, "AddOutput");
                    AcceptEntityInput(caller, "FireUser1");
                }
            }
            else
            {
                LogMessage("Orphan tripmine %d encountered!", mine_ent);
                AcceptEntityInput(mine_ent, "Break");
            }
        }
        else
        {
            LogError("Orphan beam %d encountered!", caller);
            RemoveBeamEntity(caller);
        }
    }
}

public beamBreak(const String:output[], caller, activator, Float:delay)
{
    new mine_ent = EntRefToEntIndex(g_TripmineOfBeam[caller]);
    if (mine_ent > 0 && IsValidEntity(mine_ent))
    {
        AcceptEntityInput(mine_ent, "Break");
    }
    else // check for an orphaned beam
    {
        new ref = g_SavedEntityRef[caller];
        if (ref != 0 && EntRefToEntIndex(ref) == caller)
        {
            LogError("Orphan beam %d encountered!", caller);
            RemoveBeamEntity(caller);
        }
    }
}

public mineTouched(const String:output[], caller, activator, Float:delay)
{
    new ref = g_SavedEntityRef[caller];
    if (ref != 0 && EntRefToEntIndex(ref) == caller) // it's an entity we created
    {
        new owner = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");
        new team = GetEntProp(caller, Prop_Send, "m_iTeamNum");

        if (activator > MaxClients || gTeamSpecific < 1 ||
            (activator == owner && gTeamSpecific < 2) ||
             team != GetClientTeam(activator))
        {
            AcceptEntityInput(caller, "Break");
        }
        else // Re-Hook the output.
            HookSingleEntityOutput(caller, output, mineTouched, true);
    }
}

public mineBreak(const String:output[], caller, activator, Float:delay)
{
    new ref = g_SavedEntityRef[caller];
    if (ref != 0 && EntRefToEntIndex(ref) == caller) // it's an entity we created
    {
        mineExplode(caller);
    }
}

mineExplode(mine_ent)
{
    RemoveBeamEntity(GetEntPropEnt(mine_ent, Prop_Send, "m_hEffectEntity"));
    RemoveMineEntity(mine_ent);

    if (GetConVarBool(cvType))
    {
        // Set everyone in range on fire
        new team = 0;
        if (gTeamSpecific || !GetConVarBool(cvFriendlyFire))
            team = GetEntProp(mine_ent, Prop_Send, "m_iTeamNum");

        decl Float:vecPos[3];
        GetEntPropVector(mine_ent, Prop_Send, "m_vecOrigin", vecPos);

        new owner = GetEntPropEnt(mine_ent, Prop_Send, "m_hOwnerEntity");
        new Float:maxdistance = GetConVarFloat(cvRadius);
        for (new i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                decl Float:PlayerPosition[3];
                GetClientAbsOrigin(i, PlayerPosition);
                if (GetVectorDistance(PlayerPosition, vecPos) <= maxdistance)
                {
                    if (i == owner)
                        IgniteEntity(i, 2.5);
                    else if (team != GetClientTeam(i))
                    {
                        if (GameType == tf2)
                        {
                            if (!TF2_IsPlayerUbercharged(i))
                            {
                                if (owner > 0 && IsClientInGame(owner))
                                    TF2_IgnitePlayer(i, owner);
                                else
                                    IgniteEntity(i, 2.5);
                            }
                        }
                        else
                            IgniteEntity(i, 2.5);
                    }
                }
            }
        }
    }
}

public bool:FilterAll(entity, contentsMask)
{
    return false;
}

public Action:Command_BuyTripMines(client, args)
{
    if (!client || IsFakeClient(client) || !IsPlayerAlive(client) || gInBuyZone == -1 || gAccount == -1)
        return Plugin_Handled;

    // args
    new cnt = 1;
    if (args > 0)
    {
        decl String:txt[MAX_LINE_LEN];
        GetCmdArg(1, txt, sizeof(txt));
        cnt = StringToInt(txt);
    }

    // buy
    if (cnt > 0)
    {
        // check buy zone
        if (!GetEntData(client, gInBuyZone, 1))
        {
            PrintCenterText(client, "%t", "notinbuyzone");
            return Plugin_Handled;
        }

        new max = GetConVarInt(cvNumMines);
        new cost = (cvMineCost) ? GetConVarInt(cvMineCost) : 0;
        if (cost < 0)
        {
            PrintHintText(client, "%t", "maxmines", max);
            return Plugin_Handled;
        }

        new money = GetEntData(client, gAccount);
        do
        {
            // check max count
            if (gRemaining[client] >= max)
            {
                PrintHintText(client, "%t", "maxmines", max);
                return Plugin_Handled;
            }

            // have money?
            money-= cost;
            if (money < 0)
            {
                PrepareSound(gSndCantBuy);
                EmitSoundToClient(client, gSndCantBuy);
                PrintHintText(client, "%t", "nomoney", cost, gRemaining[client]);
                return Plugin_Handled;
            }

            // deal
            PrepareSound(gSndBuy);
            EmitSoundToClient(client, gSndBuy);
            SetEntData(client, gAccount, money);
            gRemaining[client]++;

        } while(--cnt);
    }

    // info
    PrintHintText(client, "%t", "cntmines", gRemaining[client]);

    return Plugin_Handled;
}

public Native_ControlTripmines(Handle:plugin,numParams)
{
    gNativeControl = GetNativeCell(1);
}

public Native_GiveTripmines(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    gRemaining[client] = GetNativeCell(2);
    gAllowed[client] = GetNativeCell(3);
    gMaximum[client] = GetNativeCell(4);

    if (gMaximum[client] < 0)
        gMaximum[client] = GetConVarInt(cvMaxMines);
}

public Native_TakeTripmines(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    gRemaining[client] = gAllowed[client] = gMaximum[client] = 0;
}

public Native_AddTripmines(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    gRemaining[client] += GetNativeCell(2);
}

public Native_SubTripmines(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    gRemaining[client] -= GetNativeCell(2);
    if (gRemaining[client] < 0)
        gRemaining[client] = 0;
}

public Native_HasTripmines(Handle:plugin,numParams)
{
    new client = GetNativeCell(1);
    return (GetNativeCell(2)) ? gAllowed[client] : gRemaining[client];
}

public Native_SetTripmine(Handle:plugin,numParams)
{
    SetMine(GetNativeCell(1));
}

public Native_CountTripmines(Handle:plugin,numParams)
{
    return CountMines(GetNativeCell(1));
}
