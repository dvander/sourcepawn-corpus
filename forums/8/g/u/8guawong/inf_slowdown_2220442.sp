#include <sourcemod>
#include <sdktools> 
#include <sdkhooks> 
#include <zombiereloaded>
public Plugin:myinfo =
{
	name = "'Inferno' weapons slowdown",
	author = "Jeremiah Jackson",
	description = "Makes zombies upset by slowing them down with fire.",
	version = "1.0.1",
	url = "http://www.burgerking.com/"
};

new Handle:g_Cvar_InfernoSpeed = INVALID_HANDLE;
new g_StaminaOffset = -1;
new Float:slowDown = 0.0;

public OnPluginStart(){ 
	g_Cvar_InfernoSpeed = CreateConVar("zr_inferno_slowdown", "40.0", "Amount of stamina-based slowdown to be applied on a player if he is hurt by inferno.", 0, true, 0.0, true, 100.0);

	g_StaminaOffset = FindSendPropInfo("CCSPlayer", "m_flStamina");
	if (g_StaminaOffset == -1)
	{	
		LogError("\"CCSPlayer::m_flStamina\" could not be found.");
		SetFailState("\"CCSPlayer::m_flStamina\" could not be found.");
	}

	// Set an initial value
	slowDown = GetConVarFloat(g_Cvar_InfernoSpeed);
	HookConVarChange(g_Cvar_InfernoSpeed, OnSpeedChanged);	

	// Late load
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public OnMapStart()
{ 
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

public OnSpeedChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	slowDown = StringToFloat(newVal);
}

public OnTakeDamagePost(client, attacker, entity, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3])
{
	// If the player isn't alive
	if(!IsPlayerAlive(client))
	{
		return;
	}

	// If the player hit isn't a zombie
	if(!ZR_IsClientZombie(client))
	{
		return;
	}
	
	new String:entityclass[128];
	GetEdictClassname(entity, entityclass, sizeof(entityclass));

	// If it isn't an inferno we leave and call the cops
	if (strcmp(entityclass, "inferno") != 0)
	{
		return;
	}

	// Apply the stamina-based slowdown
	SetEntDataFloat(client, g_StaminaOffset, slowDown, true);
}
