#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "0.9.5"

public Plugin:myinfo = 
{
	name = "botcreator",
	author = "sonnzy",
	description = "create bot",
	version = PLUGIN_VERSION,
	url = ""
};

new Handle:double_item_on;
new botCount = 0;

public OnPluginStart()
{
	RegConsoleCmd("sm_joingame",AddPlayer, "Attempt to join Survivors");
	RegConsoleCmd("sm_addbot",AddBot, "Create one bot to take over");

	CreateConVar("botcreator_version", PLUGIN_VERSION,"version",FCVAR_PLUGIN|FCVAR_NOTIFY);
	double_item_on = CreateConVar("double_item_on", "1","double item supply is on|off",FCVAR_PLUGIN|FCVAR_NOTIFY);

	HookEvent("round_start", Event_RoundStart);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	//ServerCommand("exec server");
	if(GetConVarInt(double_item_on) == 1)
	{
		CreateTimer( 3.0, UpdateCounts, 0, TIMER_FLAG_NO_MAPCHANGE );
	}
	CreateTimer( 25.0, FillBots, 0, TIMER_FLAG_NO_MAPCHANGE );
}

public Action:AddBot( client, args )
{
	CreateTimer( 1.0, CreateBot, 0, TIMER_FLAG_NO_MAPCHANGE );
	return Plugin_Handled;
}

public Action:AddPlayer(client, args)
{
	//LogAction(0, -1, "DEBUG:addplayer");
	if(IsClientInGame(client))
	{
		FakeClientCommand(client, "jointeam 2");
	}
	return Plugin_Handled;
}

public Action:FillBots(Handle:timer)
{
	new max = GetConVarInt( FindConVar( "sv_maxplayers" ) );
	new svcnt = CountSurvivors();
	botCount = ( max - svcnt );

	if ( botCount > 0 )
	{
		for ( new j=0; j < botCount; j++ )
		{
			CreateTimer( 0.5, CreateBot, 0, TIMER_FLAG_NO_MAPCHANGE );
		}
	}

	return Plugin_Handled;
}

public Action:UpdateCounts(Handle:timer)
{
	//PrintToChatAll("\x01Supply item is loaded");

	// update fixed item spawn counts to handle 8 players
	// These only update item spawns found in starting area/saferooms
	UpdateEntCount("weapon_autoshotgun_spawn","17");
	UpdateEntCount("weapon_hunting_rifle_spawn","17");
	UpdateEntCount("weapon_pistol_spawn","17");
	UpdateEntCount("weapon_pistol_magnum_spawn","17");
	UpdateEntCount("weapon_pumpshotgun_spawn","17");
	UpdateEntCount("weapon_rifle_spawn","17");
	UpdateEntCount("weapon_rifle_ak47_spawn","17");
	UpdateEntCount("weapon_rifle_desert_spawn","17");
	UpdateEntCount("weapon_rifle_sg552_spawn","17");
	UpdateEntCount("weapon_shotgun_chrome_spawn","17");
	UpdateEntCount("weapon_shotgun_spas_spawn","17");
	UpdateEntCount("weapon_smg_spawn","17");
	UpdateEntCount("weapon_smg_mp5_spawn","17");
	UpdateEntCount("weapon_smg_silenced_spawn","17");
	UpdateEntCount("weapon_sniper_awp_spawn","17");
	UpdateEntCount("weapon_sniper_military_spawn","17");
	UpdateEntCount("weapon_sniper_scout_spawn","17");
	UpdateEntCount("weapon_grenade_launcher_spawn", "17");
	UpdateEntCount("weapon_spawn", "17");    //random new l4d2 weapon

	UpdateEntCount("weapon_chainsaw_spawn", "4");
	//UpdateEntCount("weapon_defibrillator_spawn", "4");
	UpdateEntCount("weapon_first_aid_kit_spawn", "4");
	UpdateEntCount("weapon_melee_spawn", "4");

	// pistol spawns come in two flavors stacks of 5, or multiple singles props
	UpdateEntCount("weapon_pistol_spawn", "16"); // defaults 1/4/5
	
	// StripAndChangeServerConVarInt("director_pain_pill_density", 12);  // default 6
	return Plugin_Handled;
}

public UpdateEntCount(const String:entname[], const String:count[])
{
	// LogAction(0, -1, "DEBUG:updateentcount");
	new edict_index = FindEntityByClassname(-1, entname);
	while(edict_index != -1)
	{
		DispatchKeyValue(edict_index, "count", count);
		edict_index = FindEntityByClassname(edict_index, entname);
	}
}

public Action:CreateBot( Handle:timer )
{
	// create fake client
	new cl = CreateFakeClient( "FakeClient" );

	// move into survivor team
	ChangeClientTeam( cl, 2 );

	// set entity classname to SurvivorBot
	if ( DispatchKeyValue( cl, "classname", "SurvivorBot" ) == true )
	{
		// spawn the client
		if ( DispatchSpawn( cl ) == true )
		{
			KickClient( cl, "client_is_fakeclient" );
		}
	}
	return Plugin_Handled;
}

CountSurvivors()
{
	new numSurvivors = 0;
	for ( new i=1; i <= MaxClients; i++ )
	{
		if ( IsClientInGame(i) && GetClientTeam(i) == 2 ) 
			numSurvivors++;
	}

	return numSurvivors;
}
