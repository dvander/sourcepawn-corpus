#pragma semicolon 1

#define PLUGIN_AUTHOR "Kasea"
#define PLUGIN_VERSION "1.0.0"
#define URLSIZE 512

#include <sourcemod>

public Plugin myinfo = 
{
	name = "[K] Music",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_soundhelp", cmd_help);
	RegConsoleCmd("sm_sound", cmd_sound);
	RegConsoleCmd("sm_soundyt", cmd_soundyt);
	RegConsoleCmd("sm_stopsound", cmd_stopsound);
	RegConsoleCmd("sm_soundstop", cmd_stopsound);
	RegConsoleCmd("sm_volume", cmd_volume);
	RegConsoleCmd("sm_soundurl", cmd_soundurl);
}

public Action cmd_help(int client, int args)
{
	ReplyToCommand(client, "[K-Music] Commands are !sound(soundcloud), !soundyt(youtube), !soundstop, !volume x(type something for youtube) and !soundurl");
}

public Action cmd_sound(int client, int argsNum)
{
	if(argsNum<1)
	{
		ReplyToCommand(client, "[K-Music] sm_sound name of song");
	}else
	{
		char args[128];
		GetCmdArgString(args, 128);
		char url[URLSIZE];
		Format(url, URLSIZE, "https://duckduckgo.com/?q=!ducky+%s+site%3Asoundcloud.com", args);
		CreateMotd(client, url, false);
	}
	return Plugin_Handled;
}

public Action cmd_soundyt(int client, int argsNum)
{
	if(argsNum<1)
	{
		ReplyToCommand(client, "[K-Music] sm_sound name of song");
	}else
	{
		char args[128];
		GetCmdArgString(args, 128);
		char url[URLSIZE];
		Format(url, URLSIZE, "https://duckduckgo.com/?q=!ducky+%s+site%3Ayoutube.com", args);
		CreateMotd(client, url, false);
	}
	return Plugin_Handled;
}

public Action cmd_stopsound(int client, int args)
{
	CreateMotd(client, "http://google.com", false);
	return Plugin_Handled;
}

public Action cmd_volume(int client, int args)
{
	//ReplyToCommand(client, "[K-Music] sm_volume x(add whatever if you want to edit the volume on youtube)");
	if(args>0)
		CreateMotd(client, "http://youtube.com/watch?v=YQHsXMglC9A", true);
	else
		CreateMotd(client, "soundcloud.com/liannajoymusic/adele-hello-cover-by-lianna-joy", true);
	return Plugin_Handled;
}
public Action cmd_soundurl(int client, int args)
{
	if(args<1)
	{
		ReplyToCommand(client, "sm_soundurl url 0/1");
	}else
	{
		bool show = false;
		if(args == 2)
		{
			char buffer[3];
			GetCmdArg(2, buffer, 3);
			switch(StringToInt(buffer))
			{
				case 0:show = true;
				case 1:show = false;
			}
		}
		char url[URLSIZE];
		if(args == 1)
			GetCmdArgString(url, URLSIZE);
		else
			GetCmdArg(1, url, URLSIZE);
		CreateMotd(client, url, show);
	}
	
	return Plugin_Handled;
}

public void CreateMotd(int client, char[] url, bool show)
{
	char urlz[URLSIZE];
	Format(urlz, URLSIZE, url);
	if (StrContains(urlz, "http://", true) == -1 && StrContains(urlz, "https://", true) == -1)Format(urlz, URLSIZE, "http://%s", urlz);
	if(show)
		Format(urlz, URLSIZE, "http://www.cola-team.com/franug/webshortcuts2.php?web=height=720,width=1280;franug_is_pro;%s", urlz);
	KeyValues kv = new KeyValues("data");
	kv.SetString("title", "Music plugin by Kasea");
	kv.SetString("type", "2");
	kv.SetString("msg", urlz);
	ShowVGUIPanel(client, "info", kv, show);
	delete kv;
}