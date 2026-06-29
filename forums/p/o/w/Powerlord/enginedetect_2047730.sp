/**
 * vim: set ts=4 :
 * =============================================================================
 * Engine Detector
 * Copyright (C) 2013 Ross Bemrose (Powerlord).  All rights reserved.
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
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "Engine Detector",
	author = "Powerlord",
	description = "Print out what game engine SourceMod thinks you're running. This plugin is a diagnostic tool.",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?t=208008"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("GetEngineVersion");
}

public OnPluginStart()
{
	RegAdminCmd("enginever", Cmd_EngineVersion, ADMFLAG_GENERIC, "Print engine version");
	RegAdminCmd("oldenginever", Cmd_EngineVersionOld, ADMFLAG_GENERIC, "Print engine version using old detection method");
}

public Action:Cmd_EngineVersion(client, args)
{
	if (GetFeatureStatus(FeatureType_Native, "GetEngineVersion") != FeatureStatus_Available)
	{
		ReplyToCommand(client, "New Engine Detection is not available, old engine detection will be used");
		LogMessage("New Engine Detection is not available, old engine detection will be used");
	}
	new EngineVersion:version = GetEngineVersionCompat();

	new String:printName[64];
	
	PrintEngineVersion(version, printName, sizeof(printName));
	
	ReplyToCommand(client, "New Engine Detection says you're running: %s", printName);
	LogMessage("Old Engine Detection says you're running: %s", printName);
}

public Action:Cmd_EngineVersionOld(client, args)
{
	new EngineVersion:version = GetEngineVersionCompat(true);
	
	new String:printName[64];
	
	PrintEngineVersion(version, printName, sizeof(printName));

	ReplyToCommand(client, "Old Engine Detection says you're running: %s", printName);
	LogMessage("Old Engine Detection says you're running: %s", printName);
}

// Using this stock REQUIRES you to add the following to AskPluginLoad2:
// MarkNativeAsOptional("GetEngineVersion");
stock EngineVersion:GetEngineVersionCompat(bool:forceOld=false)
{
	new EngineVersion:version;
	if (forceOld == false || GetFeatureStatus(FeatureType_Native, "GetEngineVersion") != FeatureStatus_Available)
	{
		new sdkVersion = GuessSDKVersion();
		switch (sdkVersion)
		{
			case SOURCE_SDK_ORIGINAL:
			{
				version = Engine_Original;
			}
			
			case SOURCE_SDK_DARKMESSIAH:
			{
				version = Engine_DarkMessiah;
			}
			
			case SOURCE_SDK_EPISODE1:
			{
				version = Engine_SourceSDK2006;
			}
			
			case SOURCE_SDK_EPISODE2:
			{
				version = Engine_SourceSDK2007;
			}
			
			case SOURCE_SDK_BLOODYGOODTIME:
			{
				version = Engine_BloodyGoodTime;
			}
			
			case SOURCE_SDK_EYE:
			{
				version = Engine_EYE;
			}
			
			case SOURCE_SDK_CSS:
			{
				version = Engine_CSS;
			}
			
			case SOURCE_SDK_EPISODE2VALVE:
			{
				decl String:gameFolder[PLATFORM_MAX_PATH];
				GetGameFolderName(gameFolder, PLATFORM_MAX_PATH);
				if (StrEqual(gameFolder, "dod", false))
				{
					version = Engine_DODS;
				}
				else if (StrEqual(gameFolder, "hl2mp", false))
				{
					version = Engine_HL2DM;
				}
				else
				{
					version = Engine_TF2;
				}
			}
			
			case SOURCE_SDK_LEFT4DEAD:
			{
				version = Engine_Left4Dead;
			}
			
			case SOURCE_SDK_LEFT4DEAD2:
			{
				decl String:gameFolder[PLATFORM_MAX_PATH];
				GetGameFolderName(gameFolder, PLATFORM_MAX_PATH);
				if (StrEqual(gameFolder, "nd", false))
				{
					version = Engine_NuclearDawn;
				}
				else
				{
					version = Engine_Left4Dead2;
				}
			}
			
			case SOURCE_SDK_ALIENSWARM:
			{
				version = Engine_AlienSwarm;
			}
			
			case SOURCE_SDK_CSGO:
			{
				version = Engine_CSGO;
			}
			
			default:
			{
				version = Engine_Unknown;
			}
		}
	}
	else
	{
		version = GetEngineVersion();
	}
	
	return version;
}

stock PrintEngineVersion(EngineVersion:version, String:printName[], maxlength)
{
	switch (version)
	{
		case Engine_Unknown:
		{
			strcopy(printName, maxlength, "Unknown");
		}
		
		case Engine_Original:				
		{
			strcopy(printName, maxlength, "Original");
		}
		
		case Engine_SourceSDK2006:
		{
			strcopy(printName, maxlength, "Source SDK 2006");
		}
		
		case Engine_SourceSDK2007:
		{
			strcopy(printName, maxlength, "Source SDK 2007");
		}
		
		case Engine_Left4Dead:
		{
			strcopy(printName, maxlength, "Left 4 Dead ");
		}
		
		case Engine_DarkMessiah:
		{
			strcopy(printName, maxlength, "Dark Messiah");
		}
		
		case Engine_Left4Dead2:
		{
			strcopy(printName, maxlength, "Left 4 Dead 2");
		}
		
		case Engine_AlienSwarm:
		{
			strcopy(printName, maxlength, "Alien Swarm");
		}
		
		case Engine_BloodyGoodTime:
		{
			strcopy(printName, maxlength, "Bloody Good Time");
		}
		
		case Engine_EYE:
		{
			strcopy(printName, maxlength, "E.Y.E. Divine Cybermancy");
		}
		
		case Engine_Portal2:
		{
			strcopy(printName, maxlength, "Portal 2");
		}
		
		case Engine_CSGO:
		{
			strcopy(printName, maxlength, "Counter-Strike: Global Offensive");
		}
		
		case Engine_CSS:
		{
			strcopy(printName, maxlength, "Counter-Strike: Source");
		}
		
		case Engine_DOTA:
		{
			strcopy(printName, maxlength, "DOTA 2");
		}
		
		case Engine_HL2DM:
		{
			strcopy(printName, maxlength, "Half-Life 2: Deathmatch");
		}
		
		case Engine_DODS:
		{
			strcopy(printName, maxlength, "Day of Defeat: Source");
		}
		
		case Engine_TF2:
		{
			strcopy(printName, maxlength, "Team Fortress 2");
		}
		
		case Engine_NuclearDawn:
		{
			strcopy(printName, maxlength, "Nuclear Dawn");
		}
	}
}