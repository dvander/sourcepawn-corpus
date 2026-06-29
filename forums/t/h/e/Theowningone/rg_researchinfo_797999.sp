#include <sourcemod>
#include <sdktools>
#include "empires"

#define PLUGIN_VERSION "1.0"

new Handle:g_ResearchList = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name="RG Research Info",
	author="Theowningone",
	description="RG Research Info",
	version=PLUGIN_VERSION,
	url="http://www.theowningone.info/"
}

public OnPluginStart(){
	CreateConVar("rg_researchinfo_ver",PLUGIN_VERSION,"RG Research Info Version",FCVAR_NOTIFY);
	RegConsoleCmd("sm_researchinfo",Info,"Get Info on your teams research");
	g_ResearchList=CreateTrie();
	SetTrieString(g_ResearchList,"0","None",true);
	SetTrieString(g_ResearchList,"1","Physics",true);
	SetTrieString(g_ResearchList,"2","Superheated Material Physics",true);
	SetTrieString(g_ResearchList,"3","Plasma Cannon Projectile",true);
	SetTrieString(g_ResearchList,"4","Plasma Bullet Projectile",true);
	SetTrieString(g_ResearchList,"5","Projectile Physics",true);
	SetTrieString(g_ResearchList,"6","Reflective Armor",true);
	SetTrieString(g_ResearchList,"7","Extended Range Cannon",true);
	SetTrieString(g_ResearchList,"8","Heavy Caliber Machine Gun",true);
	SetTrieString(g_ResearchList,"9","Nuclear Fission",true);
	SetTrieString(g_ResearchList,"10","Fission Reactor",true);
	SetTrieString(g_ResearchList,"11","HIT Warhead",true);
	SetTrieString(g_ResearchList,"12","Chemistry",true);
	SetTrieString(g_ResearchList,"13","Improved Flagration Compounds",true);
	SetTrieString(g_ResearchList,"14","Explosive Tipped Bullets",true);
	SetTrieString(g_ResearchList,"15","Improved Detonation Compounds",true);
	SetTrieString(g_ResearchList,"16","Upgraded Grenades",true);
	SetTrieString(g_ResearchList,"17","Explosive Shells",true);
	SetTrieString(g_ResearchList,"18","Improved Warhead Compounds",true);
	SetTrieString(g_ResearchList,"19","Upgraded Missile Warhead",true);
	SetTrieString(g_ResearchList,"20","Upgraded Grenadier RPG",true);
	SetTrieString(g_ResearchList,"21","Advanced Grenadier RPG",true);
	SetTrieString(g_ResearchList,"22","Improved Heat Transfer Fluids",true);
	SetTrieString(g_ResearchList,"23","Advanced Coolant Engine",true);
	SetTrieString(g_ResearchList,"24","Absorbant Armor",true);
	SetTrieString(g_ResearchList,"25","Mechanical Engineering",true);
	SetTrieString(g_ResearchList,"26","Advanced Personnel Deployment",true);
	SetTrieString(g_ResearchList,"27","Upgraded Chassis",true);
	SetTrieString(g_ResearchList,"28","Medium Tank Chassis",true);
	SetTrieString(g_ResearchList,"29","Artillery Tank Chassis",true);
	SetTrieString(g_ResearchList,"30","Advanced Chassis",true);
	SetTrieString(g_ResearchList,"31","Heavy Tank Chassis",true);
	SetTrieString(g_ResearchList,"32","Advanced Machining",true);
	SetTrieString(g_ResearchList,"33","Composite Armor",true);
	SetTrieString(g_ResearchList,"34","Gas Turbine Engine",true);
	SetTrieString(g_ResearchList,"35","Electrical Engineering",true);
	SetTrieString(g_ResearchList,"36","Advanced Magnet Research",true);
	SetTrieString(g_ResearchList,"37","Rail Gun",true);
	SetTrieString(g_ResearchList,"38","3 Phase Electric Motor",true);
	SetTrieString(g_ResearchList,"39","Reactive Armor",true);
	SetTrieString(g_ResearchList,"40","Tracking Systems",true);
	SetTrieString(g_ResearchList,"41","Homing Missiles",true);
	SetTrieString(g_ResearchList,"42","Guided Missiles",true);
	SetTrieString(g_ResearchList,"43","Upgraded Turrets Lvl 2",true);
	SetTrieString(g_ResearchList,"44","Upgraded Turrets Lvl 3",true);
	SetTrieString(g_ResearchList,"45","Biology",true);
	SetTrieString(g_ResearchList,"46","Regenerative Armor",true);
	SetTrieString(g_ResearchList,"47","Bio Diesel Engine",true);
	SetTrieString(g_ResearchList,"48","Biological Weaponry" ,true);
	SetTrieString(g_ResearchList,"49","Biological Warhead",true);
	SetTrieString(g_ResearchList,"50","Biological Projectile",true);
}

public Action:Info(client,args){
	if(client<=0)return Plugin_Handled;
	new Team=GetClientTeam(client);
	if(Team==2){
		new research=CurrentResearch(2);
		new Time=GetResearchTime(2);
		new String:ResearchN[128],String:Research[128];
		Format(Research,128,"%i",research);
		GetTrieString(g_ResearchList,Research,ResearchN,128);
		if(research>0){
			PrintToChat(client,"Current Research: %s, Time left: %i Seconds",ResearchN,Time);
			PrintToConsole(client,"Current Research: %s, Time left: %i Seconds",ResearchN,Time);
		}else{
			PrintToChat(client,"Current Research: %s",ResearchN);
			PrintToConsole(client,"Current Research: %s",ResearchN);
		}
	}
	if(Team==3){
		new research=CurrentResearch(3);
		new Time=GetResearchTime(3);
		new String:ResearchN[128],String:Research[128];
		Format(Research,128,"%i",research);
		GetTrieString(g_ResearchList,Research,ResearchN,128);
		if(research>0){
			PrintToChat(client,"Current Research: %s, Time left: %i Seconds",ResearchN,Time);
			PrintToConsole(client,"Current Research: %s, Time left: %i Seconds",ResearchN,Time);
		}else{
			PrintToChat(client,"Current Research: %s",ResearchN);
			PrintToConsole(client,"Current Research: %s",ResearchN);
		}
	}
	return Plugin_Handled;
}