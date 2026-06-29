#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.1"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

public Plugin myinfo = 
{
    name = "[L4D] Infinite Adren Med Shots",
    author = "Olj(Rewritten by BloodyBlade)",
    description = "Infinite Shots",
    version = PLUGIN_VERSION,
    url = "http://www.sourcemod.net/"
}

ConVar hInfMedPluginOn;
bool bL4D2 = false, bHooked = false, bAdren[MAXPLAYERS + 1] = {false, ...}, bFirst[MAXPLAYERS + 1] = {false, ...};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine == Engine_Left4Dead)
	{
		bL4D2 = false;
	}
	else if(engine == Engine_Left4Dead2)
	{
		bL4D2 = true;
	}
	else
	{
		strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" game series");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
    CreateConVar("l4d_infmed_version", PLUGIN_VERSION, "[L4D] Infinite Adren Med Shots plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
    hInfMedPluginOn = CreateConVar("l4d_infmed_enable", "1", "Enable/Disable plugin", CVAR_FLAGS);
    AutoExecConfig(true, "l4d_infmed");
    hInfMedPluginOn.AddChangeHook(OnConVarPluginEnableChanged);
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

void OnConVarPluginEnableChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
    IsAllowed();
}

void IsAllowed()
{
	bool bPluginOn = hInfMedPluginOn.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		HookEvent("heal_success", HealEvent);
		if(bL4D2)
		{
			HookEvent("adrenaline_used", AdrenalineUsed_Event);
		}
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		UnhookEvent("heal_success", HealEvent);
		if(bL4D2)
		{
			UnhookEvent("adrenaline_used", AdrenalineUsed_Event);
		}
	}
}

//Code for Medpacks
void HealEvent(Event event, const char[] name, bool dontBroadcast)
{
    int iHealer = GetClientOfUserId(event.GetInt("userid"));
    bAdren[iHealer] = false;
    bFirst[iHealer] = true;
    RequestFrame(ReGivingAdrenMeds, iHealer);
}

//Code for Adrenaline Shots
void AdrenalineUsed_Event(Event event, const char[] name, bool dontBroadcast)
{
    int iHealer = GetClientOfUserId(event.GetInt("userid"));
    bFirst[iHealer] = false;
    bAdren[iHealer] = true;
    RequestFrame(ReGivingAdrenMeds, iHealer);
}

void ReGivingAdrenMeds(int Healer)
{
    if(bFirst[Healer])
    {
        bFirst[Healer] = false;
        GivePlayerItem(Healer, "weapon_first_aid_kit");
    }
    else if(bAdren[Healer])
    {
        bAdren[Healer] = false;
        GivePlayerItem(Healer, "weapon_adrenaline");
    }
}
