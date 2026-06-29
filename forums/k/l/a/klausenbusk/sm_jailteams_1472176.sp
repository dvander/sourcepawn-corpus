#include <sourcemod>
#include <sdktools>

#define terrorist 			2
#define counterTerrorist 	3

public Plugin:myinfo = 
{
	name 		= "SM Jail Teams",
	author 		= "Elad Nava",
	description = "This plugin introduces a team ratio of terrorists to counter-terrorists for jail servers.",
	version 	= "1.0.3",
	url 		= "http://eladnava.com"
}

public OnPluginStart()
{
	//-----------------------------------------
	// Create our ConVars
	//-----------------------------------------
	
	CreateConVar( "sm_jt", "1", "Enables the jail team ratio plugin.", FCVAR_PLUGIN );
	CreateConVar( "sm_jt_ratio", "3", "The ratio of terrorists to counter-terrorists. (Default: 1CT = 3T)", FCVAR_PLUGIN );
	CreateConVar( "sm_jt_version", "1.0.3", "There is no need to change this value.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY );

	//-----------------------------------------
	// Generate config file
	//-----------------------------------------
	
	AutoExecConfig( true, "sm_jailteams" );
	
	//-----------------------------------------
	// Hook into join team command
	//-----------------------------------------
	
	RegConsoleCmd( "jointeam", jailTeams );
}

public Action:jailTeams( client, args )
{
	//-----------------------------------------
	// Get the CVar T:CT ratio
	//-----------------------------------------

	new teamRatio = GetConVarInt( FindConVar( "sm_jt_ratio" ) );
	
	//-----------------------------------------
	// System online?
	//-----------------------------------------

	if ( ! GetConVarBool( FindConVar( "sm_jt" ) ) )
	{
		return Plugin_Continue;
	}
	
	//-----------------------------------------
	// Is it a human?
	//-----------------------------------------
	
	if ( ! client || ! IsClientInGame( client ) || IsFakeClient( client ) )
	{
		return Plugin_Continue;
	}
	
	//-----------------------------------------
	// Bypass for SM admins
	//-----------------------------------------
	
	/*if ( GetUserAdmin( client ) != INVALID_ADMIN_ID )
	{
		return Plugin_Continue;
	}*/
	
	//-----------------------------------------
	// Get new and old teams
	//-----------------------------------------
	
	decl String:teamString[3];
	GetCmdArg( 1, teamString, sizeof( teamString ) );
	
	new newTeam = StringToInt(teamString);
	new oldTeam = GetClientTeam(client);
	
	//-----------------------------------------
	// Are we trying to switch to CT?
	//-----------------------------------------
	
	if ( newTeam == counterTerrorist && oldTeam != counterTerrorist )
	{
		new idx			= 0;
		new countTs 	= 0;
		new countCTs 	= 0;
		
		//-----------------------------------------
		// Count up our players!
		//-----------------------------------------
		
		for ( idx = 1; idx <= MaxClients; idx++ )
		{
		      if ( IsClientInGame( idx ) )
		      {
				 if ( GetClientTeam( idx ) == terrorist )
		         {
		            countTs++;
		         }
				 
				 if ( GetClientTeam( idx ) == counterTerrorist )
		         {
		            countCTs++;
		         }
		      }      
		}
		
		//-----------------------------------------
		// Are we trying to unbalance the ratio?
		//-----------------------------------------

		if ( countCTs < ( ( countTs ) / teamRatio ) || ! countCTs )
		{
			return Plugin_Continue;
		}
		else
		{
			//-----------------------------------------
			// Send client sound
			//-----------------------------------------
			
			ClientCommand( client, "play ui/freeze_cam.wav" );
			
			//-----------------------------------------
			// Show client message
			//-----------------------------------------
			
			PrintToChat( client, "\x03[SMJT] \x04Transfer denied, there are enough CTs!", teamRatio );

			//-----------------------------------------
			// Kill the team change request
			//-----------------------------------------

			return Plugin_Handled;
		}		
	}
	
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	if (GetClientTeam(client) == 2) // 2 = T / 3 = CT
	{		
		new countTs 	= 0;
		new countCTs 	= 0;
		
		new lowestCTtime = 0;
		new Float:timeCTs = 0.0;
		for (new idx = 1; idx <= MaxClients; idx++ )
		{
		      if ( IsClientInGame( idx ) )
		      {
				new Float:time = GetClientTime(client);
				if ( GetClientTeam( idx ) == terrorist )
				{
		        		countTs++;
		        	}
				 
				if ( GetClientTeam( idx ) == counterTerrorist )
			        {
					if (time < timeCTs || timeCTs == 0.0)
					{
						lowestCTtime = idx;
						timeCTs == time;
					}
		         		countCTs++;
		        	}
		      }      
		}
		new teamRatio = GetConVarInt( FindConVar( "sm_jt_ratio" ) );
		if ( countCTs > ( ( countTs ) / teamRatio ))
		{
			if(lowestCTtime != 0)
			{
				ChangeClientTeam(lowestCTtime, 2);
			}
		}
		
	}
}
