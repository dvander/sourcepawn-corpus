/*=======================================================================================
* 	Plugin Info:
* 
*	Name	:	[L4D / L4D2] Achievement Trophy
*	Version	:	1.4
*	Author	:	SilverShot, retroGamer
*	Link	:	http://forums.alliedmods.net/showthread.php?t=136174
* 
* ========================================================================================
* 	Change Log:
* 
*	1.4 (merged 1.2&1.3)
*	- rG: Destroy running particle timers on round end / map end / changelevel / disconnect / plugin disable
*	- rG: Added convars for thirdpersonshoulder camera time (zero to disable) and how long trophies are shown
*	- rG: Added check if player is playing with thirdpersonshoulder camera to avoid forcing to first person
*	- rG: Saved client's previous cvar settings before changing thirdpersonshoulder cvars and restore them
*	- Added spawning info_particle_system by honorcode23 on event round_start (from v1.3)
*	- rG: Return client back to first person mode and restore cvar settings if ClientView-timer is running and map changes
*	- rG: Disabled trophy effect when finale_vehicle_leaving event fires temporarily until OnMapStart()
*	- rG: Added trophy effect redrawing and convar for turning it on/off
*	- rG: Added convar variable for turning off save&restore for client convars
*	- rG: Added convar variables for thirdpersoncamera settings. You can't override default limits.
*	- rG: Added check for dead players / changing team
*
*	1.3
* 	- Added version cvar.
* 	- Attempted to cache particles by playing OnClientPutInServer.
* 
*	1.2
* 	- Added more particles (mini fireworks)!
* 	- UnhookEvent when plugin turned off.
* 
*	1.1.1
* 	- Removed 1 event per second limit.
* 
*	1.1
* 	- Moved event hook from OnMapStart to OnPluginStart
* 
*	1.0
* 	- Initial release.
* 
* ========================================================================================
* 
* 	This plugin was made using source code from the following plugins.
* 	If I have used your code and not credited you, please let me know.
* 
*	Thanks to "L. Duke" for " TF2 Particles via TempEnts" tutorial
* 	http://forums.alliedmods.net/showthread.php?t=75102
* 
*	Thanks to "Muridias" for updating "L. Duke"s code
* 	http://forums.alliedmods.net/showpost.php?p=836836&postcount=28
* 
*	Thanks to "panxiaohai" for "l4d_3rdnotbind_en" which is the ThirdPerson view
* 	http://forums.alliedmods.net/showpost.php?p=1204040&postcount=23
* 
*	See warnings about destroying particle timers by "KickBack" at:
* 	http://forums.alliedmods.net/showpost.php?p=669713&postcount=12
* ======================================================================================
*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#define CVAR_FLAGS 				FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define PLUGIN_VERSION			"1.4"

new iPluginEnabled;
new Handle:hPluginEnabled = INVALID_HANDLE;
new Handle:hTrophyShowTime = INVALID_HANDLE;
new Handle:hTrophyThirdPerson = INVALID_HANDLE;
new Handle:hTrophyLoopEffect = INVALID_HANDLE;
new Handle:hTrophySaveConVars = INVALID_HANDLE;

// convar camera variables for thirdperson
new Handle:hTPSOffset = INVALID_HANDLE;
new Handle:hTPSAimdist = INVALID_HANDLE;
new Handle:hTPSCamIdealLag = INVALID_HANDLE;
new Handle:hTPSCamIdealDist = INVALID_HANDLE;

// handle tables for running timers
new Handle:hTimerAchieved[MAXPLAYERS+1];
new Handle:hTimerMiniFireworks[MAXPLAYERS+1];
new Handle:hTimerClientView[MAXPLAYERS+1];
new Handle:hTimerLoopEffect[MAXPLAYERS+1];

// store if ConVarQuery is running for client
new bool:bConVarQuery[MAXPLAYERS+1];
// save clients replaced convars in trie so it's possible to restore them
new Handle:hCVSaveTrie[MAXPLAYERS+1];

// disable effect after rescue vehicle leaves
new bRescueVehicleLeaving = false;

// L4D1 or L4D2, scavenge events are not available on L4D1
new String:s_GameName[128];

public Plugin:myinfo =
{
	name = "[L4D & L4D2] Achievement Trophy",
	author = "SilverShot, retroGamer",
	description = "Displays the TF2 trophy when somebody unlocks an achievement, also can switch display in ThirdPerson view.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=136174"
}

public OnPluginStart()
{
	// Game check.
	GetGameFolderName(s_GameName, sizeof(s_GameName));
	if (StrContains(s_GameName, "left4dead") < 0) SetFailState("l4d_achievement_trophy plugin only supports Left4Dead");

	// Cvars
	hPluginEnabled = CreateConVar("l4d_trophy_enabled", "2", "0=Disables, 1=Enables, 2=Enables with 3rd person view. Turn the plugin on.", CVAR_FLAGS, true, 0.0, true, 2.0);
	hTrophyShowTime = CreateConVar("l4d_trophy_showtime", "12.0", "How long trophies are shown in seconds?", CVAR_FLAGS, true, 4.0, true, 900.0);
	hTrophyThirdPerson = CreateConVar("l4d_trophy_thirdpersontime", "4.0", "How long thirdperson view is shown in seconds? Zero disables changing to thirdperson view.", CVAR_FLAGS, true, 0.0, true, 900.0);
	hTrophyLoopEffect = CreateConVar("l4d_trophy_loopeffect", "1.0", "View trophy effect multiple times until l4d_trophy_showtime is up? If not, trophy effect is shown only once. 0=Show once, 1=Show again.", CVAR_FLAGS, true, 0.0, true, 1.0);
	hTrophySaveConVars = CreateConVar("l4d_trophy_saveconvars", "1.0", "Save and restore client camera setting convars? 0=No, 1=Save.", CVAR_FLAGS, true, 0.0, true, 1.0);

	hTPSOffset = CreateConVar("l4d_trophy_tpsoffset", "0", "To which value c_thirdpersonshoulderoffset is changed when using thirdperson camera. You can't override default limits.", CVAR_FLAGS);
	hTPSAimdist = CreateConVar("l4d_trophy_tpsaimdist", "720", "To which value c_thirdpersonshoulderaimdist is changed when using thirdperson camera. You can't override default limits.", CVAR_FLAGS);
	hTPSCamIdealLag = CreateConVar("l4d_trophy_camideallag", "0", "To which value cam_ideallag is changed when using thirdperson camera. You can't override default limits.", CVAR_FLAGS);
	hTPSCamIdealDist =  CreateConVar("l4d_trophy_camidealdist", "100", "To which value cam_idealdist is changed when using thirdperson camera. You can't override default limits.", CVAR_FLAGS);

	AutoExecConfig(true, "l4d_achievement_trophy");

	// If you want to test out trophy effect, uncomment these lines and corresponding functions at the end of file
	// RegConsoleCmd("sm_testparticle", Test_AttachParticle, "Test attaching trophy");
	// RegConsoleCmd("sm_stopparticle", Test_StopParticle, "Stop attaching trophy");


	// Hooks
	HookEvents();

	HookConVarChange(hPluginEnabled, ConVarChanged_Enable);
	iPluginEnabled = GetConVarInt(hPluginEnabled);
}


public ConVarChanged_Enable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	iPluginEnabled = GetConVarBool(hPluginEnabled);
	new i = StringToInt(newValue);
	if (StringToInt(oldValue) > 0 && i > 0) return; //Already hooked

	if (i > 0) {
		HookEvents();
	}else{
		UnhookEvents();
		DestroyParticleTimers();
	}
}

HookEvents()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("achievement_earned", Event_Achievement);
	HookEvent("mission_lost", Event_DestroyParticleTimers, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_DestroyParticleTimers, EventHookMode_PostNoCopy);
	HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath); // remove effect when player dies
	HookEvent("player_team", Event_PlayerTeam);   // remove effect when player changes team
	// not tested, check if scavenge events work
	if (StrEqual(s_GameName, "left4dead2", false))
	{
		HookEvent("scavenge_round_halftime", Event_DestroyParticleTimers, EventHookMode_PostNoCopy);
		HookEvent("scavenge_round_finished", Event_DestroyParticleTimers, EventHookMode_PostNoCopy);
	}
}

UnhookEvents()
{
	UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	UnhookEvent("achievement_earned", Event_Achievement);
	UnhookEvent("mission_lost", Event_DestroyParticleTimers, EventHookMode_PostNoCopy);
	UnhookEvent("round_end", Event_DestroyParticleTimers, EventHookMode_PostNoCopy);
	UnhookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving, EventHookMode_PostNoCopy);
	UnhookEvent("player_death", Event_PlayerDeath);
	UnhookEvent("player_team", Event_PlayerTeam);
	if (StrEqual(s_GameName, "left4dead2", false))
	{
		UnhookEvent("scavenge_round_halftime", Event_DestroyParticleTimers, EventHookMode_PostNoCopy);
		UnhookEvent("scavenge_round_finished", Event_DestroyParticleTimers, EventHookMode_PostNoCopy);
	}
}

public OnMapStart()
{
	bRescueVehicleLeaving = false;
}

public OnClientPutInServer(client)
{
	// When client enters in the game change view back to first person
	// and restore cvars if camera mode was changed during previous map.
	// Player in clientslot is checked to have same UID as player reserving clientslot on previous map.
	if (hTimerClientView[client] != INVALID_HANDLE)
	{
		// Return client back to first person view
		TriggerTimer(hTimerClientView[client]);
	}
}

public OnClientDisconnect(client)
{
	// Run TriggerTimer to remove particle entities from world
	if (hTimerAchieved[client] != INVALID_HANDLE)
	{
		TriggerTimer(hTimerAchieved[client]);
	}
	if (hTimerMiniFireworks[client] != INVALID_HANDLE)
	{
		TriggerTimer(hTimerMiniFireworks[client]);
	}

	// Run all ClientView timers over map change to restore camera view & convar settings

	// Stop ongoing convar queries for client and clear trie
	// This will prevent errors which could happen when client gets achievement just before changelevel
	// and convar query callback is waiting for result when map changes / on plugin unload
	if (bConVarQuery[client] == true)
	{
		bConVarQuery[client] = false;
		if (hCVSaveTrie[client] != INVALID_HANDLE)
		{
			CloseHandle(hCVSaveTrie[client]);
			hCVSaveTrie[client] = INVALID_HANDLE;
		}
	}
}

// -- Private functions --

StartParticleTimers(client)
{
	// Add achievement particles to user
	// if there are already timer running, do not add new one
	// client is always checked to be in game before calling this
	if (hTimerAchieved[client] == INVALID_HANDLE)
	{
		hTimerAchieved[client] = AttachParticle(client, "achieved", GetConVarFloat(hTrophyShowTime));
	}
	if (hTimerMiniFireworks[client] == INVALID_HANDLE)
	{
		hTimerMiniFireworks[client] = AttachParticle(client, "mini_fireworks", GetConVarFloat(hTrophyShowTime));
	}
}

DestroyParticleTimers()
{
	// Trigger all remaining timers to remove particle entities and clean up handle tables
	for (new i = 1; i <= MAXPLAYERS; i++)
	{
		if (hTimerAchieved[i] != INVALID_HANDLE)
		{
			TriggerTimer(hTimerAchieved[i]);
		}
		if (hTimerMiniFireworks[i] != INVALID_HANDLE)
		{
			TriggerTimer(hTimerMiniFireworks[i]);
		}
		if (hTimerClientView[i] != INVALID_HANDLE)
		{
			// Return client back to first person view
			TriggerTimer(hTimerClientView[i]);
		}

		bConVarQuery[i] = false;
		if (hCVSaveTrie[i] != INVALID_HANDLE)
		{
			CloseHandle(hCVSaveTrie[i]);
			hCVSaveTrie[i] = INVALID_HANDLE;
		}
	}
}

ForceIntoThirdPerson(client)
{
	ClientCommand(client, "thirdpersonshoulder");
	ClientCommand(client, "c_thirdpersonshoulderoffset %d", GetConVarInt(hTPSOffset));
	ClientCommand(client, "c_thirdpersonshoulderaimdist %d", GetConVarInt(hTPSAimdist));
	ClientCommand(client, "cam_ideallag %d", GetConVarInt(hTPSCamIdealLag));
	ClientCommand(client, "cam_idealdist %d", GetConVarInt(hTPSCamIdealDist));
}

Handle:AttachParticle(ent, String:particleType[], Float:time=10.0)
{

	if (ent < 1)
	{
		// this should never happen
		return INVALID_HANDLE;
	}

	new particle = CreateEntityByName("info_particle_system");

	if (IsValidEdict(particle))
	{
		decl String:tName[32];
		new Float:pos[3];

		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 60;

		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);

		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		if (DispatchSpawn(particle))
		{
			TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
			SetVariantString(tName);
			AcceptEntityInput(particle, "SetParent", particle, particle, 0);
			
			// see http://developer.valvesoftware.com/wiki/Point_clientcommand AddOutput explanation
			// and http://developer.valvesoftware.com/wiki/User_Inputs_and_Outputs
			// and http://developer.valvesoftware.com/wiki/Inputs_and_Outputs
			
			SetVariantString("OnUser1 !self,Start,,0.0,-1");
			AcceptEntityInput(particle, "AddOutput");
			SetVariantString("OnUser2 !self,Stop,,4.0,-1");
			AcceptEntityInput(particle, "AddOutput");
			ActivateEntity(particle);
			AcceptEntityInput(particle, "FireUser1");
			AcceptEntityInput(particle, "FireUser2");

			// create timer to delete created particles
			// return created timer handle
			new Handle:pack;
			new Handle:hTimer;
			hTimer = CreateDataTimer(time, DeleteParticle, pack);
			WritePackCell(pack, particle); // particle entity ID
			WritePackString(pack, particleType); // string of particle type
			WritePackCell(pack, ent); // attached client

			// effect redraw timer
			if (GetConVarInt(hTrophyLoopEffect))
			{
				// Achievement trophy seems to be visible about 4 secs
				// mini_fireworks about 3 secs
				new Handle:packLoop;
				hTimerLoopEffect[ent] = CreateDataTimer(4.2, LoopParticleEffect, packLoop, TIMER_REPEAT);
				WritePackCell(packLoop, particle); // particle entity ID
				WritePackCell(packLoop, ent); // attached client
			}

			return hTimer;

		} else {
			// DispatchSpawn failed for some reason
			if (IsValidEdict(particle))
			{
				RemoveEdict(particle);
			}
			return INVALID_HANDLE;
		}
	}
	return INVALID_HANDLE;
}

RemoveTrophyFromPlayer(client)
{
	if (hTimerAchieved[client] != INVALID_HANDLE)
	{
		TriggerTimer(hTimerAchieved[client]);
	}
	if (hTimerMiniFireworks[client] != INVALID_HANDLE)
	{
		TriggerTimer(hTimerMiniFireworks[client]);
	}
	if (hTimerClientView[client] != INVALID_HANDLE)
	{
		TriggerTimer(hTimerClientView[client]);
	}
	if (bConVarQuery[client] == true)
	{
		bConVarQuery[client] = false;
		if (hCVSaveTrie[client] != INVALID_HANDLE)
		{
			CloseHandle(hCVSaveTrie[client]);
			hCVSaveTrie[client] = INVALID_HANDLE;
		}
	}
}

// -- Events --

public Action:Event_Achievement(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	if (!iPluginEnabled)
	{
		return Plugin_Continue;
	}

	if (bRescueVehicleLeaving)
	{
		return Plugin_Continue;
	}

	// Player ID
	new client = GetEventInt(h_Event, "player");
	if (client < 1)
	{
		//"ClientCommand" reported: Client index 0 is invalid
		return Plugin_Continue;
	}

	// event_achievement returns directly player's entity/client index
	if (IsClientInGame(client))
	{
		if (IsClientConnected(client))
		{
			// Do not create effect on dead players as it draws on spectated player
			if (IsPlayerAlive(client))
			{
				// Do not create effect on spectators
				if (GetClientTeam(client) != 1)
				{
					// Skip thirdpersonshoulder camera check section if it's not enabled or time is zero
					if ( (iPluginEnabled == 1) || (GetConVarFloat(hTrophyThirdPerson) == 0.0) )
					{
						StartParticleTimers(client);

					} else {
						// Note: there is delay between client convar query start and result, about 0.06-0.4 seconds
						// Check if we are running query already (e.g. client unlocks more than one achievement)
						// or there are already particle/ClientView timers running
						if ( (bConVarQuery[client] == false) && (hTimerAchieved[client] == INVALID_HANDLE) && (hTimerMiniFireworks[client] == INVALID_HANDLE) && (hTimerClientView[client] == INVALID_HANDLE) )
						{
							new QueryCookie:QC = QUERYCOOKIE_FAILED;
							QC = QueryClientConVar(client, "c_thirdpersonshoulder", ConVarQueryFinished:QCV_CheckClientTPSCamera);
							if (QC != QUERYCOOKIE_FAILED)
							{
								bConVarQuery[client] = true;
							}
						}
					}
				}
			}
		} // IsClientConnected
	} // IsClientInGame

	return Plugin_Continue;
}

public Action:Event_DestroyParticleTimers(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	DestroyParticleTimers();

	return Plugin_Continue;
}

public Action:Event_FinaleVehicleLeaving(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Disable effects temporarily as player characters are not visible until OnMapStart
	bRescueVehicleLeaving = true;
	DestroyParticleTimers();

	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Remove trophy effect from player as trophy will redraw on whoever player spectates

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0)
	{
		if (IsClientConnected(client))
		{
			if (IsClientInGame(client))
			{
				if (!IsFakeClient(client))
				{
					RemoveTrophyFromPlayer(client);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Remove trophy effect from player on team change (infected are usually in spawn mode and spectators are not visible)

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new oldteam = GetEventInt(event, "oldteam");

	// skip new players/temporary bots joining in game
	if (oldteam != 0)
	{
		if (client > 0)
		{
			if (IsClientConnected(client))
			{
				if (IsClientInGame(client))
				{
					if (!IsFakeClient(client))
					{
						RemoveTrophyFromPlayer(client);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{

	// particle effects are already precached because they are in particles_manifest.txt
	// mini_fireworks is in particles/steamworks.pcf
	// materials/effects/achieved.vtf is also precached, checked with if(IsGenericPrecached)

	// This was posted by honorcode23 on Sourcemod forums under this plugin thread.
	// Modified code to avoid timer. CS:S weapons can be "prespawned" with same logic.
	// Not sure if particles need to be started at all.

	new Particle;
	Particle = CreateEntityByName("info_particle_system");
	if(IsValidEntity(Particle) && IsValidEdict(Particle))
	{
		DispatchKeyValue(Particle, "effect_name", "achieved");
		if (DispatchSpawn(Particle))
		{
			ActivateEntity(Particle);
			AcceptEntityInput(Particle, "start");
			RemoveEdict(Particle);
		}
	}
	Particle = CreateEntityByName("info_particle_system");
	if(IsValidEntity(Particle) && IsValidEdict(Particle))
	{
		DispatchKeyValue(Particle, "effect_name", "mini_fireworks");
		if (DispatchSpawn(Particle))
		{
			ActivateEntity(Particle);
			AcceptEntityInput(Particle, "start");
			RemoveEdict(Particle);
		}
	}

	return Plugin_Continue;
}

// -- Convar Queries --

public QCV_CheckClientTPSCamera(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{

	if (IsClientInGame(client))
	{
		if (IsClientConnected(client))
		{
			// Check for result and run more convar queries to store client's old settings
			if ( (bConVarQuery[client] = true) && (result == ConVarQuery_Okay) )
			{

				// Convert query result back to integer, non-numbers are converted to zero
				// client variables may contain strings (e.g. "; something")
				new iCameraSetting = StringToInt(cvarValue);

				// Check if client plays with thirdpersonshoulder camera
				// this avoids inverse effect, forcing to first person camera
				// change camera settings if zero (first person)
				if (iCameraSetting == 0)
				{
					// Optional saving of client's old camera settings
					if (GetConVarInt(hTrophySaveConVars))
					{
						// For storing client settings
						hCVSaveTrie[client] = CreateTrie();

						new QueryCookie:QC = QUERYCOOKIE_FAILED;

						QC = QueryClientConVar(client, "c_thirdpersonshoulderoffset", ConVarQueryFinished:QCV_SaveClientSettings);
						if (QC == QUERYCOOKIE_FAILED)
						{
							// on error change state so it's possible to stop ongoing processing in QCV_SaveClientSettings for other queries
							bConVarQuery[client] = false;
						}
						if (bConVarQuery[client])
						{
							QC = QueryClientConVar(client, "c_thirdpersonshoulderaimdist", ConVarQueryFinished:QCV_SaveClientSettings);
							if (QC == QUERYCOOKIE_FAILED)
							{
								bConVarQuery[client] = false;
							}
						}
						if (bConVarQuery[client])
						{
							QC = QueryClientConVar(client, "cam_ideallag", ConVarQueryFinished:QCV_SaveClientSettings);
							if (QC == QUERYCOOKIE_FAILED)
							{
								bConVarQuery[client] = false;
							}
						}
						if (bConVarQuery[client])
						{
							QC = QueryClientConVar(client, "cam_idealdist", ConVarQueryFinished:QCV_SaveClientSettings);
							if (QC == QUERYCOOKIE_FAILED)
							{
								bConVarQuery[client] = false;
							}
						}

						// On error close trie handle as it's not needed anymore
						if (bConVarQuery[client] == false)
						{
							// PrintToChatAll("QCV_CheckClientTPSCamera: error occurred during query init, closing trie.");
							CloseHandle(hCVSaveTrie[client]);
							hCVSaveTrie[client] = INVALID_HANDLE;
						}

					} else {
						// Admin has selected not to save client convars when changing camera settings
						bConVarQuery[client] = false;
						
						// Do trophy particle effect on client
						StartParticleTimers(client);

						ForceIntoThirdPerson(client);
						
						hTimerClientView[client] = CreateTimer(GetConVarFloat(hTrophyThirdPerson), ChangeView, client);
					}

				} else {
					// Client is using thirdpersonshoulder camera, do not change camera settings
					// PrintToChatAll("QCV_CheckClientTPSCamera: client is using third person camera.");
					bConVarQuery[client] = false;
					StartParticleTimers(client);
				}

			} else {
				// Query failed, show only trophy effect
				// PrintToChatAll("QCV_CheckClientTPSCamera query failed.");
				bConVarQuery[client] = false;
				StartParticleTimers(client);
			}
		} // IsClientConnected
	} // IsClientInGame
}

public QCV_SaveClientSettings(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{

	if (IsClientInGame(client))
	{
		if (IsClientConnected(client))
		{
			if ( (bConVarQuery[client] == true) && (result == ConVarQuery_Okay) )
			{
				// Convert query result back to integer, non-numbers are converted to zero
				// client variables may contain strings (e.g. "; something")
				new iClientConVar = StringToInt(cvarValue);

				if (StrEqual(cvarName, "c_thirdpersonshoulderoffset", true))
				{
					SetTrieValue(hCVSaveTrie[client], "c_thirdpersonshoulderoffset", iClientConVar);
				}
				else if (StrEqual(cvarName, "c_thirdpersonshoulderaimdist", true))
				{
					SetTrieValue(hCVSaveTrie[client], "c_thirdpersonshoulderaimdist", iClientConVar);
				}
				else if (StrEqual(cvarName, "cam_ideallag", true))
				{
					SetTrieValue(hCVSaveTrie[client], "cam_ideallag", iClientConVar);
				}
				else if (StrEqual(cvarName, "cam_idealdist", true))
				{
					SetTrieValue(hCVSaveTrie[client], "cam_idealdist", iClientConVar);
				}

				// when all convars have been returned, start particle effect
				// if some convars are never returned, trie is cleaned on client disconnect / map end / plugin unload
				if (GetTrieSize(hCVSaveTrie[client]) == 4)
				{
					// PrintToChatAll("Trie size is 4, starting effect.");
					bConVarQuery[client] = false;

					// Save client ID also in trie for checking and restoring camera view if map changes
					decl String:strSteamID[64];
					GetClientAuthString(client, strSteamID, sizeof(strSteamID));
					SetTrieString(hCVSaveTrie[client], "steamid", strSteamID);

					// Do trophy particle effect on client
					StartParticleTimers(client);

					ForceIntoThirdPerson(client);

					hTimerClientView[client] = CreateTimer(GetConVarFloat(hTrophyThirdPerson), ChangeView, client);
				}
			} else {
				// it is better not to use thirdpersonshoulder camera as client settings can't be saved
				bConVarQuery[client] = false;
				if (hCVSaveTrie[client] != INVALID_HANDLE)
				{
					CloseHandle(hCVSaveTrie[client]);
					hCVSaveTrie[client] = INVALID_HANDLE;
				}
				// Do only particle effect without thirdpersonshoulder camera
				StartParticleTimers(client);
			}
		} // IsClientConnected
	} // IsClientInGame
}

// -- Timers --

public Action:ChangeView(Handle:timer, any:client)
{

	if (IsClientInGame(client))
	{
		if (IsClientConnected(client))
		{
			ClientCommand(client, "thirdpersonshoulder");
			ClientCommand(client, "c_thirdpersonshoulder 0");

			if (hCVSaveTrie[client] != INVALID_HANDLE)
			{
				// Check client user id in case map has been changed and wrong client is in clientslot
				decl String:strSteamID[64];
				GetClientAuthString(client, strSteamID, sizeof(strSteamID));

				decl String:strTrieSteamID[64];
				GetTrieString(hCVSaveTrie[client], "steamid", strTrieSteamID, sizeof(strTrieSteamID));

				if (StrEqual(strSteamID, strTrieSteamID, true))
				{
					// Restore old settings
					decl String:strClientCommand[48];
					new iTPSOffset;
					new iTPSAimDist;
					new iCamLag;
					new iCamDist;

					GetTrieValue(hCVSaveTrie[client], "c_thirdpersonshoulderoffset", iTPSOffset);
					GetTrieValue(hCVSaveTrie[client], "c_thirdpersonshoulderaimdist", iTPSAimDist);
					GetTrieValue(hCVSaveTrie[client], "cam_ideallag", iCamLag);
					GetTrieValue(hCVSaveTrie[client], "cam_idealdist", iCamDist);

					Format(strClientCommand, sizeof(strClientCommand), "c_thirdpersonshoulderoffset %d", iTPSOffset);
					ClientCommand(client, strClientCommand);
					Format(strClientCommand, sizeof(strClientCommand), "c_thirdpersonshoulderaimdist %d", iTPSAimDist);
					ClientCommand(client, strClientCommand);
					Format(strClientCommand, sizeof(strClientCommand), "cam_ideallag %d", iCamLag);
					ClientCommand(client, strClientCommand);
					Format(strClientCommand, sizeof(strClientCommand), "cam_idealdist %d", iCamDist);
					ClientCommand(client, strClientCommand);
				}
			}
		}
	}

	// client might be map changing/disconnected at this point
	// close possible handle to trie and clean handle table
	if (hCVSaveTrie[client] != INVALID_HANDLE)
	{
		CloseHandle(hCVSaveTrie[client]);
		hCVSaveTrie[client] = INVALID_HANDLE;
	}

	// remove timer handle from table
	hTimerClientView[client] = INVALID_HANDLE;
}


public Action:LoopParticleEffect(Handle:timer, Handle:pack)
{

	ResetPack(pack);
	new particle = ReadPackCell(pack);
	new client = ReadPackCell(pack);

	if (IsValidEntity(particle))
	{
		decl String:classname[128];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "FireUser1");
			AcceptEntityInput(particle, "FireUser2");
			return Plugin_Continue;
		}
	}
	// If particles are removed by game, kill the timer
	hTimerLoopEffect[client] = INVALID_HANDLE;
	return Plugin_Stop;
}


public Action:DeleteParticle(Handle:timer, Handle:pack)
{
	decl String:particleType[32];

	ResetPack(pack);
	new particle = ReadPackCell(pack);
	ReadPackString(pack, particleType, sizeof(particleType));
	new client = ReadPackCell(pack); // for cleaning handle tables, not used to refer actual client in game

	// if there is repeating particle effect, kill looping timer
	if (hTimerLoopEffect[client] != INVALID_HANDLE)
	{
		KillTimer(hTimerLoopEffect[client]);
		hTimerLoopEffect[client] = INVALID_HANDLE;
	}

	if (IsValidEntity(particle))
	{
		decl String:classname[128];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			RemoveEdict(particle);
		}
	}

	// Clear stored timer handles from handle table or else when trying to clear them on player disconnect,
	// map change or server quit they might cause Kill/TriggerTimer errors if timers are already gone
	if (StrEqual(particleType, "achieved", true))
	{
		hTimerAchieved[client] = INVALID_HANDLE;
	} else if (StrEqual(particleType, "mini_fireworks", true)) {
		hTimerMiniFireworks[client] = INVALID_HANDLE;
	}
}

// -- Test stuff --

// FOR TESTING, REMOVE
/*
public Action:Test_AttachParticle(client, args)
{
	// event_achievement returns directly player's entity/client index
	if (IsClientInGame(client))
	{
		if (IsClientConnected(client))
		{
			// Do not create effect on dead players as it draws on spectated player
			if (IsPlayerAlive(client))
			{
				// Do not create effect on spectators
				if (GetClientTeam(client) != 1)
				{
					// Skip thirdpersonshoulder camera check section if it's not enabled or time is zero
					if ( (iPluginEnabled == 1) || (GetConVarFloat(hTrophyThirdPerson) == 0.0) )
					{
						StartParticleTimers(client);
					} else {
						// Note: there is delay between client convar query start and result, about 0.06-0.4 seconds
						// Check if we are running query already (e.g. client unlocks more than one achievement)
						// or there are already particle/ClientView timers running
						if ( (bConVarQuery[client] == false) && (hTimerAchieved[client] == INVALID_HANDLE) && (hTimerMiniFireworks[client] == INVALID_HANDLE) && (hTimerClientView[client] == INVALID_HANDLE) )
						{
							new QueryCookie:QC = QUERYCOOKIE_FAILED;
							QC = QueryClientConVar(client, "c_thirdpersonshoulder", ConVarQueryFinished:QCV_CheckClientTPSCamera);
							if (QC != QUERYCOOKIE_FAILED)
							{
								bConVarQuery[client] = true;
							}
						}
					}
				}
			}
		} // IsClientConnected
	} // IsClientInGame

	return Plugin_Handled;
}
*/

// FOR TESTING, REMOVE
/*
public Action:Test_StopParticle(client, args)
{
	DestroyParticleTimers();

	return Plugin_Handled;
}
*/