//////////////////////////////////////////////////////////////////////////////////
// RateChecker 0.2 by pRED*														//
//																				//
//	Displays Clients Rates in a Panel											//
//																				//
//	Cmds: sm_rate <name or #userid>												//
//		- displays a panel showing showing that users rates						//
//		- No param shows your own rates											//
//		sm_ratelist																//
//		- Prints all players rates into console									//
//																				//
//	ChangeLog:																	//
//		0.1 - Initial Version													//
//		0.2 - Added sm_ratelist command											//
//																				//
//////////////////////////////////////////////////////////////////////////////////

#include <sourcemod>

#define PLUGIN_VERSION "0.2"

new g_current[MAXPLAYERS]

public Plugin:myinfo = 
{
	name = "RateChecker",
	author = "pRED*",
	description = "Displays Clients Rates in a Panel",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases")
	LoadTranslations("core.phrases")
	
	CreateConVar("sm_rate_version", PLUGIN_VERSION, "RateChecker Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	RegConsoleCmd("sm_rate", Cmd_Rate)
	RegAdminCmd("sm_ratelist", Cmd_RateList, ADMFLAG_GENERIC)
}

public Action:Cmd_RateList(client,args)
{
	new maxplayers=GetMaxClients()
	
	new String:interp[10],String:update[10],String:cmd[10],String:rate[10],String:name[32]
	
	PrintToConsole(client,"Name Rate UpdateRate CmdRate Interp")
	
	for (new i=1; i<=maxplayers;i++)
	{
		if (!IsClientInGame(i))
			continue
		
		GetClientName(i, name, 31)
		GetClientInfo(i, "cl_interp", interp, 9)
		GetClientInfo(i, "cl_updaterate", update, 9)
		GetClientInfo(i, "cl_cmdrate",cmd, 9)
		GetClientInfo(i, "rate", rate, 9)
		PrintToConsole(client,"%s %s %s %s %s",name,rate,update,cmd,interp)
		
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
		RatesPrint(client,client)
		return Plugin_Handled	
	}
	
	new String:name[65]
	GetCmdArg(1, name, sizeof(name))
	
	new Clients[2]
	new NumClients = SearchForClients(name, Clients, 2)

	if (NumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client")
		return Plugin_Handled
	}
	else if (NumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", name)
		return Plugin_Handled
	}
	else if (!CanUserTarget(client, Clients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target")
		return Plugin_Handled
	}
	
	RatesPrint(client,Clients[0])

	return Plugin_Handled
}

public RatesPrint(client,target)
{
	new String:interp[10],String:update[10],String:cmd[10],String:rate[10]
	
	GetClientInfo(target, "cl_interp", interp, 9)
	GetClientInfo(target, "cl_updaterate", update, 9)
	GetClientInfo(target, "cl_cmdrate",cmd, 9)
	GetClientInfo(target, "rate", rate, 9)
	
	new Float:finterp = StringToFloat(interp)
	new iupdate = StringToInt(update)
	new icmd = StringToInt(cmd)
	new irate = StringToInt(rate)
	
	new Handle:Panel = CreatePanel(GetMenuStyleHandle(MenuStyle_Radio))
	
	new String:targetname[32],String:text[60]
	GetClientName(target,targetname,31)
	Format(text,59,"Rates for: %s",targetname)
	
	SetPanelTitle(Panel,text)
	
	DrawPanelItem(Panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE)
	Format(text,59,"Rate: %i",irate)
	DrawPanelItem(Panel, text)
	Format(text,59,"cl_updaterate: %i",iupdate)
	DrawPanelItem(Panel, text)
	Format(text,59,"cl_cmdrate: %i",icmd)
	DrawPanelItem(Panel, text)
	Format(text,59,"cl_interp: %f",finterp)
	DrawPanelItem(Panel, text)
	DrawPanelItem(Panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE)
	
	Format(text,59,"%t","Previous")
	DrawPanelItem(Panel, text)
	Format(text,59,"%t","Next")
	DrawPanelItem(Panel, text)
	Format(text,59,"%t","Exit")
	DrawPanelItem(Panel, text)
	
	SendPanelToClient(Panel, client, RateMenu, 20)
	
	CloseHandle(Panel)

	g_current[client]=target
}

public RateMenu(Handle:menu, MenuAction:action, param1, param2)
{
	new next
	
	if (action == MenuAction_Select)
	{
		if (param2==5) //Previous
		{
			next=FindPrevPlayer(g_current[param1])
			if (next!=-1)
				RatesPrint(param1,next)
			else
				PrintToChat(param1,"[SM] %t","No matching client")
			
		} else if (param2==6) //Next
		{
			next=FindNextPlayer(g_current[param1])
			if (next!=-1)
				RatesPrint(param1,next)
			else
				PrintToChat(param1,"[SM] %t","No matching client")
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
	new maxclients=GetMaxClients()
	new temp=player
	
	do
	{
		temp++
		if (temp>maxclients)
			temp=1
		
		//been all the way around without finding.
		//quit with an error to prevent infinite loop
		if (temp==player)
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
	new maxclients=GetMaxClients()
	new temp=player
	
	do
	{
		temp--
		if (temp<1)
			temp=maxclients

		//been all the way around without finding.
		//quit with an error to prevent infinite loop
		if (temp==player)
			return -1
	}
	while (!(IsClientInGame(temp) && !IsFakeClient(temp)))
	
	return temp

}