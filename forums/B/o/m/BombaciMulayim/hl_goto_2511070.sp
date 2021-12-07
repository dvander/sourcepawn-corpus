#include <sourcemod>
#include <sdktools>
#include <autoexecconfig>

#define PLUGIN_VERSION "1.6"

#pragma semicolon 1
#pragma newdecls required

ConVar gcv_bPluginEnabled;
ConVar gcv_bBotsEnabled;

public Plugin myinfo =
{
	name = "Teleport Player",
	author = "Headline, Snippents From : HyperKiLLeR",
	description = "Teleport player(s)",
	version = PLUGIN_VERSION,
	url = "http://www.michaelwflaherty.com"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	AutoExecConfig_SetFile("hl_goto");
	AutoExecConfig_SetCreateFile(true);

	AutoExecConfig_CreateConVar("hl_goto", PLUGIN_VERSION, "Headline's Player Teleport Plugin", FCVAR_DONTRECORD|FCVAR_NOTIFY);

	gcv_bPluginEnabled = AutoExecConfig_CreateConVar("hl_goto_enabled", "1", "Enables and disables the goto plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	gcv_bBotsEnabled = AutoExecConfig_CreateConVar("hl_goto_allow_bots", "1", "Enables and disables the ability to move bots", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	RegAdminCmd("sm_goto", Command_Goto, ADMFLAG_SLAY, "Go to a player");
	RegAdminCmd("sm_bring", Command_Bring, ADMFLAG_SLAY, "Teleport a player to you");
	RegAdminCmd("sm_telemenu", Command_TeleMenu, ADMFLAG_SLAY, "Opens the Teleport Menu");
}

public Action Command_Bring(int client, int args)
{
	if (!gcv_bPluginEnabled.BoolValue)
	{
		ReplyToCommand(client, "The goto plugin is disabled!");
		return Plugin_Handled;
	}
	
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage  bring <target>");
		return Plugin_Handled;
	}

	float fTeleportOrigin[3];
	float fPlayerOrigin[3];
	
	char sTarget[65];
	GetCmdArg(1, sTarget, sizeof(sTarget));

	char sTargetName[MAX_TARGET_LENGTH];
	int a_iTargets[MAXPLAYERS];
	int iTargetCount;
	bool bTN_ML;

	if((iTargetCount = ProcessTargetString(sTarget, client, a_iTargets, MAXPLAYERS, COMMAND_FILTER_ALIVE, sTargetName, sizeof(sTargetName), bTN_ML)) <= 0)
	{
		PrintToConsole(client, "Not found or invalid parameter.");
		return Plugin_Handled;
	}

	for (int i = 0; i < iTargetCount; i++)
	{
		int target = a_iTargets[i];
		if(IsValidClient(target, gcv_bBotsEnabled.BoolValue?true:false))
		{
			GetCollisionPoint(client, fPlayerOrigin);

			fTeleportOrigin[0] = fPlayerOrigin[0];
			fTeleportOrigin[1] = fPlayerOrigin[1];
			fTeleportOrigin[2] = (fPlayerOrigin[2] + 4);
			
			TeleportEntity(target, fTeleportOrigin, NULL_VECTOR, NULL_VECTOR);
			ReplyToCommand(client, "[SM] Player(s) have been teleported!");
			PrintToChat(target, "[SM] You have been brought to %N!", client);
		}
	}
	return Plugin_Handled;
}

public Action Command_Goto(int client, int args)
{
	if (!gcv_bPluginEnabled.BoolValue)
	{
		ReplyToCommand(client, "The hl_goto plugin is disabled!");
		return Plugin_Handled;
	}
	
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage  sm_goto <target>");
		return Plugin_Handled;
	}

	float fTeleportOrigin[3];
	float fPlayerOrigin[3];

	char sArg1[MAX_NAME_LENGTH];
	GetCmdArg(1, sArg1, sizeof(sArg1));
	int iTarget = FindTarget(client, sArg1, gcv_bBotsEnabled.BoolValue?false:true, true);

	if (iTarget == -1)
	{
		return Plugin_Handled;
	}

	GetClientAbsOrigin(iTarget, fPlayerOrigin);

	fTeleportOrigin[0] = fPlayerOrigin[0];
	fTeleportOrigin[1] = fPlayerOrigin[1];
	fTeleportOrigin[2] = (fPlayerOrigin[2] + 73);

	TeleportEntity(client, fTeleportOrigin, NULL_VECTOR, NULL_VECTOR);
	PrintToChat(iTarget, "[SM] %N has been brought to you!", client);
	PrintToChat(client, "[SM] You have been brought to %N!", iTarget);
	return Plugin_Handled;
}

public Action Command_TeleMenu(int client, int args)
{
	OpenMainMenu(client);
	return Plugin_Handled;
}

public void OpenMainMenu(int client)
{
	Menu MainMenu = new Menu(MainMenu_CallBack, MenuAction_Select | MenuAction_End); 
	MainMenu.SetTitle("Main Menu :");

	MainMenu.AddItem("bring", "Bring Player(s)");
	MainMenu.AddItem("goto", "Go To Player");

	DisplayMenu(MainMenu, client, MENU_TIME_FOREVER); 
}

public int MainMenu_CallBack(Menu MainMenu, MenuAction action, int param1, int param2) 
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char item[64];
			GetMenuItem(MainMenu, param2, item, sizeof(item));

			if (StrEqual(item, "bring"))
			{
				OpenBringMenu(param1);
			}
			else if (StrEqual(item, "goto"))
			{
				OpenGoToMenu(param1);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(MainMenu);
		}
	}
}

public void OpenBringMenu(int client)
{
	Menu BringMenu = new Menu(BringMenu_CallBack, MenuAction_Select | MenuAction_End); 
	BringMenu.SetTitle("Bring Menu");
	char sCommand[32] = "sm_bring";

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i, gcv_bBotsEnabled.BoolValue?true:false, false))
		{
			char sInfoBuffer[256];
			char sName[MAX_NAME_LENGTH];
			char sUserID[MAX_NAME_LENGTH];
			char sDisplay[128];
			IntToString(GetClientUserId(i), sUserID, sizeof(sUserID));
			GetClientName(i, sName, sizeof(sName));
			Format(sDisplay, sizeof(sDisplay), "%s (%s)", sName, sUserID);
			Format(sInfoBuffer, sizeof(sInfoBuffer), "%s %s", sCommand, sUserID);
			BringMenu.AddItem(sInfoBuffer, sDisplay);
		}
	}
	SetMenuExitBackButton(BringMenu, true);
	DisplayMenu(BringMenu, client, MENU_TIME_FOREVER);
}

public int BringMenu_CallBack(Menu BringMenu, MenuAction action, int param1, int param2) 
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
			GetMenuItem(BringMenu, param2, sInfo, sizeof(sInfo));
			char sTempArray[2][32];
			ExplodeString(sInfo, " ", sTempArray, sizeof(sTempArray), sizeof(sTempArray[]));

			if(!IsValidClient(GetClientOfUserId(StringToInt(sTempArray[1]))))
			{
				ReplyToCommand(param1, "Invalid target.");
			}
			else if(!IsPlayerAlive(GetClientOfUserId(StringToInt(sTempArray[1]))))
			{
				ReplyToCommand(param1, "Player no longer alive.");
			}
			else
			{
				char sCommand[300];
				Format(sCommand, sizeof(sCommand), "%s #%i", sTempArray[0], StringToInt(sTempArray[1]));
				FakeClientCommand(param1, sCommand);
			}
		}
		case MenuAction_Cancel:
		{
			//param1 is client, param2 is cancel reason (see MenuCancel types)
			if (param2 == MenuCancel_ExitBack)
			{
				OpenMainMenu(param1);
			}

		}
		case MenuAction_End:
		{
			//param1 is MenuEnd reason, if canceled param2 is MenuCancel reason
			CloseHandle(BringMenu);

		}
	}
}

public void OpenGoToMenu(int client)
{
	Menu GoToMenu = new Menu(GoToMenu_Callback, MenuAction_Select | MenuAction_End); 
	GoToMenu.SetTitle("Bring Menu ");
	char sCommand[32] = "sm_goto";
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i, gcv_bBotsEnabled.BoolValue?true:false, false))
		{
			char sInfoBuffer[256];
			char sName[MAX_NAME_LENGTH];
			char sUserID[MAX_NAME_LENGTH];
			char sDisplay[128];
			IntToString(GetClientUserId(i), sUserID, sizeof(sUserID));
			GetClientName(i, sName, sizeof(sName));
			Format(sDisplay, sizeof(sDisplay), "%s (%s)", sName, sUserID);
			Format(sInfoBuffer, sizeof(sInfoBuffer), "%s %s", sCommand, sUserID);
			GoToMenu.AddItem(sInfoBuffer, sDisplay);
		}
	}
	SetMenuExitBackButton(GoToMenu, true);
	DisplayMenu(GoToMenu, client, MENU_TIME_FOREVER);
}

public int GoToMenu_Callback(Menu GoToMenu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			//param1 is client, param2 is sInfo

			char sInfo[64];
			GetMenuItem(GoToMenu, param2, sInfo, sizeof(sInfo));
			char sTempArray[2][32];
			ExplodeString(sInfo, " ", sTempArray, sizeof(sTempArray), sizeof(sTempArray[]));

			if(!IsValidClient(GetClientOfUserId(StringToInt(sTempArray[1]))))
			{
					ReplyToCommand(param1, "Invalid target.");
			}
			else if(!IsPlayerAlive(GetClientOfUserId(StringToInt(sTempArray[1]))))
			{
					ReplyToCommand(param1, "Player no longer alive.");
			}
			else
			{
					char sCommand[300];
					Format(sCommand, sizeof(sCommand), "%s #%i", sTempArray[0], StringToInt(sTempArray[1]));
					FakeClientCommand(param1, sCommand);
			}
		}
		case MenuAction_Cancel:
		{
			//param1 is client, param2 is cancel reason (see MenuCancel types)
			if (param2 == MenuCancel_ExitBack)
			{
				OpenMainMenu(param1);
			}

		}
		case MenuAction_End:
		{
			//param1 is MenuEnd reason, if canceled param2 is MenuCancel reason
			CloseHandle(GoToMenu);

		}
	}
}

stock void GetCollisionPoint(int client, float pos[3])
{
	float vOrigin[3];
	float vAngles[3];
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		
		return;
	}
	
	CloseHandle(trace);
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients;
}  

stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}

/* Changelog
	1.0 - Initial Release
	1.1 - Added LoadTranslations because I forgot
	1.2 - Removed cstrike.inc (allowed access for TF2/etc games)
	1.3 - Added CVAR to enable/disable the teleportation of bots & fixed issue where the config file wouldn't get executed
	1.4 - Fixed OnConVarChange issue 
	1.5 - Added menus!
	1.6 - Fixed targeting issue & Ported over to new syntax
*/
