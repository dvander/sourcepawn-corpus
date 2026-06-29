//##############################################################################
/**
 * =============================================================================
 * Clan Wars Mod 
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *===============================================================================
 * Version: 0.96: cwm.sp , 15.04.2006 4:47                      Ctulchu
 */
 //##############################################################################

#include <sourcemod>
#include <adminmenu>
#include <sdktools>
#include <cstrike>



 
public Plugin:myinfo =
{
	name = "Clan Wars MOD",
	author = "ctulchu",
	description = "Clan War Administration MOD",
	version = "0.96",
	url = "http://"
};
/*****************Global vars ********************************/ 
 
new rr_num = -1
new rr_need = -1
new knifetext = -1
new livetext = -1
new String:b_map_name[32];
/**************************************************************/



/************************ Consol cmd reging ***********************************/ 
public OnPluginStart()
{
															// Command Registering
RegAdminCmd("sm_b_knife", Command_b_knife, ADMFLAG_SLAY, "Start knife round");
RegAdminCmd("sm_b_live", Command_b_live, ADMFLAG_SLAY, "Start live round");
RegAdminCmd("sm_b_tv", Command_b_tv, ADMFLAG_SLAY, "Source TV on");
RegAdminCmd("sm_b_config", Command_b_config, ADMFLAG_SLAY, "Exec cwstandart.cfg");
RegAdminCmd("sm_b_menu", Menu_Test1, ADMFLAG_SLAY, "Admins_menu");
RegAdminCmd("sm_b_swap", c_swap, ADMFLAG_SLAY, "Swap players");
RegAdminCmd("sm_b_ip", c_ip, ADMFLAG_SLAY, "Show players IPs");

RegConsoleCmd("cwmenu", Menu_Test1, "Main Control Menu");
RegConsoleCmd("kickmenu", KickMenu, "Kick control menu");

															//events
HookEvent("round_start", Event_round_start);

}

// ACTIONS ------------------------------------------------------------------------



//##################################################################################################################
//                                  ---------------------------------------------------------SWAP
public Action:c_swap(client, args)
{

new maxPlayers = GetMaxClients()
new playerTeam
PrintToChatAll("[CW MOD] Swapping players....")
    // Loop through all players and see if they are in game and that they are on a team
for (new i=1; i<=maxPlayers; i++)
    {
      if (IsClientInGame (i) ) {
        playerTeam = GetClientTeam(i);
        if (playerTeam == CS_TEAM_T) {
          CS_SwitchTeam(i, CS_TEAM_CT);
        }
        else if (playerTeam == CS_TEAM_CT) {
          CS_SwitchTeam(i, CS_TEAM_T);
        }
      }
    }

ServerCommand("mp_restartgame 1");
return Plugin_Handled;}

//                                  ---------------------------------------------------------SWAP
//##################################################################################################################
//                                  ---------------------------------------------------------Show IPs


public Action:c_ip(client, args)
{

new maxPlayers = GetMaxClients();
new String:ip_addr[32];
new String:cl_name[32];
new i;
PrintToChatAll("[CW MOD] _________________________");
PrintToChatAll("[CW MOD] Requesting Players IPs...");

    // Loop through all players and see if they are in game and that they are on a team
for (i=1; i<=maxPlayers; i++)
    {
   		if (IsClientInGame (i) ) 
    	{
      	GetClientIP(i, ip_addr, sizeof(ip_addr));
      	GetClientName(i, cl_name, sizeof(cl_name));
      	PrintToChatAll("[CW MOD] %s - %s",ip_addr,cl_name);
      	}
      
    }
PrintToChatAll("[CW MOD] Done...");
PrintToChatAll("[CW MOD] _________________________");

return Plugin_Handled;
}

//                                  ---------------------------------------------------------Show ips
//##################################################################################################################
//                                  ---------------------------------------------------------sm_b_config


public Action:Command_b_config(client, args)
{
PrintToChatAll("[CW MOD] ClanWars Mod created by ctulchu|sodb using SourceMOD.");
PrintToChatAll("[CW MOD] Preparing to start config...");
ServerCommand("exec cwmod/cwstandart.cfg");
PrintToChatAll("[CW MOD] Done...");
PrintToChatAll("[CW MOD] Config executed...");
return Plugin_Handled;
}
//                                  ---------------------------------------------------------sm_b_config
//##################################################################################################################
//                                  ---------------------------------------------------------sm_b_knife
public Action:Command_b_knife(client, args)
{
PrintToChatAll("[CW MOD] ClanWars Mod created by ctulchu|sodb using SourceMOD.");
PrintToChatAll("[CW MOD] Preparing to start knife round...");
PrintToChatAll("[CW MOD] Eexecuting Knife config...");
ServerCommand("exec cwmod/cwknife.cfg");
PrintToChatAll("[CW MOD] Eexecuted...");
PrintToChatAll("[CW MOD] Knife after 4 restarts");
rr_need=1;
knifetext =1;
ServerCommand("mp_restartgame 1");
return Plugin_Handled;
}
//                                  ---------------------------------------------------------sm_b_knife
//##################################################################################################################
//                                  ---------------------------------------------------------sm_b_live
public Action:Command_b_live(client, args)
{
PrintToChatAll("[CW MOD] ClanWars Mod created by ctulchu|sodb using SourceMOD.");
PrintToChatAll("[CW MOD] Preparing to start live round...");
PrintToChatAll("[CW MOD] Eexecuting live config...");
ServerCommand("exec cwmod/cwlive.cfg");
PrintToChatAll("[CW MOD] Eexecuted...");
PrintToChatAll("[CW MOD] Live after 4 restarts");
rr_need=1;
livetext =1;
ServerCommand("mp_restartgame 1");
return Plugin_Handled;
}
//                                  ---------------------------------------------------------sm_b_live
//##################################################################################################################
//                                  ---------------------------------------------------------sm_b_tv
public Action:Command_b_tv(client, args)
{
//////////////////////////////////TV
PrintToChatAll("[CW MOD] ClanWars Mod created by ctulchu|sodb using SourceMOD.");
PrintToChatAll("[CW MOD] Preparing to start Source TV...");
PrintToChatAll("[CW MOD] Eexecuting Source TV config...");
ServerCommand("exec cwmod/tv.cfg");
PrintToChatAll("[CW MOD] Eexecuted...");
GetCurrentMap(b_map_name,sizeof(b_map_name))
PrintToChatAll("[CW MOD] Current Map Name: %s , need restart...",b_map_name);
ServerCommand("changelevel %s",b_map_name);
return Plugin_Handled;
}
//                                  ---------------------------------------------------------sm_b_tv
//##################################################################################################################
//                                  ---------------------------------------------------------Restarts...
public Event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{

if(rr_need == 1)
	{
		if(rr_num == -1)
			{
				ServerCommand("mp_restartgame 1");
				rr_num =1;
				PrintToChatAll("[CW MOD] 3 RR for Start [||......]");
				return 1;
			}
		if(rr_num == 1)
			{
				ServerCommand("mp_restartgame 1");
				rr_num = 2;
				PrintToChatAll("[CW MOD] 2 RR for Start [||||....]");
				return 1;
			}
		if(rr_num == 2)
			{
				ServerCommand("mp_restartgame 3");
				rr_num = 3;
				rr_need = 1;
				PrintToChatAll("[CW MOD] 1 RR for Start [||||||..]");
				return 1;
			}
		if(rr_num == 3)
			{
				rr_num = -1;
				rr_need = -1;
				if(knifetext==1){knife_text();}
				if(livetext==1){live_text();}
				return 1;
			}
			
	}


return 1;
}
//                                  ---------------------------------------------------------Restarts...
//##################################################################################################################
//                                  ---------------------------------------------------------Texts
public knife_text()
{
PrintToChatAll("[CW MOD].........Starting [||||||||]");
PrintToChatAll("[CW MOD] Knife - Knife - Knife - Knife");
PrintToChatAll("[CW MOD] Live - Live - Live - Live - L");
PrintToChatAll("[CW MOD] Knife - Knife - Knife - Knife");
PrintToChatAll("[CW MOD] Live - Live - Live - Live - L");
PrintToChatAll("[CW MOD] Live Knife Round");
PrintToChatAll("[CW MOD]  - - - - - - Drop your Weapon");
knifetext =-1;
return 1;
}

public live_text()
{
PrintToChatAll("[CW MOD].........Starting [||||||||]");
PrintToChatAll("[CW MOD] - Live - Live - Live - Live -");
PrintToChatAll("[CW MOD] Live - Live - Live - Live - L");
PrintToChatAll("[CW MOD] - Live - Live - Live - Live -");
PrintToChatAll("[CW MOD] Live - Live - Live - Live - L");
PrintToChatAll("[CW MOD] Live Round - - - - - - - - - ");
PrintToChatAll("[CW MOD]  - - GooD Luck & Have Fun - -");
livetext =-1;
return 1;
}


//                                  ---------------------------------------------------------Texts
//##################################################################################################################
//                                  ---------------------------------------------------------Menus

public MenuHandler1(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[32]
		//new bool:found = 
		GetMenuItem(menu, param2, info, sizeof(info))
//	 PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info)
		//new client;
		if(param2==0){ServerCommand("sm_b_knife");}
		if(param2==1){ServerCommand("sm_b_live");}
		if(param2==2){ServerCommand("sm_b_config");}
		if(param2==3){ServerCommand("sm_b_tv");}
		if(param2==4){Command_b_config(0,0);Command_b_knife(0,0);}
		if(param2==5){c_swap(0,0);}
		if(param2==6){c_ip(0,0);}
		if(param2==7){
					new clid;
					StringToIntEx(info,clid,10);
					KickMenu(clid,0);
					
				}
		if(param2==8){ServerCommand("sv_password ' '");PrintToChatAll("[CW MOD] sv_password cleared");}
	
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		//PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2)
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}
 
 
public Action:Menu_Test1(client, args)
{
	new String:cl_in[32];
	IntToString(client, cl_in, sizeof(cl_in));
	
	new Handle:menu = CreateMenu(MenuHandler1)
	SetMenuTitle(menu, "Clan Wars MOD")
	AddMenuItem(menu, "knf", "Start Knife Round")
	AddMenuItem(menu, "liv", "Start Live Round")
	AddMenuItem(menu, "cfg", "Execute Config")
	AddMenuItem(menu, "bcw", "Start Source TV(autorec.)")
	AddMenuItem(menu, "scw", "Start Clan War (cfg & knife)")
	AddMenuItem(menu, "swp", "Swap")
	AddMenuItem(menu, "ips", "Show Players IP")
	AddMenuItem(menu, cl_in, "Player Kick Menu")
	AddMenuItem(menu, "clp", "Clear sv_password")
	
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
 
	return Plugin_Handled
}

//##################################################################################################################
//#################################Kick Menu########################################################################
public Action:KickMenu(client, args)
{
new Handle:menu = CreateMenu(MenuHandler_Kick);
new maxPlayers = GetMaxClients();
new String:i_str[32];
new String:cl_name[32];
//decl String:title[100];

	// Format(title, sizeof(title), "%T:", "Kick player", client);
SetMenuTitle(menu, "Kick Player");
SetMenuExitButton(menu, true);
	// AddTargetsToMenu(menu, client, false, false);
	
for (new i=1; i<=maxPlayers; i++)
    {
   		if (IsClientInGame (i) ) 
    	{
      	GetClientName(i, cl_name, sizeof(cl_name));
      	IntToString(i,i_str,sizeof(i_str));
      	AddMenuItem(menu,i_str,cl_name);
      	}
      
    }
	
DisplayMenu(menu, client, MENU_TIME_FOREVER);
return Plugin_Handled;
}

public MenuHandler_Kick(Handle:menu, MenuAction:action, param1, param2)
{

if (action == MenuAction_Select)
	{

	new String:info[32]
	//new bool:found = 
	GetMenuItem(menu, param2, info, sizeof(info))
	new integer:i_int;
//	PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info)
	new String:cl_name[32];
	new String:ip_addr[32];
	StringToIntEx(info,i_int,10);
	
	 
	GetClientName(i_int, cl_name, sizeof(cl_name));
	GetClientIP(i_int, ip_addr, sizeof(ip_addr));
	PrintToChatAll("[CW MOD] Kicking - '%s', ID-'%s', IP-'%s'",cl_name, info, ip_addr);
	
	KickClient(i_int, "Kicked by CW MOD...");
	return 1;
}
return 1;
}

//##################################################################################################################
//##################################################################################################################
// END