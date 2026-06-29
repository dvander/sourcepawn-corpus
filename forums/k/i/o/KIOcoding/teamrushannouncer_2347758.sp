
#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdktools_functions>





int	CTs ;
int	Ts ;
int	equal ;
int	Roundstart ;
int	equals  ;
int	rush ;







public Plugin myinfo =
{
	name = "TeamRushAnnouncer",
	author = "kio",
	description = "Announces Team to Rush",
	version = "1.5",
	url = "http://kiocoding.weebly.com/"
}


public void OnPluginStart()
{
	
	HookEvent("round_start" , RoundStart , EventHookMode_PostNoCopy);
	HookEvent("player_death" , Event_PlayerDeath , EventHookMode_PostNoCopy );
	HookEvent("player_disconnect" , Event_PlayerDisconnect , EventHookMode_PostNoCopy );
	RegConsoleCmd("sm_rush", Command_SmRush, " Tell which Team should Rush");
	RegAdminCmd("sm_arush", Command_SmARush ,ADMFLAG_GENERIC );
	rush = 1 ;
}







public  RoundStart(Handle:event, const String:name[], bool:dontBroadcast )
{
		UpdatePlayerCounts()
		Ts = 0
		CTs = 0
		equal = 0
		CreateTimer(1.0 , UpdatePlayerCountsTimer)
		CreateTimer(300.0 , TimerCheckTeamsStart)
		Roundstart = 1
		equals = 0
		rush = 1
		

}




public Event_PlayerDeath (Handle:event, const String:name[], bool:dontBroadcast)
{	
	UpdatePlayerCounts()
}

public Event_PlayerDisconnect (Handle:event, const String:name[], bool:dontBroadcast)
{
	UpdatePlayerCounts()
}

public Action:TimerCheckTeamsStart(Handle:timer)
{
	CreateTimer(0.0 , LoopStart)
	Roundstart = 0
	CreateTimer(10.0 , TimerCheckTeams)
	CreateTimer(0.1, Rush)
	Ts = 0
	CTs = 0
}

public Action:LoopStart(Handle:timer)
{
	if (Roundstart == 0)
	{	
		CreateTimer(2.5 , TimerCheckTeams)
		CreateTimer(0.1 , LoopStart)
		
	}
}




public Action:Command_SmARush(client, args)
{
	CreateTimer(0.0 , ARUSH)
}

public Action:ARUSH(Handle:timer)
{
        if (Ts != CTs)
        {
                if  (Ts < CTs)
                {
                    PrintHintTextToAll("Counter-Terrorist Rush")
                    equals = 1
                }
                else if (Ts > CTs)
                {
                    PrintHintTextToAll("Terrorist Rush")
                    equals = 2
                }
        }
		else if (Ts == CTs)
		{
			if (equal == 1 && Roundstart == 0)
			{
				PrintHintTextToAll("Terrorist Rush")
			}
			else if (equal == 2 && Roundstart == 0)
			{
				PrintHintTextToAll("Counter-Terrorist Rush")
			}
			else if (equal == 0 && Roundstart == 0)
			{
				PrintHintTextToAll("Equal Teams ")
			}
	}
 
}


public Action:TimerCheckTeams(Handle:timer)
{
	if (Ts != CTs)
	{
		if  (Ts < CTs)
		{
			if (equals != 1)
			{
				PrintHintTextToAll("Counter-Terrorist Rush")
				equals = 1
			}
		}
		else if (Ts > CTs)
		{
			if (equals != 2)
			{
				PrintHintTextToAll("Terrorist Rush")
				equals = 2
			}
		}
	}

}



public Action:UpdatePlayerCountsTimer(Handle:timer)

{
	CreateTimer(0.1 , UpdatePlayerCountsTimer)
	UpdatePlayerCounts()
}




public Action:Command_SmRush(client, args)
{
	if (rush == 1)
	{
		CreateTimer(0.1, Rush)
	}
}

public Action:Rush(Handle:timer , client)
{
	if (Ts != CTs)
	{	
		if (Roundstart == 0)
		{
			CreateTimer(5.0 , RushOver)
			rush = 0
			if  (Ts < CTs)
			{
				PrintToChatAll("Counter-Terrorist Rush")	
			}
			else if (Ts > CTs)
			{
				PrintToChatAll("Terrorist Rush")
			}
		}
	}
	else if (Ts == CTs)
	{
		if (equal == 1 && Roundstart == 0)
		{
			PrintToChatAll("Terrorist Rush")
		}
		else if (equal == 2 && Roundstart == 0)
		{
			PrintToChatAll("Counter-Terrorist Rush")
		}
			else if (equal == 0 && Roundstart == 0)
		{
			PrintToChatAll("Equal Teams ")
		}
	}
}

public Action:RushOver(Handle:timer)
{
	rush = 1
}

UpdatePlayerCounts()
{
	Ts = 0
	CTs = 0
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			if (GetClientTeam(i) == 2)
			{
			
				Ts++


				
			}
			else if (GetClientTeam(i) == 3)
			{
				CTs++
				
			}
			
		}
	}
	{
		if (Ts != CTs)
		{
			if  (Ts < CTs)
				{
				equal = 2
				}
			else if (Ts > CTs)
				{
				equal = 1
				}
		}
	}

}

