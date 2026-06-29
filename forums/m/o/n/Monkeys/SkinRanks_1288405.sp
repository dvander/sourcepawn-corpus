#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define MAXLEVELS 16

//Player Info
static Kills[MAXPLAYERS+1] = {0,...};

//SkinRank Info
static String:Skins[MAXLEVELS][PLATFORM_MAX_PATH];
static String:Path[PLATFORM_MAX_PATH];
static Ranks[MAXLEVELS];

public Plugin:myinfo =
{
	name = "SkinRanks",
	author = "Jaro Vanderheijden",
	description = "Get different Skins as you Rank up",
	version = "1.0.0.0",
	url = "http://www.sourcemod.net/"
};
 
public OnPluginStart()
{
	//Hooks
	HookEvent("player_death", EventDeath);
	HookEvent("player_spawn", EventSpawn);
	
	//Convars
	CreateConVar("sm_skinranks_version","1.0", "Version of the SkinRanks",FCVAR_NOTIFY);
	
	//Commands
	RegConsoleCmd("sm_skins", ShowSkinRanks, "Shows Skin and their required Ranks.");
	//RegConsoleCmd("sm_skintop", ShowTop10, "Shows top 10 players.");
	RegConsoleCmd("sm_level", ShowLevel, "Shows a player's Rank and TNL.");
	
	//File check
	BuildPath(Path_SM, Path, sizeof(Path), "data/SkinRanks.txt");
	if(!FileExists(Path))
		SetFailState("[SM] Couldn't find %s.", Path);
		
	//Add Files to download tables
	new Handle:KV = CreateKeyValues("SkinRanks");
	FileToKeyValues(KV, Path);
	new String:Index[5], String:Buffer[PLATFORM_MAX_PATH];
	
	//Load and precache skins
	KvJumpToKey(KV, "Skins");
	for(new X = 1; X <= MAXLEVELS; X++)
	{
		IntToString((X), Index, sizeof(Index));
		KvGetString(KV, Index, Buffer, sizeof(Buffer), "");
		strcopy(Skins[X-1], sizeof(Skins[]), Buffer);
		if(StrEqual(Buffer, ""))
			break;
		if(!IsModelPrecached(Buffer))
			PrecacheModel(Buffer);
		AddFileToDownloadsTable(Buffer);
	}
	CloseHandle(KV);
}

public OnMapStart()
{
	new Handle:KV = CreateKeyValues("SkinRanks");
	FileToKeyValues(KV, Path);
	new String:Index[5], String:Buffer[PLATFORM_MAX_PATH];
	
	//Load and precache skins
	KvJumpToKey(KV, "Skins");
	for(new X = 1; X <= MAXLEVELS; X++)
	{
		IntToString((X), Index, sizeof(Index));
		KvGetString(KV, Index, Buffer, sizeof(Buffer), "");
		strcopy(Skins[X-1], sizeof(Skins[]), Buffer);
		if(StrEqual(Buffer, ""))
			break;
		if(!IsModelPrecached(Buffer))
			PrecacheModel(Buffer);
	}
	KvRewind(KV);
	
	//Load Ranks
	KvJumpToKey(KV, "Ranks");
	for(new X = 2; X <= MAXLEVELS; X++)
	{
		IntToString(X, Index, sizeof(Index));
		Ranks[X-2] = KvGetNum(KV, Index, -1);
		if(Ranks[X-2] == -1)
			break;
	}
	CloseHandle(KV);
}

public OnClientPutInServer(Client)
{
	Kills[Client] = 0;
	decl String:Buffer[MAX_NAME_LENGTH];
	
	//Load player's kills
	GetClientAuthString(Client, Buffer, sizeof(Buffer));
	new Handle:KV = CreateKeyValues("SkinRanks");
	FileToKeyValues(KV, Path);
	KvJumpToKey(KV,"Kills");
	Kills[Client] = KvGetNum(KV, Buffer, 0);
	CloseHandle(KV);
	
	//Print welcome message
	GetClientName(Client, Buffer, sizeof(Buffer));
	PrintToChatAll("Player %s - Rank: %d has joined the server.", Buffer, GetRank(Kills[Client]));
}

public OnClientDisconnect(Client)
{
	//Save player's kills
	decl String:Auth[68];
	GetClientAuthString(Client, Auth, sizeof(Auth));
	new Handle:KV = CreateKeyValues("SkinRanks");
	FileToKeyValues(KV, Path);
	KvJumpToKey(KV,"Kills");
	KvSetNum(KV, Auth, Kills[Client]);
	KvRewind(KV);
	KeyValuesToFile(KV, Path);
	CloseHandle(KV);
	
	Kills[Client] = 0;
}

public Action:EventDeath(Handle:Event, const String:Name[], bool:Broadcast)
{
	decl Client, Attacker, CTeam, ATeam;
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	Attacker = GetClientOfUserId(GetEventInt(Event, "attacker"));
	
	if( Attacker == 0 || Attacker > MAXPLAYERS)
		return Plugin_Continue;
	
	CTeam = GetClientTeam(Client);
	ATeam = GetClientTeam(Attacker);
	if( CTeam != ATeam)
	{
		Kills[Attacker]++;
	}
	
	return Plugin_Continue;
}

public Action:EventSpawn(Handle:Event, const String:Name[], bool:Broadcast)
{
	new Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	new Rank = GetRank(Kills[Client]);
	if(GetClientTeam(Client) == 2) SetEntityModel(Client, Skins[Rank-1]);
	return Plugin_Continue;
}

public Action:ShowSkinRanks(Client, Args)
{
	PrintToChat(Client,"[SkinRanks] Skins and their ranks:");
	for(new X = 1; X <= MAXLEVELS; X++)
	{
		if(StrEqual(Skins[X-1], ""))
			break;
		PrintToChat(Client, "%d - \"%s\"", X, Skins[X-1]);
	}
	return Plugin_Handled;
}

public Action:ShowLevel(Client, Args)
{
	new CurrentRank = GetRank(Kills[Client]);
	PrintToChat(Client,"[SkinRanks] Rank: %d, Kills: %d, Kills 'till next Rank: %d.", CurrentRank, Kills[Client], Ranks[CurrentRank-1]-Kills[Client]);
	return Plugin_Handled;
}

stock GetRank(KillCount)
{
	new Rank = 1;
	for(new X = 2; X <= MAXLEVELS; X++)
	{
		if(Ranks[X-2] == -1 || Ranks[X-2] > KillCount)
			break;
		else
			Rank = X;
	}
	return Rank;
}