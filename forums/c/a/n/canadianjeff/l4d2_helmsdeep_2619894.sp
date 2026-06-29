#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define HDSE_VERSION "1.0.0"

ConVar g_cvAdminOnly, g_cvEnabled, g_cvItemLimit;

char g_sWeapons[5][] =
{
	"helms_anduril",
	"helms_hatchet",
	"helms_orcrist",
	"helms_sting",
	"helms_sword_and_shield"
};

int g_iItemLimit[MAXPLAYERS + 1][5];

public Plugin myinfo = 
{
	name = "[L4D2] Helms Deep Sourcemod Enabler",
	author = "SourceMod, linux_canadajeff, Psyk0tik (Crasher_3637)",
	description = "Allows for using the Helms Deep Reborn map with full SourceMod compatibility.",
	version	 = HDSE_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=311391"
};

public void OnPluginStart()
{
	CreateConVar("l4d2_helmsdeep_version", HDSE_VERSION, "Plugin version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	RegConsoleCmd("sm_donator", Command_Donator, "Access to custom melee weapons.");
	g_cvEnabled = CreateConVar("helmsdeep_donate_enable", "1", "0: disable donator menu, 1: enable donator menu", _, true, 0.0, true, 1.0);
	g_cvAdminOnly = CreateConVar("helmsdeep_donate_admin", "0", "0: every client can use donate, 1: only admin can use donate", _, true, 0.0, true, 1.0);
	g_cvItemLimit = CreateConVar("helmsdeep_donate_item_limit", "3", "limit for each of the 5 custom weapons each player can have.", _, true, 1.0, true, 100.0);
	HookEvent("player_connect", vEventHandler);
	HookEvent("player_disconnect", vEventHandler);
}

public void OnMapStart()
{
	char sMap[128];
	GetCurrentMap(sMap, sizeof(sMap));
	if (StrContains(sMap, "helms_deep", false) != -1)
	{
		PrintToServer("Helms Deep Detected");
		AddCommandListener(Command_Kickid, "kickid");
	}
	else
	{
		PrintToServer("--------------------------------------------------------");
		PrintToServer("Current Map: %s", sMap);
		PrintToServer("--------------------------------------------------------");
	}
}

public void vEventHandler(Event event, const char[] name, bool dontBroadcast)
{
	if (StrEqual(name, "player_connect") || StrEqual(name, "player_disconnect"))
	{
		int iPlayer = GetClientOfUserId(event.GetInt("userid"));
		for (int iWeapon = 0; iWeapon < sizeof(g_sWeapons); iWeapon++)
		{
			g_iItemLimit[iPlayer][iWeapon] = 0;
		}
	}
}

public Action Command_Kickid(int client, const char[] command, int argc)
{
	char arg[256];
	GetCmdArgString(arg, sizeof(arg));
	if (StrContains(arg, "This server is using plugins, please join a different server", false) != -1)
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Command_Donator(int client, int args)
{
	if (0 >= client || client > MaxClients || !IsClientInGame(client))
	{
		ReplyToCommand(client, "[SM] You must be in-game to use this command.");
		return Plugin_Handled;
	}

	if (!bIsAccessGranted(client))
	{
		ReplyToCommand(client, "[SM] You do not have access to this command.");
		return Plugin_Handled;
	}

	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[SM] A vote is already in progress.");
		return Plugin_Handled;
	}

	char sMap[128];
	GetCurrentMap(sMap, sizeof(sMap));
	if (StrContains(sMap, "helms_deep", false) == -1)
	{
		ReplyToCommand(client, "[SM] This command is only available on the Helms Deep Reborn survival map.");
		return Plugin_Handled;
	}

	vDonatorMenu(client, 0);
	return Plugin_Handled;
}

void vDonatorMenu(int client, int item)
{
	Menu mDonatorMenu = new Menu(iDonatorMenuHandler);
	mDonatorMenu.SetTitle("Helms Deep Reborn - Donator Menu:");

	for (int iWeapon = 0; iWeapon < sizeof(g_sWeapons); iWeapon++)
	{
		mDonatorMenu.AddItem(g_sWeapons[iWeapon], g_sWeapons[iWeapon]);
	}

	mDonatorMenu.ExitButton = true;
	mDonatorMenu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

public int iDonatorMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Start:
		{
			PrintToServer("Displaying Helms Deep Reborn - Donator Menu to a player.");
		}
		case MenuAction_Select:
		{
			char sInfo[MAX_NAME_LENGTH + 1];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			for (int iWeapon = 0; iWeapon < sizeof(g_sWeapons); iWeapon++)
			{
				if (StrEqual(sInfo, g_sWeapons[iWeapon], false))
				{
					if (g_iItemLimit[param1][iWeapon] >= g_cvItemLimit.IntValue)
					{
						ReplyToCommand(param1, "[SM] You already spawned in %d/%d of this weapon.", g_iItemLimit[param1][iWeapon], g_cvItemLimit.IntValue);
					}
					else
					{
						vCheatCommand(param1, "give", g_sWeapons[iWeapon]);
						g_iItemLimit[param1][iWeapon]++;
						break;
					}
				}
			}

			if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
			{
				vDonatorMenu(param1, menu.Selection);
			}
		}
	}

	return 0;
}

stock bool bIsAccessGranted(int client)
{
	if (g_cvAdminOnly.BoolValue)
	{
		if (bIsValidClient(client) && !CheckCommandAccess(client, "sm_donator", ADMFLAG_GENERIC, false))
		{
			return false;
		}
	}

	if (!g_cvEnabled.BoolValue)
	{
		return false;
	}
	
	return true;
}

stock void vCheatCommand(int client, char[] command, char[] arguments = "", any ...)
{
	int iCmdFlags = GetCommandFlags(command);
	SetCommandFlags(command, iCmdFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, iCmdFlags|FCVAR_CHEAT);
}

stock bool bIsValidClient(int client)
{
	if (0 >= client || client > MaxClients || !IsClientInGame(client))
	{
		return false;
	}

	return true;
}