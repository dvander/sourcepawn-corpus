#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "Airboat spawner",
	author = "Alienmario",
	description = "Simple airboat spawner",
	version = "1.01"
};

#define MAX_VEHICLES 10

int number;
public OnPluginStart(){
	RegAdminCmd("sm_airboat", airboat, ADMFLAG_CHEATS, "spawn an airboat");
}

public Action airboat(int client, int args){
	if(client>0 && number<MAX_VEHICLES){
		int ent=CreateEntityByName("prop_vehicle_airboat");
		if(IsValidEdict(ent))
		{
			float pos[3], ang[3], fwd[3];
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

public OnMapStart(){
	number=0;
}