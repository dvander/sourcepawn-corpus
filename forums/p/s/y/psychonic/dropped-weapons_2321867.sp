#include <sourcemod>
#include <sdktools>

//bool CTFPlayer::PickupWeaponFromOther(const CTFDroppedWeapon *pWeapon)

//static CTFDroppedWeapon *CTFDroppedWeapon::Create(CTFPlayer *pOwner, const Vector &vecOrigin, const QAngle &vecAngles, const char *pszModel, CEconItemView *pItemView)

//void CTFDroppedWeapon::InitDroppedWeapon(CTFPlayer *pOwner, CTFWeaponBase *pWeapon, bool bUseExactOrigin = false, bool bSaveMedigunCharge = false)

Handle hCreateDroppedWeapon;
Handle hInitDroppedWeapon;
Handle hPickupWeaponFromOther;

public void OnPluginStart()
{
	Handle hConf = LoadGameConfigFile("dropped-weapons.games");
	
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTFDroppedWeapon::Create"))
	{
		PrintToServer("[DW] Failed to set CDW from conf!");
	}
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	hCreateDroppedWeapon = EndPrepSDKCall();
	
	PrintToServer("[DW]  hCDW %d", hCreateDroppedWeapon);
	
	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTFPlayer::PickupWeaponFromOther"))
	{
		PrintToServer("[DW] Failed to set PWFO from conf!");
	}
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	hPickupWeaponFromOther = EndPrepSDKCall();
	
	PrintToServer("[DW]  hPWFO %d", hPickupWeaponFromOther);

	StartPrepSDKCall(SDKCall_Entity);
	if (!PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTFDroppedWeapon::InitDroppedWeapon"))
	{
		PrintToServer("[DW] Failed to set IDW from conf!");
	}
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	hInitDroppedWeapon = EndPrepSDKCall();
	
	PrintToServer("[DW]  hIDW %d", hInitDroppedWeapon);
	
	delete hConf;
	
	RegConsoleCmd("sm_dropit", sm_dropit);
	RegConsoleCmd("sm_pickit", sm_pickit);
}

int CreateDroppedWeapon(int fromWeapon, int client, const float origin[3], const float angles[3])
{
	// Offset of the CEconItemView class inlined on the weapon.
	// Manually using FindSendPropInfo as 1) it's a sendtable, not a value,
	// and 2) we just want a pointer to it, not the value at that address.
	int itemOffset = FindSendPropInfo("CTFWeaponBase", "m_Item");
	if (itemOffset == -1)
		ThrowError("Failed to find m_Item on CTFWeaponBase");
	
	// Can't get model directly. Instead get index and look it up in string table.
	char model[PLATFORM_MAX_PATH];
	int modelidx = GetEntProp(fromWeapon, Prop_Send, "m_iWorldModelIndex");
	ModelIndexToString(modelidx, model, sizeof(model));
	
	int droppedWeapon = SDKCall(hCreateDroppedWeapon, client, origin, angles, model, GetEntityAddress(fromWeapon) + Address:itemOffset);
	if (droppedWeapon != INVALID_ENT_REFERENCE)
		SDKCall(hInitDroppedWeapon, droppedWeapon, client, fromWeapon, false, false);
	return droppedWeapon;
}

bool PickupDroppedWeapon(int client, int droppedWeapon)
{
	return SDKCall(hPickupWeaponFromOther, client, droppedWeapon);
}

void ModelIndexToString(int index, char[] model, int size)
{
	int table = FindStringTable("modelprecache");
	ReadStringTable(table, index, model, size);
}

int lastDrop;

public Action sm_pickit(client, argc)
{
	PickupDroppedWeapon(client, lastDrop);
	
	return Plugin_Handled;
}

public Action sm_dropit(client, argc)
{
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	float origin[3];
	GetClientAbsOrigin(client, origin);
	
	int droppedWeapon = CreateDroppedWeapon(weapon, client, origin, {0.0,0.0,0.0})
	
	lastDrop = droppedWeapon;
	
	return Plugin_Handled;
}