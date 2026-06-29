//TF2 Third Person v1.0 by Joe 'Pinkfairie' Maley:                                                                                                                                           //TF2 Gore v1.0 by Joe 'Pinkfairie' Maley:

//Terminate:
#pragma semicolon 1

//Includes:
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

//Definitions:
#define PLUGIN_VERSION	"1.0"
#define	IDEAL_DISTANCE	"150"

//Client:
//static bool:IsSniper[33] = false;
//static bool:IsTPV[33] = false;

//Global:
//static bool:EnableTPV = true;
//static bool:ForceTPV = false;

//Filter:
stock BlockCommand(const String:CVARName[64])
{

	//Block:
	//SetCommandFlags(CVARName, FCVAR_NOT_CONNECTED|FCVAR_SPONLY|FCVAR_PROTECTED);
	SetCommandFlags(CVARName, FCVAR_SPONLY);
}

/*
//TPV:
stock TPV(Client)
{

	//Enable:
	SetCommandFlags("thirdperson", (GetCommandFlags("thirdperson") & ~FCVAR_SPONLY));
	SetCommandFlags("cam_idealdist", (GetCommandFlags("cam_idealdist") & ~FCVAR_SPONLY));
	SetCommandFlags("cam_idealyaw", (GetCommandFlags("cam_idealyaw") & ~FCVAR_SPONLY));
	SetCommandFlags("cam_idealpitch", (GetCommandFlags("cam_idealpitch") & ~FCVAR_SPONLY));

	//Send:
	FakeClientCommandEx(Client, "thirdperson");
	ClientCommand(Client, "cam_idealdist %s", IDEAL_DISTANCE);
	ClientCommand(Client, "cam_idealyaw 0");
	ClientCommand(Client, "cam_idealpitch 0");

	//Delay Block:
	CreateTimer(0.1, TPVDelay, Client);
}

//FPV:
stock FPV(Client)
{

	//Enable:
	SetCommandFlags("firstperson", (GetCommandFlags("firstperson") & ~FCVAR_SPONLY));

	//Send:
	FakeClientCommandEx(Client, "firstperson");

	//Delay Block:
	CreateTimer(0.1, FPVDelay, Client);
}

//TPV Logic:
stock ToggleTPV(Client)
{

	//First Person:
	if(!IsTPV[Client])
	{

		//Enable TPV:
		TPV(Client);
		IsTPV[Client] = true;
	}

	//Third Person:
	else
	{

		//Enable FPV:
		FPV(Client);
		IsTPV[Client] = false;
	}
}

//Force:
public Action:CommandForce(Client, Args)
{

	//Check:
	if(Args < 1)
	{

		//Print:
		PrintToConsole(Client, "[RP] Usage: sm_forcetpv <0|1>");

		//Print:
		return Plugin_Handled;
	}

	//Declare:
	decl Value;
	decl String:Arg[32];

	//Initialize:
	GetCmdArg(1, Arg, sizeof(Arg));
	StringToIntEx(Arg, Value);

	//Error:
	if(Value != 0 && Value != 1)
	{

		//Print:
		PrintToConsole(Client, "[RP] Usage: sm_forcetpv <0|1>");

		//Print:
		return Plugin_Handled;
	}

	//Declare:
	decl String:PrintBool[32];

	//Logic:
	if(Value == 1)
	{

		//Enable:
		ForceTPV = true;
		PrintBool = "enforced";
	}
	else
	{

		//Disable:
		ForceTPV = false;
		PrintBool = "is not enforced";
	}

	//Enabled:
	if(ForceTPV)
	{

		//Declare:
		decl MaxPlayers;

		//Initialize:
		MaxPlayers = GetMaxClients();

		//Loop:
		for(new Player = 1; Player <= MaxPlayers; Player++)
		{

			//Connected:
			if(IsClientConnected(Player) && IsClientInGame(Player))
			{

				//Enable:
				if(!IsTPV[Player]) ToggleTPV(Player);
			}
		}
	}

	//Print:
	PrintToConsole(Client, "[SM] Thirdperson %s", PrintBool);

	//Return:
	return Plugin_Handled;
}

//Enable:
public Action:CommandEnable(Client, Args)
{

	//Check:
	if(Args < 1)
	{

		//Print:
		PrintToConsole(Client, "[RP] Usage: sm_enabletpv <0|1>");

		//Print:
		return Plugin_Handled;
	}

	//Declare:
	decl Value;
	decl String:Arg[32];

	//Initialize:
	GetCmdArg(1, Arg, sizeof(Arg));
	StringToIntEx(Arg, Value);

	//Error:
	if(Value != 0 && Value != 1)
	{

		//Print:
		PrintToConsole(Client, "[RP] Usage: sm_enabletpv <0|1>");

		//Print:
		return Plugin_Handled;
	}

	//Declare:
	decl String:PrintBool[32];

	//Logic:
	if(Value == 1)
	{

		//Enable:
		EnableTPV = true;
		PrintBool = "enabled";
	}
	else
	{

		//Disable:
		EnableTPV = false;
		PrintBool = "disabled";
	}

	//Enabled:
	if(!EnableTPV)
	{

		//Declare:
		decl MaxPlayers;

		//Initialize:
		MaxPlayers = GetMaxClients();

		//Loop:
		for(new Player = 1; Player <= MaxPlayers; Player++)
		{

			//Connected:
			if(IsClientConnected(Player) && IsClientInGame(Player))
			{

				//Disable:
				if(IsTPV[Player]) ToggleTPV(Player);
			}
		}
	}

	//Print:
	PrintToConsole(Client, "[SM] Thirdperson %s", PrintBool);

	//Return:
	return Plugin_Handled;
}

//Admin TPV:
public Action:CommandTPV(Client, Args)
{

	//Error:
	if(Args < 1)
	{

		//Print:
		PrintToConsole(Client, "[RP] Usage: sm_thirdperson <Name>");

		//Return:
		return Plugin_Handled;
	}

	//Declare:
	decl Player, MaxPlayers;
	decl String:TempName[32], String:ClientName[32], String:PlayerName[32];

	//Initialize:
	Player = -1;
	GetCmdArg(1, TempName, sizeof(TempName));
	
	//Find:
	MaxPlayers = GetMaxClients();
	for(new X = 1; X <= MaxPlayers; X++)
	{

		//Connected:
		if(!IsClientConnected(X)) continue;

		//Initialize:
		GetClientName(X, PlayerName, sizeof(PlayerName));

		//Save:
		if(StrContains(PlayerName, TempName, false) != -1) Player = X;
	}
	
	//Invalid Name:
	if(Player == -1)
	{

		//Print:
		PrintToConsole(Client, "[SM] Could not find client %s", TempName);

		//Return:
		return Plugin_Handled;
	}

	//Names:
	GetClientName(Client, ClientName, sizeof(ClientName));
	GetClientName(Player, PlayerName, sizeof(PlayerName));


	//Toggling Off:
	if(ForceTPV && IsTPV[Player] == true)
	{

		//Print:
		PrintToChat(Client, "[SM] Cannot toggle TPV off of client %s due to the enforcement of TPV via sm_forcetpv");

		//Return:
		return Plugin_Handled;
	}

	//Declare:
	decl String:PrintBool[32];

	//Logic:
	if(IsTPV[Player])
	{

		IsTPV[Player] = false;
		PrintBool = "off";
	}
	else
	{

		IsTPV[Player] = true;
		PrintBool = "on";
	}

	//Print:
	PrintToConsole(Client, "[SM] Toggled %s third person view on %s", PrintBool, PlayerName);
	PrintToChat(Player, "[SM] Admin %s toggled third person view on you", ClientName);

	//Return:
	return Plugin_Handled;
}*/

//Hooking All:
public Action:BlockCheats(Handle:Timer, any:Value)
{

	//Non-Cheats:
	//BlockCommand("firstperson");
	BlockCommand("impulse");

	//Declare:
	decl Flags;
	decl Handle:CVAR;
	decl bool:IsCommand;
	decl String:CVARName[64];

	//Initialize:
	CVAR = FindFirstConCommand(CVARName, sizeof(CVARName), IsCommand, Flags);

	//Invalid:
	if(CVAR == INVALID_HANDLE) SetFailState("[SM] Could not load CVAR list");	

	//Hook:
	do
	{	
		//Contains Cheat Flag:
		if(GetCommandFlags(CVARName) & FCVAR_CHEAT || StrContains(CVARName, "mat", false) != -1) //|| StrContains(CVARName, "cam", false) != -1
		{

			//Block:
			if(StrContains(CVARName, "cam", false) == -1 || StrContains(CVARName, "thirdperson", false) == -1) BlockCommand(CVARName);
		}
	}
	
	//While:
 	while(FindNextConCommand(CVAR, CVARName, sizeof(CVARName), IsCommand, Flags));

	//Close:
	CloseHandle(CVAR);

	//Return:
	return Plugin_Handled;
}

/*
//Spawn:
public EventSpawn(Handle:Event, const String:Name[], bool:Broadcast)
{

	//Declare:
	decl Client;

	//Initialize:
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));

	//Reset:
	IsSniper[Client] = false;

	//Enable:
	if(!EnableTPV && !ForceTPV && IsTPV[Client]) ToggleTPV(Client);

	//Force:
	if(ForceTPV && !IsTPV[Client]) ToggleTPV(Client);
}

//Taunt Toggle:
public Action:ToggleViaTaunt(Client, Args)
{

	//Toggle TPV:
	if(EnableTPV) ToggleTPV(Client);

	//Block Taunt:
	return Plugin_Handled;
}

//TPV Delay:
public Action:TPVDelay(Handle:Timer, any:Client)
{
	//Block:
	BlockCommand("thirdperson");
	BlockCommand("cam_idealdist");
	BlockCommand("cam_idealyaw");
	BlockCommand("cam_idealpitch");

	//Return:
	return Plugin_Handled;
}

//FPV Delay:
public Action:FPVDelay(Handle:Timer, any:Client)
{
	//Block:
	BlockCommand("firstperson");

	//Return:
	return Plugin_Handled;
}*/

/*
//Prethink:
public OnGameFrame()
{

	//Declare:
	decl MaxPlayers;

	//Initialize:
	MaxPlayers = GetMaxClients();

	//Loop:
	for(new Client = 1; Client <= MaxPlayers; Client++)
	{

		//Connected:
		if(IsClientConnected(Client) && IsClientInGame(Client))
		{
			//Alive:
			if(IsPlayerAlive(Client))
			{


				//Declare:
				decl String:WeaponName[64];

				//Initialize:
				GetClientWeapon(Client, WeaponName, sizeof(WeaponName));

				//Sniper:
				if(StrContains(WeaponName, "sniper", false) != -1)
				{

					//Save:
					IsSniper[Client] = true;

					//TPV:
					if(IsTPV[Client])
					{

						//FPV:
						FPV(Client);
					}
				}
				else
				{

					//Sniper & TPV:
					if(IsSniper[Client] && IsTPV[Client])
					{

						//TPV:
						TPV(Client);

						//Reset:
						IsSniper[Client] = false;
					}
				}
			}
		}
	}
}*/

//Map Start:
public OnMapStart()
{
	
	//Declare:
	decl Handle:Sv_Cheats;
	decl bool:CheatsEnabled;

	//Initialize:
	Sv_Cheats = FindConVar("sv_cheats");
	CheatsEnabled = GetConVarBool(Sv_Cheats);

	//Enable Cheats:
	if(!CheatsEnabled) ServerCommand("sv_cheats 1");

	//Command Hook:
	CreateTimer(1.0, BlockCheats, 0);
}

//Information:
public Plugin:myinfo =
{

	//Initialize:
	name = "TF2 Thirdperson",
	author = "Joe 'Pinkfairie' Maley",
	description = "Various Thirdperson Commands",
	version = PLUGIN_VERSION,
	url = "hiimjoemaley@hotmail.com"
}

//Initation:
public OnPluginStart()
{

	//Register:
	PrintToConsole(0, "[SM] TF2 Third Person v%s by Joe 'Pinkfairie' Maley loaded successfully!", PLUGIN_VERSION);

	//Admin Commands:
	//RegAdminCmd("sm_forcetpv", CommandForce, ADMFLAG_CUSTOM1, "<0|1> - Forces third person view on all clients");
	//RegAdminCmd("sm_enabletpv", CommandEnable, ADMFLAG_CUSTOM1, "<0|1> - Enables or disables the usage of third person view");
	//RegAdminCmd("sm_thirdperson", CommandTPV, ADMFLAG_CUSTOM1, "<Name> - Toggles third person on a client");

	//Events:
	//HookEvent("player_spawn", EventSpawn);

	//Console Commands:
	//RegConsoleCmd("taunt", ToggleViaTaunt);

	//Server Variable:
	CreateConVar("tpvbase_version", "1.0", "TF2 Thirdperson Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}