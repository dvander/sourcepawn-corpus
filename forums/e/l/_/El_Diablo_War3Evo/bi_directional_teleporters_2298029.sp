// *************************************************************************
// bi_directional_teleporters.sp
//
// Copyright (c) 2014-2015  El Diablo <diablo@war3evo.info>
//
//  bi_directional_teleporters is free software: you may copy, redistribute
//  and/or modify it under the terms of the GNU General Public License as
//  published by the Free Software Foundation, either version 3 of the
//  License, or (at your option) any later version.
//
//  This file is distributed in the hope that it will be useful, but
//  WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

//  War3Evo Community Forums: https://war3evo.info/forums/index.php

// Sourcemod Plugin Dev for Hire
// http://war3evo.info/plugin-development-team/

// there is a tf2 attribute that chdata says works..
// shoul try this sometime:
// "bidirectional teleport"

#pragma semicolon 1

#include <tf2>

#include <sdkhooks>
#include <sdktools_functions>

#tryinclude <DiabloStocks>

#if !defined _diablostocks_included
#define LoopAlivePlayers(%1) for(new %1=1;%1<=MaxClients;++%1)\
								if(IsClientInGame(%1) && IsPlayerAlive(%1))

stock bool:ValidPlayer(client,bool:check_alive=false,bool:alivecheckbyhealth=false) {
	if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		if(check_alive && !IsPlayerAlive(client))
		{
			return false;
		}
		if(alivecheckbyhealth&&GetClientHealth(client)<1) {
			return false;
		}
		return true;
	}
	return false;
}
#endif

int TeleporterList[MAXPLAYERS + 1][TFObjectMode];

int TeleporterTime[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "Bi-Directional Teleporters",
	author = "El Diablo",
	description = "Bi-Directional Teleporters",
	version = "1.1",
	url = "https://war3evo.info"
};

public OnPluginStart()
{
	CreateConVar("war3evo_bidirectional_teleporters","1.1","War3evo bi-directional teleporters",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("player_builtobject", event_player_builtobject);
	HookEvent("player_carryobject", event_player_carryobject);
}

public OnClientPutInServer(client)
{
	TeleporterList[client][TFObjectMode_Entrance] = -1;
	TeleporterList[client][TFObjectMode_Exit] = -1;
	TeleporterTime[client]=GetTime();
}


public Action:event_player_carryobject(Handle:event, const String:name[], bool:dontBroadcast)
{
	new index = GetEventInt(event, "index");
	new TFObjectType:BuildingType = TFObjectType:GetEventInt(event, "object");

	new owner = GetClientOfUserId(GetEventInt(event, "userid"));
	if(ValidPlayer(owner))
	{
		if(BuildingType == TFObject_Teleporter)
		{
			if(IsValidEntity(index))
			{
				if(TeleporterList[owner][TFObjectMode_Entrance] == index)
				{
					SDKUnhook(index, SDKHook_TouchPost, OnTouchPost);
					TeleporterList[owner][TFObjectMode_Entrance] = -1;
				}
				else if(TeleporterList[owner][TFObjectMode_Exit] == index)
				{
					SDKUnhook(index, SDKHook_TouchPost, OnTouchPost);
					TeleporterList[owner][TFObjectMode_Exit] = -1;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:event_player_builtobject(Handle:event, const String:name[], bool:dontBroadcast)
{
	int index = GetEventInt(event, "index");
	new TFObjectType:BuildingType = TFObjectType:GetEventInt(event, "object");

	int owner = GetClientOfUserId(GetEventInt(event, "userid"));
	if(ValidPlayer(owner))
	{
		if(BuildingType == TFObject_Teleporter)
		{
			if(IsValidEntity(index))
			{
				//check for entrance (0 = entrance, 1 = exit)
				if(GetEntProp(index, Prop_Send, "m_iObjectMode") == 0) {
					TeleporterList[owner][TFObjectMode_Entrance] = index;
					//PrintToChatAll("Created a Teleporter Entrance");

					SDKHook(index, SDKHook_TouchPost, OnTouchPost);
				}
				else if(GetEntProp(index, Prop_Send, "m_iObjectMode") == 1) {
					TeleporterList[owner][TFObjectMode_Exit] = index;
					//PrintToChatAll("Created a Teleporter Exit");

					SDKHook(index, SDKHook_TouchPost, OnTouchPost);
				}
			}
		}
	}
	return Plugin_Continue;
}

public OnEntityDestroyed(entity)
{
	if (entity <= MaxClients)
	{
		return;
	}
	else if (IsValidEntity(entity))
	{
		char EntityLongName[64];
		GetEntityClassname(entity, EntityLongName, 64);

		if(StrEqual("obj_teleporter",EntityLongName,false)==true)
		{
			int owner = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
			if(ValidPlayer(owner))
			{
				if(TeleporterList[owner][TFObjectMode_Entrance] == entity)
				{
					TeleporterList[owner][TFObjectMode_Entrance] = -1;
					//PrintToChatAll("Destory a Teleporter Entrance");

					SDKUnhook(entity, SDKHook_TouchPost, OnTouchPost);
				}
				else if(TeleporterList[owner][TFObjectMode_Exit] == entity)
				{
					TeleporterList[owner][TFObjectMode_Exit] = -1;
					//PrintToChatAll("Destory a Teleporter Exit");

					SDKUnhook(entity, SDKHook_TouchPost, OnTouchPost);
				}
			}
		}
	}
}

public void OnTouchPost (int entity, int other)
{
	if(ValidPlayer(other))
	{
		if(IsValidEntity(entity))
		{
			int CurrentTime = GetTime();
			int owner = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
			if(ValidPlayer(owner) && (TeleporterTime[owner] <= CurrentTime))
			{
				if(IsValidEntity(TeleporterList[owner][TFObjectMode_Entrance])
				&& IsValidEntity(TeleporterList[owner][TFObjectMode_Exit]))
				{
					if(GetClientTeam(other)==GetClientTeam(owner))
					{
						if(entity == TeleporterList[owner][TFObjectMode_Entrance]
						|| entity == TeleporterList[owner][TFObjectMode_Exit])
						{
							int GroundEnt = GetEntPropEnt(other, Prop_Send, "m_hGroundEntity");

							if(GroundEnt != TeleporterList[owner][TFObjectMode_Entrance])
							{
								TeleportSwap(TeleporterList[owner][TFObjectMode_Entrance], TeleporterList[owner][TFObjectMode_Exit]);
								TeleporterTime[owner] = CurrentTime + 1;
							}
						}
					}
				}
			}
		}
	}
}

TeleportSwap(Teleporter1, Teleporter2)
{
	float position1[3];
	float position2[3];

	GetEntPropVector(Teleporter1, Prop_Send, "m_vecOrigin", position1);
	GetEntPropVector(Teleporter2, Prop_Send, "m_vecOrigin", position2);

	TeleportEntity(Teleporter1, position2, NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(Teleporter2, position1, NULL_VECTOR, NULL_VECTOR);
}
