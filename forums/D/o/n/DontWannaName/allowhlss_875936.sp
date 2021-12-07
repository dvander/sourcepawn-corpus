/**
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 */
#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "3.0"


/*****************************************************************


			P L U G I N   I N F O


*****************************************************************/
public Plugin:myinfo = {
    name = "Allow HLSS",
    author = "Arg!",
    description = "Allows admins to use HLSS/HLDJ even if sv_allow_voice_from_file 0",
    version = PLUGIN_VERSION,
    url = "http://www.sourcemod.com"
};


/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/
new Handle:cvar_AllowVoice = INVALID_HANDLE;

new Handle:cvar_AllowedTime;
new Handle:cvar_AllowedTime_Start;
new Handle:cvar_AllowedTime_End;

/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/
public OnPluginStart() 
{
	CreateConVar("sm_allowhlss_version", PLUGIN_VERSION, "Allows admins to use HLSS/HLDJ even if sv_allow_voice_from_file 0", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	RegAdminCmd("sm_hlsson", Command_HLSSOn, ADMFLAG_ROOT, "Does nothing. Use in an override to give people HLSS/HLDJ access");
	
	cvar_AllowedTime = CreateConVar("sm_hlssallowedtime", "0", "Enables sv_allow_voice_from_file during a specified time frame", FCVAR_PLUGIN);
	
	cvar_AllowedTime_Start = CreateConVar("sm_hlssallowedtime_start", "0", "Start hour for 'sm_hlssallowedtime'", FCVAR_PLUGIN );
	cvar_AllowedTime_End = CreateConVar("sm_hlssallowedtime_end", "0", "End hour for 'sm_hlssallowedtime'", FCVAR_PLUGIN );
	
	AutoExecConfig(true, "allowhlss");
	
	cvar_AllowVoice = FindConVar("sv_allow_voice_from_file");
	HookConVarChange(cvar_AllowVoice, AllowVoiceChanged);
	
	setClientsHLSSAccess();
}

public OnClientPostAdminCheck( client )
{
	if( CheckCommandAccess(client, "sm_hlsson", ADMFLAG_ROOT) && !GetConVarBool(cvar_AllowVoice) )
	{
		SendConVarValue( client, cvar_AllowVoice, "1" );
	}
}

public OnConfigsExecuted()
{
	if( GetConVarBool(cvar_AllowedTime) )
	{
		if( !isHourValid( GetConVarInt( cvar_AllowedTime_Start ) ) || !isHourValid( GetConVarInt( cvar_AllowedTime_End ) ) )
		{
			LogError( "Invalid hour for either sm_hlssallowedtime_start or sm_hlssallowedtime_end" );
			return;
		}
		
		if(  GetConVarInt( cvar_AllowedTime_Start ) == GetConVarInt( cvar_AllowedTime_End ) )
		{
			LogError( "sm_hlssallowedtime_start and sm_hlssallowedtime_end cannot be the same" );
			return;
		}	

		//following day check
		if( GetConVarInt( cvar_AllowedTime_End ) < GetConVarInt( cvar_AllowedTime_Start ) )
		{
			if( getHour() >= GetConVarInt( cvar_AllowedTime_End ) && getHour() < GetConVarInt( cvar_AllowedTime_Start ) )
			{
				SetConVarBool( cvar_AllowVoice, false, true );
			}
			else
			{
				SetConVarBool( cvar_AllowVoice, true, true );
			}
		}	
		else 
		{
			if( getHour() >= GetConVarInt( cvar_AllowedTime_Start ) && getHour() < GetConVarInt( cvar_AllowedTime_End ) )
			{
				SetConVarBool( cvar_AllowVoice, true, true );
			}
			else
			{
				SetConVarBool( cvar_AllowVoice, false, true );
			}
		}
	}
}
/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/
public AllowVoiceChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CreateTimer(0.1, Timer_CheckClientAccess );
}

public Action:Timer_CheckClientAccess(Handle:timer)
{
	//sv_allow_voice_from_file changed, reset everyone status
	setClientsHLSSAccess();
}

public Action:Command_HLSSOn(client, args)
{
	return Plugin_Handled;
}


/****************************************************************


			P L U G I N    F U N C T I O N S


****************************************************************/
setClientsHLSSAccess()
{		
	for( new client = 1; client <= MAXPLAYERS && !GetConVarBool(cvar_AllowVoice); client++ )
	{
		if( CheckCommandAccess(client, "sm_hlsson", ADMFLAG_ROOT) )
		{
			SendConVarValue( client, cvar_AllowVoice, "1" );
		}
	}
}



//Stolen from plugin Server Crontab - http://forums.alliedmods.net/showthread.php?p=523298
bool:isHourValid (hour)
{
    if (hour > 23)
        return false;
    return true;
}

//Stolen from plugin Server Crontab - http://forums.alliedmods.net/showthread.php?p=523298
getHour ()
{
    decl String:szHour[3] = "";

    FormatTime (szHour, sizeof (szHour), "%H");
       
    return StringToInt (szHour);
}