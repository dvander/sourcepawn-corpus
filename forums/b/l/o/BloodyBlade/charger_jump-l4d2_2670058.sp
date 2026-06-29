#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "2.0"

#define ZOMBIECLASS_CHARGER 6

ConVar cvarInertiaVault;
ConVar cvarInertiaVaultPower;
ConVar cvarInertiaVaultDelay;

Handle PluginStartTimer = null;

bool isCharging[MAXPLAYERS+1] = false;
bool buttondelay[MAXPLAYERS+1] = false;
bool isInertiaVault = false;

float ivWait;
Handle JumpTimer[MAXPLAYERS+1] = null;
int timerElapsed = 0;

public Plugin myinfo = 
{
    name = "[L4D2] Charger Jump",
    author = "Mortiegama",
    description = "Allows Chargers To Jump While Charging.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2116076#post2116076"
};

public void OnPluginStart()
{
	CreateConVar("charger_jump-l4d2_version", PLUGIN_VERSION, "Charger Jump Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cvarInertiaVault = CreateConVar("charger_jump-l4d2_inertiavault", "1", "Enable/Disable Plugin", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarInertiaVaultPower = CreateConVar("charger_jump-l4d2_inertiavaultpower", "425.0", "Inertia Vault Value Applied To Charger Jump", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarInertiaVaultDelay = CreateConVar("charger_jump-l4d2_inertiavaultdelay", "11.0", "Delay Before Inertia Vault Kicks In", FCVAR_NOTIFY, true, 0.0, false, _);
	
	HookEvent("charger_charge_start", OnChargerChargeStart);
	HookEvent("charger_carry_start", OnChargerCarryStart);
	HookEvent("charger_charge_end", OnChargerClear);
	HookEvent("charger_carry_end", OnChargerClear);
	HookEvent("charger_killed", OnChargerClear);

	ivWait = GetConVarFloat(cvarInertiaVaultDelay);

	AutoExecConfig(true, "charger_jump-l4d2");
	if (PluginStartTimer == null) PluginStartTimer = CreateTimer(3.0, OnPluginStart_Delayed);
}

public Action OnPluginStart_Delayed(Handle timer)
{	
	if (GetConVarInt(cvarInertiaVault)) isInertiaVault = true;

	if (PluginStartTimer != null)
	{
 		delete(PluginStartTimer);
		PluginStartTimer = null;
	}

	return Plugin_Stop;
}

public Action OnChargerChargeStart(Event event, const char[] name, bool dontBroadcast)
{
	int charging = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidCharger(charging) && !IsFakeClient(charging))
	{
		isCharging[charging] = true;
		buttondelay[charging] = false;
	}
}

public Action OnChargerCarryStart(Event event, const char[] name, bool dontBroadcast)
{
	int carrying = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidCharger(carrying) && !IsFakeClient(carrying))
	{
		SetEntPropFloat(carrying, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
		SetEntPropFloat(carrying, Prop_Send, "m_flProgressBarDuration", ivWait);

		if (JumpTimer[carrying] != null)
		{
			delete(JumpTimer[carrying]);
			JumpTimer[carrying] = null;
		}
		JumpTimer[carrying] = CreateTimer(ivWait, CloseJumpHandle, carrying, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action OnChargerClear(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidCharger(attacker) && !IsFakeClient(attacker))
	{
		SetEntPropFloat(attacker, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
		SetEntPropFloat(attacker, Prop_Send, "m_flProgressBarDuration", 0.0);

		isCharging[attacker] = false;

		if (buttondelay[attacker])
		{
			buttondelay[attacker] = false;

			int target = GetClientOfUserId(GetEventInt(event, "victim"));
			if (IsValidClient(target) && GetClientTeam(target) == 2 && IsPlayerAlive(target) && !IsPlayerOnGround(target))
			{
				float power = GetConVarFloat(cvarInertiaVaultPower);

				float vec[3];
				vec[0] = GetEntPropFloat(target, Prop_Send, "m_vecVelocity[0]");
				vec[1] = GetEntPropFloat(target, Prop_Send, "m_vecVelocity[1]");
				vec[2] = GetEntPropFloat(target, Prop_Send, "m_vecVelocity[2]") + (power * 3);

				TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, vec);

				Handle releaseFix = CreateDataPack();
				WritePackCell(releaseFix, GetClientUserId(attacker));
				WritePackCell(releaseFix, GetClientUserId(target));
				CreateTimer(1.0, CheckForReleases, releaseFix, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT|TIMER_DATA_HNDL_CLOSE);
			}
		}
	}
}

public Action CheckForReleases(Handle timer, Handle releaseFix)
{
	ResetPack(releaseFix);

	int charger = GetClientOfUserId(ReadPackCell(releaseFix));
	int survivor = GetClientOfUserId(ReadPackCell(releaseFix));
	if (!IsValidCharger(charger) || IsFakeClient(charger) || !IsValidClient(survivor) || GetClientTeam(survivor) != 2 || IsPlayerAlive(survivor))
	{
		if (timerElapsed < 5)
		{
			timerElapsed += 1;
			return Plugin_Continue;
		}
		else
		{
			timerElapsed = 0;
			return Plugin_Stop;
		}
	}

	Event OnPlayerDeath = CreateEvent("player_death", true);
	SetEventInt(OnPlayerDeath, "userid", GetClientUserId(survivor));
	SetEventInt(OnPlayerDeath, "attacker", GetClientUserId(charger));
	FireEvent(OnPlayerDeath, false);

	return Plugin_Stop;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if ((buttons & IN_JUMP) && IsValidCharger(client) && !IsFakeClient(client) && isCharging[client])
	{
		if (isInertiaVault && buttondelay[client] && IsPlayerOnGround(client))
		{
			float power = GetConVarFloat(cvarInertiaVaultPower);

			float vec[3];
			vec[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
			vec[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
			vec[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]") + power;

			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
		}
	}
}

public Action CloseJumpHandle(Handle timer, any carrying)
{
	buttondelay[carrying] = true;
	PrintHintText(carrying, "You Can Jump Now!");
	JumpTimer[carrying] = null;

	return Plugin_Stop;
}

public void OnMapEnd()
{
	timerElapsed = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			isCharging[client] = false;
			buttondelay[client] = false;

			if (JumpTimer[client] != null)
			{
				delete(JumpTimer[client]);
				JumpTimer[client] = null;
			}
		}
	}
}

stock bool IsValidClient(int client)
{
	if (client <= 0 
	|| client > MaxClients
	|| !IsClientInGame(client))
		return false;
	return true;
}

stock bool IsPlayerOnGround(int client)
{
	if (GetEntProp(client, Prop_Send, "m_fFlags") & FL_ONGROUND) return true;
	return false;
}

stock bool IsValidCharger(int client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (class == ZOMBIECLASS_CHARGER) return true;
	}
	return false;
}
