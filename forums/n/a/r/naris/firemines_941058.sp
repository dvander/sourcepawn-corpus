/*
 *  vim: set ai et ts=4 sw=4 :
 *
 *  TF2 Firemines - SourceMod Plugin
 *  Copyright (C) 2008  Marc Hörsken
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 * 
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 */

#pragma semicolon 1
#pragma dynamic 65536 

#include <sourcemod>
#include <sdktools>

#include <tf2_stocks>

#define MAXENTITIES 2048

#define PL_VERSION "3.2"

#define SOUND_A "weapons/smg_clip_out.wav"
#define SOUND_B "sc/tvumin01.wav" // "items/spawn_item.wav"
#define SOUND_C "sc/tvumin00.wav" // "ui/hint.wav"
#define SOUND_E "common/wpn_denyselect.wav"

#define MINE_MODEL "models/props_2fort/groundlight001.mdl"

// Phys prop spawnflags
#define SF_PHYSPROP_START_ASLEEP				0x000001
#define SF_PHYSPROP_DONT_TAKE_PHYSICS_DAMAGE	0x000002		// this prop can't be damaged by physics collisions
#define SF_PHYSPROP_DEBRIS						0x000004
#define SF_PHYSPROP_MOTIONDISABLED				0x000008		// motion disabled at startup (flag only valid in spawn - motion can be enabled via input)
#define	SF_PHYSPROP_TOUCH						0x000010		// can be 'crashed through' by running player (plate glass)
#define SF_PHYSPROP_PRESSURE					0x000020		// can be broken by a player standing on it
#define SF_PHYSPROP_ENABLE_ON_PHYSCANNON		0x000040		// enable motion only if the player grabs it with the physcannon
#define SF_PHYSPROP_NO_ROTORWASH_PUSH			0x000080		// The rotorwash doesn't push these
#define SF_PHYSPROP_ENABLE_PICKUP_OUTPUT		0x000100		// If set, allow the player to +USE this for the purposes of generating an output
#define SF_PHYSPROP_PREVENT_PICKUP				0x000200		// If set, prevent +USE/Physcannon pickup of this prop
#define SF_PHYSPROP_PREVENT_PLAYER_TOUCH_ENABLE	0x000400		// If set, the player will not cause the object to enable its motion when bumped into
#define SF_PHYSPROP_HAS_ATTACHED_RAGDOLLS		0x000800		// Need to remove attached ragdolls on enable motion/etc
#define SF_PHYSPROP_FORCE_TOUCH_TRIGGERS		0x001000		// Override normal debris behavior and respond to triggers anyway
#define SF_PHYSPROP_FORCE_SERVER_SIDE			0x002000		// Force multiplayer physics object to be serverside
#define SF_PHYSPROP_RADIUS_PICKUP				0x004000		// For Xbox, makes small objects easier to pick up by allowing them to be found 
#define SF_PHYSPROP_ALWAYS_PICK_UP				0x100000		// Physcannon can always pick this up, no matter what mass or constraints may apply.
#define SF_PHYSPROP_NO_COLLISIONS				0x200000		// Don't enable collisions on spawn
#define SF_PHYSPROP_IS_GIB						0x400000		// Limit # of active gibs

#define DF_FEIGNDEATH			                32              // TF2 Feign death_flag

enum DropType   { OnDeath, WithFlameThrower, OnCommand };

public Plugin:myinfo = 
{
    name = "TF2 Firemines",
    author = "Hunter",
    description = "Allows pyros to drop firemines on death or with secondary Flamethrower fire.",
    version = PL_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=71404"
}

//new bool:g_Pyros[MAXPLAYERS+1];
new bool:g_PyroButtonDown[MAXPLAYERS+1];
new Float:g_PyroPosition[MAXPLAYERS+1][3];
new g_PyroAmmo[MAXPLAYERS+1];
new g_FireminesRef[MAXENTITIES];
new g_FireminesTime[MAXENTITIES];
new bool:g_FiremineSeeking[MAXENTITIES];
new g_FireminesOwner[MAXENTITIES];
new g_FilteredEntity = -1;
new g_FiremineModelIndex;
new Handle:g_IsFireminesOn = INVALID_HANDLE;
new Handle:g_FireminesAmmo = INVALID_HANDLE;
new Handle:g_FireminesType = INVALID_HANDLE;
new Handle:g_FireminesMobile = INVALID_HANDLE;
new Handle:g_FireminesDamage = INVALID_HANDLE;
new Handle:g_FireminesRadius = INVALID_HANDLE;
new Handle:g_FireminesDetect = INVALID_HANDLE;
new Handle:g_FireminesProximity = INVALID_HANDLE;
new Handle:g_FireminesKeep = INVALID_HANDLE;
new Handle:g_FireminesStay = INVALID_HANDLE;
new Handle:g_FriendlyFire = INVALID_HANDLE;
new Handle:g_FireminesActTime = INVALID_HANDLE;
new Handle:g_FireminesLimit = INVALID_HANDLE;

new bool:g_NativeControl = false;
new g_Limit[MAXPLAYERS+1];    // how many mines player allowed
new g_Remaining[MAXPLAYERS+1];  // how many mines player has this spawn
new bool:g_ChangingClass[MAXPLAYERS+1];

// forwards
new Handle:fwdOnSetMine;

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
        TFPlayerCond_Healing,
        TFPlayerCond_OnFire,
        TFPlayerCond_Overhealed,
        TFPlayerCond_Jarated
    };

    #define TF2_IsDisguised(%1)         (((%1) & TFPlayerCond_Disguised) != TFPlayerCond_None)
    #define TF2_IsCloaked(%1)           (((%1) & TFPlayerCond_Cloaked) != TFPlayerCond_None)
    #define TF2_IsBonked(%1)            (((%1) & TFPlayerCond_Bonked) != TFPlayerCond_None)
    #define TF2_IsDeadRingered(%1)      (((%1) & TFPlayerCond_DeadRingered) != TFPlayerCond_None)

    #define TF2_IsPlayerBonked(%1)              TF2_IsBonked(TF2_GetPlayerCond(%1))

    stock TFPlayerCond:TF2_GetPlayerCond(client)
    {
        return TFPlayerCond:GetEntProp(client, Prop_Send, "m_nPlayerCond");
    }
#endif

/**
 * Description: Functions to return information about TF2 ammo.
 */
#tryinclude <tf2_ammo>
#if !defined _tf2_ammo_included
    enum TFAmmoTypes
    {
        Primary=1,
        Secondary=2,
        Metal=3
    }

    stock TF2_GetAmmoAmount(client,TFAmmoTypes:type=Primary)
    {
        return GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (_:type * 4), 4);
    }

    stock TF2_SetAmmoAmount(client, ammo,TFAmmoTypes:type=Primary)
    {
        SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (_:type * 4), ammo, 4);
    }
#endif

/**
 * Description: Stocks to return information about weapons.
 */
#tryinclude <weapons>
#if !defined _weapons_included
    stock GetCurrentWeaponClass(client, String:name[], maxlength)
    {
        new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        if (index > 0 && IsValidEntity(index))
            GetEntityNetClass(index, name, maxlength);
        else
            name[0] = '\0';
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

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    // Register Natives
    CreateNative("ControlMines",Native_ControlMines);
    CreateNative("GiveMines",Native_GiveMines);
    CreateNative("TakeMines",Native_TakeMines);
    CreateNative("AddMines",Native_AddMines);
    CreateNative("SubMines",Native_SubMines);
    CreateNative("HasMines",Native_HasMines);
    CreateNative("SetMine",Native_SetMine);

    // Register Forwards
    fwdOnSetMine=CreateGlobalForward("OnSetMine",ET_Hook,Param_Cell);

    RegPluginLibrary("firemines");
    return APLRes_Success;
}

public OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("firemines.phrases");

    CreateConVar("sm_tf_firemines", PL_VERSION, "Firemines", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_IsFireminesOn = CreateConVar("sm_firemines","3","Enable/Disable firemines (0 = disabled | 1 = on death | 2 = on command | 3 = on death and command)", _, true, 0.0, true, 3.0);
    g_FireminesAmmo = CreateConVar("sm_firemines_ammo","100","Ammo required for Firemines", _, true, 0.0, true, 200.0);
    g_FireminesType = CreateConVar("sm_firemines_type","1","Explosion type of Firemines (0 = normal explosion | 1 = fire explosion | 2 = Spider Mine (chases enemies)", _, true, 0.0, true, 1.0);
    g_FireminesMobile = CreateConVar("sm_firemines_seeking","1","Seeking mines/Spider Mines (0 = mines don't move | 1 =  Mines chase enemies", _, true, 0.0, true, 1.0);
    g_FireminesDamage = CreateConVar("sm_firemines_damage","80","Explosion damage of Firemines", _, true, 0.0, true, 1000.0);
    g_FireminesRadius = CreateConVar("sm_firemines_radius","150","Explosion radius of Firemines", _, true, 0.0, true, 1000.0);
    g_FireminesDetect = CreateConVar("sm_firemines_detect","1000","Detection radius of SpiderMines", _, true, 0.0, true, 5000.0);
    g_FireminesProximity = CreateConVar("sm_firemines_proximity","100","Proximity radius of SpiderMines", _, true, 0.0, true, 1000.0);
    g_FireminesKeep = CreateConVar("sm_firemines_keep","180","Time to keep Firemines on map. (0 = off | >0 = seconds)", _, true, 0.0, true, 600.0);
    g_FireminesStay = CreateConVar("sm_firemines_stay","1","Firemines stay if the owner dies. (0 = no | 1 = yes)", _, true, 0.0, true, 1.0);
    g_FriendlyFire = FindConVar("mp_friendlyfire");

    g_FireminesActTime = CreateConVar("sm_firemines_activate_time", "2.0", "If the owner dies before activation time, mine is removed. (0 = off)", _, true, 0.0, true, 600.0);
    g_FireminesLimit = CreateConVar("sm_firemines_limit", "-1", "Number of firemines allowed per life (-1 = unlimited)", _, true, -1.0, true, 99.0);

    HookConVarChange(g_IsFireminesOn, ConVarChange_IsFireminesOn);
    HookEvent("player_changeclass", Event_PlayerClass);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_team", Event_PlayerTeam);
    HookEvent("arena_win_panel", Event_RoundEnd);
    HookEvent("teamplay_round_win", Event_RoundEnd);
    HookEvent("teamplay_round_stalemate", Event_RoundEnd);

    RegConsoleCmd("sm_firemine", Command_Firemine);
    RegConsoleCmd("sm_mine", Command_Firemine);
    RegConsoleCmd("mine", Command_Firemine);

    if (GetConVarBool(g_FireminesType) || !GetConVarBool(g_FriendlyFire))
    {
        HookEntityOutput("prop_physics", "OnHealthChanged", EntityOutput:Entity_OnHealthChanged);
        HookEntityOutput("prop_physics_override", "OnHealthChanged", EntityOutput:Entity_OnHealthChanged);
    }

    CreateTimer(1.0, Timer_Caching, _, TIMER_REPEAT);

    AutoExecConfig(true);
}

public OnMapStart()
{
    #if !defined _ResourceManager_included
        // Setup trie to keep track of precached sounds
        if (g_precacheTrie == INVALID_HANDLE)
                g_precacheTrie = CreateTrie();
        else
                ClearTrie(g_precacheTrie);
    #endif

    decl String:file[PLATFORM_MAX_PATH+1];
    Format(file, PLATFORM_MAX_PATH, "sound/%s", SOUND_B);
    AddFileToDownloadsTable(file);

    Format(file, PLATFORM_MAX_PATH, "sound/%s", SOUND_C);
    AddFileToDownloadsTable(file);

    //PrecacheSound(SOUND_A, true);
    //PrecacheSound(SOUND_B, true);
    //PrecacheSound(SOUND_C, true);
    //PrecacheSound(SOUND_E, true);

    SetupModel(MINE_MODEL, g_FiremineModelIndex, false, true);

    //AutoExecConfig(true);
}

public OnClientDisconnect(client)
{
    //g_Pyros[client] = false;
    g_ChangingClass[client] = false;
    g_PyroButtonDown[client] = false;
    g_PyroAmmo[client] = 0;
    g_PyroPosition[client] = NULL_VECTOR;
    g_Remaining[client] = g_Limit[client] = 0;
}

// When a new client is put in the server we reset their mines count
public OnClientPutInServer(client)
{
    if(client && !IsFakeClient(client))
    {
        g_Remaining[client] = g_Limit[client] = g_NativeControl ? 0 : GetConVarInt(g_FireminesLimit);
        g_ChangingClass[client] = false;
    }

    if(!g_NativeControl && GetConVarBool(g_IsFireminesOn))
        CreateTimer(45.0, Timer_Advert, client);
}

public OnGameFrame()
{
    new FireminesOn = GetConVarInt(g_IsFireminesOn);
    if (FireminesOn < 2 && !g_NativeControl)
        return;

    for (new i = 1; i <= MaxClients; i++)
    {
        //if (g_Pyros[i] && !g_PyroButtonDown[i] && IsClientInGame(i))
        if (g_Remaining[i] && !g_PyroButtonDown[i] && IsClientInGame(i) &&
            TF2_GetPlayerClass(i) == TFClass_Pyro)
        {
            if (GetClientButtons(i) & IN_RELOAD)
            {
                g_PyroButtonDown[i] = true;
                CreateTimer(0.5, Timer_ButtonUp, i);
                new String:classname[64];
                GetCurrentWeaponClass(i, classname, 64);
                if (StrEqual(classname, "CTFFlameThrower"))
                {
                    TF_DropFiremine(i, WithFlameThrower,
                                    GetConVarBool(g_FireminesMobile));
                }
            }
        }
    }
}

public ConVarChange_IsFireminesOn(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (StringToInt(newValue) > 0)
        PrintToChatAll("[SM] %t", "Enabled Firemines");
    else
        PrintToChatAll("[SM] %t", "Disabled Firemines");
}

public Action:Command_Firemine(client, args)
{
    new FireminesOn = GetConVarInt(g_IsFireminesOn);
    if (FireminesOn < 2 && !g_NativeControl)
        return Plugin_Handled;

    new DropType:cmd;
    if (g_NativeControl)
        cmd = OnCommand;
    else
    {
        new TFClassType:class = TF2_GetPlayerClass(client);
        if (class != TFClass_Pyro)
            return Plugin_Handled;

        new String:classname[64];
        GetCurrentWeaponClass(client, classname, 64);
        if(!StrEqual(classname, "CTFFlameThrower"))
            return Plugin_Handled;

        cmd = WithFlameThrower;
    }

    new bool:seeking = false;
    decl String:arg[16];
    if (args >= 1 && GetCmdArg(1,arg,sizeof(arg)))
        seeking = bool:StringToInt(arg);

    TF_DropFiremine(client, cmd, seeking);

    return Plugin_Handled;
}

public Action:Timer_Advert(Handle:timer, any:client)
{
    if (IsClientConnected(client) && IsClientInGame(client))
    {
        new FireminesOn = GetConVarInt(g_IsFireminesOn);
        switch (FireminesOn)
        {
            case 1:
                PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnDeath Firemines");
            case 2:
                PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnCommand Firemines");
            case 3:
                PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnDeathAndCommand Firemines");
        }
    }
}

public Action:Timer_Caching(Handle:timer)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        //if (g_Pyros[i] && IsClientInGame(i))
        if (IsClientInGame(i) && IsPlayerAlive(i) &&
            (g_NativeControl ? g_Limit[i] != 0 : TF2_GetPlayerClass(i) == TFClass_Pyro))
        {
            g_PyroAmmo[i] = TF2_GetAmmoAmount(i);
            GetClientAbsOrigin(i, g_PyroPosition[i]);
        }
    }

    new FireminesKeep = GetConVarInt(g_FireminesKeep);
    if (FireminesKeep > 0)
    {
        new time = GetTime() - FireminesKeep;
        new maxents = GetMaxEntities();
        for (new c = MaxClients; c < maxents; c++)
        {
            if (g_FireminesTime[c] != 0 && g_FireminesTime[c] < time)
            {
                new ent = EntRefToEntIndex(g_FireminesRef[c]);
                if (g_FireminesTime[c] < time || ent != c)
                {
                    g_FireminesRef[c] = 0;
                    g_FireminesTime[c] = 0;
                    g_FireminesOwner[c] = 0;
                    if (c == ent && IsValidEntity(c))
                    {
                        PrepareSound(SOUND_C);
                        EmitSoundToAll(SOUND_C, c, _, _, _, 0.75);
                        RemoveEdict(c);
                    }
                }
            }
        }
    }
}

public Action:Timer_ButtonUp(Handle:timer, any:client)
{
    g_PyroButtonDown[client] = false;
}

public Action:Event_PlayerClass(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (!IsClientInGame(client))
        return;

    g_ChangingClass[client] = true;

    new FireminesStay = GetConVarInt(g_FireminesStay);
    new Float:ActTime = GetConVarFloat(g_FireminesActTime);
    if (FireminesStay < 1 || ActTime > 0.0)
    {
        new Float:time = GetTime() - ActTime;
        new maxents = GetMaxEntities();
        for (new c = MaxClients; c < maxents; c++)
        {
            if (g_FireminesOwner[c] == client)
            {
                new ent = EntRefToEntIndex(g_FireminesRef[c]);
                if (ent != c || FireminesStay < 1 || g_FireminesTime[c] < time)
                {
                    g_FireminesRef[c] = 0;
                    g_FireminesTime[c] = 0;
                    g_FireminesOwner[c] = 0;
                    if (c == ent && IsValidEntity(c))
                    {
                        PrepareSound(SOUND_C);
                        EmitSoundToAll(SOUND_C, c, _, _, _, 0.75);
                        RemoveEdict(c);
                    }
                }
            }
        }
    }

    new any:class = GetEventInt(event, "class");
    if (class != TFClass_Pyro)
    {
        //g_Pyros[client] = false;
        if (!g_NativeControl)
            return;
    }
    //g_Pyros[client] = true;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (g_ChangingClass[client])
        g_ChangingClass[client]=false;
    else
    {
        if (g_NativeControl)
            g_Remaining[client] = g_Limit[client];
        else
            g_Remaining[client] = g_Limit[client] = GetConVarInt(g_FireminesLimit);
    }

    return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new FireminesOn = GetConVarInt(g_IsFireminesOn);
    if (FireminesOn < 1 && !g_NativeControl)
        return;

    // Skip feigned deaths.
    if (GetEventInt(event, "death_flags") & DF_FEIGNDEATH)
        return;

    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    //if (!g_Pyros[client] || !IsClientInGame(client))
    if (!IsClientInGame(client))
        return;

    if (!g_NativeControl)
    {
        new TFClassType:class = TF2_GetPlayerClass(client);	
        if (class != TFClass_Pyro)
            return;
    }

    g_ChangingClass[client] = false;

    new FireminesStay = GetConVarInt(g_FireminesStay);
    new Float:ActTime = GetConVarFloat(g_FireminesActTime);
    if (FireminesStay < 1 || ActTime > 0.0)
    {
        new Float:time = GetTime() - ActTime;
        new maxents = GetMaxEntities();
        for (new c = MaxClients; c < maxents; c++)
        {
            if (g_FireminesOwner[c] == client)
            {
                new ent = EntRefToEntIndex(g_FireminesRef[c]);
                if (ent != c || FireminesStay < 1 || g_FireminesTime[c] < time)
                {
                    g_FireminesRef[c] = 0;
                    g_FireminesTime[c] = 0;
                    g_FireminesOwner[c] = 0;
                    if (c == ent && IsValidEntity(c))
                    {
                        PrepareSound(SOUND_C);
                        EmitSoundToAll(SOUND_C, c, _, _, _, 0.75);
                        RemoveEdict(c);
                    }
                }
            }
        }
    }

    if (g_NativeControl)
    {
        if (g_Remaining[client] == 0)
            return;
    }

    if (FireminesOn != 2 || g_NativeControl)
        TF_DropFiremine(client, OnDeath, false);
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client != 0)
    {
        new team = GetEventInt(event, "team");
        if (team < 2 && IsClientInGame(client))
        {
            //g_Pyros[client] = false;
            g_PyroButtonDown[client] = false;
            g_PyroAmmo[client] = 0;
            g_PyroPosition[client] = NULL_VECTOR;
        }
    }
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    new maxents = GetMaxEntities();
    for (new c = MaxClients; c < maxents; c++)
    {
        new ent = EntRefToEntIndex(g_FireminesRef[c]);
        g_FireminesOwner[c] = 0;
        g_FireminesTime[c] = 0;
        g_FireminesRef[c] = 0;
        if (c == ent && IsValidEntity(c))
            RemoveEdict(c);
    }
}

public Entity_OnHealthChanged(const String:output[], caller, activator, Float:delay)
{
    if (caller > 0 && activator > 0 && activator <= MaxClients &&
        g_FireminesTime[caller] > 0 && IsClientInGame(activator))
    {
        // Make sure it's a Firemine and the owner is still in the game
        new owner=g_FireminesOwner[caller];
        if (caller == EntRefToEntIndex(g_FireminesRef[caller]) && IsClientInGame(owner))
        {
            new team = 0;
            if (!GetConVarBool(g_FriendlyFire))
                team = GetEntProp(caller, Prop_Data, "m_iTeamNum");

            if (team != GetClientTeam(activator) || activator == owner)
            {
                if (GetConVarBool(g_FireminesType))
                {
                    decl Float:vecPos[3];
                    GetEntPropVector(caller, Prop_Send, "m_vecOrigin", vecPos);

                    decl Float:PlayerPosition[3];
                    new Float:maxdistance = GetConVarFloat(g_FireminesRadius);
                    for (new i = 1; i <= MaxClients; i++)
                    {
                        if (IsClientInGame(i))
                        {
                            GetClientAbsOrigin(i, PlayerPosition);
                            new Float:distance = GetVectorDistance(PlayerPosition, vecPos);
                            if (distance < 0.0)
                                distance *= -1.0;

                            if (distance <= maxdistance)
                            {
                                if (i == owner)
                                    IgniteEntity(i, 2.5);
                                else if (team != GetClientTeam(i))
                                {
                                    if (!TF2_IsPlayerUbercharged(i))
                                    {
                                        if (owner > 0 && IsClientInGame(owner))
                                            TF2_IgnitePlayer(i, owner);
                                        else
                                            IgniteEntity(i, 2.5);
                                    }
                                }
                            }

                            //if (g_Pyros[i])
                            if (g_Remaining[i])
                            {
                                g_PyroAmmo[i] = TF2_GetAmmoAmount(i);
                                g_PyroPosition[i] = PlayerPosition;
                            }
                        }
                    }
                }

                AcceptEntityInput(caller, "Break", owner, owner);
                CreateTimer(0.1, RemoveMine, EntIndexToEntRef(caller));

                g_FireminesRef[caller] = 0;
                g_FireminesTime[caller] = 0;
                g_FireminesOwner[caller] = 0;
            }
        }
    }
}

public bool:FiremineTraceFilter(ent, contentMask)
{
    return (ent != g_FilteredEntity);
}

TF_SpawnFiremine(client, DropType:cmd, bool:seeking)
{
    new Float:PlayerPosition[3];
    if (cmd != OnDeath)
        GetClientAbsOrigin(client, PlayerPosition);
    else
        PlayerPosition = g_PyroPosition[client];

    if (PlayerPosition[0] != 0.0 && PlayerPosition[1] != 0.0 &&
        PlayerPosition[2] != 0.0 && !IsEntLimitReached(100, .message="unable to create mine"))
    {
        PlayerPosition[2] += 4.0;
        g_FilteredEntity = client;
        if (cmd != OnDeath)
        {
            new Float:PlayerPosEx[3], Float:PlayerAngle[3], Float:PlayerPosAway[3];
            GetClientEyeAngles(client, PlayerAngle);
            PlayerPosEx[0] = Cosine((PlayerAngle[1]/180)*FLOAT_PI);
            PlayerPosEx[1] = Sine((PlayerAngle[1]/180)*FLOAT_PI);
            PlayerPosEx[2] = 0.0;
            ScaleVector(PlayerPosEx, 75.0);
            AddVectors(PlayerPosition, PlayerPosEx, PlayerPosAway);

            new Handle:TraceEx = TR_TraceRayFilterEx(PlayerPosition, PlayerPosAway, MASK_SOLID,
                                                     RayType_EndPoint, FiremineTraceFilter);
            TR_GetEndPosition(PlayerPosition, TraceEx);
            CloseHandle(TraceEx);
        }

        new Float:Direction[3];
        Direction[0] = PlayerPosition[0];
        Direction[1] = PlayerPosition[1];
        Direction[2] = PlayerPosition[2]-1024;
        new Handle:Trace = TR_TraceRayFilterEx(PlayerPosition, Direction, MASK_SOLID,
                                               RayType_EndPoint, FiremineTraceFilter);

        new Float:MinePos[3];
        TR_GetEndPosition(MinePos, Trace);
        CloseHandle(Trace);
        MinePos[2] += 1;

        new Firemine = CreateEntityByName("prop_physics_override");
        if (IsValidEntity(Firemine))
        {
            if (seeking)
                DispatchKeyValue(Firemine, "spawnflags", "48");
            else
                DispatchKeyValue(Firemine, "spawnflags", "152");

            SetEntPropEnt(Firemine, Prop_Data, "m_hOwnerEntity", client);
            SetEntPropFloat(Firemine, Prop_Data, "m_flGravity", 0.0);

            // Ensure the mine model is precached
            PrepareModel(MINE_MODEL, g_FiremineModelIndex);
            SetEntityModel(Firemine, MINE_MODEL);

            new String:targetname[32];
            Format(targetname, sizeof(targetname), "firemine_%d", Firemine);
            DispatchKeyValue(Firemine, "targetname", targetname);

            new team = GetConVarBool(g_FriendlyFire) ? 0 : GetClientTeam(client);
            SetEntProp(Firemine, Prop_Send, "m_iTeamNum", team, 4);
            SetEntProp(Firemine, Prop_Data, "m_nSolidType", 6);
            SetEntProp(Firemine, Prop_Data, "m_takedamage", 3);
            SetEntPropEnt(Firemine, Prop_Data, "m_hLastAttacker", client);
            SetEntPropEnt(Firemine, Prop_Data, "m_hPhysicsAttacker", client);
            DispatchKeyValue(Firemine, "physdamagescale", "1.0");

            DispatchKeyValue(Firemine, "StartDisabled", "false");
            DispatchSpawn(Firemine);

            TeleportEntity(Firemine, MinePos, NULL_VECTOR, NULL_VECTOR);

            DispatchKeyValue(Firemine, "OnBreak", "!self,Kill,,0,-1");
            DispatchKeyValueFloat(Firemine, "ExplodeDamage", GetConVarFloat(g_FireminesDamage));
            DispatchKeyValueFloat(Firemine, "ExplodeRadius", GetConVarFloat(g_FireminesRadius));

            // we might handle this ourself now...
            if (!GetConVarBool(g_FireminesType) && GetConVarBool(g_FriendlyFire))
                DispatchKeyValue(Firemine, "OnHealthChanged", "!self,Break,,0,-1");

            PrepareSound(SOUND_B);
            EmitSoundToAll(SOUND_B, Firemine, _, _, _, 0.75);

            g_FireminesRef[Firemine] = EntIndexToEntRef(Firemine);
            g_FireminesTime[Firemine] = GetTime();
            g_FireminesOwner[Firemine] = client;
            g_FiremineSeeking[Firemine] =  false;
            return Firemine;
        }
    }
    return 0;
}

bool:TF_DropFiremine(client, DropType:cmd, bool:seeking)
{
    if (g_Remaining[client] <= 0 && g_Limit[client] >= 0)
    {
        if (IsClientInGame(client))
        {
            PrepareSound(SOUND_A);
            EmitSoundToClient(client, SOUND_A, _, _, _, _, 0.75);
            PrintHintText(client, "You do not have any mines.");
        }
        return false;
    }

    new ammo = (cmd == OnDeath) ? g_PyroAmmo[client] : TF2_GetAmmoAmount(client);
    new FireminesAmmo = GetConVarInt(g_FireminesAmmo);
    new TFClassType:class = TF2_GetPlayerClass(client);
    switch (class)
    {
        case TFClass_Medic:     FireminesAmmo = RoundToNearest(float(FireminesAmmo) / 1.33);
        case TFClass_Scout:     FireminesAmmo = RoundToNearest(float(FireminesAmmo) / 6.5);
        case TFClass_Engineer:  FireminesAmmo = RoundToNearest(float(FireminesAmmo) / 6.5);
        case TFClass_Soldier:   FireminesAmmo = RoundToNearest(float(FireminesAmmo) / 12.5);
        case TFClass_DemoMan:   FireminesAmmo = RoundToNearest(float(FireminesAmmo) / 12.5);
        case TFClass_Sniper:    FireminesAmmo /= 10;
        case TFClass_Spy:       FireminesAmmo /= 10;
    }

    if (ammo >= FireminesAmmo)
    {
        new Action:res = Plugin_Continue;
        Call_StartForward(fwdOnSetMine);
        Call_PushCell(client);
        Call_Finish(res);
        if (res != Plugin_Continue)
            return false;

        if (cmd != OnDeath)
        {
            switch (class)
            {
                case TFClass_Spy:
                {
                    new TFPlayerCond:pcond = TF2_GetPlayerCond(client);
                    if (TF2_IsCloaked(pcond) || TF2_IsDeadRingered(pcond))
                    {
                        PrepareSound(SOUND_E);
                        EmitSoundToClient(client, SOUND_E);
                        return false;
                    }
                    else if (TF2_IsDisguised(pcond))
                        TF2_RemovePlayerDisguise(client);
                }
                case TFClass_Scout:
                {
                    if (TF2_IsPlayerBonked(client))
                    {
                        PrepareSound(SOUND_E);
                        EmitSoundToClient(client, SOUND_E);
                        return false;
                    }
                }
            }

            ammo -= FireminesAmmo;
            g_PyroAmmo[client] = ammo;
            TF2_SetAmmoAmount(client, ammo);

            // update client's inventory
            if (g_Remaining[client] > 0)
                g_Remaining[client]--;
        }

        new mine = TF_SpawnFiremine(client, cmd, bool:seeking);

        if (seeking)
        {
            new Float:ActTime = GetConVarFloat(g_FireminesActTime);
            CreateTimer(ActTime, MineActivate, EntIndexToEntRef(mine));
        }

        return true;
    }
    else if (cmd != OnDeath)
    {
        PrepareSound(SOUND_A);
        EmitSoundToClient(client, SOUND_A, _, _, _, _, 0.75);
    }
    return false;
}

public Action:RemoveMine(Handle:timer, any:mineRef)
{
    // Remove the mine, if it's still there
    new mine = EntRefToEntIndex(mineRef);
    if (mine > 0 && IsValidEntity(mine))
    {
        LogError("Removing Mine %d!", mine);
        RemoveEdict(mine);
        g_FireminesRef[mine] = 0;
        g_FireminesTime[mine] = 0;
        g_FireminesOwner[mine] = 0;
    }
    return Plugin_Stop;
}

public Action:MineActivate(Handle:timer, any:mineRef)
{
    // Ensure the entity is still a mine
    new mine = EntRefToEntIndex(mineRef);
    if (mine > 0 && IsValidEntity(mine))
        CreateTimer(0.2, MineSeek, mineRef, TIMER_REPEAT);

    return Plugin_Stop;
}

public Action:MineSeek(Handle:timer, any:mineRef)
{
    // Ensure the entity is still a mine
    new mine = EntRefToEntIndex(mineRef);
    if (mine > 0 && IsValidEntity(mine))
    {
        decl Float:minePos[3], Float:PlayerPosition[3];
        GetEntPropVector(mine, Prop_Send, "m_vecOrigin", minePos);

        new target = 0;
        new team = GetEntProp(mine, Prop_Data, "m_iTeamNum");
        new Float:detect = GetConVarFloat(g_FireminesDetect);
        new Float:proximity = GetConVarFloat(g_FireminesProximity);

        // Find closest enemy within range
        for (new i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && IsPlayerAlive(i) &&
                GetClientTeam(i) != team)
            {
                GetClientAbsOrigin(i, PlayerPosition);
                new Float:distance = GetVectorDistance(minePos, PlayerPosition);
                if (distance < 0.0)
                    distance *= -1.0;

                if (distance <= detect)
                {
                    if (distance <= proximity)
                    {
                        TR_TraceRayFilter(minePos, PlayerPosition, MASK_SOLID, RayType_EndPoint,
                                TraceRayDontHitSelf, mine);
                        if (TR_GetEntityIndex() == i)
                        {
                            // Explode when within proximity range!
                            Entity_OnHealthChanged("OnProximity", mine, i, 0.0);
                            return Plugin_Stop;
                        }
                    }

                    TR_TraceRayFilter(minePos, PlayerPosition, MASK_SOLID, RayType_EndPoint,
                                      TraceRayDontHitSelf, mine);
                    if (TR_GetEntityIndex() == i)
                    {
                        target = i;
                        detect = distance;
                    }
                }
            }
        }

        // Did we find a target?
        if (target > 0)
        {
            decl Float:vector[3], Float:angles[3];
            GetClientEyePosition(target, PlayerPosition);
            MakeVectorFromPoints(minePos, PlayerPosition, vector);
            NormalizeVector(vector, vector);

            GetVectorAngles(vector, angles);
            TeleportEntity(mine, NULL_VECTOR, angles, NULL_VECTOR);

            SetEntityRenderMode(mine, RENDER_GLOW);
            SetEntityRenderColor(mine, (team == 2) ? 255 : 0, 0, (team == 3) ? 0 : 255, 255);

            if (!g_FiremineSeeking[mine])
            {
                minePos[2] += 20.0;

                TeleportEntity(mine, minePos, NULL_VECTOR, NULL_VECTOR);
                g_FiremineSeeking[mine] =  true;
            }

            decl Float:velocity[3];
            velocity[0] = vector[0] * 80.0;
            velocity[1] = vector[1] * 80.0;
            velocity[2] = 10.0;

            TeleportEntity(mine, NULL_VECTOR, NULL_VECTOR, velocity);

            PrepareSound(SOUND_C);
            EmitSoundToAll(SOUND_C, mine);
        }
        else if (g_FiremineSeeking[mine])
        {
            new Float:angles[3] = {0.0,0.0,0.0};
            TeleportEntity(mine, NULL_VECTOR, angles, NULL_VECTOR);

            new Float:vecBelow[3];
            vecBelow[0] = minePos[0];
            vecBelow[1] = minePos[1];
            vecBelow[2] = minePos[2] - 2000.0;
            TR_TraceRayFilter(minePos, vecBelow, MASK_PLAYERSOLID, RayType_EndPoint,
                    TraceRayDontHitSelf, mine);
            if (TR_DidHit(INVALID_HANDLE))
            {
                // Move mine down to ground.
                TR_GetEndPosition(minePos, INVALID_HANDLE);
                TeleportEntity(mine, minePos, NULL_VECTOR, NULL_VECTOR);
            }

            SetEntityRenderColor(mine, 255, 255, 255, 255);
            SetEntityRenderMode(mine, RENDER_NORMAL);
            g_FiremineSeeking[mine] =  false;

            PrepareSound(SOUND_B);
            EmitSoundToAll(SOUND_B, mine);
        }
        return Plugin_Continue;
    }
    return Plugin_Stop;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
    return (entity != data); // Check if the TraceRay hit the itself.
}

public Native_ControlMines(Handle:plugin,numParams)
{
    if (numParams == 0)
        g_NativeControl = true;
    else if(numParams == 1)
        g_NativeControl = GetNativeCell(1);
}

public Native_GiveMines(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        g_Remaining[client] = (numParams >= 2) ? GetNativeCell(2) : -1;
        g_Limit[client] = (numParams >= 3) ? GetNativeCell(3) : -1;
    }
}

public Native_TakeMines(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        g_Remaining[client] = g_Limit[client] = 0;
    }
}

public Native_AddMines(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        if (g_Limit[client] >= 0)
        {
            new num = (numParams >= 2) ? GetNativeCell(2) : 1;
            g_Remaining[client] += num;
        }
    }
}

public Native_SubMines(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        if (g_Limit[client] >= 0)
        {
            new num = (numParams >= 2) ? GetNativeCell(2) : 1;

            g_Remaining[client] -= num;
            if (g_Remaining[client] < 0)
                g_Remaining[client] = 0;
        }
    }
}

public Native_HasMines(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new client = GetNativeCell(1);
        return ((numParams >= 2) && GetNativeCell(2)) ? g_Limit[client] : g_Remaining[client];
    }
    else
        return -1;
}

public Native_SetMine(Handle:plugin,numParams)
{
    if (numParams >= 1)
    {
        new bool:seeking = (numParams >= 2) ? (bool:GetNativeCell(2)) : false;
        TF_DropFiremine(GetNativeCell(1), OnCommand, seeking);
    }
}
