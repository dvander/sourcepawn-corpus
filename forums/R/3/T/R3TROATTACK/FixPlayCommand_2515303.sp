#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "R3TROATTACk - AlliedModders LLC"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <emitsoundany>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Custom Play Command",
	author = PLUGIN_AUTHOR,
	description = "Plays custom sounds to target",
	version = PLUGIN_VERSION,
	url = "www.memerland.com"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_customplay", Command_CustomPlay, ADMFLAG_GENERIC, "sm_customplay <#userid|name> <filename>");
	LoadTranslations("common.phrases");
	LoadTranslations("sounds.phrases");
}

public Action Command_CustomPlay(int client, int argc)
{
	if (argc < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_customplay <#userid|name> <filename>");
		return Plugin_Handled;
	}

	char Arguments[PLATFORM_MAX_PATH + 65];
	GetCmdArgString(Arguments, sizeof(Arguments));

 	char Arg[65];
	int len = BreakString(Arguments, Arg, sizeof(Arg));

	/* Make sure it does not go out of bound by doing "sm_play user  "*/
	if (len == -1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_play <#userid|name> <filename>");
		return Plugin_Handled;
	}

	/* Incase they put quotes and white spaces after the quotes */
	if (Arguments[len] == '"')
	{
		len++;
		int FileLen = TrimString(Arguments[len]) + len;

		if (Arguments[FileLen - 1] == '"')
		{
			Arguments[FileLen - 1] = '\0';
		}
	}
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			Arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		EmitSoundToClientAny(target_list[i],  Arguments[len]);
		LogAction(client, target_list[i], "\"%L\" played sound on \"%L\" (file \"%s\")", client, target_list[i], Arguments[len]);
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Played sound to target", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Played sound to target", "_s", target_name);
	}

	return Plugin_Handled;
}

public void OnMapStart()
{
	PrecacheDirecotry("sound/");
}

void PrecacheDirecotry(char[] dir)
{
	DirectoryListing hDir = null;
	if ((hDir = OpenDirectory(dir)) == null)
	{
		LogError("$s invalid file path", dir);
		return;
	}
	
	char sFile[PLATFORM_MAX_PATH]; 
	FileType type;
	while(hDir.GetNext(sFile, sizeof(sFile), type))
	{
		if(StrEqual(".", sFile, false) || StrEqual("..", sFile, false))
			continue;
		
		char sBuffer[PLATFORM_MAX_PATH];
		if(type == FileType_File)
		{
			if((StrContains(sFile, ".wav", true) != -1 || StrContains(sFile, ".mp3", true) != -1) && !StrEqual(sFile, "", false))
			{
				Format(sBuffer, sizeof(sBuffer), "%s%s", dir, sFile);
				AddFileToDownloadsTable(sBuffer);
				ReplaceString(sBuffer, sizeof(sBuffer), "sound/", "", false);
				PrecacheSoundAny(sBuffer);
			}
		}
		else if(type == FileType_Directory)
		{
			Format(sBuffer, sizeof(sBuffer), "%s%s/", dir, sFile);
			PrecacheDirecotry(sBuffer);
		}
	}
	delete hDir;
}