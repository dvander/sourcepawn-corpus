#include <emitsoundany>

#pragma semicolon 1
#pragma newdecls required 

public Plugin myinfo =
{
	name         = "Surprise!",
	author       = "8GuaWong",
	description  = "Give Your Players A Scare!!",
	version      = "1.0",
	url          = "http://www.blackmarke7.com"
};

ConVar g_cvTimeLimit;
ConVar g_cvPeoplToScare;
ArrayList g_RandomList;

public void OnPluginStart()
{
	g_cvTimeLimit = FindConVar("mp_timelimit");
	g_cvPeoplToScare = CreateConVar("sm_scare_number", "5", "Number Of People To Scare");
	g_RandomList = new ArrayList();
}

public void OnMapStart()
{
	PrecacheDecal("materials/sprites/hello.vtf");
	PrecacheSoundAny("hello.mp3");
	g_RandomList.Clear();
	CreateTimer(GetRandomFloat(30.0, (g_cvTimeLimit.FloatValue * 60.0) - 10.0), SupriseMotherFucker);	
	
	AddFileToDownloadsTable("materials/sprites/hello.vtf");
	AddFileToDownloadsTable("materials/sprites/hello.vmt");	
	AddFileToDownloadsTable("sound/hello.mp3");
}



public Action SupriseMotherFucker(Handle timer)
{
	int alive = GetAliveCount();
	int numToScare;
	if (alive < g_cvPeoplToScare.IntValue)
		numToScare = alive;
	else
		numToScare = g_cvPeoplToScare.IntValue;
	while (g_RandomList.Length < numToScare)
	{
		int randClient = GetRandomClient();
		if (g_RandomList.FindValue(randClient) == -1)
			g_RandomList.Push(randClient);
	}
	
	for (int i; i < g_RandomList.Length; i++)
	{
		int client = g_RandomList.Get(i);
		SetClientOverlay(client, "sprites/hello");
		EmitSoundToClientAny(client, "hello.mp3");
		CreateTimer(6.0, RemoveScare, GetClientUserId(client));
	}
	
	return Plugin_Stop;
}

public Action RemoveScare(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsClientValid(client))
		return Plugin_Stop;
	SetClientOverlay(client, "");
	return Plugin_Stop;
}

bool SetClientOverlay(int client, char [] strOverlay)
{
	if (IsClientValid(client))
	{
		int iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
		SetCommandFlags("r_screenoverlay", iFlags);	
		ClientCommand(client, "r_screenoverlay \"%s\"", strOverlay);
		return true;
	}
	return false;
}

bool IsClientValid(int client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}

int GetAliveCount()
{
	int iCount;
	for( int i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) && IsPlayerAlive(i))
			iCount++;
	return iCount;
}

int GetRandomClient()  
{  
    int iClients[MAXPLAYERS + 1]; // or int iClients[MAXPLAYERS]?
    int iClientsNum, i;
    for (i = 1; i <= MaxClients; ++i)  
    {  
        if (IsClientInGame(i) && IsPlayerAlive(i)) 
        { 
            iClients[iClientsNum++] = i;  
        } 
    }  
    if (iClientsNum > 0) 
    { 
        return iClients[GetRandomInt(0, iClientsNum-1)];  
    } 
    return 0;
}  