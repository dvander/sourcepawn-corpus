#pragma semicolon 1
#pragma newdecls required

#include <cstrike>
#include <sdktools_functions>

static const char CHAT_TAG[] = "\x02★\x01 ";

public Plugin myinfo =
{
	name		= "Team balance by Divin",
	author		= "Divin",
	description	= "A simple Team Balance Plugin",
	version		= "1.0.0",
	url			= "wtfcs.com/forum"
};

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO) SetFailState("Plugin supports CS:GO only.");
	
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	int alivect[65], deadct[65], alivet[65], deadt[65];
	int r=1;
	bool ok = false;
	int t = GetTeamClientCount(CS_TEAM_T);
	int j = GetTeamClientCount(CS_TEAM_CT);
	if( t==j || t+1==j || t==j+1)
	{
		PrintToChatAll("%s\x04Teams are balanced!",CHAT_TAG);
		return;
	}
	else if(t>j)
	{
		for(int x = 1; x <= MaxClients; x++)
		{
			if(IsClientInGame(x) && GetClientTeam(x) == 2)
			{
				if(IsPlayerAlive(x))
					alivet[x] = 1;
				else deadt[x] = 2;
			}		
		}
		while(GetTeamClientCount(CS_TEAM_T) > GetTeamClientCount(CS_TEAM_CT)+1)
		{	
			ok = true;
			for(int x = r; x <= MaxClients; x++)
			{
				if(deadt[x] == 2 && ok == true)
				{
					CS_SwitchTeam(x, 3);
					PrintToChatAll("%s\x01Moved \x04%N \x01from \02Terrorist \x01to \x0BCounter-Terrorist", CHAT_TAG, x);
					deadt[x] = 0;
					ok = false;			
				}
				else if(alivet[x] == 1 && ok == true)
				{
					CS_SwitchTeam(x, 3);
					PrintToChatAll("%s\x01Moved \x04%N \x01from \02Terrorist \x01to \x0BCounter-Terrorist", CHAT_TAG, x);
					alivet[x] = 0;
					ok = false;			
				}
			}
			r++;
		}

	}
	else if(t<j)
	{
		for(int x = 1; x <= MaxClients; x++)
		{
			if(IsClientInGame(x) && GetClientTeam(x) == 3)
			{
				if(IsPlayerAlive(x))
					alivect[x] = 1;
				else deadct[x] = 2;
			}
		}
		while(GetTeamClientCount(CS_TEAM_T) < GetTeamClientCount(CS_TEAM_CT)+1)
		{	
			ok = true;
			for(int x = r; x <= MaxClients; x++)
			{
				if(deadct[x] == 2 && ok == true)
				{
					CS_SwitchTeam(x, 2);
					PrintToChatAll("%s\x01Moved \x04%N \x01from \x0BCounter-Terrorist \x01to \02Terrorist", CHAT_TAG, x);
					deadct[x] = 0;
					ok = false;			
				}
				else if(alivect[x] == 1 && ok == true)
				{
					CS_SwitchTeam(x, 2);
					PrintToChatAll("%s\x01Moved \x04%N \x01from \x0BCounter-Terrorist \x01to \02Terrorist", CHAT_TAG, x);
					alivect[x] = 0;
					ok = false;			
				}
			}
			r++;
		}
	}

}