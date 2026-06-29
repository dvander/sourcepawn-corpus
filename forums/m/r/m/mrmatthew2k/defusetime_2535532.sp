#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <entity>  
// idk what im doing
public Plugin:myinfo = 
{
    name = "defusetime",
    author = "mrmatthew2k",
    description = "toggle with defusetime_enabled, prints the amount of time needed to defuse the the bomb",
    version = "1.0",
    url = "http://www.globalfragging.com"
}
ConVar g_PluginEnabledConVar;
public void OnPluginStart()
{
	 
	g_PluginEnabledConVar = CreateConVar("defusetime_enabled", "1", "Enables Run the bomb gamemode.", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	HookConVarChange(g_PluginEnabledConVar, ConVar_EnableChangeEnabled);
	ConVar_EnableCheck(); 

}
public void ConVar_EnableCheck()
{
     new enabled = GetConVarBool(g_PluginEnabledConVar);
 
     if (enabled)
     {
        OnPluginEnabledConVar();
     }
     else
     {
        OnPluginDisabledConVar();
     }
}
public void ConVar_EnableChangeEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
     new enabled = GetConVarBool(g_PluginEnabledConVar);
 
     if (enabled)
     {
        OnPluginEnabledConVar();
     }
     else
     {
        OnPluginDisabledConVar();
     }
}
public void OnPluginEnabledConVar()
{



	HookEvent("bomb_exploded", TimeLeft, EventHookMode_Pre);


}
public void OnPluginDisabledConVar()
{

    

	UnhookEvent("bomb_exploded", TimeLeft, EventHookMode_Pre);



}
public void TimeLeft(Event event, const String:name[], bool:dontBroadcast)
{
	
	int thebomb = FindEntityByClassname(-1,"planted_c4");
	
	decl float:g_timeleft;
	g_timeleft = GetEntPropFloat(thebomb, Prop_Send, "m_flDefuseCountDown") - GetGameTime() + 1.0;
	
	if (g_timeleft < 1.0 && g_timeleft > 0.0)
	{
	PrintToChatAll("%f more seconds were needed to defuse!", g_timeleft);
	PrintToServer("%f more seconds were needed to defuse!", g_timeleft);
	}
	else
	{
	// PrintToChatAll("%f seconds were needed to defuse!", g_timeleft);
	}	
}


