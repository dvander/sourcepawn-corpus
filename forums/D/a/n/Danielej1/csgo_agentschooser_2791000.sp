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

#include	<sdktools>
#include	<sdkhooks>
#include	<cstrike>
#include	<clientprefs>

#pragma		semicolon	1
#pragma		newdecls	required

#define		HIDE_CROSSHAIR_CSGO	1<<8
#define		HIDE_RADAR_CSGO		1<<12

Handle	g_hTimer[MAXPLAYERS+1] = null;

// Valve Agents list by category and team
char CTDistinguished[][][] =
{
	{"Primeiro Tenente | Brazilian 1st Battalion",			"models/player/custom_player/legacy/ctm_st6_variantn.mdl"},
	{"D Squadron Officer | NZSAS",							"models/player/custom_player/legacy/ctm_sas_variantg.mdl"},
	{"Aspirant | Gendarmerie Nationale",					"models/player/custom_player/legacy/ctm_gendarmerie_variantd.mdl"},
	{"Seal Team 6 Soldier | NSWC SEAL",						"models/player/custom_player/legacy/ctm_st6_variante.mdl"},
	{"3rd Commando Company | KSK",							"models/player/custom_player/legacy/ctm_st6_variantk.mdl"},
	{"Operator | FBI SWAT",									"models/player/custom_player/legacy/ctm_fbi_variantf.mdl"},
	{"B Squadron Officer | SAS",							"models/player/custom_player/legacy/ctm_sas_variantf.mdl"},
	{"Chem-Haz Specialist | SWAT",							"models/player/custom_player/legacy/ctm_swat_variantj.mdl"},
	{"Bio-Haz Specialist | SWAT",							"models/player/custom_player/legacy/ctm_swat_varianth.mdl"},
};

char TDistinguished[][][] =
{
	{"Trapper Aggressor | Guerrilla Warfare",				"models/player/custom_player/legacy/tm_jungle_raider_variantf.mdl"},
	{"Mr. Muhlik | Elite Crew",								"models/player/custom_player/legacy/tm_leet_variantj.mdl"},
	{"Enforcer | Phoenix",									"models/player/custom_player/legacy/tm_phoenix_variantf.mdl"},
	{"Soldier | Phoenix",									"models/player/custom_player/legacy/tm_phoenix_varianth.mdl"},
	{"Ground Rebel  | Elite Crew",							"models/player/custom_player/legacy/tm_leet_variantg.mdl"},
	{"Street Soldier | Phoenix",							"models/player/custom_player/legacy/tm_phoenix_varianti.mdl"},
	{"Dragomir | Sabre Footsoldier",						"models/player/custom_player/legacy/tm_balkan_variantl.mdl"},
};

char CTExceptional[][][] =
{
	{"Officer Jacques Beltram | Gendarmerie Nationale",		"models/player/custom_player/legacy/ctm_gendarmerie_variante.mdl"},
	{"Lieutenant 'Tree Hugger' Farlow | SWAT",				"models/player/custom_player/legacy/ctm_swat_variantk.mdl"},
	{"Sous-Lieutenant Medic | Gendarmerie Nationale",		"models/player/custom_player/legacy/ctm_gendarmerie_varianta.mdl"},
	{"Markus Delrow | FBI",									"models/player/custom_player/legacy/ctm_fbi_variantg.mdl"},
	{"Buckshot | NSWC SEAL",								"models/player/custom_player/legacy/ctm_st6_variantg.mdl"},
	{"John 'Van Healen' Kask | SWAT",						"models/player/custom_player/legacy/ctm_swat_variantg.mdl"},
	{"Sergeant Bombson | SWAT",								"models/player/custom_player/legacy/ctm_swat_varianti.mdl"},
	{"'Blueberries' Buckshot | NSWC SEAL",					"models/player/custom_player/legacy/ctm_st6_variantj.mdl"},
};

char TExceptional[][][] =
{
	{"Col. Mangos Dabisi | Guerrilla Warfare",				"models/player/custom_player/legacy/tm_jungle_raider_variantd.mdl"},
	{"Trapper | Guerrilla Warfare",							"models/player/custom_player/legacy/tm_jungle_raider_variantf2.mdl"},
	{"Maximus | Sabre",										"models/player/custom_player/legacy/tm_balkan_varianti.mdl"},
	{"Osiris | Elite Crew",									"models/player/custom_player/legacy/tm_leet_varianth.mdl"},
	{"Slingshot | Phoenix",									"models/player/custom_player/legacy/tm_phoenix_variantg.mdl"},
	{"Dragomir | Sabre",									"models/player/custom_player/legacy/tm_balkan_variantf.mdl"},
	{"Getaway Sally | The Professionals",					"models/player/custom_player/legacy/tm_professional_varj.mdl"},
	{"Little Kev | The Professionals",						"models/player/custom_player/legacy/tm_professional_varh.mdl"},
};

char CTSuperior[][][] =
{
	{"Chem-Haz Capitaine | Gendarmerie Nationale",			"models/player/custom_player/legacy/ctm_gendarmerie_variantb.mdl"},
	{"Lieutenant Rex Krikey | SEAL Frogman",				"models/player/custom_player/legacy/ctm_diver_variantc.mdl"},
	{"Michael Syfers | FBI Sniper",							"models/player/custom_player/legacy/ctm_fbi_varianth.mdl"},
	{"'Two Times' McCoy | USAF TACP",						"models/player/custom_player/legacy/ctm_st6_variantm.mdl"},
	{"1st Lieutenant Farlow | SWAT",						"models/player/custom_player/legacy/ctm_swat_variantf.mdl"},
	{"'Two Times' McCoy | TACP Cavalry",					"models/player/custom_player/legacy/ctm_st6_variantl.mdl"},
};

char TSuperior[][][] =
{
	{"Bloody Darryl The Strapped | The Professionals",		"models/player/custom_player/legacy/tm_professional_varf5.mdl"},
	{"Elite Trapper Solman | Guerrilla Warfare",			"models/player/custom_player/legacy/tm_jungle_raider_varianta.mdl"},
	{"Arno The Overgrown | Guerrilla Warfare",				"models/player/custom_player/legacy/tm_jungle_raider_variantc.mdl"},
	{"Blackwolf | Sabre",									"models/player/custom_player/legacy/tm_balkan_variantj.mdl"},
	{"Prof. Shahmat | Elite Crew",							"models/player/custom_player/legacy/tm_leet_varianti.mdl"},
	{"Rezan The Ready | Sabre",								"models/player/custom_player/legacy/tm_balkan_variantg.mdl"},
	{"Number K | The Professionals",						"models/player/custom_player/legacy/tm_professional_vari.mdl"},
	{"Safecracker Voltzmann | The Professionals",			"models/player/custom_player/legacy/tm_professional_varg.mdl"},
	{"Rezan the Redshirt | Sabre",							"models/player/custom_player/legacy/tm_balkan_variantk.mdl"},
};

char CTMaster[][][] =
{
	{"Chef d'Escadron Rouchard | Gendarmerie Nationale",	"models/player/custom_player/legacy/ctm_gendarmerie_variantc.mdl"},
	{"Cmdr. Frank 'Wet Sox' Baroud | SEAL Frogman",			"models/player/custom_player/legacy/ctm_diver_variantb.mdl"},
	{"Cmdr. Davida 'Goggles' Fernandez | SEAL Frogman",		"models/player/custom_player/legacy/ctm_diver_varianta.mdl"},
	{"Lt. Commander Ricksaw | NSWC SEAL",					"models/player/custom_player/legacy/ctm_st6_varianti.mdl"},
	{"Special Agent Ava | FBI",								"models/player/custom_player/legacy/ctm_fbi_variantb.mdl"},
	{"Cmdr. Mae 'Dead Cold' Jamison | SWAT",				"models/player/custom_player/legacy/ctm_swat_variante.mdl"},
};

char TMaster[][][] =
{
	{"Vypa Sista of the Revolution | Guerrilla Warfare",	"models/player/custom_player/legacy/tm_jungle_raider_variante.mdl"},
	{"'Medium Rare' Crasswater | Guerrilla Warfare",		"models/player/custom_player/legacy/tm_jungle_raider_variantb2.mdl"},
	{"Crasswater The Forgotten | Guerrilla Warfare",		"models/player/custom_player/legacy/tm_jungle_raider_variantb.mdl"},
	{"'The Doctor' Romanov | Sabre",						"models/player/custom_player/legacy/tm_balkan_varianth.mdl"},
	{"The Elite Mr. Muhlik | Elite Crew",					"models/player/custom_player/legacy/tm_leet_variantf.mdl"},
	{"Sir Bloody Miami Darryl | The Professionals",			"models/player/custom_player/legacy/tm_professional_varf.mdl"},
	{"Sir Bloody Silent Darryl | The Professionals",		"models/player/custom_player/legacy/tm_professional_varf1.mdl"},
	{"Sir Bloody Skullhead Darryl | The Professionals",		"models/player/custom_player/legacy/tm_professional_varf2.mdl"},
	{"Sir Bloody Darryl Royale | The Professionals",		"models/player/custom_player/legacy/tm_professional_varf3.mdl"},
	{"Sir Bloody Loudmouth Darryl | The Professionals",		"models/player/custom_player/legacy/tm_professional_varf4.mdl"},
};

#define		DATA	"1.2.0"

public Plugin myinfo =
{
	name		=	"[CS:GO] Franug Agents Chooser",
	author		=	"Franc1sco franug, Romeo, TrueProfessional, Teamkiller324",
	description	=	"Plugin giving you opportunity to change agents",
	version 	=	DATA,
	url			=	"http://steamcommunity.com/id/franug"
}

int		g_iTeam[MAXPLAYERS + 1], g_iCategory[MAXPLAYERS + 1];

char	g_ctAgent[MAXPLAYERS + 1][128], g_tAgent[MAXPLAYERS + 1][128];

Cookie	c_CTAgent, c_TAgent;

ConVar	cv_version, cv_timer, cv_noOverwritte, cv_instant, cv_autoopen, cv_PreviewDuration, cv_HidePlayers;

bool	_checkedMsg[MAXPLAYERS + 1];

public void OnPluginStart()
{
	RegConsoleCmd("sm_agents", Command_Main);
	
	RegAdminCmd("sm_agents_generatemodels", Command_GenerateModelsForSkinchooser, ADMFLAG_ROOT);
	RegAdminCmd("sm_agents_generatestoremodels", Command_GenerateModelsForStore, ADMFLAG_ROOT);
	
	c_CTAgent = new Cookie("CTAgent_b", "", CookieAccess_Private);
	c_TAgent = new Cookie("TAgent_b", "", CookieAccess_Private);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_team", OnPlayerTeam, EventHookMode_Post);
	
	cv_version			= CreateConVar("sm_csgoagents_version",				DATA,	"Agents Chooser - Version.");
	cv_autoopen			= CreateConVar("sm_csgoagents_autoopen",			"0",	"Agent Chooser - Enable/Disable auto open menu when you connect and you didnt select a agent yet", _, true, 0.0, true, 1.0);
	cv_instant			= CreateConVar("sm_csgoagents_instantly",			"1",	"Agent Chooser - Enable/Disable apply agents skins instantly", _, true, 0.0, true, 1.0);
	cv_timer			= CreateConVar("sm_csgoagents_timer",				"0.2",	"Agent Chooser - Time on Spawn for apply agent skins", _, true, 0.0);
	cv_noOverwritte		= CreateConVar("sm_csgoagents_nooverwrittecustom",	"1",	"Agent Chooser - No apply agent model if the user already have a custom model. \n1 = No apply when custom model \n0 = Disable this feature", _, true, 0.0, true, 1.0);
	cv_PreviewDuration	= CreateConVar("sm_csgoagents_previewduration",		"3.0",	"Agent Chooser - Preview duration when choosing an agent. Disable: 0", _, true, 0.0);
	cv_HidePlayers		= CreateConVar("sm_csgoagents_hideplayers",			"0",	"Agent Chooser - Hide players when thirdperson view active.\nDisable: 0\nEnemies: 1\nAll: 2", _, true, 0.0, true, 2.0);
	
	cv_version.AddChangeHook(VersionCallback);
	cv_HidePlayers.AddChangeHook(OnCvarChange); // use SetTransmit only when is needed
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
	
	AutoExecConfig(true, "csgo_agentschooser");
}

/**
 *	Makes sure the version console variable isn't changed.
 */
void VersionCallback(ConVar cvar, const char[] oldvalue, const char[] newvalue)
{
	cvar.SetString(DATA);
}

void OnCvarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	int iNewValue = StringToInt(newValue);
	int iOldValue = StringToInt(oldValue);
	
	if(iNewValue > 0 && iOldValue == 0)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				OnClientPutInServer(i);
			}
		}	
	}
	else if(iNewValue == 0 && iOldValue > 0)
	{
		// save cpu usage when we dont want the hideplayers feature
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				SDKUnhook(i, SDKHook_SetTransmit, Hook_SetTransmit);
			}
		}
	}	
}

// I generate these files automatically with code instead of do it manually like a good programmer :p
Action Command_GenerateModelsForSkinchooser(int client, int args)
{
	KeyValues kv = new KeyValues("Models");
	
	kv.JumpToKey("CSGO Agents", true);
	kv.JumpToKey("Team1", true);
	
	for (int i = 0; i < sizeof(TDistinguished); i++)
	{
		kv.JumpToKey(TDistinguished[i][0], true);
		kv.SetString("path", TDistinguished[i][1]);
		kv.GoBack();
	}
	for (int i = 0; i < sizeof(TExceptional); i++)
	{
		kv.JumpToKey(TExceptional[i][0], true);
		kv.SetString("path", TExceptional[i][1]);
		kv.GoBack();
	}
	for (int i = 0; i < sizeof(TSuperior); i++)
	{
		kv.JumpToKey(TSuperior[i][0], true);
		kv.SetString("path", TSuperior[i][1]);
		kv.GoBack();
	}
	for (int i = 0; i < sizeof(TMaster); i++)
	{
		kv.JumpToKey(TMaster[i][0], true);
		kv.SetString("path", TMaster[i][1]);
		kv.GoBack();
	}
	
	kv.GoBack();
	kv.JumpToKey("Team2", true);
	
	for (int i = 0; i < sizeof(CTDistinguished); i++)
	{
		kv.JumpToKey(CTDistinguished[i][0], true);
		kv.SetString("path", CTDistinguished[i][1]);
		kv.GoBack();
	}
	for (int i = 0; i < sizeof(CTExceptional); i++)
	{
		kv.JumpToKey(CTExceptional[i][0], true);
		kv.SetString("path", CTExceptional[i][1]);
		kv.GoBack();
	}
	for (int i = 0; i < sizeof(CTSuperior); i++)
	{
		kv.JumpToKey(CTSuperior[i][0], true);
		kv.SetString("path", CTSuperior[i][1]);
		kv.GoBack();
	}
	for (int i = 0; i < sizeof(CTMaster); i++)
	{
		kv.JumpToKey(CTMaster[i][0], true);
		kv.SetString("path", CTMaster[i][1]);
		kv.GoBack();
	}
	kv.Rewind();
	kv.ExportToFile("addons/sourcemod/configs/sm_skinchooser_withagents.cfg");
	delete kv;
	
	ReplyToCommand(client, "CFG file generated for models.");
	
	return Plugin_Handled;
}

Action Command_GenerateModelsForStore(int client, int args)
{
	char price[32] = "3000"; // default price
	KeyValues kv = new KeyValues("Store");
	
	kv.JumpToKey("CSGO Agents", true);
	kv.JumpToKey("Terrorist", true);
	
	for (int i = 0; i < sizeof(TDistinguished); i++)
	{
		kv.JumpToKey(TDistinguished[i][0], true);
		kv.SetString("model", TDistinguished[i][1]);
		kv.SetString("team", "2");
		kv.SetString("price", price);
		kv.SetString("type", "playerskin");
		kv.GoBack();
	}
	for (int i = 0; i < sizeof(TExceptional); i++)
	{
		kv.JumpToKey(TExceptional[i][0], true);
		kv.SetString("model", TExceptional[i][1]);
		kv.SetString("team", "2");
		kv.SetString("price", price);
		kv.SetString("type", "playerskin");
		kv.GoBack();
	}
	for (int i = 0; i < sizeof(TSuperior); i++)
	{
		kv.JumpToKey(TSuperior[i][0], true);
		kv.SetString("model", TSuperior[i][1]);
		kv.SetString("team", "2");
		kv.SetString("price", price);
		kv.SetString("type", "playerskin");
		kv.GoBack();
	}
	for (int i = 0; i < sizeof(TMaster); i++)
	{
		kv.JumpToKey(TMaster[i][0], true);
		kv.SetString("model", TMaster[i][1]);
		kv.SetString("team", "2");
		kv.SetString("price", price);
		kv.SetString("type", "playerskin");
		kv.GoBack();
	}
	
	kv.GoBack();
	kv.JumpToKey("Counter-Terrorist", true);
	
	for (int i = 0; i < sizeof(CTDistinguished); i++)
	{
		kv.JumpToKey(CTDistinguished[i][0], true);
		kv.SetString("model", CTDistinguished[i][1]);
		kv.SetString("team", "3");
		kv.SetString("price", price);
		kv.SetString("type", "playerskin");
		kv.GoBack();
	}
	for (int i = 0; i < sizeof(CTExceptional); i++)
	{
		kv.JumpToKey(CTExceptional[i][0], true);
		kv.SetString("model", CTExceptional[i][1]);
		kv.SetString("team", "3");
		kv.SetString("price", price); 
		kv.SetString("type", "playerskin");
		kv.GoBack();
	}
	for (int i = 0; i < sizeof(CTSuperior); i++)
	{
		kv.JumpToKey(CTSuperior[i][0], true);
		kv.SetString("model", CTSuperior[i][1]);
		kv.SetString("team", "3");
		kv.SetString("price", price);
		kv.SetString("type", "playerskin");
		kv.GoBack();
	}
	for (int i = 0; i < sizeof(CTMaster); i++)
	{
		kv.JumpToKey(CTMaster[i][0], true);
		kv.SetString("model", CTMaster[i][1]);
		kv.SetString("team", "3");
		kv.SetString("price", price);
		kv.SetString("type", "playerskin");
		kv.GoBack();
	}
	kv.Rewind();
	kv.ExportToFile("addons/sourcemod/configs/storeitems_withagents.txt");
	delete kv;
	
	ReplyToCommand(client, "CFG file generated for models.");
	
	return Plugin_Handled;
}

public void OnClientCookiesCached(int client)
{
	c_CTAgent.Get(client, g_ctAgent[client], 128);
	c_TAgent.Get(client, g_tAgent[client], 128);
}

public void OnClientDisconnect(int client)
{
	if(!IsFakeClient(client) && AreClientCookiesCached(client))
	{
		c_TAgent.Set(client, g_tAgent[client]);
		c_CTAgent.Set(client, g_ctAgent[client]);
	}
	
	strcopy(g_ctAgent[client], 128, "");
	strcopy(g_tAgent[client], 128, "");
	_checkedMsg[client] = false;
	
	if(g_hTimer[client] != null)
	{
		KillTimer(g_hTimer[client]);
		g_hTimer[client] = null;
	}
	
	if(!IsClientSourceTV(client))
	{
		SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	}
}

Action Command_Main(int client, int args)
{
	if(!VIP_IsClientVIP(client))
    {
        PrintToChat(client, "[SM] You must have vip to use agents!");
        return Plugin_Handled;
    }

	Menu menu = new Menu(SelectTeam, MenuAction_Select  | MenuAction_End);
	
	menu.SetTitle("Choose Agents Team:");
	
	menu.AddItem("", "Counter-Terrorist Team");
	menu.AddItem("", "Terrorist Team");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

int SelectTeam(Menu menu, MenuAction action, int client, int selection) 
{
	switch(action)
	{
		case	MenuAction_Select:
		{
			switch(selection)
			{
				case	0:	g_iTeam[client] = CS_TEAM_CT;
				case	1:	g_iTeam[client] = CS_TEAM_T;
			}
			
			OpenAgentsMenu(client);
		}

		case	MenuAction_End:
		{
			delete menu;
		}
	}
}

void OpenAgentsMenu(int client)
{
	Menu menu = new Menu(SelectType, MenuAction_Select  | MenuAction_End);

	menu.SetTitle("Choose Agents type:");
	
	menu.AddItem("", "Use Default Skins");
	menu.AddItem("", "Distinguished Agents");
	menu.AddItem("", "Exceptional Agents");
	menu.AddItem("", "Superior Agents");
	menu.AddItem("", "Master Agents");
	
	//SetMenuPagination(menu, MENU_NO_PAGINATION);
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int SelectType(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case	MenuAction_Select:
		{
			switch(selection)
			{
				case	0:
				{
					
					if(IsPlayerAlive(client))
						CS_UpdateClientModel(client);
					
					strcopy(g_ctAgent[client], 128, "");
					strcopy(g_tAgent[client], 128, "");
					
					PrintToChat(client, "You dont use a agent model now.");
					
					OpenAgentsMenu(client);
				}
				case	1:	DisMenu(client, 0);
				case	2:	ExMenu(client, 0);
				case	3:	SuMenu(client, 0);
				case	4:	MaMenu(client, 0);
			}
			g_iCategory[client] = selection;
		}
		
		case	MenuAction_Cancel, MenuCancel_ExitBack:
		{
 			Command_Main(client, 0);
 		}

		case	MenuAction_End:
		{
			delete menu;
		}
	}
}

void DisMenu(int client, int num)
{
	Menu menu = new Menu(AgentChoosed, MenuAction_Select  | MenuAction_End);
	
	menu.SetTitle("Distinguished Agents");
	
	if(g_iTeam[client] == CS_TEAM_CT)
	{
		for(int i = 0; i < sizeof(CTDistinguished); i++)
		{
			menu.AddItem(CTDistinguished[i][1], CTDistinguished[i][0], 
			StrEqual(g_ctAgent[client], CTDistinguished[i][1]) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		}
	}
	else
	{
		for(int i = 0; i < sizeof(TDistinguished); i++)	{
			menu.AddItem(TDistinguished[i][1], TDistinguished[i][0], 
			StrEqual(g_tAgent[client], TDistinguished[i][1]) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		}
	}
	
	menu.ExitBackButton = true;
	menu.DisplayAt(client, num, MENU_TIME_FOREVER);
}

void ExMenu(int client, int num)
{
	Menu menu = new Menu(AgentChoosed, MenuAction_Select  | MenuAction_End);
	
	menu.SetTitle("Exceptional Agents");
	
	if(g_iTeam[client] == CS_TEAM_CT)
	{
		for(int i = 0; i < sizeof(CTExceptional); i++)
		{
			menu.AddItem(CTExceptional[i][1], CTExceptional[i][0], 
			StrEqual(g_ctAgent[client], CTExceptional[i][1]) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		}
	}
	else
	{
		for(int i = 0; i < sizeof(TExceptional); i++)
		{
			menu.AddItem(TExceptional[i][1], TExceptional[i][0], 
			StrEqual(g_tAgent[client], TExceptional[i][1]) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		}
	}
	
	menu.ExitBackButton = true;
	menu.DisplayAt(client, num, MENU_TIME_FOREVER);
}

void SuMenu(int client, int num)
{
	Menu menu = new Menu(AgentChoosed, MenuAction_Select  | MenuAction_End);
	
	menu.SetTitle("Superior Agents");
	
	if(g_iTeam[client] == CS_TEAM_CT)
	{
		for(int i = 0; i < sizeof(CTSuperior); i++)
		{
			menu.AddItem(CTSuperior[i][1], CTSuperior[i][0], 
			StrEqual(g_ctAgent[client], CTSuperior[i][1]) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		}
	}
	else
	{
		for(int i = 0; i < sizeof(TSuperior); i++)
		{
			menu.AddItem(TSuperior[i][1], TSuperior[i][0], 
			StrEqual(g_tAgent[client], TSuperior[i][1]) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		}	
	}
	
	menu.ExitBackButton = true;
	menu.DisplayAt(client, num, MENU_TIME_FOREVER);
}

void MaMenu(int client, int num)
{
	Menu menu = new Menu(AgentChoosed, MenuAction_Select  | MenuAction_End);
	
	menu.SetTitle("Master Agents");
	
	if(g_iTeam[client] == CS_TEAM_CT)
	{
		for(int i = 0; i < sizeof(CTMaster); i++)
		{
			menu.AddItem(CTMaster[i][1], CTMaster[i][0], 
			StrEqual(g_ctAgent[client], CTMaster[i][1]) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		}
	}
	else
	{
		for(int i = 0; i < sizeof(TMaster); i++)
		{
			menu.AddItem(TMaster[i][1], TMaster[i][0],
			StrEqual(g_tAgent[client], TMaster[i][1]) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		}
	}
	
	menu.ExitBackButton = true;
	menu.DisplayAt(client, num, MENU_TIME_FOREVER);
}

int AgentChoosed(Menu menu, MenuAction action, any client, int selection)
{
	switch(action)
	{
		case	MenuAction_Select:
		{
			char model[128];
			menu.GetItem(selection, model, sizeof(model));
			
			switch(g_iTeam[client])
			{
				case	CS_TEAM_CT:	strcopy(g_ctAgent[client], 128, model);
				case	CS_TEAM_T:	strcopy(g_tAgent[client], 128, model);
			}
			
			PrintToChat(client, cv_instant.BoolValue ? "Agent model choosed!":"Agent model choosed! you will have it in the next spawn.");
			
			switch(g_iCategory[client])
			{
				case	1:	DisMenu(client, GetMenuSelectionPosition());
				case	2:	ExMenu(client, GetMenuSelectionPosition());
				case	3:	SuMenu(client, GetMenuSelectionPosition());
				case	4:	MaMenu(client, GetMenuSelectionPosition());
			}
			
			if(cv_instant.BoolValue && IsPlayerAlive(client) && GetClientTeam(client) == g_iTeam[client])
			{
				if(cv_noOverwritte.BoolValue)
				{
					char dmodel[128];
					GetClientModel(client, dmodel, sizeof(dmodel));
					if(StrContains(dmodel, "models/player/custom_player/legacy/") == -1)
					{
						PrintToChat(client, "You already have a custom player skin, remove your custom player skin for use a agent.");
						return;
					}
				}
				
				SetEntityModel(client, model);
				
				if(cv_PreviewDuration.BoolValue)
				{
					SetThirdPersonMode(client, true);
					
					if(g_hTimer[client] != null)
					{
						KillTimer(g_hTimer[client]);
						g_hTimer[client] = null;
					}
					
					g_hTimer[client] = CreateTimer(cv_PreviewDuration.FloatValue, Timer_SetBackMode, client, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		case	MenuAction_Cancel, MenuCancel_ExitBack:
 		{
 			OpenAgentsMenu(client);
			
			if(cv_PreviewDuration.BoolValue)
			{
				SetThirdPersonMode(client, false);
				
				if(g_hTimer[client] != null)
				{
					KillTimer(g_hTimer[client]);
					g_hTimer[client] = null;
				}
			}
 		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

Action Event_PlayerSpawn(Event event, const char[] sName, bool bDontBroadcast)
{
	CreateTimer(cv_timer.FloatValue, Timer_ApplySkin, event.GetInt("userid"));
}

Action Timer_ApplySkin(Handle timer, int id)
{
	int client = GetClientOfUserId(id);
	
	if(id < 1 || !IsValidClient(client) || !IsPlayerAlive(client) || !AreClientCookiesCached(client) || !VIP_IsClientVIP(client))
		return;
	
	char model[255];
	switch(GetClientTeam(client))
	{
		case	CS_TEAM_CT:	strcopy(model, sizeof(model), g_ctAgent[client]);
		case	CS_TEAM_T:	strcopy(model, sizeof(model), g_tAgent[client]);
	}	
		
	if(strlen(model) < 1)
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
			PrintToChat(client, "You already have a custom player skin, remove your custom player skin for use a agent.");
			return;
		}
	}
	
	SetEntityModel(client, model);
}

Action Timer_SetBackMode(Handle timer, any client)
{
	SetThirdPersonMode(client, false);
	g_hTimer[client] = null;
}

void SetThirdPersonMode(int client, bool bEnable)
{
	ConVar mp_forcecamera = FindConVar("mp_forcecamera");
	if(mp_forcecamera == null)
	{
		return;
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
		mp_forcecamera.GetString(sValue, sizeof(sValue));
		SendConVarValue(client, mp_forcecamera, sValue);
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") & ~HIDE_RADAR_CSGO);
		SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") & ~HIDE_CROSSHAIR_CSGO);
	}
}

public void OnClientPutInServer(int client)
{
	if(!IsClientSourceTV(client))
	{
		SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	}
}

Action Hook_SetTransmit(int client, int agent)
{
	if(client != agent && g_hTimer[agent] != null)	{
		if(cv_HidePlayers.IntValue == 2)
		{
			return Plugin_Handled;
		}
		else if(g_iTeam[client] != g_iTeam[agent])
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

void OnPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	
	if(userid > 0)
		g_iTeam[GetClientOfUserId(userid)] = event.GetInt("team");
}

stock bool isAgentSelected(int client)
{
	return	(strlen(g_tAgent[client]) < 1 && strlen(g_ctAgent[client]) < 1);
}

bool IsValidClient(int client)
{
	if(client == 0 || client == -1)
		return	false;
	if(client < 1 || client > MaxClients)
		return	false;
	if(!IsClientInGame(client))
		return	false;
	if(!IsClientConnected(client))
		return	false;
	if(IsFakeClient(client))
		return	false;
	if(IsClientReplay(client))
		return	false;
	if(IsClientSourceTV(client))
		return	false;
	
	return	true;
}

bool VIP_IsClientVIP(int client) 
{
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
	{
		return true;
	}
	return false;
}

