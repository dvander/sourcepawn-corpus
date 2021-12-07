#include <sdkhooks>

new bool:protect;
new bool:cvar_enabled;

public OnPluginStart()
{
	new Handle:cvar = CreateConVar("round_end_protect", "1", "No killing after round end", FCVAR_NONE, true, 0.0, true, 1.0);
	cvar_enabled = GetConVarBool(cvar);
	HookConVarChange(cvar, cvar_change);
	CloseHandle(cvar);

	HookEventEx("round_end",		rounds);
	HookEventEx("round_start",		rounds);

	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public cvar_change(Handle:convar, const String:oldValue[], const String:newValue[])
{
	cvar_enabled = StringToInt(newValue) != 0;

	if(!cvar_enabled)
	{
		protect = false;
	}
}

public rounds(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!cvar_enabled)
	{
		protect = false;
		return;
	}

	if(StrEqual(name, "round_end"))
	{
		protect = true;
	}
	else // "round_start"
	{
		protect = false;
	}
}

public OnClientPutInServer(client)
{
	SDKHookEx(client, SDKHook_OnTakeDamage, damage);
}

public Action:damage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if( protect && 0 < attacker <= MaxClients )
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}