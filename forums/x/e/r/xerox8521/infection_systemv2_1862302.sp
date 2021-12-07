#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

#define MAXZPSPLAYERS 24

#define VERSION "1.4"

public Plugin myinfo = 
{
	name = "Infection System for ZPS",
	author = "XeroX",
	description = "This Plugin allows Admins to infect or cure players in Zombie Panic Source",
	version = VERSION,
	url = "http://soldiersofdemise.com"
}

public void OnPluginStart()
{
	CreateConVar("sm_infection_system_version",VERSION,"Version of the Infection System Plugin",FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_infect",CommandInfect,ADMFLAG_CHEATS);
	RegAdminCmd("sm_cure",CommandCure,ADMFLAG_CHEATS);
	RegAdminCmd("sm_check",CommandCheck,ADMFLAG_CHEATS);
	RegAdminCmd("sm_infis",CommandInfis,ADMFLAG_CHEATS);
}


public Action CommandInfect(int client, int args)
{
	if(args < 2)
	{
		PrintToChat(client,"[SM]: Usage: sm_infect <#userid|name> time (in seconds)");
		return Plugin_Handled;
	}
	else
	{
		char arg1[32], arg2[32];
		GetCmdArg(1,arg1,sizeof(arg1));
		int target = FindTarget(client,arg1,true,true);
		if(target == -1)
		{
			return Plugin_Handled;
		}
		else
		{
			GetCmdArg(2,arg2,sizeof(arg2));
			float turnTime = StringToFloat(arg2);
			SetEntProp(client,Prop_Send,"m_IsInfected",1);
			SetEntPropFloat(client,Prop_Data,"m_tbiPrev",(GetGameTime() + turnTime));
			PrintToChat(client,"[SM]: Infecting %N will turn in %0.0f seconds",target,turnTime);
		}
	}
	return Plugin_Handled;
}

public Action CommandCure(int client, int args)
{
	if(args < 1)
	{
		PrintToChat(client,"[SM] Usage: sm_cure <#userid|name>");
		return Plugin_Handled;
	}
	char arg1[32];
	GetCmdArg(1,arg1,sizeof(arg1));
	int target = FindTarget(client,arg1,true,true);
	if(target == -1)
	{
		return Plugin_Handled;
	}
	else
	{
		PrintToChat(client,"[SM]: Curing %N",target);
		SetEntProp(client,Prop_Send,"m_IsInfected",0);
	}
	return Plugin_Handled;
}

public Action CommandCheck(int client, int args)
{
	if(args < 1)
	{
		PrintToChat(client,"[SM] Usage: sm_check <#userid|name>");
		return Plugin_Handled;
	}
	else
	{
		char arg1[32];
		GetCmdArg(1,arg1,sizeof(arg1));
		int target = FindTarget(client,arg1,true,true);
		if(target == -1)
		{
			return Plugin_Handled;
		}
		else
		{
			if(GetEntProp(client,Prop_Send,"m_IsInfected") == 1)
			{
				PrintToChat(client,"%N is infected and turning in %d seconds",target,(RoundToFloor(GetEntPropFloat(target,Prop_Data,"m_tbiPrev") - GetGameTime())));
			}
			else
			{
				PrintToChat(client,"%N is not infected",target);
			}
		}
	}
	return Plugin_Handled;
}

public Action CommandInfis(int client, int args)
{
    for (int i = 1; i < MAXZPSPLAYERS+1; i++)
    if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
    {
        if(GetEntProp(i,Prop_Send,"m_IsInfected") == 1)
        {
			PrintToChat(client, "[SM] %N is Infected, Turning in %d Seconds!", i, (RoundToFloor(GetEntPropFloat(i,Prop_Data,"m_tbiPrev") - GetGameTime())));
        }
    }
    return Plugin_Handled;
}
