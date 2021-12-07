#pragma semicolon 1
#include <sourcemod>

#define VERSION "1.0.0"
#define SHOWBANS_USAGE "sm_showbans <#userid|name> | Opens a Sourcebans page in the MOTD that list all the bans for a selected player"
#define BAN2_USAGE "sm_ban2 <#userid|name> | Opens a custom Sourcebans page to ban the selected player"

new Handle:host_var;

public Plugin:myinfo =
{
    name = "Show Bans",
    author = "Master J",
    description = "Opens a Sourcebans page in the MOTD with a list of all the bans for the selected player",
    version = VERSION,
    url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
    CreateConVar("showbans_version", VERSION, "", FCVAR_NOTIFY);
    host_var = CreateConVar("showbans_host", "http://127.0.0.1/sourcebans/", "", FCVAR_PROTECTED);

    RegAdminCmd("sm_showbans", Command_ShowBans, ADMFLAG_BAN);
    RegAdminCmd("sm_ban2", Command_Ban2, ADMFLAG_BAN);
}

public Action:Command_ShowBans(client, args)
{
    new String:targetarg[32];
    new String:id[19];
    
    if (args < 1)
    {
        ReplyToCommand(client, SHOWBANS_USAGE);
    }
    else
    {
        GetCmdArg(1, targetarg, sizeof(targetarg));

        new target = FindTarget(client, targetarg, true, true);
        if (target == -1)
        {
            return Plugin_Handled;
        }

        if (!GetClientAuthString(target, id, sizeof(id))
        || id[0] == 'B' || id[9] == 'L')
        {
            ReplyToCommand(client, "Error: Couldn't retrieve %N's Steam id.", target);
            return Plugin_Handled;
        }
        
        decl String:host[128];
        GetConVarString(host_var, host, sizeof(host));

        ServerCommand("sm_openurl \"%N\" \"%sindex.php?p=banlist&advSearch=%s&advType=steamid\"", client, host, id);
    }
    
    return Plugin_Handled;
}

public Action:Command_Ban2(client, args)
{
    new String:targetarg[32];
    new String:id[19];
    
    if (args < 1)
    {
        ReplyToCommand(client, BAN2_USAGE);
    }
    else
    {
        GetCmdArg(1, targetarg, sizeof(targetarg));

        new target = FindTarget(client, targetarg, true, true);
        if (target == -1)
        {
            return Plugin_Handled;
        }

        if (!GetClientAuthString(target, id, sizeof(id))
        || id[0] == 'B' || id[9] == 'L')
        {
            ReplyToCommand(client, "Error: Couldn't retrieve %N's Steam id.", target);
            return Plugin_Handled;
        }
        
        decl String:host[128];
        GetConVarString(host_var, host, sizeof(host));

        ServerCommand("sm_openurl \"%N\" \"%sindex.php?p=ban2&advSearch=%s&advType=steamid&action=pasteBan&sid=1&pName=%L\"", client, host, id, target);
    }
    
    return Plugin_Handled;
}