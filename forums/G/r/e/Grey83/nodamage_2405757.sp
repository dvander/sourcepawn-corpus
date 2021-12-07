#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION	"1.1 (fixed by Grey83)"
#define PLUGIN_NAME		"NoDamage"

new bool:bLateLoad = false;
new Handle:hEnabled, bool:bEnabled;

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "Thomas Ross",
	description = "Stops damage from being taken",
	version = PLUGIN_VERSION,
	url = ""
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	bLateLoad = late;
}

public OnPluginStart()
{
	CreateConVar("sm_nodamage_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hEnabled = CreateConVar("sm_nodamage_enabled", "1", "1 = Plugin enabled, 0 = Disabled", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);

	HookConVarChange(hEnabled, OnSettingsChange);
	bEnabled = GetConVarBool(hEnabled);

	if (bLateLoad && bEnabled) LookUp1();
}

public OnSettingsChange(Handle:hCVar, const String:sOldValue[], const String:sNewValue[])
{
	if (hCVar == hEnabled) bEnabled = bool:StringToInt(sNewValue);
	if (bEnabled) LookUp1();
	else LookUp0();
}

LookUp0()
{
	for(new client; client <= MaxClients; client++)
	{
		OnClientDisconnect(client)
	}
}

LookUp1()
{
	for(new client; client <= MaxClients; client++)
	{
		OnClientPostAdminCheck(client)
	}
}

public OnClientPostAdminCheck(client)
{
	if(0 < client <= MaxClients && IsClientInGame(client))
		SDKHook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
}

 public OnClientDisconnect(client)
{
	if(0 < client <= MaxClients)
		SDKUnhook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
}

public Action:Event_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) 
{ 
	damage = 0.0; 
	return Plugin_Handled; 
}