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
/*********Todo/Features To Add********
] heal me - heals client
] refill me - gives client more ammo
] add menu for health,pills and ammo
] H.H.E (hand held explosives menu - allows clients to get pipebomb or molotov
**************************************/
#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
    name = "[L4D] Tank Buster Heal Me",
    author = "{7~11} TROLL",
    description = "allows clients to heal there selfs",
    version = PLUGIN_VERSION,
    url = "www.711clan.net"
}

public OnPluginStart()
{
    //tank buster weapons menu cvar
    RegConsoleCmd("healme", TankBusterMenu);
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
    AddMenuItem(menu, "option1", "First Aid");
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
            case 0: //first aid
            {
                //gives first aid
                FakeClientCommand(client, "give first_aid_kit");
            }
        }
    }
    //Add the CHEAT flag back to "give" command
    SetCommandFlags("give", flags|FCVAR_CHEAT);
}