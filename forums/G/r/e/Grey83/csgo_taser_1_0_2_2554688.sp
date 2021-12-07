#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sdkhooks>

static const char	PLUGIN_NAME[]		= "[CSGO] Free taser",
					PLUGIN_VERSION[]	= "1.0.2";

static const int	ACCESS_FLAG			= ADMFLAG_RESERVATION;

int iAmmoOffset = -1,
	iClip1Offset = -1;

bool bFreeTaser,
	bInfTaser;

enum {
	CVar_FreeTaser,
	CVar_InfTaser
};

public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author		= "Grey83",
	description	= "Give free and/or infinite taser to player on spawn in CSGO",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?t=264043"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		strcopy(error, err_max, "Only CS:GO are supported!");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	if((iAmmoOffset = FindSendPropInfo("CBasePlayer", "m_iAmmo")) == -1)
		SetFailState("Can't find 'm_iAmmo' offset!");
	if((iClip1Offset = FindSendPropInfo("CWeaponTaser", "m_iClip1")) == -1)
		SetFailState("Can't find 'm_iClip1' offset!");

	CreateConVar("csgo_taser_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);

	ConVar CVar;
	(CVar = CreateConVar("sm_taser_free",	"1", "On/Off free taser on spawn.", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(CVarChanged_FreeTaser);
	NewCVarValue_Bool(CVar_FreeTaser, CVar);

	(CVar = CreateConVar("sm_taser_inf",	"1", "On/Off Infinite taser.", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(CVarChanged_InfTaser);
	NewCVarValue_Bool(CVar_InfTaser, CVar);

	RegConsoleCmd("sm_zeus", Cmd_GetTaser);
	RegConsoleCmd("sm_taser", Cmd_GetTaser);
}

public void CVarChanged_FreeTaser(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	NewCVarValue_Bool(CVar_FreeTaser, CVar);
}

public void CVarChanged_InfTaser(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	NewCVarValue_Bool(CVar_InfTaser, CVar);
}

stock void NewCVarValue_Bool(int cvar_type, ConVar CVar)
{
	switch(cvar_type)
	{
		case CVar_FreeTaser:
		{
			if(bFreeTaser == (bFreeTaser = CVar.BoolValue)) return;

			if(bFreeTaser) HookEvent("player_spawn", Event_PlayerSpawn);
			else UnhookEvent("player_spawn", Event_PlayerSpawn);
		}
		case CVar_InfTaser:
		{
			if(bInfTaser == (bInfTaser = CVar.BoolValue)) return;

			if(bInfTaser) HookEvent("weapon_fire", Event_WeaponFire);
			else UnhookEvent("weapon_fire", Event_WeaponFire);
		}
	}
}

public Action Cmd_GetTaser(int client, int args)
{
	if(client && IsClientInGame(client) && GetUserFlagBits(client) & ACCESS_FLAG
	&& IsPlayerAlive(client) && GetClientTeam(client) > 1)
		GivePlayerItem(client, "weapon_taser");

	return Plugin_Handled;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.1, Timer_Spawn, event.GetInt("userid"));
}

public Action Timer_Spawn(Handle timer, any client)
{
	if(!(client = GetClientOfUserId(client))) return;

	if(GetClientTeam(client) > 1) GivePlayerItem(client, "weapon_taser");
}

public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	static int client;
	if(!(client = GetClientOfUserId(event.GetInt("userid")))) return;

	if(GetClientTeam(client) > 1)
	{
		static char weapon[64];
		event.GetString("weapon", weapon, sizeof(weapon));
		if(StrEqual("taser", weapon) && IsClientInGame(client) && IsPlayerAlive(client))
		{
			static int iWeapon;
			if(IsValidEdict((iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))) && iAmmoOffset)
				SetEntData(iWeapon, iClip1Offset, 2, _, true);
		}
	}
}