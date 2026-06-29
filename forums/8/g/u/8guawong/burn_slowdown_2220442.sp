#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

enum ButtonState
{
	Pressed,
	Released,
};

new Handle:g_ConVar_Penalty_Hndl = INVALID_HANDLE;
new Handle:g_ConVar_NapalmOnly_Hndl = INVALID_HANDLE;
new Float:g_Penalty = 0.0;
new bool:g_NapalmOnly = true;

new g_StaminaOffset = -1;
new ButtonState:g_JumpButtonState[MAXPLAYERS + 1] = {Released, ...};

public Plugin:myinfo =
{
	name = "Burn Speed Penalty",
	author = "Lickaroo Johnson McPhaley",
	description = "Applies a stamina-based speed penalty when burned so ignited players get a slowdown like in older Source titles.",
	version = "1.33333333333333",
	url = "http://www.wigs4sale.net/"
};

public OnPluginStart()
{
	g_StaminaOffset = FindSendPropInfo("CCSPlayer", "m_flStamina");
	if (g_StaminaOffset == -1)
	{	
		LogError("\"CCSPlayer::m_flStamina\" could not be found.");
		SetFailState("\"CCSPlayer::m_flStamina\" could not be found.");
	}
	
	g_ConVar_Penalty_Hndl = CreateConVar("sm_stamina_burncost", "25.0", "Stamina penalty applied when burned", 0, true, 0.0, true, 100.0);
	g_Penalty = GetConVarFloat(g_ConVar_Penalty_Hndl);
	HookConVarChange(g_ConVar_Penalty_Hndl, OnPenaltyChanged);
	
	g_ConVar_NapalmOnly_Hndl = CreateConVar("sm_napalmonly", "1", "Stamina penalty will only be applied to napalm grenades", 0, true, 0.0, true, 1.0);
	g_NapalmOnly = GetConVarBool(g_ConVar_Penalty_Hndl);
	HookConVarChange(g_ConVar_NapalmOnly_Hndl, OnNapalmOnlyChanged);
	
	// Late load
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public OnPenaltyChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_Penalty = StringToFloat(newVal);
}

public OnNapalmOnlyChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_NapalmOnly = bool:StringToInt(newVal);
}


public OnTakeDamagePost(client, attacker, inflictor, Float:damage, damagetype)
{
	if (!(damagetype & DMG_BURN))
	{
		return;
	}

	if (attacker >= 1 && attacker <= MaxClients)
	{
		if (g_NapalmOnly == true)
		{
			return;
		}
	}
	
	if (!IsClientOnObject(client))
	{	
		return;
	}
	
	
	SetEntDataFloat(client, g_StaminaOffset, g_Penalty, true);
	return;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!IsClientOnObject(client))
	{
		return Plugin_Continue;
	}
	
	if (!(buttons & IN_JUMP))
	{
		// Player is not holding down space bar (+jump)
		g_JumpButtonState[client] = Released;
		
		return Plugin_Continue;
	}
	
	// Player is holding down the space bar (+jump)
	
	if (g_JumpButtonState[client] == Pressed)
	{
		// Client is holding down +jump before we land
		return Plugin_Continue;
	}
	
	g_JumpButtonState[client] = Pressed;
	SetEntDataFloat(client, g_StaminaOffset, 0.0, true);
	
	return Plugin_Continue;
}

/**
 * Return whether a client is standing on an object
 *
 * @param		Client index
 * @return		True if client is standing on an object. False otherwise.
 */
bool:IsClientOnObject(client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") > -1 ? true : false;
}
