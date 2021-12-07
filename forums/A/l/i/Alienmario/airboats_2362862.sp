#include <sourcemod>
#include <sdktools>


public Plugin:myinfo =
{
	name = "Airboat spawner",
	author = "Alienmario",
	description = "Simple airboat spawner",
	version = "1.0"
};


#define MAX_VEHICLES 10

new number;
new Handle:sm_vehicle_adminonly;
public OnPluginStart(){
	RegConsoleCmd("sm_airboat", airboat, "spawn an airboat");
	//RegConsoleCmd("sm_jeep", jeep, "spawn a jeep");
	sm_vehicle_adminonly = CreateConVar("sm_vehicle_adminonly", "1", "Only admins can spawn vehicles", _, true, 0.0, true, 1.0);
}

public Action:airboat(client, args){
	if(!adminCheck(client)) return Plugin_Handled;
	if(client>0 && number<MAX_VEHICLES){
		new ent=CreateEntityByName("prop_vehicle_airboat");
		if(IsValidEdict(ent))
		{
			new Float:pos[3], Float:ang[3], Float:fwd[3];
			GetClientAbsOrigin(client, pos);
			GetClientAbsAngles(client, ang);
			GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(fwd, 300.0);
			ang[1]-=90;

			DispatchKeyValue(ent, "model", "models/airboat.mdl");
			DispatchKeyValue(ent, "vehiclescript", "scripts/vehicles/airboat.txt");
			DispatchKeyValue(ent, "EnableGun", "0");
			DispatchSpawn(ent);
			TeleportEntity(ent, pos, ang, fwd);
			ActivateEntity(ent);
			PrintToChat(client, "[SM] Spawned an airboat");
			number++;
		}
	}else{
		PrintToChat(client, "[SM] Failed, maybe there are too many vehicles already.");
	}
	return Plugin_Handled;
}

/* 
public Action:jeep(client, args){
	if(!adminCheck(client)) return Plugin_Handled;
	if(client>0 && number<MAX_VEHICLES){
		new ent=CreateEntityByName("prop_vehicle_driveable");
		if(IsValidEdict(ent))
		{
			new Float:pos[3], Float:ang[3], Float:fwd[3];
			GetClientAbsOrigin(client, pos);
			GetClientAbsAngles(client, ang);
			GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(fwd, 300.0);
			ang[1]-=90;

			DispatchKeyValue(ent, "model", "models/buggy.mdl");// blodia/buggy
			DispatchKeyValue(ent, "vehiclescript", "scripts/vehicles/jeep_test.txt"); //"scripts/vehicles/buggy_edit.txt"
			DispatchKeyValue(ent, "actionScale", "1");
			DispatchKeyValue(ent, "EnableGun", "1");
			DispatchSpawn(ent);
			TeleportEntity(ent, pos, ang, fwd);
			ActivateEntity(ent);
			PrintToChat(client, "[SM] Spawned a buggy");
			number++;
		}
	}else{
		PrintToChat(client, "[SM] Failed, maybe there are too many vehicles already.");
	}
	return Plugin_Handled;
} 
*/

bool:adminCheck(client){
	if(GetConVarBool(sm_vehicle_adminonly)){
		new AdminId:admin = GetUserAdmin(client);
		if(!GetAdminFlag(admin, AdminFlag:Admin_Kick)){
			PrintToChat(client, "[SM] Sorry, only admins can spawn vehicles");
			return false;
		}
	}
	return true;
}

public OnMapStart(){
	number=0;
}