/*
 * This file contains various UTIL's and SDK Functions to support
 * the restrict system.
 *
 * All of the code here was written by teame06 for GunGame: Source,
 * and was used with his permission and help.
 */

new Handle:GameConf;
new Handle:GetSlot;
new Handle:CSWeaponDrop;
new Handle:UTILRemove;
new m_hMyWeapons;
new g_MaxClients;
#define INVALID_OFFSET  -1

UTIL_FindGrenadeByName(client, const String:Grenade[], bool:drop = false, bool:remove = false)
{
	decl String:Class[64];
	for(new i = 0, ent; i < 128; i += 4)
	{
		ent = GetEntDataEnt(client, m_hMyWeapons + i);

		if(IsValidEdict(ent) && ent > g_MaxClients && HACK_GetSlot(ent) == _:Slot_Grenade)
		{
			GetEdictClassname(ent, Class, sizeof(Class));

			if(strcmp(Class, Grenade, false) == 0)
			{
				if(drop)
				{
					HACK_CSWeaponDrop(client, ent);

					if(remove)
					{
						HACK_Remove(ent);
						return -1;
					}
				}
				return ent;
			}
		}
	}

	return -1;
}

CreateGetSlotHack()
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(GameConf, SDKConf_Virtual, "GetSlot");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	GetSlot = EndPrepSDKCall();

	if(GetSlot == INVALID_HANDLE)
	{
		SetFailState("Virtual CBaseCombatWeapon::GetSlot Failed. Please contact the author.");
	}
}

CreateRemoveHack()
{
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(GameConf, SDKConf_Signature, "UTIL_Remove");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	UTILRemove = EndPrepSDKCall();

	if(UTILRemove == INVALID_HANDLE)
	{
		SetFailState("Signature CBaseEntity::UTIL_Remove Failed. Please contact author");
	}
}

CreateDropHack()
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(GameConf, SDKConf_Signature, "CSWeaponDrop");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	CSWeaponDrop = EndPrepSDKCall();

	if(CSWeaponDrop == INVALID_HANDLE)
	{
		SetFailState("Signature CSSPlayer::CSWeaponDrop Failed. Please contact the author.");
	}
}

HACK_GetSlot(entity)
{
	return SDKCall(GetSlot, entity);
}

HACK_Remove(entity)
{
	/* Just incase 0 get passed */
	if(entity)
	{
		SDKCall(UTILRemove, entity);
	}
}

HACK_CSWeaponDrop(client, weapon)
{
	SDKCall(CSWeaponDrop, client, weapon, true, false);
}