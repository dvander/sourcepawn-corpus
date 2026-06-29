#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_hooks>

#pragma semicolon 1

new Handle:CvarPluginEnabled;
new bool:PluginEnabled;

public Plugin:myinfo =
{
    name = "BunnyHop Enhancement",
    author = "Requi",
    description = "SourceMod plugin that enhances bunnyhopping.",
    version = "1.0.0",
    url = "http://www.requi-dev.de"
}

public OnPluginStart()
{
	CvarPluginEnabled = CreateConVar("sm_bhop_enabled", "1", "Sets whether BunnyHop is enabled", FCVAR_NOTIFY);
    HookConVarChange(CvarPluginEnabled, OnPluginEnabledChange);
	
	AutoExecConfig(true, "sm_bhop");
	PluginEnabled = GetConVarBool(CvarPluginEnabled);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if(PluginEnabled && !IsFakeClient(client))
	{
		if(GetEntityMoveType(client) != MOVETYPE_LADDER)
		{
			if((buttons & IN_JUMP) && !(GetEntityFlags(client) & FL_ONGROUND))
			{
				buttons &= ~IN_JUMP;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public OnPluginEnabledChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
    PluginEnabled = GetConVarBool(cvar);
}