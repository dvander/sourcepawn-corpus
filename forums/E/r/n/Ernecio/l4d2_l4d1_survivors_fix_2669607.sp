#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required;

ConVar Enable;
ConVar BillBody;

static bool IsThePassing1 = false;
static bool IsThePassing3 = false;

public void OnPluginStart()
{
	Enable 		= CreateConVar("l4d2_l4d1_survivors_fix", 		"1", 	"Enable Plugin: 0 = Disabled, 1 = Enabled");
	BillBody 	= CreateConVar("l4d2_the_passing_bill_block", 	"1", 	"Blocking Bill's dead body from The Passing: 0 = Disabled, 1 = Enabled");
	
	AutoExecConfig(true, "l4d2_l4d1_survivors_fix");
	HookEvent("round_start", RoundStart, EventHookMode_Post);
}

public Action RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(Enable.IntValue == 1)
	{	
		CreateTimer(10.0, EntityFix);
	}
	
	return Plugin_Continue;
}

public Action EntityFix(Handle timer)
{
	if(IsThePassing1)
	{
		FireEntityInput("branch_zoey", "Kill");
		FireEntityInput("trigger_multiple", "Kill");
	}
	else if (IsThePassing3)
	{
		FireEntityInput("francis_outro", "Kill");
		FireEntityInput("zoey_outro", "Kill");
		FireEntityInput("louis_outro", "Kill");
		
		if(BillBody.IntValue == 1)
		{
			BlockBillBody();
		}
	}
	FireEntityInput("info_l4d1_survivor_spawn", "Kill");
	FireEntityInput("l4d1_survivors_relay", "Kill");
	FireEntityInput("l4d1_teleport_relay", "Kill");
	FireEntityInput("l4d1_script_relay", "Kill");
}

public void OnMapStart()
{
	if(Enable.IntValue == 1)
	{
		char CurrentMap[100];
		GetCurrentMap(CurrentMap, sizeof(CurrentMap));
		IsThePassing3 = StrEqual(CurrentMap, "c6m3_port");
		IsThePassing1 = StrEqual(CurrentMap, "c6m1_riverbank");
		
		if(IsThePassing1)
		{
			FireEntityInput("branch_zoey", "Kill");
			FireEntityInput("trigger_multiple", "Kill");
		}
		else if (IsThePassing3)
		{
			FireEntityInput("francis_outro", "Kill");
			FireEntityInput("zoey_outro", "Kill");
			FireEntityInput("louis_outro", "Kill");
			if(BillBody.IntValue == 1)
			{
				BlockBillBody();
			}
		}
		
		FireEntityInput("info_l4d1_survivor_spawn", "Kill");
		FireEntityInput("l4d1_survivors_relay", "Kill");
		FireEntityInput("l4d1_teleport_relay", "Kill");
		FireEntityInput("l4d1_script_relay", "Kill");
	}
}

stock void BlockBillBody()
{
	float C1[3], C1V[3], SC1[3], SC1V[3], SC2[3], SC2V[3], SC3[3], SC3V[3];
	
	C1 = view_as<float>( { -369.0, -991.0, 0.0 } );
	C1V = view_as<float>( { 0.0, 90.0, 0.0 } );
	SC1 = view_as<float>( { -364.0, -1016.0, 15.0 } );
	SC1V = view_as<float>( { 0.0, 180.0, 90.0 } );
	SC2 = view_as<float>( { -385.0, -1016.0, 15.0 } );
	SC2V = view_as<float>( { -0.0, 180.0, 90.0 } );
	SC3 = view_as<float>( { -369.0, -1033.0, 0.0 } );
	SC3V = view_as<float>( { -0.0, 90.0, 0.0 } );
	SupplyCrate(view_as<float>( SC1 ), view_as<float>( SC1V ));
	SupplyCrate(view_as<float>( SC2 ), view_as<float>( SC2V ));
	SupplyCrate(view_as<float>( SC3 ), view_as<float>( SC3V ));
	Crate(view_as<float>( C1 ), view_as<float>( C1V ));
}

stock void Crate(float fOrigin[3], float fAngles[3])
{
	int staticCrate = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(staticCrate, "model", "models/props_crates/static_crate_40.mdl");
	DispatchKeyValue(staticCrate, "Solid", "6");
	DispatchKeyValue(staticCrate, "fadescale", "1");
	DispatchKeyValue(staticCrate, "fademindist", "-1");
	DispatchKeyValue(staticCrate, "glowbackfacemult", "1.0");
	DispatchKeyValue(staticCrate, "glowcolor", "0 0 0");
	DispatchKeyValue(staticCrate, "MaxAnimTime", "10");
	DispatchKeyValue(staticCrate, "MinAnimTime", "5");
	DispatchKeyValue(staticCrate, "renderamt", "255");
	DispatchKeyValue(staticCrate, "rendercolor", "255 255 255");
	DispatchKeyValue(staticCrate, "skin", "0");
	DispatchKeyValue(staticCrate, "Solid", "6");
	DispatchSpawn(staticCrate);
	TeleportEntity(staticCrate, view_as<float>( fOrigin ), view_as<float>( fAngles ), NULL_VECTOR);
}

stock void SupplyCrate(float fOrigin[3], float fAngles[3])
{
	int staticCrate = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(staticCrate, "model", "models/props_crates/supply_crate01.mdl");
	DispatchKeyValue(staticCrate, "Solid", "6");
	DispatchKeyValue(staticCrate, "fadescale", "1");
	DispatchKeyValue(staticCrate, "fademindist", "-1");
	DispatchKeyValue(staticCrate, "glowbackfacemult", "1.0");
	DispatchKeyValue(staticCrate, "glowcolor", "0 0 0");
	DispatchKeyValue(staticCrate, "MaxAnimTime", "10");
	DispatchKeyValue(staticCrate, "MinAnimTime", "5");
	DispatchKeyValue(staticCrate, "renderamt", "255");
	DispatchKeyValue(staticCrate, "rendercolor", "255 255 255");
	DispatchKeyValue(staticCrate, "skin", "0");
	DispatchKeyValue(staticCrate, "Solid", "6");
	DispatchSpawn(staticCrate);
	TeleportEntity(staticCrate, view_as<float>( fOrigin ), view_as<float>( fAngles ), NULL_VECTOR);
}

int FireEntityInput(const char[] strTargetname, const char[] strInput, const char[] strParameter = "", const float flDelay = 0.0)
{
    char strBuffer[255];
    Format(strBuffer, sizeof(strBuffer), "OnUser1 %s:%s:%s:%f:1", strTargetname, strInput, strParameter, flDelay);
    
    int entity = CreateEntityByName("info_target"); // Dummy entity. (Pretty sure every Source game has this.)
    if(IsValidEdict(entity))
    {
        DispatchSpawn(entity);
        ActivateEntity(entity);
    
        SetVariantString(strBuffer);
        AcceptEntityInput(entity, "AddOutput");
        AcceptEntityInput(entity, "FireUser1");
        
        CreateTimer(0.0, DeleteEdict, entity); // Remove on next frame.
        return true;
    }
    return false;
}

public Action DeleteEdict(Handle timer, any entity)
{
    if(IsValidEdict(entity)) RemoveEdict(entity);
    return Plugin_Stop;
}  