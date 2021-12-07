/*
Thanks to VoiDeD for his collisionhook extension which allow us to say good-bye to the mayhem bug ;)
*/

#include <sourcemod>
#include <sdktools>
#include <collisionhook>
#include <sendproxy>

#define VERSION "2.1.0"

#pragma semicolon 1

#define COLLIDE_DISABLE_BUTTONS (IN_ATTACK | IN_ATTACK2)

public Plugin:myinfo =
{
	name = "No-collide Teammate",
	author = "Mirandor",
	description = "Players dont collide if they are in the same team.",
	version = VERSION,
	url = "www.sourcemod.net"
};

new Handle:g_NoCollide_Chat 	= INVALID_HANDLE;
new Handle:g_NoCollide_Time 	= INVALID_HANDLE;
new Handle:g_FriendlyFire 		= INVALID_HANDLE;
new NoCollide_FF 				= 0;
new NoCollide_Chat 				= 0;
new Float:NoCollide_Time 		= 0.0;
new bool:NoCollide_Disabled 	= false;
new bool:NoCollide_Delayed 		= false;
new bool:P_Move[MAXPLAYERS+1]	= false;

public OnPluginStart()
{
	LoadTranslations("no_collide_teammate.phrases");
	
	CreateConVar( "SM_NoCollideTeammate_version", VERSION, "Version of the no-collide teammate plugin", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY );
	
	g_NoCollide_Chat = CreateConVar("SM_NoCollideTeammate_Chat", "1", "Messages displayed to all players (in chat) or to server console only.\n1 - Print to chat\n0 - Print to server", _, true, 0.0, true, 1.0);
	g_NoCollide_Time = CreateConVar("SM_NoCollideTeammate_Time", "0.0", "Number of seconds after round_start with no-collision features.\n-1.0 = Collisions are always enabled\n 0.0 = Collisions are always disabled (default setting)\n>0.0 = Collisions are disabled for x seconds)", FCVAR_NONE, true, -1.0);
	
	//FriendlyFire does not work as is while collisions are removed, so i've had to add a shitty option to take care of it...
	g_FriendlyFire = FindConVar("mp_friendlyfire");
	
	HookEvent("round_start", EventRoundStart);
	
	HookConVarChange(g_NoCollide_Chat, OnSettingsChanged);
	HookConVarChange(g_NoCollide_Time, OnSettingsChanged);
	HookConVarChange(g_FriendlyFire, OnSettingsChanged);
	
	AutoExecConfig(true, "no_collide_teammate");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			SendProxy_Hook(i, "m_CollisionGroup", Prop_Int, ProxyCallback);
	}
	return APLRes_Success;
}

public OnMapStart()
{
	NoCollide_Chat = GetConVarInt(g_NoCollide_Chat);
	NoCollide_Time = GetConVarFloat(g_NoCollide_Time);
	if (NoCollide_Time < 0)
		NoCollide_Disabled = true;
}

public OnSettingsChanged(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_NoCollide_Chat)
		NoCollide_Chat = StringToInt(newvalue);
	
	if(cvar == g_NoCollide_Time)
	{
		NoCollide_Time = StringToFloat(newvalue);
		
		if (NoCollide_Time < 0)
		{
			NoCollide_Time = -1.0;
			NoCollide_Disabled = true;
			SP_Unhook();
		}
		else
		{
			NoCollide_Disabled = false;
			SP_Hook();
		}
			
		NoCollide_Delayed = false;
	}
	if(cvar == g_FriendlyFire)
		NoCollide_FF = StringToInt(newvalue);
}

SP_Hook(){
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
		{
			continue;
		}
		SendProxy_Hook(i, "m_CollisionGroup", Prop_Int, ProxyCallback);
	}
}

SP_Unhook()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
		{
			continue;
		}
		SendProxy_Unhook(i, "m_CollisionGroup", ProxyCallback);
	}
}


public OnClientPutInServer(client)
{
	if (NoCollide_Time >= 0)
		SendProxy_Hook(client, "m_CollisionGroup", Prop_Int, ProxyCallback);
}

public Action:ProxyCallback(entity, String:propname[], &iValue, element)
{	
	iValue = 2;
	return Plugin_Changed;
}

public Action:EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (NoCollide_Time < 0)
	{
		if (NoCollide_Chat)
			PrintToChatAll("[SM] %t", "NCTC_P_Enabled");
		else
			PrintToServer("Teammate collisions are permanently Enabled.");
	}
	else
	{
		if (NoCollide_Time == 0)
		{
			if (NoCollide_Chat)
				PrintToChatAll("\x01[SM] %t", "NCTC_P_Disabled");
			else
				PrintToServer("Teammate collisions are permanently Disabled.");
		}
		else
		{
			for (new i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i))
					P_Move[i] = false;
			
			if (NoCollide_Chat)
				PrintToChatAll("\x01[SM] %t", "NCTC_Disabled", "\x04", NoCollide_Time, "\x01");
			else
				PrintToServer("Teammate collisions are Disabled for %0.1f seconds.", NoCollide_Time);
			
			NoCollide_Disabled = false;
			NoCollide_Delayed = false;
			CreateTimer(NoCollide_Time, Timer_Check_Collision, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:Timer_Check_Collision(Handle:timer)
{
	NoCollide_Delayed = true;
	CreateTimer(0.1, Timer_Disable_Collision, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_Disable_Collision(Handle:timer)
{
	if (NoCollide_Chat)
		PrintToChatAll("[SM] %t", "NCTC_Enabled");
	else
		PrintToServer("[SM] Teammate collisions are now Enabled.");
	
	NoCollide_Disabled = true;
}

public Action:CH_PassFilter(ent1, ent2, &bool:result)
{	
	if (NoCollide_Disabled)
		return Plugin_Continue;
	
	if (IsValidClient(ent1) && IsValidClient(ent2))
	{
		if (IsSameTeam(ent1, ent2))
		{
			//If FriendlyFire is ON, we have to check if players are using attack or attack2 buttons...
			if(NoCollide_FF)
				if((GetClientButtons(ent1) & COLLIDE_DISABLE_BUTTONS) || (GetClientButtons(ent2) & COLLIDE_DISABLE_BUTTONS))
					return Plugin_Continue;
					
			//FF is Off or players don't use attack/attack2 buttons so let's remove collisions
			result = false;
			
			//Timer has just ended, so let's check if many players have to be moved...
			if (NoCollide_Delayed)
				ShouldMove(ent1, ent2);
				
			return Plugin_Handled;
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

ShouldMove(player1, player2)
{
	new Float:vec_player1[3], Float:vec_player2[3];
	GetClientAbsOrigin(player1, vec_player1);
	GetClientAbsOrigin(player2, vec_player2);
			
	if(GetVectorDistance(vec_player1, vec_player2, true) < 33.0)
	{
		//PrintToServer("%N collide with %N", player1, player2);
				
		if (P_Move[player1] && P_Move[player2])
			P_Move[player2] = false;
				
		if (!P_Move[player2])
		{
			//Force player2 to move backward
			//we hope players won't collide anymore...
			vec_player2[0] = FloatSub(vec_player2[0], 65.0);
			TeleportEntity(player2, vec_player2, NULL_VECTOR, NULL_VECTOR);
					
			if (NoCollide_Chat)
				PrintToChat(player2, "[SM] %t", "NCTC_Moved");
			else
				PrintToConsole(player2, "[SM] You have been moved to prevent a collision with a teammate.");
					
			P_Move[player1] = true;
			P_Move[player2] = true;
		}
	}
}

stock bool:IsValidClient(client) 
{
	if (0 < client <= MaxClients && IsClientInGame(client))
		return true;
		
	return false; 
}

stock bool:IsSameTeam(client1, client2) 
{
	new team1 = GetClientTeam(client1);
	new team2 = GetClientTeam(client2);
	
	if (team1 == team2 && team1 > 0) 
		return true;
		
	return false; 
}