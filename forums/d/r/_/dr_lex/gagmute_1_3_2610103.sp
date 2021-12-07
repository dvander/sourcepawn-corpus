/**
 * =============================================================================
 * 1 week gag & mute & ban
 * MAKS 	 steamcommunity.com/profiles/76561198025355822/
 * dr lex 	 steamcommunity.com/profiles/76561198008545221/
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <www.sourcemod.net/license.php>.
 *
*/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

#define HX_DELETE 1
char sg_fileTxt[160];
char sg_log[160];

#define MAX_COMANDS 7
#define MAX_TITLE 7
char Comands[MAX_COMANDS][256];
char Title[MAX_TITLE][256];
int ig_days;

public Plugin myinfo =
{
	name = "gagmute",
	author = "MAKS & dr lex",
	description = "gag & mute & ban",
	version = "1.3",
	url = "forums.alliedmods.net/showthread.php?p=2347844"
};

public void OnPluginStart()
{
	ig_days = 1;
	RegAdminCmd("sm_addban",  CMD_addbanmenu,  ADMFLAG_BAN,  "");
	RegAdminCmd("sm_addgag",  CMD_addgagmenu,  ADMFLAG_CHAT, "");
	RegAdminCmd("sm_addmute", CMD_addmutemenu, ADMFLAG_CHAT, "");
	RegAdminCmd("sm_unban", CMD_unban, ADMFLAG_CHAT, "");
	RegAdminCmd("sm_bansteam",  CMD_bansteam,  ADMFLAG_BAN,  "");

	BuildPath(Path_SM, sg_fileTxt, sizeof(sg_fileTxt)-1, "data/GagMuteBan.txt");
	BuildPath(Path_SM, sg_log, sizeof(sg_log)-1, "logs/GagMuteBan.log");
	
	Title[0] = "1 day";
	Comands[0] = "1";
	
	Title[1] = "3 day";
	Comands[1] = "3";
	
	Title[2] = "5 day";
	Comands[2] = "5";
	
	Title[3] = "7 day";
	Comands[3] = "7";
	
	Title[4] = "14 day";
	Comands[4] = "14";
	
	Title[5] = "21 day";
	Comands[5] = "21";
	
	Title[6] = "30 day";
	Comands[6] = "30";
}

void HxClientGagMuteBan(int &client)
{
	KeyValues hGM = new KeyValues("gagmute");

	if (hGM.ImportFromFile(sg_fileTxt))
	{
	#if HX_DELETE
		int iDelete = 1;
	#endif
		char sTeamID[24];
		GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID)-1);

		if (hGM.JumpToKey(sTeamID))
		{
			int iMute = hGM.GetNum("mute", 0);
			int iGag = hGM.GetNum("gag", 0);
			int iBan = hGM.GetNum("ban", 0);
			int iTime = GetTime();

			if (iMute > iTime)
			{
				ServerCommand("sm_mute #%d", GetClientUserId(client));
			#if HX_DELETE
				iDelete = 0;
			#endif
			}
			if (iGag > iTime)
			{
				ServerCommand("sm_gag #%d", GetClientUserId(client));
			#if HX_DELETE
				iDelete = 0;
			#endif
			}
			if (iBan > iTime)
			{
				char sTime[24];
				FormatTime(sTime, sizeof(sTime)-1, "%Y-%m-%d %H:%M:%S", iBan);
				KickClient(client,"Banned (%s)", sTime);
			#if HX_DELETE
				iDelete = 0;
			#endif
			}

		#if HX_DELETE
			if (iDelete)
			{
				hGM.DeleteThis();
				hGM.Rewind();
				hGM.ExportToFile(sg_fileTxt);
			}
		#endif
		}
		delete hGM;
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
	{
		HxClientGagMuteBan(client);
	}
}

int HxClientTimeBan(int &client, int iTime)
{
	if (IsClientInGame(client))
	{
		char sName[32];
		char sTeamID[24];

		KeyValues hGM = new KeyValues("gagmute");
		hGM.ImportFromFile(sg_fileTxt);

		GetClientName(client, sName, sizeof(sName)-12);
		GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID)-1);

		hGM.JumpToKey(sTeamID, true);

		int iTimeBan = GetTime() + (iTime * 60);
		hGM.SetString("Name", sName);
		hGM.SetNum("ban", iTimeBan);
		hGM.Rewind();
		hGM.ExportToFile(sg_fileTxt);
		delete hGM;
		return 1;
	}
	return 0;
}

public int MenuHandler_Ban(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char sInfo[8];
		bool found = menu.GetItem(param2, sInfo, sizeof(sInfo)-1);
		if (found && param1)
		{
			int client = StringToInt(sInfo);
			if (client > 0)
			{
				if (ig_days < 1)
				{
					ig_days = 1;
				}
				
				if (HxClientTimeBan(client, 60*24*ig_days))
				{
					LogToFileEx(sg_log, "Ban: %N -> %N", param1, client);
					PrintToChatAll("\x05%d min ban:\x04 %N", 60*24*ig_days, client);
					KickClient(client, "%d Min ban.", 60*24*ig_days);
				}
			}
		}
	}

	if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action CMD_addban(int client)
{
	if (client)
	{
		if (IsClientInGame(client))
		{
			char sName[32];
			char sNumber[8];
			int i = 1;

			Menu hMenu = new Menu(MenuHandler_Ban);
			hMenu.SetTitle("ban player");

			while (i <= MaxClients)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					if (client != i)
					{
						GetClientName(i, sName, sizeof(sName)-12);
						Format(sNumber, sizeof(sNumber)-1, "%d", i);
						hMenu.AddItem(sNumber, sName);
					}
				}
				i += 1;
			}

			hMenu.ExitButton = false;
			hMenu.Display(client, 20);
		}
	}

	return Plugin_Handled;
}

public int AddMenuBan(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		bool found = menu.GetItem(param2, info, sizeof(info)-1);
		if (found && param1)
		{
			int iTime = StringToInt(info);
			if (iTime > 0)
			{
				ig_days = iTime;
				CMD_addban(param1);
			}
		}
	}

	if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action CMD_addbanmenu(int client, int args)
{
	if (client)
	{
		if (IsClientInGame(client))
		{
			Menu hMenu = new Menu(AddMenuBan);
			for(int i = 0; i < MAX_TITLE; i++)
			{
				char buffer[256];
				Format(buffer, sizeof(buffer), "%s", Title[i]);
				hMenu.AddItem(buffer, buffer);
			}
			hMenu.SetTitle("Menu Ban", client);
			hMenu.ExitButton = true;
			hMenu.Display(client, MENU_TIME_FOREVER);
		}
	}
	return Plugin_Handled;
}

int HxClientTimeGag(int &client, int iTime)
{
	if (IsClientInGame(client))
	{
		char sName[32];
		char sTeamID[24];

		KeyValues hGM = new KeyValues("gagmute");
		hGM.ImportFromFile(sg_fileTxt);

		GetClientName(client, sName, sizeof(sName)-12);
		GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID)-1);

		hGM.JumpToKey(sTeamID, true);

		int iTimeGag = GetTime() + (iTime * 60);
		hGM.SetString("Name", sName);
		hGM.SetNum("gag", iTimeGag);
		hGM.Rewind();
		hGM.ExportToFile(sg_fileTxt);
		delete hGM;
		ServerCommand("sm_gag #%d", GetClientUserId(client));
		return 1;
	}
	return 0;
}

public int MenuHandler_Gage(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char sInfo[8];
		bool found = menu.GetItem(param2, sInfo, sizeof(sInfo)-1);
		if (found && param1)
		{
			int client = StringToInt(sInfo);
			if (client > 0)
			{
				if (ig_days < 1)
				{
					ig_days = 1;
				}
				
				if (HxClientTimeGag(client, 60*24*ig_days))
				{
					LogToFileEx(sg_log, "Gage: %N -> %N", param1, client);
					PrintToChatAll("\x05%d min gage:\x04 %N", 60*24*ig_days, client);
				}
			}
		}
	}

	if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action CMD_addgag(int client)
{
	if (client)
	{
		if (IsClientInGame(client))
		{
			char sName[32];
			char sNumber[8];
			int i = 1;

			Menu hMenu = new Menu(MenuHandler_Gage);
			hMenu.SetTitle("1 week block chat");

			while (i <= MaxClients)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					if (client != i)
					{
						GetClientName(i, sName, sizeof(sName)-12);
						Format(sNumber, sizeof(sNumber)-1, "%d", i);
						hMenu.AddItem(sNumber, sName);
					}
				}
				i += 1;
			}

			hMenu.ExitButton = false;
			hMenu.Display(client, 20);
		}
	}

	return Plugin_Handled;
}

public int AddMenuGag(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		bool found = menu.GetItem(param2, info, sizeof(info)-1);
		if (found && param1)
		{
			int iTime = StringToInt(info);
			if (iTime > 0)
			{
				ig_days = iTime;
				CMD_addgag(param1);
			}
		}
	}

	if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action CMD_addgagmenu(int client, int args)
{
	if (client && IsClientInGame(client))
	{
		Menu menu = new Menu(AddMenuGag);
		for(int i = 0; i < MAX_TITLE; i++)
		{
			char buffer[256];
			Format(buffer, sizeof(buffer), "%s", Title[i]);
			menu.AddItem(buffer, buffer);
		}
		menu.SetTitle("Menu Ban", client);
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);

	}
	return Plugin_Handled;
}

int HxClientTimeMute(int &client, int iTime)
{
	if (IsClientInGame(client))
	{
		char sName[32];
		char sTeamID[24];

		KeyValues hGM = new KeyValues("gagmute");
		hGM.ImportFromFile(sg_fileTxt);

		GetClientName(client, sName, sizeof(sName)-12);
		GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID)-1);

		hGM.JumpToKey(sTeamID, true);

		int iTimeMute = GetTime() + (iTime * 60);
		hGM.SetString("Name", sName);
		hGM.SetNum("mute", iTimeMute);
		hGM.Rewind();
		hGM.ExportToFile(sg_fileTxt);
		delete hGM;

		ServerCommand("sm_mute #%d", GetClientUserId(client));
		return 1;
	}
	return 0;
}

public int MenuHandler_Mute(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char sInfo[8];
		bool found = menu.GetItem(param2, sInfo, sizeof(sInfo)-1);
		if (found && param1)
		{
			int client = StringToInt(sInfo);
			if (client > 0)
			{
				if (ig_days < 1)
				{
					ig_days = 1;
				}
				
				if (HxClientTimeMute(client, 60*24*ig_days))
				{
					LogToFileEx(sg_log, "Mute: %N -> %N", param1, client);
					PrintToChatAll("\x05%d min mute:\x04 %N", 60*24*ig_days, client);
				}
			}
		}
	}

	if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action CMD_addmute(int client)
{
	if (client)
	{
		if (IsClientInGame(client))
		{
			char sName[32];
			char sNumber[8];
			int i = 1;

			Menu hMenu = new Menu(MenuHandler_Mute);
			hMenu.SetTitle("block microphone");

			while (i <= MaxClients)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					if (client != i)
					{
						GetClientName(i, sName, sizeof(sName)-12);
						Format(sNumber, sizeof(sNumber)-1, "%d", i);
						hMenu.AddItem(sNumber, sName);
					}
				}
				i += 1;
			}

			hMenu.ExitButton = false;
			hMenu.Display(client, 20);
		}
	}

	return Plugin_Handled;
}

public int AddMenuMute(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[8];
		bool found = menu.GetItem(param2, info, sizeof(info)-1);
		if (found && param1)
		{
			int iTime = StringToInt(info);
			if (iTime > 0)
			{
				ig_days = iTime;
				CMD_addmute(param1);
			}
		}
	}

	if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action CMD_addmutemenu(int client, int args)
{
	if (client && IsClientInGame(client))
	{
		Menu menu = new Menu(AddMenuMute);
		for(int i = 0; i < MAX_TITLE; i++)
		{
			char buffer[256];
			Format(buffer, sizeof(buffer), "%s", Title[i]);
			menu.AddItem(buffer, buffer);
		}
		menu.SetTitle("Menu Ban", client);
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);

	}
	return Plugin_Handled;
}

int HxClientUnBanSteam(char[] steam_id)
{
	KeyValues hGM = new KeyValues("gagmute");
	if (hGM.ImportFromFile(sg_fileTxt))
	{
		if (hGM.JumpToKey(steam_id))
		{
			hGM.DeleteThis();
			hGM.Rewind();
			hGM.ExportToFile(sg_fileTxt);
		}
	}
	delete hGM;
	return 0;
}

public Action CMD_unban(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_unban <STEAM_ID>");
		return Plugin_Handled;
	}
	
	char arg_string[256];
	char authid[50];

	GetCmdArgString(arg_string, sizeof(arg_string));

	/* Get steamid */
	int len, total_len;
	if ((len = BreakString(arg_string[total_len], authid, sizeof(authid))) != -1)
	{
		total_len += len;
	}
	else
	{
		total_len = 0;
		arg_string[0] = '\0';
	}
	
	/* Verify steamid */
	bool idValid = false;
	if (!strncmp(authid, "STEAM_", 6) && authid[7] == ':')
	{
		idValid = true;
	}
	else if (!strncmp(authid, "[U:", 3))
	{
		idValid = true;
	}
	
	if (!idValid)
	{
		ReplyToCommand(client, "Invalid SteamID specified");
		return Plugin_Handled;
	}
	
	HxClientUnBanSteam(authid);
	
	return Plugin_Handled;
}

int HxClientTimeBanSteam(char[] steam_id, int iTime)
{
	KeyValues hGM = new KeyValues("gagmute");
	hGM.ImportFromFile(sg_fileTxt);

	if (!hGM.JumpToKey(steam_id))
	{
		hGM.JumpToKey(steam_id, true);
	}

	int iTimeBan = GetTime() + (iTime * 60);
	hGM.SetNum("ban", iTimeBan);
	hGM.Rewind();
	hGM.ExportToFile(sg_fileTxt);
	delete hGM;
	return 0;
}

public Action CMD_bansteam(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_bantime <minutes> <STEAM_ID>");
		return Plugin_Handled;
	}
	
	char arg_string[256];
	char time[50];
	char authid[50];

	GetCmdArgString(arg_string, sizeof(arg_string));

	int len, total_len;
	
	/* Get time */
	if ((len = BreakString(arg_string, time, sizeof(time))) == -1)
	{
		ReplyToCommand(client, "Usage: sm_bansteam <minutes> <steamid>");
		return Plugin_Handled;
	}	
	total_len += len;
	
	/* Get steamid */
	if ((len = BreakString(arg_string[total_len], authid, sizeof(authid))) != -1)
	{
		total_len += len;
	}
	else
	{
		total_len = 0;
		arg_string[0] = '\0';
	}
	
	/* Verify steamid */
	bool idValid = false;
	if (!strncmp(authid, "STEAM_", 6) && authid[7] == ':')
		idValid = true;
	else if (!strncmp(authid, "[U:", 3))
		idValid = true;
	
	if (!idValid)
	{
		ReplyToCommand(client, "Invalid SteamID specified");
		return Plugin_Handled;
	}
	
	int minutes = StringToInt(time);
	
	HxClientTimeBanSteam(authid, minutes);
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			HxClientGagMuteBan(i);
		}
		i += 1;
	}
	return Plugin_Handled;
}