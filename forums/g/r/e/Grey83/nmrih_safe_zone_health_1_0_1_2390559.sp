#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION	"1.0.1"
#define PLUGIN_NAME		"[NMRiH] Safe Zone Health"
#define sName				"\x01[\x04SZH\x01] \x03"
#define sCon				"[SZH]"

new iSZHealthOffset;

new g_BeamSprite = -1;
new g_HaloSprite = -1;
new aSafeZone[10];
new iNumSafeZones;
new String:sSZName[10][2] = {
"A",
"B",
"C",
"D",
"E",
"F",
"G",
"H",
"I",
"J"
};
new bool:g_bLateLoaded = false;
new Handle:h_szh_max = INVALID_HANDLE;
new Float:fSafeZonesHealthMax, Float:fValue, Float:fNewValue;

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
  g_bLateLoaded = late;
  return APLRes_Success;
}

public OnPluginStart()
{
	decl String:game[16];
	GetGameFolderName(game, sizeof(game));
	if(strcmp(game, "nmrih", false) != 0)
	{
		SetFailState("Unsupported game!");
	}

	CreateConVar("nmrih_szh_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	h_szh_max = CreateConVar("sm_szh_max", "1000.0", "The maximum amount of health, which can get a player for killing zombies", FCVAR_PLUGIN, true, 0.0, true, 1000000000.0);

	RegAdminCmd("sm_szh", Command_Health, ADMFLAG_SLAY);
	iSZHealthOffset = FindSendPropInfo("CFunc_SafeZone", "_health");

	fSafeZonesHealthMax = Float:GetConVarFloat(h_szh_max);

	HookConVarChange(h_szh_max, OnConVarChanged);

	HookEvent("state_change", Event_SC);
	HookEvent("safe_zone_heal", Event_SZH, EventHookMode_Pre);

	if (g_bLateLoaded) FindSafeZones();

	AutoExecConfig(true, "nmrih_health");

	PrintToServer("%s v.%s has been successfully loaded!", PLUGIN_NAME, PLUGIN_VERSION);
}
public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == h_szh_max) fSafeZonesHealthMax = StringToFloat(newValue);
}
public OnMapStart()
{
	g_BeamSprite = PrecacheModel("materials/sprites/purplelaser1.vmt", true);
	g_HaloSprite = PrecacheModel("materials/sprites/laser/laser_dot_g.vmt", true);
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

public Event_SZH(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iIndex = GetEventInt(event, "index");
	new iAmount = GetEventInt(event, "amount");
	new iHealth = GetEventInt(event, "health");
	new Float:Pos[3];
	fValue = GetEntDataFloat(aSafeZone[iIndex], iSZHealthOffset);

	fNewValue = fValue + 25;
	if (fValue >= fSafeZonesHealthMax) fNewValue = fValue;
	else if (fNewValue > fSafeZonesHealthMax) fNewValue = fSafeZonesHealthMax;
	if (iHealth > 75) CreateTimer(0.1, SetHP, aSafeZone[iIndex]);
	PrintToChatAll("%sSafe zone \x04%s \x03got \x04+%d\x03HP (\x04%.1f\x03HP total)", sName, sSZName[iIndex], iAmount, fNewValue);
	GetEntPropVector(aSafeZone[iIndex], Prop_Send, "m_vecOrigin", Pos);
	TE_SetupBeamRingPoint(Pos, 10.0, 300.0, g_BeamSprite, g_HaloSprite, 0, 15, 3.0, 5.0, 0.0, {0, 255, 0, 255}, 10, 0);
	TE_SendToAll();
}

public Action:SetHP(Handle:timer, any:entity)
{
	if (IsValidEntity(entity)) SetEntDataFloat(entity, iSZHealthOffset, fNewValue, true);
}

public Action:Command_Health(client, args)
{
	if(!iNumSafeZones)
	{
		if(client) PrintToChat(client, "%s \x03There are no safe zones", sName);
		else PrintToServer("%s There are no safe zones", sCon);
		return Plugin_Handled;
	}
	if(args)
	{
	new String:szBuffer[10];
	GetCmdArg(1, szBuffer, sizeof(szBuffer));
	fNewValue = StringToFloat(szBuffer);
	}
	for(new i = 0; i < iNumSafeZones; i++)
	{
		fValue = GetEntDataFloat(aSafeZone[i], iSZHealthOffset);
		if(client)
		{
			new color[4], Float:fStart, Float:fEnd;
			if(!args) PrintToChat(client, "%sSafeZone \x04%s \x03health: \x04%.2f\x03HP", sName, sSZName[i], fValue);
			else if(args > 0)
			{
				if(fValue < fNewValue)
				{
					color[0] = 0;
					color[1] = 255;
					color[2] = 0;
					color[3] = 255;
					fStart = 10.0;
					fEnd = 400.0;
				}
				else if(fValue > fNewValue)
				{
					color[0] = 255;
					color[1] = 0;
					color[2] = 0;
					color[3] = 255;
					fStart = 400.0;
					fEnd = 10.0;
				}
				else
				{
					color[0] = 0;
					color[1] = 127;
					color[2] = 255;
					color[3] = 127;
					fStart = 200.0;
					fEnd = 201.0;
				}
				new Float:Pos[3];
				GetEntPropVector(aSafeZone[i], Prop_Send, "m_vecOrigin", Pos);
				SetEntDataFloat(aSafeZone[i], iSZHealthOffset, fNewValue, true);
				TE_SetupBeamRingPoint(Pos, fStart, fEnd, g_BeamSprite, g_HaloSprite, 0, 15, 3.0, 5.0, 0.0, color, 10, 0);
				if(client) TE_SendToClient(client);
			}
		}
		else
		{
			if(!args) PrintToServer("%s SafeZone %s health: %.2fHP", sCon, sSZName[i], fValue);
 			else if(args > 0)
			{
				SetEntDataFloat(aSafeZone[i], iSZHealthOffset, fNewValue, true);
			}
		}
	}
	return Plugin_Handled;
}