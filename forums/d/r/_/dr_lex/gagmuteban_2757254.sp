/*
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
 * Плагин GagMuteBan.
 *
 * native int HxSetClientBan(int client, int iTime);
 * native int HxSetClientGag(int client, int iTime);
 * native int HxSetClientMute(int client, int iTime);
 * native int HxSetClientVote(int client, int iTime);
 *
*/

#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

char sg_file[160];
char sg_log[160];

int iPlay[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "[ANY] GagMuteBan",
	author = "dr lex & MAKS",
	description = "gag & mute & ban",
	version = "2.3.0",
	url = "https://forums.alliedmods.net/showthread.php?p=2757254"
};

public void OnPluginStart()
{
	RegConsoleCmd("callvote", Callvote_Handler);
	RegAdminCmd("sm_addban",  CMD_addban,  ADMFLAG_BAN,  "sm_addban <minutes> <STEAM_ID>");
	RegAdminCmd("sm_addvote",  CMD_addvote,  ADMFLAG_BAN,  "sm_addvote <minutes> <STEAM_ID>");
	RegAdminCmd("sm_unban", CMD_unban, ADMFLAG_UNBAN, "sm_unban <STEAM_ID>");
	
	BuildPath(Path_SM, sg_file, sizeof(sg_file)-1, "data/GagMuteBan.txt");
	BuildPath(Path_SM, sg_log, sizeof(sg_log)-1, "logs/GagMuteBan.log");

	HxDelete();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("HxSetClientBan", Native_HxSetClientBan);
	CreateNative("HxSetClientGag", Native_HxSetClientGag);
	CreateNative("HxSetClientMute", Native_HxSetClientMute);
	CreateNative("HxSetClientVote", Native_HxSetClientVote);

	RegPluginLibrary("gagmuteban");
	return APLRes_Success;
}

stock int Native_HxSetClientBan(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
	}
	
	int iTime = GetNativeCell(2);
	if (iTime > 0)
	{
		HxClientTime(client, iTime, 1);
	}
	
	return 0;
}

stock int Native_HxSetClientGag(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
	}
	
	int iTime = GetNativeCell(2);
	if (iTime > 0)
	{
		HxClientTime(client, iTime, 2);
	}
	
	return 0;
}

stock int Native_HxSetClientMute(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
	}
	
	int iTime = GetNativeCell(2);
	if (iTime > 0)
	{
		HxClientTime(client, iTime, 3);
	}
	
	return 0;
}

stock int Native_HxSetClientVote(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
	}
	
	int iTime = GetNativeCell(2);
	if (iTime > 0)
	{
		HxClientTime(client, iTime, 4);
	}
	
	return 0;
}

public int HxClientTime(int &client, int iminute, int iNum)
{
	if (IsClientInGame(client))
	{
		int iBan = 0;
		char sTime[24];
		char sNum[32];
		char sName[64];
		
		KeyValues hGM = new KeyValues("gagmute");
		hGM.ImportFromFile(sg_file);
		
		char sTeamID[32];
		GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID)-1);
		
		GetClientName(client, sName, sizeof(sName)-12);
		
		switch (iNum)
		{
			case 1: sNum = "ban";
			case 2: sNum = "gag";
			case 3: sNum = "mute";
			case 4: sNum = "vote";
		}
		
		if (hGM.JumpToKey(sTeamID))
		{
			int iBanOld = 0;
			iBanOld = hGM.GetNum(sNum, 0);
			if (iBanOld > 0)
			{
				iBan = iBanOld + (iminute * 60);
			}
			else
			{
				iBan = GetTime() + (iminute * 60);
			}
			
			hGM.SetString("Name", sName);
			hGM.SetNum(sNum, iBan);
		}
		else
		{
			hGM.JumpToKey(sTeamID, true);
			
			iBan = GetTime() + (iminute * 60);
			hGM.SetString("Name", sName);
			hGM.SetNum(sNum, iBan);
		}
		
		FormatTime(sTime, sizeof(sTime)-1, "%Y-%m-%d %H:%M:%S", iBan);
		LogToFileEx(sg_log, "[GMB] Add command %s: %s, %s", sNum, sTeamID, sTime);
		
		hGM.Rewind();
		hGM.ExportToFile(sg_file);
		delete hGM;
		
		HxGetGagMuteBan(client);
		
		return 1;
	}
	return 0;
}

void HxGetGagMuteBan(int &client)
{
	KeyValues hGM = new KeyValues("gagmute");
	if (hGM.ImportFromFile(sg_file))
	{
		iPlay[client] = 0;
		int iDelete = 1;
		char sTime[24];
		char sTeamID[32];
		GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID)-1);
		
		if (hGM.JumpToKey(sTeamID))
		{
			int iVote = hGM.GetNum("vote", 0);
			int iMute = hGM.GetNum("mute", 0);
			int iGag = hGM.GetNum("gag", 0);
			int iBan = hGM.GetNum("ban", 0);
			int iTime = GetTime();
			
			if (iVote > iTime)
			{
				FormatTime(sTime, sizeof(sTime)-1, "%Y-%m-%d %H:%M:%S", iVote);
				PrintToChat(client, "\x05[\x04GMB\x05] \x04Ban Vote \x03(%s)", sTime);
				iPlay[client] = 1;
				iDelete = 0;
			}
			
			if (iMute > iTime)
			{
				FormatTime(sTime, sizeof(sTime)-1, "%Y-%m-%d %H:%M:%S", iMute);
				PrintToChat(client, "\x05[\x04GMB\x05] \x04Mute \x03(%s)", sTime);
				ServerCommand("sm_mute #%d", GetClientUserId(client));
				iDelete = 0;
			}
			
			if (iGag > iTime)
			{
				FormatTime(sTime, sizeof(sTime)-1, "%Y-%m-%d %H:%M:%S", iGag);
				PrintToChat(client, "\x05[\x04GMB\x05] \x04ChaT \x03(%s)", sTime);
				ServerCommand("sm_gag #%d", GetClientUserId(client));
				iDelete = 0;
			}
			
			if (iBan > iTime)
			{
				FormatTime(sTime, sizeof(sTime)-1, "%Y-%m-%d %H:%M:%S", iBan);
				//PrintToChatAll("\x05[\x04GMB\x05] %N \x04Ban \x03(%s)", client, sTime);
				KickClient(client,"Banned (%s)", sTime);
				iDelete = 0;
			}
			
			if (iDelete)
			{
				hGM.DeleteThis();
				hGM.Rewind();
				hGM.ExportToFile(sg_file);
			}
		}
	}
	delete hGM;
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
	{
		HxGetGagMuteBan(client);
	}
}

void HxDelete()
{
	KeyValues hGM = new KeyValues("gagmute");
	hGM.ImportFromFile(sg_file);
	
	char sTeamID[50];
	int iDelete;
	int iVote;
	int iMute;
	int iGag;
	int iBan;
	int iTime = GetTime();
	
	if (hGM.GotoFirstSubKey())
	{
		while (hGM.GetSectionName(sTeamID, sizeof(sTeamID)-1))
		{
			iVote = hGM.GetNum("vote", 0);
			iMute = hGM.GetNum("mute", 0);
			iGag = hGM.GetNum("gag", 0);
			iBan = hGM.GetNum("ban", 0);
			
			iDelete = 1;
			if (iVote > iTime)
			{
				iDelete = 0;
			}			
			
			if (iMute > iTime)
			{
				iDelete = 0;
			}
			
			if (iGag > iTime)
			{
				iDelete = 0;
			}
			
			if (iBan > iTime)
			{
				iDelete = 0;
			}
			
			if (iDelete)
			{
				if (hGM.DeleteThis() > 0)
				{
					continue;
				}
			}
			
			if (hGM.GotoNextKey())
			{
				continue;
			}
			
			break;
		}
		
		hGM.Rewind();
		hGM.ExportToFile(sg_file);
	}
	delete hGM;
}

//==============================================

public void HxClientTimeBanSteam(char[] sTeamID, int iminute, int iNum)
{
	KeyValues hGM = new KeyValues("gagmute");
	hGM.ImportFromFile(sg_file);
	
	int iBan = 0;
	char sTime[24];
	char sNum[32];
	
	switch (iNum)
	{
		case 1: sNum = "ban";
		case 2: sNum = "vote";
	}
	
	if (hGM.JumpToKey(sTeamID))
	{
		int iBanOld = 0;
		iBanOld = hGM.GetNum(sNum, 0);
		if (iBanOld > 0)
		{
			iBan = iBanOld + (iminute * 60);
		}
		else
		{
			iBan = GetTime() + (iminute * 60);
		}
		hGM.SetNum(sNum, iBan);
	}
	else
	{
		hGM.JumpToKey(sTeamID, true);
		
		iBan = GetTime() + (iminute * 60);
		hGM.SetNum(sNum, iBan);
	}
	
	FormatTime(sTime, sizeof(sTime)-1, "%Y-%m-%d %H:%M:%S", iBan);
	LogToFileEx(sg_log, "[GMB] Сonsole %s: %s, %s", sNum, sTeamID, sTime);
	
	hGM.Rewind();
	hGM.ExportToFile(sg_file);
	delete hGM;
}

public Action CMD_addban(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_addban <minutes> <STEAM_ID>");
		return Plugin_Handled;
	}
	
	char arg_string[256];
	char minute[50];
	char authid[50];
	
	GetCmdArgString(arg_string, sizeof(arg_string));
	
	int len, total_len;
	
	/* Get minute */
	if ((len = BreakString(arg_string, minute, sizeof(minute))) == -1)
	{
		ReplyToCommand(client, "Usage: sm_addban <minutes> <steamid>");
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
	{
		idValid = true;
	}
	
	if (!idValid)
	{
		ReplyToCommand(client, "Invalid SteamID specified (Must be STEAM_ )");
		return Plugin_Handled;
	}
	
	int minutes = StringToInt(minute);
	
	HxClientTimeBanSteam(authid, minutes, 1);
	for (int i = 1 ; i <= MaxClients ; ++i)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			HxGetGagMuteBan(i);
		}
	}
	return Plugin_Handled;
}

public Action CMD_addvote(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_addvote <minutes> <STEAM_ID>");
		return Plugin_Handled;
	}
	
	char arg_string[256];
	char minute[50];
	char authid[50];
	
	GetCmdArgString(arg_string, sizeof(arg_string));
	
	int len, total_len;
	
	/* Get minute */
	if ((len = BreakString(arg_string, minute, sizeof(minute))) == -1)
	{
		ReplyToCommand(client, "Usage: sm_addvote <minutes> <steamid>");
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
	{
		idValid = true;
	}
	
	if (!idValid)
	{
		ReplyToCommand(client, "Invalid SteamID specified (Must be STEAM_ )");
		return Plugin_Handled;
	}
	
	int minutes = StringToInt(minute);
	
	HxClientTimeBanSteam(authid, minutes, 2);
	for (int i = 1 ; i <= MaxClients ; ++i) 
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			HxGetGagMuteBan(i);
		}
	}
	return Plugin_Handled;
}

//===========================================

public void HxClientUnBanSteam(char[] sTeamID)
{
	KeyValues hGM = new KeyValues("gagmute");
	if (hGM.ImportFromFile(sg_file))
	{
		if (hGM.JumpToKey(sTeamID))
		{
			hGM.DeleteThis();
			hGM.Rewind();
			hGM.ExportToFile(sg_file);
			LogToFileEx(sg_log, "[GMB] Сonsole UnBan: %s", sTeamID);
		}
		else
		{
			LogToFileEx(sg_log, "[GMB] Сonsole UnBan: %s Not in the list", sTeamID);
		}
	}
	delete hGM;
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
	
	if (!idValid)
	{
		ReplyToCommand(client, "Invalid SteamID specified");
		return Plugin_Handled;
	}
	
	HxClientUnBanSteam(authid);
	return Plugin_Handled;
}

//===========================================

public Action Callvote_Handler(int client, int args)
{
	if (client)
	{
		if (iPlay[client])
		{
			PrintToChat(client, "[GMB] Vote access denied!");
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}