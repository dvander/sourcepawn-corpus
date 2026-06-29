#include	<cstrike>

#pragma		semicolon	1
#pragma		newdecls	required

public	Plugin	myinfo	=	{
	name		=	"[CSS/CS:GO] Custom Tags",
	author		=	"Tk /id/Teamkiller324",
	description	=	"Puts a custom tag on a client with a custom flag",
	version		=	"1.0",
	url			=	"https://steamcommunity.com/id/Teamkiller324"
}

#define	Owner		"Owner"
#define	Admin		"Admin"
#define	Moderator	"Mod"
#define	Vip			"Vip"


public void OnPluginStart()	{
	HookEvent("player_spawn",	CustomTags_Spawn,	EventHookMode_Pre);
}

public void OnClientPostAdminCheck(int client)	{
	Tags(client);	
}

void Tags(int client)	{
	if(IsClientOwner(client))	//If the client is an owner
	{
		CS_SetClientClanTag(client, Owner);
	}
	else if(IsClientAdmin(client))	//Else if the client is an admin
	{
		CS_SetClientClanTag(client,	Admin);
	}
	else if(IsClientModerator(client))	//Else if the client is a moderator
	{
		CS_SetClientClanTag(client, Moderator);
	}
	else if(IsClientVip(client))	//Else if the client is a vip
	{
		CS_SetClientClanTag(client,	Vip);
	}
}

Action	CustomTags_Spawn(Event event, const char[] name, bool dontBroadcast)	{
	int	client	=	GetClientOfUserId(event.GetInt("userid"));
	Tags(client);
}


stock bool IsClientOwner(int client)	{
	if(!CheckCommandAccess(client,	"owner_flag",	ADMFLAG_ROOT,	false))			return false;
	return true;
}

stock bool IsClientAdmin(int client)	{
	if(!CheckCommandAccess(client,	"admin_flag",	ADMFLAG_GENERIC,	false))		return false;
	return true;
}

stock bool IsClientModerator(int client)	{
	if(!CheckCommandAccess(client,	"moderator_flag",	ADMFLAG_CUSTOM1,	false))	return false;
	return true;
}

stock bool IsClientVip(int client)	{
	if(!CheckCommandAccess(client,	"vip_flag",	ADMFLAG_RESERVATION,	false))		return false;
	return true;
}