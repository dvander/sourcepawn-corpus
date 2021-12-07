#include <sourcemod>

new Handle:cvar_cheats = INVALID_HANDLE;
new Handle:cvar_enabled = INVALID_HANDLE;

public OnPluginStart()
{	
	cvar_cheats = FindConVar("sv_cheats");
	cvar_enabled = CreateConVar("sm_servercheats", "1", "Enable/Disable(1/0) plugin", FCVAR_PLUGIN|FCVAR_NOTIFY)
	HookConVarChange(cvar_enabled, ServerCheats);
}

public OnConfigsExecuted()
{
	if(cvar_enabled)
	{
		SetConVarFlags(cvar_cheats, FCVAR_NONE);
	}
}

public ServerCheats(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new newcheats = StringToInt(newValue);
	if(newcheats == 0)
	{
		SetConVarFlags(cvar_cheats, FCVAR_NOTIFY|FCVAR_REPLICATED);		
	}
	else
	{
		SetConVarFlags(cvar_cheats, FCVAR_NONE);
	}
}
