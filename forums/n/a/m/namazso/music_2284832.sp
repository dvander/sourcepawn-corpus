#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#define VERSION		"1.2.3"

#define BASE_URL	"http://www.google.com/search?tbm=vid&btnI=1&q="
#define DELIMITER	"+"

public Plugin myinfo =
{
	name =			"Simple YouTube Music Player",
	author =		"namazso",
	description =	"Lets you play music from YouTube",
	version =		VERSION,
	url =			"http://namazso.eu/"
}

char sHexTable[] = "0123456789abcdef";

public void urlencode(const char[] sString, char[] sResult, int len)
{
    int from, to;
    char c;

    while(from < len)
    {
        c = sString[from++];
        if(c == 0)
        {
            sResult[to++] = c;
            break;
        }
        else if(c == ' ')
        {
            sResult[to++] = '+';
        }
        else if((c < '0' && c != '-' && c != '.') ||
                (c < 'A' && c > '9') ||
                (c > 'Z' && c < 'a' && c != '_') ||
                (c > 'z'))
        {
            if((to + 3) > len)
            {
                sResult[to] = 0;
                break;
            }
            sResult[to++] = '%';
            sResult[to++] = sHexTable[c >> 4];
            sResult[to++] = sHexTable[c & 15];
        }
        else
        {
            sResult[to++] = c;
        }
    }
}

ConVar displayurl;

public void OnPluginStart() {
	RegConsoleCmd("sm_musicyt", Cmd_PlayMusic);
	RegConsoleCmd("sm_music", Cmd_PlayMusic);
	RegConsoleCmd("sm_yt", Cmd_PlayMusic);
	RegConsoleCmd("sm_musicto", Cmd_PlayMusicTo);
	RegConsoleCmd("sm_yt_to", Cmd_PlayMusicTo);
	RegConsoleCmd("sm_musicfull", Cmd_DisplayMusic);
	RegConsoleCmd("sm_yt_full", Cmd_DisplayMusic);
	RegConsoleCmd("sm_musicstop", Cmd_StopMusic);
	RegConsoleCmd("sm_yt_stop", Cmd_StopMusic);
	CreateConVar("ytmusic_version", VERSION, "Simple YouTube Music Player Version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	displayurl = CreateConVar("ytmusic_displayurl", "", "Url to open when typing !yt_full. Change only if it doesn't work");
}

public Action Cmd_DisplayMusic(int client, int args) {
	char url[192];
	displayurl.GetString(url, sizeof(url));
	ShowMOTDPanel(client, "YouTube Music Player by namazso", url, MOTDPANEL_TYPE_URL);
	return Plugin_Handled;
}

public Action Cmd_PlayMusicTo(int client, int args)
{
	if(args <= 1){
		ReplyToCommand(client, "Usage: !yt_to <target> <music name>");
		return Plugin_Handled;
	}
	
	char arg[32], argEncoded[96], url[192]=BASE_URL, target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	GetCmdArg(1, arg, sizeof(arg));
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for(int i=2; i<=args; i++)
	{
		GetCmdArg(i, arg, sizeof(arg));
		urlencode(arg, argEncoded, sizeof(argEncoded));
		StrCat(url, sizeof(url), argEncoded);
		StrCat(url, sizeof(url), DELIMITER);
	}
	
	for (int i = 0; i < target_count; i++)
	{
		PrintToChat(target_list[i],"Music will start in a few seconds. !yt_stop to stop, !yt_full to display youtube, where you can modify the volume");
		ShowHiddenMOTDPanel(target_list[i], url, MOTDPANEL_TYPE_URL);
	}
		
	ReplyToCommand(client, "Started music for targets!");
	return Plugin_Handled;
}

public Action Cmd_PlayMusic(int client, int args)
{
	char arg[32], argEncoded[96], url[192]=BASE_URL;
	if(args == 0){
		ReplyToCommand(client, "Usage: !yt <music name>");
		return Plugin_Handled;
	}
	
	for(int i=1; i<=args; i++)
	{
		GetCmdArg(i, arg, sizeof(arg));
		urlencode(arg, argEncoded, sizeof(argEncoded));
		StrCat(url, sizeof(url), argEncoded);
		StrCat(url, sizeof(url), DELIMITER);
	}
	
	ShowHiddenMOTDPanel(client, url, MOTDPANEL_TYPE_URL);
	
	ReplyToCommand(client, "Music will start in a few seconds. !musicstop to stop, !musicfull to display youtube, where you can modify the volume");
	return Plugin_Handled;
}

public Action Cmd_StopMusic(int client, int args)
{
	ShowHiddenMOTDPanel(client, "http://example.com", MOTDPANEL_TYPE_URL);
	return Plugin_Handled;
}
public void ShowHiddenMOTDPanel(int client, char[] url, int type)
{
	Handle setup = CreateKeyValues("data");
	KvSetString(setup, "title", "YouTube Music Player by namazso");
	KvSetNum(setup, "type", type);
	KvSetString(setup, "msg", url);
	ShowVGUIPanel(client, "info", setup, false);
	delete setup;
}