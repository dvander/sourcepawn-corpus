#include	<cstrike>
//#include	<multicolors>

#pragma		semicolon 1
#pragma		newdecls required

#define		Tag	"{green}[SM]{default}"
#define		PLUGIN_AUTHOR	"never"
#define		PLUGIN_VERSION	"1.01"

bool		lock[MAXPLAYERS+1]; //Disabled by default anyways

public	Plugin	myinfo	=	{
	name		=	"Hide tags", 
	author		=	PLUGIN_AUTHOR, 
	description	=	"tags for Admins", 
	version		=	PLUGIN_VERSION, 
	url			=	"https://steamcommunity.com/id/213never213/"
};

public void OnPluginStart()	{
	RegAdminCmd("sm_hide", cmd_hide, ADMFLAG_GENERIC);
}

public Action cmd_hide(int client, int args)	{
	lock[client] = lock[client] == true ? false : true;
	
	switch(lock[client])	{
		case	true:	HandleTag2(client);
		case	false:	HandleTag(client);
	}
	
	PrintToChat(client, "%s Your clan tag has been %s", lock ? "hidden":"shown");
}

public void OnClientSettingsChanged(int client)	{
	if(!IsValidClient(client))
		return;
	
	switch(lock[client])	{
		case	true:	HandleTag2(client);
		case	false:	HandleTag(client);
	}
}

void HandleTag(int client)	{
	if(IsClientOwner(client))
		CS_SetClientClanTag(client, "[Owner]");
	
	else if(IsClientHeadAdmin(client))
		CS_SetClientClanTag(client, "[Head-Admin]");
	
	else if(IsClientAdmin(client))
		CS_SetClientClanTag(client, "[Admin]");
	
	else if(IsClientModerator(client))
		CS_SetClientClanTag(client, "[Moderator]");
}

void HandleTag2(int client)	{
	if(IsClientOwner(client))
		CS_SetClientClanTag(client, "[VIP]");
	
	else if(IsClientHeadAdmin(client))
		CS_SetClientClanTag(client, "[VIP]");
	
	else if(IsClientAdmin(client))
		CS_SetClientClanTag(client,	"[VIP]");
	
	else if(IsClientModerator(client))
		CS_SetClientClanTag(client,	"[VIP]");
}


bool IsClientOwner(int client)	{
	if(!CheckCommandAccess(client, "", ADMFLAG_ROOT, false))
		return	false;
	return	true;
}

bool IsClientHeadAdmin(int client)	{
	if(!CheckCommandAccess(client, "", ADMFLAG_CUSTOM6, false))
		return	false;
	return	true;
}

bool IsClientAdmin(int client)	{
	if(!CheckCommandAccess(client, "", ADMFLAG_GENERIC, false))
		return	false;
	return	true;
}

bool IsClientModerator(int client)	{
	if(!CheckCommandAccess(client, "", ADMFLAG_CUSTOM1, false))
		return	false;
	return	true;
}

bool IsValidClient(int client)	{
	if(!IsClientInGame(client))
		return	false;
	if(client < 1 || client > MaxClients)
		return	false;
	if(IsFakeClient(client))
		return	false;
	if(IsClientReplay(client))
		return	false;
	if(IsClientSourceTV(client))
		return	false;
	if(GetClientTeam(client) < 1)
		return	false;
	return	true;
}