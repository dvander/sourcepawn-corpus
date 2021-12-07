#include <sourcemod>

native ArrayList Creat3Array(int blocksize=1, int startsize=0);

native int Get3ntProp(int iEntity, PropType pType, char[] szProp, int iSize = 4, int iElem = 0);
native void Set3ntProp(int iEntity, PropType pType, char[] szProp, any _Val, int iSize = 4, int iElem = 0);

native float Get3ntPropFloat(int iEntity, PropType pType, char[] szProp, int iElem = 0);
native void Set3ntPropFloat(int iEntity, PropType pType, char[] szProp, float fVal, int iElem = 0);

native int Get3ntPropEnt(int iEntity, PropType pType, char[] szProp, int iElem = 0);
native void Set3ntPropEnt(int iEntity, PropType pType, char[] szProp, int iOther, int iElem = 0);

native void Get3ntPropVector(int iEntity, PropType pType, char[] szProp, float pVec[3], int iElem = 0);
native void Set3ntPropVector(int iEntity, PropType pType, char[] szProp, float pVec[3], int iElem = 0);

native int Get3ntPropString(int iEntity, PropType pType, char[] szProp, char[] szBuff, int iMaxSize, int iElem = 0);
native int Set3ntPropString(int iEntity, PropType pType, char[] szProp, char[] szBuff, int iElem = 0);

Handle g_pStrings = INVALID_HANDLE, g_pIndexes = INVALID_HANDLE;

int Find(char[] szProp)
{
	static int iIter = 0, iInfo = 0;

	static char pClasses[][] =
	{
		"Player", "CSPlayer", "CCSPlayer", "GameResource", "GameResources",
		"CGameResource", "CGameResources", "CSGameResource", "CSGameResources",
		"CCSGameResource", "CCSGameResources", "BasePlayer", "CBasePlayer",
		"BaseEntity", "CBaseEntity", "BaseWeapon", "CBaseWeapon", "BaseGrenade",
		"CBaseGrenade", "BaseCombatWeapon", "CBaseCombatWeapon", "WeaponCSBase",
		"CWeaponCSBase", "CSWeaponCSBase", "CCSWeaponCSBase", "PlayerResource",
		"CPlayerResource", "CSPlayerResource", "CCSPlayerResource", "PlayerResources",
		"CPlayerResources", "CSPlayerResources", "CCSPlayerResources", "BaseAnimating",
		"CBaseAnimating", "BaseCombatCharacter", "CBaseCombatCharacter",
		"BaseMultiplayerPlayer", "CBaseMultiplayerPlayer", "BaseFlex", "CBaseFlex"
	};

	for (iIter = 0; iIter < sizeof(pClasses); iIter++)
	{
		if ((iInfo = FindSendPropInfo(pClasses[iIter], szProp)) > 0)
			return iInfo;
	}

	return 0;
}

int GetOffSize(char[] szProp)
{
	static int iIter = 0;

	static char pProps[][] =
	{
		"BOT", "Helmet", "RenderFX"
	};

	for (iIter = 0; iIter < sizeof(pProps); iIter++)
	{
		if (StrContains(szProp, pProps[iIter], false) != -1)
			return 1;
	}

	return 4;
}

public APLRes AskPluginLoad2(Handle pSelf, bool bLateLoaded, char[] szError, int iMaxSize)
{
	CreateNative("CreateArray", __CreateArray);

	CreateNative("GetEntProp", __GetEntProp);
	CreateNative("SetEntProp", __SetEntProp);

	CreateNative("GetEntPropEnt", __GetEntPropEnt);
	CreateNative("SetEntPropEnt", __SetEntPropEnt);

	CreateNative("GetEntPropFloat", __GetEntPropFloat);
	CreateNative("SetEntPropFloat", __SetEntPropFloat);

	CreateNative("GetEntPropVector", __GetEntPropVector);
	CreateNative("SetEntPropVector", __SetEntPropVector);

	CreateNative("GetEntPropString", __GetEntPropString);
	CreateNative("SetEntPropString", __SetEntPropString);

	RegPluginLibrary("entprop");

	return APLRes_Success;
}

public void OnPluginStart()
{
	g_pIndexes = CreateArray(MAX_NAME_LENGTH);
	g_pStrings = CreateArray(MAX_NAME_LENGTH);
}

public int __CreateArray(Handle pPlug, int iParams)
{
	int iMaxSize = GetNativeCell(1);

	if (iMaxSize >= (PLATFORM_MAX_PATH * 2))
		iMaxSize /= 32;

	else if (iMaxSize >= PLATFORM_MAX_PATH || iMaxSize > (PLATFORM_MAX_PATH / 2))
		iMaxSize /= 14;

	else if (iMaxSize == (PLATFORM_MAX_PATH / 2))
		iMaxSize = 8;

	else if (iMaxSize >= 4)
		iMaxSize /= 4;

	return view_as<int>(Creat3Array(iMaxSize));
}

public int __GetEntProp(Handle pPlug, int iParams)
{
	static int iEntity = INVALID_ENT_REFERENCE, iPos = 0, iProp = 0;
	static char szProp[PLATFORM_MAX_PATH] = "";

	iEntity = GetNativeCell(1);
	GetNativeString(3, szProp, sizeof(szProp));

	if (StrContains(szProp, "MoveType", false) != -1 || \
			StrContains(szProp, "iFrags", false) != -1 || \
				StrContains(szProp, "iDeaths", false) != -1 || \
					StrContains(szProp, "nButtons", false) != -1)
	{
		return Get3ntProp(iEntity, Prop_Data, szProp);
	}

	iPos = FindStringInArray(g_pStrings, szProp);

	if (iPos >= 0)
		return GetEntData(iEntity, GetArrayCell(g_pIndexes, iPos), GetOffSize(szProp));

	iProp = Find(szProp);

	if (iProp > 0)
	{
		PushArrayString(g_pStrings, szProp);
		PushArrayCell(g_pIndexes, iProp);

		return GetEntData(iEntity, iProp, GetOffSize(szProp));
	}
	
	return Get3ntProp(iEntity, GetNativeCell(2), szProp, GetNativeCell(4));
}

public int __SetEntProp(Handle pPlug, int iParams)
{
	static int iEntity = INVALID_ENT_REFERENCE, iPos = 0, iProp = 0, iVal = 0;
	static char szProp[PLATFORM_MAX_PATH] = "";

	iEntity = GetNativeCell(1);
	GetNativeString(3, szProp, sizeof(szProp));
	iVal = GetNativeCell(4);

	if (StrContains(szProp, "MoveType", false) != -1 || \
			StrContains(szProp, "iFrags", false) != -1 || \
				StrContains(szProp, "iDeaths", false) != -1 || \
					StrContains(szProp, "nButtons", false) != -1)
	{
		Set3ntProp(iEntity, Prop_Data, szProp, iVal);
		return 1;
	}

	iPos = FindStringInArray(g_pStrings, szProp);

	if (iPos >= 0)
	{
		SetEntData(iEntity, GetArrayCell(g_pIndexes, iPos), iVal, GetOffSize(szProp));

		if (StrContains(szProp, "iObserverMode", false) != -1)
			ChangeEdictState(iEntity, GetArrayCell(g_pIndexes, iPos));

		return 1;
	}

	iProp = Find(szProp);

	if (iProp > 0)
	{
		PushArrayString(g_pStrings, szProp);
		PushArrayCell(g_pIndexes, iProp);

		SetEntData(iEntity, iProp, iVal, GetOffSize(szProp));

		if (StrContains(szProp, "iObserverMode", false) != -1)
			ChangeEdictState(iEntity, iProp);

		return 1;
	}
	
	Set3ntProp(iEntity, GetNativeCell(2), szProp, iVal, GetNativeCell(5));
	return 1;
}

public int __GetEntPropEnt(Handle pPlug, int iParams)
{
	static int iEntity = INVALID_ENT_REFERENCE, iPos = 0, iProp = 0;
	static char szProp[PLATFORM_MAX_PATH] = "";
	
	iEntity = GetNativeCell(1);
	GetNativeString(3, szProp, sizeof(szProp));

	iPos = FindStringInArray(g_pStrings, szProp);
	
	if (iPos >= 0)
		return GetEntDataEnt2(iEntity, GetArrayCell(g_pIndexes, iPos));
	
	iProp = Find(szProp);
	
	if (iProp > 0)
	{
		PushArrayString(g_pStrings, szProp);
		PushArrayCell(g_pIndexes, iProp);
		
		return GetEntDataEnt2(iEntity, iProp);
	}

	return Get3ntPropEnt(iEntity, GetNativeCell(2), szProp, GetNativeCell(4));
}

public int __SetEntPropEnt(Handle pPlug, int iParams)
{
	static int iEntity = INVALID_ENT_REFERENCE, iPos = 0, iProp = 0, iVal = 0;
	static char szProp[PLATFORM_MAX_PATH] = "";
	
	iEntity = GetNativeCell(1);
	GetNativeString(3, szProp, sizeof(szProp));
	iVal = GetNativeCell(4);

	iPos = FindStringInArray(g_pStrings, szProp);
	
	if (iPos >= 0)
	{
		SetEntDataEnt2(iEntity, GetArrayCell(g_pIndexes, iPos), iVal);
		
		if (StrContains(szProp, "hObserverTarget", false) != -1)
			ChangeEdictState(iEntity, GetArrayCell(g_pIndexes, iPos));
		
		return 1;
	}
	
	iProp = Find(szProp);
	
	if (iProp > 0)
	{
		PushArrayString(g_pStrings, szProp);
		PushArrayCell(g_pIndexes, iProp);
		
		SetEntDataEnt2(iEntity, iProp, iVal);
		
		if (StrContains(szProp, "hObserverTarget", false) != -1)
			ChangeEdictState(iEntity, iProp);
		
		return 1;
	}

	Set3ntPropEnt(iEntity, GetNativeCell(2), szProp, iVal, GetNativeCell(5));
	return 1;
}

public int __GetEntPropFloat(Handle pPlug, int iParams)
{
	static int iEntity = INVALID_ENT_REFERENCE, iPos = 0, iProp = 0;
	static char szProp[PLATFORM_MAX_PATH] = "";

	iEntity = GetNativeCell(1);
	GetNativeString(3, szProp, sizeof(szProp));

	if (StrContains(szProp, "fLerpTime", false) != -1 || \
			StrContains(szProp, "flGravity", false) != -1)
	{
		return view_as<int>(Get3ntPropFloat(iEntity, Prop_Data, szProp));
	}

	iPos = FindStringInArray(g_pStrings, szProp);

	if (iPos >= 0)
		return view_as<int>(GetEntDataFloat(iEntity, GetArrayCell(g_pIndexes, iPos)));

	iProp = Find(szProp);

	if (iProp > 0)
	{
		PushArrayString(g_pStrings, szProp);
		PushArrayCell(g_pIndexes, iProp);

		return view_as<int>(GetEntDataFloat(iEntity, iProp));
	}

	return view_as<int>(Get3ntPropFloat(iEntity, GetNativeCell(2), szProp, GetNativeCell(4)));
}

public int __SetEntPropFloat(Handle pPlug, int iParams)
{
	static int iEntity = INVALID_ENT_REFERENCE, iPos = 0, iProp = 0;
	static char szProp[PLATFORM_MAX_PATH] = "";
	static float fVal = 0.0;

	iEntity = GetNativeCell(1);
	GetNativeString(3, szProp, sizeof(szProp));
	fVal = view_as<float>(GetNativeCell(4));

	if (StrContains(szProp, "fLerpTime", false) != -1 || \
			StrContains(szProp, "flGravity", false) != -1)
	{
		Set3ntPropFloat(iEntity, Prop_Data, szProp, fVal);
		return 1;
	}

	iPos = FindStringInArray(g_pStrings, szProp);

	if (iPos >= 0)
	{
		SetEntDataFloat(iEntity, GetArrayCell(g_pIndexes, iPos), fVal);
		return 1;
	}

	iProp = Find(szProp);

	if (iProp > 0)
	{
		PushArrayString(g_pStrings, szProp);
		PushArrayCell(g_pIndexes, iProp);

		SetEntDataFloat(iEntity, iProp, fVal);
		return 1;
	}

	Set3ntPropFloat(iEntity, GetNativeCell(2), szProp, fVal, GetNativeCell(5));
	return 1;
}

public int __GetEntPropVector(Handle pPlug, int iParams)
{
	static int iEntity = INVALID_ENT_REFERENCE, iPos = 0, iProp = 0;
	static char szProp[PLATFORM_MAX_PATH] = "";
	static float pVec[3] = { 0.0, ... };
	
	iEntity = GetNativeCell(1);
	GetNativeString(3, szProp, sizeof(szProp));

	if (StrContains(szProp, "angAbsRotation", false) != -1 || \
			StrContains(szProp, "vecAbsOrigin", false) != -1)
	{
		Get3ntPropVector(iEntity, Prop_Data, szProp, pVec);
		SetNativeArray(4, pVec, sizeof(pVec));

		return 1;
	}

	iPos = FindStringInArray(g_pStrings, szProp);
	
	if (iPos >= 0)
	{
		GetEntDataVector(iEntity, GetArrayCell(g_pIndexes, iPos), pVec);
		SetNativeArray(4, pVec, sizeof(pVec));

		return 1;
	}
	
	iProp = Find(szProp);
	
	if (iProp > 0)
	{
		PushArrayString(g_pStrings, szProp);
		PushArrayCell(g_pIndexes, iProp);
		
		GetEntDataVector(iEntity, iProp, pVec);
		SetNativeArray(4, pVec, sizeof(pVec));
		
		return 1;
	}
	
	Get3ntPropVector(iEntity, GetNativeCell(2), szProp, pVec);
	SetNativeArray(4, pVec, sizeof(pVec));
	
	return 1;
}

public int __SetEntPropVector(Handle pPlug, int iParams)
{
	static int iEntity = INVALID_ENT_REFERENCE, iPos = 0, iProp = 0;
	static char szProp[PLATFORM_MAX_PATH] = "";
	static float pVal[3] = { 0.0, ... };

	iEntity = GetNativeCell(1);
	GetNativeString(3, szProp, sizeof(szProp));
	GetNativeArray(4, pVal, 3);

	if (StrContains(szProp, "angAbsRotation", false) != -1 || \
			StrContains(szProp, "vecAbsOrigin", false) != -1)
	{
		Set3ntPropVector(iEntity, Prop_Data, szProp, pVal);
		return 1;
	}

	iPos = FindStringInArray(g_pStrings, szProp);

	if (iPos >= 0)
	{
		SetEntDataVector(iEntity, GetArrayCell(g_pIndexes, iPos), pVal);
		return 1;
	}

	iProp = Find(szProp);

	if (iProp > 0)
	{
		PushArrayString(g_pStrings, szProp);
		PushArrayCell(g_pIndexes, iProp);

		SetEntDataVector(iEntity, iProp, pVal);
		return 1;
	}

	Set3ntPropVector(iEntity, GetNativeCell(2), szProp, pVal);
	return 1;
}

public int __GetEntPropString(Handle pPlug, int iParams)
{
	static int iEntity = INVALID_ENT_REFERENCE, iPos = 0, iProp = 0;
	static char szProp[PLATFORM_MAX_PATH] = "", szString[PLATFORM_MAX_PATH] = "";
	
	iEntity = GetNativeCell(1);
	GetNativeString(3, szProp, sizeof(szProp));
	
	if (StrContains(szProp, "iClassname", false) != -1)
	{
		GetEdictClassname(iEntity, szString, sizeof(szString));
		SetNativeString(4, szString, GetNativeCell(5));
		
		return 1;
	}
	
	iPos = FindStringInArray(g_pStrings, szProp);
	
	if (iPos >= 0)
	{
		GetEntDataString(iEntity, GetArrayCell(g_pIndexes, iPos), szString, sizeof(szString));
		SetNativeString(4, szString, GetNativeCell(5));

		return 1;
	}
	
	iProp = Find(szProp);
	
	if (iProp > 0)
	{
		PushArrayString(g_pStrings, szProp);
		PushArrayCell(g_pIndexes, iProp);
		
		GetEntDataString(iEntity, iProp, szString, sizeof(szString));
		SetNativeString(4, szString, GetNativeCell(5));
		
		return 1;
	}
	
	Get3ntPropString(iEntity, GetNativeCell(2), szProp, szString, sizeof(szString));
	SetNativeString(4, szString, GetNativeCell(5));
	
	return 1;
}

public int __SetEntPropString(Handle pPlug, int iParams)
{
	static int iEntity = INVALID_ENT_REFERENCE, iPos = 0, iProp = 0;
	static char szProp[PLATFORM_MAX_PATH] = "", szString[PLATFORM_MAX_PATH] = "";

	iEntity = GetNativeCell(1);
	GetNativeString(3, szProp, sizeof(szProp));
	GetNativeString(4, szString, sizeof(szString));

	if (StrContains(szProp, "iClassname", false) != -1)
	{
		Set3ntPropString(iEntity, Prop_Data, "m_iClassname", szString);
		return 1;
	}

	iPos = FindStringInArray(g_pStrings, szProp);
	
	if (iPos >= 0)
	{
		SetEntDataString(iEntity, GetArrayCell(g_pIndexes, iPos), szString, sizeof(szString));
		return 1;
	}
	
	iProp = Find(szProp);
	
	if (iProp > 0)
	{
		PushArrayString(g_pStrings, szProp);
		PushArrayCell(g_pIndexes, iProp);
		
		SetEntDataString(iEntity, iProp, szString, sizeof(szString));
		return 1;
	}
	
	Set3ntPropString(iEntity, GetNativeCell(2), szProp, szString, sizeof(szString));
	return 1;
}
