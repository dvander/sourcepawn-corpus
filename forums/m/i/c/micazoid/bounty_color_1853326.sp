#include <sourcemod>
#include <cstrike>
#include <colors>
//CT
new Handle:h_Red = INVALID_HANDLE;
new Handle:h_Green = INVALID_HANDLE;
new Handle:h_Blue = INVALID_HANDLE;
new Handle:h_Alpha = INVALID_HANDLE;
//T
new Handle:h_RedT = INVALID_HANDLE;
new Handle:h_GreenT = INVALID_HANDLE;
new Handle:h_BlueT = INVALID_HANDLE;
new Handle:h_AlphaT = INVALID_HANDLE;
new Handle:h_Amount = INVALID_HANDLE;
new kills[MAXPLAYERS+1]
#define PLUGIN_VERSION "1";

public Plugin:myinfo =
{
	name = "Bounty_Colors",
	author = "ShadowDragon",
	description = "change color after x kills",
	version = "PLUGIN_VERSION",
	url = "digital-laser.net"
};

public OnPluginStart()
{
	//convar
	h_Red = CreateConVar("sm_bRed", "255", "255 = strong 0 = non");
	h_Green = CreateConVar("sm_bGreen", "255", "255 = strong 0 = non");
	h_Blue = CreateConVar("sm_bBlue", "255", "255 = strong 0 = non");
	h_Alpha = CreateConVar("sm_bAlpha", "255", "255 = strong 0 = non");
	
	h_RedT = CreateConVar("sm_bRedT", "255", "255 = strong 0 = non");
	h_GreenT = CreateConVar("sm_bGreenT", "255", "255 = strong 0 = non");
	h_BlueT = CreateConVar("sm_bBlueT", "255", "255 = strong 0 = non");
	h_AlphaT = CreateConVar("sm_bAlphaT", "255", "255 = strong 0 = non");
	h_Amount = CreateConVar("sm_kills_needed", "1", "kills needed to get leader color");
	
	HookEvent("player_spawn",SpawnEvent);
	HookEvent("player_death",DeathEvent);
}



public Action:SpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client_id = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_id);
	new Amount = GetConVarInt(h_Amount);
	//spawn color
	
	if(kills[client] > Amount)
	{
		if (GetClientTeam(client) == 3)
		{	
			
				new Red = GetConVarInt(h_Red);
				new Green = GetConVarInt(h_Green);
				new Blue = GetConVarInt(h_Blue);
				new Alpha = GetConVarInt(h_Alpha);
				SetEntityRenderColor(client, Red, Green, Blue, Alpha);	
		
		}
		
		if (GetClientTeam(client) == 2)
		{	
		
				new RedT = GetConVarInt(h_RedT);
				new GreenT = GetConVarInt(h_GreenT);
				new BlueT = GetConVarInt(h_BlueT);
				new AlphaT = GetConVarInt(h_AlphaT);
				SetEntityRenderColor(client, RedT, GreenT, BlueT, AlphaT);	
		
		}
	}
	
		

}

public Action:DeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new victim_id = GetEventInt(event, "userid");
	new attacker_id = GetEventInt(event, "attacker");
 
	new victim = GetClientOfUserId(victim_id);
	new attacker = GetClientOfUserId(attacker_id);
	if (victim && attacker && GetClientTeam(victim) != GetClientTeam(attacker))
	{
		kills[attacker]++;
		
		if(kills[attacker] == 0)
		{
			if (GetClientTeam(attacker) == 3)
			{		
				SetEntityRenderColor(attacker, 255, 255, 255, 255);	
				
			}
		
			if (GetClientTeam(attacker) == 2)
			{
				SetEntityRenderColor(attacker, 255, 255, 255, 255);	
			
			}
			
		}
		
	}	
	
	kills[victim] = 0;
	if(kills[victim] == 0)
	{
		CPrintToChat(victim, "{green}[Bounty] {olive}Du bist tot und Du bist kein Führer.");  
	}

		
}




	