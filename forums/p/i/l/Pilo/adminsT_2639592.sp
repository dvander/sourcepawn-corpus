#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PREFIX "[SM]"

public Plugin myinfo = 
{
	name = "Admins T Clients CT",
	author = "Pilo",
	description = "Move all the normal players to CT and Admins/Vip's to T'",
	version = "1.0",
	url = "https://forums.gamers-israel.co.il/member.php?u=33"
};

public void OnPluginStart()
{	
	RegAdminCmd("sm_event", Command_Event, ADMFLAG_GENERIC, "");
}

public Action Command_Event (int client, int args)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) != CS_TEAM_CT && !CheckCommandAccess(i, "sm_null_command", ADMFLAG_RESERVATION, true))
		{
			CS_SwitchTeam(i, CS_TEAM_T)
		}
		
		else
		
		{
			CS_SwitchTeam(i, CS_TEAM_CT);
		}
	}
	
	{
		PrintToChatAll("%s \x02%N \x01 moved all players to CT and Admins to T! \x05Have Fun! \x01", PREFIX, client);
	}
}