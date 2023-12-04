#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

static String:FakeName[20] =  { "Micmacx" };

public Plugin:myinfo = 
{
	name = "First bot", 
	author = "Micmacx", 
	description = "Create first bot for Rcbot2 1.3", 
	version = PLUGIN_VERSION, 
	url = "https://dods.neyone.fr"
};

public OnPluginStart() 
{
	CreateConVar("dod_first_bot", PLUGIN_VERSION, "DoS:S first bot for Rcbot2 1.3", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
}

public OnMapStart() 
{
	CreateTimer(1.0, OnTimedCreateFakeClient, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:OnTimedCreateFakeClient(Handle:timer) 
{
	CreateFakeClient(FakeName);
	CreateTimer(5.0, OnTimedKickme, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:OnTimedKickme(Handle:timer) 
{
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i) && IsFakeClient(i)) 
		{
			new String:testname[20];
			GetClientName(i, testname, 20);
			if (StrEqual(testname, FakeName))
			{
				KickClient(i, "Start Bot");
			}
		}
	}
} 
