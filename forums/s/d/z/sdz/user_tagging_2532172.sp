#include <sourcemod>
#include <morecolors>
#include <sdktools>

ConVar g_cvTagColor;
ConVar g_cvAdminOnly;
ConVar g_cvTagSound;
ConVar g_cvTagSymbol;

char g_TagColor[64];
char g_TagSound[PLATFORM_MAX_PATH];
char g_Symbol[8];
bool g_AdminOnly;

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	g_cvTagColor = CreateConVar("sm_tagging_color", "green", "Color for the tagged player to see in the chat");
	g_cvAdminOnly = CreateConVar("sm_tagging_adminonly", "0", "Only admins can tag players");
	g_cvTagSound = CreateConVar("sm_tagging_sound", "HL1/fvox/blip.wav", "Sound to play when tagged (omit sound/ in directory)");
	g_cvTagSymbol = CreateConVar("sm_tagging_symbol", "@", "Symbol which should be used to tag players");

	AutoExecConfig();

	g_cvTagColor.AddChangeHook(OnColorChanged);
	g_cvAdminOnly.AddChangeHook(OnAdminChanged);
	g_cvTagSound.AddChangeHook(OnSoundChanged);
	g_cvTagSymbol.AddChangeHook(OnSymbolChanged);

	CreateConVar("sm_tagging_version", "1.2", "Version CVar");
}

public OnMapStart()
{
	char download[PLATFORM_MAX_PATH];
	Format(download, sizeof(download), "sound/%s", g_TagSound);
	AddFileToDownloadsTable(download);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] text)
{
	/*
	 * Get client chat message if global chat
	 * If contains @user and user is found, replace said text with username, and highlight.
	 */
	char message[256];
	strcopy(message, sizeof(message), text);

	if(!StrEqual(command, "say", false)) return Plugin_Continue; //Not sure if we'll let them use say_team or messagemode2 for this.
	if(StrEqual(message[0], "@", false)) return Plugin_Continue; //The latter is used by a default sourcemod plugin.

	//Do this so we don't have people putting escape sequences in their text messages.
	ReplaceString(message, 256, "\\", "", false);

	int tagPosition = -1;
	tagPosition = StrContains(message, g_Symbol, false);
	if(tagPosition != -1)
	{
		char nameArg[256 + 1];
		char clientName[2][MAX_NAME_LENGTH];
		int copyPasta = 0;

		if((!g_AdminOnly) || (g_AdminOnly && CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC)))
		{
			for(int i = tagPosition + 1; i < sizeof(message); i++)
			{
				if(IsCharSpace(message[i]))
				{
					i = 256;
					break;
				}

				nameArg[copyPasta] = message[i];
				copyPasta++;
				continue;	
			}

			int target = -1;

			//UserID vs. Username
			if(StrContains(nameArg, "#", false) == 0) 
			{
				target = FindTargetByName(client, nameArg, true);
			}
			else
			{
				target = FindTargetByName(client, nameArg, false);
			}

			if(target == -1) return Plugin_Continue;

			char message2[256];

			strcopy(message2, sizeof(message2), message);

			Format(nameArg, sizeof(nameArg), "%s%s", g_Symbol, nameArg);
			Format(clientName[0], sizeof(clientName[]), "{%s}%N{default}", g_TagColor, target); //To our target
			Format(clientName[1], sizeof(clientName[]), "%N", target); //To everyone else
			ReplaceString(message, sizeof(message), nameArg, clientName[0], false);

			Format(message, sizeof(message), "{teamcolor}%N {default}:  %s", client, message);
			CPrintToChatEx(target, client, message);
			EmitSoundToClient(target, g_TagSound);
			
			ReplaceString(message2, sizeof(message2), nameArg, clientName[1], false);
			Format(message2, sizeof(message2), "{teamcolor}%N {default}:  %s", client, message2);
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && !IsFakeClient(i))
				{
					if(i != target)
					{
						CPrintToChatEx(i, client, message2);
					}
				}
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void OnConfigsExecuted()
{
	g_cvTagColor.GetString(g_TagColor, sizeof(g_TagColor));
	g_cvTagSound.GetString(g_TagSound, sizeof(g_TagSound));
	g_AdminOnly = g_cvAdminOnly.BoolValue;
	g_cvTagSymbol.GetString(g_Symbol, sizeof(g_Symbol));
	PrecacheSound(g_TagSound, true);
}

public void OnColorChanged(ConVar convar, const char[] oldVal, const char[] newVal)
{
	strcopy(g_TagColor, sizeof(g_TagColor), newVal);
}

public void OnAdminChanged(ConVar convar, const char[] oldVal, const char[] newVal)
{
	g_AdminOnly = convar.BoolValue;
}

public void OnSoundChanged(ConVar convar, const char[] oldVal, const char[] newVal)
{
	strcopy(g_TagSound, sizeof(g_TagSound), newVal);
	PrecacheSound(g_TagSound);
}

public void OnSymbolChanged(ConVar convar, const char[] oldVal, const char[] newVal)
{
	strcopy(g_Symbol, sizeof(g_Symbol), newVal);
}

public int FindTargetByName(int client, char[] name, bool userid)
{
	int targets = 0;
	int targetArray[MAXPLAYERS + 1];

	//Don't search via userid
	if(!userid)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			char cName[MAX_NAME_LENGTH];
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				GetClientName(i, cName, sizeof(cName));
				if(StrContains(cName, name, false) != -1)
				{
					targets++;
					targetArray[i] = i;
				}
			}
		}
	}
	else //Do search via userid
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				int uID = GetClientUserId(i);
				char user[8]; IntToString(uID, user, sizeof(user));
				if(StrContains(name, user, false) != -1)
				{
					targets++;
					targetArray[i] = i;
				}
			}
		}
	}

	SortIntegers(targetArray, MAXPLAYERS + 1, Sort_Descending);

	if(targets > 1)
	{
		ReplyToTargetError(client, COMMAND_TARGET_AMBIGUOUS);
		PrintToChat(client, "[SM] More than one client matched the given pattern.");
		return -1;
	}
	else if(targets < 1)
	{
		ReplyToTargetError(client, COMMAND_TARGET_NONE);
		PrintToChat(client, name);
		PrintToChat(client, "[SM] No matching client was found.");
		return -1;
	}
	else if(targets == 1)
	{
		return targetArray[0];
	}

	return -1;
}

public Plugin myinfo =
{
	name = "User-Tagging in Chat",
	author = "Sidezz",
	description = "Enable social media style tagging (@user) in chat",
	version = "1.0",
	url = "www.everythingFPS.com, www.coldcommunity.com"
}