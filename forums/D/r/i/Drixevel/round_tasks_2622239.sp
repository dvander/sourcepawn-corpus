//Pragma
#pragma semicolon 1
#pragma newdecls required

//Sourcemod Includes
#include <sourcemod>

public Plugin myinfo =
{
	name = "Round Tasks",
	author = "Keith Warren (Shaders Allen)",
	description = "Creates timers and does basic tasks with server commands.",
	version = "1.0.0",
	url = "https://github.com/ShadersAllen"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_OnRoundStart);
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/round_tasks.cfg");
	
	KeyValues kv = new KeyValues("round_tasks");
	
	if (!kv.ImportFromFile(sPath) || !kv.GotoFirstSubKey())
	{
		delete kv;
		return;
	}
	
	float seconds; float minutes; float hours; char sTask[256];
	float total;
	
	do
	{
		kv.GetString("task", sTask, sizeof(sTask));
		seconds = kv.GetFloat("seconds");
		minutes = kv.GetFloat("minutes");
		hours = kv.GetFloat("hours");
		
		total = seconds;
		
		if (minutes > 0.0)
			total += (minutes * 60.0);
			
		if (hours > 0.0)
			total += (hours * 3600.0);
		
		DataPack pack;
		CreateDataTimer(total, Timer_ExecuteTask, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteString(sTask);
	}
	while (kv.GotoNextKey());
	
	delete kv;
}

public Action Timer_ExecuteTask(Handle timer, DataPack pack)
{
	pack.Reset();
	
	char sTask[256];
	pack.ReadString(sTask, sizeof(sTask));
	
	ServerCommand(sTask);
}