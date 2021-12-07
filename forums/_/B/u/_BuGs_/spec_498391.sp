/**
 * ===============================================================
 * Spec for cash, Copyright (C) 2007
 * All rights reserved.
 * ===============================================================
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * To view the latest information, see: 
 * 	Author(s):	Shane A. ^BuGs^ Froebel
 *
 *	Use at your OWN risk! Please submit your changes of this
 *	script to Shane. Known issues/Submit bug reports at:
 *	
 *		http://bugs.alliedmods.net/?project=9&do=index
 *	
 *	If you post bug reports over the forums, they will not be taken.
 *
 *	Thanks...                 
 *	  -- Shane A. Froebel
 *
**/ 

#pragma semicolon 1
#include <sourcemod>

#define SPEC_VERSION "1.0.1.0"
#define BUILDD __DATE__
#define BUILDT __TIME__

new Handle:g_StartMoney = INVALID_HANDLE;
new g_MoneyOffset = -1;
new PlayerOldTeam[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "Spec for Cash",
	author = "Shane A. ^BuGs^ Froebel",
	description = "Disables people from gaining cash for specing and re-joining their former team.",
	version = SPEC_VERSION,
	url = "http://bugssite.org/"
}

public OnPluginStart() 
{

	CreateConVar("sm_speccash_buildversion", SOURCEMOD_VERSION, "The version of 'Spec for Cash' was built on.", FCVAR_PLUGIN);
	CreateConVar("sm_speccash_version", SPEC_VERSION, "The version of 'Spec for Cash' running.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_MoneyOffset = FindSendPropOffs("CCSPlayer","m_iAccount");
	g_StartMoney = FindConVar("mp_startmoney");
	
	CreateTimer(1.0, OnPluginStart_Delayed);
}

public Action:OnPluginStart_Delayed(Handle:timer)
{
	if(!HookEventEx("player_team", Event_PlayerTeam, EventHookMode_Pre))
	{
		decl String:Error[PLATFORM_MAX_PATH + 64];
		FormatEx(Error, sizeof(Error), "[SC] FATAL *** ERROR *** Could not load hook: player_team");
		SetFailState(Error);
	}
}

public SpecConsole_Debug(String:text[], any:...)
{
	new String:message[255];
	VFormat(message, sizeof(message), text, 2);
	PrintToServer("[SC DEBUG] %s", message);
}

public SpecConsole_Server(String:text[], any:...)
{
	new String:message[255];
	VFormat(message, sizeof(message), text, 2);
	PrintToServer("[SC] %s", message);
}

//	Functions..

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Userid = GetEventInt(event, "userid");
	new NewTeamid = GetEventInt(event, "team");
		
	if (NewTeamid != 0)
	{
		if (PlayerOldTeam[Userid] == NewTeamid)
		{
			//	 Take away their' cash that they get from the server..
			new CurrentCash = GetPlayerCash(GetClientOfUserId(Userid));
			new NewCash = CurrentCash - GetConVarInt(g_StartMoney);
			SetPlayerCash(GetClientOfUserId(Userid), NewCash);
		}
		PlayerOldTeam[Userid] = NewTeamid;
	}
}

public GetPlayerCash(entity)
{
	return GetEntData(entity, g_MoneyOffset);
}

public SetPlayerCash(entity, amount)
{
	if (amount > 16000)
	{
		SetEntData(entity, g_MoneyOffset, 16000, _, true);
	} else {
		SetEntData(entity, g_MoneyOffset, amount, _, true);
	}
}