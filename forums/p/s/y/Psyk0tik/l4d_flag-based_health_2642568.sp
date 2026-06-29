#include <sourcemod>

#define FH_VERSION "1.0"

public Plugin myinfo =
{
	name = "[L4D & L4D2] Flag-based Health",
	author = "Psyk0tik (Crasher_3637) & foquaxticity",
	description = "Sets players' health based on their flags.",
	version = FH_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=312288"
};

ConVar g_cvEnable, g_cvFlags, g_cvMaxHealth;

public void OnPluginStart()
{
	g_cvEnable = CreateConVar("fh_enable", "1", "Enable \"Flag-based Health\"?\n0: OFF\n1: ON", _, true, 0.0, true, 1.0);
	g_cvFlags = CreateConVar("fh_flags", "z", "Players must have either the \"fh_admin\" override, or one or more of these flags to have custom health.");
	g_cvMaxHealth = CreateConVar("fh_maxhealth", "150", "Max health for affected players.", _, true, 1.0, true, 65535.0);
	CreateConVar("fh_version", FH_VERSION, "Version of \"Flag-based Health.\"", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	HookEvent("player_spawn", vPlayerSpawn);

	AutoExecConfig(true, "l4d_flag-based_health");
}

public void vPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvEnable.BoolValue)
	{
		return;
	}

	int iSurvivor = GetClientOfUserId(event.GetInt("userid"));
	if (0 < iSurvivor <= MaxClients && IsClientInGame(iSurvivor) && GetClientTeam(iSurvivor) == 2)
	{
		char sFlags[32];
		g_cvFlags.GetString(sFlags, sizeof(sFlags));
		int iFlags = ReadFlagString(sFlags);
		if ((iFlags != 0 && (GetUserFlagBits(iSurvivor) & iFlags)) || CheckCommandAccess(iSurvivor, "fh_admin", ADMFLAG_ROOT))
		{
			SetEntityHealth(iSurvivor, g_cvMaxHealth.IntValue);
		}
	}
}