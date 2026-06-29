/*
    Fakebomb

    Basically timebomb with no actual killing.
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION          "0x02"

#define TF_MAX_PLAYERS          34
#define FCVAR_VERSION           FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_CHEAT

public Plugin:myinfo =
{
    name = "Fun Commands - Fakebomb",
    author = "AlliedModders LLC & Chdata",
    description = "Fun Commands - Fakebomb",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/groups/tf2data"
};

new String:g_BeepSound[PLATFORM_MAX_PATH];
new String:g_FinalSound[PLATFORM_MAX_PATH];
new String:g_BoomSound[PLATFORM_MAX_PATH];

// Following are model indexes for temp entities
new g_BeamSprite        = -1;
new g_HaloSprite        = -1;
new g_ExplosionSprite   = -1;

// Basic color arrays for temp entities
new whiteColor[4]   = {255, 255, 255, 255};
new greyColor[4]    = {128, 128, 128, 255};

// Serial Generator for Timer Safety
new g_Serial_Gen = 0;

// Flags used in various timers
#define DEFAULT_TIMER_FLAGS TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE

new g_TimeBombSerial[MAXPLAYERS + 1] = { 0, ... };
new g_TimeBombTime[MAXPLAYERS + 1] = { 0, ... };

new Handle:g_Cvar_TimeBombTicks = INVALID_HANDLE;
new Handle:g_Cvar_TimeBombRadius = INVALID_HANDLE;

public OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("funcommands.phrases");

    // timebomb
    g_Cvar_TimeBombTicks = CreateConVar("sm_fakebomb_ticks", "10.0", "Sets how long the fakebomb fuse is.", 0, true, 5.0, true, 120.0);
    g_Cvar_TimeBombRadius = CreateConVar("sm_fakebomb_radius", "600", "Sets the fakebomb's blast radius.", 0, true, 50.0, true, 3000.0);
    //g_Cvar_TimeBombMode = CreateConVar("sm_fakebomb_mode", "0", "Who is killed by the fakebomb? 0 = Target only, 1 = Target's team, 2 = Everyone", 0, true, 0.0, true, 2.0);
    
    AutoExecConfig(true, "ch.fakebomb");

    RegAdminCmd("sm_fakebomb", Command_TimeBomb, ADMFLAG_SLAY, "sm_fakebomb <#userid|name> [0/1]");
    RegAdminCmd("sm_warnbomb", Command_TimeBomb, ADMFLAG_SLAY, "sm_fakebomb <#userid|name> [0/1]");

    decl String:folder[64];
    GetGameFolderName(folder, sizeof(folder));

    if (strcmp(folder, "tf") == 0)
    {
        HookEvent("teamplay_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
        HookEvent("teamplay_restart_round", Event_RoundEnd, EventHookMode_PostNoCopy);
        HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
    }
    else if (strcmp(folder, "nucleardawn") == 0)
    {
        HookEvent("round_win", Event_RoundEnd, EventHookMode_PostNoCopy);
    }
    else
    {
        HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
    }

    CreateConVar("cv_fakebomb_version", PLUGIN_VERSION, "Fakebomb Version", FCVAR_VERSION);
}

public OnMapStart()
{
    new Handle:gameConfig = LoadGameConfigFile("funcommands.games");
    if (gameConfig == INVALID_HANDLE)
    {
        SetFailState("Unable to load game config funcommands.games");
        return;
    }
    
    if (GameConfGetKeyValue(gameConfig, "SoundBeep", g_BeepSound, sizeof(g_BeepSound)) && g_BeepSound[0])
    {
        PrecacheSound(g_BeepSound, true);
    }
    
    if (GameConfGetKeyValue(gameConfig, "SoundFinal", g_FinalSound, sizeof(g_FinalSound)) && g_FinalSound[0])
    {
        PrecacheSound(g_FinalSound, true);
    }
    
    if (GameConfGetKeyValue(gameConfig, "SoundBoom", g_BoomSound, sizeof(g_BoomSound)) && g_BoomSound[0])
    {
        PrecacheSound(g_BoomSound, true);
    }
    
    new String:buffer[PLATFORM_MAX_PATH];
    if (GameConfGetKeyValue(gameConfig, "SpriteBeam", buffer, sizeof(buffer)) && buffer[0])
    {
        g_BeamSprite = PrecacheModel(buffer);
    }
    
    if (GameConfGetKeyValue(gameConfig, "SpriteExplosion", buffer, sizeof(buffer)) && buffer[0])
    {
        g_ExplosionSprite = PrecacheModel(buffer);
    }

    if (GameConfGetKeyValue(gameConfig, "SpriteHalo", buffer, sizeof(buffer)) && buffer[0])
    {
        g_HaloSprite = PrecacheModel(buffer);
    }
    
    CloseHandle(gameConfig);
}

public OnMapEnd()
{
    KillAllTimeBombs();
}

public Action:Event_RoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
    KillAllTimeBombs();
}

CreateTimeBomb(client)
{
    g_TimeBombSerial[client] = ++g_Serial_Gen;
    CreateTimer(1.0, Timer_TimeBomb, client | (g_Serial_Gen << 7), DEFAULT_TIMER_FLAGS);
    g_TimeBombTime[client] = GetConVarInt(g_Cvar_TimeBombTicks);
}

KillTimeBomb(client)
{
    g_TimeBombSerial[client] = 0;

    if (IsClientInGame(client))
    {
        SetEntityRenderColor(client, 255, 255, 255, 255);
    }
}

KillAllTimeBombs()
{
    for (new i = 1; i <= MaxClients; i++)
    {
        KillTimeBomb(i);
    }
}

PerformTimeBomb(client, target)
{
    if (g_TimeBombSerial[target] == 0)
    {
        CreateTimeBomb(target);
        LogAction(client, target, "\"%L\" set a FakeBomb on \"%L\"", client, target);
    }
    else
    {
        KillTimeBomb(target);
        SetEntityRenderColor(client, 255, 255, 255, 255);
        LogAction(client, target, "\"%L\" removed a FakeBomb on \"%L\"", client, target);
    }
}

public Action:Timer_TimeBomb(Handle:timer, any:value)
{
    new client = value & 0x7f;
    new serial = value >> 7;

    if (!IsClientInGame(client)
        || !IsPlayerAlive(client)
        || serial != g_TimeBombSerial[client])
    {
        KillTimeBomb(client);
        return Plugin_Stop;
    }   
    g_TimeBombTime[client]--;
    
    new Float:vec[3];
    GetClientEyePosition(client, vec);
    
    if (g_TimeBombTime[client] > 0)
    {
        new color;
        
        if (g_TimeBombTime[client] > 1)
        {
            color = RoundToFloor(g_TimeBombTime[client] * (128.0 / GetConVarFloat(g_Cvar_TimeBombTicks)));
            if (g_BeepSound[0])
            {
                EmitAmbientSound(g_BeepSound, vec, client, SNDLEVEL_RAIDSIREN); 
            }
        }
        else
        {
            color = 0;
            if (g_FinalSound[0])
            {
                EmitAmbientSound(g_FinalSound, vec, client, SNDLEVEL_RAIDSIREN);
            }
        }
        
        SetEntityRenderColor(client, 255, 128, color, 255);

        decl String:name[64];
        GetClientName(client, name, sizeof(name));
        PrintCenterTextAll("%t", "Till Explodes", name, g_TimeBombTime[client]);
        
        if (g_BeamSprite > -1 && g_HaloSprite > -1)
        {
            GetClientAbsOrigin(client, vec);
            vec[2] += 10;

            TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_Cvar_TimeBombRadius) / 3.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
            TE_SendToAll();
            TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_Cvar_TimeBombRadius) / 3.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, whiteColor, 10, 0);
            TE_SendToAll();
        }
        return Plugin_Continue;
    }
    else
    {
        if (g_ExplosionSprite > -1)
        {
            TE_SetupExplosion(vec, g_ExplosionSprite, 5.0, 1, 0, GetConVarInt(g_Cvar_TimeBombRadius), 5000);
            TE_SendToAll();
        }

        if (g_BoomSound[0])
        {
            EmitAmbientSound(g_BoomSound, vec, client, SNDLEVEL_RAIDSIREN);
        }

        //ForcePlayerSuicide(client);
        KillTimeBomb(client);
        SetEntityRenderColor(client, 255, 255, 255, 255);
        
        return Plugin_Stop;
    }
}

public Action:Command_TimeBomb(client, args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_fakebomb <#userid|name>");
        return Plugin_Handled;
    }

    decl String:arg[65];
    GetCmdArg(1, arg, sizeof(arg));

    decl String:target_name[MAX_TARGET_LENGTH];
    decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
    
    if ((target_count = ProcessTargetString(
            arg,
            client,
            target_list,
            MAXPLAYERS,
            COMMAND_FILTER_ALIVE,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
    {
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }
    
    for (new i = 0; i < target_count; i++)
    {
        PerformTimeBomb(client, target_list[i]);
    }
    
    if (tn_is_ml)
    {
        ShowActivity2(client, "[SM] ", "%t", "Toggled TimeBomb on target", target_name);
    }
    else
    {
        ShowActivity2(client, "[SM] ", "%t", "Toggled TimeBomb on target", "_s", target_name);
    }
    
    return Plugin_Handled;
}
