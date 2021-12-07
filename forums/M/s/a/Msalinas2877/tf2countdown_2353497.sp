#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <timers>

public Plugin:myinfo = 
{
    name = "Boss Spawn Random",
    author = "Msalinas2877",
    version = "1.0"
}

new String:gS_Bosses[][] = 
{
    "merasmus",
    "headless_hatman",
};
 
public void OnPluginStart()
{
	HookEventEx("teamplay_round_active", Event_Play);
}

public OnMapStart()
{
	PrecacheSound("*/vo/announcer_begins_5sec.mp3");
	PrecacheSound("*/vo/announcer_begins_4sec.mp3");
	PrecacheSound("*/vo/announcer_begins_3sec.mp3");
	PrecacheSound("*/vo/announcer_begins_2sec.mp3");
	PrecacheSound("*/vo/announcer_begins_1sec.mp3");
}
 
public Action:Event_Play(Event event, const char[] name, bool dontBroadcast)
{
	decl String:mapname[128];
    GetCurrentMap(mapname, sizeof(mapname));
 
    if (strncmp(mapname, "ctf_2fort", 9) == 0)
    {
		new randomspawn = GetRandomInt(1, 900);
	
		new randomspawntimer = float(randomspawn);
	
		CreateTimer(randomspawntimer, BossSpawn);
	
		PrintCenterTextAll("Boss Will Spawn In %d Seconds", randomspawn);
	}
	
	if (GameRules_GetProp("m_bPlayingKoth") == 1)
    {
		HookEvent("teamplay_point_captured", Event_Cap);
    }
}

public void Event_Cap(Handle event, const char[] name, bool dontBroadcast)
{
	new cpspawn = FindEntityByClassname(-1 , "team_control_point");
	
	new Float:position[3];
	GetEntPropVector(cpspawn, Prop_Send, "m_vecOrigin", position);
		
	new randomspawn = GetRandomInt(1, 180);
	
	new randomspawntimer = float(randomspawn);
	
	CreateTimer(randomspawntimer, BossSpawn);
	
	PrintCenterTextAll("Boss Will Spawn In %d Seconds", randomspawn);
	
	UnhookEvent("teamplay_point_captured", Event_Cap);
}

public Action:BossSpawn(Handle:timer)
{
	CreateTimer(1.0, Five);
	CreateTimer(2.0, Four);
	CreateTimer(3.0, Three);
	CreateTimer(4.0, Two);
	CreateTimer(5.0, One);
}

public Action:Five(Handle:timer)
{
	EmitSoundToAll("*/vo/announcer_begins_5sec.mp3");
}

public Action:Four(Handle:timer)
{
	EmitSoundToAll("*/vo/announcer_begins_4sec.mp3");
}

public Action:Three(Handle:timer)
{
	EmitSoundToAll("*/vo/announcer_begins_3sec.mp3");
}

public Action:Two(Handle:timer)
{
	EmitSoundToAll("*/vo/announcer_begins_2sec.mp3");
}

public Action:One(Handle:timer)
{
	EmitSoundToAll("*/vo/announcer_begins_1sec.mp3");
	new entindex = CreateEntityByName(gS_Bosses[GetRandomInt(0, sizeof(gS_Bosses) - 1)]); 
	DispatchSpawn(entindex);
	ActivateEntity(entindex);
	SetEntProp(entindex, Prop_Send, "m_bGlowEnabled", 1);
}