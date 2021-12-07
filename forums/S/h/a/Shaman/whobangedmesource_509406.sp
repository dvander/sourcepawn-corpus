/*
whobangedmesource.sp
WhoBangedMe?: Source Plugin - This file is needed to run WhoBangedMe?: Source
This plugin is coded by Alican "AlicanC" Çubukçuoðlu (alicancubukcuoglu@gmail.com)
Copyright (C) 2007 Alican Çubukçuoðlu
*/
/*
Plugin Change Log (N: New, C: Changed, S: Same, R: Removed)

v0.0.6
Files included:
	C|scripting/whobangedmesource.sp
	S|translations/whobangedmesource.base.txt
Release Notes:
	None.
Changes:
	Changed default value of "whobangedmesource_tmbanglimit" to "0".

v0.0.5
Files included:
	C|scripting/whobangedmesource.sp
	C|translations/whobangedmesource.base.txt
Release Notes:
	None.
Changes:
	Fixed 'tmonly' mode.
	Added teammate bang punishment.

v0.0.4
Files included:
	C|scripting/whobangedmesource.sp
	S|translations/whobangedmesource.base.txt
Release Notes:
	From now on SStocks is required to compile this plugin.
Changes:
	Removed 'sm_' prefix from ConVars.

v0.0.3
Files included:
	C|scripting/whobangedmesource.sp
	S|translations/whobangedmesource.base.txt
Release Notes:
	Ready to go.
Changes:
	Changed client name variables' sizes to 'MAX_NAME_LENGTH'.

v0.0.2b
Files included:
	C|scripting/whobangedmesource.sp
	S|translations/whobangedmesource.base.txt
Release Notes:
	Ready to go.
Changes:
	Removed unnecessery code.
	Optimized functions.
	Fixed a problem which caused 'Native "GetClientTeam" reported: Client index 0 is invalid' error.

v0.0.1b
Files included:
	C|scripting/whobangedmesource.sp
	C|translations/whobangedmesource.base.txt
Release Notes:
	Still needs some tests.
Changes:
	Removed message displayed when WhoBangedMe?: Source not active.
	Removed unnecessery code.
	Optimized functions to work a little bit faster.
	Fixed a problem which caused wrong names to be displayed.

v0.0.1a
Files included:
	N|scripting/whobangedmesource.sp
	N|translations/whobangedmesource.base.txt
Release Notes:
	First release
Changes:
	First release
*/
/*
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sstocks>

//||||||||||||||||||||Plugin Information

new const String:PLUGIN_NAME[]= "WhoBangedMe?: Source";
new const String:PLUGIN_DESCRIPTION[]= "Tells who banged who!";
#define PLUGIN_VERSION "0.0.6"

public Plugin:myinfo=
	{
	name= PLUGIN_NAME,
	author= "Alican 'AlicanC' Çubukçuoðlu",
	description= PLUGIN_DESCRIPTION,
	version= PLUGIN_VERSION,
	url= "http://www.sourcemod.net/"
	}

//||||||||||||||||||||Variables

new tmbangcount[MAXPLAYERS+1];
new lastbanger;

//||||||||||||||||||||Initialization

public OnPluginStart()
	{
	//Translations
	LoadTranslations("plugin.whobangedmesource.base");
	
	//Version ConVar
	CreateConVar("whobangedmesource_version", PLUGIN_VERSION, "WhoBangedMe?: Source Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//ConVars
	CreateConVar("whobangedmesource_enable", "1", "WhoBangedMe? Source | Enable/disable.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	CreateConVar("whobangedmesource_tmonly", "1", "WhoBangedMe? Source | Tell to teammates only.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	CreateConVar("whobangedmesource_tmbanglimit", "0", "WhoBangedMe? Source | Punish player when bangs a teammate. 0: Off, 1: Instant slay, >=2: Slay after limit is reached", FCVAR_PLUGIN|FCVAR_NOTIFY, true, -1.0, true, 20.0);
	
	//Event hooks
	HookEvent("flashbang_detonate", Event_FlashbangDetonate);
	HookEvent("player_blind", Event_PlayerBlind);
	}

//||||||||||||||||||||Event hooks

public OnClientPutInServer(client)
	{
	if(!Running()){return;}
	//Display plugin status to the client
	MessageToOne(client, PLUGIN_NAME, "%t", "WBMS Running", PLUGIN_VERSION);
	//Reset teammate bang count
	tmbangcount[client]= 0;
	return;
	}

public Event_FlashbangDetonate(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!Running()){return;}
	lastbanger= GetClientOfUserId(GetEventInt(event, "userid"));
	}

public Event_PlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!Running()){return;}
	//Who is blinded?
	new victim= GetClientOfUserId(GetEventInt(event, "userid"));
	//Return if the blinded player is dead
	if(!IsPlayerAlive(victim))
		return;
	//Pack the data and create the timer
	new Handle:data;
	CreateDataTimer(0.1, WhoBangedWho, data);
	WritePackCell(data, victim);
	WritePackCell(data, lastbanger);
	}

public Action:WhoBangedWho(Handle:timer, Handle:data)
	{
	//Get victim and attacker info
	ResetPack(data);
	new victim= ReadPackCell(data);
	new attacker= ReadPackCell(data);
	new String:attacker_name[MAX_NAME_LENGTH];
	GetClientName(attacker, attacker_name, sizeof(attacker_name));
	//Is attacker or victim invalid?
	if(victim==0 || attacker==0)
		return;
	//Did someone banged him/herself?
	if(victim==attacker)
		{
		MessageToOne(victim, PLUGIN_NAME, "%t", "WBMS BangedSelf");
		return;
		}
	//Is our attacker banged a teammate?
	if(GetClientTeam(victim)==GetClientTeam(attacker))
		TMbang(attacker);
	//Send the message if we can
	if(!BConVar("tmonly") || (BConVar("tmonly") && GetClientTeam(victim)==GetClientTeam(attacker)))
		MessageToOne(victim, PLUGIN_NAME, "%t", "WBMS BangedBy", attacker_name);
	return;
	}

//||||||||||||||||||||Functions

public bool:Running()
	{
	return GetConVarBool(FindConVar("whobangedmesource_enable"));
	}

public bool:BConVar(const String:subcv[])
	{
	new String:ConVarName[32];
	Format(ConVarName, 32, "whobangedmesource_%s", subcv);
	return GetConVarBool(FindConVar(ConVarName));
	}

public IConVar(const String:subcv[])
	{
	new String:ConVarName[32];
	Format(ConVarName, 32, "whobangedmesource_%s", subcv);
	return GetConVarInt(FindConVar(ConVarName));
	}

public TMbang(client)
	{
	new banglimit= IConVar("tmbanglimit");
	tmbangcount[client]++;
	//Return if banglimit is 0
	if(banglimit==0)
		return;
	//Slay the banger is limit is reached
	if(tmbangcount[client]>=banglimit)
		{
		//Tell attacker that he/she reached the limit
		MessageToOne(client, PLUGIN_NAME, "%t", "WBMS ReachedTheLimit");
		//Slay the attacker
		ForcePlayerSuicide(client);
		//Reset the counter
		tmbangcount[client]= 0;
		}
		else
		{//Warn the banger
		new remaining= banglimit-tmbangcount[client];
		if(remaining==1)
			MessageToOne(client, PLUGIN_NAME, "%t", "WBMS WillBeSlayedIf Singular");
		else
			MessageToOne(client, PLUGIN_NAME, "%t", "WBMS WillBeSlayedIf Plural", remaining);
		}
	}