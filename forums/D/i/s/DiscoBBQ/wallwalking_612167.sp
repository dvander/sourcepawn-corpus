//Wall Walking v1.1 by Pinkfairie

//Termination:
#pragma semicolon 1

//Includes:
#include <sourcemod>
#include <sdktools>

//Definitions:
#define Speed 200

//Variables:
static bool:AllowWallWalking[33] = false;

//SM_Wallwalk:
public Action:Command_Wallwalk(Client, Arguments)
{

	//Player:
	new Player = -1;

	//Default:
	if(Arguments < 1) 
	{

		//Print:
		PrintToConsole(Client, "Usage: sm_wallwalk <Client>");

		//Return:
		return Plugin_Handled;
	}
	
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

	//Toggle:
	AllowWallWalking[Player] = !AllowWallWalking[Player];

	//Name:
	decl String:CName[32], String:PName[32];
	GetClientName(Client, CName, 32);
	GetClientName(Player, PName, 32);

	//Print:
	PrintToConsole(Client, "[SM] Toggled Wallwalking on client %s to %d", PName, AllowWallWalking[Player]);
	PrintToChat(Player, "[SM] %s toggled wallking on you to %d", CName, AllowWallWalking[Player]);

	//Return:
	return Plugin_Handled;
	
}

//Prethink:
public OnGameFrame()
{

	//Declare:
	decl MaxPlayers;

	//Initialize:
	MaxPlayers = GetMaxClients();

	//Loop:
	for(new X = 1; X < MaxPlayers; X++)
	{

		//Connected:
		if(IsClientConnected(X) && IsClientInGame(X))
		{

			//Alive:
			if(IsPlayerAlive(X))
			{

				//Wall?
				new bool:NearWall = false;

				//Circle:
				for(new AngleRotate = 0; AngleRotate < 360; AngleRotate += 30)
				{

					//Declare:
					decl Handle:TraceRay;
					decl Float:StartOrigin[3], Float:Angles[3];

					//Initialize:
					Angles[0] = 0.0;
					Angles[2] = 0.0;
					Angles[1] = float(AngleRotate);
					GetClientEyePosition(X, StartOrigin);

					//Ray:
					TraceRay = TR_TraceRayEx(StartOrigin, Angles, MASK_SOLID, RayType_Infinite);

					//Collision:
					if(TR_DidHit(TraceRay))
					{

						//Declare:
						decl Float:Distance;
						decl Float:EndOrigin[3];

						//Retrieve:
						TR_GetEndPosition(EndOrigin, TraceRay);

						//Distance:
						Distance = (GetVectorDistance(StartOrigin, EndOrigin));

						//Allowed:
						if(AllowWallWalking[X]) if(Distance < 50) NearWall = true;

					}

					//Close:
					CloseHandle(TraceRay);

				}

				//Ceiling:
				decl Handle:TraceRay;
				decl Float:StartOrigin[3];
				new Float:Angles[3] =  {270.0, 0.0, 0.0};

				//Initialize:
				GetClientEyePosition(X, StartOrigin);

				//Ray:
				TraceRay = TR_TraceRayEx(StartOrigin, Angles, MASK_SOLID, RayType_Infinite);

				//Collision:
				if(TR_DidHit(TraceRay))
				{
					//Declare:
					decl Float:Distance;
					decl Float:EndOrigin[3];

					//Retrieve:
					TR_GetEndPosition(EndOrigin, TraceRay);

					//Distance:
					Distance = (GetVectorDistance(StartOrigin, EndOrigin));

					//Allowed:
					if(AllowWallWalking[X]) if(Distance < 50) NearWall = true;
				}

				//Close:
				CloseHandle(TraceRay);

				//Near:
				if(NearWall)
				{ 
					
					//Almost Zero:
					SetEntityGravity(X, Pow(Pow(100.0, 3.0), -1.0));

					//Buttons:
					decl ButtonBitsum;
					ButtonBitsum = GetClientButtons(X);

					//Origin:
					decl Float:ClientOrigin[3];
					GetClientAbsOrigin(X, ClientOrigin);

					//Angles:
					decl Float:ClientEyeAngles[3];
					GetClientEyeAngles(X, ClientEyeAngles);

					//Declare:
					decl Float:VeloX, Float:VeloY, Float:VeloZ;

					//Initialize:
					VeloX = (Speed * Cosine(DegToRad(ClientEyeAngles[1])));
					VeloY = (Speed * Sine(DegToRad(ClientEyeAngles[1])));
					VeloZ = (Speed * Sine(DegToRad(ClientEyeAngles[0])));


					//Jumping:
					if(ButtonBitsum & IN_JUMP)
					{

						//Stop:
						new Float:Velocity[3] = {0.0, 0.0, 0.0};
						TeleportEntity(X, ClientOrigin, NULL_VECTOR, Velocity);
					}

					//Forward:
					if(ButtonBitsum & IN_FORWARD)
					{

						//Forward:
						new Float:Velocity[3];
						Velocity[0] = VeloX;
						Velocity[1] = VeloY;
						Velocity[2] = (VeloZ - (VeloZ * 2));
						TeleportEntity(X, ClientOrigin, NULL_VECTOR, Velocity);
					}

					//Backward:
					else if(ButtonBitsum & IN_BACK)
					{

						//Backward:
						new Float:Velocity[3];
						Velocity[0] = (VeloX - (VeloX * 2));
						Velocity[1] = (VeloY - (VeloY * 2));
						Velocity[2] = VeloZ;
						TeleportEntity(X, ClientOrigin, NULL_VECTOR, Velocity);
					}

					//Null:
					else 
					{

						//Stop:
						new Float:Velocity[3] = {0.0, 0.0, 0.0};
						TeleportEntity(X, ClientOrigin, NULL_VECTOR, Velocity);
					}

				}

				//Default:
				else SetEntityGravity(X, 1.0);		
			}

		}

	}

}

//Information:
public Plugin:myinfo =
{

	//Initialize:
	name = "Wallwalk",
	author = "Pinkfairie",
	description = "Allows users to walk on walls",
	version = "1.1",
	url = "Http://www.myspace.com/josephmaley"
}

//Initation:
public OnPluginStart()
{

	//Commands:
	RegAdminCmd("sm_wallwalk", Command_Wallwalk, ADMFLAG_KICK, "<Client> Toggles wallwalking on a player!");
}