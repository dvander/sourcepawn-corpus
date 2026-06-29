#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar hPluginEnabled;
bool bHooked = false;
int zClassTank = 5;

public Plugin myinfo =
{
	name = "l4d random tank",
	author = "gamemann(Rewritten by BloodyBlade)",
	description = "gives a tank random speed and health!",
	version = PLUGIN_VERSION,
	url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine == Engine_Left4Dead)
	{
		zClassTank = 5;
	}
	else if(engine == Engine_Left4Dead2)
	{
		zClassTank = 8;
	}
	else
	{
		strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" game series");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_random_tank_version", PLUGIN_VERSION, "l4d random tank plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	hPluginEnabled = CreateConVar("l4d_random_tank_enabled", "1", "Enable/Disable plugin", CVAR_FLAGS);
	AutoExecConfig(true, "l4d_random_tank");
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
		HookEvent("player_spawn", Event_Tank_Spawn);
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		UnhookEvent("player_spawn", Event_Tank_Spawn);
	}
}

Action Event_Tank_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int iTankId = GetClientOfUserId(event.GetInt("userid"));
	if(iTankId > 0 && IsClientInGame(iTankId) && GetClientTeam(iTankId) == 3 && IsPlayerAlive(iTankId) && GetEntProp(iTankId, Prop_Send, "m_zombieClass") == zClassTank)
	{
		SetEntityHealth(iTankId, GetRandomInt(1000, 10000));
		SetEntPropFloat(iTankId, Prop_Send, "m_flLaggedMovementValue", GetRandomFloat(1.0, 5.0));
	}
	PrintToChatAll("this server is running the plugin random tank so the tank has random speed or health!");
	return Plugin_Continue;
}
