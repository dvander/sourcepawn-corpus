#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION "1.0"

// ====[ CVARS | HANDLES ]=====================================================
new Handle:g_hCvarEnabled;

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "File Errors Fix",
	author = "ReFlexPoison",
	description = "Information on how to fix file errors",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

// ====[ EVENTS ]==============================================================
public OnPluginStart()
{
	CreateConVar("sm_errorfix_version", PLUGIN_VERSION, "File Errors Fix Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);

	g_hCvarEnabled = CreateConVar("sm_errorfix_enabled", "1", "Enable File Errors Fix\n0 = Disabled\n1 = Enabled", FCVAR_NONE, true, 0.0, true, 1.0);

	AddCommandListener(SayCmd, "say");
	AddCommandListener(SayCmd, "say_team");

	LoadTranslations("core.phrases");
	LoadTranslations("fileerrors.phrases");
}

// ====[ COMMANDS ]============================================================
public Action:SayCmd(iClient, const String:strCommand[], iArgc)
{
	if(!GetConVarBool(g_hCvarEnabled) || !IsValidClient(iClient))
		return Plugin_Continue;

	decl String:strCmd[196];
	GetCmdArgString(strCmd, sizeof(strCmd));

	decl String:strTrigger[192];
	SetGlobalTransTarget(iClient);
	Format(strTrigger, sizeof(strTrigger), "%t", "Trigger");
	if(StrContains(strCmd, strTrigger, false) != -1)
		ErrorMenu(iClient);
	return Plugin_Continue;
}

public ErrorMenu(iClient)
{
	decl String:strInfo[255];
	SetGlobalTransTarget(iClient);
	Format(strInfo, sizeof(strInfo), "[SM] %t", "Read");
	PrintToChat(iClient, strInfo);

	new Handle:hPanel = CreatePanel();
	Format(strInfo, sizeof(strInfo), "%t:", "Title");
	SetPanelTitle(hPanel, strInfo);
	DrawPanelText(hPanel, " ");

	Format(strInfo, sizeof(strInfo), "%t", "Step1");
	DrawPanelText(hPanel, strInfo);
	
	Format(strInfo, sizeof(strInfo), "%t", "Step2");
	DrawPanelText(hPanel, strInfo);
	
	Format(strInfo, sizeof(strInfo), "%t", "Step3");
	DrawPanelText(hPanel, strInfo);
	
	Format(strInfo, sizeof(strInfo), "%t", "Step4");
	DrawPanelText(hPanel, strInfo);
	
	Format(strInfo, sizeof(strInfo), "%t", "Step5");
	DrawPanelText(hPanel, strInfo);
	DrawPanelText(hPanel, " ");

	Format(strInfo, sizeof(strInfo), "%t", "Exit");
	DrawPanelItem(hPanel, strInfo);

	SendPanelToClient(hPanel, iClient, MenuHandler, MENU_TIME_FOREVER);
	CloseHandle(hPanel);
}

public MenuHandler(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	return;
}

// ====[ STOCKS ]==============================================================
stock bool:IsValidClient(iClient, bool:bReplay = true)
{
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}