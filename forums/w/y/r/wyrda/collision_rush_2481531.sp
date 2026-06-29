#include <sourcemod>
#include <sdktools>
#include <sdkhooks>



public Plugin:myinfo =
{
	name = "Collision rush",
	author = "wyrda",
	description = "Allow players to rush at spawn by disabling collision and enabling it again",
	version = "2.0.0",
	url = "http://wyrdaprogramming.tk/"
};

#define COLLISION_GROUP_DEBRIS_TRIGGER      2
#define COLLISION_GROUP_PUSHAWAY            17
#define COLLISION_GROUP_PLAYER              5

new ColGroup = COLLISION_GROUP_PLAYER;
new Handle:cvar_NoCollisionTime	= INVALID_HANDLE;
new Handle:cvar_PushAwayTime	= INVALID_HANDLE;
new Handle:cvar_FreezeTime	= INVALID_HANDLE;
new bool:g_UnstuckPlayers[65];



public OnPluginStart()
{	
	cvar_NoCollisionTime = CreateConVar("sm_cr_nocollision_time", "4.0", "No collision time offset(after freeze time)", FCVAR_PLUGIN, true, 1.0, true, 10.0);
	cvar_PushAwayTime = CreateConVar("sm_cr_pushaway_time", "2.0", "Push away time", FCVAR_PLUGIN, true, 1.0, true, 5.0);
	cvar_FreezeTime = FindConVar("mp_freezetime");
	
	for (new i = 1; i <= MaxClients; i++)    
        if (IsClientInGame(i))        
            OnClientPutInServer(i);
	
	HookEvent("round_start", Event_RoundStart);
	
	RegConsoleCmd("sm_unstuck", Command_UnStuck, "Unstuck a player.");
	RegConsoleCmd("sm_unblock", Command_UnStuck, "Unstuck a player.");
	
	for(new i = 0; i<64; i++)
		g_UnstuckPlayers[i] = false;
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_PostThinkPost, OnPostThink);
}

public OnPostThink(client)
{	
	if (IsPlayerAlive(client))
	{
		if(g_UnstuckPlayers[client])		
			SetEntProp(client, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PUSHAWAY);				
		else
			SetEntProp(client, Prop_Data, "m_CollisionGroup", ColGroup);   
	}
}

public Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	ColGroup = COLLISION_GROUP_DEBRIS_TRIGGER;	
	CreateTimer(GetConVarFloat(cvar_FreezeTime) + GetConVarFloat(cvar_NoCollisionTime), Timer_PushAway);	
	return bool:Plugin_Handled;
}

public Action:Timer_PushAway(Handle:timer)
{
	ColGroup = COLLISION_GROUP_PUSHAWAY;
	CreateTimer(GetConVarFloat(cvar_PushAwayTime), Timer_NormalCollision);	
	return Plugin_Continue;	
}

public Action:Timer_NormalCollision(Handle:timer)
{
	ColGroup = COLLISION_GROUP_PLAYER;
	return Plugin_Continue;	
}

public Action:Command_UnStuck(client, args) {
	if (client == 0) 
		return Plugin_Handled;
	
	ReplyToCommand(client, "Unstuck enable for 2 seconds!");
	g_UnstuckPlayers[client] = true;
	CreateTimer(2.0, Timer_DisablePushAwayPlayer, client);	
	return Plugin_Handled;
}

public Action:Timer_DisablePushAwayPlayer(Handle:timer, any:client)
{
	g_UnstuckPlayers[client] = false;
	return Plugin_Continue;	
}