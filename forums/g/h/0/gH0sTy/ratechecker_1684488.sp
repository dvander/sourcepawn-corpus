//////////////////////////////////////////////////////////////////////////////////
// RateChecker 0.4 by pRED*     (modified by BehaartesEtwas and PlayBoy31.fr)   //
//                                                                              //
//      Displays Clients Rates in a Panel                                       //
//                                                                              //
//      Cmds: sm_rate <name or #userid>                                         //
//              - displays a panel showing showing that users rates             //
//              - No param shows your own rates                                 //
//              sm_ratelist                                                     //
//              - Prints all players rates into console                         //
//                                                                              //
//      ChangeLog:                                                              //
//              0.1 - Initial Version                                           //
//              0.2 - Added sm_ratelist command                                 //
//              0.3be - Added display of real values and additional info        //
//              0.4 - Fix deprecated, added steamid to menu, added rate/rates   //
//                    commands for says areas and reworked sp file              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////

#include <sourcemod>

#define PLUGIN_VERSION "0.4"

new g_current[MAXPLAYERS]

public Plugin:myinfo =
{
	name = "RateChecker",
	author = "pRED*, mod. by BehaartesEtwas and PlayBoy31.fr",
	description = "Displays Clients Rates in a Panel",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases")
	LoadTranslations("core.phrases")

	CreateConVar("sm_rate_version", PLUGIN_VERSION, "RateChecker Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	RegAdminCmd("sm_rate", Cmd_Rate, ADMFLAG_GENERIC)
	RegAdminCmd("sm_ratelist", Cmd_RateList, ADMFLAG_GENERIC)
	
	AddCommandListener(Command_SayRates, "say")
	AddCommandListener(Command_SayRates, "say2")
	AddCommandListener(Command_SayRates, "say_team")
}

public Action:Cmd_RateList(client,args)
{
	new String:interp[32], String:update[32], String:cmd[32], String:rate[32], String:name[MAX_NAME_LENGTH]

	PrintToConsole(client, "Name Rate UpdateRate CmdRate Interp")

	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if (!IsClientInGame(i))
			continue

		GetClientName(i, name, sizeof(name))
		GetClientInfo(i, "cl_interp", interp, sizeof(interp))
		GetClientInfo(i, "cl_updaterate", update, sizeof(update))
		GetClientInfo(i, "cl_cmdrate", cmd, sizeof(cmd))
		GetClientInfo(i, "rate", rate, sizeof(rate))
		PrintToConsole(client,"%32s %s %s %s %s", name, rate, update, cmd, interp)
	}
}

public Action:Cmd_Rate(client, args)
{
	if (args > 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_rate <name or #userid>")
		return Plugin_Handled;
	}

	if (args == 0)
	{
		RatesPrint(client, client)
		return Plugin_Handled
	}

	decl String:name[MAX_NAME_LENGTH]
	GetCmdArg(1, name, sizeof(name))

	new ClientIndex = FindTarget(client, name, true)

	if (ClientIndex == -1)
		return Plugin_Handled

	else if (!CanUserTarget(client, ClientIndex))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target")
		return Plugin_Handled
	}

	RatesPrint(client, ClientIndex)

	return Plugin_Handled
}

public RatesPrint(client, target)
{
	new String:interp[32], String:update[32], String:cmd[32], String:rate[32]

	GetClientInfo(target, "cl_interp", interp, sizeof(interp))
	GetClientInfo(target, "cl_updaterate", update, sizeof(update))
	GetClientInfo(target, "cl_cmdrate", cmd, sizeof(cmd))
	GetClientInfo(target, "rate", rate, sizeof(rate))

	new Float:finterp = StringToFloat(interp)
	new iupdate = StringToInt(update)
	new icmd = StringToInt(cmd)
	new irate = StringToInt(rate)

	// real rates! directions as seen from server!
	new Float:fin  = GetClientAvgPackets(target, NetFlow_Incoming)	// cmdrate
	new Float:fout = GetClientAvgPackets(target, NetFlow_Outgoing)	// updaterate

	new Float:fchoke = GetClientAvgChoke(target, NetFlow_Outgoing)
	new Float:floss  = GetClientAvgLoss(target, NetFlow_Outgoing)

	new Float:fping = GetClientAvgLatency(target, NetFlow_Outgoing)

	new Float:fdin  = GetClientAvgData(target, NetFlow_Incoming)
	new Float:fdout = GetClientAvgData(target, NetFlow_Outgoing)

	new Handle:Panel = CreatePanel(GetMenuStyleHandle(MenuStyle_Radio))

	new String:targetname[MAX_NAME_LENGTH], String:text[64], String:steamid[32]
	
	GetClientName(target, targetname, sizeof(targetname))
	GetClientAuthString(target, steamid, sizeof(steamid))
	
	Format(text, sizeof(text), "Rates for: %s (%s)", targetname, steamid)

	SetPanelTitle(Panel, text)

	DrawPanelItem(Panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE)
	Format(text, sizeof(text), "Rate (CVAR): %i", irate)
	DrawPanelItem(Panel, text)
	Format(text, sizeof(text), "cl_updaterate (CVAR / real): %i / %.2f/s", iupdate, fout)
	DrawPanelItem(Panel, text)
	Format(text, sizeof(text), "cl_cmdrate (CVAR / real): %i / %.2f/s", icmd, fin)
	DrawPanelItem(Panel, text)
	Format(text, sizeof(text), "cl_interp: %.4f s", finterp)
	DrawPanelItem(Panel, text)
	Format(text, sizeof(text), "choke / loss: %.2f%% / %.2f%%", (fchoke*100.0), (floss*100.0))
	DrawPanelItem(Panel, text)
	Format(text, sizeof(text), "kB/s (in/out): %.2f / %.2f", (fdin/1000.0), (fdout/1000.0))
	DrawPanelItem(Panel, text)
	Format(text, sizeof(text), "Ping: %.2f ms", (fping*1000.0))
	DrawPanelItem(Panel, text)
	DrawPanelItem(Panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE)

	Format(text, sizeof(text), "%t", "Previous")
	DrawPanelItem(Panel, text)
	Format(text, sizeof(text), "%t", "Next")
	DrawPanelItem(Panel, text)
	Format(text, sizeof(text), "%t", "Exit")
	DrawPanelItem(Panel, text)

	SendPanelToClient(Panel, client, RateMenu, 20)

	CloseHandle(Panel)

	g_current[client] = target
}

public RateMenu(Handle:menu, MenuAction:action, param1, param2)
{
	new next

	if (action == MenuAction_Select)
	{
		if (param2 == 8) //Previous
		{
			next = FindPrevPlayer(g_current[param1])
			if (next != -1)
				RatesPrint(param1, next)
			else
				PrintToChat(param1, "[SM] %t","No matching client")

		} else if (param2 == 9) //Next
		{
			next=FindNextPlayer(g_current[param1])
			if (next != -1)
				RatesPrint(param1, next)
			else
				PrintToChat(param1, "[SM] %t","No matching client")
		}
	}
}

/**
 * Finds the Next Non bot connected player (based on id number)
 *
 * @param player		Id number of the current player
 * @return				Id of next player or -1 for failure
 */
stock FindNextPlayer(player)
{
	new temp = player

	do
	{
		temp++
		if (temp > GetMaxClients())
			temp = 1

		//been all the way around without finding.
		//quit with an error to prevent infinite loop
		if (temp == player)
			return -1
	}
	while (!(IsClientInGame(temp) && !IsFakeClient(temp)))

	return temp
}

/**
 * Finds the Previous Non bot connected player (based on id number)
 *
 * @param player		Id number of the current player
 * @return				Id of previous player or -1 for failure
 */
stock FindPrevPlayer(player)
{
	new temp = player

	do
	{
		temp--
		if (temp < 1)
			temp = GetMaxClients()

		//been all the way around without finding.
		//quit with an error to prevent infinite loop
		if (temp == player)
			return -1
	}
	while (!(IsClientInGame(temp) && !IsFakeClient(temp)))

	return temp
}

public Action:Command_SayRates(client, const String:command[], argc)
{
	decl String:text[192];
	new startidx = 0;
	if (GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}
	
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	if (strcmp(command, "say2", false) == 0)
		startidx += 4;

	if ((strcmp(text[startidx], "rate", false) == 0) || (strcmp(text[startidx], "rates", false) == 0))
	{
		RatesPrint(client, client)
	}
	
	return Plugin_Continue;
}