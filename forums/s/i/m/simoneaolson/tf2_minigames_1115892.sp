/*
 *
 * =============================================================================
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 */

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#define PLUGIN_VERSION "1.20"

new Handle:Cvar_TF2_MINIGAMES_ENABLED, Handle:Cvar_TF2_MINIGAMES_PARTY, Handle:Cvar_TF2_MINIGAMES_TIME, Handle:Cvar_TF2_MINIGAMES_MODE, Handle:Cvar_TF2_MINIGAMES_ROUNDS, Handle:Cvar_TF2_MINIGAMES_CRITS, Handle:Cvar_TF2_MINIGAMES_MIN, Handle:Cvar_TF2_MINIGAMES_EXPLODE, Handle:Cvar_TF2_MINIGAMES_WAITING, Handle:CountdownTimer 
new String:CenterMessage[128], String:ChatMessage[128], String:SoundFile[256], String:classname[256]
new bool:miniGames, bool:firstBlood, bool:alreadyFired, bool:haveSpawnCoords[2], bool:alreadyIntruders[2]
new bool:messageFlag[40], clientParticle[40][4], clientSpawns[40], preClass[40], teamScore[2], BluIntruders[3], RedIntruders[3], Kills[40], KillStreak[40], Float:BluSpawnCoord[3], Float:RedSpawnCoord[3]
new temp, roundNum, miniGameMode, prevMiniGameMode, numIntruders, redWinner[5], bluWinner[5]


public Plugin:myinfo = 
{

	name = "Team Fortress 2 Mini-Games",
	author = "simoneaolson",
	description = "A variety of fun, short mini games at the beginning of every map",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
	
}


public OnPluginStart()
{

	LoadTranslations("tf2minigames.phrases")
	AutoExecConfig(true, "tf2_minigames")
	
	CreateConVar("tf2_minigames_version", PLUGIN_VERSION, "Current plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD)
	Cvar_TF2_MINIGAMES_ENABLED = CreateConVar("tf2_minigames_enabled", "1", "Enabled/Disable TF2 Mini-Games (bool)", _, true, 0.0, true, 1.0)
	Cvar_TF2_MINIGAMES_TIME = CreateConVar("tf2_minigames_time", "50.0", "Time in seconds to play each mini-game", _, true, 30.0, false)
	Cvar_TF2_MINIGAMES_ROUNDS = CreateConVar("tf2_minigames_rounds", "2", "Number of Mini Games to play before round start", _, true, 1.0, true, 5.0)
	Cvar_TF2_MINIGAMES_MODE = CreateConVar("tf2_minigames_mode", "1", "How to select mini-game to be played: (1 = Sequentially) (2 = Randomly)", _, true, 1.0, true, 2.0)
	Cvar_TF2_MINIGAMES_CRITS = CreateConVar("tf2_minigames_crits", "1", "Enable/Disable Crits during a Mini Game Round (bool)", _, true, 0.0, true, 1.0)
	Cvar_TF2_MINIGAMES_MIN = CreateConVar("tf2_minigames_minplayers", "6", "Fires TF2 Minigames ONLY when there are more than/equal X players on the server (0 = Disable)", _, true, 0.0, true, 40.0)
	Cvar_TF2_MINIGAMES_EXPLODE = CreateConVar("tf2_minigames_explode", "1", "Explode players on death in mini games", _, true, 0.0, true, 1.0)
	Cvar_TF2_MINIGAMES_WAITING = CreateConVar("tf2_minigames_waiting", "15.0", "Time to wait for players to join the server", _, true, 5.0, true, 30.0)
	Cvar_TF2_MINIGAMES_PARTY = CreateConVar("tf2_minigames_party_off", "1", "Disable party mode when the minigames end (bool)", _, true, 0.0, true, 1.0)
	
	if (GetConVarBool(Cvar_TF2_MINIGAMES_ENABLED))
	{
		HookEventEx("teamplay_round_start", RoundStart, EventHookMode_Post)
		HookEventEx("player_spawn", PlayerSpawn)
		HookEventEx("player_death", PlayerDeath, EventHookMode_Pre)
		HookEventEx("player_changeclass", PlayerChangeClass)
		RegAdminCmd("jointeam", jointeam, 0)
	}
	
}


public OnConfigsExecuted()
{

	ServerCommand("sm_cvar mp_waitingforplayers_time %i", GetConVarInt(Cvar_TF2_MINIGAMES_ROUNDS)*(6 + GetConVarInt(Cvar_TF2_MINIGAMES_TIME)) + GetConVarInt(Cvar_TF2_MINIGAMES_WAITING))

}


public OnMapStart()
{

	if (GetConVarBool(Cvar_TF2_MINIGAMES_ENABLED))
	{
		//Precache countdown sounds
		PrecacheSound("ui/ding_a_ling.wav", true)
		PrecacheSound("misc/your_team_won.wav", true)
		PrecacheSound("misc/your_team_lost.wav", true)
		PrecacheSound("misc/your_team_stalemate.wav", true)
		PrecacheSound("misc/happy_birthday.wav", true)
		PrecacheSound("misc/tf_nemesis.wav", true)
		PrecacheSound("vo/announcer_am_lastmanalive04.wav", true) //YOURE TEAM IS DEAD, GOOD LUCK
		PrecacheSound("vo/announcer_am_roundstart04.wav", true) //FIGHT TO THE DEATH
		PrecacheSound("vo/announcer_am_gamestarting04.wav", true) //LET THE GAMES BEGIN
		PrecacheSound("vo/announcer_am_gamestarting05.wav", true) //TIME TO FIGHT
		PrecacheSound("vo/announcer_am_firstblood01.wav", true)
		PrecacheSound("vo/announcer_am_firstblood02.wav", true)
		PrecacheSound("vo/announcer_am_firstblood03.wav", true)
		PrecacheSound("vo/announcer_am_firstblood04.wav", true)
		PrecacheSound("vo/announcer_am_firstblood05.wav", true)
		PrecacheSound("vo/announcer_am_firstblood06.wav", true)
		PrecacheSound("vo/announcer_am_flawlessdefeat03.wav", true) //YOU DIDNT KILL ANY OF THEM
		PrecacheSound("vo/announcer_am_flawlessdefeat04.wav", true) //NEXT TIME TRY KILLING ONE
		PrecacheSound("vo/announcer_ends_60sec.wav", true)
		PrecacheSound("vo/announcer_ends_30sec.wav", true)
		PrecacheSound("vo/announcer_ends_10sec.wav", true)
		PrecacheSound("vo/announcer_ends_5sec.wav", true)
		PrecacheSound("vo/announcer_ends_4sec.wav", true)
		PrecacheSound("vo/announcer_ends_3sec.wav", true)
		PrecacheSound("vo/announcer_ends_2sec.wav", true)
		PrecacheSound("vo/announcer_ends_1sec.wav", true)
		PrecacheSound("vo/announcer_failure.wav", true) //FAILURE
	}
	
	alreadyFired = false
	haveSpawnCoords[0] = false
	haveSpawnCoords[1] = false
	alreadyIntruders[0] = false
	alreadyIntruders[1] = false
	firstBlood = false
	for (new i = 1; i < MaxClients+1; ++i)
	{
		messageFlag[i] = false
	}
	miniGameMode = 1
	roundNum = 1
	DetermineMode()
	
}


public Action:StartMiniGames(Handle:timer)
{

	if (GetConVarInt(Cvar_TF2_MINIGAMES_MIN) == 0) MiniGamesTrue()
	else
	{
		if (GetClientCount() >= GetConVarInt(Cvar_TF2_MINIGAMES_MIN)) MiniGamesTrue()
		else
		{
			PrintToServer("(MiniGames Canceled [Too few players])")
			StopMiniGames()
		}
	}
	
}


public Action:MiniGamesTrue()
{

	PrintToServer("(MiniGames Started)")
	miniGames = true
	ServerCommand("sm_cvar tf_birthday 1")
	CountdownTimer = CreateTimer(0.0, CountdownMessage, GetConVarInt(Cvar_TF2_MINIGAMES_TIME))
	
	//Respawn clients
	for (new i = 1; i < MaxClients+1; ++i)
	{
		if (IsValidClientId(i) && GetClientTeam(i) > 1) TF2_RespawnPlayer(i)
	}
	
	if (GetRandomInt(1,2) == 2) Format(SoundFile, 256, "%s", "vo/announcer_am_gamestarting04.wav")
	else Format(SoundFile, 256, "%s", "vo/announcer_am_roundstart04.wav")
	EmitSoundToClients()

}


public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{

	if (!alreadyFired)
	{
		alreadyFired = true
		
		PrepareCenterMessage(1.0, 0, 1)
		
		CreateTimer(GetConVarFloat(Cvar_TF2_MINIGAMES_WAITING), StartMiniGames)
	}
	else if (miniGames) StopMiniGames()
	
}


public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	new team = GetClientTeam(client)
	
	if (IsValidClientId(client) && team > 1)
	{
		if (miniGames)
		{
			if (miniGameMode != 5) DisableResupply()
			
			if (!messageFlag[client])
			{
				messageFlag[client] = true
				
				if (miniGameMode == 5)
				{
					if (TF2_GetPlayerClass(client) != TFClass_Heavy)
					{
						PreClass(client)
						TF2_SetPlayerClass(client, TFClass_Heavy, false, true)
						TF2_RespawnPlayer(client)
					}
				}
				
				PrepareCenterMessage(0.1, client, 0)
				
				CreateTimer(0.1, PrintChatMessage, client)
				CreateTimer(13.2, Dingaling, client)
			}
				
			if (miniGameMode != 3)
			{
				if (miniGameMode == 4) CreateTimer(0.1, StripToMelee, client)
				
				//Add buffed effect
				TF2_AddCondition(client, TFCond_Buffed, 99.0)
			}
			
			temp = team - 2
			if (miniGameMode == 3 && alreadyIntruders[temp] == false)
			{
				alreadyIntruders[temp] = true
				if (haveSpawnCoords[temp] == false)
				{
					haveSpawnCoords[temp] = true
					if (team == 2) GetEntPropVector(client, Prop_Send, "m_vecOrigin", RedSpawnCoord)
					else if (team == 3) GetEntPropVector(client, Prop_Send, "m_vecOrigin", BluSpawnCoord)
				}
				if (haveSpawnCoords[0] && haveSpawnCoords[1]) GetIntruders()
			}
		}
	}
	
}


public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{

	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	if (miniGames && IsValidClientId(client))
	{
		
		//Remove particles attached to client (if they exist)
		CheckAndRemove(clientParticle[client][0], "info_particle_system")
		CheckAndRemove(clientParticle[client][1], "info_particle_system")
		CheckAndRemove(clientParticle[client][2], "info_particle_system")
		
		//Remove buffed condition
		TF2_RemoveCondition(client, TFCond_Buffed)
		
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
		if (IsValidClientId(attacker) && client != attacker)
		{
			if (!firstBlood)
			{
				FirstBloodSound()
				firstBlood = true
			}
			++Kills[attacker]
			++KillStreak[attacker]
			PrintHintText(attacker, "Kill-Streak: %i", KillStreak[attacker])
			CreateTimer(0.1, Dingaling, attacker)
		}
		
		CalculateScore(client)
		if (GetConVarBool(Cvar_TF2_MINIGAMES_EXPLODE) && miniGameMode != 1)
		{
			ExplodePlayer(client)
		}
		if (miniGameMode == 5)
		{
			if (KillStreak[client] == 0)
			{
				Format(SoundFile, 256, "%s%i.wav", "vo/announcer_am_flawlessdefeat0", GetRandomInt(3,4))
				EmitSoundToClient(client, SoundFile)
			}
			else EmitSoundToClient(client, "misc/tf_nemesis.wav")
			ChangeClientTeam(client, 1)
			
			decl team
			new aliveRed, aliveBlu
			for (new i = 1; i < MaxClients+1; ++i)
			{
				if (IsValidClientId(i))
				{
					team = GetClientTeam(i)
					if (team == 2) ++aliveRed
					else if (team == 3) ++aliveBlu
				}
			}
			
			if (aliveRed == 1) DisplayStats(2)
			else if (aliveBlu == 1) DisplayStats(3)
			
		}
		else
		{
			if (IsValidClientId(client)) CreateTimer(0.1, InstantRespawn, client)
		}
		KillStreak[client] = 0
	}
	
}


public bool:IsValidClientId(client)
{

	return ((client > 0 && client < MaxClients+1) && IsClientInGame(client))

}


public Action:PlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	if (miniGames && miniGameMode == 5 && GetEventInt(event, "class") != 7)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		if (IsValidClientId(client))
		{
			TF2_SetPlayerClass(client, TFClass_Heavy, false, true)
			CreateTimer(0.0, InstantRespawn, client)
		}
	}
	
}


public Action:jointeam(client, team)
{
	
	if (IsValidClientId(client) && miniGames && miniGameMode == 5)
	{
		new prevTeam = GetClientTeam(client)
		if (prevTeam > 1)
		{
			ChangeClientTeam(client, prevTeam)
			return Plugin_Handled
		}
	}
	return Plugin_Continue
	
}


public Action:DetermineMode()
{
	
	prevMiniGameMode = miniGameMode
	
	if (GetConVarInt(Cvar_TF2_MINIGAMES_MODE) == 1)
	{
		if (miniGameMode == 5) miniGameMode = 2
		else ++miniGameMode
	}
	else miniGameMode = GetRandomInt(2,5)
	
	SetMessages()

	//Turn on friendly-fire for certain modes
	if (miniGames && miniGameMode != 3) ServerCommand("sm_cvar mp_friendlyfire 1")
	
}


public Action:SetMessages()
{

	if (miniGameMode == 2)
	{
		Format(ChatMessage, 128, "%t", "Free-For-All Mode (Chat Text)")
		Format(CenterMessage, 128, "%t", "Free-For-All Mode (Center Text)")
	}
	else if (miniGameMode == 3)
	{
		Format(ChatMessage, 128, "%t", "Fire Fire Fire (Chat Text)")
		Format(CenterMessage, 128, "%t", "Fire Fire Fire (Center Text)")
	}
	else if (miniGameMode == 4)
	{
		Format(ChatMessage, 128, "%t", "Melee Maddness (Chat Text)")
		Format(CenterMessage, 128, "%t", "Melee Maddness (Center Text)")
	}
	else if (miniGameMode == 5)
	{
		Format(ChatMessage, 128, "%t", "Heavy Bloodbath (Chat Text)")
		Format(CenterMessage, 128, "%t", "Heavy Bloodbath (Center Text)")
	}

}


public Action:CalculateScore(client)
{
	
	new team = GetClientTeam(client) - 2
	if (miniGameMode == 3)
	{
		if (IsClientIntruder(client)) ++teamScore[team]
	}
	else if (miniGameMode == 2 || miniGameMode == 4)
	{
		++teamScore[team]
		PrintHintText(client, "Teamkills: %i", teamScore[team])
	}
	else if (miniGameMode == 5)
	{
		new playersLeft = 0
		for (new i = 1; i < MaxClients+1; ++i)
		{
			if (IsValidClientId(i))
			{
				if (IsPlayerAlive(i)) ++playersLeft
			}
		}
		if (playersLeft == 2) ResetMiniGames()
	}
	
}


public Action:RoundEndSound()
{
	
	new bluScore = teamScore[1], redScore = teamScore[0]
	if (redScore > bluScore)
	{
		temp = 2
	}
	else if (redScore < bluScore)
	{
		temp = 3
	}
	else if (redScore == bluScore)
	{
		Format(SoundFile, sizeof(SoundFile), "%s", "misc/your_team_stalemate.wav")
		EmitSoundToClients()
		return Plugin_Handled
	}
	
	for (new i = 1; i < MaxClients+1; ++i)
	{
		if (IsValidClientId(i))
		{
			if (GetClientTeam(i) == temp) EmitSoundToClient(i, "misc/your_team_won.wav")
			else EmitSoundToClient(i, "misc/your_team_lost.wav")
		}
	}
	return Plugin_Handled
	
}


public Action:GetIntruders()
{
	
	decl String:class[5], max, team
	new redInc, bluInc
	
	//Determine how many intruders to spawn:
	max = GetClientCount()
	if (max >= 15) numIntruders = 3
	else if (max >= 10) numIntruders = 2
	else numIntruders = 1

	//Enumerate clients, select intruders
	for (new i = 1; i < MaxClients+1; ++i)
	{
		if (IsValidClientId(i))
		{
			if (!IsFakeClient(i) && TF2_GetPlayerClass(i) == TF2_GetClass(class))
			{
				team = GetClientTeam(i)
				if (team == 3 && bluInc < numIntruders)
				{
					BluIntruders[bluInc] = i
					++bluInc
				}
				else if (team == 2 && redInc < numIntruders)
				{
					RedIntruders[redInc] = i
					++redInc
				}
			}
		}
	}
	
	//Fill in the rest with random red clients
	if (redInc < numIntruders)
	{
		for (new i = 1; i < MaxClients+1; ++i)
		{
			if (IsValidClientId(i))
			{
				if (!IsFakeClient(i) && GetClientTeam(i) == 2 && redInc < numIntruders)
				{
					RedIntruders[redInc] = i
					++redInc
				}
			}
		}
	}
	
	//Fill in the rest with random blu clients
	if (bluInc < numIntruders)
	{
		for (new i = 1; i < MaxClients+1; ++i)
		{
			if (IsValidClientId(i))
			{
				if (!IsFakeClient(i) && GetClientTeam(i) == 3 && bluInc < numIntruders)
				{
					BluIntruders[bluInc] = i
					++bluInc
				}
			}
		}
	}
	
	decl String:message[128]
	Format(message, 128, "%t", "Personal Message To Pyro")
		
	//Prepare intruders to enter enemy base
	for (new i = 0; i < numIntruders; ++i)
	{
		if (IsValidClientId(i))
		{
			if (TF2_GetPlayerClass(i) != TFClass_Pyro)
			{
				TF2_SetPlayerClass(RedIntruders[i], TFClass_Pyro, false, true)
				CreateTimer(0.0, InstantRespawn, RedIntruders[i])
				TF2_SetPlayerClass(BluIntruders[i], TFClass_Pyro, false, true)
				CreateTimer(0.0, InstantRespawn, BluIntruders[i])
			}
		}
		
		//Send personal message
		PrintCenterText(BluIntruders[i], message)
		PrintCenterText(RedIntruders[i], message)
		
		//Buff health
		SetEntProp(BluIntruders[i], Prop_Data, "m_iHealth", 1000)
		SetEntProp(RedIntruders[i], Prop_Data, "m_iHealth", 1000)
	}
	
	CreateTimer(0.0, TeleportIntruders)
	
}


public Action:TeleportIntruders(Handle:timer)
{
	
	for (new i = 0; i < numIntruders; ++i)
	{
		if (IsValidClientId(BluIntruders[i]))
		{
			TeleportEntity(BluIntruders[i], RedSpawnCoord, NULL_VECTOR, NULL_VECTOR)
			AttachParticle(BluIntruders[i], 2, "healhuff_blu", "head")
		}
		if (IsValidClientId(RedIntruders[i]))
		{
			TeleportEntity(RedIntruders[i], BluSpawnCoord, NULL_VECTOR, NULL_VECTOR)
			AttachParticle(RedIntruders[i], 2, "healhuff_red", "head")
		}
		
	}
	
}


public bool:IsClientIntruder(client)
{
	
	for (new i = 0; i < numIntruders; ++i)
	{
		if (client == RedIntruders[i] || client == BluIntruders[i]) return true
	}
	return false
	
}


//Create Particle:
public Action:AttachParticle(const client, const particleNum, const String:effectName[], const String:attachTo[])
{
	
	clientParticle[client][particleNum] = CreateEntityByName("info_particle_system")
	new particle = clientParticle[client][particleNum]
	
	if (IsValidEdict(particle))
	{
		decl String:tName[32], String:pName[12], Float:fPos[3]
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos)
		if (particleNum == 0) fPos[2] -= 75
		else if (particleNum == 1) fPos[2] -= 15
		TeleportEntity(particle, fPos, NULL_VECTOR, NULL_VECTOR)
		
		
		//Set Entity Keys & Spawn Entity (make sure dispatched entity name does not already exist, otherwise it will not work!!)
		Format(tName, sizeof(tName), "tf2mg_cl_%i", client)
		DispatchKeyValue(client, "targetname", tName)
		
		//Set Key Values
		Format(pName, sizeof(pName), "tf2mg_pe_%i_%i", particleNum, client)
		DispatchKeyValue(particle, "targetname", pName)
		DispatchKeyValue(particle, "parentname", tName)
		DispatchKeyValue(particle, "effect_name", effectName)
		DispatchSpawn(particle)
		
		//Set Entity Inputs
		SetVariantString("!activator")
		AcceptEntityInput(particle, "SetParent", client, particle, 0)
		SetVariantString(attachTo)
		AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0)
		ActivateEntity(particle)
		AcceptEntityInput(particle, "Start")
		
	}
	else
	{
		LogError("Failed to create info_particle_system!")
	}
	
}


//Delete Particle:

public Action:DeleteParticle(const delParticle)
{

	if (IsValidEdict(delParticle))
	{
		AcceptEntityInput(delParticle, "Stop")
		RemoveEdict(delParticle)
	}
	
}


public Action:InstantRespawn(Handle:timer, any:client)
{
	
	TF2_RespawnPlayer(client)
	
}


//Enable 100% crits:

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{

	if (miniGames && GetConVarBool(Cvar_TF2_MINIGAMES_CRITS))
	{
		if (miniGameMode == 2 || miniGameMode == 4) result = true
		else if (miniGameMode == 3)
		{
			if (IsClientIntruder(client)) result = true
		}
		else result = false
		return Plugin_Handled
	}
	return Plugin_Continue
	
}


public Action:ExplodePlayer(client)
{
	
	//Client explodes into gibs:
	new ent = CreateEntityByName("tf_ragdoll")
	decl Float:ClientOrigin[3]
	GetClientAbsOrigin(client, ClientOrigin)
	SetEntPropVector(ent, Prop_Send, "m_vecRagdollOrigin", ClientOrigin)
	SetEntProp(ent, Prop_Send, "m_iPlayerIndex", client)
	SetEntPropVector(ent, Prop_Send, "m_vecForce", NULL_VECTOR)
	SetEntPropVector(ent, Prop_Send, "m_vecRagdollVelocity", NULL_VECTOR)
	SetEntProp(ent, Prop_Send, "m_bGib", 1)
	TF2_RespawnPlayer(client)
	DispatchSpawn(ent)
	CreateTimer(10.0, DeleteGibs, ent)
	
}


public Action:DeleteGibs(Handle:timer, any:ent)
{

	if (IsValidEntity(ent))
    {
        CheckAndRemove(ent, "tf_ragdoll")
    }

}

public Action:CheckAndRemove(const ent, const String:compare[])
{

	if (IsValidEdict(ent))
	{
		GetEdictClassname(ent, classname, sizeof(classname))
		if (StrEqual(classname, compare, false))
		{
			RemoveEdict(ent)
		}
	}
	
}


public Action:StripToMelee(Handle:timer, any:client)
{

	if (IsValidClientId(client) && IsPlayerAlive(client)) 
	{
		for(new i = 0; i < 6; ++i)
		{
			if (i != 2)
			{
				if (TF2_GetPlayerClass(client) != TFClass_Spy)
				{
					TF2_RemoveWeaponSlot(client, i)
				}
				else
				{
					if (i != 4) TF2_RemoveWeaponSlot(client, i)
				}
			}
		}
		
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 2))
	}
	
}


public Action:DisableResupply()
{
	
	new ent = -1
	while ((ent = FindEntityByClassname(ent, "func_regenerate")) != -1)
	{
		AcceptEntityInput(ent, "Disable")
	}
	
}


public Action:EnableResupply()
{
	
	new ent = -1
	while ((ent = FindEntityByClassname(ent, "func_regenerate")) != -1)
	{
		AcceptEntityInput(ent, "Enable")
	}
	
}


public Action:EmitSoundToClients()
{

	for (new i = 1; i < MaxClients+1; ++i)
	{
		if (IsValidClientId(i)) EmitSoundToClient(i, SoundFile)
	}
	
}


public Action:FirstBloodSound()
{

	Format(SoundFile, 256, "%s%i.wav", "vo/announcer_am_firstblood0", GetRandomInt(1,6))
	EmitSoundToClients()

}


public Action:Dingaling(Handle:timer, any:client)
{

	if (IsValidClientId(client)) EmitSoundToClient(client, "ui/ding_a_ling.wav")
	
}


public Action:CountdownMessage(Handle:timer, any:seconds)
{

	if (seconds == 0)
	{
		CountdownTimer = INVALID_HANDLE
		ResetMiniGames()
	}
	else if (seconds == 60)
	{
		Format(SoundFile, sizeof(SoundFile), "vo/announcer_ends_60sec.wav")
		EmitSoundToClients()
	}
	else if (seconds == 30)
	{
		Format(SoundFile, sizeof(SoundFile), "vo/announcer_ends_30sec.wav")
		EmitSoundToClients()
	}
	else if (seconds <= 10)
	{
		PrintCenterTextAll("%t", "Countdown Message", seconds)
		if (seconds <= 5)
		{
			Format(SoundFile, sizeof(SoundFile), "vo/announcer_ends_%isec.wav", seconds)
			EmitSoundToClients()
		}
		else if (seconds == 10)
		{
			Format(SoundFile, sizeof(SoundFile), "vo/announcer_ends_10sec.wav")
			EmitSoundToClients()
		}
	}
	if (seconds > 0) CreateTimer(0.99, CountdownMessage, seconds-1)
	
}


public Action:PrintChatMessage(Handle:timer, any:client)
{
	SetMessages()
	if (IsValidClientId(client))
	{
		PrintToChat(client, "\x04=======================")
		PrintToChat(client, "\x04%s", ChatMessage)
		PrintToChat(client, "\x04=======================")
	}
	
}


public Action:HoldCenterMessage(Handle:timer, Handle:pack)
{

	decl client, seconds, wfp, String:msg[128]
	
	ResetPack(pack)
	client = ReadPackCell(pack)
	seconds = ReadPackCell(pack)
	wfp = ReadPackCell(pack)
	ReadPackString(pack, msg, 128)
	
	if (wfp == 1) Format(msg, 128, "%t", "Waiting Message", seconds)
	
	if (client == 0)
	{
		for (new i = 1; i < MaxClients+1; ++i)
		{
			if (IsValidClientId(i) && GetClientTeam(i) > 1) PrintCenterText(i, msg)
		}
	}
	else
	{
		if (IsValidClientId(client) && GetClientTeam(client) > 1) PrintCenterText(client, msg)
	}
	
	if (seconds > 0)
	{
		CreateDataTimer(0.99, HoldCenterMessage, pack)
		WritePackCell(pack, client)
		WritePackCell(pack, seconds-1)
		WritePackCell(pack, wfp)
		WritePackString(pack, msg)
	}
	
}


public Action:PrepareCenterMessage(Float:wait, client, wfp)
{

	decl String:msg[128]
	
	Format(msg, 128, CenterMessage)
	new Handle:pack
	CreateDataTimer(wait, HoldCenterMessage, pack)
	WritePackCell(pack, client)
	WritePackCell(pack, 8)
	WritePackCell(pack, wfp)
	WritePackString(pack, msg)

}


public Action:SetAllHeavy()
{
	
	for (new i = 1; i < MaxClients+1; ++i)
	{
		if (IsValidClientId(i) && IsPlayerAlive(i))
		{
			PreClass(i)
			TF2_SetPlayerClass(i, TFClass_Heavy, false, true)
			TF2_RespawnPlayer(i)
		}
	}
	
}


public Action:DisplayStats(teamWon)
{
	
	decl team
	
	if (miniGameMode == 2 || miniGameMode == 4)
	{
		decl String:redStr[256], String:bluStr[256], String:name[64]
		new redMax, bluMax, dupesRed, dupesBlu, winnersRed, winnersBlu
		
		//Find max score on both teams
		for (new i = 1; i < MaxClients+1; ++i)
		{
			if (IsValidClientId(i))
			{
				team = GetClientTeam(i)
				if (team == 2)
				{
					if (Kills[i] > redMax)
					{
						redMax = Kills[i]
					}
				}
				else if (team == 3)
				{
					if (Kills[i] > bluMax)
					{
						bluMax = Kills[i]
					}
				}
			}
		}
		
		//Find how many players have the same amount of kills on each team
		for (new i = 1; i < MaxClients+1; ++i)
		{
			if (IsValidClientId(i))
			{
				team = GetClientTeam(i)
				if (team == 2)
				{
					if (winnersRed < 5 && redMax > 0 && Kills[i] == redMax)
					{
						redWinner[winnersRed] = i
						++winnersRed
						
					}
				}
				else if (team == 3)
				{
					if (winnersBlu < 5 && bluMax > 0 && Kills[i] == bluMax)
					{
						bluWinner[winnersBlu] = i
						++winnersBlu
					}
				}
			}
		}
		
		//Compile list of winners on both teams
		for (new i = 1; i < MaxClients+1; ++i)
		{
			if (IsValidClientId(i))
			{
				team = GetClientTeam(i)
				if (team == 2)
				{
					if (redMax > 0 && Kills[i] >= redMax)
					{
						GetClientName(i, name, 32)
						if (dupesRed == 0)
						{
							Format(redStr, 256, "%s", name)
						}
						else if (dupesRed + 1 < winnersRed)
						{
							Format(redStr, 256, "%s\x04, \x05%s", redStr, name)
						}
						else
						{
							Format(redStr, 256, "%s \x04and \x05%s", redStr, name)
						}
						++dupesRed
					}
				}
				else if (team == 3)
				{
					if (bluMax > 0 && Kills[i] >= bluMax)
					{
						GetClientName(i, name, 32)
						if (dupesBlu == 0)
						{
							Format(bluStr, 256, "%s", name)
						}
						else if (dupesBlu + 1 < winnersBlu)
						{
							Format(bluStr, 256, "%s\x04, \x05%s", bluStr, name)
						}
						else
						{
							Format(bluStr, 256, "%s \x04and \x05%s", bluStr, name)
						}
						++dupesBlu
					}
				}
			}
		}
		
		
		if (winnersRed > 1) PrintToChatAll("\x05%s \x04 all had the highest kill streak on\x05 Red\x04 (%i)", redStr, redMax)
		else if (winnersRed == 1) PrintToChatAll("\x05%s \x04 had the highest kill streak on\x05 Red\x04 (%i)", redStr, redMax)
		if (redMax == 0) PrintToChatAll("\x04For shame! There were no teamkills on the \x05Red\x04 team!")
		
		if (winnersBlu > 1) PrintToChatAll("\x05%s \x04 had the highest kill streak on\x05 Blu\x04 (%i)", bluStr, bluMax)
		else if (winnersBlu == 1) PrintToChatAll("\x05%s \x04 had the highest kill streak on\x05 Blu\x04 (%i)", bluStr, bluMax)
		if (bluMax == 0) PrintToChatAll("\x04For shame! There were no teamkills on the \x05Blu\x04 team!")

		//Print stats message to clients
		for (new i = 1; i < MaxClients+1; ++i)
		{
			if (IsValidClientId(i) && GetClientTeam(i) > 1) PrintToChat(i, "\x05You had \x04(%i)\x05 teamkills.", Kills[i])
		}
		WinnerParticle(redWinner, bluWinner)
		
	}
	else if (miniGameMode == 5)
	{
		decl String:nameRed[64], String:nameBlu[64]
		for (new i = 1; i < MaxClients+1; ++i)
		{
			if (IsValidClientId(i))
			{
				team = GetClientTeam(i)
				if (team == teamWon)
				{
					if (team == 2) redWinner[0] = i
					else if (team == 3) bluWinner[0] = i
				}
			}
		}
		
		if (redWinner[0] > 0)
		{
			GetClientName(redWinner[0], nameRed, 32)
			PrintToChatAll("\x05%s \x04 was the last man standing on\x05 Red\x04!", nameRed)
		}
		if (bluWinner[0] > 0)
		{
			GetClientName(bluWinner[0], nameBlu, 32)
			PrintToChatAll("\x05%s \x04 was the last man standing on\x05 Blu\x04!", nameBlu)
		}
		WinnerParticle(redWinner, bluWinner)
	}
}


public Action:WinnerParticle(redW[], bluW[])
{

	decl rw, bw
	for (new i = 0; i < 5; ++i)
	{
		rw = redW[i]
		bw = bluW[i]
		if (IsValidClientId(rw))
		{
			AttachParticle(rw, 0, "achieved", "partyhat")
			AttachParticle(rw, 1, "bday_1balloon", "partyhat")
			AttachParticle(rw, 2, "bday_confetti", "partyhat")
			AttachParticle(rw, 3, "mini_fireworks", "partyhat")
			EmitSoundToClient(rw, "misc/happy_birthday.wav")
		}
		if (IsValidClientId(bw))
		{
			AttachParticle(bw, 0, "achieved", "partyhat")
			AttachParticle(bw, 1, "bday_1balloon", "partyhat")
			AttachParticle(bw, 2, "bday_confetti", "partyhat")
			AttachParticle(rw, 3, "mini_fireworks", "partyhat")
			EmitSoundToClient(bw, "misc/happy_birthday.wav")
		}
		
	}

}


public Action:PreClass(client)
{

	decl class
	switch(TF2_GetPlayerClass(client))
	{
		case TFClass_Scout:
			class = 1
		case TFClass_Soldier:
			class = 2
		case TFClass_Pyro:
			class = 3
		case TFClass_DemoMan:
			class = 4
		case TFClass_Heavy:
			class = 5
		case TFClass_Engineer:
			class = 6
		case TFClass_Medic:
			class = 7
		case TFClass_Sniper:
			class = 8
		case TFClass_Spy:
			class = 9
	}
	preClass[client] = class
	
}


public Action:ResetMiniGames()
{
	
	PrintCenterTextAll("%t", "MiniGame Completed Message", roundNum, GetConVarInt(Cvar_TF2_MINIGAMES_ROUNDS))
	
	firstBlood = false
	ServerCommand("mp_friendlyfire 0")
	
	if (miniGameMode == 2 || miniGameMode == 4) DisplayStats(1)
	RoundEndSound()
	
	if (roundNum == GetConVarInt(Cvar_TF2_MINIGAMES_ROUNDS))
	{
		CreateTimer(0.0, FinishReset)
		StopMiniGames()
	}
	else
	{
		++roundNum
		DetermineMode()
		if (miniGameMode == 5) SetAllHeavy()
		PrepareCenterMessage(6.0, 0, 0)
		CreateTimer(6.0, FinishReset)
		CreateTimer(6.0, CountdownMessage, GetConVarInt(Cvar_TF2_MINIGAMES_TIME))
	}
	
	//Prepare clients for next round
	for (new i = 1; i < MaxClients+1; ++i)
	{
		//Reset client specific variables
		clientSpawns[i] = 1
		Kills[i] = 0
		
		if (i < 5)
		{
			redWinner[i] = 0
			bluWinner[i] = 0
		}
		
		if (IsValidClientId(i))
		{
			
			//Remove all attached particles
			CheckAndRemove(clientParticle[i][0], "info_particle_system")
			CheckAndRemove(clientParticle[i][1], "info_particle_system")
			CheckAndRemove(clientParticle[i][2], "info_particle_system")
			
			if (IsPlayerAlive(i))
			{
				//Freeze the client
				SetEntityMoveType(i, MOVETYPE_NONE)
				
				//Change clients back to original class
				if (prevMiniGameMode == 5)
				{
					switch (preClass[i])
					{
						case 1:
							TF2_SetPlayerClass(i, TFClass_Scout, false, true)
						case 2:
							TF2_SetPlayerClass(i, TFClass_Soldier, false, true)
						case 3:
							TF2_SetPlayerClass(i, TFClass_Pyro, false, true)
						case 4:
							TF2_SetPlayerClass(i, TFClass_DemoMan, false, true)
						case 5:
							TF2_SetPlayerClass(i, TFClass_Heavy, false, true)
						case 6:
							TF2_SetPlayerClass(i, TFClass_Engineer, false, true)
						case 7:
							TF2_SetPlayerClass(i, TFClass_Medic, false, true)
						case 8:
							TF2_SetPlayerClass(i, TFClass_Sniper, false, true)
						case 9:
							TF2_SetPlayerClass(i, TFClass_Spy, false, true)
					}
					TF2_RespawnPlayer(i)
				}
				else ExplodePlayer(i)
			}
		}
	}
	
}


public Action:FinishReset(Handle:timer)
{

	for (new i = 1; i < MaxClients+1; ++i)
	{
		if (IsValidClientId(i)) SetEntityMoveType(i, MOVETYPE_WALK)
	}
	
}


public Action:StopMiniGames()
{
	
	miniGames = false
	ServerCommand("mp_friendlyfire 0")
	if (GetConVarBool(Cvar_TF2_MINIGAMES_PARTY)) ServerCommand("tf_birthday 0")
	if (CountdownTimer != INVALID_HANDLE) KillTimer(CountdownTimer)
	EnableResupply()
	roundNum = 1
	ServerCommand("mp_waitingforplayers_cancel 1")
	Format(SoundFile, 256, "%s", "vo/announcer_am_gamestarting05.wav")
	EmitSoundToClients()
	PrintToServer("(MiniGames Stopped)")
	
}


public OnClientDisconnect(client)
{

	if (miniGameMode == 2 || miniGameMode == 4)
	{
		CheckAndRemove(clientParticle[client][0], "info_particle_system")
		CheckAndRemove(clientParticle[client][1], "info_particle_system")
		CheckAndRemove(clientParticle[client][2], "info_particle_system")
	}
	Kills[client] = 0
	KillStreak[client] = 0
	messageFlag[client] = false
	
}
