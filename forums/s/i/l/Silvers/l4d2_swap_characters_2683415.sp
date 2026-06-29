/*
*	Swap Characters
*	Copyright (C) 2021 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION		"1.2"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Swap Characters
*	Author	:	SilverShot
*	Descrp	:	Swap between L4D1 and L4D2 characters on command.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=321454
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.2 (01-Jul-2021)
	- Added a warning message to suggest installing the "Attachments API" plugin if missing.

1.1 (21-Mar-2020)
	- Now changes the bots names to their characters. This is for SourceMod menu lists (e.g. kick) and "status" command.
	- Names above their heads change anyway without this.

1.0 (11-Feb-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define MODEL_FRANCIS			"models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS				"models/survivors/survivor_manager.mdl"
#define MODEL_ZOEY				"models/survivors/survivor_teenangst.mdl"
#define MODEL_BILL				"models/survivors/survivor_namvet.mdl"

#define MODEL_NICK 				"models/survivors/survivor_gambler.mdl"
#define MODEL_ROCHELLE			"models/survivors/survivor_producer.mdl"
#define MODEL_COACH				"models/survivors/survivor_coach.mdl"
#define MODEL_ELLIS				"models/survivors/survivor_mechanic.mdl"

#define SET_NICK				0, 4, MODEL_BILL
#define SET_ROCHELLE			1, 5, MODEL_ZOEY
#define SET_COACH				2, 7, MODEL_LOUIS
#define SET_ELLIS				3, 6, MODEL_FRANCIS

#define SET_BILL				4, 0, MODEL_NICK
#define SET_ZOEY				5, 1, MODEL_ROCHELLE
#define SET_FRANCIS				6, 3, MODEL_ELLIS
#define SET_LOUIS				7, 2, MODEL_COACH



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo = {
	name = "[L4D2] Swap Characters",
	author = "SilverShot",
	description = "Swap between L4D1 and L4D2 characters on command.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=321454"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	// Attachments API
	if( FindConVar("attachments_api_version") == null )
	{
		LogMessage("\n==========\nWarning: You should install \"[ANY] Attachments API\" to fix weapons and model attachments when changing character models: https://forums.alliedmods.net/showthread.php?t=325651\n==========\n");
	}
}

public void OnPluginStart()
{
	RegAdminCmd("sm_l4d1",	CmdL4D1, ADMFLAG_ROOT, "Swap to L4D1 characters.");
	RegAdminCmd("sm_l4d2",	CmdL4D2, ADMFLAG_ROOT, "Swap to L4D2 characters.");

	CreateConVar("l4d2_swap_characters_version", PLUGIN_VERSION, "Swap Characters plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public void OnMapStart()
{
	PrecacheModel(MODEL_FRANCIS);
	PrecacheModel(MODEL_LOUIS);
	PrecacheModel(MODEL_ZOEY);
	PrecacheModel(MODEL_BILL);

	PrecacheModel(MODEL_NICK);
	PrecacheModel(MODEL_ROCHELLE);
	PrecacheModel(MODEL_COACH);
	PrecacheModel(MODEL_ELLIS);
}

public Action CmdL4D1(int client, int args)
{
	SwapCharacters(true);
	return Plugin_Handled;
}

public Action CmdL4D2(int client, int args)
{
	SwapCharacters(false);
	return Plugin_Handled;
}

void SwapCharacters(bool l4d1)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 )
		{
			if( l4d1 )
			{
				DoSwap(i, SET_NICK);
				DoSwap(i, SET_ROCHELLE);
				DoSwap(i, SET_COACH);
				DoSwap(i, SET_ELLIS);
			} else {
				DoSwap(i, SET_BILL);
				DoSwap(i, SET_ZOEY);
				DoSwap(i, SET_FRANCIS);
				DoSwap(i, SET_LOUIS);
			}
		}
	}
}

void DoSwap(int client, int from, int to, const char[] sTo)
{
	if( from == GetEntProp(client, Prop_Send, "m_survivorCharacter") )
	{
		if( IsFakeClient(client) )
		{
			switch( to )
			{
				case 0: SetClientName(client, "Nick");
				case 1: SetClientName(client, "Rochelle");
				case 2: SetClientName(client, "Coach");
				case 3: SetClientName(client, "Ellis");
				case 4: SetClientName(client, "Bill");
				case 5: SetClientName(client, "Zoey");
				case 6: SetClientName(client, "Francis");
				case 7: SetClientName(client, "Louis");
			}
		}

		SetEntProp(client, Prop_Send, "m_survivorCharacter", to);
		SetEntityModel(client, sTo);
	}
}