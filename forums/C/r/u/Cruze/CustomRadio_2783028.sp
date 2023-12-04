#include <sourcemod>
#include <sdktools>
#include <multicolors>

#pragma newdecls required
#pragma semicolon 1

#define LOG_PREFIX "[CustomRadio]"
#define MAX_RADIOS 128

enum struct eCustomRadios
{
	char sName[64];
	char sPrint[64];
	char sSound[64];
}

eCustomRadios g_eRadios[MAX_RADIOS];

int g_iRadioCount = 0;

public Plugin myinfo =  
{ 
	name = "Custom Radio", 
	author = "Cruze", 
	description = "Plays custom radio to teammates.", 
	version = "1.0.0", 
	url = "https://github.com/cruze03" 
};


public void OnPluginStart()
{
	RegConsoleCmd("sm_radio", Command_Radio);
	RegAdminCmd("sm_reloadradio", Command_ReloadRadio, ADMFLAG_ROOT);
}

public void OnMapStart()
{
	ReloadConfig();
}

public Action Command_Radio(int client, int args)
{
	if(!client || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	ShowRadioMenu(client);
	return Plugin_Handled;
}

public Action Command_ReloadRadio(int client, int args)
{
	ReloadConfig();
	ReplyToCommand(client, "[SM] Reloaded custom radio file.");
	return Plugin_Handled;
}

void ShowRadioMenu(int client)
{
	Menu menu = new Menu(Handler_ShowRadioMenu);
	menu.SetTitle("Custom Radios:");
	for(int i = 0; i < g_iRadioCount; i++)
	{
		menu.AddItem("", g_eRadios[i].sName);
	}
	if(menu.ItemCount < 1)
	{
		PrintToChat(client, "[SM] No Radio(s) found.");
		delete menu;
	}
	else
	{
		menu.Display(client, 30);
	}
}

public int Handler_ShowRadioMenu(Menu menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_End:
		{	
			delete menu;
		}
		case MenuAction_Select:
		{
			PlayNPrintRadio(client, item);
		}
	}
	return 0;
}

void PlayNPrintRadio(int client, int count)
{
	int team = GetClientTeam(client);
	char sPrint[128], sName[MAX_NAME_LENGTH];

	GetClientTeam(client);
	strcopy(sPrint, 128, g_eRadios[count].sPrint);
	ReplaceString(sPrint, 128, "{NAME}", sName);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
		{
			if(sPrint[0])
			{
				CPrintToChat(i, sPrint);
			}
			if(g_eRadios[count].sSound[0])
			{
				EmitSoundToClient(i, g_eRadios[count].sSound);
			}
		}
	}
}

void ReloadConfig()
{
	char sFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFile, sizeof(sFile), "configs/custom_radios.cfg");

	if(!FileExists(sFile))
	{
		SetFailState("%s Unable to find file: \"%s\"", LOG_PREFIX, sFile);
		return;
	}
	
	KeyValues kv = new KeyValues("CustomRadio");

	if(!kv.ImportFromFile(sFile))
	{
		LogError("%s Unable to import from file: \"%s\"", LOG_PREFIX, sFile);
		delete kv;
		return;
	}
	
	kv.Rewind();

	if(!kv.GotoFirstSubKey())
	{
		LogError("%s Unable to goto first sub key: \"%s\"", LOG_PREFIX, sFile);
		delete kv;
		return;
	}
	
	for(int i = 0; i < MAX_RADIOS; i++)
	{
		 g_eRadios[g_iRadioCount].sName[0] = '\0';
		 g_eRadios[g_iRadioCount].sPrint[0] = '\0';
		 g_eRadios[g_iRadioCount].sSound[0] = '\0';
	}
	
	g_iRadioCount = 0;
	char sBuffer[256];
	do
	{
		kv.GetString("name", g_eRadios[g_iRadioCount].sName, 64, "");
		kv.GetString("print", g_eRadios[g_iRadioCount].sPrint, 128, "");
		
		kv.GetString("sound", sBuffer, 256, "");
		
		
		if(sBuffer[0])
		{
			if(FileExists(sBuffer, true) || FileExists(sBuffer, false))
			{
				AddFileToDownloadsTable(sBuffer);
				ReplaceString(sBuffer, 256, "sound/", "");
				
				PrecacheSound(sBuffer, true);
				strcopy(g_eRadios[g_iRadioCount].sSound, 256, sBuffer);
			}
			else
			{
				LogError("%s Path does not exist: \"%s\"", LOG_PREFIX, sBuffer);
			}
		}
		g_iRadioCount++;
	}
	while(kv.GotoNextKey());
}