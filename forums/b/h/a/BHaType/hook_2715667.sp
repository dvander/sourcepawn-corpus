#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sourcescramble>

#define ADDRESS(%1) view_as<Address>(%1)
#define BOOL(%1) view_as<bool>(%1)
#define INT(%1) view_as<int>(%1)

Address g_pCallback;

Address g_pServer, g_pSourcemod;
Address g_pPEB;

Handle g_hOriginal;

public void OnPluginStart()
{
	Init();
	CreateCallback();
	CreateHook();
}

// ====================================================================================================
//					OUR Callback
// ====================================================================================================

public void UTIL_SetModel (Address CBaseEntity, Address name)
{
	char szName[256];
	GetString(name, szName, sizeof szName);
	
	PrintToServer("UTIL_SetModel 0x%X %s", CBaseEntity, szName);
	
	SDKCall(g_hOriginal, CBaseEntity, szName);
}

// ====================================================================================================
//					Create Hook
// ====================================================================================================

void CreateHook()
{
	static const int iCall[] = { 0x55, 0x8B, 0xEC, 0x51, 0x56, 0xFF, 0x75, 0x08, 0xBE, 0x2A, 0x2A, 0x2A, 0x2A, 0x8B, 0xCE, 0x8B, 0x06, 0xFF, 0x10, 0x8B, 0x06, 0x8B, 0xCE, 0xFF, 0x75, 0x0C, 0xFF, 0x10, 0x8B, 0x06, 0x8D, 0x55, 0xFC, 0x52, 0x8B, 0xCE, 0xFF, 0x50, 0x20, 0x8B, 0x45, 0xFC, 0x5E, 0x8B, 0xE5, 0x5D, 0xC3 };
	static const int size = 9;
	
	int[] bytes = new int[size];
	
	MemoryBlock pMemory = new MemoryBlock (sizeof iCall + 4 + size); /* size of OUR patch + JMP + size of original bytes */
	Address pAddr = pMemory.Address;
	
	Address pServerBase = ADDRESS(LoadFromAddress(g_pServer + ADDRESS(8), NumberType_Int32)); /* Getting server base address */
	Address pFunc = pServerBase + ADDRESS(0x207490); /* adding base address to offset of UTIL_SetModel function */
	
	/* just nopping all the place where OUR jump will be located */
	
	for (int i; i < size; i++)
	{
		bytes[i] = LoadFromAddress(pFunc + ADDRESS(i), NumberType_Int8);
		StoreToAddress(pFunc + ADDRESS(i), 0x90, NumberType_Int8);
	}
	
	/* Creating a function that will call our callback */
	
	for (int i; i < sizeof iCall; i++)
		StoreToAddress(pAddr + ADDRESS(i), iCall[i], NumberType_Int8);
	
	/* Calculate relative addres for OUR jump */
	Address relative = (pAddr - pFunc) - ADDRESS(5);

	/* Inserting the jump that jumps from UTIL_SetModel into the function that will call OUR callback */
	StoreToAddress(pFunc, 0xE9, NumberType_Int8);
	StoreToAddress(pFunc + ADDRESS(1), INT(relative), NumberType_Int32);
	
	/* Calculate relative addres for OUR jump */
	relative = (pFunc - pAddr) - ADDRESS(sizeof iCall + size);
	
	/* Inserting the jump that jumps from the function that will call OUR callback into (UTIL_SetModel + 8) */
	for (int i; i < size; i++)
		StoreToAddress(pAddr + ADDRESS(sizeof iCall + i), bytes[i], NumberType_Int8);
	
	StoreToAddress(pAddr + ADDRESS(sizeof iCall + size), 0xE9, NumberType_Int8);
	StoreToAddress(pAddr + ADDRESS(sizeof iCall + size + 1), INT(relative), NumberType_Int32);
	
	/* Insert OUR callback */
	StoreToAddress(pAddr + ADDRESS(9), INT(g_pCallback), NumberType_Int32);
	
	PrintToServer("pAddr %X pFunc %X SDK %X", pAddr, pFunc, pAddr + ADDRESS(sizeof iCall));
	
	/* Creating OUR SDK which will call original code */
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetAddress(pAddr + ADDRESS(sizeof iCall));
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	g_hOriginal = EndPrepSDKCall();
}

// ====================================================================================================
//					Getiing Callback
// ====================================================================================================

void CreateCallback()
{
	static const int iContext[] = { 0x8B, 0x44, 0x24, 0x08, 0x56, 0x57, 0x8B, 0x7C, 0x24, 0x0C, 0x8B, 0xCF, 0xFF, 0x70, 0x08, 0x8B, 0x17, 0xFF, 0x92, 0x88, 0x00, 0x00, 0x00, 0x8B, 0xF0, 0x57, 0x8B, 0xCE, 0x8B, 0x16, 0xFF, 0x12, 0x8B, 0x16, 0x8D, 0x44, 0x24, 0x0C, 0x50, 0x8B, 0xCE, 0xFF, 0x52, 0x20, 0x5F, 0x33, 0xC0, 0x5E, 0xC3 };
	
	Address pSMBase = ADDRESS(LoadFromAddress(g_pSourcemod + ADDRESS(8), NumberType_Int32)); /* Getting sourcemod base address */
	Address pFunc = pSMBase + ADDRESS(0x33C0); /* adding base address to offset of SortFloat function */
	
	int iSaved[sizeof iContext]; /* Creating array to save original bytes */
	
	for (int i; i < sizeof iContext; i++)
	{
		/* Loading original byte and replacing it */
		
		iSaved[i] = LoadFromAddress(pFunc + ADDRESS(i), NumberType_Int8); 
		StoreToAddress(pFunc + ADDRESS(i), iContext[i], NumberType_Int8);		
	}
	
	/* Call a patched function that calls CreateHandleCallback in which we get a callback */
	
	float floats[1];
	SortFloats (floats, INT(CreateHandleCallback), Sort_Random); 
	
	/* Restore original bytes of SortFloats function*/
	
	for (int i; i < sizeof iContext; i++) 
		StoreToAddress(pFunc + ADDRESS(i), iSaved[i], NumberType_Int8);
}

void CreateHandleCallback (Address IPluginContext)
{
	/* Here we got the context of OUR plugin as an argument */
	/* Now You need to create an SDKCall using a context */
	
	StartPrepSDKCall(SDKCall_Raw);
	
	/* 136 is offset to GetFunctionById which is located in virtual method table */
	/* https://www.sourcemod.net/sp-dox/class_source_pawn_1_1_i_plugin_context.html */
	
	PrepSDKCall_SetAddress(ADDRESS(LoadFromAddress(ADDRESS(LoadFromAddress(IPluginContext, NumberType_Int32)) + ADDRESS(136), NumberType_Int32)));
	
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	Handle hCall = EndPrepSDKCall();
	
	/* Call OUR SDK and return OUR callback */
	g_pCallback = ADDRESS(SDKCall(hCall, IPluginContext, INT(UTIL_SetModel))); 
	
	delete hCall;
}

// ====================================================================================================
//					Getting PEB & Modules
// ====================================================================================================

void Init()
{
	static const int bytes[] = { 0x64, 0xA1, 0x30, 0x00, 0x00, 0x00, 0xC3 };

	MemoryBlock pMemory = new MemoryBlock (sizeof bytes);
	
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetAddress(pMemory.Address);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	Handle get = EndPrepSDKCall();
	
	for (int i; i < sizeof bytes; i++)
		pMemory.StoreToOffset(i, bytes[i], NumberType_Int8);
	
	g_pPEB = ADDRESS(SDKCall(get));
	
	delete get;
	
	EnumerateModules (g_pPEB);
	
	delete pMemory;
}

Address EnumerateModules (Address pProcessEnviromentBlock)
{
	/* Why 0x0C and 0x1C? */
	/* This is an offset that can be calculated through the structures I showed above in the C++ code */
	
	Address InInitilizationOrderModuleList = ADDRESS(LoadFromAddress(ADDRESS(LoadFromAddress(pProcessEnviromentBlock + ADDRESS(0x0C), NumberType_Int32)) + ADDRESS(0x1C), NumberType_Int32));
	
	Address pStart = ADDRESS(LoadFromAddress(InInitilizationOrderModuleList, NumberType_Int32)); /* Getting first module */
	Address pModule = ADDRESS(LoadFromAddress(pStart, NumberType_Int32)); 						/* Getting next module */
	
	while (LoadFromAddress(pModule, NumberType_Int32) != INT(pStart)) /* Iteration until we reach first module */
	{
		char szName[36];
		ReadUnicode(ADDRESS(LoadFromAddress(pModule + ADDRESS(0x20), NumberType_Int32)), szName, sizeof szName);
		
		if (strcmp(szName, "sourcemod.logic.dll") == 0)					g_pSourcemod = pModule;
		else if (strcmp(szName, "server.dll") == 0 && !g_pServer)			g_pServer = pModule;
		
		pModule = ADDRESS(LoadFromAddress(pModule, NumberType_Int32));
	}
	
	return Address_Null;
}

void ReadUnicode (Address pStart, char[] szBuffer, int lenght)
{
	char szName[256];

	int count;
	
	while (!DoubleNullTermination(pStart))
	{
		szName[count] = view_as<char>(LoadFromAddress(pStart + view_as<Address>(count), NumberType_Int8));
		
		pStart++;
		count++;
	}
	
	for (int i = count; i >= 0; i--)
		if (szName[i] == 0x00)
			szName[i] = view_as<char>(0x85);
	
	int pos;
	
	if ((pos = StrContains(szName, ".dll", false)) != -1)
		szName[pos + 4] = view_as<char>(0x00);
		
	strcopy(szBuffer, lenght, szName);
}

bool DoubleNullTermination (Address pAddr)
{
	return (pAddr != Address_Null && pAddr + view_as<Address>(1) != Address_Null) ? (LoadFromAddress(pAddr, NumberType_Int8) != 0x00 && LoadFromAddress(pAddr + view_as<Address>(1), NumberType_Int8) != 0x00) : true;
}

// ====================================================================================================
//					Stocks
// ====================================================================================================

stock void GetString (Address ptr, char[] szBuffer, int len)
{
	int byte, counter;
	
	while ((byte = LoadFromAddress(ptr + ADDRESS(counter), NumberType_Int8)) != '\0' && counter <= len - 1)
	{
		szBuffer[counter] = view_as<char>(byte);
		counter++;
	}
}