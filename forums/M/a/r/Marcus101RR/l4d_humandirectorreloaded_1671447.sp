#pragma semicolon 1
/**
 * \x01 - Default
 * \x02 - Team Color
 * \x03 - Light Green
 * \x04 - Orange
 * \x05 - Olive
 * 
 */

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"0.7.0"
#define CVAR_FLAGS		FCVAR_PLUGIN|FCVAR_NOTIFY
new MOB_COST;
new SMOKER_COST;
new BOOMER_COST;
new HUNTER_COST;
new SPITTER_COST;
new CHARGER_COST;
new JOCKEY_COST;
new WITCH_COST;
new TANK_COST;

new Handle:m_iDirectorStressTimer =				INVALID_HANDLE;
new Handle:DisplayHumanDirectorPanelTimer[MAXPLAYERS + 1] =	INVALID_HANDLE;
new bool:b_IsDirector[MAXPLAYERS + 1] = false;
new m_iDirectorStress;

public Plugin:myinfo =
{
    name = "[L4D(2)] Human Director Reloaded",
    author = "Marcus101RR & lucskywalker",
    description = "Human Player(s) can become a director to replace the AI Director.",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net"
}

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if(StrEqual(game_name, "left4dead", false))
	{
		MOB_COST = GetConVarInt(FindConVar("z_mega_mob_size"))*6;
		SMOKER_COST = GetConVarInt(FindConVar("z_gas_health"));
		BOOMER_COST = GetConVarInt(FindConVar("z_exploding_health"));
		HUNTER_COST = GetConVarInt(FindConVar("z_gas_health"));
		WITCH_COST = GetConVarInt(FindConVar("z_witch_health"));
		TANK_COST = 1500;
	}
	else if(StrEqual(game_name, "left4dead2", false))
	{
		MOB_COST = GetConVarInt(FindConVar("z_mega_mob_size"))*6;
		SMOKER_COST = GetConVarInt(FindConVar("z_gas_health"));
		BOOMER_COST = GetConVarInt(FindConVar("z_exploding_health"));
		HUNTER_COST = GetConVarInt(FindConVar("z_gas_health"));
		SPITTER_COST = GetConVarInt(FindConVar("z_spitter_health"));
		CHARGER_COST = GetConVarInt(FindConVar("z_charger_health"));
		JOCKEY_COST = GetConVarInt(FindConVar("z_jockey_health"));
		WITCH_COST = GetConVarInt(FindConVar("z_witch_health"));
		TANK_COST = 1500;
	}

	CreateConVar("sm_humandirectorreloaded_version", PLUGIN_VERSION, "Human Director Reloaded Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	RegConsoleCmd("sm_hdmenu", DisplayHumanDirectorMenu, "Human Director Menu.");
	RegConsoleCmd("sm_hdfuss", GetAllFuss, "Human Director Menu.");

	HookEvent("round_start", round_start);
	HookEvent("round_end", round_end, EventHookMode_Pre);

	AutoExecConfig(true, "l4d_humandirectorreloaded");
}

public Action:GetAllFuss(client, args)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if (!IsClientConnected(i))
			continue;
		if (!IsClientInGame(i))
			continue;

		decl String:target_name[MAX_TARGET_LENGTH];
		GetClientName(i, target_name, sizeof(target_name));
		PrintToChatAll("%s - %d - %d - %d", target_name, GetEntProp(i, Prop_Send, "m_clientIntensity"), i,  GetClientOfUserId(GetEntData(i, FindSendPropInfo("SurvivorBot", "m_humanSpectatorUserID"))));
	}
	//PrintToChatAll("%d", GetEntProp(client, Prop_Send, "m_upgradeBitVec"));
	return Plugin_Handled;
}

public OnClientPostAdminCheck(client)
{
	//ClientCommand(client, "bind f3 sm_hdmenu");
}

public OnClientDisconnect(client)
{
	if(b_IsDirector[client] == true)
	{
		HumanDirectorQuit(client);
	}
}

public Action:DisplayHumanDirectorMenu(client, args)
{
	DisplayHumanDirectorPanel(client);
}

public DisplayHumanDirectorPanel(client)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && b_IsDirector[i] == true && b_IsDirector[client] == false)
		{
			PrintToChat(client, "There currently is already a director!");
			return;
		}
		
	}
	if(b_IsDirector[client] == true && GetClientTeam(client) == 3)
	{
		new Handle:HumanDirectorPanel = CreatePanel();

		decl String:buffer[255];
		Format(buffer, sizeof(buffer), "Human Director Menu");
		SetPanelTitle(HumanDirectorPanel, buffer);
		
		new String:text[64];
		Format(text, sizeof(text), "Stress Points: %d", m_iDirectorStress);
		DrawPanelText(HumanDirectorPanel, text);
		
		DrawPanelItem(HumanDirectorPanel, "Spawn Menu");
		DrawPanelItem(HumanDirectorPanel, "Quit");
		DrawPanelItem(HumanDirectorPanel, "Close");
		DrawPanelItem(HumanDirectorPanel, "Help");
		
		SendPanelToClient(HumanDirectorPanel, client, DisplayHumanDirectorPanelHandler, 30);
		CloseHandle(HumanDirectorPanel);
		DisplayHumanDirectorPanelTimer[client] = CreateTimer(1.0, timer_HumanDirectorPanelHandler, client);
	}
	if(b_IsDirector[client] == false)
	{
		if(HumanDirectorAvailable() == true)
		{
			b_IsDirector[client] = true;
			ChangeClientTeam(client, 3);
			SetConVarInt(FindConVar("director_no_bosses"), 1);
			SetConVarInt(FindConVar("director_no_specials"), 1);
			SetConVarInt(FindConVar("director_no_mobs"), 1);
			m_iDirectorStressTimer = CreateTimer(1.0, timer_AddDirectorStress, _, TIMER_REPEAT);
		}
	}
	if(b_IsDirector[client] == true && GetClientTeam(client) != 3)
	{
		b_IsDirector[client] = true;
		ChangeClientTeam(client, 3);
	}
	if(b_IsDirector[client] == true && GetClientTeam(client) == 3 && m_iDirectorStressTimer == INVALID_HANDLE)
	{
		m_iDirectorStressTimer = CreateTimer(1.0, timer_AddDirectorStress, _, TIMER_REPEAT);
	}
}

public DisplayHumanDirectorPanelHandler(Handle:HumanDirectorPanel, MenuAction:action, param1, param2)
{
	new client = param1;
	if (action == MenuAction_Select)
	{
		if(param2 == 1)
		{
			KillTimer(DisplayHumanDirectorPanelTimer[client]);
			DisplayHumanDirectorPanelTimer[client] = INVALID_HANDLE;
			SpawnMenu(client);
		}
		else if(param2 == 2)
		{
			KillTimer(DisplayHumanDirectorPanelTimer[client]);
			DisplayHumanDirectorPanelTimer[client] = INVALID_HANDLE;
			HumanDirectorQuit(client);
		}
		else if(param2 == 3)
		{
			KillTimer(DisplayHumanDirectorPanelTimer[client]);
			DisplayHumanDirectorPanelTimer[client] = INVALID_HANDLE;
		}
		else if(param2 == 4)
		{

		}
	}
	else if(action == MenuAction_Cancel)
	{
		// Nothing
	}
}

public Action:timer_HumanDirectorPanelHandler(Handle:hTimer, any:client)
{
	DisplayHumanDirectorPanel(client);
}

public SpawnMenu(client)
{
	if(b_IsDirector[client] == true && GetClientTeam(client) == 3)
	{
		decl String:game_name[64];
		GetGameFolderName(game_name, sizeof(game_name));
		new Handle:menu = CreateMenu(SpawnMenuHandler);

		AddMenuItem(menu, "drop1", "Drop Control");

		if(m_iDirectorStress >= SMOKER_COST)
		{
			new String:text[64];
			Format(text, sizeof(text), "Spawn Smoker (%d)", SMOKER_COST);
			AddMenuItem(menu, "option1", text);
		}
		if(m_iDirectorStress >= BOOMER_COST)
		{
			new String:text[64];
			Format(text, sizeof(text), "Spawn Boomer (%d)", BOOMER_COST);
			AddMenuItem(menu, "option2", text);
		}
		if(m_iDirectorStress >= HUNTER_COST)
		{
			new String:text[64];
			Format(text, sizeof(text), "Spawn Hunter (%d)", HUNTER_COST);
			AddMenuItem(menu, "option3", text);
		}
		if(m_iDirectorStress >= SPITTER_COST && StrEqual(game_name, "left4dead2", false))
		{
			new String:text[64];
			Format(text, sizeof(text), "Spawn Spitter (%d)", SPITTER_COST);
			AddMenuItem(menu, "option4", text);
		}
		if(m_iDirectorStress >= CHARGER_COST && StrEqual(game_name, "left4dead2", false))
		{
			new String:text[64];
			Format(text, sizeof(text), "Spawn Charger (%d)", CHARGER_COST);
			AddMenuItem(menu, "option5", text);
		}
		if(m_iDirectorStress >= JOCKEY_COST && StrEqual(game_name, "left4dead2", false))
		{
			new String:text[64];
			Format(text, sizeof(text), "Spawn Jockey (%d)", JOCKEY_COST);
			AddMenuItem(menu, "option6", text);
		}
		if(m_iDirectorStress >= WITCH_COST)
		{
			new String:text[64];
			Format(text, sizeof(text), "Spawn Witch (%d)", WITCH_COST);
			AddMenuItem(menu, "option7", text);
		}
		if(m_iDirectorStress >= TANK_COST)
		{
			new String:text[64];
			Format(text, sizeof(text), "Spawn Tank (%d)", TANK_COST);
			AddMenuItem(menu, "option8", text);
		}
		if(m_iDirectorStress >= MOB_COST)
		{
			new String:text[64];
			Format(text, sizeof(text), "Spawn Mob (%d)", MOB_COST);
			AddMenuItem(menu, "option9", text);
		}
		SetMenuTitle(menu, "Stress Points: %d", m_iDirectorStress);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public SpawnMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				DisplayHumanDirectorPanel(client);
			}
		}
		case MenuAction_Select:
		{
			new String:item1[56];
			GetMenuItem(menu, param2, item1, sizeof(item1));
			if(StrEqual(item1, "drop1", false))
			{
				ChangeClientTeam(client, 1);
				ChangeClientTeam(client, 3);
				SpawnMenu(client);
			}
			else if(StrEqual(item1, "option1", false))
			{
				if(testDistance(client) == true)
				{
					m_iDirectorStress -= SMOKER_COST;
					CheatCommand(client, "z_spawn", "smoker", "area");
					SpawnMenu(client);
				}
				else
				{
					m_iDirectorStress -= SMOKER_COST;
					CheatCommand(client, "z_spawn", "smoker", "auto");
					SpawnMenu(client);
				}
			}
			else if(StrEqual(item1, "option2", false))
			{
				if(testDistance(client) == true)
				{
					m_iDirectorStress -= BOOMER_COST;
					CheatCommand(client, "z_spawn", "boomer", "area");
					SpawnMenu(client);
				}
				else
				{
					m_iDirectorStress -= BOOMER_COST;
					CheatCommand(client, "z_spawn", "boomer", "auto");
					SpawnMenu(client);
				}
			}
			else if(StrEqual(item1, "option3", false))
			{
				if(testDistance(client) == true)
				{
					m_iDirectorStress -= HUNTER_COST;
					CheatCommand(client, "z_spawn", "hunter", "area");
					SpawnMenu(client);
				}
				else
				{
					m_iDirectorStress -= HUNTER_COST;
					CheatCommand(client, "z_spawn", "hunter", "auto");
					SpawnMenu(client);
				}
			}
			else if(StrEqual(item1, "option4", false))
			{
				if(testDistance(client) == true)
				{
					m_iDirectorStress -= SPITTER_COST;
					CheatCommand(client, "z_spawn", "spitter", "area");
					SpawnMenu(client);
				}
				else
				{
					m_iDirectorStress -= SPITTER_COST;
					CheatCommand(client, "z_spawn", "spitter", "auto");
					SpawnMenu(client);
				}
			}
			else if(StrEqual(item1, "option5", false))
			{
				if(testDistance(client) == true)
				{
					m_iDirectorStress -= CHARGER_COST;
					CheatCommand(client, "z_spawn", "charger", "area");
					SpawnMenu(client);
				}
				else
				{
					m_iDirectorStress -= CHARGER_COST;
					CheatCommand(client, "z_spawn", "charger", "auto");
					SpawnMenu(client);
				}
			}
			else if(StrEqual(item1, "option6", false))
			{
				if(testDistance(client) == true)
				{
					m_iDirectorStress -= JOCKEY_COST;
					CheatCommand(client, "z_spawn", "jockey", "area");
					SpawnMenu(client);
				}
				else
				{
					m_iDirectorStress -= JOCKEY_COST;
					CheatCommand(client, "z_spawn", "jockey", "auto");
					SpawnMenu(client);
				}
			}
			else if(StrEqual(item1, "option7", false))
			{
				if(testDistance(client) == true)
				{
					m_iDirectorStress -= WITCH_COST;
					CheatCommand(client, "z_spawn", "witch", "area");
					SpawnMenu(client);
				}
				else
				{
					m_iDirectorStress -= WITCH_COST;
					CheatCommand(client, "z_spawn", "witch", "auto");
					SpawnMenu(client);
				}
			}
			else if(StrEqual(item1, "option8", false))
			{
				if(testDistance(client) == true)
				{
					m_iDirectorStress -= TANK_COST;
					CheatCommand(client, "z_spawn", "tank", "area");
					SpawnMenu(client);
				}
				else
				{
					m_iDirectorStress -= TANK_COST;
					CheatCommand(client, "z_spawn", "tank", "auto");
					SpawnMenu(client);
				}
			}
			else if(StrEqual(item1, "option9", false))
			{
				if(testDistance(client) == true)
				{
					m_iDirectorStress -= MOB_COST;
					CheatCommand(client, "z_spawn", "mob", "area");
					SpawnMenu(client);
				}
				else
				{
					m_iDirectorStress -= MOB_COST;
					CheatCommand(client, "z_spawn", "mob", "auto");
					SpawnMenu(client);
				}
			}
		}
	}
}

bool:HumanDirectorAvailable()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(b_IsDirector[i] == false)
			continue;
		if(b_IsDirector[i] == true)
		{
			return false;
		}		
	}
	return true;
}

public HumanDirectorQuit(client)
{
	b_IsDirector[client] = false;
	FakeClientCommand(client, "jointeam 2");
	SetConVarInt(FindConVar("director_no_bosses"), 0);
	SetConVarInt(FindConVar("director_no_specials"), 0);
	SetConVarInt(FindConVar("director_no_mobs"), 0);
	if(m_iDirectorStressTimer != INVALID_HANDLE)	
	{
		KillTimer(m_iDirectorStressTimer);
		m_iDirectorStressTimer = INVALID_HANDLE;
	}
}

public Action:round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(HumanDirectorAvailable() == false)
	{
		m_iDirectorStressTimer = CreateTimer(1.0, timer_AddDirectorStress, _, TIMER_REPEAT);
	}
}

public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(m_iDirectorStressTimer != INVALID_HANDLE)	
	{
		KillTimer(m_iDirectorStressTimer);
		m_iDirectorStressTimer = INVALID_HANDLE;
	}
}

public Action:timer_AddDirectorStress(Handle:hTimer, any:client)
{
	m_iDirectorStress += GetAverageIntensity();
	if(m_iDirectorStress >= 2000)
	{
		m_iDirectorStress = 2000;
	}
}

public GetAverageIntensity()
{
	new m_iIntensity = 0;
	for(new i=1; i<=MaxClients; i++)
	{
		if (!IsClientConnected(i))
			continue;
		if (!IsClientInGame(i))
			continue;
		if(GetClientTeam(i) == 2)
		{
			m_iIntensity += GetEntProp(i, Prop_Send, "m_clientIntensity");
		}
	}
	new m_iAverageIntensity = (100 / 4) - ((m_iIntensity / GetPlayerCount(2)) / 4);
	return m_iAverageIntensity;
}

public GetPlayerCount(any:team)
{
	new int=0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientConnected(i))
			continue;
		if (!IsClientInGame(i))
			continue;
		if (GetClientTeam(i) != team)
			continue;
		int++;
	}
	return int;
}

public Float:calculDistance(Float:emeteur[3], Float:recepteur[3])
{
	new Float:x = emeteur[0] - recepteur[0];
	new Float:y = emeteur[1] - recepteur[1];
	new Float:z = emeteur[2] - recepteur[2];
	
	// On facilite le spawn en hauteur
	z = z * 3;

	// racine	
	new Float:distanceResultat = SquareRoot(x * x + y * y + z * z);
	
	if (distanceResultat < 0) 
	{
		distanceResultat = -1 * distanceResultat;
	}

	return distanceResultat;
}

public bool:testDistance(client)
{ 
	new bool:unSurvivantDejaTeste = false;

	new Float:angleVue[3];
	new Float:positionJoueur[3];
	new Float:positionVisee[3];
	
	GetClientEyeAngles(client, angleVue);
	GetClientEyePosition(client, positionJoueur);
	
	for(new player=1; player<= MaxClients; player++)
	{
		if (IsClientInGame(player) && IsPlayerAlive(player) && GetClientTeam(player) == 2)
		{
			// On récupére la position du Survivant
			new Float:posSurvivant[3];
			GetClientEyePosition(player, posSurvivant);
			
			// Test position
			new Float:distPos = calculDistance(positionJoueur, posSurvivant);
			new Float:distVisee = calculDistance(positionVisee, posSurvivant);
			
			// Distance critique à respecter
			if(distPos < 450 || distVisee < 450)
			{			
				if(distPos < 450)
				return false;
			}
			else
			{
				if(distPos < 450 || distVisee < 450)
				{
					if(unSurvivantDejaTeste == false)
					{
						unSurvivantDejaTeste = true;
					}
					else
					{				
						if(distPos < 450)
						return false;
					}
				}
			}
		}
	}
	return true;
}

stock bool:HasIdlePlayer(bot)
{
    new userid = GetEntData(bot, FindSendPropInfo("SurvivorBot", "m_humanSpectatorUserID"));
    new client = GetClientOfUserId(userid);
    
    if(client > 0)
    {
        if(IsClientConnected(client) && !IsFakeClient(client))
            return true;
    }    
    return false;
}

stock bool:IsClientIdle(client)
{
    for(new i = 1; i <= MaxClients; i++)
    {
        if(!IsClientConnected(i))
            continue;
        if(!IsClientInGame(i))
            continue;
        if(GetClientTeam(i)!=2)
            continue;
        if(!IsFakeClient(i))
            continue;
        if(!HasIdlePlayer(i))
            continue;
        
        new spectator_userid = GetEntData(i, FindSendPropInfo("SurvivorBot", "m_humanSpectatorUserID"));
        new spectator_client = GetClientOfUserId(spectator_userid);
        
        if(spectator_client == client)
            return true;
    }
    return false;
}

stock GetAnyValidClient()
{
	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target)) return target;
	}
	return -1;
}

stock CheatCommand(client, String:command[], String:argument1[], String:argument2[])
{
	new userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, argument1, argument2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}