#include <sourcemod>
#include <sdktools>
#include <donator>

#pragma semicolon 1

#define PLUGIN_VERSION	"0.1"

new gColor[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "Donator Engineer Building Colors",
	author = "abrandnewday",
	description = "Donator Feature: Color your Engineer Buildings!",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=165383"
}

public OnPluginStart()
{
	CreateConVar("basicdonator_buildcolor_v", PLUGIN_VERSION, "Donator Building Colors Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookEvent("player_builtobject", Event_BuiltObject);
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

public OnAllPluginsLoaded()
{
	if(!LibraryExists("donator.core"))
	{
		SetFailState("Unabled to find plugin: Basic Donator Interface");
	}
	Donator_RegisterMenuItem("Change Building Color", ChangeBuildingColorCallback);
}

public OnClientPutInServer(iClient)
{
	gColor[iClient] = 0;
}

public DonatorMenu:ChangeBuildingColorCallback(iClient)
{
	Menu_ChangeBuildingColor(iClient);
}

public Action:Menu_ChangeBuildingColor(iClient)
{
	new Handle:menu = CreateMenu(BuildingColorMenuSelected);
	SetMenuTitle(menu, "Donator: Change Building Color:");

	AddMenuItem(menu, "0", "No Color");
	AddMenuItem(menu, "1", "Black");
	AddMenuItem(menu, "2", "Red");
	AddMenuItem(menu, "3", "Green");
	AddMenuItem(menu, "4", "Blue");
	AddMenuItem(menu, "5", "Yellow");
	AddMenuItem(menu, "6", "Purple");
	AddMenuItem(menu, "7", "Cyan");
	AddMenuItem(menu, "8", "Orange");
	AddMenuItem(menu, "9", "Pink");
	AddMenuItem(menu, "10", "Olive");
	AddMenuItem(menu, "11", "Lime");
	AddMenuItem(menu, "12", "Violet");
	AddMenuItem(menu, "13", "Light Blue");
	AddMenuItem(menu, "14", "Silver");
	AddMenuItem(menu, "15", "Chocolate");
	AddMenuItem(menu, "16", "Saddle Brown");
	AddMenuItem(menu, "17", "Indigo");
	AddMenuItem(menu, "18", "Ghost White");
	AddMenuItem(menu, "19", "Thistle");
	AddMenuItem(menu, "20", "Alice Blue");
	AddMenuItem(menu, "21", "Steel Blue");
	AddMenuItem(menu, "22", "Teal");
	AddMenuItem(menu, "23", "Gold");
	AddMenuItem(menu, "24", "Tan");
	AddMenuItem(menu, "25", "Tomato");
	
	DisplayMenu(menu, iClient, 20);
}

public BuildingColorMenuSelected(Handle:menu, MenuAction:action, iClient, param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}

	if(action == MenuAction_Select)
	{
		decl String:info[12];
		GetMenuItem(menu, param2, info, sizeof(info));
		gColor[iClient] = StringToInt(info);
	}
}

public Action:Event_BuiltObject(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(iClient)) return Plugin_Continue;

	new iBuilding = GetEventInt(event, "index");

	switch(gColor[iClient])
	{
		case 1: SetEntityRenderColor(iBuilding, 0, 0, 0, _);
		case 2: SetEntityRenderColor(iBuilding, 255, 0, 0, _);
		case 3: SetEntityRenderColor(iBuilding, 0, 255, 0, _);
		case 4: SetEntityRenderColor(iBuilding, 0, 0, 255, _);
		case 5: SetEntityRenderColor(iBuilding, 255, 255, 0, _);
		case 6: SetEntityRenderColor(iBuilding, 255, 0, 255, _);
		case 7: SetEntityRenderColor(iBuilding, 0, 255, 255, _);
		case 8: SetEntityRenderColor(iBuilding, 255, 128, 0, _);
		case 9: SetEntityRenderColor(iBuilding, 255, 0, 128, _);
		case 10: SetEntityRenderColor(iBuilding, 128, 255, 0, _);
		case 11: SetEntityRenderColor(iBuilding, 0, 255, 128, _);
		case 12: SetEntityRenderColor(iBuilding, 128, 0, 255, _);
		case 13: SetEntityRenderColor(iBuilding, 0, 128, 255, _);
		case 14: SetEntityRenderColor(iBuilding, 192, 192, 192, _);
		case 15: SetEntityRenderColor(iBuilding, 210, 105, 30, _);
		case 16: SetEntityRenderColor(iBuilding, 139, 69, 19, _);
		case 17: SetEntityRenderColor(iBuilding, 75, 0, 130, _);
		case 18: SetEntityRenderColor(iBuilding, 248, 248, 255, _);
		case 19: SetEntityRenderColor(iBuilding, 216, 191, 216, _);
		case 20: SetEntityRenderColor(iBuilding, 240, 248, 255, _);
		case 21: SetEntityRenderColor(iBuilding, 70, 130, 180, _);
		case 22: SetEntityRenderColor(iBuilding, 0, 128, 128, _);
		case 23: SetEntityRenderColor(iBuilding, 255, 215, 0, _);
		case 24: SetEntityRenderColor(iBuilding, 210, 180, 140, _);
		case 25: SetEntityRenderColor(iBuilding, 255, 99, 71, _);
	}
	return Plugin_Continue;
}

stock bool:IsValidClient(iClient, bool:replay = true)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient)) return false;
	if(replay && (IsClientSourceTV(iClient) || IsClientReplay(iClient))) return false;
	return true;
}