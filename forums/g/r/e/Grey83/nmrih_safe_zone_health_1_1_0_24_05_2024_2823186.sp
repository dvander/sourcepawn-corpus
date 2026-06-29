#pragma semicolon 1
#pragma newdecls required

#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

#define ADMIN_LVL		ADMFLAG_SLAY

static const char
	PL_NAME[]			= "[NMRiH] Safe Zone Health",
	PL_VER[]			= "1.1.0_24.05.2024",

	CHAT_PREFIX[]		= "\x01[\x04SZH\x01] \x03",
	CONSOLE_PREFIX[]	= "[SZH]";

ArrayList
	hSafeZone;
bool
	bLate;
int
	iSZHealthOffset,
	g_BeamSprite = -1,
	g_HaloSprite = -1,
	iAmt;
float
	fValue,
	fNewValue,
	fMax;

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Safe zone management",
	author		= "Grey83",
	url			= "https://forums.alliedmods.net/showthread.php?t=278699"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char game[8];
	GetGameFolderName(game, sizeof(game));
	if(strcmp(game, "nmrih", false))
	{
		FormatEx(error, err_max, "Unsupported game!");
		return APLRes_Failure;
	}

	bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	if((iSZHealthOffset = FindSendPropInfo("CFunc_SafeZone", "_health")) < 1)
		SetFailState("Can't find offset 'CFunc_SafeZone::_health'.");

	CreateConVar("nmrih_szh_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	ConVar cvar;
	cvar = CreateConVar("sm_szh_max", "1000", "The maximum amount of health, which a safe zone can get by dufflebag", _, true, _, true, 1000000000.0);
	fMax = cvar.FloatValue;
	cvar.AddChangeHook(CVarChange_Max);

	cvar = CreateConVar("sm_szh_amt", "25", "Amount safe zone heals at once by dufflebag", _, true, _, true, 100000000.0);
	iAmt = cvar.IntValue;
	cvar.AddChangeHook(CVarChange_Amt);

	AutoExecConfig(true, "nmrih_health");

	RegConsoleCmd("sm_szh", Command_Health, "Show or set the health for all SafeZones on the map");

	HookEvent("state_change", Event_SC);
	HookEvent("safe_zone_heal", Event_SZH, EventHookMode_Pre);

	hSafeZone = new ArrayList();

	if(bLate) FindSafeZones();

	PrintToServer("%s v.%s has been successfully loaded!", PL_NAME, PL_VER);
}

public void CVarChange_Max(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fMax = cvar.FloatValue;
}

public void CVarChange_Amt(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iAmt = cvar.IntValue;
}

public void OnMapStart()
{
	Handle gameConfig = LoadGameConfigFile("funcommands.games");
	if(!gameConfig)
		SetFailState("Unable to load game config funcommands.games");

	char buffer[PLATFORM_MAX_PATH];
	if(GameConfGetKeyValue(gameConfig, "SpriteBeam", buffer, sizeof(buffer)) && buffer[0])
		g_BeamSprite = PrecacheModel(buffer);
	if(GameConfGetKeyValue(gameConfig, "SpriteHalo", buffer, sizeof(buffer)) && buffer[0])
		g_HaloSprite = PrecacheModel(buffer);

	CloseHandle(gameConfig);

}

public void Event_SC(Event event, const char[] name, bool dontBroadcast)
{
	if(event.GetInt("state") == 3 && event.GetInt("game_type") == 1) FindSafeZones();
}

void FindSafeZones()
{
	if(hSafeZone.Length) hSafeZone.Clear();
	int ent = MaxClients+1;
	while((ent = FindEntityByClassname(ent, "func_safe_zone")) != -1) hSafeZone.Push(ent);
}

public void Event_SZH(Event event, const char[] name, bool dontBroadcast)
{
	int iIndex = event.GetInt("index"), amt = iAmt, ent = hSafeZone.Get(iIndex);
	fValue = GetEntDataFloat(ent, iSZHealthOffset);
	fNewValue = fValue + iAmt;
	if(fValue >= fMax)
	{
		fNewValue = fValue;
		amt = 0;
	}
	else if(fNewValue > fMax)
	{
		fNewValue = fMax;
		amt = RoundToNearest(fMax - fValue);
	}
	if(iAmt != 25) event.GetInt("amount", amt);
	if(fValue > 100 - iAmt) CreateTimer(0.1, SetHP, ent);
	PrintToChatAll("%sSafe zone \x04%c \x03got \x04+%d\x03HP (\x04%.1f\x03HP total)", CHAT_PREFIX, ('A' + iIndex), amt, fNewValue);
	CreateEffect(ent);
}

public Action SetHP(Handle timer, int entity)
{
	if(IsValidEntity(entity)) SetEntDataFloat(entity, iSZHealthOffset, fNewValue, true);
	return Plugin_Stop;
}

public Action Command_Health(int client, int args)
{
	if(!hSafeZone.Length)
	{
		if(!client) PrintToServer("%s There are no safe zones", CONSOLE_PREFIX);
		else PrintToChat(client, "%s \x03There are no safe zones", CHAT_PREFIX);
		return Plugin_Handled;
	}

	int ent;
	if(!args || (client && !(GetUserFlagBits(client) & ADMIN_LVL)))
	{
		for(int i, num = hSafeZone.Length; i < num; i++)
		{
			ent = hSafeZone.Get(i);
			fValue = GetEntDataFloat(ent, iSZHealthOffset);
			fNewValue = fValue;
			if(client)
			{
				PrintToChat(client, "%sSafeZone \x04%c \x03health: \x04%.2f\x03HP", CHAT_PREFIX, ('A' + i), fValue);
				CreateEffect(ent, client);
			}
			else PrintToServer("%s SafeZone %c health: %.2fHP", CONSOLE_PREFIX, ('A' + i), fValue);
		}
		return Plugin_Handled;
	}
	else if(args == 1)
	{
		char sArg1[12];
		GetCmdArg(1, sArg1, sizeof(sArg1));
		fNewValue = StringToFloat(sArg1);

		for(int i, num = hSafeZone.Length; i < num; i++)
		{
			ent = hSafeZone.Get(i);
			fValue = GetEntDataFloat(ent, iSZHealthOffset);
			SetEntDataFloat(ent, iSZHealthOffset, fNewValue, true);
			if(client) CreateEffect(ent, client);
			else PrintToServer("%s SafeZone %c health: %.2fHP", CONSOLE_PREFIX, ('A' + i), fNewValue);
		}
	}
	else if(args > 1)
	{
		char sArg1[12], sArg2[4];
		GetCmdArg(1, sArg1, sizeof(sArg1));
		GetCmdArg(2, sArg2, sizeof(sArg2));
		fNewValue = StringToFloat(sArg1);
		int iIndex = StringToInt(sArg2);
		fValue = GetEntDataFloat(hSafeZone.Get(iIndex), iSZHealthOffset);

		if(0 <= iIndex < hSafeZone.Length)
		{
			ent = hSafeZone.Get(iIndex);
			SetEntDataFloat(ent, iSZHealthOffset, fNewValue, true);
			if(client) CreateEffect(ent, client);
			else PrintToServer("%s SafeZone %c health: %.2fHP", CONSOLE_PREFIX, ('A' + iIndex), fNewValue);
		}
		else
		{
			if(client) PrintToChat(client, "%s \x03SafeZone \x04%c \x03does not exist", CHAT_PREFIX, ('A' + iIndex));
			else PrintToServer("%s SafeZone %c does not exist", CONSOLE_PREFIX, ('A' + iIndex));
		}
	}

	return Plugin_Handled;
}

void CreateEffect(int ent, int client = -1)
{
	static int color[4];
	static float fStart, fEnd, Pos[3];
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
	if(g_BeamSprite > 0 && g_HaloSprite > 0)
	{
		TE_SetupBeamRingPoint(Pos, fStart, fEnd, g_BeamSprite, g_HaloSprite, 0, 15, 3.0, 5.0, 0.0, color, 10, 0);
		if(client == -1) TE_SendToAll();
		else if(client) TE_SendToClient(client);
	}
}