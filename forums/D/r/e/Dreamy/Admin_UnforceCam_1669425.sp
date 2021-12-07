#pragma semicolon 1
#include <sourcemod>

public OnPluginStart()
{
	HookEvent("player_death", Event_Death);
	
	AddCommandListener(cmd_next, "spec_next");
	AddCommandListener(cmd_prev, "spec_prev");
	AddCommandListener(cmd_mode, "spec_mode");
	AddCommandListener(cmd_player, "spec_player");
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsClientValid(client) && (GetUserAdmin(client) == INVALID_ADMIN_ID))
		SpecNext(client, GetEntPropEnt(client, Prop_Send, "m_hObserverTarget"));

	return Plugin_Handled;
}

public Action:cmd_next(client, const String:command[], args)
{
	if (IsClientValid(client) && (GetUserAdmin(client) == INVALID_ADMIN_ID))
		SpecNext(client, GetEntPropEnt(client, Prop_Send, "m_hObserverTarget"));
	else
		return Plugin_Continue;	
	
	return Plugin_Handled;
}

public Action:cmd_prev(client, const String:command[], args)
{
	if (IsClientValid(client) && (GetUserAdmin(client) == INVALID_ADMIN_ID))
		SpecPrev(client, GetEntPropEnt(client, Prop_Send, "m_hObserverTarget"));
	else
		return Plugin_Continue;
		
	return Plugin_Handled;
}

public Action:cmd_mode(client, const String:command[], args)
{
	if (!IsClientValid(client) || (GetUserAdmin(client) == INVALID_ADMIN_ID))
		return Plugin_Handled;
	else
		return Plugin_Continue;
}

public Action:cmd_player(client, const String:command[], args)
{	
	if (!IsClientValid(client))
		return Plugin_Handled;
		
	if (!args || (GetUserAdmin(client) != INVALID_ADMIN_ID))
		return Plugin_Continue;
	
	decl String:arg[128];
	GetCmdArg(1, arg, sizeof(arg));
	if (arg[0]!='\0')
	{
		decl String:target_name[MAX_TARGET_LENGTH];
		new target_list[MaxClients];
		new bool:tn_is_ml;
		
		if (!ProcessTargetString(
				arg, 0, target_list, 
				MaxClients, 
				COMMAND_FILTER_ALIVE, 
				target_name, sizeof(target_name), 
				tn_is_ml))
		{
			return Plugin_Handled;
		}
		
		if (GetClientTeam(client) == GetClientTeamEx(target_list[0]))
			return Plugin_Continue;
	}
	return Plugin_Handled;
}

stock SpecNext(client, current)
{
	new team = GetClientTeam(client);
	for (new i = current+1; i != current; i++)
	{	
		if (team == GetClientTeamEx(i))
		{
			SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", i);
			return;
		}
		if (i == MaxClients)
			i = 1;
	}
}

stock SpecPrev(client, current)
{
	new team = GetClientTeam(client);
	for (new i = current-1; i != current; i--)
	{
		if (team == GetClientTeamEx(i))
		{
			SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", i);
			return;
		}
		if (i == 1)
			i = MaxClients;
	}
}

GetClientTeamEx(client)
{
	return (!client || !IsClientInGame(client) || !IsPlayerAlive(client)) ? -1:GetClientTeam(client);
}

bool:IsClientValid(client)
{
	return (!client || !IsClientInGame(client) || IsPlayerAlive(client) || IsFakeClient(client)) ? false:true;
}