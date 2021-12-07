#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "Car Alarm Inform",
	author = "Eyal282 ( FuckTheSchool )",
	description = "Tells the players whomst'dve the fucc started the mofo car alarm",
	version = "2.0",
	url = "<- URL ->"
}

new Fuccer, String:FuccerName[32];
new bool:AlarmWentOff;

public OnPluginStart()
{
	HookEvent("create_panic_event", Event_CreatePanicEvent, EventHookMode_Post);
	HookEvent("triggered_car_alarm", Event_TriggeredCarAlarm, EventHookMode_Pre);
}

public Action:Event_TriggeredCarAlarm(Handle:hEvent, String:Name[], bool:dontBroastcast)
{
	AlarmWentOff = true;
}
public Action:Event_CreatePanicEvent(Handle:hEvent, String:Name[], bool:dontBroastcast)
{
	Fuccer = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(Fuccer == 0) // Console panic events.
		return;
		
	else if(GetClientTeam(Fuccer) != 2) // Better safe than sorry.
		return;
	
	GetClientName(Fuccer, FuccerName, sizeof(FuccerName));
	RequestFrame(CheckAlarm, 0);
}

public CheckAlarm(zero) // Zero is basically a null variable, I didn't need to pass a variable but I'm forced to.
{
	if(!AlarmWentOff)
		return;

	AlarmWentOff = false;
	
	// I took his name in the impossible case where he logs out a frame later.
	PrintToChatAll("\x03%s \x01has triggered the\x04 car alarm!\x01 I wanna see the\x05 hate!", FuccerName);
}

stock Float:GetXOriginByCircleStage(Stage, Float:Origin[3])
{
	if(Stage == 0)
		return Origin[0] + 50.0;
		
	else if(Stage == 1)
		return Origin[0] - 50.0;
		
	else if(Stage == 4)
		return Origin[0] + 40.0;
	
	else if(Stage == 5)
		return Origin[0] - 40.0;
	
	else if(Stage == 6)
		return Origin[0] + 25.0;
	
	else if(Stage == 7)
		return Origin[0] + 25.0;
	
	return Origin[0];
}

stock Float:GetYOriginByCircleStage(Stage, Float:Origin[3])
{
	if(Stage == 2)
		return Origin[1] + 50.0;
	
	else if(Stage == 3)
		return Origin[1] - 50.0;
		
	else if(Stage == 4)
		return Origin[1] + 40.0;
		
	else if(Stage == 5)
		return Origin[1] - 40.0;
	
	else if(Stage == 6)
		return Origin[1] + 30.0;
	
	else if(Stage == 7)
		return Origin[1] + 30.0;
		
	return Origin[1];
}