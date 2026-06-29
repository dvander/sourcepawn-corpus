#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define VERSION "1.1"

new Handle:cvarEnabled;
new bool:gEnabled;

new gColor[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "[TF2] Colored Engineer Buildings",
	author = "Oshizu",
	description = "Allows admins to paint their engineer buildings.",
	version = VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	CreateConVar("sm_ceb_version", VERSION, "TF2 Colored Engineer Buildings Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cvarEnabled = CreateConVar("sm_ceb_enabled", "1", "Enable Colored Engineer Buildings\n0 = Disabled\n1 = Enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	gEnabled = GetConVarBool(cvarEnabled);

	HookConVarChange(cvarEnabled, CVarChange);

	HookEvent("player_builtobject", SentryColor);

	RegAdminCmd("sm_buildingcolors", ColorMenu, ADMFLAG_GENERIC);

	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i)) gColor[i] = 0;
	}
}

public OnPluginEnd()
{
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "obj_dispenser")) != -1)
	{
		SetEntityRenderColor(ent, 255, 255, 255, _);
	}
	while((ent = FindEntityByClassname(ent, "obj_teleporter")) != -1)
	{
		SetEntityRenderColor(ent, 255, 255, 255, _);
	}
	while((ent = FindEntityByClassname(ent, "obj_sentry")) != -1)
	{
		SetEntityRenderColor(ent, 255, 255, 255, _);
	}
}

public CVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == cvarEnabled)
	{
		gEnabled = GetConVarBool(cvarEnabled);

		if(!gEnabled)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsValidClient(i)) gColor[i] = 0;
			}

			new ent = -1;
			while((ent = FindEntityByClassname(ent, "obj_dispenser")) != -1)
			{
				SetEntityRenderColor(ent, 255, 255, 255, _);
			}
			while((ent = FindEntityByClassname(ent, "obj_teleporter")) != -1)
			{
				SetEntityRenderColor(ent, 255, 255, 255, _);
			}
			while((ent = FindEntityByClassname(ent, "obj_sentry")) != -1)
			{
				SetEntityRenderColor(ent, 255, 255, 255, _);
			}
		}
	}
}

public OnClientPutInServer(client)
{
	gColor[client] = 0;
}

public Action:SentryColor(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!gEnabled) return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client)) return Plugin_Continue;

	new building = GetEventInt(event, "index");

	switch(gColor[client])
	{
		case 1: SetEntityRenderColor(building, 0, 0, 0, _);
		case 2: SetEntityRenderColor(building, 255, 102, 0, _);
		case 3: SetEntityRenderColor(building, 255, 255, 0, _);
		case 4: SetEntityRenderColor(building, 0, 128, 0, _);
		case 5: SetEntityRenderColor(building, 0, 0, 255, _);
		case 6: SetEntityRenderColor(building, 255, 0, 0, _);
		case 7: SetEntityRenderColor(building, 0, 255, 255, _);
	}
	return Plugin_Continue;
}

public Action:ColorMenu(client, args)
{
	new Handle:cm = CreateMenu(ColorMenuCallback);
	SetMenuTitle(cm, "Choose Color For Your Building");

	AddMenuItem(cm, "0", "No Color");
	AddMenuItem(cm, "1", "Black");
	AddMenuItem(cm, "2", "Orange");
	AddMenuItem(cm, "3", "Yellow");
	AddMenuItem(cm, "4", "Green");
	AddMenuItem(cm, "5", "Blue");
	AddMenuItem(cm, "6", "Red");
	AddMenuItem(cm, "7", "Aqua");

	DisplayMenu(cm, client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public ColorMenuCallback(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_End) CloseHandle(menu);

	if(action == MenuAction_Select)
	{
		decl String:info[12];
		GetMenuItem(menu, param2, info, sizeof(info));
		gColor[client] = StringToInt(info);
	}
}

stock bool:IsValidClient(client, bool:replay = true)
{
	if(client <= 0 || client > MaxClients || !IsClientInGame(client)) return false;
	if(replay && (IsClientSourceTV(client) || IsClientReplay(client))) return false;
	return true;
}