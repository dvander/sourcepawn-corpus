#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "RG BuildTrace",
	author = "Theowningone",
	description = "Traces the owners of turrets, walls, cameras, and radars!",
	version = "1.0",
	url = "http://www.theowningone.info/"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_id", IdentifyBuild, "Traces the owners of turrets, walls, cameras, and radars!");
	CreateConVar("rg_buildtrace_ver", "1.0", "RG BuildTrace Version", FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public Action:IdentifyBuild(client, args)
{
	new String:Class[128];
	new ent = GetClientAimTarget(client, false);
	if(ent == -1){
		PrintToChat(client, "You didnt select a buildable!");
	}
	GetEdictClassname(ent, Class, sizeof(Class));
	if(strcmp(Class, "emp_building_mgturret", false) == 0 || strcmp(Class, "emp_building_mlturret", false) == 0){
		new off = FindSendPropOffs("CTurret", "m_iOwner");
		new data = GetEntData(ent, off, 4);
		new String:Owner[128];
		if(data == 0)
		{
			Format(Owner, sizeof(Owner), "Commander");
		}else{
			GetClientName(data, Owner, sizeof(Owner));
		}
		PrintToChat(client, "Turret built by %s", Owner);
	}else if(strcmp(Class, "emp_building_nf_mgturret", false) == 0 || strcmp(Class, "emp_building_imp_mgturret", false) == 0 || strcmp(Class, "emp_building_nf_mlturret", false) == 0 || strcmp(Class, "emp_building_imp_mlturret", false) == 0){
		PrintToChat(client, "Turret built by the map");
	}else if(strcmp(Class, "emp_eng_radar", false) == 0){
		new off = FindSendPropOffs("CEngineerRadar", "m_iOwner");
		new data = GetEntData(ent, off, 4);
		new String:Owner[128];
		GetClientName(data, Owner, sizeof(Owner));
		PrintToChat(client, "Radar built by %s", Owner);
	}else if(strcmp(Class, "emp_eng_camera", false) == 0){
		new off = FindSendPropOffs("CEngineerCamera", "m_iOwner");
		new data = GetEntData(ent, off, 4);
		new String:Owner[128];
		GetClientName(data, Owner, sizeof(Owner));
		PrintToChat(client, "Camera built by %s", Owner);
	}else if(strcmp(Class, "emp_eng_walls", false) == 0){
		new off = FindSendPropOffs("CEngineerWalls", "m_iOwner");
		new data = GetEntData(ent, off, 4);
		new String:Owner[128];
		if(data == 0)
		{
			Format(Owner, sizeof(Owner), "Commander");
		}else{
			GetClientName(data, Owner, sizeof(Owner));
		}
		PrintToChat(client, "Wall built by %s", Owner);
	}else{
		PrintToChat(client, "You didnt select a buildable!");
	}
}
