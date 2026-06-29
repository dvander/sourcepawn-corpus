#include <sourcemod>
#include <sdktools>

#define TL_VERSION "1.0"

public Plugin myinfo =
{
	name = "[L4D & L4D2] Tank Limiter",
	author = "Psyk0tik (Crasher_3637) & Neon123",
	description = "Limits the number of Tanks alive at any given time.",
	version = TL_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=312958"
};

ConVar g_cvTLEnable, g_cvTLLimit;

public void OnPluginStart()
{
	g_cvTLEnable = CreateConVar("tl_enable", "1", "Enable the Tank Limiter plugin?\n0: OFF\n1: ON", _, true, 0.0, true, 1.0);
	g_cvTLLimit = CreateConVar("tl_limit", "1", "Number of alive Tanks allowed at once.");

	HookEvent("player_spawn", ePlayerSpawn);

	AutoExecConfig(true, "l4d_tank_limiter");
}

public void ePlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int iTankId = event.GetInt("userid"), iTank = GetClientOfUserId(iTankId);
	if (g_cvTLEnable.BoolValue && bIsValidClient(iTank) && bIsTank(iTank))
	{
		CreateTimer(0.1, tTimerRemoveTank, iTankId, TIMER_FLAG_NO_MAPCHANGE);
	}
}

static bool bIsTank(int tank)
{
	return GetClientTeam(tank) == 3 && (GetEngineVersion() == Engine_Left4Dead2 ? GetEntProp(tank, Prop_Send, "m_zombieClass") == 8 : GetEntProp(tank, Prop_Send, "m_zombieClass") == 5);
}

static bool bIsValidClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client);
}

static int iGetTankCount()
{
	int iTankCount;
	for (int iTank = 1; iTank <= MaxClients; iTank++)
	{
		if (IsClientInGame(iTank) && IsPlayerAlive(iTank) && bIsTank(iTank))
		{
			iTankCount++;
		}
	}

	return iTankCount;
}

public Action tTimerRemoveTank(Handle timer, int userid)
{
	int iTank = GetClientOfUserId(userid);
	if (!bIsValidClient(iTank) || !bIsTank(iTank))
	{
		return Plugin_Stop;
	}

	if (!g_cvTLEnable.BoolValue)
	{
		return Plugin_Continue;
	}

	if (iGetTankCount() > g_cvTLLimit.IntValue)
	{
		IsFakeClient(iTank) ? KickClient(iTank) : ForcePlayerSuicide(iTank);
	}

	return Plugin_Continue;
}