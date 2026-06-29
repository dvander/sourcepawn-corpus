#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define SOUND_BLIP		"buttons/blip1.wav"
#define SOUND_BLIP2		"hl1/fvox/beep.wav"
#define SOUND_GONG		"ambient/alarms/warningbell1.wav"
#define SOUND_HIT		"buttons/button10.wav"
#define SOUND_HIT_SELF		"weapons/crossbow/hitbod2.wav"
#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"

new Handle:sm_tagfreeze_min_players = INVALID_HANDLE;
new Handle:sm_tagfreeze_beacon_delay = INVALID_HANDLE;
new Handle:sm_tagfreeze_beacon_makesound = INVALID_HANDLE;
new Handle:sm_tagfreeze_beacon_radius = INVALID_HANDLE;
new Handle:sm_tagfreeze_beacon_volume = INVALID_HANDLE;
new Handle:sm_tagfreeze_freeze_volume = INVALID_HANDLE;
new Handle:sm_tagfreeze_beacon_enable = INVALID_HANDLE;
new Handle:sm_tagfreeze_low_msg_enable = INVALID_HANDLE;
new Handle:sm_tagfreeze_chosen_msg_enable = INVALID_HANDLE;
new Handle:sm_tagfreeze_chosen_chat_enable = INVALID_HANDLE;
new Handle:sm_tagfreeze_freeze_time = INVALID_HANDLE;
new Handle:sm_tagfreeze_freeze_beacon_radius = INVALID_HANDLE;
new Handle:sm_tagfreeze_unfreeze_message = INVALID_HANDLE;
new Handle:sm_tagfreeze_points_attacker = INVALID_HANDLE;
new Handle:sm_tagfreeze_points_hit_it = INVALID_HANDLE;
new Handle:sm_tagfreeze_points_get_hit = INVALID_HANDLE;
new Handle:sm_tagfreeze_points_victim = INVALID_HANDLE;
new Handle:sm_tagfreeze_deaths_victim = INVALID_HANDLE;
new Handle:sm_tagfreeze_takepoints_sec = INVALID_HANDLE;
new Handle:sm_tagfreeze_endlooser_hudmsg_enable = INVALID_HANDLE;
new Handle:sm_tagfreeze_endlooser_hudmsg_text = INVALID_HANDLE;
new Handle:sm_tagfreeze_points_endlooser = INVALID_HANDLE;
new Handle:sm_tagfreeze_carrier_selfkill_msg = INVALID_HANDLE;
new Handle:sm_tagfreeze_points_help_it = INVALID_HANDLE;

new Handle:synch1;

new bool:canStart=false;
new bool:started=false;
new rounds=0;
new bool:tp;

//beacon
new g_BeamSprite        = -1;
new g_HaloSprite        = -1;
new beaconRed[4] = {255, 0, 0, 255};
new beaconBlu[4] = {0, 0, 255, 255};
new whiteColor[4]	= {255, 255, 255, 255};
new greyColor[4]	= {128, 128, 128, 255};

new tagged=-1;
new bool:taggedTP[MAXPLAYERS+1];

new Handle:assholes;

//take points timer
new Handle:takePT=INVALID_HANDLE;
new PTseconds;

new bool:intermissionCalled;

new ClientTeams[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "tag freeze gamemode",
	author = "Alienmario",
	description = "tag freeze gamemode",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	sm_tagfreeze_min_players = CreateConVar("sm_tagfreeze_min_players","2","Minimum players needed for the game to start",FCVAR_PLUGIN);	
	sm_tagfreeze_beacon_delay = CreateConVar("sm_tagfreeze_beacon_delay","1.0","How fast is the beacon (less=faster)",FCVAR_PLUGIN);	
	sm_tagfreeze_beacon_radius = CreateConVar("sm_tagfreeze_beacon_radius","650.0","How far the beacon travels",FCVAR_PLUGIN);	
	sm_tagfreeze_beacon_makesound = CreateConVar("sm_tagfreeze_beacon_makesound","1","Should beacon make sound?",FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	sm_tagfreeze_beacon_enable = CreateConVar("sm_tagfreeze_beacon_enable","1","Enable beacon",FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	sm_tagfreeze_low_msg_enable = CreateConVar("sm_tagfreeze_low_msg_enable","1","Show HUD message when there aren't enough players to start",FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	sm_tagfreeze_chosen_msg_enable = CreateConVar("sm_tagfreeze_chosen_msg_enable","1","Show HUD message when someone gets tagged",FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	sm_tagfreeze_chosen_chat_enable = CreateConVar("sm_tagfreeze_chosen_chat_enable","1","Show chat message when someone gets tagged",FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	sm_tagfreeze_freeze_time = CreateConVar("sm_tagfreeze_freeze_time","6.0","How long should newly tagged player be frozen.",FCVAR_PLUGIN, true, 0.0);	
	sm_tagfreeze_freeze_beacon_radius = CreateConVar("sm_tagfreeze_freeze_beacon_radius", "600", "Sets the radius of beacon when someone is tagged", FCVAR_PLUGIN, true, 50.0, true, 3000.0);
	sm_tagfreeze_unfreeze_message = CreateConVar("sm_tagfreeze_unfreeze_message", "You are unfrozen. Go tag someone!", "Message sent to unfrozen player", FCVAR_PLUGIN);
	sm_tagfreeze_points_attacker = CreateConVar("sm_tagfreeze_points_attacker", "5", "How many points does the 'attacker' get. Negative values allowed", FCVAR_PLUGIN);
	sm_tagfreeze_points_victim = CreateConVar("sm_tagfreeze_points_victim", "-1", "How many points does the 'victim' or new 'it' get. Negative values allowed", FCVAR_PLUGIN);
	sm_tagfreeze_points_hit_it = CreateConVar("sm_tagfreeze_points_hit_it", "1", "How many points does player get, when he/she attacks 'it'", FCVAR_PLUGIN);
	sm_tagfreeze_points_get_hit = CreateConVar("sm_tagfreeze_points_get_hit", "-1", "How many points does player get, when he/she's 'it' and gets crowbared. Negative values allowed", FCVAR_PLUGIN);
	sm_tagfreeze_points_help_it = CreateConVar("sm_tagfreeze_points_help_it", "1", "How many points does player get, when he/she helps a teammate in teamplay mode", FCVAR_PLUGIN);
	sm_tagfreeze_deaths_victim = CreateConVar("sm_tagfreeze_deaths_victim", "1", "How many deaths does the 'victim' or new 'it' get. Negative values allowed", FCVAR_PLUGIN);
	sm_tagfreeze_points_endlooser = CreateConVar("sm_tagfreeze_points_endlooser", "0", "How many points does the looser get on game end. Negative values allowed", FCVAR_PLUGIN);
	sm_tagfreeze_endlooser_hudmsg_enable = CreateConVar("sm_tagfreeze_endlooser_hudmsg_enable", "1", "Enable hud message on game end, showing who lost and points taken", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	sm_tagfreeze_endlooser_hudmsg_text = CreateConVar("sm_tagfreeze_endlooser_hudmsg_text", "", "Message on game end; Example: 'You loose NAME LINE POINTS points' ;; NAME = the IT's name; LINE = new line; POINTS = points lost. These are case sensitive and will be automatically replaced.", FCVAR_PLUGIN);
	sm_tagfreeze_beacon_volume = CreateConVar("sm_tagfreeze_beacon_volume", "70", "Volume of the beacon in dB, 0=NONE, 180=ROCKET, more at:docs.sourcemod.net/api/index.php?fastload=file&id=34&", FCVAR_PLUGIN, true, 0.0 );
	sm_tagfreeze_freeze_volume = CreateConVar("sm_tagfreeze_freeze_volume", "0.3", "Volume of the freeze sound, 0.0=min, 1.0=Normal", FCVAR_PLUGIN, true, 0.0 );
	sm_tagfreeze_carrier_selfkill_msg = CreateConVar("sm_tagfreeze_carrier_selfkill_msg", "Good luck with that", "Reply message when the carrier tries to kill himself using console", FCVAR_PLUGIN);
	sm_tagfreeze_takepoints_sec = CreateConVar("sm_tagfreeze_takepoints_sec", "30", "How long until take -1 points from it", FCVAR_PLUGIN, true, 0.0);
	
	AutoExecConfig()
	
	HookEvent("player_death", Event_Death, EventHookMode_Pre);
	HookEvent("player_spawn", Event_Spawn);
	HookEvent("player_team", Event_Team);
	AddCommandListener(BlockJT, "jointeam"); 
	AddCommandListener(BlockKill, "kill"); 
	AddCommandListener(BlockKill, "explode"); 
	HookUserMessage(GetUserMessageId("VGUIMenu"),VguiEnd);
	synch1=CreateHudSynchronizer();
	
	assholes=CreateArray(32);
}

public OnMapStart(){ 
	ClearArray(assholes);

	intermissionCalled=false;
	
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt", true); 
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt", true);
	
	PrecacheSound(SOUND_BLIP, true);
	PrecacheSound(SOUND_BLIP2, true);
	PrecacheSound(SOUND_GONG, true);
	PrecacheSound(SOUND_FREEZE, true);
	PrecacheSound(SOUND_HIT, true);
	PrecacheSound(SOUND_HIT_SELF, true);
	
	new Handle:hTp=FindConVar("mp_teamplay");
	if(hTp==INVALID_HANDLE){
		SetFailState("failed to find mp_teamplay convar");
	}else{
		tp=GetConVarBool(hTp);
		CloseHandle(hTp);
	}
	takePT=INVALID_HANDLE;
	tagged=-1;
	canStart=false;
	started=false;
	rounds=0;
	for( new i=0;i<=MAXPLAYERS;i++ ){
		taggedTP[i]=false;
	}
	CreateTimer(0.0, startT, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(GetConVarFloat(sm_tagfreeze_beacon_delay), makeBeacon, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:VguiEnd(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init){
    if(intermissionCalled) return;

    new String:type[10];
    BfReadString(bf, type, sizeof(type));

    if(strcmp(type, "scores", false) == 0)
    {
        if(BfReadByte(bf) == 1 && BfReadByte(bf) == 0)
        {
            intermissionCalled = true;
            CreateTimer(0.05, endgame)
        }
    }
}

public Action:endgame(Handle:timer){
	if(IsClientValid(tagged)){
		modifyScore(tagged, GetConVarInt(sm_tagfreeze_points_endlooser));
		if(GetConVarBool(sm_tagfreeze_endlooser_hudmsg_enable)){
			decl String:buffer[200]; new String:nmBuf[34];
			GetConVarString(sm_tagfreeze_endlooser_hudmsg_text, buffer, sizeof (buffer));	
			GetClientName(tagged, nmBuf, sizeof(nmBuf));
			ReplaceString(buffer, sizeof(buffer), "NAME", nmBuf);
			IntToString(GetConVarInt(sm_tagfreeze_points_endlooser), nmBuf, sizeof(nmBuf));
			ReplaceString(buffer, sizeof(buffer), "POINTS", nmBuf);
			ReplaceString(buffer, sizeof(buffer), "LINE", "\n");
			PrintToChatAll(buffer);
			SetHudTextParams(-1.0, 0.2, 10.0, 200,230,100,255);
	 		for(new i=1;i<=MaxClients;i++){
				if(IsClientValid(i)){
					ShowSyncHudText(i, synch1, buffer);
				}
			}
		}
	}
}

public Action:startT(Handle:timer){
	if(!checkStart()){
		canStart=true;
		CreateTimer(1.0, startHudT, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:restartRoundTimer(Handle:timer, any:userid){
	new client = GetClientOfUserId(userid);
	if(IsClientValid(client)) {
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		DispatchSpawn(client);
	}
	return Plugin_Handled;
}


public Action:makeBeacon(Handle:timer){
	if (!tp){
		if(tagged!=-1 && GetConVarBool(sm_tagfreeze_beacon_enable)){
			decl Float:pos[3];
			GetClientAbsOrigin(tagged, pos);
			pos[2]+=10.0;
			TE_SetupBeamRingPoint(pos, 10.0, GetConVarFloat(sm_tagfreeze_beacon_radius), g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, beaconRed, 10, 0);
			TE_SendToAll();
			if(GetConVarBool(sm_tagfreeze_beacon_makesound)){
				for(new i=1;i<=MaxClients;i++){
					if(IsClientValid(i) && i!=tagged){
						EmitSoundToClient(i, SOUND_BLIP, tagged, _, GetConVarInt(sm_tagfreeze_beacon_volume));
					}
				}
			}
		}
	}else if (GetConVarBool(sm_tagfreeze_beacon_enable)){
		for(new i=1;i<=MaxClients;i++){
			if(IsClientValid(i) && taggedTP[i]){
				decl Float:pos[3];
				GetClientAbsOrigin(i, pos);
				pos[2]+=10.0;
				new team=GetClientTeam(i);
				if(team==2){
					TE_SetupBeamRingPoint(pos, 10.0, GetConVarFloat(sm_tagfreeze_beacon_radius), g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, beaconBlu, 10, 0);
				}else if (team==3){
					TE_SetupBeamRingPoint(pos, 10.0, GetConVarFloat(sm_tagfreeze_beacon_radius), g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, beaconRed, 10, 0);
				}
				TE_SendToAll();
 				for(new j=1;j<=MaxClients;j++){
					if(IsClientValid(j) && j!=i){
						if(team==2){
							EmitSoundToClient(j, SOUND_BLIP, i, _, GetConVarInt(sm_tagfreeze_beacon_volume));
						}else if (team==3){
							EmitSoundToClient(j, SOUND_BLIP2, i, _, GetConVarInt(sm_tagfreeze_beacon_volume));
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:WeaponCanSwitchTo(client, weapon){
	new String:sWeapon[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
	if(!tp){
		if(!StrEqual(sWeapon, "weapon_crowbar")){
			delEnt(weapon);
			return Plugin_Handled;
		}else return Plugin_Continue;
	}else{
		new team=GetClientTeam(client);
		if(team==2){
			if(!StrEqual(sWeapon, "weapon_stunstick")){
				delEnt(weapon);
				return Plugin_Handled;
			}else{
				return Plugin_Continue;
			}
		}
		if(team==3){
			if(StrEqual(sWeapon, "weapon_crowbar")){
				return Plugin_Continue;
			}else{
				delEnt(weapon);
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Handled;
}

public Action:Event_Spawn (Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsFakeClient(client)) giveWeapon(client);
	if(tp){
		if(taggedTP[client]){ 
			CreateTimer(0.0, frDelay, client); //fix of: teamchange not blocked bug using cl_playermodel
		}
	}
	new String:buffer[32]; GetClientAuthString(client, buffer, sizeof(buffer));
	if(FindStringInArray(assholes, buffer)!=-1){ //cheaters
		//CreateTimer(0.0, spDelay, client); //make him unable to move
		KickClient(client, "You can't join until next map"); //kick him
	}
	return Plugin_Continue;
}
public Action:frDelay(Handle:timer, any:client){
	freeze(client);
}
public Action:spDelay(Handle:timer, any:client){
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0);
	PrintToChat(client, "You can't move until next map");
}

public Action:BlockKill(client, const String:command[], argc) {
	if(IsClientValid(client)){
		decl String:buffer[200]; GetConVarString(sm_tagfreeze_carrier_selfkill_msg, buffer, sizeof(buffer));
		PrintToChat(client, buffer);
	}
	return Plugin_Handled;
} 

public Action:BlockJT(client, const String:command[], argc) {
	return Plugin_Handled;
} 

giveWeapon(client){
	new String:weapon[32];
	new team=GetClientTeam(client);
	if(team==2){
		weapon="weapon_stunstick";
	}else if(team==3 || !tp){
		weapon="weapon_crowbar";
	}else return;
	
	new ent = CreateEntityByName(weapon);
	if (ent == -1) return;
	
	DispatchSpawn(ent);
	EquipPlayerWeapon(client, ent);
}

public OnClientPutInServer(client){

	if(canStart) checkStart();
	SDKHook(client, SDKHook_WeaponCanUse, WeaponCanSwitchTo);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage (victim, &attacker, &inflictor, &Float:damage, &damagetype){
	if(!started) return Plugin_Handled;
	if(!tp){
		if(IsClientValid(attacker) && IsClientValid(victim) ){
			if(damagetype & DMG_BLAST) return Plugin_Handled;
			if(attacker==tagged && victim!=tagged) {
				modifyScore(attacker, GetConVarInt(sm_tagfreeze_points_attacker));
				makeTagged(victim, false);
			} else if (victim==tagged && attacker != tagged) {
				/* new MoveType:movetype=GetEntityMoveType(tagged);
				if(movetype!=MOVETYPE_NONE){ */
/* 				new iFlags = GetEntityFlags(tagged);
				if(!(iFlags & FL_FROZEN)){ */
				if(GetEntPropFloat(tagged, Prop_Data, "m_flLaggedMovementValue")!=0.0){
					modifyScore(attacker, GetConVarInt(sm_tagfreeze_points_hit_it));
					modifyScore(victim, GetConVarInt(sm_tagfreeze_points_get_hit));
					EmitSoundToClient(attacker, SOUND_HIT);
					EmitSoundToClient(victim, SOUND_HIT_SELF);
				}
			}
		}
	}else{
		if(IsClientValid(attacker) && IsClientValid(victim) ){
			if(damagetype & DMG_BLAST) return Plugin_Handled;
			
			new teamAttacker=GetClientTeam(attacker);
			new teamVictim=GetClientTeam(victim);
			if(teamAttacker==teamVictim){
				if(taggedTP[victim]){
					modifyScore(attacker, GetConVarInt(sm_tagfreeze_points_help_it));
					PrintToChat(attacker, "You unfroze %N", victim);
					PrintToChat(victim, "%N unfroze you", attacker);
					unFreeze(INVALID_HANDLE, GetClientUserId(victim));
				}
			}else{
				if(!taggedTP[victim]){
					modifyScore(attacker, GetConVarInt(sm_tagfreeze_points_attacker));
					makeTagged(victim, false);
				}
			}
		}
	}
	if(!IsClientValid(attacker) && IsClientValid(victim) ){
			return Plugin_Continue;
	}
	return Plugin_Handled;
}

bool:checkStart(){
	if(GetRealClientCount()>=GetConVarInt(sm_tagfreeze_min_players) && NobodyDownloading()){
		start();
		canStart=false;
		return true;
	}
	return false;
}

bool:NobodyDownloading(){
	if(GetRealClientCount(false)-GetRealClientCount()==0) return true;
	return false;
}

start(){
	CreateTimer(0.1, firstTagDelay, _, TIMER_FLAG_NO_MAPCHANGE);
	started=true;
	EmitSoundToAll(SOUND_GONG);
	for(new i=1;i<=MaxClients;i++){
		goHud(i);
	}
}

public Action:firstTagDelay(Handle:timer){
	if(!tp)	makeTagged(chooseRandomPlayer());
	/* 	else{
		for(new i=1;i<=MaxClients;i++){
			unFreeze (INVALID_HANDLE, i);
		}
	} */
}

stock makeTagged(client, bool:randomised=true){
	if(!tp){
		if(client==0) { //Restart
			tagged=-1;
			startT(INVALID_HANDLE);
			return;
		}
		if (IsClientValid (tagged))	SetEntityRenderColor(tagged, 255, 255, 255, 255);
		tagged=client;
		if(!randomised){
			modifyScore(client, GetConVarInt(sm_tagfreeze_points_victim));
			modifyDeaths(client, GetConVarInt(sm_tagfreeze_deaths_victim));
		}
		freeze(client);
		
		if(takePT!=INVALID_HANDLE){
			KillTimer(takePT);
			takePT=INVALID_HANDLE;
		}
		PTseconds=0;
		takePT=CreateTimer(1.0, doPoints, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}else{
		taggedTP[client]=true;
		modifyScore(client, GetConVarInt(sm_tagfreeze_points_victim));
		modifyDeaths(client, GetConVarInt(sm_tagfreeze_deaths_victim));
		freeze(client);
		if(checkEndTP()) {
			return;
		}
	}
	if(GetConVarBool(sm_tagfreeze_chosen_msg_enable)){
		for(new i=1;i<=MaxClients;i++){
			taggedHud(i, client);
		}
	}	
	if(GetConVarBool(sm_tagfreeze_chosen_chat_enable)){
		PrintToChatAll( "%N is tagged!", client);
	}
}

/* quickFreezeAll(){
	for (new i; i<=MaxClients;i++){
		if(!IsClientValid(i)) continue;
 		new iFlags = GetEntityFlags(i);
		if(!(iFlags & FL_FROZEN))
			iFlags |= FL_FROZEN;
		SetEntityFlags(i, iFlags);
		SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 0.0);
	}
} */

bool:checkEndTP(){
 	new team2,team3; //team count
	new fTeam2,fTeam3; //frozen count
	
	for(new i; i<=MaxClients;i++){
		if(!IsClientValid(i)) continue;
		if(GetClientTeam(i)==2){
			team2++;
			if(taggedTP[i]) fTeam2++;
		}
		else if (GetClientTeam(i)==3){
			team3++;
			if(taggedTP[i]) fTeam3++;
		}
	}
	
	if(fTeam2==team2 && team2!=0){
		PrintToChatAll("\x07FF0000Red Team has won!");
		SetHudTextParams(-1.0, 0.8, 10.0, 255,0,0,255);
		SetTeamScore(3, GetTeamScore(3)+1);
		for(new i=1;i<=MaxClients;i++){
			if(IsClientValid(i)) ShowSyncHudText(i, synch1, "Red Team has won!");
		}
		
		if(rounds>=4){
			gameEnd();
		}else{
			started=false;
			rounds++;
			for( new i=0;i<=MAXPLAYERS;i++ ){
				taggedTP[i]=false;
				if(IsClientValid(i)){
					while (GetPlayerWeaponSlot(i, 0)!=-1){
						new wep=GetPlayerWeaponSlot(i, 0);
						RemovePlayerItem(i,  wep);
						delEnt(wep);
					}
					CreateTimer(7.0, restartRoundTimer, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			CreateTimer(7.0, startT, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		return true;
	}
	if(fTeam3==team3 && team3!=0){
		PrintToChatAll("\x070050FFBlue Team has won!");
		SetHudTextParams(-1.0, 0.8, 10.0, 0,206,209,255);
		for(new i=1;i<=MaxClients;i++){
			if(IsClientValid(i)) ShowSyncHudText(i, synch1, "Blue Team has won!");
		}
		SetTeamScore(2, GetTeamScore(2)+1);
		if(rounds>=4){
			gameEnd();
		}else{
			started=false;
			rounds++;
			for( new i=0;i<=MAXPLAYERS;i++ ){
				taggedTP[i]=false;
				if(IsClientValid(i)){
					while (GetPlayerWeaponSlot(i, 0)!=-1){
						new wep=GetPlayerWeaponSlot(i, 0);
						RemovePlayerItem(i,  wep);
						delEnt(wep);
					}
					CreateTimer(7.0, restartRoundTimer, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			CreateTimer(7.0, startT, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		return true;
	}
	return false;
}

gameEnd(){
	new game_end = FindEntityByClassname(-1, "game_end");

	if (game_end == -1) {
			game_end = CreateEntityByName("game_end");
	}
	AcceptEntityInput(game_end, "EndGame");
}

public Action:doPoints(Handle:timer, any:client){
	if(IsClientValid(tagged)){
		if(++PTseconds>=GetConVarInt(sm_tagfreeze_takepoints_sec)){
			PTseconds=0;
			modifyScore(tagged, -1); 
		}
	}
	return Plugin_Continue;
}

taggedHud(showTo, client){
	if(IsClientValid(showTo) && IsClientValid(client))
	{
		SetHudTextParams(-1.0, 0.2, 5.0, 200,230,100,255);
		ShowSyncHudText(showTo, synch1, "%N is tagged!", client);
	}
}

chooseRandomPlayer(){
	if(GetRealClientCount()<1) return 0;
	
	new r;
	do{
		r=GetRandomInt(1, MaxClients);
	}while(!IsClientValid(r));
	return r;
}

freeze(client){
	while (GetPlayerWeaponSlot(client, 0)!=-1){
		new wep=GetPlayerWeaponSlot(client, 0);
		RemovePlayerItem(client,  wep);
		delEnt(wep);
	}
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	pos[2] += 10;

	TE_SetupBeamRingPoint(pos, 10.0, GetConVarFloat(sm_tagfreeze_freeze_beacon_radius) / 3.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos, 10.0, GetConVarFloat(sm_tagfreeze_freeze_beacon_radius) / 3.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, whiteColor, 10, 0);
	TE_SendToAll();
	
/* 	new iFlags = GetEntityFlags(client);
	if(!(iFlags & FL_FROZEN))
		iFlags |= FL_FROZEN;
	SetEntityFlags(client, iFlags); */
	
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0);
	//SetEntityMoveType(client, MOVETYPE_NONE);

	EmitAmbientSound(SOUND_FREEZE, pos, client, SNDLEVEL_RAIDSIREN, SND_CHANGEVOL , GetConVarFloat(sm_tagfreeze_freeze_volume));
	
	if(!tp){
		SetEntityRenderColor(client, 0, 128, 255, 135);
		CreateTimer( GetConVarFloat(sm_tagfreeze_freeze_time), unFreeze, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:unFreeze(Handle:timer, any:userid){
	new client=GetClientOfUserId(userid);
	if (IsClientValid(client))
	{
		decl Float:pos[3];
		GetClientAbsOrigin(client, pos);
		pos[2] += 10;	
		
		EmitAmbientSound(SOUND_FREEZE, pos, client, SNDLEVEL_RAIDSIREN, SND_CHANGEVOL , GetConVarFloat(sm_tagfreeze_freeze_volume));
	
		TE_SetupBeamRingPoint(pos, 10.0, GetConVarFloat(sm_tagfreeze_freeze_beacon_radius) / 3.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(pos, 10.0, GetConVarFloat(sm_tagfreeze_freeze_beacon_radius) / 3.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, whiteColor, 10, 0);
		TE_SendToAll();
		
/*		SetEntityMoveType(client, MOVETYPE_WALK);
		
 		new iFlags = GetEntityFlags(client);
		if(iFlags & FL_FROZEN)
			iFlags &= ~FL_FROZEN;
		SetEntityFlags(client, iFlags); */
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		
		if(!tp){
		SetEntityRenderColor(client, 255, 0, 0, 255);
		}
		
		taggedTP[client]=false;
		PrintToChatAll("%N got unfrozen", client);
		
		decl String:buffer[150];
		GetConVarString(sm_tagfreeze_unfreeze_message, buffer, sizeof(buffer));
		PrintToChat(client, buffer);
		giveWeapon(client);
	}
}

public Action:startHudT(Handle:timer){
	if(canStart){
		if(!checkStart()){
			if(GetConVarBool(sm_tagfreeze_low_msg_enable)){
				new needed=GetConVarInt(sm_tagfreeze_min_players)-GetRealClientCount();
				if(needed<1){
					for(new i=1;i<=MaxClients;i++){
						startHud2(i);
					}
				}else{
					for(new i=1;i<=MaxClients;i++){
						startHud(i, needed);
					}
				}
			}
			return Plugin_Continue;
		}else{
			return Plugin_Stop;
		}
	}else{
		return Plugin_Stop;
	}
}


startHud(client, needed){
	if(IsClientValid(client))
	{
		SetHudTextParams(-1.0, 0.35, 1.0, 200,230,100,255);
		ShowSyncHudText(client, synch1, "Need %d more player(s) to start\nTag/freeze", needed);
	}
}
startHud2(client){
	if(IsClientValid(client))
	{
		SetHudTextParams(-1.0, 0.35, 1.0, 200,230,100,255);
		ShowSyncHudText(client, synch1, "Waiting for all players to load");
	}
}
goHud(client){
	if(IsClientValid(client))
	{
		SetHudTextParams(-1.0, 0.35, 1.0, 0,255,0,255);
		ShowSyncHudText(client, synch1, "GO!");
	}
}

public OnClientDisconnect(client){
	if(!tp){
		if(client==tagged){
			new String:buffer[32]; GetClientAuthString(client, buffer, sizeof(buffer));
			PushArrayString(assholes, buffer);
		}
	}else{
		if(taggedTP[client]){
			new String:buffer[32]; GetClientAuthString(client, buffer, sizeof(buffer));
			PushArrayString(assholes, buffer);
		}
	}
}

public OnClientDisconnect_Post(client){
	if(canStart) checkStart(); //we've been waiting for someone to dl the map and he screwed us
	if(!tp){
		if(client==tagged){
			makeTagged(chooseRandomPlayer());
		}else if (GetRealClientCount()<1) makeTagged(0);
	}else{
		taggedTP[client]=false;
		if (GetRealClientCount()<1)
			startT(INVALID_HANDLE);
		else{
			checkEndTP();
		}
	}
	ClientTeams[client] = 0;
}

modifyScore(client, value){
	new score = GetEntProp(client, Prop_Data, "m_iFrags");
	score+=value;
	SetEntProp(client, Prop_Data, "m_iFrags", score);
	SetEntProp(client, Prop_Data, "m_iFrags", score);
	
	new game_score_index = CreateEntityByName("game_score");
	DispatchSpawn(game_score_index);
	
	AcceptEntityInput(game_score_index, "ApplyScore", client, game_score_index);
	AcceptEntityInput(game_score_index, "Kill");
}

modifyDeaths(client, value){
	new score = GetEntProp(client, Prop_Data, "m_iDeaths");
	score+=value;
	SetEntProp(client, Prop_Data, "m_iDeaths", score);
	SetEntProp(client, Prop_Data, "m_iDeaths", score);
}

stock GetRealClientCount( bool:inGameOnly = true ) {
	new clients = 0;
	for( new i = 1; i <= MaxClients; i++ ) {
		if( ( ( inGameOnly ) ? IsClientInGame( i ) : IsClientConnected( i ) ) && !IsFakeClient( i ) ) {
 			clients++;
 		}
 	}
	return clients;
}

bool:IsClientValid(client){
 	if (client < 1) return false;
 	if (client > MaxClients) return false;
	if (!IsValidEntity(client)) return false;
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	return true;
}

public Action:Event_Death (Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientValid(client)){
		modifyScore(client, 1);
		modifyDeaths(client,-1);
	}
	return Plugin_Stop;
}

delEnt(index){
	if (index != INVALID_ENT_REFERENCE && index !=0) {
		AcceptEntityInput(index, "Kill");
	}
}


//Extra team change protection, was seperate plugin before
public Action:Event_Team(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client  = GetClientOfUserId(GetEventInt(event, "userid"));
	new team    = GetEventInt(event, "team");
	if (team>1 && ClientTeams[client]<2){
		ClientTeams[client]=team;
	}
	if(team!=ClientTeams[client]){
		SetTeamScore(team, (GetTeamScore(team)+1));
		CreateTimer(0.01, teamBack, client);
	}
}

public Action:teamBack(Handle:timer, any:client){
	ChangeClientTeam(client, ClientTeams[client]);
}