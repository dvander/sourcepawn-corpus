
/////////////////////////// 
//                       //
//     {default}         //
//     {red}             //
//     {purple}          //
//     {green}           //
//                       //
///////////////////////////


#include <sourcemod>
#include <multicolors>

public Plugin:myinfo = 
{
    name        = "SoundCloud Volume",
    author        = "KennY",
    description    = "Volume Menu",
    version        = "1.0",
    url            = "http://steamcommunity.com/id/kennysweden/"
}

public OnPluginStart()
{
    RegConsoleCmd("sm_scv", menu_scv, "Volume Menu");
}

public Action:menu_scv (client, args)
{
    if(!client || !IsClientInGame(client)) return Plugin_Handled;

    {
        new Handle:menu = CreateMenu(scv);
        SetMenuTitle(menu, "SoundCloud Volume Menu");
        AddMenuItem(menu, "0", "100% Volume");
        AddMenuItem(menu, "1", "90% Volume");
        AddMenuItem(menu, "2", "80% Volume");
		AddMenuItem(menu, "3", "70% Volume");
		AddMenuItem(menu, "4", "60% Volume");
		AddMenuItem(menu, "5", "50% Volume");
		AddMenuItem(menu, "6", "40% Volume");
		AddMenuItem(menu, "7", "30% Volume");
		AddMenuItem(menu, "8", "20% Volume");
		AddMenuItem(menu, "9", "10% Volume");
		SetMenuExitButton(menu, true);
        DisplayMenu(menu, client, 0);
    }

    return Plugin_Handled;
}

public scv(Handle:menu, MenuAction:action, client, param)
{
    if (action == MenuAction_Select)
    {
        switch (param)
        {
            case 0: FakeClientCommand(client, "sm_scvol 10");
            case 1: FakeClientCommand(client, "sm_scvol 9");
            case 2: FakeClientCommand(client, "sm_scvol 8");
            case 3: FakeClientCommand(client, "sm_scvol 7");
			case 4: FakeClientCommand(client, "sm_scvol 6");
			case 5: FakeClientCommand(client, "sm_scvol 5");
			case 6: FakeClientCommand(client, "sm_scvol 4");
			case 7: FakeClientCommand(client, "sm_scvol 3");
			case 8: FakeClientCommand(client, "sm_scvol 2");
			case 9: FakeClientCommand(client, "sm_scvol 1");
        }
    }
    else if (action == MenuAction_End) CloseHandle(menu)
}