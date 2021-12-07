#pragma semicolon 1
#pragma tabsize 0

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdktools_sound>
#include <emitsoundany>

#define DEBUG

#define PLUGIN_AUTHOR "DeadSwim"
#define PLUGIN_VERSION "1.1"


new aktivni[64];
new onoff[64];

public Plugin myinfo = 
{
    name = "Songy",
    author = PLUGIN_AUTHOR,
    description = "",
    version = PLUGIN_VERSION,
    url = ""
}

public void OnPluginStart()
{
    
	RegConsoleCmd("sm_song", Ukamenu);   
	RegConsoleCmd("sm_songs", Ukamenu);   
    RegConsoleCmd("sm_music", Ukamenu);  
	
	RegAdminCmd("sm_songoff", off, ADMFLAG_SLAY);
	RegAdminCmd("sm_songon", on, ADMFLAG_SLAY);
}
public OnMapStart()
{
    AddFileToDownloadsTable("sound/PATH");
    PrecacheSoundAny("PATH", true);
	
	for (new i = 1; i <= MaxClients; i++)
	{
	onoff[i] = 1;
	}
	
}  
public Action:Fun_EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	for (new i = 1; i <= MaxClients; i++)
	{
	aktivni[i]=0;
	}
}

public Action Ukamenu(int client, int args)
{
	Menusong(client);
	return Plugin_Handled;
}

public Action on(int client, int args)
{
	for (new i = 1; i <= MaxClients; i++)
	{
	onoff[i] = 1;
	}
}
public Action off(int client, int args)
{
	for (new i = 1; i <= MaxClients; i++)
	{
	onoff[i] = 0;
	
	PrintToChatAll(" \x04 -- Admin vypnul /songs !!! --");
	PrintToChatAll(" \x04 -- Admin vypnul /songs !!! --");
	PrintToChatAll(" \x04 -- Admin vypnul /songs !!! --");
	PrintToChatAll(" \x04 -- Admin vypnul /songs !!! --");
	PrintToChatAll(" \x04 -- Admin vypnul /songs !!! --");
	PrintToChatAll(" \x04 -- Admin vypnul /songs !!! --");
	PrintToChatAll(" \x04 -- Admin vypnul /songs !!! --");
	}
}


void Menusong(int client)
{
	for (new i = 1; i <= MaxClients; i++)
	{
	CreateTimer(40.5, removeFlood, i);
		if (IsClientInGame(client)) {
			if(onoff[client] == 1){
				if(aktivni[i] != 1){
					aktivni[i]++;
					new Handle:menu = CreateMenu(select, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
					SetMenuTitle(menu, "Sounds (!song)");

					AddMenuItem(menu, "name_in_select", "Name in menu");
									
					DisplayMenu(menu, client, MENU_TIME_FOREVER);
					}else{
					PrintToChat(client," \x04 -- You must wait, for playe next sound. --");
					}
			}else{
			PrintToChat(client," \x04 -- Admin turn off /songs !!! --");
			}
		}
	}
}
public Action removeFlood(Handle:timer, any:client){
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)) {
		aktivni[i]=0;
		}
	}
}

public select(Handle:menu, MenuAction:action, param1, param2)
{

	switch (action)
	{
		case MenuAction_Select:
		{
			//param1 is client, param2 is item

			new String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			if (StrEqual(item, "name_in_select"))
			{
			EmitSoundToAllAny("PATH", _, _, _, _, 0.50); 
			PrintToChatAll(" \x01[\x04Songs\x01] \x04Now you lisen \x01NAME", param1);
			}
			else if (StrEqual(item, "example"))
			{
			EmitSoundToAllAny("PATH", _, _, _, _, 0.50); 
			PrintToChatAll(" \x01[\x04Songs\x01] \x04Now you lisen \x01NAME", param1);
			}
		}

		case MenuAction_End:
		{
			//param1 is MenuEnd reason, if canceled param2 is MenuCancel reason
			CloseHandle(menu);

		}

	}
	return 0;
}
