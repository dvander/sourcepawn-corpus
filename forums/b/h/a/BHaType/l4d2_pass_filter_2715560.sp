#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#include <sourcescramble>
#include <dhooks>

#define MAX 7

#define INTERFACE_NAME "StaticPropMgrServer002"

public Plugin myinfo =
{
	name = "Collision Hook",
	author = "BHaType"
};

enum struct IPluginContext
{
	MemoryBlock passfilter;
	MemoryBlock relocation;
	
	Address pFunction;
	
	int size;
	int original[MAX];
}

IPluginContext context;
GlobalForward g_hPassFilterForward;
Address staticpropmgr;
Handle g_hIsStaticProp, g_hGetBaseEntity;

public APLRes AskPluginLoad2 (Handle core, bool late, char[] error, int lenght) 
{
	g_hPassFilterForward = new GlobalForward("OnPassServerEntityFilter", ET_Hook, Param_Cell, Param_Cell);
}

public MRESReturn PassServerEntityFilter (DHookReturn retn, DHookParam params)
{
	int left = params.Get(1);
	int right = params.Get(2);
	
	if ( left == right )
	{
		retn.Value = 1;
		return MRES_Supercede;
	}
	
	if ( !left || !right || IsStaticProp(left) || IsStaticProp(right) )
	{
		retn.Value = 1;
		return MRES_Supercede;
	}
	
	if ( (left = GetEntity(left)) == -1 || (right = GetEntity(right)) == -1 )
	{
		retn.Value = 1;
		return MRES_Supercede;
	}
	
	
	int action = -1;
	
	Call_StartForward(g_hPassFilterForward);
	Call_PushCell(left);
	Call_PushCell(right);
	Call_Finish(action);
	
	retn.Value = action;
	
	return retn.Value != -1 ? MRES_Supercede : MRES_Ignored;
}
public void OnPluginStart()
{
	Init();
	
	if ( CreateCodeCave() )
	{
		CreateCodeRelocation();
		Hook();
	}
}

public void OnPluginEnd()
{
	Unhook();
}

void Hook()
{
	DynamicDetour detour = new DynamicDetour(context.passfilter.Address, CallConv_CDECL, ReturnType_Int);
	detour.AddParam(HookParamType_Int);
	detour.AddParam(HookParamType_Int);
	detour.Enable(Hook_Pre, PassServerEntityFilter);
}

void Unhook()
{
	for (int i; i < context.size; i++)
	{
		StoreToAddress(context.pFunction + view_as<Address>(i), context.original[i], NumberType_Int8);
	}
	
	delete context.passfilter;
	delete context.relocation;
}

void Init()
{
	context.passfilter = new MemoryBlock(0x30);	
	context.relocation = new MemoryBlock(0xF);
	
	GameData data = new GameData("l4d2_pass_filter"); 
	
	context.pFunction = data.GetAddress("PassServerEntityFilter"); 
	context.size = data.GetOffset("size");
	
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetSignature(SDKLibrary_Engine, "@CreateInterface", 0);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	Handle hGetInterface = EndPrepSDKCall();
	
	staticpropmgr = SDKCall(hGetInterface, INTERFACE_NAME, 0);
	
	delete hGetInterface;
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetVirtual(data.GetOffset("IsStaticProp"));
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hIsStaticProp = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetVirtual(data.GetOffset("GetBaseEntity"));
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hGetBaseEntity = EndPrepSDKCall();
	
	delete data;
}

bool CreateCodeCave()
{
	static bool hacked;
	
	if ( hacked )
		return false;
		
	static const int sequence[] = { 0x55, 0x8B, 0xEC, 0x83, 0xC8, 0xFF, 0x5D, 0xC2, 0x00, 0x00, 0x90, 0x90, 0x8B, 0x45, 0x08, 0x50, 0x8B, 0x4D, 0x0C, 0x51, 0xE8, 0xE7, 0xFF, 0xFF, 0xFF, 0x81, 0xC4, 0x08, 0x00, 0x00, 0x00, 0x83, 0xF8, 0xFF, 0x0F, 0x84, 0x00, 0x00, 0x00, 0x00, 0x8B, 0xE5, 0x5D, 0xC2, 0x00, 0x00 };
	
	for (int i; i < sizeof sequence; i++)
	{
		context.passfilter.StoreToOffset(i, sequence[i], NumberType_Int8);
	}
	
	hacked = true;
	return true;
}

void CreateCodeRelocation()
{
	for (int i; i < context.size; i++)
	{
		context.original[i] = LoadFromAddress(context.pFunction + view_as<Address>(i), NumberType_Int8);
		context.relocation.StoreToOffset(i + 5, context.original[i], NumberType_Int8);
		StoreToAddress(context.pFunction + view_as<Address>(i), 0x90, NumberType_Int8);
	}
	
	StoreToAddress(context.pFunction, 0xE9, NumberType_Int8);
	StoreToAddress(context.pFunction + view_as<Address>(1), GetRelativeOffset(context.pFunction, context.relocation.Address), NumberType_Int32);
	
	StoreToAddress(context.relocation.Address, 0xE9, NumberType_Int8);
	StoreToAddress(context.relocation.Address + view_as<Address>(1), GetRelativeOffset(context.relocation.Address, context.passfilter.Address + view_as<Address>(12)), NumberType_Int32);
	
	StoreToAddress(context.relocation.Address + view_as<Address>(context.size + 5), 0xE9, NumberType_Int8);
	StoreToAddress(context.relocation.Address + view_as<Address>(context.size + 1 + 5), GetRelativeOffset(context.relocation.Address + view_as<Address>(context.size + 5), context.pFunction + view_as<Address>(5)), NumberType_Int32);
	
	StoreToAddress(context.passfilter.Address + view_as<Address>(36), GetRelativeOffset(context.passfilter.Address + view_as<Address>(35), context.relocation.Address + view_as<Address>(5)), NumberType_Int32);
}

static int GetEntity (int entity)
{
	return SDKCall(g_hGetBaseEntity, entity);
}

stock bool IsStaticProp (any handle)
{	
	return SDKCall(g_hIsStaticProp, staticpropmgr, handle); 
}

stock Address GetRelativeOffset (Address source, Address destination) 
{
	return destination - source - view_as<Address>(5);  
}