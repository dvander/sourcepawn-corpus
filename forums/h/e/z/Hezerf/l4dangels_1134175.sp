#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

new Handle:iCheck = INVALID_HANDLE;

new String:iAngel[33];
new String:iAngelB[33];
new Handle:iEnabled;

public Plugin:myinfo =
{
	name = "[L4D(2)] Angels",
	author = "Hezerf",
	description = "Create Angels for hurted players.",
	version = PLUGIN_VERSION,
	url = "http://www.devicenull.org/"
};

public OnPluginStart()
{
	// Require Left 4 Dead (2)
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead", false) 
	&& !StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead or Left 4 Dead 2 only.");
	}
	CreateConVar("l4dangels_version", PLUGIN_VERSION, "[L4D(2)] Angels", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	iCheck=CreateTimer(5.0,checkfan,_, TIMER_REPEAT);
	iEnabled = CreateConVar("l4dangels_enabled", "1", "Enable/Disable Angels.");
}

public PluginEnd()
{
	CloseHandle(iCheck);
}

public Action:checkfan(Handle:nothing)
{
	for( new i = 1; i <= GetMaxClients(); i++ )
		if(  IsClientInGame( i ) && IsClientConnected( i ) && GetClientTeam( i ) == 2 && IsPlayerAlive( i ) && GetConVarInt( iEnabled ) )
	{
		if ( GetClientHealth( i ) < 50 && iAngel[i]==0 ) 
		{
			l4dbot( i );
			iAngel[i]=1;
			KickClient(iAngelB[i],"Go to sky....");
		}
		if ( GetClientHealth( i ) > 50 && iAngel[i]==1 )
		{
			KickClient(iAngelB[i]+1,"Go to sky....");
			iAngel[i]=0;
		}
		
		
	}
}

stock l4dbot(client)
{
	new bot = CreateFakeClient("Angel");
	ChangeClientTeam(bot,2);
	DispatchKeyValue(bot,"classname","SurvivorBot");
	DispatchSpawn(bot);
	iAngelB[client]=bot;}