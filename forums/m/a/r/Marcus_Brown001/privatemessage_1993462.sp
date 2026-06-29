#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

bool g_bImmunity = false;
Handle g_hImmunity = INVALID_HANDLE;

public Plugin myinfo = { name = "Private Messager", author = "MarcusBrown", description = "A plugin that allows players to private message each other.", version = "1.0.4", url = "http://www.aocgamers.com" };

public void OnPluginStart()
{
	CreateConVar("sv_pm_version", "1.0.4", "This is the plugin version for the plugin.", FCVAR_NONE);
	CreateConVar("sv_pm_immunity", "0", "This toggles whether the pm command checks players' immunity.", FCVAR_PLUGIN | FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	GetConVarBool(g_hImmunity);
	HookConVarChange(g_hImmunity, OnSettingsChange);
	
	RegAdminCmd("sm_pm", Command_PM, 0, "This command allows a player to send a private message to another player/group of players.");
}

public void OnSettingsChange(Handle hCvar, const char[] sOld, const char[] sNew)
{
	if (hCvar == g_hImmunity)
		g_bImmunity = StringToInt(sNew) == 0 ? false : true;
}

public Action Command_PM(int iClient, int iArgs)
{
	if (iArgs < 2)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_pm <player> <message>");
		
		return Plugin_Handled;
	}
	
	char sArg[32], sArguments[256];
	GetCmdArg(1, sArg, sizeof(sArg));
	GetCmdArgString(sArguments, sizeof(sArguments));
	
	int iTarget = FindTarget(iClient, sArg, true, g_bImmunity);
	
	if (iTarget == -1)
	{
		ReplyToCommand(iClient, "[SM] Error: Couldn't find player using %s", sArg);
		
		return Plugin_Handled;
	}
	
	if (iTarget == iClient)
	{
		ReplyToCommand(iClient, "[SM] Error: You can't send a private message to yourself!");
		
		return Plugin_Handled;
	}
	
	ReplaceStringEx(sArguments, sizeof(sArguments), sArg, "", -1, -1, false);
	TrimString(sArguments);
	
	PrintToChat(iClient, "[PM] %N to %N: %s", iClient, iTarget, sArguments);
	PrintToChat(iTarget, "[PM] %N to %N: %s", iClient, iTarget, sArguments);
	
	LogToGame("[Private Message] From: %L To: %L : %s", iClient, iTarget, sArguments);
	
	return Plugin_Handled;
}