#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.3"

#define RED 2
#define BLU 3

#define FLAG_RED_IGNORE_PRIMARY (1 << 0)        // 1
#define FLAG_BLU_IGNORE_PRIMARY (1 << 1)        // 2
#define FLAG_RED_IGNORE_ACTION  (1 << 2)        // 4
#define FLAG_BLU_IGNORE_ACTION  (1 << 3)        // 8

new g_flags;
new g_tauntdelay;
new g_actiontauntdelay;

public Plugin:myinfo =
{
    name = "Taunt Rate Control",
    author = "Friagram",
    description = "Limits the Funs even more",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/groups/poniponiponi"
};

public OnPluginStart()
{
    CreateConVar("ftauntlimit_version", PLUGIN_VERSION, "Taunt Rate Control", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

    new Handle:cvar;
    HookConVarChange(cvar = CreateConVar("sm_taunt_flags", "0", "Filter Flags", FCVAR_PLUGIN, true, 0.0), ConVarFilterChanged);
    g_flags = GetConVarInt(cvar);

    HookConVarChange(cvar = CreateConVar("sm_taunt_primary", "0", "Taunt delay after normal taunts", FCVAR_PLUGIN, true, -1.0), ConVarPrimaryChanged);
    g_tauntdelay = GetConVarInt(cvar);

    HookConVarChange(cvar = CreateConVar("sm_taunt_action", "-1", "Allow action-type taunts", FCVAR_PLUGIN, true, -1.0), ConVarActionChanged);
    g_actiontauntdelay = GetConVarInt(cvar);

    AddCommandListener(Command_InterceptTaunt, "+taunt");
    AddCommandListener(Command_InterceptTaunt, "taunt");
}

public ConVarFilterChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
    g_flags = StringToInt(newvalue);
}
public ConVarPrimaryChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
    g_tauntdelay = StringToInt(newvalue);
}
public ConVarActionChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
    g_actiontauntdelay = StringToInt(newvalue);
}

public Action:Command_InterceptTaunt(client, const String:command[], args)
{	
    static LastTauntTime[MAXPLAYERS+1][2];
    
    if(IsClientInGame(client))
    {
        if(TF2_IsPlayerInCondition(client, TFCond_Taunting))    // !GetEntityFlags(client) & FL_ONGROUND < they could have slide taunt enabled
        {
            return Plugin_Handled;
        }

        new time = GetTime();

        decl String:arg[3]; 
        GetCmdArg(1, arg, 3);

        if(StringToInt(arg) > 0)                                                 // it's an action taunt
        {
            if(g_flags)                                                         // most people won't even use this
            {
                switch(GetClientTeam(client))
                {
                    case RED:
                    {
                        if(g_flags & FLAG_RED_IGNORE_ACTION)
                        {
                            return Plugin_Continue;
                        }
                    }
                    case BLU:
                    {
                        if(g_flags & FLAG_BLU_IGNORE_ACTION)
                        {
                            return Plugin_Continue;
                        }
                    }
                }
            }

            if(g_actiontauntdelay == -1)                                       // never allow primary taunts
            {
                return Plugin_Handled;
            }
            else if(g_actiontauntdelay > 0)                                    // there's a delay to enforce
            {
                if(LastTauntTime[client][1] < time)
                {
                    LastTauntTime[client][1] = time + g_actiontauntdelay;
                    return Plugin_Continue;
                }

                return Plugin_Handled;
            }
        }
        else                                                                     // assuming it's an primary taunt
        {
            if(g_flags)                                                         // most people won't even use this
            {
                switch(GetClientTeam(client))
                {
                    case RED:
                    {
                        if(g_flags & FLAG_RED_IGNORE_PRIMARY)
                        {
                            return Plugin_Continue;
                        }
                    }
                    case BLU:
                    {
                        if(g_flags & FLAG_BLU_IGNORE_PRIMARY)
                        {
                            return Plugin_Continue;
                        }
                    }
                }
            }

            if(g_tauntdelay == -1)                                              // never allow primary taunts
            {
                return Plugin_Handled;
            }
            else if(g_tauntdelay > 0)                                           // there's a delay to enforce
            {
                if(LastTauntTime[client][0] < time)
                {
                    LastTauntTime[client][0] = time + g_tauntdelay;           // assuming it's a normal taunt
                    return Plugin_Continue;
                }

                return Plugin_Handled;
            }
        }
    }

    return Plugin_Continue;
}