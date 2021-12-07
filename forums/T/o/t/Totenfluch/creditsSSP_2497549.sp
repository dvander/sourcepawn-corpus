/*
	Credits Scissors Rock Paper
    Copyright (C) 2016 Christian Ziegler

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#pragma semicolon 1

#define PLUGIN_AUTHOR "Totenfluch"
#define PLUGIN_VERSION "1.23"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <store>
#include <adminmenu>
#include <multicolors>
#include <autoexecconfig>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "T-Credits-SSP", 
	author = PLUGIN_AUTHOR, 
	description = "implements SSP for zephstore", 
	version = PLUGIN_VERSION, 
	url = "http://ggc-base.de"
};

bool g_bInGame[MAXPLAYERS + 1];
bool g_bInAccept[MAXPLAYERS + 1];

enum sspItems {
	None = 0, 
	Schere = 1, 
	Stein = 2, 
	Papier = 3
};

sspItems g_eSSPItem[MAXPLAYERS + 1];
int g_iOponent[MAXPLAYERS + 1];
int g_iGameAmount[MAXPLAYERS + 1];

bool g_bIgnoringInvites[MAXPLAYERS + 1];
int g_iIgnoringInvitesBellow[MAXPLAYERS + 1];

Handle g_hMinSSPThreshold;
int g_iMinSSPThreshold;

Handle g_hMaxSSPThreshold;
int g_iMaxSSPThreshold;

Handle g_hDefaultOffForAdmins;
bool g_bDefaultOffForAdmins;

Handle g_hChatTag;
char ttag[64] = "GGC-SSP";

Handle g_hUseMysqlForBlockSSP;
bool g_bUseMysqlForBlockSSP;

Handle g_hSSPOnlyDead;
int g_iSSPOnlyDead;

Handle g_hSSPOnlyDeadAdminOverride;
bool g_bSSPOnlyDeadAdminOverride;

Handle g_hSSPOnlyDeadItemOverride;
bool g_bSSPOnlyDeadItemOverride;

Handle g_hHouseMargin;
float g_fHouseMargin;

Handle g_hCreditsChooserMenuValue1;
int g_iCreditsChooserMenuValue1;

Handle g_hCreditsChooserMenuValue2;
int g_iCreditsChooserMenuValue2;

Handle g_hCreditsChooserMenuValue3;
int g_iCreditsChooserMenuValue3;

Handle g_hCreditsChooserMenuValue4;
int g_iCreditsChooserMenuValue4;

Handle g_hCreditsChooserMenuValue5;
int g_iCreditsChooserMenuValue5;

Handle g_hCreditsChooserMenuValue6;
int g_iCreditsChooserMenuValue6;

Handle g_hCreditsChooserMenuValue7;
int g_iCreditsChooserMenuValue7;

Handle g_hCreditsChooserMenuValue8;
int g_iCreditsChooserMenuValue8;

Handle g_hBlockChatCommand;
bool g_bBlockChatCommand;

Database g_DB;

public void OnPluginStart()
{
	RegConsoleCmd("sm_ssp", sspCommand, "Opens the SSP Menu");
	RegConsoleCmd("sm_srp", sspCommand, "Opens the SSP Menu");
	RegConsoleCmd("sm_blockssp", blockSSPCommand, "Blocks SSP invites");
	RegConsoleCmd("sm_unblockssp", unblockSSPCommand, "unblocks SSP invites");
	RegConsoleCmd("sm_togglessp", toggleSSPCommand, "toggles the Block for SSP invites");
	RegConsoleCmd("say", chatHook);
	
	Store_RegisterHandler("sspAlive", "sspAliveUpgrade", AliveItem_OnMapStart, AliveItem_Reset, AliveItem_Config, AliveItem_Equip, AliveItem_Remove, true);
	
	LoadTranslations("sspCredits.phrases");
	
	AutoExecConfig_SetFile("sspCredits");
	AutoExecConfig_SetCreateFile(true);
	
	g_hChatTag = AutoExecConfig_CreateConVar("ssp_chattag", "GGC", "sets the chat tag before every message for SSP");
	g_hMaxSSPThreshold = AutoExecConfig_CreateConVar("ssp_maxThreshold", "50000", "maximum amount of credits you can play ssp with");
	g_hMinSSPThreshold = AutoExecConfig_CreateConVar("ssp_minThreshold", "10", "minimum amount of credits you can play ssp with");
	g_hDefaultOffForAdmins = AutoExecConfig_CreateConVar("ssp_defaultOffForAdmins", "1", "BlockSSP enabled by default for Admins (Generic Flag) [Disabled when MySQL enabled], 0 -> False, 1 -> True");
	g_hUseMysqlForBlockSSP = AutoExecConfig_CreateConVar("ssp_useMysqlForBlockSSP", "0", "Save the blockssp after mapchange via mysql (Databse config: 'sspCredits'), 0 -> False, 1 -> True");
	g_hSSPOnlyDead = AutoExecConfig_CreateConVar("ssp_onlyDead", "0", "0 -> Disabled, 1 -> Only allows dead players to send SSP invites, 2 -> Only allows dead players to play and send invites");
	g_hSSPOnlyDeadAdminOverride = AutoExecConfig_CreateConVar("ssp_onlyDeadAdminOverride", "1", "Overrides 'ssp_onlyDead' for Admins, 0 -> False, 1 -> True");
	g_hSSPOnlyDeadItemOverride = AutoExecConfig_CreateConVar("ssp_onlyDeadItemOverride", "0", "Enables to override 'ssp_onlyDead' with an store item ('sspAlive'), 0 -> False, 1 -> True");
	g_hHouseMargin = AutoExecConfig_CreateConVar("ssp_housemargin", "1.0", "Percentag of Credit the winner recieves, 1.0 -> 100%, 0.95 -> 95% [5% will be voided])");
	g_hBlockChatCommand = AutoExecConfig_CreateConVar("ssp_BlockChatCommand", "1", "Removes !ssp from the Chat to prevent spam. 1 -> True, 0 -> False");
	
	
	g_hCreditsChooserMenuValue1 = AutoExecConfig_CreateConVar("ssp_creditsMenuOption_1", "10", "Defines the option (1) in the CreditsChooserMenu");
	g_hCreditsChooserMenuValue2 = AutoExecConfig_CreateConVar("ssp_creditsMenuOption_2", "25", "Defines the option (2) in the CreditsChooserMenu");
	g_hCreditsChooserMenuValue3 = AutoExecConfig_CreateConVar("ssp_creditsMenuOption_3", "50", "Defines the option (3) in the CreditsChooserMenu");
	g_hCreditsChooserMenuValue4 = AutoExecConfig_CreateConVar("ssp_creditsMenuOption_4", "75", "Defines the option (4) in the CreditsChooserMenu");
	g_hCreditsChooserMenuValue5 = AutoExecConfig_CreateConVar("ssp_creditsMenuOption_5", "150", "Defines the option (5) in the CreditsChooserMenu");
	g_hCreditsChooserMenuValue6 = AutoExecConfig_CreateConVar("ssp_creditsMenuOption_6", "500", "Defines the option (6) in the CreditsChooserMenu");
	g_hCreditsChooserMenuValue7 = AutoExecConfig_CreateConVar("ssp_creditsMenuOption_7", "1000", "Defines the option (7) in the CreditsChooserMenu");
	g_hCreditsChooserMenuValue8 = AutoExecConfig_CreateConVar("ssp_creditsMenuOption_8", "2500", "Defines the option (8) in the CreditsChooserMenu");
	
	
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
}

public void OnConfigsExecuted() {
	GetConVarString(g_hChatTag, ttag, sizeof(ttag));
	g_iMinSSPThreshold = GetConVarInt(g_hMinSSPThreshold);
	g_iMaxSSPThreshold = GetConVarInt(g_hMaxSSPThreshold);
	g_bDefaultOffForAdmins = GetConVarBool(g_hDefaultOffForAdmins);
	g_bUseMysqlForBlockSSP = GetConVarBool(g_hUseMysqlForBlockSSP);
	g_iSSPOnlyDead = GetConVarInt(g_hSSPOnlyDead);
	g_bSSPOnlyDeadAdminOverride = GetConVarBool(g_hSSPOnlyDeadAdminOverride);
	g_bSSPOnlyDeadItemOverride = GetConVarBool(g_hSSPOnlyDeadItemOverride);
	g_fHouseMargin = GetConVarFloat(g_hHouseMargin);
	g_bBlockChatCommand = GetConVarBool(g_hBlockChatCommand);
	if (g_fHouseMargin > 1.0)
		SetFailState("Invalid 'ssp_housemargin' Value. Change it otherwise this can be exploided");
	
	g_iCreditsChooserMenuValue1 = GetConVarInt(g_hCreditsChooserMenuValue1);
	g_iCreditsChooserMenuValue2 = GetConVarInt(g_hCreditsChooserMenuValue2);
	g_iCreditsChooserMenuValue3 = GetConVarInt(g_hCreditsChooserMenuValue3);
	g_iCreditsChooserMenuValue4 = GetConVarInt(g_hCreditsChooserMenuValue4);
	g_iCreditsChooserMenuValue5 = GetConVarInt(g_hCreditsChooserMenuValue5);
	g_iCreditsChooserMenuValue6 = GetConVarInt(g_hCreditsChooserMenuValue6);
	g_iCreditsChooserMenuValue7 = GetConVarInt(g_hCreditsChooserMenuValue7);
	g_iCreditsChooserMenuValue8 = GetConVarInt(g_hCreditsChooserMenuValue8);
	
	if (g_bUseMysqlForBlockSSP) {
		char error[255];
		g_DB = SQL_Connect("sspCredits", true, error, sizeof(error));
		SQL_SetCharset(g_DB, "utf8");
		
		char CreateProtectedIdsTable[256];
		Format(CreateProtectedIdsTable, sizeof(CreateProtectedIdsTable), "CREATE TABLE IF NOT EXISTS `ssp_sspblocked` (`playerid` varchar(30) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;");
		SQL_TQuery(g_DB, SQLErrorCheckCallback, CreateProtectedIdsTable);
	}
}

public void OnClientPostAdminCheck(int client) {
	g_bInGame[client] = false;
	g_eSSPItem[client] = None;
	g_iOponent[client] = -1;
	g_iGameAmount[client] = -1;
	g_bInAccept[client] = false;
	g_bIgnoringInvites[client] = false;
	g_iIgnoringInvitesBellow[client] = 0;
	
	if (CheckCommandAccess(client, "sm_totenfluchCMDAccess", ADMFLAG_GENERIC, true) && g_bDefaultOffForAdmins && !g_bUseMysqlForBlockSSP)
		g_bIgnoringInvites[client] = true;
	
	if (g_bUseMysqlForBlockSSP) {
		char checkId[20];
		GetClientAuthId(client, AuthId_Steam2, checkId, sizeof(checkId));
		
		Handle datapack = CreateDataPack();
		WritePackCell(datapack, client);
		ResetPack(datapack);
		
		char query[512];
		Format(query, sizeof(query), "SELECT Count(*) FROM ssp_sspblocked WHERE playerid = '%s'", checkId);
		SQL_TQuery(g_DB, sql_CheckIfSSPBlockedCallback, query, datapack);
	}
}

public void OnClientDisconnect(int client) {
	int target = GetClientOfUserId(g_iOponent[client]);
	if (isValidClient(target) && (g_bInGame[client] || g_bInAccept[client])) {
		CPrintToChat(target, "%t", "opponentDisconnect", ttag);
		g_bInGame[target] = false;
		g_eSSPItem[target] = None;
		g_iOponent[target] = -1;
		g_iGameAmount[target] = -1;
		g_bInAccept[target] = false;
	}
	g_bInGame[client] = false;
	g_eSSPItem[client] = None;
	g_iOponent[client] = -1;
	g_iGameAmount[client] = -1;
	g_bInAccept[client] = false;
	g_bIgnoringInvites[client] = false;
	g_iIgnoringInvitesBellow[client] = 0;
}

public Action sspCommand(int client, int args) {
	if ((g_iSSPOnlyDead == 1 || g_iSSPOnlyDead == 2) && !IsPlayerAlive(client)) {
		if (!(g_bSSPOnlyDeadAdminOverride && CheckCommandAccess(client, "sm_totenfluchCMDAccess", ADMFLAG_GENERIC, true))) {
			int m_iEquipped = Store_GetEquippedItem(client, "sspAlive");
			if (!(g_bSSPOnlyDeadItemOverride && m_iEquipped >= 0)) {
				CReplyToCommand(client, "%t", "notAlive", ttag);
				return Plugin_Handled;
			}
		}
	}
	
	if (args == 0) {
		openSSPCreditsMenu(client);
	} else if (args == 1) {
		char amount[255];
		GetCmdArg(1, amount, sizeof(amount));
		int intAmount = StringToInt(amount);
		if (intAmount == 0 || intAmount > g_iMaxSSPThreshold || intAmount < g_iMinSSPThreshold) {
			CReplyToCommand(client, "%t", "invalidAmountOfCredits", ttag);
			return Plugin_Handled;
		} else {
			openSSPTargetChooserMenu(client, intAmount);
		}
	} else {
		CReplyToCommand(client, "%t", "invalidAmountOfParams", ttag);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action blockSSPCommand(int client, int args) {
	toggleSSPCommand(client, args);
}

public Action toggleSSPCommand(int client, int args) {
	if (args == 0) {
		if (g_bIgnoringInvites[client]) {
			g_bIgnoringInvites[client] = false;
			g_iIgnoringInvitesBellow[client] = 0;
			CPrintToChat(client, "%t", "noLongerIgnoringInvites", ttag);
			if (g_bUseMysqlForBlockSSP) {
				char checkId[20];
				GetClientAuthId(client, AuthId_Steam2, checkId, sizeof(checkId));
				char query[128];
				Format(query, sizeof(query), "DELETE FROM ssp_sspblocked WHERE playerid = '%s'", checkId);
				SQL_TQuery(g_DB, SQLErrorCheckCallback, query);
			}
		} else {
			g_bIgnoringInvites[client] = true;
			g_iIgnoringInvitesBellow[client] = 0;
			CPrintToChat(client, "%t", "ignoringInvites", ttag);
			if (g_bUseMysqlForBlockSSP) {
				char checkId[20];
				GetClientAuthId(client, AuthId_Steam2, checkId, sizeof(checkId));
				char query[128];
				Format(query, sizeof(query), "INSERT INTO ssp_sspblocked (`playerid`) VALUES ('%s')", checkId);
				SQL_TQuery(g_DB, SQLErrorCheckCallback, query);
			}
		}
	} else if (args == 1) {
		g_bIgnoringInvites[client] = false;
		
		char amount[255];
		GetCmdArg(1, amount, sizeof(amount));
		int intAmount = StringToInt(amount);
		
		g_iIgnoringInvitesBellow[client] = intAmount;
		
		CPrintToChat(client, "%t", "ingnoringInvitesBellow", ttag, g_iIgnoringInvitesBellow[client]);
	}
}

public Action unblockSSPCommand(int client, int args) {
	g_bIgnoringInvites[client] = false;
	g_iIgnoringInvitesBellow[client] = 0;
	CPrintToChat(client, "%t", "noLongerIgnoringInvites", ttag);
	if (g_bUseMysqlForBlockSSP) {
		char checkId[20];
		GetClientAuthId(client, AuthId_Steam2, checkId, sizeof(checkId));
		char query[128];
		Format(query, sizeof(query), "DELETE FROM ssp_sspblocked WHERE playerid = '%s'", checkId);
		SQL_TQuery(g_DB, SQLErrorCheckCallback, query);
	}
}

public void openSSPCreditsMenu(int client) {
	int clientCredits = Store_GetClientCredits(client);
	char panelTitle[256];
	Format(panelTitle, sizeof(panelTitle), "%T", "menu_title_chooseAmount", client, clientCredits);
	
	Panel panel = CreatePanel();
	SetPanelTitle(panel, panelTitle);
	DrawPanelText(panel, "^-.-^-.-^-.-^");
	
	char panelCreditsItem1[16];
	Format(panelCreditsItem1, sizeof(panelCreditsItem1), ">%i<", g_iCreditsChooserMenuValue1);
	if (clientCredits >= g_iCreditsChooserMenuValue1)
		DrawPanelItem(panel, panelCreditsItem1);
	else
		DrawPanelItem(panel, panelCreditsItem1, ITEMDRAW_DISABLED);
	
	char panelCreditsItem2[16];
	Format(panelCreditsItem2, sizeof(panelCreditsItem2), ">%i<", g_iCreditsChooserMenuValue2);
	if (clientCredits >= g_iCreditsChooserMenuValue2)
		DrawPanelItem(panel, panelCreditsItem2);
	else
		DrawPanelItem(panel, panelCreditsItem2, ITEMDRAW_DISABLED);
	
	char panelCreditsItem3[16];
	Format(panelCreditsItem3, sizeof(panelCreditsItem3), ">%i<", g_iCreditsChooserMenuValue3);
	if (clientCredits >= g_iCreditsChooserMenuValue3)
		DrawPanelItem(panel, panelCreditsItem3);
	else
		DrawPanelItem(panel, panelCreditsItem3, ITEMDRAW_DISABLED);
	
	char panelCreditsItem4[16];
	Format(panelCreditsItem4, sizeof(panelCreditsItem4), ">%i<", g_iCreditsChooserMenuValue4);
	if (clientCredits >= g_iCreditsChooserMenuValue4)
		DrawPanelItem(panel, panelCreditsItem4);
	else
		DrawPanelItem(panel, panelCreditsItem4, ITEMDRAW_DISABLED);
	
	char panelCreditsItem5[16];
	Format(panelCreditsItem5, sizeof(panelCreditsItem5), ">%i<", g_iCreditsChooserMenuValue5);
	if (clientCredits >= g_iCreditsChooserMenuValue5)
		DrawPanelItem(panel, panelCreditsItem5);
	else
		DrawPanelItem(panel, panelCreditsItem5, ITEMDRAW_DISABLED);
	
	char panelCreditsItem6[16];
	Format(panelCreditsItem6, sizeof(panelCreditsItem6), ">%i<", g_iCreditsChooserMenuValue6);
	if (clientCredits >= g_iCreditsChooserMenuValue6)
		DrawPanelItem(panel, panelCreditsItem6);
	else
		DrawPanelItem(panel, panelCreditsItem6, ITEMDRAW_DISABLED);
	
	char panelCreditsItem7[16];
	Format(panelCreditsItem7, sizeof(panelCreditsItem7), ">%i<", g_iCreditsChooserMenuValue7);
	if (clientCredits >= g_iCreditsChooserMenuValue7)
		DrawPanelItem(panel, panelCreditsItem7);
	else
		DrawPanelItem(panel, panelCreditsItem7, ITEMDRAW_DISABLED);
	
	char panelCreditsItem8[16];
	Format(panelCreditsItem8, sizeof(panelCreditsItem8), ">%i<", g_iCreditsChooserMenuValue8);
	if (clientCredits >= g_iCreditsChooserMenuValue8)
		DrawPanelItem(panel, panelCreditsItem8);
	else
		DrawPanelItem(panel, panelCreditsItem8, ITEMDRAW_DISABLED);
	
	DrawPanelItem(panel, "Exit");
	DrawPanelText(panel, "^-.-^-.-^-.-^");
	
	
	SendPanelToClient(panel, client, creditsChooserMenuHandler, 30);
	
	CloseHandle(panel);
}

public int creditsChooserMenuHandler(Handle menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		if (item == 1) {
			openSSPTargetChooserMenu(client, g_iCreditsChooserMenuValue1);
		} else if (item == 2) {
			openSSPTargetChooserMenu(client, g_iCreditsChooserMenuValue2);
		} else if (item == 3) {
			openSSPTargetChooserMenu(client, g_iCreditsChooserMenuValue3);
		} else if (item == 4) {
			openSSPTargetChooserMenu(client, g_iCreditsChooserMenuValue4);
		} else if (item == 5) {
			openSSPTargetChooserMenu(client, g_iCreditsChooserMenuValue5);
		} else if (item == 6) {
			openSSPTargetChooserMenu(client, g_iCreditsChooserMenuValue6);
		} else if (item == 7) {
			openSSPTargetChooserMenu(client, g_iCreditsChooserMenuValue7);
		} else if (item == 8) {
			openSSPTargetChooserMenu(client, g_iCreditsChooserMenuValue8);
		} else if (item == 9) {
			// Exit...
		}
	}
	if (action == MenuAction_End) {
		delete menu;
	}
}

public void openSSPTargetChooserMenu(int client, int amount) {
	int clientCredits = Store_GetClientCredits(client);
	if (clientCredits < amount) {
		CPrintToChat(client, "%t", "notEnoughCredits", ttag);
		return;
	}
	
	if (g_bInGame[client]) {
		CPrintToChat(client, "%t", "alreadyInGame", ttag);
		return;
	}
	
	if (g_bInAccept[client]) {
		CPrintToChat(client, "%t", "pendingInvite", ttag);
		return;
	}
	
	g_iGameAmount[client] = amount;
	
	Handle menu = CreateMenu(targetChooserMenuHandler);
	char menuTitle[255];
	Format(menuTitle, sizeof(menuTitle), "%T", "menu_title_chooseOpponent", client, amount);
	SetMenuTitle(menu, menuTitle);
	
	for (int i = 1; i <= MAXPLAYERS; i++) {
		
		if (i == client)
			continue;
		
		if (!isValidClient(i))
			continue;
		
		if (IsFakeClient(i))
			continue;
		
		if (g_bInGame[i])
			continue;
		
		if (g_bIgnoringInvites[i])
			continue;
		
		if (g_bInAccept[i])
			continue;
		
		if (g_iIgnoringInvitesBellow[i] > amount)
			continue;
		
		if (g_iSSPOnlyDead == 2 && IsPlayerAlive(i))
			continue;
		
		if (Store_GetClientCredits(i) < amount)
			continue;
		
		char Id[128];
		IntToString(i, Id, sizeof(Id));
		
		char targetName[MAX_NAME_LENGTH + 1];
		GetClientName(i, targetName, sizeof(targetName));
		
		AddMenuItem(menu, Id, targetName);
	}
	
	DisplayMenu(menu, client, 30);
}

public int targetChooserMenuHandler(Handle menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		int amount = g_iGameAmount[client];
		if (amount == -1) {
			char logfile[255];
			BuildPath(Path_SM, logfile, sizeof(logfile), "logs/store_ssp.txt");
			LogToFile(logfile, "--------------------------------------------------------------");
			LogToFile(logfile, "FATAL ERROR | winnerMoney == -1 || looserMoney == -1 | FATAL ERROR");
			LogToFile(logfile, "--------------------------------------------------------------");
			CPrintToChat(client, "{green}[{purple}%s{green}] {purple}Internal SSP Error. Contact an Admin", ttag);
			return;
		}
		
		
		char info[64];
		GetMenuItem(menu, item, info, sizeof(info));
		
		int target = StringToInt(info);
		
		if ((!isValidClient(target)) || (!IsClientInGame(target)) || g_bInGame[target] || g_bIgnoringInvites[target] || g_bInAccept[target] || (g_iIgnoringInvitesBellow[target] > amount)) {
			CPrintToChat(client, "%t", "invalidTarget", ttag);
			return;
		}
		
		g_iOponent[client] = GetClientUserId(target);
		challengeClient(client, target, amount);
	}
	if (action == MenuAction_End) {
		delete menu;
	}
}

public void challengeClient(int client, int target, int amount) {
	Panel panel = CreatePanel();
	if (panel == INVALID_HANDLE)
		return;
	char panelTitle[255];
	g_bInAccept[target] = true;
	g_bInAccept[client] = true;
	
	char clientName[MAX_NAME_LENGTH + 8];
	//char targetName[MAX_NAME_LENGTH + 8];
	GetClientName(client, clientName, sizeof(clientName));
	//GetClientName(target, targetName, sizeof(targetName));
	
	Format(panelTitle, sizeof(panelTitle), "%T", "menu_title_challengeReceived", target, clientName, amount);
	SetPanelTitle(panel, panelTitle);
	
	char panelAccept[64];
	Format(panelAccept, sizeof(panelAccept), "%T", "menu_item_doYouAccept", target);
	DrawPanelText(panel, panelAccept);
	
	char panelThink[64];
	Format(panelThink, sizeof(panelThink), "%T", "menu_item_think", target);
	DrawPanelItem(panel, panelThink, ITEMDRAW_DISABLED);
	
	char panelBeforeYou[64];
	Format(panelBeforeYou, sizeof(panelBeforeYou), "%T", "menu_item_beforeYou", target);
	DrawPanelItem(panel, panelBeforeYou, ITEMDRAW_DISABLED);
	
	char panelChoose[64];
	Format(panelChoose, sizeof(panelChoose), "%T", "menu_item_choose", target);
	DrawPanelItem(panel, panelChoose, ITEMDRAW_DISABLED);
	
	
	DrawPanelText(panel, "^-.-^-.-^-.-^");
	
	char panelYes[20];
	Format(panelYes, sizeof(panelYes), "%T", "menu_item_yes", target);
	DrawPanelItem(panel, panelYes);
	
	char panelNo[20];
	Format(panelNo, sizeof(panelNo), "%T", "menu_item_no", target);
	DrawPanelItem(panel, panelNo);
	
	DrawPanelText(panel, "^-.-^-.-^-.-^");
	
	g_iOponent[target] = GetClientUserId(client);
	
	SendPanelToClient(panel, target, challengeAcceptHandler, 30);
}

public int challengeAcceptHandler(Handle menu, MenuAction action, int client, int item)
{
	if (!IsClientConnected(client))
		return;
	int origin = GetClientOfUserId(g_iOponent[client]);
	int destination = client;
	int amount = g_iGameAmount[origin];
	
	char destinationName[MAX_NAME_LENGTH + 1];
	GetClientName(destination, destinationName, sizeof(destinationName));
	if (action == MenuAction_Select)
	{
		if (item == 4) {
			startSSP(origin, destination, amount);
		} else if (item == 5) {
			g_iOponent[origin] = -1;
			g_iOponent[destination] = -1;
			g_iGameAmount[origin] = -1;
			g_bInAccept[origin] = false;
			g_bInAccept[destination] = false;
			if (isValidClient(origin))
				CPrintToChat(origin, "%t", "requestDenied", ttag, destinationName);
		}
	}
	if (action == MenuAction_Cancel) {
		if (item == MenuCancel_Timeout) {
			g_bInAccept[origin] = false;
			g_bInAccept[destination] = false;
			if (isValidClient(origin))
				CPrintToChat(origin, "%t", "opponentNotRespondInTime", ttag, destinationName);
			if (isValidClient(destination))
				CPrintToChat(destination, "%t", "notRespondInTime", ttag);
		} else if (item == MenuCancel_Disconnected) {
			g_bInAccept[origin] = false;
			g_bInAccept[destination] = false;
			if (isValidClient(origin))
				CPrintToChat(origin, "%t", "opponentDisconnected", ttag, destinationName);
		} else if (item == MenuCancel_NoDisplay || item == MenuCancel_Interrupted) {
			g_bInAccept[origin] = false;
			g_bInAccept[destination] = false;
			if (isValidClient(origin))
				CPrintToChat(origin, "%t", "opponentExitedMenu", ttag, destinationName);
		}
	}
	if (action == MenuAction_End) {
		delete menu;
	}
}

public void startSSP(int origin, int destination, int amount) {
	g_bInAccept[origin] = false;
	g_bInAccept[destination] = false;
	g_bInGame[origin] = true;
	g_bInGame[destination] = true;
	g_iGameAmount[destination] = amount;
	
	Panel playPanel = CreatePanel();
	char panelTitleChoose[64];
	Format(panelTitleChoose, sizeof(panelTitleChoose), "%T", "menu_title_chooseItem", LANG_SERVER);
	SetPanelTitle(playPanel, panelTitleChoose);
	
	DrawPanelText(playPanel, "^-.-^-.-^-.-^");
	
	char panelScissors[64];
	Format(panelScissors, sizeof(panelScissors), "%T", "menu_item_scissors", LANG_SERVER);
	DrawPanelItem(playPanel, panelScissors);
	
	char panelRock[64];
	Format(panelRock, sizeof(panelRock), "%T", "menu_item_rock", LANG_SERVER);
	DrawPanelItem(playPanel, panelRock);
	
	char panelPaper[64];
	Format(panelPaper, sizeof(panelPaper), "%T", "menu_item_paper", LANG_SERVER);
	DrawPanelItem(playPanel, panelPaper);
	
	DrawPanelText(playPanel, "^-.-^-.-^-.-^");
	
	SendPanelToClient(playPanel, origin, sspGameHandler, 60);
	SendPanelToClient(playPanel, destination, sspGameHandler, 60);
}

public int sspGameHandler(Handle menu, MenuAction action, int client, int item)
{
	int target = GetClientOfUserId(g_iOponent[client]);
	if (action == MenuAction_Select)
	{
		if (item == 1) {
			g_eSSPItem[client] = Schere;
			lookupGame(client);
		} else if (item == 2) {
			g_eSSPItem[client] = Stein;
			lookupGame(client);
		} else if (item == 3) {
			g_eSSPItem[client] = Papier;
			lookupGame(client);
		}
	}
	if (action == MenuAction_Cancel) {
		if (item == MenuCancel_Timeout) {
			endSSP(client, client);
			CPrintToChat(client, "%t", "noItemChosenInTime", ttag);
		} else if (item == MenuCancel_Disconnected) {
			// ??
		} else if (item == MenuCancel_NoDisplay || item == MenuCancel_Interrupted) {
			endSSP(client, target);
			char clientName[MAX_NAME_LENGTH + 8];
			GetClientName(client, clientName, sizeof(clientName));
			if (isValidClient(target))
				CPrintToChat(target, "%t", "opponentCancelledMenu", ttag, clientName);
			if (isValidClient(client))
				CPrintToChat(client, "%t", "cancelledMenu", ttag);
		}
	}
	if (action == MenuAction_End) {
		delete menu;
	}
}

public void lookupGame(int client) {
	int client2 = GetClientOfUserId(g_iOponent[client]);
	if (g_eSSPItem[client] != None && g_eSSPItem[client2] != None) {
		if (g_eSSPItem[client] == Schere && g_eSSPItem[client2] == Schere)
			finishSSP(0, client, client2);
		if (g_eSSPItem[client] == Stein && g_eSSPItem[client2] == Stein)
			finishSSP(0, client, client2);
		if (g_eSSPItem[client] == Papier && g_eSSPItem[client2] == Papier)
			finishSSP(0, client, client2);
		if (g_eSSPItem[client] == Schere && g_eSSPItem[client2] == Stein)
			finishSSP(1, client2, client);
		if (g_eSSPItem[client] == Stein && g_eSSPItem[client2] == Schere)
			finishSSP(1, client, client2);
		if (g_eSSPItem[client] == Schere && g_eSSPItem[client2] == Papier)
			finishSSP(1, client, client2);
		if (g_eSSPItem[client] == Papier && g_eSSPItem[client2] == Schere)
			finishSSP(1, client2, client);
		if (g_eSSPItem[client] == Stein && g_eSSPItem[client2] == Papier)
			finishSSP(1, client2, client);
		if (g_eSSPItem[client] == Papier && g_eSSPItem[client2] == Stein)
			finishSSP(1, client, client2);
	}
}

public void finishSSP(int state, int winner, int looser) {
	char logfile[255];
	BuildPath(Path_SM, logfile, sizeof(logfile), "logs/store_ssp.txt");
	
	if (g_iGameAmount[winner] != g_iGameAmount[looser]) {
		LogToFile(logfile, "--------------------------------------------------------");
		LogToFile(logfile, "FATAL ERROR | winnerMoney != looserMoney | FATAL ERROR");
		LogToFile(logfile, "--------------------------------------------------------");
		PrintToChat(winner, "{green}[{purple}%s{green}] {purple}Internal SSP Error. Contact an Admin");
		PrintToChat(looser, "{green}[{purple}%s{green}] {purple}Internal SSP Error. Contact an Admin");
		return;
	}
	
	if (g_iGameAmount[winner] == -1 || g_iGameAmount[looser] == -1) {
		LogToFile(logfile, "--------------------------------------------------------");
		LogToFile(logfile, "FATAL ERROR | winnerMoney or looserMoney == -1 | FATAL ERROR");
		LogToFile(logfile, "--------------------------------------------------------");
		PrintToChat(winner, "{green}[{purple}%s{green}] {purple}Internal SSP Error. Contact an Admin");
		PrintToChat(looser, "{green}[{purple}%s{green}] {purple}Internal SSP Error. Contact an Admin");
		return;
	}
	
	int testClient1 = GetClientOfUserId(g_iOponent[winner]);
	int testClient2 = GetClientOfUserId(g_iOponent[looser]);
	if (testClient1 != looser || testClient2 != winner) {
		LogToFile(logfile, "--------------------------------------------------------");
		LogToFile(logfile, "FATAL ERROR | game async Error | FATAL ERROR");
		LogToFile(logfile, "--------------------------------------------------------");
		PrintToChat(winner, "{green}[{purple}%s{green}] {purple}Internal SSP Error. Contact an Admin");
		PrintToChat(looser, "{green}[{purple}%s{green}] {purple}Internal SSP Error. Contact an Admin");
		return;
	}
	
	
	char haveValue1[64];
	char haveValue2[64];
	
	char winnerName[MAX_NAME_LENGTH + 1];
	char looserName[MAX_NAME_LENGTH + 1];
	GetClientName(winner, winnerName, sizeof(winnerName));
	GetClientName(looser, looserName, sizeof(looserName));
	
	char winner_id[20];
	GetClientAuthId(winner, AuthId_Steam2, winner_id, sizeof(winner_id));
	char looser_id[20];
	GetClientAuthId(looser, AuthId_Steam2, looser_id, sizeof(looser_id));
	
	if (g_eSSPItem[winner] == Schere)
		Format(haveValue1, sizeof(haveValue2), "%T", "item_scissors", winner);
	else if (g_eSSPItem[winner] == Stein)
		Format(haveValue1, sizeof(haveValue2), "%T", "item_rock", winner);
	else if (g_eSSPItem[winner] == Papier)
		Format(haveValue1, sizeof(haveValue2), "%T", "item_paper", winner);
	
	if (g_eSSPItem[looser] == Schere)
		Format(haveValue2, sizeof(haveValue2), "%T", "item_scissors", looser);
	else if (g_eSSPItem[looser] == Stein)
		Format(haveValue2, sizeof(haveValue2), "%T", "item_rock", looser);
	else if (g_eSSPItem[looser] == Papier)
		Format(haveValue2, sizeof(haveValue2), "%T", "item_paper", looser);
	
	int looserCredits = Store_GetClientCredits(looser);
	if ((looserCredits - g_iGameAmount[looser]) < 0) {
		CPrintToChat(winner, "{green}[{purple}%s{green}] {purple} Your Oponent Cheated. Stopping Game.", ttag);
		CPrintToChat(looser, "{green}[{purple}%s{green}] {purple} Doing this again may get your Permanently banned. Stopping Game.", ttag);
		LogToFile(logfile, ">>>>>>>>>>>>>>>>SSP EXPLOID BY !looser! | Winner: %s (%s), Looser: %s (%s) | Amount: %i | %i | DIFF: %i", winnerName, winner_id, looserName, looser_id, g_iGameAmount[winner], g_iGameAmount[looser], looserCredits);
		endSSP(winner, looser);
		return;
	}
	
	int winnerCredits = Store_GetClientCredits(winner);
	if ((winnerCredits - g_iGameAmount[winner]) < 0) {
		CPrintToChat(looser, "{green}[{purple}%s{green}] {purple} Your Oponent Cheated. Stopping Game.", ttag);
		CPrintToChat(winner, "{green}[{purple}%s{green}] {purple} Doing this again may get your Permanently banned. Stopping Game.", ttag);
		LogToFile(logfile, ">>>>>>>>>>>>>>>>SSP EXPLOID BY !Winner! | Winner: %s (%s), Looser: %s (%s) | Amount: %i | %i | DIFF: %i", winnerName, winner_id, looserName, looser_id, g_iGameAmount[winner], g_iGameAmount[looser], winnerCredits);
		endSSP(winner, looser);
		return;
	}
	
	if (state == 0) {
		CPrintToChat(winner, "%t", "sameChoice", ttag, haveValue1);
		CPrintToChat(looser, "%t", "sameChoice", ttag, haveValue2);
		
		LogToFile(logfile, "SSP END | TIE | Player[1]: %s (%s), Player[2]: %s (%s) | Amount: %i | %i", winnerName, winner_id, looserName, looser_id, g_iGameAmount[winner], g_iGameAmount[looser]);
		endSSP(winner, looser);
	} else if (state == 1) {
		int winAmount = RoundToNearest(g_iGameAmount[winner] * g_fHouseMargin);
		
		Store_SetClientCredits(winner, Store_GetClientCredits(winner) + winAmount);
		Store_SetClientCredits(looser, Store_GetClientCredits(looser) - g_iGameAmount[looser]);
		
		CPrintToChat(winner, "%t", "win", ttag, haveValue1, looserName, haveValue2, winAmount);
		CPrintToChat(looser, "%t", "lose", ttag, haveValue2, winnerName, haveValue1, g_iGameAmount[looser]);
		
		
		LogToFile(logfile, "SSP END | Winner: %s (%s), Looser: %s (%s) | Amount: %i | %i | House Margin: %f | Corrected: %i", winnerName, winner_id, looserName, looser_id, g_iGameAmount[winner], g_iGameAmount[looser], g_fHouseMargin, winAmount);
		endSSP(winner, looser);
	}
}

public void endSSP(int client1, int client2) {
	g_bInGame[client1] = false;
	g_eSSPItem[client1] = None;
	g_iOponent[client1] = -1;
	g_iGameAmount[client1] = -1;
	g_bInAccept[client1] = false;
	
	g_bInGame[client2] = false;
	g_eSSPItem[client2] = None;
	g_iOponent[client2] = -1;
	g_iGameAmount[client2] = -1;
	g_bInAccept[client2] = false;
}

public Action chatHook(int client, int args)
{
	if (!g_bBlockChatCommand)
		return Plugin_Continue;
	
	char text[256];
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);
	
	if (StrContains(text, "!ssp", false) != -1)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public void SQLErrorCheckCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (!StrEqual(error, ""))
		LogError(error);
}

public void sql_CheckIfSSPBlockedCallback(Handle owner, Handle hndl, const char[] error, any datapack)
{
	int client;
	if (datapack != INVALID_HANDLE)
	{
		ResetPack(datapack);
		client = ReadPackCell(datapack);
		CloseHandle(datapack);
	}
	
	if (SQL_FetchRow(hndl)) {
		int result = SQL_FetchInt(hndl, 0);
		if (result != 0) {
			g_bIgnoringInvites[client] = true;
		}
	}
}

stock bool isValidClient(int client)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client))
		return false;
	
	return true;
}

public void AliveItem_OnMapStart() {  }
public void AliveItem_Reset() {  }
public void AliveItem_Remove(int client, int id) {  }

public bool AliveItem_Config(Handle kv, int itemid)
{
	Store_SetDataIndex(itemid, 0);
	return true;
}

public int AliveItem_Equip(int client, int id)
{
	return -1;
} 