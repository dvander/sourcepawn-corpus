/**
* Sonic Trip mines and Hidden only alarms
*
* Description:
*	Makes it so that only the hidden sets off the sonic alarm
*	And IRIS have the abilit to turn sonic alarms into tripmines
*	If you have 1 or more tripmines type in chat tripmine to swap a sonic
*	alarm for a trip mine, then walk up to a sonic alarm, look at it and type
*	in chat arm.  All hidden deaths with tripmine sonic alarms are credited to 
*	the person who armed the alarm, all iris deaths caused by an alarm being detonated
*	are credited to the hidden.
*
*	CAUTION: NOT MADE FOR OVERRUN GAME MODE, PLUGIN WILL AUTOMATICALLY DISABLE
*
* Commands:
* sm_sonicmines_version : Prints current version
* sm_sonicmines_enable (0/1)
* sm_sonicmines_hiddencanhear (0/1) Default 0, controls whether the hidden can hear the alarm or not
* sm_sonicmines_tripmines (0/1) Default 1, controls whether trip mines are allowed or not
*
* Version History
*	0.9 Stable and working version
*	0.8 Fixed several bugs and issues
*	0.5 Sonic alarm arming and exploding
* 	hdn_hiddenalarm - 1.0 Basis of this plugin
*
*	THANKS TO:
*	pimpinjuice For his damage stock
*	Paegus for his alarm sound hooks
*
*
*
* Contact:
* Ice: Alex_leem@hotmail.com
* Hidden:Source: http://forum.hidden-source.com/
*/

#include <sdktools>

#define CD_VERSION		"0.9.0"
#pragma semicolon	1
#define DEV	0
#define ANYONE	-1
#define DEAD	0
#define ALIVE	1
#define HDN_MAXPLAYERS		10
#define HDN_TEAM_IRIS		2
#define HDN_TEAM_HIDDEN		3
#define Anyone		0
#define IRISAura	1
#define RadioAlarm	2
#define RadioSprite	3
#define CVARS		4
#define AlarmTime 5.7
#define DMG_GENERIC			0

new ActiveAlarm[4][1]; //To track what alarms are active - 4 alarms are alowed to be active at once
new EveryFifthTime; //Just to track how many times clients have been notified of the changed alarms
new ArmedAlarm[36][3]; //36 armed alarms are alowed per round :D
new HasArmingKit[36];
new LaserCache;
new LaserHalo;
new Alarmtoblow;
new Clientwhoblew;
new Alarmthatblew[9];  //9 Alarms are allowed to blow up at once without the beams bugging
new Float:AlarmCoordinates[36][2];

new bool:g_isHooked;

new Handle:cvarEnable;
new Handle:Heardbyhidden;
new Handle:Tripmines;
new Handle:Notify;

public Plugin:myinfo = 
{
	name = "Sonic mines",
	author = "Ice",
	description = "Makes the sonic alarm only make a sound when the hidden sets it off and lets iris have tripmines",
	version = CD_VERSION,
	url = "http://forum.hidden-source.com/"
};

public OnPluginStart () {
	CreateConVar("sm_sonicmines_version", CD_VERSION, _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	cvarEnable = CreateConVar("sm_sonicmines_enable","1","Enable/disable phys kill ranking",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	Heardbyhidden = CreateConVar("sm_sonicmines_hiddencanhear","0.0","Is the sonic alarm sound heard by the hidden?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,false);
	Tripmines = CreateConVar("sm_sonicmines_tripmines","1.0","Enables the trip mine ability",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,false);
	Notify = CreateConVar("sm_sonicmines_notify","1.0","Notify clients that alarms are hidden only every fifth time an alarm is activated",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,false);
	HookConVarChange(cvarEnable,EnablePluginCvarChange);
	CreateTimer(0.5, OnPluginStart_Delayed);
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
}

public Action:OnPluginStart_Delayed(Handle:timer){
	if(GetConVarInt(cvarEnable) > 0)
	{
		g_isHooked = true;
		AddNormalSoundHook(NormalSHook:event_SoundPlayed);
		HookEvent("game_round_start",ev_RoundStart);
		HookEvent("game_round_end", ev_RoundEnd);

		HookConVarChange(cvarEnable,EnablePluginCvarChange);
		LogMessage("[Sonicmines] - Loaded");
	}
}
public OnConfigsExecuted(){
	if (GetConVarInt(cvarEnable) == 0)
		{
			return;
		}
	new String:MapName[4];
	GetCurrentMap(MapName, sizeof(MapName));
	if(strcmp(MapName,"ovr", false) == 0){
		CreateTimer(3.0, PluginUnloadOVR_Delayed);
	}
}

public Action:PluginUnloadOVR_Delayed(Handle:timer){
	SetConVarInt(cvarEnable,0,false,false);
	LogMessage("[Sonicmines] - UnLoaded, OVR map being played");
}

public OnMapStart(){
	PrecacheSound("weapons/hegrenade/explode3.wav",true);
	LaserCache = PrecacheModel("sprites/combineball_trail_red_1.vmt");
	LaserHalo = PrecacheModel("sprites/glow01.vmt");
	PrecacheSound("weapons/sonic/alarm.wav",true);
	PrecacheSound("weapons/slam/mine_mode.wav",true);
}

public EnablePluginCvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarInt(cvarEnable) <= 0)
	{
		if(g_isHooked)
		{
		g_isHooked = false;
		UnhookEvent("game_round_start",ev_RoundStart);
		RemoveNormalSoundHook(event_SoundPlayed);
		}
	}
	else if(!g_isHooked)
	{
		g_isHooked = true;
		AddNormalSoundHook(NormalSHook:event_SoundPlayed);
		HookEvent("game_round_end",ev_RoundEnd);
		HookEvent("game_round_start",ev_RoundStart);
	}
}

public Action:Command_Say(client, args)
{
	if (GetConVarInt(cvarEnable) == 0 || GetConVarInt(Tripmines) == 0)
	{
		return Plugin_Continue;
	}
	
	new String:Chat[64];
	GetCmdArgString(Chat, sizeof(Chat));
	
	new startidx;
	if (Chat[strlen(Chat)-1] == '"')
	{
		Chat[strlen(Chat)-1] = '\0';
		startidx = 1;
	}
	if (strcmp(Chat[startidx],"tripmine", false) == 0){
		if(IsPlayer(client)){
			if (GetClientTeam(client) == 2){
				new osAmmo = FindSendPropOffs("CSDKPlayer","m_iAmmo");
				new entdata = GetEntData(client, osAmmo+(84*4), 4);
				if(entdata == 1){
					//Player is support
					new sonicdata =  GetEntData(client, osAmmo+(8*4), 4);
					if(sonicdata >= 1){
						//Player has 1 sonics and is support
						for(new i=0;i<=35;i++){
							if(HasArmingKit[i] == 0){
								HasArmingKit[i] = client;
								i = 50;
							}
						}
						SetEntData(client, osAmmo+(8*4), sonicdata - 1);
						PrintToChat(client,"You changed a sonic alarm for a sonic alarm bomb kit");
						PrintToChat(client,"To arm a sonic alarm go close to it, look at it and type in chat arm");
					} else{
						PrintToChat(client,"You must have 1 or more sonic alarms!");
					}
				} else{
					PrintToChat(client,"You must be support to use tripmines");
				}
			}			
		}
		return Plugin_Continue;
	} else if (strcmp(Chat[startidx],"arm", false) == 0){
		new Float:Blank[3];
		RigAlarm(0,Blank,0,client);
		return Plugin_Continue;	
	} 
	return Plugin_Continue;
}

public ev_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast){
	for(new i=0;i <= 35; i++){
		ArmedAlarm[i][0] = 0;
		ArmedAlarm[i][1] = 0;
		ArmedAlarm[i][2] = -10;
	}
	for(new i=0;i<=35;i++){
		HasArmingKit[i] = 0;
	}
}

public ev_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(Tripmines) == 0)
	{
		return;
	}
	
	EveryFifthTime = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsPlayer(i)){
			if (GetClientTeam(i) == 2){
				new osAmmo = FindSendPropOffs("CSDKPlayer","m_iAmmo");
				new entdata = GetEntData(i, osAmmo+(84*4), 4);
				if(entdata == 1){
					//Player is support
					new sonicdata =  GetEntData(i, osAmmo+(8*4), 4);
					if(sonicdata >= 3){
						//Player has 3 or more sonics and is support
						PrintToChat(i,"Type in chat tripmine to exchange a sonic alarm for a trip mine kit");
					}
				}
			}			
		}
	}
	for(new i=0;i <= 35; i++){
		ArmedAlarm[i][0] = 0;
		ArmedAlarm[i][1] = 0;
		ArmedAlarm[i][2] = -10;
	}
	for(new i=0;i<=35;i++){
		HasArmingKit[i] = 0;
	}
}

public Action:DamageDelay(Handle:timer){
	DealDamage(Alarmtoblow,50,Clientwhoblew,DMG_GENERIC,"weapon_sonic");
	for(new i=0;i<=8;i++){
		if(Alarmthatblew[i] == 0){
			Alarmthatblew[i] = Alarmtoblow;
			i = 10;
		}
	}
}

public Action:Beam(Handle:timer, Handle:AlarmBeam){
	ResetPack (AlarmBeam);
	new
		Alarm	= ReadPackCell(AlarmBeam)
	;
	new Float:Origin[3];
	Origin[0] = ReadPackFloat(AlarmBeam);
	Origin[1] = ReadPackFloat(AlarmBeam);
	Origin[2] = ReadPackFloat(AlarmBeam);
	new Float:Angle[3];
	Angle[0] = ReadPackFloat(AlarmBeam);
	Angle[1] = ReadPackFloat(AlarmBeam);
	Angle[2] = ReadPackFloat(AlarmBeam);
	CloseHandle (AlarmBeam);
	for(new i=0;i<=8;i++){
		if(Alarmthatblew[i] == Alarm){
			Alarmthatblew[i] = 0;
			i = 10;
			return;
		}
	}
	if(!IsValidEntity(Alarm)){
	//Alarm must have been destroyed, update the armed alarm registry and stop the beam loop
		for(new w=0;w <= 35; w++){
			if(ArmedAlarm[w][0] == Alarm){
				ArmedAlarm[w][0] = 0;
				ArmedAlarm[w][1] = 0;
				ArmedAlarm[w][2] = -10;
				return;
			}
		}
	}
	for(new i=0;i <= 35; i++){
		if(ArmedAlarm[i][0] == Alarm){
			if(Origin[0] == 0 && Origin[1] == 0 && Origin[2] == 0 && Angle[0] == 0 && Angle[1] == 0 && Angle[2] == 0){
				GetEntPropVector(Alarm, Prop_Send, "m_vecOrigin", Origin);
				GetEntPropVector(Alarm, Prop_Send, "m_angRotation", Angle);
				Angle[0] -= 90;	//Because the model faces at 90 degrees pitch when on a normal wall
			}
			TR_TraceRayFilter(Origin, Angle, MASK_ALL, RayType_Infinite, TraceRayDontHitSelf2,Alarm);
			if (TR_DidHit(INVALID_HANDLE)){
				new Float:hit[3];
				TR_GetEndPosition(hit,INVALID_HANDLE);
				new entitythathit = TR_GetEntityIndex(INVALID_HANDLE);
				if(ArmedAlarm[i][2] == -10 && (entitythathit > MaxClients || entitythathit <= 0)){
					ArmedAlarm[i][2] = entitythathit;
				}
				
				new beamcolour[4];
				beamcolour[0] = 255;
				beamcolour[3] = 200;
				TE_SetupBeamPoints(Origin, hit, LaserCache, LaserHalo, 0, -1, 2.5,1.0, 1.0, -1, 1.0, beamcolour, 10);
				TE_SendToAll(0.0);
				AlarmBeam = CreateDataPack();
				WritePackCell(AlarmBeam, Alarm);
				WritePackFloat(AlarmBeam,Origin[0]);
				WritePackFloat(AlarmBeam,Origin[1]);
				WritePackFloat(AlarmBeam,Origin[2]);
				WritePackFloat(AlarmBeam,Angle[0]);
				WritePackFloat(AlarmBeam,Angle[1]);
				WritePackFloat(AlarmBeam,Angle[2]);
				CreateTimer (4.0, Beam, AlarmBeam);
			}
			i = 50;
		}
	}
}

DealDamage(victim,damage,attacker=0,dmg_type=DMG_GENERIC,String:weapon[]="")
{
	if(victim>0 && IsValidEdict(victim) && damage>0)
	{
		new String:dmg_str[16];
		IntToString(damage,dmg_str,16);
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		new pointHurt=CreateEntityByName("point_hurt");
		if(pointHurt)
		{
			DispatchKeyValue(victim,"targetname","war3_hurtme");
			DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
			DispatchKeyValue(pointHurt,"Damage",dmg_str);
			DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,""))
			{
				DispatchKeyValue(pointHurt,"classname",weapon);
			}
			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
			DispatchKeyValue(pointHurt,"classname","point_hurt");
			DispatchKeyValue(victim,"targetname","war3_donthurtme");
			RemoveEdict(pointHurt);
			decl String:szClass[MAX_NAME_LENGTH];
			if (IsValidEdict(victim) && GetEdictClassname(victim, szClass, MAX_NAME_LENGTH) || strcmp(szClass, "npc_tripmine") != 0){
				//Must be a sonic alarm that was hurt, somehow it survived though, so remove it
				RemoveEdict(victim);
			}
		}
	}
}


RigAlarm(Alarm,Float:Origin[3],ArmOrExplode,client){
	if(ArmOrExplode == 0){
		if(IsPlayer(client)){
			if (GetClientTeam(client) == 2){
				new CanArm = 0;
				for(new i=0;i<=35;i++){
					if(HasArmingKit[i] == client){
						new entity = GetClientAimTarget(client, false);
						if(entity < 0){
							PrintToChat(client,"You must look directly at a sonic alarm");
						} else if(entity >= 0){
							new String:Entityclass[64];
							GetEdictClassname(entity, Entityclass, sizeof(Entityclass));
							if (strcmp(Entityclass, "npc_tripmine") != 0){
								PrintToChat(client,"You must look directly at a sonic alarm");
							} else if (strcmp(Entityclass, "npc_tripmine") == 0){
								GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Origin);
								new Float:PlayerOrigin[3];
								new Float:ydistance;
								new Float:xdistance;
								new Float:zdistance;
								new Float:LineDistance;
								GetClientAbsOrigin(client, PlayerOrigin);
								ydistance = Origin[1] - PlayerOrigin[1];
								xdistance = Origin[0] - PlayerOrigin[0];
								zdistance = Origin[2] - PlayerOrigin[2];
								LineDistance = SquareRoot(Pow(FloatAbs(zdistance),2.0) + Pow(FloatAbs(xdistance),2.0) + Pow(FloatAbs(ydistance),2.0));
								if(LineDistance < 75.0){
									SetEntityRenderMode(entity, RENDER_TRANSALPHA);
									SetEntityRenderColor(entity, 200, 0, 0, 75);
									PrintToChat(client,"You rigged this sonic alarm to blow!");							
									new Float:Redundand2[3];
									new Handle:AlarmBeam = CreateDataPack();
									WritePackCell(AlarmBeam, entity);
									WritePackFloat(AlarmBeam,Redundand2[0]);
									WritePackFloat(AlarmBeam,Redundand2[1]);
									WritePackFloat(AlarmBeam,Redundand2[2]);
									WritePackFloat(AlarmBeam,Redundand2[0]);
									WritePackFloat(AlarmBeam,Redundand2[1]);
									WritePackFloat(AlarmBeam,Redundand2[2]);
									CreateTimer (0.1, Beam, AlarmBeam);
									HasArmingKit[i] = 0;
									EmitSoundToAll("weapons/slam/mine_mode.wav",Alarm,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,Origin,NULL_VECTOR,true,0.0);
									for(new p=0;p <= 35; p++){
										if(ArmedAlarm[p][0] == 0){
											ArmedAlarm[p][0] = entity;
											ArmedAlarm[p][1] = client;
											AlarmCoordinates[p][0] = Origin[0];
											AlarmCoordinates[p][1] = Origin[1];
											p = 100;
										}
									}
								} else{
									PrintToChat(client,"You must be closer to the alarm to arm it!");
								}
							}
						}
						i = 50;
					} else if(HasArmingKit[i] != client){
						CanArm++;
					}
				}
				if(CanArm == 36){
					PrintToChat(client,"You do not have an arming kit! Type in chat tripmine to get one!");
				}
			}
		}
	}
	if(ArmOrExplode == 1){
		//Must be exploding the alarm
		new Explosion = CreateEntityByName("env_explosion");            // Create explosion
		DispatchKeyValue(Explosion, "magnitude", "400.0");                    // force float
		DispatchKeyValue(Explosion, "radius", "400");                        // radius
		new Float:AngleFloat[3];
		GetEntPropVector(Alarm, Prop_Send, "m_angRotation", AngleFloat);
		AngleFloat[0] -= 90;
		new String:AnglesString[16];
		Format(AnglesString, sizeof(AnglesString), "%f %f %f",AngleFloat[0],AngleFloat[1],AngleFloat[2]);
		DispatchKeyValue(Explosion, "angles", AnglesString);
		DispatchSpawn(Explosion);                                        // Spawn descriped explosion
		TeleportEntity(Explosion, Origin, NULL_VECTOR, NULL_VECTOR);    // move it somewhere
		AcceptEntityInput(Explosion, "Explode");
		EmitSoundToAll("weapons/hegrenade/explode3.wav",Alarm,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,Origin,NULL_VECTOR,true,0.0);
		new Float:PlayerOrigin[3];
		new Float:ydistance;
		new Float:xdistance;
		new Float:zdistance;
		new Float:LineDistance;
		new HiddenClient = 0;
		for(new i=1;i <= MaxClients; i++){
			if(IsPlayer(i) && GetClientTeam(i) == 3){
				HiddenClient = i;
				i = 50;
			}
		}
			
		for(new i=1;i <= MaxClients; i++){
			if(IsPlayer(i)){
				GetClientAbsOrigin(i, PlayerOrigin);
				ydistance = Origin[1] - PlayerOrigin[1];
				xdistance = Origin[0] - PlayerOrigin[0];
				zdistance = Origin[2] - PlayerOrigin[2];
				LineDistance = SquareRoot(Pow(FloatAbs(zdistance),2.0) + Pow(FloatAbs(xdistance),2.0) + Pow(FloatAbs(ydistance),2.0));
				if(GetClientTeam(i) == 3){
					if(LineDistance <= 150.0){
						if(IsPlayer(client)){
							DealDamage(i,40,client,DMG_GENERIC,"weapon_sonic");
						} else {
						//Client who planted alarm must have disconnected, make attacker the world
							DealDamage(i,40,0,DMG_GENERIC,"weapon_sonic");
						}
					} else if(LineDistance < 250.0){
						if(IsPlayer(client)){
							DealDamage(i,20,client,DMG_GENERIC,"weapon_sonic");
						} else {
							DealDamage(i,20,0,DMG_GENERIC,"weapon_sonic");
						}
					} else if(LineDistance < 300.0){
						if(IsPlayer(client)){
							DealDamage(i,10,client,DMG_GENERIC,"weapon_sonic");
						} else {
							DealDamage(i,10,0,DMG_GENERIC,"weapon_sonic");
						}
					}
				} else {
					if(LineDistance <= 120.0){
						DealDamage(i,60,HiddenClient,DMG_GENERIC,"weapon_sonic");
						ClientCommand(i, "blur");
					} else if(LineDistance < 200.0){
						DealDamage(i,30,HiddenClient,DMG_GENERIC,"weapon_sonic");
						ClientCommand(i, "blur");
					} else if(LineDistance < 250.0){
						DealDamage(i,10,HiddenClient,DMG_GENERIC,"weapon_sonic");
						ClientCommand(i, "blur");
					}
				}
			}
		}
		Alarmtoblow = Alarm;
		Clientwhoblew = client;
		CreateTimer(0.1, DamageDelay);
	}
}



public Action:event_SoundPlayed (
	clients[64],
	&numClients,
	String:sample[PLATFORM_MAX_PATH],
	&entity,
	&channel,
	&Float:volume,
	&level,
	&pitch,
	&flags
) {
	if (
		!StrEqual (sample,")weapons/sonic/alarm.wav") ||	// Wasn't an alarm.
		volume < 0.001									// Too quiet to care about.
	) {
		return Plugin_Continue;
	}
	
	for(new e = 0; e <= 3; e++){
		if(ActiveAlarm[e][0] == entity){
			return Plugin_Handled;	//Alarm is already playing a sound and hasnt finished yet
		}
	}
	
	new Float:Origin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Origin);
	decl String:szClass[MAX_NAME_LENGTH];

	if (!IsValidEntity(entity) || !GetEdictClassname(entity, szClass, MAX_NAME_LENGTH) || strcmp(szClass, "npc_tripmine") != 0){
		return Plugin_Handled;	//Something is wrong here.... return
	}
	new Isarmed = -1;
	for(new i=0;i <= 35; i++){
		if(ArmedAlarm[i][0] == entity){
			Isarmed = i;
		}
	}
	
	new Float:Angle[3];
	GetEntPropVector(entity, Prop_Send, "m_angRotation", Angle);
	Angle[0] -= 90;	//Because the model faces at 90 degrees pitch when on a normal wall
	new Hiddenclient = 0;
	new Isaplayercloser = 0;
	new Float:PlayerDistance = 0.0;
	new Float:Hiddendistance = 0.0;
	if(Isarmed > -1){
		TR_TraceRayFilter(Origin, Angle, MASK_ALL, RayType_Infinite, TraceRayDontHitSelf3,entity);
		if (TR_DidHit(INVALID_HANDLE)){
			new entitythathit = TR_GetEntityIndex(INVALID_HANDLE);
			if (ArmedAlarm[Isarmed][2] != entitythathit && ArmedAlarm[Isarmed][2] != -10){
				#if DEV
					LogMessage("*** ALARM EXPLODED ***!");
				#endif
				RigAlarm(entity,Origin,1,ArmedAlarm[Isarmed][1]);
				ArmedAlarm[Isarmed][0] = 0;
				ArmedAlarm[Isarmed][1] = 0;
				ArmedAlarm[Isarmed][2] = -10;
				return Plugin_Handled;
			}
		}
	}
	for(new a = 1; a <= MaxClients; a++){
		if(IsClientInGame(a)){
			if(GetClientTeam(a) == 3){
				Hiddenclient = a;
				Hiddendistance = GetClientDistance(Hiddenclient, entity, Origin, Angle);
				#if DEV
					LogMessage("Hiddendistance: %f",Hiddendistance);
				#endif
				if(Hiddendistance != -1.0){
					for(new q = 1; q <= MaxClients; q++){
						if(IsClientInGame(a)){
							PlayerDistance = GetClientDistance(q, entity, Origin, Angle);
							#if DEV
							LogMessage("PlayerDistance: %f",PlayerDistance);
							#endif
							if(PlayerDistance < Hiddendistance && PlayerDistance != -1.0){
								Isaplayercloser = 1;
							}
						}
					}
				} else{
					Isaplayercloser = 1;
				}
			}
		}
	}
	
	#if DEV
		LogMessage("Isaplayercloser: %d",Isaplayercloser);
	#endif
	
	//We want to only set the alarm off if the hidden is the closest one to it or if he is very close to it
	if((Isaplayercloser == 0 && Hiddendistance < 170) || (Hiddendistance < 65 && Hiddendistance != -1)){
		#if DEV
			LogMessage("*** ALARM TRIGGERED ***!");
		#endif
		if(Isarmed > -1){
			#if DEV
				LogMessage("*** ALARM EXPLODED ***!");
			#endif
			RigAlarm(entity,Origin,1,ArmedAlarm[Isarmed][1]);
			ArmedAlarm[Isarmed][0] = 0;
			ArmedAlarm[Isarmed][1] = 0;
			ArmedAlarm[Isarmed][2] = -10;
			return Plugin_Handled;
		}
		for(new w = 0; w <= 3; w++){
			if(ActiveAlarm[w][0] == 0){
				ActiveAlarm[w][0] = entity;
				if (GetConVarInt(Heardbyhidden) == 1)
				{
					EmitSoundToTeam (	// Emit sound from alarm's origin.
					ANYONE,
					ANYONE,
					"weapons/sonic/alarm.wav",
					entity,
					channel,
					level,
					SND_NOFLAGS,
					volume,
					pitch,
					NULL_VECTOR,
					NULL_VECTOR,
					true,
					0.0
					);
				} else if (GetConVarInt(Heardbyhidden) == 0)
				{
					EmitSoundToTeam (	// Emit sound from alarm's origin.
					2,
					ANYONE,
					"weapons/sonic/alarm.wav",
					entity,
					channel,
					level,
					SND_NOFLAGS,
					volume,
					pitch,
					NULL_VECTOR,
					NULL_VECTOR,
					true,
					0.0
					);
				}
				

				new Handle:hKillPack = CreateDataPack();
				WritePackCell(hKillPack, entity);
				WritePackCell(hKillPack, channel);
				WritePackFloat(hKillPack, volume);
				WritePackCell(hKillPack, level);
				WritePackCell(hKillPack, pitch);
				WritePackCell(hKillPack, w);
			
				CreateTimer (5.7, tmr_SilenceAlarmSound, hKillPack); // Kill the sound after 5.7 seconds
				w = 5;
			} else{
				#if DEV
					LogMessage("*** SLOT %d IS ACTIVE ***!",w);
				#endif
			}
		}
	}
	else if(GetConVarInt(Notify) == 1){
		if(EveryFifthTime == 0){
			for(new p = 1; p <= MaxClients; p++){
				if(IsPlayer(p)){
					if(GetClientTeam(p) != 3){
						//Fifth time alarm has been walked throug without it being set off by the hidden, let people know whats happening
						PrintToChat(p, "Alarms are set to hidden only!");
					}
				}
			}
			EveryFifthTime++;
		} else if(EveryFifthTime > 5){
			EveryFifthTime = 0;
		} else {
			EveryFifthTime++;
		}	
	}
	return Plugin_Handled;
}
	

/* Silence the alarm sound */
public Action:tmr_SilenceAlarmSound (Handle:timer, Handle:datapack) {
	ResetPack (datapack);
	new
		alarm	= ReadPackCell(datapack),
		channel	= ReadPackCell(datapack),
		Float:volume = ReadPackFloat(datapack),
		level	= ReadPackCell(datapack),
		pitch	= ReadPackCell(datapack),
		slot	= ReadPackCell(datapack)
	;
	CloseHandle (datapack);
	
	#if DEV
		LogMessage("*** Killing sound from alarm %d slot %d", alarm, slot);
	#endif
	
	if(slot != -1){
		ActiveAlarm[slot][0] = 0;	//Report that alarm is inactive
	}
	
	EmitSoundToTeam (	// Silence!
		ANYONE,
		ANYONE,
		"weapons/sonic/alarm.wav",
		alarm,
		channel,
		level,
		SND_STOPLOOPING,
		volume,
		pitch,
		NULL_VECTOR,
		NULL_VECTOR,
		true,
		0.0
	);
	return Plugin_Handled;
}

stock EmitSoundToTeam (
	team = ANYONE,
	alive = ANYONE,
	const String:sample[],
	entity = SOUND_FROM_PLAYER,
	channel = SNDCHAN_AUTO,
	level = SNDLEVEL_NORMAL,
	flags = SND_NOFLAGS,
	Float:volume = SNDVOL_NORMAL,
	pitch = SNDPITCH_NORMAL,
	const Float:origin[3] = NULL_VECTOR,
	const Float:dir[3] = NULL_VECTOR,
	bool:updatePos = true,
	Float:soundtime = 0.0
) {
	decl clients[MaxClients];
	new totalClients = 0;

	for (new i=1; i<=MaxClients; i++) {
		if (
			IsClientInGame (i) &&				// Client is connected
			 (
				team == ANYONE ||				// Specified team is ALL
				GetClientTeam (i) == team		// Client is on specified team.
			) &&
			 (
				alive == ANYONE ||				// Specified life is ANY
				IsPlayerAlive (i) == bool:alive	// Client is on specified life state.
			)
		) {
			clients[totalClients++] = i;
		}
	}
	
	if (totalClients) {
		EmitSound (
			clients,
			totalClients,
			sample,
			entity,
			channel,
			level,
			flags,
			volume,
			pitch,
			entity,
			origin,
			dir,
			updatePos,
			soundtime
		);
	}
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if ((entity > 0) && (entity <= MaxClients))
	{
	return true;
	}
	else
	{
	return false;
	}
}

public bool:TraceRayDontHitSelf3(entity, mask, any:data)
{
	if ((entity == data) || ((entity <= MaxClients) && entity > 0))
	{
	return false;
	}
	else
	{
	return true;
	}
}

public bool:TraceRayDontHitSelf2(entity, mask, any:data)
{
	if ((entity == data))
	{
	return false;
	}
	else
	{
	return true;
	}
}

stock Float:GetClientDistance (const any:Client, const any:Entity, const Float:Origin[3], const Float:Angle[3], const bool:squared=false) {	
	if(IsPlayer(Client)){
		new Float:PlayerOrigin[3];
		GetClientAbsOrigin(Client, PlayerOrigin);
		PlayerOrigin[2] += 30.0;
		TR_TraceRayFilter(Origin, PlayerOrigin, MASK_SOLID, RayType_EndPoint, TraceRayDontHitSelf,Entity);
		if (TR_DidHit(INVALID_HANDLE)){
			new TRIndex = TR_GetEntityIndex(INVALID_HANDLE);
			if (TRIndex == Client){
				new Float:hit[3];
				TR_GetEndPosition(hit,INVALID_HANDLE);
				new Float:ydistance;
				new Float:xdistance;
				new Float:zdistance;
				ydistance = Origin[1] - hit[1];
				xdistance = Origin[0] - hit[0];
				zdistance = Origin[2] - hit[2];
				new Float:LineDistance;
				LineDistance = SquareRoot(Pow(FloatAbs(zdistance),2.0) + Pow(FloatAbs(xdistance),2.0) + Pow(FloatAbs(ydistance),2.0));
				new Float:PlanLineDistance = SquareRoot(Pow(xdistance,2.0) + Pow(ydistance,2.0));
				new Float:Xtrace = PlanLineDistance * Cosine(DegToRad(Angle[1]));
				new Float:Ytrace = PlanLineDistance * Sine(DegToRad(Angle[1]));
				new Float:Ztrace = LineDistance * Sine(DegToRad(Angle[0] + 180));
				new Float:Proximityorigin[3];
				//Using the distance away from the alarm the player is at, find what the location of the player would be if the distance was exactly
				//along the axis of the alarm
				Proximityorigin[0] = Origin[0] + Xtrace;
				Proximityorigin[1] = Origin[1] + Ytrace;
				Proximityorigin[2] = Origin[2] + Ztrace;
				//Find the players distance away from the extrapolated location
				new Float:Distancetoproximity = SquareRoot(Pow(FloatAbs(FloatAbs(Proximityorigin[0])-FloatAbs(hit[0])),2.0) + Pow(FloatAbs(FloatAbs(Proximityorigin[1])-FloatAbs(hit[1])),2.0) + Pow(FloatAbs(FloatAbs(Proximityorigin[2])-FloatAbs(hit[2])),2.0));
				return Distancetoproximity;
			}
			return -1.0;  //Didnt hit a client
		}
	}
	return -1.0;  //Wasnt a player
}

bool:IsPlayer(client) {
	if (client >= 1 && client <= MaxClients) {
		if(IsValidEntity(client) && !IsFakeClient(client) && IsClientConnected(client) && IsClientInGame(client)){
			return true;
		}
	}
	return false;
}