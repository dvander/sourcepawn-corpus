#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define LAST_MAN_ON_EARTH
#define PLUGIN_VERSION "1.0"

new Handle:cvarBuffHP;
new Handle:cvarPillsHeal;
new Handle:cvarAdrenHeal;
new bool:isIncapped[MAXPLAYERS+1] = false;
new bool:isPillsHeal = false;
new bool:isAdrenHeal = false;
new BufferHP = -1;
new Revived = 0;

public Plugin:myinfo = 
{
	name = "[L4D2] Last Man On Earth",
	author = "Mortiegama",
	description = "Creates the Last Man On Earth Mutation.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	HookEvent("item_pickup", event_RoundStart);
	HookEvent("player_incapacitated", event_Incap);
	HookEvent("heal_success", event_HealSuccess);
	HookEvent("pills_used", event_PillsUsed);
	HookEvent("adrenaline_used", event_AdrenUsed);

	BufferHP = FindSendPropOffs("CTerrorPlayer","m_healthBuffer");
	Revived = FindSendPropOffs("CTerrorPlayer","m_currentReviveCount");

	cvarBuffHP = CreateConVar("sm_lastman_buffhp", "10", "Amount of bonus HP Survivor revives with (Def 10)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarPillsHeal = CreateConVar("sm_lastman_pillsheal", "1", "Amount of bonus HP Survivor revives with (Def 10)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarAdrenHeal = CreateConVar("sm_lastman_adrenheal", "1", "Amount of bonus HP Survivor revives with (Def 10)", FCVAR_PLUGIN, true, 0.0, false, _);

	if (cvarPillsHeal)
	{
		isPillsHeal = true;
	}

	if (cvarAdrenHeal)
	{
		isAdrenHeal = true;
	}
}

public event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (LeftStartArea())
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClient(client))
	{
		isIncapped[client] = false;
	}
	
	if (IsFakeClient(client))
		return;

	SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 1);
	SetConVarInt(FindConVar("z_background_limit"), 0);
	SetConVarInt(FindConVar("z_common_limit"), 0);
	SetConVarInt(FindConVar("z_ghost_delay_max"), 10);
	SetConVarInt(FindConVar("z_ghost_delay_min"), 15);

	CreateTimer(1.0, Timer_LastMan);
}

public Action:Timer_LastMan(Handle:timer)
{
    	for (new client=1; client<=MaxClients; client++)
	{
		if (IsValidClient(client) && IsFakeClient(client) && GetClientTeam(client) == 2)
		{
			KickClient(client,"Kick");
		}
	}
}  

public event_Incap(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (IsValidClient(client) && GetClientTeam(client) == 2 && !isIncapped[client])
	{
		isIncapped[client] = true;
		SetEntData(client, Revived, 1, 1);
		new flags3 = GetCommandFlags("give");
		SetCommandFlags("give", flags3 & ~FCVAR_CHEAT);
		FakeClientCommand(client,"give health");
		SetCommandFlags("give", flags3);
		SetEntityHealth(client, 1);
		new Float:sBuff = GetEntDataFloat(client, BufferHP);
		new sBuffHP = GetConVarInt(cvarBuffHP);
		SetEntDataFloat(client, BufferHP, sBuff + sBuffHP, true);
		SetCommandFlags("give", flags3|FCVAR_CHEAT);
	}

	else if (IsValidClient(client) && GetClientTeam(client) == 2 && isIncapped[client])
	{
		ForcePlayerSuicide(client);
	}
}

public event_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"subject"));

	if (IsValidClient(client) && GetClientTeam(client) == 2 && !isIncapped[client])
	{
		isIncapped[client] = false;
	}
}

public event_PillsUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"subject"));

	if (IsValidClient(client) && GetClientTeam(client) == 2 && isPillsHeal)
	{
		isIncapped[client] = false;
		new Float:sBuff = GetEntDataFloat(client, BufferHP);
		SetEntProp(client, Prop_Send, "m_iHealth", 80, 1);
		SetEntDataFloat(client, BufferHP, sBuff*0, true);
		SetEntData(client, Revived, 0, 1);

	}
}

public event_AdrenUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"subject"));

	if (IsValidClient(client) && GetClientTeam(client) == 2 && isAdrenHeal)
	{
		isIncapped[client] = false;
		new Float:sBuff = GetEntDataFloat(client, BufferHP);
		SetEntProp(client, Prop_Send, "m_iHealth", 80, 1);
		SetEntDataFloat(client, BufferHP, sBuff*0, true);
		SetEntData(client, Revived, 0, 1);
	}
}

bool:LeftStartArea()
{
	new ent = -1, maxents = GetMaxEntities();
	for (new i = MaxClients+1; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			decl String:netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			
			if (StrEqual(netclass, "CTerrorPlayerResource"))
			{
				ent = i;
				break;
			}
		}
	}
	
	if (ent > -1)
	{
		new offset = FindSendPropInfo("CTerrorPlayerResource", "m_hasAnySurvivorLeftSafeArea");
		if (offset > 0)
		{
			if (GetEntData(ent, offset))
			{
				if (GetEntData(ent, offset) == 1) return true;
			}
		}
	}
	return false;
}

public IsValidClient(client)
{
	if (client == 0)
		return false;

	if (!IsClientConnected(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (!IsPlayerAlive(client))
		return false;

	if (!IsValidEntity(client))
		return false;

	return true;
}