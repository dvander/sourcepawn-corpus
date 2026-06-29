#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION		"0.1.2"
//Plugin ConVars
new Handle:hCvarEnabled;
new Handle:hCvarEnabledForAll;


new bool:bCanShootTeammates[MAXPLAYERS];

new bool:bEnabled = true;
new bool:bEnabledForAll = false;

public Plugin:myinfo = 
{
	name = "FriendlyFire Manager",
	author = "Afronanny",
	description = "Manage FriendlyFire for specific people",
	version = PLUGIN_VERSION,
	url = "http://teamfail.net/"
}




public OnPluginStart()
{
	hCvarEnabledForAll = CreateConVar("sm_friendlyfire_enabledforall", "0", "Turn on friendly fire for everybody.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hCvarEnabled = FindConVar("mp_friendlyfire");
	
	RegAdminCmd("sm_toggleff", Command_ToggleFriendlyFire, ADMFLAG_SLAY, "Toggle Friendly Fire on a player or group of players");
	
	if (hCvarEnabled != INVALID_HANDLE)
		SetConVarBool(hCvarEnabled, true);
	
	HookConVarChange(hCvarEnabled, ConVarChanged_FriendlyFire);
	HookConVarChange(hCvarEnabledForAll, ConVarChanged_FriendlyFire);
	
	
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}


public OnPluginEnd()
{
	SetConVarBool(hCvarEnabled, false);
}
public Action:Command_ToggleFriendlyFire(client, args)
{
	if (bEnabled)
	{
		decl String:pattern[64],String:buffer[64];
		GetCmdArg(1,pattern,sizeof(pattern));
		new targets[64],bool:mb;
		new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
		for (new i = 0; i < count; i++)
		{
			if (IsClientInGame(targets[i]))
			{
				Toggle(bCanShootTeammates[targets[i]]);
				PrintToServer("%N shoot: %i", targets[i], bCanShootTeammates[targets[i]]);
			}
		}
	} else {
		ReplyToCommand(client, "[SM] FriendlyFire manager is disabled");
	}
	return Plugin_Handled;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (victim > 0 && victim <= MaxClients && attacker > 0 && attacker <= MaxClients && victim != attacker)
	{
		if (bEnabled)
		{
			if (GetClientTeam(victim) == GetClientTeam(attacker))
			{
				if (!bCanShootTeammates[attacker] && !bEnabledForAll)
				{
					damage = 0.0;
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}

public ConVarChanged_FriendlyFire(Handle:convar, const String:oldValue[], const String:newValue[])
{
	bEnabled = GetConVarBool(hCvarEnabled);
	bEnabledForAll = GetConVarBool(hCvarEnabledForAll);
}

stock Toggle(&bool:value)
{
	if (value)
	{
		value = false;
	} else {
		value = true;
	}
}
