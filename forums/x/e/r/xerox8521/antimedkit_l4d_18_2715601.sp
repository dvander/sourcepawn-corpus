#include <sourcemod>
#include <sdkhooks>
#include <dhooks>

ConVar cvmkp_minhealth = null;
ConVar cvmkp_usetemphealth = null;
ConVar pain_pills_decay_rate = null;
ConVar cvmkp_messagetime = null;

float flLastMessageTime[MAXPLAYERS+1];

const int UseAction_SelfHeal = 0;
const int UseAction_TargetHeal = 1;

#define PLUGIN_VERSION "1.2.1"

Handle hPlayerStartHealingDetour = null;

bool bIsOnThirdStrike[MAXPLAYERS+1];

public Plugin myInfo =
{
	name = "Medkit Preventer L4D",
	author = "XeroX",
	description = "Prevents the use of the medkit if certain conditions are not met",
	version = PLUGIN_VERSION,
	url = "http://soldiersofdemise.com"
}

public void OnPluginStart()
{
	cvmkp_minhealth = CreateConVar("mkp_minhealth", "40", "Specify the amount the player needs to be at to use Medkits.", FCVAR_NOTIFY, true, 1.0);
	cvmkp_usetemphealth = CreateConVar("mkp_usetemphealth", "0", "Should temporary health be included in the health check.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvmkp_messagetime = CreateConVar("mkp_messagetime", "2.5", "Time between sending a warning message", FCVAR_NOTIFY, true, 1.0, true, 10.0);
	CreateConVar("mkp_version", PLUGIN_VERSION, "Plugin Version", FCVAR_NOTIFY);

	pain_pills_decay_rate = FindConVar("pain_pills_decay_rate");

	LoadTranslations("antimedkit.phrases");

	Handle hGameConfig = LoadGameConfigFile("antimedkit");
	if(hGameConfig == null)
	{
		SetFailState("Gamedata file antimedkit.txt is missing!");
		return;
	}

	hPlayerStartHealingDetour = DHookCreateFromConf(hGameConfig, "PlayerStartHealing");
	DHookEnableDetour(hPlayerStartHealingDetour, false, OnPlayerStartHealing);
	delete hGameConfig;

	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("heal_success", Event_HealSuccess);
	HookEvent("player_death", Event_PlayerDeath);

	HookEvent("round_end_message", Event_RoundEnd);
	HookEvent("finale_win", Event_RoundEnd);
	HookEvent("mission_lost", Event_RoundEnd);
	HookEvent("round_end_message", Event_RoundEnd);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) continue;
		flLastMessageTime[i] = 0.0;
	}
}

public MRESReturn OnPlayerStartHealing(int client, Handle hParams)
{
	int target = DHookGetParam(hParams, 1);
	if(client == target)
	{
		// Ignore if we are in Black / White Mode
		if(bIsOnThirdStrike[client])
			return MRES_Ignored;

		if(cvmkp_usetemphealth.BoolValue)
		{
			if(GetClientRealHealth(client) > cvmkp_minhealth.IntValue)
			{
				// Prevent message spamming when holding LMB / RMB
				if(GetGameTime() > flLastMessageTime[client])
				{
					PrintToChat(client, "[AntiMedkit]: %t", "Cannot Use Medkit");
					flLastMessageTime[client] = GetGameTime() + cvmkp_messagetime.FloatValue; // Allow another message after cvmkp_messagetime seconds
				}
				return MRES_Supercede;
			}
		}
		// This only checks normal hp. It does not check for temp health
		if(GetClientHealth(client) > cvmkp_minhealth.IntValue )
		{
			// Prevent message spamming when holding LMB / RMB
			if(GetGameTime() > flLastMessageTime[client])
			{
				PrintToChat(client, "[AntiMedkit]: %t", "Cannot Use Medkit");
				flLastMessageTime[client] = GetGameTime() + cvmkp_messagetime.FloatValue; // Allow another message after cvmkp_messagetime seconds	
			}
			return MRES_Supercede;
		}
	}
	else
	{
		if(IsValidEntity(target))
		{
			// Ignore on full health
			if(GetClientHealth(target) == GetEntProp(target, Prop_Data, "m_iMaxHealth"))
				return MRES_Ignored;
			// Ignore if we are in Black / White Mode
			if(bIsOnThirdStrike[target])
				return MRES_Ignored;

			if(cvmkp_usetemphealth.BoolValue)
			{
				if(GetClientRealHealth(target) > cvmkp_minhealth.IntValue)
				{
					// Prevent message spamming when holding LMB / RMB
					if(GetGameTime() > flLastMessageTime[client])
					{
						char Name[MAX_NAME_LENGTH];
						GetClientName(target, Name, sizeof(Name));
						PrintToChat(client, "[AntiMedkit]: %t", "Cannot Use Medkit Target", Name);
						flLastMessageTime[client] = GetGameTime() + cvmkp_messagetime.FloatValue; // Allow another message after cvmkp_messagetime seconds	
					}
					return MRES_Supercede;
				}
			}
			// This only checks normal hp. It does not check for temp health
			if(GetClientHealth(target) > cvmkp_minhealth.IntValue )
			{
				// Prevent message spamming when holding LMB / RMB
				if(GetGameTime() > flLastMessageTime[client])
				{
					char Name[MAX_NAME_LENGTH];
					GetClientName(target, Name, sizeof(Name));
					PrintToChat(client, "[AntiMedkit]: %t", "Cannot Use Medkit Target", Name);	
					flLastMessageTime[client] = GetGameTime() + cvmkp_messagetime.FloatValue; // Allow another message after cvmkp_messagetime seconds	
				}
				return MRES_Supercede;
			}
		}
	}
	return MRES_Ignored;
}

public void Event_RoundEnd(Event event, const char[] szName, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) continue;
		flLastMessageTime[i] = 0.0;
	}
}


public void Event_PlayerDeath(Event event, const char[] szName, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	bIsOnThirdStrike[client] = false;
}
public void Event_HealSuccess(Event event, const char[] szName, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	bIsOnThirdStrike[client] = false;
}
public void Event_ReviveSuccess(Event event, const char[] szName, bool dontBroadcast)
{
	// L4d unfortunatly doesn't provide a simple way to check if a player is on their "third strike"
	// So we have to do it manually
	int client = GetClientOfUserId(event.GetInt("subject"));

	bIsOnThirdStrike[client] = event.GetBool("lastlife");
}

int GetClientRealHealth(int client)
{
	// Code based on: https://forums.alliedmods.net/showthread.php?t=144780
	float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");

	// Time difference between using the temp health item and current time.
	float bufferTimeDifference = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");

	// This is used to determine the amount of time has to pass before 1 Temp HP is removed.
	float constant = 1.0 / pain_pills_decay_rate.FloatValue;

	float tempHealth = buffer - (bufferTimeDifference / constant);
	if(tempHealth < 0.0)
		tempHealth = 0.0;

	return GetClientHealth(client) + RoundToFloor(tempHealth);
}