/*
laser_tag.sp

Name:
	Laser Tag

Description:
	Creates A Beam for every shot fired
	
Versions:
	0.1 Initial Release	
	0.2 Streamlined the code
	0.3 Tweaked the position of the beam
	1.0 Added settings to turn on or off depending on certain conditions
	1.1 Bugfix in persistence logic
*/

#include <sourcemod>
#include <sdktools>

#define VERSION "1.0" 
#define MAX_FILE_LEN 80
#define TERRORIST_TEAM 2
#define COUNTER_TERRORIST_TEAM 3

new Handle:g_CvarEnable = INVALID_HANDLE;
new Handle:g_CvarAllowClientEnableDisable = INVALID_HANDLE;
new Handle:g_CvarDefaultClientSetting = INVALID_HANDLE;
new Handle:g_CvarInactiveUsersOnly = INVALID_HANDLE;
new Handle:g_CvarTeamMembersOnly = INVALID_HANDLE;
new Handle:g_CvarAttackerOnlyWhenEnabled = INVALID_HANDLE;

new iLifeState = -1;
new g_sprite;

new Handle:g_CvarCTRed = INVALID_HANDLE;
new Handle:g_CvarCTBlue = INVALID_HANDLE;
new Handle:g_CvarCTGreen = INVALID_HANDLE;
new Handle:g_CvarTRed = INVALID_HANDLE;
new Handle:g_CvarTBlue = INVALID_HANDLE;
new Handle:g_CvarTGreen = INVALID_HANDLE;

new Handle:g_CvarTrans = INVALID_HANDLE;
new Handle:g_CvarLife = INVALID_HANDLE;
new Handle:g_CvarWidth = INVALID_HANDLE;

new Handle:hGameConf = INVALID_HANDLE;
new Handle:hGetWeaponPosition = INVALID_HANDLE;
new String:g_filenameSettings[MAX_FILE_LEN];
new Handle:hKVSettings = INVALID_HANDLE;
new g_userPreference[MAXPLAYERS + 1];

new bool:g_lateLoaded;

public OnMapStart()
{
	g_sprite = PrecacheModel("materials/sprites/laser.vmt");
}

public Plugin:myinfo =
{
	name = "Laser Tag",
	author = "Chocolate and Cheese",
	description = "Creates A Beam For every shot fired, code snippets provided by Peoples Army, AMP and Deception5",
	version = VERSION,
	url = "www.sourcemod.net"
};

public OnPluginStart()
{
	g_CvarEnable = CreateConVar("sm_laser_tag_on", "1", "1 turns the plugin on 0 is off", FCVAR_NOTIFY);
	g_CvarAllowClientEnableDisable = CreateConVar("sm_laser_tag_client_choice", "1", "Do clients have a choice to enable or disable the Laser Beam");
	g_CvarDefaultClientSetting = CreateConVar("sm_laser_tag_client_default", "1", "Default setting for new people connecting, 1=on and 0=off");
	g_CvarInactiveUsersOnly = CreateConVar("sm_laser_tag_spectators_only", "0", "Only show the laser beams for spectators, 1=on and 0=off");
	g_CvarTeamMembersOnly = CreateConVar("sm_laser_tag_team_members_only", "0", "Only show the laser beams for shots fired by members of the same team, 1=on and 0=off");
	g_CvarAttackerOnlyWhenEnabled = CreateConVar("sm_laser_tag_attacker_only_when_enabled", "0", "Only show the laser beams for shots fired by an attacker who has it enabled, 1=on and 0=off");

	g_CvarCTRed = CreateConVar("sm_laser_tag_ct_red", "25", "Amount OF Red In The Beam of the CTs", FCVAR_NOTIFY);
	g_CvarCTGreen = CreateConVar("sm_laser_tag_ct_green", "25", "Amount Of Green In The Beam of the CTs", FCVAR_NOTIFY);
	g_CvarCTBlue = CreateConVar("sm_laser_tag_ct_blue", "200", "Amount OF Blue In The Beam of the CTs", FCVAR_NOTIFY);

	g_CvarTRed = CreateConVar("sm_laser_tag_t_red", "200", "Amount OF Red In The Beam of the Ts", FCVAR_NOTIFY);
	g_CvarTGreen = CreateConVar("sm_laser_tag_t_green", "25", "Amount Of Green In The Beam of the Ts", FCVAR_NOTIFY);
	g_CvarTBlue = CreateConVar("sm_laser_tag_t_blue", "25", "Amount OF Blue In The Beam of the Ts", FCVAR_NOTIFY);

	g_CvarTrans = CreateConVar("sm_laser_tag_alpha", "150", "Amount OF Transparency In Beam", FCVAR_NOTIFY);
	g_CvarLife = CreateConVar("sm_laser_tag_life", "0.3", "Life of the Beam");
	g_CvarWidth = CreateConVar("sm_laser_tag_width", "3.0", "Width of the Beam");

	iLifeState = FindSendPropOffs("CBasePlayer", "m_lifeState");

	hGameConf = LoadGameConfigFile("laser_tag.games");
	if(hGameConf == INVALID_HANDLE)
	{
		SetFailState("gamedata/laser_tag.games.txt not loadable");
	}

	// Prep some virtual SDK calls
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "Weapon_ShootPosition");
	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
	hGetWeaponPosition = EndPrepSDKCall();

	HookEvent("bullet_impact", BulletImpact)
	HookEvent("round_start", EventRoundStart);

	RegConsoleCmd("lasertag", LaserTagMenu);

	hKVSettings=CreateKeyValues("UserSettings");
 	BuildPath( Path_SM, g_filenameSettings, MAX_FILE_LEN, "data/lasertagusersettings.txt" );
	if( !FileToKeyValues( hKVSettings, g_filenameSettings ) )
	{
   	KeyValuesToFile(hKVSettings, g_filenameSettings);
  }

	if( g_lateLoaded )
	{
		// Next we need to whatever we would have done as each client authorized
		for( new i = 1; i < GetMaxClients(); i++ )
		{
			if( IsClientInGame(i) && !IsFakeClient(i) )
			{
				PrepareClient(i);
			}
		}
	}
}

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	g_lateLoaded = late;
	return true;
}

public BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	if( GetConVarBool(g_CvarEnable) )
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "userid"));	

		new Float:bulletOrigin[3];
		SDKCall( hGetWeaponPosition, attacker, bulletOrigin );

		new Float:bulletDestination[3];
		bulletDestination[0] = GetEventFloat( event, "x" );
		bulletDestination[1] = GetEventFloat( event, "y" );
		bulletDestination[2] = GetEventFloat( event, "z" );

		// The following code moves the beam a little bit further away from the player
		new Float:distance = GetVectorDistance( bulletOrigin, bulletDestination );
		//PrintToChatAll( "vector distance: %f", distance );

		// calculate the percentage between 0.4 and the actual distance
		new Float:percentage = 0.4 / ( distance / 100 );
		//PrintToChatAll( "percentage (0.4): %f", percentage );

		// we add the difference between origin and destination times the percentage to calculate the new origin
		new Float:newBulletOrigin[3];
		newBulletOrigin[0] = bulletOrigin[0] + ( ( bulletDestination[0] - bulletOrigin[0] ) * percentage );
		newBulletOrigin[1] = bulletOrigin[1] + ( ( bulletDestination[1] - bulletOrigin[1] ) * percentage ) - 0.08;
		newBulletOrigin[2] = bulletOrigin[2] + ( ( bulletDestination[2] - bulletOrigin[2] ) * percentage );

		new color[4];
		if ( GetClientTeam( attacker ) == TERRORIST_TEAM )
		{
			color[0] = GetConVarInt( g_CvarTRed ); 
			color[1] = GetConVarInt( g_CvarTGreen );
			color[2] = GetConVarInt( g_CvarTBlue );
		}
		else
		{
			color[0] = GetConVarInt( g_CvarCTRed ); 
			color[1] = GetConVarInt( g_CvarCTGreen );
			color[2] = GetConVarInt( g_CvarCTBlue );
		}
		color[3] = GetConVarInt( g_CvarTrans );
		
		new Float:life;
		life = GetConVarFloat( g_CvarLife );

		new Float:width;
		width = GetConVarFloat( g_CvarWidth );

		/*
		start				Start position of the beam
		end					End position of the beam
		ModelIndex	Precached model index
		HaloIndex		Precached model index
		StartFrame	Initital frame to render
		FrameRate		Beam frame rate
		Life				Time duration of the beam
		Width				Initial beam width
		EndWidth		Final beam width
		FadeLength	Beam fade time duration
		Amplitude		Beam amplitude
		color				Color array (r, g, b, a)
		Speed				Speed of the beam
		*/
		
		TE_SetupBeamPoints( newBulletOrigin, bulletDestination, g_sprite, 0, 0, 0, life, width, width, 1, 0.0, color, 0);
		new bool:allowClientEnable=GetConVarBool( g_CvarAllowClientEnableDisable );
		new bool:inactiveUsersOnly=GetConVarBool( g_CvarInactiveUsersOnly );
		new bool:teamMembersOnly=GetConVarBool( g_CvarTeamMembersOnly );
		new bool:onlyIfEnabledForAttacker=GetConVarBool( g_CvarAttackerOnlyWhenEnabled );

		if ( allowClientEnable || inactiveUsersOnly || teamMembersOnly )
		{
			for( new client = 1; client < GetMaxClients(); client++ )
			{
				if ( IsClientInGame( client ) && !IsFakeClient( client ) && DisplayBeam( attacker, client, allowClientEnable, inactiveUsersOnly, teamMembersOnly, onlyIfEnabledForAttacker ) )
				{
					TE_SendToClient( client );
				}
			}
		}
		else
		{
			TE_SendToAll();
		}
	}
}

public bool:DisplayBeam( attacker, client, bool:allowClientEnable, bool:inactiveUsersOnly, bool:teamMembersOnly, bool:onlyIfEnabledForAttacker )
{
	if ( !allowClientEnable || IsClientEnabled( client ) )
	{
		if ( !inactiveUsersOnly || IsUserInactive( client ) )
		{
			if ( !teamMembersOnly || IsSameTeam( attacker, client ) )
			{
				if ( !onlyIfEnabledForAttacker || IsClientEnabled( attacker ) )
				{
					return true;
				}
			}
		}
	}
	return false;
}

public bool:IsSameTeam( attacker, client )
{
	return GetClientTeam( attacker ) == GetClientTeam( client );
}

public bool:IsClientEnabled( client )
{
	if ( g_userPreference[client] == 1 )
	{
		return true;
	}
	else
	{
		return false;
	}
}

public bool:IsUserInactive( client )
{
	new team = GetClientTeam( client );
	if ( team == TERRORIST_TEAM || team == COUNTER_TERRORIST_TEAM )
	{
		if ( iLifeState != -1 && GetEntData( client, iLifeState, 1 ) == 0 )
		{
			return false;
		}
		else
		{
			// death terrorist or death counter terrorist
			return true;
		}
	}
	else
	{
		// spectator
		return true;
	}
}

//  This creates the lastman panel
public Action:LaserTagMenu( client, args )
{
	new Handle:panel = CreatePanel();
	SetPanelTitle( panel, "Laser Tag" );
	if( g_userPreference[client] )
	{
		DrawPanelItem(panel, "Enable(Current Setting)");
		DrawPanelItem(panel, "Disable");
	}
	else
	{
		DrawPanelItem(panel, "Enable");
		DrawPanelItem(panel, "Disable(Current Setting)");
	}
	SendPanelToClient(panel, client, LaserTagMenuHandler, 20);
 
	CloseHandle(panel);

	return Plugin_Handled;
}

public LaserTagMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if ( action == MenuAction_Select )
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
		KvSetNum(hKVSettings, "lasertag enable", g_userPreference[param1]);
		KvSetNum(hKVSettings, "timestamp", GetTime());
	}
}

// Initializations to be done at the beginning of the round
public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Save user settings to a file
	KvRewind(hKVSettings);
	KeyValuesToFile(hKVSettings, g_filenameSettings);
}

public OnClientPutInServer(client)
{
	PrepareClient(client);
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
				g_userPreference[client] = KvGetNum(hKVSettings, "lasertag enable", 1);
			}
			else
			{
				KvRewind(hKVSettings);
				KvJumpToKey(hKVSettings, steamId, true);
				KvSetNum(hKVSettings, "lasertag enable", GetConVarInt(g_CvarDefaultClientSetting));
				g_userPreference[client] = GetConVarInt(g_CvarDefaultClientSetting);
			}
			KvRewind(hKVSettings);
		}
	}
}