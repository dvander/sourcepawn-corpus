#include <sdkhooks>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>



// Change this [ADMFLAG_CUSTOM2] To get your target flag who overrides these advertisements and get Boosts
#define VIP_FLAG ADMFLAG_CUSTOM2



public void OnPluginStart()
{
	RegConsoleCmd("sm_stop", Command_StopListen);
	HookEvent("player_death", Event_PlayerDeath);
	CreateTimer(30.0, Timer_FreeVip, _); // Comment to remove
}

public Action Event_PlayerDeath(Handle hEvent, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int killer = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	int deathflags = GetEventInt(hEvent, "death_flags");
	
	if(!(GetUserFlagBits(client) & VIP_FLAG) && (deathflags & TF_DEATHFLAG_DEADRINGER))  
	{
		Handle Kv = CreateKeyValues("motd");
		KvSetString(Kv, "title", "No hard feelings");
		KvSetNum(Kv, "type", MOTDPANEL_TYPE_URL);
		switch(GetRandomInt(1, 14))
		{
			case 1: KvSetString(Kv, "msg", "LINK HERE"); 
/*
			EXAMPLES
			case 1: KvSetString(Kv, "msg", "http://adf.ly/1IImDG");
			case 2: KvSetString(Kv, "msg", "http://adf.ly/1LMXqS");
			case 3: KvSetString(Kv, "msg", "http://adf.ly/1LMZAQ");
			case 4: KvSetString(Kv, "msg", "http://adf.ly/1LMbql");
			case 5: KvSetString(Kv, "msg", "http://adf.ly/1LMcHB");
			case 6: KvSetString(Kv, "msg", "http://adf.ly/1LMcul");
			case 7: KvSetString(Kv, "msg", "http://adf.ly/1LMcyw");
			case 8: KvSetString(Kv, "msg", "http://adf.ly/1LMd49");
			case 9: KvSetString(Kv, "msg", "http://adf.ly/1Q3DFy"); 
			case 10: KvSetString(Kv, "msg", "http://adf.ly/1SKFzx"); 
			case 11: KvSetString(Kv, "msg", "http://adf.ly/1SKGEs"); 
			case 12: KvSetString(Kv, "msg", "http://adf.ly/1SKGSR"); 
			case 13: KvSetString(Kv, "msg", "http://adf.ly/1SKGVU"); 
			case 14: KvSetString(Kv, "msg", "http://adf.ly/1SKGc2"); 
*/
		}
		KvSetNum(Kv, "customsvr", 1);
		
		ShowVGUIPanel(client, "info", Kv);
		CloseHandle(Kv);
	}
	
	if(client != 0 && killer != 0 && client != killer && client <= MaxClients && killer <= MaxClients 
	&& GetClientTeam(client) != GetClientTeam(killer) && deathflags != TF_DEATHFLAG_DEADRINGER)
	{
		SetEntProp(killer, Prop_Send, "m_iHealth", GetEntProp(killer, Prop_Send, "m_iHealth") + 5);
	}
}



public Action:Timer_FreeVip(Handle:timer, any)
{
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("{green}----------------------------");
	CPrintToChatAll("{green}Server Advertisements v1.1");
	CPrintToChatAll("{green}By vikvek.com");
	CPrintToChatAll("{green}----------------------------");
}



public Action:Command_StopListen(client, args)
{
	DoUrl(client, "http://google.com");
	
	return Plugin_Handled;
}

public Action:DoUrl(client, String:url[255])
{
	new Handle:setup = CreateKeyValues("data");
	
	KvSetString(setup, "title", "TTS");
	KvSetNum(setup, "type", MOTDPANEL_TYPE_URL);
	KvSetString(setup, "msg", url);
	KvSetNum(setup, "customsvr", 1);
	
	ShowVGUIPanel(client, "info", setup, true);
	CloseHandle(setup);
	return Plugin_Handled;
}