#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

bool g_bClientIsHoldByInfected[MAXPLAYERS+1];
ConVar pain_pills_decay_rate;

public void OnPluginStart()
{
	RegConsoleCmd("sm_teams", Command_TeamsPanel, "Show Team Panel");
	RegConsoleCmd("sm_team", Command_TeamsPanel, "Show Team Panel");
	
	HookEvent("choke_start", Event_PlayerControlledByInfected);
	HookEvent("lunge_pounce", Event_PlayerControlledByInfected);
	//HookEvent("jockey_ride", Event_PlayerControlledByInfected);
	//HookEvent("charger_pummel_start", Event_PlayerControlledByInfected);
	
	HookEvent("choke_end", Event_PlayerControlledByInfectedEnd);
	HookEvent("tongue_release", Event_PlayerControlledByInfectedEnd);
	HookEvent("pounce_stopped", Event_PlayerControlledByInfectedEnd);
	//HookEvent("charger_pummel_end", Event_PlayerControlledByInfectedEnd);
	//HookEvent("jockey_ride_end", Event_PlayerControlledByInfectedEnd);
	
	pain_pills_decay_rate = FindConVar("pain_pills_decay_rate");
}

void Event_PlayerControlledByInfected(Event event, const char[] name, bool dontBroadcast)
{  
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (!victim || !IsClientInGame(victim) || GetClientTeam(victim) != 2 || !IsPlayerAlive(victim) || !IsFakeClient(victim)) return;
	
	g_bClientIsHoldByInfected[victim] = true;
	
}

void Event_PlayerControlledByInfectedEnd(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (!victim || !IsClientInGame(victim) || GetClientTeam(victim) != 2 || !IsPlayerAlive(victim) || !IsFakeClient(victim)) return;
	
	g_bClientIsHoldByInfected[victim] = false;
}

Action Command_TeamsPanel(int client, int args)
{
	Create_ShowTeamsPanel(client);
	return Plugin_Handled;
}

void Create_ShowTeamsPanel(int client)
{
	Panel panel = new Panel();
	
	char sInfo[100];
	char sStatus[32];
	
	panel.DrawItem("Spectator Team");
	if(GetTeamNumber(1) == 0) panel.DrawItem("- None", ITEMDRAW_RAWLINE);
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || GetClientTeam(i) != 1) continue;
			
			FormatEx(sInfo, sizeof(sInfo), "- %N", i);
			panel.DrawItem(sInfo, ITEMDRAW_RAWLINE);
		}
	}
	
	panel.DrawItem(" ", ITEMDRAW_RAWLINE);
	
	panel.DrawItem("Survivors Team");
	if(GetTeamNumber(2) == 0) panel.DrawItem("- None", ITEMDRAW_RAWLINE);
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || GetClientTeam(i) != 2) continue;
			
			if(!IsPlayerAlive(i)) FormatEx(sStatus, sizeof(sStatus), "Dead");
			else if (IsClientIncapped(i) && !g_bClientIsHoldByInfected[i]) FormatEx(sStatus, sizeof(sStatus), "Incapped");
			else if (IsClientHanging(i)) FormatEx(sStatus, sizeof(sStatus), "Hanging");
			else if (g_bClientIsHoldByInfected[i]) FormatEx(sStatus, sizeof(sStatus), "Hold By Infected");
			else FormatEx(sStatus, sizeof(sStatus), "Standing");
			
			FormatEx(sInfo, sizeof(sInfo), "- %N ( %i HP ) ( %s )", i, GetClientRealHealth(i), sStatus);
			panel.DrawItem(sInfo, ITEMDRAW_RAWLINE);
		}
	}
	
	panel.DrawItem(" ", ITEMDRAW_RAWLINE);
	
	panel.DrawItem("Infected Team");
	if(GetTeamNumber(3) == 0) panel.DrawItem("- None", ITEMDRAW_RAWLINE);
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || GetClientTeam(i) != 3) continue;
			
			FormatEx(sInfo, sizeof(sInfo), "- %N", i);
			panel.DrawItem(sInfo, ITEMDRAW_RAWLINE);
		}
	}
	
	panel.Send(client, HandleShowTeamsPanel, MENU_TIME_FOREVER);
}

int HandleShowTeamsPanel(Menu menu, MenuAction action, int client, int selectedIndex)
{
	switch(action) 
	{
		case MenuAction_End: 
		{
			delete menu;
		}
	}
	return 0;
}

bool IsClientHanging(int client)
{
	return GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0 || GetEntProp(client, Prop_Send, "m_isFallingFromLedge") != 0;
}

bool IsClientIncapped(int client)
{
    return GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0 && GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 1;
}

int GetTeamNumber(int team)
{
	int number = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team)
			number++;
	}
	return number;
}

int GetClientRealHealth(int client)
{ 
	float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float TempHealth;
	int PermHealth = GetClientHealth(client);
	if(buffer <= 0.0) TempHealth = 0.0;
	else
	{
		float difference = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
		float decay = pain_pills_decay_rate.FloatValue;
		float constant = 1.0/decay;
		TempHealth = buffer - (difference / constant);
	}
	if(TempHealth < 0.0) TempHealth = 0.0;
	return RoundToFloor(PermHealth + TempHealth);
}