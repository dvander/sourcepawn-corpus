#pragma semicolon 1;

#include <sdktools>
#include <sourcemod>

#define INFECTED_TEAM 3
#define SURVIVOR_TEAM 2
#define INF_TANK 8
#define MAX_PER_SIDE 10
#define VERSION "1.2.2"

new Handle:cvar_tankroar = INVALID_HANDLE;
new Handle:cvar_power = INVALID_HANDLE;
new Handle:cvar_distanceaffected = INVALID_HANDLE;
new Handle:cvar_cooldown = INVALID_HANDLE;
new Handle:cvar_damage = INVALID_HANDLE;
new Handle:cvar_direction = INVALID_HANDLE;
new Handle:cvar_hint = INVALID_HANDLE;
new Handle:cvar_knockback_type = INVALID_HANDLE;
new Handle:cvar_required_hp = INVALID_HANDLE;
new Handle:cvar_tank_stun = INVALID_HANDLE;

new survivor[MAX_PER_SIDE];
new infected[MAX_PER_SIDE];
new cooldown[MAXPLAYERS + 1];
new round = 0;
new bool:pinned[MAXPLAYERS + 1];


public Plugin:myinfo = 
{
	name = "Tank Roar",
	author = "Karma",
	description = "Tank is given a special roar ability that knockbacks survivors.",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1180732#post1180732"
}

public OnPluginStart()
{
	///////////////////////////////////////////
	//Check Whether the Game is Left 4 Dead 2//
	///////////////////////////////////////////
	decl String:gamename[16];
	GetGameFolderName(gamename, sizeof(gamename));
	if (!StrEqual(gamename, "left4dead2", false)) SetFailState("This plugin support Left 4 Dead 2 only.");//plugin for l4d2 only.
	
	/////////
	//Cvars//
	/////////
	CreateConVar("sm_tankroar_version",VERSION, "The Version of this plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_tankroar = CreateConVar("sm_tankroar","2", "Sets the dimensional plane the roar affects.0 - Disable plugin, 1 - Roar only affect survivors on the (relatively) same plane as tank, 2 - Roar affects survivor as long as survivor is set distance away from tank.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_power = CreateConVar("sm_tankroar_power","300", "Sets how powerful the roar is.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_distanceaffected = CreateConVar("sm_tankroar_radius","400", "Sets how near survivor must be in order to be affected by the roar.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_cooldown = CreateConVar("sm_tankroar_cooldown","7", "Sets how long before tank can roar again. Numbers <= 0 indicates roar can only be used once.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_damage = CreateConVar("sm_tankroar_damage","0", "Sets damage dealt to survivors.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_direction = CreateConVar("sm_tankroar_direction","1", "Sets which direction the survivor will be knockbacked. 0 for towards tank. 1 for away from tank. ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_hint = CreateConVar("sm_tankroar_hint","3", "Set the displaying hint type. 0 - disable. 1 - chat. 2 - instructor hint. 3 - both.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_knockback_type = CreateConVar("sm_tankroar_knock_type","1", "Sets the type of knockback. 0 - Jump-like knockback. 1 - Tank punch knockback.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_required_hp = CreateConVar("sm_tankroar_req_hp","6000", "Sets the health the tank must be below before it can use roar.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_tank_stun = CreateConVar("sm_tankroar_stun","2", "Sets how long the tank cannot move/attack after roaring. Input 0 for no stun. Max stun time can only be as long as roar's cooldown.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	///////////////////////////////////
	//Load Translation and cfg files//
	//////////////////////////////////
	LoadTranslations("tankroar.phrases");
	AutoExecConfig(true, "l4d2_tankroar");
	
	////////////////////////////////////////////////
	//Hooking Events for (un)Registering Survivors//
	////////////////////////////////////////////////
	HookEvent("round_freeze_end", Event_RoundEnd);
	HookEvent("player_first_spawn", Event_FirstSpawn);
	HookEvent("player_bot_replace", Event_BotReplacePlayer);
	HookEvent("bot_player_replace", Event_PlayerReplaceBot);
	HookEvent("player_team", Event_SwitchTeam);
	
	
	//////////////////////////////////////////////////////////
	//Hooking Events for Checking Whether Survivor is Pinned//
	//////////////////////////////////////////////////////////
	HookEvent("lunge_pounce", Event_PlayerPinned);
	HookEvent("pounce_end", Event_PlayerPinnedEnd);
	HookEvent("jockey_ride", Event_PlayerPinned);
	HookEvent("jockey_ride_end", Event_PlayerPinnedEnd);
	HookEvent("choke_start", Event_PlayerPinned);
	HookEvent("choke_end", Event_PlayerPinnedEnd);
}

	//////////////////////////////////////////
	//Registering or Unregistering survivors//
	//////////////////////////////////////////
public Action:Event_FirstSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	CreateTimer(0.1, Delayed_FirstSpawnAction, GetClientOfUserId(GetEventInt(event, "userid")));
}

public Action:Delayed_FirstSpawnAction(Handle:timer, any:client){
	//Registers survivors so that we will be able to knockback them 
	//if the tank roars.
	if (IsValidEntity(client) && GetClientTeam(client) == SURVIVOR_TEAM)
	{
		for (new iii = 0; iii< MAX_PER_SIDE; iii++)
		{
			if ((survivor[iii] == 0) && (GetSurvivorIndex(client) == -1) )//save slot is available and client is not already saved.
			{
				survivor[iii] = client;
			}
		}
	} 
	//Registers infected(that are not bots) so that when the round
	//ends and they become the survivors, we will be able to 
	//refer to the new survivors.
	else if (IsValidEntity(client) && GetClientTeam(client) == INFECTED_TEAM && IsClientValid(client))
	{
		for (new iii = 0; iii< MAX_PER_SIDE; iii++)
		{
			if ((infected[iii] == 0) && (GetInfectedIndex(client) == -1) )
			{
				infected[iii] = client;
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_BotReplacePlayer(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	new bot = GetClientOfUserId(GetEventInt(event, "bot"));
	
	//If player leaves survivor team, he/she is unregistered and
	//the bot is registered instead.
	if (GetClientTeam(bot) == SURVIVOR_TEAM)
	{
		for (new iii = 0; iii< MAX_PER_SIDE; iii++)
		{
			if (survivor[iii] == client) 
			{
				survivor[iii] = bot;
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_PlayerReplaceBot(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "bot"));
	new player = GetClientOfUserId(GetEventInt(event, "player"));
	
	//If player joins the survivor team, unregister the bot and
	//registers the player.
	if (GetClientTeam(player) == SURVIVOR_TEAM)
	{
		for (new iii = 0; iii< MAX_PER_SIDE; iii++)
		{
			if (survivor[iii] == client)
			{
				survivor[iii] = player;
			}
		}
	}
	//If a player takes over the tank, display instructor hint to
	//him/her.
	else if (GetClientTeam(player) == INFECTED_TEAM && (GetConVarInt(cvar_tankroar) != 0))
	{
		decl String:entClass[96]; 
		GetEntityNetClass(client, entClass, sizeof(entClass));
		if (StrEqual(entClass, "Tank", false) ) 
		{
			new Handle:pack = CreateDataPack();
			WritePackCell(pack, GetEventInt(event, "player"));
			WritePackString(pack, "Roar");
			WritePackString(pack, "+zoom");
			CreateTimer(0.2, DisplayHint, pack);
		}
	}
	return Plugin_Continue;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast){
	round += 1;
	
	//Round 2 of the map ends. Clear all registers.
	if (round >= 2)
	{
		for (new iii = 0; iii< MAX_PER_SIDE; iii++)
		{
			survivor[iii] = 0;
			infected[iii] = 0;
			round = 0;
		}
	}
	else
	//Round 1 ends and teams switch side. Thus, switch infected's
	//register id to survivor.
	{
		for (new iii = 0; iii< MAX_PER_SIDE; iii++)
		{
			survivor[iii] = infected[iii];
		}
	}
	return Plugin_Continue;
}


public Action:Event_SwitchTeam(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//Infected player switches to survivor team. Thus, remove his
	//id from infected.
	if (GetEventInt(event, "oldteam") == INFECTED_TEAM)
	{
		for (new iii = 0; iii< MAX_PER_SIDE; iii++)
		{
			if (infected[iii] == client)
			{
				infected[iii] = 0;
			}
		}
	}
	//Survivor player switches to infected. Registers him to infected.
	if (GetEventInt(event, "team") == INFECTED_TEAM)
	{
		for (new iii = 0; iii< MAX_PER_SIDE; iii++)
		{
			if ((infected[iii] == 0) && (GetInfectedIndex(client) == -1) && IsClientValid(client) )
			{
				infected[iii] = client;
			}
		}
	}
}

//New map starts. Clear all previous registration.
public OnMapStart(){
	for (new iii = 0; iii< MAX_PER_SIDE; iii++)
	{
		survivor[iii] = 0;
		infected[iii] = 0;
	}
}

//Infected player leaves game. Unregisters him.
//public OnClientDisconnect(client){	
//	if (GetClientTeam(client) == INFECTED_TEAM)
//	{
//		for (new iii = 0; iii< MAX_PER_SIDE; iii++)
//		{
//			if (infected[iii] == client) 
//			{
//				infected[iii] = 0;
//			}
//		}
//	}
//}

public Action:Event_PlayerPinned(Handle:event, const String:name[], bool:dontBroadcast){
	pinned[GetClientOfUserId(GetEventInt(event, "victim"))] = true;
}

public Action:Event_PlayerPinnedEnd(Handle:event, const String:name[], bool:dontBroadcast){
	pinned[GetClientOfUserId(GetEventInt(event, "victim"))] = false;
}


public Action:DisplayHint(Handle:timer, Handle: pack){ 
	decl String: msg[256], String: bind[16], String: msgphrase[256];
	
	ResetPack(pack);
	new client = GetClientOfUserId(ReadPackCell(pack));
	ReadPackString(pack, msg, sizeof(msg));
	ReadPackString(pack, bind, sizeof(bind));
	CloseHandle(pack);
	
	new hintType = GetConVarInt(cvar_hint);
	decl String:tempString[128];
	IntToString(GetConVarInt(cvar_required_hp), tempString, sizeof(tempString));
	FormatEx(msgphrase, sizeof(msgphrase), "%t if your health is below %s", msg, tempString);
	
	if (hintType == 1 || hintType == 3)
	{
		PrintToChat(client,  "\x03[Hint]\x01 %s.", msgphrase);
	}

	if (hintType == 2 || hintType == 3)
	{
		decl instrHintEnt, String:name[32];
		
		instrHintEnt = CreateEntityByName("env_instructor_hint");
		FormatEx(name, sizeof(name), "TRIH%d", client);
		DispatchKeyValue(client, "targetname", name);
		DispatchKeyValue(instrHintEnt, "hint_target", name);
		
		DispatchKeyValue(instrHintEnt, "hint_range", "0.01");
		DispatchKeyValue(instrHintEnt, "hint_color", "255 255 255");
		DispatchKeyValue(instrHintEnt, "hint_caption", msgphrase);
		DispatchKeyValue(instrHintEnt, "hint_icon_onscreen", "use_binding");
		DispatchKeyValue(instrHintEnt, "hint_binding", bind);
		DispatchKeyValue(instrHintEnt, "hint_timeout", "6.0");
		
		ClientCommand(client, "gameinstructor_enable 1");
		DispatchSpawn(instrHintEnt);
		AcceptEntityInput(instrHintEnt, "ShowHint");
		
		CreateTimer(6.0, DisableInstructor, client);
	}
} 

public Action:DisableInstructor(Handle:timer, any:client){
	ClientCommand(client, "gameinstructor_enable 0");
	DispatchKeyValue(client, "targetname", "");
}

ApplyDamage(victim, damage, attacker=0, type=0, String:weapon[]=""){
	if((victim>0) && (damage>0) && (IsClientInGame(victim)) && (IsPlayerAlive(victim)))
	{		
		decl String: s_dmg[16];
		IntToString(damage, s_dmg, sizeof(s_dmg));
		decl String: s_type[32];
		IntToString(type, s_type, sizeof(s_type));
		
		new PtHurtEnt=CreateEntityByName("point_hurt");
		if(PtHurtEnt > 0)
		{
			DispatchKeyValue(victim,"targetname","TRDD");
			DispatchKeyValue(PtHurtEnt,"DamageTarget","TRDD");
			DispatchKeyValue(PtHurtEnt,"Damage",s_dmg);
			DispatchKeyValue(PtHurtEnt,"DamageType",s_type);
			if(!StrEqual(weapon,"")) DispatchKeyValue(PtHurtEnt,"classname",weapon);
			
			DispatchSpawn(PtHurtEnt);
			if (!(attacker>0)) attacker = -1;
			AcceptEntityInput(PtHurtEnt,"Hurt", attacker);
			
			DispatchKeyValue(victim,"targetname","");
			RemoveEdict(PtHurtEnt);
		}
	}
}


stock Fling(target, Float:vector[3], attacker, Float:stunTime = 3.0)
{
	new Handle:sdkCall = INVALID_HANDLE;
	new Handle:configFile = LoadGameConfigFile("l4d2tankroar");
	
	StartPrepSDKCall(SDKCall_Player);
	

	if(!PrepSDKCall_SetFromConf(configFile, SDKConf_Signature, "CTerrorPlayer_Fling"))
		LogError("Fling not found.");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);

	sdkCall = EndPrepSDKCall();
	if(sdkCall == INVALID_HANDLE)
		LogError("Could not prep the Fling function");
	
	SDKCall(sdkCall, target, vector, 96, attacker, stunTime);//96
}



public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon){
	if ((buttons & IN_ZOOM) && (GetConVarInt(cvar_tankroar) != 0)) {
		if (IsClientValid(client) && (GetZombieClass(client) == INF_TANK) && (GetConVarInt(cvar_tankroar)) && (!cooldown[client])) 
		{ 
			if (GetEntProp(client, Prop_Data, "m_iHealth") <= GetConVarInt(cvar_required_hp) && (IsPlayerAlive(client)))
			{
				TankRoar(client);
				
				if (GetConVarFloat(cvar_cooldown)  > 0){
					CreateTimer(GetConVarFloat(cvar_cooldown), Reset, client);
				}
				cooldown[client] = true;
			}
		}
	}
}


TankRoar(tank){
	new Float:power = GetConVarFloat(cvar_power);
	
	decl Float:tankPos[3];
	GetClientEyePosition(tank, tankPos);
	EmitSoundToAll("player/tank/voice/yell/tank_yell_12.wav", tank);
	
	new Float:stun = GetConVarFloat(cvar_tank_stun);
	new Float:cd = GetConVarFloat(cvar_cooldown);
	if (stun>cd) stun = cd;
	if (stun>0){
		SetEntProp(tank, Prop_Send, "m_fFlags", GetEntityFlags(tank) | FL_FROZEN);
		SetEntProp(tank, Prop_Data, "m_nSequence", 53);
		CreateTimer(stun, UnstunTank, tank);
	}
	
	for (new iii = 0; iii < MAX_PER_SIDE; iii++)
	{
		if (IsValidEntity(survivor[iii]) && (survivor[iii] != 0))
		{
			if (!GetEntProp(survivor[iii], Prop_Send, "m_isIncapacitated") && !pinned[survivor[iii]])
			{
				decl Float:svPos[3];
				GetClientEyePosition(survivor[iii], svPos);
				
				decl Float:distance[3];
				
				distance[0] = (tankPos[0] - svPos[0]);
				distance[1] = (tankPos[1] - svPos[1]);
				distance[2] = (tankPos[2] - svPos[2]);
				
				if (CheckDistance(distance))
				{
					decl Float: addAmount[3];
					decl Float: resultant[3];
					decl Float: svVector[3];
					decl Float: ratio[2];
					
					ratio[0] =  FloatDiv(distance[0], SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]));//Ratio x/hypo
					ratio[1] =  FloatDiv(distance[1], SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]));//Ratio y/hypo
					
					GetEntPropVector(survivor[iii], Prop_Data, "m_vecVelocity", svVector);
					
					addAmount[0] = FloatMul( ratio[0]*Direction(), power);//multiply negative = away from tank. multiply positive = towards tank.
					addAmount[1] = FloatMul( ratio[1]*Direction(), power);
					addAmount[2] = power;
					
					resultant[0] = FloatAdd(addAmount[0], svVector[0]);//current velocity + added velocity
					resultant[1] = FloatAdd(addAmount[1], svVector[1]);
					resultant[2] = power;
					
					
					//SetEntProp(survivor[iii], Prop_Data, "m_nSequence", 803);
					
					switch (GetConVarInt(cvar_knockback_type))
					{
						case 1: Fling(survivor[iii],addAmount,tank);
						default: TeleportEntity(survivor[iii], NULL_VECTOR, NULL_VECTOR, resultant);
					}
					
					new dmg = GetConVarInt(cvar_damage);
					
					while (dmg>100)
					{
						ApplyDamage(survivor[iii], 100, tank, 0, "weapon tank_claw");
						dmg -= 100;
					}
					ApplyDamage(survivor[iii], dmg, tank, 0, "weapon tank_claw");
				}
			}
		}
		else
		{
			survivor[iii] = 0;
		}
	}
}

public Action:UnstunTank(Handle:timer, any:tank){
	SetEntProp(tank, Prop_Send, "m_fFlags", GetEntityFlags(tank) & ~FL_FROZEN);
}


bool:CheckDistance(Float:distance[3]){
	new roarType = GetConVarInt(cvar_tankroar);
	
	new Float:distanceaffected = GetConVarFloat(cvar_distanceaffected);
	
	switch (roarType)
	{
		case 0: return false;
		case 1: 
		{
			if ((SquareRoot( FloatMul(distance[0],distance[0]) + FloatMul(distance[1],distance[1]) ) <= distanceaffected) &&  (Absolute(distance[2]) <= 50) ) return true;
		}
		default:
		{
			if (SquareRoot( FloatMul(distance[0],distance[0]) + FloatMul(distance[1],distance[1]) + FloatMul(distance[2],distance[2])) <= distanceaffected) return true;
		}
	}
	return false;
}

Float:Absolute(Float:number)
{
	if (number < 0) return -number;
	return number;
}


bool:IsClientValid(client)
{ 	if (client <= 0) return false;
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	//if (IsFakeClient(client)) return false; //support for bots
	return true;
}


Direction(){
	new direction = GetConVarInt(cvar_direction);
	if (direction == 0) return 1;
	return -1;
}

public Action:Reset(Handle:timer, any:client){
	cooldown[client] = false;
}

GetZombieClass(client){
	if (GetClientTeam(client) == INFECTED_TEAM){
		return GetEntProp(client, Prop_Send, "m_zombieClass");
	}
	return -1;
}

GetSurvivorIndex(client)
{
	for(new iii = 0; iii < MAX_PER_SIDE; iii++)
	{
		if (survivor[iii] == client)
			return iii;
	}
	return -1;
}

GetInfectedIndex(client)
{
	for(new iii = 0; iii < MAX_PER_SIDE; iii++)
	{
		if (infected[iii] == client)
			return iii;
	}
	return -1;
}

/*
db(int)
{
decl String:str[100];
IntToString(int, str, 100);
PrintToServer(str);}

*/