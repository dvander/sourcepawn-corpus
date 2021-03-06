#pragma semicolon 1

#include <sourcemod>
#include <morecolors>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define MAJOR_REVISION "1"
#define MINOR_REVISION "0"
#define PATCH_REVISION "2"

#pragma newdecls required

#if !defined PATCH_REVISION
	#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION
#else
	#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...PATCH_REVISION
#endif

bool Ability_TriggerAMS[MAXPLAYERS+1]; // global boolean to use with AMS

public Plugin myinfo = {
    name = "Freak Fortress 2: AMS-supported subplugin template",
    author = "SHADoW NiNE TR3S",
    version = PLUGIN_VERSION,
};

#define ABILITYNAME "rage_text" // ability name
#define ABILITYNAMEALIAS "TXT"  // abbreviation of ability name
/*
 use this same 3-letter abbreviation for the following stocks
	public bool <ABILITYNAMEALIAS>_CanInvoke(clientIdx)
	public void <ABILITYNAMEALIAS>_Invoke(clientIdx)
	
 since we have ABILITYNAMEALIAS as TXT, it would then be written as:
	public bool TXT_CanInvoke(clientIdx)
	public void TXT_Invoke(clientIdx)
	
 since the final argument for AMS_InitSubability makes a reflective call using that abbreviation for the two public analogues to the subplugin
*/

public void OnPluginStart2()
{
	HookEvent("arena_round_start", Event_ArenaRoundStart);
	HookEvent("arena_win_panel", Event_ArenaWinPanel);
	if(FF2_GetRoundState()==1)
	{
		PrepareAbilities(); // Late-load / reload
	}
}

public void FF2_OnAbility2(int bossIdx, const char[] plugin_name, const char[] ability_name, int status)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState()!=1)
		return; // Because some FF2 forks still allow RAGE to be activated when the round is over....
		
	int clientIdx=GetClientOfUserId(FF2_GetBossUserId(bossIdx));
	if(!strcmp(ability_name, ABILITYNAME))
	{
		Rage_Text(clientIdx); // Normal RAGE
	}
}

public void Event_ArenaRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState()!=1)
		return;
		
	PrepareAbilities(); // We initialize all abilities here
}

public void PrepareAbilities()
{
	for(int clientIdx=1;clientIdx<=MaxClients;clientIdx++) // lets find clients
	{
		if(!IsValidClient(clientIdx)) // ignore invalid clients
			continue;
			
		Ability_TriggerAMS[clientIdx]=false; // set to false for everyone
		
		int bossIdx=FF2_GetBossIndex(clientIdx); // let's find bosses
		if(bossIdx>=0) // only continue if they have a boss index other than -1
		{
			if(FF2_HasAbility(bossIdx, this_plugin_name, ABILITYNAME)) // We check whether this RAGE is activated normally, or via AMS
			{
				Ability_TriggerAMS[clientIdx] = view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, ABILITYNAME, 1)); // If true, this will trigger AMS_InitSubability.
				if(Ability_TriggerAMS[clientIdx])
				{
					AMS_InitSubability(bossIdx, clientIdx, this_plugin_name, ABILITYNAME, ABILITYNAMEALIAS); // Important function to tell AMS that this subplugin supports it
				}
			}
		}
	}
}

public void Event_ArenaWinPanel(Event event, const char[] name, bool dontBroadcast)
{
	for(int clientIdx=1;clientIdx<=MaxClients;clientIdx++)
	{
		if(IsValidClient(clientIdx))
		{
			Ability_TriggerAMS[clientIdx]=false; // Cleanup
		}
	}
}

public bool TXT_CanInvoke(int clientIdx)
{
	/*
		specify any conditions that would prevent this ability, and return false if either condition is met
		otherwise, return true
	*/
	return true;
}

void Rage_Text(int clientIdx)
{
	if(Ability_TriggerAMS[clientIdx]) // Prevent normal 100% RAGE activation if using AMS
		return;
		
	TXT_Invoke(clientIdx); // Activate RAGE normally, if ability is configured to be used as a normal RAGE.
}

public void TXT_Invoke(int clientIdx)
{
	int bossIdx=FF2_GetBossIndex(clientIdx);
	/*
		Insert your boss RAGE ability code here
	*/
	
	char message[512];	
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ABILITYNAME, 2, message, sizeof(message));
	if(message[0]!='\0')
	{
		CPrintToChatAll(message);
	}
}

// use this to check for valid clients (or alive valid clients)
stock bool IsValidClient(int clientIdx, bool isPlayerAlive=false)
{
	if (clientIdx <= 0 || clientIdx > MaxClients) return false;
	if(isPlayerAlive) return IsClientInGame(clientIdx) && IsPlayerAlive(clientIdx);
	return IsClientInGame(clientIdx);
}

// call AMS from epic scout's subplugin via reflection:
stock Handle FindPlugin(char[] pluginName)
{
	char buffer[256];
	char path[PLATFORM_MAX_PATH];
	Handle iter = GetPluginIterator();
	Handle pl = null;
	
	while (MorePlugins(iter))
	{
		pl = ReadPlugin(iter);
		Format(path, sizeof(path), "%s.ff2", pluginName);
		GetPluginFilename(pl, buffer, sizeof(buffer));
		if (StrContains(buffer, path, false) >= 0)
			break;
		else
			pl = null;
	}
	
	delete iter;

	return pl;
}

// this will tell AMS that the abilities listed on PrepareAbilities() supports AMS
stock void AMS_InitSubability(int bossIdx, int clientIdx, const char[] pluginName, const char[] abilityName, const char[] prefix)
{
	Handle plugin = FindPlugin("ff2_sarysapub3");
	if (plugin != null)
	{
		Function func = GetFunctionByName(plugin, "AMS_InitSubability");
		if (func != INVALID_FUNCTION)
		{
			Call_StartFunction(plugin, func);
			Call_PushCell(bossIdx);
			Call_PushCell(clientIdx);
			Call_PushString(pluginName);
			Call_PushString(abilityName);
			Call_PushString(prefix);
			Call_Finish();
		}
		else
			LogError("ERROR: Unable to initialize ff2_sarysapub3:AMS_InitSubability()");
	}
	else
		LogError("ERROR: Unable to initialize ff2_sarysapub3:AMS_InitSubability(). Make sure this plugin exists!");
}