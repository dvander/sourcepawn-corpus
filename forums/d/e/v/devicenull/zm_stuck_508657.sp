#pragma semicolon 1

#include <sourcemod>
#include <usermessages>
#include <bitbuffer>
#include <events>
#include <entity>

public Plugin:myinfo = 
{
	name = "AntiStuck",
	author = "devicenull",
	description = "Anti-Stuck",
	version = "1.0.1.0",
	url = "http://forums.alliemods.net/"
};

#define MAX_PLAYERS 64+1

//Maximum number of spawn locations to record
#define MAX_SPAWNS 16

//Number of teleports remaining for each player
new TeleRemain[MAX_PLAYERS];

//Stored spawn locations
new Float:SpawnLoc[MAX_SPAWNS][3];
new nxtSpawn;

//Next spawn location to use when someone is stuck
new useSpawn;

//Offset to absolute position
new off_AbsPos;

new Handle:cTeleNum;

public OnPluginStart()
{
	RegConsoleCmd("say",saycmd);
	cTeleNum = CreateConVar("zm_teleportcount","3","Number of times to allow a user to teleport per round");	
	off_AbsPos = FindSendPropOffs("CBaseEntity","m_vecOrigin");
	HookEvent("round_start",round_begin);
}

public OnClientPutInServer(client)
{
	//Reset the players spawns when they join
	TeleRemain[client] = GetConVarInt(cTeleNum);
}

/*
*	Reset all players teleport count
*	Store the locations of spawns
*/
public round_begin(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl Float:tloc[3];
	nxtSpawn = 0;
	for (new i=1;i<GetMaxClients();++i)
	{
		TeleRemain[i] = GetConVarInt(cTeleNum);
		if (IsPlayerInGame(i) && i<MAX_SPAWNS)
		{
			GetEntDataVector(i,off_AbsPos,tloc);
			SpawnLoc[nxtSpawn][0] = tloc[0];
			SpawnLoc[nxtSpawn][1] = tloc[1];
			SpawnLoc[nxtSpawn][2] = tloc[2];
			//PrintToServer("Got spawn location: %f,%f,%f",tloc[0],tloc[1],tloc[2]);
			++nxtSpawn;
		}
	}
	if (nxtSpawn != 0) useSpawn = useSpawn % nxtSpawn;
	CPrint(0,"Stuck? say !stuck");
}

public Action:saycmd(client, args)
{ //Arg0 is "say"

	decl String:arg1[32];
	GetCmdArg(1,arg1,32);
	
	//Show the player their current position
	if (StrCompare(arg1,"whereami",false) == 0)
	{
		decl Float:loc[3];
		GetEntDataVector(client,off_AbsPos,loc);
		
		CPrint(client,"Your position is: x=%f y=%f z=%f",loc[0],loc[1],loc[2]);
		return Plugin_Handled;
	}
	else if (StrCompare(arg1,"!stuck",false) == 0 || StrCompare(arg1,"/stuck",false) == 0 
		|| StrCompare(arg1,"!teleport",false) == 0 || StrCompare(arg1,"/teleport",false) == 0)
	{
		//If a player gets stuck, teleport them back to one of the spawn locations
		if (TeleRemain[client] > 0)
		{
			--TeleRemain[client];
			SetEntDataVector(client,off_AbsPos,SpawnLoc[useSpawn]);
			useSpawn = (++useSpawn) % nxtSpawn;
			CPrint(client,"You have %i / %i teleports remaining for this round",TeleRemain[client],GetConVarInt(cTeleNum));
		}
		else
		{
			CPrint(client,"You have used up your teleports for this round");
		}	
		return Plugin_Handled;
	}
	else if (StrCompare(arg1,"!zstuck",false) == 0 || StrCompare(arg1,"/zstuck") == 0)
	{
		CPrint(client,"If you are stuck in an object, use !stuck ... not !zstuck");
	}
	return Plugin_Continue;
}

stock CPrint(client,String:tosend[],{Float,String,_}:...)
{
	decl String:buff[512];
	VFormat(buff,512,tosend,3);
	decl Handle:msg;
	if (client == 0) msg = StartMessageAll("SayText",0);
	else msg = StartMessageOne("SayText",client,0);
	BfWriteByte(msg,0);
	BfWriteString(msg,buff);
	BfWriteByte(msg,1);
	EndMessage();	
}
