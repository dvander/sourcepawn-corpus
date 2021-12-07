#include <sdktools>
#include <sdkhooks>

new Handle:cvarHealth;

new Float:Health;

public OnPluginStart()
{
	cvarHealth = CreateConVar("tf_health_multiplier", "1.0", "Number to multiply all maximum health values by.");
	
	HookConVarChange(cvarHealth, OnConVarChanged);
	
	Health = GetConVarFloat(cvarHealth);
	
	HookEvent("post_inventory_application", Event_Inventory, EventHookMode_Pre);
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client)) continue;
		OnClientPutInServer(client);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
}

public Action:OnGetMaxHealth(entity, &maxhealth)
{
	if (1.0 == Health) return Plugin_Continue;
	maxhealth = RoundFloat(maxhealth * Health);
	return Plugin_Changed;
}

public OnConVarChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (cvar == cvarHealth) Health = GetConVarFloat(cvarHealth);
}

public Action:Event_Inventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!Health) return;
	CreateTimer(0.1, Timer_SetHealth, GetEventInt(event, "userid"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_SetHealth(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!client) return;
	
	SetEntityHealth(client, GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client));
}