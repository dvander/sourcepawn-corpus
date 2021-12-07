
//Terminate:
#pragma semicolon 1

//Includes:
#include <sourcemod>
#include <sdktools>

//Definitions:
#define SAYDIST 600
#define YELLDIST 1000
#define WHISPDIST 150

//Calling:
static Connected[33];
new bool:Answered[33] = false;

//Timers:
static TimeOut[33];

//Calling:
stock Call(Client, Player)
{

	//World:
	if(Client != 0 && Player != 0)
	{

		//Declare:
		decl String:PlayerName[32];
		decl String:ClientName[32];

		//Initialize:
		GetClientName(Player, PlayerName, sizeof(PlayerName));
		GetClientName(Client, ClientName, sizeof(ClientName));

		//Not Connected:
		if(Connected[Player] == 0)
		{

			//Initialize:
			Connected[Client] = Player;
			Connected[Player] = Client;
	
			//Print:
			PrintToChat(Client, "\x04[RP]\x01 - You call \x04%s...", PlayerName);
			PrintToChat(Player, "\x04[RP]\x01 - \x04%s\x01 Is calling you", ClientName);

			//Send:
			RecieveCall(Player);
			TimeOut[Client] = 40;
			CreateTimer(1.0, TimeOutCall, Client);

		}
		else
		{

			//Print:
			PrintToChat(Client, "\x04[RP]\x01 - \x04%s\x01 is already on the phone", PlayerName);
		}
	}
}
//Recieve:
stock RecieveCall(Client)
{

	//Sound:
	EmitSoundToClient(Client, "roleplay/ring.wav", SOUND_FROM_PLAYER, 5);

	//Print:
	//PrintToChat(Client, "\x04[RP]\x01 - Your phone is ringing, Type \x04answer\x01 to recieve the call");

	//Send:
	TimeOut[Client] = 40;
	CreateTimer(1.0, TimeOutRecieve, Client);
}

//Answer:
stock Answer(Client)
{

	//Connected:
	if(!Answered[Client] && Connected[Client] != 0)
	{

		//Declare:
		decl Player;
		decl String:ClientName[32];
	
		//Initialize:
		Player = Connected[Client];
		GetClientName(Client, ClientName, sizeof(ClientName));

		//Print:
		PrintToChat(Client, "\x04[RP]\x01 - You answer your phone");
		PrintToChat(Client, "\x04[RP]\x01 - Use TeamChat to talk on the phone");
		PrintToChat(Player, "\x04[RP]\x01 - \x04%s\x01 answered their phone", ClientName);
		PrintToChat(Player, "\x04[RP]\x01 - Use TeamChat to talk on the phone");
	
		//Send:
		Answered[Client] = true;
		Answered[Player] = true;

		//Sound:
		StopSound(Client, 5, "roleplay/ring.wav");
	}
	else
	{

		//Print:
		PrintToChat(Client, "\x04[RP]\x01 - You already answered the phone");
	}
}

//Hang Up:
stock HangUp(Client)
{

	//Connected:
	if(Connected[Client] != 0)
	{

		//Declare:
		decl Player;
		decl String:ClientName[32], String:PlayerName[32];
	
		//Initialize:
		Player = Connected[Client];
		GetClientName(Client, ClientName, sizeof(ClientName));
		GetClientName(Player, PlayerName, sizeof(PlayerName));

		//Print:
		PrintToChat(Client, "\x04[RP]\x01 - You hang up on \x04%s", PlayerName);
		PrintToChat(Player, "\x04[RP]\x01 - \x04%s\x01 hung up on you", ClientName);
	
		//Send:
		Connected[Client] = 0;
		Answered[Client] = false;
		Connected[Player] = 0;
		Answered[Player] = false;

		//Sound:
		StopSound(Client, 5, "roleplay/ring.wav");
	}
	else
	{

		//Print:
		PrintToChat(Client, "\x04[RP]\x01 - You are not on the phone");
	}
}

//Silent:
stock PrintSilentChat(Client, String:ClientName[32], Player, String:Message[32], String:Arg[255])
{

	//Print:
	PrintToChat(Client, "\x01(%s)\x04%s:\x01 %s", Message, ClientName, Arg);
	PrintToChat(Player, "\x01(%s)\x04%s:\x01 %s", Message, ClientName, Arg);
}

//In-Game:
public OnClientPutInServer(Client)
{

	//Default:
	Connected[Client] = 0;
	Answered[Client] = false;
	TimeOut[Client] = 0;
}

//Disconnect:
public OnClientDisconnect(Client)
{

	//Connected:
	if(Connected[Client] != 0)
	{

		//Declare:
		decl Player;

		//Initialize:
		Player = Connected[Client];

		//Print:
		PrintToChat(Player, "\x04[RP]\x01 - You have lost service, \x04phone conversation\x01 aborted");
	
		//Send:
		Connected[Client] = 0;
		Answered[Client] = false;
		Connected[Player] = 0;
		Answered[Player] = false;
	}
}

//Time Out (Calling):
public Action:TimeOutCall(Handle:Timer, any:Client)
{
	
	//Push:
	if(TimeOut[Client] > 0) TimeOut[Client] -= 1;

	//Broken Connection:
	if(Connected[Client] == 0)
	{

		//End:
		TimeOut[Client] = 0;
	}

	//Not Answered:
	if(!Answered[Client] && TimeOut[Client] == 1)
	{

		//Declare:
		decl Player;
		decl String:PlayerName[32];
	
		//Initialize:
		Player = Connected[Client];
		GetClientName(Player, PlayerName, sizeof(PlayerName));

		//Print:
		PrintToChat(Client, "\x04[RP]\x01 - \x04%s\x01 failed to answer their phone", PlayerName);

		//End Connection:
		Answered[Client] = false;
		Connected[Client] = 0;	
	}

	//Loop:
	if(TimeOut[Client] > 0)
	{

		//Send:
		CreateTimer(1.0, TimeOutCall, Client);
	}
}

//Time Out (Recieve):
public Action:TimeOutRecieve(Handle:Timer, any:Client)
{

	//Push:
	if(TimeOut[Client] > 0) TimeOut[Client] -= 1;

	//Broken Connection:
	if(Connected[Client] == 0)
	{

		//End:
		TimeOut[Client] = 0;
	}

	//Not Answered:
	if(!Answered[Client] && TimeOut[Client] == 1)
	{

		//Print:
		PrintToChat(Client, "\x04[RP]\x01 - Your phone has \x04stopped\x01 ringing");

		//End Connection:
		Answered[Client] = false;
		Connected[Client] = 0;
	}

	//Loop:
	if(TimeOut[Client] > 0)
	{

		//Send:
		CreateTimer(1.0, TimeOutRecieve, Client);
	}
}

//Handle Chat:
public Action:CommandSay(Client, Arguments)
{

	//World:
	if(Client == 0) return Plugin_Continue;

	//Declare:
	decl String:Arg[255];

	//Initialize:
	GetCmdArgString(Arg, sizeof(Arg));

	//Clean:
	StripQuotes(Arg);
	TrimString(Arg);

	if(StrEqual(Arg, "/answer", false))
	{
		//Answer:
		Answer(Client);
		return Plugin_Handled;
	}
	else if(StrEqual(Arg, "/hangup", false))
	{
		//Hangup:
		HangUp(Client);
		return Plugin_Handled;
	}
	else if(StrContains(Arg, "/call ", false) == 0)
	{
		//Already Connected:
		if(Connected[Client] != 0) return Plugin_Handled;

		//Dead:
		if(!IsPlayerAlive(Client)) return Plugin_Handled;

		//Declare:
		decl Player, MaxPlayers;
		decl String:ArgBuffers[2][32], String:TempName[32];
		
		//Explode:
		ExplodeString(Arg, " ", ArgBuffers, 2, 32);

		//Initialize:
		Player = -1;
		MaxPlayers = GetMaxClients();
	
		//Find:
		for(new X = 1; X <= MaxPlayers; X++)
		{
			//Connected:
			if(IsClientConnected(X))
			{
				//Initialize:
				GetClientName(X, TempName, sizeof(TempName));

				//Save:
				if(StrContains(TempName, ArgBuffers[1], false) != -1) 
				{
					Player = X;
					break;
				}
			}
		}
	
		if(Player == -1)
		{
			//Print:
			PrintToChat(Client, "\x04[RP]\x01 - Could not find client \x04%s", ArgBuffers[1]);

			//Return:
			return Plugin_Handled;
		}
		else if(Player == Client)
		{
			//Print:
			PrintToChat(Client, "\x04[RP]\x01 - You cannot call yourself");

			//Return:
			return Plugin_Handled;
		}
		else if(!IsPlayerAlive(Player))
		{

			//Print:
			PrintToChat(Client, "\x04[RP]\x01 - Cannot call a dead player");

			//Return:
			return Plugin_Handled;
		}

		//Call:
		Call(Client, Player);

		//Return:
		return Plugin_Handled; 
	}
	else if(StrEqual(Arg, "/call", false))
	{
		PrintToChat(Client, "\x04[RP]\x01 - Usage: /call <name>");
		return Plugin_Handled;
	}

	//Close:
	return Plugin_Continue;  
}      

//Team Chat:
public Action:CommandSayTeam(Client, Arguments)
{

	//World:
	if(Client == 0) return Plugin_Continue;

	//Declare:
	decl String:Arg[255];

	//Initialize:
	GetCmdArgString(Arg, sizeof(Arg));

	//Clean:
	StripQuotes(Arg);
	TrimString(Arg);

	//Name:
	new String:ClientName[32];
	GetClientName(Client, ClientName, 32);

	//Admin-Say:
	if(Arg[0] == '@') return Plugin_Continue;

	//Phone:
	if(Connected[Client] != 0)
	{
		//On the Phone:
		if(Answered[Client])
		{

			//Print:
			GetClientName(Client, ClientName, 32);
			PrintSilentChat(Client, ClientName, Connected[Client], "Phone", Arg);

			//Return:
			return Plugin_Handled;
		}
	}

	//Return:
	return Plugin_Continue; 
}

//Death:
public Action:EventDeath(Handle:Event, const String:Name[], bool:Broadcast)
{

	//Declare:
	decl Client;

	//Initialize:
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));

	//Hangup:
	if(Connected[Client] != 0) HangUp(Client);
}



//Map Start:
public OnMapStart()
{

	//Precache:
	PrecacheSound("roleplay/ring.wav", true);
	AddFileToDownloadsTable("sound/roleplay/ring.wav");
}

//Information:
public Plugin:myinfo =
{

	//Initation:
	name = "Phonecall",
	author = "Joe 'Pinkfairie' Maley - it's_me edit",
	description = "Phonecalls for RP",
	version = "2.1b",
	url = "hiimjoemaley@hotmail.com"
}

//Initation:
public OnPluginStart()
{

	//Commands:
	RegConsoleCmd("say", CommandSay);
	RegConsoleCmd("say_team", CommandSayTeam);

	//Server Variable:
	CreateConVar("talkzone_version", "2.1", "Phonecall Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}