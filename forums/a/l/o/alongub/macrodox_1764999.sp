//macrodox, a macro detection plugin
//THANKS TO: Blodia for brainstorming
//THANKS TO: Cheaters on Aoki's server
//GREETS: 2S, DaFox, justshoot, AnIHiL
//22:54 - 2S: why am I there?

//If you have a timer that can delete records you might want to edit this
//for auto deletion. Console command gets called with steamid as parameter.
#define DELETE_CMD "sm_deleterecord_all"

//Command used to delayed ban.
//Default is "banid 0 %s kick"
#define BAN_CMD "banid 0 %s kick"

//if banid is used, write to banned_user.cfg manually.
#define BAN_WRITE

//Delayed bans every 3 maps
#define BAN_DELAY 3

//UNCOMMENT IF YOU WANT TO SUPPORT TESTING
//Enables aspi/Inami to use stats command
//#define DEFAULT_DEBUGID "STEAM_0:0:6183127"

//#define DEBUG

#define PLUGIN_VERSION "1.9"

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
    name = "macrodox",
    author = "aspi",
    description = "Macro detection plugin",
    version = PLUGIN_VERSION,
    url = ""
}



//General variables
new aiJumps[MAXPLAYERS+1] = {0, ...};
new Float:afAvgJumps[MAXPLAYERS+1] = {1.0, ...};
new Float:afAvgSpeed[MAXPLAYERS+1] = {250.0, ...};
new Float:avVEL[MAXPLAYERS+1][3];
new aiPattern[MAXPLAYERS+1] = {0, ...};
new aiPatternhits[MAXPLAYERS+1] = {0, ...};
new Float:avLastPos[MAXPLAYERS+1][3];
new aiAutojumps[MAXPLAYERS+1] = {0, ...};
new aaiLastJumps[MAXPLAYERS+1][30];
new Float:afAvgPerfJumps[MAXPLAYERS+1] = {0.3333, ...};
new iTickCount = 1;
new aiIgnoreCount[MAXPLAYERS+1];
new String:path[PLATFORM_MAX_PATH];
new String:pathdat[PLATFORM_MAX_PATH];
new bool:bBanFlagged[MAXPLAYERS+1];
new bool:bSurfCheck[MAXPLAYERS+1];
new aiLastPos[MAXPLAYERS+1] = {0, ...};

#if defined DEFAULT_DEBUGID
new String:debugid[32] = DEFAULT_DEBUGID;
#else
new String:debugid[32];
#endif


public OnPluginStart()
{   
    CreateConVar("macrodox_version", PLUGIN_VERSION, "macrodox version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
    HookEvent("player_jump", Event_PlayerJump, EventHookMode_Post);
    BuildPath(Path_SM, path, sizeof(path), "logs/macrodox.log");
    BuildPath(Path_SM, pathdat, sizeof(pathdat), "data/macrodox.dat"); 
    RegAdminCmd("mdx_stats", Command_Stats, ADMFLAG_BAN, "mdx_stats <#userid|name|@all>");
    RegAdminCmd("mdx_debug", Command_Debug, ADMFLAG_BAN, "mdx_debug STEAM_ID");

    RegConsoleCmd("mdx_test", Command_test, "mdx_test <#userid|name|@all>");
    
}
public Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    afAvgJumps[client] = ( afAvgJumps[client] * 9.0 + float(aiJumps[client]) ) / 10.0;
    
    decl Float:vec_vel[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec_vel);
    vec_vel[2] = 0.0;
    new Float:speed = GetVectorLength(vec_vel);
    afAvgSpeed[client] = (afAvgSpeed[client] * 9.0 + speed) / 10.0;
    
    aaiLastJumps[client][aiLastPos[client]] = aiJumps[client];
    aiLastPos[client]++;
    if (aiLastPos[client] == 30)
    {
        aiLastPos[client] = 0;
    }
    
    if (afAvgJumps[client] > 15.0)
    {
        if ((aiPatternhits[client] > 0) && (aiJumps[client] == aiPattern[client]))
        {
            aiPatternhits[client]++;
            if ((aiPatternhits[client] > 15) && (!bBanFlagged[client]))
            {
                BanDelayed(client, "pat1");
                bBanFlagged[client] = true;
            }
        }
        else if ((aiPatternhits[client] > 0) && (aiJumps[client] != aiPattern[client]))
        {
            aiPatternhits[client] -= 2;
        }
        else
        {
            aiPattern[client] = aiJumps[client];
            aiPatternhits[client] = 2;
        }
        
    }
    else if(aiJumps[client] > 1)
    {
        aiAutojumps[client] = 0;
    }
    else if((afAvgJumps[client] <1.1) && (!bBanFlagged[client]))
    {	
        bSurfCheck[client] = true;
        if (aiIgnoreCount[client])
        {
            aiIgnoreCount[client]--;
        }
        if (speed > 350 && aiIgnoreCount[client] == 0)
        {
            aiAutojumps[client]++;
            if (aiAutojumps[client] >= 20)
            {
                BanDelayed(client, "hax1");
            }
        }
        else if (aiAutojumps[client])
        {
            aiAutojumps[client]--;
        }
        
    } 

    aiJumps[client] = 0;
    new Float:tempvec[3];
    tempvec = avLastPos[client];
    GetEntPropVector(client, Prop_Send, "m_vecOrigin", avLastPos[client]);
    
    new Float:len = GetVectorDistance(avLastPos[client], tempvec, true);
    if (len < 30.0)
    {   
        aiIgnoreCount[client] = 2;
    }
    
    if (afAvgPerfJumps[client] >= 0.94 && !bBanFlagged[client])
    {
        BanDelayed(client, "hax2");
    }
    
}

public OnMapStart()
{
    static deltick;
    deltick++;
    if (deltick >= BAN_DELAY)
    {
        DoBans();
        deltick = 0;
    }


}
public OnClientDisconnect(client)
{
    aiJumps[client] = 0;
    afAvgJumps[client] = 5.0;
    afAvgSpeed[client] = 250.0;
    afAvgPerfJumps[client] = 0.3333;
    aiPattern[client] = 0;
    aiPatternhits[client] = 0;
    aiAutojumps[client] = 0;
    aiIgnoreCount[client] = 0;
    bBanFlagged[client] = false;
    avVEL[client][2] = 0.0;
    new i;
    while (i < 30)
    {
        aaiLastJumps[client][i] = 0;
        i++;
    }
}

public OnGameFrame()
{
    if (iTickCount > 1*MaxClients)
    {
        iTickCount = 1;
    }
    else
    {
        if (iTickCount % 1 == 0)
        {
            new index = iTickCount / 1;
            if (bSurfCheck[index] && IsClientInGame(index) && IsPlayerAlive(index))
            {	
                GetEntPropVector(index, Prop_Data, "m_vecVelocity", avVEL[index]);
                if (avVEL[index][2] < -290)
                {
                    aiIgnoreCount[index] = 2;
                }
                
            }
        }
        iTickCount++;
    }
}

BanDelayed(client, const String:type[])
{
    new String:uid[64];
    GetClientAuthString(client, uid, sizeof(uid));
    new Handle:banfile = OpenFile(pathdat, "a+");
    if (banfile == INVALID_HANDLE)
    {
        LogError("Cannot open macrodox.dat");
        return;
    }
    new String:reader[65];
    while (ReadFileLine(banfile, reader, sizeof(reader)))
    {
        TrimString(reader);
        #if defined DEBUG
        PrintToChatAll("read %s from .dat", reader);
        #endif
        if (StrEqual(reader, uid, false))
        {   
            bBanFlagged[client] = true;
            CloseHandle(banfile);
            return;
        }
    }
    new String:banstats[256];
    GetClientStats(client, banstats, sizeof(banstats));
    LogToFile(path, "%s %s", banstats, type);
    WriteFileLine(banfile, uid);
    bBanFlagged[client] = true;
    CloseHandle(banfile);
    #if defined DEBUG
    PrintToChatAll("written %s to .dat", uid);
    #endif
}
DoBans()
{
    new Handle:banfile = OpenFile(pathdat, "a+");
    if (banfile == INVALID_HANDLE)
    {
        LogError("Cannot open macrodox.dat");
        return;
    }
    new String:reader[65];
    while (ReadFileLine(banfile, reader, sizeof(reader)))
    {
        TrimString(reader);
        #if defined DEBUG
        PrintToChatAll("banned %s", reader);
        #endif
		#if defined BAN_CMD
        ServerCommand(BAN_CMD, reader);
		#endif      
		#if defined DELETE_CMD
		ServerCommand("%s %s", DELETE_CMD, reader); 
		#endif
    }
    CloseHandle(banfile);
    banfile = OpenFile(pathdat, "w");
    CloseHandle(banfile);
    #if defined BAN_WRITE
    ServerCommand("writeid");
    #endif   
}


public Action:Command_Stats(client, args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: mdx_stats <#userid|name|@all>");
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
                    COMMAND_FILTER_NO_IMMUNITY,
                    target_name,
                    sizeof(target_name),
                    tn_is_ml)) <= 0)
    {
        PrintToConsole(client, "Not found or invalid parameter.");
        return Plugin_Handled;
    }
    
    for (new i = 0; i < target_count; i++)
    {
        PerformStats(client, target_list[i]);
    }
    
    
    return Plugin_Handled;
}

public Action:Command_test(client, args)
{
    new String:auth[32];
    GetClientAuthString(client,auth,sizeof(auth));
    if(!StrEqual(auth, debugid))
    {
        return Plugin_Handled;
    }
    
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: mdx_test <#userid|name|@all>");
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
                    COMMAND_FILTER_NO_IMMUNITY,
                    target_name,
                    sizeof(target_name),
                    tn_is_ml)) <= 0)
    {
        PrintToConsole(client, "Not found or invalid parameter.");
        return Plugin_Handled;
    }
    
    for (new i = 0; i < target_count; i++)
    {
        PerformStats(client, target_list[i]);
    }
    
    
    return Plugin_Handled;
}
PerformStats(client, target)
{
    new String:banstats[256];
    GetClientStats(target, banstats, sizeof(banstats));
    PrintToConsole(client, "%d %s",bBanFlagged[target], banstats);
}
GetClientStats(client, String:string[], length)
{
    new Float:origin[3];
    GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
    new String:map[128];
    GetCurrentMap(map, 128);
    Format(string, length, "%L Avg: %f/%f Perf: %f %s %f %f %f Last: %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i",
    client,
    afAvgJumps[client],
    afAvgSpeed[client],
    afAvgPerfJumps[client],
    map,
    origin[0],
    origin[1],
    origin[2],
    aaiLastJumps[client][0],
    aaiLastJumps[client][1],
    aaiLastJumps[client][2],
    aaiLastJumps[client][3],
    aaiLastJumps[client][4],
    aaiLastJumps[client][5],
    aaiLastJumps[client][6],
    aaiLastJumps[client][7],
    aaiLastJumps[client][8],
    aaiLastJumps[client][9],
    aaiLastJumps[client][10],
    aaiLastJumps[client][11],
    aaiLastJumps[client][12],
    aaiLastJumps[client][13],
    aaiLastJumps[client][14],
    aaiLastJumps[client][15],
    aaiLastJumps[client][16],
    aaiLastJumps[client][17],
    aaiLastJumps[client][18],
    aaiLastJumps[client][19],
    aaiLastJumps[client][20],
    aaiLastJumps[client][21],
    aaiLastJumps[client][22],
    aaiLastJumps[client][23],
    aaiLastJumps[client][24],
    aaiLastJumps[client][25],
    aaiLastJumps[client][26],
    aaiLastJumps[client][27],
    aaiLastJumps[client][28],
    aaiLastJumps[client][29]);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(IsPlayerAlive(client))
    {
        static bool:bHoldingJump[MAXPLAYERS + 1];
        static bLastOnGround[MAXPLAYERS + 1];
        if(buttons & IN_JUMP)
        {
            if(!bHoldingJump[client])
            {
                bHoldingJump[client] = true;//started pressing +jump
                aiJumps[client]++;
                if (bLastOnGround[client] && (GetEntityFlags(client) & FL_ONGROUND))
                {
                    afAvgPerfJumps[client] = ( afAvgPerfJumps[client] * 9.0 + 0 ) / 10.0;
                   
                }
                else if (!bLastOnGround[client] && (GetEntityFlags(client) & FL_ONGROUND))
                {
                    afAvgPerfJumps[client] = ( afAvgPerfJumps[client] * 9.0 + 1 ) / 10.0;
                }
            }
        }
        else if(bHoldingJump[client]) 
        {
            bHoldingJump[client] = false;//released (-jump)
            
        }
        bLastOnGround[client] = GetEntityFlags(client) & FL_ONGROUND;

        if ((buttons & IN_LEFT) || (buttons & IN_RIGHT))
        {
            ForcePlayerSuicide(client);
        }
       

        
    }
    
    return Plugin_Continue;
}
public Action:Command_Debug(client, args)
{
    GetCmdArgString(debugid, sizeof(debugid));

    PrintToConsole(client, "debugcmd for -%s-", debugid);
}



//EOF
