#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION 	"1.2"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "Survivor Heal Info",
	author = "CAPS LOCK FUCK YEAH",
	description = "SameAsName",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" and \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

ConVar g_enabled, g_allowed_all_teams;
bool bHooked = false, bAllowedAllTeams = false;

public void OnPluginStart()
{
	CreateConVar("sm_healinfo_version", PLUGIN_VERSION,"Heal Info Version", CVAR_FLAGS|FCVAR_DONTRECORD);
	g_enabled = CreateConVar("sm_healinfo_enabled", "1", "Is Heal Info Enabled?", CVAR_FLAGS);
	g_allowed_all_teams = CreateConVar("sm_healinfo_all_teams", "1", "1 = All teams, 0 = Only Surv & Spec team", CVAR_FLAGS);
	g_enabled.AddChangeHook(ConVarPluginOnChanged);
	g_allowed_all_teams.AddChangeHook(ConVarsChanged);
	AutoExecConfig(true, "healinfo");
	LoadTranslations("healinfo.phrases.txt");
}

void ConVarPluginOnChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    IsAllowed();
}

void ConVarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    bAllowedAllTeams = g_allowed_all_teams.BoolValue;
}

void IsAllowed()
{
    bool bPluginOn = g_enabled.BoolValue;
    if (bPluginOn && !bHooked)
    {
        bHooked = true;
    	ConVarsChanged(null, "", "");
        HookEvent("heal_success", HealSuccess);
    }
    else if(!bPluginOn && bHooked)
    {
        bHooked = false;
        UnhookEvent("heal_success", HealSuccess);
    }
}

void HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int HealthRestored = event.GetInt("health_restored");
	int healee = GetClientOfUserId(event.GetInt("subject"));
	int healer = GetClientOfUserId(event.GetInt("userid"));
	char PName1[64], PName2[64];
	GetClientName(healer, PName1, sizeof(PName1));
	GetClientName(healee, PName2, sizeof(PName2));
	if (StrEqual(PName1, PName2))
	{
		if(bAllowedAllTeams)
		{
			PrintHintTextToAll("%T", "healed_self", PName1, HealthRestored);
		}
		else
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && GetClientTeam(i) != 3)
				{
					PrintHintText(i, "%T", "healed_self", PName1, HealthRestored);
				}
			}
		}
	}
	else
	{
		if(bAllowedAllTeams)
		{
			PrintHintTextToAll("%T", "healed_other", PName1, PName2, HealthRestored);
		}
		else
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && GetClientTeam(i) != 3)
				{
					PrintHintText(i, "%T", "healed_other", PName1, PName2, HealthRestored);
				}
			}
		}
	}
}
