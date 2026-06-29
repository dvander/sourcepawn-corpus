/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Death Check Revamp Plug-in
 * Changes how the death check behaves slightly
 *
 * Death Check Revamp (C)2023-2024 cravenge. All rights reserved
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>
 *
 * Version: $Id$
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <srcscramble>

#tryinclude <cravengelib>
#tryinclude <left4stuff>
#tryinclude <game_fixes>

#define PLUGIN_VERSION "1.0.1.0"

public Plugin myinfo = 
{
	name = "Death Check Revamp",
	description = "Changes how the death check behaves slightly",
	author = "cravenge",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=344967"
};

#if !defined _gamefixes_included && !defined _left4stuff_included
EngineVersion engineVers;
#endif

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
#if defined _gamefixes_included || defined _left4stuff_included
	EngineVersion evTemp = GetEngineVersion();
	if (evTemp == Engine_Left4Dead || evTemp == Engine_Left4Dead2)
#else
	engineVers = GetEngineVersion();
	if (engineVers == Engine_Left4Dead || engineVers == Engine_Left4Dead2)
#endif
	{
#if !defined _gamefixes_included && defined _left4stuff_included
		bIsLateLoad = late;
#endif
		return APLRes_Success;
	}
	
	strcopy(error, err_max, "Plug-in supports L4D and L4D2 only");
	return APLRes_SilentFailure;
}

#if !defined _gamefixes_included
MemoryPatch mpDCR;

#endif
public void OnPluginStart()
{
	CreateConVar("death_check_revamp_version", PLUGIN_VERSION, "", FCVAR_NOTIFY);
#if !defined _gamefixes_included
	
	ConVar convarTemp = CreateConVar("director_no_incap_death_check", "0", "Disable survivor team death ending scenario if all survivors are incapacitated", FCVAR_CHEAT);
	convarTemp.AddChangeHook(OnDirectorNoIncapDeathCheckCVarChanged);
	
 #if defined _left4stuff_included
	if (!bIsLateLoad)
	{
		return;
	}
	
 #endif
	InitPlugin();
#endif
}

#if !defined _gamefixes_included
void OnDirectorNoIncapDeathCheckCVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	!convar.BoolValue ? mpDCR.Disable() : mpDCR.Enable();
}

 #if defined _left4stuff_included
public void OnAllPluginsLoaded()
{
	if (bIsLateLoad)
	{
		return;
	}
	
	InitPlugin();
}

 #endif
void InitPlugin()
{
	GameData gdTemp = ObtainGameData("death_check_revamp");
	if (gdTemp == null)
		SetFailState("\"death_check_revamp.txt\" was not found in the \"gamedata\" folder!");
	
	mpDCR = MemoryPatch.FromConf(gdTemp, "CheckForDeadPlayers_LiveSurvivorCounterCheckFlag");
	if (mpDCR == null)
	{
		SetFailState("Failed to create MemoryPatch handle for \"CheckForDeadPlayers_LiveSurvivorCounterCheckFlag\"!");
	}
	else if (!mpDCR.Validate())
	{
		SetFailState("The byte found in the patch's address doesn't match the one provided in the game data file!");
	}
	
	PrintToServer("[DCR] MemoryPatch handle for \"CheckForDeadPlayers_LiveSurvivorCounterCheckFlag\" has been created successfully!");
}

 #if defined _cravengelib_included
public void OnGameDataFileCreated(File file)
{
	WriteGameDataFile(file);
}

 #else
GameData ObtainGameData(const char[] file)
{
	char sFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "gamedata/%s.txt", file);
	if (!FileExists(sFilePath))
	{
		File fileTemp = OpenFile(sFilePath, "w");
		if (fileTemp == null)
		{
			LogError("Something went wrong while making the \"%s.txt\" file!", file);
			return view_as<GameData>(fileTemp);
		}
		
		fileTemp.WriteLine("\"Games\"");
		fileTemp.WriteLine("{");
		
		WriteGameDataFile(fileTemp);
		
		fileTemp.WriteLine("}");
		
		fileTemp.Close();
	}
	return new GameData(file);
}

 #endif
void WriteGameDataFile(File hndl)
{
	hndl.WriteLine("	\"#default\"");
	hndl.WriteLine("	{");
	hndl.WriteLine("		\"Patches\"");
	hndl.WriteLine("		{");
	hndl.WriteLine("			\"CheckForDeadPlayers_LiveSurvivorCounterCheckFlag\"");
	hndl.WriteLine("			{");
	hndl.WriteLine("				\"match\"			\"\\x01\"");
	hndl.WriteLine("				\"overwrite\"		\"\\x00\"");
	hndl.WriteLine("			}");
	hndl.WriteLine("		}");
	hndl.WriteLine("	}");
	hndl.WriteLine("	\"left4dead\"");
	hndl.WriteLine("	{");
	hndl.WriteLine("		\"Patches\"");
	hndl.WriteLine("		{");
	hndl.WriteLine("			\"CheckForDeadPlayers_LiveSurvivorCounterCheckFlag\"");
	hndl.WriteLine("			{");
	hndl.WriteLine("				\"signature\"		\"Director::CheckForDeadPlayers\"");
	hndl.WriteLine("				\"linux\"");
	hndl.WriteLine("				{");
	hndl.WriteLine("					\"offset\"	\"65h\"");
	hndl.WriteLine("				}");
	hndl.WriteLine("				\"windows\"");
	hndl.WriteLine("				{");
	hndl.WriteLine("					\"offset\"	\"55h\"");
	hndl.WriteLine("				}");
	hndl.WriteLine("			}");
	hndl.WriteLine("		}");
	hndl.WriteLine("		\"Signatures\"");
	hndl.WriteLine("		{");
	hndl.WriteLine("			\"Director::CheckForDeadPlayers\"");
	hndl.WriteLine("			{");
	hndl.WriteLine("				\"linux\"		\"@_ZN8Director19CheckForDeadPlayersEv\"");
	hndl.WriteLine("				\"windows\"	\"\\x83\\xEC\\x2A\\x53\\x55\\x56\\x57\\x8D\\x44\\x24\\x2A\\x33\\xDB\\x83\\xCF\\xFF\\x50\\x8B\\xF1\\xC7\"");
	hndl.WriteLine("				/* 83 EC ? 53 55 56 57 8D 44 24 ? 33 DB 83 CF FF 50 8B F1 C7 */");
	hndl.WriteLine("			}");
	hndl.WriteLine("		}");
	hndl.WriteLine("	}");
	hndl.WriteLine("	\"left4dead2\"");
	hndl.WriteLine("	{");
	hndl.WriteLine("		\"Patches\"");
	hndl.WriteLine("		{");
	hndl.WriteLine("			\"CheckForDeadPlayers_LiveSurvivorCounterCheckFlag\"");
	hndl.WriteLine("			{");
	hndl.WriteLine("				\"signature\"		\"CDirector::CheckForDeadPlayers\"");
	hndl.WriteLine("				\"linux\"");
	hndl.WriteLine("				{");
	hndl.WriteLine("					\"offset\"	\"7Ch\"");
	hndl.WriteLine("				}");
	hndl.WriteLine("				\"windows\"");
	hndl.WriteLine("				{");
	hndl.WriteLine("					\"offset\"	\"6Fh\"");
	hndl.WriteLine("				}");
	hndl.WriteLine("			}");
	hndl.WriteLine("		}");
	hndl.WriteLine("		\"Signatures\"");
	hndl.WriteLine("		{");
	hndl.WriteLine("			\"CDirector::CheckForDeadPlayers\"");
	hndl.WriteLine("			{");
	hndl.WriteLine("				\"linux\"		\"@_ZN9CDirector19CheckForDeadPlayersEv\"");
	hndl.WriteLine("				\"windows\"	\"\\x55\\x8B\\xEC\\x83\\xEC\\x2A\\x57\\x8B\\xF9\\x8B\\x87\\x2A\\x2A\\x2A\\x2A\\x80\\xB8\\x2A\\x2A\\x2A\\x2A\\x00\\x74\"");
	hndl.WriteLine("				/* 55 8B EC 83 EC ? 57 8B F9 8B 87 ? ? ? ? 80 B8 ? ? ? ? 00 74 */");
	hndl.WriteLine("			}");
	hndl.WriteLine("		}");
	hndl.WriteLine("	}");
}
#endif