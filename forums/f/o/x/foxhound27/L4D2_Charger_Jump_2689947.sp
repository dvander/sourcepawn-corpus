#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

#define L4D2 Charger Jump
#define PLUGIN_VERSION "1.11"

#define ZOMBIECLASS_CHARGER 						6

Handle cvarInertiaVault;
Handle cvarInertiaVaultPower;

Handle PluginStartTimer = INVALID_HANDLE;
Handle cvarResetDelayTimer[MAXPLAYERS+1] = INVALID_HANDLE;

bool isCharging[MAXPLAYERS+1] = false;
bool buttondelay[MAXPLAYERS+1] = false;
bool isInertiaVault = false;


public Plugin myinfo = 
{
    name = "[L4D2] Charger Jump",
    author = "Mortiegama",
    description = "Allows the Charger to jump while Charging.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2116076#post2116076"
};

public void OnPluginStart()
{
	CreateConVar("l4d_cjm_version", PLUGIN_VERSION, "Charger Jump Version", 0|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cvarInertiaVault = CreateConVar("l4d_cjm_inertiavault", "1", "Enables the ability Inertia Vault, allows the Charger to jump while charging. (Def 1)", 0, true, 0.0, false, _);
	cvarInertiaVaultPower = CreateConVar("l4d_cjm_inertiavaultpower", "400.0", "Power behind the Charger's jump. (Def 400.0)", 0, true, 0.0, false, _);

	HookEvent("charger_charge_start", Event_ChargeStart);
	HookEvent("charger_charge_end", Event_ChargeEnd);	
	
	AutoExecConfig(true, "plugin.L4D2.ChargerJump");
	PluginStartTimer = CreateTimer(3.0, OnPluginStart_Delayed);
}

public Action OnPluginStart_Delayed(Handle timer)
{	
	if (GetConVarInt(cvarInertiaVault))
	{
		isInertiaVault = true;
	}
	
	if(PluginStartTimer != INVALID_HANDLE)
	{
 		KillTimer(PluginStartTimer);
		PluginStartTimer = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}

public Action Event_ChargeStart (Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(client))
	{
		isCharging[client] = true;
	}
}

public Action Event_ChargeEnd (Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(client))
	{
		isCharging[client] = false;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (buttons & IN_JUMP && IsValidCharger(client) && isCharging[client])
	{
		if (isInertiaVault && !buttondelay[client] && IsPlayerOnGround(client))
		{
			buttondelay[client] = true;
			float vec[3];
			float power = GetConVarFloat(cvarInertiaVaultPower);
			vec[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
			vec[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
			vec[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]") + power;
			
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
			cvarResetDelayTimer[client] = CreateTimer(1.0, ResetDelay, client);
		}
	}
}

public Action ResetDelay(Handle timer, any client)
{
	buttondelay[client] = false;
	
	if (cvarResetDelayTimer[client] != INVALID_HANDLE)
	{
		KillTimer(cvarResetDelayTimer[client]);
		cvarResetDelayTimer[client] = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}

public void OnMapEnd()
{
    for (int client=1; client<=MaxClients; client++)
	{
	if (IsValidClient(client))
		{
			isCharging[client] = false;
		}
	}
}

public bool IsValidClient(int client)
{
	if (client <= 0)
		return false;
		
	if (client > MaxClients)
		return false;
		
	if (!IsClientInGame(client))
		return false;
		
	if (!IsPlayerAlive(client))
		return false;

	return true;
}

public bool IsPlayerOnGround(int client)
{
	if (GetEntProp(client, Prop_Send, "m_fFlags") & FL_ONGROUND) return true;
		else return false;
}

public bool IsValidCharger(int client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		
		if (class == ZOMBIECLASS_CHARGER)
			return true;
		
		return false;
	}
	
	return false;
}