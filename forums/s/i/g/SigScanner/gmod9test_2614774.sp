#include <sourcemod>
#include <gmod9>

public Plugin myinfo = {
	name = "GMod 9 Test",
	author = "SigScanner (aka n0thing)"
};

public Action PlayerInitialSpawn(Event event,const char[] name,bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	GModSpawnMenu_AddItem(client,"sourcemod","+test1","test1");
	GModSpawnMenu_AddItem(client,"sourcemod","+test2","test2");
	GModSpawnMenu_AddItem(client,"sourcemod","+test3","test3");
	GModSpawnMenu_AddItem(client,"sourcemod","+test4","test4");
	return Plugin_Continue;
}

public Action Command_Test1(client,args)
{
	GModText_Send(client,201,"Hello world!!!","DefaultShadow",255,255,255,255,0.4,0.4,999.0);
	return Plugin_Handled;
}

public Action Command_Test2(client,args)
{
	GModText_Hide(client,201,0.0,0.0);
	return Plugin_Handled;
}

public Action Command_Test3(client,args)
{
	GModRect_Send(client,202,"gmod/white",255,0,0,128,0.1,0.1,0.9,0.9,999.0);
	return Plugin_Handled;
}

public Action Command_Test4(client,args)
{
	GModRect_Hide(client,202,0.0,0.0);
	return Plugin_Handled;
}

public OnPluginStart()
{
	RegConsoleCmd("test1",Command_Test1);
	RegConsoleCmd("test2",Command_Test2);
	RegConsoleCmd("test3",Command_Test3);
	RegConsoleCmd("test4",Command_Test4);
	
	HookEvent("player_spawn",PlayerInitialSpawn);
}