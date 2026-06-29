#pragma semicolon 1

#include <sourcemod>

new Handle:zoomlevel = INVALID_HANDLE;

#define DATA "2.1.1"

new bool:tienezoom[MAXPLAYERS+1] = {false, ...};

new Handle:g_CVarAdmFlag;
new g_AdmFlag;

new Handle:nobloqueardisparos;

public Plugin:myinfo =
{
	name = "SM Binoculars",
	author = "Franc1sco Steam: franug",
	description = "Use binoculars",
	version = DATA,
	url = "www.servers-cfg.foroactivo.com"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_binoculars", Prismaticos);

	new String:modname[30];
	GetGameFolderName(modname, sizeof(modname));
	if (!StrEqual(modname, "nucleardawn", false))
	{
		HookEvent("weapon_zoom", EventWeaponZoom);
	}

	zoomlevel = CreateConVar("sm_binoculars_zoom", "15", "zoom level for binoculars");
	CreateConVar("sm_binoculars_version", DATA, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	nobloqueardisparos = CreateConVar("sm_binoculars_shots", "0", "Allow or disallow shots while using binoculars. 1 = allow. 0 = disallow.");
	g_CVarAdmFlag = CreateConVar("sm_binoculars_adminflag", "0", "Admin flag required to use binoculars. 0 = No flag needed. Can use a b c ....");

	HookConVarChange(g_CVarAdmFlag, CVarChange);
}

public CVarChange(Handle:convar, const String:oldValue[], const String:newValue[]) {

	g_AdmFlag = ReadFlagString(newValue);
}

public Action:Prismaticos(client, args)
{
	if ((g_AdmFlag > 0) && !CheckCommandAccess(client, "sm_binoculars", g_AdmFlag, true))
	{
		PrintToChat(client, "\x03[SM_BINOCULARS] \x04You do not have access");
		return Plugin_Handled;
	}

	if(!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		PrintToChat(client, "\x03[SM_BINOCULARS] \x04you must be alive");
		return Plugin_Handled;
	}

	new zoomahora = GetEntProp(client, Prop_Send, "m_iFOV");
	if(zoomahora == 90 || zoomahora == 0)
	{
		//PrintToChat(client, "fov es: %i", zoomahora);
		SetEntProp(client, Prop_Send, "m_iFOV", GetConVarInt(zoomlevel));
		PrintToChat(client, "\x03[SM_BINOCULARS] \x04Now you use binoculars");
		tienezoom[client] = true;
	}
	else
	{
		//PrintToChat(client, "fov es: %i", zoomahora);
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
		PrintToChat(client, "\x03[SM_BINOCULARS] \x04binoculars removed");
		tienezoom[client] = false;
	}
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(GetConVarInt(nobloqueardisparos) == 0)
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

// Easy ;D

// si quieres aprender a hacer plugins visita www.servers-cfg.foroactivo.com y registrate
// tenemos un apartado para ello
