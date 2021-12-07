#include <sourcemod>

#define PLUGIN_VERSION "1.0"
public Plugin:myinfo = 
{
    name = "Retro Ban",
    author = "Pathfinder",
    description = "Shows the last xx users to disconnect, and gives an easy way to ban them",
    version = PLUGIN_VERSION,
    url = "http://www.sourcemod.net"
}

new Handle:PlayerName
new Handle:PlayerAuthid
new Handle:PlayerIp
new count
new rbanhistory = 20 // default history length
new bool:logbots = false
new bool:RetroBanID
new String:szFile[256]

public OnPluginStart()
{
    CreateConVar("retroban", PLUGIN_VERSION, "Retro Ban version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY)    
     
    PlayerName = CreateArray(64, rbanhistory)
    PlayerAuthid = CreateArray(64, rbanhistory)
    PlayerIp = CreateArray(64, rbanhistory)

    RegAdminCmd("rlist", List, ADMFLAG_GENERIC, "Lists the last xx players to disconnect.")
    RegAdminCmd("rlistip", ListIP, ADMFLAG_GENERIC, "Lists the last xx players to disconnect.")
    RegAdminCmd("rban", Command_RetroBanID, ADMFLAG_BAN)
    RegAdminCmd("rbanip", Command_RetroBanIP, ADMFLAG_BAN)
    RegAdminCmd("sm_rbanhistory", SetHistory, ADMFLAG_GENERIC, "sm_rbanhistory <#> : Sets how many player names+ID's/IP's to remember for Retro Ban command.")
    RegAdminCmd("sm_rbanbots", SetBots, ADMFLAG_GENERIC, "sm_rbanbots <#> : Determines if Retro Ban will log bots.")
}

public Action:Command_RetroBanID(client, args)
{
    BuildPath(Path_SM, szFile, sizeof(szFile), "../../cfg/banned_user.cfg")
    RetroBanID = true
    BanAll()
    return Plugin_Handled
}

public Action:Command_RetroBanIP(client, args)
{
    BuildPath(Path_SM, szFile, sizeof(szFile), "../../cfg/banned_ip.cfg")
    RetroBanID = false
    BanAll()
    return Plugin_Handled
}

public BanAll()
{
    new Handle:hFile = OpenFile(szFile, "at")
	
    new String:allargs[128]
    new String:searchstring[2] = "||"
    new String:replacestring[2] = "//"
    GetCmdArgString(allargs,128)

    ReplaceStringEx(allargs, sizeof(allargs), searchstring, replacestring, -1, -1)
    if (RetroBanID)
    {
        ServerCommand("banid 0 %s",allargs)
        WriteFileLine(hFile, "banid 0 %s", allargs)
    }
    else
    {
        ServerCommand("banip 0 %s",allargs)
        WriteFileLine(hFile, "banip 0 %s", allargs)
    }
    CloseHandle(hFile)
}

public OnClientDisconnect(client)
{
    decl String:playername[64], String:playerid[64], String:playerIP[64]
    GetClientName(client, playername, sizeof(playername))
    GetClientAuthString(client, playerid, sizeof(playerid))
    GetClientIP(client, playerIP, sizeof(playerIP))
	
    if (!strcmp(playerid, "BOT"))
    {
        if (!logbots)
        {
            return
        }
    }

    if (++count >= rbanhistory)
    {
        count = rbanhistory
        RemoveFromArray(PlayerName, rbanhistory - 1)
        RemoveFromArray(PlayerAuthid, rbanhistory - 1)
        RemoveFromArray(PlayerIp, rbanhistory - 1)
    }

    if (count)
    {
        ShiftArrayUp(PlayerAuthid, 0)
        ShiftArrayUp(PlayerName, 0)
        ShiftArrayUp(PlayerIp, 0)
    }

    SetArrayString(PlayerName, 0, playername)
    SetArrayString(PlayerAuthid, 0, playerid)
    SetArrayString(PlayerIp, 0, playerIP)

    return
}

public Action:List(client, args)
{
    PrintToConsole(client, "Last %i players to disconnect:", count)

    decl String:Auth[64], String:Name[64]
    for (new i = 0; i < count; i++)
    {
        GetArrayString(PlayerName, i, Name, sizeof(Name))
        GetArrayString(PlayerAuthid, i, Auth, sizeof(Auth))

        PrintToConsole(client, "rcon rban %s || %s", Auth, Name)
    }

    return Plugin_Handled
}

public Action:ListIP(client, args)
{
    PrintToConsole(client, "Last %i players to disconnect:", count)

    decl String:clientIP[64], String:Name[64]
    for (new i = 0; i < count; i++)
    {
        GetArrayString(PlayerName, i, Name, sizeof(Name))
        GetArrayString(PlayerIp, i, clientIP, sizeof(clientIP))

        PrintToConsole(client, "rcon rbanip %s || %s", clientIP, Name)
    }

    return Plugin_Handled
}

public Action:SetHistory(client, args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "Current Value: %i \n[SM] Usage: sm_rbanhistory <#> : min 1.0 max 64.0", rbanhistory)
        return Plugin_Handled
    }

    decl String:history[64]
    GetCmdArg(1, history, sizeof(history))

    new value = StringToInt(history)

    if (0 < value < 65)
    {
        if(value < count)
        {
            count = value
        }

        rbanhistory = value

        ResizeArray(PlayerName, rbanhistory)
        ResizeArray(PlayerAuthid, rbanhistory)
        ResizeArray(PlayerIp, rbanhistory)
        return Plugin_Handled
    }
    else
    {
        ReplyToCommand(client, "Current Value: %i \n[SM] Usage: sm_rbanhistory <#> : min 1 max 64", rbanhistory)
        return Plugin_Handled
    }
}

public Action:SetBots(client, args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "Current Value: %i \n[SM] Usage: sm_rbanbots <0 or 1>", logbots)
        return Plugin_Handled
    }

    decl String:bots[64]
    GetCmdArg(1, bots, sizeof(bots))

    new value = StringToInt(bots)

    if (value == 1)
    {
        logbots = true
        return Plugin_Handled
    }

    if (value == 0)
    {
        logbots = false
        return Plugin_Handled
    }

    else
    {
        ReplyToCommand(client, "Current Value: %i \n[SM] Usage: sm_rbanhistory <#> : min 1.0 max 64.0", rbanhistory)
        return Plugin_Handled
    }
}