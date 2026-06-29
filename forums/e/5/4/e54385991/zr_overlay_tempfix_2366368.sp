#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

//ConVar g_mp_round_restart_delay;
ConVar g_convar_overlayHuman;
ConVar g_convar_overlayZombie;
ConVar g_convar_roundend_overlay;

char gc_overlayHuman[256];
char gc_overlayZombie[256];

bool twin = false;
bool ctwin = false;

int i_twin = 0;
int i_ctwin = 0;

Handle DisplayOverlay_Timer = INVALID_HANDLE;


public Plugin myinfo = 
{
	name = "zr overlay,score tempfix",
	author = "bbs.93x.net",
	description = "<- Description ->",
	version = "1.07",
	url = "<- URL ->"
}

public void OnAllPluginsLoaded()
{
	g_convar_roundend_overlay = FindConVar("zr_roundend_overlay");
	if(!g_convar_roundend_overlay)
	{
		SetFailState("zr_roundend_overlay not found!");
	}
	
	//g_mp_round_restart_delay = FindConVar("mp_round_restart_delay");
	
	g_convar_overlayHuman = FindConVar("zr_roundend_overlays_human");
	g_convar_overlayZombie = FindConVar("zr_roundend_overlays_zombie");
	
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("cs_win_panel_match", Event_cs_win_panel_match);

	
	HookConVarChange(g_convar_overlayHuman, HookConVar_Changed);
	HookConVarChange(g_convar_overlayZombie, HookConVar_Changed);
}

public void HookConVar_Changed(ConVar convar, char[] oldValue, char[] newValue)
{
	if(convar == g_convar_overlayHuman)
		GetConVarString(g_convar_overlayHuman, gc_overlayHuman, 256);
	
	if(convar == g_convar_overlayZombie)
		GetConVarString(g_convar_overlayZombie, gc_overlayZombie, 256);
}


public void OnConfigsExecuted()
{	
	if(DisplayOverlay_Timer != INVALID_HANDLE)
	{
		DisplayOverlay_Timer = INVALID_HANDLE;
	}
	CreateTimer(5.0 ,OnConfigsExecutedt);
}

public Action OnConfigsExecutedt(Handle timer)
{
	if(GetConVarInt(g_convar_roundend_overlay) != 0)
	{
		SetConVarInt(g_convar_roundend_overlay, 0);
	}
	/*
	if(GetConVarInt(g_mp_round_restart_delay) < 7)
	{
		SetConVarInt(g_mp_round_restart_delay, 7);
	}

	GetConVarString(g_convar_overlayHuman, gc_overlayHuman, 256);
	GetConVarString(g_convar_overlayZombie, gc_overlayZombie, 256);
	*/
}

public Action Event_cs_win_panel_match(Handle event, char[] name, bool dontBroadcast)
{
	if(DisplayOverlay_Timer != INVALID_HANDLE)
	{
		KillTimer(DisplayOverlay_Timer);
		DisplayOverlay_Timer = INVALID_HANDLE;
		ShowOverlayToAll("");
	}
}

public Action Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	twin = false;
	ctwin = false;
	
	if(DisplayOverlay_Timer != INVALID_HANDLE)
	{	
		KillTimer(DisplayOverlay_Timer);
		DisplayOverlay_Timer = INVALID_HANDLE;
	}
	
	ShowOverlayToAll("");
	
	i_twin = GetTeamScore(2);
	i_ctwin = GetTeamScore(3);
	
}

public void OnMapEnd()
{
	if(DisplayOverlay_Timer != INVALID_HANDLE)
	{
		KillTimer(DisplayOverlay_Timer);
		DisplayOverlay_Timer = INVALID_HANDLE;
		ShowOverlayToAll("");
	}
}

public Action Event_RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	int winner = GetEventInt(event, "winner");
	
	if(winner == 3)
	{
		ctwin = true;
		ShowOverlayToAll(gc_overlayHuman);
		CreateTimer(1.0 ,CheckScore);
	}
	else if(winner == 2)
	{
		ShowOverlayToAll(gc_overlayZombie);
		twin = true;
		CreateTimer(1.0 ,CheckScore);
	}
	
	if(DisplayOverlay_Timer != INVALID_HANDLE)
	{
		KillTimer(DisplayOverlay_Timer);
		DisplayOverlay_Timer = INVALID_HANDLE;
	}
	
	DisplayOverlay_Timer = CreateTimer(1.0, DisplayOverlay, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	
	//PrintToChatAll("T %s",gc_overlayZombie);
	//PrintToChatAll("CT %s",gc_overlayHuman);
}

public Action CheckScore(Handle timer)
{	
	if(twin)
	{
		if(GetTeamScore(2) == i_twin)
		{
			SetTeamScore(2, GetTeamScore(2)+1);
		}
		if(GetTeamScore(3) > i_ctwin)
		{
			SetTeamScore(3, GetTeamScore(3)-1);
		}
	}
	else if(ctwin) 
	{
		if(GetTeamScore(3) == i_ctwin)
		{
			SetTeamScore(3, GetTeamScore(3)+1);
		}
		if(GetTeamScore(2) > i_twin)
		{
			SetTeamScore(2, GetTeamScore(2)-1);
		}
	}
	return Plugin_Stop;
}


public Action DisplayOverlay(Handle timer)
{	
	if(twin)
	{	
		ShowOverlayToAll(gc_overlayZombie);
	}
	else if(ctwin) 
	{
		ShowOverlayToAll(gc_overlayHuman);
	}
	else if(!ctwin && !twin)
	{
		ShowOverlayToAll("");
	}
}	


void ShowOverlayToClient(client, const char[] overlaypath)
{
	ClientCommand(client, "r_screenoverlay \"%s\"", overlaypath);
}

void ShowOverlayToAll(const char[] overlaypath)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			ShowOverlayToClient(i, overlaypath);
		}
	}
}

