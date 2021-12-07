/*
 *Grabber Plugin
 */

new const String:PluginVersion[60] = "1.0.0.94N9";

public Plugin:myinfo = {
	
	name = "GravityGun",
	author = "javalia",
	description = "Grab it!",
	version = PluginVersion,
	url = "http://www.sourcemod.net/"
	
};

//인클루드문장
#include <sourcemod>
#include <sdktools>
#include "sdkhooks"
#include "vphysics"
#include "stocklib"
#include "matrixmath"
#include <roleplay>

#include "rpggsound.inc"
#include "rpggcvars.inc"

//문법정의
#pragma semicolon 1

//are they using grabber?
//new bool:grabenabled[MAXPLAYERS + 1];
//which entity is grabbed?(and are we currently grabbing anything?) this is entref, not ent index
new grabbedentref[MAXPLAYERS + 1];

new keybuffer[MAXPLAYERS + 1];

new Float:grabangle[MAXPLAYERS + 1][3];
//new Float:grabpos[MAXPLAYERS + 1][3];

new Float:grabdistance[MAXPLAYERS + 1];

new Float:preeyangle[MAXPLAYERS + 1][3];
new Float:playeranglerotate[MAXPLAYERS + 1][3];

new Float:nextactivetime[MAXPLAYERS + 1];

public OnPluginStart(){
	
	HookEvent("player_spawn", EventSpawn);
	creategravityguncvar();

	//LoadTranslations("gravitygun.phrases");
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			grabbedentref[client] = -1;
			SDKHook(client, SDKHook_PreThink, PreThinkHook);
		}
	}
}

public OnMapStart(){
	
	prepatchsounds();

	AutoExecConfig();
	
}

public Action:EventSpawn(Handle:Event, const String:Name[], bool:Broadcast){
	
	decl client;
	client = GetClientOfUserId(GetEventInt(Event, "userid"));
	
	nextactivetime[client] = GetGameTime();
	
}

public OnClientPutInServer(client){

	grabbedentref[client] = -1;
	
	SDKHook(client, SDKHook_PreThink, PreThinkHook);

}

public OnClientDisconnect(client){
	
	//we must release any thing if it is on spectator`s hand
	release(client);
	
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon){

	if(IsClientConnectedIngameAlive(client)){
	
		if(clientisgrabbingvalidobject(client)){
		
			if(buttons & IN_USE){
	
				new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");	
				if((IsClientDriving(client)) || (IsValidEntity(car)))
				{		
					release(client);
					buttons &= ~IN_USE;
					return Plugin_Continue;
				}
			
				ZeroVector(vel);
				
				if(buttons & IN_MOVELEFT){
					
					buttons &= ~IN_MOVELEFT;
					playeranglerotate[client][1] = playeranglerotate[client][1] - 1.0;
				
				}else if(buttons & IN_MOVERIGHT){
				
					buttons &= ~IN_MOVERIGHT;
					playeranglerotate[client][1] = playeranglerotate[client][1] + 1.0;
				
				}
				
				if(buttons & IN_FORWARD){
				
					buttons &= ~IN_FORWARD;
					
					playeranglerotate[client][0] = playeranglerotate[client][0] + 1.0;
					
				
				}else if(buttons & IN_BACK){
				
					buttons &= ~IN_BACK;
					playeranglerotate[client][0] = playeranglerotate[client][0] - 1.0;
					
				
				}
			
			}
			
			if(buttons & IN_RELOAD){
				
				ZeroVector(vel);
				
				if(buttons & IN_MOVELEFT){
					
					buttons &= ~IN_MOVELEFT;
					playeranglerotate[client][2] = playeranglerotate[client][2] - 1.0;
				
				}else if(buttons & IN_MOVERIGHT){
				
					buttons &= ~IN_MOVERIGHT;
					playeranglerotate[client][2] = playeranglerotate[client][2] + 1.0;
				
				}
				
				if(buttons & IN_FORWARD){
				
					buttons &= ~IN_FORWARD;
					
					if(buttons & IN_SPEED){
					
						grabdistance[client] = grabdistance[client] + 10.0;
					
					}else{
					
						grabdistance[client] = grabdistance[client] + 1.0;
						
					}
					
					if(grabdistance[client] >= GetConVarFloat(cvar_grab_maxdistance)){
					
						grabdistance[client] = GetConVarFloat(cvar_grab_maxdistance);
					
					}
				
				}else if(buttons & IN_BACK){
				
					buttons &= ~IN_BACK;
					
					if(buttons & IN_SPEED){
					
						grabdistance[client] = grabdistance[client] - 10.0;
					
					}else{
					
						grabdistance[client] = grabdistance[client] - 1.0;
						
					}
					
					if(grabdistance[client] < GetConVarFloat(cvar_grab_mindistance)){
					
						grabdistance[client] = GetConVarFloat(cvar_grab_mindistance);
					
					}
				
				}
			
			}
			
		}
		
	}
	
	return Plugin_Continue;

}

public PreThinkHook(client){
	
	if((IsClientConnectedIngameAlive(client)) && (client > 0)){
		
		new buttons = GetClientButtons(client);
		new clientteam = GetClientTeam(client);	
		new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
		
		
		if((buttons & IN_USE)  && clientisgrabbingvalidobject(client)){
	
		
			//SetEntityFlags(client, GetEntityFlags(client) & FL_ONTRAIN);
		
			if(buttons & IN_SPEED){
			
				grabangle[client][0] = 0.0;
				grabangle[client][1] = 0.0;
				grabangle[client][2] = 0.0;
			
			}else{
		
				//클라이언트의 이전 눈 각도에 대비해서 현재 각도가 얼마나 변했는지를 구해서 그것을 그랩앵글에 적용한다
				decl Float:nowangle[3];
				GetClientEyeAngles(client, nowangle);
				
				playeranglerotate[client][0] = playeranglerotate[client][0] + (preeyangle[client][0] - nowangle[0]);
				playeranglerotate[client][1] = playeranglerotate[client][1] + (preeyangle[client][1] - nowangle[1]);
				playeranglerotate[client][2] = playeranglerotate[client][2] + (preeyangle[client][2] - nowangle[2]);
				
				clampangle(playeranglerotate[client]);
				
				TeleportEntity(client, NULL_VECTOR, preeyangle[client], NULL_VECTOR);
				
			}
		
		}else{
			
			GetClientEyeAngles(client, preeyangle[client]);
		
		}
		
		//잡은 물건이 있는가? 없는가? any held object?
		if(grabbedentref[client] == -1){
		
			//잡은 물건이 애초에 없다 no helding at all
		
			if((buttons & IN_ATTACK2) && !(keybuffer[client] & IN_ATTACK2)){
		
				//물건을 잡는다 try to grab something
				if(teamcanusegravitygun(clientteam)){
	
					if((!IsClientDriving(client)) && (!IsValidEntity(car))){
				
						grab(client);
					}
					
				}
			
			}/*else if(buttons & IN_ATTACK){
			
				//물건을 쏜다 try to shoot something
				if(teamcanusegravitygun(clientteam)){
				
					emptyshoot(client);
					
				}
			
			}*/
			
		}else if(EntRefToEntIndex(grabbedentref[client]) == -1){
		
			//잡은 물건이 있었으나 현재는 사라졌다 held object has gone
			grabbedentref[client] = -1;
			//lets make some release sound of gravity gun.
			stopentitysound(client, SOUND_GRAVITYGUN_HOLD);
			playsoundfromclient(client, SOUNDTYPE_GRAVITYGUN_DROP);
		
		}else{
		
			//현재도 물건을 잡고 있다we are currently helding something now
	
			if((IsClientDriving(client)) || (IsValidEntity(car))){		
			
				Phys_EnableGravity(EntRefToEntIndex(grabbedentref[client]), true);
				SetEntPropEnt(grabbedentref[client], Prop_Send, "m_hOwnerEntity", INVALID_ENT_REFERENCE);
				grabbedentref[client] = -1;
			}		
	
			if(((buttons & IN_ATTACK2) && !(keybuffer[client] & IN_ATTACK2)) || !teamcanusegravitygun(clientteam)){
		
				//물건을 내려놓는다. try to release something
				release(client);
			
			}else if(buttons & IN_ATTACK){
			
				//물건을 쏜다. try to shot something
				shoot(client);
			
			}else{
			
				//물건을 잡은 상태를 유지한다 try to keep helding object
				hold(client);
			
			}
		
		}
		
		if(!(buttons & IN_ATTACK2)){
			
			//마우스2를 누르고 있지 않으므로 버퍼를 푼다
			keybuffer[client] = keybuffer[client] & ~IN_ATTACK2;
			
		}
		
	}else{
		
		//we must release any thing if it is on spectator`s hand
		release(client);
	
	}
	
}

grab(client){

	new targetentity, Float:distancetoentity, Float:resultpos[3];
	
	targetentity = GetClientAimEntity3(client, distancetoentity, resultpos);
	new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
	
	new MoveType:move = GetEntityMoveType(targetentity);

	if((targetentity != -1) && isgrabbableentity(targetentity) && (!IsClientDriving(client)) && (!IsValidEntity(car)) && (!IsClientConnectedIngameAlive(GetEntPropEnt(targetentity, Prop_Send, "m_hOwnerEntity"))))
	{
		decl String:ClassName[255];
		GetEdictClassname(targetentity, ClassName, 255);
		
		if ((move == MOVETYPE_NONE) && (!StrEqual(ClassName, "prop_vehicle_driveable")))
		{
			return;
		}
		if(distancetoentity <= GetConVarFloat(cvar_maxpickupdistance)){
			
			if(!clientcangrab(client)){
		
				return;
			
			}
			
			//즉각 든다


			if ((move != MOVETYPE_NONE) && (Phys_IsMotionEnabled(targetentity)))
			{
				Phys_EnableGravity(targetentity, false);
			}
			else
			{
				return;
			}
			
			
			SetEntPropEnt(targetentity, Prop_Send, "m_hOwnerEntity", client);
			grabbedentref[client] = EntIndexToEntRef(targetentity);
			
			decl Float:clienteyeangle[3], Float:entityangle[3];// Float:entityposition[3];
			GetEntPropVector(grabbedentref[client], Prop_Send, "m_angRotation", entityangle);
			GetClientEyeAngles(client, clienteyeangle);
			
			playeranglerotate[client][0] = 0.0;
			playeranglerotate[client][1] = 0.0;
			playeranglerotate[client][2] = 0.0;
			
			grabangle[client][0] = 0.0;
			grabangle[client][1] = 0.0;
			grabangle[client][2] = 0.0;
			
			grabdistance[client] = GetConVarFloat(cvar_grab_defaultdistance);
			/* GetEntPropVector(grabbedentref[client], Prop_Send, "m_vecOrigin", entityposition);
			grabpos[client][0] = entityposition[0] - resultpos[0];
			grabpos[client][1] = entityposition[1] - resultpos[1];
			grabpos[client][2] = entityposition[2] - resultpos[2]; */
			
			new matrix[matrix3x4_t];
			
			matrix3x4FromAnglesNoOrigin(clienteyeangle, matrix);
			
			decl Float:temp[3];
			
			MatrixAngles(matrix, temp);
			
			TransformAnglesToLocalSpace(entityangle, grabangle[client], matrix);
			
			keybuffer[client] = keybuffer[client] | IN_ATTACK2;
			
			playsoundfromclient(client, SOUNDTYPE_GRAVITYGUN_PICKUP);
			playentitysoundfromclient(client, SOUND_GRAVITYGUN_HOLD);
			
		}else if(distancetoentity <= GetConVarFloat(cvar_maxdragdistance)){
		
			//그냥 끌어온다
			decl Float:entityposition[3], Float:clientposition[3], Float:vector[3];
			GetEntPropVector(targetentity, Prop_Send, "m_vecOrigin", entityposition);
			GetClientEyePosition(client, clientposition);
			MakeVectorFromPoints(entityposition, clientposition, vector);
			NormalizeVector(vector, vector);
			ScaleVector(vector, GetConVarFloat(cvar_dragforce));
			
			decl Float:ZeroSpeed[3];
			ZeroVector(ZeroSpeed);
			Phys_SetVelocity(targetentity, vector, ZeroSpeed);

			new String:entity_name[32];
			GetEdictClassname(targetentity, entity_name, 255);
			if ((StrContains(entity_name, "weapon_", false)) == -1)
			{
				SetEntPropEnt(targetentity, Prop_Data, "m_hPhysicsAttacker", client);
				SetEntPropFloat(targetentity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime());
			}			
		}
	}
}

shoot(client){
	
	if(!clientcanpull(client)){
		
		return;
	
	}
	new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
	if (IsValidEntity(car))
	{
		return;
	}
	
	decl Float:clienteyeangle[3], Float:anglevector[3];
	GetClientEyeAngles(client, clienteyeangle);
	GetAngleVectors(clienteyeangle, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	ScaleVector(anglevector, GetConVarFloat(cvar_pullforce));
	

	new ent = EntRefToEntIndex(grabbedentref[client]);
	new MoveType:move = GetEntityMoveType(ent);
	if ((move != MOVETYPE_NONE) && (Phys_IsMotionEnabled(ent)))
	{
		Phys_EnableGravity(EntRefToEntIndex(grabbedentref[client]), true);
	}
	
	decl Float:ZeroSpeed[3];
	ZeroVector(ZeroSpeed);
	TeleportEntity(grabbedentref[client], NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
	Phys_SetVelocity(EntRefToEntIndex(grabbedentref[client]), anglevector, ZeroSpeed);
	SetEntPropEnt(grabbedentref[client], Prop_Send, "m_hOwnerEntity", INVALID_ENT_REFERENCE);
	
	new String:entity_name[32];
	GetEdictClassname(grabbedentref[client], entity_name, 255);
	if ((StrContains(entity_name, "weapon_", false)) == -1)
	{
		SetEntPropEnt(grabbedentref[client], Prop_Data, "m_hPhysicsAttacker", client);
		SetEntPropFloat(grabbedentref[client], Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime());
	}
	grabbedentref[client] = -1;
	
	stopentitysound(client, SOUND_GRAVITYGUN_HOLD);
	playsoundfromclient(client, SOUNDTYPE_GRAVITYGUN_PUNT);

}

/*emptyshoot(client){
	
	if(!clientcanpull(client)){
		
		return;
	
	}
	new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
	if (IsValidEntity(car))
	{
		return;
	}	
	
	new targetentity, Float:distancetoentity;
	
	targetentity = GetClientAimEntity(client, distancetoentity);
	
	if(targetentity != -1 && isgrabbableentity(targetentity) && distancetoentity <= GetConVarFloat(cvar_maxpulldistance)  && !IsClientConnectedIngameAlive(GetEntPropEnt(targetentity, Prop_Send, "m_hOwnerEntity"))){
		
		decl Float:clienteyeangle[3], Float:anglevector[3];
		GetClientEyeAngles(client, clienteyeangle);
		GetAngleVectors(clienteyeangle, anglevector, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(anglevector, anglevector);
		ScaleVector(anglevector, GetConVarFloat(cvar_pullforce));
		
		decl Float:ZeroSpeed[3];
		ZeroVector(ZeroSpeed);
		//TeleportEntity(targetentity, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
		Phys_AddVelocity(targetentity, anglevector, ZeroSpeed);

		new String:entity_name[32];
		GetEdictClassname(targetentity, entity_name, 255);
		if ((StrContains(entity_name, "weapon_", false)) == -1)
		{
			SetEntPropEnt(targetentity, Prop_Data, "m_hPhysicsAttacker", client);
			SetEntPropFloat(targetentity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime());
		}	
		playsoundfromclient(client, SOUNDTYPE_GRAVITYGUN_PUNT);
	}
}*/

release(client){
	
	if((IsValidEntity(grabbedentref[client])) && (EntRefToEntIndex(grabbedentref[client]) > 0))
	{
		new ent = EntRefToEntIndex(grabbedentref[client]);
		new MoveType:move = GetEntityMoveType(ent);
		if ((move != MOVETYPE_NONE) && (Phys_IsMotionEnabled(ent)))
		{
			Phys_EnableGravity(EntRefToEntIndex(grabbedentref[client]), true);
		}
		SetEntPropEnt(grabbedentref[client], Prop_Send, "m_hOwnerEntity", INVALID_ENT_REFERENCE);
		if(IsClientConnectedIngame(client)){
	
			playsoundfromclient(client, SOUNDTYPE_GRAVITYGUN_DROP);
			
		}
		
	}
	grabbedentref[client] = -1;
	keybuffer[client] = keybuffer[client] | IN_ATTACK2;
	
	stopentitysound(client, SOUND_GRAVITYGUN_HOLD);

}

hold(client){

	new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");	
	if((IsClientDriving(client)) || (IsValidEntity(car))){		
			
		release(client);
	}
	
	//물건을 어디로 끌어갈지 정한다
	decl Float:resultpos[3];
	GetClientAimPosition(client, grabdistance[client], resultpos, tracerayfilterrocket, client);
	
	decl Float:entityposition[3], Float:clientposition[3], Float:vector[3];
	GetEntPropVector(grabbedentref[client], Prop_Send, "m_vecOrigin", entityposition);
	GetClientEyePosition(client, clientposition);
	decl Float:clienteyeangle[3];
	GetClientEyeAngles(client, clienteyeangle);
	
	decl Float:clienteyeangleafterchange[3];
	
	clienteyeangleafterchange[0] = clienteyeangle[0] + playeranglerotate[client][0];
	clienteyeangleafterchange[1] = clienteyeangle[1] + playeranglerotate[client][1];
	clienteyeangleafterchange[2] = clienteyeangle[2] + playeranglerotate[client][2];
	
	decl playerlocalspace[matrix3x4_t], playerlocalspaceafterchange[matrix3x4_t];
	
	matrix3x4FromAnglesNoOrigin(clienteyeangle, playerlocalspace);
	matrix3x4FromAnglesNoOrigin(clienteyeangleafterchange, playerlocalspaceafterchange);
	
	decl Float:resultangle[3];
	
	TransformAnglesToWorldSpace(grabangle[client], resultangle, playerlocalspaceafterchange);
	TransformAnglesToLocalSpace(resultangle, grabangle[client], playerlocalspace);
	
	ZeroVector(playeranglerotate[client]);
	
	MakeVectorFromPoints(entityposition, resultpos, vector);
	ScaleVector(vector, GetConVarFloat(cvar_grabforcemultiply));
	
	decl Float:entityangle[3], Float:angvelocity[3];
	GetEntPropVector(grabbedentref[client], Prop_Send, "m_angRotation", entityangle);
	
	angvelocity[0] = resultangle[0] - entityangle[0];
	angvelocity[1] = resultangle[1] - entityangle[1];
	angvelocity[2] = resultangle[2] - entityangle[2];
	
	ZeroVector(angvelocity);
	TeleportEntity(grabbedentref[client], NULL_VECTOR, resultangle, NULL_VECTOR);
	
	new ent = EntRefToEntIndex(grabbedentref[client]);
	new MoveType:move = GetEntityMoveType(ent);
	if ((move != MOVETYPE_NONE) && (IsValidEdict(ent)) && (Phys_IsMotionEnabled(ent)))
	{
		Phys_SetVelocity(EntRefToEntIndex(grabbedentref[client]), vector, angvelocity, true);
	}

	if (IsValidEdict(grabbedentref[client]))
	{
		new String:entity_name[32];
		GetEdictClassname(grabbedentref[client], entity_name, 255);
		if ((StrContains(entity_name, "weapon_", false)) == -1)
		{
			SetEntPropEnt(grabbedentref[client], Prop_Data, "m_hPhysicsAttacker", client);
			SetEntPropFloat(grabbedentref[client], Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime());
		}
	}

	if (IsClientDriving(client))
	{
		release(client);
	}
}

bool:isgrabbableentity(entity){

	decl String:classname[64];
	GetEdictClassname(entity, classname, 64);
	
	if((StrContains(classname, "prop_physics", false)  != -1) || ((IsEntityChair(entity)) == 2) || (StrContains(classname, "prop_ragdoll", false)  != -1) || (StrContains(classname, "weapon_", false)  != -1)
		|| (StrContains(classname, "projectile", false)  != -1)){
	
		return true;
	
	}else{
	
		return false;
	
	}

}

bool:clientcanpull(client){

	new Float:now = GetGameTime();
	
	if(nextactivetime[client] <= now){
	
		nextactivetime[client] = now + GetConVarFloat(cvar_pull_delay);
		
		return true;
	
	}
	
	return false;

}

bool:clientcangrab(client){

	new car = GetEntPropEnt(client, Prop_Send, "m_hVehicle");	
	if((IsClientDriving(client)) || (IsValidEntity(car))){		
			
		return false;
	}

	new Float:now = GetGameTime();
	
	if(nextactivetime[client] <= now){
	
		nextactivetime[client] = now + GetConVarFloat(cvar_grab_delay);
		
		return true;
	
	}
	
	return false;

}

bool:clientisgrabbingvalidobject(client){

	if((grabbedentref[client] != -1) && (EntRefToEntIndex(grabbedentref[client]) != -1)){
		
		return true;
		
	}else{
	
		return false;
	
	}

}