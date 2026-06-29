#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

#define MODEL_ZOEY "models/survivors/survivor_teenangst.mdl"
#define MODEL_BILL "models/survivors/survivor_namvet.mdl"
#define MODEL_FRANCIS "models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS "models/survivors/survivor_manager.mdl"

public Plugin:myinfo = 
{
	name = "sb_takecontrol",
	author = "pan xiaohai - fork by Sunyata",
	description = "<- Description ->",
	version = "1.0",
	url = "<- URL ->"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_anb",AddNamedSurvivorBots, "Adds Named Bot - uses !anb command ");
}

public Action:AddNamedSurvivorBots(client, args)
{
	for(new i = 0; i < 2; i++) // spawn 2 extra zoey bots - but if 4 extra zoeys wanted then change < 2 to < 4
	{
		new bot = CreateFakeClient("Duplicate survivor bot");
		if(bot != 0)
		{
			SetEntityModel(bot, MODEL_ZOEY); //currently using zoey bots
			SetClientName(bot, "Zoey"); //currently using zoey bots
			
			//SetEntityModel(bot, MODEL_LOUIS); //if louis bot wanted instead on zoey then uncomment this line and comment out zoey above
			//SetClientName(bot, "Louis"); //if louis bot wanted instead on zeoy uncomment this line and comment out zoey above
			
			//SetEntityModel(bot, MODEL_FRANCIS); //ditto as above
			//SetClientName(bot, "Francis"); // ditto as above
			
			//SetEntityModel(bot, MODEL_BILL); //ditto as above
			//SetClientName(bot, "Bill"); //ditto as above
			
			ChangeClientTeam(bot, 2);
			if(DispatchKeyValue(bot, "classname", "SurvivorBot") == false)
			{
				PrintToChatAll("\x01Create bot failed");
				return Plugin_Handled;
			}
			if(DispatchSpawn(bot) == false)
			{
				PrintToChatAll("\x01Create bot failed");
				return Plugin_Handled;
			}
			SetEntityRenderColor(bot, 128, 0, 0, 255);
			CreateTimer(1.0, kick, bot, TIMER_FLAG_NO_MAPCHANGE);
			PrintToChatAll("\x01Extra Bot Created");
		}
	}
	return Plugin_Handled;
}

public Action:kick(Handle:timer, any:bot)
{
	KickClient(bot, "fake player");
	return Plugin_Stop;
}
