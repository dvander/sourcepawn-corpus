/* AWP Win Limit Restrict
* 
* 	DESCRIPTION
* 		Allow you to restrict AWPs for a team if they are winning by a certain number of rounds.
* 
* 		This plugin was created by request of Monochrome (https://forums.alliedmods.net/showpost.php?p=2051471&postcount=1442)
* 
* 	VERSIONS and ChangeLog
* 
* 		1.0.0.0	*	Initial public release
* 		
* 		1.0.0.1	*	Modified code with Dr!fter's suggestions using Restrict_GetRestrictValue for original values of weapon_restrict awp limits
* 				+	Added code to disable this plugin if weapon_restrict is unloaded
* 
* 	TO DO List
* 		*	None, suggest something
* 
* 	KNOWN ISSUES
* 		None that I could find during my testing
* 
* 	REQUESTS
* 		Suggest something
* 
* 	CREDITS
* 		Monochrome for the request and idea.
*/

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <restrict>
#include <cstrike_weapons>
#include <autoexecconfig>

#pragma semicolon 1

#define PLUGIN_VERSION			"1.0.0.1"
#define _DEBUG 					0 // Set to 1 for debug spew

new bool:restrictedT;
new bool:restrictedCT;
new bool:Enabled;
new oldTvalue;
new oldCTvalue;
new dominationValue;

#if _DEBUG
#define MAX_MESSAGE_LENGTH		256
new String:dmsg[MAX_MESSAGE_LENGTH];
#endif

public Plugin:myinfo =
{
	name = "AWP Win Limit Restrict",
	author = "TnTSCS aka ClarkKent",
	description = "Restrict AWP after a team is N rounds ahead of the other.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

public OnPluginStart()
{
	new bool:appended;
	AutoExecConfig_SetFile("plugin.awp_win_limit");
	
	new Handle:hRandom; //KyleS HATES Handles
	
	HookConVarChange((CreateConVar("sm_awlr_version", PLUGIN_VERSION, 
	"The version of \"AWP Win Limit Restrict\"", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_awlr_enabled", "1", 
	"Is plugin enabled?", _, true, 0.0, true, 1.0)), OnEnabledChanged);
	Enabled = GetConVarBool(hRandom);
	SetAppend(appended);
	
	HookConVarChange((hRandom = AutoExecConfig_CreateConVar("sm_awlr_domination", "3", 
	"Number of wins a team must be ahead to have AWP limited for them", _, true, 1.0)), OnDominationChanged);
	dominationValue = GetConVarInt(hRandom);
	SetAppend(appended);
	
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	// Cleaning is an expensive operation and should be done at the end
	if (appended)
	{
		AutoExecConfig_CleanFile();
	}
	
	AutoExecConfig(true, "plugin.awp_win_limit");
}

public OnPluginEnd()
{
	#if _DEBUG
	Format(dmsg, sizeof(dmsg), "[OnPluginEnd] Resetting values for AWP: T=%i, CT=%i.", oldTvalue, oldCTvalue);
	DebugMessage(dmsg);
	#endif
	
	SetAWPRestrict(CS_TEAM_CT, oldCTvalue);
	SetAWPRestrict(CS_TEAM_T, oldTvalue);
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "weaponrestrict"))
	{
		Enabled = false;
		
		#if _DEBUG
		DebugMessage("[OnLibraryRemoved] Weapon Restrict plugin was unloaded, setting this plugin to DISABLED");
		#endif
	}
}

public OnConfigsExecuted()
{
	if (!LibraryExists("weaponrestrict"))
	{
		SetFailState("Cannot find required plugin, \"weaponrestrict\"");
	}
	else
	{
		#if _DEBUG
		DebugMessage("Weapon Restrict is running");
		#endif
	}
	
	oldCTvalue = Restrict_GetRestrictValue(CS_TEAM_CT, WEAPON_AWP);
	oldTvalue = Restrict_GetRestrictValue(CS_TEAM_T, WEAPON_AWP);
	
	#if _DEBUG
	Format(dmsg, sizeof(dmsg), "[OnConfigsExecuted] Weapon Restrict CVar values for AWP: T=%i, CT=%i.", oldTvalue, oldCTvalue);
	DebugMessage(dmsg);
	#endif
	
	if (AllowedGame[WEAPON_AWP] != 1)
	{
		SetFailState("The AWP [ID: %i] is not supported on your game", WEAPON_AWP);
	}
}

SetAppend(&appended)
{
	if (AutoExecConfig_GetAppendResult() == AUTOEXEC_APPEND_SUCCESS)
	{
		appended = true;
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (Enabled)
	{
		CheckRestrict();
	}
}

CheckRestrict()
{
	new team;
	
	if (!TeamIsDominating(dominationValue, team))
	{
		#if _DEBUG
		Format(dmsg, sizeof(dmsg), "[CheckRestrict] No team is dominating by %i.", dominationValue);
		DebugMessage(dmsg);
		#endif
		
		if (restrictedT)
		{
			SetAWPRestrict(CS_TEAM_T, oldTvalue);
		}
		if (restrictedCT)
		{
			SetAWPRestrict(CS_TEAM_CT, oldCTvalue);
		}
		
		restrictedCT = false;
		restrictedT = false;
		
		return;
	}
	
	if (team == CS_TEAM_T)
	{
		#if _DEBUG
		DebugMessage("[CheckRestrict] The Terrorists are dominating.");
		#endif
		
		if (!restrictedT)
		{
			SetAWPRestrict(team, 0);
		}
		restrictedT = true;
		
		if (restrictedCT)
		{
			SetAWPRestrict(CS_TEAM_CT, oldCTvalue);
		}
		restrictedCT = false;
	}
	else
	{
		#if _DEBUG
		DebugMessage("[CheckRestrict] The CTs are dominating.");
		#endif
		
		if (!restrictedCT)
		{
			SetAWPRestrict(team, 0);
		}
		restrictedCT = true;
		
		if (restrictedT)
		{
			SetAWPRestrict(CS_TEAM_T, oldTvalue);
		}
		restrictedT = false;
	}
}

SetAWPRestrict(team, value)
{
	#if _DEBUG
	Format(dmsg, sizeof(dmsg), "[SetAWPRestrict] Setting AWP limit for team [%i] to [%i].", team, value);
	DebugMessage(dmsg);
	#endif
	
	if (!Restrict_SetRestriction(WEAPON_AWP, team, value, true))
	{
		new String:sTeam[20];
		team == CS_TEAM_T ? Format(sTeam, sizeof(sTeam), "Terrorists") : Format(sTeam, sizeof(sTeam), "Counter Terrorists");
		LogError("Unable to set value for AWP [ID: %i] restriction for [%s] to value [%i]", WEAPON_AWP, sTeam, value);
	}
}

bool:TeamIsDominating(score, &winningTeam)
{
	new s_teamT = GetTeamScore(CS_TEAM_T);
	new s_teamCT = GetTeamScore(CS_TEAM_CT);
	
	#if _DEBUG
	Format(dmsg, sizeof(dmsg), "[TeamIsDominating] The scores are: T=%i, CT=%i.", s_teamT, s_teamCT);
	DebugMessage(dmsg);
	#endif
	
	if ((s_teamT - s_teamCT) >= score)
	{
		winningTeam = CS_TEAM_T;
		return true;
	}
	
	if ((s_teamCT - s_teamT) >= score)
	{
		winningTeam = CS_TEAM_CT;
		return true;
	}
	
	return false;
}

#if _DEBUG
DebugMessage(const String:msg[], any:...)
{
	LogMessage("%s", msg);
	PrintToChatAll("[AWLR Debug] %s", msg);
}
#endif

public OnVersionChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(newValue, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public OnEnabledChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Enabled = GetConVarBool(cvar);
	
	if (!Enabled)
	{
		SetAWPRestrict(CS_TEAM_CT, oldCTvalue);
		SetAWPRestrict(CS_TEAM_T, oldTvalue);
	}
}

public OnDominationChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	dominationValue = GetConVarInt(cvar);
}