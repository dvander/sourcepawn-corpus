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
	RegAdminCmd("sm_addban",  CMD_addban,  ADMFLAG_BAN,  "");
	RegAdminCmd("sm_addgag",  CMD_addgag,  ADMFLAG_CHAT, "");
	RegAdminCmd("sm_addmute", CMD_addmute, ADMFLAG_CHAT, "");

	BuildPath(Path_SM, sg_fileTxt, sizeof(sg_fileTxt)-1, "data/GagMuteBan.txt");
	BuildPath(Path_SM, sg_log, sizeof(sg_log)-1, "logs/GagMuteBan.log");
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
				if (HxClientTimeBan(client, 60*24*7))
				{
					LogToFileEx(sg_log, "Ban: %N -> %N", param1, client);
					PrintToChatAll("\x05%d min ban:\x04 %N", 60*24*7, client);
					KickClient(client, "%d Min ban.", 60*24*7);
				}
			}
		}
	}

	if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action CMD_addban(int client, int args)
{
	if (client)
	{
		if (IsClientInGame(client))
		{
			char sName[32];
			char sNumber[8];
			int i = 1;

			Menu hMenu = new Menu(MenuHandler_Ban);
			hMenu.SetTitle("1 week ban player");

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
				if (HxClientTimeGag(client, 60*24*7))
				{
					LogToFileEx(sg_log, "Gage: %N -> %N", param1, client);
					PrintToChatAll("\x05%d min gage:\x04 %N", 60*24*7, client);
				}
			}
		}
	}

	if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action CMD_addgag(int client, int args)
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
				if (HxClientTimeMute(client, 60*24*7))
				{
					LogToFileEx(sg_log, "Mute: %N -> %N", param1, client);
					PrintToChatAll("\x05%d min mute:\x04 %N", 60*24*7, client);
				}
			}
		}
	}

	if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action CMD_addmute(int client, int args)
{
	if (client)
	{
		if (IsClientInGame(client))
		{
			char sName[32];
			char sNumber[8];
			int i = 1;

			Menu hMenu = new Menu(MenuHandler_Mute);
			hMenu.SetTitle("1 week block microphone");

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
