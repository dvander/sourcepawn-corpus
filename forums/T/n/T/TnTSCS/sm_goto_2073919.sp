#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Player-Teleport by Dr. HyperKiLLeR",
	author = "Dr. HyperKiLLeR",
	description = "Go to a player or teleport a player to you",
	version = "1.2.0.1",
	url = ""
};
 
//Plugin-Start
public OnPluginStart()
{
	RegAdminCmd("sm_goto", Command_Goto, ADMFLAG_SLAY,"Go to a player");
	RegAdminCmd("sm_bring", Command_Bring, ADMFLAG_SLAY,"Teleport a player to you");

	CreateConVar("goto_version", "1.2", "Dr. HyperKiLLeRs Player Teleport",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	LoadTranslations("common.phrases");
}

public Action:Command_Goto(Client,args)
{
    //Error:
	if(args < 1)
	{
		//Print:
		ReplyToCommand(Client, "Usage: sm_goto <name>");
		
		//Return:
		return Plugin_Handled;
	}
	
	new Player, String:target_name[MAX_NAME_LENGTH];
	
	GetCmdArg(1, target_name, sizeof(target_name));
	
	if ((Player = FindTarget(Client, target_name, false, true)) <= 0)
	{
		// Error, couldn't find name
		ReplyToCommand(Client, "Unable to find player matching [%s]", target_name);
		return Plugin_Handled;
	}
	
	//Declare:
	new Float:TeleportOrigin[3];
	new Float:PlayerOrigin[3];
	
	//Initialize
	GetClientAbsOrigin(Player, PlayerOrigin);
	
	//Math
	TeleportOrigin[0] = PlayerOrigin[0];
	TeleportOrigin[1] = PlayerOrigin[1];
	TeleportOrigin[2] = (PlayerOrigin[2] + 73);
	
	//Teleport
	TeleportEntity(Client, TeleportOrigin, NULL_VECTOR, NULL_VECTOR);
	
	ShowActivity2(Client, "[SM] ", "Teleported to %N's location", Player);
	
	return Plugin_Handled;
}

public Action:Command_Bring(Client,args)
{
    //Error:
	if(args < 1)
	{
		//Print:
		ReplyToCommand(Client, "Usage: sm_bring <name>");
		
		//Return:
		return Plugin_Handled;
	}
	
	//Declare:
	new Float:TeleportOrigin[3];
	new Float:PlayerOrigin[3];
	
	new Player, String:target_name[MAX_NAME_LENGTH];
	
	GetCmdArg(1, target_name, sizeof(target_name));
	
	if ((Player = FindTarget(Client, target_name, false, true)) <= 0)
	{
		// Error, couldn't find name
		ReplyToCommand(Client, "Unable to find player matching [%s]", target_name);
		return Plugin_Handled;
	}
	
	//Initialize
	GetCollisionPoint(Client, PlayerOrigin);
	
	//Math
	TeleportOrigin[0] = PlayerOrigin[0];
	TeleportOrigin[1] = PlayerOrigin[1];
	TeleportOrigin[2] = (PlayerOrigin[2] + 4);
	
	//Teleport
	TeleportEntity(Player, TeleportOrigin, NULL_VECTOR, NULL_VECTOR);
	
	ShowActivity2(Client, "[SM] ", "Teleported %N", Player);
	
	return Plugin_Handled;
}

// Trace

GetCollisionPoint(client, Float:pos[3])
{
	new Float:vOrigin[3], Float:vAngles[3];
	
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

