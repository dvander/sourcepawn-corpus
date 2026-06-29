#include <sourcemod>
#include <sdkhooks>
#include <dhooks>

Handle hShouldStartAction = null;

ConVar cvmkp_minhealth = null;
ConVar cvmkp_usetemphealth = null;
ConVar pain_pills_decay_rate = null;
ConVar cvmkp_messagetime = null;

float flLastMessageTime[MAXPLAYERS+1];

const int UseAction_SelfHeal = 0;
const int UseAction_TargetHeal = 1;

#define PLUGIN_VERSION "1.2.1"

public Plugin myInfo =
{
	name = "Medkit Preventer",
	author = "XeroX",
	description = "Prevents the use of the medkit if certain conditions are not met",
	version = PLUGIN_VERSION,
	url = "http://soldiersofdemise.com"
}

public void OnPluginStart()
{

	cvmkp_minhealth = CreateConVar("mkp_minhealth", "40", "Specify the amount the player needs to be at to use Medkits.", FCVAR_NOTIFY, true, 1.0, true, 100.0);
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

	int offset = GameConfGetOffset(hGameConfig, "CFirstAidKit::ShouldStartAction");
	hShouldStartAction = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, OnShouldStartAction);
	DHookAddParam(hShouldStartAction, HookParamType_Int);
	DHookAddParam(hShouldStartAction, HookParamType_CBaseEntity);
	DHookAddParam(hShouldStartAction, HookParamType_CBaseEntity);
	delete hGameConfig;

	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "weapon_first_aid_kit")) != -1)
	{
		DHookEntity(hShouldStartAction, true, entity);
	}

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) continue;
		flLastMessageTime[i] = 0.0;
	}

	HookEvent("mission_lost", Event_MissionLost);
	HookEvent("round_end", Event_MissionLost);
	HookEvent("round_end_message", Event_MissionLost);
}

public void OnClientPutInServer(int client)
{
	flLastMessageTime[client] = 0.0;
}

public void Event_MissionLost(Event event, const char[] szName, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) continue;
		flLastMessageTime[i] = 0.0;
	}
}

public void OnEntityCreated(int entity, const char[] szClassname)
{
	if(StrEqual("weapon_first_aid_kit", szClassname, false))
	{
		DHookEntity(hShouldStartAction, true, entity);
	}
}

public MRESReturn OnShouldStartAction(int pThis, Handle hReturn, Handle hParams)
{
	int client = GetEntPropEnt(pThis, Prop_Data, "m_hOwner");
	int useAction = DHookGetParam(hParams, 1);
	int target = DHookGetParam(hParams, 3);
	if(IsValidEntity(client))
	{
		// Ignore if we are in Black / White Mode
		if(GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike"))
			return MRES_Ignored;

		if(useAction == UseAction_SelfHeal)
		{
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
					DHookSetReturn(hReturn, false);
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
				DHookSetReturn(hReturn, false);
				return MRES_Supercede;
			}
		}
		else if(useAction == UseAction_TargetHeal && IsValidEntity(target))
		{
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
					DHookSetReturn(hReturn, false);
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
				DHookSetReturn(hReturn, false);
				return MRES_Supercede;
			}
		}	
	}
	return MRES_Ignored;
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