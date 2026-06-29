#pragma semicolon 1

#include <sourcemod>

new Handle:enabled = INVALID_HANDLE;
new Handle:tagconvar = INVALID_HANDLE;
new Handle:castSens = INVALID_HANDLE;
new Handle:flagBit = INVALID_HANDLE;
new String:tags[10][32];
new cflags;

public Plugin:myinfo = 
{
	name = "ClanTag Detection",
	author = "Mini",
	description = "Sets admin flags based on clantag",
	version = "1.2.1",
	url = "http://sourcemod.net"
};

public OnPluginStart()
{
	enabled = CreateConVar("clantagdetect_enabled", "1", "Enabled");
	tagconvar = CreateConVar("clantagdetect_tag", "myTag,myTagVIP", "The clan tags to search for seperated with a comma (\",\")");
	HookConVarChange(tagconvar, TagListChange);
	castSens = CreateConVar("clantagdetect_case", "1", "Should the search be case sensitive?");
	flagBit = CreateConVar("clantagdetect_flag", "ar", "What admin flags to add?");
	HookConVarChange(flagBit, TagListChange);

	AutoExecConfig(true, "clantag_detect");
}

public TagListChange(Handle:conVar, const String:oldValue[], const String:newValue[])
{
	if(conVar == tagconvar)
		ExplodeString(newValue, ",", tags, sizeof(tags), sizeof(tags[]));
	if(conVar == flagBit) 
		cflags = ReadFlagString(newValue);
}

public OnClientPostAdminFilter(client)
{
	if(GetConVarBool(enabled))
	{
		new String:cname[32];
		GetClientName(client, cname, sizeof(cname));
		new bool:bCaseSens = GetConVarBool(castSens);
		for(new i = 0; i < sizeof(tags); i++)
		{
			if(StrEqual(tags[i], "", false))
				continue;
			if(StrContains(cname, tags[i], bCaseSens) != -1)
			{
				SetUserFlagBits(client, GetUserFlagBits(client) | cflags);
				PrintToChat(client, "Welcome! You have been given extra privilages because of your clan tag!");
			}
		}
	}
} 