#include <sourcemod>
#include <clientprefs>

#define PLUGIN_VERSION  "1.7.3"

public Plugin myinfo =
{
	name = "Soundcloud",
	author = "AlienMario",
	description = "Soundcloud background player",
	version = PLUGIN_VERSION
};

EngineVersion engineVersion;
Handle:sm_sc_url;
Handle:sm_sc_visible;
Handle:sm_sc_volume;

Handle:volume_cookie;
int volume[MAXPLAYERS+1] = {3, ...};

char last[MAXPLAYERS+1][128];
int lastTime[MAXPLAYERS+1];
int lastTrackNum[MAXPLAYERS+1];

char lastGlobalTrack[128];

public OnPluginStart(){
	engineVersion = GetEngineVersion();
	
	CreateConVar("sm_soundcloud_version", PLUGIN_VERSION, "Soundcloud version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	sm_sc_url = CreateConVar("sm_sc_url", "localhost/soundcloud.php", "Soundcloud php script location. Needs to follow the default format", FCVAR_PROTECTED);
	sm_sc_visible = CreateConVar("sm_sc_visible", "0", "1 = makes the window popup, 0 = plays in background", _, true, 0.0, true, 1.0);
	sm_sc_volume = CreateConVar("sm_sc_volume", "3", "default volume (0-10)", _, true, 0.0, true, 10.0);
	
	RegConsoleCmd("sm_sc", OnSc, "Play a song on soundcloud. Format: sm_sc song_name");
	RegAdminCmd("sm_scall", OnScAll, ADMFLAG_KICK, "Play a song on soundcloud to all players. Format: sm_scall song_name");
	
	RegConsoleCmd("sm_scnext", OnNext, "Plays next song from last played song");
	
	RegAdminCmd("sm_scset", OnScSet, ADMFLAG_KICK, "Sets the song that others can listen to. Format: sm_scset song_name");
	RegConsoleCmd("sm_sclisten", OnListen, "Listen to current song set by admin.");
	
	RegConsoleCmd("sm_scstop", OnStop, "Stops song playback");
	RegAdminCmd("sm_scstopall", OnStopAll, ADMFLAG_KICK, "Stops song playback for everyone");

	
	RegConsoleCmd("sm_scopen", OnOpen, "Opens the motd window");
	RegConsoleCmd("sm_scbring", OnOpen, "Opens the motd window");
	
	RegConsoleCmd("sm_scvol", OnVolume, "Sets soundcloud volume (0-10)");
	RegConsoleCmd("sm_scvolume", OnVolume, "Sets soundcloud volume (0-10)");
	
	RegConsoleCmd("sm_schelp", OnHelp, "Prints out soundcloud plugin help");
	
	volume_cookie = RegClientCookie("sm_soundcloud_volume", "Soundcloud player volume preference (0-10)", CookieAccess_Protected);
}

public OnClientConnected(client){
	volume[client] = GetConVarInt(sm_sc_volume);
	lastTime[client] = 0;
}

public OnClientCookiesCached(client){
	char temp[3];
	GetClientCookie(client, volume_cookie, temp, sizeof(temp));
	if(!StrEqual(temp, "")){
		volume[client] = StringToInt(temp);
	}
}

#define cPRIMARY "\x07FF9900"
#define cSECONDARY "\x07DDDD55"

#define c2PRIMARY "\x02 "
#define c2SECONDARY "\x01 "

public Action:OnSc(int client, int args){
	if(args>0){
		char arg[128];
		char url[192];
		GetCmdArgString(arg, sizeof(arg));
		getUrl(arg, url, sizeof(url), volume[client]);
		motd(client, url);
		
		strcopy(last[client], 128, arg);
		lastTime[client] = GetTime();
		lastTrackNum[client] = 0;
		
		if(engineVersion == Engine_CSGO || engineVersion == Engine_Left4Dead || engineVersion == Engine_Left4Dead2){
			PrintToChat(client, "\x01\x0B%s[SoundCloud] %sSearching for %s%s%s. See %s!schelp%s for more options.", c2PRIMARY, c2SECONDARY, c2PRIMARY, arg, c2SECONDARY, c2PRIMARY, c2SECONDARY);
		} else {
			PrintToChat(client, "%s[SoundCloud] %sSearching for %s%s%s. See %s!schelp%s for more options.", cPRIMARY, cSECONDARY, cPRIMARY, arg, cSECONDARY, cPRIMARY, cSECONDARY);
		}
	} else {
		PrintToChat(client, "Format: !sc song name");
	}
	return Plugin_Handled;
}

public Action:OnScAll(int client, int args){
	if(args>0){
		char arg[128];
		char url[192];
		GetCmdArgString(arg, sizeof(arg));
		for(int i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i)){
				getUrl(arg, url, sizeof(url), volume[i]);
				motd(i, url);
				
				strcopy(last[i], 128, arg);
				lastTime[i] = GetTime();
				lastTrackNum[i] = 0;
			}
		}
		
		if(engineVersion == Engine_CSGO || engineVersion == Engine_Left4Dead || engineVersion == Engine_Left4Dead2){
			PrintToChatAll("\x01\x0B%s[SoundCloud]%s Admin %N played %s%s%s. See %s!schelp%s for more options.", c2PRIMARY, c2SECONDARY, client, c2PRIMARY, arg, c2SECONDARY, c2PRIMARY, c2SECONDARY);
		} else {
			PrintToChatAll("%s[SoundCloud]%s Admin %N played %s%s%s. See %s!schelp%s for more options.", cPRIMARY, cSECONDARY, client, cPRIMARY, arg, cSECONDARY, cPRIMARY, cSECONDARY);
		}
	} else {
		PrintToChat(client, "Format: !scall song name");
	}
	return Plugin_Handled;
}

public Action:OnScSet(int client, int args){
	if(args>0){
		GetCmdArgString(lastGlobalTrack, sizeof(lastGlobalTrack));
		
		if(engineVersion == Engine_CSGO || engineVersion == Engine_Left4Dead || engineVersion == Engine_Left4Dead2){
			PrintToChatAll("\x01\x0B%s[SoundCloud]%s Admin %N changed the track to %s%s%s. Type %s!sclisten%s to tune in.", c2PRIMARY, c2SECONDARY, client, c2PRIMARY, lastGlobalTrack, c2SECONDARY, c2PRIMARY, c2SECONDARY);
		} else {
			PrintToChatAll("%s[SoundCloud]%s Admin %N changed the track to %s%s%s. Type %s!sclisten%s to tune in.", cPRIMARY, cSECONDARY, client, cPRIMARY, lastGlobalTrack, cSECONDARY, cPRIMARY, cSECONDARY);
		}
	} else {
		PrintToChat(client, "Format: !scset song name");
	}
	return Plugin_Handled;
}

public Action OnListen(int client, int args){
	if(StrEqual(lastGlobalTrack, "")){
		PrintToChat(client, "No track has been set.");
		return Plugin_Handled;
	}
	
	char url[192];
	getUrl(lastGlobalTrack, url, sizeof(url), volume[client]);
	motd(client, url);
	
	strcopy(last[client], 128, lastGlobalTrack);
	lastTime[client] = GetTime();
	lastTrackNum[client] = 0;
	
	if(engineVersion == Engine_CSGO || engineVersion == Engine_Left4Dead || engineVersion == Engine_Left4Dead2){
		PrintToChat(client, "\x01\x0B%s[SoundCloud] %sSearching for %s%s%s. See %s!schelp%s for more options.", c2PRIMARY, c2SECONDARY, c2PRIMARY, lastGlobalTrack, c2SECONDARY, c2PRIMARY, c2SECONDARY);
	} else {
		PrintToChat(client, "%s[SoundCloud] %sSearching for %s%s%s. See %s!schelp%s for more options.", cPRIMARY, cSECONDARY, cPRIMARY, lastGlobalTrack, cSECONDARY, cPRIMARY, cSECONDARY);
	}
	return Plugin_Handled;
}

public Action:OnNext(int client, int args){
	char url[192];
	if(lastTime[client] != 0){
		getUrl(last[client], url, sizeof(url), volume[client], 0, ++lastTrackNum[client]);
		motd(client, url);
		lastTime[client] = GetTime();
		
		char trackString[10];
		IntToString(lastTrackNum[client]+1, trackString, sizeof(trackString));
		if( 10 < (lastTrackNum[client]+1) < 14 ){
			StrCat(trackString, sizeof(trackString), "th");
		} else {
			switch(trackString[strlen(trackString)-1]){
				case '1': StrCat(trackString, sizeof(trackString), "st");
				case '2': StrCat(trackString, sizeof(trackString), "nd");
				case '3': StrCat(trackString, sizeof(trackString), "rd");
				default: StrCat(trackString, sizeof(trackString), "th");
			}
		}
		
		if(engineVersion == Engine_CSGO || engineVersion == Engine_Left4Dead || engineVersion == Engine_Left4Dead2){
			PrintToChat(client, "\x01\x0B%s[SoundCloud] %sSearching %s track for %s%s%s. See %s!schelp%s for more options.", c2PRIMARY, c2SECONDARY, trackString, c2PRIMARY, last[client], c2SECONDARY, c2PRIMARY, c2SECONDARY);
		} else {
			PrintToChat(client, "%s[SoundCloud] %sSearching %s track for %s%s%s. See %s!schelp%s for more options.", cPRIMARY, cSECONDARY, trackString, cPRIMARY, last[client], cSECONDARY, cPRIMARY, cSECONDARY);
		}
	} else {
		if(engineVersion == Engine_CSGO || engineVersion == Engine_Left4Dead || engineVersion == Engine_Left4Dead2){
			PrintToChat(client, "\x01\x0B%s[SoundCloud] %sNot playing anything. Try !sc song name", c2PRIMARY, c2SECONDARY);
		} else {
			PrintToChat(client, "%s[SoundCloud] %sNot playing anything. Try !sc song name", cPRIMARY, cSECONDARY);
		}
	}
	return Plugin_Handled;
}

public Action:OnStop(int client, int args){
	motd(client, "about:blank");
	if(lastTime[client]>0) lastTime[client] = -1;
	
	if(engineVersion == Engine_CSGO || engineVersion == Engine_Left4Dead || engineVersion == Engine_Left4Dead2){
		PrintToChat(client, "\x01\x0B%s[SoundCloud] %sPlayback stopped.", c2PRIMARY, c2SECONDARY);
	} else {
		PrintToChat(client, "%s[SoundCloud] %sPlayback stopped.", cPRIMARY, cSECONDARY);
	}
	return Plugin_Handled;
}

public Action:OnStopAll(int client, int args){
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i)){
			OnStop(i, 0);
		}
	}

	return Plugin_Handled;
}

public Action:OnHelp(int client, int args){
	if(engineVersion == Engine_CSGO || engineVersion == Engine_Left4Dead || engineVersion == Engine_Left4Dead2){
		PrintToChat(client, \
		"\x01\x0B%s[SoundCloud] !sc %sPlays track | %s!scnext %sPlays next track | %s!scvol 0-10 %sSets volume | %s!scstop %s| %s!scopen %sOpens window", \
		c2PRIMARY, c2SECONDARY, c2PRIMARY, c2SECONDARY, c2PRIMARY, c2SECONDARY, c2PRIMARY, c2SECONDARY, c2PRIMARY, c2SECONDARY);
	} else {
		PrintToChat(client, \
		"%s[SoundCloud] !sc %sPlays track | %s!scnext %sPlays next track | %s!scvol 0-10 %sSets volume | %s!scstop %s| %s!scopen %sOpens window", \
		cPRIMARY, cSECONDARY, cPRIMARY, cSECONDARY, cPRIMARY, cSECONDARY, cPRIMARY, cSECONDARY, cPRIMARY, cSECONDARY);
	}
	return Plugin_Handled;
}

public Action:OnOpen(int client, int args){
	if(lastTime[client]>0){
		CreateTimer(0.2, delayOpen, client, TIMER_FLAG_NO_MAPCHANGE); // the chat send (enter) key sometimes cancels out the window
	} else {
		if(engineVersion == Engine_CSGO || engineVersion == Engine_Left4Dead || engineVersion == Engine_Left4Dead2){
			PrintToChat(client, "\x01\x0B%s[SoundCloud] %sNot playing anything. Try !sc song name", c2PRIMARY, c2SECONDARY);
		} else {
			PrintToChat(client, "%s[SoundCloud] %sNot playing anything. Try !sc song name", cPRIMARY, cSECONDARY);
		}
	}
	return Plugin_Handled;
}

public Action:delayOpen(Handle timer, int client){
	if(lastTime[client]>0 && IsClientInGame(client)){
		char url[192];
		getUrl(last[client], url, sizeof(url), volume[client], GetTime()-lastTime[client]-8, lastTrackNum[client]);
		ShowMOTDPanel(client, "", url, MOTDPANEL_TYPE_URL);
	}
}

void motd(int client, char[] url)
{
	Handle panel = CreateKeyValues("data");
	KvSetNum(panel, "type", MOTDPANEL_TYPE_URL);
	KvSetString(panel, "msg", url);
	ShowVGUIPanel(client, "info", panel, GetConVarBool(sm_sc_visible));
	delete panel;
}

void getUrl(const char[] search, char[] url, int len, int vol, int seek=0, int trackNum = 0)
{
	strcopy(url, len, "http://");
	
	char temp[192];
	GetConVarString(sm_sc_url, temp, sizeof(temp));
	StrCat(url, len, temp);

	StrCat(url, len, "/?search=");
	
	char sEncoded[128];
	urlencode(search, sEncoded, sizeof(sEncoded));
	StrCat(url, len, sEncoded);
	
	if(vol!=10){
		StrCat(url, len, "&vol=");
		IntToString(vol, temp, sizeof(temp));
		StrCat(url, len, temp);
	}
	
	if(seek>0){
		StrCat(url, len, "&seek=");
		IntToString(seek, temp, sizeof(temp));
		StrCat(url, len, temp);
	}
	
	if(trackNum>0){
		StrCat(url, len, "&track=");
		IntToString(trackNum, temp, sizeof(temp));
		StrCat(url, len, temp);
	}
}

public Action:OnVolume(int client, int args){
	if(args==1){
		char temp[4];
		GetCmdArg(1, temp, sizeof(temp));
		
		int vol;
		int chars = StringToIntEx(temp, vol);
		if(chars>0 && vol<11){
			volume[client] = vol;
			IntToString(vol, temp, sizeof(temp));
			SetClientCookie(client, volume_cookie, temp);
			
			if(engineVersion == Engine_CSGO || engineVersion == Engine_Left4Dead || engineVersion == Engine_Left4Dead2){
				PrintToChat(client, "\x01\x0B%s[SoundCloud] %sVolume set %s%d%s.", c2PRIMARY, c2SECONDARY, c2PRIMARY, volume[client], c2SECONDARY);
			} else {
				PrintToChat(client, "%s[SoundCloud] %sVolume set %s%d%s.", cPRIMARY, cSECONDARY, cPRIMARY, volume[client], cSECONDARY);
			}
			
			if(lastTime[client]>0){
				char url[192];
				getUrl(last[client], url, sizeof(url), volume[client], GetTime()-lastTime[client]-8, lastTrackNum[client]);
				motd(client, url);
			}
			return Plugin_Handled;
		}
	}
	PrintToChat(client, "Format: !scvol 0-10 (Your volume: %d)", volume[client]);
	return Plugin_Handled;
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