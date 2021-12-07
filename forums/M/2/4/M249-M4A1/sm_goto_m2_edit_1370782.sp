#include <sourcemod>
#include <sdktools> 
#include "dbi.inc"

// Edited by M249-M4A1-[KM]- KM++
// -features added: sm_bring @blue/@red/@all
// -also added team index getter (for references) "sm_getteamindex <name>"
// credit goes to HyperKiLLeR for original plugin which I added some features to
// note: my additions were poorly written, but work -- feel free to clean up/improve

public Plugin:myinfo =
{
	name = "Player-Teleport by Dr. HyperKiLLeR",
	author = "Dr. HyperKiLLeR (edited by M249-M4A1-[KM]- KM++)",
	description = "Go to a player or teleport a player to you",
	version = "1.2.0.0",
	url = ""
};
 
//Plugin-Start
public OnPluginStart()
{
	RegAdminCmd("sm_getteamindex", Command_Team, ADMFLAG_SLAY,"Get Team Index");
	RegAdminCmd("sm_goto", Command_Goto, ADMFLAG_SLAY,"Go to a player");
	RegAdminCmd("sm_bring", Command_Bring, ADMFLAG_SLAY,"Teleport a player to you");

	CreateConVar("goto_version", "1.3", "Dr. HyperKiLLeRs Player Teleport (M249-M4A1-[KM]- KM++'s Edit)",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
}

public Action:Command_Goto(Client,args)
{
    //Error:
	if(args < 1)
	{

		//Print:
		PrintToConsole(Client, "Usage: sm_goto <name>");
		PrintToChat(Client, "Usage:\x04 sm_goto <name>");

		//Return:
		return Plugin_Handled;
	}
	
	//Declare:
	decl MaxPlayers, Player;
	decl String:PlayerName[32];
	new Float:TeleportOrigin[3];
	new Float:PlayerOrigin[3];
	decl String:Name[32];
	
	//Initialize:
	Player = -1;
	GetCmdArg(1, PlayerName, sizeof(PlayerName));
	
	//Find:
	MaxPlayers = GetMaxClients();
	for(new X = 1; X <= MaxPlayers; X++)
	{

		//Connected:
		if(!IsClientConnected(X)) continue;

		//Initialize:
		GetClientName(X, Name, sizeof(Name));

		//Save:
		if(StrContains(Name, PlayerName, false) != -1) Player = X;
	}
	
	//Invalid Name:
	if(Player == -1)
	{

		//Print:
		PrintToConsole(Client, "Could not find client \x04%s", PlayerName);

		//Return:
		return Plugin_Handled;
	}
	
	//Initialize
	GetClientName(Player, Name, sizeof(Name));
	GetClientAbsOrigin(Player, PlayerOrigin);
	
	//Math
	TeleportOrigin[0] = PlayerOrigin[0];
	TeleportOrigin[1] = PlayerOrigin[1];
	TeleportOrigin[2] = (PlayerOrigin[2] + 73);
	
	//Teleport
	TeleportEntity(Client, TeleportOrigin, NULL_VECTOR, NULL_VECTOR);
	
	return Plugin_Handled;
}

public Action:Command_Team(Client,args)
{
	if(args < 1)
	{

		//Print:
		PrintToConsole(Client, "Usage: sm_getteamindex <name>");
		PrintToChat(Client, "Usage:\x04 sm_getteamindex <name>");

		//Return:
		return Plugin_Handled;
	}

	decl TeamIndex;
	decl MaxPlayers, Player;
	decl String:target[32];
	decl String:PlayerName[32];
	decl String:TargetName[32];

	GetCmdArg(1, PlayerName, sizeof(PlayerName));
	
	Player = -1;
	TeamIndex = -1;
	MaxPlayers = GetMaxClients();

	for (new i = 1; i < MaxPlayers; i++)
	{
		//Connected:
		if(!IsClientConnected(i)) continue;

		//Initialize:
		GetClientName(i, target, sizeof(target));

		//Save:
		if(StrContains(target, PlayerName, false) != -1) Player = i;
	}

	if (Player == -1)
	{
		PrintToChat(Client, "No such client.");
		return Plugin_Handled;
	}

	GetClientName(Player, TargetName, sizeof(TargetName));

	TeamIndex = GetClientTeam(Player);
	PrintToChat(Client, "Team Index of Player (%s): %i", TargetName, TeamIndex);

	return Plugin_Handled;
}

public Action:Command_Bring(Client,args)
{
    //Error:
	if(args < 1)
	{

		//Print:
		PrintToConsole(Client, "Usage: sm_bring <name|@blue|@red|@all>");
		PrintToChat(Client, "Usage:\x04 sm_bring <name|@blue|@red|@all>");

		//Return:
		return Plugin_Handled;
	}
	
	//Declare:
	decl MaxPlayers, Player, Team;
	decl String:PlayerName[32];
	new Float:TeleportOrigin[3];
	new Float:PlayerOrigin[3];
	decl String:Name[32];
	decl TeamNum;
	decl String:CallerName[32];
	
	//Initialize:
	Player = -1;
	TeamNum = 0;
	Team = 0;
	GetCmdArg(1, PlayerName, sizeof(PlayerName));

	GetClientName(Client, CallerName, sizeof(CallerName));

	// Find out if they are on a team
	if (StrEqual("@red", PlayerName))
	{
		Team = 2;
	}

	else if (StrEqual("@blue", PlayerName))
	{
		Team = 3;
	}
	else if (StrEqual("@all", PlayerName))
	{
		Team = 6291;
	}
	
	if (Team == 0)
	{
		//Find:
		MaxPlayers = GetMaxClients();
		for(new X = 1; X <= MaxPlayers; X++)
		{

			//Connected:
			if(!IsClientConnected(X)) continue;

			//Initialize:
			GetClientName(X, Name, sizeof(Name));

			//Save:
			if(StrContains(Name, PlayerName, false) != -1) Player = X;
		}
	
		//Invalid Name:
		if(Player == -1)
		{

			//Print:
			PrintToConsole(Client, "Could not find client \x04%s", PlayerName);

			//Return:
			return Plugin_Handled;
		}
	
		//Initialize
		GetClientName(Player, Name, sizeof(Name));
		GetCollisionPoint(Client, PlayerOrigin);
	
		//Math
		TeleportOrigin[0] = PlayerOrigin[0];
		TeleportOrigin[1] = PlayerOrigin[1];
		TeleportOrigin[2] = (PlayerOrigin[2] + 4);
	
		//Teleport
		TeleportEntity(Player, TeleportOrigin, NULL_VECTOR, NULL_VECTOR);

	} else if (Team == 3)
	
	{ // Blue Team

		MaxPlayers = GetMaxClients();
		for (new X = 1; X <= MaxPlayers; X++)
		{

			//Connected:
			if(!IsClientConnected(X)) continue;

			//Initialize:
			TeamNum = GetClientTeam(X);

			if (TeamNum == Team) {

				Player = X;

				//Initialize
				GetClientName(Player, Name, sizeof(Name));
				GetCollisionPoint(Client, PlayerOrigin);
	
				if (!StrEqual(Name, CallerName))
				{

	
					//Math
					TeleportOrigin[0] = PlayerOrigin[0];
					TeleportOrigin[1] = PlayerOrigin[1];
					TeleportOrigin[2] = (PlayerOrigin[2] + 4);
	
					//Teleport
					TeleportEntity(Player, TeleportOrigin, NULL_VECTOR, NULL_VECTOR);
				}
			}
		}

	} else if (Team == 2) { // Red

		MaxPlayers = GetMaxClients();
		for (new X = 1; X <= MaxPlayers; X++)
		{

			//Connected:
			if(!IsClientConnected(X)) continue;

			//Initialize:
			TeamNum = GetClientTeam(X);

			if (TeamNum == Team) {

				Player = X;

				//Initialize
				GetClientName(Player, Name, sizeof(Name));
				GetCollisionPoint(Client, PlayerOrigin);

				if (!StrEqual(Name, CallerName))
				{

	
					//Math
					TeleportOrigin[0] = PlayerOrigin[0];
					TeleportOrigin[1] = PlayerOrigin[1];
					TeleportOrigin[2] = (PlayerOrigin[2] + 4);
	
					//Teleport
					TeleportEntity(Player, TeleportOrigin, NULL_VECTOR, NULL_VECTOR);
				}

			}
		}

	} else if (Team == 6291) { // All

		MaxPlayers = GetMaxClients();
		for (new X = 1; X <= MaxPlayers; X++)
		{

			//Connected:
			if(!IsClientConnected(X)) continue;

			Player = X;

			//Initialize
			GetClientName(Player, Name, sizeof(Name));

			if (!StrEqual(Name, CallerName))
			{

				GetCollisionPoint(Client, PlayerOrigin);
	
				//Math
				TeleportOrigin[0] = PlayerOrigin[0];
				TeleportOrigin[1] = PlayerOrigin[1];
				TeleportOrigin[2] = (PlayerOrigin[2] + 4);
	
				//Teleport
				TeleportEntity(Player, TeleportOrigin, NULL_VECTOR, NULL_VECTOR);
			}
		}

	} else if (Team == 1) {

		PrintToChat(Client, "Can't teleport the Spectators!");
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

// Trace

stock GetCollisionPoint(client, Float:pos[3])
{
	decl Float:vOrigin[3], Float:vAngles[3];
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		
		return;
	}
	
	CloseHandle(trace);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > MaxClients;
}  

