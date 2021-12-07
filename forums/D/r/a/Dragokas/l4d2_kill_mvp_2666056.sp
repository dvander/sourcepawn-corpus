//new Float:NULL_VECTOR[3];
//new String:NULL_STRING[4];

new killif[MAXPLAYERS+1];
new killifs[MAXPLAYERS+1];
new damageff[MAXPLAYERS+1];
new pdamageff[MAXPLAYERS+1];
new Handle:hCountMvpDelay;
new Float:CountMvpDelay;
new IF;

public Plugin:myinfo =
{
	name = "Special kill ranking",
	description = "Special kill ranking by night",
	author = "fenghf (rebuild by Dragokas)",
	version = "1.1",
	url = ""
};

public OnPluginStart()
{
	RegConsoleCmd("sm_mvp", Command_kill, "");
	HookEvent("player_death", MVPEvent_kill_infected, EventHookMode_Post);
	HookEvent("player_hurt", MVPEvent_PlayerHurt, EventHookMode_Post);
	HookEvent("infected_death", MVPEvent_kill_SS, EventHookMode_Post);
	HookEvent("map_transition", MVPEvent_MapTransition, EventHookMode_PostNoCopy);
	HookEvent("round_end", MVPEvent_MapTransition, EventHookMode_PostNoCopy);
	HookEvent("round_start", MVPEvent_RoundStart, EventHookMode_PostNoCopy);
	CreateConVar("L4D2_kill_mvp_Version", "L4D2 Special kill ranking v1.1 - by night", "L4D2 Special kill ranking v1.1 - by night", 8512, false, 0.0, false, 0.0);
	hCountMvpDelay = CreateConVar("kill_mvp_display_delay", "120", "How long to kill the ranking (seconds).", 0, true, 10.0, true, 9999.0);
	CountMvpDelay = GetConVarFloat(hCountMvpDelay);
	HookConVarChange(hCountMvpDelay, ConVarMvpDelays);
	AutoExecConfig(true, "l4d2_kill_mvp", "sourcemod");
	IF = FindSendPropInfo("CTerrorPlayer", "m_zombieClass");
}

public ConVarMvpDelays(Handle:convar, String:oldValue[], String:newValue[])
{
	CountMvpDelay = GetConVarFloat(hCountMvpDelay);
}

public OnMapStart()
{
	CountMvpDelay = GetConVarFloat(hCountMvpDelay);
	kill_infected();
	CreateTimer(CountMvpDelay, killinfected_dis, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public MVPEvent_PlayerHurt(Handle:event, String:name[], bool:dontBroadcast)
{
	new victimId = GetEventInt(event, "userid", 0);
	new victim = GetClientOfUserId(victimId);
	new attackerId = GetEventInt(event, "attacker", 0);
	new attackersid = GetClientOfUserId(attackerId);
	new damageDone = GetEventInt(event, "dmg_health", 0);
	if (IsClientAndInGame(attackersid) && IsClientAndInGame(victim) && GetClientTeam(attackersid) == 2 && GetClientTeam(victim) == 2)
	{
		damageff[attackersid] += damageDone;
		pdamageff[victim] = attackersid;
	}
}

bool:IsClientAndInGame(index)
{
	return index > 0 && index <= MaxClients && IsClientInGame(index);
}

public Action:MVPEvent_kill_SS(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!killer)
	{
		return Plugin_Continue;
	}
	if (GetClientTeam(killer) == 2)
	{
		killifs[killer] += 1;
	}
	return Plugin_Continue;
}

public Action:MVPEvent_kill_infected(Handle:event, String:name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	new deadbody = GetClientOfUserId(GetEventInt(event, "userid"));
	if (0 < killer <= MaxClients && deadbody)
	{
		new ZClass = GetEntData(deadbody, IF, 4);
		if (GetClientTeam(killer) == 2)
		{
			if (ZClass == 1 || ZClass == 2 || ZClass == 3 || ZClass == 4 || ZClass == 5 || ZClass == 6)
			{
				killif[killer] += 1;
			}
			if (IsPlayerTank(deadbody))
			{
				killif[killer] += 1;
			}
		}
	}
	return Plugin_Continue;
}

bool:IsPlayerTank(client)
{
	if (GetEntProp(client, Prop_Send, "m_zombieClass", 4) == 8)
	{
		return true;
	}
	return false;
}

public MVPEvent_MapTransition(Handle:event, String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, killinfected_dis);
}

public Action:killinfected_dis(Handle:timer)
{
	displaykillinfected();
}

public MVPEvent_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	kill_infected();
}

public Action:Command_kill(client, args)
{
	displaykillinfected();
	return Plugin_Handled;
}

displaykillinfected()
{
	new players = -1;
	new players_clients[24];
	decl killss;
	decl killsss;
	decl damageffss;
	//decl pdamageffss;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2) {
			players++;
			players_clients[players] = i;
			/*
			killss = killif[i];
			killsss = killifs[i];
			damageffss = damageff[i];
			pdamageffss = pdamageff[i];
			*/
		}
	}

	new client, i;
	PrintToChatAll("\x04[MVP]\x03 Kill ranking - by night");
	SortCustom1D(players_clients, 24, SortByDamageDesc);
	while (i <= 3)
	{
		client = players_clients[i];
		killss = killif[client];
		killsss = killifs[client];
		damageffss = damageff[client];
		PrintToChatAll("\x01%d: \x04%3d  \x03Special,\x04%4i  \x03Zombie,\x04%5d  \x03FF; \x05%N", i + 1, killss, killsss, damageffss, client);
		i++;
	}
	
	SortCustom1D(players_clients, 24, SortByDamageDesc2);
	client = players_clients[0];
	damageffss = killif[client] + killifs[client];
	PrintToChatAll("\x01<Most damage> \x03 -> \x04%i  \x05%N", damageffss, client);
	
	SortCustom1D(players_clients, 24, SortByffDamageDesc);
	damageffss = damageff[players_clients[0]];
	PrintToChatAll("\x01<Most FF> \x03 -> \x04%i  \x05%N", damageffss, players_clients[0]);
	
}

public SortByDamageDesc2(elem1, elem2, array[], Handle:hndl)
{
	return ((killif[elem2] + killifs[elem2]) < (killif[elem1] + killifs[elem1])) ? -1 : 1;
}

public SortByDamageDesc(elem1, elem2, array[], Handle:hndl)
{
	if (killif[elem2] < killif[elem1])
	{
		return -1;
	}
	if (killif[elem1] < killif[elem2])
	{
		return 1;
	}
	if (elem1 > elem2)
	{
		return -1;
	}
	if (elem2 > elem1)
	{
		return 1;
	}
	return 0;
}

public SortByffDamageDesc(elem1, elem2, array[], Handle:hndl)
{
	if (damageff[elem2] < damageff[elem1])
	{
		return -1;
	}
	if (damageff[elem1] < damageff[elem2])
	{
		return 1;
	}
	if (elem1 > elem2)
	{
		return -1;
	}
	if (elem2 > elem1)
	{
		return 1;
	}
	return 0;
}

/*
public SortByPffDamageDesc(elem1, elem2, array[], Handle:hndl)
{
	if (pdamageff[elem2] < pdamageff[elem1])
	{
		return -1;
	}
	if (pdamageff[elem1] < pdamageff[elem2])
	{
		return 1;
	}
	if (elem1 > elem2)
	{
		return -1;
	}
	if (elem2 > elem1)
	{
		return 1;
	}
	return 0;
}
*/

kill_infected()
{
	new i = 1;
	while (i <= MaxClients)
	{
		killif[i] = 0;
		killifs[i] = 0;
		damageff[i] = 0;
		pdamageff[i] = 0;
		i++;
	}
}

