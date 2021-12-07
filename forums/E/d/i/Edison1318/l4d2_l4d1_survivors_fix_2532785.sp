#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
ConVar Enable;
ConVar BillBody;

static bool IsThePassing1 = false;
static bool IsThePassing3 = false;

public OnPluginStart()
{
	Enable = CreateConVar("l4d2_l4d1_survivors_fix", "1", "Enable Plugin: 0 = Disabled, 1 = Enabled");
	BillBody = CreateConVar("l4d2_the_passing_bill_block", "1", "Blocking Bill's dead body from The Passing: 0 = Disabled, 1 = Enabled");
	AutoExecConfig(true, "l4d2_l4d1_survivors_fix");
	HookEvent("round_start", RoundStart, EventHookMode_Post);
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(Enable.IntValue == 1)
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
	return Plugin_Continue;
}

public OnMapStart()
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

stock BlockBillBody()
{
	float C1[3], C1V[3], SC1[3], SC1V[3], SC2[3], SC2V[3], SC3[3], SC3V[3];
	C1 = Float: { -369.0, -991.0, 0.0 };
	C1V = Float: { 0.0, 90.0, 0.0 };
	SC1 = Float: { -364.0, -1016.0, 15.0 };
	SC1V = Float: { 0.0, 180.0, 90.0 };
	SC2 = Float: { -385.0, -1016.0, 15.0 };
	SC2V = Float: { -0.0, 180.0, 90.0 };
	SC3 = Float: { -369.0, -1033.0, 0.0 };
	SC3V = Float: { -0.0, 90.0, 0.0 };
	SupplyCrate(float:SC1, float:SC1V);
	SupplyCrate(float:SC2, float:SC2V);
	SupplyCrate(float:SC3, float:SC3V);
	Crate(float:C1, float:C1V);
}

stock Crate(float:fOrigin[3], float:fAngles[3])
{
	new staticCrate = CreateEntityByName("prop_dynamic");
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
	TeleportEntity(staticCrate, Float:fOrigin, Float:fAngles, NULL_VECTOR);
}

stock SupplyCrate(float:fOrigin[3], float:fAngles[3])
{
	new staticCrate = CreateEntityByName("prop_dynamic_override");
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
	TeleportEntity(staticCrate, Float:fOrigin, Float:fAngles, NULL_VECTOR);
}

FireEntityInput(const String:strTargetname[], const String:strInput[], const String:strParameter[]="", const Float:flDelay=0.0)
{
    decl String:strBuffer[255];
    Format(strBuffer, sizeof(strBuffer), "OnUser1 %s:%s:%s:%f:1", strTargetname, strInput, strParameter, flDelay);
    
    new entity = CreateEntityByName("info_target"); // Dummy entity. (Pretty sure every Source game has this.)
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

public Action:DeleteEdict(Handle:timer, any:entity)
{
    if(IsValidEdict(entity)) RemoveEdict(entity);
    return Plugin_Stop;
}  