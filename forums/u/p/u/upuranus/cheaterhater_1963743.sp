/* Cheater Hater
 *  By Antithasys, [QaZ]UpUranus
 *  http://www.qaz-gaming.com
 *
 * Description:
 *   Marks a player as a cheater and they no longer do any damage
 *   Cheater will now die with he takes any fall damage
 * 
 * 1.0.0
 * Initial Release by Antithasys
 */
 
#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "2.0.0"
#define MAX_STRING_LEN 64
#define MAX_PLAYERS 33

new bool:Cheater[MAX_PLAYERS];

public Plugin:myinfo =

{
	name = "Cheater Hater",
	author = "Antithasys, [QaZ]Upuranus",
	description = "Give cheaters a hard time.",
	version = PLUGIN_VERSION,
	url = "http://www.qaz-gaming.com"
}

public OnPluginStart()

{
	CreateConVar("ch_version", PLUGIN_VERSION, "Cheater Hater", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_cheater", Command_Cheater, ADMFLAG_BAN, "Marks player as a cheater");
}

/* HOOKED EVENTS */

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)

{
	if (Cheater[client]) {
		if (damagetype & DMG_FALL) {
			damage *= 1000.0;
			return Plugin_Changed;
		}
	}
	if (Cheater[attacker]) {
		if (client != attacker) {
			damage *= 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public OnClientDisconnect(client)

{
	CleanUp(client);
}

/* COMMAND FUNCTIONS */

public Action:Command_Cheater(client, args)
{
	decl String:playeruserid[MAX_STRING_LEN];
	GetCmdArg(1, playeruserid, MAX_STRING_LEN);
	new player = GetClientOfUserId(StringToInt(playeruserid));
	if (!player || !IsClientInGame(player)) {
		new Handle:playermenu = BuildPlayerMenu();
		DisplayMenu(playermenu, client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}
	SetCheater(client, player);
	return Plugin_Handled;
}

/* STOCK FUNCTIONS */

stock SetCheater(client, player)
{
	decl String:pName[MAX_STRING_LEN];
	GetClientName(player, pName, MAX_STRING_LEN);
	if (!Cheater[player]) {
		Cheater[player] = true;
		PrintHintText(client, "%s is now tagged as a cheater", pName);
	} else {
		Cheater[player] = false;
		PrintHintText(client, "%s is no longer tagged as a cheater", pName);
	}
}

stock CleanUp(client)
{
	Cheater[client] = false;
}

/* MENU CODE */

stock Handle:BuildPlayerMenu()
{
	new Handle:menu = CreateMenu(Menu_SelectPlayer);
	AddTargetsToMenu(menu, 0, true, false);
	SetMenuTitle(menu, "Select A Player:");
	SetMenuExitButton(menu, true);
	return menu;
}

public Menu_SelectPlayer(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		new String:selection[MAX_STRING_LEN];
		GetMenuItem(menu, param2, selection, MAX_STRING_LEN);
		new player = GetClientOfUserId(StringToInt(selection));
		if (param1 == player) {
			PrintHintText(param1, "You are not a cheater");
		} else if (!IsClientInGame(player)) {
			PrintHintText(param1, "Player no longer in game");
		} else {
			SetCheater(param1, player);
		}
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}