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

#define PLUGIN_VERSION  "3.6"

#define MAXENTITIES     2048

#define MAX_LINE_LEN    256

#define TRACE_START     24.0
#define TRACE_END       64.0

#define DF_FEIGNDEATH   32 // TF2 Feign death_flag

#define LASER_SPRITE    "sprites/laser.vmt"

#define SND_MINEPUT     "npc/roller/blade_cut.wav"
#define SND_MINEACT     "npc/roller/mine/rmine_blades_in2.wav"
#define SND_MINEERR     "common/wpn_denyselect.wav"
#define SND_MINEREM     "ui/hint.wav"
#define SND_BUYMINE     "items/itempickup.wav"
#define SND_CANTBUY     "buttons/weapon_cant_buy.wav"

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

// for buy
new gInBuyZone = -1;
new gAccount = -1;

new bool:gNativeControl = false;
new bool:gChangingClass[MAXPLAYERS+1];
new gAllowed[MAXPLAYERS+1];    // how many tripmines player allowed

new gTripmineModelIndex;
new gLaserModelIndex;

new g_SavedEntityRef[MAXENTITIES+1];
new g_BeamForTripmine[MAXENTITIES+1];
new g_TripmineOfBeam[MAXENTITIES+1];

new String:mdlMine[256] = "models/props_lab/tpplug.mdl";

// forwards
new Handle:fwdOnSetTripmine;

// convars
new Handle:cvActTime = INVALID_HANDLE;
new Handle:cvModel = INVALID_HANDLE;
new Handle:cvMineCost = INVALID_HANDLE;
new Handle:cvAllowSpectators = INVALID_HANDLE;
new Handle:cvTeamRestricted = INVALID_HANDLE;
new Handle:cvTeamSpecific = INVALID_HANDLE;
new Handle:cvAdmin = INVALID_HANDLE;
new Handle:cvRadius = INVALID_HANDLE;
new Handle:cvDamage = INVALID_HANDLE;
new Handle:cvType = INVALID_HANDLE;
new Handle:cvStay = INVALID_HANDLE;
new Handle:cvFriendlyFire = INVALID_HANDLE;

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
    enum Game { undetected, tf2, cstrike, dod, hl2mp, insurgency, zps, l4d, l4d2, other };
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
                GameType=other;
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
    stock IsEntLimitReached(warn=20,critical=16,client=0,const String:message[]="")
    {
        new max = GetMaxEntities();
        new count = GetEntityCount();
        new remaining = max - count;
        if (remaining <= warn)
        {
            if (count <= critical)
            {
                PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
                LogError("Entity limit is nearly reached: %d/%d (%d):%s", count, max, remaining, message);

                if (client > 0)
                {
                    PrintToConsole(client, "Entity limit is nearly reached: %d/%d (%d):%s",
                                   count, max, remaining, message);
                }
            }
            else
            {
                PrintToServer("Caution: Entity count is getting high!");
                LogMessage("Entity count is getting high: %d/%d (%d):%s", count, max, remaining, message);

                if (client > 0)
                {
                    PrintToConsole(client, "Entity count is getting high: %d/%d (%d):%s",
                                   count, max, remaining, message);
                }
            }
            return count;
        }
        else
            return 0;
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
    enum TFPlayerCond (<<= 1)
    {
        TFPlayerCond_None = 0,
        TFPlayerCond_Slowed,
        TFPlayerCond_Zoomed,
        TFPlayerCond_Disguising,
        TFPlayerCond_Disguised,
        TFPlayerCond_Cloaked,
        TFPlayerCond_Ubercharged,
        TFPlayerCond_TeleportedGlow,
        TFPlayerCond_Taunting,
        TFPlayerCond_UberchargeFading,
        TFPlayerCond_Unknown1,
        TFPlayerCond_Teleporting,
        TFPlayerCond_Kritzkrieged,
        TFPlayerCond_Unknown2,
        TFPlayerCond_DeadRingered,
        TFPlayerCond_Bonked,
        TFPlayerCond_Dazed,
        TFPlayerCond_Buffed,
        TFPlayerCond_Charging,
        TFPlayerCond_DemoBuff,
        TFPlayerCond_CritCola,
        TFPlayerCond_Healing,
        TFPlayerCond_OnFire,
        TFPlayerCond_Overhealed,
        TFPlayerCond_Jarated
    };

    #define TF2_IsDisguised(%1)         (((%1) & TFPlayerCond_Disguised) != TFPlayerCond_None)
    #define TF2_IsCloaked(%1)           (((%1) & TFPlayerCond_Cloaked) != TFPlayerCond_None)
    #define TF2_IsUbercharged(%1)       (((%1) & TFPlayerCond_Ubercharged) != TFPlayerCond_None)
    #define TF2_IsBonked(%1)            (((%1) & TFPlayerCond_Bonked) != TFPlayerCond_None)
    #define TF2_IsDeadRingered(%1)      (((%1) & TFPlayerCond_DeadRingered) != TFPlayerCond_None)

    #define TF2_IsPlayerUbercharged(%1)         TF2_IsUbercharged(TF2_GetPlayerCond(%1))
    #define TF2_IsPlayerBonked(%1)              TF2_IsBonked(TF2_GetPlayerCond(%1))

    stock TFPlayerCond:TF2_GetPlayerCond(client)
    {
        return TFPlayerCond:GetEntProp(client, Prop_Send, "m_nPlayerCond");
    }
#endif

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    // To work with all mods
    MarkNativeAsOptional("TF2_IgnitePlayer");
    MarkNativeAsOptional("TF2_RemovePlayerDisguise");

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
    cvModel = CreateConVar("sm_tripmines_model", mdlMine, "Tripmine model");
    cvAllowSpectators = CreateConVar("sm_tripmines_allowspec", "0", "Allow spectators to use tripmines", _, true, 0.0, true, 3.0);
    cvTeamRestricted = CreateConVar("sm_tripmines_restrictedteam", "0", "Team that does NOT get any tripmines", _, true, 0.0, true, 3.0);
    cvTeamSpecific = CreateConVar("sm_tripmines_teamspecific", "1", "Allow teammates of planter to pass (0=no | 1=yes | 2=also allow planter to pass)", _, true, 0.0, true, 2.0);
    cvAdmin = CreateConVar("sm_tripmines_admin", "", "Admin flag required to use tripmines (empty=anyone can use tripmines)");
    cvType = CreateConVar("sm_tripmines_type","1","Explosion type of Tripmines (0=normal explosion | 1=fire explosion)", _, true, 0.0, true, 1.0);
    cvStay = CreateConVar("sm_tripmines_stay","1","Tripmines stay if the owner dies. (0=no | 1 = yes | 2=destruct)", _, true, 0.0, true, 2.0);
    cvRadius = CreateConVar("sm_tripmines_radius", "256.0", "Tripmines Explosion Radius");
    cvDamage = CreateConVar("sm_tripmines_damage", "200", "Tripmines Explosion Damage");

    cvFriendlyFire = FindConVar("mp_friendlyfire");

    cvMineColor[1] = CreateConVar("sm_tripmines_mine_color_1", gMineColor[1], "Mine Color (can include alpha) for team 1 (Spectators)");
    cvMineColor[2] = CreateConVar("sm_tripmines_mine_color_2", gMineColor[2], "Mine Color (can include alpha) for team 2 (Red  / Allies / Terrorists)");
    cvMineColor[3] = CreateConVar("sm_tripmines_mine_color_3", gMineColor[3], "Mine Color (can include alpha) for team 3 (Blue / Axis   / Counter-Terrorists)");

    cvBeamColor[1] = CreateConVar("sm_tripmines_beam_color_1", gBeamColor[1], "Beam Color (can include alpha) for team 1 (Spectators)");
    cvBeamColor[2] = CreateConVar("sm_tripmines_beam_color_2", gBeamColor[2], "Beam Color (can include alpha) for team 2 (Red  / Allies / Terrorists)");
    cvBeamColor[3] = CreateConVar("sm_tripmines_beam_color_3", gBeamColor[3], "Beam Color (can include alpha) for team 3 (Blue / Axis   / Counter-Terrorists)");

    cvMaxMines = CreateConVar("sm_tripmines_maximum", "6", "Maximum Number of tripmines allowed to be active per client (-1=unlimited)");
    cvNumMines = CreateConVar("sm_tripmines_allowed", "3", "Number of tripmines allowed per life (-1=unlimited)");

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

    // Get the color settings
    GetConVarString(cvMineColor[1], gMineColor[1], sizeof(gMineColor[]));
    GetConVarString(cvMineColor[2], gMineColor[2], sizeof(gMineColor[]));
    GetConVarString(cvMineColor[3], gMineColor[3], sizeof(gMineColor[]));

    GetConVarString(cvBeamColor[1], gBeamColor[1], sizeof(gBeamColor[]));
    GetConVarString(cvBeamColor[2], gBeamColor[2], sizeof(gBeamColor[]));
    GetConVarString(cvBeamColor[3], gBeamColor[3], sizeof(gBeamColor[]));

    // set model based on cvar
    GetConVarString(cvModel, mdlMine, sizeof(mdlMine));

    // precache models
    gTripmineModelIndex = 0; // PrecacheModel(mdlMine, true);
    gLaserModelIndex = 0;    // PrecacheModel(LASER_SPRITE, true);

    // precache sounds
    //PrecacheSound(SND_MINEPUT, true);
    //PrecacheSound(SND_MINEACT, true);
    //PrecacheSound(SND_MINEERR, true);
    //PrecacheSound(SND_MINEREM, true);
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (convar == cvAllowSpectators)
        gAllowSpectators = bool:StringToInt(newValue);
    else if (convar == cvTeamSpecific)
        gTeamSpecific = bool:StringToInt(newValue);
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
    // Skip feigned deaths.
    if (GetEventInt(event, "death_flags") & DF_FEIGNDEATH)
        return Plugin_Continue;

    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    gChangingClass[client]=false;
    gRemaining[client] = 0;

    new stay = GetConVarInt(cvStay);
    if (stay != 1)
	{
		new Handle:pack;
		CreateDataTimer(0.1, HandlePlayerDeath, pack, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(pack, client);
		WritePackCell(pack, stay > 1);
        // RemoveTripmines(client, (stay > 1));
	}

    return Plugin_Continue;
}

public Action:HandlePlayerDeath(Handle:timer, Handle:pack)
{ 
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new stay = ReadPackCell(pack);
	
	RemoveTripmines(client, (stay > 1));
 
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
            GetEntityNetClass(c, classname, sizeof(classname));
            if (StrEqual(classname, "CBeam")) // it's a beam
            {
                new mine = EntRefToEntIndex(g_TripmineOfBeam[c]);
                if (mine > 0 && IsValidEntity(mine))
                {
                    RemoveEdict(mine);
                    g_SavedEntityRef[mine] = 0;
                    g_BeamForTripmine[mine] = 0;
                }

                RemoveEdict(c);
                g_SavedEntityRef[c] = 0;
                g_TripmineOfBeam[c] = 0;
            }
            else // it must be a tripmine
            {
                new beam = EntRefToEntIndex(g_BeamForTripmine[c]);
                if (beam > 0 && IsValidEntity(beam))
                {
                    RemoveEdict(beam);
                    g_SavedEntityRef[beam] = 0;
                    g_TripmineOfBeam[beam] = 0;
                }

                RemoveEdict(c);
                g_SavedEntityRef[c] = 0;
                g_BeamForTripmine[c] = 0;
            }
        }
    }
}

RemoveTripmines(client, bool:explode=false)
{
    new Float:time=0.01;
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
                if (GetEntPropEnt(c, Prop_Send, "m_hOwnerEntity") == client)
                {				
                    new mine = EntRefToEntIndex(g_TripmineOfBeam[c]);
                    if (mine > 0 && IsValidEntity(mine))
                    {
						RemoveEdict(c);
						g_SavedEntityRef[c] = 0;
						g_TripmineOfBeam[c] = 0;
						g_BeamForTripmine[mine] = 0;

						if (explode)
                        {
                            CreateTimer(time, ExplodeMine, ref);
                            time += 0.02;
                            continue;
                        }
						else
                        {
                            PrepareSound(SND_MINEREM);
                            EmitSoundToAll(SND_MINEREM, c, _, _, _, 0.75);

                            RemoveEdict(mine);
                            g_SavedEntityRef[mine] = 0;
                        }
                    }
                }
            }
            else // it must be a tripmine
            {
                if (GetEntPropEnt(c, Prop_Send, "m_hOwnerEntity") == client)
                {
                    new beam = EntRefToEntIndex(g_BeamForTripmine[c]);
                    if (beam > 0 && IsValidEntity(beam))
                    {
						UnhookSingleEntityOutput(beam, "OnTouchedByEntity", beamTouched);
						UnhookSingleEntityOutput(c, "OnBreak", beamBreak);
					
						RemoveEdict(beam);
						g_SavedEntityRef[beam] = 0;
						g_TripmineOfBeam[beam] = 0;
						g_BeamForTripmine[c] = 0;

						if (explode)
						{
							CreateTimer(time, ExplodeMine, ref);
							time += 0.02;
							continue;
						}
						else
						{
							PrepareSound(SND_MINEREM);
							EmitSoundToAll(SND_MINEREM, c, _, _, _, 0.75);

							RemoveEdict(c);
							g_SavedEntityRef[c] = 0;
						}
					}
                }
            }
        }
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
                new TFPlayerCond:pcond = TF2_GetPlayerCond(client);
                if (TF2_IsCloaked(pcond) || TF2_IsDeadRingered(pcond))
                {
                    PrepareSound(SND_MINEERR);
                    EmitSoundToClient(client, SND_MINEERR);
                    return;
                }
                else if (TF2_IsDisguised(pcond))
                    TF2_RemovePlayerDisguise(client);
            }
            case TFClass_Scout:
            {
                if (TF2_IsPlayerBonked(client))
                {
                    PrepareSound(SND_MINEERR);
                    EmitSoundToClient(client, SND_MINEERR);
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
        if (gCount>10000)
            gCount = 1;


        // create tripmine model
        new prop_ent = CreateEntityByName("prop_physics_override");

        PrepareModel(mdlMine, gTripmineModelIndex);
        SetEntityModel(prop_ent,mdlMine);

        DispatchKeyValue(prop_ent, "spawnflags", "152");
        DispatchKeyValue(prop_ent, "StartDisabled", "false");

        if (gMineColor[team][0] != '\0')
        {
            decl String:color[4][4];
            if (ExplodeString(gMineColor[team], " ", color, sizeof(color), sizeof(color[])) <= 3)
                strcopy(color[3], sizeof(color[]), "255");

            SetEntityRenderMode(prop_ent, RENDER_TRANSCOLOR);
            SetEntityRenderColor(prop_ent, StringToInt(color[0]), StringToInt(color[1]),
                                           StringToInt(color[2]), StringToInt(color[3]));
        }

        if (DispatchSpawn(prop_ent))
        {
            SetEntProp(prop_ent, Prop_Data, "m_takedamage", 2); //  3);
            SetEntProp(prop_ent, Prop_Send, "m_usSolidFlags", 152);
            //DispatchKeyValue(prop_ent, "physdamagescale", "1.0");

            TeleportEntity(prop_ent, end, normal, NULL_VECTOR);
            DispatchKeyValue(prop_ent, "targetname", minename);

            SetEntProp(prop_ent, Prop_Data, "m_MoveCollide", 0);
            //SetEntProp(prop_ent, Prop_Data, "m_iHealth", 1);

            SetEntProp(prop_ent, Prop_Send, "m_nSolidType", 6);
            SetEntProp(prop_ent, Prop_Send, "m_iTeamNum", team, 4);
            SetEntProp(prop_ent, Prop_Send, "m_CollisionGroup", 1); // 2);

            SetEntPropEnt(prop_ent, Prop_Data, "m_hLastAttacker", client);
            SetEntPropEnt(prop_ent, Prop_Data, "m_hPhysicsAttacker", client);
            SetEntPropEnt(prop_ent, Prop_Send, "m_hOwnerEntity", client);

            SetEntityMoveType(prop_ent, MOVETYPE_NONE);
            //DispatchKeyValue(prop_ent, "SetHealth", "1");

            GetConVarString(cvRadius, tmp, sizeof(tmp));
            DispatchKeyValue(prop_ent, "ExplodeRadius", tmp);

            GetConVarString(cvDamage, tmp, sizeof(tmp));
            DispatchKeyValue(prop_ent, "ExplodeDamage", tmp);

            HookSingleEntityOutput(prop_ent, "OnBreak", mineBreak, true);

            if (gTeamSpecific > 0)
                HookSingleEntityOutput(prop_ent, "OnTouchedByEntity", mineTouched, true);
            else
                DispatchKeyValue(prop_ent, "OnTouchedByEntity", "!self,Break,,0,-1");

            AcceptEntityInput(prop_ent, "Enable");

            new prop_ref = EntIndexToEntRef(prop_ent);
            g_SavedEntityRef[prop_ent] = prop_ref;

            new beam_ent = CreateBeam(client, prop_ent, minename, beamname,
                                      beamend, end, GetConVarFloat(cvActTime),
                                      false);

            // play sound
            PrepareSound(SND_MINEPUT);
            EmitSoundToAll(SND_MINEPUT, beam_ent, SNDCHAN_AUTO,
                           SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
                           100, beam_ent, end, NULL_VECTOR, true, 0.0);

            // send message
            if (gRemaining[client] >= 0)
                PrintHintText(client, "%t", "left", gRemaining[client]);
        }
        else
            LogError("Unable to spawn a prop_ent");
    }
    else
    {
        PrintHintText(client, "%t", "locationerr");
    }
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

CreateBeam(client, prop_ent, const String:minename[], const String:beamname[],
           const Float:start[3], const Float:end[3], const Float:delay, bool:force)
{
    // create laser beam
    new beam_ent = CreateEntityByName("env_beam");
    TeleportEntity(beam_ent, start, NULL_VECTOR, NULL_VECTOR);

    PrepareModel(LASER_SPRITE, gLaserModelIndex);
    SetEntityModel(beam_ent, LASER_SPRITE);

    SetEntPropVector(beam_ent, Prop_Send, "m_vecEndPos", end);
    SetEntPropFloat(beam_ent, Prop_Send, "m_fWidth", 4.0);

    DispatchKeyValue(beam_ent, "texture", LASER_SPRITE);
    DispatchKeyValue(beam_ent, "parentname", minename);
    DispatchKeyValue(beam_ent, "targetname", beamname);
    // AcceptEntityInput(beam_ent, "AddOutput");
    DispatchKeyValue(beam_ent, "TouchType", "4");
    DispatchKeyValue(beam_ent, "LightningStart", beamname);
    DispatchKeyValue(beam_ent, "BoltWidth", "4.0");
    DispatchKeyValue(beam_ent, "life", "0");
    DispatchKeyValue(beam_ent, "rendercolor", "0 0 0");
    DispatchKeyValue(beam_ent, "renderamt", "0");
    DispatchKeyValue(beam_ent, "HDRColorScale", "1.0");
    DispatchKeyValue(beam_ent, "decalname", "Bigshot");
    DispatchKeyValue(beam_ent, "StrikeTime", "0");
    DispatchKeyValue(beam_ent, "TextureScroll", "35");

    if (gTeamSpecific > 0)
        HookSingleEntityOutput(beam_ent, "OnTouchedByEntity", beamTouched, false);
    else
    {
        decl String:tmp[64];
        Format(tmp, sizeof(tmp), "%s,Break,,0,-1", minename);
        DispatchKeyValue(beam_ent, "OnTouchedByEntity", tmp);
    }

    HookSingleEntityOutput(beam_ent, "OnBreak", beamBreak, true);
    AcceptEntityInput(beam_ent, "TurnOff");

    new prop_ref = EntIndexToEntRef(prop_ent);
    new beam_ref = EntIndexToEntRef(beam_ent);

    g_SavedEntityRef[prop_ent] = prop_ref;
    g_SavedEntityRef[beam_ent] = beam_ref;

    g_TripmineOfBeam[beam_ent] = prop_ref;
    g_BeamForTripmine[prop_ent] = beam_ref;

    new Handle:data;
    CreateDataTimer(delay, TurnBeamOn, data, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
    WritePackCell(data, client);
    WritePackCell(data, prop_ref);
    WritePackCell(data, beam_ref);
    WritePackCell(data, force);
    WritePackFloat(data, end[0]);
    WritePackFloat(data, end[1]);
    WritePackFloat(data, end[2]);

    return beam_ent;
}

public Action:TurnBeamOn(Handle:timer, Handle:data)
{
    ResetPack(data);
    new client = ReadPackCell(data);
    new prop_ref = ReadPackCell(data);
    new beam_ref = ReadPackCell(data);
    new force = ReadPackCell(data);

    new prop_ent = EntRefToEntIndex(prop_ref);
    new beam_ent = EntRefToEntIndex(beam_ref);
    if (prop_ent > 0 && beam_ent > 0 && client > 0 && IsClientInGame(client))
    {
        if (force || IsPlayerAlive(client))
        {
            new team = GetEntProp(prop_ent, Prop_Send, "m_iTeamNum");

            new String:color[4][4];
            if (ExplodeString(gBeamColor[team], " ", color, sizeof(color), sizeof(color[])) > 3)
            {
                SetEntityRenderMode(beam_ent, RENDER_TRANSCOLOR);
                SetEntityRenderColor(beam_ent, StringToInt(color[0]), StringToInt(color[1]),
                                               StringToInt(color[2]), StringToInt(color[3]));
            }
            else
                DispatchKeyValue(beam_ent, "rendercolor", gBeamColor[team]);

            AcceptEntityInput(beam_ent, "TurnOn");

            DispatchKeyValue(prop_ent, "OnHealthChanged", "!self,Break,,0,-1");
            DispatchKeyValue(prop_ent, "OnTakeDamage", "!self,Break,,0,-1");

            new Float:end[3];
            end[0] = ReadPackFloat(data);
            end[1] = ReadPackFloat(data);
            end[2] = ReadPackFloat(data);

            PrepareSound(SND_MINEACT);
            EmitSoundToAll(SND_MINEACT, beam_ent, SNDCHAN_AUTO,
                           SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
                           100, beam_ent, end, NULL_VECTOR, true, 0.0);

            return Plugin_Stop;
        }
    }

    // Player died before activation or something happened to the tripmine,

    // Remove the beam entity
    if (beam_ent > 0)
    {
        if (gTeamSpecific > 0)
            UnhookSingleEntityOutput(beam_ent, "OnTouchedByEntity", beamTouched);

        AcceptEntityInput(beam_ent, "Kill");
        g_TripmineOfBeam[beam_ent] = 0;
    }

    // Remove the tripmine entity
    if (prop_ent > 0)
    {
        UnhookSingleEntityOutput(prop_ent, "OnBreak", mineBreak);
        AcceptEntityInput(prop_ent, "Kill");
        g_BeamForTripmine[prop_ent] = 0;
    }

    return Plugin_Stop;
}

public beamTouched(const String:output[], caller, activator, Float:delay)
{
    new ref = g_SavedEntityRef[caller];
    if (ref != 0 && EntRefToEntIndex(ref) == caller) // it's an entity we created
    {
        new tripmine = EntRefToEntIndex(g_TripmineOfBeam[caller]);
        if (tripmine > 0 && IsValidEntity(tripmine))
        {
            new owner = GetEntPropEnt(tripmine, Prop_Send, "m_hOwnerEntity");
            new team = (owner > 0 && gAllowSpectators && IsClientInGame(owner))
                       ? GetClientTeam(owner) : GetEntProp(tripmine, Prop_Send, "m_iTeamNum");

            if (activator > MaxClients || (activator == owner && gTeamSpecific < 2) ||
                team != GetClientTeam(activator))
            {
                UnhookSingleEntityOutput(caller, "OnTouchedByEntity", beamTouched);
                UnhookSingleEntityOutput(caller, "OnBreak", beamBreak);
                AcceptEntityInput(caller,"Kill");
                g_SavedEntityRef[caller] = 0;
                g_TripmineOfBeam[caller] = 0;

                AcceptEntityInput(tripmine,"Break");
            }
            else if (owner > 0 && IsClientInGame(owner))
            {				
				decl Float:end[3];
				GetEntPropVector(caller, Prop_Send, "m_vecEndPos", end);
				AcceptEntityInput(caller, "TurnOff");
				
				new Handle:data;
				CreateDataTimer(GetConVarFloat(cvActTime), ToggleBeam, data, TIMER_FLAG_NO_MAPCHANGE);
				WritePackCell(data, caller);
				WritePackFloat(data, end[0]);
				WritePackFloat(data, end[1]);
				WritePackFloat(data, end[2]);
            }
            else
            {
                LogError("Orphan tripmine %d encountered!", caller);
                g_SavedEntityRef[caller] = 0;
                g_TripmineOfBeam[caller] = 0;
                RemoveEdict(caller);

                AcceptEntityInput(tripmine,"Break");
            }
        }
        else
        {
            LogError("Orphan beam %d encountered!", caller);
            g_SavedEntityRef[caller] = 0;
            g_TripmineOfBeam[caller] = 0;
            RemoveEdict(caller);
        }
    }
}

public Action:ToggleBeam(Handle:timer, Handle:data)
{
	ResetPack(data);
	new beament = ReadPackCell(data);

	if (beament == 0 || !IsValidEntity(beament))
		return Plugin_Stop;
		
	new Float:end[3];
	end[0] = ReadPackFloat(data);
	end[1] = ReadPackFloat(data);
	end[2] = ReadPackFloat(data);
	
	AcceptEntityInput(beament, "TurnOn");
	PrepareSound(SND_MINEACT);
	EmitSoundToAll(SND_MINEACT, beament, SNDCHAN_AUTO,
		SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
		100, beament, end, NULL_VECTOR, true, 0.0);
	
	return Plugin_Stop;
}

public mineTouched(const String:output[], caller, activator, Float:delay)
{
    new ref = g_SavedEntityRef[caller];
    if (ref != 0 && EntRefToEntIndex(ref) == caller) // it's an entity we created
    {
        new owner = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");
        new team = GetEntProp(caller, Prop_Send, "m_iTeamNum");

        if (activator > MaxClients || (activator == owner && gTeamSpecific < 2) ||
            team != GetClientTeam(activator))
        {
            UnhookSingleEntityOutput(caller, "OnTouchedByEntity", mineTouched);
            AcceptEntityInput(caller, "Break");
        }
        else
            HookSingleEntityOutput(caller, output, mineTouched, true);
    }
}

public mineBreak(const String:output[], caller, activator, Float:delay)
{
    new ref = g_SavedEntityRef[caller];
    if (ref != 0 && EntRefToEntIndex(ref) == caller) // it's an entity we created
    {
        new beam = EntRefToEntIndex(g_BeamForTripmine[caller]);
        if (beam > 0 && IsValidEntity(beam))
        {
            if (gTeamSpecific > 0)
                UnhookSingleEntityOutput(beam, "OnTouchedByEntity", beamTouched);

            UnhookSingleEntityOutput(beam, "OnBreak", beamBreak);
            AcceptEntityInput(beam,"Kill");
            g_SavedEntityRef[beam] = 0;
            g_TripmineOfBeam[beam] = 0;
        }

        if (gTeamSpecific > 0)
            UnhookSingleEntityOutput(caller, "OnTouchedByEntity", mineTouched);

        UnhookSingleEntityOutput(caller, "OnBreak", mineBreak);
        AcceptEntityInput(caller,"Kill");
        g_BeamForTripmine[caller] = 0;
        g_SavedEntityRef[caller] = 0;

        if (GetConVarBool(cvType))
        {
            // Set everyone in range on fire
            new team = 0;
            if (gTeamSpecific || !GetConVarBool(cvFriendlyFire))
                team = GetEntProp(caller, Prop_Send, "m_iTeamNum");

            decl Float:vecPos[3];
            GetEntPropVector(caller, Prop_Send, "m_vecOrigin", vecPos);

            new owner = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");
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
}

public beamBreak(const String:output[], caller, activator, Float:delay)
{
    new ref = g_SavedEntityRef[caller];
    if (ref != 0 && EntRefToEntIndex(ref) == caller) // it's an entity we created
    {
        if (gTeamSpecific > 0)
            UnhookSingleEntityOutput(caller, "OnTouchedByEntity", beamTouched);

        UnhookSingleEntityOutput(caller, "OnBreak", beamBreak);
        AcceptEntityInput(caller,"Kill");
        g_SavedEntityRef[caller] = 0;
        g_TripmineOfBeam[caller] = 0;
    }

    new tripmine = EntRefToEntIndex(g_TripmineOfBeam[caller]);
    if (tripmine > 0 && IsValidEntity(tripmine))
    {
        AcceptEntityInput(tripmine,"Break");
        g_BeamForTripmine[tripmine] = 0;
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
                PrintHintText(client, "%t", "nomoney", cost, gRemaining[client]);
                EmitSoundToClient(client, SND_CANTBUY);
                return Plugin_Handled;
            }

            // deal
            SetEntData(client, gAccount, money);
            gRemaining[client]++;
            EmitSoundToClient(client, SND_BUYMINE);

        } while(--cnt);
    }

    // info
    PrintHintText(client, "%t", "cntmines", gRemaining[client]);

    return Plugin_Handled;
}

public Native_ControlTripmines(Handle:plugin,numParams)
{
    if (numParams == 0)
        gNativeControl = true;
    else if(numParams == 1)
        gNativeControl = GetNativeCell(1);
}

public Native_GiveTripmines(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        gRemaining[client] = (numParams >= 2) ? GetNativeCell(2) : -1;
        gAllowed[client] = (numParams >= 3) ? GetNativeCell(3) : -1;
        gMaximum[client] = (numParams >= 4) ? GetNativeCell(4) : -1;

        if (gMaximum[client] < 0)
            gMaximum[client] = GetConVarInt(cvMaxMines);
    }
}

public Native_TakeTripmines(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        gRemaining[client] = gAllowed[client] = gMaximum[client] = 0;
    }
}

public Native_AddTripmines(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        new num = (numParams >= 2) ? GetNativeCell(2) : 1;
        gRemaining[client] += num;
    }
}

public Native_SubTripmines(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        new num = (numParams >= 2) ? GetNativeCell(2) : 1;

        gRemaining[client] -= num;
        if (gRemaining[client] < 0)
            gRemaining[client] = 0;
    }
}

public Native_HasTripmines(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        return ((numParams >= 2) && GetNativeCell(2)) ? gAllowed[client] : gRemaining[client];
    }
    else
        return -1;
}

public Native_SetTripmine(Handle:plugin,numParams)
{
    if (numParams == 1)
        SetMine(GetNativeCell(1));
}

public Native_CountTripmines(Handle:plugin,numParams)
{
    if (numParams == 1)
        return CountMines(GetNativeCell(1));
    else
        return -1;
}
