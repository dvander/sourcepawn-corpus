enum // Collision_Group_t in const.h
{
	COLLISION_GROUP_NONE  = 0,
	COLLISION_GROUP_DEBRIS,			// Collides with nothing but world and static stuff
	COLLISION_GROUP_DEBRIS_TRIGGER, // Same as debris, but hits triggers
	COLLISION_GROUP_INTERACTIVE_DEBRIS,	// Collides with everything except other interactive debris or debris
	COLLISION_GROUP_INTERACTIVE,	// Collides with everything except interactive debris or debris
	COLLISION_GROUP_PLAYER,
	COLLISION_GROUP_BREAKABLE_GLASS,
	COLLISION_GROUP_VEHICLE,
	COLLISION_GROUP_PLAYER_MOVEMENT,  // For HL2, same as Collision_Group_Player, for
										// TF2, this filters out other players and CBaseObjects
	COLLISION_GROUP_NPC,			// Generic NPC group
	COLLISION_GROUP_IN_VEHICLE,		// for any entity inside a vehicle
	COLLISION_GROUP_WEAPON,			// for any weapons that need collision detection
	COLLISION_GROUP_VEHICLE_CLIP,	// vehicle clip brush to restrict vehicle movement
	COLLISION_GROUP_PROJECTILE,		// Projectiles!
	COLLISION_GROUP_DOOR_BLOCKER,	// Blocks entities not permitted to get near moving doors
	COLLISION_GROUP_PASSABLE_DOOR,	// ** sarysa TF2 note: Must be scripted, not passable on physics prop (Doors that the player shouldn't collide with)
	COLLISION_GROUP_DISSOLVING,		// Things that are dissolving are in this group
	COLLISION_GROUP_PUSHAWAY,		// ** sarysa TF2 note: I could swear the collision detection is better for this than NONE. (Nonsolid on client and server, pushaway in player code)

	COLLISION_GROUP_NPC_ACTOR,		// Used so NPCs in scripts ignore the player.
	COLLISION_GROUP_NPC_SCRIPTED,	// USed for NPCs in scripts that should not collide with each other

	LAST_SHARED_COLLISION_GROUP
};

#define ARG_LENGTH 256

bool PRINT_DEBUG_INFO = true;
bool PRINT_DEBUG_SPAM = false;

#define NOPE_AVI "vo/engineer_no01.mp3" // DO NOT DELETE FROM FUTURE PACKS

#define INVALID_ENTREF INVALID_ENT_REFERENCE

// text string limits
#define MAX_SOUND_FILE_LENGTH 80
#define MAX_MODEL_FILE_LENGTH 128
#define MAX_MATERIAL_FILE_LENGTH 128
#define MAX_WEAPON_NAME_LENGTH 64
#define MAX_WEAPON_ARG_LENGTH 256
#define MAX_EFFECT_NAME_LENGTH 48
#define MAX_ENTITY_CLASSNAME_LENGTH 48
#define MAX_CENTER_TEXT_LENGTH 256
#define MAX_RANGE_STRING_LENGTH 66
#define MAX_HULL_STRING_LENGTH 197
#define MAX_ATTACHMENT_NAME_LENGTH 48
#define COLOR_BUFFER_SIZE 12
#define HEX_OR_DEC_STRING_LENGTH 12 // max -2 billion is 11 chars + null termination
#define MAX_TERMINOLOGY_LENGTH 24
#define MAX_ABILITY_NAME_LENGTH 33
#define MAX_KILL_ID_LENGTH 33

#define FAR_FUTURE 100000000.0

// common array limits
#define MAX_CONDITIONS 10 // TF2 conditions (bleed, dazed, etc.)

#define MAX_PLAYERS_ARRAY 36
#define MAX_PLAYERS (MAX_PLAYERS_ARRAY < (MaxClients + 1) ? MAX_PLAYERS_ARRAY : (MaxClients + 1))

bool NULL_BLACKLIST[MAX_PLAYERS_ARRAY];

TFTeam MercTeam = TFTeam_Red;
TFTeam BossTeam = TFTeam_Blue;

bool RoundInProgress = false;
bool PluginActiveThisRound = false;

#define SAXTON_KEY_RELOAD 0
#define SAXTON_KEY_SPECIAL 1
#define SAXTON_KEY_ALT_FIRE 2
#define MAX_RAGE_SOUNDS 3

#define IsEmptyString(%1) (%1[0] == 0)

bool SAO_CanUse[MAX_PLAYERS_ARRAY];
TFCond SAO_SlamConditions[MAX_PLAYERS_ARRAY][MAX_CONDITIONS]; // arg2
// args 12-19 aren't initialized
#define MAX_KILL_ID_LENGTH 33
#define SH_MAX_HUD_FORMAT_LENGTH 30

#define SS_JUMP_FORCE 800.0
#define SS_EFFECT_GROUNDPOUND1 "hammer_impact_button_dust2"
#define SS_EFFECT_GROUNDPOUND2 "hammer_impact_button_ring"
bool SS_ActiveThisRound;
bool SS_CanUse[MAX_PLAYERS_ARRAY];
bool SS_IsUsing[MAX_PLAYERS_ARRAY]; // internal
bool SS_KeyDown[MAX_PLAYERS_ARRAY]; // internal
float SS_PreparingUntil[MAX_PLAYERS_ARRAY]; // internal
float SS_TauntingUntil[MAX_PLAYERS_ARRAY]; // internal
float SS_OnCooldownUntil[MAX_PLAYERS_ARRAY]; // internal
float SS_NoSlamUntil[MAX_PLAYERS_ARRAY]; // internal, workaround for a bug where slam sometimes happens in midair
SS_PropEntRef[MAX_PLAYERS_ARRAY]; // internal
bool SS_WasFirstPerson[MAX_PLAYERS_ARRAY]; // internal
TFClassType SS_OldClass[MAX_PLAYERS_ARRAY]; // internal, lets a soldier do the party trick taunt
SS_DesiredKey[MAX_PLAYERS_ARRAY]; // based on arg1
float SS_Cooldown[MAX_PLAYERS_ARRAY]; // arg2
float SS_RageCost[MAX_PLAYERS_ARRAY]; // arg3
SS_ForcedTaunt[MAX_PLAYERS_ARRAY]; // arg4
float SS_PropDelay[MAX_PLAYERS_ARRAY]; // arg5
char SS_PropModel[MAX_MODEL_FILE_LENGTH]; // arg6
float SS_GravityDelay[MAX_PLAYERS_ARRAY]; // arg7
float SS_GravitySetting[MAX_PLAYERS_ARRAY]; // arg8
float SS_MaxDamage[MAX_PLAYERS_ARRAY]; // arg9
float SS_Radius[MAX_PLAYERS_ARRAY]; // arg10
float SS_DamageDecayExponent[MAX_PLAYERS_ARRAY]; // arg11
float SS_BuildingDamageFactor[MAX_PLAYERS_ARRAY]; // arg12
float SS_Knockback[MAX_PLAYERS_ARRAY]; // arg13
//float SS_PitchConstraint[MAX_PLAYERS_ARRAY][2]; // arg14
// arg14 and arg15 only used at rage time
char SS_CooldownError[MAX_CENTER_TEXT_LENGTH]; // arg16
char SS_NotEnoughRageError[MAX_CENTER_TEXT_LENGTH]; // arg17
char SS_NotMidairError[MAX_CENTER_TEXT_LENGTH]; // arg18
char SS_WeighdownError[MAX_CENTER_TEXT_LENGTH]; // arg19

Handle healTimer = INVALID_HANDLE;

//bool SH_ActiveThisRound;
//bool SH_CanUse[MAX_PLAYERS_ARRAY];
float SH_NextHUDAt[MAX_PLAYERS_ARRAY];
float SH_HUDInterval[MAX_PLAYERS_ARRAY];
SH_LastHPValue[MAX_PLAYERS_ARRAY];
Handle SH_NormalHUDHandle;
Handle SH_AlertHUDHandle;
//float SH_HudY[MAX_PLAYERS_ARRAY];
char SH_HudFormat[MAX_PLAYERS_ARRAY][SH_MAX_HUD_FORMAT_LENGTH];
bool SH_DisplayHealth[MAX_PLAYERS_ARRAY];
bool SH_DisplayRage[MAX_PLAYERS_ARRAY];
//char SH_LungeReadyStr[MAX_CENTER_TEXT_LENGTH];
//char SH_LungeNotReadyStr[MAX_CENTER_TEXT_LENGTH];
char SH_SlamReadyStr[MAX_CENTER_TEXT_LENGTH];
char SH_SlamNotReadyStr[MAX_CENTER_TEXT_LENGTH];
//char SH_BerserkReadyStr[MAX_CENTER_TEXT_LENGTH];
//char SH_BerserkNotReadyStr[MAX_CENTER_TEXT_LENGTH];
//SH_NormalColor[MAX_PLAYERS_ARRAY];
//SH_AlertColor[MAX_PLAYERS_ARRAY];
bool SH_AlertIfNotReady[MAX_PLAYERS_ARRAY];
char SH_HealthStr[MAX_CENTER_TEXT_LENGTH];
char SH_RageStr[MAX_CENTER_TEXT_LENGTH];
bool SH_AlertOnLowHP[MAX_PLAYERS_ARRAY];

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    Saxton_Cleanup(); // Clean up previous round state
    
    BossTeam = TFTeam_Blue;
    RoundInProgress = true;
    
    // Initialize variables for this round
    PluginActiveThisRound = false;
    SS_ActiveThisRound = false;
    
    // Initialize arrays for each client
    for (int clientIdx = 1; clientIdx <= MAX_PLAYERS; clientIdx++)
    {
        // Initialize player state
        SS_CanUse[clientIdx] = false;
        int bossIdx = IsLivingPlayer(clientIdx) ? VSH2_GetBossIndex(clientIdx) : -1;
        
        if (bossIdx < 0)
            continue;
        
        // When a player is a valid boss
        SS_CanUse[clientIdx] = true;
        PluginActiveThisRound = true;
        SS_ActiveThisRound = true;
        SS_IsUsing[clientIdx] = false;
        SS_PropEntRef[clientIdx] = INVALID_ENTREF;
        SS_OnCooldownUntil[clientIdx] = 1.0;
        SS_PreparingUntil[clientIdx] = FAR_FUTURE;
        SS_TauntingUntil[clientIdx] = FAR_FUTURE;

        SS_DesiredKey[clientIdx] = 1;
        SS_Cooldown[clientIdx] = 15.0;
        SS_RageCost[clientIdx] = 1.0;
        SS_ForcedTaunt[clientIdx] = 1114;
        SS_PropDelay[clientIdx] = 5.0;
        SS_GravityDelay[clientIdx] = 5.0;
        SS_GravitySetting[clientIdx] = 10.0;
        SS_MaxDamage[clientIdx] = 200.0;
        SS_Radius[clientIdx] = 1000.0;
        SS_DamageDecayExponent[clientIdx] = 1.3;
        SS_BuildingDamageFactor[clientIdx] = 1.5;
        SS_Knockback[clientIdx] = 1000.0;
        SS_SlamSound(bossIdx, false); // precache sound for slam

        // Initialize key state for ability trigger
        SS_KeyDown[clientIdx] = (GetClientButtons(clientIdx) & SS_DesiredKey[clientIdx]) != 0;
    }
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	RoundInProgress = false;
	Saxton_Cleanup();
}

public void Saxton_Cleanup()
{
	if (!PluginActiveThisRound)
		return;

	PluginActiveThisRound = false;
	
	// remove prethink. also fix gravity, because it leaks.
	if (SS_ActiveThisRound)
	{
		SS_ActiveThisRound = false;
		
		UnhookEvent("player_death", Saxton_PlayerDeath, EventHookMode_Pre);
	
		for (int clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (IsClientInGame(clientIdx))
			{
			}

			if (SS_CanUse[clientIdx]) // do this even if they're dead
				SS_RemoveProp(clientIdx);
				
			// remove megaheal, in case somehow in some configuration this doesn't reset on round change
			if (IsLivingPlayer(clientIdx) && TF2_IsPlayerInCondition(clientIdx, TFCond_MegaHeal))
				TF2_RemoveCondition(clientIdx, TFCond_MegaHeal);
		}
	}
}

public int Saxton_GetKey(int bossIdx, const char[] abilityName, int argIdx)
{
    int keyId = 1;
    if (keyId == SAXTON_KEY_RELOAD)
        return IN_RELOAD;
    else if (keyId == SAXTON_KEY_SPECIAL)
        return IN_ATTACK3;
    else if (keyId == SAXTON_KEY_ALT_FIRE)
        return IN_ATTACK2;

    PrintToServer("[improved_saxton] ERROR: Invalid key ID specified for %s. Ability has no key assigned and cannot be executed.", abilityName);
    
    return -1; // vagy egy érvénytelen int érték
}

public Action Saxton_PreThink(int clientIdx)
{
	if (!IsLivingPlayer(clientIdx))
		return;
		
	if (SS_CanUse[clientIdx])
		SS_PreThink(clientIdx);
}

public Action SS_SlamSound(int bossIdx, bool play)
{
	static char soundName[MAX_SOUND_FILE_LENGTH];
	//ReadSound(bossIdx, SS_STRING, 15, soundName);
	if (play && strlen(soundName) > 3)
	{
		EmitSoundToAll("mvm/mvm_tank_start.wav");
		EmitSoundToAll("mvm/mvm_tank_start.wav");
	}
}

public Action SS_RemoveProp(int clientIdx)
{
	if (SS_PropEntRef[clientIdx] == INVALID_ENTREF)
		return;
		
	RemoveEntity(SS_PropEntRef[clientIdx]);
	SS_PropEntRef[clientIdx] = INVALID_ENTREF;
}

public float SS_CalculateDamage(int clientIdx, float distance)
{
	float damage;
	if (SS_DamageDecayExponent[clientIdx] <= 0.0)
		damage = SS_MaxDamage[clientIdx];
	else if (SS_DamageDecayExponent[clientIdx] == 1.0)
		damage = SS_MaxDamage[clientIdx] * (1.0 - (distance / SS_Radius[clientIdx]));
	else
	{
		damage = SS_MaxDamage[clientIdx] - (SS_MaxDamage[clientIdx] * (Pow(Pow(SS_Radius[clientIdx], SS_DamageDecayExponent[clientIdx]) -
			Pow(SS_Radius[clientIdx] - distance, SS_DamageDecayExponent[clientIdx]), 1.0 / SS_DamageDecayExponent[clientIdx]) / SS_Radius[clientIdx]));
	}
		
	return fmax(1.0, damage);
}

public bool SS_RageAvailable(int clientIdx, float  curTime, bool reportError)
{
	int  bossIdx = VSH2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
		return false;
		
	if (VSH2_GetBossCharge(bossIdx, 0) < SS_RageCost[clientIdx])
	{
		if (reportError)
		{
			if (!IsEmptyString(SS_NotEnoughRageError))
				PrintCenterText(clientIdx, SS_NotEnoughRageError, SS_RageCost[clientIdx]);
			Nope(clientIdx);
		}
		return false;
	}

	if (GetEntityGravity(clientIdx) == 6.0)
	{
		if (reportError)
		{
			if (!IsEmptyString(SS_WeighdownError))
				PrintCenterText(clientIdx, "SS_WeighdownError");
			Nope(clientIdx);
		}
		return false;
	}
	
	if (GetEntityFlags(clientIdx) & (FL_ONGROUND | FL_SWIM | FL_INWATER))
	{
		if (reportError)
		{
			if (!IsEmptyString(SS_NotMidairError))
				PrintCenterText(clientIdx, SS_NotMidairError);
			Nope(clientIdx);
		}
		return false;
	}
	
	if (SS_OnCooldownUntil[clientIdx] > curTime)
	{
		if (reportError)
		{
			if (!IsEmptyString(SS_CooldownError))
				PrintCenterText(clientIdx, SS_CooldownError);
			Nope(clientIdx);
		}
		return false;
	}
	
	// fail silently if the user is stunned or taunting
	if (TF2_IsPlayerInCondition(clientIdx, TFCond_Dazed) || TF2_IsPlayerInCondition(clientIdx, TFCond_Taunting))
		return false;
		
	// don't allow while other rages are active
	if ((SS_CanUse[clientIdx] && SS_IsUsing[clientIdx]))
		return false;
	
	// all conditions passed
	return true;
}

public Action SS_CreateEarthquake(int clientIdx)
{
	float amplitude = 16.0;
	float radius = SS_Radius[clientIdx];
	float duration = 5.0;
	float frequency = 255.0;

	int earthquake = CreateEntityByName("env_shake");
	if (IsValidEntity(earthquake))
	{
		static float halePos[3];
		GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", halePos);
	
		DispatchKeyValueFloat(earthquake, "amplitude", amplitude);
		DispatchKeyValueFloat(earthquake, "radius", radius * 2);
		DispatchKeyValueFloat(earthquake, "duration", duration + 2.0);
		DispatchKeyValueFloat(earthquake, "frequency", frequency);

		SetVariantString("spawnflags 4"); // no physics (physics is 8), affects people in air (4)
		AcceptEntityInput(earthquake, "AddOutput");

		// create
		DispatchSpawn(earthquake);
		TeleportEntity(earthquake, halePos, NULL_VECTOR, NULL_VECTOR);

		AcceptEntityInput(earthquake, "StartShake", 0);
		//CreateTimer(duration + 0.1, RemoveEntity, EntIndexToEntRef(earthquake), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action SS_Initiate(int clientIdx, float curTime)
{
	// remove rage
	int bossIdx = VSH2_GetBossIndex(clientIdx);
	if (bossIdx < 0)
		return;
	VSH2_SetBossCharge(bossIdx, 0, VSH2_GetBossCharge(bossIdx, 0) - SS_RageCost[clientIdx]);
	
	// remove FOV effect, fixing an issue where lunge immediately followed by slam traps user in a higher FOV
	SetEntProp(clientIdx, Prop_Send, "m_iFOV", GetEntProp(clientIdx, Prop_Send, "m_iDefaultFOV"));
	SetEntPropFloat(clientIdx, Prop_Send, "m_flFOVTime", 0.0);
	
	SS_TauntingUntil[clientIdx] = curTime + SS_PropDelay[clientIdx];
	SS_NoSlamUntil[clientIdx] = SS_TauntingUntil[clientIdx] + 0.2;
	SS_PreparingUntil[clientIdx] = curTime + SS_GravityDelay[clientIdx];
	SS_OnCooldownUntil[clientIdx] = curTime + SS_Cooldown[clientIdx];
	SS_IsUsing[clientIdx] = true;
	float vector[3] = {0.0, 0.0, 0.0};
	TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, vector); // stop velocity

	// set immobile and immovable
	SetEntityMoveType(clientIdx, MOVETYPE_NONE);
	TF2_AddCondition(clientIdx, TFCond_MegaHeal, -1.0);
	Saxton_AddConditions(clientIdx, SAO_SlamConditions[clientIdx]);
	if (strlen(SS_PropModel) > 3)
	{
		SS_RemoveProp(clientIdx); // in case the cooldown is zero and this rage is spammable
		int prop = CreateEntityByName("prop_physics");
		if (IsValidEntity(prop))
		{
			SetEntityModel(prop, SS_PropModel);
			DispatchSpawn(prop);
			static float spawnPos[3];
			GetEntPropVector(clientIdx, Prop_Data, "m_vecOrigin", spawnPos);
			TeleportEntity(prop, spawnPos, NULL_VECTOR, NULL_VECTOR);
			SetEntProp(prop, Prop_Data, "m_takedamage", 0);

			SetEntityMoveType(prop, MOVETYPE_NONE);
			SetEntProp(prop, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_NONE);
			SS_PropEntRef[clientIdx] = EntIndexToEntRef(prop);

			SetEntityRenderMode(prop, RENDER_TRANSCOLOR);
			SetEntityRenderColor(prop, 255, 255, 255, 0);
		}
	}

	// force third person during the rage
	SS_WasFirstPerson[clientIdx] = (GetEntProp(clientIdx, Prop_Send, "m_nForceTauntCam") == 0);
	SetVariantInt(1);
	AcceptEntityInput(clientIdx, "SetForcedTauntCam");

	// force the taunt. if the prop is good, this'll work.
	if (SS_ForcedTaunt[clientIdx] > 0)
	{
		SetEntProp(clientIdx, Prop_Send, "m_fFlags", GetEntProp(clientIdx, Prop_Send, "m_fFlags") | FL_ONGROUND);
		SS_OldClass[clientIdx] = TF2_GetPlayerClass(clientIdx);
		TFClassType newClass = GetClassOfTaunt(SS_ForcedTaunt[clientIdx], SS_OldClass[clientIdx]);
		if (SS_OldClass[clientIdx] != newClass)
			TF2_SetPlayerClass(clientIdx, newClass);
		ForceUserToTaunt(clientIdx, SS_ForcedTaunt[clientIdx]);
	}

	// disable dynamic abilities during the rage.
	//DD_SetDisabled(clientIdx, true, true, true, true);
}

public Action SS_OnPlayerRunCmd(int clientIdx, int buttons, float curTime)
{
	bool keyDown = (buttons & SS_DesiredKey[clientIdx]) != 0;
	if (keyDown && !SS_KeyDown[clientIdx] && SS_RageAvailable(clientIdx, curTime, true))
		SS_Initiate(clientIdx, curTime);
	
	SS_KeyDown[clientIdx] = keyDown;
	return Plugin_Continue;
}

public Action SS_PreThink(int clientIdx)
{
	float curTime = GetEngineTime();
	if (SS_IsUsing[clientIdx])
	{
		if (curTime >= SS_TauntingUntil[clientIdx])
		{
			SS_TauntingUntil[clientIdx] = FAR_FUTURE;
			SetEntityMoveType(clientIdx, MOVETYPE_WALK);
			float highjump[3] = {0.0, 0.0, SS_JUMP_FORCE};
			TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, highjump); // simulate a high jump
			SS_RemoveProp(clientIdx);
			
			// fix their class
			if (SS_ForcedTaunt[clientIdx] > 0 && TF2_GetPlayerClass(clientIdx) != SS_OldClass[clientIdx])
				TF2_SetPlayerClass(clientIdx, SS_OldClass[clientIdx]);
		}
		else if (SS_TauntingUntil[clientIdx] != FAR_FUTURE) // this is plus the prop's physics rect are necessary for the trick to work
		{
			if (SS_ForcedTaunt[clientIdx] > 0 && !TF2_IsPlayerInCondition(clientIdx, TFCond_Taunting))
			{
				SetEntProp(clientIdx, Prop_Send, "m_fFlags", GetEntProp(clientIdx, Prop_Send, "m_fFlags") | FL_ONGROUND);
				ForceUserToTaunt(clientIdx, SS_ForcedTaunt[clientIdx]);
			}
		}
		
		if (SS_PreparingUntil[clientIdx] != FAR_FUTURE && SS_TauntingUntil[clientIdx] == FAR_FUTURE)
		{
			if (curTime >= SS_PreparingUntil[clientIdx])
			{
				SS_PreparingUntil[clientIdx] = FAR_FUTURE;
				float downward[3] = {0.0, 0.0, -200.0};
				TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, downward); // give them a head start downward
				SetEntityGravity(clientIdx, SS_GravitySetting[clientIdx]); // set gravity now
				PrintToServer("Slam executed for client %d with gravity setting %f", clientIdx, SS_GravitySetting[clientIdx]);
			}
			else
			{
				// if player hits a ceiling, suspend them in midair until it's time to fall
				static float velocity[3];
				GetEntPropVector(clientIdx, Prop_Data, "m_vecVelocity", velocity);
				if (velocity[2] < 0.0)
				{
					velocity[2] = 0.0;
					TeleportEntity(clientIdx, NULL_VECTOR, NULL_VECTOR, velocity);
				}
			}
		}
	
		if (SS_PreparingUntil[clientIdx] == FAR_FUTURE)
		{
			if (curTime >= SS_NoSlamUntil[clientIdx] && (GetEntityFlags(clientIdx) & FL_ONGROUND) != 0)
			{
				// damage nearby players, but make this unhooked damage if it's under two thirds of the user's HP
				// or if it's a spy.
				static float halePos[3];
				GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", halePos);
				
				// either use override particle or default
				static char effect1[MAX_EFFECT_NAME_LENGTH];
				static char effect2[MAX_EFFECT_NAME_LENGTH];
				bool override = false;
				if (SAO_CanUse[clientIdx])
				{
					int bossIdx = VSH2_GetBossIndex(clientIdx);
					if (bossIdx >= 0)
					{
						if (!IsEmptyString(effect1) || !IsEmptyString(effect2))
							override = true;
					}
				}
				
				if (!override)
				{
					effect1 = SS_EFFECT_GROUNDPOUND1;
					effect2 = SS_EFFECT_GROUNDPOUND2;
				}
	
				if (!IsEmptyString(effect1))
					ParticleEffectAt(halePos, effect1, 1.0);
				if (!IsEmptyString(effect2))
					ParticleEffectAt(halePos, effect2, 1.0);
				
				for (int victim = 1; victim < MAX_PLAYERS; victim++)
				{
					if (!IsLivingPlayer(victim) || GetClientTeam(victim) == 2)
						continue;
					else if (IsTreadingWater(victim) || IsFullyInWater(victim) || CheckGroundClearance(victim, 80.0, true))
						continue;
						
					static float victimPos[3];
					GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
					float distance = GetVectorDistance(halePos, victimPos);
					if (distance >= SS_Radius[clientIdx])
						continue;
					
					// knockback first
					static float angles[3];
					static float velocity[3];
					GetVectorAnglesTwoPoints(halePos, victimPos, angles);
					GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
					ScaleVector(velocity, SS_Knockback[clientIdx]);
					if ((GetEntityFlags(victim) & FL_ONGROUND) != 0 && velocity[2] < 500.0) // minimum Z, gives victims lift
					velocity[2] = 500.0;
					TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, velocity);
						
					// apply the damage
					if (SS_MaxDamage[clientIdx] > 0.0)
					{
						float damage = SS_CalculateDamage(clientIdx, distance);
						if (TF2_GetPlayerClass(victim) == TFClass_Spy || float(GetEntProp(victim, Prop_Send, "m_iHealth")) * 0.66 >= damage)
							SDKHooks_TakeDamage(victim, clientIdx, clientIdx, damage, DMG_PREVENT_PHYSICS_FORCE, -1);
						else
							FullyHookedDamage(victim, clientIdx, clientIdx, fixDamageForVSH2(damage), DMG_PREVENT_PHYSICS_FORCE, -1);
					}
				}
				
				// damage nearby buildings
				if (SS_MaxDamage[clientIdx] > 0.0 && SS_BuildingDamageFactor[clientIdx] > 0.0) for (int pass = 0; pass <= 2; pass++)
				{
					static char classname[MAX_ENTITY_CLASSNAME_LENGTH];
					if (pass == 0) classname = "obj_sentrygun";
					else if (pass == 1) classname = "obj_dispenser";
					else if (pass == 2) classname = "obj_teleporter";
					
					int building = MaxClients + 1;
					while ((building = FindEntityByClassname(building, classname)) != -1)
					{
						if (GetEntProp(building, Prop_Send, "m_bCarried") || GetEntProp(building, Prop_Send, "m_bPlacing"))
							continue;
					
						static float buildingPos[3];
						GetEntPropVector(building, Prop_Send, "m_vecOrigin", buildingPos);
						float distance = GetVectorDistance(buildingPos, halePos);
						if (distance >= SS_Radius[clientIdx])
							continue;
							
						float damage = SS_CalculateDamage(clientIdx, distance);
						SDKHooks_TakeDamage(building, clientIdx, clientIdx, damage * SS_BuildingDamageFactor[clientIdx], DMG_GENERIC, -1);
					}
				}
				
				int bossIdx = VSH2_GetBossIndex(clientIdx);
				if (bossIdx >= 0)
				SS_SlamSound(bossIdx, true);
				SS_CreateEarthquake(clientIdx);
			}
			
			// end the rage if on ground or in water. (in water, it'll fail to do damage)
			if (curTime >= SS_NoSlamUntil[clientIdx] && ((GetEntityFlags(clientIdx) & FL_ONGROUND) != 0 || IsFullyInWater(clientIdx)))
			{
				SS_IsUsing[clientIdx] = false;
				if (TF2_IsPlayerInCondition(clientIdx, TFCond_MegaHeal))
				TF2_RemoveCondition(clientIdx, TFCond_MegaHeal);
				Saxton_RemoveConditions(clientIdx, SAO_SlamConditions[clientIdx]);

				SetEntityGravity(clientIdx, 1.0);
				//DD_SetDisabled(clientIdx, false, false, false, false);
				
				if (SS_WasFirstPerson[clientIdx])
				{
					SetVariantInt(0);
					AcceptEntityInput(clientIdx, "SetForcedTauntCam");
				}
			}
			else
			{
				// ensure gravity hasn't been changed, i.e. by default_abilities
				if (GetEntityGravity(clientIdx) != SS_GravitySetting[clientIdx])
					SetEntityGravity(clientIdx, SS_GravitySetting[clientIdx]);
			}
		}
	}
}

public Action SH_PreThink(int clientIdx)
{
	if (GetClientButtons(clientIdx) & IN_SCORE)
		return; // Don't show hud when player is viewing scoreboard, as it will only flash violently

	float curTime = GetEngineTime();
	
	if (curTime >= SH_NextHUDAt[clientIdx])
	{
		SH_NextHUDAt[clientIdx] = curTime + SH_HUDInterval[clientIdx];
		int bossIdx = VSH2_GetBossIndex(clientIdx);
		if (bossIdx < 0)
			return;
		
		// format health str
		static char healthStr[80];
		healthStr = "";
#if defined VSP_VERSION
		int hp = VSH2_GetBossMax(bossIdx);
#else
		int hp = GetEntProp(clientIdx, Prop_Send, "m_iHealth"); // see my rant about this at the bottom of this file.
#endif
		if ((hp - SH_LastHPValue[clientIdx]) <= 5) // this way it'll be wrong, but relatively stable in appearance
			hp = SH_LastHPValue[clientIdx];
		else
			SH_LastHPValue[clientIdx] = hp;
		int maxHP = VSH2_GetBossMaxHealth(bossIdx);
		if (SH_DisplayHealth[clientIdx])
			Format(healthStr, sizeof(healthStr), SH_HealthStr, hp, maxHP);
		bool healthIsAlert = (SH_AlertOnLowHP[clientIdx] ? (hp * 3 <= maxHP) : false);

		// format rage str
		static char rageStr[80];
		rageStr = "";
		if (SH_DisplayRage[clientIdx])
			Format(rageStr, sizeof(rageStr), SH_RageStr, VSH2_GetBossCharge(bossIdx, 0));

		static char slamStr[MAX_CENTER_TEXT_LENGTH];
		bool slamAvailable = (SS_CanUse[clientIdx] && SS_RageAvailable(clientIdx, curTime, false));
		if (!SS_CanUse[clientIdx])
			slamStr = "";
		else
			Format(slamStr, sizeof(slamStr), (slamAvailable ? SH_SlamReadyStr : SH_SlamNotReadyStr), SS_RageCost[clientIdx]);
		bool slamIsAlert = (slamAvailable && !SH_AlertIfNotReady[clientIdx]) || (!slamAvailable && SH_AlertIfNotReady[clientIdx]);

		// normal HUD
		SetHudTextParams(-1.0, 1.0, 1.0 + 0.05, 128,128,128, 192);
		ShowSyncHudText(clientIdx, SH_NormalHUDHandle, SH_HudFormat[clientIdx], (!healthIsAlert ? healthStr : ""), rageStr,
					(!slamIsAlert ? slamStr : "Ability is on cooldown!"));
		
		// alert HUD
		SetHudTextParams(-1.0, 1.0, 1.0 + 0.05, 128,128,128, 192);
		ShowSyncHudText(clientIdx, SH_AlertHUDHandle, SH_HudFormat[clientIdx], (healthIsAlert ? healthStr : ""), "",
					(slamIsAlert ? slamStr : "Not enough rage! %.0f rage required."));
	}
}

public void OnGameFrame() {
    TickTock(GetEngineTime());
}

public void TickTock(float currentTime)
{
	if (!PluginActiveThisRound || !RoundInProgress)
		return;

	// need this fallback for multi-boss, as the invisible prop has collision
	if (SS_ActiveThisRound)
	{
		for (int clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		{
			if (SS_CanUse[clientIdx] && !IsLivingPlayer(clientIdx))
				SS_RemoveProp(clientIdx);
		}
	}
}

public Action OnPlayerRunCmd(int clientIdx, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!PluginActiveThisRound || !RoundInProgress)
		return Plugin_Continue;
	else if (!IsLivingPlayer(clientIdx))
		return Plugin_Continue;
		
	Action ret = Plugin_Continue;
		
	if (SS_ActiveThisRound && SS_CanUse[clientIdx])
		SS_OnPlayerRunCmd(clientIdx, buttons, GetEngineTime());
	
	return ret;
}

stock int ParticleEffectAt(float position[3], const char[] effectName, float duration = 0.1)
{
	if (strlen(effectName) < 3)
		return -1; // nothing to display
		
	int particle = CreateEntityByName("info_particle_system");
	if (particle != -1)
	{
		TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "effect_name", effectName);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		//if (duration > 0.0)
			//CreateTimer(duration, RemoveEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
	}
	return particle;
}

stock int AttachParticle(int entity, const char[] particleType, float offset=0.0, bool attach=true)
{
	new particle = CreateEntityByName("info_particle_system");
	
	if (!IsValidEntity(particle))
		return -1;

	decl String:targetName[128];
	decl Float:position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[2] += offset;
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	Format(targetName, sizeof(targetName), "target%i", entity);
	DispatchKeyValue(entity, "targetname", targetName);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(targetName);
	if (attach)
	{
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	}
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	return particle;
}

// adapted from the above and Friagram's halloween 2013 (which standing alone did not work for me)
stock int AttachParticleToAttachment(int entity, const char[] particleType, const char[] attachmentPoint) // m_vecAbsOrigin. you're welcome.
{
	new particle = CreateEntityByName("info_particle_system");
	
	if (!IsValidEntity(particle))
		return -1;

	decl String:targetName[128];
	decl Float:position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	Format(targetName, sizeof(targetName), "target%i", entity);
	DispatchKeyValue(entity, "targetname", targetName);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(targetName);
	AcceptEntityInput(particle, "SetParent", particle, particle, 0);
	SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	
	SetVariantString(attachmentPoint);
	AcceptEntityInput(particle, "SetParentAttachment");

	if (!IsEmptyString(particleType))
	{
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
	}
	return particle;
}

public Action RemoveEntityNoTele(Handle timer, any entid)
{
	int entity = EntRefToEntIndex(entid);
	if (IsValidEdict(entity) && entity > MaxClients)
		AcceptEntityInput(entity, "Kill");
}

stock bool IsLivingPlayer(int clientIdx)
{
	if (clientIdx <= 0 || clientIdx >= MAX_PLAYERS)
		return false;
		
	return IsClientInGame(clientIdx) && IsPlayerAlive(clientIdx);
}

stock bool IsValidBoss(int clientIdx)
{
	if (!IsLivingPlayer(clientIdx))
		return false;
		
	return GetClientTeam(clientIdx) == BossTeam;
}

stock bool IsPlayerInRange(int player, float position[3], float maxDistance)
{
	maxDistance *= maxDistance;
	
	static float playerPos[3];
	GetEntPropVector(player, Prop_Data, "m_vecOrigin", playerPos);
	return GetVectorDistance(position, playerPos, true) <= maxDistance;
}

stock bool FindRandomPlayer(bool isBossTeam, float position[3] = NULL_VECTOR, float maxDistance = 0.0, bool anyTeam = false, bool deadOnly = false)
{
	return FindRandomPlayerBlacklist(isBossTeam, NULL_BLACKLIST, position, maxDistance, anyTeam, deadOnly);
}

stock bool FindRandomPlayerBlacklist(bool isBossTeam, const bool blacklist[MAX_PLAYERS_ARRAY], float position[3] = NULL_VECTOR, float maxDistance = 0.0, bool anyTeam = false, bool deadOnly = false)
{
	new player = -1;

	// first, get a player count for the team we care about
	new playerCount = 0;
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!deadOnly && !IsLivingPlayer(clientIdx))
			continue;
		else if (deadOnly)
		{
			if (!IsClientInGame(clientIdx) || IsLivingPlayer(clientIdx))
				continue;
		}
			
		if (!deadOnly && maxDistance > 0.0 && !IsPlayerInRange(clientIdx, position, maxDistance))
			continue;
			
		if (blacklist[clientIdx])
			continue;

		// fixed to not grab people in spectator, since we can now include the dead
		new bool:valid = anyTeam && (GetClientTeam(clientIdx) == BossTeam || GetClientTeam(clientIdx) == MercTeam);
		if (!valid)
			valid = (isBossTeam && GetClientTeam(clientIdx) == BossTeam) || (!isBossTeam && GetClientTeam(clientIdx) == MercTeam);
			
		if (valid)
			playerCount++;
	}

	// ensure there's at least one living valid player
	if (playerCount <= 0)
		return -1;

	// now randomly choose our victim
	new rand = GetRandomInt(0, playerCount - 1);
	playerCount = 0;
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!deadOnly && !IsLivingPlayer(clientIdx))
			continue;
		else if (deadOnly)
		{
			if (!IsClientInGame(clientIdx) || IsLivingPlayer(clientIdx))
				continue;
		}
			
		if (!deadOnly && maxDistance > 0.0 && !IsPlayerInRange(clientIdx, position, maxDistance))
			continue;

		if (blacklist[clientIdx])
			continue;

		// fixed to not grab people in spectator, since we can now include the dead
		new bool:valid = anyTeam && (GetClientTeam(clientIdx) == BossTeam || GetClientTeam(clientIdx) == MercTeam);
		if (!valid)
			valid = (isBossTeam && GetClientTeam(clientIdx) == BossTeam) || (!isBossTeam && GetClientTeam(clientIdx) == MercTeam);
			
		if (valid)
		{
			if (playerCount == rand) // needed if rand is 0
			{
				player = clientIdx;
				break;
			}
			playerCount++;
			if (playerCount == rand) // needed if rand is playerCount - 1, executes for all others except 0
			{
				player = clientIdx;
				break;
			}
		}
	}
	
	return player;
}

stock bool CheckLineOfSight(float position[3], int targetEntity, float zOffset)
{
	static float targetPos[3];
	GetEntPropVector(targetEntity, Prop_Send, "m_vecOrigin", targetPos);
	targetPos[2] += zOffset;
	static float angles[3];
	GetVectorAnglesTwoPoints(position, targetPos, angles);
	
	Handle trace = TR_TraceRayFilterEx(position, angles, (CONTENTS_SOLID | CONTENTS_WINDOW | CONTENTS_GRATE), RayType_Infinite, TraceWallsOnly);
	static Float:endPos[3];
	TR_GetEndPosition(endPos, trace);
	CloseHandle(trace);
	
	return GetVectorDistance(position, targetPos, true) <= GetVectorDistance(position, endPos, true);
}
			
stock bool FindRandomSpawn(bool bluSpawn, bool redSpawn)
{
	new spawn = -1;

	// first, get a spawn count for the team(s) we care about
	new spawnCount = 0;
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "info_player_teamspawn")) != -1)
	{
		new teamNum = GetEntProp(entity, Prop_Send, "m_iTeamNum");
		if ((teamNum == BossTeam && bluSpawn) || (teamNum != BossTeam && redSpawn))
			spawnCount++;
	}

	// ensure there's at least one valid spawn
	if (spawnCount <= 0)
		return -1;

	// now randomly choose our spawn
	new rand = GetRandomInt(0, spawnCount - 1);
	spawnCount = 0;
	while ((entity = FindEntityByClassname(entity, "info_player_teamspawn")) != -1)
	{
		new teamNum = GetEntProp(entity, Prop_Send, "m_iTeamNum");
		if ((teamNum == BossTeam && bluSpawn) || (teamNum != BossTeam && redSpawn))
		{
			if (spawnCount == rand)
				spawn = entity;
			spawnCount++;
			if (spawnCount == rand)
				spawn = entity;
		}
	}
	
	return spawn;
}

stock int GetLivingMercCount()
{
	// recalculate living players
	new livingMercCount = 0;
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
		if (IsLivingPlayer(clientIdx) && GetClientTeam(clientIdx) != BossTeam)
			livingMercCount++;
	
	return livingMercCount;
}
	
stock int ParseFloatRange(const char rangeStr[MAX_RANGE_STRING_LENGTH], float &min, float &max)
{
	char rangeStrs[2][32];
	ExplodeString(rangeStr, ";", rangeStrs, 2, 32);
	min = StringToFloat(rangeStrs[0]);
	max = StringToFloat(rangeStrs[1]);
}

stock int ParseHull(char hullStr[MAX_HULL_STRING_LENGTH], float hull[2][3])
{
	char hullStrs[2][MAX_HULL_STRING_LENGTH / 2];
	char vectorStrs[3][MAX_HULL_STRING_LENGTH / 6];
	ExplodeString(hullStr, " ", hullStrs, 2, MAX_HULL_STRING_LENGTH / 2);
	for (int i = 0; i < 2; i++)
	{
		ExplodeString(hullStrs[i], ",", vectorStrs, 3, MAX_HULL_STRING_LENGTH / 6);
		hull[i][0] = StringToFloat(vectorStrs[0]);
		hull[i][1] = StringToFloat(vectorStrs[1]);
		hull[i][2] = StringToFloat(vectorStrs[2]);
	}
}

stock bool ReadFloatRange(int bossIdx, const char[] ability_name, int argInt, float range[2])
{
	static char rangeStr[MAX_RANGE_STRING_LENGTH];
	ParseFloatRange(rangeStr, range[0], range[1]); // do this even if the length is invalid, for stock backwards comatibility
	return (strlen(rangeStr) >= 3); // minimum length for valid range is 3
}

stock int ReadHull(int bossIdx, const char[] ability_name, int argInt, float hull[2][3])
{
	static char hullStr[MAX_HULL_STRING_LENGTH];
	ParseHull(hullStr, hull);
}

public bool TraceWallsOnly(int entity, int contentsMask)
{
	return false;
}

public bool TraceRedPlayers(int entity, int contentsMask)
{
	if (IsLivingPlayer(entity) && GetClientTeam(entity) != 2)
	{
		if (PRINT_DEBUG_SPAM)
			PrintToServer("[improved_saxton] Hit player %d on trace.", entity);
		return true;
	}

	return false;
}

public bool TraceRedPlayersAndBuildings(int entity, int contentsMask)
{
	if (IsLivingPlayer(entity) && GetClientTeam(entity) != 2)
	{
		if (PRINT_DEBUG_SPAM)
			PrintToServer("[improved_saxton] Hit player %d on trace.", entity);
		return true;
	}
	else if (IsValidEntity(entity))
	{
		static char classname[MAX_ENTITY_CLASSNAME_LENGTH];
		GetEntityClassname(entity, classname, sizeof(classname));
		classname[4] = 0;
		if (!strcmp(classname, "obj_")) // all buildings start with this
			return true;
	}

	return false;
}

stock float fixAngle(float angle)
{
	new sanity = 0;
	while (angle < -180.0 && (sanity++) <= 10)
		angle = angle + 360.0;
	while (angle > 180.0 && (sanity++) <= 10)
		angle = angle - 360.0;
		
	return angle;
}

// really wish that the original GetVectorAngles() worked this way.
stock float GetVectorAnglesTwoPoints(const float startPos[3], const float endPos[3], float angles[3])
{
	static float tmpVec[3];
	tmpVec[0] = endPos[0] - startPos[0];
	tmpVec[1] = endPos[1] - startPos[1];
	tmpVec[2] = endPos[2] - startPos[2];
	GetVectorAngles(tmpVec, angles);
}

stock float GetVelocityFromPointsAndInterval(float pointA[3], float pointB[3], float deltaTime)
{
	if (deltaTime <= 0.0)
		return 0.0;

	return GetVectorDistance(pointA, pointB) * (1.0 / deltaTime);
}

stock float fixDamageForVSH2(float damage)
{
	if (damage <= 160.0)
		return damage / 3.0;
	return damage;
}

stock void QuietDamage(int victim, int &inflictor, int &attacker, float damage, int damageType=DMG_GENERIC, int weapon=-1)
{
	new takedamage = GetEntProp(victim, Prop_Data, "m_takedamage");
	SetEntProp(victim, Prop_Data, "m_takedamage", 0);
	SDKHooks_TakeDamage(victim, inflictor, attacker, damage, damageType, weapon);
	SetEntProp(victim, Prop_Data, "m_takedamage", takedamage);
	SDKHooks_TakeDamage(victim, victim, victim, damage, damageType, weapon);
}

// for when damage to a hale needs to be recognized
stock void SemiHookedDamage(int victim, int &inflictor, int &attacker, float damage, int damageType=DMG_GENERIC, int weapon=-1)
{
	if (GetClientTeam(victim) != BossTeam)
		SDKHooks_TakeDamage(victim, inflictor, attacker, damage, damageType, weapon);
	else
		FullyHookedDamage(victim, inflictor, attacker, damage, damageType, weapon);
}

stock void FullyHookedDamage(int victim, int &inflictor, int &attacker, float damage, int damageType=DMG_GENERIC, int weapon=-1, float attackPos[3] = NULL_VECTOR)
{
	static char dmgStr[16];
	IntToString(RoundFloat(damage), dmgStr, sizeof(dmgStr));

	// took this from war3...I hope it doesn't double damage like I've heard old versions do
	int pointHurt = CreateEntityByName("point_hurt");
	if (IsValidEntity(pointHurt))
	{
		DispatchKeyValue(victim, "targetname", "halevictim");
		DispatchKeyValue(pointHurt, "DamageTarget", "halevictim");
		DispatchKeyValue(pointHurt, "Damage", dmgStr);
		DispatchKeyValueFormat(pointHurt, "DamageType", "%d", damageType);

		DispatchSpawn(pointHurt);
		if (!(attackPos[0] == NULL_VECTOR[0] && attackPos[1] == NULL_VECTOR[1] && attackPos[2] == NULL_VECTOR[2]))
		{
			TeleportEntity(pointHurt, attackPos, NULL_VECTOR, NULL_VECTOR);
		}
		else if (IsLivingPlayer(attacker))
		{
			static float attackerOrigin[3];
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", attackerOrigin);
			TeleportEntity(pointHurt, attackerOrigin, NULL_VECTOR, NULL_VECTOR);
		}
		AcceptEntityInput(pointHurt, "Hurt", attacker);
		DispatchKeyValue(pointHurt, "classname", "point_hurt");
		DispatchKeyValue(victim, "targetname", "noonespecial");
		RemoveEntity(EntIndexToEntRef(pointHurt));
	}
}

public Action Saxton_RemoveConditions(int clientIdx, const TFCond conditions[MAX_CONDITIONS])
{
	if (!SAO_CanUse[clientIdx])
		return;

	for (int i = 0; i < MAX_CONDITIONS; i++)
		if (conditions[i] > view_as<TFCond>(0) && TF2_IsPlayerInCondition(clientIdx, conditions[i]))
			TF2_RemoveCondition(clientIdx, conditions[i]);
}

// this version ignores obstacles
stock int PseudoAmbientSound(int clientIdx, char[] soundPath, int count=1, float radius=1000.0, bool skipSelf=false, bool skipDead=false, float volumeFactor=1.0)
{
	static Float:emitterPos[3];
	static Float:listenerPos[3];
	if (!IsLivingPlayer(clientIdx)) // updated 2015-01-16 to allow non-players...finally.
		GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", emitterPos);
	else
		GetClientEyePosition(clientIdx, emitterPos);
	for (new listener = 1; listener < MAX_PLAYERS; listener++)
	{
		if (!IsClientInGame(listener))
			continue;
		else if (skipSelf && listener == clientIdx)
			continue;
		else if (skipDead && !IsLivingPlayer(listener))
			continue;
			
		GetClientEyePosition(listener, listenerPos);
		new Float:distance = GetVectorDistance(emitterPos, listenerPos);
		if (distance >= radius)
			continue;
		
		new Float:volume = (radius - distance) / radius;
		if (volume <= 0.0)
			continue;
		else if (volume > 1.0)
		{
			PrintToServer("[improved_saxton] How the hell is volume greater than 1.0?");
			volume = 1.0;
		}
		
		for (new i = 0; i < count; i++)
			EmitSoundToClient(listener, soundPath, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, volume);
	}
}

Handle hPlayTaunt = INVALID_HANDLE;

public void RegisterForceTaunt()
{
	Handle conf = LoadGameConfigFile("tf2.tauntem");
	if (conf == INVALID_HANDLE)
	{
		LogError("[improved_saxton] Unable to load gamedata/tf2.tauntem.txt. Guitar Hero DOT will not function.");
		return;
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "CTFPlayer::PlayTauntSceneFromItem");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	hPlayTaunt = EndPrepSDKCall();
	if (hPlayTaunt == INVALID_HANDLE)
	{
		LogError("[improved_saxton] Unable to initialize call to CTFPlayer::PlayTauntSceneFromItem. Need to get updated tf2.tauntem.txt method signatures. Saxton Slam will not animate.");
		CloseHandle(conf);
		return;
	}
	CloseHandle(conf);
}

bool congaFailurePrintout = false;

int Address_MinimumValid = 0x1000;

public void ForceUserToTaunt(int clientIdx, int itemdef)
{
	if (hPlayTaunt == INVALID_HANDLE)
	{
		if (PRINT_DEBUG_INFO)
			PrintToChatAll("[improved_saxton] WARNING: RegisterForceTaunt() wasn't ever called, or it needs to be updated.");
		return;
	}
		
	int  ent = MakeCEIVEnt(clientIdx, itemdef);
	if (!IsValidEntity(ent))
	{
		if (!congaFailurePrintout)
		{
			PrintToServer("[improved_saxton] Could not create %d taunt entity.", itemdef);
			congaFailurePrintout = true;
		}
		return;
	}
	Address pEconItemView = GetEntityAddress(ent) + view_as<Address>(FindSendPropInfo("CTFWearable", "m_Item"));
	if ((view_as<int>(pEconItemView) & 0x80000000) == 0 && view_as<int>(pEconItemView) <= view_as<int>(Address_MinimumValid))
	{
		if (!congaFailurePrintout)
		{
			PrintToServer("[improved_saxton] Couldn't find CEconItemView for taunt %d.", itemdef);
			congaFailurePrintout = true;
		}
		AcceptEntityInput(ent, "Kill");
		return;
	}
	
	bool success = SDKCall(hPlayTaunt, clientIdx, pEconItemView);
	AcceptEntityInput(ent, "Kill");
	
	if (!success && PRINT_DEBUG_SPAM)
		PrintToServer("[improved_saxton] Failed to force %d to taunt %d.", clientIdx, itemdef);
	else if (PRINT_DEBUG_SPAM)
		PrintToServer("[improved_saxton] Successfully forced %d to taunt %d.", clientIdx, itemdef);
}

stock int MakeCEIVEnt(int client, int itemdef)
{
	static Handle hItem;
	if (hItem == INVALID_HANDLE)
	{
		hItem = TF2Items_CreateItem(OVERRIDE_ALL|PRESERVE_ATTRIBUTES|FORCE_GENERATION);
		TF2Items_SetClassname(hItem, "tf_wearable_vm");
		TF2Items_SetQuality(hItem, 6);
		TF2Items_SetLevel(hItem, 1);
		TF2Items_SetNumAttributes(hItem, 0);
	}
	TF2Items_SetItemIndex(hItem, itemdef);
	return TF2Items_GiveNamedItem(client, hItem);
}

stock float fixAngles(float angles[3])
{
	for (new i = 0; i < 3; i++)
		angles[i] = fixAngle(angles[i]);
}

stock float abs(float x)
{
	return x < 0 ? -x : x;
}

stock float fabs(float x)
{
	return x < 0 ? -x : x;
}

stock float min(float n1, float n2)
{
	return n1 < n2 ? n1 : n2;
}

stock float fmin(float n1, float n2)
{
	return n1 < n2 ? n1 : n2;
}

stock float max(float n1, float n2)
{
	return n1 > n2 ? n1 : n2;
}

stock float fmax(float n1, float n2)
{
	return n1 > n2 ? n1 : n2;
}

stock float fsquare(float x)
{
	return x * x;
}

stock float DEG2RAD(float n) { return n * 0.017453; }

stock float RAD2DEG(float n) { return n * 57.29578; }

stock bool WithinBounds(float point[3], float min[3], float max[3])
{
	return point[0] >= min[0] && point[0] <= max[0] &&
		point[1] >= min[1] && point[1] <= max[1] &&
		point[2] >= min[2] && point[2] <= max[2];
}

stock int ReadHexOrDecInt(const char hexOrDecString[HEX_OR_DEC_STRING_LENGTH])
{
	if (StrContains(hexOrDecString, "0x") == 0)
	{
		new result = 0;
		for (new i = 2; i < 10 && hexOrDecString[i] != 0; i++)
		{
			result = result<<4;
				
			if (hexOrDecString[i] >= '0' && hexOrDecString[i] <= '9')
				result += hexOrDecString[i] - '0';
			else if (hexOrDecString[i] >= 'a' && hexOrDecString[i] <= 'f')
				result += hexOrDecString[i] - 'a' + 10;
			else if (hexOrDecString[i] >= 'A' && hexOrDecString[i] <= 'F')
				result += hexOrDecString[i] - 'A' + 10;
		}
		
		return result;
	}
	else
		return StringToInt(hexOrDecString);
}

stock int ReadHexOrDecString(int bossIdx, const char[] ability_name, int argIdx)
{
	static char hexOrDecString[HEX_OR_DEC_STRING_LENGTH];
	return ReadHexOrDecInt(hexOrDecString);
}

stock float ConformAxisValue(float src, float dst, float distCorrectionFactor)
{
	return src - ((src - dst) * distCorrectionFactor);
}

stock float ConformLineDistance(float result[3], const float src[3], const float dst[3], float maxDistance, bool canExtend = false)
{
	float distance = GetVectorDistance(src, dst);
	if (distance <= maxDistance && !canExtend)
	{
		// everything's okay.
		result[0] = dst[0];
		result[1] = dst[1];
		result[2] = dst[2];
	}
	else
	{
		// need to find a point at roughly maxdistance. (FP irregularities aside)
		float distCorrectionFactor = maxDistance / distance;
		result[0] = ConformAxisValue(src[0], dst[0], distCorrectionFactor);
		result[1] = ConformAxisValue(src[1], dst[1], distCorrectionFactor);
		result[2] = ConformAxisValue(src[2], dst[2], distCorrectionFactor);
	}
}

public void Saxton_AddConditions(int clientIdx, const TFCond conditions[MAX_CONDITIONS])
{
	if (!SAO_CanUse[clientIdx])
		return;

	for (int i = 0; i < MAX_CONDITIONS; i++)
		if (conditions[i] > view_as<TFCond>(0))
			TF2_AddCondition(clientIdx, conditions[i], -1.0);
}

stock bool CylinderCollision(float cylinderOrigin[3], float colliderOrigin[3], float maxDistance, float zMin, float zMax)
{
	if (colliderOrigin[2] < zMin || colliderOrigin[2] > zMax)
		return false;

	static float tmpVec1[3];
	tmpVec1[0] = cylinderOrigin[0];
	tmpVec1[1] = cylinderOrigin[1];
	tmpVec1[2] = 0.0;
	static float tmpVec2[3];
	tmpVec2[0] = colliderOrigin[0];
	tmpVec2[1] = colliderOrigin[1];
	tmpVec2[2] = 0.0;
	
	return GetVectorDistance(tmpVec1, tmpVec2, true) <= maxDistance * maxDistance;
}

stock bool RectangleCollision(float hull[2][3], float point[3])
{
	return (point[0] >= hull[0][0] && point[0] <= hull[1][0]) &&
		(point[1] >= hull[0][1] && point[1] <= hull[1][1]) &&
		(point[2] >= hull[0][2] && point[2] <= hull[1][2]);
}

stock float getLinearVelocity(float vecVelocity[3])
{
	return SquareRoot((vecVelocity[0] * vecVelocity[0]) + (vecVelocity[1] * vecVelocity[1]) + (vecVelocity[2] * vecVelocity[2]));
}

stock float getBaseVelocityFromYaw(const float angle[3], float vel[3])
{
	vel[0] = Cosine(angle[1]); // same as unit circle
	//vel[1] = -Sine(angle[1]); // inverse of unit circle
	vel[1] = Sine(angle[1]); // ...or also same of unit circle? must not test in game at 3am...
	vel[2] = 0.0; // unaffected
}

stock float RandomNegative(float someVal)
{
	return someVal * (GetRandomInt(0, 1) == 1 ? 1.0 : -1.0);
}

stock float GetRayAngles(float startPoint[3], float endPoint[3], float angle[3])
{
	static float tmpVec[3];
	tmpVec[0] = endPoint[0] - startPoint[0];
	tmpVec[1] = endPoint[1] - startPoint[1];
	tmpVec[2] = endPoint[2] - startPoint[2];
	GetVectorAngles(tmpVec, angle);
}

stock bool AngleWithinTolerance(float entityAngles[3], float targetAngles[3], float tolerance)
{
	static bool tests[2];
	
	for (new i = 0; i < 2; i++)
		tests[i] = fabs(entityAngles[i] - targetAngles[i]) <= tolerance || fabs(entityAngles[i] - targetAngles[i]) >= 360.0 - tolerance;
	
	return tests[0] && tests[1];
}

stock TFClassType GetClassOfTaunt(int tauntIdx, TFClassType currentPlayerClass)
{
	switch (tauntIdx) // I literally never use these. except now. also it's weird that there's no break and they don't leak.
	{
		case 30609, 30614, 1116:
			return TFClass_Sniper;
		case 30572, 1119, 1117:
			return TFClass_Scout;
		case 1120, 1114:
			return TFClass_DemoMan;
		case 1115:
			return TFClass_Engineer;
		case 1113:
			return TFClass_Soldier;
		case 1112, 30570:
			return TFClass_Pyro;
		case 1109, 477:
			return TFClass_Medic;
		case 1108:
			return TFClass_Spy;
	}
	
	return currentPlayerClass;
}

stock int constrainDistance(const float[] startPoint, float[] endPoint, float distance, float maxDistance)
{
	if (distance <= maxDistance)
		return; // nothing to do
		
	new Float:constrainFactor = maxDistance / distance;
	endPoint[0] = ((endPoint[0] - startPoint[0]) * constrainFactor) + startPoint[0];
	endPoint[1] = ((endPoint[1] - startPoint[1]) * constrainFactor) + startPoint[1];
	endPoint[2] = ((endPoint[2] - startPoint[2]) * constrainFactor) + startPoint[2];
}

stock bool signIsDifferent(const float one, const float two)
{
	return one < 0.0 && two > 0.0 || one > 0.0 && two < 0.0;
}

static int GetR(int c) { return (c >> 16) & 0xff; }
static int GetG(int c) { return (c >> 8) & 0xff; }
static int GetB(int c) { return c & 0xff; }

stock int ColorToDecimalString(char buffer[COLOR_BUFFER_SIZE], int rgb)
{
	Format(buffer, COLOR_BUFFER_SIZE, "%d %d %d", GetR(rgb), GetG(rgb), GetB(rgb));
}

stock int BlendColorsRGB(int oldColor, float oldWeight, int newColor, float newWeight)
{
	int r = min(RoundFloat((GetR(oldColor) * oldWeight) + (GetR(newColor) * newWeight)), 255);
	int g = min(RoundFloat((GetG(oldColor) * oldWeight) + (GetG(newColor) * newWeight)), 255);
	int b = min(RoundFloat((GetB(oldColor) * oldWeight) + (GetB(newColor) * newWeight)), 255);
	return (r<<16) + (g<<8) + b;
}

stock int Nope(int clientIdx)
{
	EmitSoundToClient(clientIdx, NOPE_AVI);
}

// stole this stock from KissLick. it's a good stock!
stock int DispatchKeyValueFormat(int entity, const char[] keyName, const char[] format, any:...)
{
	static char value[256];
	VFormat(value, sizeof(value), format, 4);

	DispatchKeyValue(entity, keyName, value);
} 

stock bool PlayerIsInvincible(int clientIdx)
{
	return TF2_IsPlayerInCondition(clientIdx, TFCond_Ubercharged) ||
		TF2_IsPlayerInCondition(clientIdx, TFCond_UberchargedHidden) ||
		TF2_IsPlayerInCondition(clientIdx, TFCond_UberchargedCanteen) ||
		TF2_IsPlayerInCondition(clientIdx, TFCond_UberchargedOnTakeDamage) ||
		TF2_IsPlayerInCondition(clientIdx, TFCond_Bonked);
}

stock bool CheckGroundClearance(int clientIdx, float minClearance, bool failInWater)
{
	// standing? automatic fail.
	if (GetEntityFlags(clientIdx) & FL_ONGROUND)
		return false;
	else if (failInWater && (GetEntityFlags(clientIdx) & (FL_SWIM | FL_INWATER)))
		return false;
		
	// need to do a trace
	static float origin[3];
	GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", origin);
	
	float traceray[3] = {90.0, 0.0, 0.0};
	Handle trace = TR_TraceRayFilterEx(origin, traceray, (CONTENTS_SOLID | CONTENTS_WINDOW | CONTENTS_GRATE), RayType_Infinite, TraceWallsOnly);
	static float endPos[3];
	TR_GetEndPosition(endPos, trace);
	CloseHandle(trace);
	
	// only Z should change, so this is easy.
	return origin[2] - endPos[2] >= minClearance;
}

stock bool IsInstanceOf(int entity, const char[] desiredClassname)
{
	static char classname[MAX_ENTITY_CLASSNAME_LENGTH];
	GetEntityClassname(entity, classname, MAX_ENTITY_CLASSNAME_LENGTH);
	return strcmp(classname, desiredClassname) == 0;
}

// need to distinguish being fully in water and not, which is a little more complicated than it should be
stock bool IsFullyInWater(int clientIdx)
{
	int flags = GetEntityFlags(clientIdx);
	if ((flags & (FL_SWIM | FL_INWATER)) == 0)
		return false;

	int waterLevel = GetEntProp(clientIdx, Prop_Send, "m_nWaterLevel");
	if (waterLevel <= 1)
		return false;
		
	return true;
}

stock bool IsTreadingWater(int clientIdx)
{
	return (GetEntityFlags(clientIdx) & FL_ONGROUND) == 0 && GetEntProp(clientIdx, Prop_Send, "m_nWaterLevel") == 1;
}

stock bool ShouldGetZBoost(int clientIdx)
{
	int flags = GetEntityFlags(clientIdx);
	return (flags & FL_ONGROUND) != 0 || ((flags & (FL_SWIM | FL_INWATER)) != 0 && !IsFullyInWater(clientIdx));
}

bool Saxton_TempGoomba = false;

public Action Saxton_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (IsLivingPlayer(attacker))
	{
		static char killWeapon[MAX_KILL_ID_LENGTH];
		static char killName[MAX_KILL_ID_LENGTH];
		bool override = false;
		
		int bossIdx = VSH2_GetBossIndex(attacker);
		if (bossIdx < 0)
			return Plugin_Continue;

		if (SS_CanUse[attacker] && SS_IsUsing[attacker])
		{
			override = true;
			if (Saxton_TempGoomba) {
			}
		}
		if (override)
		{
			SetEventString(event, "weapon", killWeapon); // train
			SetEventString(event, "weapon_logclassname", killName);
		}
	}
	
	return Plugin_Continue;
}

public Action Saxton_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (IsLivingPlayer(victim) && IsLivingPlayer(attacker))
	{
	}
	
	return Plugin_Continue;
}

public void Saxton_GetKillStringWithDefault(int bossIdx, const float[] abilityName, int intargIdx, char killStr[MAX_KILL_ID_LENGTH], int clientIdx, const float[] defaultStr)
{
	if (SAO_CanUse[clientIdx])
	{
		if (!IsEmptyString(killStr))
			return; // good enough
	}
	
	//strcopy(killStr, MAX_KILL_ID_LENGTH, defaultStr);
}