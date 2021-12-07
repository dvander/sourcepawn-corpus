#pragma semicolon 1
#include <sdktools>
#include <sourcemod>


public Plugin:myinfo = 
{
    name = "Climb Map Timer",
    author = "Raydan",
    description = "Provide climb map timer forward",
    version = "1.0",
    url = "http://www.zombiex2.net"
};
new Handle:hStartPress = INVALID_HANDLE;
new Handle:hEndPress = INVALID_HANDLE;
public OnPluginStart()
{
	HookEntityOutput("func_button", "OnPressed", ButtonPress);
}
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	hStartPress = CreateGlobalForward("CL_OnStartTimerPress", ET_Ignore, Param_Cell);
	hEndPress = CreateGlobalForward("CL_OnEndTimerPress", ET_Ignore, Param_Cell);
	return true;
}
public ButtonPress(const String:name[], caller, activator, Float:delay)
{
	if(!IsValidEntity(caller) || !IsValidEntity(activator))
		return;
	decl String:targetname[128];
	GetEdictClassname(activator,targetname, sizeof(targetname));
	if(!StrEqual(targetname,"player"))
		return;
	GetEntPropString(caller, Prop_Data, "m_iName", targetname, sizeof(targetname));
	if(StrEqual(targetname,"climb_startbutton"))
	{
		Call_StartForward(hStartPress);
		Call_PushCell(activator);
		Call_Finish();
	} else if(StrEqual(targetname,"climb_endbutton")) {
		Call_StartForward(hEndPress);
		Call_PushCell(activator);
		Call_Finish();
	}
}