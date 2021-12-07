#pragma semicolon 1

#include <sourcemod>

#define 		PLUGIN_VERSION 						"0.91"
const 	Float:	RESETTIMER							= 1.0;
new 	bool:	bEnabled 							= true;
new 	bool:	bProhibitClientCmds[MAXPLAYERS+1]	= {false};
new 	Handle:	hEnableCvar;

public Plugin:myinfo = 
{
	name = "Charge Control",
	author = "Mr. Zero",
	description = "Prevents the charger from having control between chargering and pounding animation.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=118642"
}

public OnPluginStart()
{
	hEnableCvar = CreateConVar("l4d2_chargecontrol_enabled","1","Sets whether chargers have control between the chargering and pounding animation.",FCVAR_PLUGIN);
	CreateConVar("l4d2_chargecontrol_version", PLUGIN_VERSION, "Charge Control Version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookConVarChange(hEnableCvar,ConVarChange);
	HookEvent("charger_carry_end",Charger_LimitControl_Event);
	HookEvent("charger_charge_end",Charger_LimitControl_Event);
	HookEvent("charger_pummel_start",Charger_ResetControl_Event);
	HookEvent("charger_killed",Charger_ResetControl_Event);
}

public Charger_LimitControl_Event(Handle:event, const String:name[], bool:dB)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	bProhibitClientCmds[client] = true;
	CreateTimer(RESETTIMER,Charger_ResetControl_Timer,client);
}

public Charger_ResetControl_Event(Handle:event, const String:name[], bool:dB)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	bProhibitClientCmds[client] = false;
}

public Action:Charger_ResetControl_Timer(Handle:timer,any:client)
{
	bProhibitClientCmds[client] = false;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(!bEnabled || !bProhibitClientCmds[client] || (!(buttons & IN_ATTACK2) && !(buttons & IN_JUMP)))
	{
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	bEnabled = GetConVarBool(hEnableCvar);
}