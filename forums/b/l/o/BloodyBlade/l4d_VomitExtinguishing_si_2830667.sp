#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar hVomitPluginEnabled, hVomitAdvMessageType;
int iVomitAdvMessageType = 0;
bool bHooked = false, bVomited[MAXPLAYERS + 1] = {false, ...};

public Plugin myinfo = 
{
	name = "[L4D] Vomit extinguishing special infected",
	author = "BloodyBlade",
	description = "Vomit can extinguish burning special infected",
	version = PLUGIN_VERSION,
	url = "http://bloodsiworld.ru/"
}

//Special thanks: [L4D & L4D2] Vomit extinguishing by Olj, Visual77, asto, raziEiL [disawar1]

public void OnPluginStart()
{
	CreateConVar("l4d_vomit_extinguish_si_plugin_version", PLUGIN_VERSION, "Vomit Extinguishing  special infected plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	hVomitPluginEnabled = CreateConVar("l4d_vomit_extinguish_si_plugin_enabled", "1", " Enable/Disable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
	hVomitAdvMessageType = CreateConVar("l4d_vomit_extinguish_si_advmessage_type", "1", "Message type(0 - disable, 1 - chat, 2 - hint, 3 - instructor hint)", CVAR_FLAGS, true, 0.0, true, 3.0);

	hVomitPluginEnabled.AddChangeHook(ConVarPluginOnChanged);
	hVomitAdvMessageType.AddChangeHook(ConVarVomitMessageTypeChanged);

	LoadTranslations("l4d_vomit_extinguish_si.phrases");
	AutoExecConfig(true, "l4d_vomit_extinguishing_si");
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

void ConVarPluginOnChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    IsAllowed();
}

void ConVarVomitMessageTypeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    iVomitAdvMessageType = hVomitAdvMessageType.IntValue;
}

void IsAllowed()
{
	bool bPluginOn = hVomitPluginEnabled.BoolValue;
	if(bPluginOn && !bHooked)
	{
		bHooked = true;
		ConVarVomitMessageTypeChanged(null, "", "");
		HookEvent("player_spawn", EventPlayerSpawn);
		HookEvent("player_now_it", EventNowVomit);
		HookEvent("player_no_longer_it", EventNoLongerVomit);
	}
	else if(!bPluginOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("player_spawn", EventPlayerSpawn);
		UnhookEvent("player_now_it", EventNowVomit);
		UnhookEvent("player_no_longer_it", EventNoLongerVomit);
	}
}

public void OnClientPutInServer(int client)
{
	if (bHooked && client > 0)
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

Action EventPlayerSpawn(Event h_Event, const char[] s_Name, bool b_DontBroadcast)
{
	int iClient = GetClientOfUserId(h_Event.GetInt("userid"));
	if (IsValidInfected(iClient) && !IsFakeClient(iClient) && GetEntProp(iClient, Prop_Send, "m_zombieClass") == 2)
	{
		switch(iVomitAdvMessageType)
		{
			case 1:
			{
				PrintToChat(iClient, "\x03[%t]\x01 %t.", "Information", "Vomit players");
			}
			case 2: 
			{
				PrintHintText(iClient, "%t", "Vomit players");
			}
			case 3:
			{
				char s_Message[256];
				FormatEx(s_Message, sizeof(s_Message), "%t", "Vomit players");
				DisplayInstructorHint(iClient, s_Message, "+attack");
			}
		}
	}
	return Plugin_Continue;
}

void DisplayInstructorHint(int iClient, char sMessage[256], char[] sBind)
{
	char s_TargetName[32];
	int iEnt = CreateEntityByName("env_instructor_hint");
	FormatEx(s_TargetName, sizeof(s_TargetName), "hint%d", iClient);
	ReplaceString(sMessage, sizeof(sMessage), "\n", " ");
	DispatchKeyValue(iClient, "targetname", s_TargetName);
	DispatchKeyValue(iEnt, "hint_target", s_TargetName);
	DispatchKeyValue(iEnt, "hint_timeout", "5");
	DispatchKeyValue(iEnt, "hint_range", "0.01");
	DispatchKeyValue(iEnt, "hint_color", "255 255 255");
	DispatchKeyValue(iEnt, "hint_icon_onscreen", "use_binding");
	DispatchKeyValue(iEnt, "hint_caption", sMessage);
	DispatchKeyValue(iEnt, "hint_binding", sBind);
	DispatchSpawn(iEnt);
	AcceptEntityInput(iEnt, "ShowHint");

	DataPack hRemovePack = new DataPack();
	hRemovePack.WriteCell(iClient);
	hRemovePack.WriteCell(EntIndexToEntRef(iEnt));
	CreateDataTimer(5.0, RemoveInstructorHint, hRemovePack, TIMER_DATA_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
}

Action RemoveInstructorHint(Handle h_Timer, DataPack hPack)
{
	hPack.Reset();
	int iClient = hPack.ReadCell();
	int iEnt = EntRefToEntIndex(hPack.ReadCell());

	if (IsValidEntity(iEnt))
	{
		RemoveEntity(iEnt);
	}

	if (IsValidInfected(iClient))
	{
		DispatchKeyValue(iClient, "targetname", "");
	}

	return Plugin_Stop;
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	if(IsValidInfected(victim) && bVomited[victim] && GetEntityFlags(victim) & FL_ONFIRE)
	{
		ExtinguishEntity(victim);
	}
	return Plugin_Continue;
}

void EventNowVomit(Event event, const char[] name, bool dontBroadcast)
{
	int iAttacker = GetClientOfUserId(event.GetInt("attacker")), iVictim = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidInfected(iAttacker) && IsValidInfected(iVictim) && GetEntityFlags(iVictim) & FL_ONFIRE)
	{
		bVomited[iVictim] = true;
		if(event.GetBool("exploded") || event.GetBool("by_boomer"))
		{
			ExtinguishEntity(iVictim);
		}
	}
}

void EventNoLongerVomit(Event event, const char[] name, bool dontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidInfected(iVictim))
	{
		bVomited[iVictim] = false;
	}
}

bool IsValidInfected(int iClient)
{
	return iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient) && GetClientTeam(iClient) == 3 && IsPlayerAlive(iClient);
}
