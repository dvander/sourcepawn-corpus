#include <sourcemod>
#include <store>
#include <zephstocks>

ConVar CreditsAdder;
ConVar CreditsTime;
Handle TimeAuto = null;

public Plugin myinfo = 
{
	name = "Store Flag Credits",
	author = "Xines, edit by shanapu",
	description = "Deals x amount of credits per x amount of secounds for Vip",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
		
	//Configs
	CreditsAdder = CreateConVar("sm_flag_credits", "5", "Credits to give per X time, if player is in group.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	CreditsTime = CreateConVar("sm_flag_credits_time", "60", "Time in seconds to deal credits.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	//Don't Touch
	HookConVarChange(CreditsTime, Change_CreditsTime);
}

public void OnMapStart()
{
	TimeAuto = CreateTimer(GetConVarFloat(CreditsTime), CheckPlayers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action CheckPlayers(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			addcredits(i);
		}
	}
	
	return Plugin_Continue;
}

public void addcredits(int client)
{
	if (CheckCommandAccess(client, "custom_command", ADMFLAG_CUSTOM1, true))
	{
		Store_SetClientCredits(client, Store_GetClientCredits(client) + GetConVarInt(CreditsAdder));
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (IsFakeClient(client))
		return;

}

public void Change_CreditsTime(Handle cvar, const char[] oldVal, const char[] newVal)
{
	if (TimeAuto != null)
	{
		KillTimer(TimeAuto);
		TimeAuto = null;
	}

	TimeAuto = CreateTimer(GetConVarFloat(CreditsTime), CheckPlayers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
