/**
* Menu Say for Admins Only & Private Messages V2.0 [17 Jun 09]
* Now includes HUDSAY! For coloured messages in TF2/orange box games
*
* Description:
*	This pluging does two things currently: 
*	1. Makes a panel for private messages
*	2. Makes a panel for admin only chat messages
*
* Usage:
*	sm_psay <name or #userid> <message> - sends private message as a menu panel
*	sm_masay <message> - sends message to admins as a menu panel
*	sm_namsay <message> - sends message to non-admins as a menu panel
*	
* Thanks to:
* 	Tsunami for my n00b questions
*	
* Based upon:
*	SourceMod Basic Chat Plugin <  pretty much skank'ed it all from this
*  
* Version History
* 	1.0 - After a few attempts :-P
*	1.1 - nub cake
*	1.2 - Added non admin menus
*	2.0 - Rewrite to clean up code and use a single function (SendPanelToTargets) for the menu creation, rather than 3 separate functions
*	2.1 - Added hud messages and fixed maxclients issue
* 	
*/
//////////////////////////////////////////////////////////////////
// Defines, Includes, Handles & Plugin Info
//////////////////////////////////////////////////////////////////
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "2.1"

//	2.1 - Added hud messages
new Handle:HudMessage;
new bool:CanHUD;
//new Handle:g_cvars_USEHUD;
new Handle:g_cvars_HUDTIME;
new String:g_ColorNames[13][10] = {"White", "Red", "Green", "Blue", "Yellow", "Purple", "Cyan", "Orange", "Pink", "Olive", "Lime", "Violet", "Lightblue"};
new g_Colors[13][3] = {{255,255,255},{255,0,0},{0,255,0},{0,0,255},{255,255,0},{255,0,255},{0,255,255},{255,128,0},{255,0,128},{128,255,0},{0,255,128},{128,0,255},{0,128,255}};

public Plugin:myinfo = 
{
	name = "Advanced Menu Say",
	author = "MoggieX",
	description = "Menu's for admins only, private msgs and coloured hud msgs",
	version = PLUGIN_VERSION,
	url = "http://www.UKManDown.co.uk/"
};

//////////////////////////////////////////////////////////////////
// Plugin Start
//////////////////////////////////////////////////////////////////
public OnPluginStart()
{
//	LoadTranslations("common.phrases");
	
	CreateConVar("sm_mpsay_version", PLUGIN_VERSION, "Menu's for admins only and private msgs", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	RegAdminCmd("sm_pmsay", Command_SmmPsay, ADMFLAG_CHAT, "sm_pmsay <name or #userid> <message> - sends private message as a menu panel");
	RegAdminCmd("sm_amsay", Command_SmAMsay, ADMFLAG_CHAT, "sm_amsay <message> - sends message to admins as a menu panel");
	RegAdminCmd("sm_namsay", Command_SmNAmsay, ADMFLAG_CHAT, "sm_namsay <message> - sends message to non-admins as a menu panel");

//	2.1 - Added hud messages
	RegAdminCmd("sm_hudsay", Command_SmHUDsay, ADMFLAG_CHAT, "sm_hudsay [colour] <message>. Valid colours: White, Red, Green, Blue, Yellow, Purple, Cyan, Orange, Pink, Olive, Lime, Violet, Lightblue");

//	2.1 - Added hud messages
	g_cvars_HUDTIME = CreateConVar("sm_amsay_hudtime","6.0","How long the HUD messages are displayed.");
//	g_cvars_USEHUD = CreateConVar("sm_amsay_usehud","1","Enables or disables using the HUD for spray tracking. Works on supported games. If this is off, hint will be used.");

// OnLoad - verify game is supported

	new String:gamename[32];
	GetGameFolderName(gamename, sizeof(gamename));

	CanHUD = StrEqual(gamename,"tf",false) || StrEqual(gamename,"hl2mp",false) || StrEqual(gamename,"sourceforts",false) || StrEqual(gamename,"obsidian",false) || StrEqual(gamename,"left4dead",false) || StrEqual(gamename,"l4d",false);
	if(CanHUD)
		HudMessage = CreateHudSynchronizer();



}

//////////////////////////////////////////////////////////////////
// Private Menu Say - sm_pmsay 
//////////////////////////////////////////////////////////////////

public Action:Command_SmmPsay(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_pmsay <name or #userid> <message> - sends private message as a menu panel");
		return Plugin_Handled;	
	}	
	
	decl String:text[192], 
	String:arg[64], 
	String:message[192];
	
	GetCmdArgString(text, sizeof(text));

	new len = BreakString(text, arg, sizeof(arg));
	BreakString(text[len], message, sizeof(message));
	
	new target = FindTarget(client, arg, true, false);
		
	if (target == -1)
		return Plugin_Handled;	
		
	decl String:name[64], 
	String:name2[64];

	if (client == 0)
	{
		name = "Console";
	}
	else
	{
		// get the person initiating the chat
		GetClientName(client, name, sizeof(name));
	}
	
	// now get the target
	GetClientName(target, name2, sizeof(name2));

	PrintToChat(target, "\x03(Private Message: %s) %s:\x04 %s", name2, name, message);	
	PrintToChat(client, "\x03(Private Message: %s) %s:\x04 %s", name2, name, message);

	//Added this to identify panels
	new identifier = 1;		// Private Say

	SendPanelToTargets(name, target, client, message, identifier);

	return Plugin_Handled;	
}

//////////////////////////////////////////////////////////////////
// Admin Only Menu - sm_amsay
//////////////////////////////////////////////////////////////////
public Action:Command_SmAMsay(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_amsay <message> - sends message to admins as a menu panel");
		return Plugin_Handled;	
	}
	
	decl String:message[192];
	GetCmdArgString(message, sizeof(message));

	decl String:name[64];
	GetClientName(client, name, sizeof(name));

	//Added this to identify panels
	new identifier = 2;		// Admin ONLY
	new target = 0;			// Null this out

	SendPanelToTargets(name, target, client, message, identifier);

	return Plugin_Handled;		
}

//////////////////////////////////////////////////////////////////
// Non-Admin Menu - sm_namsay
//////////////////////////////////////////////////////////////////
public Action:Command_SmNAmsay(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_namsay <message> - sends message to non-admins as a menu panel");
		return Plugin_Handled;	
	}
	
	decl String:message[192];
	GetCmdArgString(message, sizeof(message));

	decl String:name[64];
	GetClientName(client, name, sizeof(name));
		
	//Added this to identify panels
	new identifier = 3;		// Non Admin only
	new target = 0;			// Null this out

	SendPanelToTargets(name,target,client, message, identifier);
	
	return Plugin_Handled;		
}

//////////////////////////////////////////////////////////////////
// MENU FUNCTION - SendPanelToTargets
//////////////////////////////////////////////////////////////////
SendPanelToTargets(String:name[], target, client, String:message[], identifier)
{
	decl String:title[100];

	if(identifier == 1)	// Private Menu Message
	{
		Format(title, 64, "Private Message From: %s:", name);
		
	}
	if(identifier == 2)	// Admin Only Menu Message
	{
		Format(title, 64, "Admin Only Message From: %s:", name);
	}

	if(identifier == 3)	// Non Admin Menu Message
	{
		Format(title, 64, "Message From: %s:", name);
	}

	ReplaceString(message, 192, "\\n", "\n");
	
	new Handle:mSayPanel = CreatePanel();
	SetPanelTitle(mSayPanel, title);
	DrawPanelItem(mSayPanel, "", ITEMDRAW_SPACER);
	DrawPanelText(mSayPanel, message);
	DrawPanelItem(mSayPanel, "", ITEMDRAW_SPACER);

	SetPanelCurrentKey(mSayPanel, 10);
	DrawPanelItem(mSayPanel, "Exit", ITEMDRAW_CONTROL);

	// moved here in 2.1
	//new MaxClients = GetMaxClients();

	if(identifier == 1)	// Private Menu Message
	{
		//target
		if(IsClientInGame(target) && !IsFakeClient(target))
		{
			SendPanelToClient(mSayPanel, target, Handler_DoNothing, 10);
		}
		//client
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			SendPanelToClient(mSayPanel, client, Handler_DoNothing, 10);
		}

		LogAction(client, -1, "%L triggered sm_pmsay to %L (text %s)", client, target, message);

	}

	if(identifier == 2)	// Admin Only Menu Message
	{
		for(new i = 1; i < MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && CheckCommandAccess(i, "sm_chat", ADMFLAG_CHAT))
			{
				SendPanelToClient(mSayPanel, i, Handler_DoNothing, 10);
			}
		}

		LogAction(client, -1, "%L triggered sm_amsay (text %s)", client, message);

	}

	if(identifier == 3)	// Non Admin Menu Message
	{ 
		for(new i = 1; i < MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && !CheckCommandAccess(i, "sm_chat", ADMFLAG_CHAT))
			{
				SendPanelToClient(mSayPanel, i, Handler_DoNothing, 10);
			}
		}

		LogAction(client, -1, "%L triggered sm_namsay (text %s)", client, message);
	}

	CloseHandle(mSayPanel);
}
//////////////////////////////////////////////////////////////////
// Do Nothing!
//////////////////////////////////////////////////////////////////

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2)
{
	/* Do nothing */
}

//////////////////////////////////////////////////////////////////
// Private HUD Say - sm_hudsay 
//////////////////////////////////////////////////////////////////

public Action:Command_SmHUDsay(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_hudsay [colour] <message>. Valid colours: White, Red, Green, Blue, Yellow, Purple, Cyan, Orange, Pink, Olive, Lime, Violet, Lightblue");
		return Plugin_Handled;	
	}	

	// colour
	decl String:text[192], String:colorStr[16];
	GetCmdArgString(text, sizeof(text));
	
	new len = BreakString(text, colorStr, 16);
 
	// Name
	decl String:name[64];
	GetClientName(client, name, sizeof(name));
		
	new color = FindColor(colorStr);
	//new String:nameBuf[MAX_NAME_LENGTH];
	
	if (color == -1)
	{
		color = 0;
		len = 0;
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}
		//FormatActivitySource(client, i, nameBuf, sizeof(nameBuf));
		//SendDialogToOne(i, color, "%s: %s", nameBuf, text[len]);

		SetHudTextParams(0.04, 0.4, GetConVarFloat(g_cvars_HUDTIME), g_Colors[color][0], g_Colors[color][1], g_Colors[color][2], 255);
		ShowSyncHudText(i, HudMessage, "%s \nFrom: %s", text[len], name);
	}

	LogAction(client, -1, "%L triggered sm_hudsay (text %s)", client, text);
	
	return Plugin_Handled;

}
//////////////////////////////////////////////////////////////////
// sm_hudsay Find the colour name
//////////////////////////////////////////////////////////////////
FindColor(String:color[])
{
	for (new i = 0; i < 13; i++)
	{
		if (strcmp(color, g_ColorNames[i], false) == 0)
			return i;
	}
	
	return -1;
}