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
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <thirdperson_api>

Handle zoomlevel = INVALID_HANDLE;

#define DATA "3.0TF"

bool tienezoom[MAXPLAYERS+1] = {false, ...};
bool ToMode[MAXPLAYERS+1] = false;

Handle g_CVarAdmFlag;
int g_AdmFlag;

Handle nobloqueardisparos;

int zoomlevel_int;
bool noshotsblocked;

int fov_client[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "SM Binoculars",
	author = "Franc1sco Steam: franug",
	description = "Use binoculars",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegConsoleCmd("sm_binoculars", Prismaticos);
	RegConsoleCmd("sm_bino", Prismaticos);

	HookEventEx("weapon_zoom", EventWeaponZoom);
	HookEvent("player_spawn", Event_Player_Spawn);
	HookEvent("player_death", Event_Player_Death);

	zoomlevel = CreateConVar("sm_binoculars_zoom", "10", "zoom level for binoculars", 0, true, 1.0);
	//CreateConVar("sm_binoculars_version", DATA, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	nobloqueardisparos = CreateConVar("sm_binoculars_shots", "0", "Allow or disallow shots while using binoculars. 1 = allow. 0 = disallow.");
	g_CVarAdmFlag = CreateConVar("sm_binoculars_adminflag", "0", "Admin flag required to use binoculars. 0 = No flag needed. Can use a b c ....");

	HookConVarChange(g_CVarAdmFlag, CVarChange);
	HookConVarChange(zoomlevel, CVarChange2);
	HookConVarChange(nobloqueardisparos, CVarChange2);
}

public void CVarChange(Handle convar, const char[] oldValue, const char[] newValue) {

	g_AdmFlag = ReadFlagString(newValue);
}

public void CVarChange2(Handle convar_hndl, const char[] oldValue, const char[] newValue)
{
	GetCVars();
}

public void OnConfigsExecuted()
{
	GetCVars();
}

public void OnMapStart()
{
	PrecacheDecal("materials/overlay/binoculars.vmt", true);
	PrecacheDecal("materials/overlay/binoculars.vtf", true);
	AddFileToDownloadsTable("materials/overlay/binoculars.vmt");
	AddFileToDownloadsTable("materials/overlay/binoculars.vtf");
}

public Action Event_Player_Spawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	fov_client[client] = GetEntProp(client, Prop_Send, "m_iFOV"); // get default fov
	tienezoom[client] = false;
	ToMode[client] = false;
}


public Action Event_Player_Death(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	ClientCommand(client, "r_screenoverlay 0");
}

public Action Prismaticos(int client, int args)
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
		PrintToChat(client, "\x03[SM_BINOCULARS] \x04you must be alive.");
		return Plugin_Handled;
	}

	tienezoom[client] == false ? SetBino(client) : UnsetBino(client);
	return Plugin_Handled;
}


void SetBino(int client)
{
	ClientCommand(client, "r_screenoverlay overlay/binoculars");

	if(!noshotsblocked)
  	{
		StripToMelee(client);
	}

	SetEntProp(client, Prop_Send, "m_iFOV", zoomlevel_int);
	PrintToChat(client, "\x03[SM_BINOCULARS] \x04Now you use binoculars.");
	tienezoom[client] = true;
		
	if(TP_GetMod(client) == true)
	{
		ToMode[client] = true;
		TP_SetMod(client, false);
	}
	else
	{
		ToMode[client] = false;
	}
}

void UnsetBino(int client)
{
	ClientCommand(client, "r_screenoverlay 0");
	TF2_RemoveCondition(client, TFCond_RestrictToMelee);
	SetEntProp(client, Prop_Send, "m_iFOV", fov_client[client]);
	PrintToChat(client, "\x03[SM_BINOCULARS] \x04binoculars removed.");
	tienezoom[client] = false;
	if(ToMode[client] == true)
	{
		TP_SetMod(client, true);
	}
}


void StripToMelee(int client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client)) {
		TF2_AddCondition(client, TFCond_RestrictToMelee, 99999.0, 0);
		ClientCommand(client, "slot3");
	}
}

public Action EventWeaponZoom(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	tienezoom[client] = false;

}

public void TP_OnModChange(int client, bool bMode)
{
    if(tienezoom[client] && bMode)
    {
        TP_SetMod(client, false);
    }
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
    if (tienezoom[client] && condition == TFCond_Taunting)
    {
		TF2_RemoveCondition(client, TFCond_Taunting);
    }
}

// Get int values of cvars if they has being changed
public void GetCVars()
{
	noshotsblocked = GetConVarBool(nobloqueardisparos);
	zoomlevel_int = GetConVarInt(zoomlevel);
}


// Easy ;D



// si quieres aprender a hacer plugins visita www.servers-cfg.foroactivo.com y registrate
// tenemos un apartado para ello