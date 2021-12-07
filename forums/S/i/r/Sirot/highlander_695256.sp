#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>

#define PLUGIN_VERSION  "0.4"

public Plugin:myinfo = 
{
	name = "Highlander",
	author = "Sirot",
	description = "There can only be one (of each class).",
	version = PLUGIN_VERSION,
	url = "http://zombiefort.blogspot.com/"
}

///Global Variables

new hl_a_wishList[19];
new hl_a_classList[4][10];
new Handle:hl_cvar_Enable = INVALID_HANDLE;
static String:hl_a_Classes[TFClassType][] = {"", "Scout", "Sniper", "Soldier", "Demoman", "Medic", "Heavy", "Pyro", "Spy", "Engineer" };
static String:hl_a_Weapons[TFClassType][] = {"", "CTFBat", "CTFClub", "CTFShovel", "CTFBottle", "CTFBonesaw", "CTFFists", "CTFFireAxe", "CTFKnife", "CTFWrench" };


///Callbacks

public OnPluginStart()
{
	CreateConVar("sm_hl_version", PLUGIN_VERSION, "The Highlander Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hl_cvar_Enable = CreateConVar("sm_hl_enable", "0", "On \"1\" activates Highlander (supports only 18 players).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(hl_cvar_Enable, cvar_Enable);
	AutoExecConfig(true, "plugin_hl");
	
	HookEvent("player_spawn", event_Spawn);
	HookEvent("player_say", event_Chat);
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", event_Spawn);
	UnhookEvent("player_say ", event_Chat);
}

public OnClientDisconnected(client)
{
	if (GetConVarFloat(hl_cvar_Enable) == 1.0)
	{
		hl_a_classList[GetClientTeam(client)][TF2_GetPlayerClass(client)] = 0;
	}
}

////Commands

public cvar_Enable(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	if (strcmp(newValue, "1") == 0) 
	{
		ServerCommand("mp_restartround 5");
		PrintToChatAll("\x05Highlander\x01 Enabled.");
	} 
	else 
	{
		PrintToChatAll("\x05Highlander\x01 Disabled.");
	}
}


////Events

public Action:event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ((GetConVarFloat(hl_cvar_Enable) == 1.0))
	{
		function_updateTeams();
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new team = GetClientTeam(client);
		new TFClassType:class = TF2_GetPlayerClass(client);
		if (hl_a_classList[team][class] != client)
		{
			//Check if the current class is free, assign them that class.
			if ((hl_a_classList[team][class] == 0))
			{
				hl_a_classList[team][class] = client;
			}
			//If the class is not free, return the player to their assigned class.
			else if ((hl_a_classList[team][class] == client) && (class != TFClassType:0))
			{
				TF2_SetPlayerClass(client, class, false, true);
				TF2_RespawnPlayer(client);
				CreateTimer(0.5, timer_Respawn, client);
				return Plugin_Continue;
			}
			//If a class was not assigned, give them a class that is free.
			else
			{
				for (new i = 1; i < 10; i++)
				{
					if (hl_a_classList[team][i] == 0)
					{
						hl_a_classList[team][i] = client;
						TF2_SetPlayerClass(client, TFClassType:i, false, true);
						TF2_RespawnPlayer(client);
						CreateTimer(0.5, timer_Respawn, client);
						return Plugin_Continue;
					}
				}
			}
		}
		new weapon = GetPlayerWeaponSlot(client, 1);
		if (IsValidEntity(weapon))
		{
			decl String:netclass[32];
			GetEntityNetClass(weapon, netclass, sizeof(netclass));
			if (strcmp(netclass, hl_a_Weapons[class]) != 0)
			{
				TF2_RespawnPlayer(client);
				return Plugin_Continue;
			}
		}
		PrintToChat(client, "\x05[Highlander]\x01 Type \"hl_swap\" to change classes.");
	}
	return Plugin_Continue;
}

public Action:event_Chat(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarFloat(hl_cvar_Enable) == 1.0)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new team = GetClientTeam(client);
		if (team >1)
		{
			decl String:chatText[191];
			GetEventString(event, "text", chatText, sizeof(chatText));
			if ((strcmp(chatText, "hl_swap", false)) == 0)
			{
				function_updateTeams();
				new String:text[191];
				new String:clientName[191];
				
				//Menu
				new Handle:panel = CreatePanel();
				SetPanelTitle(panel, "Select a Class:");
				for (new i = 1; i < 10; i++)
				{
					//if the player slot has a player.
					if (hl_a_classList[team][i] > 0)
					{
						//If the player is ingame.
						if (IsClientInGame(hl_a_classList[team][i]))
						{
							GetClientName(hl_a_classList[team][i], clientName, 191);
							Format(text,191,"%s -- %s", hl_a_Classes[i], clientName);
						}
						else
						{
							Format(text,191,"%s -- Spot Open", hl_a_Classes[i]);
						}
					}
					else
					{
						Format(text,191,"%s -- Spot Open", hl_a_Classes[i]);
					}
					DrawPanelItem(panel,text);
				}				
				SendPanelToClient(panel, client, PanelHandler, 30);
				CloseHandle(panel);
			}
		}
	}
}

public PanelHandler(Handle:menu, MenuAction:action, client, num)
{
	if (action == MenuAction_Select)
	{
		new team = GetClientTeam(client);
		new TFClassType:class = TF2_GetPlayerClass(client);
		if (TFClassType:num != class)
		{
			if (hl_a_classList[team][num] > 0)
			{
				if (IsClientInGame(hl_a_classList[team][num]))
				{
					//If a player is currently that class, send a request for a swap.
					if (TFClassType:hl_a_wishList[hl_a_classList[team][num]] != class)
					{
						new String:name[191];
						GetClientName(client,name,191);
						hl_a_wishList[client] = num;
						PrintToChat(client, "\x05[Highlander]\x01 Swap pending...");
						PrintToChat(hl_a_classList[team][num], "\x05[Highlander]\x01 \x03%s\x01, who is a \x03%s\x01 wants to swap classes with you. Type in \"hl_swap\" in chat and select their class to accept.", name, hl_a_Classes[class]);
					}
					//If the other player agrees to the swap, swap classes.
					else
					{
						//Kill players
						ClientCommand(hl_a_classList[team][num], "Explode");
						ClientCommand(client, "Explode");
						hl_a_classList[team][class] = hl_a_classList[team][num];
						TF2_SetPlayerClass(hl_a_classList[team][class], TFClassType:class, false, true);
						hl_a_classList[team][num] = client;
						TF2_SetPlayerClass(client, TFClassType:num, false, true);
						PrintToChat(client, "\x05[Highlander]\x01 Swap successful.");
						PrintToChat(hl_a_classList[team][num],"\x05[Highlander]\x01 Swap successful.");
					}
					return;
				}
			}
			//If the class slot is free.
			hl_a_classList[team][class] = 0;
			hl_a_classList[team][num] = client;
			if (num == 6)
			{
				ClientCommand(client, "join_class heavyweapons", hl_a_Classes[num]);
			}
			else
			{
				ClientCommand(client, "join_class %s", hl_a_Classes[num]);
			}
			PrintToChat(client, "\x05[Highlander]\x01 Class successfully changed.");
		}
	} 
	else if (action == MenuAction_Cancel) 
	{
		hl_a_wishList[client] = 0;
		PrintToChat(client, "\x05[Highlander]\x01 Swap cancelled.");
	}
	return;
}

////Functions

public function_updateTeams()
{
	for (new t = 2; t < 4; t++) //team
	{
		for (new c = 1; c < 10; c++) //class
		{
			for (new p = 1; p < 19; p++) //player
			{
				if (IsValidEntity(p))
				{
					if (IsClientInGame(p))
					{
						//Checks if the player is on the proper team.
						if ((p == hl_a_classList[t][c]) && (GetClientTeam(p) != t))
						{
							hl_a_classList[t][c] = 0;
						}
						//Checks if the player is the proper class.
						if ((p == hl_a_classList[t][c]) && (TF2_GetPlayerClass(p) != TFClassType:c))
						{
							hl_a_classList[t][c] = 0;
						}
					}
				}
			}
		}
	}
}

public Action:timer_Respawn(Handle:timer, any:client)
{
	if ((IsValidEntity(client)) && (client > 0))
	{
		if (IsClientInGame(client)) 
		{
			TF2_RespawnPlayer(client);
		}
	}
	return Plugin_Continue;
}

