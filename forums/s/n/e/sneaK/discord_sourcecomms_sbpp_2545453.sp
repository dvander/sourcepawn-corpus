#include <sourcemod>
#include <discord>

#define PLUGIN_VERSION "1.1"

#define MSG_BAN "{\"attachments\": [{\"color\": \"{COLOR}\",\"title\": \"View on Sourcebans\",\"title_link\": \"{SOURCEBANS}\",\"fields\": [{\"title\": \"Player\",\"value\": \"{NICKNAME} ( {STEAMID} )\",\"true\": false},{\"title\": \"Admin\",\"value\": \"{ADMIN}\",\"short\": true},{\"title\": \"{COMMTYPE} Length\",\"value\": \"{BANLENGTH}\",\"short\": true},{\"title\": \"Reason\",\"value\": \"{REASON}\",\"short\": true}]}]}"

ConVar g_cColorGag = null;
ConVar g_cColorMute = null;
ConVar g_cColorSilence = null;
ConVar g_cSourcebans = null;
ConVar g_cWebhook = null;

public Plugin myinfo = 
{
	name = "Discord: SourceComms",
	author = ".#Zipcore",
	description = "",
	version = PLUGIN_VERSION,
	url = "www.zipcore.net"
}

public void OnPluginStart()
{
	CreateConVar("discord_sourcecomms_version", PLUGIN_VERSION, "Discord SourceComms version", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_cColorGag = CreateConVar("discord_sourcecomms_color_gag", "#ffff22", "Discord/Slack attachment gag color.");
	g_cColorMute = CreateConVar("discord_sourcecomms_color_mute", "#2222ff", "Discord/Slack attachment mute color.");
	g_cColorSilence = CreateConVar("discord_sourcecomms_color_silence", "#ff22ff", "Discord/Slack attachment silence color.");
	g_cSourcebans = CreateConVar("discord_sourcecomms_url", "https://sb.eu.3kliksphilip.com/index.php?p=commslist&searchText={STEAMID}", "Link to sourcebans.");
	g_cWebhook = CreateConVar("discord_sourcecomms_webhook", "sourcecomms", "Config key from configs/discord.cfg.");
	
	AutoExecConfig(true, "discord_sourcecomms");
}

public int SourceComms_OnBlockAdded(int client, int target, int time, int type, char[] reason)
{
	PrePareMsg(client, target, time, type, reason);
}

public int PrePareMsg(int client, int target, int time, int type, char[] reason)
{
	char sAuth[32];
	GetClientAuthId(target, AuthId_Steam2, sAuth, sizeof(sAuth));
	
	char sName[32];
	GetClientName(target, sName, sizeof(sName));
	
	char sAdminName[32];
	if(client && IsClientInGame(client))
		GetClientName(client, sAdminName, sizeof(sAdminName));
	else sAdminName = "CONSOLE";
	
	char sLength[32];
	if(time < 0)
	{
		sLength = "Session";
	}
	else if(time == 0)
	{
		sLength = "Permanent";
	}
	else if (time >= 525600)
	{
		int years = RoundToFloor(time / 525600.0);
		Format(sLength, sizeof(sLength), "%d mins (%d year%s)", time, years, years == 1 ? "" : "s");
    }
	else if (time >= 10080)
	{
		int weeks = RoundToFloor(time / 10080.0);
		Format(sLength, sizeof(sLength), "%d mins (%d week%s)", time, weeks, weeks == 1 ? "" : "s");
    }
	else if (time >= 1440)
	{
		int days = RoundToFloor(time / 1440.0);
		Format(sLength, sizeof(sLength), "%d mins (%d day%s)", time, days, days == 1 ? "" : "s");
    }
	else if (time >= 60)
	{
		int hours = RoundToFloor(time / 60.0);
		Format(sLength, sizeof(sLength), "%d mins (%d hour%s)", time, hours, hours == 1 ? "" : "s");
    }
	else Format(sLength, sizeof(sLength), "%d min%s", time, time == 1 ? "" : "s");
    
	Discord_EscapeString(sName, strlen(sName));
	Discord_EscapeString(sAdminName, strlen(sAdminName));
	
	char sMSG[2048] = MSG_BAN;
	
	char sSourcebans[512];
	g_cSourcebans.GetString(sSourcebans, sizeof(sSourcebans));
	
	char sColor[512];
	char sType[64];
	
	switch(type)
	{
		case 1: 
		{
			g_cColorMute.GetString(sColor, sizeof(sColor));
			sType = "Mute";
		}
		case 2: 
		{
			g_cColorGag.GetString(sColor, sizeof(sColor));
			sType = "Gag";
		}
		case 3: 
		{
			g_cColorSilence.GetString(sColor, sizeof(sColor));
			sType = "Silence";
		}
	}
	
	ReplaceString(sMSG, sizeof(sMSG), "{COLOR}", sColor);
	ReplaceString(sMSG, sizeof(sMSG), "{COMMTYPE}", sType);
	ReplaceString(sMSG, sizeof(sMSG), "{SOURCEBANS}", sSourcebans);
	ReplaceString(sMSG, sizeof(sMSG), "{STEAMID}", sAuth);
	ReplaceString(sMSG, sizeof(sMSG), "{REASON}", reason);
	ReplaceString(sMSG, sizeof(sMSG), "{BANLENGTH}", sLength);
	ReplaceString(sMSG, sizeof(sMSG), "{ADMIN}", sAdminName);
	ReplaceString(sMSG, sizeof(sMSG), "{NICKNAME}", sName);
	
	SendMessage(sMSG);
}

SendMessage(char[] sMessage)
{
	char sWebhook[32];
	g_cWebhook.GetString(sWebhook, sizeof(sWebhook));
	Discord_SendMessage(sWebhook, sMessage);
}