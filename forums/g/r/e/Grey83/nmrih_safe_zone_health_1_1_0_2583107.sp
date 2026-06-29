#pragma semicolon 1
#pragma newdecls required

#include <sdktools>

static const char	PLUGIN_VERSION[]	= "1.1.0",
					PLUGIN_NAME[]		= "[NMRiH] Safe Zone Health",

					sName[]				= "\x01[\x04SZH\x01] \x03",
					sCon[]				= "[SZH]";
#define ADMIN_LVL			ADMFLAG_SLAY

bool bLateLoad,
	bIsAdmin[MAXPLAYERS + 1];
int iMaxHP,
	iMaxAmt,
	iHealth,
	iHealAmt,
	iSZHealthOffset,
	g_BeamSprite = -1,
	g_HaloSprite = -1,
	aSafeZone[10],
	iNumSafeZones;
float fValue,
	fNewValue,
	fZonePos[10][3],
	fZoneSize[10];

public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author		= "Grey83",
	description	= "",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?t=278699"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLateLoad = late;
	return APLRes_Success; 
}

public void OnPluginStart()
{
	char game[8];
	GetGameFolderName(game, sizeof(game));
	if(strcmp(game, "nmrih", false)) SetFailState("Unsupported game!");

	CreateConVar("nmrih_szh_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ConVar CVar;
	(CVar = CreateConVar("sm_szh_max", "1000", "The maximum amount of health, which a safe zone can get by dufflebag", FCVAR_NOTIFY, true, _, true, 100000000.0)).AddChangeHook(CVarChanged_MaxHP);
	iMaxHP = CVar.IntValue;
	(CVar = CreateConVar("sm_szh_amt", "25", "Amount safe zone heals at once by dufflebag", FCVAR_NOTIFY, true, _, true, 100000000.0)).AddChangeHook(CVarChanged_MaxAmt);
	iMaxAmt = CVar.IntValue;

//	"sv_safezone_heal_amt"	Amount safe zone heals at once
	(CVar = FindConVar("sv_safezone_heal_amt")).AddChangeHook(CVarChanged_HealAmt);
	iHealAmt = CVar.IntValue;
//	"sv_safezone_health"	Maximum HP of safe zones
	(CVar = FindConVar("sv_safezone_health")).AddChangeHook(CVarChanged_Health);
	iHealth = CVar.IntValue;


	RegConsoleCmd("sm_szh", Command_Health, "Show or set the health for all SafeZones on the map");

	iSZHealthOffset = FindSendPropInfo("CFunc_SafeZone", "_health");

	HookEvent("state_change", Event_SC);
	HookEvent("safe_zone_heal", Event_SZH, EventHookMode_Pre);

	if(bLateLoad) FindSafeZones();

	AutoExecConfig(true, "nmrih_health");

	PrintToServer("%s v.%s has been successfully loaded!", PLUGIN_NAME, PLUGIN_VERSION);
}

public void CVarChanged_MaxHP(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	iMaxHP = CVar.IntValue;
}

public void CVarChanged_MaxAmt(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	iMaxAmt = CVar.IntValue;
}

public void CVarChanged_HealAmt(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	iHealAmt = CVar.IntValue;
}

public void CVarChanged_Health(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	iHealth = CVar.IntValue;
}

public void OnMapStart()
{
	Handle gameConfig = LoadGameConfigFile("funcommands.games");
	if(gameConfig == INVALID_HANDLE)
	{
		SetFailState("Unable to load game config funcommands.games");
		return;
	}

	char buffer[PLATFORM_MAX_PATH];
	if(GameConfGetKeyValue(gameConfig, "SpriteBeam", buffer, sizeof(buffer)) && buffer[0]) g_BeamSprite = PrecacheModel(buffer);
	if(GameConfGetKeyValue(gameConfig, "SpriteHalo", buffer, sizeof(buffer)) && buffer[0]) g_HaloSprite = PrecacheModel(buffer);

	CloseHandle(gameConfig);
}

public void Event_SC(Event event, const char[] name, bool dontBroadcast)
{
	if(event.GetInt("game_type") == 1 && event.GetInt("state") == 3) FindSafeZones();
}

public void FindSafeZones()
{
	char class[24];
	int num;
	float min[3], max[3], size[3];
	for(int i = MaxClients, ent = GetMaxEntities(); i < ent; i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i) && GetEdictClassname(i, class, sizeof(class)) && !strcmp(class, "func_safe_zone"))
		{
			aSafeZone[num] = i;
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", fZonePos[num]);
			GetEntPropVector(i, Prop_Data, "m_vecMins", min);
			GetEntPropVector(i, Prop_Data, "m_vecMaxs", max);
			fZonePos[num][2] = max[2];
			SubtractVectors(max, min, size);
			fZoneSize[num] = FloatCompare(size[0], size[1]) != -1 ? size[0] : size[1];
			num++;
		}
	}
	iNumSafeZones = num;
}

public void OnClientPostAdminCheck(int client)
{
	if(0 < client <= MaxClients) bIsAdmin[client] = CheckCommandAccess(client, "sm_admin", ADMIN_LVL);
}

public void Event_SZH(Event event, const char[] name, bool dontBroadcast)
{
	int iIndex = GetEventInt(event, "index");
	fValue = GetEntDataFloat(aSafeZone[iIndex], iSZHealthOffset);
	int iAmount = GetEventInt(event, "amount");
	if(iAmount > iHealAmt) iMaxAmt *= iAmount / iHealAmt;
	int amt = iMaxAmt;

	fNewValue = fValue + iMaxAmt;
	if(fValue >= iMaxHP)
	{
		fNewValue = fValue;
		amt = 0;
	}
	else if(fNewValue > iMaxHP)
	{
		fNewValue = iMaxHP + 0.0;
		amt = RoundToNearest(iMaxHP - fValue);
	}
	if(iHealAmt != iMaxAmt) SetEventInt(event, "amount", amt);
	if(fValue > iHealth - iMaxAmt) CreateTimer(0.1, SetHP, aSafeZone[iIndex]);
	PrintToChatAll("%sSafe zone \x04%c \x03got \x04+%d\x03HP (\x04%.1f\x03HP total)", sName, iIndex+'A', amt, fNewValue);
	CreateEffect(1, aSafeZone[iIndex], true);
}

public Action SetHP(Handle timer, any entity)
{
	if(IsValidEntity(entity)) SetEntDataFloat(entity, iSZHealthOffset, fNewValue, true);
}

public Action Command_Health(int client, int args)
{
	if(!iNumSafeZones)
	{
		if(!client) PrintToServer("%s There are no safe zones", sCon);
		else PrintToChat(client, "%s \x03There are no safe zones", sName);
		return Plugin_Handled;
	}

	if(!args || (!bIsAdmin[client] && client ))
	{
		for(int i; i < iNumSafeZones; i++)
		{
			fValue = GetEntDataFloat(aSafeZone[i], iSZHealthOffset);
			if(0 < client <= MaxClients)
			{
				PrintToChat(client, "%sSafeZone \x04%c \x03health: \x04%.2f\x03HP", sName, i+'A', fValue);
				CreateEffect(client, aSafeZone[i], false);
			}
			else PrintToServer("%s SafeZone %c health: %.2fHP", sCon, i+'A', fValue);
		}
	}
	else if(args == 1)
	{
		char sArg1[10];
		GetCmdArg(1, sArg1, sizeof(sArg1));
		fNewValue = StringToFloat(sArg1);

		for(int i; i < iNumSafeZones; i++)
		{
			SetEntDataFloat(aSafeZone[i], iSZHealthOffset, fNewValue, true);
			if(0 < client <= MaxClients) CreateEffect(client, aSafeZone[i], false);
			else PrintToServer("%s SafeZone %c health: %.2fHP", sCon, i+'A', fNewValue);
		}
	}
	else if(args > 1)
	{
		char sArg1[10], sArg2[2];
		GetCmdArg(2, sArg2, sizeof(sArg2));
		int iIndex = StringToInt(sArg2);

		if(-1 < iIndex < iNumSafeZones)
		{
			GetCmdArg(1, sArg1, sizeof(sArg1));
			fNewValue = StringToFloat(sArg1);
			SetEntDataFloat(aSafeZone[iIndex], iSZHealthOffset, fNewValue, true);
			if(0 < client <= MaxClients) CreateEffect(client, aSafeZone[iIndex], false);
			else PrintToServer("%s SafeZone %c health: %.2fHP", sCon, iIndex+'A', fNewValue);
		}
		else
		{
			if(0 < client <= MaxClients) PrintToChat(client, "%s \x03SafeZone \x04%c \x03does not exist", sName, iIndex+'A');
			else PrintToServer("%s SafeZone %c does not exist", sCon, iIndex+'A');
		}
	}

	return Plugin_Handled;
}

stock void ShowZones()
{
	static const int color[] = {0, 255, 0, 127};
	if(g_BeamSprite > -1 && g_HaloSprite > -1)
	{
		for(int i; i < iNumSafeZones; i++)
		{
			fValue = GetEntDataFloat(aSafeZone[i], iSZHealthOffset);
			if(fValue < iHealth)
			{
				color[1] = RoundFloat(25500/fValue);
				color[0] = 255 - color[1];
			}

			TE_SetupBeamRingPoint(fZonePos[i], fZoneSize, fZoneSize, g_BeamSprite, g_HaloSprite, 0, 15, 3.0, 5.0, 0.0, color, 10, FBEAM_FOREVER);	// 3 сек
			TE_SendToAll();
		}
	}
}

stock void CreateEffect(int client, int ent, bool bToAll)
{
	int color[4];
	float fStart, fEnd, Pos[3];
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
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", Pos);
	if(g_BeamSprite > -1 && g_HaloSprite > -1)
	{
		TE_SetupBeamRingPoint(Pos, fStart, fEnd, g_BeamSprite, g_HaloSprite, 0, 15, 3.0, 5.0, 0.0, color, 10, 0);
		if(bToAll) TE_SendToAll();
		else TE_SendToClient(client);
	}
}