#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.0.2"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DOOR_MAX 8
#define DOOR_SPEED 89.0
#define DOOR_CHECKPOINT "prop_door_rotating_checkpoint"

new	entityDoor[DOOR_MAX];
new	flagDoorLock[DOOR_MAX];

new multiLanguage;
new Handle:hPluginEnable = INVALID_HANDLE;
new Handle:hDoorLockSpam = INVALID_HANDLE;
new Handle:hDoorLockTrap = INVALID_HANDLE;
new Handle:hDoorOpenRush = INVALID_HANDLE;
new Handle:hDoorLockDown = INVALID_HANDLE;
new Handle:hDoorLockPos = INVALID_HANDLE;
new Handle:hDoorLockMin = INVALID_HANDLE;
new Handle:hDoorLockMax = INVALID_HANDLE;
new Handle:hDoorLockChange = INVALID_HANDLE;
new Handle:hDoorLockShow = INVALID_HANDLE;
new Handle:hDoorLockDebug = INVALID_HANDLE;

new Handle:hTimer = INVALID_HANDLE;
new entDoorCount = 0;
new entDoorStart;
new entDoorGoal;
new ofs_doorOrigin;
new Float:vecGoal[3];
new Float:vecSpwn[3];
new flagDoorStart;
new flagDoorGoal;
new flagDoorType;
new countDown;
new nShowType;
new Float:prevTime;
new Float:prevDoorTime;
new bool:isSafeRoom[MAXPLAYERS+1];

public Plugin:myinfo = {
	name = "L4D Door Lock",
	author = "NiCo-op",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://nico-op.forjp.net/"
};

public OnPluginStart(){

	CreateConVar("l4d_doorlock_version",
		PLUGIN_VERSION,
		"L4D Door Lock",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD
	);

	hPluginEnable = CreateConVar(
		"l4d_doorlock",
		"1",
		"plugin on/off (on:1 / off:0)",
		CVAR_FLAGS,
		true,
		0.0,
		true,
		1.0
	);

	hDoorLockSpam = CreateConVar(
		"l4d_doorlock_spam",
		"1",
		"anti-doorspam",
		CVAR_FLAGS,
		true,
		0.0,
		true,
		1.0
	);

	hDoorLockTrap = CreateConVar(
		"l4d_doorlock_trap",
		"100",
		"sets up the traps to the door(0-100%)",
		CVAR_FLAGS,
		true,
		0.0,
		true,
		100.0
	);

	hDoorOpenRush = CreateConVar(
		"l4d_doorlock_rush",
		"10",
		"frequency of panic event that trap calls (def:10 / min:0 / max:20)",
		CVAR_FLAGS,
		true,
		0.0,
		true,
		20.0
	);

	hDoorLockDown = CreateConVar(
		"l4d_doorlock_down",
		"0",
		"player that has been downed is included (def:0 / on:1 / off:0)",
		CVAR_FLAGS,
		true,
		0.0,
		true,
		1.0
	);

	hDoorLockMin = CreateConVar(
		"l4d_doorlock_secmin",
		"15",
		"number of seconds with effective trap(min)",
		CVAR_FLAGS,
		true,
		5.0,
		true,
		300.0
	);

	hDoorLockMax = CreateConVar(
		"l4d_doorlock_secmax",
		"45",
		"number of seconds with effective trap(max)",
		CVAR_FLAGS,
		true,
		5.0,
		true,
		300.0
	);

	hDoorLockChange = CreateConVar(
		"l4d_doorlock_change",
		"30",
		"door speed change. open slowly",
		CVAR_FLAGS,
		true,
		30.0,
		true,
		300.0
	);

	hDoorLockPos = CreateConVar(
		"l4d_doorlock_pos",
		"1000",
		"distance in which door is permitted to be opened",
		CVAR_FLAGS,
		true,
		0.0,
		true,
		5000.0
	);

	hDoorLockShow = CreateConVar(
		"l4d_doorlock_show",
		"0",
		"countdown type (def:0 / center text:0 / hint text:1)",
		CVAR_FLAGS,
		true,
		0.0,
		true,
		1.0
	);

	hDoorLockDebug = CreateConVar(
		"l4d_doorlock_debug",
		"0",
		"debug command (def:0 / on:1 / off:0)",
		CVAR_FLAGS,
		true,
		0.0,
		true,
		1.0
	);

	if(FileExists("addons/sourcemod/translations/plugin.l4d_doorlock.txt")){
		LoadTranslations("plugin.l4d_doorlock");
		multiLanguage = 1;
	}
	else{
		multiLanguage = 0;
	}

	HookEvent("round_start_post_nav", OnRoundStartPostNav);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("player_death", OnPlayerLeftCheckpoint);
	HookEvent("player_left_checkpoint", OnPlayerLeftCheckpoint);
	HookEvent("player_entered_checkpoint", OnPlayerEnteredCheckpoint);
	HookEvent("player_use", OnPlayerUse, EventHookMode_Pre);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("bot_player_replace", OnBotPlayerReplace);
	RegConsoleCmd("sm_doorpos", CommandDEBUG);

	AutoExecConfig(true, "l4d_doorlock");

	if((ofs_doorOrigin = FindSendPropOffs("CBaseDoor", "m_vecOrigin")) == -1){
		LogError("Could not find offset for CBaseDoor::m_vecOrigin");
	}
}

IsALLinSafeRoom(){
	new count = 0;
	new alive = 0;
	new max = GetMaxClients();
	for(new i=1; i<=max; i++){
		if(IsClientConnected(i)
		  && IsClientInGame(i)
		  && !IsFakeClient(i)
		  && IsPlayerAlive(i)
		  && GetClientTeam(i) == 2
		  && (!GetConVarBool(hDoorLockDown)
		  || !GetEntProp(i, Prop_Send, "m_isIncapacitated"))){
			if(isSafeRoom[i]){
				count++;
			}
			alive++;
		}
	}
	return (alive <= count) ? 1 : 0;
}

GetEntitySafeRoomDoor(){
	decl Float:vec[3];
	new door_1st = -1;
	new door_last = -1;
	new door_count = 0;

	new index = -1;
	while((index = FindEntityByClassname(index, DOOR_CHECKPOINT)) != -1){
		GetEntDataVector(index, ofs_doorOrigin, vec);
		if(FloatAbs(vec[0] - vecSpwn[0])
		 + FloatAbs(vec[1] - vecSpwn[1])
		 + FloatAbs(vec[2] - vecSpwn[2]) > 2000){
			door_last = index;
		}
		else if(door_1st == -1){
			door_1st = index;
		}
		DoorUnlockFlag(index);
		door_count++;
	}
	if(door_last != -1 && GetEntProp(door_last, Prop_Data, "m_bLocked") <= 0){
		entDoorGoal = door_last;
	}
	else{
		entDoorGoal = -1;
	}
	entDoorCount = door_count;
	entDoorStart = door_1st;
}

DoorUnlockFlag(entity){
	for(new i=0; i<DOOR_MAX; i++){
		if(!entityDoor[i]||entityDoor[i] == entity){
			entityDoor[i] = entity;
			flagDoorLock[i] = 0;
			break;
		}
	}
}

DoorLockFlag(entity){
	for(new i=0; i<DOOR_MAX; i++){
		if(!entityDoor[i]||entityDoor[i] == entity){
			entityDoor[i] = entity;
			flagDoorLock[i] = entity;
			break;
		}
	}
}

CheckDoor(entity){
	for(new i=0; i<DOOR_MAX; i++){
		if(entityDoor[i] == entity){
			return entity;
		}
	}
	return 0;
}

CheckDoorLock(entity){
	for(new i=0; i<DOOR_MAX; i++){
		if(entityDoor[i] == entity){
			return flagDoorLock[i];
		}
	}
	return 0;
}

public Action:OnRoundStartPostNav(Handle:event, const String:name[], bool:dontBroadcast)
{
	prevTime = 0.0;
	prevDoorTime = 0.0;
	flagDoorStart = 0;
	flagDoorGoal = 0;
	for(new i=0; i<MAXPLAYERS+1; i++){
		isSafeRoom[i] = false;
	}

	return Plugin_Continue;
}

public OnMapStart(){
	PrecacheSound("ambient/alarms/klaxon1.wav", true);
}

public OnMapEnd(){
	hTimer = INVALID_HANDLE;
	entDoorCount = 0;
	entDoorGoal = 0;
	vecGoal[0] = vecGoal[1] = vecGoal[2] = 0.0;
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	hTimer = INVALID_HANDLE;
	entDoorCount = 0;
	entDoorGoal = 0;
	return Plugin_Continue;
}

public Action:OnPlayerLeftCheckpoint(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client && IsClientConnected(client) && IsClientInGame(client)){
		isSafeRoom[client] = false;
	}
}

public Action:OnPlayerEnteredCheckpoint(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client
	  && IsClientConnected(client)
	  && IsClientInGame(client)
	  && IsPlayerAlive(client)
	  && GetClientTeam(client) == 2
	){
		isSafeRoom[client] = true;
	}

	return Plugin_Continue;
}

public Action:OnPlayerUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(hPluginEnable)) return Plugin_Continue;
	new entity = GetEventInt(event, "targetid");
	new Float:nowTime = GetGameTime();

	if(entity == entDoorGoal && !flagDoorGoal){

		decl String:username[MAX_NAME_LENGTH];
		decl Float:vec[3], Float:vecPlayer[3];
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		GetClientAbsOrigin(client, vecPlayer);

		if(GetConVarBool(hDoorLockPos)){
			new max = GetMaxClients();
			new count = 0;
			for(new i=1; i<=max; i++){
				if(IsClientConnected(i)
				  && IsClientInGame(i)
				  && IsPlayerAlive(i)
				  && !IsFakeClient(i)
				  && GetClientTeam(i) == 2
				  && (!GetConVarBool(hDoorLockDown)
				  || !GetEntProp(i, Prop_Send, "m_isIncapacitated"))){
					GetClientAbsOrigin(i, vec);
					if(FloatAbs(vec[0] - vecPlayer[0])
					 + FloatAbs(vec[1] - vecPlayer[1])
					 + FloatAbs(vec[2] - vecPlayer[2]) > GetConVarFloat(hDoorLockPos)){
						if(count++ < 3){
							// for doorspamer
							if(nowTime - prevDoorTime >= 0.0 && nowTime - prevDoorTime <= 8.00){
								if(count == 1){
									if(multiLanguage){
										PrintToChat(client, "\x04[DOOR] \x03%t", "hint doorlock");
									}
									else{
										PrintToChat(client, "\x04[DOOR] \x03please wait for players arrival");
									}
								}
								GetClientName(i, username, sizeof(username));
								if(multiLanguage){
									PrintToChat(client, "\x04[DOOR] \x03%t", "goto doorlock", username);
								}
								else{
									PrintToChat(client, "\x04[DOOR] \x03%s - please go to safe room", username);
								}
							}
							// for all
							else{
								if(count == 1){
									GetClientName(client, username, sizeof(username));
									if(multiLanguage){
										PrintToChatAll("\x04[DOOR] \x03%t", "block doorlock", username);
										PrintToChatAll("\x04[DOOR] \x03%t", "hint doorlock");
									}
									else{
										PrintToChatAll("\x04[DOOR] \x03%s - failed to open the door", username);
										PrintToChatAll("\x04[DOOR] \x03please wait for players arrival");
									}
								}
								GetClientName(i, username, sizeof(username));
								if(multiLanguage){
									PrintToChatAll("\x04[DOOR] \x03%t", "goto doorlock", username);
								}
								else{
									PrintToChatAll("\x04[DOOR] \x03%s - please go to safe room", username);
								}
							}
						}
					}
				}
			}
			if(count){
				prevDoorTime = nowTime;
				return Plugin_Continue;
			}
		}

		flagDoorGoal = 1;
		if(countDown <= 0){
			AcceptEntityInput(entity, "Unlock");
			AcceptEntityInput(entity, "forceclosed");
			AcceptEntityInput(entity, "Open");
		}
		else{
			new mobs = GetConVarInt(hDoorOpenRush);
			new flags = GetCommandFlags("z_spawn");
			SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
			for(new i=0; i<mobs; i++){
				FakeClientCommand(client, "z_spawn mob auto");
			}
			SetCommandFlags("z_spawn", flags);

			nShowType = GetConVarBool(hDoorLockShow);
			hTimer = CreateTimer(1.0,
				TimerDoorCountDown, entity, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			TimerDoorCountDown(hTimer, entity);

			if(flagDoorType){
				SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", 0);
				AcceptEntityInput(entity, "Unlock");
				AcceptEntityInput(entity, "forceclosed");
				AcceptEntityInput(entity, "Open");
				SetEntPropFloat(entity, Prop_Data, "m_flSpeed", 200.0);
			}
		}
	}
	else if(entity == entDoorStart && !flagDoorStart
	  && !GetEntProp(entity, Prop_Data, "m_bLocked")){
		flagDoorStart = 1;
	}

	if(nowTime - prevTime >= 0.0 && nowTime - prevTime <= 0.25) return Plugin_Continue;

	if(CheckDoor(entity)){
		new status = GetEntProp(entity, Prop_Data, "m_eDoorState");
		new flags = ((!flagDoorGoal || countDown <= 0) && CheckDoorLock(entity));
		if(IsALLinSafeRoom()){
			if(status == 2 && flags && GetEntProp(entity, Prop_Data, "m_bLocked")){
				SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", 0);
				AcceptEntityInput(entity, "Unlock");
				AcceptEntityInput(entity, "forceclosed");
				AcceptEntityInput(entity, "Close");
			}
		}
		else if(!status && flags){
			SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", 0);
			AcceptEntityInput(entity, "Unlock");
			AcceptEntityInput(entity, "forceclosed");
			AcceptEntityInput(entity, "Open");
		}
		else if((status&3)%3 && !GetEntProp(entity, Prop_Data, "m_bLocked")){
			// anti-doorspam
			if(GetConVarBool(hDoorLockSpam)){
				DoorLockFlag(entity);
				AcceptEntityInput(entity, "forceclosed");
				AcceptEntityInput(entity, "Lock");
				SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", 1);
			}
		}
		else if(status == 2 && GetEntProp(entity, Prop_Data, "m_bLocked")){
			decl String:username[MAX_NAME_LENGTH];
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			new max = GetMaxClients();
			new count = 0;
			for(new i=1; i<=max; i++){
				if(!isSafeRoom[i]
				  && IsClientConnected(i)
				  && IsClientInGame(i)
				  && IsPlayerAlive(i)
				  && !IsFakeClient(i)
				  && GetClientTeam(i) == 2
				  &&  (!GetConVarBool(hDoorLockDown)
				  || !GetEntProp(i, Prop_Send, "m_isIncapacitated"))){
					if(count++ < 3){
						GetClientName(i, username, sizeof(username));
						// for doorspamer
						if(nowTime - prevTime >= 0.0 && nowTime - prevTime <= 3.00){
							if(multiLanguage){
								PrintToChat(client, "\x04[DOOR] \x03%t", "enter doorlock", username);
							}
							else{
								PrintToChat(client, "\x04[DOOR] \x03%s - please enter a safe room", username);
							}
						}
						// for all
						else{
							if(multiLanguage){
								PrintToChatAll("\x04[DOOR] \x03%t", "enter doorlock", username);
							}
							else{
								PrintToChatAll("\x04[DOOR] \x03%s - please enter a safe room", username);
							}
						}
					}
				}
			}
		}
	}
	prevTime = nowTime;
	return Plugin_Continue;
}

public Action:TimerDoorCountDown(Handle:timer, any:entity){
	if(timer == hTimer){
		EmitSoundToAll(
			"ambient/alarms/klaxon1.wav", entity,
			SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN,
			SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_LOW,
			-1, NULL_VECTOR, NULL_VECTOR, true, 0.0);

		if(countDown > 0){
			if(!nShowType){
				PrintCenterTextAll("[DOOR OPEN] %d sec", countDown);
			}
			else{
				new max = GetMaxClients();
				for(new i=1; i<=max; i++){
					if(IsClientConnected(i)
					  && IsClientInGame(i)
					  && !IsFakeClient(i)
					  && GetClientTeam(i) == 2){
						PrintHintText(i, "[DOOR OPEN] %d sec", countDown);
					}
				}
			}
			countDown--;
			return Plugin_Continue;
		}

		if(!flagDoorType){
			SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", 0);
			AcceptEntityInput(entity, "Unlock");
			AcceptEntityInput(entity, "Open");
		}

		new max = GetMaxClients();
		for(new i=1; i<=max; i++){
			if(IsClientConnected(i)
			  && IsClientInGame(i)
			  && !IsFakeClient(i)
			  && GetClientTeam(i) == 2){
				PrintHintText(i, "DOOR OPENED");
			}
		}
	}

	return Plugin_Stop;
}

// afk -> join
public Action:TimerCheckSafeRoom(Handle:timer, any:client)
{
	if(client <= 0 
	  || !IsClientConnected(client)
	  || !IsClientInGame(client)
	  || !IsPlayerAlive(client)
	  || GetClientTeam(client) != 2){
		return Plugin_Stop;
	}

	decl Float:vec[3], Float:vecPlayer[3];
	GetClientAbsOrigin(client, vecPlayer);

	new max = GetMaxClients();
	for(new i=1; i<=max; i++){
		if(client != i
		  && isSafeRoom[i]
		  && IsClientConnected(i)
		  && IsClientInGame(i)
		  && IsPlayerAlive(i)
		  && GetClientTeam(i) == 2){
			GetClientAbsOrigin(i, vec);
			if(FloatAbs(vec[0] - vecPlayer[0])
			 + FloatAbs(vec[1] - vecPlayer[1])
			 + FloatAbs(vec[2] - vecPlayer[2]) < 1000.0){
				isSafeRoom[client] = true;
				break;
			}
		}
	}
	return Plugin_Stop;
}

public Action:TimerDoorLock(Handle:timer, any:entity){
	AcceptEntityInput(entity, "Close");
	SetEntPropFloat(entity, Prop_Data, "m_flSpeed",
		flagDoorType ? (DOOR_SPEED/float(countDown)) : 200.0);
	DoorLockFlag(entity);
	AcceptEntityInput(entity, "Lock");
	SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", 1);
	return Plugin_Stop;
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(entDoorGoal == 0
	  && client > 0
	  && IsClientConnected(client)
	  && IsClientInGame(client)
	  && GetClientTeam(client) == 2
	  && IsValidEntity(client)
	){
		GetClientAbsOrigin(client, vecSpwn);
		for(new i=0; i<DOOR_MAX; i++){
			entityDoor[i] = 0;
			flagDoorLock[i] = 0;
		}
		GetEntitySafeRoomDoor();

		new min = GetConVarInt(hDoorLockMin);
		new max = GetConVarInt(hDoorLockMax);
		new trap = GetConVarInt(hDoorLockTrap);
		new change = GetConVarInt(hDoorLockChange);
		countDown = (GetRandomInt(1, 100) <= trap) ? GetRandomInt(min, max) : 0;

		if(entDoorCount > 2){
			countDown = 0;
		}
		flagDoorType = (countDown > change) ? 1 : 0;

		if(GetConVarBool(hPluginEnable) && entDoorGoal > 0){
			GetEntDataVector(entDoorGoal, ofs_doorOrigin, vecGoal);
			CreateTimer(0.25, TimerDoorLock, entDoorGoal, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	CreateTimer(0.25, TimerCheckSafeRoom, client, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action:OnBotPlayerReplace(Handle:event, const String:name[], bool:dontBroadcast)
{
	TimerCheckSafeRoom(INVALID_HANDLE, GetClientOfUserId(GetEventInt(event, "player")));
	return Plugin_Continue;
}

public Action:CommandDEBUG(client, args)
{
	if( GetConVarBool(hDoorLockDebug)
		&& client
		&& IsClientConnected(client)
		&& !IsFakeClient(client)
		&& IsClientInGame(client)
		&& IsPlayerAlive(client)
		&& GetClientTeam(client) == 2
	){
		decl Float:pos[3];
		GetClientAbsOrigin(client, pos);
		PrintToChat(client, "[pos] x:%f, y:%f, z:%f", pos[0], pos[1], pos[2]);
		PrintToChat(client, "[end] x:%f, y:%f, z:%f", vecGoal[0], vecGoal[1], vecGoal[2]);
		PrintToChat(client, "[info] id:%d, dist:%d", entDoorGoal, RoundToFloor(
			   FloatAbs(vecGoal[0] - pos[0])
			 + FloatAbs(vecGoal[1] - pos[1])
			 + FloatAbs(vecGoal[2] - pos[2])
			)
		);

	}
	return Plugin_Handled;
}
