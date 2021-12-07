#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define PLUGIN_VERSION "1.0"

new Handle:g_Cookie = INVALID_HANDLE;
new Handle:g_Reason = INVALID_HANDLE;

new Handle:g_Timer = INVALID_HANDLE;

new Handle:g_RoundEnd = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Roundend",
	author = "Zephyrus",
	description = "Privately coded plugin for -[FF]- Fire.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	g_Reason = CreateConVar("sm_rr_reason", "9");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	g_Cookie = RegClientCookie("mapname", "mapname", CookieAccess_Private);
	
	new Handle:hGameConf = LoadGameConfigFile("roundend");
	
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(hGameConf,SDKConf_Signature,"EndRound");
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); 
	g_RoundEnd=EndPrepSDKCall();
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new freezetime = GetConVarInt(FindConVar("mp_freezetime"));
	new roundtime = GetConVarInt(FindConVar("mp_roundtime"));
	new Float:time = freezetime+roundtime*60-10.0;
	if(g_Timer != INVALID_HANDLE)
	{
		CloseHandle(g_Timer);
	}
	g_Timer = CreateTimer(time, RoundTimer);
	
	new String:times[64];
	IntToString(GetTime(), times, sizeof(times));

	for(new i=1;i<=MaxClients;++i)
	{
		if(IsClientInGame(i))
			SetClientCookie(i, g_Cookie, times);
	}
	
	return Plugin_Continue;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_Timer != INVALID_HANDLE)
	{
		CloseHandle(g_Timer);
		g_Timer = INVALID_HANDLE;
	}
	
	new String:time[64];
	IntToString(GetTime(), time, sizeof(time));
	
	for(new i=1;i<=MaxClients;++i)
	{
		if(IsClientInGame(i))
			SetClientCookie(i, g_Cookie, time);
	}
	
	return Plugin_Continue;
}

public Action:RoundTimer(Handle:timer, any:data)
{
	PrintToChatAll("\x04The round is about to end in 10 seconds.");
	CreateTimer(10.0, EndRound);
	g_Timer = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:EndRound(Handle:timer, any:data)
{
	SDKCall(g_RoundEnd, 5.0, GetConVarInt(g_Reason));
	
	return Plugin_Stop;
}
   



	


