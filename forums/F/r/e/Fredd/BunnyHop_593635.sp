#include <sourcemod>
#include <sdktools>
#include <hooker>

#pragma semicolon 1

enum GameType 
{
	GameCS = 0,
	GameTF,
};
new GameType:Game;
new Handle:BhopEnabled;
new Handle:DefaultGrav;


public Plugin:myinfo = 
{
	name = "Bunny Bhop",
	author = "Fredd",
	description = "Lets user auto bunny hop holding down space..",
	version = "1.1",
	url = "www.sourcemod.net"
}
public OnPluginStart()
{
	CreateConVar("bhop_version", "1.1", "Bunny Bhop Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	decl String:GameDir[64];
	GetGameFolderName(GameDir, sizeof(GameDir));
	if(strcmp(GameDir, "cstrike") == 0)
		Game = GameCS;
	else if(strcmp(GameDir, "tf") == 0)
		Game = GameTF;
	else
		SetFailState("game not supported...");
	
	BhopEnabled	= CreateConVar("bhop_enabled", "1", "enables disables bhoping");
	DefaultGrav = FindConVar("sv_gravity");
	
	RegisterHook(HK_PlayerJump, PlayerJump, true);	
}
public OnClientPutInServer(client)
{
	if(Game == GameCS)
		HookEntity(HKE_CCSPlayer, client);
	else
		HookEntity(HKE_CTFPlayer, client);
}
public OnClientDisconnect(client)
{
	if(Game == GameCS)
		UnHookPlayer(HKE_CCSPlayer, client);
	else
		UnHookPlayer(HKE_CTFPlayer, client);
}
public Action:PlayerJump(client)
{
	if(GetConVarInt(BhopEnabled) == 1 && IsClientInGame(client) && IsPlayerAlive(client) && (GetEntityFlags(client) & FL_ONGROUND))
	{
		static Float:PlayerVel[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", PlayerVel);
		PlayerVel[2] = (GetConVarFloat(DefaultGrav)/3.0);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, PlayerVel);
	}

}