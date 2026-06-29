#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <gifts>

#define PLUGIN_VERSION "1.1"

enum Module
{
	Handle:PluginHndl,
	Function:FunctionId
}

new Handle:g_hCvarChance = INVALID_HANDLE;
new Handle:g_hCvarLifetime = INVALID_HANDLE;
new Handle:g_hCvarModel = INVALID_HANDLE;
new Handle:g_hPlugins = INVALID_HANDLE;

new Float:g_fChance = 0.50;
new Float:g_fLifetime = 5.0;

new String:g_sModel[PLATFORM_MAX_PATH]="models/items/cs_gift.mdl";

new GiftConditions:g_eConditions[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "[ANY] Gifts",
	author = "Zephyrus",
	description = "Gifts :333",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	
	g_hCvarChance = CreateConVar("sm_gifts_chance", "0.50", "Chance that a gift will be spawned upon player death.", 0, true, 0.0, true, 1.0);
	g_hCvarLifetime = CreateConVar("sm_gifts_lifetime", "5.0", "Lifetime of the gift.");
	g_hCvarModel = CreateConVar("sm_gifts_model", "models/items/cs_gift.mdl", "Model file for the gift");
	
	HookConVarChange(g_hCvarChance, ConVarChange);
	HookConVarChange(g_hCvarLifetime, ConVarChange);
}

public OnMapStart()
{
	GetConVarString(g_hCvarModel, g_sModel, PLATFORM_MAX_PATH);
	
	PrecacheModel(g_sModel);
}

public OnClientDisconnect(client)
{
	g_eConditions[client]=Condition_None;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_hPlugins = CreateArray(2);

	CreateNative("Gifts_RegisterPlugin", Native_RegisterPlugin);
	CreateNative("Gifts_RemovePlugin", Native_RemovePlugin);
	CreateNative("Gifts_SetClientCondition", Native_SetClientCondition);
	CreateNative("Gifts_GetClientCondition", Native_GetClientCondition);
	return APLRes_Success;
}

public Native_RegisterPlugin(Handle:plugin, numParams)
{
	new id = GetArraySize(g_hPlugins);
	ResizeArray(g_hPlugins, id+1);
	
	new String:sFunc[64];
	GetNativeString(1, sFunc, 64);
	
	new Module:tmp[Module];
	
	tmp[PluginHndl]=plugin;
	tmp[FunctionId]=GetFunctionByName(plugin, sFunc);
	
	if(tmp[FunctionId]==INVALID_FUNCTION)
		return 0;
	
	SetArrayArray(g_hPlugins, id, tmp[0]);
	
	return 1;
}

public Native_RemovePlugin(Handle:plugin, numParams)
{
	new Module:tmp[Module];
	for(new i=0;i<GetArraySize(g_hPlugins);++i)
	{
		GetArrayArray(g_hPlugins, i, tmp[0]);
		if(tmp[PluginHndl]==plugin)
		{
			RemoveFromArray(g_hPlugins, i);
			return 1;
		}
	}
	return 0;
}

public Native_SetClientCondition(Handle:plugin, numParams)
{
	g_eConditions[GetNativeCell(1)]=GiftConditions:GetNativeCell(2);
	return 0;
}

public Native_GetClientCondition(Handle:plugin, numParams)
{
	return _:g_eConditions[GetNativeCell(1)];
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar==g_hCvarChance)
		g_fChance = StringToFloat(newValue);
	else if(convar==g_hCvarLifetime)
		g_fLifetime = StringToFloat(newValue);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(g_fChance>0.0)
		if(GetRandomInt(1, RoundToNearest(100/(g_fChance*100)))==1)
			Stock_SpawnGift(client);
	
	return Plugin_Continue;
}

stock Stock_SpawnGift(client)
{
	new ent;

	if((ent = CreateEntityByName("prop_physics_override")) != -1)
	{
		new Float:pos[3], String:targetname[100], String:tmp[256];

		GetClientAbsOrigin(client, pos);
		pos[2]-=50.0;

		Format(targetname, sizeof(targetname), "gift_%i", ent);

		DispatchKeyValue(ent, "model", g_sModel);
		DispatchKeyValue(ent, "physicsmode", "2");
		DispatchKeyValue(ent, "massScale", "1.0");
		DispatchKeyValue(ent, "targetname", targetname);
		DispatchSpawn(ent);
		
		SetEntProp(ent, Prop_Send, "m_usSolidFlags", 8);
		SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
		
		if(FloatCompare(g_fLifetime, 0.0)!=0)
		{
			Format(tmp, sizeof(tmp), "OnUser1 !self:kill::%0.2f:-1", g_fLifetime);
			SetVariantString(tmp);
			AcceptEntityInput(ent, "AddOutput");
			AcceptEntityInput(ent, "FireUser1");
		}
		
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		
		new rot = CreateEntityByName("func_rotating");
		DispatchKeyValueVector(rot, "origin", pos);
		DispatchKeyValue(rot, "targetname", targetname);
		DispatchKeyValue(rot, "maxspeed", "200");
		DispatchKeyValue(rot, "friction", "0");
		DispatchKeyValue(rot, "dmg", "0");
		DispatchKeyValue(rot, "solid", "0");
		DispatchKeyValue(rot, "spawnflags", "64");
		DispatchSpawn(rot);
		
		SetVariantString("!activator");
		AcceptEntityInput(ent, "SetParent", rot, rot);
		AcceptEntityInput(rot, "Start");
		
		SDKHook(ent, SDKHook_StartTouch, OnStartTouch);
	}
}

public OnStartTouch(ent, client)
{
	if(g_eConditions[client]==Condition_InCondition)
		return;

	AcceptEntityInput(ent, "Kill");
	
	if(GetArraySize(g_hPlugins)!=0)
	{
		new id = GetRandomInt(0, GetArraySize(g_hPlugins)-1);
		
		new Module:tmp[Module];
		GetArrayArray(g_hPlugins, id, tmp[0]);
		
		Call_StartFunction(tmp[PluginHndl], tmp[FunctionId]);
		Call_PushCell(client);
		Call_Finish();
	}
}