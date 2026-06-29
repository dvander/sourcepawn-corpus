/*
	SM Adminseeall bY TechKnow & Pred
	

	Admin See All	    - Cvar: sm_adminseeall <1|0>

*/

#include <sourcemod>
#include <sdktools>


#define PLUGIN_VERSION "1.0"

//#define ADMIN_LEVEL ADMFLAG_BAN
#define ADMIN_SEEALL	ADMFLAG_GENERIC

new Handle:g_hAdminSeeAll
new LifeStateOff
new maxplayers

 


public Plugin:myinfo = 
{
	name = "SM Adminseeall",
	author = "TechKnow & Pred",
	description = "Admin sees all chat",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("sm_admin-see-all_version", PLUGIN_VERSION, "Admin-see-all Version",         FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	
	RegConsoleCmd("say", Command_Say)
	RegConsoleCmd("say_team", Command_SayTeam)
	
	g_hAdminSeeAll = CreateConVar("sm_adminseeall","1","Show admins all chat")

	LifeStateOff = FindSendPropOffs("CBasePlayer","m_lifeState")
        
	LoadTranslations("common.phrases");
}

public OnMapStart()
{
	maxplayers = GetMaxClients()
}

public trim_quotes(String:text[])
{
	new startidx = 0
	if (text[0] == '"')
	{
		startidx = 1
		/* Strip the ending quote, if there is one */
		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0'
		}
	}
	
	return startidx
}

public Action:Command_Say(client, args)
{
	if (!GetConVarInt(g_hAdminSeeAll))
		return Plugin_Continue
	
	new String:text[192]
	GetCmdArgString(text, sizeof(text))
 
	new startidx = trim_quotes(text)
	
	new AdminFlag:flag
	BitToFlag(ADMIN_SEEALL, flag)
	new AdminId:aid
		
	new String:name[32]
	GetClientName(client,name,31)

	//need to send message to admin if sender is dead
	if (GetEntData(client, LifeStateOff, 1) != 0)
	{
		//dead
		for (new i=1; i<=maxplayers; i++)
		{
			if (IsClientInGame(i))
			{
				aid = GetUserAdmin(i)
				if (GetAdminFlag(aid, flag, Access_Effective) && (GetEntData(client, LifeStateOff, 1) == 0))
					PrintToChat(i,"\x01\x04[ADMINSEEALL]%s: %s",name,text[startidx])
			}
		}	
	}
	
	/* Let say continue normally */
	return Plugin_Continue
}

public Action:Command_SayTeam(client, args)
{
	if (!GetConVarInt(g_hAdminSeeAll))
		return Plugin_Continue
		
	new String:text[192]
	GetCmdArgString(text, sizeof(text))
 
	new startidx = trim_quotes(text)
	
	new AdminFlag:flag
	BitToFlag(ADMIN_SEEALL, flag)
	new AdminId:aid
		
	new String:name[32]
	GetClientName(client,name,31)
	
	new senderteam = GetClientTeam(client)
	new team

	if (GetEntData(client, LifeStateOff, 1) == 0)
	{
		//alive
		for (new i=1; i<=maxplayers; i++)
		{
			if (IsClientInGame(i))
			{
				aid = GetUserAdmin(i)
				team = GetClientTeam(i)
				if (GetAdminFlag(aid, flag, Access_Effective) && (senderteam != team))
					PrintToChat(i,"\x01\x04[ADMINSEEALL]%s: %s",name,text[startidx])
			}
		}	
	}
	else
	{
		//dead	
		for (new i=1; i<=maxplayers; i++)
		{
			if (IsClientInGame(i))
			{
				aid = GetUserAdmin(i)
				team = GetClientTeam(i)
				if (GetAdminFlag(aid, flag, Access_Effective) && ((GetEntData(client, LifeStateOff, 1) == 0) || (senderteam != team)))
					PrintToChat(i,"\x01\x04[ADMINSEEALL]%s: %s",name,text[startidx])
			}
		}	
		
	}
	
	/* Let say continue normally */
	return Plugin_Continue
}

