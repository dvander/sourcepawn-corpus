/**
PLUGIN REQUEST URL - http://forums.alliedmods.net/showthread.php?t=171938
PLUGIN REQUEST USER - banania (http://forums.alliedmods.net/member.php?u=112689)

REQUEST:
	I wonder if it was possible to make a script that slay people who throw the bomb.
	I have a rush server and it's very disabling when someone throws the bomb, so I'd like to end this problem.
	
	Regarding the timer and the message WARNING in my case I do not want to have for the simple reason that the 
	rules change as soon as the bomb and thrown or given (CSS not being the difference) I must so just a script for 
	people giving or throwing the bomb.
	
	will be possible to make sure to have a sentence that appears at the slay to configure so that it can take several 
	languages?
	
SOLUTION:
	This plugin will do the following if a player drops the bomb:
	
	1.	If a player merely gives the bomb to another player, it will not do anything
		-	It allows 1/2 seconds for the bomb to be picked up by another (or the same) player before anything starts to happen
	
	2.	If configured with the cvar sm_dropbombslay_dropwarn, this plugin will warn the player that they have X seconds
		to pick the bomb up or they will get slayed.
		-	The message is in a translation file, so just add new languages as you see fit.  Just follow the same format for the messages
			and don't change anything other than adding a new language line for each event you want.
	
	3.	The amount of time before the player is slayed is controlled via the cvar sm_dropbombslay_timer
	
	4.	If the bomb is picked up within the allotted time, no slay will happen.  If configured with the cvar sm_dropbombslay_advisepickup,
		the player will be notified that someone picked up the bomb for them.  If they pick it back up themselves, no notification happens.
		
	5.	If the bomb is not picked up in the allotted time the player is slayed - if they're still alive.
	
	All cvars are configured through the config file BombDropSlay.plugin.cfg
	
	All translation text is maintained in the BombDropSlay.phrases.txt
	
**/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

new Handle:ClientTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:ClientTimer2[MAXPLAYERS+1] = INVALID_HANDLE;

new WhoHadBomb;

new Float:DropTimer;
new DropTimer2;
new bool:WarnOnDrop;
new bool:AdviseOnPickup;
new bool:AdviseOnSlay;
new bool:RoundEnd;

new bool:BombDropped = false;

public Plugin:myinfo = 
{
	name = "Drop Bomb Slay",
	author = "TnTSCS & Impact123",
	description = "Slays a player if they drop the bomb while alive",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_dropbombslay_version", PLUGIN_VERSION, "Drop Bomb Slay Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	CreateConVar("sm_dropbombslay_version_build", SOURCEMOD_VERSION, "The version of SourceMod that 'Drop Bomb Slay' was compiled with.", FCVAR_PLUGIN);
	
	new Handle:hRandom;// KyleS Hates handles
	
	HookConVarChange((hRandom = CreateConVar("sm_dropbombslay_timer", "10", 
	"Number of seconds to allow the bomb to be picked up before the player who dropped it is slayed.", _, true, 0.1, true, 120.0)), TimerChanged);
	DropTimer = GetConVarFloat(hRandom);
	DropTimer2 = GetConVarInt(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_dropbombslay_adviseslay", "1", 
	"1=Advise the player they were slayed because they dropped the bomb.  0=Don't advise the player why they were slayed.", _, true, 0.0, true, 1.0)), AdviseSlayChanged);
	AdviseOnSlay = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_dropbombslay_dropwarn", "1", 
	"1=Warn the player when they drop the bomb.  0=Don't warn the player when they drop the bomb.", _, true, 0.0, true, 1.0)), DropWarnChanged);
	WarnOnDrop = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_dropbombslay_advisepickup", "1", 
	"1=Advise player the bomb was picked up by another player.  0=Don't advise player the bomb was picked up by another player.", _, true, 0.0, true, 1.0)), AdvisePickupChanged);
	AdviseOnPickup = GetConVarBool(hRandom);
	
	CloseHandle(hRandom);// KyleS Hates handles
	
	HookEvent("bomb_dropped", OnBombDropped);
	HookEvent("bomb_pickup", OnBombPickedup);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	
	LoadTranslations("BombDropSlay.phrases");
	
	// Execute the config file
	AutoExecConfig(true, "BombDropSlay.plugin");
}

public OnBombDropped(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	ClientTimer2[client] = CreateTimer(0.5, t_BombDropped, client);
	
	WhoHadBomb = 0;
}

public Action:t_BombDropped(Handle:timer, any:client)
{
	if(IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && ClientTimer2[client] != INVALID_HANDLE)
	{
		ClientTimer2[client] = INVALID_HANDLE;
		
		if(WarnOnDrop)
			PrintToChat(client, "%t", "Bomb_Dropped", DropTimer2);
			
		BombDropped = true;
		
		WhoHadBomb = GetClientUserId(client);
		
		ClientTimer[client] = CreateTimer(DropTimer, t_BombDropSlay, client);
	}
}

public OnBombPickedup(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new client2 = GetClientOfUserId(WhoHadBomb);
	
	BombDropped = false;
	
	if(client == client2)
	{
		if(IsClientInGame(client) && IsClientConnected(client))
		{
			ClearTimer(ClientTimer[client]);
			ClearTimer(ClientTimer2[client]);
		}

		return;
	}
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsClientConnected(i))
		{
			ClearTimer(ClientTimer[i]);
			ClearTimer(ClientTimer2[i]);
		}
	}
	
	if(AdviseOnPickup && !RoundEnd && WhoHadBomb != 0)
		PrintToChat(client2, "%t", "Bomb_Pickup_Team", client);
}

public Action:t_BombDropSlay(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsClientConnected(client) && BombDropped && ClientTimer[client] != INVALID_HANDLE)
	{
		ForcePlayerSuicide(client);
		
		if(AdviseOnSlay)
			PrintToChat(client, "%t", "Player_Slayed");
			
		ClientTimer[client] = INVALID_HANDLE;
	}
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	ClearTimer(ClientTimer[client]);
	ClearTimer(ClientTimer2[client]);
}

public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		ClearTimer(ClientTimer[client]);
		ClearTimer(ClientTimer2[client]);
	}
}

stock ClearTimer(&Handle:timer)  
{  
    if (timer != INVALID_HANDLE)  
    {  
        KillTimer(timer);  
    }  
    timer = INVALID_HANDLE;  
}

public OnRoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	RoundEnd = false;
}

public OnRoundEnd(Handle:event, String:name[], bool:dontBroadcast)
{
	RoundEnd = true;
}

public TimerChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	DropTimer = GetConVarFloat(cvar);
	DropTimer2 = GetConVarInt(cvar);
}

public AdviseSlayChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	AdviseOnSlay = GetConVarBool(cvar);
}

public DropWarnChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	WarnOnDrop = GetConVarBool(cvar);
}

public AdvisePickupChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	AdviseOnPickup = GetConVarBool(cvar);
}