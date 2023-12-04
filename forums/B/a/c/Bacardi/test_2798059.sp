


#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#define HITDISTANCE 9.0

// Weapon m_iState
#define WEAPON_NOT_CARRIED				0	// Weapon is on the ground
#define WEAPON_IS_CARRIED_BY_PLAYER			1	// This client is carrying this weapon.
#define WEAPON_IS_ACTIVE					2	// This client is carrying this weapon and it's the currently held weapon

bool exploded = false;
int hit_counter = 0;

public void OnPluginStart()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i)) OnClientPutInServer(i);
	}

	HookEvent("round_start", round_start);
}

public void round_start(Event event, const char[] name, bool dontBroadcast)
{
	exploded = false;
	hit_counter = 0;
}



public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}


public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(exploded)
		return Plugin_Continue;

	if(damagetype != DMG_BULLET|DMG_NEVERGIB) // no headshot, blast, knife
		return Plugin_Continue;

	if(!HasC4(victim)) // Is actual bomb carrier by game
		return Plugin_Continue;

	int c4 = GetPlayerWeaponSlot(victim, CS_SLOT_C4);

	if(c4 == -1 || !HasEntProp(c4, Prop_Send, "m_iState"))
		return Plugin_Continue;

	int m_iState = GetEntProp(c4, Prop_Send, "m_iState");

	float origin[3], results[3];
	
	switch(m_iState) // where c4 locate on player
	{
		case WEAPON_IS_CARRIED_BY_PLAYER:
		{
			if(!LookupEntityAttachment_Pos(victim, "c4", origin))	// If player model have this attachment
				return Plugin_Continue;

			SubtractVectors(origin, damagePosition, results);

			if(results[0] < HITDISTANCE && results[0] > -HITDISTANCE
			&& results[1] < HITDISTANCE && results[1] > -HITDISTANCE
			&& results[2] < HITDISTANCE && results[2] > -HITDISTANCE)
			{
				DataPack pack;
				CreateDataTimer(0.1, C4Hit, pack, TIMER_FLAG_NO_MAPCHANGE);
				pack.WriteCell(GetClientUserId(victim));
				pack.WriteCell(EntIndexToEntRef(c4));

				//PrintToServer("+c4 %f %f %f", 	results[0],
				//									results[1],
				//									results[2]);
				damage = 0.0;
				return Plugin_Changed;
			}
		}
		case WEAPON_IS_ACTIVE:
		{
			if(LookupEntityAttachment_Pos(victim, "weapon_hand_R", origin)) // If player model have this attachment
			{
				SubtractVectors(origin, damagePosition, results);

				if(results[0] < HITDISTANCE && results[0] > -HITDISTANCE
				&& results[1] < HITDISTANCE && results[1] > -HITDISTANCE
				&& results[2] < HITDISTANCE && results[2] > -HITDISTANCE)
				{
					DataPack pack;
					CreateDataTimer(0.1, C4Hit, pack, TIMER_FLAG_NO_MAPCHANGE);
					pack.WriteCell(GetClientUserId(victim));
					pack.WriteCell(EntIndexToEntRef(c4));

					//PrintToServer("+weapon_hand_R %f %f %f", 	results[0],
					//									results[1],
					//									results[2]);
					damage = 0.0;
					return Plugin_Changed;
				}
			}

			if(LookupEntityAttachment_Pos(victim, "weapon_hand_L", origin)) // If player model have this attachment
			{
				SubtractVectors(origin, damagePosition, results);

				if(results[0] < HITDISTANCE && results[0] > -HITDISTANCE
				&& results[1] < HITDISTANCE && results[1] > -HITDISTANCE
				&& results[2] < HITDISTANCE && results[2] > -HITDISTANCE)
				{
					DataPack pack;
					CreateDataTimer(0.1, C4Hit, pack, TIMER_FLAG_NO_MAPCHANGE);
					pack.WriteCell(GetClientUserId(victim));
					pack.WriteCell(EntIndexToEntRef(c4));

					//PrintToServer("+weapon_hand_L %f %f %f", 	results[0],
					//									results[1],
					//									results[2]);
					damage = 0.0;
					return Plugin_Changed;
				}
			}
		}
	}

	return Plugin_Continue;
}


public Action C4Hit(Handle timer, DataPack pack)
{
	pack.Reset();

	int victim = GetClientOfUserId(pack.ReadCell());
	int c4 = EntRefToEntIndex(pack.ReadCell());

	if(c4 == -1)
		return Plugin_Continue;

	hit_counter++;

	if(victim == 0 || !IsClientInGame(victim))
		return Plugin_Continue;

	PrintToChatAll("Bomb hit %i times", hit_counter);

	if(!exploded && hit_counter >= 3)
	{
		exploded = true;
	
		float origin[3];
		int m_iState = GetEntProp(c4, Prop_Send, "m_iState");

		switch(m_iState)
		{
			case WEAPON_IS_CARRIED_BY_PLAYER:
			{
				LookupEntityAttachment_Pos(victim, "c4", origin)
			}
			case WEAPON_IS_ACTIVE:
			{
				LookupEntityAttachment_Pos(victim, "weapon_hand_R", origin)
			}
		}

		Explosion(origin);

		CS_DropWeapon(victim, c4, false, true);
		RequestFrame(delaykill, EntIndexToEntRef(c4));
	}

	return Plugin_Continue;
}

public void delaykill(any ref)
{
	AcceptEntityInput(ref, "Kill");
}



bool LookupEntityAttachment_Pos(int entity, const char[] attachment, float pos[3])
{
	int attachmentid = LookupEntityAttachment(entity, attachment);

	if(attachmentid == 0)
		return false;

	return GetEntityAttachment(entity, attachmentid, pos, NULL_VECTOR);
}


void Explosion(float pos[3])
{
	int entity = CreateEntityByName("info_particle_system");

	if(entity == -1)
		return;
	
	DispatchKeyValue(entity, "start_active", "0");
	DispatchKeyValue(entity, "effect_name", "explosion_c4_500_fallback");
	DispatchSpawn(entity);
	ActivateEntity(entity);
		
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);

	AcceptEntityInput(entity, "Start");

	EmitGameSoundToAll("c4.explode", SOUND_FROM_WORLD, .origin = pos);

	SetVariantString("OnUser1 !self,Kill,,1.0,-1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
}



bool HasC4(int client)
{
	if(client <= 0 || client > MaxClients)
		return false;

	int entity = GetPlayerResourceEntity();

	if(entity != -1 && HasEntProp(entity, Prop_Send, "m_iPlayerC4"))
	{
		if(client == GetEntProp(entity, Prop_Send, "m_iPlayerC4"))
			return true;
	}

	return false;
}
