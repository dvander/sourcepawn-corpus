#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "Show Players",
	author = "Jaffa",
	description = "Rate display plugin for SourceMod",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	SetConVarString(CreateConVar("sm_rates_version", PLUGIN_VERSION, "Show Rates version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT), PLUGIN_VERSION);

	RegAdminCmd("sm_allrates", Command_allrates, ADMFLAG_GENERIC, "admins are able to view all players rates via console includes IP address");
	RegConsoleCmd("sm_ratehelp", Command_RateMenu, "rate plugin help menu");
	RegConsoleCmd("sm_rates", Command_rates, "displays baisc rate info on all players via console");
	RegConsoleCmd("sm_rate", Command_rate, "displays player rate in a menu");
	
}




public OnClientPutInServer(client)
{
	startmenu(client)

}

startmenu(client)
{
	new Handle:panel = CreatePanel();
	DrawPanelText(panel, "SM Rates Help Menu");
	DrawPanelText(panel, "--------------------");
	DrawPanelText(panel, "Available Commands");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "  !rate - Views your current rates.");
	DrawPanelText(panel, "  !rates - Views other players rates.");
	DrawPanelText(panel, "  !allrates - Admin only command.");
	DrawPanelText(panel, "--------------------");
	DrawPanelText(panel, "  Normal rates are 25000/67/67.");
	DrawPanelText(panel, "  BHOP rates are 30000/101/101.");
	DrawPanelText(panel, "--------------------");
	DrawPanelText(panel, "  !ratehelp - Shows this popup menu.");
	DrawPanelText(panel, "--------------------");
	DrawPanelText(panel, "Written by Jaffa.");
	DrawPanelItem(panel, "exit");
	SendPanelToClient(panel, client, startmenuPanelHandler, 0);
	CloseHandle(panel);
}
public startmenuPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}
public Action:Command_RateMenu(client, args)
{
	new Handle:panel = CreatePanel();
	DrawPanelText(panel, "SM Rates Help Menu");
	DrawPanelText(panel, "--------------------");
	DrawPanelText(panel, "Available Commands");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "  !rate - Views your current rates.");
	DrawPanelText(panel, "  !rates - Views other players rates.");
	DrawPanelText(panel, "  !allrates - Admin only command.");
	DrawPanelText(panel, "--------------------");
	DrawPanelText(panel, "  Normal rates are 25000/67/67.");
	DrawPanelText(panel, "  BHOP rates are 30000/101/101.");
	DrawPanelText(panel, "--------------------");
	DrawPanelText(panel, "  !ratehelp - Shows this popup menu.");
	DrawPanelText(panel, "--------------------");
	DrawPanelText(panel, "SM Rates by Jaffa");
	DrawPanelItem(panel, "exit");
	SendPanelToClient(panel, client, RateMenuPanelHandler, 0);
	CloseHandle(panel);
	return Plugin_Handled;
}
public RateMenuPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}
public Action:Command_allrates(client,args)
{
	if (args < 1)
	{
		// Header
		decl String:h_admin[2];
		decl String:h_name[5];
		decl String:h_rate[5];
		decl String:h_updaterate[11];
		decl String:h_cmdrate[8];
		decl String:h_steamid[21];
		decl String:h_ip[17];
		Format(h_admin, sizeof(h_admin), "%s", "A");
		Format(h_name, sizeof(h_name), "%s", "Name");
		Format(h_rate, sizeof(h_rate), "%s", "Rate");
		Format(h_steamid, sizeof(h_steamid), "%s", "Steam ID");
		Format(h_updaterate, sizeof(h_updaterate), "%s", "Update");
		Format(h_cmdrate, sizeof(h_cmdrate), "%s", "CMD");
		Format(h_ip, sizeof(h_ip), "%s", "IP Address");

		PrintToConsole(client, "------------------------------------------------------------------------------------------------------");
		PrintToConsole(client, "|                                 Player Information by Jaffa                                         |");
		PrintToConsole(client, "------------------------------------------------------------------------------------------------------");
		PrintToConsole(client, "| %1.1s | %-5.5s | %-6.6s | %-3.3s | %-15.15s |%-20.20s | %-32.32s |", h_admin, h_rate, h_updaterate, h_cmdrate, h_ip, h_steamid, h_name);
		PrintToConsole(client, "------------------------------------------------------------------------------------------------------");
		
		new String:tmp_admin[2];
		new AdminId:id;
		new String:tmp_steamid[21];
		new String:tmp_update[10],String:tmp_cmd[10],String:tmp_rate[10],String:tmp_name[32];
		new String:tmp_ip[17];

		for (new i=1; i<=MaxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			id = GetUserAdmin(i);
			
			if (id != INVALID_ADMIN_ID)
			{
				Format(tmp_admin, sizeof(tmp_admin), "%s", "A");
			}
			
		
			GetClientAuthString(i, tmp_steamid, 21);		
			GetClientName(i, tmp_name, 35);
			GetClientInfo(i, "cl_updaterate", tmp_update, 9);
			GetClientInfo(i, "cl_cmdrate",tmp_cmd, 9);
			GetClientInfo(i, "rate", tmp_rate, 9);
			GetClientIP(i, tmp_ip, 17);
			
			PrintToConsole(client, "| %1.1s | %-5.5s | %-6.6s | %-3.3s | %-15.15s |%-20.20s | %-32.32s |", tmp_admin, tmp_rate, tmp_update, tmp_cmd, tmp_ip, tmp_steamid, tmp_name);
		
		}
	}
	
	PrintToChat(client, "\x04[SM] See console for output!");
	
	return Plugin_Handled
}

public Action:Command_rates(client,args)
{
	if (args < 1)
	{
		// Header
		decl String:h_name[5];
		decl String:h_rate[5];
		decl String:h_updaterate[11];
		decl String:h_cmdrate[8];
		decl String:h_steamid[21];
		Format(h_name, sizeof(h_name), "%s", "Name");
		Format(h_rate, sizeof(h_rate), "%s", "Rate");
		Format(h_steamid, sizeof(h_steamid), "%s", "Steam ID");
		Format(h_updaterate, sizeof(h_updaterate), "%s", "Update");
		Format(h_cmdrate, sizeof(h_cmdrate), "%s", "CMD");

		PrintToConsole(client, "--------------------------------------------------------------------------------");
		PrintToConsole(client, "|                       Player Information by Jaffa                             |");
		PrintToConsole(client, "--------------------------------------------------------------------------------");
		PrintToConsole(client, "| %-5.5s | %-6.6s | %-3.3s |%-20.20s | %-32.32s |", h_rate, h_updaterate, h_cmdrate, h_steamid, h_name);
		PrintToConsole(client, "--------------------------------------------------------------------------------");
		
		new String:tmp_steamid[21];
		new String:tmp_update[10],String:tmp_cmd[10],String:tmp_rate[10],String:tmp_name[32];

		for (new i=1; i<=MaxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			
		
			GetClientAuthString(i, tmp_steamid, 21);		
			GetClientName(i, tmp_name, 35);
			GetClientInfo(i, "cl_updaterate", tmp_update, 9);
			GetClientInfo(i, "cl_cmdrate",tmp_cmd, 9);
			GetClientInfo(i, "rate", tmp_rate, 9);
			
			PrintToConsole(client, "| %-5.5s | %-6.6s | %-3.3s |%-20.20s | %-32.32s |", tmp_rate, tmp_update, tmp_cmd, tmp_steamid, tmp_name);
		
		}
	}
	
	PrintToChat(client, "\x04[SM] See console for output!");
	
	return Plugin_Handled
}

public Action:Command_rate(client,args)
{
	new String:interp[10],String:update[10],String:cmd[10],String:rate[10]
	
	GetClientInfo(client, "cl_interp", interp, 9)
	GetClientInfo(client, "cl_updaterate", update, 9)
	GetClientInfo(client, "cl_cmdrate",cmd, 9)
	GetClientInfo(client, "rate", rate, 9)
	
	new Float:finterp = StringToFloat(interp)
	new iupdate = StringToInt(update)
	new icmd = StringToInt(cmd)
	new irate = StringToInt(rate)
	
	new Handle:Panel = CreatePanel(GetMenuStyleHandle(MenuStyle_Radio))
	
	new String:targetname[32],String:text[60]
	GetClientName(client,targetname,31)
	DrawPanelText(Panel, "SM Rates by Jaffa");
	
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
	
	Format(text,59,"%t","Exit")
	
	DrawPanelItem(Panel, text)
	
	SendPanelToClient(Panel, client, RateMenu, 20)
	
	CloseHandle(Panel)
}
public RateMenu(Handle:menu, MenuAction:action, param1, param2)
{
	
}


