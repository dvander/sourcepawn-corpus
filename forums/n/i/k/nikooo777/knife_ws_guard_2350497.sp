#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Nikooo777"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
//#include <sdkhooks>

#pragma newdecls required

char banned_words[][] =  {"!ws","ws","!knife","knife","!wp","wp"};
Handle h_tagsCvar,h_hostCvar;

public Plugin myinfo = 
{
	name = "tags-hostname-guard",
	author = PLUGIN_AUTHOR,
	description = "Makes sure server complies with the rules",
	version = PLUGIN_VERSION,
	url = "https://go-free.info"
};

public void OnPluginStart()
{
	h_tagsCvar = FindConVar("sv_tags");
	HookConVarChange(h_tagsCvar, SvTagsChanged);
	
	h_hostCvar = FindConVar("hostname");
	HookConVarChange(h_hostCvar, HostNameChanged);
	
	/*
	* regex here, somebody help me removing the string correctly?
	for (int i = 0; i < sizeof(banned_words); i++) 
	{
		char pattern[32];
		Format(pattern,"\\b%s\\b", banned_words[i]);
		h_banned_words = CompileRegex(pattern); //deleted the handles array anyway
	}*/
}

public void OnMapStart()
{
	FixTags();
	FixHostName();
}

public void SvTagsChanged(Handle convar, char[] oldValue, char[] newValue)
{
	FixTags();
}

public void HostNameChanged(Handle convar, char[] oldValue, char[] newValue)
{
	FixHostName();
}

stock void FixTags()
{
	char sv_tags[512];
	
	GetConVarString(h_tagsCvar, sv_tags, sizeof(sv_tags));

	for (int i = 0; i < sizeof(banned_words); i++) 
	{
		if (StrContains(sv_tags,banned_words[i],false)!=-1)
			ReplaceString(sv_tags, sizeof(sv_tags), banned_words[i], "", false);
	}
	SetConVarString(h_tagsCvar, sv_tags);
	LogError("[Warning!] Your server is using tags against VALVE rules! Please remove such plugins and any references to ws/knife from your sv_tags.");
}

stock void FixHostName()
{
	char hostname[512];
	
	GetConVarString(h_hostCvar, hostname, sizeof(hostname));

	for (int i = 0; i < sizeof(banned_words); i++) 
	{
		if (StrContains(hostname,banned_words[i],false)!=-1)
			ReplaceString(hostname, sizeof(hostname), banned_words[i], "", false);
	}
	SetConVarString(h_hostCvar, hostname);	
	LogError("[Warning!] Your server is using an HostName against VALVE rules! Please remove such plugins and any references to ws/knife from your hostname.");
}