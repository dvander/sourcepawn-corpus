#include <sourcemod>
#include <timer>
#include <morecolors>

#pragma semicolon 1


public Plugin:myinfo = 
{
	name = "[Timer] Spec Best",
	author = "Ofir",
	description = "",
	version = "1.0",
	url = ""
}

new String:g_sCurrentMap[MAX_MAPNAME_LENGTH];

public OnPluginStart()
{
	LoadTranslations("timer-specbest.phrases");
	RegConsoleCmd("sm_specbest", Cmd_SpecBest);
	RegConsoleCmd("sm_specmost", Cmd_SpecMost);
	RegConsoleCmd("sm_spec", Cmd_Spec, "Move player to spectators.");
}

public OnMapStart() 
{
	GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
	StringToLower(g_sCurrentMap);
}

public Action:Cmd_Spec(client, args)
{
	ChangeClientTeam(client, 1);
	new target;
	
	if(args > 0)
	{
		new String:arg1[MAX_TARGET_LENGTH];
		GetCmdArg(1, arg1, MAX_TARGET_LENGTH);

		target = FindTarget(client, arg1, false, false);
	}
	
	if(target == -1)
	{
		return Plugin_Handled;
	}

	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", target);

	return Plugin_Handled;
}

public Action:Cmd_SpecBest(client, args)
{
	new target;
	new Float:Best = 10000000.0, Float:Current, jumps, fpsmax, flashbangs;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(i == client)
			continue;
		
		if(IsValidClient(i, true))
		{
			Timer_GetBestRecord(i, g_sCurrentMap, 1, Current, jumps, fpsmax, flashbangs);
			
			if(Current < Best && Current != 0.0) 
			{
				Best = Current;
				target = i;
			}
		}
	}

	if(Best == 10000000.0)
	{
		CPrintToChat(client, PLUGIN_PREFIX, "No One Finished the map");

		return Plugin_Handled;
	}

	ChangeClientTeam(client, 1);
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", target);

	return Plugin_Handled;
}

public Action:Cmd_SpecMost(client, args)
{
	new MostSpectators = 0, Spectators = 0, target;

	for(new i = 1; i <= MaxClients; i++)
	{
		if(i == client)
			continue;
		Spectators = 0;		
		if(IsValidClient(i, true))
		{
			for(new x = 1; x <= MaxClients; x++)
			{
				if(!IsClientInGame(x) || !IsClientObserver(x))
				{
					continue;
				}
					
				new SpecMode = GetEntProp(x, Prop_Send, "m_iObserverMode");
				
				if(SpecMode == 4 || SpecMode == 5)
				{
					if(GetEntPropEnt(x, Prop_Send, "m_hObserverTarget") == target)
					{
						Spectators++;
					}
				}
			}
			if(Spectators > MostSpectators)
				target = i;
		}
	}

	ChangeClientTeam(client, 1);
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", target);

	return Plugin_Handled;
}

stock bool:IsValidClient(client, bool:alive = false)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (!alive || IsPlayerAlive(client)))
	{
		return true;
	}
	
	return false;
}