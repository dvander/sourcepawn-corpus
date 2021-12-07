/**
* Hidden alarm only
*
* Description:
*	Makes it so that only the hidden sets off the sonic alarm
*
* Commands:
* sm_hiddenalarm_version : Prints current version
*
* Version History
* 	1.0 Working version
*
* Contact:
* Ice: Alex_leem@hotmail.com
* Hidden:Source: http://forum.hidden-source.com/
*/

#define CD_VERSION		"1.0.0"
#pragma semicolon	1
#define DEV		0
#include <sdktools>
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
new ActiveAlarm[4][1]; //To track what alarms are active - 4 alarms are alowed to be active at once
new EveryFifthTime; //Just to track how many times clients have been notified of the changed alarms

public Plugin:myinfo = 
{
	name = "HiddenAlarmOnly",
	author = "Ice",
	description = "Makes the sonic alarm only make a sound when the hidden sets it off",
	version = CD_VERSION,
	url = "http://forum.hidden-source.com/"
};

public OnPluginStart () {
	CreateConVar("sm_hiddenalarm_version", CD_VERSION, _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	AddNormalSoundHook(NormalSHook:event_SoundPlayed);
	HookEvent("game_round_start",ev_RoundStart);
	PrecacheSound("weapons/sonic/alarm.wav",true);
}

public ev_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	EveryFifthTime = 0;
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
	
	#if DEV
		LogMessage(
			"*** Alarm %d was triggered",
			entity
		);
	#endif
	
	for(new e = 0; e <= 3; e++){
		if(ActiveAlarm[e][0] == entity){
			return Plugin_Handled;	//Alarm is already playing a sound and hasnt finished yet
		}
	}
	
	decl String:szClass[MAX_NAME_LENGTH];

	if (!IsValidEntity(entity) || !GetEdictClassname(entity, szClass, MAX_NAME_LENGTH) || strcmp(szClass, "npc_tripmine") != 0){
		return Plugin_Handled;	//Something is wrong here.... return
	}
	
	new Float:Angle[3];
	new Float:Origin[3];
	GetEntPropVector(entity, Prop_Send, "m_angRotation", Angle);
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Origin);
	Angle[0] -= 90;	//Because the model faces at 90 degrees pitch when on a normal wall
	new Hiddenclient = 0;
	new Isaplayercloser = 0;
	new Float:PlayerDistance = 0.0;
	new Float:Hiddendistance = 0.0;
	for(new a = 1; a <= MaxClients; a++){
		if(IsClientInGame(a)){
			if(GetClientTeam(a) == 3){
				Hiddenclient = a;
				Hiddendistance = GetClientDistance(Hiddenclient, entity, Origin, Angle);
				#if DEV
					{LogMessage("Hiddendistance: %f",Hiddendistance);
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
		for(new w = 0; w <= 3; w++){
			if(ActiveAlarm[w][0] == 0){
				ActiveAlarm[w][0] = entity;
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
	else {
		if(EveryFifthTime == 0){
			for(new p = 1; p <= MaxClients; p++){
				if(IsPlayer(p)){
					if(GetClientTeam(p) != 3){
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