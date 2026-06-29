// SPDX-License-Identifier: GPL-3.0-only
/*
 *
 * Copyright 2011 - 2022 steamcommunity.com/profiles/76561198025355822/
 * Plugin GagMuteBan
 *
*/
#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

char sg_fileTxt[160];
KeyValues hg_kv;

public Plugin myinfo =
{
	name = "gagmuteban",
	author = "MAKS",
	description = " ",
	version = "2.0",
	url = "forums.alliedmods.net/showthread.php?t=272356"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("HxSetClientBan", __HxSetBan);
	CreateNative("HxSetClientGag", __HxSetGag);
	CreateNative("HxSetClientMute", __HxSetMute);
	CreateNative("HxGCollect", __HxGarbageCollection);

	RegPluginLibrary("gagmuteban");
	return APLRes_Success;
}

public void OnPluginStart()
{
	BuildPath(Path_SM, sg_fileTxt, sizeof(sg_fileTxt)-1, "data/GagMuteBan.txt");
}

public void OnMapStart()
{
	hg_kv = new KeyValues("data");
	if (!hg_kv.ImportFromFile(sg_fileTxt))
	{
		hg_kv.Rewind();
		hg_kv.ExportToFile(sg_fileTxt);
	}
}

public void OnMapEnd()
{
	if (hg_kv)
	{
		delete hg_kv;
	}
}

public int __HxSetBan(Handle plugin, int numParams)
{
	char sTeamID[24];
	GetNativeString(1, sTeamID, sizeof(sTeamID)-1);
	int iTime = GetNativeCell(2);

	if (sTeamID[0])
	{
		if (iTime > 0)
		{
			int iBan = GetTime() + iTime;
			if (hg_kv)
			{
				LogMessage("Ban: %s -> %d", sTeamID, iTime);
				hg_kv.Rewind();
				hg_kv.JumpToKey(sTeamID, true);
				hg_kv.SetNum("ban", iBan);

				hg_kv.Rewind();
				hg_kv.ExportToFile(sg_fileTxt);
				return 1;
			}
		}
	}

	return 0;
}

public int __HxSetGag(Handle plugin, int numParams)
{
	char sTeamID[24];
	GetNativeString(1, sTeamID, sizeof(sTeamID)-1);
	int iTime = GetNativeCell(2);

	if (sTeamID[0])
	{
		if (iTime > 0)
		{
			int iGag = GetTime() + iTime;
			if (hg_kv)
			{
				LogMessage("Gag: %s -> %d", sTeamID, iTime);
				hg_kv.Rewind();
				hg_kv.JumpToKey(sTeamID, true);
				hg_kv.SetNum("gag", iGag);

				hg_kv.Rewind();
				hg_kv.ExportToFile(sg_fileTxt);
				return 1;
			}
		}
	}

	return 0;
}

public int __HxSetMute(Handle plugin, int numParams)
{
	char sTeamID[24];
	GetNativeString(1, sTeamID, sizeof(sTeamID)-1);
	int iTime = GetNativeCell(2);

	if (sTeamID[0])
	{
		if (iTime > 0)
		{
			int iMute = GetTime() + iTime;
			if (hg_kv)
			{
				LogMessage("Mute: %s -> %d", sTeamID, iTime);
				hg_kv.Rewind();
				hg_kv.JumpToKey(sTeamID, true);
				hg_kv.SetNum("mute", iMute);

				hg_kv.Rewind();
				hg_kv.ExportToFile(sg_fileTxt);
				return 1;
			}
		}
	}

	return 0;
}

public int __HxGarbageCollection(Handle plugin, int numParams)
{
	char sTeamID[50];
	int iTime = GetTime();
	int iDelete;
	int iMute;
	int iGag;
	int iBan;

	if (hg_kv)
	{
		hg_kv.Rewind();
		if (hg_kv.GotoFirstSubKey())
		{
			while (hg_kv.GetSectionName(sTeamID, sizeof(sTeamID)-1))
			{
				iMute = hg_kv.GetNum("mute", 0);
				iGag = hg_kv.GetNum("gag", 0);
				iBan = hg_kv.GetNum("ban", 0);

				iDelete = 1;
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
					if (hg_kv.DeleteThis() > 0)
					{
						LogMessage("Delete: %s", sTeamID);
						continue;
					}
				}

				if (hg_kv.GotoNextKey())
				{
					continue;
				}

				break;
			}
		}

		hg_kv.Rewind();
		hg_kv.ExportToFile(sg_fileTxt);
		return 1;
	}

	return 0;
}

void HxGetGagMuteBan(int &client)
{
	char sTeamID[24];
	int iDelete = 1;

	if (hg_kv)
	{
		hg_kv.Rewind();

		GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID)-1);
		if (hg_kv.JumpToKey(sTeamID))
		{
			int iMute = hg_kv.GetNum("mute", 0);
			int iGag = hg_kv.GetNum("gag", 0);
			int iBan = hg_kv.GetNum("ban", 0);
			int iTime = GetTime();

			if (iMute > iTime)
			{
				ServerCommand("sm_mute #%d", GetClientUserId(client));
				iDelete = 0;
			}
			if (iGag > iTime)
			{
				ServerCommand("sm_gag #%d", GetClientUserId(client));
				iDelete = 0;
			}
			if (iBan > iTime)
			{
				char sTime[24];
				FormatTime(sTime, sizeof(sTime)-1, "%Y-%m-%d %H:%M:%S", iBan);
				KickClient(client,"Banned (%s)", sTime);
				iDelete = 0;
			}

			if (iDelete)
			{
				hg_kv.DeleteThis();
				hg_kv.Rewind();
				hg_kv.ExportToFile(sg_fileTxt);
			}
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
	{
		HxGetGagMuteBan(client);
	}
}
