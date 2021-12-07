/**
 *  triggerhappy.sp - Adds event trigger support to specifically designed maps
 *  Copyright (C) 2012 William Scott
 * 
 *  History:
 * 		0.2 - Added support for Sudden Death events; Maps can use these triggers to change it's layout or (un)lock doors, etc.
 * 		0.1 - Alpha release, only supports voicemenu commands at the moment.
 * 		
 **/ 

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "TriggerHappy",
	author = "[poni] Shutterfly",
	description = "Adds event trigger support to specifically designed maps",
	version = "0.1",
	url = "forums.alliedmods.net"
}

public OnPluginStart()
{
	AddCommandListener(Event_VoiceMenu, "voicemenu");	// added v0.1
	
	HookEvent("teamplay_suddendeath_begin", Event_TeamplaySuddendeathBegin, EventHookMode_Post); // added v0.2
	HookEvent("teamplay_suddendeath_end", Event_TeamplaySuddendeathEnd, EventHookMode_Post); // added v0.2
}

public DoTrigger(String:triggername[], activator, caller)
{
	decl String:name[32];
	
	new index = -1;
	while((index = FindEntityByClassname(index, "trigger_brush")) != -1)
	{
		GetEntPropString(index, Prop_Data, "m_iName", name, sizeof(name));
		
		if(StrEqual(name, triggername))		
			AcceptEntityInput(index, "Use", activator, caller);
		
	}		
}


public Action:Event_VoiceMenu(client, const String:command[], argc)
{
	if(argc < 2)
		return Plugin_Handled;
	
	decl String:arg1[4];
	decl String:arg2[4];
	decl String:trigger[32];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	Format(trigger, sizeof(trigger), "voicemenu %s %s", arg1, arg2);
	
	DoTrigger(trigger, client, -1);
	
	//PrintCenterText(client, "%s", trigger);	
	return Plugin_Continue;
}

public Action:Event_TeamplaySuddendeathBegin(Handle:event, String:name[], bool:dontBroadcast)
{
	DoTrigger("teamplay_suddendeath_begin", -1, -1);
	return Plugin_Continue;
}

public Action:Event_TeamplaySuddendeathEnd(Handle:event, String:name[], bool:dontBroadcast)
{
	DoTrigger("teamplay_suddendeath_end", -1, -1);
	return Plugin_Continue;
}
