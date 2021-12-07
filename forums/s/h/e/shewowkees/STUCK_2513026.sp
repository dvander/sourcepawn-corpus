#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <clients>
#include <sdkhooks>



public Plugin myinfo ={
	name = "Engineers Vs Zombies",
	author = "shewowkees",
	description = "zombie like gamemode",
	version = "1.2",
	url = "noSiteYet"
};

public void OnPluginStart (){
	RegConsoleCmd("sm_stuck", stuckCommand);




}
public Action stuckCommand(int client, int args){

	int CollisionGroup = GetEntProp(client, Prop_Data, "m_CollisionGroup");

	SetEntProp(client, Prop_Data, "m_CollisionGroup", 2);
	CreateTimer(3.0, reCollide, client);
	PrintToChat(client, "[WARNING] You now have 3 seconds to move !");
	/*CommandCount[client]--;*/
	return Plugin_Handled;


}




public Action reCollide(Handle timer, any client){
	if(TF2_GetClientTeam(client)==TFTeam_Red){
		SetEntProp(client, Prop_Data, "m_CollisionGroup", 3);

	}else if(TF2_GetClientTeam(client)==TFTeam_Blue){
		SetEntProp(client, Prop_Data, "m_CollisionGroup", 5);
	}

	PrintToChat(client, "[WARNING] You are now solid again.");
}
