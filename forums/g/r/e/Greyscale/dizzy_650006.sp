/**
 * ====================
 *        Dizzy
 *   File: dizzy.sp
 *   Author: Greyscale
 * ==================== 
 */

#pragma semicolon 1
#include <sourcemod>

#define VERSION "1.0.1"

new offsPunchAngle;

new bool:bDizzy[MAXPLAYERS+1];
new Float:flMagnitude[MAXPLAYERS+1];

public Plugin:myinfo =
{
    name = "PunchShot", 
    author = "Greyscale", 
    description = "Punishment that spins the player's view in random directions making it very difficult to walk", 
    version = VERSION, 
    url = ""
};

public OnPluginStart()
{
    LoadTranslations("common.phrases.txt");
    LoadTranslations("dizzy.phrases.txt");
    
    // ======================================================================
    
    offsPunchAngle = FindSendPropInfo("CBasePlayer", "m_vecPunchAngle");
    if (offsPunchAngle == -1)
    {
        SetFailState("Couldn't find \"m_vecPunchAngle\"!");
    }
    
    // ======================================================================
    
    HookEvent("player_spawn", StopDizzy);
    HookEvent("player_death", StopDizzy);
    
    // ======================================================================
    
    RegAdminCmd("sm_dizzy", Command_Dizzy, ADMFLAG_GENERIC, "sm_dizzy <#userid|name> [magnitude]");
    
    // ======================================================================
    
    CreateConVar("gs_smdizzy_version", VERSION, "[SMDizzy] Current version of this plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnMapStart()
{
    CreateTimer(0.5, Dizzy, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnClientPutInServer(client)
{
    bDizzy[client] = false;
}

public Action:Command_Dizzy(client, argc)
{
    if (argc < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_dizzy <#userid|name> [magnitude]");
        
        return Plugin_Handled;
    }
    
    decl String:arg1[32];
    GetCmdArg(1, arg1, sizeof(arg1));
    
    decl String:target_name[MAX_TARGET_LENGTH];
    new targets[MAXPLAYERS];
    new bool:tn_is_ml;
    
    new tcount = ProcessTargetString(arg1, client, targets, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml);
    if (tcount <= 0)
    {
        ReplyToTargetError(client, tcount);
        return Plugin_Handled;
    }
    
    new Float:magnitude;
    if (argc >= 2)
    {
        decl String:arg2[8];
        GetCmdArg(2, arg2, sizeof(arg2));
        magnitude = StringToFloat(arg2);
    }
    
    if (magnitude > 0.0)
    {
        for (new x = 0; x < tcount; x++)
        {
            bDizzy[targets[x]] = true;
            flMagnitude[targets[x]] = magnitude;
        }
    }
    else
    {
        for (new x = 0; x < tcount; x++)
        {
            bDizzy[targets[x]] = !bDizzy[targets[x]];
            flMagnitude[targets[x]] = 300.0;
        }
    }
    
    if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Toggled dizziness on target", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Toggled dizziness on target", "_s", target_name);
	}
	
    return Plugin_Handled;
}

public Action:StopDizzy(Handle:event, const String:name[], bool:dontBroadcast)
{
    new index = GetClientOfUserId(GetEventInt(event, "userid"));
    
    bDizzy[index] = false;
}

public Action:Dizzy(Handle:timer)
{
    new Float:vecPunch[3];
    
    new maxplayers = GetMaxClients();
    for (new x = 1; x <= maxplayers; x++)
    {
        if (!IsClientInGame(x))
            continue;
        
        if (!bDizzy[x])
            continue;
        
        vecPunch[0] = GetRandomFloat(flMagnitude[x] * -1, flMagnitude[x]);
        vecPunch[1] = GetRandomFloat(flMagnitude[x] * -1, flMagnitude[x]);
        vecPunch[2] = GetRandomFloat(flMagnitude[x] * -1, flMagnitude[x]);
        
        SetEntDataVector(x, offsPunchAngle, vecPunch);
    }
}