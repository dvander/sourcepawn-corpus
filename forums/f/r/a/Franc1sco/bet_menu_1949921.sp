#pragma semicolon 1
#include <sourcemod>



#define PLUGIN_VERSION "1.0 by Franc1sco franug"


public Plugin:myinfo =
{
	name = "SM Bet Menu",
	author = "Franc1sco Steam: franug",
	description = "x",
	version = PLUGIN_VERSION,
	url = "www.servers-cfg.foroactivo.com"
};

public OnPluginStart()
{
	CreateConVar("sm_betmenu_version", PLUGIN_VERSION, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookEvent("player_death", PlayerDeath);
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	DID(client);
}

public Action:DID(clientId) 
{
    new Handle:menu = CreateMenu(DIDMenuHandler);
    SetMenuTitle(menu, "Make your bet");
    AddMenuItem(menu, "option1", "Bet T all");
    AddMenuItem(menu, "option2", "Bet CT all");
    AddMenuItem(menu, "option3", "No bet");
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, clientId, MENU_TIME_FOREVER);

}

public DIDMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
    if ( action == MenuAction_Select ) 
    {
        new String:info[32];
        
        GetMenuItem(menu, itemNum, info, sizeof(info));
        
        if ( strcmp(info,"option1") == 0 ) 
        {
            
            
			FakeClientCommand(client, "say bet t all");

            
            
        }
        
        else if ( strcmp(info,"option2") == 0 ) 
        {

			FakeClientCommand(client, "say bet ct all");
            
            
        }
       
    }

    else if (action == MenuAction_End)
    {
		CloseHandle(menu);
    }
}