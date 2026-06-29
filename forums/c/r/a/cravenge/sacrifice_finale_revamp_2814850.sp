/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Sacrifice Finale Revamp Plug-in
 * Changes how "sacrifice" finales behave slightly
 *
 * Sacrifice Finale Revamp (C)2023-2024 cravenge. All rights reserved
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

#define PLUGIN_VERSION "1.0.0.0"

public Plugin myinfo = 
{
	name = "Sacrifice Finale Revamp",
	description = "Changes how \"sacrifice\" finales behave slightly",
	author = "cravenge",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=344960"
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
MemoryPatch mpSFR[2];
bool bSBAllBot, bAllowAllBotSurvivorTeam;

#endif
public void OnPluginStart()
{
	CreateConVar("sacrifice_finale_revamp_version", PLUGIN_VERSION, "", FCVAR_NOTIFY);
#if !defined _gamefixes_included
	
 #if !defined _left4stuff_included
	if (engineVers == Engine_Left4Dead)
 #else
	if (IsL4D())
 #endif
	{
		FindConVar("sb_all_bot_team").AddChangeHook(OnSBAllBotCVarChanged);
	}
	else
	{
		FindConVar("sb_all_bot_game").AddChangeHook(OnSBAllBotCVarChanged);
		FindConVar("allow_all_bot_survivor_team").AddChangeHook(OnAllowAllBotSurvivorTeamCVarChanged);
	}
	
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
void OnSBAllBotCVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	bSBAllBot = convar.BoolValue;
	if (!bSBAllBot)
	{
		if (!mpSFR[0].Disable())
		{
			return;
		}
		
		if (mpSFR[1] != null)
		{
			mpSFR[1].Disable();
		}
	}
	else
	{
 #if !defined _left4stuff_included
		if (engineVers == Engine_Left4Dead2 && !bAllowAllBotSurvivorTeam)
 #else
		if (IsL4D2() && !bAllowAllBotSurvivorTeam)
 #endif
		{
			return;
		}
		
		if (mpSFR[0].Enable())
		{
			if (mpSFR[1] == null)
			{
				return;
			}
			
			mpSFR[1].Enable();
		}
	}
}

void OnAllowAllBotSurvivorTeamCVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	bAllowAllBotSurvivorTeam = convar.BoolValue;
	if (!bAllowAllBotSurvivorTeam)
	{
		if (!mpSFR[0].Disable())
		{
			return;
		}
		
		if (mpSFR[1] != null)
		{
			mpSFR[1].Disable();
		}
	}
	else
	{
		if (!bSBAllBot)
		{
			return;
		}
		
		if (mpSFR[0].Enable())
		{
			if (mpSFR[1] == null)
			{
				return;
			}
			
			mpSFR[1].Enable();
		}
	}
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
 #if !defined _cravengelib_included
enum OS
{
	OS_Unknown,
	OS_Windows,
	OS_Linux,
	OS_Mac
}

 #endif
void InitPlugin()
{
	GameData gdTemp = ObtainGameData("sacrifice_finale_revamp");
	if (gdTemp == null)
		SetFailState("\"sacrifice_finale_revamp.txt\" was not found in the \"gamedata\" folder!");
	
	char sTemp[64] = "UpdateDLC3FinaleFailureConditions_AliveHumanSurvivorsCondition";
	
	for (int i = 0; i < 2; i++)
	{
		if (!i)
		{
 #if !defined _left4stuff_included
			if (engineVers != Engine_Left4Dead)
 #else
			if (!IsL4D())
 #endif
			{
				ReplaceStringEx(sTemp, sizeof(sTemp), "DLC3FinaleFailureConditions", "SacrificeFinaleFailure");
			}
		}
		else
		{
			ReplaceStringEx(sTemp, sizeof(sTemp), "AliveHumanSurvivorsCondition", "NoAlivePlayersDebug");
		}
		
		mpSFR[i] = MemoryPatch.FromConf(gdTemp, sTemp);
		if (mpSFR[i] == null)
		{
			SetFailState("Failed to create MemoryPatch handle for \"%s\"!", sTemp);
		}
		else if (!mpSFR[i].Validate())
		{
			SetFailState("The bytes found in the patch's address don't match the ones provided in the game data file!");
		}
		
		PrintToServer("[SFR] MemoryPatch handle for \"%s\" has been created successfully!", sTemp);
		if (GetOS() == OS_Windows)
		{
			break;
		}
	}
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
	hndl.WriteLine("	\"left4dead\"");
	hndl.WriteLine("	{");
	hndl.WriteLine("		\"Patches\"");
	hndl.WriteLine("		{");
	hndl.WriteLine("			\"UpdateDLC3FinaleFailureConditions_AliveHumanSurvivorsCondition\"");
	hndl.WriteLine("			{");
	hndl.WriteLine("				\"signature\"		\"Director::UpdateDLC3FinaleFailureConditions\"");
	hndl.WriteLine("				\"linux\"");
	hndl.WriteLine("				{");
	hndl.WriteLine("					\"offset\"	\"15Bh\"");
	hndl.WriteLine("					\"match\"		\"\\x85\\xC0\\x0F\\x8E\"");
	hndl.WriteLine("					\"overwrite\"	\"\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\"");
	hndl.WriteLine("				}");
	hndl.WriteLine("				\"windows\"");
	hndl.WriteLine("				{");
	hndl.WriteLine("					\"offset\"	\"E0h\"");
	hndl.WriteLine("					\"match\"		\"\\x83\\xF8\\x01\\x7D\\x2A\\x68\\x2A\\x2A\\x2A\\x2A\\xEB\"");
	hndl.WriteLine("					\"overwrite\"	\"\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\"");
	hndl.WriteLine("				}");
	hndl.WriteLine("			}");
	hndl.WriteLine("			\"UpdateDLC3FinaleFailureConditions_NoAlivePlayersDebug\"");
	hndl.WriteLine("			{");
	hndl.WriteLine("				\"linux\"");
	hndl.WriteLine("				{");
	hndl.WriteLine("					\"signature\"	\"Director::UpdateDLC3FinaleFailureConditions\"");
	hndl.WriteLine("					\"offset\"	\"469h\"");
	hndl.WriteLine("					\"match\"		\"\\x8D\\x83\\x2A\\x2A\\x2A\\x2A\\x89\\x04\\x24\\xE8\\x2A\\x2A\\x2A\\x2A\\x8B\\x84\\x24\\x2A\\x2A\\x2A\\x2A\\xC6\\x80\\x2A\\x2A\\x2A\\x2A\\x01\\xE9\"");
	hndl.WriteLine("					\"overwrite\"	\"\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\"");
	hndl.WriteLine("				}");
	hndl.WriteLine("			}");
	hndl.WriteLine("		}");
	hndl.WriteLine("		\"Signatures\"");
	hndl.WriteLine("		{");
	hndl.WriteLine("			\"Director::UpdateDLC3FinaleFailureConditions\"");
	hndl.WriteLine("			{");
	hndl.WriteLine("				\"linux\"		\"@_ZN8Director33UpdateDLC3FinaleFailureConditionsEv\"");
	hndl.WriteLine("				\"windows\"	\"\\x83\\xEC\\x2A\\x53\\x55\\x8B\\xD9\\x80\\xBB\\x2A\\x2A\\x2A\\x2A\\x00\\x56\\x57\\x89\\x5C\\x24\\x2A\\xBD\"");
	hndl.WriteLine("				/* 83 EC ? 53 55 8B D9 80 BB ? ? ? ? 00 56 57 89 5C 24 ? BD */");
	hndl.WriteLine("			}");
	hndl.WriteLine("		}");
	hndl.WriteLine("	}");
	hndl.WriteLine("	\"left4dead2\"");
	hndl.WriteLine("	{");
	hndl.WriteLine("		\"Patches\"");
	hndl.WriteLine("		{");
	hndl.WriteLine("			\"UpdateSacrificeFinaleFailure_AliveHumanSurvivorsCondition\"");
	hndl.WriteLine("			{");
	hndl.WriteLine("				\"signature\"		\"CDirectorScriptedEventManager::UpdateSacrificeFinaleFailure\"");
	hndl.WriteLine("				\"linux\"");
	hndl.WriteLine("				{");
	hndl.WriteLine("					\"offset\"	\"15Dh\"");
	hndl.WriteLine("					\"match\"		\"\\x85\\xC0\\x0F\\x8E\"");
	hndl.WriteLine("					\"overwrite\"	\"\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\"");
	hndl.WriteLine("				}");
	hndl.WriteLine("				\"windows\"");
	hndl.WriteLine("				{");
	hndl.WriteLine("					\"offset\"	\"138h\"");
	hndl.WriteLine("					\"match\"		\"\\x83\\xF8\\x01\\x7D\\x2A\\x68\\x2A\\x2A\\x2A\\x2A\\xEB\"");
	hndl.WriteLine("					\"overwrite\"	\"\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\"");
	hndl.WriteLine("				}");
	hndl.WriteLine("			}");
	hndl.WriteLine("			\"UpdateSacrificeFinaleFailure_NoAlivePlayersDebug\"");
	hndl.WriteLine("			{");
	hndl.WriteLine("				\"linux\"");
	hndl.WriteLine("				{");
	hndl.WriteLine("					\"signature\"	\"CDirectorScriptedEventManager::UpdateSacrificeFinaleFailure\"");
	hndl.WriteLine("					\"offset\"	\"3BCh\"");
	hndl.WriteLine("					\"match\"		\"\\xC7\\x04\\x24\\x2A\\x2A\\x2A\\x2A\\xE8\"");
	hndl.WriteLine("					\"overwrite\"	\"\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\\x90\"");
	hndl.WriteLine("				}");
	hndl.WriteLine("			}");
	hndl.WriteLine("		}");
	hndl.WriteLine("		\"Signatures\"");
	hndl.WriteLine("		{");
	hndl.WriteLine("			\"CDirectorScriptedEventManager::UpdateSacrificeFinaleFailure\"");
	hndl.WriteLine("			{");
	hndl.WriteLine("				\"linux\"		\"@_ZN29CDirectorScriptedEventManager28UpdateSacrificeFinaleFailureEv\"");
	hndl.WriteLine("				\"windows\"	\"\\x55\\x8B\\xEC\\x83\\xEC\\x2A\\x53\\x8B\\xD9\\x80\\xBB\\x2A\\x2A\\x2A\\x2A\\x00\\x0F\\x84\\x2A\\x2A\\x2A\\x2A\\xA1\"");
	hndl.WriteLine("				/* 55 8B EC 83 EC ? 53 8B D9 80 BB ? ? ? ? 00 0F 84 ? ? ? ? A1 */");
	hndl.WriteLine("			}");
	hndl.WriteLine("		}");
	hndl.WriteLine("	}");
}
 #if !defined _cravengelib_included

OS GetOS()
{
	static OS os;
	if (os == OS_Unknown)
	{
		char sCmdLine[4];
		GetCommandLine(sCmdLine, sizeof(sCmdLine));
		
		os = (sCmdLine[0] != '.') ? OS_Windows : OS_Linux;
	}
	return os;
}
 #endif
#endif