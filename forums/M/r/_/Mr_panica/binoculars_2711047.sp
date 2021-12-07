/*  SM Binoculars
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new Handle:zoomlevel = INVALID_HANDLE;

#define DATA "3.0"

new bool:tienezoom[MAXPLAYERS+1] = {false, ...};

new Handle:g_CVarAdmFlag;
new g_AdmFlag;

new Handle:nobloqueardisparos;

new zoomlevel_int;
new bool:noshotsblocked;

new fov_client[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "SM Binoculars",
	author = "Franc1sco Steam: franug",
	description = "Use binoculars",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegConsoleCmd("sm_binoculars", Prismaticos);

	HookEventEx("weapon_zoom", EventWeaponZoom);
	HookEvent("player_spawn", Event_Player_Spawn);
	HookEvent("player_death", Event_Player_Death);

	zoomlevel = CreateConVar("sm_binoculars_zoom", "15", "zoom level for binoculars", 0, true, 1.0);
	//CreateConVar("sm_binoculars_version", DATA, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

	nobloqueardisparos = CreateConVar("sm_binoculars_shots", "0", "Allow or disallow shots while using binoculars. 1 = allow. 0 = disallow.");
	g_CVarAdmFlag = CreateConVar("sm_binoculars_adminflag", "0", "Admin flag required to use binoculars. 0 = No flag needed. Can use a b c ....");

	HookConVarChange(g_CVarAdmFlag, CVarChange);
	HookConVarChange(zoomlevel, CVarChange2);
	HookConVarChange(nobloqueardisparos, CVarChange2);
}

public CVarChange(Handle:convar, const String:oldValue[], const String:newValue[]) {

	g_AdmFlag = ReadFlagString(newValue);
}

public CVarChange2(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
}

public OnConfigsExecuted()
{
	GetCVars();
}

public OnMapStart()
{
	PrecacheDecal("materials/overlay/binoculars.vmt", true);
	PrecacheDecal("materials/overlay/binoculars.vtf", true);
	AddFileToDownloadsTable("materials/overlay/binoculars.vmt");
	AddFileToDownloadsTable("materials/overlay/binoculars.vtf");
}

public Action:Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	fov_client[client] = GetEntProp(client, Prop_Send, "m_iFOV"); // get default fov
	tienezoom[client] = false;
}


public Action:Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	ClientCommand(client, "r_screenoverlay 0");
}

public Action:Prismaticos(client, args)
{
	if(client == 0)
	{
		PrintToServer("%t","Command is in-game only");
		return Plugin_Handled;
	}


	if ((g_AdmFlag > 0) && !CheckCommandAccess(client, "sm_binoculars", g_AdmFlag, true)) 
        {
		PrintToChat(client, "\x03[SM_BINOCULARS] \x04You do not have access");
		return Plugin_Handled;
	}

        if(!IsPlayerAlive(client))
        {
		PrintToChat(client, "\x03[SM_BINOCULARS] \x04you must be alive");
		return Plugin_Handled;
	}

	if(!tienezoom[client])
	{
		ClientCommand(client, "r_screenoverlay overlay/binoculars");
		SetEntProp(client, Prop_Send, "m_iFOV", zoomlevel_int);
		PrintToChat(client, "\x03[SM_BINOCULARS] \x04Now you use binoculars");
		tienezoom[client] = true;
	}
	else
	{ 
		ClientCommand(client, "r_screenoverlay 0");
		SetEntProp(client, Prop_Send, "m_iFOV", fov_client[client]);
		PrintToChat(client, "\x03[SM_BINOCULARS] \x04binoculars removed");
		tienezoom[client] = false;
	}
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) 
{   
  	if(!noshotsblocked)
  	{
		if(buttons & IN_ATTACK) 
		{ 

			if(!tienezoom[client]) return Plugin_Continue; 

			new zoomactual = GetEntProp(client, Prop_Send, "m_iFOV");
			if(zoomactual != 90 && zoomactual != 0)
			{
				PrintToChat(client, "\x03[SM_BINOCULARS] \x04you cant attack while using binoculars");
				buttons &= ~IN_ATTACK;
			}
		}
  	}
  	return Plugin_Continue; 
} 


public Action:EventWeaponZoom(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	tienezoom[client] = false;

}


// Get new values of cvars if they has being changed
public GetCVars()
{
	noshotsblocked = GetConVarBool(nobloqueardisparos);
	zoomlevel_int = GetConVarInt(zoomlevel);

}


// Easy ;D



// si quieres aprender a hacer plugins visita www.servers-cfg.foroactivo.com y registrate
// tenemos un apartado para ello