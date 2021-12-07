#include <sourcemod>
#include <sdktools_functions>

public Plugin:myinfo = {
	name = "nubtuber",
	author = "Grey bird",
	description = "Forces a player to use their knife after a while from when they crouch",
	version = "1.0",
	url = ""
};

new m_OffsetDuck;
new weapon;
new cflags;
new loop;
new Handle:g_CrouchTime = INVALID_HANDLE;
new bool:g_crouch_check[MAXPLAYERS+1] = {true,...};


public OnPluginStart()
{
	m_OffsetDuck = FindSendPropOffs("CBasePlayer", "m_fFlags");
	HookEvent("bullet_impact",ev_bullet_impact);
	g_CrouchTime = CreateConVar("crouch_time", "5", "The amount of time before Weaon change happens [Default:5].", FCVAR_PLUGIN);
}

public Action:ev_bullet_impact( Handle:event, const String:name[], bool:dontBroadcast )
{
	decl client;
	client = GetClientOfUserId(GetEventInt(event,"userid"));

	if ( (IsClientConnected(client)) && (IsClientInGame(client)) && (!IsFakeClient(client)) )
	{
	    loop = INVALID_HANDLE;	 
		cflags = GetEntData(client, m_OffsetDuck);
		if( cflags & FL_DUCKING && bool:g_crouch_check[client] )
		{
			loop = CreateTimer(1.0, Timer_Crouch, client, TIMER_REPEAT);
			PrintToChat(client, "[\x04nubtuber\x01] You have \x05%i \x01left to shoot while crouching. ", GetConVarInt(g_CrouchTime));
            g_crouch_check[client] = false;			
		}
	}
}

public Action:Timer_Crouch(Handle:timer, any:client)
{  
	static times = 0;	
	decl String:sWeapon[32];
	GetClientWeapon(client, sWeapon, sizeof(sWeapon));
	cflags = GetEntData(client, m_OffsetDuck);
	if (times < GetConVarFloat(g_CrouchTime) && cflags & FL_DUCKING && !StrEqual("weapon_knife",sWeapon) )	
	{		
		times +=1;
	}
	else if (times = GetConVarFloat(g_CrouchTime) && cflags & FL_DUCKING && !StrEqual("weapon_knife",sWeapon) )
	{ 
		weapon = GetPlayerWeaponSlot(client, 2);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		g_crouch_check[client] = true;
        return Plugin_Stop;		
	}
	else
	{
	 loop = INVALID_HANDLE;
	 g_crouch_check[client] = true;
	 return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
   if ( (!IsFakeClient(client)) )
   {
        loop = INVALID_HANDLE;
        CloseHandle(loop);
        g_crouch_check[client] = true;
   }
   
}