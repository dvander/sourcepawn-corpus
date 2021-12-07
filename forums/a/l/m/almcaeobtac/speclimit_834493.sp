#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"
#define MAXSPECTATORS	5
#define MAXSPECTIME	300
#define DELAYAFTERSPEC	60

public Plugin:myinfo = 
{
	name = "Spectate Limit",
	author = "Alm",
	description = "Limits the number of spectators",
	version = PLUGIN_VERSION,
	url = ""
}

static SpecTime[65];
static SpecDelay[65];

public OnPluginStart()
{
	RegAdminCmd("sm_kickspec", KickSpec, ADMFLAG_KICK, "<name> kicks a spectator, putting them on a random team.");
	RegConsoleCmd("spectate", CheckSpec);
	RegConsoleCmd("jointeam", JoinTeam);
}

public OnClientPutInServer(Client)
{
	SpecTime[Client] = 0;
	SpecDelay[Client] = 0;
	CreateTimer(1.0, GameTick, Client);
}

public Action:GameTick(Handle:Timer, any:Client)
{
	decl Team;
	Team = GetClientTeam(Client);

	if(Team == 1)
	{
		if(SpecDelay[Client] == 1)
		{
			PrintToChat(Client, "[SM] You may spectate again.");
		}
		
		if(SpecDelay[Client] > 0)
		{
			SpecDelay[Client] -= 1;
		}

		if(SpecTime[Client] == 0)
		{
			PrintToChat(Client, "[SM] You have been a spectator for too long.");
			KickFromSpec(Client);
		}

		if(SpecTime[Client] > 0)
		{
			SpecTime[Client] -= 1;
		}
	}

	CreateTimer(1.0, GameTick, Client);
}

public CanSpec(Client)
{
	if(SpecDelay[Client] == 0)
	{
		return true;
	}
	else
	{
		return false;
	}
}

public KickFromSpec(Client)
{
	if(SpecTime[Client] != 0)
	{
		SpecTime[Client] = 0;
	}

	SpecDelay[Client] = DELAYAFTERSPEC;

	decl RandTeam;
	RandTeam = GetRandomInt(2,3);

	ChangeClientTeam(Client, RandTeam);
}

public Action:KickSpec(Client, Args)
{
	decl String:PlayerName[32];
	decl String:TestName[32];
	decl Team;
	decl Target;
	decl y;
	y = GetMaxClients();
	Target = -1;

	GetCmdArgString(PlayerName, 32);

	for(new x = 1; x <= y; x++)
	{
		if(IsClientConnected(x) && IsClientInGame(x) && Target == -1)
		{
			GetClientName(x, TestName, 32);
			
			if(StrContains(TestName, PlayerName, false) != -1)
			{
				Target = x;
				GetClientName(x, PlayerName, 32);
			}
		}
	}

	if(Target == -1)
	{
		PrintToConsole(Client, "[SM] %s was not found in-game.", PlayerName);
		return Plugin_Handled;
	}

	Team = GetClientTeam(Target);
	
	if(Team != 1)
	{
		PrintToConsole(Client, "[SM] %s is not spectating.", PlayerName);
		return Plugin_Handled;
	}

	PrintToChat(Target, "[SM] You have been kicked from spectating.");
	KickFromSpec(Target);

	PrintToConsole(Client, "[SM] You kick %s from spectating.", PlayerName);

	return Plugin_Handled;
}

public Action:JoinTeam(Client, Args)
{
	if(Client == 0)
	{
		return Plugin_Handled;
	}

	decl Choice;
	decl Team;
	decl String:TempStr[32];
	GetCmdArgString(TempStr, 32);
	Team = GetClientTeam(Client);
	
	Choice = StringToInt(TempStr);
	
	if(Choice != 1)
	{
		return Plugin_Continue;
	}

	if(Choice == 1 && Team == 1)
	{
		return Plugin_Handled;
	}

	if(!CanSpec(Client))
	{
		PrintToChat(Client, "[SM] Please wait before spectating again.");
		return Plugin_Handled;
	}

	if(SpecIsFull())
	{
		if(CanKick(Client))
		{
			if(!AllReserved())
			{
				KickRandomSpec();
				CreateTimer(1.0, CheckOnSpec, Client);
				return Plugin_Continue;
			}
		}
		
		PrintToChat(Client, "[SM] Too many people are already spectating.");
		return Plugin_Handled;
	}

	CreateTimer(1.0, CheckOnSpec, Client);

	return Plugin_Continue;
}

public KickRandomSpec()
{
	decl y;
	decl Team;
	decl Chance;
	y = GetMaxClients();
	decl Failed;
	Failed = 1;

	for(new x = 1; x <= y; x++)
	{
		if(IsClientConnected(x) && IsClientInGame(x) && Failed == 1)
		{
			Team = GetClientTeam(x);
			
			if(Team == 1)
			{
				Chance = GetRandomInt(1,y);
				if(Chance == x)
				{
					Failed = 0;
					PrintToChat(x, "[SM] You have been kicked from spectating.");
					KickFromSpec(x);
				}
			}
		}
	}

	if(Failed == 1)
	{
		KickRandomSpec();
	}
}

public CanKick(Client)
{
	if(GetUserFlagBits(Client)&ReadFlagString("a") > 0)
	{
		return true;
	}
	else
	{
		return false;
	}
}

public AllReserved()
{
	decl y;
	decl Team;
	decl FailCount;
	y = GetMaxClients();
	FailCount = 0;

	for(new x = 1; x <= y; x++)
	{
		if(IsClientConnected(x) && IsClientInGame(x))
		{
			Team = GetClientTeam(x);
			
			if(Team == 1 && GetUserFlagBits(x)&ReadFlagString("a") > 0)
			{
				FailCount += 1;
			}
		}
	}

	if(FailCount >= MAXSPECTATORS)
	{
		return true;
	}
	else
	{
		return false;
	}
}

public Action:CheckSpec(Client, Args)
{
	if(Client == 0)
	{
		return Plugin_Handled;
	}

	decl Team;
	Team = GetClientTeam(Client);
	
	if(Team == 1)
	{
		KickFromSpec(Client);
		return Plugin_Handled;
	}

	if(!CanSpec(Client))
	{
		PrintToChat(Client, "[SM] Please wait before spectating again.");
		return Plugin_Handled;
	}

	if(SpecIsFull())
	{
		if(CanKick(Client))
		{
			if(!AllReserved())
			{
				KickRandomSpec();
				CreateTimer(1.0, CheckOnSpec, Client);
				return Plugin_Continue;
			}
		}

		PrintToChat(Client, "[SM] Too many people are already spectating.");
		return Plugin_Handled;
	}

	CreateTimer(1.0, CheckOnSpec, Client);

	return Plugin_Continue;
}

public Action:CheckOnSpec(Handle:Timer, any:Client)
{
	decl Team;
	Team = GetClientTeam(Client);

	if(Team == 1)
	{
		SpecTime[Client] = MAXSPECTIME;
	}

	return Plugin_Handled;
}

public SpecIsFull()
{
	decl y;
	decl Team;
	decl SpecCount;
	y = GetMaxClients();
	SpecCount = 0;

	for(new x = 1; x <= y; x++)
	{
		if(IsClientConnected(x) && IsClientInGame(x))
		{
			Team = GetClientTeam(x);
			
			if(Team == 1)
			{
				SpecCount += 1;
			}
		}
	}

	if(SpecCount >= MAXSPECTATORS)
	{
		return true;
	}
	else
	{
		return false;
	}
}