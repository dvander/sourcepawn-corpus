#include <sourcemod>
#include <tf2_stocks>
#include <tf2_objects>

public Plugin:myinfo = 
{
	name = "Bad Tele Nuke",
	author = "Kevin_b_er",
	description = "Nukes teles built at the secondary 2fort drop-down",
	version = "1.1",
	url = "www.brothersofchaos.com"
}

								//H		L
new Float:badLocs[2][3][2] = { { {-320.0, -370.0},
								 {2030.0, 1940.0},
								 {257.0, 256.0 } },
								 
							   { {370.0,   320.0},
								 {-1940.0, -2020.0},
								 {257.0, 	256.0 } } };
								 
#define HIGH 0
#define LOW  1						 


public OnPluginStart()
{
	HookEvent("player_builtobject", BuiltObjectEvent, EventHookMode_Post);
}

public Action:BuiltObjectEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl Float:teleLoc[3];
	new objectid = GetEventInt(event,"index");
	new TFObjectType:type = TF2_GetObjectType(objectid, true);
	
	if( type == TFObjectType_TeleporterExit )
	{
		GetEntPropVector(objectid, Prop_Send, "m_vecOrigin", teleLoc);
		// RED vs BLU drop-down spawn
		for( new entry_num = 0; entry_num < 2; entry_num++ )
		{
			new axis_count = 0;
			for( new axis = 0; axis < 3; axis++ )
			{
				// Check this axis for being within the bounds
				if( (teleLoc[axis] < badLocs[entry_num][axis][HIGH]) &&
					(teleLoc[axis] > badLocs[entry_num][axis][LOW]) )
				{
					axis_count++;
				}
				else
				{
					break;
				}
			}
			if( axis_count == 3 )
			{
				// Each axis was found to be within the bounds, make with the pain.
				
				// Kill the building
				SetVariantInt(9999);
				AcceptEntityInput(objectid, "RemoveHealth");
				
				decl String:authString[64];
				if ( !GetClientAuthString(client, authString, 64) )
					{
					strcopy(authString, 64, "STEAM_ID_PENDING");
					}

				FakeClientCommand(client, "explode");
				FakeClientCommand(client, "kill");
				LogMessage( "\"%N<%s>\" had a teleporter destroyed for bad build location.", client, authString );
				PrintToChatAll("%N attempted to build a tele in respawn.", client);
				break;
			}
		}
	}
	
	return Plugin_Continue;
}
