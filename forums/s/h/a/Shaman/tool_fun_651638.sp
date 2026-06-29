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

public OnToolStart()
	{
	//||||||Create ConVar
	strcopy(ToolConVar, sizeof(ToolConVar), "admintoolssource_fun");
	CreateConVar(ToolConVar, "0", "Enable/Disable fun.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	CreateConVar("admintoolssource_fun_health", "100", "Fun Tool: Round start health.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0, true, 500.0);
	CreateConVar("admintoolssource_fun_speed", "1", "Fun Tool: Players' speed.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.5, true, 3.0);
	
	//||||||Event hooks
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookConVarChange(FindConVar(ToolConVar), ConVarChange_Enable);
	HookConVarChange(FindConVar("admintoolssource_fun_speed"), ConVarChange_Speed);
	}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!ToolRunning(ToolConVar))
		return;
	//
	new clients= GetMaxClients();
	for(new client= 1; client<=clients; client++)
		{
		//
		if(IsClientInGame(client) && !IsClientObserver(client) && IsPlayerAlive(client))
			{
			ClientHealth(client, "set", GetConVarInt(FindConVar("admintoolssource_fun_health")));
			SetClientSpeed(client, GetConVarFloat(FindConVar("admintoolssource_fun_speed")));
			}
		}
	}

public ConVarChange_Enable(Handle:CVar, const String:s_oldvalue[], const String:s_newvalue[])
	{
	if(StrEqual(s_oldvalue, s_newvalue) || !ToolRunning(ToolConVar))
		return;
	//
	new clients= GetMaxClients();
	for(new client= 1; client<=clients; client++)
		{
		//
		if(IsClientInGame(client) && !IsClientObserver(client))
			{
			if(StrEqual(s_newvalue, "1"))
				SetClientSpeed(client, GetConVarFloat(FindConVar("admintoolssource_fun_speed")));
			else if(StrEqual(s_newvalue, "0"))
				SetClientSpeed(client, 1.0);
			}
		}
	}

public ConVarChange_Speed(Handle:CVar, const String:s_oldvalue[], const String:s_newvalue[])
	{
	if(StrEqual(s_oldvalue, s_newvalue) || !ToolRunning(ToolConVar))
		return;
	//
	new clients= GetMaxClients();
	for(new client= 1; client<=clients; client++)
		{
		//
		if(IsClientInGame(client) && !IsClientObserver(client))
			SetClientSpeed(client, StringToFloat(s_newvalue));
		}
	}