#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo = 
{
	name = "[L4D] Colors Admin",
	author = "AlexMy(edit. by BloodyBlade)",
	description = "Set custom body colors and outline colors to admin players",
	version = "1.0",
	url = "https://"
};

int ColorOverride[MAXPLAYERS + 1];

public void OnPluginStart()
{
	HookEvent("player_spawn", EventAdminSpawn, EventHookMode_Post);
}

public void EventAdminSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int adminid = GetClientOfUserId(event.GetInt("userid"));
	if(adminid)
	{
		int flags = GetUserFlagBits(adminid);
		if(flags)
		{
    		if(flags & ADMFLAG_ROOT)
    		{
    			SetEntityRenderColor(adminid, 255, 0, 0, 255); //red
    			ColorOverride[adminid] = 255; //red
    		}
    		else if(flags & ADMFLAG_GENERIC)
    		{
    			SetEntityRenderColor(adminid, 0, 0, 255, 255); //blue
    			ColorOverride[adminid] = 16711680; //blue
    		}
    		else if(flags & ADMFLAG_CUSTOM1)
    		{
    			SetEntityRenderColor(adminid, 0, 255, 0, 255); //green
    			ColorOverride[adminid] = 52224; //green
    		}
    		SetEntProp(adminid, Prop_Send, "m_glowColorOverride", ColorOverride[adminid]);
    		SetEntProp(adminid, Prop_Send, "m_iGlowType", 3);
    		SetEntProp(adminid, Prop_Send, "m_bFlashing", 0);
    		SetEntProp(adminid, Prop_Send, "m_nGlowRange", 0);
		}
	}
}
