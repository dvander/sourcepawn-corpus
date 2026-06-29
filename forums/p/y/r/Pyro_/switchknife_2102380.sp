#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1

new bool:g_MenuOpen[MAXPLAYERS + 1];
new bool:g_DisableSwitch[MAXPLAYERS + 1];
new g_iKnife[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "SwitchKnifes",
	author = "Pyro",
	version = "0.26",
	description = "Switch your knife with another player!"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_switchknife", Command_SwitchKnife, "Send a request to the specified player");
	RegConsoleCmd("sm_disablesk", Command_DisableSwitch, "Disable the requests!");

	HookEvent("round_start", Event_RoundStart);
	AddCommandListener(OnSay, "say");
	LoadTranslations("common.phrases");
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	for(new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			g_iKnife[i] = GetPlayerWeaponSlot(i, 2);
		}
		else
		{
			g_iKnife[i] = -1;
		}
	}
}

public OnClientPutInServer(client)
{
	g_DisableSwitch[client] = false;
}

public Action:Command_DisableSwitch(client, args)
{
	g_DisableSwitch[client] = !g_DisableSwitch[client];
	if(g_DisableSwitch[client])
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] You have \x0Fdisabled\x01 switching!");
	}
	else
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] You have \x06enabled\x01 switching!");
	}
	return Plugin_Handled;
}

public Action:Command_SwitchKnife(client, args)
{
	if(args < 1)
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] Usage: sm_switchknife <player>");
		return Plugin_Handled;
	}
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));

	new target = FindTarget(client, arg, false, false);
	if (target == -1)
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] \x07Can't find player!");
		return Plugin_Handled;
	}
	else if(target == client)
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] \x07You can't swap knives with yourself!");
		return Plugin_Handled;
	}
	else if(g_DisableSwitch[target])
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] \x07That person has disabled switching!");
		return Plugin_Handled;
	}
	else if(!IsPlayerAlive(target))
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] \x07That player is dead!");
		return Plugin_Handled;
	}
	else if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] \x07You are dead!");
		return Plugin_Handled;
	}
	else if(g_MenuOpen[target])
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] \x07That player already has an open offer!");
		return Plugin_Handled;
	}
	else if(!GetPlayerWeaponSlot(client, 2))
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] \x07You don't have a knife to switch!");
		return Plugin_Handled;
	}
	else if(!GetPlayerWeaponSlot(target, 2))
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] \x07They don't have a knife to switch!");
		return Plugin_Handled;
	}

	PrintToChat(client, "[\x0ESwitchKnife\x01] Request to switch knives sent to: \x09%N", target);

	DisplayConfirmation(target, client);

	return Plugin_Handled;
}

DisplayConfirmation(client, sender)
{
	new Handle:menu = CreateMenu(ConfirmationHandler);

	new String:senderYes[255];
	Format(senderYes, sizeof(senderYes), "yes%d", sender);
	new String:senderNo[255];
	Format(senderNo, sizeof(senderNo), "no%d", sender);

	SetMenuTitle(menu, "Would you like to switch knives with %N", sender);
	AddMenuItem(menu, senderYes, "Yes");
	AddMenuItem(menu, senderNo, "No");
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 10);
}

public ConfirmationHandler(Handle:menu, MenuAction:action, param1, param2)
{
	//Weird bug caused param1 to be negative
	if(param1 < 0) {param1 *= (-1);}
	if(action == MenuAction_Start)
	{
		g_MenuOpen[param1] = true;
	}
	else if(action == MenuAction_Select)
	{
		new String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		new sender;
		if(info[0] == 'y' && info[1] == 'e' && info[2] == 's')
		{
			strcopy(info, sizeof(info), info[3]);
			sender = StringToInt(info);
			PrintToChat(sender, "[\x0ESwitchKnife\x01] \x09%N\x01 \x06accepted\x01 your request.", param1);
			PrintToChat(param1, "[\x0ESwitchKnife\x01] You \x06accepted\x01 \x09%N\x01's request.", sender);
			SwitchPlayerKnives(param1, sender);
		}
		else
		{
			strcopy(info, sizeof(info), info[2]);
			sender = StringToInt(info);
			PrintToChat(sender, "[\x0ESwitchKnife\x01] \x09%N\x01 \x0Fdeclined\x01 your request.", param1);
			PrintToChat(param1, "[\x0ESwitchKnife\x01] You \x0Fdeclined\x01 \x09%N\x01's request.", sender);
		}
	}
	else if(action == MenuAction_End)
	{
		g_MenuOpen[param1] = false;
		CloseHandle(menu);
	}
}

SwitchPlayerKnives(player1, player2)
{
	if(!IsPlayerAlive(player1))
	{
		PrintToChat(player2, "[\x0ESwitchKnife\x01]\x07 Cancelled: That player is dead!");
		PrintToChat(player1, "[\x0ESwitchKnife\x01]\x07 Cancelled: You are dead!");
		return;
	}
	else if(!IsPlayerAlive(player2))
	{
		PrintToChat(player1, "[\x0ESwitchKnife\x01]\x07 Cancelled: That player is dead!");
		PrintToChat(player2, "[\x0ESwitchKnife\x01]\x07 Cancelled: You are dead!");
		return;
	}

	new knife1 = GetPlayerWeaponSlot(player1, 2);
	new knife2 = GetPlayerWeaponSlot(player2, 2);

	if(knife1 == -1)
	{
		PrintToChat(player1, "[\x0ESwitchKnife\x01]\x07 Cancelled: You don't have a knife to switch!");
		PrintToChat(player2, "[\x0ESwitchKnife\x01]\x07 Cancelled: They don't have a knife to switch!");
		return;
	}
	else if(knife2 == -1)
	{
		PrintToChat(player2, "[\x0ESwitchKnife\x01]\x07 Cancelled: You don't have a knife to switch!");
		PrintToChat(player1, "[\x0ESwitchKnife\x01]\x07 Cancelled: They don't have a knife to switch!");
		return;
	}

	CS_DropWeapon(player1, knife1, false, true);
	CS_DropWeapon(player2, knife2, false, true);

	g_iKnife[player1] = knife2;
	g_iKnife[player2] = knife1;

	CreateTimer(0.1, EquipKnife, player1);
	CreateTimer(0.1, EquipKnife, player2);
}

public Action:EquipKnife(Handle:timer, any:client)
{
	if(IsPlayerAlive(client))
	{
		EquipPlayerWeapon(client, g_iKnife[client]);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", g_iKnife[client]);
	}
}

public Action:OnSay(client, const String:command[], args)
{
	decl String:messageText[200];
	GetCmdArgString(messageText, sizeof(messageText));
	
	if(messageText[1] == '!' && messageText[2] == 's' && messageText[3] == 'w' && messageText[4] == 'i' && messageText[5] == 't' && messageText[6] == 'c' 
		 && messageText[7] == 'h' && messageText[8] == 'k' && messageText[9] == 'n' && messageText[10] == 'i' && messageText[11] == 'f' && messageText[12] == 'e')
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}