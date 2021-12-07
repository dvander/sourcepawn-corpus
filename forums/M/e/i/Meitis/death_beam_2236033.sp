/*
deathbeam.sp

Name:
	Death Beam's

Description:
	Creates A Beam Between Victim And Killer
	
Versions:
	0.1
		* Initial Release
		
	1.0
		* Fixed beam holes
		* Fixed beam color
		* Added persistent settings
		
	1.0.1
		* Fixed the declaration of userPreference
		* Changed naming conventions to match sourcemod standards
		
	1.1
		* Added a default value cvar
*/

#include <sourcemod>
#include <sdktools>

#define VERSION "1.1" 
#define MAX_FILE_LEN 80

new Handle:g_CvarEnable = INVALID_HANDLE;
new g_sprite;
new Handle:g_CvarRed = INVALID_HANDLE;
new Handle:g_CvarBlue = INVALID_HANDLE;
new Handle:g_CvarGreen = INVALID_HANDLE;
new Handle:g_CvarTrans = INVALID_HANDLE;
new Handle:g_CvarDefaultSetting = INVALID_HANDLE;
new g_userPreference[MAXPLAYERS + 1];
new Handle:hKVSettings = INVALID_HANDLE;
new String:g_filenameSettings[MAX_FILE_LEN];
new bool:g_lateLoaded;

public OnMapStart()
{
	g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public Plugin:myinfo =
{
	name = "Death Beam",
	author = "Peoples Army, AMP",
	description = "Creates A Beam Between Victim And Killer",
	version = VERSION,
	url = "www.sourcemod.net"
};

// We need to capture if the plugin was late loaded so we can make sure initializations
// are handled properly
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_lateLoaded = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	g_CvarEnable = CreateConVar("death_beam_on", "1", "1 turns the plugin on 0 is off", FCVAR_NOTIFY);
	g_CvarRed = CreateConVar("death_beam_red", "200", "Amount OF Red In The Beam", FCVAR_NOTIFY);
	g_CvarGreen = CreateConVar("death_beam_green", "25", "Amount Of Green In The Beam", FCVAR_NOTIFY);
	g_CvarBlue = CreateConVar("death_beam_blue", "25", "Amount OF Blue In The Beam", FCVAR_NOTIFY);
	g_CvarTrans = CreateConVar("death_beam_alpha", "200", "Amount OF Transperency In Beam", FCVAR_NOTIFY);
	g_CvarDefaultSetting = CreateConVar("death_beam_default_setting", "1", "The default setting for new players");
	
	HookEvent("player_death",EventDeath);
	HookEvent("round_start", EventRoundStart);
	
	RegConsoleCmd("deathbeam", DeathBeamMenu);
	
	hKVSettings=CreateKeyValues("UserSettings");
  	BuildPath(Path_SM, g_filenameSettings, MAX_FILE_LEN, "data/beamusersettings.txt");
	if(!FileToKeyValues(hKVSettings, g_filenameSettings))
	{
    	KeyValuesToFile(hKVSettings, g_filenameSettings);
    }
    	
	if(g_lateLoaded)
	{
		// Next we need to whatever we would have done as each client authorized
		for(new i = 1; i < GetMaxClients(); i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				PrepareClient(i);
			}
		}
	}
}

public EventDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(GetConVarBool(g_CvarEnable))
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new Float:victimOrigin[3];
		new Float:attackerOrigin[3];
		new color[4];
		
		// We only want to show a death beam in the case of kills where there was a real attacker and a real victim and it was not a self kill
		if(victim && attacker && attacker != victim && IsClientInGame(victim) && !IsFakeClient(victim) && g_userPreference[victim])
		{
			GetClientEyePosition(attacker, attackerOrigin);
			GetClientEyePosition(victim, victimOrigin);
			color[0] = GetConVarInt(g_CvarRed); 
			color[1] = GetConVarInt(g_CvarGreen);
			color[2] = GetConVarInt(g_CvarBlue);
			color[3] = GetConVarInt(g_CvarTrans);
			
			TE_SetupBeamPoints(victimOrigin, attackerOrigin, g_sprite, 0, 0, 0, 20.0, 3.0, 3.0, 10, 0.0, color, 0);
			TE_SendToClient(victim);
		}
	}
}

// When a new client is authorized we reset sound preferences
public OnClientPutInServer(client)
{
	PrepareClient(client);
}

//  This sets enables or disables the sounds
public DeathBeamMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if(param2 == 2)
		{
			g_userPreference[param1] = 0;
		}
		else
		{
			g_userPreference[param1] = param2;
		}
		new String:steamId[20];
		GetClientAuthString(param1, steamId, 20);
		KvRewind(hKVSettings);
		KvJumpToKey(hKVSettings, steamId);
		KvSetNum(hKVSettings, "beam enable", g_userPreference[param1]);
		KvSetNum(hKVSettings, "timestamp", GetTime());
	}
}
 
//  This creates the lastman panel
public Action:DeathBeamMenu(client, args)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Death Beam Menu");
	if(g_userPreference[client])
	{
		DrawPanelItem(panel, "Enable(Current Setting)");
		DrawPanelItem(panel, "Disable");
	} else {
		DrawPanelItem(panel, "Enable");
		DrawPanelItem(panel, "Disable(Current Setting)");
	}
	SendPanelToClient(panel, client, DeathBeamMenuHandler, 20);
 
	CloseHandle(panel);
 
	return Plugin_Handled;
}

// Initializations to be done at the beginning of the round
public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Save user settings to a file
	KvRewind(hKVSettings);
	KeyValuesToFile(hKVSettings, g_filenameSettings);
}

// When a user disconnects we need to update their timestamp in kvC4
public OnClientDisconnect(client)
{
	new String:steamId[20];
	if(client && !IsFakeClient(client))
	{
		GetClientAuthString(client, steamId, 20);
		KvRewind(hKVSettings);
		if(KvJumpToKey(hKVSettings, steamId))
		{
			KvSetNum(hKVSettings, "timestamp", GetTime());
		}
	}
}

public PrepareClient(client)
{
	new String:steamId[20];
	if(client)
	{
		if(!IsFakeClient(client))
		{
			// Get the users saved setting or create them if they don't exist
			GetClientAuthString(client, steamId, 20);
			KvRewind(hKVSettings);
			if(KvJumpToKey(hKVSettings, steamId))
			{
				g_userPreference[client] = KvGetNum(hKVSettings, "beam enable", 1);
			} else {
				KvRewind(hKVSettings);
				KvJumpToKey(hKVSettings, steamId, true);
				KvSetNum(hKVSettings, "beam enable", GetConVarInt(g_CvarDefaultSetting));
				g_userPreference[client] = GetConVarInt(g_CvarDefaultSetting);
			}
			KvRewind(hKVSettings);
		}
	}
}