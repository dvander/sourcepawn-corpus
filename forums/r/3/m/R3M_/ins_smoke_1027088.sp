#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
    name = "INS Custom smoke grenade colors",
    author = "R3M",
    description = "Shows a menu to customize smoke colors",
    version = PLUGIN_VERSION,
    url = "http://www.econsole.de/"
}

public OnPluginStart()
{
	CreateConVar("ins_smoke_version", PLUGIN_VERSION, "INS Custom smoke grenade colors Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_smoke", smoke);
	RegConsoleCmd("smoke", smoke);
}

public SmokeMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[256];

		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
 
		PrintToChat(param1, "[SM] Smoke color set.", found);
 
		ClientCommand(param1, "%s", info);
	}
}

public Action:smoke(client, args)
{
	new Handle:menu = CreateMenu(SmokeMenuHandler);
	SetMenuTitle(menu, "Select a smoke color:");
	AddMenuItem(menu, "ins_player_smokecolor 0; ins_player_smokecolor_r 1; ins_player_smokecolor_g 0; ins_player_smokecolor_b 0", "Red");
	AddMenuItem(menu, "ins_player_smokecolor 0; ins_player_smokecolor_r 0; ins_player_smokecolor_g 1; ins_player_smokecolor_b 0", "Green");
	AddMenuItem(menu, "ins_player_smokecolor 0; ins_player_smokecolor_r 0; ins_player_smokecolor_g 0; ins_player_smokecolor_b 1", "Blue");
	AddMenuItem(menu, "ins_player_smokecolor 0; ins_player_smokecolor_r 0.78432; ins_player_smokecolor_g 0.196078; ins_player_smokecolor_b 1", "Violet");
	AddMenuItem(menu, "ins_player_smokecolor 0; ins_player_smokecolor_r 0; ins_player_smokecolor_g 1; ins_player_smokecolor_b 1", "Cyan");
	AddMenuItem(menu, "ins_player_smokecolor 0; ins_player_smokecolor_r 1; ins_player_smokecolor_g 1; ins_player_smokecolor_b 0", "Yellow");
	AddMenuItem(menu, "ins_player_smokecolor 0; ins_player_smokecolor_r 1;ins_player_smokecolor_g 0.5;ins_player_smokecolor_b 0.5", "Ruby");
	AddMenuItem(menu, "ins_player_smokecolor 0; ins_player_smokecolor_r 1; ins_player_smokecolor_g 0.41176; ins_player_smokecolor_b 0.70588", "Pink");
	AddMenuItem(menu, "ins_player_smokecolor 0; ins_player_smokecolor_r 0; ins_player_smokecolor_g 0.74901; ins_player_smokecolor_b 1", "Lightblue");
	AddMenuItem(menu, "ins_player_smokecolor 0; ins_player_smokecolor_r 0;ins_player_smokecolor_g 0;ins_player_smokecolor_b 0", "Black");
	AddMenuItem(menu, "ins_player_smokecolor 1", "Default");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
 
	return Plugin_Handled;
}