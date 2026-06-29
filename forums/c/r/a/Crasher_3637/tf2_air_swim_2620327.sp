#include <sourcemod>
#include <tf2>
#include <adminmenu>

#pragma semicolon 1
#pragma newdecls required

#define ASC_VERSION "1.0"

public Plugin myinfo =
{
	name = "[TF2] Air Swim Condition",
	author = "ApoziX and Psyk0tik (Crasher_3637)",
	description = "Provides a command to toggle air swim condition on players.",
	version = ASC_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=311471"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		strcopy(error, err_max, "This plugin only supports Team Fortress 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

bool g_bAirSwim[MAXPLAYERS + 1];

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_swim", cmdAirSwim, ADMFLAG_GENERIC, "Toggle air swim condition for players.");
	CreateConVar("asc_version", ASC_VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public void OnClientPutInServer(int client)
{
	g_bAirSwim[client] = false;
}

public Action cmdAirSwim(int client, int args)
{
	if (!bIsValidClient(client))
	{
		ReplyToCommand(client, "[SM] You must be in-game to use this command.");
		return Plugin_Handled;
	}

	char target[32], target_name[32], toggle[32];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, toggle, sizeof(toggle));
	int toggler = StringToInt(toggle);

	if (args != 2 || toggler < 0 || toggler > 1)
	{
		if (IsVoteInProgress())
		{
			ReplyToCommand(client, "[SM] Usage: sm_swim <#userid|name> <0|1>");
		}
		else
		{
			vMenuSwim(client, 0);
		}

		return Plugin_Handled;
	}

	if ((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		if (bIsValidClient(target_list[i]))
		{
			switch (toggler)
			{
				case 0:
				{
					TF2_RemoveCondition(target_list[i], TFCond_SwimmingCurse);
					PrintToChat(target_list[i], "[SM] You cannot air swim anymore.");
				}
				case 1:
				{
					TF2_AddCondition(target_list[i], TFCond_SwimmingCurse, TFCondDuration_Infinite);
					PrintToChat(target_list[i], "[SM] You can now air swim.");
				}
			}
		}
	}

	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Toggled air swimming for %t.", client, target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Toggled air swimming for %s.", client, target_name);
	}

	return Plugin_Handled;
}

void vMenuSwim(int client, int item)
{
	Menu mSwimMenu = new Menu(iSwimMenuHandler);
	mSwimMenu.SetTitle("Choose a player:");
	AddTargetsToMenu(mSwimMenu, client, true, true);
	mSwimMenu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

public int iSwimMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			int iTarget = GetClientOfUserId(StringToInt(sInfo));

			if (iTarget == 0)
			{
				PrintToChat(param1, "[SM] %t", "Player no longer available");
			}
			else if (!CanUserTarget(param1, iTarget))
			{
				PrintToChat(param1, "[SM] %t", "Unable to target");
			}
			else if (!IsPlayerAlive(iTarget))
			{
				PrintToChat(param1, "[SM] %t", "Player has since died");
			}
			else
			{
				switch (g_bAirSwim[iTarget])
				{
					case true:
					{
						TF2_RemoveCondition(iTarget, TFCond_SwimmingCurse);
						g_bAirSwim[iTarget] = false;
						PrintToChat(iTarget, "[SM] You cannot air swim anymore.");
					}
					case false:
					{
						TF2_AddCondition(iTarget, TFCond_SwimmingCurse, TFCondDuration_Infinite);
						g_bAirSwim[iTarget] = true;
						PrintToChat(iTarget, "[SM] You can now air swim.");
					}
				}

				ShowActivity2(param1, "[SM] ", "Toggled air swimming for %N.", iTarget);

				if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
				{
					vMenuSwim(param1, menu.Selection);
				}
			}
		}
	}

	return 0;
}

stock bool bIsValidClient(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return false;
	}

	return true;
}