#include <cstrike>
#include <sdktools>
#include <colors>

#define Tag_Verison   "1.6"



new tag = 0;



public OnPluginStart() 
{
	RegAdminCmd("sm_tagon", tagon, ADMFLAG_GENERIC);
	RegAdminCmd("sm_tagoff", tagoff, ADMFLAG_GENERIC);
	AddCommandListener(HookPlayerChat, "say");
	
	CreateConVar("sm_tag_version", Tag_Verison,  "Enable or disable the admin tag made by ZcaverZ", FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_PLUGIN);
}


public Plugin:myinfo = {
	name = "Admin Tag",
	author = "ZcaverZ",
	description = "Admin kan välja om han vill ha tag eller inte",
	version = Tag_Verison,
	url = "ZcaverZ"
};


public Action:tagon(client, args) 
{
	if(tag == 0)
	{
		{
			CPrintToChat(client, "{green}[Admin Tag]{default} You have now actiaved the tag");
			tag = client;
		}
	}
}

public Action:tagoff(client, args)
{
	if(client == tag) 
	{
		CPrintToChat(client, "{green}[Admin Tag]{default} You have now disabled the tag");
		tag = 0;
	}
}

	
public Action:HookPlayerChat(client, const String:command[], args)
{
	if(tag == client)
	{
		decl String:szText[256];
		GetCmdArg(1, szText, sizeof(szText));
		
		if(szText[0] == '/')
		{
			return Plugin_Handled;
		}
		
		{
			CPrintToChatAll("{red}[Admin] {green}%N:{default} %s",client, szText);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}