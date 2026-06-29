#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0"

new MARINES = 1;
new INSURGENTS = 2;

public Plugin:myinfo = 
{
    name = "INS Guns2 Menu",
    author = "R3M",
    description = "Allows Clients To Get Guns From The Gun Menu",
    version = PLUGIN_VERSION,
    url = "http://www.econsole.de/"
}

public OnPluginStart()
{
    RegConsoleCmd("sm_guns2", WeaponMenu);
    RegConsoleCmd("guns2", WeaponMenu);

    CreateConVar("ins_guns2_version", PLUGIN_VERSION, "INS Gun Menu Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    OnMapStart();
}

public OnMapStart()
{
	decl String:mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	if (strcmp(mapname, "ins_karam") == 0 || strcmp(mapname, "ins_baghdad") == 0)
	{
		INSURGENTS = 1;
		MARINES = 2;
	}
	else
	{
		MARINES = 1;
		INSURGENTS = 2;
	}
}

public Action:WeaponMenu(client,args)
{
    Weapons(client);
    
    return Plugin_Handled;
}

public Action:Weapons(clientId) {

	new team = GetClientTeam(clientId);
	if (team == INSURGENTS)
	{
		new Handle:menu = CreateMenu(WeaponMenuHandlerUS);
		SetMenuTitle(menu, "Marines Gun Menu");
		AddMenuItem(menu, "option1", "M4 AimPoint");
		AddMenuItem(menu, "option2", "M16M203");
		AddMenuItem(menu, "option3", "M14 Sniper");
		AddMenuItem(menu, "option4", "M249 SAW");
		AddMenuItem(menu, "option5", "M1014 Shotgun");
		AddMenuItem(menu, "option6", "M4 Medium");
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, clientId, 15);
	}
	else if (team == MARINES)
	{
		new Handle:menu = CreateMenu(WeaponMenuHandlerINS);
		SetMenuTitle(menu, "Insurgents Gun Menu");
		AddMenuItem(menu, "option1", "AK-47");
		AddMenuItem(menu, "option2", "FNFAL");
		AddMenuItem(menu, "option2", "AKS-74U");
		AddMenuItem(menu, "option3", "RPK MG");
		AddMenuItem(menu, "option4", "TOZ Shotgun");
		AddMenuItem(menu, "option5", "Dragunov");
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, clientId, 15);
	}
    	return Plugin_Handled;
}

public WeaponMenuHandlerUS(Handle:menu, MenuAction:action, client, itemNum)
{
		SetConVarBool(FindConVar("sv_cheats"), true, false);

		if ( action == MenuAction_Select ) {
        
        switch (itemNum)
        {
            case 0: 
            {
                 FakeClientCommand(client, "give_weapon m4");
            }
            case 1: 
            {
                FakeClientCommand(client, "give_weapon m16m203");
            }
	     case 2: 
            {
                FakeClientCommand(client, "give_weapon m14");
            }
	     case 3: 
            {
	     FakeClientCommand(client, "give_weapon m249");
            }
	     case 4:
            {
                FakeClientCommand(client, "give_weapon m1014");
            }
	     case 5:
            {
                FakeClientCommand(client, "give_weapon m4med");
            }
        }
    }
		SetConVarBool(FindConVar("sv_cheats"), false, false);
}

public WeaponMenuHandlerINS(Handle:menu, MenuAction:action, client, itemNum)
{
		SetConVarBool(FindConVar("sv_cheats"), true, false);

		if ( action == MenuAction_Select ) {
        
        switch (itemNum)
        {
            case 0: 
            {
                FakeClientCommand(client, "give_weapon ak47");
            }
	     case 1: 
            {
                FakeClientCommand(client, "give_weapon fnfal");
            }
	     case 2: 
            {
                FakeClientCommand(client, "give_weapon aks74u");
            }
	     case 3:
            {
                FakeClientCommand(client, "give_weapon rpk");
            }
	     case 4:
            {
                FakeClientCommand(client, "give_weapon toz");
            }
	     case 5:
            {
                FakeClientCommand(client, "give_weapon svd");
            }
        }
    }
		SetConVarBool(FindConVar("sv_cheats"), false, false);
}

