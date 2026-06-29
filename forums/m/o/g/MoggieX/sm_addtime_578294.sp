/**
 * =============================================================================
 * sm_addtime & sm_togglephase By Team MX | MoggieX - http://www.afterbuy.co.uk
 * Adds time & togglephase thus removing the need to RCON these commands
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
 **/
//////////////////////////////////////////////////////////////////
// Includes / Defintions
//////////////////////////////////////////////////////////////////
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define PLUGIN_VERSION "1.2"

//////////////////////////////////////////////////////////////////
// Plugin Info
//////////////////////////////////////////////////////////////////
public Plugin:myinfo = 
{
	name = "sm_addtime",
	author = "MoggieX",
	description = "Adds time & togglephase commands",
	version = PLUGIN_VERSION,
	url = "http://www.afterbuy.co.uk"
};

//////////////////////////////////////////////////////////////////
// Start Plugin, Reg commands & get Translations
//////////////////////////////////////////////////////////////////
public OnPluginStart()
{
	CreateConVar("sm_add_tog_version", PLUGIN_VERSION, "SM Addtime-togglephase Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_addtime", Command_SmAddTime, ADMFLAG_CUSTOM1, "sm_addtime <Amount> - Add Time.");
	//RegAdminCmd("sm_togglephase", Command_SmToggle, ADMFLAG_CUSTOM1, "sm_togglephase - Run on its own to togglephase.");
	RegAdminCmd("sm_togglephase", Command_Toggle, ADMFLAG_CUSTOM1, "sm_togglephase - Togglephase");
}

public Action:Command_Toggle(client, args)
{
	if (args > 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_togglephase - No need for extra commands");
		return Plugin_Handled;
	}

	LogAction(client, -1, "\"%L\" Used [SM] TogglePhase Command", client);

	ServerCommand("togglephase");

	return Plugin_Handled;
}

public Action:Command_SmAddTime(client, args)
{
	if (args > 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addtime <Amount>");
		return Plugin_Handled;
	}

	new amount = 0;
	decl String:arg1[20];
	GetCmdArg(1, arg1, sizeof(arg1));
	StringToIntEx(arg1, amount);

/*	if (StringToIntEx(arg1, amount) < 0)
	{
		ReplyToCommand(client, "[SM] %t", "Invalid Amount");
		return Plugin_Handled;
	}
		
	if (amount < 0)
	{
		amount = 0;
	}
		
	if (amount > 40000)
	{
		amount = 40000;
	}
*/

	LogAction(client, -1, "\"%L\" [SM] AddTime (Time \"%s\")", client, amount);

	ServerCommand("addtime %i", amount);

	return Plugin_Handled;
}