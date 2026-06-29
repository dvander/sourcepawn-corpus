/***************GUNS***************
] give ammo - not included
] give autoshotgun
] give first_aid_kit - not included
] give health - not included
] give pipe_bomb
] give molotov
] give rifle
] give smg
] give hunting_rifle
] give pain_pills
] give pistol
] give pumpshotgun
************END LIST***************/

/**********Thanks To**************
* CrimsonGt - helped me with give player item issues
*********************************/

/*********Todo/Features To Add********
] heal me - heals client
] refill me - gives client more ammo
] add menu for health,pills and ammo
] H.H.E (hand held explosives menu - allows clients to get pipebomb or molotov
**************************************/

#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "1.1.1"

public Plugin:myinfo = 
{
    name = "[L4D] Tank Buster Wepons Menu",
    author = "{7~11} TROLL",
    description = "Allows Clients To Get Weapons From The Weapon Menu",
    version = PLUGIN_VERSION,
    url = "www.711clan.net"
}

public OnPluginStart()
{
    //tank buster weapons menu cvar
    RegConsoleCmd("tankbuster", TankBusterMenu);
    //plugin version
    CreateConVar("tank_buster_version", PLUGIN_VERSION, "Tank_Buster_Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public Action:TankBusterMenu(client,args)
{
    TankBuster(client);
    
    return Plugin_Handled;
}

public Action:TankBuster(clientId) {
    new Handle:menu = CreateMenu(TankBusterMenuHandler);
    SetMenuTitle(menu, "TankBuster Weapons Menu");
    AddMenuItem(menu, "option1", "Shotgun");
    AddMenuItem(menu, "option2", "SMG");
    AddMenuItem(menu, "option3", "Rifle");
    AddMenuItem(menu, "option4", "Hunting Rifle");
    AddMenuItem(menu, "option5", "Auto Shotgun");
    AddMenuItem(menu, "option6", "Pipe Bomb");
    AddMenuItem(menu, "option7", "Molotov");
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
    
    return Plugin_Handled;
}

public TankBusterMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
    //Strip the CHEAT flag off of the "give" command
    new flags = GetCommandFlags("give");
    SetCommandFlags("give", flags & ~FCVAR_CHEAT);
    
    if ( action == MenuAction_Select ) {
        
        switch (itemNum)
        {
            case 0: //shotgun
            {
                //Give the player a shotgun
                FakeClientCommand(client, "give pumpshotgun");
            }
            case 1: //smg
            {
                //Give the player a smg
                FakeClientCommand(client, "give smg");
            }
            case 2: //rifle
            {
                //Give the player a rifle
                FakeClientCommand(client, "give rifle");
            }
			case 3: //hunting rifle
            {
                //Give the player a hunting rifle
                FakeClientCommand(client, "give hunting_rifle");
            }
			case 4: //auto shotgun
            {
                //Give the player a autoshotgun
                FakeClientCommand(client, "give autoshotgun");
            }
			case 5: //pipe_bomb
            {
                //Give the player a pipe_bomb
                FakeClientCommand(client, "give pipe_bomb");
            }
			case 6: //hunting molotov
            {
                //Give the player a molotov
                FakeClientCommand(client, "give molotov");
            }
        }
    }

    //Add the CHEAT flag back to "give" command
    SetCommandFlags("give", flags|FCVAR_CHEAT);
}