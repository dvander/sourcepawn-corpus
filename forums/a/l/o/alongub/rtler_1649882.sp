#pragma semicolon 1

#include <sourcemod>
#include <scp>
#include <rtler>
#undef REQUIRE_PLUGIN
#include <updater>

#define PL_VERSION		"1.0.5"
#define UPDATE_URL		"http://dl.dropbox.com/u/16304603/rtler/updatefile.txt"

new Handle:g_hFlag;
new Handle:g_hMinimum;

new Float:minimum = 0.1;

public Plugin:myinfo =
{
    name        = "The RTLer",
    author      = "alongub",
    description = "In-game chat support for RTL languages.",
    version     = PL_VERSION,
    url         = "http://steamcommunity.com/id/alon"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("RTLify", Native_RTLify);

	RegPluginLibrary("rtler");
	return APLRes_Success;
}

public OnPluginStart()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}

	CreateConVar("rtler_version", PL_VERSION, "RTLer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hFlag = CreateConVar("rtler_flag", "", "Restrict chat correction only for people who have this flag.");
	g_hMinimum = CreateConVar("rtler_minimum", "0.1", "Minimum percent of RTL letters for a word's direction to be considered right to left.", _, true,	0.001, true, 1.0);
	HookConVarChange(g_hMinimum, OnMinimumChange);
	
	AutoExecConfig(true);
}

public OnMinimumChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	minimum = StringToFloat(newVal);
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public Action:OnChatMessage(&author, Handle:recipients, String:name[], String:message[])
{
	decl String:flagString[2];
	GetConVarString(g_hFlag, flagString, sizeof(flagString));

	new AdminFlag:flag;
	if (FindFlagByChar(flagString[0], flag))
	{
		new AdminId:adminId = GetUserAdmin(author);

		if (adminId == INVALID_ADMIN_ID || (adminId != INVALID_ADMIN_ID && !GetAdminFlag(adminId, flag)))
			return Plugin_Continue;
	}

	if (_RTLify(message, message) == 0)
		return Plugin_Continue;
	
	return Plugin_Changed;
}

_RTLify(String:dest[], String:original[])
{
	new rtledWords = 0;

	new String:tokens[96][96]; // TODO: This shouldn't be a fixed size.	
	new String:words[sizeof(tokens)][sizeof(tokens[])];

	new n = ExplodeString(original, " ", tokens, sizeof(tokens), sizeof(tokens[]));
	
	for (new word = 0; word < n; word++)
	{
		if (WordAnalysis(tokens[word]) >= minimum)
		{
			ReverseString(tokens[word], sizeof(tokens[]), words[n-1-word]);
			rtledWords++;
		}
		else
		{
			new firstWord = word;
			new lastWord = word;
			
			while (WordAnalysis(tokens[lastWord]) < minimum)
			{
				lastWord++;
			}
			
			for (new t = lastWord - 1; t >= firstWord; t--)
			{
				strcopy(words[n-1-word], sizeof(tokens[]), tokens[t]);
				
				if (t > firstWord)
					word++;
			}
		}
	}
	
	ImplodeStrings(words, n, " ", dest, sizeof(words[]));
	return rtledWords;
}

ReverseString(String:str[], maxlength, String:buffer[])
{
	for (new character = strlen(str); character >= 0; character--)
	{
		if (str[character] >= 0xD6 && str[character] <= 0xDE)
			continue;
		
		if (character > 0 && str[character - 1] >= 0xD7 && str[character - 1] <= 0xD9)
			Format(buffer, maxlength, "%s%c%c", buffer, str[character - 1], str[character]);
		else
			Format(buffer, maxlength, "%s%c", buffer, str[character]);
	}
}

Float:WordAnalysis(String:word[])
{
	new count = 0, length = strlen(word);
	
	for (new n = 0; n < length - 1; n++)
	{
		if (IsRTLCharacter(word, n))
		{	
			count++;
			n++;
		}
	}

	return float(count) * 2 / length;
}

bool:IsRTLCharacter(String:str[], n)
{
	return (str[n] >= 0xD6 && str[n] <= 0xDE && str[n + 1] >= 0x80 && str[n + 1] <= 0xBF);
}

public Native_RTLify(Handle:plugin, params)
{
	new destLen = GetNativeCell(2);
	decl String:dest[destLen];

	new originalLen = destLen;
	GetNativeStringLength(3, originalLen);
	
	decl String:original[originalLen];
	GetNativeString(3, original, originalLen + 1);

	new amount = _RTLify(dest, original);
	SetNativeString(1, dest, destLen, true);

	return amount;
}