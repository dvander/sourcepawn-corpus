#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define Color1   {255,0,0,255}    // red
#define Color2   {0,0,255,255}    // blue
#define Color3   {0,255,0,255} 	  // green
#define Color4   {255,48,48,255}  // Firebrick1
#define Color5   {255,255,0,255}  // Yellow
#define Color6   {50,205,50,255}  // LimeGreen
#define Color7   {160,32,240,255} // Purple
#define Color8   {255,0,255,255}  // Magenta
#define Color9	 {30,144,255,255} // DodgerBlue
#define Color10  {255,165,0,255}  // Orange

new Handle:laseroffset	= INVALID_HANDLE;

new Sprite1;
new Sprite2;
new Float:Origin[3];
new Float:myPos[3];
new Float:myAng[3];
new Float:trsPos[3];
new Float:trsPos002[3];
new player_id[MAXPLAYERS+1];
new laszer[MAXPLAYERS+1];
new g_color = 1;

public Plugin:myinfo = {
	name = "[L4D2]Ammo Laszer",
	author = "AK978",
	version = "1.1"
}

public void OnPluginStart(){
	RegConsoleCmd("sm_ammo_laszer_on",laszer_on);
	RegConsoleCmd("sm_amno_laszer_off",laszer_off);
	
	HookEvent("bullet_impact",SlugImpact);
	HookEvent("weapon_fire",weapon_fire);

	laseroffset = CreateConVar("l4d2_laseroffset", "36", "Tracker offeset", 0);
}

public OnClientDisconnect(client){
	laszer[client] = 0;
}
    
public void OnMapStart(){
    g_color++;

    Sprite1 = PrecacheModel("materials/sprites/laserbeam.vmt");    
    Sprite2 = PrecacheModel("materials/sprites/glow.vmt");
}

public Action laszer_on(int client,int args){
	laszer[client] = 1;
	PrintToChat(client, "子彈激光特效開啟,Open Ammo Laszer");
}

public Action laszer_off(int client,int args){
	laszer[client] = 0;
	PrintToChat(client, "子彈激光特效關閉,Close Ammo Laszer");
}

public SlugImpact(Handle:event,const String:name[],bool:dontBroadcast){	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(laszer[client] == 1){
		Origin[0] = GetEventFloat(event,"x");
		Origin[1] = GetEventFloat(event,"y");
		Origin[2] = GetEventFloat(event,"z");

		if (g_color == 11){
			g_color = 1;
		}
		else if (g_color == 1){		
			TE_SetupBeamPoints(myPos, Origin, Sprite1, Sprite2, 0, 0, 0.1, 0.2, 0.2, 0, 0.0, Color1, 0);
			TE_SendToAll();
		}
		else if (g_color == 2){		
			TE_SetupBeamPoints(myPos, Origin, Sprite1, Sprite2, 0, 0, 0.1, 0.2, 0.2, 0, 0.0, Color2, 0); 
			TE_SendToAll();
		}
		else if (g_color == 3){		
			TE_SetupBeamPoints(myPos, Origin, Sprite1, Sprite2, 0, 0, 0.1, 0.2, 0.2, 0, 0.0, Color3, 0); 
			TE_SendToAll();
		}
		else if (g_color == 4){		
			TE_SetupBeamPoints(myPos, Origin, Sprite1, Sprite2, 0, 0, 0.1, 0.2, 0.2, 0, 0.0, Color4, 0); 
			TE_SendToAll();
		}
		else if (g_color == 5){		
			TE_SetupBeamPoints(myPos, Origin, Sprite1, Sprite2, 0, 0, 0.1, 0.2, 0.2, 0, 0.0, Color5, 0); 
			TE_SendToAll();
		}
		else if (g_color == 6){		
			TE_SetupBeamPoints(myPos, Origin, Sprite1, Sprite2, 0, 0, 0.1, 0.2, 0.2, 0, 0.0, Color6, 0); 
			TE_SendToAll();
		}
		else if (g_color == 7){		
			TE_SetupBeamPoints(myPos, Origin, Sprite1, Sprite2, 0, 0, 0.1, 0.2, 0.2, 0, 0.0, Color7, 0); 
			TE_SendToAll();
		}
		else if (g_color == 8){		
			TE_SetupBeamPoints(myPos, Origin, Sprite1, Sprite2, 0, 0, 0.1, 0.2, 0.2, 0, 0.0, Color8, 0); 
			TE_SendToAll();
		}
		else if (g_color == 9){		
			TE_SetupBeamPoints(myPos, Origin, Sprite1, Sprite2, 0, 0, 0.1, 0.2, 0.2, 0, 0.0, Color9, 0); 
			TE_SendToAll();
		}
		else if (g_color == 10){		
			TE_SetupBeamPoints(myPos, Origin, Sprite1, Sprite2, 0, 0, 0.1, 0.2, 0.2, 0, 0.0, Color10, 0); 
			TE_SendToAll();
		}
		return;
	}
	return;
}

public weapon_fire(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(laszer[client] == 1){
		player_id[client] = GetClientOfUserId(GetEventInt(event, "userid"));
		GetClientEyePosition(player_id[client], myPos);
		GetClientEyeAngles(player_id[client], myAng);
		new Handle:trace = TR_TraceRayFilterEx(myPos, myAng, CONTENTS_SOLID|CONTENTS_MOVEABLE, RayType_Infinite, TraceEntityFilterPlayer, client);
		if(TR_DidHit(trace))
			TR_GetEndPosition(trsPos, trace);
		CloseHandle(trace);
		for(new i = 0; i < 3; i++)
			trsPos002[i] = trsPos[i];

		decl Float:tmpVec[3];
		SubtractVectors(myPos, trsPos, tmpVec);
		NormalizeVector(tmpVec, tmpVec);
		ScaleVector(tmpVec, GetConVarFloat(laseroffset));
		SubtractVectors(myPos, tmpVec, trsPos);
		
		return;
	}
	return;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask){
	return entity > MaxClients || !entity;
}