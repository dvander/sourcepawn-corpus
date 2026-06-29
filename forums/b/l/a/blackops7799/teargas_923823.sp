#include <sourcemod>
#include <sdktools>

#define VERSION "1.0.0"

new Handle:g_radius;
new Handle:g_damage;
new Handle:g_enabled;

public Plugin:myinfo = {
	name = "Tear Gas",
	author = "BlackOps7799",
	description = "Causes smoke grenades to deal damage if you are within its radius",
	version = VERSION,
	url = ""
};

public OnPluginStart()
{
	CreateConVar("sm_teargas_version", VERSION, "Current version of this plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_radius = CreateConVar("sm_teargas_radius","200");
	g_damage = CreateConVar("sm_teargas_damage","2");
	g_enabled = CreateConVar("sm_teargas_enabled","1");

	HookEvent("smokegrenade_detonate",smoke_detonate);
}

public Action:smoke_detonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(g_enabled) == true)
	{
		new client = GetClientOfUserId(GetEventInt(event,"userid"));
	   
		if( !IsClientConnected(client) && !IsClientInGame(client) )
			return Plugin_Continue;
			
		new index = CreateEntityByName("point_hurt");
		
		if (index == -1)
			return Plugin_Handled;
		
		DispatchKeyValueFloat(index, "DamageRadius", GetConVarFloat(g_radius));
		DispatchKeyValueFloat(index, "Damage", GetConVarFloat(g_damage));
		DispatchKeyValueFloat(index, "DamageType", 32.00);
		DispatchSpawn(index);
		
		decl Float:VectorPos[3];
		VectorPos[0]=GetEventFloat(event,"x");
		VectorPos[1]=GetEventFloat(event,"y");
		VectorPos[2]=GetEventFloat(event,"z");
		TeleportEntity(index, VectorPos, NULL_VECTOR, NULL_VECTOR);
			
		SetVariantString("OnUser1 !self,kill,-1,20");
		AcceptEntityInput(index, "AddOutput");
		AcceptEntityInput(index, "TurnOn");
		AcceptEntityInput(index, "FireUser1");
	}

	return Plugin_Continue;
}