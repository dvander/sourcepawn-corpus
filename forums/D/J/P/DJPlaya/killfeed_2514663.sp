// ====[ INCLUDES ]============================================================
#include <sourcemod>

// ====[ DEFINES ]=============================================================
#define	PLUGIN_VERSION			"1.3-B"
#define	dDeaths					(1 << 0)
#define	dKills					(1 << 1)

// ====[ HANDLES | CVARS ]=====================================================
Handle cvarEnabled;

// ====[ VARIABLES ]===========================================================
int g_iEnabled;

public Plugin myinfo =
{
	name = "Hide Bots in Kill Feed",
	author = "ReFlexPoison (Playa Edot)",
	description = "Modifiy the global Killfeed via sm_killfeed",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1684156"
}

public OnPluginStart()
{
	CreateConVar("sm_killfeed_version", PLUGIN_VERSION, "Hide Bots in Kill Feed Version", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD);

	cvarEnabled = CreateConVar("sm_killfeed", "3", "Enable Hide Bots in Kill Feed (Add up values)\n0 = Disabled\n1 = Deaths\n2 = Kills", FCVAR_NONE, true, 0.0, true, 3.0);
	g_iEnabled = GetConVarInt(cvarEnabled);

	HookConVarChange(cvarEnabled, CVarChange);

	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
}

public CVarChange(Handle hConvar, const char[] strOldVal, const char[] strNewVal)
{
	g_iEnabled = GetConVarInt(cvarEnabled);
}

public Action OnPlayerDeath(Handle hEvent, const char[] strName, bool bBroadcast)
{
	if(g_iEnabled <= 0)
		return Plugin_Continue;

	if(g_iEnabled & dDeaths)
	{
		int iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		if(IsValidClient(iVictim))
			SetEventBroadcast(hEvent, true);
	}

	if(g_iEnabled & dKills)
	{
		int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
		if(IsValidClient(iAttacker))
			SetEventBroadcast(hEvent, true);
	}
	return Plugin_Continue;
}

// ====[ STOCKS ]==============================================================
bool IsValidClient(iClient, bool bReplay = true)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}