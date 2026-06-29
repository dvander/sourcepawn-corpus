#include <sourcemod>
#include <csgo_colors>
#include <smlib>
#include <sdktools_functions>
#include <sdktools>
#include <stamm>

public Plugin:myinfo = 
{
	name = "eXodice",
	author = "DAVID",
	description = "diceplugin by DAVID",
	version = "1.0",
	url = "www.eXoDivision.de"
}

new bool:g_refused[MAXPLAYERS+1] = false;
new Handle:Timers[MAXPLAYERS+1];

public OnPluginStart()
{
	RegConsoleCmd("sm_dice", Command_dice);
	RegConsoleCmd("sm_dice", Command_dice);
	RegConsoleCmd("sm_d", Command_dice);
	RegConsoleCmd("sm_dice", Command_dice);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	for(new client=1; client<=MaxClients; client++)
	{
		if (IsClientConnected(client))
		{
			SetEntityGravity(client, 1);
			g_refused[client] = false;
			
		}
	}
	return Plugin_Continue;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new usrid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(usrid);
	
	DiceMenu(client);
	
	return Plugin_Handled;
}

DiceMenu(client)
{
	new Handle:menu = CreateMenu(DiceMenuHandler);
	
	SetMenuTitle(menu, "[eXo] Dice?");
	
	AddMenuItem(menu, "yes", "yes");
	AddMenuItem(menu, "no", "no");
	
	DisplayMenu(menu, client, 60);
}

public DiceMenuHandler(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select)
	{
		param2++;
		
		switch(param2)
		{
			case 1:
			{
				ClientCommand(client, "sm_dice");
			}
			case 2:
			{
				CloseHandle(menu);
			}
		}
	}
}

public Action:Command_dice(client, args)
{
	if (args != 0)
	{
		return Plugin_Handled;
	}
	
	
	if (IsPlayerAlive(client))
	{
		
		if (!(g_refused[client]))
		{
			g_refused[client] = true;
			new rnd = GetRandomInt(1,9);
			
			if (rnd == 1)
			{	
				//slap von eXoDivision 
				CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {LIME}Dice you become a slap from {OLIVE}David.");
				SlapPlayer(client, Math_GetRandomInt(5,30), true);
				
			} else if (rnd == 2) 
			{
				// HP 5+
				CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {LIME}Dice you become  {LIGHTRED}5 HP");
				Entity_AddHealth(client, 5);
				
			} else if (rnd == 3)
			{
				// NIETE
				CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {LIME}Dice you become  {RED}nothing{LIGHTBLUE} haha");
				
			} else if (rnd == 4)
			{
				// High Gravity
				CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {LIME}Dice your Gravitation is higher");
				SetEntityGravity(client, 0.5);
				
			} else if (rnd == 5)
			{
				// Kill
				CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {LIME}Dice sorry you have no{RED} luck");
				ForcePlayerSuicide(client);
				
			} else if (rnd == 6)
			{
				// SMOKE
				CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {LIME}Dice you become a {OLIVE}smoke");
				GivePlayerItem(client, "weapon_smokegrenade");
				
			} else if (rnd == 7)
			{
				// NIETE
				CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {LIME}Dice you become nothing");
				
			} else if (rnd == 8)
			{
				// 1 STAMMPUNKT
				CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {LIME}Dice you become one stammpoint");
				STAMM_AddClientPoints(client, 1);
				
			} else if (rnd == 9)
			{
				// Low Gravity
				CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {LIME}Dice your gravity is decreased");
				SetEntityGravity(client, 1.7);
				
			} /*else if (rnd == 10)
			{
				// LEERE PISTOLE - P250
				CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {LIME}Dice you become a {LIGHTOLIVE}Pistole");
				
				
			} else if (rnd == 8)
			{
				// Low Gravity
				CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {LIME}Dice your gravity is decreased");
				
			} else if (rnd == 8)
			{
				// Low Gravity
				CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {LIME}Dice your gravity is decreased");
		
			} else if (rnd == 8)
			{
				// Low Gravity
				CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {LIME}Dice your gravity is decreased");
				
			} else if (rnd == 8)
			{
				// Low Gravity
				CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {LIME}Dice your gravity is decreased");
				
			} else if (rnd == 8)
			{
				// Low Gravity
				CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {LIME}Dice your gravity is decreased");
				
			} else if (rnd == 8)
			{
				// Low Gravity
				CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {LIME}Dice your gravity is decreased");
				
			} else if (rnd == 8)
			{
				// Low Gravity
				CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {LIME}Dice your gravity is decreased");
				
			} else if (rnd == 8)
			{
				// Low Gravity
				CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {LIME}Dice your gravity is decreased");
				
			} else if (rnd == 8)
			{
				// Low Gravity
				CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {LIME}Dice your gravity is decreased");
				
			} else if (rnd == 8)
			{
				// Low Gravity
				CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {LIME}Dice your gravity is decreased");
				
			}*/
		
		
		} else
		{
			CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {OLIVE}you can only use dice once");
		}
	
	} else 
	{
		CGOPrintToChat(client, "{LIGHTOLIVE}[eXo] {RED} you death you cant dice");
	}
	
	return Plugin_Handled;
}