#pragma semicolon 1
#pragma newdecls required

#include <sdktools>

#define DEBUG

Handle g_hCBaseEntity_GetRefEHandle = null;
Handle g_hCBaseEntity_GetContextValue = null;
Handle g_hCBaseEntity_GetContextName = null;

Address m_ResponseContexts;
Address m_Size;

public Plugin myinfo =
{
    name = "Context Manager",
    author = "PŠΣ™ SHUFEN",
    description = "",
    version = "0.1",
    url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Context_GetContextCount", Native_GetContextCount);
	CreateNative("Context_GetContextName", Native_GetContextName);
	CreateNative("Context_GetContextValue", Native_GetContextValue);
	CreateNative("Context_FindContextByName", Native_FindContextByName);
	CreateNative("Context_GetContextValueByName", Native_GetContextValueByName);
	CreateNative("Context_AddContext", Native_AddContext);
	CreateNative("Context_ClearContext", Native_ClearContext);
	CreateNative("Context_RemoveContext", Native_RemoveContext);

	RegPluginLibrary("ContextManager");

	return APLRes_Success;
}

public void OnPluginStart()
{
	GameData hGameData = new GameData("ContextManager.games");
	if (hGameData == null) {
		SetFailState("Couldn't load \"ContextManager.games\" game config!");
		return;
	}

	// CBaseHandle CBaseEntity::GetRefEHandle( void )
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CBaseEntity::GetRefEHandle")) {
		SetFailState("PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, \"CBaseEntity::GetRefEHandle\") failed!");
	}
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hCBaseEntity_GetRefEHandle = EndPrepSDKCall();
	if (g_hCBaseEntity_GetRefEHandle == null) {
		SetFailState("Method \"CBaseEntity::GetRefEHandle\" was not loaded right.");
	}

	// const char *CBaseEntity::GetContextValue( int index )
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CBaseEntity::GetContextValue")) {
		SetFailState("PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, \"CBaseEntity::GetContextValue\") failed!");
	}
	PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hCBaseEntity_GetContextValue = EndPrepSDKCall();
	if (g_hCBaseEntity_GetContextValue == null) {
		SetFailState("Method \"CBaseEntity::GetContextValue\" was not loaded right.");
	}

	// const char *CBaseEntity::GetContextName( int index )
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CBaseEntity::GetContextName")) {
		SetFailState("PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, \"CBaseEntity::GetContextName\") failed!");
	}
	PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hCBaseEntity_GetContextName = EndPrepSDKCall();
	if (g_hCBaseEntity_GetContextName == null) {
		SetFailState("Method \"CBaseEntity::GetContextName\" was not loaded right.");
	}

	// m_ResponseContexts
	int offset = hGameData.GetOffset("m_ResponseContexts");
	if (offset == -1) {
		SetFailState("Couldn't get offset \"m_ResponseContexts\"");
	}
	m_ResponseContexts = view_as<Address>(offset);

	// m_Size
	offset = hGameData.GetOffset("m_Size");
	if (offset == -1) {
		SetFailState("Couldn't get offset \"m_Size\"");
	}
	m_Size = view_as<Address>(offset);

	delete hGameData;

	#if defined DEBUG
	RegConsoleCmd("sm_context", Command_ContextTest);
	#endif
}

#if defined DEBUG
public Action Command_ContextTest(int client, int args)
{
	if (!IsClientInGame(client))
		return Plugin_Handled;

	Address pEntity = GetEntityAddress(client);
	if (pEntity == Address_Null)
		return Plugin_Handled;

	int count = LoadFromAddress(pEntity + m_ResponseContexts + m_Size, NumberType_Int32);
	PrintToChat(client, "CBaseEntity::GetContextCount() -> %i", count);

	char sContextName[128], sContextValue[128];
	for (int x = 0; x < count; x++) {
		int len_name = SDKCall(g_hCBaseEntity_GetContextName, pEntity, sContextName, sizeof(sContextName), x);
		int len_value = SDKCall(g_hCBaseEntity_GetContextValue, pEntity, sContextValue, sizeof(sContextValue), x);
		PrintToChatAll("Context<%i>: %i:%i | \"%s:%s\"", x, len_name, len_value, sContextName, sContextValue);
	}

	return Plugin_Handled;
}
#endif

public int Native_GetContextCount(Handle plugin, int numParams)
{
	int entity = GetNativeCell(1);

	return GetContextCount(entity);
}

public int Native_GetContextName(Handle plugin, int numParams)
{
	int entity = GetNativeCell(1);
	int index = GetNativeCell(2);
	int maxlen = GetNativeCell(4);

	char[] buffer = new char[maxlen];

	int len = GetContextName(entity, index, buffer, maxlen);
	if (len == -1)
		return -1;

	return SetNativeString(3, buffer, maxlen);
}

public int Native_GetContextValue(Handle plugin, int numParams)
{
	int entity = GetNativeCell(1);
	int index = GetNativeCell(2);
	int maxlen = GetNativeCell(4);

	char[] buffer = new char[maxlen];

	int len = GetContextValue(entity, index, buffer, maxlen);
	if (len == -1)
		return -1;

	return SetNativeString(3, buffer, maxlen);
}

public int Native_FindContextByName(Handle plugin, int numParams)
{
	int entity = GetNativeCell(1);

	char contextName[128];
	GetNativeString(2, contextName, sizeof(contextName));

	return FindContextByName(entity, contextName);
}

public int Native_GetContextValueByName(Handle plugin, int numParams)
{
	int entity = GetNativeCell(1);

	char contextName[128];
	GetNativeString(2, contextName, sizeof(contextName));

	int maxlen = GetNativeCell(4);

	char[] buffer = new char[maxlen];

	int len = GetContextValueByName(entity, contextName, buffer, maxlen);
	if (len == -1)
		return -1;

	return SetNativeString(3, buffer, maxlen);
}

public int Native_AddContext(Handle plugin, int numParams)
{
	int entity = GetNativeCell(1);

	char context[128];
	GetNativeString(2, context, sizeof(context));

	return AddContext(entity, context);
}

public int Native_ClearContext(Handle plugin, int numParams)
{
	int entity = GetNativeCell(1);

	return ClearContext(entity);
}

public int Native_RemoveContext(Handle plugin, int numParams)
{
	int entity = GetNativeCell(1);

	char contextName[128];
	GetNativeString(2, contextName, sizeof(contextName));

	return RemoveContext(entity, contextName);
}

int GetContextCount(int entity)
{
	if (!IsValidEntity(entity))
		return -1;

	Address pEntity = GetEntityAddress(entity);
	if (pEntity == Address_Null)
		return -1;

	return LoadFromAddress(pEntity + m_ResponseContexts + m_Size, NumberType_Int32);
}

int GetContextName(int entity, int index, char[] buffer, int maxlen)
{
	if (!IsValidEntity(entity))
		return -1;

	Address pEntity = GetEntityAddress(entity);
	if (pEntity == Address_Null)
		return -1;

	return SDKCall(g_hCBaseEntity_GetContextName, pEntity, buffer, maxlen, index);
}

int GetContextValue(int entity, int index, char[] buffer, int maxlen)
{
	if (!IsValidEntity(entity))
		return -1;

	Address pEntity = GetEntityAddress(entity);
	if (pEntity == Address_Null)
		return -1;

	return SDKCall(g_hCBaseEntity_GetContextValue, pEntity, buffer, maxlen, index);
}

int FindContextByName(int entity, const char[] contextName)
{
	if (!IsValidEntity(entity))
		return -1;

	int c = GetContextCount(entity);
	if (c == -1)
		return -1;

	char buffer[128];
	for (int i = 0; i < c; i++) {
		GetContextName(entity, i, buffer, sizeof(buffer));
		if (StrEqual(contextName, buffer))
			return i;
	}

	return -1;
}

int GetContextValueByName(int entity, const char[] contextName, char[] buffer, int maxlen)
{
	int index = -1;
	if ((index = FindContextByName(entity, contextName)) == -1)
		return -1;

	return GetContextValue(entity, index, buffer, maxlen);
}

bool AddContext(int entity, const char[] context)
{
	if (!IsValidEntity(entity))
		return false;

	SetVariantString(context);
	return AcceptEntityInput(entity, "AddContext");
}

bool ClearContext(int entity)
{
	if (!IsValidEntity(entity))
		return false;

	return AcceptEntityInput(entity, "ClearContext");
}

bool RemoveContext(int entity, const char[] contextName)
{
	if (!IsValidEntity(entity))
		return false;

	SetVariantString(contextName);
	return AcceptEntityInput(entity, "RemoveContext");
}

stock Address CBaseEntity_GetRefEHandle(Address pEntity)
{
	if (pEntity == Address_Null)
		return Address_Null;

	return SDKCall(g_hCBaseEntity_GetRefEHandle, pEntity);
}

stock int CBaseEntity_GetEntIndex(Address pEntity)
{
	int ref = CBaseEntity_GetEntReference(pEntity);
	if (ref == INVALID_ENT_REFERENCE)
		return INVALID_ENT_REFERENCE;

	return EntRefToEntIndex(ref);
}

stock int CBaseEntity_GetEntReference(Address pEntity)
{
	Address addr = CBaseEntity_GetRefEHandle(pEntity);
	if (addr == Address_Null)
		return INVALID_ENT_REFERENCE;

	int EntHandle = LoadFromAddress(addr, NumberType_Int32);
	return (EntHandle | (1 << 31)) & 0xffffffff;
}
