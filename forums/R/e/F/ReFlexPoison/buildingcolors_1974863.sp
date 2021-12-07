#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <sdktools>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION	"1.0"

// ====[ HANDLES | CVARS ]=====================================================
new Handle:g_hCvarEnabled;

// ====[ VARIABLES ]===========================================================
new g_iColor[MAXPLAYERS + 1];
new bool:g_bEnabled;

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Building Colors",
	author = "ReFlexPoison",
	description = "Color Engineer Buildings",
	version = PLUGIN_VERSION,
	url = "https://www.sourcemod.net/"
}

// ====[ FUNCTIONS ]===========================================================
public OnPluginStart()
{
	CreateConVar("sm_buildcolors_version", PLUGIN_VERSION, "Building Colors Version", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_hCvarEnabled = CreateConVar("sm_buildcolors_enabled", PLUGIN_VERSION, "Enable Building Colors\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
	HookConVarChange(g_hCvarEnabled, ConVarChanged);

	HookEvent("player_builtobject", OnBuiltObject);

	RegAdminCmd("sm_buildingcolors", BuildingColorsCmd, ADMFLAG_GENERIC);
}

public ConVarChanged(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == g_hCvarEnabled)
	{
		g_bEnabled = GetConVarBool(g_hCvarEnabled);
		if(!g_bEnabled)
			OnPluginEnd();
	}
}

// ====[ EVENTS ]==============================================================
public OnPluginEnd()
{
	new iEntity = INVALID_ENT_REFERENCE;
	while((iEntity = FindEntityByClassname(iEntity, "obj_dispenser")) != INVALID_ENT_REFERENCE)
		SetEntityRenderColor(iEntity, 255, 255, 255, _);
	while((iEntity = FindEntityByClassname(iEntity, "obj_teleporter")) != INVALID_ENT_REFERENCE)
		SetEntityRenderColor(iEntity, 255, 255, 255, _);
	while((iEntity = FindEntityByClassname(iEntity, "obj_sentry")) != INVALID_ENT_REFERENCE)
		SetEntityRenderColor(iEntity, 255, 255, 255, _);
}

public OnClientConnected(iClient)
{
	g_iColor[iClient] = 0;
}

public Action:OnBuiltObject(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(iClient) || !g_bEnabled)
		return Plugin_Continue;

	if(!CheckCommandAccess(iClient, "sm_buildingcolors", ADMFLAG_GENERIC))
		return Plugin_Continue;

	new iBuilding = GetEventInt(hEvent, "index");
	if(IsValidEntityEx(iBuilding))
		SetBuildingColor(iBuilding, iClient);
	return Plugin_Continue;
}

// ====[ COMMANDS ]============================================================
public Action:BuildingColorsCmd(iClient, iArgs)
{
	if(!IsValidClient(iClient) || !g_bEnabled)
		return Plugin_Continue;

	new Handle:hMenu = CreateMenu(BuildingColorsHandler);
	SetMenuTitle(hMenu, "Building Colors:");

	AddMenuItem(hMenu, "0", "None");
	AddMenuItem(hMenu, "1", "Black");
	AddMenuItem(hMenu, "2", "Red");
	AddMenuItem(hMenu, "3", "Green");
	AddMenuItem(hMenu, "4", "Blue");
	AddMenuItem(hMenu, "5", "Yellow");
	AddMenuItem(hMenu, "6", "Purple");
	AddMenuItem(hMenu, "7", "Cyan");
	AddMenuItem(hMenu, "8", "Orange");
	AddMenuItem(hMenu, "9", "Pink");
	AddMenuItem(hMenu, "10", "Olive");
	AddMenuItem(hMenu, "11", "Lime");
	AddMenuItem(hMenu, "12", "Violet");
	AddMenuItem(hMenu, "13", "Light Blue");
	AddMenuItem(hMenu, "14", "Silver");
	AddMenuItem(hMenu, "15", "Chocolate");
	AddMenuItem(hMenu, "16", "Saddle Brown");
	AddMenuItem(hMenu, "17", "Indigo");
	AddMenuItem(hMenu, "18", "Ghost White");
	AddMenuItem(hMenu, "19", "Thistle");
	AddMenuItem(hMenu, "20", "Alice Blue");
	AddMenuItem(hMenu, "21", "Steel Blue");
	AddMenuItem(hMenu, "22", "Teal");
	AddMenuItem(hMenu, "23", "Gold");
	AddMenuItem(hMenu, "24", "Tan");
	AddMenuItem(hMenu, "25", "Tomato");

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public BuildingColorsHandler(Handle:hMenu, MenuAction:iAction, iParam1, iParam2)
{
	if(iAction == MenuAction_End)
		CloseHandle(hMenu);

	if(iAction == MenuAction_Select)
	{
		decl String:strInfo[12];
		GetMenuItem(hMenu, iParam2, strInfo, sizeof(strInfo));
		g_iColor[iParam1] = StringToInt(strInfo);

		new iEntity = INVALID_ENT_REFERENCE;
		while((iEntity = FindEntityByClassname(iEntity, "obj_dispenser")) != INVALID_ENT_REFERENCE)
		{
			if(GetEntPropEnt(iEntity, Prop_Send, "m_hBuilder") == iParam1)
				SetBuildingColor(iEntity, iParam1);
		}
		while((iEntity = FindEntityByClassname(iEntity, "obj_teleporter")) != INVALID_ENT_REFERENCE)
		{
			if(GetEntPropEnt(iEntity, Prop_Send, "m_hBuilder") == iParam1)
				SetBuildingColor(iEntity, iParam1);
		}
		while((iEntity = FindEntityByClassname(iEntity, "obj_sentry")) != INVALID_ENT_REFERENCE)
		{
			if(GetEntPropEnt(iEntity, Prop_Send, "m_hBuilder") == iParam1)
				SetBuildingColor(iEntity, iParam1);
		}
	}
}

// ====[ STOCKS ]==============================================================
stock bool:IsValidClient(iClient, bool:bReplay = true)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}

stock bool:IsValidEntityEx(iEntity)
{
	if(iEntity <= MaxClients || !IsValidEntity(iEntity))
		return false;
	return true;
}

stock SetBuildingColor(iEntity, iOwner)
{
	switch(g_iColor[iOwner])
	{
		case 1: SetEntityRenderColor(iEntity, 0, 0, 0, _);
		case 2: SetEntityRenderColor(iEntity, 255, 0, 0, _);
		case 3: SetEntityRenderColor(iEntity, 0, 255, 0, _);
		case 4: SetEntityRenderColor(iEntity, 0, 0, 255, _);
		case 5: SetEntityRenderColor(iEntity, 255, 255, 0, _);
		case 6: SetEntityRenderColor(iEntity, 255, 0, 255, _);
		case 7: SetEntityRenderColor(iEntity, 0, 255, 255, _);
		case 8: SetEntityRenderColor(iEntity, 255, 128, 0, _);
		case 9: SetEntityRenderColor(iEntity, 255, 0, 128, _);
		case 10: SetEntityRenderColor(iEntity, 128, 255, 0, _);
		case 11: SetEntityRenderColor(iEntity, 0, 255, 128, _);
		case 12: SetEntityRenderColor(iEntity, 128, 0, 255, _);
		case 13: SetEntityRenderColor(iEntity, 0, 128, 255, _);
		case 14: SetEntityRenderColor(iEntity, 192, 192, 192, _);
		case 15: SetEntityRenderColor(iEntity, 210, 105, 30, _);
		case 16: SetEntityRenderColor(iEntity, 139, 69, 19, _);
		case 17: SetEntityRenderColor(iEntity, 75, 0, 130, _);
		case 18: SetEntityRenderColor(iEntity, 248, 248, 255, _);
		case 19: SetEntityRenderColor(iEntity, 216, 191, 216, _);
		case 20: SetEntityRenderColor(iEntity, 240, 248, 255, _);
		case 21: SetEntityRenderColor(iEntity, 70, 130, 180, _);
		case 22: SetEntityRenderColor(iEntity, 0, 128, 128, _);
		case 23: SetEntityRenderColor(iEntity, 255, 215, 0, _);
		case 24: SetEntityRenderColor(iEntity, 210, 180, 140, _);
		case 25: SetEntityRenderColor(iEntity, 255, 99, 71, _);
	}
}