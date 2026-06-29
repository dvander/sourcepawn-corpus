/*
    This file is part of SourcePawn SteamWorks.

    SourcePawn SteamWorks is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, as per version 3 of the License.

    SourcePawn SteamWorks is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with SourcePawn SteamWorks.  If not, see <http://www.gnu.org/licenses/>.
	
	Author: Kyle Sanderson (KyleS).
*/

#pragma semicolon 1
#include <sourcemod>
#include <nextmap>

new String:g_sBuildPath[256];
new Handle:g_hFile = INVALID_HANDLE;
new Handle:g_hRoundTime = INVALID_HANDLE;

new bool:g_bServerSaved[MAXPLAYERS+1];
new bool:g_bSaved;

public Plugin:myinfo =
{
    name 			=		"Cassandra",				/* https://www.youtube.com/watch?v=YLO7tCdBVrA&hd=1 */
    author			=		"Kyle Sanderson",
    description		=		"Harbinger of things to come.",
    version			=		"1.0",
    url				=		"http://SourceMod.net"
};

public OnPluginStart()
{
	BuildPath(Path_SM, g_sBuildPath, sizeof(g_sBuildPath), "data/RestoreState.txt");
	g_hRoundTime = FindConVar("mp_roundtime");
}

public OnMapStart()
{
	static bool:bSkipNextFire = false, newtime = 0;
	decl String:sMap[PLATFORM_MAX_PATH];
	
	if (bSkipNextFire)
	{
		SetConVarInt(g_hRoundTime, newtime);
		bSkipNextFire = false;
		newtime = 0;
		return;
	}

	if (g_hFile != INVALID_HANDLE)
	{
		CloseHandle(g_hFile);
	}
	else if (FileExists(g_sBuildPath))
	{
		new iModTime = GetFileTime(g_sBuildPath, FileTime_LastChange);
		iModTime = ((GetTime() - iModTime) / 60);
		if (iModTime > 0 && iModTime < GetConVarInt(g_hRoundTime))
		{
			g_hFile = OpenFile(g_sBuildPath, "r");
			if (g_hFile != INVALID_HANDLE)
			{
				ReadFileLine(g_hFile, sMap, sizeof(sMap));
				TrimString(sMap);
				if (sMap[0] == '1')
				{
					ReadFileLine(g_hFile, sMap, sizeof(sMap));
					TrimString(sMap);
					CloseHandle(g_hFile);

					bSkipNextFire = true;
					g_hFile = OpenFile(g_sBuildPath, "w");
					WriteFileLine(g_hFile, "2\n%s", sMap);
					FlushFile(g_hFile);
					
					ForceChangeLevel(sMap, "Cassandra");
					newtime = iModTime;
					g_bSaved = true;
				}

				return;
			}
		}
	}

	g_hFile = OpenFile(g_sBuildPath, "w");
	if (g_hFile == INVALID_HANDLE)
	{
		return;
	}

	if (!GetCurrentMap(sMap, sizeof(sMap)))
	{
		return;
	}

	WriteFileLine(g_hFile, "1\n%s", sMap, false);
	FlushFile(g_hFile);
}

public OnClientPutInServer(client)
{
	if (!g_bSaved || g_bServerSaved[client])
	{
		return;
	}

	new Float:fTime = GetEngineTime();
	if (fTime > 30.0)
	{
		g_bSaved = false;
		g_bServerSaved[client] = true;
		return;
	}

	g_bServerSaved[client] = true;
	PrintToChat(client, "\x05[Cassandra]\x04 Hello %N.\nReport a bug if you keep seeing this. Thanks!", client);
}
