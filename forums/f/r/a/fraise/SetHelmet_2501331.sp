#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>

Handle timercheck;



public Plugin myinfo = 
{
	name = "SetHelmet", 
	author = "Pookie", 
	description = "Set an helmet to player who have 100 armour", 
	version = "1.0", 
	url = "http://www.involved-gaming.com/forum/index.php"
};

public void OnPluginStart()
{
	HookEvent("round_start", EventArmour);	
}


public Action EventArmour(Handle event, const char[] name, bool dontBroadcast)
{
	timercheck = CreateTimer(2.0, SetHelmet, _, TIMER_REPEAT);
}


public Action SetHelmet(Handle timer)
{
	for (int i=1; i<=MaxClients; i++)
	{
		if (GetClientArmor(i)==100 )
		{
			if (IsPlayerAlive(i))		
			{
				SetEntProp(i, Prop_Send, "m_bHasHelmet", 1);
				
			}
			
		}
		
	}
}