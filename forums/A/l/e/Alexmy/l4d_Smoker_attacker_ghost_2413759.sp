#include <sourcemod>

Handle sm_cvarTranscolorSmoker = null;
Handle sm_cvarTranscolorSurvivor = null;
Handle sm_cvarNolmalSmoker = null;
Handle sm_cvarNormalSurvivor = null;

public Plugin:myinfo = 
{
	name = "[L4D] SMOKER ATTACKER GHOST",
	author = "AlexMy",
	description = "",
	version ="",
	url = "",
}

public void OnPluginStart()
{
	sm_cvarTranscolorSmoker = CreateConVar("sm_cvarTranscolorSmoker", "40", "Smoker transparency during capture survivor.", 0, true, 0.0, true, 255.0);
	
	sm_cvarTranscolorSurvivor = CreateConVar("sm_cvarTranscolorSurvivor", "40", "Survivor transparency when grabbed smoker.", 0, true, 0.0, true, 255.0);
	
	sm_cvarNolmalSmoker = CreateConVar("sm_cvarNolmalSmoker", "255", "Smoker transparent after a survivor freed.", 0, true, 0.0, true, 255.0);
	
	sm_cvarNormalSurvivor = CreateConVar("sm_cvarNormalSurvivor", "255", "Transparency Survivor after he was released from the smoker.", 0, true, 0.0, true, 255.0);
	AutoExecConfig(true, "L4D SMOKER ATTACKER GHOST");
	/*HookEvent("tongue_grab", Event_TongueStart); Захват языком (курильщик).*/
	HookEvent("choke_start", Event_TongueStart); /*Курильщик бьет жертву вблизи.*/
	
	HookEvent("choke_end", Event_TongueTheEnd); 
	HookEvent("choke_stopped", Event_TongueTheEnd); 
	HookEvent("tongue_pull_stopped", Event_TongueTheEnd); 
	HookEvent("tongue_broke_bent", Event_TongueTheEnd); 
	HookEvent("tongue_broke_victim_died", Event_TongueTheEnd) 
}

public void Event_TongueStart(Handle event, const char[] name, bool dontBroadcast)
{
	int userid = GetClientOfUserId(GetEventInt(event, "userid"));
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	SetEntityRenderMode(userid, RENDER_TRANSALPHA);
	SetEntityRenderColor(userid, 255, 255, 255, GetConVarInt(sm_cvarTranscolorSmoker));
	
	SetEntityRenderMode(victim, RENDER_TRANSALPHA);
	SetEntityRenderColor(victim, 255, 255, 255, GetConVarInt(sm_cvarTranscolorSurvivor));
}
public void Event_TongueTheEnd(Handle event, const char[] name, bool dontBroadcast)
{
	int userid = GetClientOfUserId(GetEventInt(event, "userid"));
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	SetEntityRenderMode(userid, RENDER_NORMAL);
	SetEntityRenderColor(userid, 255, 255, 255, GetConVarInt(sm_cvarNolmalSmoker));
	
	SetEntityRenderMode(victim, RENDER_NORMAL);
	SetEntityRenderColor(victim, 255, 255, 255, GetConVarInt(sm_cvarNormalSurvivor));
}