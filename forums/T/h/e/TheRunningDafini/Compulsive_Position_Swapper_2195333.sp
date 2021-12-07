#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


#define PL_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "[TF2] Compulsive Position Swapper",
	author = "Dafini",
	description = "Kill someone, Take their spot, by typing in /swap in chat",
	version = PL_VERSION,
	url = "http://www.sourcemod.net"
}

//SM CALLBACKS

new SwapperVar = 0;
new Handle:TheVictim = INVALID_HANDLE;
new Handle:TheKiller = INVALID_HANDLE;
new Handle:KillerClient = INVALID_HANDLE;
new Handle:KilledClient = INVALID_HANDLE;

public OnPluginStart()
{
	RegConsoleCmd("sm_swap", Command_Swap);
	RegConsoleCmd("sm_swapf", Command_Swapf);
	RegConsoleCmd("sm_swaphelp", Command_SwapHelp);
    HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
}

public Action:Command_Swap(client, args){
	if(SwapperVar == 0)
	{
		SwapperVar = 1;
	}	else if(SwapperVar == 1)	{
		SwapperVar = 0;
	}	else if(SwapperVar == 2)	{
		SwapperVar = 1;
	}
}

public Action:Command_Swapf(client, args){
	if(SwapperVar == 0)
	{
		SwapperVar = 2;
	}	else if(SwapperVar == 1)	{
		SwapperVar = 2;
	}	else if(SwapperVar == 2)	{
		SwapperVar = 0;
	}
}

public Action:Command_SwapHelp(client, args){
	PrintToChat(client, "Type !swap to enable Position Swapping with your kills, and a Second time to disable it. !swapf does similar, except you face the way of your victim too.");
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
if(SwapperVar == 1)
{
    TheVictim = GetEventInt(event, "userid");
    TheKiller = GetEventInt(event, "attacker");
    KilledClient = GetClientOfUserId(TheVictim);
    KillerClient = GetClientOfUserId(TheKiller);
    new Float:VictimPos[3];
    new Float:ClientEyes[3];
    GetClientAbsOrigin(KilledClient, VictimPos);
    GetClientEyeAngles(KilledClient, ClientEyes);
    TeleportEntity(KillerClient, VictimPos, NULL_VECTOR, NULL_VECTOR);
}
else if(SwapperVar == 2)
{
    TheVictim = GetEventInt(event, "userid");
    TheKiller = GetEventInt(event, "attacker");
    KilledClient = GetClientOfUserId(TheVictim);
    KillerClient = GetClientOfUserId(TheKiller);
    new Float:VictimPos[3];
    new Float:ClientEyes[3];
    GetClientAbsOrigin(KilledClient, VictimPos);
    GetClientEyeAngles(KilledClient, ClientEyes);
    TeleportEntity(KillerClient, VictimPos, ClientEyes, NULL_VECTOR);
}
}