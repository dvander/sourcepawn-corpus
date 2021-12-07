/*
adminsounds.sp

Description:
	Allows admins to play sounds from a menu

Versions:
	1.0
		* Initial Release
		
	1.0.1
		* Increased the max number of sounds to 50
		* Added error checking on the number of sounds

	1.0.2
		* Modified by o_O.Uberman.O_o upon request of|HS|Jesus
		* Added a chat "!stop" command to allow players to stop sounds started by this plug-in
	1.0.3
		* Modified by |HS|Jesus
		* Added output of what sound is playing  

*/


#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0.3"
#define MAX_FILE_LEN 100
#define MAX_SOUNDS 100
#define MAX_DISPLAY_LENGTH 100

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Admin Sounds",
	author = "dalto,o_O.Uberman.O_o,|HS|Jesus",
	description = "Allows admins to play sounds from a menu",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

new String:g_displayNames[MAX_SOUNDS][MAX_FILE_LEN];
new String:g_soundNames[MAX_SOUNDS][MAX_DISPLAY_LENGTH];
new g_numSounds;
new String:SndPlaying[MAXPLAYERS+1][PLATFORM_MAX_PATH];

public OnPluginStart()
{
	// Create the rest of the cvar's
	CreateConVar("sm_admin_sounds_version", PLUGIN_VERSION, "Admin Sounds Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_admin_sounds", AdminSoundsMenu, ADMFLAG_GENERIC);
        RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);

	LoadSounds();
}

// On map start we Precache the sound and add the file to the downloads table
public OnMapStart()
{
	decl String:buffer[MAX_FILE_LEN];
	for(new i = 0; i < g_numSounds; i++)
	{
		PrecacheSound(g_soundNames[i], true);
		Format(buffer, MAX_FILE_LEN, "sound/%s", g_soundNames[i]);
		AddFileToDownloadsTable(buffer);
	}
}

// Loads the soundsList array with the quake sounds
public LoadSounds()
{
	decl String:filename[MAX_FILE_LEN];
	BuildPath(Path_SM, filename, MAX_FILE_LEN, "configs/soundlist.txt");
	new Handle:hFile = OpenFile(filename, "r");
	
	if(hFile == INVALID_HANDLE)
	{
		SetFailState("addons/sourcemod/configs/soundlist.txt not found");
		return;
	}
	
	g_numSounds = 0;
	decl String:line[250];
	new pos;
	while(ReadFileLine(hFile, line, sizeof(line)) && g_numSounds < MAX_SOUNDS + 1)
	{
		if(!(line[0] == '/' && line[1] == '/'))
		{
			g_displayNames[g_numSounds][0] = 0;
			g_soundNames[g_numSounds][0] = 0;
			pos = BreakString(line, g_displayNames[g_numSounds], sizeof(g_displayNames[]));
			if(strcmp(g_displayNames[g_numSounds], ""))
			{
				strcopy(g_soundNames[g_numSounds], sizeof(g_soundNames[]), line[pos]);
				if(strcmp(g_soundNames[g_numSounds], ""))
				{
					TrimString(g_soundNames[g_numSounds]);
					g_numSounds++;
				}
			}
		}
	}
	
	CloseHandle(hFile);
}

public Action:AdminSoundsMenu(client, args)
{
	new Handle:menu = CreateMenu(AdminSoundsMenuHandler);
	
	SetMenuTitle(menu, "Admin sounds");
	
	for(new i = 0; i < g_numSounds; i++)
	{
		AddMenuItem(menu, "admin sounds", g_displayNames[i]);
	}
 
	SetMenuExitButton(menu, true);

	DisplayMenu(menu, client, 20);
 
	return Plugin_Handled;
}

public AdminSoundsMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		PlaySound(param2);
		AdminSoundsMenu(param1, 0);
	} else if(action == MenuAction_End)	{
		CloseHandle(menu);
	}
}

public PlaySound(soundKey)
{
	new clientlist[MAXPLAYERS+1];
	new clientcount = 0;
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			clientlist[clientcount++] = i;
			strcopy(SndPlaying[i], sizeof(SndPlaying[]), g_soundNames[soundKey]);
		}
	}

	if(clientcount)
	{
		EmitSound(clientlist, clientcount, g_soundNames[soundKey]);
		PrintToChatAll("\x04[SM]Admin Sounds: Now Playing - \x01%s", g_displayNames[soundKey]);
		PrintToChatAll("\x00\x01[SM]Type \x04!stop \x01to stop the music if you don't like it");
	}
}

public Action:Command_Say(client,args)
{
        if(client == 0)
		return Plugin_Continue;

	decl String:speech[128];
	GetCmdArgString(speech,sizeof(speech));

	new startidx = 0;
	if (speech[0] == '"')
	{
		startidx = 1;
		/* Strip the ending quote, if there is one */
		new len = strlen(speech);
		if (speech[len-1] == '"')
		{
			speech[len-1] = '\0';
		}
	}

	if(strcmp(speech[startidx],"!stop",false) == 0)
	{
		if(SndPlaying[client][0])
		{
			StopSound(client,SNDCHAN_AUTO,SndPlaying[client]);
			SndPlaying[client] = "";
		}
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
