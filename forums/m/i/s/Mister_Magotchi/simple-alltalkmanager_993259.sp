/************************************************************************
*************************************************************************
Simple AllTalk Manager
Description:
	Allows you to set alltalk at different times
*************************************************************************
*************************************************************************
This file is part of Simple Plugins project.

This plugin is free software: you can redistribute 
it and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the License, or
later version. 

This plugin is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
*************************************************************************
*************************************************************************
File Information
$Id: simple-alltalkmanager.sp 7 2009-09-27 04:58:48Z antithasys $
$Author: antithasys $
$Revision: 7 $
$Date: 2009-09-26 23:58:48 -0500 (Sat, 26 Sep 2009) $
$LastChangedBy: antithasys $
$LastChangedDate: 2009-09-26 23:58:48 -0500 (Sat, 26 Sep 2009) $
$URL: https://svn.simple-plugins.com/svn/simpleplugins/trunk/addons/sourcemod/scripting/simple-alltalkmanager.sp $
$Copyright: (c) Simple Plugins 2008-2009$
*************************************************************************
*************************************************************************
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.3.0"

new Handle:satm_enabled = INVALID_HANDLE;
new Handle:satm_threshold_enabled = INVALID_HANDLE;
new Handle:satm_player_threshold = INVALID_HANDLE;
new Handle:satm_threshold_setting = INVALID_HANDLE;
new Handle:satm_logactivity = INVALID_HANDLE;
new Handle:satm_alltalk = INVALID_HANDLE;

new Handle:g_aEventNames = INVALID_HANDLE;
new Handle:g_aEventReasons = INVALID_HANDLE;
new Handle:g_aEventSettings = INVALID_HANDLE;

new bool:g_bLastThreshold = false;
new bool:g_bEnabled = true;
new bool:g_bThresholdEnabled = true;
new bool:g_bIsSetupMap = false;
new bool:g_bIsGameTF2 = false;
new bool:g_bLogActivity = false;

new g_iLastEventIndex;

public Plugin:myinfo =
{
	name = "Simple AllTalk Manager",
	author = "Simple Plugins",
	description = "Allows you to set alltalk at different times",
	version = PLUGIN_VERSION,
	url = "http://www.simple-plugins.com"
}

/**
Sourcemod callbacks
*/
public OnPluginStart()
{
	
	/**
	Need to create all of our console variables.
	*/
	CreateConVar("satm_version", PLUGIN_VERSION, "Simple AllTalk Manager", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	satm_enabled = CreateConVar("satm_enabled", "1", "Enables/Disables Simple AllTalk Manager", _, true, 0.0, true, 1.0);
	satm_threshold_enabled = CreateConVar("satm_threshold_enabled", "1", "Enables/Disables player threshold", _, true, 0.0, true, 1.0);
	satm_player_threshold = CreateConVar("satm_player_threshold", "8", "Amount of players for the threshold");
	satm_threshold_setting = CreateConVar("satm_threshold_setting", "1", "Enables/Disables all talk up to player threshold, with the opposite set after the threshold", _, true, 0.0, true, 1.0);
	satm_logactivity = CreateConVar("satm_logactivity", "0", "Enables/Disables log activity", _, true, 0.0, true, 1.0);
	satm_alltalk = FindConVar("sv_alltalk");
	
	/**
	Hook console variables
	*/
	HookConVarChange(satm_enabled, ConVarSettingsChanged);
	HookConVarChange(satm_threshold_enabled, ConVarSettingsChanged);
	HookConVarChange(satm_player_threshold, ConVarSettingsChanged);
	HookConVarChange(satm_logactivity, ConVarSettingsChanged);
	
	/**
	Remove the notify flag from all talk cvar since we do it
	*/
	SetConVarFlags(satm_alltalk, GetConVarFlags(satm_alltalk)^FCVAR_NOTIFY);
	
	/**
	Get the game type.  We only care if it's TF2
	*/
	new String:sGameType[64];
	GetGameFolderName(sGameType, sizeof(sGameType));
	if (StrEqual(sGameType, "tf", false))
	{
		g_bIsGameTF2 = true;
	}
	
	/**
	Create the arrays
	*/
	g_aEventNames = CreateArray(255, 1);
	g_aEventReasons = CreateArray(255, 1);
	g_aEventSettings = CreateArray(1, 1);
	
	/**
	Need to register the commands we are going to create and use.
	*/
	RegAdminCmd("sm_reloadatconfig", Command_Reload, ADMFLAG_GENERIC,  "Reloads settings from config file");
	
	/**
	Create the config file
	*/
	AutoExecConfig(true);
	
	/**
	Load the events from the config
	*/
	LoadEventsFromConfig();
}

public OnConfigsExecuted()
{
	
	/**
	Load up the settings
	*/
	g_bEnabled = GetConVarBool(satm_enabled);
	g_bLogActivity = GetConVarBool(satm_logactivity);
	g_bThresholdEnabled = GetConVarBool(satm_threshold_enabled);
}

public OnMapStart()
{
	
	/**
	Reset the globals
	*/
	g_iLastEventIndex = 0;
	g_bLastThreshold = false;
	
	/**
	Check the map type if we are in TF2
	*/
	if (g_bIsGameTF2)
	{
		g_bIsSetupMap = IsSetupPeriodMap();
	}
	
	/**
	Set AllTalk
	*/
	if (g_bEnabled)
	{
		SetConVarBool(satm_alltalk, true);
	}
}

public OnClientDisconnect_Post(client)
{
	if (g_bEnabled)
	{
		SetAllTalk(-1);
	}
}

public OnClientPostAdminCheck(client)
{
	if (g_bEnabled)
	{
		SetAllTalk(-1);
	}
	CreateTimer(2.0, Timer_ShowAllTalkStatus, client, TIMER_FLAG_NO_MAPCHANGE);
}

public ConVarSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == satm_enabled) 
	{
		if (StringToInt(newValue))
		{
			g_bEnabled = true;
		}
		else
		{
			g_bEnabled = false;
		}
	}
	else if (convar == satm_threshold_enabled) 
	{
		if (StringToInt(newValue))
		{
			g_bThresholdEnabled = true;
		}
		else
		{
			g_bThresholdEnabled = false;
		}
	}
	else if (convar == satm_logactivity)
	{
		if (StringToInt(newValue))
		{
			g_bLogActivity = true;
		}
		else
		{
			g_bLogActivity = false;
		}
	}
	if (g_bEnabled)
	{
		SetAllTalk(-1);
	}
}

/**
Commands
*/
public Action:Command_Reload(client, args)
{
	
	/**
	Clear the array
	*/
	ClearArray(g_aEventNames);
	ClearArray(g_aEventReasons);
	ClearArray(g_aEventSettings);
	
	/**
	Load the events from the config
	*/
	LoadEventsFromConfig();
	
	return Plugin_Handled;
}

/**
Game Event Hooks
*/
public Hook_All_Events(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bIsSetupMap)
	{
		if (StrEqual(name, "teamplay_round_start"))
		{
			if (FindStringInArray(g_aEventNames, "teamplay_setup_finished") != -1)
			{
				g_iLastEventIndex = FindStringInArray(g_aEventNames, "teamplay_setup_finished");
				if (g_bEnabled)
				{
					SetAllTalk(g_iLastEventIndex);
					return;
				}
			}
		}
	}
	g_iLastEventIndex = FindStringInArray(g_aEventNames, name);
	if (g_bEnabled)
	{
		SetAllTalk(g_iLastEventIndex);
	}	
}

/**
Timers
*/
public Action:Timer_ShowAllTalkStatus(Handle:timer, any:client)
{
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		new bool:bSetting = GetConVarBool(satm_alltalk);
		if (bSetting)
		{
			PrintToChat(client, "\x01\x04[SM] AllTalk is \x01[on]");
		}
		else
		{
			PrintToChat(client, "\x01\x04[SM] AllTalk is \x01[off]");
		}
	}
}

/**
Stock Functions
*/
stock LoadEventsFromConfig()
{
	
	/**
	Make sure the config file is here and load it up
	*/
	new String:sConfigFile[256];
	BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "configs/simple-alltalkmanager_events.cfg");
	if (!FileExists(sConfigFile)) 
	{
        
		/**
		Config file doesn't exists, stop the plugin
		*/
		LogError("[SATM] Simple AllTalk Manager is not running! Could not find file %s", sConfigFile);
		SetFailState("Could not find file %s", sConfigFile);
    }
	
	/**
	Create the arrays and variables
	*/
	new String:sGameEventName[256];
	new String:sReason[256];
	new iSetting;
	
	/**
	Load config file as a KeyValues file
	*/
	new Handle:kvGameEvents = CreateKeyValues("game_events");
	FileToKeyValues(kvGameEvents, sConfigFile);
	
	if (!KvGotoFirstSubKey(kvGameEvents))
	{
		return;
	}
	
	/**
	Hook the game events and load the settings
	*/
	do
	{
		
		/**
		Get the section name; this should be the event name
		*/
		KvGetSectionName(kvGameEvents, sGameEventName, sizeof(sGameEventName));
		if (!HookEventEx(sGameEventName, Hook_All_Events, EventHookMode_PostNoCopy))
		{
			
			/**
			Could not hook this event, stop the plugin
			*/
			SetFailState("Could not hook event %s", sGameEventName);
		}
		else
		{
			if (g_bLogActivity)
			{
				LogMessage("[SATM] Hooked event: %s", sGameEventName);
			}
		}
		
		/**
		Get the reason string and setting
		*/
		KvGetString(kvGameEvents, "reason", sReason, sizeof(sReason));
		iSetting = KvGetNum(kvGameEvents, "setting");
		if (g_bLogActivity)
		{
			LogMessage("[SATM] Event reason string: %s", sReason);
			LogMessage("[SATM] Event setting: %i", iSetting);
		}
		
		/**
		Push the values to the arrays
		*/
		PushArrayString(g_aEventNames, sGameEventName);
		PushArrayString(g_aEventReasons, sReason);
		PushArrayCell(g_aEventSettings, iSetting);
	} while (KvGotoNextKey(kvGameEvents));
	
	/**
	Close our handle
	*/
	CloseHandle(kvGameEvents);
}

GetPlayerCount()
{
  new players;
  for (new i = 1; i <= MaxClients; i++)
  {
    if (IsClientInGame(i) && !IsFakeClient(i) && !IsClientObserver(i))
    {
      players++;
    }
  }
  return players;
}

stock SetAllTalk(index)
{
	new iPlayerThreshold = GetConVarInt(satm_player_threshold);
	new bool:bThresholdMet = ((GetPlayerCount() >= iPlayerThreshold) ? true : false);
	new bool:bSetting;
	
	if (g_bThresholdEnabled)
	{
		if (bThresholdMet)
		{
			if (index == -1)
			{
				if (bThresholdMet != g_bLastThreshold)
				{
					g_bLastThreshold = true;
					bSetting = !GetConVarBool(satm_threshold_setting);
					new bool:bLastSetting = GetArrayCell(g_aEventSettings, g_iLastEventIndex);
					if (bLastSetting && !bSetting)
					{
						bSetting = GetArrayCell(g_aEventSettings, g_iLastEventIndex);
					}
				}
				else
				{
					bSetting = GetArrayCell(g_aEventSettings, g_iLastEventIndex);
				}
			}
			else
			{
				bSetting = GetArrayCell(g_aEventSettings, index);
			}
		}
		else
		{
			g_bLastThreshold = false;
			bSetting = GetConVarBool(satm_threshold_setting);
		}
	}
	else
	{
		if (index != -1)
		{
			bSetting = GetArrayCell(g_aEventSettings, index);
		}
	}
	
	if (GetConVarBool(satm_alltalk) != bSetting)
	{
		
		SetConVarBool(satm_alltalk, bSetting);
		
		new String:sReason[256];
		if (index == -1)
		{
			Format(sReason, sizeof(sReason), "Player Threshold");
		}
		else
		{
			if (!g_bIsSetupMap)
			{
				new String:sCurrentEvent[256];
				GetArrayString(g_aEventNames, index, sCurrentEvent, sizeof(sCurrentEvent));
				if (StrEqual(sCurrentEvent, "teamplay_setup_finished"))
				{
					new iRoundStartIndex = FindStringInArray(g_aEventNames, "teamplay_round_start");
					if (iRoundStartIndex != -1)
					{
						GetArrayString(g_aEventReasons, iRoundStartIndex, sReason, sizeof(sReason));
					}
					else
					{
						GetArrayString(g_aEventReasons, index, sReason, sizeof(sReason));
					}
				}
				else
				{
					GetArrayString(g_aEventReasons, index, sReason, sizeof(sReason));
				}
			}
			else
			{
				GetArrayString(g_aEventReasons, index, sReason, sizeof(sReason));
			}
		}
		
		if (bSetting)
		{
			PrintToChatAll("\x01\x04[SM] AllTalk turned \x01[on] \x04due to:\x01 %s", sReason);
		}
		else
		{
			PrintToChatAll("\x01\x04[SM] AllTalk turned \x01[off] \x04due to:\x01 %s", sReason);
		}
	}
}

stock bool:IsSetupPeriodMap()
{
	new iEnt = -1;
	new String:sMapName[32];
	
	GetCurrentMap(sMapName, sizeof(sMapName));
	
	if (strncmp(sMapName, "cp_", 3, false) == 0)
	{
		new iTeam;
		while ((iEnt = FindEntityByClassname(iEnt, "team_control_point")) != -1)
		{
			iTeam = GetEntProp(iEnt, Prop_Send, "m_iTeamNum");
			
			/**
			If there is a blu CP or a neutral CP, then it's not an attack/defend map
			*/
			if (iTeam != 2)
			{
				//this is a push map
				return false;
			}
		}
		//this is a attack/defend map
		return true;
	}
	else if (strncmp(sMapName, "ctf_", 3, false) == 0)
	{
		//this is a ctf map
		return false;
	}
	return false;
}
