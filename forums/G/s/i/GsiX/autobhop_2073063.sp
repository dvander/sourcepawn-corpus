#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

static g_enable = 1;

public OnPluginStart()
{
	RegAdminCmd( "sm_bhop", Command_CustomBhopShort, ADMFLAG_ROOT );
}

public Action:Command_CustomBhopShort( client, args )
{
	if ( client < 1 )
	{
		ReplyToCommand( client, "[BHOP]: Command in game only.." );
		return Plugin_Handled;
	}
	if ( args > 1 )
	{
		ReplyToCommand( client, "[BHOP]: Usage, !bhop in chat to toggle plugin on/off" );
		return Plugin_Handled;
	}
	
	if (g_enable == 0 )
	{
		g_enable = 1;
		ReplyToCommand( client, "[BHOP]: Autobhop is Enable.." );
	}
	else
	{
		g_enable = 0;
		ReplyToCommand( client, "[BHOP]: Autobhop is Disable.." );
	}
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{	
	if ( IsClientInGame( client ) && IsPlayerAlive(client) && g_enable == 1 )
    {
		if (buttons & IN_JUMP)
		{
			if (!(GetEntityFlags(client) & FL_ONGROUND))
			{
				if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
				{
					if (GetEntProp(client, Prop_Data, "m_nWaterLevel") <= 1)
					{
						buttons &= ~IN_JUMP;
					}
				}
			}
		}
    }
	
	return Plugin_Continue;
}
