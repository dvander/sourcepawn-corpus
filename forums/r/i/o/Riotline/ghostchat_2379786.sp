#include <sourcemod>
#include <morecolors>
 
public Plugin:myinfo =
{
    name = "-=II=- Ghost Chat",
    author = "Riotline/Astrak",
    description = "Ghost chat to talk to alive.",
    version = "1.2",
    url = ""
};
 
public OnPluginStart()
{
    RegConsoleCmd("sm_ghost", Command_Ghost);
    RegConsoleCmd("sm_g", Command_Ghost);
}

public Action Command_Ghost(int client, int args)
{
    new String:arg[256];
    new String:name[MAX_NAME_LENGTH];
    GetClientName(client, name, sizeof(name));

    if (!IsPlayerAlive(client))
    {
    GetCmdArgString(arg, sizeof(arg));
    CPrintToChatAll("\x01*GHOST* \x03%s\x01: %s", name, arg)
    }
    else
    {
    GetCmdArgString(arg, sizeof(arg));
    CPrintToChat(client, "{valve}Woops. Ghost chat doesn't work when you're alive.", arg)
    }
}  