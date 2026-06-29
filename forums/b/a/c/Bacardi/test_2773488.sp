

#include <regex>
#include <sdktools>

#define DEBUG_ENABLE false // change false to true to start logging name replace, into sourcemod logs

bool NameChanged[MAXPLAYERS+1]; // = {false, ...};


public void OnPluginStart()
{
	//HookEvent("player_changename", player_changename); // not needed
}

public void player_changename(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	OnClientSettingsChanged(client);
}


public void OnClientSettingsChanged(int client)
{
	// This is very spammy some times.

	if(NameChanged[client])
	{
		NameChanged[client] = false;
		return;
	}

	if(IsFakeClient(client))
	{
		NameChanged[client] = false;
		return;
	}

	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	NameChanged[client] = changestring(name, sizeof(name));

	//PrintToServer("NameChanged[client] %i", NameChanged[client]);


	if(strlen(name) == 0)
	{
		Format(name, sizeof(name), "id_%i", GetClientUserId(client));
		NameChanged[client] = true;
	}


	if(strlen(name) > 13)
	{
		Format(name, 13, "%s", name);
		NameChanged[client] = true;
	}

	
	if(NameChanged[client])
	{
		char buffer[250];
		Format(buffer, sizeof(buffer), " \x03[SM] '%N' your name changed to '%s' because you are using special characters in your name.", client, name);

		SetClientName(client, name);

		DataPack pack;
		CreateDataTimer(2.0, delaymsg, pack, TIMER_REPEAT);
		pack.WriteCell(GetClientUserId(client));
		pack.WriteString(buffer);
		pack.Reset();
	}
}


public Action delaymsg(Handle timer, DataPack pack)
{
	pack.Reset();

	int client = GetClientOfUserId(pack.ReadCell());

	if(!client)
		return Plugin_Stop;

	if(!IsValidEntity(client)
	|| GetEntProp(client, Prop_Send, "m_iPlayerState") != 0
	&& GetEntProp(client, Prop_Send, "m_iPlayerState") != 6)
	{
		return Plugin_Continue;
	}

	char buffer[250];
	pack.ReadString(buffer, sizeof(buffer));
	PrintToChat(client, "%s", buffer);
	//PrintToServer("%s", buffer);
	return Plugin_Stop;
}





bool changestring(char[] originaltext, int originaltextsize)
{
	// Regex pattern.
	// For this code, we should check/match each letter. Not whole words/sentenced.
	static const char pattern[] = "[^a-zA-Z\\d,._\\-]";

	char error[128];
	char buffer[50]; // ...not sure how big character can be, so I use lot of extra space.

	RegexError errcode;
	int flags = PCRE_UTF8; // PCRE_UTF8 for multibyte characters

	Regex regex = new Regex(pattern, flags, error, sizeof(error), errcode);

	if(regex == null)
	{
		ThrowError("Regex compile failed:(%s) %s. code %d", pattern, error, errcode);
	}

	RegexError ret = REGEX_ERROR_NONE;

	int matches = regex.MatchAll(originaltext, ret); // How many regex matches we found from string.

	if(ret != REGEX_ERROR_NONE)
	{
		delete regex;
		ThrowError("error %i", ret);
	}

	int captures = 0;	// When regex pattern use capturing group (), sub-matches

	int offset = 0; // Offset to keep track, in which position we are on original text.

	int removed = 0; // Collect number of removed bytes from copy string, so we can keep right offset.

	int multibyte = 0; // Get character size.

	int offset_tmp = 0; // Offset for copyoftext.

	char copyoftext[MAX_NAME_LENGTH];
	strcopy(copyoftext, sizeof(copyoftext), originaltext);

	//PrintToServer("strlen(%i)", strlen(copyoftext));

	for(int m = 0; m < matches; m++)
	{
		captures = regex.CaptureCount(m);
		offset = regex.MatchOffset(m);

		for(int c = 0; c < captures; c++)
		{
			regex.GetSubString(c, buffer, sizeof(buffer), m);
			multibyte = IsCharMB(buffer[0]);

			if(!multibyte)
				multibyte = 1;

			offset_tmp = offset - removed - multibyte;

			// ...should not happen
			if(offset_tmp < 0)
				offset_tmp = 0;

			//PrintToServer("buffer(%s) offset %i, multibyte %i, offset_tmp %i", buffer, offset, multibyte, offset_tmp);

			copyoftext[offset_tmp] = '\0'; // erase rest of string
			//Format(copyoftext, sizeof(copyoftext), "%s%s", copyoftext, originaltext[offset]); // rewrite
			StrCat(copyoftext, sizeof(copyoftext), originaltext[offset]); // rewrite

			removed += multibyte;

			//copyoftext[x] = '\127'; // delete char visually remove space in string, but string size is filled by it own existent. not good.
			//copyoftext[x] = '\32'; // replace char with spaces, best this far.
			//copyoftext[x] = '\8'; // insert char, visually hide char or something
		}
	}


	//PrintToChatAll("- %s", copyoftext);
	//PrintToServer("strlen(%i)", strlen(copyoftext));

	delete regex;

	if(DEBUG_ENABLE && matches)
	{
		LogAction(-1, -1, "(%s) replace to (%s)", originaltext, copyoftext);
	}

	strcopy(originaltext, originaltextsize, copyoftext);

	return (matches > 0);
}

