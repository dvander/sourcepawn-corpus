#include <sourcemod>
#include <sdktools>
#include <multicolors>

#pragma newdecls required
#pragma semicolon 1

#define LOG_PREFIX "[CustomRadio]"
#define PREFIX "{green}[CustomRadio]{default}"
#define MAX_RADIOS 128

enum struct eCustomRadios
{
	char sName[64];
	char sCommand[64];
	char sPrint[128];
	char sSound[256];
	float fVolume;
}

eCustomRadios g_eRadios[MAX_RADIOS];

int g_iRadioCount = 0;
float g_fCD[MAXPLAYERS+1], g_fCooldown;
ConVar g_hCooldown;

public Plugin myinfo =  
{ 
	name = "Custom Radio", 
	author = "Cruze", 
	description = "Plays custom radio to teammates.", 
	version = "1.0.3", 
	url = "https://github.com/cruze03"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_radio", Command_Radio);
	RegAdminCmd("sm_reloadradio", Command_ReloadRadio, ADMFLAG_ROOT);
	
	g_hCooldown = CreateConVar("sm_customradio_cooldown", "2.0", "Per Player Cooldown for radio.");
	HookConVarChange(g_hCooldown, OnConVarChanged);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public int OnConVarChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(strcmp(oldValue, newValue, false) == 0)
	{
		return 0;
	}
	g_fCooldown = g_hCooldown.FloatValue;
	return 0;
}

public void OnMapStart()
{
	g_fCooldown = g_hCooldown.FloatValue;
	
	ReloadConfig();
}

public void OnClientPutInServer(int client)
{
	g_fCD[client] = 0.0;
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
	CReplyToCommand(client, "%s Reloaded custom radio file.", PREFIX);
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
		CPrintToChat(client, "%s No Radio(s) found.", PREFIX);
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
	float fTime = GetGameTime();
	
	if(g_fCD[client] > fTime)
	{
		CPrintToChat(client, "%s Radio is in cooldown. [%.0fs]", PREFIX, g_fCD[client]-fTime);
		return;
	}
	
	g_fCD[client] = fTime + g_fCooldown;
	
	int team = GetClientTeam(client);
	char sPrint[128], sName[MAX_NAME_LENGTH];

	GetClientName(client, sName, MAX_NAME_LENGTH);
	strcopy(sPrint, 128, g_eRadios[count].sPrint);
	ReplaceString(sPrint, 128, "{NAME}", sName, false);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
		{
			if(sPrint[0])
			{
				CPrintToChat(i, "%s %s", PREFIX, sPrint);
			}
			if(g_eRadios[count].sSound[0])
			{
				EmitSoundToClient(i, g_eRadios[count].sSound, _, _, _, _, g_eRadios[count].fVolume);
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
		 g_eRadios[g_iRadioCount].sCommand[0] = '\0';
		 g_eRadios[g_iRadioCount].sPrint[0] = '\0';
		 g_eRadios[g_iRadioCount].sSound[0] = '\0';
		 
		 g_eRadios[g_iRadioCount].fVolume = 1.0;
	}
	
	g_iRadioCount = 0;
	char sBuffer[256], sCommand[64];
	do
	{
		kv.GetString("name", g_eRadios[g_iRadioCount].sName, 64, "");
		kv.GetString("command", sCommand, 64, "");
		kv.GetString("print", g_eRadios[g_iRadioCount].sPrint, 128, "");
		
		g_eRadios[g_iRadioCount].fVolume = kv.GetFloat("volume", 1.0);
		if(g_eRadios[g_iRadioCount].fVolume < 0.1)
		{
			g_eRadios[g_iRadioCount].fVolume = 0.1;
		}
		
		if(CommandExists(sCommand))
		{
			LogError("%s Command already exists: \"%s\"", LOG_PREFIX, sCommand);
		}
		else
		{
			strcopy(g_eRadios[g_iRadioCount].sCommand, 64, sCommand);
			AddCommandListener(CommandListener_Radio, sCommand);
		}
		
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
	
	delete kv;
}

public Action CommandListener_Radio(int client, const char[] command, int args)
{
	for(int i = 0; i < g_iRadioCount; i++)
	{
		if(strcmp(command, g_eRadios[i].sCommand) == 0)
		{
			PlayNPrintRadio(client, i);
			break;
		}
	}
	return Plugin_Continue;
}