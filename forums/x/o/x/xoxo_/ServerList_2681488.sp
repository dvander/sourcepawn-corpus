
#pragma semicolon 1

#define DEBUG
 
#define PLUGIN_AUTHOR "xoxo^^"
#define PLUGIN_VERSION "2.0"
 
#include <sourcemod>
#include <sdktools>
#include <cstrike>

char PREFIX[64];

char Path[] = "configs/ServerList.cfg";

StringMap ServersTrie;

public Plugin myinfo =
{
	name = "ServerList",
	description = "[CS:GO] Advanced Servers IP Menu",
	author = "xoxo^^",
	version = "1.00",
	url = ""
};
 
public void OnPluginStart()
{
	
	RegConsoleCmd("sm_servers", Servers);
	RegConsoleCmd("sm_server", Servers);
	RegConsoleCmd("sm_s", Servers);
	RegConsoleCmd("sm_serverlist", Servers);
	
	Handle convar = CreateConVar("sm_server_prefix", "SM");
	
	GetConVarString(convar, PREFIX, sizeof(PREFIX));
	
	HookConVarChange(convar, onConVarChange_PREFIX);
	ServersTrie = new StringMap();
	
	ReadConfigFile();
}

public void onConVarChange_PREFIX(Handle convar, char[] oldValue, char[] newValue)
{
	FormatEx(PREFIX, sizeof(PREFIX), newValue);
}
public void ReadConfigFile()
{
	char FullPath[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, FullPath, sizeof(FullPath), Path, sizeof(Path));
	
	if(!FileExists(FullPath))
		UC_CreateEmptyFile(FullPath);
		
	KeyValues kv = new KeyValues("Server List");
	kv.ImportFromFile(FullPath);
	
	kv.GotoFirstSubKey();
	
	char Name[64];
	char IPAddress[35];
	
	do
	{
		kv.GetString("name", Name, sizeof(Name));
		kv.GetString("address", IPAddress, sizeof(IPAddress));
		
		ServersTrie.SetString(Name, IPAddress);
	}
	while(kv.GotoNextKey());
	
	delete kv;
}

public Action Servers(int client, int args)
{
	Menu menu = new Menu(MenuHandler1);
	menu.SetTitle(" [%s] ServerList " ,PREFIX);
	
	StringMapSnapshot TrieSnapshot = ServersTrie.Snapshot();
	
	new String:Name[64], String:IPAddress[64];
	for(int i=0;i < TrieSnapshot.Length;i++)
	{
		TrieSnapshot.GetKey(i, Name, sizeof(Name));
		
		ServersTrie.GetString(Name, IPAddress, sizeof(IPAddress));
		
		menu.AddItem(IPAddress, Name);
	}
	
	delete TrieSnapshot;
	
	menu.ExitButton = true;
	menu.Display(client, 20);
	return Plugin_Handled;
}
 
public int MenuHandler1(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_End)
	{
		delete menu;
		
		return;
	}
	else if (action == MenuAction_Select)
	{
		
		char info[32], name[64];
		
		int dummy_value;
		
		menu.GetItem(item, info, sizeof(info), dummy_value, name, sizeof(name));
		
		PrintToChat(client, " [%s]\x07 %s\x01 Server:\x04 connect\x01 %s", PREFIX, name, info);
	}
}

stock UC_CreateEmptyFile(const char[] sPath)
{
	CloseHandle(OpenFile(sPath, "a"));
}