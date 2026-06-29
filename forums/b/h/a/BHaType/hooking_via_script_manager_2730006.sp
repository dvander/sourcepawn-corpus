#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#include <MemoryEx>

#define ADDRESS(%1) view_as<Address>(%1)
#define BOOL(%1) view_as<bool>(%1)
#define INT(%1) view_as<int>(%1)

Address g_pScripts;
Handle g_hOriginal;

public void OnPluginStart()
{
    CheckInitPEB();
}

public void MemoryEx_InitPEB()
{
	g_pScripts = FindPattern(g_hMem.GetModuleHandle("sourcemod.logic"), GetModuleSize("sourcemod.logic"), { 0x28, 0x4A, 0x2A, 0x2A, 0x08 }, 5);
	Hook();
} 

public void UTIL_SetModel (Address CBaseEntity, Address name)
{
	char szName[256];
	GetString(name, szName, sizeof szName);
	
	PrintToServer("UTIL_SetModel 0x%X %s", CBaseEntity, szName);
	
	SDKCall(g_hOriginal, CBaseEntity, szName);
}

void Hook()
{
	static const int iCall[] = { 0x55, 0x8B, 0xEC, 0x51, 0x56, 0xFF, 0x75, 0x08, 0xBE, 0x2A, 0x2A, 0x2A, 0x2A, 0x8B, 0xCE, 0x8B, 0x06, 0xFF, 0x10, 0x8B, 0x06, 0x8B, 0xCE, 0xFF, 0x75, 0x0C, 0xFF, 0x10, 0x8B, 0x06, 0x8D, 0x55, 0xFC, 0x52, 0x8B, 0xCE, 0xFF, 0x50, 0x20, 0x8B, 0x45, 0xFC, 0x5E, 0x8B, 0xE5, 0x5D, 0xC3 };
	static const int size = 9;
	
	int[] bytes = new int[size];
	
	Address pAddr = VirtualAlloc(sizeof iCall + 4 + size);

	Address pFunc = g_hMem.GetModuleHandle("server") + ADDRESS(0x20A870);
	
	for (int i; i < size; i++)
	{
		bytes[i] = LoadFromAddress(pFunc + ADDRESS(i), NumberType_Int8);
		StoreToAddress(pFunc + ADDRESS(i), 0x90, NumberType_Int8);
	}
	
	for (int i; i < sizeof iCall; i++)
		StoreToAddress(pAddr + ADDRESS(i), iCall[i], NumberType_Int8);
	
	Address relative = (pAddr - pFunc) - ADDRESS(5);

	StoreToAddress(pFunc, 0xE9, NumberType_Int8);
	StoreToAddress(pFunc + ADDRESS(1), INT(relative), NumberType_Int32);
	
	relative = (pFunc - pAddr) - ADDRESS(sizeof iCall + size);
	
	for (int i; i < size; i++)
		StoreToAddress(pAddr + ADDRESS(sizeof iCall + i), bytes[i], NumberType_Int8);
	
	StoreToAddress(pAddr + ADDRESS(sizeof iCall + size), 0xE9, NumberType_Int8);
	StoreToAddress(pAddr + ADDRESS(sizeof iCall + size + 1), INT(relative), NumberType_Int32);
	
	StoreToAddress(pAddr + ADDRESS(9), INT(GetHandleCallback(GetMyHandle(), UTIL_SetModel)), NumberType_Int32);

	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetAddress(pAddr + ADDRESS(sizeof iCall));
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	g_hOriginal = EndPrepSDKCall();
}

Address GetHandleCallback (Handle plugin, Function pFunc)
{
	static Handle GetFunctionById;
	
	Address context = GetPluginContext(plugin);
	
	if ( !GetFunctionById )
	{
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetAddress(ADDRESS(LoadFromAddress(ADDRESS(LoadFromAddress(context, NumberType_Int32)) + ADDRESS(136), NumberType_Int32)));
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		GetFunctionById = EndPrepSDKCall();
	}
	
	return ADDRESS(SDKCall(GetFunctionById, context, INT(pFunc)));
}

Address GetPluginContext (Handle plugin)
{
	if ( g_pScripts == Address_Null )
	{
		SetFailState("...");
		return Address_Null;
	}
	
	Address script = ADDRESS(LoadFromAddress(g_pScripts, NumberType_Int32));
	
	static Handle hGetPluginByHandle;
	static Handle GetContext;
	
	if ( !hGetPluginByHandle )
	{
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetAddress(ADDRESS(LoadFromAddress(ADDRESS(LoadFromAddress(script, NumberType_Int32)) + ADDRESS(0x3C), NumberType_Int32)));
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		hGetPluginByHandle = EndPrepSDKCall();
	}

	Address IPlugin = ADDRESS(SDKCall(hGetPluginByHandle, script, plugin, 0));
	
	if ( !GetContext )
	{
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetAddress(ADDRESS(LoadFromAddress(ADDRESS(LoadFromAddress(IPlugin, NumberType_Int32) + 8), NumberType_Int32)));
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		GetContext = EndPrepSDKCall();
	}
	
	return ADDRESS(SDKCall(GetContext, IPlugin));
}

stock void GetString (Address ptr, char[] szBuffer, int len)
{
	int byte, counter;
	
	while ((byte = LoadFromAddress(ptr + ADDRESS(counter), NumberType_Int8)) != '\0' && counter <= len - 1)
	{
		szBuffer[counter] = view_as<char>(byte);
		counter++;
	}
}