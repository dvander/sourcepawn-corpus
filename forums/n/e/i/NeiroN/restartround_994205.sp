#include <sourcemod>

#define VERSION "2.0"

new Handle:g_Timer_Say = INVALID_HANDLE;
new Handle:g_Timer_Res = INVALID_HANDLE;
new Handle:g_Cvar_Auto_timer = INVALID_HANDLE;
new Handle:g_Cvar_Auto_interval = INVALID_HANDLE;
new Handle:g_Timer_SayFinal = INVALID_HANDLE;
new s_restimer = 0;
new s_interval = 0;

public Plugin:myinfo =
{
	name = "Restart Round After MapChange",
	author = "NeiroN",
	description = "After Mapchange, plugin will restart round!",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("restartround.phrases");
	
	CreateConVar("sm_restartround_version", VERSION, "Restart Round after Mapchange Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_Auto_timer = CreateConVar("sm_autorestart", "30.0" , "Time (in seconds) before map be restarted after load", 0, true, 10.0, true, 120.0);
	g_Cvar_Auto_interval = CreateConVar("sm_autorestart_sayinterval", "10.0" , "Interval (in seconds) to say restart round", 0, true, 1.0, true, 30.0);
	
}

public OnMapStart()
{
	s_restimer = GetConVarInt(g_Cvar_Auto_timer);
	g_Timer_Say = CreateTimer(0.1, SayRestart0);
}

public Action:SayRestart0(Handle:timer)
{
	if(s_restimer <= GetConVarInt(g_Cvar_Auto_interval))
		{
		PrintCenterTextAll("%t", "Round restart in", s_restimer);
		}else{
		if(s_interval == 0)
			{
			PrintToChatAll("[SM] %t", "Round restart in", s_restimer);
			s_interval = GetConVarInt(g_Cvar_Auto_interval);
			}
		}
	s_restimer--;
	s_interval--;
	KillTimer(g_Timer_Say);
	if (s_restimer == 1)
	{
	g_Timer_Res = CreateTimer(1.0, RestartT);
	}else{
	g_Timer_Say = CreateTimer(1.0, SayRestart0);
	}
}

public Action:RestartT(Handle:timer)
{
	KillTimer(g_Timer_Res);		
	ServerCommand("mp_restartgame 1");
	g_Timer_SayFinal = CreateTimer(1.0, RezSay);
}


public Action:RezSay(Handle:timer)
{
	KillTimer(g_Timer_SayFinal);
	PrintToChatAll("[SM] %t", "Round restarted");
	PrintCenterTextAll("%t", "Round restarted");
}
