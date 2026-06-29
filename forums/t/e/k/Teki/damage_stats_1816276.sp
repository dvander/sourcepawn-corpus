#include <sourcemod>
#include <clientprefs>
#define PLUGIN_VERSION "0.3"
#define AUTHOR "Teki"
#define URL "https://forums.alliedmods.net/showthread.php?t=198022"
#define OUTPUT_PREFIX "[DS]"

new Handle:pluginEnabled = INVALID_HANDLE;
new Handle:panelCookie = INVALID_HANDLE;
new panelDisabled[MAXPLAYERS+1]; //Collect who wants to see stats in console

enum victimDataStruct
{
	String:Data_attackerName[32],
	Data_dmgHealth,
	Data_hitgroup
}
new victimTable[MAXPLAYERS+1][MAXPLAYERS+1][victimDataStruct]; //Collect each hits a player take in a round
new iVictimTable[MAXPLAYERS+1]; //Number of hits each player take in a round
enum attackerDataStruct
{
	String:Data_victimName[32],
	Data_dmgHealth,
	Data_hitgroup
}
new attackerTable[MAXPLAYERS+1][50][attackerDataStruct]; //Collect each hits a player give in a round
new iAttackerTable[MAXPLAYERS+1]; //Number of hits each player give in a round
enum statsDataStruct
{
	String:Data_enemyName[32],
	Data_hitcount,
	Data_headHitcount,
	Data_chestHitcount,
	Data_stomachHitcount,
	Data_leftarmHitcount,
	Data_rightarmHitcount,
	Data_leftlegHitcount,
	Data_rightlegHitcount,
	Data_defaultHitcount,
	Data_dmgHealth,
	Data_headDmgHealth,
	Data_chestDmgHealth,
	Data_stomachDmgHealth,
	Data_leftarmDmgHealth,
	Data_rightarmDmgHealth,
	Data_leftlegDmgHealth,
	Data_rightlegDmgHealth,
	Data_defaultDmgHealth
}
new statsTable[MAXPLAYERS+1][2][MAXPLAYERS+1][statsDataStruct]; //Collect each hits taken/given by a player to other players in a round
new enemies[MAXPLAYERS+1][2]; //Number of enemies who took/gave damages to a player in a round
enum statsMessageDataStruct
{
	String:Data_victimMessage[1024],
	String:Data_attackerMessage[1024],
	String:Data_victimPanelMessage[1024],
	String:Data_attackerPanelMessage[1024],
	String:Data_victimChatMessage[255],
	String:Data_attackerChatMessage[255]
}
new statsMessage[MAXPLAYERS+1][statsMessageDataStruct]; //Collect each players stats messages of the last round
new userDeadTable[MAXPLAYERS+1]; //Collect all players who die in a round

public Plugin:myinfo = 
{
	name = "Damages Stats",
	author = AUTHOR,
	description = "This plugin will show damages stats in a panel or console",
	version = PLUGIN_VERSION,
	url = URL
};

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	CreateConVar("sm_ds_version", PLUGIN_VERSION, "Version of Damages Stats.", FCVAR_NOTIFY);
	pluginEnabled = CreateConVar("sm_ds_enable", "1", "(1)Enable or (0)Disable Damages Stats. Default: 1", FCVAR_NOTIFY);
	RegConsoleCmd("ds", DataStats);
	panelCookie = RegClientCookie("ds_panel", "Damages Stats Panel (0)On/(1)Off", CookieAccess_Public);
}

public OnClientCookiesCached(client)
{
	new String:cookie[2];
	GetClientCookie(client, panelCookie, cookie, sizeof(cookie));
	if (StrEqual(cookie, "1"))
	{
		panelDisabled[client] = 1;
	}
	else
	{
		panelDisabled[client] = 0;
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) //Update stats for a player who die
{
	new victimId = GetEventInt(event, "userid");
	new victim = GetClientOfUserId(victimId);
	
	if (IsClientInGame(victim) && !IsFakeClient(victim) && userDeadTable[victim] != 1 && GetConVarInt(pluginEnabled) == 1)
	{
		userDeadTable[victim] = 1;
		UpdateStatsTable(victim);
		UpdateVictimMessage(victim);
		UpdateAttackerMessage(victim);
		PrintToChat(victim, "\x01\x0B\x05[DS]\x01 Damages Stats updated !\nType \x05!ds \x01to show stats or \x05!ds help \x01to show help");
	}
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) //Get attacker/victim stats for each hits and count them
{
	new victimId = GetEventInt(event, "userid");
	new attackerId = GetEventInt(event, "attacker");
	new dmgHealth = GetEventInt(event, "dmg_health");
	new hitgroup = GetEventInt(event, "hitgroup");
	decl String:victimName[32];
	decl String:attackerName[32];
	new victim = GetClientOfUserId(victimId);
	new attacker = GetClientOfUserId(attackerId);
	GetClientName(victim, victimName, sizeof(victimName));
	GetClientName(attacker, attackerName, sizeof(attackerName));
	
	new iVictim = iVictimTable[victim];
	new iAttacker = iAttackerTable[attacker];
	
	if (IsClientInGame(victim) && IsPlayerAlive(victim) && !IsFakeClient(victim) && userDeadTable[victim] != 1)
	{
		strcopy(victimTable[victim][iVictim][Data_attackerName], 32, attackerName);
		victimTable[victim][iVictim][Data_dmgHealth] = dmgHealth;
		victimTable[victim][iVictim][Data_hitgroup] = hitgroup;
		iVictimTable[victim] = iVictimTable[victim] + 1;
	}
	
	if (attacker != 0 && IsClientInGame(attacker) && IsPlayerAlive(attacker) && !IsFakeClient(attacker) && userDeadTable[attacker] != 1)
	{
		strcopy(attackerTable[attacker][iAttacker][Data_victimName], 32, victimName);
		attackerTable[attacker][iAttacker][Data_dmgHealth] = dmgHealth;
		attackerTable[attacker][iAttacker][Data_hitgroup] = hitgroup;
		iAttackerTable[attacker] = iAttackerTable[attacker] + 1;
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) //Update stats for players who are stayed alive and clear rounds stats
{
	for (new i = 1; i < MAXPLAYERS; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && userDeadTable[i] != 1 && GetConVarInt(pluginEnabled) == 1)
		{
			UpdateStatsTable(i);
			UpdateVictimMessage(i);
			UpdateAttackerMessage(i);
			PrintToChat(i, "\x01\x0B\x05[DS]\x01 Damages Stats updated !\nType \x05!ds \x01to show stats or \x05!ds help \x01to show help");
		}
	}
	
	for (new i = 0; i < MAXPLAYERS; i++)
	{
		for (new iAttacker = 0; iAttacker < MAXPLAYERS; iAttacker++)
		{
			strcopy(victimTable[i][iAttacker][Data_attackerName], 32, "");
			victimTable[i][iAttacker][Data_hitgroup] = 0;
			victimTable[i][iAttacker][Data_dmgHealth] = 0;
		}
		for (new iAttacker = 0; iAttacker < 50; iAttacker++)
		{
			strcopy(attackerTable[i][iAttacker][Data_victimName], 32, "");
			attackerTable[i][iAttacker][Data_hitgroup] = 0;
			attackerTable[i][iAttacker][Data_dmgHealth] = 0;
		}
		for (new iTable = 0; iTable < 2; iTable++)
		{
			enemies[i][iTable] = 0;
		}
		iVictimTable[i] = 0;
		iAttackerTable[i] = 0;
		userDeadTable[i] = 0;
	}
}
 
public PanelHandler1(Handle:menu, MenuAction:action, client, choice) //Panel navigation
{
	if (action == MenuAction_Select)
	{
		if (choice == 1)
		{
			new Handle:panel = CreatePanel();
			SetPanelTitle(panel, "[Damages Taken]");
			DrawPanelText(panel, statsMessage[client][Data_victimMessage]);
			DrawPanelItem(panel, "View damages Taken");
			DrawPanelItem(panel, "View damages Given");
			DrawPanelItem(panel, "Exit");
			SendPanelToClient(panel, client, PanelHandler1, 10);
			CloseHandle(panel);
		}
		else if (choice == 2)
		{
			new Handle:panel = CreatePanel();
			SetPanelTitle(panel, "[Damages Given]");
			DrawPanelText(panel, statsMessage[client][Data_attackerMessage]);
			DrawPanelItem(panel, "View damages Taken");
			DrawPanelItem(panel, "View damages Given");
			DrawPanelItem(panel, "Exit");
			SendPanelToClient(panel, client, PanelHandler1, 10);
			CloseHandle(panel);
		}
		else if (choice == 3)
		{
			new Handle:panel = CreatePanel();
			SetPanelTitle(panel, "[Exit]");
			SendPanelToClient(panel, client, PanelHandler1, 1);
			CloseHandle(panel);
		}
	}
}

public Action:DataStats(client, args) //Command !ds and all arguments
{
	if (GetConVarInt(pluginEnabled) == 1)
	{
		new String:commandArg[32];
		GetCmdArgString(commandArg, sizeof(commandArg))
		
		if (StrEqual(commandArg, "help"))
		{
			PrintToChat(client, "\x01\x0B\x05[DS]\x01 Type \x05!ds\x01 to show stats");
			PrintToChat(client, "\x01\x0B\x05[DS]\x01 Type \x05!ds taken\x01 or \x05!ds given\x01\nTo show taken and given damages");
			PrintToChat(client, "\x01\x0B\x05[DS]\x01 Type \x05!ds console\x01 to switch panel or console output for stats");
			PrintToChat(client, "\x01\x0B\x05[DS]\x01 Type \x05!ds help\x01 to show this message");
		}
		else if (StrEqual(commandArg, "console"))
		{
			if (panelDisabled[client] == 0)
			{
				panelDisabled[client] = 1;
				SetClientCookie(client, panelCookie, "1");
				PrintToChat(client, "\x01\x0B\x05[DS]\x01 Panel disabled, look at the console now !");
			}
			else
			{
				panelDisabled[client] = 0;
				SetClientCookie(client, panelCookie, "0");
				PrintToChat(client, "\x01\x0B\x05[DS]\x01 Console disabled, look at the panel now !");
			}
		}
		else if (StrEqual(commandArg, "taken"))
		{
			if (panelDisabled[client] == 0)
			{
				new Handle:panel = CreatePanel();
				SetPanelTitle(panel, "[Damages Taken]");
				DrawPanelText(panel, statsMessage[client][Data_victimMessage]);
				DrawPanelItem(panel, "View damages Taken");
				DrawPanelItem(panel, "View damages Given");
				DrawPanelItem(panel, "Exit");
				SendPanelToClient(panel, client, PanelHandler1, 10);
				CloseHandle(panel);
			}
			else
			{
				PrintToConsole(client, statsMessage[client][Data_victimMessage]);
				PrintToChat(client, statsMessage[client][Data_victimChatMessage]);
			}
		}
		else if (StrEqual(commandArg, "given"))
		{
			if (panelDisabled[client] == 0)
			{
				new Handle:panel = CreatePanel();
				SetPanelTitle(panel, "[Damages Given]");
				DrawPanelText(panel, statsMessage[client][Data_attackerMessage]);
				DrawPanelItem(panel, "View damages Taken");
				DrawPanelItem(panel, "View damages Given");
				DrawPanelItem(panel, "Exit");
				SendPanelToClient(panel, client, PanelHandler1, 10);
				CloseHandle(panel);
			}
			else
			{
				PrintToConsole(client, statsMessage[client][Data_attackerMessage]);
				PrintToChat(client, statsMessage[client][Data_attackerChatMessage]);
			}
		}
		else if (StrEqual(commandArg, ""))
		{
			if (panelDisabled[client] == 0)
			{
				new Handle:panel = CreatePanel();
				SetPanelTitle(panel, "[Damages Stats]");
				DrawPanelItem(panel, "View damages Taken");
				DrawPanelItem(panel, "View damages Given");
				DrawPanelItem(panel, "Exit");
				SendPanelToClient(panel, client, PanelHandler1, 10);
				CloseHandle(panel);
			}
			else
			{
				PrintToConsole(client, statsMessage[client][Data_attackerMessage]);
				PrintToChat(client, statsMessage[client][Data_attackerChatMessage]);
				PrintToConsole(client, statsMessage[client][Data_victimMessage]);
				PrintToChat(client, statsMessage[client][Data_victimChatMessage]);
			}
		}
		else
		{
			PrintToChat(client, "\x01\x0B\x05[DS]\x01 Bad argument, try \x05!ds help");
		}
	}
}

String:UpdateStatsTable(player) // Update THE BIG TABLE (attacker/victim damages stats) for the last rounds stats of a player
{
	decl String:enemyName[32];
	new iVictim = iVictimTable[player];
	new iAttacker = iAttackerTable[player];
	new enemy = -1, oldEnemy = -1, hitgroup, dmgHealth, i, iHits;
	
	for (new iTable = 0; iTable < 2; iTable++)
	{
		for (new iY = 0; iY < MAXPLAYERS; iY++)
		{
			strcopy(statsTable[player][iTable][iY][Data_enemyName], 32, "");
			statsTable[player][iTable][iY][Data_hitcount] = 0;
			statsTable[player][iTable][iY][Data_headHitcount] = 0;
			statsTable[player][iTable][iY][Data_chestHitcount] = 0;
			statsTable[player][iTable][iY][Data_stomachHitcount] = 0;
			statsTable[player][iTable][iY][Data_leftarmHitcount] = 0;
			statsTable[player][iTable][iY][Data_rightarmHitcount] = 0;
			statsTable[player][iTable][iY][Data_leftlegHitcount] = 0;
			statsTable[player][iTable][iY][Data_rightlegHitcount] = 0;
			statsTable[player][iTable][iY][Data_defaultHitcount] = 0;
			statsTable[player][iTable][iY][Data_dmgHealth] = 0;
			statsTable[player][iTable][iY][Data_headDmgHealth] = 0;
			statsTable[player][iTable][iY][Data_chestDmgHealth] = 0;
			statsTable[player][iTable][iY][Data_stomachDmgHealth] = 0;
			statsTable[player][iTable][iY][Data_leftarmDmgHealth] = 0;
			statsTable[player][iTable][iY][Data_rightarmDmgHealth] = 0;
			statsTable[player][iTable][iY][Data_leftlegDmgHealth] = 0;
			statsTable[player][iTable][iY][Data_rightlegDmgHealth] = 0;
			statsTable[player][iTable][iY][Data_defaultDmgHealth] = 0;
		}	
	
		if (iTable == 0)
		{
			iHits = iVictim;
		}
		else
		{
			iHits = iAttacker;
		}
		
		while (i < iHits)
		{
			enemy++;
			
			if (iTable == 0)
			{
				strcopy(enemyName, 32, victimTable[player][i][Data_enemyName]);
			}
			else
			{
				strcopy(enemyName, 32, attackerTable[player][i][Data_enemyName]);
			}
			
			for (new iEnemyName = 0; iEnemyName < MAXPLAYERS; iEnemyName++)
			{
				if (StrEqual(enemyName, statsTable[player][iTable][iEnemyName][Data_enemyName]))
				{
					oldEnemy = enemy;
					enemy = iEnemyName;
					break;
				}
				else if (enemy == 0)
				{
					strcopy(statsTable[player][iTable][enemy][Data_enemyName], 32, enemyName);
					oldEnemy = -1;
					break;
				}
				else if(iEnemyName == (MAXPLAYERS - 1) && oldEnemy == -1)
				{
					strcopy(statsTable[player][iTable][enemy][Data_enemyName], 32, enemyName);
					oldEnemy = -1;
					break;
				}
				else if(iEnemyName == (MAXPLAYERS - 1))
				{
					strcopy(statsTable[player][iTable][enemy][Data_enemyName], 32, enemyName);
					oldEnemy = -1;
					break;
				}
			}
			
			if (iTable == 0)
			{
				hitgroup = victimTable[player][i][Data_hitgroup];
				dmgHealth = victimTable[player][i][Data_dmgHealth];
			}
			else
			{
				hitgroup = attackerTable[player][i][Data_hitgroup];
				dmgHealth = attackerTable[player][i][Data_dmgHealth];
			}
			
			switch(hitgroup)
			{
				case 1:
				{
					statsTable[player][iTable][enemy][Data_hitcount]++;
					statsTable[player][iTable][enemy][Data_dmgHealth] += dmgHealth;
					statsTable[player][iTable][enemy][Data_headHitcount]++;
					statsTable[player][iTable][enemy][Data_headDmgHealth] += dmgHealth;
				}
				case 2:
				{
					statsTable[player][iTable][enemy][Data_hitcount]++;
					statsTable[player][iTable][enemy][Data_dmgHealth] += dmgHealth;
					statsTable[player][iTable][enemy][Data_chestHitcount]++;
					statsTable[player][iTable][enemy][Data_chestDmgHealth] += dmgHealth;
				}
				case 3:
				{
					statsTable[player][iTable][enemy][Data_hitcount]++;
					statsTable[player][iTable][enemy][Data_dmgHealth] += dmgHealth;
					statsTable[player][iTable][enemy][Data_stomachHitcount]++;
					statsTable[player][iTable][enemy][Data_stomachDmgHealth] += dmgHealth;
				}
				case 4:
				{
					statsTable[player][iTable][enemy][Data_hitcount]++;
					statsTable[player][iTable][enemy][Data_dmgHealth] += dmgHealth;
					statsTable[player][iTable][enemy][Data_leftarmHitcount]++;
					statsTable[player][iTable][enemy][Data_leftarmDmgHealth] += dmgHealth;
				}
				case 5:
				{
					statsTable[player][iTable][enemy][Data_hitcount]++;
					statsTable[player][iTable][enemy][Data_dmgHealth] += dmgHealth;
					statsTable[player][iTable][enemy][Data_rightarmHitcount]++;
					statsTable[player][iTable][enemy][Data_rightarmDmgHealth] += dmgHealth;
				}
				case 6:
				{
					statsTable[player][iTable][enemy][Data_hitcount]++;
					statsTable[player][iTable][enemy][Data_dmgHealth] += dmgHealth;
					statsTable[player][iTable][enemy][Data_leftlegHitcount]++;
					statsTable[player][iTable][enemy][Data_leftlegDmgHealth] += dmgHealth;
				}
				case 7:
				{
					statsTable[player][iTable][enemy][Data_hitcount]++;
					statsTable[player][iTable][enemy][Data_dmgHealth] += dmgHealth;
					statsTable[player][iTable][enemy][Data_rightlegHitcount]++;
					statsTable[player][iTable][enemy][Data_rightlegDmgHealth] += dmgHealth;
				}
				default:
				{
					statsTable[player][iTable][enemy][Data_hitcount]++;
					statsTable[player][iTable][enemy][Data_dmgHealth] += dmgHealth;
					statsTable[player][iTable][enemy][Data_defaultHitcount]++;
					statsTable[player][iTable][enemy][Data_defaultDmgHealth] += dmgHealth;
				}
			}
			
			if (oldEnemy != -1)
			{
				enemy = oldEnemy - 1;
			}
			
			i++;
		}
		enemies[player][iTable] = enemy + 1;
		i = 0;
		enemy = -1;
	}
}

String:UpdateVictimMessage(victim) // Format the victim stats message
{
	decl String:victimMessage[1024];
	decl String:victimChatMessage[255];
	new iAttackers;
	new iTable = 0;
	new enemiesCount = enemies[victim][iTable];
	
	if (enemiesCount >= 1)
	{
		if (panelDisabled[victim] == 1)
		{
			Format(victimMessage, sizeof(victimMessage), "---------------[DS]---------------\n");
			Format(victimChatMessage, sizeof(victimChatMessage), "\x01\x0B\x02[DS]\x01 You were hit by \x02%d\x01 enemies, see console for more info.", enemiesCount);	
			Format(victimMessage, sizeof(victimMessage), "%sYou were hit by %d enemies :", victimMessage, enemiesCount);
		}
		else
		{
			Format(victimMessage, sizeof(victimMessage), "You were hit by %d enemies :", enemiesCount);
		}
		
		while (iAttackers <= enemiesCount)
		{
			if (statsTable[victim][iTable][iAttackers][Data_hitcount] > 0)
			{
				Format(victimMessage, sizeof(victimMessage), "%s\n%s : %d hits (%d hp) :", victimMessage,
																											statsTable[victim][iTable][iAttackers][Data_enemyName],
																											statsTable[victim][iTable][iAttackers][Data_hitcount],
																											statsTable[victim][iTable][iAttackers][Data_dmgHealth]);
				if (panelDisabled[victim] == 0)
				{
					Format(victimMessage, sizeof(victimMessage), "%s\n", victimMessage);
				}
				
				if (statsTable[victim][iTable][iAttackers][Data_headHitcount] > 0)
				{
					if (panelDisabled[victim] == 1)
					{
						Format(victimMessage, sizeof(victimMessage), "%s\n", victimMessage);
					}
					Format(victimMessage, sizeof(victimMessage), "%s head:%d (%d hp),", victimMessage,
																									statsTable[victim][iTable][iAttackers][Data_headHitcount],
																									statsTable[victim][iTable][iAttackers][Data_headDmgHealth]);
				}
				if (statsTable[victim][iTable][iAttackers][Data_chestHitcount] > 0)
				{
					if (panelDisabled[victim] == 1)
					{
						Format(victimMessage, sizeof(victimMessage), "%s\n", victimMessage);
					}
					Format(victimMessage, sizeof(victimMessage), "%s chest:%d (%d hp),", victimMessage,
																									statsTable[victim][iTable][iAttackers][Data_chestHitcount],
																									statsTable[victim][iTable][iAttackers][Data_chestDmgHealth]);
				}
				if (statsTable[victim][iTable][iAttackers][Data_stomachHitcount] > 0)
				{
					if (panelDisabled[victim] == 1)
					{
						Format(victimMessage, sizeof(victimMessage), "%s\n", victimMessage);
					}
					Format(victimMessage, sizeof(victimMessage), "%s stomach:%d (%d hp),", victimMessage,
																										statsTable[victim][iTable][iAttackers][Data_stomachHitcount],
																										statsTable[victim][iTable][iAttackers][Data_stomachDmgHealth]);
				}
				if (statsTable[victim][iTable][iAttackers][Data_leftarmHitcount] > 0)
				{
					if (panelDisabled[victim] == 1)
					{
						Format(victimMessage, sizeof(victimMessage), "%s\n", victimMessage);
					}
					Format(victimMessage, sizeof(victimMessage), "%s left arm:%d (%d hp),", victimMessage,
																										statsTable[victim][iTable][iAttackers][Data_leftarmHitcount],
																										statsTable[victim][iTable][iAttackers][Data_leftarmDmgHealth]);
				}
				if (statsTable[victim][iTable][iAttackers][Data_rightarmHitcount] > 0)
				{
					if (panelDisabled[victim] == 1)
					{
						Format(victimMessage, sizeof(victimMessage), "%s\n", victimMessage);
					}
					Format(victimMessage, sizeof(victimMessage), "%s right arm:%d (%d hp),", victimMessage,
																										statsTable[victim][iTable][iAttackers][Data_rightarmHitcount],
																										statsTable[victim][iTable][iAttackers][Data_rightarmDmgHealth]);
				}
				if (statsTable[victim][iTable][iAttackers][Data_leftlegHitcount] > 0)
				{
					if (panelDisabled[victim] == 1)
					{
						Format(victimMessage, sizeof(victimMessage), "%s\n", victimMessage);
					}
					Format(victimMessage, sizeof(victimMessage), "%s left leg:%d (%d hp),", victimMessage,
																										statsTable[victim][iTable][iAttackers][Data_leftlegHitcount],
																										statsTable[victim][iTable][iAttackers][Data_leftlegDmgHealth]);
				}
				if (statsTable[victim][iTable][iAttackers][Data_rightlegHitcount] > 0)
				{
					if (panelDisabled[victim] == 1)
					{
						Format(victimMessage, sizeof(victimMessage), "%s\n", victimMessage);
					}
					Format(victimMessage, sizeof(victimMessage), "%s right leg:%d (%d hp),", victimMessage,
																										statsTable[victim][iTable][iAttackers][Data_rightlegHitcount],
																										statsTable[victim][iTable][iAttackers][Data_rightlegDmgHealth]);
				}
				if (statsTable[victim][iTable][iAttackers][Data_defaultHitcount] > 0)
				{
					if (panelDisabled[victim] == 1)
					{
						Format(victimMessage, sizeof(victimMessage), "%s\n", victimMessage);
					}
					Format(victimMessage, sizeof(victimMessage), "%s body:%d (%d hp)", victimMessage, statsTable[victim][iTable][iAttackers][Data_defaultHitcount], statsTable[victim][iTable][iAttackers][Data_defaultDmgHealth]);
				}
			}
			iAttackers++;
		}
		if (panelDisabled[victim] == 1)
		{
			Format(victimMessage, sizeof(victimMessage), "%s\n----------------------------------", victimMessage);
		}
	}
	else
	{
		if (panelDisabled[victim] == 1)
		{
			Format(victimChatMessage, sizeof(victimChatMessage), "\x01\x0B\x02[DS]\x01 You received no damages on the last round !");
		}
		Format(victimMessage, sizeof(victimMessage), "You received no damages on the last round !");
	}
	strcopy(statsMessage[victim][Data_victimMessage], 1024, victimMessage);
	strcopy(statsMessage[victim][Data_victimChatMessage], 1024, victimChatMessage);
}

String:UpdateAttackerMessage(attacker) // Format the attacker stats message
{
	decl String:attackerMessage[1024];
	decl String:attackerChatMessage[255];
	new iVictims;
	new iTable = 1;
	new enemiesCount = enemies[attacker][iTable];
	
	if (enemiesCount >= 1)
	{
		if (panelDisabled[attacker] == 1)
		{
			Format(attackerMessage, sizeof(attackerMessage), "---------------[DS]---------------\n");
			Format(attackerChatMessage, sizeof(attackerChatMessage), "\x01\x0B\x04[DS]\x01 You have hit \x04%d\x01 enemies, see console for more info.", enemiesCount);
			Format(attackerMessage, sizeof(attackerMessage), "%sYou have hit %d enemies :", attackerMessage, enemiesCount);
		}
		else
		{
			Format(attackerMessage, sizeof(attackerMessage), "You have hit %d enemies :", enemiesCount);
		}
		
		while (iVictims <= enemiesCount)
		{
			if (statsTable[attacker][iTable][iVictims][Data_hitcount] > 0)
			{
				Format(attackerMessage, sizeof(attackerMessage), "%s\n%s : %d hits (%d hp) :", attackerMessage,
																											statsTable[attacker][iTable][iVictims][Data_enemyName],
																											statsTable[attacker][iTable][iVictims][Data_hitcount],
																											statsTable[attacker][iTable][iVictims][Data_dmgHealth]);
				if (panelDisabled[attacker] == 0)
				{
					Format(attackerMessage, sizeof(attackerMessage), "%s\n", attackerMessage);
				}
			
				if (statsTable[attacker][iTable][iVictims][Data_headHitcount] > 0)
				{
					if (panelDisabled[attacker] == 1)
					{
						Format(attackerMessage, sizeof(attackerMessage), "%s\n", attackerMessage);
					}
					Format(attackerMessage, sizeof(attackerMessage), "%s head:%d (%d hp),", attackerMessage,
																									statsTable[attacker][iTable][iVictims][Data_headHitcount],
																									statsTable[attacker][iTable][iVictims][Data_headDmgHealth]);
				}
				if (statsTable[attacker][iTable][iVictims][Data_chestHitcount] > 0)
				{
					if (panelDisabled[attacker] == 1)
					{
						Format(attackerMessage, sizeof(attackerMessage), "%s\n", attackerMessage);
					}
					Format(attackerMessage, sizeof(attackerMessage), "%s chest:%d (%d hp),", attackerMessage,
																									statsTable[attacker][iTable][iVictims][Data_chestHitcount],
																									statsTable[attacker][iTable][iVictims][Data_chestDmgHealth]);
				}
				if (statsTable[attacker][iTable][iVictims][Data_stomachHitcount] > 0)
				{
					if (panelDisabled[attacker] == 1)
					{
						Format(attackerMessage, sizeof(attackerMessage), "%s\n", attackerMessage);
					}
					Format(attackerMessage, sizeof(attackerMessage), "%s stomach:%d (%d hp),", attackerMessage,
																										statsTable[attacker][iTable][iVictims][Data_stomachHitcount],
																										statsTable[attacker][iTable][iVictims][Data_stomachDmgHealth]);
				}
				if (statsTable[attacker][iTable][iVictims][Data_leftarmHitcount] > 0)
				{
					if (panelDisabled[attacker] == 1)
					{
						Format(attackerMessage, sizeof(attackerMessage), "%s\n", attackerMessage);
					}
					Format(attackerMessage, sizeof(attackerMessage), "%s left arm:%d (%d hp),", attackerMessage,
																										statsTable[attacker][iTable][iVictims][Data_leftarmHitcount],
																										statsTable[attacker][iTable][iVictims][Data_leftarmDmgHealth]);
				}
				if (statsTable[attacker][iTable][iVictims][Data_rightarmHitcount] > 0)
				{
					if (panelDisabled[attacker] == 1)
					{
						Format(attackerMessage, sizeof(attackerMessage), "%s\n", attackerMessage);
					}
					Format(attackerMessage, sizeof(attackerMessage), "%s right arm:%d (%d hp),", attackerMessage,
																										statsTable[attacker][iTable][iVictims][Data_rightarmHitcount],
																										statsTable[attacker][iTable][iVictims][Data_rightarmDmgHealth]);
				}
				if (statsTable[attacker][iTable][iVictims][Data_leftlegHitcount] > 0)
				{
					if (panelDisabled[attacker] == 1)
					{
						Format(attackerMessage, sizeof(attackerMessage), "%s\n", attackerMessage);
					}
					Format(attackerMessage, sizeof(attackerMessage), "%s left leg:%d (%d hp),", attackerMessage,
																										statsTable[attacker][iTable][iVictims][Data_leftlegHitcount],
																										statsTable[attacker][iTable][iVictims][Data_leftlegDmgHealth]);
				}
				if (statsTable[attacker][iTable][iVictims][Data_rightlegHitcount] > 0)
				{
					if (panelDisabled[attacker] == 1)
					{
						Format(attackerMessage, sizeof(attackerMessage), "%s\n", attackerMessage);
					}
					Format(attackerMessage, sizeof(attackerMessage), "%s right leg:%d (%d hp),", attackerMessage,
																										statsTable[attacker][iTable][iVictims][Data_rightlegHitcount],
																										statsTable[attacker][iTable][iVictims][Data_rightlegDmgHealth]);
				}
				if (statsTable[attacker][iTable][iVictims][Data_defaultHitcount] > 0)
				{
					if (panelDisabled[attacker] == 1)
					{
						Format(attackerMessage, sizeof(attackerMessage), "%s\n", attackerMessage);
					}
					Format(attackerMessage, sizeof(attackerMessage), "%s body:%d (%d hp)", attackerMessage, statsTable[attacker][iTable][iVictims][Data_defaultHitcount], statsTable[attacker][iTable][iVictims][Data_defaultDmgHealth]);
				}
			}
			iVictims++;
		}
		if (panelDisabled[attacker] == 1)
		{
			Format(attackerMessage, sizeof(attackerMessage), "%s\n----------------------------------", attackerMessage);
		}
	}
	else
	{
		if (panelDisabled[attacker] == 1)
		{
			Format(attackerChatMessage, sizeof(attackerChatMessage), "\x01\x0B\x04[DS]\x01 You dealed no damages on the last round !");
		}
		Format(attackerMessage, sizeof(attackerMessage), "You dealed no damages on the last round !");
	}
	strcopy(statsMessage[attacker][Data_attackerMessage], 1024, attackerMessage);
	strcopy(statsMessage[attacker][Data_attackerChatMessage], 1024, attackerChatMessage);
}