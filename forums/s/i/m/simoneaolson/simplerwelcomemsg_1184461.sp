/**
 * =============================================================================
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
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
 */


#include <sourcemod>
#define PLUGIN_VERSION "1.01"

new Handle:Cvar_EnablePlugin, Handle:Cvar_Timer1, Handle:Cvar_Timer2, Handle:Cvar_Method, Handle:Cvar_Mode
new String:name[MAX_NAME_LENGTH], String:language[MAX_NAME_LENGTH]
new bool:alreadyDisplayed[MAXPLAYERS]


public Plugin:myinfo =
{

	name = "Simpler Welcome Message",
	author = "simoneaolson",
	description = "Displays a simple welcome message to every client, light on the sever, multilingual, not bloatware!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/plugins.php?cat=0&mod=0&title=&author=simoneaolson&description=&search=1"
	
}


public OnPluginStart()
{

	LoadTranslations("simplerwelcomemsg.phrases")
	CreateConVar("swm2_version", PLUGIN_VERSION, "Simpler Welcome Message Plugin Version")
	Cvar_EnablePlugin = CreateConVar("swm2_enable", "1", "Enable/Disable Plugin", _, true, 0.0, true, 1.0)
	Cvar_Mode = CreateConVar("swm2_mode", "1", "When to display the message 1=When the player joins a team, 2=X seconds after joining", _, true, 1.0, true, 2.0)
	Cvar_Timer1 = CreateConVar("swm2_timer1", "7.0", "IF swm2_mode=1, When the message should be displayed after the player joins a team (seconds)")
	Cvar_Timer2 = CreateConVar("swm2_timer2", "22.0", "IF swm2_mode=2, When the message should be displayed after the player joins the server (seconds)")
	Cvar_Method = CreateConVar("swm2_method", "1", "How to display the welcome message to the client 1=Hint text, 2=Center Text", _, true, 1.0, true, 2.0)
	RegConsoleCmd("jointeam", jointeam)
	
}


public OnMapStart()
{

	for (new i = 0; i < MAXPLAYERS; ++i)
	{
		alreadyDisplayed[i] = false
	}

}


public OnClientPostAdminCheck(client)
{

	if (GetConVarBool(Cvar_EnablePlugin) && GetConVarInt(Cvar_Mode) == 2)
	{
		if (GetConVarInt(Cvar_Method) == 1) CreateTimer(GetConVarFloat(Cvar_Timer2), TimerWelcomeHint, GetClientSerial(client))
		else CreateTimer(GetConVarFloat(Cvar_Timer2), TimerWelcomeCenter, GetClientSerial(client))
	}
	
}
	

public Action:TimerWelcomeHint(Handle:timer, any:clientSerial)
{
	
	new client = GetClientFromSerial(clientSerial)
	
	if (IsClientInGame(client))
	{
		GetClientName(client, name, 32)
		Format(language, 32, "%t", "Welcome")
		PrintHintText(client, "%s %s", language, name)
	}
	
}


public Action:TimerWelcomeCenter(Handle:timer, any:clientSerial)
{
	
	new client = GetClientFromSerial(clientSerial)
	
	if (IsClientInGame(client))
	{
		GetClientName(client, name, 32)
		Format(language, 32, "%t", "Welcome")
		PrintCenterText(client, "%s %s", language, name)
	}
	
}


public Action:jointeam(client, team)
{
	
	if (!alreadyDisplayed[client] && GetConVarInt(Cvar_Mode) == 1)
	{
		alreadyDisplayed[client] = true
		if (GetConVarInt(Cvar_Method) == 1) CreateTimer(GetConVarFloat(Cvar_Timer1), TimerWelcomeHint, GetClientSerial(client))
		else CreateTimer(GetConVarFloat(Cvar_Timer1), TimerWelcomeCenter, GetClientSerial(client))
	}
	
	return Plugin_Continue
	
}


public OnClientDisconnect(client)
{

	alreadyDisplayed[client] = false

}