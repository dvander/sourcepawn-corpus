#include <sourcemod>
#include <sdktools>

new Handle:AdminOnly = INVALID_HANDLE;

static Float:SpawnPoint[65][3];
static bool:SpawnSet[65];

public Plugin:myinfo = 
{
	name = "Custom Spawn",
	author = "Alm",
	description = "Players set a custom spawnpoint for themself.",
	version = "1.2",
	url = "http://www.loners-gaming.com/ && http://www.iwuclan.com/"
}

public OnPluginStart()
{
	AdminOnly = CreateConVar("playerspawn_adminonly", "0", "Toggles Admin Only spawn saving.", FCVAR_PLUGIN);
	RegConsoleCmd("sm_setspawn", SetSpawn);
	RegConsoleCmd("sm_clearspawn", ClearSpawn);

	HookEvent("player_spawn", PlayerSpawn);
}

public OnClientPutInServer(Client)
{
	SpawnPoint[Client][0] = 0.0;
	SpawnPoint[Client][1] = 0.0;
	SpawnPoint[Client][2] = 0.0;
	SpawnSet[Client] = false;
}

public Action:SetSpawn(Client, Args)
{
	if(Client == 0)
	{
		return Plugin_Handled;
	}

	new AdminId:id = GetUserAdmin(Client);

	if(GetConVarBool(AdminOnly) && id == INVALID_ADMIN_ID)
	{
		PrintToChat(Client, "[SM] You cannot do this now.");
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(Client))
	{
		PrintToChat(Client, "[SM] You must be alive to set a spawn location.");
		return Plugin_Handled;
	}

	decl Float:Location[3];

	GetClientAbsOrigin(Client, Location);

	SpawnPoint[Client][0] = Location[0];
	SpawnPoint[Client][1] = Location[1];
	SpawnPoint[Client][2] = Location[2];

	SpawnSet[Client] = true;

	PrintToChat(Client, "[SM] Spawn location set.");

	return Plugin_Handled;
}

public Action:ClearSpawn(Client, Args)
{
	if(Args == 0)
	{
		if(Client == 0)
		{
			return Plugin_Handled;
		}

		if(!SpawnSet[Client])
		{
			PrintToChat(Client, "[SM] No spawn location set.");
			return Plugin_Handled;
		}

		SpawnSet[Client] = false;

		PrintToChat(Client, "[SM] Spawn location cleared.");
		
		return Plugin_Handled;
	}
	else
	{
		decl bool:IsAdmin;

		if(Client == 0)
		{
			IsAdmin = true;
		}
		else
		{
			new AdminId:id = GetUserAdmin(Client);
			if(id == INVALID_ADMIN_ID)
			{
				IsAdmin = false;
			}
			else
			{
				IsAdmin = true;
			}
		}

		if(!IsAdmin)
		{
			PrintToChat(Client, "[SM] You do not have access to this command.");
			return Plugin_Handled;
		}

		decl String:TypedName[32];
		decl String:TestName[32];
		decl String:TargetName[32];
		decl String:AdminName[32];

		decl Possibles;
		Possibles = 0;

		decl Target;
		Target = -1;

		GetCmdArgString(TypedName, 32);
		StripQuotes(TypedName);
		TrimString(TypedName);

		for(new Player = 1; Player <= GetMaxClients(); Player++)
		{
			if(IsClientInGame(Player))
			{
				GetClientName(Player, TestName, 32);
					

				if(StrContains(TestName, TypedName, false) != -1)
				{
					Target = Player;
					Possibles += 1;
				}
			}
		}

		if(Target == -1)
		{
			if(Client == 0)
			{
				PrintToConsole(Client, "[SM] %s is not ingame.", TypedName);
			}
			else
			{
				PrintToChat(Client, "[SM] %s is not ingame.", TypedName);
			}
			
			return Plugin_Handled;
		}

		if(Possibles > 1)
		{
			if(Client == 0)
			{
				PrintToConsole(Client, "[SM] Multiple targets found.");
			}
			else
			{
				PrintToChat(Client, "[SM] Multiple targets found.");
			}
			
			return Plugin_Handled;
		}

		GetClientName(Target, TargetName, 32);
		
		if(Client == 0)
		{
			AdminName = "The Console";
		}
		else
		{
			GetClientName(Client, AdminName, 32);
		}

		if(!SpawnSet[Target])
		{
			if(Client == 0)
			{
				PrintToConsole(Client, "[SM] %s does not have a spawn location set.", TargetName);
			}
			else
			{
				PrintToChat(Client, "[SM] %s does not have a spawn location set.", TargetName);
			}
			
			return Plugin_Handled;
		}

		SpawnSet[Target] = false;

		PrintToChat(Target, "[SM] %s cleared your spawn location.", AdminName);
		
		if(Client == 0)
		{
			PrintToConsole(Client, "[SM] You cleared the spawn location of %s.", TargetName);
		}
		else
		{
			PrintToChat(Client, "[SM] You cleared the spawn location of %s.", TargetName);
		}

		return Plugin_Handled;
	}
}

public PlayerSpawn(Handle:Event, const String:Name[], bool:Broadcast)
{
	decl Client;
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));

	new AdminId:id = GetUserAdmin(Client);

	if(GetConVarBool(AdminOnly) && id == INVALID_ADMIN_ID)
	{
		return;
	}

	if(SpawnSet[Client])
	{
		TeleportEntity(Client, SpawnPoint[Client], NULL_VECTOR, NULL_VECTOR);
	}
}