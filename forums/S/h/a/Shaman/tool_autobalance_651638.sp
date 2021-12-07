/*
tool.autobalance.sp
AdminTools: Source
This plugin is coded by Alican "AlicanC" Çubukçuoðlu (alicancubukcuoglu@gmail.com)
Copyright (C) 2007 Alican Çubukçuoðlu
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

#include "admintoolssource/atstool.inc"

new String:ToolConVar[32];
new Handle:GameConfig;
new Handle:SDKC_SwitchTeam;
new Handle:SDKC_SetModel;

public OnToolStart()
	{
	//||||||Check required files
	//||||Check game data file
	CheckRequiredFile("gamedata/admintoolssource.games.txt", "AdminTools: Source | Tool: Auto Balance");
	
	//||||||Create ConVar
	strcopy(ToolConVar, sizeof(ToolConVar), "admintoolssource_autobalance");
	CreateConVar(ToolConVar, "0", "Enable/Disable automatic team balancing.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	//||||||Get GameConfig
	GameConfig= LoadGameConfigFile("admintoolssource.games");
	
	//||||||Prepare for SwitchTeam SDK call
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(GameConfig, SDKConf_Signature, "SwitchTeam");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	SDKC_SwitchTeam= EndPrepSDKCall();
	
	//||||||Prepare for SetModel SDK call
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(GameConfig, SDKConf_Signature, "SetModel");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	SDKC_SetModel= EndPrepSDKCall();
	
	
	//||||||Event hooks
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	}

stock TransferClient(client, team)
	{
	//Transfer player to other team
	SDKCall(SDKC_SwitchTeam, client, team);
	//Find a model for player
	new String:model[64];
	if(CheckMod("cstrike"))
		{
		if(team==2)
			strcopy(model, sizeof(model), "models/player/ct_urban.mdl");
		else
			strcopy(model, sizeof(model), "models/player/t_phoenix.mdl");
		}
		else
		{
		//Mod is not supported
		return;
		}
	SDKCall(SDKC_SetModel, client, model);
	}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!ToolRunning(ToolConVar))
		return Plugin_Continue;
	//Get mod specific team indexes
	new team1, team2;
	if(CheckMod("cstrike"))
		{
		team1= 2;
		team2= 3;
		}
		else
		{
		//Mod is not supported
		return Plugin_Continue;
		}
	//Get dead player's client and team
	new player= GetClientOfUserId(GetEventInt(event, "userid"));
	new player_team= GetClientTeam(player);
	//Get client counts of teams
	new team1c= CountClientsInTeam(team1);
	new team2c= CountClientsInTeam(team2);
	//Return if teams are even
	if(team1c==team2c)
		return Plugin_Continue;
	//Learn which team needs help
	if(team1c>team2c)
		{
		//Return if team can't get help
		if(team1c-team2c==1)
			return Plugin_Continue;
		//Return if our player can't help team2
		if(player_team==team2)
			return Plugin_Continue;
		//Yay! Let's send our player to team2!
		new Handle:data;
		CreateDataTimer(1.0, Timer_TransferClient, data);
		WritePackCell(data, player);
		WritePackCell(data, team2);
		}
		else if(team2c>team1c)
		{
		//Return if team can't get help
		if(team2c-team1c==1)
			return Plugin_Continue;
		//Return if our player can't help team1
		if(player_team==team1)
			return Plugin_Continue;
		//Yay! Let's send our player to team1!
		new Handle:data;
		new Float:time= 0.9;
		if(CheckPlugin("cssdm"))
			time= GetConVarFloat(FindConVar("cssdm_respawn_wait"));
		CreateDataTimer(time, Timer_TransferClient, data);
		WritePackCell(data, player);
		WritePackCell(data, team1);
		}
	return Plugin_Continue;
	}

public Action:Timer_TransferClient(Handle:timer, Handle:data)
	{
	if(!ToolRunning(ToolConVar))
		return;
	//Get data
	ResetPack(data);
	new client= ReadPackCell(data);
	new team= ReadPackCell(data);
	CloseHandle(data);
	//Transfer client
	TransferClient(client, team);
	return;
	}