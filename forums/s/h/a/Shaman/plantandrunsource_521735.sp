/*
plantandrunsource.sp
Plant and Run: Source
This plugin is coded by Alican "AlicanC" Çubukçuoðlu (alicancubukcuoglu@gmail.com)
Copyright (C) 2007 Alican Çubukçuoðlu
*/
/*
Plugin Change Log (N: New, C: Changed, S: Same, R: Removed)

v0.0.1b
Files included:
	N|scripting/plantandrunsource.sp
	N|translations/plugin.plantandrunsource.txt
Release Notes:
	SStocks is needed to compile this plugin.
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

#define PLUGIN_VERSION "0.0.1b"

//||||||||Create Variables
new Handle:plantandrunsource_enabled;
new bool:bomb_planted;
new bool:planter_killed;
new bool:they_learned_the_pass;
new planter;
new last_defuser;

public Plugin:myinfo =
	{
	name = "Plant and Run: Source",
	author = "Alican 'AlicanC' Çubukçuoðlu",
	description = "Counter-Terrorists have to kill the planter to defuse the bomb.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
	}

public OnPluginStart()
	{
	//||||||||Checks
	//||||||Check modification
	if(!CheckMod("cstrike"))
		Fail("Plant and Run: Source", "This plugin only works with Counter-Strike: Source.");
	//||||||Check required translation file
	CheckRequiredFile("translations/plugin.plantandrunsource.txt", "Plant and Run: Source");
	
	//||||||||Load Translations
	LoadTranslations("plugin.plantandrunsource");
	
	//||||||||Create Version CVar
	CreateConVar("plantandrunsource_version", PLUGIN_VERSION, "Plant and Run: Source Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//||||||||CVars
	plantandrunsource_enabled= CreateConVar("plantandrunsource_enable", "1", "Enable/Disable Plant and Run: Source.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	//||||||||Event Hooks
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("bomb_begindefuse", Event_BeginDefuse, EventHookMode_Pre);
	HookEvent("bomb_planted", Event_BombPlanted, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	}

//||||||||||||||||||||EVENTS

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!GetConVarBool(plantandrunsource_enabled))
		return;
	//Reset variables
	bomb_planted= false;
	planter_killed= false;
	they_learned_the_pass= false;
	planter= 0;
	last_defuser= 0;
	//Give defuse kit to all CT's
	new clients= GetMaxClients();
	for(new client= 1; client<=clients; client++)
		{
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==CSSTEAM_CT)
			{
			new defuseroffset= FindSendPropOffs("CCSPlayer", "m_bHasDefuser");
			SetEntData(client, defuseroffset, 1);
			}
		}
	}

public Action:Event_BeginDefuse(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!GetConVarBool(plantandrunsource_enabled))
		return Plugin_Continue;
	//Who is the defuser?
	new defuser= GetClientOfUserId(GetEventInt(event, "userid"));
	//Check if CT's know the password
	if(they_learned_the_pass)
		{
		MessageToOne(defuser, "Plant and Run: Source", "%t", "PARS EnteringPassword");
		return Plugin_Continue;
		}
		else if(defuser!=last_defuser)
		{
		//Who is the planter?
		new String:planter_name[MAX_NAME_LENGTH];
		GetClientName(planter, planter_name, sizeof(planter_name));
		//Is planter killed?
		if(planter_killed)
			{
			//Tell defuser that he/she needs the pass
			MessageToOne(defuser, "Plant and Run: Source", "%t", "PARS CantDefuse", planter_name);
			}
			else
			{
			//Tell defuser that he/she can't defuse
			MessageToOne(defuser, "Plant and Run: Source", "%t", "PARS NeedThePassword", planter_name);
			}
		}
	last_defuser= defuser;
	new planted_c4= FindEntityByClassname(-1, "planted_c4");
	SetEntPropFloat(planted_c4, Prop_Send, "m_flDefuseCountDown", 100.0);
	return Plugin_Handled;
	}

public Event_BombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!GetConVarBool(plantandrunsource_enabled))
		return;
	//Bomb is planted
	bomb_planted= true;
	//Who is the planter?
	planter= GetClientOfUserId(GetEventInt(event, "userid"));
	new String:planter_name[MAX_NAME_LENGTH];
	GetClientName(planter, planter_name, sizeof(planter_name));
	//Tell T's to protect planter
	MessageToTeam(CSSTEAM_T, "Plant and Run: Source", "%t", "PARS ProtectPlanter", planter_name);
	//Tell CT's to kill planter
	MessageToTeam(CSSTEAM_CT, "Plant and Run: Source", "%t", "PARS FindPlanter", planter_name);
	//Tell planter to run!
	if(!IsFakeClient(planter))
		MessageToOne(planter, "Plant and Run: Source", "%t", "PARS Run");
	}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!GetConVarBool(plantandrunsource_enabled) || !bomb_planted || planter_killed)
		return;
	//Who is the killer?
	new killer= GetClientOfUserId(GetEventInt(event, "attacker"));
	new String:killer_name[MAX_NAME_LENGTH];
	GetClientName(killer, killer_name, sizeof(killer_name));
	//Who is the dead player?
	new deadplayer= GetClientOfUserId(GetEventInt(event, "userid"));
	new String:deadplayer_name[MAX_NAME_LENGTH];
	GetClientName(deadplayer, deadplayer_name, sizeof(deadplayer_name));
	//Is planter the dead player?
	if(deadplayer==planter)
		{
		planter_killed= true;
		//Is the killer a CT?
		if(GetClientTeam(killer)==CSSTEAM_CT)
			{
			they_learned_the_pass= true;
			MessageToTeam(CSSTEAM_CT, "Plant and Run: Source", "%t", "PARS FoundPassword", killer_name, deadplayer_name);
			}
			else
			{
			MessageToTeam(CSSTEAM_CT, "Plant and Run: Source", "%t", "PARS PlanterDead", deadplayer_name);
			}
		}
	}