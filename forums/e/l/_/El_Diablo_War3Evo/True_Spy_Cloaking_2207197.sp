//True_Spy_Cloaking.sp

/*
	True_Spy_Cloaking

	Copyright (c) 2014  El Diablo <www.war3evo.info>

	Antihack is free software: you may copy, redistribute
	and/or modify it under the terms of the GNU General Public License as
	published by the Free Software Foundation, either version 3 of the
	License, or (at your option) any later version.

	This file is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#include <sdkhooks>
#include <tf2_stocks>

public Plugin:myinfo = {
	name = "True_Spy_Cloaking",
	author = "El Diablo",
	description = "Gives a spy true cloaking",
	version = "1.1",
	url = "https://github.com/War3Evo, admin@war3evo.info"
};

new Handle:h_IsEnabled;
new bool:bIsEnabled=false;

public OnPluginStart()
{
	CreateConVar("truespycloaking_version","1.2 by El Diablo","TrueSpyCloaking version.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	h_IsEnabled = CreateConVar("truespycloaking_enabled", "1", "0 - disable / 1 - enable", FCVAR_PLUGIN);

	HookConVarChange(h_IsEnabled, OnEnabledChange);

	for(new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i))
		{
			SDKHook(i, SDKHook_SetTransmit, SDK_FORWARD_TRANSMIT);
		}
	}
}

stock Float:GetPlayerDistance(client1,client2)
{
	static Float:vec1[3];
	static Float:vec2[3];
	GetClientAbsOrigin(client1,vec1);
	GetClientAbsOrigin(client2,vec2);
	return GetVectorDistance(vec1,vec2);
}
public OnEnabledChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	bIsEnabled = GetConVarBool(cvar);
}

stock bool:ValidPlayer(client)
{
	if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		return true;
	}
	return false;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_SetTransmit, SDK_FORWARD_TRANSMIT);
}

public OnPluginEnd()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i))
		{
			SDKUnhook(i, SDKHook_SetTransmit, SDK_FORWARD_TRANSMIT);
		}
	}
}

public Action:SDK_FORWARD_TRANSMIT(entity, client)
{
	if(!bIsEnabled) return Plugin_Continue;

	if(entity!=client && ValidPlayer(entity) && ValidPlayer(client))
	{
		new ClientTeam=GetClientTeam(client);
		if((ClientTeam==2 || ClientTeam==3)
		&& GetClientTeam(entity)!=ClientTeam
		&& IsPlayerAlive(entity)
		&& GetPlayerDistance(client,entity)>60.0
		&& GetEntPropFloat(entity, Prop_Send, "m_flCloakMeter")>0.0
		&& TF2_IsPlayerInCondition(entity, TFCond_Cloaked)
		&& !TF2_IsPlayerInCondition(entity, TFCond_Jarated)
		&& !TF2_IsPlayerInCondition(entity, TFCond_OnFire)
		&& !TF2_IsPlayerInCondition(entity, TFCond_Milked))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
