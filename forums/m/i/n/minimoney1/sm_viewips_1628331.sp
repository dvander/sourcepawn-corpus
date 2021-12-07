/*
* SM_ALLINFO
* This Mod Was Created Base On The Amx Version.
* Credits:
* Lebson506th  - Thanks For Helping Fix Some Errors I Was Having With The Coding
* Wh0s YoUr DaDdY?!?! - Thanks For Helping Me Fix The Logging Issues
* w4rkr4f7 - helped improve plugin so it no longer logs bots into allinfo file
*/
#pragma semicolon 1

#include <sourcemod>
#define PLUGIN_VERSION "2.1.1"

public Plugin:myinfo = 
{
    name = "IP Viewer",
    author = "{7~11} TROLL, Command names changed by Mini",
    description = "gets single clients steam id,name,and ip based on the amx version",
    version = PLUGIN_VERSION,
    url = "www.711clan.net"
}

public OnPluginStart()
{
    RegAdminCmd("sm_viewips", Command_Users, ADMFLAG_BAN, "sm_viewips <Clients Name>");
    CreateConVar("sm_viewips_version", PLUGIN_VERSION, "sm_viewips_version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public Action:Command_Users(client, args)
{
    new target;

    if (args == 1)
    {
        decl String:arg[MAX_NAME_LENGTH];
        GetCmdArg(1, arg, sizeof(arg));

        target = FindTarget(client, arg, false, false);

        if (!target)
        {
            ReplyToCommand(client, "Could not find %s", arg);
            return Plugin_Handled;
        }
    }
    else
    {
        ReplyToCommand(client, "Correct syntax: sm_viewips playername");
        return Plugin_Handled;
    }

    decl String:t_name[MAX_NAME_LENGTH], String:t_ip[16], String:t_steamid[16];

    GetClientName(target, t_name, sizeof(t_name));
    GetClientIP(target, t_ip, sizeof(t_ip));
    GetClientAuthString(target, t_steamid, sizeof(t_steamid));
    //prints this to console to the admins
    PrintToConsole(client, ".:[Name: %s | Steam ID: %s | IP: %s]:.", t_name, t_steamid, t_ip);

 
    return Plugin_Handled;
}
//gets client info apon joing server
public OnClientPutInServer(id) 
{
	decl String:t_name[MAX_NAME_LENGTH], String:t_ip[32], String:t_steamid[32], String:path[256];
	//gets client name
	GetClientName(id,t_name,31);
    //gets steam id
	GetClientAuthString(id,t_steamid,31);
    //checks to see if client is conncted -  also checks to see if client is a bot
    if(!IsClientConnected(id) || IsFakeClient(id)) 
        return;  
	//gets clients ip	
    GetClientIP(id,t_ip,31);
	//prints players allinfo to console in this format (removing ^n to see if it effects mod)
    PrintToConsole(id," .:[Name: %s | Steam ID: %s | IP: %s]:.",t_name,t_steamid,t_ip);
	BuildPath(Path_SM, path, 256, "logs/allinfo_players.txt");
	//logs the info in this format (removing ^n to see if it effects logging
	LogToFile(path,".:[Name: %s | STEAMID: %s | IP: %s]:.",t_name,t_steamid,t_ip);
	
}