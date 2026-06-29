#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

KeyValues gK_JoinInfo;

public Plugin myinfo =
{
	name = "[CS:GO] Join Info",
	author = "LenHard",
	description = "Displays messages + sounds on join.",
	version = "1.0",
	url = "http://steamcommunity.com/id/TheOfficalLenHard/"
};

public void OnMapStart()
{
	gK_JoinInfo = new KeyValues("joininfo");

	char[] sFile = new char[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFile, PLATFORM_MAX_PATH, "configs/joininfo.cfg");
	gK_JoinInfo.ImportFromFile(sFile);
}

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
	{
		char[] sSteamId = new char[MAX_NAME_LENGTH];
		GetClientAuthId(client, AuthId_Steam2, sSteamId, MAX_NAME_LENGTH);
	 
		if (gK_JoinInfo.JumpToKey(sSteamId, false))
		{
			char[] sFormat = new char[PLATFORM_MAX_PATH];
			gK_JoinInfo.GetString("sound", sFormat, PLATFORM_MAX_PATH);
			
			if (sFormat[0] != '\0') 
			{
				if (sFormat[0] != '*')
					Format(sFormat, PLATFORM_MAX_PATH, "*%s", sFormat);	
				EmitSoundToAll(sFormat);
			}
			
			gK_JoinInfo.GetString("message", sFormat, PLATFORM_MAX_PATH);
			
			if (sFormat[0] != '\0') 
			{
				FilterColors(sFormat);
				PrintToChatAll(" %s", sFormat);
			}
		}
		gK_JoinInfo.Rewind();
	}
}

void FilterColors(char[] sString)
{	
	ReplaceString(sString, PLATFORM_MAX_PATH, "{red}", "\x02", false);
	ReplaceString(sString, PLATFORM_MAX_PATH, "{green}", "\x04", false);
	ReplaceString(sString, PLATFORM_MAX_PATH, "{olive}", "\x06", false);
	ReplaceString(sString, PLATFORM_MAX_PATH, "{purple}", "\x03", false);
	ReplaceString(sString, PLATFORM_MAX_PATH, "{yellow}", "\x09", false);
	ReplaceString(sString, PLATFORM_MAX_PATH, "{blue}", "\x0B", false);
	ReplaceString(sString, PLATFORM_MAX_PATH, "{pink}", "\x0E", false);
	ReplaceString(sString, PLATFORM_MAX_PATH, "{grey}", "\x08", false);
	ReplaceString(sString, PLATFORM_MAX_PATH, "{lightred}", "\x07", false);
	ReplaceString(sString, PLATFORM_MAX_PATH, "{white}", "\x01", false);
	ReplaceString(sString, PLATFORM_MAX_PATH, "{orange}", "\x10", false);
}