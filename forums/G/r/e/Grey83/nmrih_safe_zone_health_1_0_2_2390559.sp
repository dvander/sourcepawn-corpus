#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION	"1.0.2"
#define PLUGIN_NAME		"[NMRiH] Safe Zone Health"
#define sName				"\x01[\x04SZH\x01] \x03"
#define sCon				"[SZH]"
#define ADMIN_LVL			ADMFLAG_SLAY

new iSZHealthOffset;
new g_BeamSprite = -1;
new g_HaloSprite = -1;
new aSafeZone[10];
new iNumSafeZones;
new cSZName[] = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'};
new bool:bLateLoad = false;
new bool:bIsAdmin[MAXPLAYERS + 1];
new Handle:h_szh_max = INVALID_HANDLE, Handle:h_szh_amt = INVALID_HANDLE;
new Float:fValue, Float:fNewValue;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "Grey83",
	description = "",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=278699"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	bLateLoad = late;
	return APLRes_Success; 
}

public OnPluginStart()
{
	decl String:game[16];
	GetGameFolderName(game, sizeof(game));
	if(strcmp(game, "nmrih", false) != 0) SetFailState("Unsupported game!");

	CreateConVar("nmrih_szh_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	h_szh_max = CreateConVar("sm_szh_max", "1000.0", "The maximum amount of health, which a safe zone can get by dufflebag", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1000000000.0);
	h_szh_amt = CreateConVar("sm_szh_amt", "25", "Amount safe zone heals at once by dufflebag", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100000000.0);

	RegConsoleCmd("sm_szh", Command_Health, "Show or set the health for all SafeZones on the map");

	iSZHealthOffset = FindSendPropInfo("CFunc_SafeZone", "_health");

	HookEvent("state_change", Event_SC);
	HookEvent("safe_zone_heal", Event_SZH, EventHookMode_Pre);

	if (bLateLoad) FindSafeZones();

	AutoExecConfig(true, "nmrih_health");

	PrintToServer("%s v.%s has been successfully loaded!", PLUGIN_NAME, PLUGIN_VERSION);
}

public OnMapStart()
{
	new Handle:gameConfig = LoadGameConfigFile("funcommands.games");
	new String:buffer[PLATFORM_MAX_PATH];

	if (gameConfig == INVALID_HANDLE)
	{
		SetFailState("Unable to load game config funcommands.games");
		return;
	}

	if (GameConfGetKeyValue(gameConfig, "SpriteBeam", buffer, sizeof(buffer)) && buffer[0]) g_BeamSprite = PrecacheModel(buffer);
	if (GameConfGetKeyValue(gameConfig, "SpriteHalo", buffer, sizeof(buffer)) && buffer[0]) g_HaloSprite = PrecacheModel(buffer);

	CloseHandle(gameConfig);
}

public Event_SC(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iState = GetEventInt(event, "state");
	new iGameType = GetEventInt(event, "game_type");
	if (iState == 3 && iGameType == 1) FindSafeZones();
}

public FindSafeZones()
{
	new String:classname[64];
	new num = 0;
	for(new i = GetMaxClients(); i < GetMaxEntities(); i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, classname, sizeof(classname));
			if(strcmp(classname, "func_safe_zone")==0)
			{
				aSafeZone[num] = i;
				num++;
			}
		}
	}
	iNumSafeZones = num;
}

public OnClientPostAdminCheck(client)
{
	if (1 <= client <= MaxClients) bIsAdmin[client] = CheckCommandAccess(client, "sm_admin", ADMIN_LVL);
}

public Event_SZH(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iIndex = GetEventInt(event, "index");
	fValue = GetEntDataFloat(aSafeZone[iIndex], iSZHealthOffset);
	new Float:fSafeZonesHealthMax = GetConVarFloat(h_szh_max);
	new add = GetConVarInt(h_szh_amt);
	new amt = add;

	fNewValue = fValue + add;
	if (fValue >= fSafeZonesHealthMax)
	{
		fNewValue = fValue;
		amt = 0;
	}
	else if (fNewValue > fSafeZonesHealthMax)
	{
		fNewValue = fSafeZonesHealthMax;
		amt = RoundToNearest(fSafeZonesHealthMax - fValue);
	}
	if (add != 25) SetEventInt(event, "amount", amt);
	if (fValue > 100 - add) CreateTimer(0.1, SetHP, aSafeZone[iIndex]);
	PrintToChatAll("%sSafe zone \x04%c \x03got \x04+%d\x03HP (\x04%.1f\x03HP total)", sName, cSZName[iIndex], amt, fNewValue);
	CreateEffect(1, aSafeZone[iIndex], true);
}

public Action:SetHP(Handle:timer, any:entity)
{
	if (IsValidEntity(entity)) SetEntDataFloat(entity, iSZHealthOffset, fNewValue, true);
}

public Action:Command_Health(client, args)
{
	if(!iNumSafeZones)
	{
		if(!client) PrintToServer("%s There are no safe zones", sCon);
		else PrintToChat(client, "%s \x03There are no safe zones", sName);
		return Plugin_Handled;
	}

	if(!args || (!bIsAdmin[client] && client ))
	{
		for(new i = 0; i < iNumSafeZones; i++)
		{
			fValue = GetEntDataFloat(aSafeZone[i], iSZHealthOffset);
			fNewValue = fValue;
			if(0 < client <= MaxClients)
			{
				PrintToChat(client, "%sSafeZone \x04%c \x03health: \x04%.2f\x03HP", sName, cSZName[i], fValue);
				CreateEffect(client, aSafeZone[i], false);
			}
			else
			{
				PrintToServer("%s SafeZone %c health: %.2fHP", sCon, cSZName[i], fValue);
			}
		}
		return Plugin_Handled;
	}
	else if(args == 1)
	{
		new String:sArg1[10];
		GetCmdArg(1, sArg1, sizeof(sArg1));
		fNewValue = StringToFloat(sArg1);

		for(new i = 0; i < iNumSafeZones; i++)
		{
			fValue = GetEntDataFloat(aSafeZone[i], iSZHealthOffset);
			SetEntDataFloat(aSafeZone[i], iSZHealthOffset, fNewValue, true);
			if(0 < client <= MaxClients) CreateEffect(client, aSafeZone[i], false);
			else PrintToServer("%s SafeZone %c health: %.2fHP", sCon, cSZName[i], fNewValue);
		}
	}
	else if(args > 1)
	{
		new String:sArg1[10], String:sArg2[2];
		GetCmdArg(1, sArg1, sizeof(sArg1));
		GetCmdArg(2, sArg2, sizeof(sArg2));
		fNewValue = StringToFloat(sArg1);
		new iIndex = StringToInt(sArg2);
		fValue = GetEntDataFloat(aSafeZone[iIndex], iSZHealthOffset);

		if (0 <= iIndex < iNumSafeZones)
		{
			SetEntDataFloat(aSafeZone[iIndex], iSZHealthOffset, fNewValue, true);
			if(0 < client <= MaxClients) CreateEffect(client, aSafeZone[iIndex], false);
			else PrintToServer("%s SafeZone %c health: %.2fHP", sCon, cSZName[iIndex], fNewValue);
		}
		else
		{
			if(0 < client <= MaxClients) PrintToChat(client, "%s \x03SafeZone \x04%c \x03does not exist", sName, cSZName[iIndex]);
			else PrintToServer("%s SafeZone %c does not exist", sCon, cSZName[iIndex]);
		}
	}

	return Plugin_Handled;
}

CreateEffect(client, ent, bool:bToAll)
{
	new color[4], Float:fStart, Float:fEnd;
	if(fValue < fNewValue)
	{
		color = {0, 255, 0, 255};
		fStart = 10.0;
		fEnd = 400.0;
	}
	else if(fValue > fNewValue)
	{
		color = {255, 0, 0, 255};
		fStart = 400.0;
		fEnd = 10.0;
	}
	else
	{
		color = {0, 127, 255, 127};
		fStart = 200.0;
		fEnd = 201.0;
	}
	new Float:Pos[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", Pos);
	if (g_BeamSprite > -1 && g_HaloSprite > -1)
	{
		TE_SetupBeamRingPoint(Pos, fStart, fEnd, g_BeamSprite, g_HaloSprite, 0, 15, 3.0, 5.0, 0.0, color, 10, 0);
		if (bToAll) TE_SendToAll();
		else TE_SendToClient(client);
	}
}