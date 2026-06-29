#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar hPluginEnabled;
bool bHooked = false;

public Plugin myinfo =
{
	name = "l4d2 witch spawned stuff",
	author = "gamemann(Rewritten by BloodyBlade)",
	description = "when a witch is spawned new stuff comes out",
	version = PLUGIN_VERSION,
	url = "sourcemod.net"
};

public void OnPluginStart()
{
	CreateConVar("l4d2_witch_spawned_stuff_version", PLUGIN_VERSION, "l4d2 witch spawned stuff plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	hPluginEnabled = CreateConVar("l4d2_witch_spawned_stuff_enabled", "1", "Enable/Disable plugin", CVAR_FLAGS);
	AutoExecConfig(true, "l4d2_witch_spawned_stuff");
	hPluginEnabled.AddChangeHook(OnConVarPluginOnChange);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarPluginOnChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bPluginOn = hPluginEnabled.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		HookEvent("witch_spawn", Event_Witch_Spawn);
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		UnhookEvent("witch_spawn", Event_Witch_Spawn);
	}
}

Action Event_Witch_Spawn(Event event, const char[] name, bool dontBroadcast)
{
    int iWitchId = event.GetInt("witchid");
    if(iWitchId > 0)
    {
        SetEntityHealth(iWitchId, GetRandomInt(1000, 10000));
        SetEntPropFloat(iWitchId, Prop_Send, "m_flLaggedMovementValue", GetRandomFloat(1.0, 5.0));
    }
    PrintToChatAll("this server run randomwitchrun so the health and sppeed is random!");
    return Plugin_Continue;
}
