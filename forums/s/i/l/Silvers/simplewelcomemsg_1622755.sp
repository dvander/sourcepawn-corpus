/* 
 * Simple Welcome Message Plugin
 * This plugin display simple welcome message to players on chat, panel or hint
 *
 * ConVars:
 * sm_swm_enable 		- Enable/Disable Plugin
 * sm_swm_timer			- When the message should be displayed after the player join on the server (in seconds)
 * sm_swm_messagelines	- How many lines plugin should display on chat. 
 * sm_swm_panellines	- How many lines plugin should display on panel.
 *
 *
 * Colored Message Example:
 * {green}Hello! {lightgreen}Don't be shy! Say {green}Hello {lightgreen}to other players.
 *
 * Color list:
 * http://forums.alliedmods.net/showthread.php?t=96831
 *
 * Changelog:
 * Version 1.0 (24.07.09)
 * - Initial Relase
 *
 * Version 1.1 (26.07.09)
 * - More lines for chat messages
 * - Max lines limits for L4D and Insurgency
 *
 * Version 1.2 (17.08.09)
 * - Added Panel and Hint Message
 *
 * Version 1.2a(31.12.11)
 * - Fixed translations not working.
 * 
 * TODO
 * - Add commands to force message display do players (by Admins)
 *
 */

#include <sourcemod>
#include <colors>

#define PLUGIN_VERSION "1.2b"

#define CHAT 1
#define PANEL 2
#define HINT 4

new Handle:g_Cvar_PluginEnable = INVALID_HANDLE;
new Handle:g_Cvar_PluginTimer = INVALID_HANDLE;
new Handle:g_Cvar_MessageLines = INVALID_HANDLE;
new Handle:g_Cvar_PanelLines = INVALID_HANDLE;
new Handle:g_Cvar_MsgType = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Simple Welcome Message",
	author = "Zuko",
	description = "Display simple welcome msg.",
	version = PLUGIN_VERSION,
	url = "http://zuko.isports.pl"
}

public OnPluginStart()
{
	CreateConVar("swm_version", PLUGIN_VERSION, "Simple Welcome Message Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_Cvar_PluginEnable = 		CreateConVar("sm_swm_enable", "1", "Enable/Disable Plugin", _, true, 0.0, true, 1.0);
	g_Cvar_MsgType = 			CreateConVar("sm_swm_msgtype", "7", "Sets Message Type: 1 - Chat , 2 - Panel , 4 - Hint (You can combine more than one)", _, true, 0.0, true, 7.0);
	g_Cvar_PanelLines = 		CreateConVar("sm_swm_panellines", "0", "How many lines plugin should display in panels.", _, true, 0.0, true, 13.0);
	g_Cvar_PluginTimer = 		CreateConVar("sm_swm_timer", "25.0", "When the message should be displayed after the player join on the server (in seconds)");
	
	LoadTranslations("simplewelcomemsg.phrases");
	AutoExecConfig(true, "plugin.simplewelcomemsg");

	new String:game_mod[32];
	GetGameFolderName(game_mod, sizeof(game_mod));
	if (strcmp(game_mod, "insurgency", false) == 0)
	{
		// LogAction(0, -1, "%T", "Insurgency", LANG_SERVER);
		g_Cvar_MessageLines = CreateConVar("sm_swm_messagelines", "0", "How many lines plugin should display.", _, true, 0.0, true, 5.0);
	}	
	else if (strcmp(game_mod, "left4dead", false) == 0)
	{
		// LogAction(0, -1, "%T", "L4D", LANG_SERVER);
		g_Cvar_MessageLines = CreateConVar("sm_swm_messagelines", "0", "How many lines plugin should display.", _, true, 0.0, true, 6.0);
	}
	else
	{
		// LogAction(0, -1, "%T", "Other", LANG_SERVER);
		g_Cvar_MessageLines = CreateConVar("sm_swm_messagelines", "0", "How many lines plugin should display.", _, true, 0.0, true, 7.0);
	}
}

public OnClientPostAdminCheck(client)
{
	if (GetConVarInt(g_Cvar_PluginEnable) == 1)
	{
		CreateTimer (GetConVarFloat(g_Cvar_PluginTimer), Timer_Welcome, GetClientUserId(client));
	}
}
	
public Action:Timer_Welcome(Handle:timer, any:client)
{
	client = GetClientOfUserId(client);
	if( client > 0 && IsClientInGame(client) )
	{
		new msgbits = GetConVarInt(g_Cvar_MsgType);
		if (msgbits & CHAT)
			ChatMessagesDisplay(client);
		if (msgbits & PANEL)
			PanelMessageDisplay(client);
		if (msgbits & HINT)
			HintMessageDisplay(client);
	}
}

ChatMessagesDisplay(client)
{
	SetGlobalTransTarget(client);

	switch(GetConVarInt(g_Cvar_MessageLines))
	{
		case 0:
		{
			CPrintToChat (client, "%t", "WelcomeMsg1", client);
		}
		case 1:
		{
			CPrintToChat (client, "%t", "WelcomeMsg1", client);
			CPrintToChat (client, "%t", "WelcomeMsg2", client);
		}
		case 2:
		{
			CPrintToChat (client, "%t", "WelcomeMsg1", client);
			CPrintToChat (client, "%t", "WelcomeMsg2", client);
			CPrintToChat (client, "%t", "WelcomeMsg3", client);
		}
		case 3:
		{
			CPrintToChat (client, "%t", "WelcomeMsg1", client);
			CPrintToChat (client, "%t", "WelcomeMsg2", client);
			CPrintToChat (client, "%t", "WelcomeMsg3", client);
			CPrintToChat (client, "%t", "WelcomeMsg4", client);
		}
		case 4:
		{
			CPrintToChat (client, "%t", "WelcomeMsg1", client);
			CPrintToChat (client, "%t", "WelcomeMsg2", client);
			CPrintToChat (client, "%t", "WelcomeMsg3", client);
			CPrintToChat (client, "%t", "WelcomeMsg4", client);
			CPrintToChat (client, "%t", "WelcomeMsg5", client);
		}
		case 5:
		{
			CPrintToChat (client, "%t", "WelcomeMsg1", client);
			CPrintToChat (client, "%t", "WelcomeMsg2", client);
			CPrintToChat (client, "%t", "WelcomeMsg3", client);
			CPrintToChat (client, "%t", "WelcomeMsg4", client);
			CPrintToChat (client, "%t", "WelcomeMsg5", client);
			CPrintToChat (client, "%t", "WelcomeMsg6", client);
		}
		case 6:
		{
			CPrintToChat (client, "%t", "WelcomeMsg1", client);
			CPrintToChat (client, "%t", "WelcomeMsg2", client);
			CPrintToChat (client, "%t", "WelcomeMsg3", client);
			CPrintToChat (client, "%t", "WelcomeMsg4", client);
			CPrintToChat (client, "%t", "WelcomeMsg5", client);
			CPrintToChat (client, "%t", "WelcomeMsg6", client);
			CPrintToChat (client, "%t", "WelcomeMsg7", client);
		}
		case 7:
		{
			CPrintToChat (client, "%t", "WelcomeMsg1", client);
			CPrintToChat (client, "%t", "WelcomeMsg2", client);
			CPrintToChat (client, "%t", "WelcomeMsg3", client);
			CPrintToChat (client, "%t", "WelcomeMsg4", client);
			CPrintToChat (client, "%t", "WelcomeMsg5", client);
			CPrintToChat (client, "%t", "WelcomeMsg6", client);
			CPrintToChat (client, "%t", "WelcomeMsg7", client);
			CPrintToChat (client, "%t", "WelcomeMsg8", client);
		}
	}
}

PanelMessageDisplay(client) 
{
	decl String:message1[255], String:message2[255], String:message3[255], String:message4[255], String:message5[255], String:message6[255], String:message7[255], String:message8[255];
	decl String:message9[255], String:message10[255], String:message11[255], String:message12[255], String:message13[255], String:message14[255], String:message15[255];
	decl String:closepanel[255];
	
	new Handle:WelcomePanel = CreatePanel(INVALID_HANDLE);
	
	switch(GetConVarInt(g_Cvar_PanelLines))
	{
		case 0:
		{
			Format(message1, sizeof(message1), "%T", "PanelTitle", client, client);
			SetPanelTitle(WelcomePanel, message1);
			Format(message2, sizeof(message2), "%T", "PanelLine1", client, client);
			DrawPanelText(WelcomePanel, message2);
			Format(closepanel, sizeof(closepanel), "%T", "PanelClose", client, client);
			DrawPanelText(WelcomePanel, closepanel);
			SendPanelToClient(WelcomePanel, client, NullMenuHandler, 60);
			CloseHandle(WelcomePanel);
		}
		case 1:
		{
			Format(message1, sizeof(message1), "%T", "PanelTitle", client, client);
			SetPanelTitle(WelcomePanel, message1);
			Format(message2, sizeof(message2), "%T", "PanelLine1", client, client);
			DrawPanelText(WelcomePanel, message2);
			Format(message3, sizeof(message3), "%T", "PanelLine2", client, client);
			DrawPanelText(WelcomePanel, message3);
			Format(closepanel, sizeof(closepanel), "%T", "PanelClose", client, client);
			DrawPanelText(WelcomePanel, closepanel);
			SendPanelToClient(WelcomePanel, client, NullMenuHandler, 60);
			CloseHandle(WelcomePanel);
		}
		case 2:
		{
			Format(message1, sizeof(message1), "%T", "PanelTitle", client, client);
			SetPanelTitle(WelcomePanel, message1);
			Format(message2, sizeof(message2), "%T", "PanelLine1", client, client);
			DrawPanelText(WelcomePanel, message2);
			Format(message3, sizeof(message3), "%T", "PanelLine2", client, client);
			DrawPanelText(WelcomePanel, message3);
			Format(message4, sizeof(message4), "%T", "PanelLine3", client, client);
			DrawPanelText(WelcomePanel, message4);
			Format(closepanel, sizeof(closepanel), "%T", "PanelClose", client, client);
			DrawPanelText(WelcomePanel, closepanel);
			SendPanelToClient(WelcomePanel, client, NullMenuHandler, 60);
			CloseHandle(WelcomePanel);
		}
		case 3:
		{
			Format(message1, sizeof(message1), "%T", "PanelTitle", client, client);
			SetPanelTitle(WelcomePanel, message1);
			Format(message2, sizeof(message2), "%T", "PanelLine1", client, client);
			DrawPanelText(WelcomePanel, message2);
			Format(message3, sizeof(message3), "%T", "PanelLine2", client, client);
			DrawPanelText(WelcomePanel, message3);
			Format(message4, sizeof(message4), "%T", "PanelLine3", client, client);
			DrawPanelText(WelcomePanel, message4);
			Format(message5, sizeof(message5), "%T", "PanelLine4", client, client);
			DrawPanelText(WelcomePanel, message5);
			Format(closepanel, sizeof(closepanel), "%T", "PanelClose", client, client);
			DrawPanelText(WelcomePanel, closepanel);
			SendPanelToClient(WelcomePanel, client, NullMenuHandler, 60);
			CloseHandle(WelcomePanel);
		}
		case 4:
		{
			Format(message1, sizeof(message1), "%T", "PanelTitle", client, client);
			SetPanelTitle(WelcomePanel, message1);
			Format(message2, sizeof(message2), "%T", "PanelLine1", client, client);
			DrawPanelText(WelcomePanel, message2);
			Format(message3, sizeof(message3), "%T", "PanelLine2", client, client);
			DrawPanelText(WelcomePanel, message3);
			Format(message4, sizeof(message4), "%T", "PanelLine3", client, client);
			DrawPanelText(WelcomePanel, message4);
			Format(message5, sizeof(message5), "%T", "PanelLine4", client, client);
			DrawPanelText(WelcomePanel, message5);
			Format(message6, sizeof(message6), "%T", "PanelLine5", client, client);
			DrawPanelText(WelcomePanel, message6);
			Format(closepanel, sizeof(closepanel), "%T", "PanelClose", client, client);
			DrawPanelText(WelcomePanel, closepanel);
			SendPanelToClient(WelcomePanel, client, NullMenuHandler, 60);
			CloseHandle(WelcomePanel);
		}
		case 5:
		{
			Format(message1, sizeof(message1), "%T", "PanelTitle", client, client);
			SetPanelTitle(WelcomePanel, message1);
			Format(message2, sizeof(message2), "%T", "PanelLine1", client, client);
			DrawPanelText(WelcomePanel, message2);
			Format(message3, sizeof(message3), "%T", "PanelLine2", client, client);
			DrawPanelText(WelcomePanel, message3);
			Format(message4, sizeof(message4), "%T", "PanelLine3", client, client);
			DrawPanelText(WelcomePanel, message4);
			Format(message5, sizeof(message5), "%T", "PanelLine4", client, client);
			DrawPanelText(WelcomePanel, message5);
			Format(message6, sizeof(message6), "%T", "PanelLine5", client, client);
			DrawPanelText(WelcomePanel, message6);
			Format(message7, sizeof(message7), "%T", "PanelLine6", client, client);
			DrawPanelText(WelcomePanel, message7);
			Format(closepanel, sizeof(closepanel), "%T", "PanelClose", client, client);
			DrawPanelText(WelcomePanel, closepanel);
			SendPanelToClient(WelcomePanel, client, NullMenuHandler, 60);
			CloseHandle(WelcomePanel);
		}
		case 6:
		{
			Format(message1, sizeof(message1), "%T", "PanelTitle", client, client);
			SetPanelTitle(WelcomePanel, message1);
			Format(message2, sizeof(message2), "%T", "PanelLine1", client, client);
			DrawPanelText(WelcomePanel, message2);
			Format(message3, sizeof(message3), "%T", "PanelLine2", client, client);
			DrawPanelText(WelcomePanel, message3);
			Format(message4, sizeof(message4), "%T", "PanelLine3", client, client);
			DrawPanelText(WelcomePanel, message4);
			Format(message5, sizeof(message5), "%T", "PanelLine4", client, client);
			DrawPanelText(WelcomePanel, message5);
			Format(message6, sizeof(message6), "%T", "PanelLine5", client, client);
			DrawPanelText(WelcomePanel, message6);
			Format(message7, sizeof(message7), "%T", "PanelLine6", client, client);
			DrawPanelText(WelcomePanel, message7);
			Format(message8, sizeof(message8), "%T", "PanelLine7", client, client);
			DrawPanelText(WelcomePanel, message8);
			Format(closepanel, sizeof(closepanel), "%T", "PanelClose", client, client);
			DrawPanelText(WelcomePanel, closepanel);
			SendPanelToClient(WelcomePanel, client, NullMenuHandler, 60);
			CloseHandle(WelcomePanel);
		}
		case 7:
		{
			Format(message1, sizeof(message1), "%T", "PanelTitle", client, client);
			SetPanelTitle(WelcomePanel, message1);
			Format(message2, sizeof(message2), "%T", "PanelLine1", client, client);
			DrawPanelText(WelcomePanel, message2);
			Format(message3, sizeof(message3), "%T", "PanelLine2", client, client);
			DrawPanelText(WelcomePanel, message3);
			Format(message4, sizeof(message4), "%T", "PanelLine3", client, client);
			DrawPanelText(WelcomePanel, message4);
			Format(message5, sizeof(message5), "%T", "PanelLine4", client, client);
			DrawPanelText(WelcomePanel, message5);
			Format(message6, sizeof(message6), "%T", "PanelLine5", client, client);
			DrawPanelText(WelcomePanel, message6);
			Format(message7, sizeof(message7), "%T", "PanelLine6", client, client);
			DrawPanelText(WelcomePanel, message7);
			Format(message8, sizeof(message8), "%T", "PanelLine7", client, client);
			DrawPanelText(WelcomePanel, message8);
			Format(message9, sizeof(message9), "%T", "PanelLine8", client, client);
			DrawPanelText(WelcomePanel, message9);
			Format(closepanel, sizeof(closepanel), "%T", "PanelClose", client, client);
			DrawPanelText(WelcomePanel, closepanel);
			SendPanelToClient(WelcomePanel, client, NullMenuHandler, 60);
			CloseHandle(WelcomePanel);
		}
		case 8:
		{
			Format(message1, sizeof(message1), "%T", "PanelTitle", client, client);
			SetPanelTitle(WelcomePanel, message1);
			Format(message2, sizeof(message2), "%T", "PanelLine1", client, client);
			DrawPanelText(WelcomePanel, message2);
			Format(message3, sizeof(message3), "%T", "PanelLine2", client, client);
			DrawPanelText(WelcomePanel, message3);
			Format(message4, sizeof(message4), "%T", "PanelLine3", client, client);
			DrawPanelText(WelcomePanel, message4);
			Format(message5, sizeof(message5), "%T", "PanelLine4", client, client);
			DrawPanelText(WelcomePanel, message5);
			Format(message6, sizeof(message6), "%T", "PanelLine5", client, client);
			DrawPanelText(WelcomePanel, message6);
			Format(message7, sizeof(message7), "%T", "PanelLine6", client, client);
			DrawPanelText(WelcomePanel, message7);
			Format(message8, sizeof(message8), "%T", "PanelLine7", client, client);
			DrawPanelText(WelcomePanel, message8);
			Format(message9, sizeof(message9), "%T", "PanelLine8", client, client);
			DrawPanelText(WelcomePanel, message9);
			Format(message10, sizeof(message10), "%T", "PanelLine9", client, client);
			DrawPanelText(WelcomePanel, message10);
			Format(closepanel, sizeof(closepanel), "%T", "PanelClose", client, client);
			DrawPanelText(WelcomePanel, closepanel);
			SendPanelToClient(WelcomePanel, client, NullMenuHandler, 60);
			CloseHandle(WelcomePanel);
		}
		case 9:
		{
			Format(message1, sizeof(message1), "%T", "PanelTitle", client, client);
			SetPanelTitle(WelcomePanel, message1);
			Format(message2, sizeof(message2), "%T", "PanelLine1", client, client);
			DrawPanelText(WelcomePanel, message2);
			Format(message3, sizeof(message3), "%T", "PanelLine2", client, client);
			DrawPanelText(WelcomePanel, message3);
			Format(message4, sizeof(message4), "%T", "PanelLine3", client, client);
			DrawPanelText(WelcomePanel, message4);
			Format(message5, sizeof(message5), "%T", "PanelLine4", client, client);
			DrawPanelText(WelcomePanel, message5);
			Format(message6, sizeof(message6), "%T", "PanelLine5", client, client);
			DrawPanelText(WelcomePanel, message6);
			Format(message7, sizeof(message7), "%T", "PanelLine6", client, client);
			DrawPanelText(WelcomePanel, message7);
			Format(message8, sizeof(message8), "%T", "PanelLine7", client, client);
			DrawPanelText(WelcomePanel, message8);
			Format(message9, sizeof(message9), "%T", "PanelLine8", client, client);
			DrawPanelText(WelcomePanel, message9);
			Format(message10, sizeof(message10), "%T", "PanelLine9", client, client);
			DrawPanelText(WelcomePanel, message10);
			Format(message11, sizeof(message11), "%T", "PanelLine10", client, client);
			DrawPanelText(WelcomePanel, message11);
			Format(closepanel, sizeof(closepanel), "%T", "PanelClose", client, client);
			DrawPanelText(WelcomePanel, closepanel);
			SendPanelToClient(WelcomePanel, client, NullMenuHandler, 60);
			CloseHandle(WelcomePanel);
		}
		case 10:
		{
			Format(message1, sizeof(message1), "%T", "PanelTitle", client, client);
			SetPanelTitle(WelcomePanel, message1);
			Format(message2, sizeof(message2), "%T", "PanelLine1", client, client);
			DrawPanelText(WelcomePanel, message2);
			Format(message3, sizeof(message3), "%T", "PanelLine2", client, client);
			DrawPanelText(WelcomePanel, message3);
			Format(message4, sizeof(message4), "%T", "PanelLine3", client, client);
			DrawPanelText(WelcomePanel, message4);
			Format(message5, sizeof(message5), "%T", "PanelLine4", client, client);
			DrawPanelText(WelcomePanel, message5);
			Format(message6, sizeof(message6), "%T", "PanelLine5", client, client);
			DrawPanelText(WelcomePanel, message6);
			Format(message7, sizeof(message7), "%T", "PanelLine6", client, client);
			DrawPanelText(WelcomePanel, message7);
			Format(message8, sizeof(message8), "%T", "PanelLine7", client, client);
			DrawPanelText(WelcomePanel, message8);
			Format(message9, sizeof(message9), "%T", "PanelLine8", client, client);
			DrawPanelText(WelcomePanel, message9);
			Format(message10, sizeof(message10), "%T", "PanelLine9", client, client);
			DrawPanelText(WelcomePanel, message10);
			Format(message11, sizeof(message11), "%T", "PanelLine10", client, client);
			DrawPanelText(WelcomePanel, message11);
			Format(message12, sizeof(message12), "%T", "PanelLine11", client, client);
			DrawPanelText(WelcomePanel, message12);
			Format(closepanel, sizeof(closepanel), "%T", "PanelClose", client, client);
			DrawPanelText(WelcomePanel, closepanel);
			SendPanelToClient(WelcomePanel, client, NullMenuHandler, 60);
			CloseHandle(WelcomePanel);
		}
		case 11:
		{
			Format(message1, sizeof(message1), "%T", "PanelTitle", client, client);
			SetPanelTitle(WelcomePanel, message1);
			Format(message2, sizeof(message2), "%T", "PanelLine1", client, client);
			DrawPanelText(WelcomePanel, message2);
			Format(message3, sizeof(message3), "%T", "PanelLine2", client, client);
			DrawPanelText(WelcomePanel, message3);
			Format(message4, sizeof(message4), "%T", "PanelLine3", client, client);
			DrawPanelText(WelcomePanel, message4);
			Format(message5, sizeof(message5), "%T", "PanelLine4", client, client);
			DrawPanelText(WelcomePanel, message5);
			Format(message6, sizeof(message6), "%T", "PanelLine5", client, client);
			DrawPanelText(WelcomePanel, message6);
			Format(message7, sizeof(message7), "%T", "PanelLine6", client, client);
			DrawPanelText(WelcomePanel, message7);
			Format(message8, sizeof(message8), "%T", "PanelLine7", client, client);
			DrawPanelText(WelcomePanel, message8);
			Format(message9, sizeof(message9), "%T", "PanelLine8", client, client);
			DrawPanelText(WelcomePanel, message9);
			Format(message10, sizeof(message10), "%T", "PanelLine9", client, client);
			DrawPanelText(WelcomePanel, message10);
			Format(message11, sizeof(message11), "%T", "PanelLine10", client, client);
			DrawPanelText(WelcomePanel, message11);
			Format(message12, sizeof(message12), "%T", "PanelLine11", client, client);
			DrawPanelText(WelcomePanel, message12);
			Format(message13, sizeof(message13), "%T", "PanelLine12", client, client);
			DrawPanelText(WelcomePanel, message13);
			Format(closepanel, sizeof(closepanel), "%T", "PanelClose", client, client);
			DrawPanelText(WelcomePanel, closepanel);
			SendPanelToClient(WelcomePanel, client, NullMenuHandler, 60);
			CloseHandle(WelcomePanel);
		}
		case 12:
		{
			Format(message1, sizeof(message1), "%T", "PanelTitle", client, client);
			SetPanelTitle(WelcomePanel, message1);
			Format(message2, sizeof(message2), "%T", "PanelLine1", client, client);
			DrawPanelText(WelcomePanel, message2);
			Format(message3, sizeof(message3), "%T", "PanelLine2", client, client);
			DrawPanelText(WelcomePanel, message3);
			Format(message4, sizeof(message4), "%T", "PanelLine3", client, client);
			DrawPanelText(WelcomePanel, message4);
			Format(message5, sizeof(message5), "%T", "PanelLine4", client, client);
			DrawPanelText(WelcomePanel, message5);
			Format(message6, sizeof(message6), "%T", "PanelLine5", client, client);
			DrawPanelText(WelcomePanel, message6);
			Format(message7, sizeof(message7), "%T", "PanelLine6", client, client);
			DrawPanelText(WelcomePanel, message7);
			Format(message8, sizeof(message8), "%T", "PanelLine7", client, client);
			DrawPanelText(WelcomePanel, message8);
			Format(message9, sizeof(message9), "%T", "PanelLine8", client, client);
			DrawPanelText(WelcomePanel, message9);
			Format(message10, sizeof(message10), "%T", "PanelLine9", client, client);
			DrawPanelText(WelcomePanel, message10);
			Format(message11, sizeof(message11), "%T", "PanelLine10", client, client);
			DrawPanelText(WelcomePanel, message11);
			Format(message12, sizeof(message12), "%T", "PanelLine11", client, client);
			DrawPanelText(WelcomePanel, message12);
			Format(message13, sizeof(message13), "%T", "PanelLine12", client, client);
			DrawPanelText(WelcomePanel, message13);
			Format(message14, sizeof(message14), "%T", "PanelLine13", client, client);
			DrawPanelText(WelcomePanel, message14);
			Format(closepanel, sizeof(closepanel), "%T", "PanelClose", client, client);
			DrawPanelText(WelcomePanel, closepanel);
			SendPanelToClient(WelcomePanel, client, NullMenuHandler, 60);
			CloseHandle(WelcomePanel);
		}
		case 13:
		{
			Format(message1, sizeof(message1), "%T", "PanelTitle", client, client);
			SetPanelTitle(WelcomePanel, message1);
			Format(message2, sizeof(message2), "%T", "PanelLine1", client, client);
			DrawPanelText(WelcomePanel, message2);
			Format(message3, sizeof(message3), "%T", "PanelLine2", client, client);
			DrawPanelText(WelcomePanel, message3);
			Format(message4, sizeof(message4), "%T", "PanelLine3", client, client);
			DrawPanelText(WelcomePanel, message4);
			Format(message5, sizeof(message5), "%T", "PanelLine4", client, client);
			DrawPanelText(WelcomePanel, message5);
			Format(message6, sizeof(message6), "%T", "PanelLine5", client, client);
			DrawPanelText(WelcomePanel, message6);
			Format(message7, sizeof(message7), "%T", "PanelLine6", client, client);
			DrawPanelText(WelcomePanel, message7);
			Format(message8, sizeof(message8), "%T", "PanelLine7", client, client);
			DrawPanelText(WelcomePanel, message8);
			Format(message9, sizeof(message9), "%T", "PanelLine8", client, client);
			DrawPanelText(WelcomePanel, message9);
			Format(message10, sizeof(message10), "%T", "PanelLine9", client, client);
			DrawPanelText(WelcomePanel, message10);
			Format(message11, sizeof(message11), "%T", "PanelLine10", client, client);
			DrawPanelText(WelcomePanel, message11);
			Format(message12, sizeof(message12), "%T", "PanelLine11", client, client);
			DrawPanelText(WelcomePanel, message12);
			Format(message13, sizeof(message13), "%T", "PanelLine12", client, client);
			DrawPanelText(WelcomePanel, message13);
			Format(message14, sizeof(message14), "%T", "PanelLine13", client, client);
			DrawPanelText(WelcomePanel, message14);
			Format(message15, sizeof(message15), "%T", "PanelLine14", client, client);
			DrawPanelText(WelcomePanel, message15);
			Format(closepanel, sizeof(closepanel), "%T", "PanelClose", client, client);
			DrawPanelText(WelcomePanel, closepanel);
			SendPanelToClient(WelcomePanel, client, NullMenuHandler, 60);
			CloseHandle(WelcomePanel);
		}
	}
}

public NullMenuHandler(Handle:menu, MenuAction:action, param1, param2) 
{
}

HintMessageDisplay(client)
{
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		PrintHintText(client, "%T", "HintMessage", client, client);
	}
}