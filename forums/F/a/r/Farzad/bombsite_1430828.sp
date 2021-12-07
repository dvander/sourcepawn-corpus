#include <sourcemod>
#include <sdktools>
#include <cstrike>
 
public Plugin:myinfo =
{
	name = "Bomb Site",
	author = "AoT [!] Farzad",
	description = "Displays a menu to the bomber to choose the bomb's destination.",
	version = "1.0.0.0",
	url = "http://www.aotclan.net/"
}
 
public OnPluginStart()
{
	// Hook the spawn event
	HookEvent("player_spawn", Event_Spawn);
}
 
public Event_Spawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	// Get the client id from the event
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// Check if client is ingame and a terrorist
	if (IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		// Check to see if the player has the bomb
		new ent = -1;
		if ((ent = GetPlayerWeaponSlot(client, CS_SLOT_C4)) != -1)
		{
			if (!IsValidEntity(ent)) {
				return;
			}

			new String:className[32];
			GetEdictClassname(ent, className, sizeof(className));
			
			// Secondary check, its not needed but better safe than sorry
			if (StrEqual(className, "weapon_c4"))
			{
				// Open the menu
				Menu_open(client);
			}
		}
	}
}

public Action:Menu_open(any:client)
{
	// Create the menu and send it
	new Handle:BombMenu = CreateMenu(Menu_Selection);
	SetMenuTitle(BombMenu, "Where to plant the bomb ?");

	AddMenuItem(BombMenu, "A", "Bomb Site A");
	AddMenuItem(BombMenu, "B", "Bomb Site B");

	DisplayMenu(BombMenu, client, 20);
}

public Menu_Selection(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));

		// Send the message to all the terrorists
		for (new i = 1; i <= MaxClients; i ++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
			{
				PrintToChat(i, "\x05[Bomb Site]\x01: The bomb will be planted at bomb site \x03[%s]\x01, follow the bomb and defend it.", info);
			}
		}
	}
}