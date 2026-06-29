#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.8"

ConVar gcv_bPluginEnabled;
ConVar gcv_bBotsEnabled;
ConVar gcv_bIgnoreImmunity;
ConVar gcv_sFlagString;

public Plugin myinfo =
{
	name = "Teleport Player",
	author = "Headline, Original: HyperKiLLeR",
	description = "Teleport players!",
	version = PLUGIN_VERSION,
	url = "http://www.michaelwflaherty.com"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	gcv_bPluginEnabled = CreateConVar("hl_goto_enabled", "1", "Enables and disables the goto plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	gcv_bBotsEnabled = CreateConVar("hl_goto_allow_bots", "1", "Enables and disables the ability to move bots", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	gcv_bIgnoreImmunity = CreateConVar("hl_goto_ignore_immunity", "0", "Enable to ignore immunity permissions", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	gcv_sFlagString = CreateConVar("hl_goto_flags", "f", "Flag for command access (default is slay)", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	RegConsoleCmd("sm_goto", Command_Goto, "Go to a player");
	RegConsoleCmd("sm_bring", Command_Bring, "Teleport a player to you");
	RegConsoleCmd("sm_telemenu", Command_TeleMenu, "Opens the Teleport Menu");
}

public Action Command_Bring(int client, int args)
{
	if (!gcv_bPluginEnabled.BoolValue)
	{
		ReplyToCommand(client, "The goto plugin is disabled!");
		return Plugin_Handled;
	}
	
	char flagString[32];
	gcv_sFlagString.GetString(flagString, sizeof(flagString));
	if (!HasFlags(client, flagString))
	{
		ReplyToCommand(client, "[SM] You have no access to this command!");
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

	if((iTargetCount = ProcessTargetString(sTarget, client, a_iTargets, MAXPLAYERS, (gcv_bIgnoreImmunity.BoolValue)?(COMMAND_FILTER_NO_IMMUNITY|COMMAND_FILTER_ALIVE):(COMMAND_FILTER_ALIVE), sTargetName, sizeof(sTargetName), bTN_ML)) <= 0)
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
	char flagString[32];
	gcv_sFlagString.GetString(flagString, sizeof(flagString));
	if (!HasFlags(client, flagString))
	{
		ReplyToCommand(client, "[SM] You have no access to this command!");
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
	if (!gcv_bPluginEnabled.BoolValue)
	{
		ReplyToCommand(client, "The goto plugin is disabled!");
		return Plugin_Handled;
	}
	
	if (!IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] You must be ingame to use this command!");
		return Plugin_Handled;
	}
	
	char flagString[32];
	gcv_sFlagString.GetString(flagString, sizeof(flagString));
	if (!HasFlags(client, flagString))
	{
		ReplyToCommand(client, "[SM] You have no access to this command!");
		return Plugin_Handled;
	}

	OpenMainMenu(client);
	return Plugin_Handled;
}

public void OpenMainMenu(int client)
{
	Menu menu = new Menu(MainMenu_CallBack, MenuAction_Select | MenuAction_End); 
	menu.SetTitle("Main Menu :");

	menu.AddItem("bring", "Bring Player(s)");
	menu.AddItem("goto", "Go To Player");

	menu.Display(client, MENU_TIME_FOREVER); 
}

public int MainMenu_CallBack(Menu menu, MenuAction action, int param1, int param2) 
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char item[64];
			GetMenuItem(menu, param2, item, sizeof(item));

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
			delete menu;
		}
	}
}

void OpenBringMenu(int client)
{
	Menu menu = new Menu(BringMenu_CallBack, MenuAction_Select | MenuAction_End); 
	menu.SetTitle("Bring Menu");
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
			menu.AddItem(sInfoBuffer, sDisplay);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int BringMenu_CallBack(Menu menu, MenuAction action, int param1, int param2) 
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
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
			delete menu;

		}
	}
}

void OpenGoToMenu(int client)
{
	Menu menu = new Menu(GoToMenu_Callback, MenuAction_Select | MenuAction_End); 
	menu.SetTitle("Bring Menu ");
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
			menu.AddItem(sInfoBuffer, sDisplay);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int GoToMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			//param1 is client, param2 is sInfo

			char sInfo[64];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
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
			delete menu;

		}
	}
}

void GetCollisionPoint(int client, float pos[3])
{
	float vOrigin[3];
	float vAngles[3];
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		delete trace;
		
		return;
	}
	
	delete trace;
}

bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients;
}  

bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}

// Copy & Pasted from ThatOneGuy 
bool HasFlags(int client, char[] sFlags)
{
	if(StrEqual(sFlags, "public", false) || StrEqual(sFlags, "", false))
	{
		return true;
	}
	
	if(StrEqual(sFlags, "none", false))
	{
		return false;
	}
	
	AdminId id = GetUserAdmin(client);
	if(id == INVALID_ADMIN_ID)
	{
		return false;
	}
	
	if(CheckCommandAccess(client, "sm_not_a_command", ADMFLAG_ROOT, true))
	{
		return true;
	}
	int iCount, iFound, flags;
	if(StrContains(sFlags, ";", false) != -1) //check if multiple strings
	{
		int c = 0, iStrCount = 0;
		while(sFlags[c] != '\0')
		{
			if(sFlags[c++] == ';')
			{
				iStrCount++;
			}
		}
		iStrCount++; //add one more for IP after last comma
		
		char[][] sTempArray = new char[iStrCount][30];
		ExplodeString(sFlags, ";", sTempArray, iStrCount, 30);
		
		for(int i = 0; i < iStrCount; i++)
		{
			flags = ReadFlagString(sTempArray[i]);
			iCount = 0;
			iFound = 0;
			for(int j = 0; j <= 20; j++)
			{
				if(flags & (1<<j))
				{
					iCount++;

					if(GetAdminFlag(id, view_as<AdminFlag>(j)))
					{
						iFound++;
					}
				}
			}
			
			if(iCount == iFound)
			{
				return true;
			}
		}
	}
	else
	{
		flags = ReadFlagString(sFlags);
		iCount = 0;
		iFound = 0;
		for(int i = 0; i <= 20; i++)
		{
			if(flags & (1<<i))
			{
				iCount++;

				if(GetAdminFlag(id, view_as<AdminFlag>(i)))
				{
					iFound++;
				}
			}
		}

		if(iCount == iFound)
		{
			return true;
		}
	}
	return false;
}

/* Changelog
	1.0 - Initial Release
	1.1 - Added LoadTranslations because I forgot
	1.2 - Removed cstrike.inc (allowed access for TF2/etc games)
	1.3 - Added CVAR to enable/disable the teleportation of bots & fixed issue where the config file wouldn't get executed
	1.4 - Fixed OnConVarChange issue 
	1.5 - Added menus!
	1.6 - Fixed targeting issue & Ported over to new syntax
	1.7 - Cleaned code, added new cvar, and removed autoexecconfig
	1.8 - Added HasFlags from ThatOneGuy
*/
