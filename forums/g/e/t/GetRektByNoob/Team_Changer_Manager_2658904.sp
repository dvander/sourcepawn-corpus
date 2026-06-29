#pragma semicolon 1

#define DEBUG

#define PREFIX " \x0C[TJM]\x01"
#define PLUGIN_AUTHOR "GetRektByNoob"
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

ConVar gC_Cooldown;

ConVar gC_T_Message;
ConVar gC_CT_Message;
ConVar gC_S_Message;

ConVar gC_T_Disable;
ConVar gC_CT_Disable;
ConVar gC_S_Disable;
int g_iCanChangeTeams[MAXPLAYERS + 1] = {-1, ...};

public Plugin myinfo = 
{
	name = "Join Team Manager", 
	author = PLUGIN_AUTHOR, 
	description = "Adds a cooldown between switching teams", 
	version = PLUGIN_VERSION, 
	url = "https://steamcommunity.com/profiles/76561198805764302/"
};

public void OnPluginStart() {
	gC_T_Disable = CreateConVar("tjm_t_disable", "0", "[0] Allow players to join the CT team \n[1] Don't allow players to join the CT team", FCVAR_NONE, true, 0.0, true, 1.0);
	gC_CT_Disable = CreateConVar("tjm_ct_disable", "0", "[0] Allow players to join the T team \n[1] Don't allow players to join the T team", FCVAR_NONE, true, 0.0, true, 1.0);
	gC_S_Disable = CreateConVar("tjm_spec_disable", "0", "[0] Allow players to join the SPEC team \n[1] Don't allow players to join the SPEC team", FCVAR_NONE, true, 0.0, true, 1.0);
	
	gC_T_Message = CreateConVar("tjm_t_message", "1", "[0] Don't show the T join message \n[1] Show the T join message", FCVAR_NONE, true, 0.0, true, 1.0);
	gC_CT_Message = CreateConVar("tjm_ct_message", "1", "[0] Don't show the CT join message \n[1] Show the CT join message", FCVAR_NONE, true, 0.0, true, 1.0);
	gC_S_Message = CreateConVar("tjm_spec_message", "1", "[0] Don't show the SPEC join message \n[1] Show the SPEC join message", FCVAR_NONE, true, 0.0, true, 1.0);

	gC_Cooldown = CreateConVar("tjm_cooldown", "5", "The time [In Seconds] you have to wait until you can switch teams again \nSetting this to [-1] will disable the team changing permenatly.", FCVAR_NONE, true, -1.0, true, 60.0);
	
	RegAdminCmd("sm_tjm", Command_ShowConvars, ADMFLAG_CONVARS, "Show menu of all of the Convars and values");
	HookEvent("player_team", TeamChanging, EventHookMode_Pre);
	AddCommandListener(CommandList_ChangeTeam, "jointeam");

	AutoExecConfig(true, "Team Join Manager");
}

public void OnClientConnected(int client) {
	g_iCanChangeTeams[client] = -1;
}

//////////////////
// *** MENU *** //
//////////////////

public Action Command_ShowConvars(int client, int args)
{
	Menu menu = new Menu(menuHandle);
	char Item[32];

	Format(Item, sizeof(Item), "tjm_t_disable » %s", gC_T_Disable.BoolValue ? "ON" : "OFF");
	menu.AddItem("",Item, ITEMDRAW_DISABLED);

	Format(Item, sizeof(Item), "tjm_ct_disable » %s", gC_CT_Disable.BoolValue ? "ON" : "OFF");
	menu.AddItem("",Item, ITEMDRAW_DISABLED);

	Format(Item, sizeof(Item), "tjm_spec_disable » %s", gC_S_Disable.BoolValue ? "ON" : "OFF");
	menu.AddItem("",Item, ITEMDRAW_DISABLED);

	Format(Item, sizeof(Item), "tjm_t_message » %s", gC_T_Message.BoolValue ? "ON" : "OFF");
	menu.AddItem("",Item, ITEMDRAW_DISABLED);

	Format(Item, sizeof(Item), "tjm_ct_message » %s", gC_CT_Message.BoolValue ? "ON" : "OFF");
	menu.AddItem("",Item, ITEMDRAW_DISABLED);

	Format(Item, sizeof(Item), "tjm_spec_message » %s", gC_S_Message.BoolValue ? "ON" : "OFF");
	menu.AddItem("",Item, ITEMDRAW_DISABLED);
	
	Format(Item, sizeof(Item), "tjm_cooldown » %d", gC_Cooldown.IntValue);
	menu.AddItem("",Item, ITEMDRAW_DISABLED);

	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

int menuHandle(Menu menu, MenuAction action, int param1, int param2) {
	if(action == MenuAction_End) {
		delete menu;
	}
}

////////////////////
// *** Events *** //
////////////////////

Action CommandList_ChangeTeam(int client, const char[] command, int argc) {
	int iNow = GetTime(), NewTeam;
	char arg[5];
	
	GetCmdArg(1, arg, sizeof(arg));
	NewTeam = StringToInt(arg);
	
	if(GetClientTeam(client) == 0) { // if player not in team
		return Plugin_Continue;
	}

	else if(gC_T_Disable.BoolValue && NewTeam == CS_TEAM_T) { // if t is disabled
		PrintToChat(client, "%s You can not join the\x07 Terrorists\x01 team on this server.", PREFIX);
		return Plugin_Handled;
	}

	else if(gC_CT_Disable.BoolValue && NewTeam == CS_TEAM_CT) { // if ct is disabled
		PrintToChat(client, "%s You can not join the\x07 Counter-Terrorists\x01 team on this server.", PREFIX);
		return Plugin_Handled;
	}

	else if(gC_S_Disable.BoolValue && NewTeam == CS_TEAM_SPECTATOR) { // if spec is disabled
		PrintToChat(client, "%s You can not join the\x07 Spectators\x01 team on this server.", PREFIX);
		return Plugin_Handled;
	}

	else if(gC_Cooldown.IntValue == -1) {  // switch disabled
		PrintToChat(client, "%s You \x07can not \x01switch teams on this server.", PREFIX);
		return Plugin_Handled;
	}
	
	else if (g_iCanChangeTeams[client] <= iNow) { // can switch
		g_iCanChangeTeams[client] = iNow + gC_Cooldown.IntValue;
		return Plugin_Continue;
	} 

	else { // on cooldown
		int iWaitTime = g_iCanChangeTeams[client] - iNow;
		PrintToChat(client, "%s You have to wait \x07%d Seconds \x01before switching teams again.", PREFIX, iWaitTime);
		return Plugin_Handled;
	}
}

Action TeamChanging(Event event, const char[] name, bool dontBroadcast) {
	int TeamID = event.GetInt("team");

	switch(TeamID) {
		case CS_TEAM_T: {
			if(!gC_T_Message.BoolValue) {
				event.SetBool("silent", true);
			} 
		}

		case CS_TEAM_CT: {
			if(!gC_CT_Message.BoolValue) {
				event.SetBool("silent", true);
			}
		}

		case CS_TEAM_SPECTATOR: {
			if(!gC_S_Message.BoolValue) {
				event.SetBool("silent", true);
			}
		}
	}
	
	return Plugin_Continue;
}

public void OnClientPutInServer(int client) 
{ 
     SetEntPropFloat(client, Prop_Send, "m_fForceTeam", 3600.0); 
}  