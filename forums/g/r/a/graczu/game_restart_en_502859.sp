#include <sourcemod>

#define VERSION "1.1"

new Handle:g_Timer_One = INVALID_HANDLE;
new Handle:g_Timer_Two = INVALID_HANDLE;
new Handle:g_Timer_Thre = INVALID_HANDLE;
new Handle:g_Timer_Res = INVALID_HANDLE;
new Handle:g_Timer_Say = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Simple Restart Round After 60s on MapChange",
	author = "graczu",
	description = "After 60s on Mapchange, plugin will restart round!",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("mapchangerestartround_version", VERSION, "Restart Round after Mapchange Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnMapStart()
{
	g_Timer_One = CreateTimer(30.0, SayRestart1)
}

public Action:SayRestart1(Handle:timer)
{
	PrintToChatAll("[RoundRestart] Round restart in: 30s");
	g_Timer_Two = CreateTimer(10.0, SayRestart2);
	KillTimer(g_Timer_One);		
}

public Action:SayRestart2(Handle:timer)
{
	PrintToChatAll("[RoundRestart] Round restart in: 20s");
	g_Timer_Thre = CreateTimer(10.0, SayRestart3);
	KillTimer(g_Timer_Two);		
}

public Action:SayRestart3(Handle:timer)
{
	PrintToChatAll("[RoundRestart] Round restart in: 10s");
	g_Timer_Res = CreateTimer(10.0, RoundRez);
	KillTimer(g_Timer_Thre);		
}

public Action:RoundRez(Handle:timer)
{
	KillTimer(g_Timer_Res);
	g_Timer_Say = CreateTimer(1.0, RezSay);
	ServerCommand("mp_restartgame 1");
}

public Action:RezSay(Handle:timer)
{
	KillTimer(g_Timer_Say);
	PrintToChatAll("* [PLAY] GL & HF :-) *");
	PrintCenterTextAll("* [PLAY] GL & HF :-) *");
}
