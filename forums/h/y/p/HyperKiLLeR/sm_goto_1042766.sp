#include <sourcemod>
#include <sdktools> 
#include "dbi.inc"




public Plugin:myinfo =
{
	name = "Player-Teleport by Dr. HyperKiLLeR",
	author = "Dr. HyperKiLLeR",
	description = "Go to a player or teleport a player to you",
	version = "1.2.0.0",
	url = ""
};
 
//Plugin-Start
public OnPluginStart()
{
	RegAdminCmd("sm_goto", Command_Goto, ADMFLAG_SLAY,"Go to a player");
	RegAdminCmd("sm_bring", Command_Bring, ADMFLAG_SLAY,"Teleport a player to you");

	CreateConVar("goto_version", "1.2", "Dr. HyperKiLLeRs Player Teleport",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
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

public Action:Command_Bring(Client,args)
{
    //Error:
	if(args < 1)
	{

		//Print:
		PrintToConsole(Client, "Usage: sm_bring <name>");
		PrintToChat(Client, "Usage:\x04 sm_bring <name>");

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
	GetCollisionPoint(Client, PlayerOrigin);
	
	//Math
	TeleportOrigin[0] = PlayerOrigin[0];
	TeleportOrigin[1] = PlayerOrigin[1];
	TeleportOrigin[2] = (PlayerOrigin[2] + 4);
	
	//Teleport
	TeleportEntity(Player, TeleportOrigin, NULL_VECTOR, NULL_VECTOR);
	
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

