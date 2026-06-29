#include <sourcemod>
//#include <sdktools> //0o sdktools, why?
#undef REQUIRE_PLUGIN
#include <autoupdate>
#define REQUIRE_PLUGIN //1SWAT2KILLTHEMALL, just in case ;P

#define PL_VERSION "1.0.4" 
//#define MAX_PLAYERS 256 //WUT???- 1swatty, something wrong with predefined MAXPLAYERS ??

new Handle:cAswSkill,
	Handle:WelcomeTimers[MAXPLAYERS+1], //swat
	AswSkill;
//1SWAT2KILLTHEMALL (ok, i edited 2 lines above this one as well ;P)
//todo: add the new difficulty settins? brutal, or w/e + hc ff?
enum E_Difficulties {
	E_D_Easy = 0,
	E_D_Normal,
	E_D_Hard,
	E_D_Insane,
	E_D_Max
}
new const String:Difficulties[][] = {
	"Easy",
	"Normal",
	"Hard",
	"Insane"
}
//---eo(swatty)
//Info for the plugin
public Plugin:myinfo = 
{
	name = "Skill Change Alerter",
	author = "DaveC524",
	description = "Prints out new skill level when changed",
	version = PL_VERSION,
	url = "http://davec524.mooo.com"
}

//Initialization of handle and hooking
public OnPluginStart()
{
	cAswSkill = Handle:FindConVar("asw_skill");
	HookConVarChange(Handle:cAswSkill, ConVarChanged:SkillChanged);
	AswSkill = GetConVarInt(cAswSkill); //1SWAT2KILLTHEMALL
}

//Needed to allow autoupdating
public OnAllPluginsLoaded() 
{
    if(LibraryExists("pluginautoupdate")) 
	{
        // only register myself if the autoupdater is loaded
        // AutoUpdate_AddPlugin(const String:url[], const String:file[], const String:version[])
        AutoUpdate_AddPlugin("davec524.mooo.com", "/misc/SOURCEMODplugins/getdifficulty/plugins.xml", PL_VERSION);
    }
}

//Needed to allow autoupdating
public OnPluginEnd() 
{
    if(LibraryExists("pluginautoupdate")) 
	{
        // I don't need updating anymore
        // AutoUpdate_RemovePlugin(Handle:plugin=INVALID_HANDLE) - don't specifiy plugin to remove calling plugin
        AutoUpdate_RemovePlugin();
    }
}

//Upon client put in the server, a timer is made that later uses WelcomePlayer()
public OnClientPutInServer(client)
{
	WelcomeTimers[client] = CreateTimer(15.0, WelcomePlayer, client);
}

//Closes timer if one exists upon client disconnect
public OnClientDisconnect(client)
{
	if (WelcomeTimers[client] != INVALID_HANDLE)
	{
		KillTimer(WelcomeTimers[client]);
		WelcomeTimers[client] = INVALID_HANDLE;
	}
}

//Prints the difficulty to a player, and closes the timer
public Action:WelcomePlayer(Handle:timer, any:client)
{
	PrintDifficulty(client);
	WelcomeTimers[client] = INVALID_HANDLE;
}

//Using the data grabbed from GetSkill(), a player is reminded to the current skill level
PrintDifficulty(client = 0) //edited
{
	/*new skill = GetSkill();
	switch (skill)
	{
		case 1:
			PrintToChat(client, "The server is set to Easy.");
		case 2:
			PrintToChat(client, "The server is set to Normal.");
		case 3:
			PrintToChat(client, "This server is set to Hard.");
		case 4:
			PrintToChat(client, "This server is set to Insane.");
		default:
			PrintToServer("Something broke.");
	}*/
	//1SWAT2KILLTHEMALL
	decl String:message[256];
	if (AswSkill < 1 || AswSkill >= _:E_D_Max) Format(message, sizeof(message), "[SkillChangeAlerter] Something went wrong!");
	else if (!client) Format(message, sizeof(message), "[SkillChangeAlerter] The server is now on %s.", Difficulties[AswSkill]);
	else if (client) Format(message, sizeof(message), "[SkillChangeAlerter] This server is set to %s.", Difficulties[AswSkill]);
	if (!client) PrintToChatAll(message);
	else if (IsClientConnected(client) && IsClientInGame(client)) PrintToChat(client, message);
}

//This function closes all timers to prevent chat redundancy as well as calling PrintDiffAll()
public SkillChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) //swat
{
	//Kill all timers to prevent redundancy
	for(new i = 0; i <= MAXPLAYERS ; i++)//swat
	{
		if(WelcomeTimers[i] != INVALID_HANDLE)
		{
			KillTimer(WelcomeTimers[i]);
			WelcomeTimers[i] = INVALID_HANDLE;
		}
	}
	AswSkill = StringToInt(newVal);//swat
	//Print difficulty change to all
	PrintDifficulty(); //swat
}

//Using the data grabbed from GetSkill(), every player is alerted to the new skill level
//public PrintDiffAll()
//{
//	new skill = GetSkill();
//	switch (skill)
//	{
//		case 1:
//			PrintToChatAll("The server is now on Easy.");
//		case 2:
//			PrintToChatAll("The server is now on Normal.");
//		case 3:
//			PrintToChatAll("This server is now on Hard.");
//		case 4:
//			PrintToChatAll("This server is now on Insane.");
//		default:
//			PrintToServer("Something broke.");
//	}
//}
//not needed
//Returns the current skill level as an integer; 1=Easy, 2=Normal, 3=Hard, 4=Insane
//public GetSkill()
//{
//	new skill = GetConVarInt(Handle:cAswSkill);
//	return skill;
//}
//not needed - swatty