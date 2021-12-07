#include <sourcemod>
#include <sdktools>

#define DATA "1.0"

#pragma newdecls required

public Plugin myinfo = 
{
	name = "SM Debug for Server Crashes",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

char g_sCmdLogPath_dump[256];
char g_sCmdLogPath_entities[256];

public void OnPluginStart()
{    
 	for(int i=0;;i++)
	{
		Format(g_sCmdLogPath_dump, 256, "sm_dumb_handles_%d.log", i);
		if ( !FileExists(g_sCmdLogPath_dump) ) // use different file on new plugin load (for dont override on server crash)
			break;
	}
	
	for(int i=0;;i++)
	{
		BuildPath(Path_SM, g_sCmdLogPath_entities, sizeof(g_sCmdLogPath_entities), "logs/entidades_%d.log", i);
		if ( !FileExists(g_sCmdLogPath_entities) )
			break;
	}
	
	CreateTimer(120.0, Timer_Dump, _, TIMER_REPEAT); // execute dump handles for try to have the latest log before the crash
	
	HookEvent("round_prestart", Event_Start, EventHookMode_Pre); // between round end and round start
}

public void Event_Start(Event event, const char[] name, bool dontBroadcast) 
{
    if (FileExists(g_sCmdLogPath_entities))
    	DeleteFile(g_sCmdLogPath_entities); // delete on new round for dont have a extremly big log
}

public Action Timer_Dump(Handle timer)
{
	ServerCommand("sm_dump_handles %s", g_sCmdLogPath_dump); // dump sourcemod handles
}

public void OnEntityCreated(int ent, const char[] classname)
{
	LogToFile(g_sCmdLogPath_entities, "E %i n %s", ent, classname); // log all new entities
}