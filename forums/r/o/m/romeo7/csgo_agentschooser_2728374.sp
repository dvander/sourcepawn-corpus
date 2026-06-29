/*  SM Franug CS:GO Agents Chooser
 *
 *  Copyright (C) 2020 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <clientprefs>

#define HIDE_CROSSHAIR_CSGO 1<<8
#define HIDE_RADAR_CSGO 1<<12

Handle g_hTimer[MAXPLAYERS+1];

// Valve Agents list by category and team
char CTDistinguished[][][] =
{
	{"Seal Team 6 Soldier | NSWC SEAL",						"models/player/custom_player/legacy/ctm_st6_variante.mdl"},
	{"3rd Commando Company | KSK",							"models/player/custom_player/legacy/ctm_st6_variantk.mdl"},
	{"Operator | FBI SWAT",									"models/player/custom_player/legacy/ctm_fbi_variantf.mdl"},
	{"B Squadron Officer | SAS",							"models/player/custom_player/legacy/ctm_sas_variantf.mdl"},
	{"Chem-Haz Specialist | SWAT",							"models/player/custom_player/legacy/ctm_swat_variantj.mdl"},
	{"Bio-Haz Specialist | SWAT",							"models/player/custom_player/legacy/ctm_swat_varianth.mdl"},
}

char TDistinguished[][][] =
{
	{"Enforcer | Phoenix",									"models/player/custom_player/legacy/tm_phoenix_variantf.mdl"},
	{"Soldier | Phoenix",									"models/player/custom_player/legacy/tm_phoenix_varianth.mdl"},
	{"Ground Rebel  | Elite Crew",							"models/player/custom_player/legacy/tm_leet_variantg.mdl"},
	{"Street Soldier | Phoenix",							"models/player/custom_player/legacy/tm_phoenix_varianti.mdl"},
	{"Dragomir | Sabre Footsoldier",						"models/player/custom_player/legacy/tm_balkan_variantl.mdl"},
}

char CTExceptional[][][] =
{
	{"Markus Delrow | FBI",									"models/player/custom_player/legacy/ctm_fbi_variantg.mdl"},
	{"Buckshot | NSWC SEAL",								"models/player/custom_player/legacy/ctm_st6_variantg.mdl"},
	{"John 'Van Healen' Kask | SWAT",						"models/player/custom_player/legacy/ctm_swat_variantg.mdl"},
	{"Sergeant Bombson | SWAT",								"models/player/custom_player/legacy/ctm_swat_varianti.mdl"},
	{"'Blueberries' Buckshot | NSWC SEAL",					"models/player/custom_player/legacy/ctm_st6_variantj.mdl"},
}

char TExceptional[][][] =
{
	{"Maximus | Sabre",										"models/player/custom_player/legacy/tm_balkan_varianti.mdl"},
	{"Osiris | Elite Crew",									"models/player/custom_player/legacy/tm_leet_varianth.mdl"},
	{"Slingshot | Phoenix",									"models/player/custom_player/legacy/tm_phoenix_variantg.mdl"},
	{"Dragomir | Sabre",									"models/player/custom_player/legacy/tm_balkan_variantf.mdl"},
	{"Getaway Sally | The Professionals",					"models/player/custom_player/legacy/tm_professional_varj.mdl"},
	{"Little Kev | The Professionals",						"models/player/custom_player/legacy/tm_professional_varh.mdl"},
}

char CTSuperior[][][] =
{
	{"Michael Syfers | FBI Sniper",							"models/player/custom_player/legacy/ctm_fbi_varianth.mdl"},
	{"'Two Times' McCoy | USAF TACP",						"models/player/custom_player/legacy/ctm_st6_variantm.mdl"},
	{"1st Lieutenant Farlow | SWAT",						"models/player/custom_player/legacy/ctm_swat_variantf.mdl"},
	{"'Two Times' McCoy | TACP Cavalry",					"models/player/custom_player/legacy/ctm_st6_variantl.mdl"},
}

char TSuperior[][][] =
{
	{"Blackwolf | Sabre",									"models/player/custom_player/legacy/tm_balkan_variantj.mdl"},
	{"Prof. Shahmat | Elite Crew",							"models/player/custom_player/legacy/tm_leet_varianti.mdl"},
	{"Rezan The Ready | Sabre",								"models/player/custom_player/legacy/tm_balkan_variantg.mdl"},
	{"Number K | The Professionals",						"models/player/custom_player/legacy/tm_professional_vari.mdl"},
	{"Safecracker Voltzmann | The Professionals",			"models/player/custom_player/legacy/tm_professional_varg.mdl"},
	{"Rezan the Redshirt | Sabre",							"models/player/custom_player/legacy/tm_balkan_variantk.mdl"},
}

char CTMaster[][][] =
{
	{"Lt. Commander Ricksaw | NSWC SEAL",					"models/player/custom_player/legacy/ctm_st6_varianti.mdl"},
	{"Special Agent Ava | FBI",								"models/player/custom_player/legacy/ctm_fbi_variantb.mdl"},
	{"Cmdr. Mae 'Dead Cold' Jamison | SWAT",				"models/player/custom_player/legacy/ctm_swat_variante.mdl"},
}

char TMaster[][][] =
{
	{"'The Doctor' Romanov | Sabre",						"models/player/custom_player/legacy/tm_balkan_varianth.mdl"},
	{"The Elite Mr. Muhlik | Elite Crew",					"models/player/custom_player/legacy/tm_leet_variantf.mdl"},
	{"Sir Bloody Miami Darryl | The Professionals",			"models/player/custom_player/legacy/tm_professional_varf.mdl"},
	{"Sir Bloody Silent Darryl | The Professionals",		"models/player/custom_player/legacy/tm_professional_varf1.mdl"},
	{"Sir Bloody Skullhead Darryl | The Professionals",		"models/player/custom_player/legacy/tm_professional_varf2.mdl"},
	{"Sir Bloody Darryl Royale | The Professionals",		"models/player/custom_player/legacy/tm_professional_varf3.mdl"},
	{"Sir Bloody Loudmouth Darryl | The Professionals",		"models/player/custom_player/legacy/tm_professional_varf4.mdl"},
}

#define DATA "1.1.4"

public Plugin myinfo =
{
	name = "SM Franug CS:GO Agents Chooser",
	author = "Franc1sco franug & Romeo",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
}

int g_iTeam[MAXPLAYERS + 1], g_iCategory[MAXPLAYERS + 1];
char g_ctAgent[MAXPLAYERS + 1][128], g_tAgent[MAXPLAYERS + 1][128];

Handle c_CTAgent, c_TAgent;

ConVar cv_timer, cv_noOverwritte, cv_instant, cv_autoopen, cv_PreviewDuration;

bool _checkedMsg[MAXPLAYERS + 1];

public void OnPluginStart()
{
	RegConsoleCmd("sm_agents", Command_Main);
	
	RegAdminCmd("sm_agents_generatemodels", Command_GenerateModelsForSkinchooser, ADMFLAG_ROOT);
	RegAdminCmd("sm_agents_generatestoremodels", Command_GenerateModelsForStore, ADMFLAG_ROOT);
	
	c_CTAgent = RegClientCookie("CTAgent_b", "", CookieAccess_Private);
	c_TAgent = RegClientCookie("TAgent_b", "", CookieAccess_Private);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	cv_autoopen = CreateConVar("sm_csgoagents_autoopen", "0", "Enable or disable auto open menu when you connect and you didnt select a agent yet");
	cv_instant = CreateConVar("sm_csgoagents_instantly", "1", "Enable or disable apply agents skins instantly");
	cv_timer = CreateConVar("sm_csgoagents_timer", "0.2", "Time on Spawn for apply agent skins");
	cv_noOverwritte = CreateConVar("sm_csgoagents_nooverwrittecustom", "1", "No apply agent model if the user already have a custom model. 1 = no apply when custom model, 0 = disable this feature");
	cv_PreviewDuration = CreateConVar("sm_csgoagents_previewduration", "3.0", "Preview duration when choosing an agent. Disable: 0");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
	
	AutoExecConfig(true, "csgo_agentschooser");
}

// I generate these files automatically with code instead of do it manually like a good programmer :p
public Action Command_GenerateModelsForSkinchooser(client, args)
{
	Handle kv = CreateKeyValues("Models");
	
	KvJumpToKey(kv, "CSGO Agents", true);
	KvJumpToKey(kv, "Team1", true);
	
	for (int i = 0; i < sizeof(TDistinguished); i++)
	{
		KvJumpToKey(kv, TDistinguished[i][0], true);
		KvSetString(kv, "path", TDistinguished[i][1]);
		KvGoBack(kv);
	}
	for (int i = 0; i < sizeof(TExceptional); i++)
	{
		KvJumpToKey(kv, TExceptional[i][0], true);
		KvSetString(kv, "path", TExceptional[i][1]);
		KvGoBack(kv);
	}
	for (int i = 0; i < sizeof(TSuperior); i++)
	{
		KvJumpToKey(kv, TSuperior[i][0], true);
		KvSetString(kv, "path", TSuperior[i][1]);
		KvGoBack(kv);
	}
	for (int i = 0; i < sizeof(TMaster); i++)
	{
		KvJumpToKey(kv, TMaster[i][0], true);
		KvSetString(kv, "path", TMaster[i][1]);
		KvGoBack(kv);
	}
	
	KvGoBack(kv);
	KvJumpToKey(kv, "Team2", true);
	
	for (int i = 0; i < sizeof(CTDistinguished); i++)
	{
		KvJumpToKey(kv, CTDistinguished[i][0], true);
		KvSetString(kv, "path", CTDistinguished[i][1]);
		KvGoBack(kv);
	}
	for (int i = 0; i < sizeof(CTExceptional); i++)
	{
		KvJumpToKey(kv, CTExceptional[i][0], true);
		KvSetString(kv, "path", CTExceptional[i][1]);
		KvGoBack(kv);
	}
	for (int i = 0; i < sizeof(CTSuperior); i++)
	{
		KvJumpToKey(kv, CTSuperior[i][0], true);
		KvSetString(kv, "path", CTSuperior[i][1]);
		KvGoBack(kv);
	}
	for (int i = 0; i < sizeof(CTMaster); i++)
	{
		KvJumpToKey(kv, CTMaster[i][0], true);
		KvSetString(kv, "path", CTMaster[i][1]);
		KvGoBack(kv);
	}
	KvRewind(kv);
	KeyValuesToFile(kv, "addons/sourcemod/configs/sm_skinchooser_withagents.cfg");
	delete kv;
	
	ReplyToCommand(client, "CFG file generated for models");
	
	return Plugin_Handled;
}

public Action Command_GenerateModelsForStore(client, args)
{
	char price[32] = "3000"; // default price
	Handle kv = CreateKeyValues("Store");
	
	KvJumpToKey(kv, "CSGO Agents", true);
	KvJumpToKey(kv, "Terrorist", true);
	
	for (int i = 0; i < sizeof(TDistinguished); i++)
	{
		KvJumpToKey(kv, TDistinguished[i][0], true);
		KvSetString(kv, "model", TDistinguished[i][1]);
		KvSetString(kv, "team", "2");
		KvSetString(kv, "price", price);
		KvSetString(kv, "type", "playerskin");
		KvGoBack(kv);
	}
	for (int i = 0; i < sizeof(TExceptional); i++)
	{
		KvJumpToKey(kv, TExceptional[i][0], true);
		KvSetString(kv, "model", TExceptional[i][1]);
		KvSetString(kv, "team", "2");
		KvSetString(kv, "price", price);
		KvSetString(kv, "type", "playerskin");
		KvGoBack(kv);
	}
	for (int i = 0; i < sizeof(TSuperior); i++)
	{
		KvJumpToKey(kv, TSuperior[i][0], true);
		KvSetString(kv, "model", TSuperior[i][1]);
		KvSetString(kv, "team", "2");
		KvSetString(kv, "price", price);
		KvSetString(kv, "type", "playerskin");
		KvGoBack(kv);
	}
	for (int i = 0; i < sizeof(TMaster); i++)
	{
		KvJumpToKey(kv, TMaster[i][0], true);
		KvSetString(kv, "model", TMaster[i][1]);
		KvSetString(kv, "team", "2");
		KvSetString(kv, "price", price);
		KvSetString(kv, "type", "playerskin");
		KvGoBack(kv);
	}
	
	KvGoBack(kv);
	KvJumpToKey(kv, "Counter-Terrorist", true);
	
	for (int i = 0; i < sizeof(CTDistinguished); i++)
	{
		KvJumpToKey(kv, CTDistinguished[i][0], true);
		KvSetString(kv, "model", CTDistinguished[i][1]);
		KvSetString(kv, "team", "3");
		KvSetString(kv, "price", price);
		KvSetString(kv, "type", "playerskin");
		KvGoBack(kv);
	}
	for (int i = 0; i < sizeof(CTExceptional); i++)
	{
		KvJumpToKey(kv, CTExceptional[i][0], true);
		KvSetString(kv, "model", CTExceptional[i][1]);
		KvSetString(kv, "team", "3");
		KvSetString(kv, "price", price); 
		KvSetString(kv, "type", "playerskin");
		KvGoBack(kv);
	}
	for (int i = 0; i < sizeof(CTSuperior); i++)
	{
		KvJumpToKey(kv, CTSuperior[i][0], true);
		KvSetString(kv, "model", CTSuperior[i][1]);
		KvSetString(kv, "team", "3");
		KvSetString(kv, "price", price);
		KvSetString(kv, "type", "playerskin");
		KvGoBack(kv);
	}
	for (int i = 0; i < sizeof(CTMaster); i++)
	{
		KvJumpToKey(kv, CTMaster[i][0], true);
		KvSetString(kv, "model", CTMaster[i][1]);
		KvSetString(kv, "team", "3");
		KvSetString(kv, "price", price);
		KvSetString(kv, "type", "playerskin");
		KvGoBack(kv);
	}
	KvRewind(kv);
	KeyValuesToFile(kv, "addons/sourcemod/configs/storeitems_withagents.txt");
	delete kv;
	
	ReplyToCommand(client, "CFG file generated for models");
	
	return Plugin_Handled;
}

public void OnClientCookiesCached(int client)
{
	GetClientCookie(client, c_CTAgent, g_ctAgent[client], 128);
	GetClientCookie(client, c_TAgent, g_tAgent[client], 128);
	
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
}

public void OnClientDisconnect(int client)
{
	if(!IsFakeClient(client) && AreClientCookiesCached(client))
	{
		SetClientCookie(client, c_TAgent, g_tAgent[client]);
		SetClientCookie(client, c_CTAgent, g_ctAgent[client]);
	}
	
	strcopy(g_ctAgent[client], 128, "");
	strcopy(g_tAgent[client], 128, "");
	_checkedMsg[client] = false;
	
	if(g_hTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTimer[client]);
		g_hTimer[client] = INVALID_HANDLE;
	}
	
	SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
}

public Action Command_Main(client, args)
{
	Menu menu = new Menu(SelectTeam, MenuAction_Select  | MenuAction_End);
	
	SetMenuTitle(menu, "Choose Agents Team:");
	
	AddMenuItem(menu, "", "Counter-Terrorist team");
	AddMenuItem(menu, "", "Terrorist team");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int SelectTeam(Menu menu, MenuAction action, int param1, int param2) 
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch(param2)
			{
				case 0:{
					g_iTeam[param1] = CS_TEAM_CT;
				}
				case 1:{
					g_iTeam[param1] = CS_TEAM_T;
				}
			}
			OpenAgentsMenu(param1);
		}

		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

void OpenAgentsMenu(int client)
{
	Menu menu = new Menu(SelectType, MenuAction_Select  | MenuAction_End);

	SetMenuTitle(menu, "Choose Agents type:");
	
	AddMenuItem(menu, "", "Use Default skins");
	
	AddMenuItem(menu, "", "Distinguished Agents");
	
	AddMenuItem(menu, "", "Exceptional Agents");
	
	AddMenuItem(menu, "", "Superior Agents");
	
	AddMenuItem(menu, "", "Master Agents");
	//SetMenuPagination(menu, MENU_NO_PAGINATION);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int SelectType(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch(param2)
			{
				case 0:{
					
					if(IsPlayerAlive(param1))CS_UpdateClientModel(param1);
					
					strcopy(g_ctAgent[param1], 128, "");
					strcopy(g_tAgent[param1], 128, "");
					PrintToChat(param1, "You dont use a agent model now");
					
					OpenAgentsMenu(param1);
				}
				case 1:{
					DisMenu(param1, 0);
				}
				case 2:{
					ExMenu(param1, 0);
				}
				case 3:{
					SuMenu(param1, 0);
				}
				case 4:{
					MaMenu(param1, 0);
				}
			}
			g_iCategory[param1] = param2;
		}
		
		case MenuAction_Cancel, MenuCancel_ExitBack:
 		{
 			Command_Main(param1, 0);
 		}

		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

void DisMenu(int client, int num)
{
	new Handle:menu = CreateMenu(AgentChoosed, MenuAction_Select  | MenuAction_End);
	SetMenuTitle(menu, "Distinguished Agents");
	if(g_iTeam[client] == CS_TEAM_CT){
		
		for (int i = 0; i < sizeof(CTDistinguished); i++)
			AddMenuItem(menu, CTDistinguished[i][1], CTDistinguished[i][0], 
			StrEqual(g_ctAgent[client], CTDistinguished[i][1])?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			
	}
	else{
		
		for (int i = 0; i < sizeof(TDistinguished); i++)
			AddMenuItem(menu, TDistinguished[i][1], TDistinguished[i][0], 
			StrEqual(g_tAgent[client], TDistinguished[i][1])?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenuAtItem(menu, client, num, MENU_TIME_FOREVER);
}

void ExMenu(int client, int num)
{
	new Handle:menu = CreateMenu(AgentChoosed, MenuAction_Select  | MenuAction_End);
	SetMenuTitle(menu, "Exceptional Agents");
	if(g_iTeam[client] == CS_TEAM_CT){
		
		for (int i = 0; i < sizeof(CTExceptional); i++)
			AddMenuItem(menu, CTExceptional[i][1], CTExceptional[i][0], 
			StrEqual(g_ctAgent[client], CTExceptional[i][1])?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			
	}
	else{
		
		for (int i = 0; i < sizeof(TExceptional); i++)
			AddMenuItem(menu, TExceptional[i][1], TExceptional[i][0], 
			StrEqual(g_tAgent[client], TExceptional[i][1])?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenuAtItem(menu, client, num, MENU_TIME_FOREVER);
}

void SuMenu(int client, int num)
{
	new Handle:menu = CreateMenu(AgentChoosed, MenuAction_Select  | MenuAction_End);
	SetMenuTitle(menu, "Superior Agents");
	if(g_iTeam[client] == CS_TEAM_CT){
		
		for (int i = 0; i < sizeof(CTSuperior); i++)
			AddMenuItem(menu, CTSuperior[i][1], CTSuperior[i][0], 
			StrEqual(g_ctAgent[client], CTSuperior[i][1])?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			
	}
	else{
		
		for (int i = 0; i < sizeof(TSuperior); i++)
			AddMenuItem(menu, TSuperior[i][1], TSuperior[i][0], 
			StrEqual(g_tAgent[client], TSuperior[i][1])?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenuAtItem(menu, client, num, MENU_TIME_FOREVER);
}

void MaMenu(int client, int num)
{
	new Handle:menu = CreateMenu(AgentChoosed, MenuAction_Select  | MenuAction_End);
	SetMenuTitle(menu, "Master Agents");
	if(g_iTeam[client] == CS_TEAM_CT){
		
		for (int i = 0; i < sizeof(CTMaster); i++)
			AddMenuItem(menu, CTMaster[i][1], CTMaster[i][0], 
			StrEqual(g_ctAgent[client], CTMaster[i][1])?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			
	}
	else{
		
		for (int i = 0; i < sizeof(TMaster); i++)
			AddMenuItem(menu, TMaster[i][1], TMaster[i][0], 
			StrEqual(g_tAgent[client], TMaster[i][1])?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenuAtItem(menu, client, num, MENU_TIME_FOREVER);
}

public int AgentChoosed(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char model[128];
			GetMenuItem(menu, param2, model, sizeof(model));
			
			if(g_iTeam[param1] == CS_TEAM_CT)
			{
				strcopy(g_ctAgent[param1], 128, model);
			}
			else
			{
				strcopy(g_tAgent[param1], 128, model);
			}
				
			if(cv_instant.BoolValue)
				PrintToChat(param1, "Agent model choosed!");
			else
				PrintToChat(param1, "Agent model choosed! you will have it in the next spawn");
			
			switch(g_iCategory[param1])
			{
				case 1:
				{
					DisMenu(param1, GetMenuSelectionPosition());
				}
				case 2:
				{
					ExMenu(param1, GetMenuSelectionPosition());
				}
				case 3:
				{
					SuMenu(param1, GetMenuSelectionPosition());
				}
				case 4:
				{
					MaMenu(param1, GetMenuSelectionPosition());
				}
			}
			
			if(cv_instant.BoolValue && IsPlayerAlive(param1) && GetClientTeam(param1) == g_iTeam[param1])
			{
				if(cv_noOverwritte.BoolValue)
				{
					char dmodel[128];
					GetClientModel(param1, dmodel, sizeof(dmodel));
					if(StrContains(dmodel, "models/player/custom_player/legacy/") == -1)
					{
						PrintToChat(param1, "You already have a custom player skin, remove your custom player skin for use a agent");
						return;
					}
				}
				
				SetEntityModel(param1, model);
				
				if(cv_PreviewDuration.BoolValue)
				{
					SetThirdPersonMode(param1, true);
					
					if(g_hTimer[param1] != INVALID_HANDLE)
					{
						KillTimer(g_hTimer[param1]);
						g_hTimer[param1] = INVALID_HANDLE;
					}
					
					g_hTimer[param1] = CreateTimer(cv_PreviewDuration.FloatValue, Timer_SetBackMode, param1, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		case MenuAction_Cancel, MenuCancel_ExitBack:
 		{
 			OpenAgentsMenu(param1);
 		}

		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public Action Event_PlayerSpawn(Event event, const char[] sName, bool bDontBroadcast)
{
	CreateTimer(cv_timer.FloatValue, Timer_ApplySkin, event.GetInt("userid"));
}

public Action Timer_ApplySkin(Handle timer, int id)
{
	int client = GetClientOfUserId(id);
	
	if (!client || !IsClientInGame(client) || !IsPlayerAlive(client) || !AreClientCookiesCached(client))return;
	
	int team = GetClientTeam(client);
	char model[255];
	
	if(team == CS_TEAM_CT)
		strcopy(model, sizeof(model), g_ctAgent[client]);
	else if(team == CS_TEAM_T)
		strcopy(model, sizeof(model), g_tAgent[client]);
		
	if (strlen(model) < 1)
	{
		if(cv_autoopen.BoolValue && !_checkedMsg[client])
		{
			_checkedMsg[client] = true;
			Command_Main(client, 0);
		}
		return;
	}
	
	if(!IsModelPrecached(model)) // sqlite corrupted? we restore it
	{
		strcopy(g_ctAgent[client], 128, "");
		strcopy(g_tAgent[client], 128, "");
		return;
	}
	
	if(cv_noOverwritte.BoolValue)
	{
		char dmodel[128];
		GetClientModel(client, dmodel, sizeof(dmodel));
		if(StrContains(dmodel, "models/player/custom_player/legacy/") == -1)
		{
			PrintToChat(client, "You already have a custom player skin, remove your custom player skin for use a agent");
			return;
		}
	}
	SetEntityModel(client, model);
}

public Action Timer_SetBackMode(Handle hTimer, any client)
{
	SetThirdPersonMode(client, false);
	g_hTimer[client] = INVALID_HANDLE;
}

SetThirdPersonMode(int client, bool bEnable)
{
	Handle mp_forcecamera;
	if(!mp_forcecamera)
	{
		mp_forcecamera = FindConVar("mp_forcecamera");
	}
	
	if(bEnable)
	{
		
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0); 
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		SetEntProp(client, Prop_Send, "m_iFOV", 120);
		SendConVarValue(client, mp_forcecamera, "1");
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR_CSGO);
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_CROSSHAIR_CSGO);
	}
	else
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
		char sValue[4];
		GetConVarString(mp_forcecamera, sValue, sizeof(sValue));
		SendConVarValue(client, mp_forcecamera, sValue);
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") & ~HIDE_RADAR_CSGO);
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") & ~HIDE_CROSSHAIR_CSGO);
	}
}

public Action Hook_SetTransmit(int client, int agent)
{
	if(IsPlayerAlive(client) && 1 <= agent <= MaxClients && IsClientInGame(agent) && g_hTimer[agent] != INVALID_HANDLE)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock bool isAgentSelected(int client)
{
	if(strlen(g_tAgent[client]) < 1 && strlen(g_ctAgent[client]) < 1)
		return true;
		
	return false;
}