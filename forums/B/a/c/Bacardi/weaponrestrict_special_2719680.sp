
#include <cstrike>
#include <sdktools>
#include <restrict>

/*

public void OnPluginStart()
{
	RegConsoleCmd("sm_test", test);
}

public Action test(int client, int args)
{
	PrintToServer("Restrict_GetTeamWeaponCount(int team, CSWeaponID id); %i", Restrict_GetTeamWeaponCount(GetClientTeam(client), CSWeapon_AWP));
	PrintToServer("Restrict_GetRestrictValue(int team, CSWeaponID id); %i", Restrict_GetRestrictValue(GetClientTeam(client), CSWeapon_AWP));
	return Plugin_Handled;
}
*/


public Action Restrict_OnCanBuyWeapon(int client, int team, CSWeaponID id, CanBuyResult &result)
{
	// skip these rounds
	if(Restrict_IsWarmupRound() || Restrict_IsSpecialRound())
	{
		return Plugin_Continue;
	}

	// no awp, can buy, admin immunity (sm_restrict_immunity_level) works on this client -> skip
	if(id != CSWeapon_AWP || result == CanBuy_Allow || Restrict_ImmunityCheck(client))
	{
		return Plugin_Continue;
	}


	// when can't buy awp

	result = CanBuy_Allow;

	return AllowAWP(client, team) ? Plugin_Changed:Plugin_Continue;
}

public Action Restrict_OnCanPickupWeapon(int client, int team, CSWeaponID id, bool &result)
{
	// skip
	if(Restrict_IsWarmupRound() || Restrict_IsSpecialRound())
	{
		return Plugin_Continue;
	}

	// no awp, can pick, admin immunity works on this client -> skip
	if(id != CSWeapon_AWP || result || Restrict_ImmunityCheck(client))
	{
		return Plugin_Continue;
	}



	// when can't buy awp

	result = true;

	return AllowAWP(client, team) ? Plugin_Changed:Plugin_Continue;
}

bool AllowAWP(int client, int team)
{
	int awp_count[] = {0,0};

	int entity;
	char clsname[30];


	// count awp's
	for(int i = 1; i <= MaxClients; i++)
	{
		// not in game, not in same team, dead, have admin immunity (sm_restrict_immunity_level)
		if(!IsClientInGame(i) || GetClientTeam(i) != team || !IsPlayerAlive(i) || Restrict_ImmunityCheck(i)) continue;

		entity = GetPlayerWeaponSlot(i, CS_SLOT_PRIMARY);

		if(entity == -1) continue;
		
		GetEntityClassname(entity, clsname, sizeof(clsname));
		CS_GetTranslatedWeaponAlias(clsname, clsname, sizeof(clsname));

		if(CS_AliasToWeaponID(clsname) == CSWeapon_AWP)
		{
			!CheckCommandAccess(i, "sm_vip", ADMFLAG_RESERVATION) ? awp_count[0]++:awp_count[1]++;
		}
	}

	// Is client "vip" or normal player
	if(CheckCommandAccess(client, "sm_vip", ADMFLAG_RESERVATION))
	{
		// no "vip's" with awp
		if(awp_count[1] == 0)
		{
			return true;
		}
	}
	else
	{
		
		if(Restrict_GetRestrictValue(team, CSWeapon_AWP) > awp_count[0])
		{
			return true;
		}
	}
	
	return false;
}