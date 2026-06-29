/*
[Css] Hostages Health
Change Hostages Health amount or give god mode.
- Works maps where added hostage rescue area.

cvars:
sm_hostages_god 0/1 			Hostages not die or get hurt, this disable sm_hostages_showhealth messages
sm_hostages_health 1/999999 	Set hostages health, 100 is default
sm_hostages_showhealth 0/1		Show hostage health to CT who pick him
sm_hostages_health_version		Current version

NOTICE!
- GOD mode start work when round start
- Health change when round start
- This plugin not generate configuration file

16.10.2010

Change
19.10.2010 V0.2
- Change word hostage to plural, hostages
- Added cvar sm_hostages_health_version
26.10.2010 V0.3
- Change code little, to not change hostages health if god mode enabled
- Hostages health show in green in chat message when CT pick him
30.10.2010 V0.4
- Buddha mode, hostages get hurt but not lose health
3.11.2010 V0.5
- Change code one more time to find hostage entities (optimized ?)
8.11.2010 V0.6
- Removed OnMapStart to hook and unhook events, now hook events once when plugin start.

11.11.2011 V0.7
- Not check anymore is map hostage rescue map.
- Hook/unhook two events depend how cvar are enabled. (Even if there fear that it duplicate event callback, I still leave it !!)
- Now change hostage health immediatelly when cvar change, not need wait to new round.
- Show hostage health chat output is now hint text. Edit source code if you want back.

*/

#include <sourcemod>
#include <sdktools>


#define PLUGIN_VERSION "0.7"

public Plugin:myinfo =
{
	name = "[Css] Hostages Health",
	author = "Bacardi",
	description = "Change Hostages Health or give god mode",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

//cvars
new Handle:cvars[3] = { INVALID_HANDLE, ... };
new cvars_value[2] = { 0, ... };

public OnPluginStart()
{
	CreateConVar("sm_hostages_health_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	// god
	cvars[0] = CreateConVar("sm_hostages_god", "0", "0 = Disabled, 1 = God mode, 2 = Buddha mode", 0, true, 0.0, true, 2.0);
	HookConVarChange(cvars[0], convar_changed);
	// hp
	cvars[1] = CreateConVar("sm_hostages_health", "0", "Set hostages health, 100 is default", 0, true, 0.0, true, 999999.0);
	HookConVarChange(cvars[1], convar_changed);
	// show
	cvars[2] = CreateConVar("sm_hostages_showhealth", "0", "Show hostage health to CT who pick him if god mode disabled", 0, true, 0.0, true, 1.0);
	HookConVarChange(cvars[2], convar_changed);


	// When plugin start/reload, do action!
	if( GetConVarBool(cvars[0]) || GetConVarBool(cvars[1]) ) // One of these two cvars need to be true
	{
		convar_changed(GetConVarBool(cvars[0]) ? cvars[0]:cvars[1], "0", "1"); // Do convar change
	}

	if( GetConVarBool(cvars[2]) ) // cvar true
	{
		convar_changed(cvars[2], "0", "1"); // Do convar change
	}
}


public convar_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	decl bool:oldv, bool:newv;
	oldv = StringToInt(oldValue) != 0;
	newv = StringToInt(newValue) != 0;

	if(convar == cvars[0] || convar == cvars[1]) // god or hp change
	{
		if( (!oldv && newv) && (!cvars_value[0] && !cvars_value[1]) ) // convar change old "0" new "1" and both cvars old value false
		{
			if(!HookEventEx("round_start", Event_RoundStart, EventHookMode_PostNoCopy))
			{
				SetFailState("Missing event round_start");
			}
		}

		// Take now real new cvar values
		cvars_value[0] = GetConVarInt(cvars[0]); //god
		cvars_value[1] = GetConVarInt(cvars[1]); // hp

		// Do round start, update hostages health
		Event_RoundStart(INVALID_HANDLE, "round_start", false);

		if( (oldv && !newv) && (!cvars_value[0] && !cvars_value[1]) ) // convar change old "1" new "0" and both cvars new value false
		{
			UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		}
	}

	if(convar == cvars[2]) // show health change
	{
		newv = GetConVarBool(cvars[2]);

		if(oldv != newv)
		{
			if(newv)
			{
				if(!HookEventEx("hostage_follows", Event_HostageFollows))
				{
					SetFailState("Missing event hostage_follows");
				}
			}
			else
			{
				UnhookEvent("hostage_follows", Event_HostageFollows);
			}
		}
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl bool:god, value;
	god = cvars_value[0] != 0;
	value = god ? (cvars_value[0] == 2 ? 1:0):(!cvars_value[1] ? 100:cvars_value[1]);

	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "hostage_entity")) != -1)
	{
		// god or mortal with health
		god ? SetEntProp(ent, Prop_Data, "m_takedamage", value):(SetEntProp(ent, Prop_Data, "m_iHealth", value), SetEntProp(ent, Prop_Data, "m_takedamage", 2));
	}
}


public Event_HostageFollows(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsFakeClient(client))
	{
		//cvars_value[0] ? PrintToChat(client, "\x01Hostage have \x04GOD mode\x01"):PrintToChat(client, "\x01Hostage health \x04%i\x01HP", GetEntProp(GetEventInt(event, "hostage"), Prop_Data, "m_iHealth", 1));
		cvars_value[0] ? PrintHintText(client, "Hostage have GOD mode"):PrintHintText(client, "Hostage health %iHP", GetEntProp(GetEventInt(event, "hostage"), Prop_Data, "m_iHealth", 1));
	}
}