#include <sourcemod>
#include <morecolors>
#include <colors>

public Plugin myinfo = 
{
    name = "WelcomeMsg",
    author = "oosii",
    description = "displays a welcome message to the connected client",
    version = "1.0",
    url = "https:/www.sourcemod.net/"
};

public void OnPluginStart()
{
    RegConsoleCmd("test_cmd", test_cmd);
    AddCommandListener(Command_JoinTeam, "jointeam")
}

public Action test_cmd(int client, int args)
{

    CPrintToChatAll("{red}Hello!");
}
public Action Command_JoinTeam(int client, String:command[], int args)
{
    CPrintToChat(client, "{white}[Timer] {blue}Welcome to the server!");
}  