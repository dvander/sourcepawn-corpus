/**
 * =============================================================================
 * ImDawe plugin
 * www.neogames.eu Plugin / Mod request section for plugin request
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 */
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <basestock>
#include <smartdm>
#include <sdkhooks>
#define VERSION "1.0"
#define EF_NODRAW 32
#define SOLID_NONE 0
#define FSOLID_NOT_SOLID 0x0004
public Plugin:myinfo =
{
	name = "[ANY] Heli",
	author = "ImDawe",
	description = "",
	version = VERSION,
	url = "http://www.neogames.eu/"
};

enum eHeli
{
	bool:Has,
	EntID,
	RearEntID,
	RotorEntID,
	CameraEntID,
	Health,
	bool:Damaged,
}

new Float:MinNadeHull[3] = {-2.5, -2.5, -2.5};
new Float:MaxNadeHull[3] = {2.5, 2.5, 2.5};
new Float:MaxWorldLength;
new Float:SpinVel[3] = {0.0, 0.0, 200.0};
new Float:SmokeOrigin[3] = {-30.0,0.0,0.0};
new Float:SmokeAngle[3] = {0.0,-180.0,0.0};
new cvDamage;
new cvMissile;
new cvRadius;
new cvSpeed;
new cvType;
new cvArc;
new cvGetInDistance;
new cvMaxHelis;
new cvRocketShootSpeed;
new cvHeliHP;
new cvHeliMaxSpeed;
new helinum=0;
new ClientHelicopters[MAXPLAYERS+1][eHeli];
new AvaliableHelicopters[128][eHeli];
public OnPluginStart()
{
	RegAdminCmd("sm_heli", Command_SpawnHeli, ADMFLAG_ROOT);
	RegConsoleCmd("sm_helienter", Command_GetInHeli);
	
	
	RegConsoleCmd("sm_hmenu", Command_HMenu);
	Precache();
	
	cvDamage			=	RegisterConVar("sm_rocket_damage", "100", "Sets the maximum amount of damage the rockets can do", TYPE_INT);
	cvMissile			=	RegisterConVar("sm_rocket_give", "3.0", "Sets the second to get rockets", TYPE_FLOAT);
	cvRadius			=	RegisterConVar("sm_rocket_radius", "350", "Sets the explosive radius of the rockets", TYPE_INT);
	cvMaxHelis			=	RegisterConVar("sm_max_heli", "12", "Sets the explosive radius of the rockets", TYPE_INT);
	cvHeliHP			=	RegisterConVar("sm_heli_hp", "1000", "Sets the explosive radius of the rockets", TYPE_INT);
	cvSpeed				=	RegisterConVar("sm_rocket_speed", "500.0", "Sets the speed of the rockets", TYPE_FLOAT);
	cvGetInDistance		=	RegisterConVar("sm_heli_getin_distance", "200.0", "Sets the speed of the rockets", TYPE_FLOAT);
	cvType				=	RegisterConVar("sm_rocket_type", "1", "Type of missile to use, 0 = dumb rockets, 1 = homing rockets, 2 = crosshair guided", TYPE_INT);
	cvArc				=	RegisterConVar("sm_rocket_arc", "1", "1 enables the turning arc of rockets, 0 makes turning instant for rockets", TYPE_INT);
	cvRocketShootSpeed	=	RegisterConVar("sm_rocket_shoot", "0.5", "Sets the second to shoot rockets", TYPE_FLOAT);
	cvHeliMaxSpeed		= 	RegisterConVar("sm_heli_speed", "700.0", "Sets the second to shoot rockets", TYPE_FLOAT);
	
	HookEvent("round_start", Event_RoundStart);

}

public OnClientPutInServer(client)
{
	ClientHelicopters[client][Has]=false;
}

public OnClientDisconnect(client)
{
	ClientHelicopters[client][Has]=false;
}

public Action:Command_HMenu(client, args)
{
	HMenu(client);
}
new Float:curration=0.0;

public HMenu(client)
{
	new Handle:Menu = CreateMenu(HHMenu);
	AddMenuItem(Menu, "0", "+X");
	AddMenuItem(Menu, "1", "-X");
	AddMenuItem(Menu, "2", "+Y");
	AddMenuItem(Menu, "3", "-Y");
	AddMenuItem(Menu, "4", "+Z");
	AddMenuItem(Menu, "5", "-Z");
	new String:asd[512];
	Format(asd, 512, "%f ration", curration);
	AddMenuItem(Menu, "6", asd);
	DisplayMenu(Menu, client, 20);
}

public HHMenu(Handle:menu, MenuAction:action, client, item)
{
	if(action == MenuAction_Select)
	{
		new Float:velo[3];
		new target = GetClientAimTarget(client, false);
		if(target != -1)
		{
			switch(item)
			{
				case 0:
				{
					velo[0]=FloatAdd(velo[0], curration);
				}
				case 1:
				{
					velo[0]=FloatSub(velo[0], curration);
				}
				case 2:
				{
					velo[1]=FloatAdd(velo[1], curration);
				}
				case 3:
				{
					velo[1]=FloatSub(velo[1], curration);
				}
				case 4:
				{
					velo[2]=FloatAdd(velo[2], curration);
				}
				case 5:
				{
					velo[2]=FloatSub(velo[2], curration);
				}
				case 6:
				{
					if(curration>100.0)
						curration=-10.0;
					curration=FloatAdd(curration, 10.0);
				}
			}
			TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, velo);
		}
		 HMenu(client);
	}
	if(action == action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	helinum=0;
	LoopIngamePlayers(i)
	{
		ClientHelicopters[i][EntID]=0;
		ClientHelicopters[i][Has]=false;
	}
	return Plugin_Continue;
}

public TameRotate(entity, Float:Angle[3], Float:tamerate)
{
	new Float:EntAngles[3];
	GetEntPropVector(entity, Prop_Send, "m_angRotation", EntAngles);
	if(Angle[0] > EntAngles[0])
	{
		EntAngles[0]=FloatAdd(EntAngles[0], tamerate);
	}else{
		EntAngles[0]=FloatSub(EntAngles[0], tamerate);
	}
	EntAngles[1]=Angle[1];
	/*if(Angle[1] > EntAngles[1])
	{
		EntAngles[1]=FloatAdd(EntAngles[1],tamerate);
	}else{
		EntAngles[1]=FloatSub(EntAngles[1], tamerate);
	}*/
	if(Angle[2] > EntAngles[2])
	{
		EntAngles[2]=FloatAdd(EntAngles[2], tamerate);
	}else{
		EntAngles[2]=FloatSub(EntAngles[2], tamerate);
	}
	TeleportEntity(entity, NULL_VECTOR, EntAngles, NULL_VECTOR);
}

public Action:Command_GetInHeli(client, args)
{
	if(ClientHelicopters[client][Has])
	{
		new Float:pos[3];
		new Float:ang[3];
		new Float:fForward[3];
		new Float:fRight[3];
		new Float:fUp[3];
		new Float:fOffset[3];
		GetEntPropVector(ClientHelicopters[client][EntID], Prop_Send, "m_vecOrigin", pos);
		GetEntPropVector(ClientHelicopters[client][EntID], Prop_Send, "m_angRotation", ang);
		GetAngleVectors(ang, fForward, fRight, fUp);
		fOffset[0] = 100.0*(GetRandomInt(0,1)==1?1:-1);
		fOffset[1] = 200.0;
		fOffset[2] = 1.0;
		pos[0] += fRight[0]*fOffset[0]+fForward[0]*fOffset[1]+fUp[0]*fOffset[2];
		pos[1] += fRight[1]*fOffset[0]+fForward[1]*fOffset[1]+fUp[1]*fOffset[2];
		pos[2] += fRight[2]*fOffset[0]+fForward[2]*fOffset[1]+fUp[2]*fOffset[2];
		ang[1]=0.0;
		TeleportEntity(ClientHelicopters[client][EntID], NULL_VECTOR, ang, NULL_VECTOR);
		TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
		ClientHelicopters[client][Has]=false;
	}else{
		
		new target = GetClientAimTarget(client, false);
		if(target != -1)
		{
			for(new i=0;i<helinum;++i)
			{
				if(AvaliableHelicopters[i][EntID]==target || AvaliableHelicopters[i][RearEntID]==target || AvaliableHelicopters[i][RotorEntID]==target)
				{
					new Float:PlayerPos[3];
					new Float:HeliPos[3];
					GetClientAbsOrigin(client, PlayerPos);
					GetEntPropVector(AvaliableHelicopters[i][EntID], Prop_Send, "m_vecOrigin", HeliPos);
					new Float:distance = GetVectorDistance(PlayerPos, HeliPos);
					PrintToChat(client, "%f>%f", g_eCvars[cvGetInDistance][aCache], distance);
					if(g_eCvars[cvGetInDistance][aCache] > distance)
					{
						PrintToChat(client, "You are far away");
						return false;
					}
					ClientHelicopters[client][EntID]=AvaliableHelicopters[i][EntID];
					ClientHelicopters[client][RearEntID]=AvaliableHelicopters[i][RearEntID];
					ClientHelicopters[client][RotorEntID]=AvaliableHelicopters[i][RotorEntID];
					ClientHelicopters[client][Has]=true;
					SetEntityHealth(client, AvaliableHelicopters[i][Health]);
					return true;
				}
			}
			
		}
	}
}

public OnMapStart()
{
	Precache();
}

public Precache()
{
	Downloader_AddFileToDownloadsTable("models/sentry/apache.mdl");
	Downloader_AddFileToDownloadsTable("models/sentry/apacherear.mdl");
	Downloader_AddFileToDownloadsTable("models/sentry/apachemain.mdl");
	Downloader_AddFileToDownloadsTable("models/weapons/w_missile_closed.mdl");
	AddFileToDownloadsTable("sound/ah64d/ah64d_cannon.wav");
	AddFileToDownloadsTable("sound/ah64d/fire_alarm.wav");
	PrecacheModel("models/sentry/apache.mdl");
	PrecacheModel("models/sentry/apacherear.mdl");
	PrecacheModel("models/sentry/apachemain.mdl");
	PrecacheModel("models/weapons/w_missile_closed.mdl");
	PrecacheSound("weapons/hegrenade/explode3.wav");
	PrecacheSound("weapons/hegrenade/explode4.wav");
	PrecacheSound("weapons/hegrenade/explode5.wav");
	PrecacheSound("ah64d/fire_alarm.wav");
	PrecacheSound("ah64d/ah64d_cannon.wav");
}

public Action:Command_SpawnHeli(client, args)
{
	CreateHeli(client);
}
public CreateHeli(client)
{
	if(g_eCvars[cvMaxHelis][aCache]>helinum)
	{
		PrecacheModel("models/sentry/apache.mdl");
		PrecacheModel("models/sentry/apacherear.mdl");
		PrecacheModel("models/sentry/apachemain.mdl");
		new Float:origin[3];
		new Float:vecDir[3];
		new Float:angle[3];
		new Float:rearpos[3];
		new Float:rotorpos[3];

		GetClientEyeAngles(client, angle);
		GetAngleVectors(angle, vecDir, NULL_VECTOR, NULL_VECTOR);
		GetClientEyePosition(client, origin); 
		AvaliableHelicopters[helinum][EntID] = CreateEntityByName("prop_physics_override");
		origin[0]+=vecDir[0]*600.0;
		origin[1]+=vecDir[1]*600.0;
		TeleportEntity(AvaliableHelicopters[helinum][EntID], origin, NULL_VECTOR, NULL_VECTOR);
	
		AvaliableHelicopters[helinum][RearEntID] = CreateEntityByName("prop_physics_override");
		rearpos[0]=FloatSub(origin[0], 332.5);
		rearpos[1]=FloatSub(origin[1], 17.0);
		rearpos[2]=FloatAdd(origin[2], 93.5);
		TeleportEntity(AvaliableHelicopters[helinum][RearEntID], rearpos, NULL_VECTOR, NULL_VECTOR);
		
		AvaliableHelicopters[helinum][RotorEntID] = CreateEntityByName("prop_physics_override");
		rotorpos[0]=FloatAdd(origin[0], 37.0);
		rotorpos[1]=FloatAdd(origin[1], 0.0);
		rotorpos[2]=FloatAdd(origin[2], 100.0);
		TeleportEntity(AvaliableHelicopters[helinum][RotorEntID], rotorpos, NULL_VECTOR, NULL_VECTOR);
		

		SetEntityModel(AvaliableHelicopters[helinum][EntID], "models/sentry/apache.mdl");
		SetEntityModel(AvaliableHelicopters[helinum][RearEntID], "models/sentry/apacherear.mdl");
		SetEntityModel(AvaliableHelicopters[helinum][RotorEntID], "models/sentry/apachemain.mdl");
		
		//DispatchKeyValue(AvaliableHelicopters[client][EntID], "spawnflags", "256"); // +USE output dont work, fuck OFF!:@
		// Set rear
		SetVariantString("!activator");
		AcceptEntityInput(AvaliableHelicopters[helinum][RearEntID], "SetParent", AvaliableHelicopters[helinum][EntID]);
		
		// set rotor
		SetVariantString("!activator");
		AcceptEntityInput(AvaliableHelicopters[helinum][RotorEntID], "SetParent", AvaliableHelicopters[helinum][EntID]);

		// Spawn props
		DispatchSpawn(AvaliableHelicopters[helinum][EntID]);
		DispatchSpawn(AvaliableHelicopters[helinum][RearEntID]);
		DispatchSpawn(AvaliableHelicopters[helinum][RotorEntID]);
		AvaliableHelicopters[helinum][Health]=g_eCvars[cvHeliHP][aCache];	
		//AcceptEntityInput(AvaliableHelicopters[client][RearEntID], "Start");
		// copy to global world
		AvaliableHelicopters[helinum][Damaged]=false;
		SDKHook(AvaliableHelicopters[helinum][EntID], SDKHook_OnTakeDamage, OnTakeDamage);
		++helinum;
		PrintToChat(client, "Helicopter spawned %d/%d", helinum, g_eCvars[cvMaxHelis][aCache]);

		return true;
	}else{
		PrintToChat(client, "Sorry, helicopter limit is reached %d/%d", helinum, g_eCvars[cvMaxHelis][aCache]);
	}
	return false;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    if(IsValidClient(attacker))
	{
		for(new i=0;i<helinum;++i)
		{
			if(AvaliableHelicopters[i][EntID]==victim && attacker != i)
			{
				//PrintToChatAll("%d", inflictor);
				DamageHeli(i, damage);
				return Plugin_Handled;
			}
		}
	}
}  

public MoveRotor(index)
{
	new Float:angles[3];
	GetEntPropVector(ClientHelicopters[index][RotorEntID], Prop_Send, "m_angRotation", angles);
	angles[1]=FloatAdd(angles[1], 25.5);
	TeleportEntity(ClientHelicopters[index][RotorEntID], NULL_VECTOR, angles, NULL_VECTOR);
}

public MoveRear(index)
{
	new Float:angles[3];
	GetEntPropVector(ClientHelicopters[index][RearEntID], Prop_Send, "m_angRotation", angles);
	angles[0]=FloatAdd(angles[0], 25.5);
	TeleportEntity(ClientHelicopters[index][RearEntID], NULL_VECTOR, angles, NULL_VECTOR);
}
new bool:CanTheRocketShoot[MAXPLAYERS+1]={true,...};
public OnGameFrame()
{
	LoopIngamePlayers(i)
	{
		if(ClientHelicopters[i][EntID]>0 && ClientHelicopters[i][Has])
		{
			for(new d=0;d<helinum;++d)
			{	
				if(AvaliableHelicopters[d][EntID]==ClientHelicopters[i][EntID])
				{
					if(AvaliableHelicopters[d][Damaged])
						CreateTimer(0.8, Timer_PlayAlarm, i);
				}
			}
			MoveRear(i);
			MoveRotor(i);
			new Float:position[3];
			new Float:oldposition[3];
			new Float:velocit[3];
			new Float:velocity[3];
			new Float:angles[3];
			new Float:EntAngles[3];
			new Float:VecFor[3];
			new Float:VecUp[3];
			GetClientEyeAngles(i, angles);
			//PrintToChat(i, "angles[0]:%f", angles[0]);
			GetEntPropVector(ClientHelicopters[i][EntID], Prop_Send, "m_vecOrigin", position);
			GetEntPropVector(ClientHelicopters[i][EntID], Prop_Send, "m_angRotation", EntAngles);
			GetEntPropVector(ClientHelicopters[i][EntID], Prop_Data, "m_vecVelocity", velocity); 
			GetAngleVectors(EntAngles, VecFor, NULL_VECTOR, NULL_VECTOR);
			//ScaleVector(VecFor, -600.0);
			//PrintToChat(i, "position[%f]", position[0]);
			//AddVectors(position, VecUp, position);
			position[0]+=VecFor[0]*-600.0;
			position[1]+=VecFor[1]*-600.0;
			position[2]=FloatAdd(position[2], 350.0);
			//VecFor[2]=250.0;
			GetClientAbsOrigin(i, oldposition);
			new Float:distance = GetVectorDistance(position, oldposition);
			//PrintToChat(i, "%f:", distance);
			MakeVectorFromPoints(oldposition, position, position);
			NormalizeVector(position, position);
			ScaleVector(position, (distance*3.0));
			//position[2]=0.0;
			TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, position);
			new buttons = GetClientButtons(i);
			//velocit[2]=50.0;
			//PrintToChat(i, "angles[%f], angles[%f], angles[%f]", angles[0], angles[1], angles[2]);
			if(angles[0]<-45.0)
			{
				angles[0]=-45.0;
			}
			if(angles[0]>45.0)
			{
				angles[0]=45.0;
			}
			if(angles[2]<-30.0)
			{
				angles[2]=-30.0;
				TeleportEntity(ClientHelicopters[i][EntID], NULL_VECTOR, angles, NULL_VECTOR);
			}
			if(angles[2]>30.0)
			{
				angles[2]=30.0;
				TeleportEntity(ClientHelicopters[i][EntID], NULL_VECTOR, angles, NULL_VECTOR);
			}
			if(buttons & IN_MOVELEFT)
			{
				EntAngles[1]=FloatAdd(EntAngles[1], 90.0);
				GetAngleVectors(EntAngles, VecFor, NULL_VECTOR, NULL_VECTOR);
				angles[2]=-30.0;
				velocit[0]=VecFor[0];
				velocit[1]=VecFor[1];
				ScaleVector(velocit, g_eCvars[cvHeliMaxSpeed][aCache]);
			}
			if(buttons & IN_MOVERIGHT)
			{
				EntAngles[1]=FloatSub(EntAngles[1], 90.0);
				GetAngleVectors(EntAngles, VecFor, NULL_VECTOR, NULL_VECTOR);
				velocit[0]=VecFor[0];
				velocit[1]=VecFor[1];
				angles[2]=30.0;
				ScaleVector(velocit, g_eCvars[cvHeliMaxSpeed][aCache]);
			}
			if(buttons & IN_FORWARD)
			{
				if(buttons & IN_MOVERIGHT)
					EntAngles[1]=FloatAdd(EntAngles[1], 45.0);
				if(buttons & IN_MOVELEFT)
					EntAngles[1]=FloatSub(EntAngles[1], 45.0);
				GetAngleVectors(EntAngles, VecFor, NULL_VECTOR, NULL_VECTOR);
				velocit[0]=VecFor[0];
				velocit[1]=VecFor[1];
				PrintToChat(i, "%f", angles[0]);
				if(angles[0]<30.0)
					angles[0]=30.0;
				ScaleVector(velocit, g_eCvars[cvHeliMaxSpeed][aCache]);
			}
			if(buttons & IN_BACK)
			{
				GetAngleVectors(EntAngles, VecFor, NULL_VECTOR, NULL_VECTOR);
				velocit[0]=VecFor[0];
				velocit[1]=VecFor[1];
				if(angles[0]>-10.0)
					angles[0]=-10.0;
				ScaleVector(velocit, g_eCvars[cvHeliMaxSpeed][aCache]*-1);
			}
			if(buttons & IN_JUMP)
			{
				if(velocity[2]<0.0)
					velocity[2]=FloatAdd(velocity[2], 10.0);
				if(velocity[2]<400.0)
					velocity[2]=FloatAdd(velocity[2], 5.0);
				velocit[2]=velocity[2];
			}else
			if(buttons & IN_DUCK)
			{
				if(velocity[2]>-400.0)
					velocity[2]=FloatSub(velocity[2], 5.0);
				velocit[2]=velocity[2];
			}else{
				if(velocity[2]>0.0)
					velocity[2]=FloatSub(velocity[2], 5.0);
				else
					velocity[2]=FloatAdd(velocity[2], 5.0);
				velocit[2]=velocity[2];
			}
			
			if(buttons & IN_ATTACK)
			{
				if(CanTheRocketShoot[i])
				{
						CanTheRocketShoot[i]=false;
						CreateTimer(g_eCvars[cvSpeed][cvRocketShootSpeed], RocketShootTimer, i);
						RocketShoot(i);
				}
			}
			
			TameRotate(ClientHelicopters[i][EntID], angles, 0.5);
			TeleportEntity(ClientHelicopters[i][EntID], NULL_VECTOR, NULL_VECTOR, velocit);
		}
	}
}

public Action:RocketShootTimer(Handle:timer, any:data)
{
		CanTheRocketShoot[data]=true;
}
 
public RocketShoot(client)
{
	decl Float:pos[3];
	decl Float:ang[3];
	new Float:fForward[3];
	new Float:fRight[3];
	new Float:fUp[3];
	new ent = CreateEntityByName("hegrenade_projectile");
	if(ent != -1)
	{
		SetEntPropEnt(ent, Prop_Send, "m_hThrower", client);
		GetEntPropVector(ClientHelicopters[client][EntID], Prop_Send, "m_vecOrigin", pos);
		GetEntPropVector(ClientHelicopters[client][EntID], Prop_Send, "m_angRotation", ang);

		new Float:fOffset[3];
		fOffset[0] = 70.0*(GetRandomInt(0,1)==1?1:-1);
		fOffset[1] = 250.0;
		fOffset[2] = -40.0;

		GetAngleVectors(ang, fForward, fRight, fUp);

		pos[0] += fRight[0]*fOffset[0]+fForward[0]*fOffset[1]+fUp[0]*fOffset[2];
		pos[1] += fRight[1]*fOffset[0]+fForward[1]*fOffset[1]+fUp[1]*fOffset[2];
		pos[2] += fRight[2]*fOffset[0]+fForward[2]*fOffset[1]+fUp[2]*fOffset[2];
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent);
		EmitSoundToAll("ah64d/ah64d_cannon.wav", ent, 1, 90);
	}
}

public OnEntityCreated(entity, const String:classname[])
{
		if (StrEqual(classname, "hegrenade_projectile", false))
		{
		
			   
		HookSingleEntityOutput(entity, "OnUser2", InitMissile, true);
	   
		new String:OutputString[50] = "OnUser1 !self:FireUser2::0.0:1";
		SetVariantString(OutputString);
		AcceptEntityInput(entity, "AddOutput");
	   
		AcceptEntityInput(entity, "FireUser1");
		}
 
}
 
 
 
public InitMissile(const String:output[], caller, activator, Float:delay)
{
		new NadeOwner = GetEntPropEnt(caller, Prop_Send, "m_hThrower");

		// assume other plugins don't set this on any projectiles they create, this avoids conflicts.
		if (NadeOwner == -1)
		{
				return;
		}
	   
	   
	   
		// stop the projectile thinking so it doesn't detonate.
		SetEntProp(caller, Prop_Data, "m_nNextThinkTick", -1);
		SetEntityMoveType(caller, MOVETYPE_FLY);
		SetEntityModel(caller, "models/weapons/w_missile_closed.mdl");
		// make it spin correctly.
		SetEntPropVector(caller, Prop_Data, "m_vecAngVelocity", SpinVel);
		// stop it bouncing when it hits something
		SetEntPropFloat(caller, Prop_Send, "m_flElasticity", 0.0);
		SetEntPropVector(caller, Prop_Send, "m_vecMins", MinNadeHull);
		SetEntPropVector(caller, Prop_Send, "m_vecMaxs", MaxNadeHull);
		new NadeTeam = GetEntProp(caller, Prop_Send, "m_iTeamNum");
		switch (NadeTeam)
		{
				case 2:
				{
						SetEntityRenderColor(caller, 255, 0, 0, 255);
				}
				case 3:
				{
						SetEntityRenderColor(caller, 0, 0, 255, 255);
				}
		}
	   
		new SmokeIndex = CreateEntityByName("env_rockettrail");
		if (SmokeIndex != -1)
		{
			SetEntPropFloat(SmokeIndex, Prop_Send, "m_Opacity", 0.5);
			SetEntPropFloat(SmokeIndex, Prop_Send, "m_SpawnRate", 100.0);
			SetEntPropFloat(SmokeIndex, Prop_Send, "m_ParticleLifetime", 0.5);
			new Float:SmokeRed[3] = {0.5, 0.25, 0.25};
			new Float:SmokeBlue[3] = {0.25, 0.25, 0.5};
			switch (NadeTeam)
			{
					case 2:
					{
							SetEntPropVector(SmokeIndex, Prop_Send, "m_StartColor", SmokeRed);
					}
					case 3:
					{
							SetEntPropVector(SmokeIndex, Prop_Send, "m_StartColor", SmokeBlue);
					}
			}
			SetEntPropFloat(SmokeIndex, Prop_Send, "m_StartSize", 1.0);
			SetEntPropFloat(SmokeIndex, Prop_Send, "m_EndSize", 10.0);
			SetEntPropFloat(SmokeIndex, Prop_Send, "m_SpawnRadius", 0.0);
			SetEntPropFloat(SmokeIndex, Prop_Send, "m_MinSpeed", 0.0);
			SetEntPropFloat(SmokeIndex, Prop_Send, "m_MaxSpeed", 2.0);
			SetEntPropFloat(SmokeIndex, Prop_Send, "m_flFlareScale", 2.0);
		   
			DispatchSpawn(SmokeIndex);
			ActivateEntity(SmokeIndex);
		   
			new String:NadeName[20];
			Format(NadeName, sizeof(NadeName), "Nade_%i", caller);
			DispatchKeyValue(caller, "targetname", NadeName);
			SetVariantString(NadeName);
			AcceptEntityInput(SmokeIndex, "SetParent");
			TeleportEntity(SmokeIndex, SmokeOrigin, SmokeAngle, NULL_VECTOR);
		}
	   
		// make the missile go towards the coordinates the player is looking at.
		new Float:NadePos[3];
		GetEntPropVector(caller, Prop_Send, "m_vecOrigin", NadePos);
		new Float:OwnerAng[3];
		GetEntPropVector(ClientHelicopters[NadeOwner][EntID], Prop_Send, "m_angRotation", OwnerAng);
		//GetClientEyeAngles(NadeOwner, OwnerAng);
		//new Float:OwnerPos[3];
		//GetClientEyePosition(NadeOwner, OwnerPos);
		TR_TraceRayFilter(NadePos, OwnerAng, MASK_SOLID, RayType_Infinite, DontHitOwnerOrNade, caller);
		new Float:InitialPos[3];
		TR_GetEndPosition(InitialPos);
		new Float:InitialVec[3];
		MakeVectorFromPoints(NadePos, InitialPos, InitialVec);
		NormalizeVector(InitialVec, InitialVec);
		ScaleVector(InitialVec, g_eCvars[cvSpeed][aCache]);
		new Float:InitialAng[3];
		GetVectorAngles(InitialVec, InitialAng);
		TeleportEntity(caller, NULL_VECTOR, InitialAng, InitialVec);
	   
		EmitSoundToAll("ah64d/ah64d_cannon.wav", caller, 1, 90);
	   
		HookSingleEntityOutput(caller, "OnUser2", MissileThink);
	   
		new String:OutputString[50] = "OnUser1 !self:FireUser2::0.1:-1";
		SetVariantString(OutputString);
		AcceptEntityInput(caller, "AddOutput");
	   
		AcceptEntityInput(caller, "FireUser1");
	   
		SDKHook(caller, SDKHook_StartTouchPost, OnStartTouchPost);
}
 
public MissileThink(const String:output[], caller, activator, Float:delay)
{
		// detonate any missiles that stopped for any reason but didn't detonate.
		decl Float:CheckVec[3];
		GetEntPropVector(caller, Prop_Send, "m_vecVelocity", CheckVec);
		if ((CheckVec[0] == 0.0) && (CheckVec[1] == 0.0) && (CheckVec[2] == 0.0))
		{
				StopSound(caller, 1, "ah64d/ah64d_cannon.wav");
				CreateExplosion(caller);
				return;
		}
	   
		decl Float:NadePos[3];
		GetEntPropVector(caller, Prop_Send, "m_vecOrigin", NadePos);
	   
		new NadeTeam = GetEntProp(caller, Prop_Send, "m_iTeamNum");
		if (g_eCvars[cvType][aCache] > 0)
		{
				new Float:ClosestDistance = MaxWorldLength;
				decl Float:TargetVec[3];
			   
				// find closest enemy in line of sight.
				if (g_eCvars[cvType][aCache] == 1)
				{
					   
						new ClosestEnemy;
						new Float:EnemyDistance;
						for (new i = 1; i <= MaxClients; i++)
						{
								if (IsClientInGame(i) && IsPlayerAlive(i) && (GetClientTeam(i) != NadeTeam))
								{
										decl Float:EnemyPos[3];
										GetClientEyePosition(i, EnemyPos);
										TR_TraceHullFilter(NadePos, EnemyPos, MinNadeHull, MaxNadeHull, MASK_SOLID, DontHitOwnerOrNade, caller);
										if (TR_GetEntityIndex() == i)
										{
												EnemyDistance = GetVectorDistance(NadePos, EnemyPos);
												if (EnemyDistance < ClosestDistance)
												{
														ClosestEnemy = i;
														ClosestDistance = EnemyDistance;
												}
										}
								}
						}
						// no target found, continue along current trajectory.
						if (!ClosestEnemy)
						{
								AcceptEntityInput(caller, "FireUser1");
								return;
						}
						else
						{
								decl Float:EnemyPos[3];
								GetClientEyePosition(ClosestEnemy, EnemyPos);
								MakeVectorFromPoints(NadePos, EnemyPos, TargetVec);
						}
				}
			   
				// make the missile go towards the coordinates the player is looking at.
				else if (g_eCvars[cvType][aCache] == 2)
				{
					   
						new NadeOwner = GetEntPropEnt(caller, Prop_Send, "m_hThrower");
						decl Float:OwnerAng[3];
						GetEntPropVector(ClientHelicopters[NadeOwner][EntID], Prop_Send, "m_angRotation", OwnerAng);
						decl Float:OwnerPos[3];
						GetClientEyePosition(NadeOwner, OwnerPos);
						TR_TraceRayFilter(OwnerPos, OwnerAng, MASK_SOLID, RayType_Infinite, DontHitOwnerOrNade, caller);
						decl Float:TargetPos[3];
						TR_GetEndPosition(TargetPos);
						ClosestDistance = GetVectorDistance(NadePos, TargetPos);
						MakeVectorFromPoints(NadePos, TargetPos, TargetVec);
				}
			   
				decl Float:CurrentVec[3];
				GetEntPropVector(caller, Prop_Send, "m_vecVelocity", CurrentVec);
				decl Float:FinalVec[3];
				if (g_eCvars[cvArc][aCache] && (ClosestDistance > 100.0))
				{
						NormalizeVector(TargetVec, TargetVec);
						NormalizeVector(CurrentVec, CurrentVec);
						ScaleVector(TargetVec, (g_eCvars[cvSpeed][aCache]/1000.0));
						AddVectors(TargetVec, CurrentVec, FinalVec);
				}
				// ignore turning arc if the missile is close to the enemy to avoid it circling them.
				else
				{
						FinalVec = TargetVec;
				}
			   
				NormalizeVector(FinalVec, FinalVec);
				ScaleVector(FinalVec, g_eCvars[cvSpeed][aCache]);
				decl Float:FinalAng[3];
				GetVectorAngles(FinalVec, FinalAng);
				TeleportEntity(caller, NULL_VECTOR, FinalAng, FinalVec);
		}
	   
		AcceptEntityInput(caller, "FireUser1");
}
 
public bool:DontHitOwnerOrNade(entity, contentsMask, any:data)
{
		new NadeOwner = GetEntPropEnt(data, Prop_Send, "m_hThrower");
		if(entity > 0 && entity < MaxClients && IsClientInGame(entity) && GetClientTeam(NadeOwner) != GetClientTeam(entity))
			return true;
		return ((entity != data) && (entity != NadeOwner));
}
 
public OnStartTouchPost(entity, other)
{
	// Extra detonate if the missile hits a vehicle
	new String:Classname[256];
	GetEntityClassname(other, Classname, 256);
	if(StrEqual(Classname, "prop_vehicle") || StrEqual(Classname, "prop_vehicle_driveable"))
	{
		CreateExplosion(entity);
		StopSound(entity, 1, "ah64d/ah64d_cannon.wav");
		UnhookSingleEntityOutput(entity, "OnUser2", MissileThink);
		return;
	}
	if(StrEqual(Classname, "prop_physics"))
	{
		CreateExplosion(entity);
		StopSound(entity, 1, "ah64d/ah64d_cannon.wav");
		return;
	}
	// detonate if the missile hits something solid.
	if (other > 0 && (GetEntProp(other, Prop_Data, "m_nSolidType") != SOLID_NONE) && (!(GetEntProp(other, Prop_Data, "m_usSolidFlags") & FSOLID_NOT_SOLID)))
	{
		StopSound(entity, 1, "ah64d/ah64d_cannon.wav");
		CreateExplosion(entity);
	}
}


CreateExplosion(entity)
{
		UnhookSingleEntityOutput(entity, "OnUser2", MissileThink);
		new Float:MissilePos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", MissilePos);
		new MissileOwner = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
		new MissileOwnerTeam = GetEntProp(entity, Prop_Send, "m_iTeamNum");
		new NadeTeam = GetEntProp(MissileOwner, Prop_Send, "m_iTeamNum");
		new ExplosionIndex = CreateEntityByName("env_explosion");
		if (ExplosionIndex != -1)
		{
				DispatchKeyValue(ExplosionIndex,"classname","hegrenade_projectile");
			   
				SetEntProp(ExplosionIndex, Prop_Data, "m_spawnflags", 6146);
				SetEntProp(ExplosionIndex, Prop_Data, "m_iMagnitude", g_eCvars[cvDamage][aCache]);
				SetEntProp(ExplosionIndex, Prop_Data, "m_iRadiusOverride", g_eCvars[cvRadius][aCache]);
			   
				DispatchSpawn(ExplosionIndex);
				ActivateEntity(ExplosionIndex);
				TeleportEntity(ExplosionIndex, MissilePos, NULL_VECTOR, NULL_VECTOR);
				SetEntPropEnt(ExplosionIndex, Prop_Send, "m_hOwnerEntity", MissileOwner);
				SetEntProp(ExplosionIndex, Prop_Send, "m_iTeamNum", MissileOwnerTeam);
				decl String:wavstr[256];
				Format(wavstr, 256, "weapons/hegrenade/explode%d.wav", GetRandomInt(3,5));
				EmitSoundToAll(wavstr, ExplosionIndex, 1, 90);
			   
				AcceptEntityInput(ExplosionIndex, "Explode");

			   
			   
				DispatchKeyValue(ExplosionIndex,"classname","env_explosion");
			   
				AcceptEntityInput(ExplosionIndex, "Kill");
		}
		AcceptEntityInput(entity, "Kill");
 
}

public DestroyEffect(Float:pos[3])
{
	new ExplosionIndex = CreateEntityByName("env_explosion");
	if (ExplosionIndex != -1)
	{
			DispatchKeyValue(ExplosionIndex,"classname","hegrenade_projectile");
		   
			SetEntProp(ExplosionIndex, Prop_Data, "m_spawnflags", 6146);
			SetEntProp(ExplosionIndex, Prop_Data, "m_iMagnitude", g_eCvars[cvDamage][aCache]);
			SetEntProp(ExplosionIndex, Prop_Data, "m_iRadiusOverride", g_eCvars[cvRadius][aCache]);
		   
			DispatchSpawn(ExplosionIndex);
			ActivateEntity(ExplosionIndex);
			TeleportEntity(ExplosionIndex, pos, NULL_VECTOR, NULL_VECTOR);
			decl String:wavstr[256];
			Format(wavstr, 256, "weapons/hegrenade/explode%d.wav", GetRandomInt(3,5));
			EmitSoundToAll(wavstr, ExplosionIndex, 1, 90);
		   
			AcceptEntityInput(ExplosionIndex, "Explode");

		   
		   
			DispatchKeyValue(ExplosionIndex,"classname","env_explosion");
		   
			AcceptEntityInput(ExplosionIndex, "Kill");
	}
}
public Action:Timer_DestoryHeli(Handle:Timer, any:ent)
{
	if(IsValidEntity(ent))
	{
		AcceptEntityInput(ent, "Kill");
	}
}
public Action:Timer_DestroyEffect(Handle:Timer, any:ent)
{
	if(IsValidEntity(ent))
	{
		new Float:pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[0]=(GetRandomInt(0,1)==1?FloatAdd(pos[0],GetRandomFloat(10.0, 100.0)):FloatSub(pos[0], GetRandomFloat(10.0, 100.0)));
		pos[1]=(GetRandomInt(0,1)==1?FloatAdd(pos[1],GetRandomFloat(10.0, 100.0)):FloatSub(pos[1], GetRandomFloat(10.0, 100.0)));
		pos[2]=(GetRandomInt(0,1)==1?FloatAdd(pos[2],GetRandomFloat(10.0, 100.0)):FloatSub(pos[2], GetRandomFloat(10.0, 100.0)));
		DestroyEffect(pos);
	}
}

public Action:Timer_PlayAlarm(Handle:Timer, any:client)
{
	EmitSoundToClient(client, "ah64d/fire_alarm.wav");
}

public DamageHeli(index, Float:damage)
{
	//CreateTimer(0.4,Timer_HintOwner,_,TIMER_REPEAT);
	//PrintToChatAll("%f, %d", damage, index);
	AvaliableHelicopters[index][Damaged]=true;
	CreateTimer(10.0, Timer_RemoveAlarm, index);
	AvaliableHelicopters[index][Health]=AvaliableHelicopters[index][Health]-RoundToZero(damage);
	new SmokeIndex  = CreateEntityByName("env_rockettrail");
	new Float:pos[3];
	GetEntPropVector(AvaliableHelicopters[index][EntID], Prop_Send, "m_vecOrigin", pos);
	pos[0]=(GetRandomInt(0,1)==1?FloatAdd(pos[0],GetRandomFloat(10.0, 50.0)):FloatSub(pos[0], GetRandomFloat(10.0, 50.0)));
	pos[1]=(GetRandomInt(0,1)==1?FloatAdd(pos[1],GetRandomFloat(10.0, 50.0)):FloatSub(pos[1], GetRandomFloat(10.0, 50.0)));
	pos[2]=FloatAdd(pos[2],GetRandomFloat(10.0, 100.0));
	TeleportEntity(SmokeIndex, pos, NULL_VECTOR, NULL_VECTOR);
	SetEntPropFloat(SmokeIndex, Prop_Send, "m_Opacity", 0.5);
	SetEntPropFloat(SmokeIndex, Prop_Send, "m_SpawnRate", 100.0);
	SetEntPropFloat(SmokeIndex, Prop_Send, "m_ParticleLifetime", 1.5);
	new Float:m_StartColor[3] = {0.15, 0.15, 0.15};
	SetEntPropVector(SmokeIndex, Prop_Send, "m_StartColor", m_StartColor);
	SetEntPropFloat(SmokeIndex, Prop_Send, "m_StartSize", 10.0);
	SetEntPropFloat(SmokeIndex, Prop_Send, "m_EndSize", 30.0);
	SetEntPropFloat(SmokeIndex, Prop_Send, "m_SpawnRadius", 0.0);
	SetEntPropFloat(SmokeIndex, Prop_Send, "m_MinSpeed", 0.0);
	SetEntPropFloat(SmokeIndex, Prop_Send, "m_MaxSpeed", 2.0);
	SetVariantString("!activator");
	AcceptEntityInput(SmokeIndex, "SetParent", AvaliableHelicopters[index][EntID]);
	DispatchSpawn(SmokeIndex);
	CreateTimer(10.0, Timer_RemoveTrail, SmokeIndex);
	for(new i=0;i<MaxClients;++i)
	{
		if(ClientHelicopters[i][EntID]==AvaliableHelicopters[index][EntID])
		{
			SetEntityHealth(i, AvaliableHelicopters[index][Health]);
			KeyHintText(i, "Helicopter %dHP", AvaliableHelicopters[index][Health]);
			break;
		}
	}
	if(AvaliableHelicopters[index][Health]<0.0)
		DestroyHeli(index);
}

public Action:Timer_RemoveTrail(Handle:Timer, any:data)
{
	if(IsValidEntity(data))
		AcceptEntityInput(data, "Kill");

}
public Action:Timer_RemoveAlarm(Handle:Timer, any:index)
{
	if(IsValidEntity(AvaliableHelicopters[index][EntID]))
		AvaliableHelicopters[index][Damaged]=false;
}

DestroyHeli(index)
{
	new Float:velo[3];
	velo[2]=-100.0;
	TeleportEntity(AvaliableHelicopters[index][EntID], NULL_VECTOR, NULL_VECTOR, velo);
	for(new i=0;i<10;++i)
		CreateTimer(GetRandomFloat(0.5,6.0), Timer_DestroyEffect, AvaliableHelicopters[index][EntID]);
	CreateTimer(10.0, Timer_DestoryHeli, AvaliableHelicopters[index][EntID]);
	LoopIngamePlayers(i)
	{
		if(ClientHelicopters[i][EntID]==AvaliableHelicopters[index][EntID])
		{
			ClientHelicopters[i][EntID]=0;
			ClientHelicopters[i][Has]=false;
			ForcePlayerSuicide(i);
		}
	}
	AvaliableHelicopters[index][EntID]=0;
	PrintToChatAll("Heli destroyed! INDEX[%d]", index);
}

stock bool:KeyHintText(client,String:format[],any:...)
{
	new Handle:hBuffer;
	decl String:buffer[1000];
	if((hBuffer = StartMessageOne("KeyHintText", client))==INVALID_HANDLE)
		return false;
	
	VFormat(buffer, sizeof(buffer), format, 3);
	BfWriteByte(hBuffer, 1);
	BfWriteString(hBuffer, buffer);
	EndMessage();
	return true;
}
