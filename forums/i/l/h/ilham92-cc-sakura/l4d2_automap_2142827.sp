#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.01"
#define PLUGIN_NAME		"[L4D2] Lightweight Next Campaign"
#define PLUGIN_AUTHOR	"Anime4000"
#define PLUGIN_DESC		"A alternative of ACS, the LNC (Lightweight Next Campaign). Let game keep continue all campaign based on story"

new roundNum = 0;
new Handle:ThisIsEnable		= INVALID_HANDLE;
new Handle:TimeToSwitch		= INVALID_HANDLE;

new const String:theMaps[][] = {
	//L4D1 Story
	"c8m1_apartment",		//0
	"c9m1_alleys",			//1
	"c10m1_caves",			//2
	"c11m1_greenhouse",		//3
	"c12m1_hilltop",		//4
	"c7m1_docks",			//5
	
	//L4D2 Story
	"c1m1_hotel",			//6
	"c6m1_riverbank",		//7
	"c2m1_highway",			//8
	"c3m1_plankcountry",	//9
	"c4m1_milltown_a",		//10
	"c5m1_waterfront",		//11
	"c13m1_alpinecreek"		//12
};

new const String:theCamp[][] = {
	//L4D1 Story
	"No Mercy",				//0
	"Crash Course",			//1
	"Death Toll",			//2
	"Dead Air",				//3
	"Blood Harvest",		//4
	"The Sacrifice",		//5

	//L4D2 Story
	"Dead Center",			//6
	"The Passing",			//7
	"Dark Carnival",		//8
	"Swamp Fever",			//9
	"Hard Rain",			//10
	"The Parish",			//11
	"Cold Stream"			//12
};

public Plugin:myinfo =
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = PLUGIN_DESC,
    version = PLUGIN_VERSION,
    url = "http://animeclan.org/"
}

public OnPluginStart()
{
	HookEvent("round_end", Event_RoundWin);

	CreateConVar("lnc_version", PLUGIN_VERSION, "Tell LNC version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	CreateConVar("lnc_author", PLUGIN_AUTHOR, "Who did this", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	CreateConVar("lnc_about", PLUGIN_DESC, "About LNC", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ThisIsEnable = CreateConVar("cr_enable","1","Enable or Disable of Lightweight Next Campaign plugins");
	TimeToSwitch = CreateConVar("cr_timer_switch", "10.0", "How many second before switch to next campaign", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY, true, 5.0, true, 20.0);
}

public OnMapStart()
{
	roundNum = 0;
}

//This event fired twice, execute when showing versus score then execute again during switch team,
public Action:Event_RoundWin(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(!GetConVarBool(ThisIsEnable))
		return;

	new String:strCurrentMap[32];
	GetCurrentMap(strCurrentMap, 32);

	if(IsValidLastMap(strCurrentMap) && roundNum >= 2)
	{
		new mapIndex = GetNextCamp(strCurrentMap);

		PrintToChatAll("\x04[Hentai Rape] \x01Going to next campaign \x05%s. \x03Get ready!", theCamp[mapIndex]);
		CreateTimer(GetConVarFloat(TimeToSwitch), ChangeNextCamp, mapIndex);
	}

	roundNum++;
}

public Action:ChangeNextCamp(Handle:pTimer, any:nValue)
{
	ServerCommand("changelevel %s", theMaps[nValue]);
	return Plugin_Stop;
}

GetNextCamp(String:mapName[])
{
	if(StrEqual(mapName, "c8m5_rooftop", false))
		return 1;

	if(StrEqual(mapName, "c9m2_lots", false))
		return 2;

	if(StrEqual(mapName, "c10m5_houseboat", false))
		return 3;

	if(StrEqual(mapName, "c11m5_runway", false))
		return 4;

	if(StrEqual(mapName, "c12m5_cornfield", false))
		return 5;

	if(StrEqual(mapName, "c7m3_port", false))
		return 6;

	if(StrEqual(mapName, "c1m4_atrium", false))
		return 7;

	if(StrEqual(mapName, "c6m3_port", false))
		return 8;

	if(StrEqual(mapName, "c2m5_concert", false))
		return 9;

	if(StrEqual(mapName, "c3m4_plantation", false))
		return 10;

	if(StrEqual(mapName, "c4m5_milltown_escape", false))
		return 11;

	if(StrEqual(mapName, "c5m5_bridge", false))
		return 12;

	if(StrEqual(mapName, "c13m4_cutthroatcreek", false))
		return 0;

	return 0;
}

bool:IsValidLastMap(String:mapName[])
{
	if(StrEqual(mapName, "c8m5_rooftop", false))
		return true;

	if(StrEqual(mapName, "c9m2_lots", false))
		return true;

	if(StrEqual(mapName, "c10m5_houseboat", false))
		return true;

	if(StrEqual(mapName, "c11m5_runway", false))
		return true;

	if(StrEqual(mapName, "c12m5_cornfield", false))
		return true;

	if(StrEqual(mapName, "c7m3_port", false))
		return true;

	if(StrEqual(mapName, "c1m4_atrium", false))
		return true;

	if(StrEqual(mapName, "c6m3_port", false))
		return true;

	if(StrEqual(mapName, "c2m5_concert", false))
		return true;

	if(StrEqual(mapName, "c3m4_plantation", false))
		return true;

	if(StrEqual(mapName, "c4m5_milltown_escape", false))
		return true;

	if(StrEqual(mapName, "c5m5_bridge", false))
		return true;

	if(StrEqual(mapName, "c13m4_cutthroatcreek", false))
		return true;

	return false;
}