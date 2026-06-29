#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <ckSurf>
#include <store>

#define PLUGIN_VERSION "Private"
#define DEFAULT_FLAGS 	FCVAR_NOTIFY

new bool:mapFinished[MAXPLAYERS + 1] = false;
new bool:bonusFinished[MAXPLAYERS + 1] = false;
new bool:practiceFinished[MAXPLAYERS + 1] = false;

public Plugin:myinfo =
{
	name = "Zephyrus-Store: ckSurf",
	author = "Simon",
	description = "Give credits on completion.",
	version = PLUGIN_VERSION,
	url = "yash1441@yahoo.com"
};

new Handle:g_hCreditsNormal = INVALID_HANDLE;
new Handle:g_hCreditsBonus = INVALID_HANDLE;
new Handle:g_hCreditsPractice = INVALID_HANDLE;
new g_CreditsNormal, g_CreditsBonus, g_CreditsPractice;

public OnPluginStart()
{
	CreateConVar("zeph_surf_version", PLUGIN_VERSION, "Zephyrus-Store: ckSurf", FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	g_hCreditsNormal = CreateConVar("zeph_surf_normal", "50", "Credits given when a player finishes a map.", DEFAULT_FLAGS);
	g_hCreditsBonus = CreateConVar("zeph_surf_bonus", "100", "Credits given when a player finishes a bonus.", DEFAULT_FLAGS);
	g_hCreditsPractice = CreateConVar("zeph_surf_practice", "25", "Credits given when a player finishes a map in practice mode", DEFAULT_FLAGS);
	HookConVarChange(g_hCreditsNormal, OnConVarChanged);
	HookConVarChange(g_hCreditsBonus, OnConVarChanged);
	HookConVarChange(g_hCreditsPractice, OnConVarChanged);
}

public OnMapStart()
{
	for(new i = 1; i < MaxClients; i++)
	{
		mapFinished[i] = false;
		bonusFinished[i] = false;
		practiceFinished[i] = false;
	}
}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_hCreditsNormal)
	{
		g_CreditsNormal = StringToInt(newValue);
	}
	else if (convar == g_hCreditsBonus)
	{
		g_CreditsBonus = StringToInt(newValue);
	}
	else if (convar == g_hCreditsPractice)
	{
		g_CreditsPractice = StringToInt(newValue);
	}
}

public Action:ckSurf_OnMapFinished(client, Float:fRunTime, String:sRunTime[54], rank, total)
{
	if(!mapFinished[client])
	{
		Store_SetClientCredits(client, Store_GetClientCredits(client) + g_CreditsNormal);
		mapFinished[client] = true;
	}
	else
	{
		Store_SetClientCredits(client, Store_GetClientCredits(client) + 10);
	}
}

public Action:ckSurf_OnBonusFinished(client, Float:fRunTime, String:sRunTime[54], rank, total, bonusid)
{
	if(!bonusFinished[client])
	{
		Store_SetClientCredits(client, Store_GetClientCredits(client) + g_CreditsBonus);
		bonusFinished[client] = true;
	}
	else
	{
		Store_SetClientCredits(client, Store_GetClientCredits(client) + 10);
	}
}

public Action:ckSurf_OnPracticeFinished(client, Float:fRunTime, String:sRunTime[54])
{
	if(!practiceFinished[client])
	{
		Store_SetClientCredits(client, Store_GetClientCredits(client) + g_CreditsPractice);
		practiceFinished[client] = true;
	}
	else
	{
		Store_SetClientCredits(client, Store_GetClientCredits(client) + 5);
	}
}