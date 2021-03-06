/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools> 

new Handle:l4d_hunter_pounce_move= INVALID_HANDLE;
 
new Handle:pounce_move_timer[MAXPLAYERS+1];
new pounce_push_ent[MAXPLAYERS+1];
new bool:l4d2=false;
new GameMode;
public Plugin:myinfo = 
{
	name = "L4D & L4D2 movable hunter",
	author = "Pan Xiaohai",
	description = "<- Description ->",
	version = "1.0",
	url = "<- URL ->"
}

public OnPluginStart()
{
	GameCheck(); 	 
	l4d_hunter_pounce_move  = CreateConVar("l4d_hunter_pounce_move", "30.0", "movable probability when hunter pounce", FCVAR_PLUGIN);
 
	if(GameMode!=2)
	{
		HookEvent("lunge_pounce", lunge_pounce);
		HookEvent("pounce_end", pounce_end); 
		AutoExecConfig(true, "l4d_hunter"); 
	}
}
public Action:lunge_pounce(Handle:event, String:event_name[], bool:dontBroadcast)
{
 
	new victim  = GetClientOfUserId(GetEventInt(event, "victim")); victim=victim*1;
	new attacker  = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetRandomFloat(0.0, 100.0)<GetConVarFloat( l4d_hunter_pounce_move))
	{		
		pounce_push_ent[attacker]=CreatePushForce(attacker, 1800.0, 250.0);
		pounce_move_timer[attacker]=CreateTimer(0.3, HunterMove, attacker, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
	} 
  	return Plugin_Continue;
}
public Action:pounce_end(Handle:event, String:event_name[], bool:dontBroadcast)
{
 
	new victim  = GetClientOfUserId(GetEventInt(event, "victim"));victim=victim*1;
	new attacker  = GetClientOfUserId(GetEventInt(event, "userid"));
	if(pounce_move_timer[attacker]!= INVALID_HANDLE)
	{
		KillTimer(pounce_move_timer[attacker]);
		pounce_move_timer[attacker]= INVALID_HANDLE ;		
		new ent=pounce_push_ent[attacker];
		pounce_push_ent[attacker]=0;	 
		DeletePushForce(ent);
		//PrintToChatAll("end");
	}	 
  	return Plugin_Continue;
}
public Action:HunterMove(Handle:timer, any:attacker)
{
	if(IsClientInGame(attacker) && IsPlayerAlive(attacker))
	{
		//PrintToChatAll("move"); 
		SetPushForcePos(attacker, 150.0, 180.0);
		return Plugin_Continue;
	}
	else
	{
		pounce_move_timer[attacker]= INVALID_HANDLE ;
		new ent=pounce_push_ent[attacker];
		pounce_push_ent[attacker]=0;	 
		DeletePushForce(ent);
		//PrintToChatAll("end");
		return Plugin_Stop;
	}
	
}
CreatePushForce(attacker, Float:force, Float:radius)
{
	new Float:pos[3];
	GetClientAbsOrigin(attacker, pos);
	new push = CreateEntityByName("point_push");         
	DispatchKeyValueFloat (push, "magnitude", force);                     
	DispatchKeyValueFloat (push, "radius", radius*1.0);                     
	SetVariantString("spawnflags 24");                             
	AcceptEntityInput(push, "AddOutput");
	DispatchSpawn(push);   
	TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);  
	AcceptEntityInput(push, "Enable");
	return push;
}
SetPushForcePos(attacker,  Float:force, Float:radius)
{
	new ent=pounce_push_ent[attacker];
	if(ent>0)
	{
		new Float:pos[3];
		GetClientAbsOrigin(attacker, pos);
		pos[0]+=GetRandomFloat(-10.0, 10.0);
		pos[1]+=GetRandomFloat(-10.0, 10.0);
		pos[2]+=GetRandomFloat(-5.0, 5.0); 
		DispatchKeyValueFloat (ent, "magnitude", force);                     
		DispatchKeyValueFloat (ent, "radius", radius*1.0);  
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);  
	}
}
DeletePushForce(ent)
{
	if(ent>0 && IsValidEntity(ent) && IsValidEdict(ent))
	{
		decl String:classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if (StrEqual(classname, "point_push", false))
		{
			AcceptEntityInput(ent, "Disable");
			AcceptEntityInput(ent, "Kill"); 
			RemoveEdict(ent);
		}	
	}
}
GameCheck()
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	
	
	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		GameMode = 1;
	else
	{
		GameMode = 0;
 	}

	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
 
		l4d2=true;
	}	
	else
	{
 
		l4d2=false;
	}
	l4d2=!!l4d2;
} 
