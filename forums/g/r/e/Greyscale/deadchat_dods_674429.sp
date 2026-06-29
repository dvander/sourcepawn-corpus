/**
 * ====================
 *       DeadChat
 *   File: deadchat.sp
 *   Author: Greyscale
 * ==================== 
 */
 
#pragma semicolon 1
#include <sourcemod>

#define VERSION "1.3"

new Handle:cvarEnable = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "DeadChat (tf)",
    author = "Greyscale",
    description = "Dead players can use chat to talk to alive players",
    version = VERSION,
    url = ""
};

public OnPluginStart()
{
    RegConsoleCmd("say", Command_Say);
    RegConsoleCmd("say_team", Command_Say);
    
    // ======================================================================
    
    cvarEnable = CreateConVar("deadchat_enable", "-1", "Enable deadchat (-1: Read sv_alltalk, 0: Disable, 1: Enable)");
    
    CreateConVar("gs_deadtalk_version", VERSION, "[DeadChat] Current version of this plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public Action:Command_Say(client, argc)
{
    if (!client || IsPlayerAlive(client))
        return Plugin_Continue;
    
    new Handle:alltalk = FindConVar("sv_alltalk");
    
    new override = GetConVarInt(cvarEnable);
    new bool:enable = override > -1 ? (bool:override) : GetConVarBool(alltalk);
    
    if (!enable)
        return Plugin_Continue;
    
    decl String:text[192];
    
    GetCmdArgString(text, sizeof(text));
    StripQuotes(text);
    
    if (!text[0] || text[0] == '@')
    {
        return Plugin_Continue;
    }
    
    decl String:pname[64];
    GetClientName(client, pname, sizeof(pname));
    
    new maxplayers = GetMaxClients();
    
    decl String:cmd[16];
    GetCmdArg(0, cmd, sizeof(cmd));
    
    if (StrEqual(cmd, "say", false))
    {
        for (new x = 1; x <= maxplayers; x++)
        {
            if (!IsClientInGame(x) || !IsPlayerAlive(x))
                continue;
            
            GetClientName(client, pname, sizeof(pname));
            
            new Handle:hSayText2 = StartMessageOne("SayText2", x);
            
            BfWriteByte(hSayText2, client);
            BfWriteByte(hSayText2, true);
            BfWriteString(hSayText2, "\x01*DEAD* \x03%s1 \x01:  %s2");
            BfWriteString(hSayText2, pname);
            BfWriteString(hSayText2, text);
            
            EndMessage();
        }
    }
    else if (StrEqual(cmd, "say_team", false))
    {
        for (new x = 1; x <= maxplayers; x++)
        {
            if (!IsClientInGame(x) || !IsPlayerAlive(x) || GetClientTeam(client) != GetClientTeam(x))
                continue;
            
            GetClientName(client, pname, sizeof(pname));
            
            new Handle:hSayText2 = StartMessageOne("SayText2", x);
            BfWriteByte(hSayText2, client);
            BfWriteByte(hSayText2, true);
            BfWriteString(hSayText2, "\x01*DEAD*(TEAM) \x03%s1 \x01:  %s2");
            BfWriteString(hSayText2, pname);
            BfWriteString(hSayText2, text);
            
            EndMessage();
        }
    }
    
    return Plugin_Continue;
}