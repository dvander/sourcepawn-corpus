#include <sourcemod>
#include <sdktools>

#define DEBUG 0

#define PLUGIN_VERSION "1.3"
#define PLUGIN_NAME "L4D Race Mod"

new Handle:cvar_on; //handle for the cvar sm_racemod_on
new Handle:snareTimer[MAXPLAYERS + 1]; //timers for calling delayPlayer
new snareCount[MAXPLAYERS + 1]; //number of times delayPlayer was called for a survivor
new snarerId[MAXPLAYERS + 1]; //ids of attacking special inf
new finishId[4]; //ids of people who reached safe room
new place; //number of survivors that made it to the saferoom
new award[4]; //award scores
new String:clientId[4][25]; //steam ids of clients
new score[4]; //keep track of clients current scores
new incap[4]; //keep track of who is incapped.
new stillRacing; //number of players who have not made it to the safe room and have not been incapacitated
new mapNum; //the number that points to the correct array of saferoom position coords.
new String:nameFromModel[10]; //no idea how to use references.
new Handle:infoTimer = INVALID_HANDLE; //the handle for the timer that spits out random facts to players
new msgNum; //keep track of the info message to report
new secondsToGo; //keep track of how many seconds till racing starts.
new finaleTips; //this is not 0 if the level is a finale

//When a player gets to a checkpoint (start checkpoints included) their position must be within these constraints so we know they are at the end of the level.
new safeRoomArea[26][6];

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = " KrazyKyleP ",
	description = " Allows 4 player campigns to become a race to the finish. ",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1165358"
};

public OnPluginStart()
{
	cvar_on = CreateConVar("sm_racemod_on", "1", "Is the racemod plugin turned on?", FCVAR_PLUGIN|FCVAR_SPONLY);
	
	//HookEvent("round_end", Event_recordScores, EventHookMode_Pre);
	HookEvent("round_start", Event_roundStart);

	//assign score values. 0 is first place, 1 is second, etc...
	award[0] = 10;
	award[1] = 8;
	award[2] = 6;
	award[3] = 4;
	strcopy(clientId[0], 25, "null");  //i have no idea how to check to see if a string is new, so i just assign it 'null' and check for 'null' below.

	//When a player gets to a checkpoint (start checkpoints included) their position must be within these constraints so we know they are at the end of the level.
	//all finalies use the finale_vehicle_leaving event to give scores... not any area or saferoom.
	safeRoomArea[0] = {1800,2000,4450,4750,1150,1300};      //c1m1
	safeRoomArea[1] = {-7650,-7250,-4770,-4550,350,500};    //c1m2
	safeRoomArea[2] = {-2200,-1900,-4700,-4450,500,650};    //c1m3
	safeRoomArea[3] = {0,0,0,0,0,0};                        //c1m4 doesnt use a check point
	safeRoomArea[4] = {-1050,-800,-2700,-2350,-1150,-900};  //c2m1
	safeRoomArea[5] = {-4500,-4300,-5600,-5300,-150,50};    //c2m2
	safeRoomArea[6] = {-5200,-4950,1400,1900,-100,100};     //c2m3
	safeRoomArea[7] = {-850,-650,2250,2500,-300,-100};      //c2m4
	safeRoomArea[8] = {0,0,0,0,0,0};                        //c2m5 doesnt use a check point
	safeRoomArea[9] = {-2670,-2650,600,850,0,150};          //c3m1
	safeRoomArea[10] = {7300,7800,-1000,-650,50,250};       //c3m2
	safeRoomArea[11] = {4850,5100,-4000,-3700,300,450};     //c3m3
	safeRoomArea[12] = {1300,2000,4400,5000,-200,600};      //c3m4 swamp's boat area just incase.
	safeRoomArea[13] = {3700,4200,-1600,-1300,150,350};     //c4m1
	safeRoomArea[14] = {-1900,-1500,-13800,-13400,50,250};  //c4m2
	safeRoomArea[15] = {3800,4000,-2200,-1800,50,250};      //c4m3
	safeRoomArea[16] = {-3000,-2700,7700,8100,50,250};      //c4m4
	safeRoomArea[17] = {-7500,-7000,7400,8000,50,400};      //c4m5 hard rain's boat area just incase
	safeRoomArea[18] = {-4000,-3600,-1400,-900,-500,-200};  //c5m1
	safeRoomArea[19] = {-9800,-9400,-8400,-7800,-300,-100}; //c5m2
	safeRoomArea[20] = {7100,7600,-9600,-9300,50,250};      //c5m3
	safeRoomArea[21] = {1300,1600,-3600,-3200,0,200};       //c5m4
	safeRoomArea[22] = {7300,7500,3550,3900,100,300};       //c5m5 I was thinking about making the bridge a race too.
	safeRoomArea[23] = {-4100,-3700,1200,1600,650,850};     //c6m1
	safeRoomArea[24] = {11000,11400,4700,5200,-700,-500};   //c6m2
	safeRoomArea[25] = {0,0,0,0,0,0};                       //c6m3 never was able to get the car's coords
	
	//hook special inf. grabbing events to have them killed 5 seconds after.
	HookEvent("lunge_pounce", Event_PlayerGrabbed);
	HookEvent("tongue_grab", Event_PlayerGrabbed);
	HookEvent("jockey_ride", Event_PlayerGrabbed);
	HookEvent("charger_carry_start", Event_PlayerGrabbed);
	HookEvent("charger_pummel_start", Event_PlayerGrabbed);
    
    //monitor if survivors are downed, plays role in finale scoring.
	HookEvent("player_incapacitated", Event_PlayerIncap); 
	HookEvent("player_death", Event_PlayerDeath);
    
	HookEvent("finale_vehicle_leaving", Event_FinaleOver); //give final scores
    
	HookEvent("player_entered_checkpoint", Event_PlayerWin); //give the player a score.
    
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre); //turn off friendly fire
	
	HookEvent("revive_success", Event_PlayerPickedUp); //how to tell if a player is picked up
	HookEvent("gascan_pour_completed", Event_PourCompleted); //how to tell if a player poured a gascan.
   	
	RegConsoleCmd("scores", chatCMD); //allows players to check scores by typing '!scores' or '/scores' in the chat
	RegAdminCmd("startrace", forceStartRace, ADMFLAG_RCON, "Set the round start timer to 0, thus force starting the race.")
	
	CreateConVar("l4d_RaceMod_version", PLUGIN_VERSION, " Version of L4D Racemod on this server ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
}

public Action:chatCMD(client,args)
{
	if(GetConVarInt(cvar_on) > 0)
	{
		reportScores(client);
	}
	return Plugin_Handled;
}

public Action:forceStartRace(client,args)
{
	secondsToGo = 1;
	return Plugin_Handled;
}

public Action:Event_PourCompleted(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(cvar_on) > 0)
	{
		new userId = GetEventInt(event, "userid");
		new user = GetClientOfUserId(userId);
		new String:modelName[40];
		new String:plName[40];
	
	
		GetClientModel(user, modelName, 40); 
		model2name(modelName); //name is stored in nameFromModel
		for(new i=0; i<4; i++)
		{
			if(strcmp(nameFromModel, clientId[i]) == 0)
			{
				GetClientName(user, plName, sizeof(plName)); 
				score[i] += 2; //give player points for pouring a gas can
				PrintToChatAll("[RaceMod] %s earned 2 points for pouring a gascan!", plName);
			}	
		}
	}
	
	return Plugin_Continue;	
}

public Action:Event_PlayerPickedUp(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(cvar_on) > 0)
	{
		new userId = GetEventInt(event, "subject");
		new user = GetClientOfUserId(userId);
		new String:modelName[40];
		GetClientModel(user, modelName, 40);
		model2name(modelName); //name is stored in nameFromModel
	
		for(new i=0; i<4; i++){
			if(strcmp(nameFromModel, clientId[i]) == 0){
				incap[i] = false; //flag the client as not incapped
				#if DEBUG
				PrintToChatAll("[RaceMod] %s was picked up.", nameFromModel);
				#endif	
				stillRacing++;
			}	
		}
	}
	
	return Plugin_Continue;	
}

public Action:Event_roundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(cvar_on) > 0)
	{
		new String:mapName[40];
		GetCurrentMap(mapName, sizeof(mapName));  //get the mapname
	
		secondsToGo = 50;
	 
		//single out the 4 characters of the mapname
		new String:charArr[5][5];
		ExplodeString(mapName, "_", charArr, 5, 5);
		new String:mapAbbriv[5];
		strcopy(mapAbbriv, 5, charArr[0]);
	
		finaleTips = 0; //this is set to 1 on finales, where more specific tips are used.
	
		if(strcmp(mapAbbriv, "c1m1") == 0){
			secondsToGo = 70;
			mapNum = 0;	
		}else if(strcmp(mapAbbriv, "c1m2") == 0){
			mapNum = 1;	
		}else if(strcmp(mapAbbriv, "c1m3") == 0){
			mapNum = 2;	
		}else if(strcmp(mapAbbriv, "c1m4") == 0){
			mapNum = 3;	
			finaleTips = 1;
		}else if(strcmp(mapAbbriv, "c2m1") == 0){
			secondsToGo = 70;
			mapNum = 4;	
		}else if(strcmp(mapAbbriv, "c2m2") == 0){
			mapNum = 5;	
		}else if(strcmp(mapAbbriv, "c2m3") == 0){
			mapNum = 6;	
		}else if(strcmp(mapAbbriv, "c2m4") == 0){
			mapNum = 7;	
		}else if(strcmp(mapAbbriv, "c2m5") == 0){
			mapNum = 8;	
			finaleTips = 1;
		}else if(strcmp(mapAbbriv, "c3m1") == 0){
			secondsToGo = 70;
			mapNum = 9;	
		}else if(strcmp(mapAbbriv, "c3m2") == 0){
			mapNum = 10;	
		}else if(strcmp(mapAbbriv, "c3m3") == 0){
			mapNum = 11;	
		}else if(strcmp(mapAbbriv, "c3m4") == 0){
			mapNum = 12;
			finaleTips = 1;
		}else if(strcmp(mapAbbriv, "c4m1") == 0){
			secondsToGo = 70;
			mapNum = 13;	
		}else if(strcmp(mapAbbriv, "c4m2") == 0){
			mapNum = 14;	
		}else if(strcmp(mapAbbriv, "c4m3") == 0){
			mapNum = 15;	
		}else if(strcmp(mapAbbriv, "c4m4") == 0){
			mapNum = 16;	
		}else if(strcmp(mapAbbriv, "c4m5") == 0){
			mapNum = 17;
			finaleTips = 1;
		}else if(strcmp(mapAbbriv, "c5m1") == 0){
			secondsToGo = 70;
			mapNum = 18;	
		}else if(strcmp(mapAbbriv, "c5m2") == 0){
			mapNum = 19;	
		}else if(strcmp(mapAbbriv, "c5m3") == 0){
			mapNum = 20;	
		}else if(strcmp(mapAbbriv, "c5m4") == 0){
			mapNum = 21;	
		}else if(strcmp(mapAbbriv, "c5m5") == 0){
			mapNum = 22;
			finaleTips = 2;
			CreateTimer(0.5, checkPlayerPos, _, TIMER_REPEAT); //bridge race
		}else if(strcmp(mapAbbriv, "c6m1") == 0){
			secondsToGo = 70;
			mapNum = 23;	
		}else if(strcmp(mapAbbriv, "c6m2") == 0){
			mapNum = 24;	
		}else if(strcmp(mapAbbriv, "c6m3") == 0){
			mapNum = 25;
			finaleTips = 1;
		}
		
		//set vars
		for(new i=0; i<4; i++){
			finishId[i] = 0;
			incap[i] = false;	
		}
		
		for(new i=0; i<(MAXPLAYERS+1); i++){
			snarerId[i]	= 0;
		}
	
		stillRacing = 4;
		place = 0;
		
		CreateTimer(1.0, roundCountDown, _, TIMER_REPEAT);
		CreateTimer(60.0, setup, _, TIMER_REPEAT);
		
	}
	
	return Plugin_Continue;	
}

public Action:setup(Handle:timer, any:client) 
{
	if(GetConVarInt(cvar_on) > 0)
	{
		new String:mapName[40];
		GetCurrentMap(mapName, sizeof(mapName));
		//single out the 4th character in the mapname (which happens to be the level number)
		new String:charArr[5][5];
		ExplodeString(mapName, "m", charArr, 5, 5);
		ExplodeString(charArr[1], "_", charArr, 5, 5);
		new String:fourthChar[2];
		strcopy(fourthChar, 2, charArr[0]);
		
		//again... not sure how to detect this correctly, but if the var was just made, we should set things up.
		//also if the 4th character in a map name is 1 (it's the first level.
		if(strcmp(clientId[0], "null") == 0 || strcmp(fourthChar, "1") == 0)
		{
			#if DEBUG
			PrintToChatAll("[RaceMod] Detected no ids, resetting vars.");
			#endif
		
			if(infoTimer == INVALID_HANDLE)
			{
				msgNum = 0;
				infoTimer = CreateTimer(60.0, Notify, _, TIMER_REPEAT); //start telling players random facts
			}
		
			score[0] = 0;
			score[1] = 0;
			score[2] = 0;
			score[3] = 0;
		
			//get client ids and set up scores
			new k = 0;
			new String:modelName[40];
			for(new i=1; i<=MaxClients; i++) //find everyone's client id.
			{	
				if(IsClientInGame(i))
				{
					if(GetClientTeam(i) == 2) //client is a survivor
					{ 
						GetClientModel(i, modelName, 40);
						model2name(modelName); //this stores the name in nameFromModel
						strcopy(clientId[k], 25, nameFromModel);
					
						#if DEBUG
						PrintToChatAll("[RaceMod] stored auth string: %s.", clientId[k]);
						#endif
						k++;
					}	
				}
			}	
		}
	}
	
	return Plugin_Stop;	
}

public Event_PlayerGrabbed(Handle:event, const String:name[], bool:dontBroadcast) //set up events to happen when player is grabbed by special inf.
{
	if(GetConVarInt(cvar_on) > 0)
	{
		new attackerId = GetEventInt(event, "userid");
		new attackerClient = GetClientOfUserId(attackerId);
		new victimId = GetEventInt(event, "victim");
		new victimClient = GetClientOfUserId(victimId);
	
		#if DEBUG
		PrintToChatAll("[RaceMod] player grabbed");
		#endif
	
		if(snareTimer[victimClient] == INVALID_HANDLE)
		{
			#if DEBUG
			PrintToChatAll("[RaceMod] started a timer");
			#endif
		
			snareTimer[victimClient] = CreateTimer(0.5, delayPlayer, victimClient, TIMER_REPEAT); //start the clients timer
			snareCount[victimClient] = 0; //set the clients counter to 0
			snarerId[victimClient] = attackerClient;
		}
	}
		
	//return Plugin_Continue;
}

public Action:delayPlayer(Handle:timer, any:client) //delay the player by 5 seconds after grabbed by special inf.
{
	new ClientHealth = GetClientHealth(client);

	if(ClientHealth < 25)
	{
		#if DEBUG
		PrintToChatAll("[RaceMod] turn on god mode");
		#endif
		
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1); //turn on god mode if player is about to die.
	}
	
	snareCount[client]++; //add to the number of delay counts.
	
	if(snareCount[client] >= 10){ //victim can now go free.
		#if DEBUG
		PrintToChatAll("[RaceMod] kill timer/turn off god");
		#endif
		
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1); //turn off god mode.
		ForcePlayerSuicide(snarerId[client]); //kill infected... 
		snareTimer[client] = INVALID_HANDLE;
		return Plugin_Stop; //stop timer
	}
	
	return Plugin_Continue;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) //turn off friendly fire
{
	if(GetConVarInt(cvar_on) > 0)
	{
		new victimId = GetEventInt(event, "userid");
		new attackerId = GetEventInt(event, "attacker");
		new victim = GetClientOfUserId(victimId);
		new attacker = GetClientOfUserId(attackerId);
	
		new String:weapon[50];
		GetEventString(event, "weapon", weapon, 50);
		
		#if DEBUG
		PrintToChatAll("[RaceMod] weapon: %s", weapon);
		#endif
	
		//allow friendly fire of fire, but not bullets.
		if(strcmp(weapon, "inferno") != 0 && strcmp(weapon, "fire_cracker_blast") != 0 && attacker != 0)
		{
			if(IsClientInGame(victim) && IsClientInGame(attacker))
			{
				if(GetClientTeam(victim) == GetClientTeam(attacker)) //client is a survivor
				{
					SetEntityHealth(victim,(GetEventInt(event,"dmg_health")+ GetEventInt(event,"health"))); //set friend's health back to what is was before FF.
					#if DEBUG
					PrintToChatAll("[RaceMod] NO FF for you! vic: %i, att: %i", GetClientTeam(victim), GetClientTeam(attacker));
					new String:modelName[40];
					GetClientModel(victim, modelName, 40); 
					PrintToChatAll("[RaceMod] vic model: %s ", modelName);
					#endif
				}			
			}	
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_PlayerIncap(Handle:event, const String:name[], bool:dontBroadcast) //if player was incapped set vars assuming he wont be picked up.
{
	if(GetConVarInt(cvar_on) > 0)
	{
		new victimId = GetEventInt(event, "userid");
		new player = GetClientOfUserId(victimId);
	
		new String:modelName[40];
		GetClientModel(player, modelName, 40); 
		model2name(modelName); //this stores the name in nameFromModel				
		for(new i=0; i<4; i++){
			if(strcmp(nameFromModel, clientId[i]) == 0){
				incap[i] = true; //flag the player as incapped so he wont get bonus points for finishing finale
				stillRacing--;
				#if DEBUG
				PrintToChatAll("[RaceMod] %s was incapped.", nameFromModel);
				#endif	
			}	
		}
	
		//one less persion is in the race now. As people should not pick him up.
		if(stillRacing < 1){
			reportScores(0);	
		}
	}
	
	return Plugin_Continue;
}

//make sure that the survivor is marked as 'incapped'
//also check to see if a player killed a special infected because they may get bonus points for that.
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if(GetConVarInt(cvar_on) > 0)
	{
		new victimId = GetEventInt(event, "userid");
		new player = GetClientOfUserId(victimId);
		new killerId = GetEventInt(event, "attacker");
		new killer = GetClientOfUserId(killerId);
		new String:victimName[50];
		new String:modelName[40];
		new String:plName[40];
	
		GetEventString(event, "victimname", victimName, 50);
	
		if(strcmp(victimName, "Tank") == 0) //if a tank died
		{
			if(IsClientInGame(killer))
			{
				if(GetClientTeam(killer) == 2) //client is a survivor
				{
					GetClientModel(killer, modelName, 40); 
					model2name(modelName); //this stores the name in nameFromModel
					for(new i=0; i<4; i++)
					{
						if(strcmp(nameFromModel, clientId[i]) == 0)
						{
							GetClientName(killer, plName, sizeof(plName)); 
							score[i] += 5;
							PrintToChatAll("[RaceMod] %s earned 5 points for killing a tank!", plName);
						}	
					}
				}
			}
		}else if(strcmp(victimName, "Witch") == 0){ //if a witch died
		
			if(IsClientInGame(killer))
			{
				if(GetClientTeam(killer) == 2) //client is a survivor
				{
					GetClientModel(killer, modelName, 40); 
					model2name(modelName); //this stores the name in nameFromModel
					for(new i=0; i<4; i++)
					{
						if(strcmp(nameFromModel, clientId[i]) == 0)
						{
							GetClientName(killer, plName, sizeof(plName)); 
							score[i] += 3;
							PrintToChatAll("[RaceMod] %s earned 3 points for killing a witch!", plName);
						}	
					}
				}
			}
		}else if(strcmp(victimName, "Hunter") == 0 || strcmp(victimName, "Charger") == 0 || strcmp(victimName, "Smoker") == 0 || strcmp(victimName, "Jockey") == 0){ //if any of these special infected die, give item (maybe?)
	
			if(IsClientInGame(killer)) //you only get a chance of getting an item from a special if you kill it without it snaring you.
			{
				if(GetClientTeam(killer) == 2) //client is a survivor
				{
					new randInt = GetRandomInt(0, 5);
					if(randInt == 0){
						GivePlayerItem(killer, "weapon_molotov");
						PrintToChat(killer,"[RaceMod] That special you killed dropped something. Pick it up!");
					}else if(randInt == 1){
						GivePlayerItem(killer, "weapon_adrenaline");
						PrintToChat(killer,"[RaceMod] That special you killed dropped something. Pick it up!");
					}else if(randInt == 2){
						GivePlayerItem(killer, "weapon_pipe_bomb");
						PrintToChat(killer,"[RaceMod] That special you killed dropped something. Pick it up!");
					}else if(randInt == 3){
						GivePlayerItem(killer, "weapon_pain_pills");
						PrintToChat(killer,"[RaceMod] That special you killed dropped something. Pick it up!");
					}else{
						//4 and 5 are bad luck, too bad. 67% chance to get item!
					}
					#if DEBUG
					PrintToChatAll("[RaceMod] Give item for special kill? rand: %i", randInt);
					#endif
				}		
			}
		}
	
		if(IsClientInGame(player))
		{
			if(GetClientTeam(player) == 2) //client is a survivor
			{
				GetClientModel(player, modelName, 40); 
				model2name(modelName); //this stores the name in nameFromModel
						
				for(new i=0; i<4; i++){
					if(strcmp(nameFromModel, clientId[i]) == 0){
						incap[i] = true; //just make sure that the client wont be getting a finale bonus
						#if DEBUG
						PrintToChatAll("[RaceMod] %s was killed.", nameFromModel);
						#endif	
					}	
				}
			}
		}
	}	
	
	return Plugin_Continue;
}

public Action:Event_PlayerWin(Handle:event, const String:name[], bool:dontBroadcast) //give the player a score.
{
	if(GetConVarInt(cvar_on) > 0)
	{
		new playerId = GetEventInt(event, "userid");
		new player = GetClientOfUserId(playerId);
	
		if(player != 0) //if the player is not an npc
		{
			if(IsClientInGame(player) && GetClientTeam(player) == 2) //a survivor reached the finish line
			{
				new vec[3];
				GetClientAbsOrigin(player, Float:vec);
				new posX = RoundToCeil(Float:vec[0]);
				new posY = RoundToCeil(Float:vec[1]);
				new posZ = RoundToCeil(Float:vec[2]);
				//make sure that this event was called when the survivor made it to the safe room at the end of the level, because start safe rooms call this event too.
				if(posX > safeRoomArea[mapNum][0] && posX < safeRoomArea[mapNum][1] && posY > safeRoomArea[mapNum][2] && posY < safeRoomArea[mapNum][3] && posZ > safeRoomArea[mapNum][4] && posZ < safeRoomArea[mapNum][5])
				{
					#if DEBUG
					PrintToChatAll("[RaceMod] A player has won.");
					#endif	
				
					//check if player entered safe room for the first time.
					new awardPoints = true;
					for(new i=0; i<4; i++)
					{
						if(finishId[i] == player)
						{
							awardPoints = false;
				
							#if	DEBUG
							PrintToChatAll("[RaceMod] player has already finished.");
							#endif	
						}
					}
				
					//award points...
					if(awardPoints)
					{
						new pointsToAdd = award[place];
						new totalPoints;
						new String:plName[40];
						new String:modelName[40];
						GetClientModel(player, modelName, 40); 
						model2name(modelName); //this stores the name in nameFromModel
						GetClientName(player, plName, sizeof(plName)); 
										
						//find the right player and give them points.
						for(new i=0; i<4; i++)
						{
							if(strcmp(nameFromModel, clientId[i]) == 0)
							{
								totalPoints = score[i]+pointsToAdd;
								score[i] = totalPoints;
							}	
						}
						finishId[place] = player; //record down that player has finished.
						PrintToChatAll("[RaceMod] %s finished. %i points awarded. %i points total.", plName, pointsToAdd, totalPoints);
						place++;
						stillRacing--;
						if(stillRacing < 1)
						{
							reportScores(0);	
						}
					}
					
					#if DEBUG
					PrintToChatAll("[RaceMod] id: %i 0: %i 1: %i 2: %i 3: %i.", player, finishId[0], finishId[1], finishId[2], finishId[3]);
					#endif
				}
			}
		}
		#if DEBUG
		PrintToChatAll("[RaceMod] Event_PlayerWin id: %i", player);
		#endif	
	}
	
	return Plugin_Continue;
}

public Action:Event_FinaleOver(Handle:event, const String:name[], bool:dontBroadcast) //the finale round is over, award survivors final points and report the winners.
{
	if(GetConVarInt(cvar_on) > 0)
	{
		PrintToChatAll("[RaceMod] Survivors win 10 points!.");
		new String:modelName[40];
	
		//only award survivors that have not died or are not incapped points.
		for(new j=0; j<4; j++)
		{
			for(new i=1; i<=MaxClients; i++) //find everyone's client id.
			{	
				if(IsClientInGame(i))
				{
					if(GetClientTeam(i) == 2) //client is a human
					{ 
						GetClientModel(i, modelName, 40); 
						model2name(modelName); //this stores the name in nameFromModel
						if(strcmp(clientId[j], nameFromModel) == 0 && !incap[j])
						{
							score[j] += 10;
						}
					}
				}
			}
		}
		reportScores(0);
	}
	
	return Plugin_Continue;	
}

public Action:model2name(const String:model[]) //convert a model name to just a character name.
{ 
	if(strcmp(model, "models/survivors/survivor_coach.mdl") == 0){
		strcopy(nameFromModel, 10, "Coach");
	}else if(strcmp(model, "models/survivors/survivor_producer.mdl") == 0){
		strcopy(nameFromModel, 10, "Rochelle");
	}else if(strcmp(model, "models/survivors/survivor_mechanic.mdl") == 0){
		strcopy(nameFromModel, 10, "Ellis");
	}else if(strcmp(model, "models/survivors/survivor_gambler.mdl") == 0){
		strcopy(nameFromModel, 10, "Nick");
	}else{
		strcopy(nameFromModel, 10, "NULL");
	}
}

public Action:reportScores(const client) //report the scores in order. if client is not 0 then a player asked to have it printed to them
{
	#if DEBUG
	PrintToChatAll("[RaceMod] End of round has been reached.");
	#endif
	
	//initiate buble sort
	new sort = true;
	new temp1;
	new String:temp2[25];
	while(sort){
		sort = false;
		for(new i=0; i<3; i++){
			if(score[i] < score[i+1]){
				temp1 = score[i];
				strcopy(temp2, 25, clientId[i]);
				score[i] = score[i+1];
				strcopy(clientId[i], 25, clientId[i+1]);
				score[i+1] = temp1;
				strcopy(clientId[i+1], 25, temp2);
				sort = true;
			}
		}
	}
	
	new String:modelName[40];
	
	new String:cName[40];
	
	//there is probably an easier way of executing this part... but i was lazy.
	//make sure the clientid matches the same person's score and name.
	for(new j=0; j<4; j++)
	{
		for(new i=1; i<=MaxClients; i++) //find everyone's client id.
		{	
			if(IsClientInGame(i))
			{
				if(GetClientTeam(i) == 2) //client is a human
				{ 
					GetClientModel(i, modelName, 40); 
					model2name(modelName); //this stores the name in nameFromModel
					
					if(strcmp(clientId[j], nameFromModel) == 0){
						GetClientName(i, cName, sizeof(cName));
						if(j == 0){
							if(client == 0){
								PrintToChatAll("[RaceMod] 1st place: %s with %i points.", cName, score[0]);
							}else{
								PrintToChat(client,"[RaceMod] 1st place: %s with %i points.", cName, score[0]);
							}
						}else if(j == 1){
							if(client == 0){
								PrintToChatAll("[RaceMod] 2nd place: %s with %i points.", cName, score[1]);
							}else{
								PrintToChat(client,"[RaceMod] 2nd place: %s with %i points.", cName, score[1]);
							}
						}else if(j == 2){
							if(client == 0){
								PrintToChatAll("[RaceMod] 3rd place: %s with %i points.", cName, score[2]);
							}else{
								PrintToChat(client,"[RaceMod] 3rd place: %s with %i points.", cName, score[2]);
							}
						}else if(j == 3){
							if(client == 0){
								PrintToChatAll("[RaceMod] 4th place: %s with %i points.", cName, score[3]);
							}else{
								PrintToChat(client,"[RaceMod] 4th place: %s with %i points.", cName, score[3]);
							}
						}
					}
				}
			}
		}
	}	
}

public Action:Notify(Handle:timer, any:client) //tell players random facts
{
	if(GetConVarInt(cvar_on) > 0){
		if(msgNum == 0){
			if(finaleTips == 0){
				PrintToChatAll("[RaceMod] Beat your friends to the safe room!");
			}else if(finaleTips == 1){
				PrintToChatAll("[RaceMod] Kill tanks and pour gascans for points!"); //used for any other finale
			}else if(finaleTips == 2){
				PrintToChatAll("[RaceMod] Be the first to the chopper!"); //used for bridge finale
			}
		}else if(msgNum == 1){
			PrintToChatAll("[RaceMod] Special infected will only delay you, it's unlikely that they will kill you.");
		}else if(msgNum == 2){
			PrintToChatAll("[RaceMod] Adrenaline will significantly speed you up. Use it to get that extra edge!");
		}else if(msgNum == 3){
			PrintToChatAll("[RaceMod] Killing Tanks and Witches earn you bonus points!");
		}else if(msgNum == 4){
			PrintToChatAll("[RaceMod] Sometimes killing special infected will give you an item! Don't forget to pick it up!");
		}else if(msgNum == 5){
			PrintToChatAll("[RaceMod] Don't get incapacitated, as your friends are against you!");
		}else if(msgNum == 6){
			PrintToChatAll("[RaceMod] Friendly fire is off but molotovs still hurt your friends!");
		}
	
		msgNum++;
	
		if(msgNum > 6){
			msgNum = 0;
		}
	}
	
	return Plugin_Continue;	
}

public Action:roundCountDown(Handle:timer, any:client) //freeze players till the counter reaches 0, then unfreeze them.
{
	if(GetConVarInt(cvar_on) > 0){
		secondsToGo--;
		if(secondsToGo % 5 == 0 || secondsToGo < 6)
		{
			if(secondsToGo > 5 && secondsToGo % 2 == 0)
			{
				PrintToChatAll("[RaceMod] You can't move till race starts!");			
			}
			PrintToChatAll("[RaceMod] Race starts in %i seconds!", secondsToGo);
		}
		
		//constantly try to freeze players and give them god mode
		for(new i=1; i<=MaxClients; i++) //find everyone's client id.
		{	
			if(IsClientInGame(i))
			{
				if(GetClientTeam(i) == 2) //client is a survivor
				{ 
					SetEntityMoveType(i, MOVETYPE_NONE); //freeze player
					SetEntProp(i, Prop_Data, "m_takedamage", 0, 1); //give god mode
				}
			}
		}
	
		//take away god mode and let players move
		if(secondsToGo < 1)
		{
			//SetHudTextParams(-1.0,0.3,5.0,255,0,0,255,0,5.0,0.3,0.3);
			PrintToChatAll("[RaceMod] GO GO GO!!!");
			for(new i=1; i<=MaxClients; i++) //find everyone's client id.
			{	
				if(IsClientInGame(i))
				{
					if(GetClientTeam(i) == 2) //client is a survivor
					{ 
						SetEntityMoveType(i, MOVETYPE_WALK); //unfreeze player
						SetEntProp(i, Prop_Data, "m_takedamage", 2, 1); //take god mode
						
						GivePlayerItem(i, "weapon_first_aid_kit");
						GivePlayerItem(i, "weapon_adrenaline");
						GivePlayerItem(i, "weapon_pipe_bomb");
						//ShowHudText(i,-1,"RACE START!");
					}
				}
			}
			return Plugin_Stop;	//stop timer
		}
	}
	
	return Plugin_Continue;	
}

public Action:checkPlayerPos(Handle:timer, any:client)
{
	if(GetConVarInt(cvar_on) > 0)
	{
		for(new player=1; player<=MaxClients; player++) //find everyone's client id.
		{
			if(IsClientInGame(player) && GetClientTeam(player) == 2) //a survivor reached the finish line
			{
				new vec[3];
				GetClientAbsOrigin(player, Float:vec);
				new posX = RoundToCeil(Float:vec[0]);
				new posY = RoundToCeil(Float:vec[1]);
				new posZ = RoundToCeil(Float:vec[2]);
				//make sure that this event was called when the survivor made it to the safe room at the end of the level, because start safe rooms call this event too.
				if(posX > safeRoomArea[mapNum][0] && posX < safeRoomArea[mapNum][1] && posY > safeRoomArea[mapNum][2] && posY < safeRoomArea[mapNum][3] && posZ > safeRoomArea[mapNum][4] && posZ < safeRoomArea[mapNum][5])
				{
					#if DEBUG
					PrintToChatAll("[RaceMod] A player has won.");
					#endif	
				
					//check if player entered safe room for the first time.
					new awardPoints = true;
					for(new i=0; i<4; i++)
					{
						if(finishId[i] == player)
						{
							awardPoints = false;
				
							#if	DEBUG
							PrintToChatAll("[RaceMod] player has already finished.");
							#endif	
						}
					}
				
					//award points...
					if(awardPoints)
					{
						new pointsToAdd = award[place];
						new totalPoints;
						new String:plName[40];
						new String:modelName[40];
						GetClientModel(player, modelName, 40); 
						model2name(modelName); //this stores the name in nameFromModel
						GetClientName(player, plName, sizeof(plName)); 
										
						//find the right player and give them points.
						for(new i=0; i<4; i++)
						{
							if(strcmp(nameFromModel, clientId[i]) == 0)
							{
								totalPoints = score[i]+pointsToAdd;
								score[i] = totalPoints;
							}	
						}
						finishId[place] = player; //record down that player has finished.
						PrintToChatAll("[RaceMod] %s finished. %i points awarded. %i points total.", plName, pointsToAdd, totalPoints);
						place++;
						stillRacing--;
						if(stillRacing < 1)
						{
							reportScores(0);	
						}
					}
				}
			}
		}
	}
	if(mapNum == 22){
		return Plugin_Continue;
	}else{
		return Plugin_Stop;
	}
}