/*
tool.afks.sp
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
new Float:spawnorigin[MAXPLAYERS+1][3];

public OnToolStart()
	{
	//||||||Create ConVar
	strcopy(ToolConVar, sizeof(ToolConVar), "admintoolssource_afks");
	CreateConVar(ToolConVar, "0", "Enable/Disable AFK's to Spectators.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	//||||||Event hooks
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!ToolRunning(ToolConVar))
		return;
	new client= GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsFakeClient(client))
		return;
	new Float:origin[3];
	GetClientAbsOrigin(client, origin);
	spawnorigin[client][0]= origin[0];
	spawnorigin[client][1]= origin[1];
	spawnorigin[client][2]= origin[2];
	}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!ToolRunning(ToolConVar))
		return Plugin_Continue;
	//
	new clients= GetMaxClients();
	for(new client= 1; client<=clients; client++)
		{
		if(IsClientInGame(client) && !IsClientObserver(client) && IsPlayerAlive(client) && !IsFakeClient(client))
			{
			new Float:origin[3];
			GetClientAbsOrigin(client, origin);
			if(spawnorigin[client][0]==origin[0] && spawnorigin[client][1]==origin[1] && spawnorigin[client][2]==origin[2])
				ChangeClientTeam(client, 1);
			}
		}
	return Plugin_Continue;
	}