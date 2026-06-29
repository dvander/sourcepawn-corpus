#pragma semicolon 1
#include <sourcemod>

public Plugin myinfo = 
{
	name = "Квар Лист", 
	author = "Upholder of the [BFG]", 
	description = "Плагин отображает все доступные переменные на сервере", 
	version = "1.1", 
	url = "http://www.sourcemod.net/"
}

public void OnPluginStart()
{
	RegAdminCmd("sm_cclist", Command_Mycclist, ADMFLAG_CONVARS, "Команда, с помощью которой отображается Cvar List");
}

public Action Command_Mycclist(int client, int args)
{
    Handle iter;
    char buffer[256];
    int flags;
    bool isCommand;

    iter = FindFirstConCommand(buffer, sizeof(buffer), isCommand, flags);
    
    do
    {
        if (!isCommand) // A ConVar
        {
            ReplyToCommand(client, "%s (%d)", buffer, flags);
        }
    }
    while (FindNextConCommand(iter, buffer, sizeof(buffer), isCommand, flags));
    delete iter;
    
    return Plugin_Handled;
} 

