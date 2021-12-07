#pragma semicolon 1

#if 0
#endif
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "[ND] Commander Restrictions",
	author = "Player 1",
	description = "Blocks players from applying for commander if they are not on the interval [Min,Max]",
	version = "1.0.1",
	url = "http://forums.alliedmods.net/showthread.php?p=1701970"
}

new cEnable;
new Float:cTimer;
new cTimerActive;
new cMinLvl;
new cMaxLvl;
new cMinPop;
// new cMaxPop;
new rank;
new spam = 0;

new Handle:g_Cvar_Enable = INVALID_HANDLE;
new Handle:g_Cvar_MinLvl = INVALID_HANDLE;
new Handle:g_Cvar_MaxLvl = INVALID_HANDLE;
new Handle:g_Cvar_MinPop = INVALID_HANDLE;
// new Handle:g_Cvar_MaxPop = INVALID_HANDLE;

public OnPluginStart()
{
	AddCommandListener(CommandListener:Command_Apply, "applyforcommander");

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

	g_Cvar_Enable = CreateConVar("sm_com_restrictions", "0", "Enables/Disables ND-Commander-Restrictions");
	g_Cvar_MinLvl = CreateConVar("sm_com_min_level", "1", "Minimum level allowed to apply for commander.");
	g_Cvar_MaxLvl = CreateConVar("sm_com_max_level", "60", "Maximum level allowed to apply for commander.");
	g_Cvar_MinPop = CreateConVar("sm_com_min_pop", "10", "Minimum number of players before restrictions are enforced.");
	// g_Cvar_MaxPop = CreateConVar("sm_com_max_pop", "32", "Maximum number of players before restrictions are enforced.");
	CreateConVar("sm_com_restrict_time", "60", "Number of seconds after round start remove restrictions. [0 == Never Remove]");

	HookConVarChange(Handle:g_Cvar_Enable, ConVarChanged:RefreshCvars);
	HookConVarChange(Handle:g_Cvar_MinLvl, ConVarChanged:RefreshCvars);
	HookConVarChange(Handle:g_Cvar_MaxLvl, ConVarChanged:RefreshCvars);
	HookConVarChange(Handle:g_Cvar_MinPop, ConVarChanged:RefreshCvars);
	// HookConVarChange(Handle:g_Cvar_MaxPop, ConVarChanged:RefreshCvars);

	cEnable = GetConVarInt(g_Cvar_Enable);
	cMinLvl = GetConVarInt(g_Cvar_MinLvl);
	cMaxLvl = GetConVarInt(g_Cvar_MaxLvl);
	cMinPop = GetConVarInt(g_Cvar_MinPop);
	// cMaxPop = GetConVarInt(g_Cvar_MaxPop);
}

public OnMapStart()
{
	cTimerActive = 1;
}

public RefreshCvars(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	cEnable = GetConVarInt(g_Cvar_Enable);
	cMinLvl = GetConVarInt(g_Cvar_MinLvl);
	cMaxLvl = GetConVarInt(g_Cvar_MaxLvl);
	cMinPop = GetConVarInt(g_Cvar_MinPop);
	// cMaxPop = GetConVarInt(g_Cvar_MaxPop);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	cTimer = (GetConVarFloat(FindConVar("sm_com_restrict_time")));
	if (cEnable == 1)
	{
		// if population threshold reached...
		if (cMinPop >= GetTotalNumPlayers()) {
			GameRules_SetProp("m_hCommanders", 0, 4, 0, true);
			GameRules_SetProp("m_hCommanders", 0, 4, 1, true);
			cTimerActive = 1;
			if (cTimer > 0)
			{
				CreateTimer(cTimer, Kill_Timer);
			}
		}
	}
}

public Action:Kill_Timer(Handle:timer)
{
	cTimerActive = 0;
	PrintToChatAll("[SM] Commander level restrictions lifted.");
	return Plugin_Stop;
}

public Action:Waiting(Handle:timer)
{
	spam = 0;
	return Plugin_Stop;
}

public Action:Command_Apply(client, const String:command[], argc)
{
	if ((cEnable == 1) && (cTimerActive == 1))
	{
		if (spam == 0)
		{
			rank = ND_GetPlayerRank(client);
			spam = 1;
			CreateTimer(1.5, Waiting);
			if (rank == 0)
			{
				PrintToChat(client, "[SM] Please spawn before applying for commander!");
				return Plugin_Handled;
			}
			else if (rank < cMinLvl)
			{
				PrintToChat(client, "[SM] Players below level %d may not apply for commander.",cMinLvl);
				return Plugin_Handled;
			}
			else if (rank > cMaxLvl)
			{
					PrintToChat(client, "[SM] Players above level %d may not apply for commander.",cMaxLvl);
					return Plugin_Handled;
			}
			else
			{
				return Plugin_Continue;
			}
		}
		else
		{
			return Plugin_Handled;
		}
	}
	else
	{
		return Plugin_Continue;
	}
}

stock ND_GetPlayerRank(client)
{
	new ent = GetCNDPlayerResource();

	if (ent != INVALID_ENT_REFERENCE)
	{
		new offset = FindSendPropInfo("CNDPlayerResource", "m_iPlayerRank");
		if (offset > 0)
		{
			return GetEntData(ent, offset + client * 4);
		}
	}

	return 0;
}

stock GetCNDPlayerResource()
{
	static ref = INVALID_ENT_REFERENCE;

	new ent = INVALID_ENT_REFERENCE;

	for (new i = 0; i < 2 && ent == INVALID_ENT_REFERENCE; i++)
	{
		if (ref == INVALID_ENT_REFERENCE)
		{
			ent = FindEntityByNetClass("CNDPlayerResource");
			ref = EntIndexToEntRef(ent);
		}
		else
		{
			ent = EntRefToEntIndex(ref);
		}
	}

	return ent;
}

stock FindEntityByNetClass(const String:netclass[])
{
	new ent = INVALID_ENT_REFERENCE,
		maxEnts = GetMaxEntities();

	for (new i = MaxClients + 1; i <= maxEnts; i++)
	{
		if (!IsValidEntity(i))
		{
			continue;
		}

		new len = strlen(netclass) + 2;
		decl String:_netclass[len];
		GetEntityNetClass(i, _netclass, len);

		if (strcmp(_netclass, netclass) == 0)
		{
			ent = i;
			break;
		}
	}

	return ent;
}

stock GetTotalNumPlayers()
{
	new iCount = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsFakeClient(i)) // IsClientInGame(i) && IsPlayerAlive(i))
		{
			iCount++;
		}
	}

	return iCount;
}

