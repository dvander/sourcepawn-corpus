/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>
#define IDENTIFIER_MAX_LENGTH 6
#define FIRST_AID_KIT_IDENTIFIER "Medkit"
#define PAIN_PILLS_IDENTIFIER "Pills"
#define MOLOTOV_IDENTIFIER "Molly"
#define PIPE_BOMB_IDENTIFIER "Pipe"
#define HEALING_IDENTIFIER "-HEAL-"
#define EMPTY_SLOT_IDENTIFIER "---"
public Plugin:myinfo = 
{
	name = "L4D Infected HUD",
	author = "Frustian",
	description = "Adds a HUD to infected/spectators/dead survivors to easily see the survivor's status without pressing tab",
	version = "1.2-Long Identifiers",
	url = ""
}

new Handle:g_hEnabled;
new Handle:g_hHUDType;
new Handle:g_hPanelWait;
new Handle:g_hHUDTimer;
new Handle:g_hSurvivor;
new String:g_sSurvivorNames[4][8] = {"Bill", "Zoey", "Francis", "Louis"};
new g_iClientMenuStatus[MAXPLAYERS+1];
public OnPluginStart()
{
	CreateConVar("l4d_infectedhud_version", "1.2-Long Identifiers", "L4D Infected HUD Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("l4d_infectedhud_enabled", "1", "L4D Infected HUD Enable/Disable",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hHUDType = CreateConVar("l4d_infectedhud_type", "1", "1: Full; 2: Concise",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hPanelWait = CreateConVar("l4d_infectedhud_panelwait", "15", "How many seconds it waits if a menu was sent to the client",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSurvivor = CreateConVar("l4d_infectedhud_survivors", "0", "If 1, show the infected HUD to survivors",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	RegConsoleCmd("sm_enableihud", EnableHUD);
	RegConsoleCmd("sm_disableihud", DisableHUD);
	RegConsoleCmd("sm_toggleihud", ToggleHUD);
}
public OnMapStart()
{
	if (!GetConVarInt(g_hEnabled))
		return;
	for (new i=1;i<=MaxClients;i++)
		g_iClientMenuStatus[i] = 0;
	if (g_hHUDTimer != INVALID_HANDLE)
		CloseHandle(g_hHUDTimer);
	g_hHUDTimer = CreateTimer(1.0, DrawInfectedHUD, _, TIMER_REPEAT);
}
public OnMapEnd()
{
	if (!GetConVarInt(g_hEnabled))
		return;
	for (new i=1;i<MaxClients;i++)
		g_iClientMenuStatus[i] = 0;
	//if (g_hHUDTimer != INVALID_HANDLE)
		//CloseHandle(g_hHUDTimer);
}
public OnClientDisconnect(iClient)
	g_iClientMenuStatus[iClient] = 0;
public Action:EnableHUD(iClient, args)
{
	if (!GetConVarInt(g_hEnabled))
		return Plugin_Handled;
	g_iClientMenuStatus[iClient] = 2;
	return Plugin_Handled;
}
public Action:DisableHUD(iClient, args)
{
	if (!GetConVarInt(g_hEnabled))
		return Plugin_Handled;
	g_iClientMenuStatus[iClient] = 3;
	return Plugin_Handled;
}
public Action:ToggleHUD(iClient, args)
{
	if (!GetConVarInt(g_hEnabled))
		return Plugin_Handled;
	if (g_iClientMenuStatus[iClient] == 3)
		g_iClientMenuStatus[iClient] = 2;
	else
		g_iClientMenuStatus[iClient] = 3;
	return Plugin_Handled;
}
public Action:DrawInfectedHUD(Handle:timer)
{
	if (!GetConVarInt(g_hEnabled))
		return Plugin_Stop;
	if (!GetConVarInt(FindConVar("director_ready_duration")))
		return Plugin_Continue;
	new Handle:hPanel = CreatePanel();
	switch(GetConVarInt(g_hHUDType))
	{
		case 1:
		{
			new iSurvivorClient[4];
			decl String:sTempString[512];
			decl String:sNameString[MAX_NAME_LENGTH+1];
			decl String:sIdentifier2[IDENTIFIER_MAX_LENGTH+1],String:sIdentifier3[IDENTIFIER_MAX_LENGTH+1],String:sIdentifier4[IDENTIFIER_MAX_LENGTH+1];
			for (new i=0;i<4;i++)
				iSurvivorClient[i] = 0;
			for (new i=1;i<=MaxClients;i++)
				if (IsClientInGame(i) && GetClientTeam(i) == 2)
					iSurvivorClient[GetEntProp(i, Prop_Send, "m_survivorCharacter")] = i;
			for (new i=0;i<4;i++)
			{
				if (iSurvivorClient[i])
				{
					GetClientName(iSurvivorClient[i], sNameString, sizeof(sNameString));
					if (strlen(sNameString) > 25)
					{
						sNameString[22] = '.';
						sNameString[23] = '.';
						sNameString[24] = '.';
						sNameString[25] = 0;
					}
					if (!IsFakeClient(iSurvivorClient[i]))
						Format(sTempString, sizeof(sTempString), "%s (%s)", sNameString, g_sSurvivorNames[i]);
					else
						sTempString = g_sSurvivorNames[i];
					DrawPanelText(hPanel, sTempString);
					if (IsPlayerAlive(iSurvivorClient[i]))
					{
						decl String:sIncapState[32];
						new iIncapCount = GetEntProp(iSurvivorClient[i], Prop_Send, "m_currentReviveCount");
						new iMaxIncap = GetConVarInt(FindConVar("survivor_max_incapacitated_count"));
						if (GetEntProp(iSurvivorClient[i], Prop_Send, "m_isIncapacitated"))
							sIncapState = "(Incapacitated)";
						else if (!iIncapCount)
							sIncapState = "";
						else if (iIncapCount < iMaxIncap)
							Format(sIncapState, sizeof(sTempString), "(Incapped %d time)", iIncapCount);
						else
							sIncapState = "(Black & White)";
						GetSlotInfo(iSurvivorClient[i], 2, sIdentifier2);
						GetSlotInfo(iSurvivorClient[i], 3, sIdentifier3);
						GetSlotInfo(iSurvivorClient[i], 4, sIdentifier4);
						Format(sTempString, sizeof(sTempString), "->   %dHP %s %s %s %s", GetSurvivorHealth(iSurvivorClient[i]), sIdentifier3, sIdentifier4, sIdentifier2, sIncapState);
					}
					else
						sTempString = "->   Dead";
					DrawPanelText(hPanel, sTempString);
				}
			}
		}
		case 2:
		{
			decl String:sTempString[512];
			decl String:sNameString[MAX_NAME_LENGTH];
			decl String:sIdentifier2[IDENTIFIER_MAX_LENGTH+1],String:sIdentifier3[IDENTIFIER_MAX_LENGTH+1],String:sIdentifier4[IDENTIFIER_MAX_LENGTH+1];
			for (new i=1;i<=MaxClients;i++)
				if (IsClientInGame(i) && GetClientTeam(i) == 2)
				{
					if (IsPlayerAlive(i))
					{
						GetClientName(i, sNameString, sizeof(sNameString));
						if (strlen(sNameString) > 20)
						{
							sNameString[17] = '.';
							sNameString[18] = '.';
							sNameString[19] = '.';
							sNameString[20] = 0;
						}
						new String:sStatus[5] = "";
						new iIncapCount = GetEntProp(i, Prop_Send, "m_currentReviveCount");
						new iMaxIncap = GetConVarInt(FindConVar("survivor_max_incapacitated_count"));
						if (GetEntProp(i, Prop_Send, "m_isIncapacitated"))
							sStatus = "(I)";
						else if (!iIncapCount)
							sStatus = "";
						else if (iIncapCount < iMaxIncap)
							Format(sStatus, sizeof(sTempString), "(%d)", iIncapCount);
						else
							sStatus = "(B)";
						GetSlotInfo(i, 2, sIdentifier2);
						GetSlotInfo(i, 3, sIdentifier3);
						GetSlotInfo(i, 4, sIdentifier4);
						Format(sTempString, sizeof(sTempString), "->%s - %dHP %s %s %s %s", sNameString, GetSurvivorHealth(i), sIdentifier3, sIdentifier4, sIdentifier2, sStatus);
						DrawPanelText(hPanel, sTempString);
					}
				}
		}
		default:
			return Plugin_Continue;
	}
	for (new i=1;i<=MaxClients;i++)
		if (IsClientInGame(i) && !IsFakeClient(i) && (GetClientTeam(i) != 2 || !IsPlayerAlive(i) || GetConVarInt(g_hSurvivor)))
			if ((GetClientMenu(i) == MenuSource_RawPanel || GetClientMenu(i) == MenuSource_None) && g_iClientMenuStatus[i] < 3)
				SendPanelToClient(hPanel, i, Menu_PanelHandler, 1);
			else
				if (g_iClientMenuStatus[i] == 2)
				{
					SendPanelToClient(hPanel, i, Menu_PanelHandler, 1);
					g_iClientMenuStatus[i] = 0;
				}
				else if (g_iClientMenuStatus[i] == 0)
				{
					CreateTimer(GetConVarFloat(g_hPanelWait), FreePanel, i);
					g_iClientMenuStatus[i] = 1;
				}
	return Plugin_Continue;
}
public Action:FreePanel(Handle:timer, any:iClient)
{
	if (g_iClientMenuStatus[iClient] != 3)
		g_iClientMenuStatus[iClient] = 2;
}
public GetSurvivorHealth(iClient)
{
	new iTempHealth = RoundToCeil(GetEntPropFloat(iClient, Prop_Send, "m_healthBuffer") - ((GetGameTime() -GetEntPropFloat(iClient, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate"))));
	if (iTempHealth > 0)
		return GetClientHealth(iClient) + iTempHealth - 1;
	return GetClientHealth(iClient)
}
public GetSlotInfo(iClient, iSlot, String:Identifier[IDENTIFIER_MAX_LENGTH+1])
{
	decl String:sWeaponClass[64];
	if (GetPlayerWeaponSlot(iClient, iSlot) > 0)
		GetEdictClassname(GetPlayerWeaponSlot(iClient, iSlot), sWeaponClass, 64);
	else
	{
		Identifier = EMPTY_SLOT_IDENTIFIER;
		return;
	}
	switch(iSlot)
	{
		case 2:
			if (StrEqual("weapon_molotov", sWeaponClass))
				Identifier = MOLOTOV_IDENTIFIER;
			else if (StrEqual("weapon_pipe_bomb", sWeaponClass))
				Identifier = PIPE_BOMB_IDENTIFIER;
		case 3:
			if (GetEntProp(iClient, Prop_Send, "m_healTarget") > 0)
				if (RoundToCeil(GetGameTime())%2)
					Identifier = FIRST_AID_KIT_IDENTIFIER;
				else
					Identifier = HEALING_IDENTIFIER;
			else
				Identifier = FIRST_AID_KIT_IDENTIFIER;
		case 4:
			Identifier = PAIN_PILLS_IDENTIFIER;
		default:
			Identifier = EMPTY_SLOT_IDENTIFIER;
	}
}
public Menu_PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}
