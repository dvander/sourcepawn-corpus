#include <sourcemod>
#include <sdktools>
#include <restrict>
#include <cstrike_weapons>

#pragma semicolon 1

new bool:restrictedT;
new bool:restrictedCT;

public OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	CheckRestrict();
}

CheckRestrict()
{
	new team;
	new WeaponID:id = GetWeaponID("awp");
	
	if (AllowedGame[WeaponID:id] != 1)
	{
		LogError("This weapon [awp] [ID: %i] is not supported on your game", WeaponID:id);
		return;
	}
	
	if (!TeamIsDominating(3, team))
	{
		if (restrictedT && !Restrict_SetRestriction(WeaponID:id, 2, -1, true))
		{
			LogError("Unable to unrestrict awp [ID: %i] for Terrorist", WeaponID:id);
		}
		if (restrictedCT && !Restrict_SetRestriction(WeaponID:id, 3, -1, true))
		{
			LogError("Unable to unrestrict awp [ID: %i] for Terrorist", WeaponID:id);
		}
		
		restrictedCT = false;
		restrictedT = false;
		
		return;
	}
	
	new String:teamName[30];	
	
	if (team == 2)
	{
		Format(teamName, sizeof(teamName), "Terrorist");
		
		if (!restrictedT && !Restrict_SetRestriction(WeaponID:id, team, 0, true))
		{
			LogError("Unable to restrict awp [ID: %i] for %s", WeaponID:id, teamName);
		}
		restrictedT = true;
		
		if (restrictedCT && !Restrict_SetRestriction(WeaponID:id, 3, -1, true))
		{
			LogError("Unable to unrestrict awp [ID: %i] for CTs", WeaponID:id);
		}
		restrictedCT = false;
	}
	else
	{
		Format(teamName, sizeof(teamName), "CT");
		
		if (!restrictedCT && !Restrict_SetRestriction(WeaponID:id, team, 0, true))
		{
			LogError("Unable to restrict awp [ID: %i] for %s", WeaponID:id, teamName);
		}
		restrictedCT = true;
		
		if (restrictedT && !Restrict_SetRestriction(WeaponID:id, 2, -1, true))
		{
			LogError("Unable to unrestrict awp [ID: %i] for Terrorist", WeaponID:id);
		}
		restrictedT = false;
	}
}

bool:TeamIsDominating(score, &winningTeam)
{
	new s_teamT = GetTeamScore(CS_TEAM_T);
	new s_teamCT = GetTeamScore(CS_TEAM_CT);
	
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