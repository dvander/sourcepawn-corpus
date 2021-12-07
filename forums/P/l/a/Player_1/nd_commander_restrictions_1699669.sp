#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define NAME "[ND] Commander Restrictions"
#define VERSION "1.3"

public Plugin:myinfo =
{
	name = NAME,
	author = "Player 1",
	description = "Blocks players from applying for commander if they are not on the interval [Min,Max]",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1701970"
}

new bool:g_bEnabled,
	bool:g_bActive,
	g_iMinLevel,
	g_iMaxLevel,
	g_iMinPop,
	
	g_iRankOffset,
	g_iPlayerManager,

	Handle:g_Cvar_Enable = INVALID_HANDLE,
	Handle:g_Cvar_MinLvl = INVALID_HANDLE,
	Handle:g_Cvar_MaxLvl = INVALID_HANDLE,
	Handle:g_Cvar_MinPop = INVALID_HANDLE,
	Handle:g_Cvar_Timer = INVALID_HANDLE,
	Handle:g_hTimerHandle = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("sm_nd_com_restrictions_version", VERSION, NAME, FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	RegConsoleCmd("applyforcommander", Command_Apply);

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_win", Event_RoundWin, EventHookMode_PostNoCopy);

	g_Cvar_Enable = CreateConVar("sm_com_restrictions", "0", "Enables/Disables ND-Commander-Restrictions", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_MinLvl = CreateConVar("sm_com_min_level", "1", "Minimum level allowed to apply for commander.", FCVAR_NONE, true, 1.0, true, 80.0);
	g_Cvar_MaxLvl = CreateConVar("sm_com_max_level", "80", "Maximum level allowed to apply for commander.", FCVAR_NONE, true, 1.0, true, 80.0);
	g_Cvar_MinPop = CreateConVar("sm_com_min_pop", "10", "Minimum number of players before restrictions are enforced.", FCVAR_NONE, true, 0.0, false);
	g_Cvar_Timer = CreateConVar("sm_com_restrict_time", "60", "Number of seconds after round start remove restrictions. [0 == Never Remove]", FCVAR_NONE, true, 0.0, false);

	HookConVarChange(g_Cvar_Enable, ConVarChanged:RefreshCvars);
	HookConVarChange(g_Cvar_MinLvl, ConVarChanged:RefreshCvars);
	HookConVarChange(g_Cvar_MaxLvl, ConVarChanged:RefreshCvars);
	HookConVarChange(g_Cvar_Timer, ConVarChanged:RefreshCvars);

	g_bEnabled = GetConVarBool(g_Cvar_Enable);
	g_iMinLevel = GetConVarInt(g_Cvar_MinLvl);
	g_iMaxLevel = GetConVarInt(g_Cvar_MaxLvl);
	g_iMinPop = GetConVarInt(g_Cvar_MinPop);
	
	g_iRankOffset = FindSendPropInfo("CNDPlayerResource", "m_iPlayerRank");
}

public OnMapStart() 
{
	g_iPlayerManager = FindEntityByClassname(-1, "nd_player_manager");
	g_bActive = true;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bEnabled)
	{
		if (GetTotalNumPlayers() >= g_iMinPop)
		{
			new Float:cTimer = GetConVarFloat(g_Cvar_Timer);
			
			g_bActive = true;
			
			if (cTimer > 0)
				g_hTimerHandle = CreateTimer(Float:cTimer, End_Restrictions);
		}
		else 
			g_bActive = false;
	}
}

public Action:End_Restrictions(Handle:timer)
{
	g_bActive = false;
	PrintToChatAll("[SM] Commander level restrictions lifted.");
	g_hTimerHandle = INVALID_HANDLE;
}

public Action:Command_Apply(client, args)
{
	if (!client)
		return Plugin_Handled;
	
	if (g_bEnabled && g_bActive)
	{
		new rank = GetEntData(g_iPlayerManager, g_iRankOffset + 4*client);
		
		if (rank == 0)
			PrintToChat(client, "\x05[SM] Please spawn before applying for commander!");

		else if (rank < g_iMinLevel)
			PrintToChat(client, "\x05[SM] Players below level %d may not apply for commander.",g_iMinLevel);

		else if (rank > g_iMaxLevel)
			PrintToChat(client, "\x05[SM] Players above level %d may not apply for commander.",g_iMaxLevel);
		
		else
			return Plugin_Continue;
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}


GetTotalNumPlayers()
{
	new iCount = 0;
	
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientConnected(i) && !IsFakeClient(i))
			iCount++;
			
	return iCount;
}

public RefreshCvars(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == g_Cvar_Enable)
		g_bEnabled = GetConVarBool(g_Cvar_Enable);
	
	else if (cvar == g_Cvar_MinLvl)
		g_iMinLevel = GetConVarInt(g_Cvar_MinLvl);
	
	else if (cvar == g_Cvar_MaxLvl)
		g_iMaxLevel = GetConVarInt(g_Cvar_MaxLvl);
	
	else if (cvar == g_Cvar_MinPop)
		g_iMinPop = GetConVarInt(g_Cvar_MinPop);
}

public Action:Event_RoundWin(Handle:event, const String:name[], bool:DontBroadcast)
{
	CheckTimer();
}

public OnMapEnd()
{
	CheckTimer();
}

CheckTimer()
{
	if (g_hTimerHandle != INVALID_HANDLE)
	{
		CloseHandle(g_hTimerHandle);
		g_hTimerHandle = INVALID_HANDLE;
	}
}