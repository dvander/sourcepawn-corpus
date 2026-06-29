#include <sourcemod>
#include <sdktools>
#include <nextmap>
#include <tf2>
#include <tf2_stocks>

new Handle:g_hRemoveCPs;
new Handle:g_hPluginEnabled;
new bool:g_bPluginEnabled
new bool:g_bCPTouched[33][8];
new g_iMaxClients, g_iCPs, g_iCPsTouched[33];

public OnPluginStart()
{
	g_hPluginEnabled = CreateConVar("jm_enabled", "1", "Enable the Jump Mode", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	g_hRemoveCPs = CreateConVar("jm_removecps", "1", "Remove Control Points from the map", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hRemoveCPs, cvarRemoveCPsChanged);
	HookEvent("teamplay_round_start", eventRoundStart);
	HookConVarChange(g_hPluginEnabled, cvarEnabledChanged);
}

public OnConfigsExecuted()
{
	new iEnabled = GetConVarInt(g_hPluginEnabled);
	if(iEnabled == 0)
		TurnOffPlugin();
	else if(iEnabled == 1)
	{
		if(IsMapEnabled())
			TurnOnPlugin();
		else
			TurnOffPlugin();
	}
	else
		TurnOnPlugin();
}


public Action:eventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bPluginEnabled)
	{
		if(GetConVarBool(g_hRemoveCPs))
			RemoveCPs();	
		ZeroCPsAll();
	}
}

public cvarRemoveCPsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
		RemoveCPs();
}

public cvarEnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iEnabled = GetConVarInt(g_hPluginEnabled);
	if(iEnabled == 0)
		TurnOffPlugin();
	else if(iEnabled == 1)
	{
		if(IsMapEnabled())
			TurnOnPlugin();
		else
			TurnOffPlugin();
	}
	else
		TurnOnPlugin();
}

RemoveCPs()
{
	new iCP = -1;
	g_iCPs = 0;
	while ((iCP = FindEntityByClassname(iCP, "trigger_capture_area")) != -1)
	{
		SetVariantString("2 0");
		AcceptEntityInput(iCP, "SetTeamCanCap");
		SetVariantString("3 0");
		AcceptEntityInput(iCP, "SetTeamCanCap");
		g_iCPs++;
	}
}

ZeroCPsAll()
{
	for(new i = 0; i <= g_iMaxClients; i++)
		ZeroCPs(i);
}	

ZeroCPs(client)
{
	for(new j = 0; j < 8; j++)
		g_bCPTouched[client][j] = false;
	g_iCPsTouched[client] = 0;
}

TurnOnPlugin()
{
	g_bPluginEnabled = true;
}

TurnOffPlugin()
{
	if(g_bPluginEnabled)
	{
		g_bPluginEnabled = false;
	}
}

bool:IsMapEnabled()
{
	return false;
}