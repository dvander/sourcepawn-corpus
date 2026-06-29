/**
 * vim: set ts=4 :
 * =============================================================================
 * Valve Translation Test
 * Test the PrintValveTranslation functions in printvalvetranslation.inc
 *
 * Valve Translation Test (C)2015 Powerlord (Ross Bemrose). All rights reserved.
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

#pragma semicolon 1
#pragma newdecls required

#include "include/printvalvetranslation.inc"

#define VERSION "1.0.0"

EngineVersion engine;

#define CSGO_SIMPLE_PHRASE "#SFUI_SessionError_KickBan_TK_Start"
#define CSGO_COMPLEX_PHRASE "#game_player_joined_autoteam"
#define CSGO_COMPLEX_PHRASE_ARG1 "SourceTV"
#define CSGO_COMPLEX_PHRASE_ARG2 "#terrorists"

#define TF2_SIMPLE_PHRASE "#TF_Eternaween__ServerReject"
#define TF2_COMPLEX_PHRASE "#TF_Arena_MaxStreak"
#define TF2_COMPLEX_PHRASE_ARG1 "#TF_RedTeam_Name"
#define TF2_COMPLEX_PHRASE_ARG2 "3"


public Plugin myinfo = {
	name			= "Valve Translation Test",
	author			= "Powerlord",
	description		= "Test the PrintValveTranslation functions in printvalvetranslation.inc",
	version			= VERSION,
	url				= ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	engine = GetEngineVersion();

	if (engine != Engine_TF2 && engine != Engine_CSGO)
	{
		strcopy(error, err_max, "Plugin only works on TF2 and CS:GO");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("valvetranslationtest_version", VERSION, "Valve Translation Test version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	
	RegAdminCmd("simplemsg", Cmd_Msg, ADMFLAG_GENERIC, "Print Simple Translation");
	RegAdminCmd("complexmsg", Cmd_Msg, ADMFLAG_GENERIC, "Print Complex Translation");
	RegAdminCmd("simplemsgtoall", Cmd_Msg, ADMFLAG_GENERIC, "Print Simple Translation");
	RegAdminCmd("complexmsgtoall", Cmd_Msg, ADMFLAG_GENERIC, "Print Complex Translation");
}

public Action Cmd_Msg(int client, int args)
{
	char commandName[64];
	GetCmdArg(0, commandName, sizeof(commandName));
	
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: %s destination", commandName);
		return Plugin_Handled;
	}

	char destinationString[2];
	GetCmdArg(1, destinationString, sizeof(destinationString));
	
	int destination = StringToInt(destinationString);
	if (destination < 1 || destination > 4)
	{
		ReplyToCommand(client, "Valid desinations are 1 through 4");
		return Plugin_Handled;
	}
	
	bool complex = false;
	bool toAll = false;
	
	if (StrEqual(commandName, "complexmsgtoall", false))
	{
		complex = true;
		toAll = true;
	}
	else
	if (StrEqual(commandName, "simplemsgtoall", false))
	{
		toAll = true;
	}
	else
	if (StrEqual(commandName, "complexmsg", false))
	{
		complex = true;
	}
	
	PrintMessage(client, view_as<Destination>(destination), complex, toAll);
	
	return Plugin_Handled;
}

void PrintMessage(int client, Destination dest, bool complex = false, bool toAll = false)
{
	switch (engine)
	{
		case Engine_CSGO:
		{
			if (complex)
			{
				if (toAll)
				{
					PrintValveTranslationToAll(dest, CSGO_COMPLEX_PHRASE, CSGO_COMPLEX_PHRASE_ARG1, CSGO_COMPLEX_PHRASE_ARG2);
				}
				else
				{
					PrintValveTranslationToOne(client, dest, CSGO_COMPLEX_PHRASE, CSGO_COMPLEX_PHRASE_ARG1, CSGO_COMPLEX_PHRASE_ARG2);
				}
			}
			else
			{
				if (toAll)
				{
					PrintValveTranslationToAll(dest, CSGO_SIMPLE_PHRASE);
				}
				else
				{
					PrintValveTranslationToOne(client, dest, CSGO_SIMPLE_PHRASE);
				}
			}
		}
		
		case Engine_TF2:
		{
			if (complex)
			{
				if (toAll)
				{
					PrintValveTranslationToAll(dest, TF2_COMPLEX_PHRASE, TF2_COMPLEX_PHRASE_ARG1, TF2_COMPLEX_PHRASE_ARG2);
				}
				else
				{
					PrintValveTranslationToOne(client, dest, TF2_COMPLEX_PHRASE, TF2_COMPLEX_PHRASE_ARG1, TF2_COMPLEX_PHRASE_ARG2);
				}
			}
			else
			{
				if (toAll)
				{
					PrintValveTranslationToAll(dest, TF2_SIMPLE_PHRASE);
				}
				else
				{
					PrintValveTranslationToOne(client, dest, TF2_SIMPLE_PHRASE);
				}
			}
		}
	}
}