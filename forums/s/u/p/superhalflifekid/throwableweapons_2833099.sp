#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>
#include <vphysics>


#pragma semicolon 1
#pragma newdecls required


public Plugin myinfo = 
{
	name = "throwable crowbar / stunstick",
	author = "superhalflifekid",
	version = "1.0"
};



Handle hDeletionTimers[2048];
int hPlayerGravguns[MAXPLAYERS + 1];


Handle hGamedata; // throwableweapons.txt

Handle hSDKCall_SmoothVel;
Handle hSDKCall_VAttackAnimation;


DynamicHook hDHook_Attack1;
DynamicHook hDHook_Attack2;




public void OnMapStart()
{
	PrecacheModel("models/weapons/phys_crowbar.mdl", true);
	PrecacheModel("models/weapons/phys_stunbaton.mdl", true);
}




public void OnPluginStart()
{
	// get gamedata
	hGamedata = LoadGameConfigFile("throwableweapons");
	
	
	
	if (!hGamedata)
	{
		SetFailState("Failed to get throwable weapons plugin gamedata");
	}
	
	
	
	// prep sdkcalls
	StartPrepSDKCall(SDKCall_Entity);
	
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Virtual, "CBaseEntity::GetSmoothedVelocity");
	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
	
	hSDKCall_SmoothVel = EndPrepSDKCall();
	
	if (!hSDKCall_SmoothVel)
	{
		SetFailState("Failed to set throwable weapon plugin GetSmoothedVelocity SDKcall");
	}
	
	
	
	
	StartPrepSDKCall(SDKCall_Entity);
		
	PrepSDKCall_SetFromConf(hGamedata, SDKConf_Virtual, "CBaseCombatWeapon::SendViewModelAnim");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		
	hSDKCall_VAttackAnimation = EndPrepSDKCall();
	
	
	if (!hSDKCall_VAttackAnimation)
	{
		SetFailState("Failed to set throwable weapon plugin SendViewModelAnim SDKcall");
	}
	
	
	
	// set dhooks
	int iDhookOffset = GameConfGetOffset(hGamedata, "CBaseCombatWeapon::PrimaryAttack");
	hDHook_Attack1 = DHookCreate(iDhookOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity);
	
	if (!hDHook_Attack1)
	{
		SetFailState("epic fail setting up primary attack Dhook");
	}
	
	
	iDhookOffset = GameConfGetOffset(hGamedata, "CBaseCombatWeapon::SecondaryAttack");
	hDHook_Attack2 = DHookCreate(iDhookOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity);
	
	if (!hDHook_Attack2)
	{
		SetFailState("epic fail setting up secondary attack Dhook");
	}
	
	
	
}



// Throw crowbar or stunstick on attack2
public MRESReturn DH_Attack2(int entity)
{
	if (IsValidEntity(entity))
	{
		int client = GetEntPropEnt(entity, Prop_Data, "m_hOwner");
		EmitGameSoundToAll("Weapon_Crowbar.Single", client);
		
		
		SDKCall(hSDKCall_VAttackAnimation, entity, 2);
		
		
		float fGameTime = GetGameTime();
		SetEntPropFloat(entity, Prop_Data, "m_flNextPrimaryAttack", fGameTime + 1.0);
		SetEntPropFloat(entity, Prop_Data, "m_flNextSecondaryAttack", fGameTime + 1.0);
		
		
		CreateTimer(0.3, WeaponThrowTimer, entity, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	
	return MRES_Handled;
}



// Set correct attack2 delay on attack1
public MRESReturn DH_Attack1(int entity)
{
	if (IsValidEntity(entity))
	{
		char sClassname[32];
		GetEntityClassname(entity, sClassname, sizeof(sClassname));
		if (StrEqual(sClassname, "weapon_crowbar"))
		{
			float fGameTime = GetGameTime();
			SetEntPropFloat(entity, Prop_Data, "m_flNextSecondaryAttack", fGameTime + 1.0);
		}
		else if (StrEqual(sClassname, "weapon_stunstick"))
		{
			float fGameTime = GetGameTime();
			SetEntPropFloat(entity, Prop_Data, "m_flNextSecondaryAttack", fGameTime + 1.5);
		}
		
	}
	
	
	return MRES_Handled;
}



// throw weapon
public Action WeaponThrowTimer(Handle timer, any data)
{
	if (IsValidEntity(data))
	{
		char sClassname[32];
		GetEntityClassname(data, sClassname, sizeof(sClassname));
		if (StrEqual(sClassname, "weapon_crowbar") || StrEqual(sClassname, "weapon_stunstick"))
		{
			int client = GetEntPropEnt(data, Prop_Data, "m_hOwner");
			if (client > 0)
			{
				int iActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
				if (data == iActiveWeapon)
				{
					float fEyeAngles[3];
					float fEyePos[3];
				
					GetClientEyePosition(client, fEyePos);
					GetClientEyeAngles(client, fEyeAngles);
				
					
					
					// calc where weapon should be infront player
					float fWeaponPos[3];
					GetAngleVectors(fEyeAngles, fWeaponPos, NULL_VECTOR, NULL_VECTOR);
					
					float fPlayerVelocity[3];
					GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fPlayerVelocity);
					
					float fPositionScale;
					if (GetVectorDotProduct(fWeaponPos, fPlayerVelocity) > 0.0)
					{
						float fPlayerSpeed = GetVectorLength(fPlayerVelocity, false);
						fPositionScale = fPlayerSpeed / 10.0;
					}
			
					
					ScaleVector(fWeaponPos, 45.0 + fPositionScale);
					fWeaponPos[0] += fEyePos[0];
					fWeaponPos[1] += fEyePos[1];
					fWeaponPos[2] += fEyePos[2];
					
					
					
					
					//Check if possible spawn
					float fVecMins[3] = {-18.0, -18.0, -18.0};
					float fVecMaxs[3] = {18.0, 18.0, 18.0};
					
					Handle hCollisionTrace = TR_TraceHullFilterEx(fWeaponPos, fWeaponPos, fVecMins, fVecMaxs, MASK_SOLID, TraceRayClientFilter, client);
					
					
					if (TR_DidHit(hCollisionTrace)) // no space
					{
						PrintToChat(client, "[SM] Not enough space to throw");
						CloseHandle(hCollisionTrace);
						return Plugin_Stop;
					}
					
					CloseHandle(hCollisionTrace);
					
					
					
					// Create throwed weapon
					int iThrownWeapon = CreateEntityByName("prop_physics");
					
					
					if (StrEqual(sClassname, "weapon_crowbar"))
					{
						DispatchKeyValue(iThrownWeapon, "model", "models/weapons/phys_crowbar.mdl");
					}
					else //if (StrEqual(sClassname, "weapon_stunstick"))
					{
						DispatchKeyValue(iThrownWeapon, "model", "models/weapons/phys_stunbaton.mdl");
					}
					
					
					float fWeaponAngles[3];
					fWeaponAngles[0] = fEyeAngles[0] - 2.0;
					fWeaponAngles[1] = fEyeAngles[1];
					fWeaponAngles[2] = fEyeAngles[2] - 30.0;
					
					char sWeaponAngles[16];
					Format(sWeaponAngles, sizeof(sWeaponAngles), "%.0f %.0f %.0f", fWeaponAngles[0], fWeaponAngles[1], fWeaponAngles[2]);
					DispatchKeyValue(iThrownWeapon, "Angles", sWeaponAngles);
					
					
					SetEntPropEnt(iThrownWeapon, Prop_Data, "m_hPhysicsAttacker", client);
					SetEntPropFloat(iThrownWeapon, Prop_Data, "m_flLastPhysicsInfluenceTime", GetEngineTime());
					
					TeleportEntity(iThrownWeapon, fWeaponPos, NULL_VECTOR, NULL_VECTOR);
					
					
					
					
					AcceptEntityInput(iThrownWeapon, "DisablePhyscannonPickup");
					
					
					DispatchSpawn(iThrownWeapon);
					
					
					// add velocity
					float fVelocityVector[3];
					GetAngleVectors(fEyeAngles, fVelocityVector, NULL_VECTOR, NULL_VECTOR);
					ScaleVector(fVelocityVector, 1000.0);
					
					float fAngularVelocityVector[3] = { 0.0, 1500.0, 0.0 };
			
					Phys_SetVelocity(iThrownWeapon, fVelocityVector, fAngularVelocityVector, true);
					
					
					
					// hook touch and make despawn timer
					SDKHook(iThrownWeapon, SDKHook_StartTouch, WeaponTouchHook);
					
					
					hDeletionTimers[iThrownWeapon] = CreateTimer(30.0, WeaponDespawnTimer, iThrownWeapon, TIMER_FLAG_NO_MAPCHANGE);
			
					
					
					RemovePlayerItem(client, data);
					
					EquipPlayerWeapon(client, hPlayerGravguns[client]);
				}
			}
		}	
	}
	return Plugin_Handled;
}




// remove weapon after 30 seconds
public Action WeaponDespawnTimer(Handle timer, any data)
{
	RemoveEntity(data);
			
	return Plugin_Handled;
}


// Register gravgun ent index
public Action CheckOwnerTimer(Handle timer, any data)
{
	if (IsValidEntity(data))
	{
		char sClassname[32];
		GetEntityClassname(data, sClassname, sizeof(sClassname));
		if (StrEqual(sClassname, "weapon_physcannon"))
		{
			int iOwner = GetEntPropEnt(data, Prop_Data, "m_hOwner");
			if (iOwner > 0)
			{
				hPlayerGravguns[iOwner] = data;
			}
		}
	}
	
	return Plugin_Handled;
}


// Dhook melee weps on spawn
public void OnEntityCreated(int entity, const char[] classname)
{
	if (IsValidEntity(entity))
	{
		if (StrEqual(classname, "weapon_crowbar") || StrEqual(classname, "weapon_stunstick"))
		{
			hDHook_Attack1.HookEntity(Hook_Post, entity, DH_Attack1);
			hDHook_Attack2.HookEntity(Hook_Post, entity, DH_Attack2);
		}
		else if (StrEqual(classname, "weapon_physcannon"))
		{
			CreateTimer(0.1, CheckOwnerTimer, entity, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}


// remove deleting timer on destroy
public void OnEntityDestroyed(int entity)
{
	if (IsValidEntity(entity))
	{
		char sNameBuffer[64];
		GetEntityClassname(entity, sNameBuffer, sizeof(sNameBuffer));
		if (StrEqual(sNameBuffer, "prop_physics"))
		{	
			GetEntPropString(entity, Prop_Data, "m_ModelName", sNameBuffer, sizeof(sNameBuffer));
			if (StrContains(sNameBuffer, "phys_crowbar") > 0 || StrContains(sNameBuffer, "phys_stunbaton") > 0)
			{
				KillTimer(hDeletionTimers[entity]);
			}
		}
	}
}



// allow player to pick up weapon when touch
public Action WeaponTouchHook(int entity, int other)
{
	if (other > 0)
	{
		if (IsValidEntity(entity) && IsValidEntity(other))
		{
			char sClassname[32];
			GetEntityClassname(other, sClassname, sizeof(sClassname));
			if (StrEqual(sClassname, "player"))
			{
				float fVelocityVector[3];
				SDKCall(hSDKCall_SmoothVel, entity, fVelocityVector);

				float fVelocityScalar = GetVectorLength(fVelocityVector);
				
				if (fVelocityScalar < 45.0)
				{
					char sWeaponType[64];
					GetEntPropString(entity, Prop_Data, "m_ModelName", sWeaponType, sizeof(sWeaponType));
					if (StrContains(sWeaponType, "phys_crowbar") > 0)
					{
						sWeaponType = "weapon_crowbar";
					}
					else
					{
						sWeaponType = "weapon_stunstick";
					}
					
					int iArraySize = GetEntPropArraySize(other, Prop_Data, "m_hMyWeapons");
					int iWeapon;
					
					bool bOwnsWeapon;
					
					for (int i; i < iArraySize; i++)
					{
						iWeapon = GetEntPropEnt(other, Prop_Data, "m_hMyWeapons", i);
						if (iWeapon > 0)
						{	
							char sWeaponClassname[32];
							GetEntityClassname(iWeapon, sWeaponClassname, sizeof(sWeaponClassname));
							{
								if (StrEqual(sWeaponClassname, sWeaponType))
								{
									bOwnsWeapon = true;
								}
							}
						}
					}
					
					
					
					if (!bOwnsWeapon)
					{
						GivePlayerItem(other, StrEqual(sWeaponType, "weapon_crowbar") ? "weapon_crowbar" : "weapon_stunstick");
						SDKUnhook(entity, SDKHook_StartTouch, WeaponTouchHook);
						RemoveEntity(entity);
						
						return Plugin_Stop;
					}
					
					
				}
			}
			
		}
	}
	
	return Plugin_Handled;
}






// trace filter so client not hit self
public bool TraceRayClientFilter(int entity, int contentsMask, any data)
{
	return (entity != data) ? true : false;
}



