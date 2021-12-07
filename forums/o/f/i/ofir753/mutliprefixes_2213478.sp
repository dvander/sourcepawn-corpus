#pragma semicolon 1
#include <sourcemod>

public Plugin:myinfo = 
{
	name        = "Multi Prefixes for Commands",
	author      = "Ofir",
	description = "Enable multi commands prefixes",
	version     = "1.0",
	url         = "https://forums.alliedmods.net/member.php?u=190571"
};

//Cvar Handles
new Handle:gh_SilentPrefixes = INVALID_HANDLE;
new Handle:gh_Prefixes       = INVALID_HANDLE;

//Cvars Variables 
new String:gs_Prefixes[32];
new String:gs_SilentPrefixes[32];

public OnPluginStart()
{
	//Cvars
	gh_Prefixes = CreateConVar("prefix_chars", ".", "Prefix chars for commands max 32 chars Example:\".[-\"", _);
	gh_SilentPrefixes = CreateConVar("prefix_silentchars", "", "Prefix chars for hidden commands max 32 chars Example:\".[-\"", _);

	HookConVarChange(gh_Prefixes, Action_OnSettingsChange);
	HookConVarChange(gh_SilentPrefixes, Action_OnSettingsChange);

	GetConVarString(gh_Prefixes, gs_Prefixes, sizeof(gs_Prefixes));
	GetConVarString(gh_SilentPrefixes, gs_SilentPrefixes, sizeof(gs_SilentPrefixes));

	AutoExecConfig(true, "multiprefixes");
	//Listeners
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
}

public Action_OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if (cvar == gh_Prefixes)
	{
		strcopy(gs_Prefixes, sizeof(gs_Prefixes), newvalue);
	}
	else if (cvar == gh_SilentPrefixes)
	{
		strcopy(gs_SilentPrefixes, sizeof(gs_SilentPrefixes), newvalue);
	}
}

public Action:Command_Say(client, const String:command[], argc)
{
	decl String:sText[300];
	decl String:sSplit[2];
	GetCmdArgString(sText, sizeof(sText));
	StripQuotes(sText);
	for (new i = 0; i < strlen(gs_Prefixes); i++)
	{
		if(sText[0] == gs_Prefixes[i])
		{
			if(sText[1] == '\0' || sText[1] == ' ')
				return Plugin_Continue;
			Format(sSplit, sizeof(sSplit), "%c", gs_Prefixes[i]);
			if(!SplitStringRight(sText, sSplit, sText, sizeof(sText)))
			{
				return Plugin_Continue;
			}
			FakeClientCommand(client, "sm_%s", sText);
			return Plugin_Continue;
		}
	}
	for (new i = 0; i < strlen(gs_SilentPrefixes); i++)
	{
		if(sText[0] == gs_SilentPrefixes[i])
		{
			if(sText[1] == '\0' || sText[1] == ' ')
				return Plugin_Continue;
			Format(sSplit, sizeof(sSplit), "%c", gs_SilentPrefixes[i]);
			if(!SplitStringRight(sText, sSplit, sText, sizeof(sText)))
			{
				return Plugin_Continue;
			}
			FakeClientCommand(client, "sm_%s", sText);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

stock bool:SplitStringRight( const String:source[], const String:split[], String:part[], partLen ) //Thanks to KissLick https://forums.alliedmods.net/member.php?u=210752
{
    new index = StrContains( source, split ); // get start index of split string
    
    if( index == -1 ) // split string not found..
        return false;
    
    index += strlen( split ); // get end index of split string    
    strcopy( part, partLen, source[ index ] ); // copy everything after source[ index ] to part
    return true;
} 