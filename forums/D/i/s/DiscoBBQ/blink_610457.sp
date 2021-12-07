//Blink v1.1 by Pinkfairie

//Termination:
#pragma semicolon 1

//Includes:
#include <sourcemod>
#include <sdktools>

//Definitions:
#define	CLIENTWIDTH	35.0
#define	CLIENTHEIGHT	90.0

//SM_Blink:
public Action:Command_Blink(Client, Arguments)
{

	//Player:
	new Player;

	//Default:
	if(Arguments < 1) Player = Client;
	
	//Player:
	else
	{

		//Retrieve Arguments:
		decl MaxClients;
		decl String:ArgumentName[32], String:PlayerName[32];

		//Initialize:
		MaxClients = GetMaxClients();
		GetCmdArg(1, ArgumentName, sizeof(ArgumentName));

		//Find:
		for(new X = 1; X <= MaxClients; X++)
		{

			//Invalid:
			if(!IsClientConnected(X)) continue;

			//Initialize:
			GetClientName(X, PlayerName, sizeof(PlayerName));

			//Compare:
			if(StrContains(PlayerName, ArgumentName, false) != -1) Player = X;
		}

	}

	//Declare:
	decl Handle:TraceRay;
	decl Float:StartOrigin[3], Float:Angles[3];

	//Initialize:
	GetClientEyeAngles(Client, Angles);
	GetClientEyePosition(Client, StartOrigin);

	//Ray:
	TraceRay = TR_TraceRayEx(StartOrigin, Angles, MASK_SHOT, RayType_Infinite);

	//Collision:
	if(TR_DidHit(TraceRay))
	{

		//Declare:
		decl Float:Distance;
		decl Float:PositionBuffer[3], Float:EndOrigin[3], Float:CeilingBuffer[3];

		//Retrieve:
		TR_GetEndPosition(EndOrigin, TraceRay);

		//Distance:
		Distance = (GetVectorDistance(StartOrigin, EndOrigin) - CLIENTWIDTH);

		//Update:
		PositionBuffer[2] = EndOrigin[2];
		PositionBuffer[1] = (StartOrigin[1] + (Distance * Sine(DegToRad(Angles[1]))));
		PositionBuffer[0] = (StartOrigin[0] + (Distance * Cosine(DegToRad(Angles[1]))));

		//Initialize:
		CeilingBuffer = PositionBuffer;
		CeilingBuffer[2] = (CeilingBuffer[2] - CLIENTHEIGHT);

		//Ceiling:
		if(TR_GetPointContents(CeilingBuffer) == 0) PositionBuffer[2] = (PositionBuffer[2] - CLIENTHEIGHT);

		//Send:
		if(TR_GetPointContents(PositionBuffer) == 0) TeleportEntity(Player, PositionBuffer, NULL_VECTOR, NULL_VECTOR);	
	}

	//End:
	CloseHandle(TraceRay);

	//Return:
	return Plugin_Handled;
	
}

//Information:
public Plugin:myinfo =
{

	//Initialize:
	name = "Blink",
	author = "Pinkfairie",
	description = "Adds sm_blink",
	version = "1.1",
	url = "Http://www.myspace.com/josephmaley"
}

//Initation:
public OnPluginStart()
{

	//Commands:
	RegAdminCmd("sm_blink", Command_Blink, ADMFLAG_KICK, "Teleports you to where you are aiming!");
}