#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

new jockey_count = 0;
new jockeys[8];
new victims[8];
new bool:active[8];
new bool:injump[8];

public OnPluginStart()
{
	HookEvent("round_start", Round_Event);
	HookEvent("jockey_ride", Ride_Event);
	HookEvent("jockey_ride_end", Ride_End_Event);
}

public Action:Round_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	jockey_count = 0;
	for (new i = 0; i < 8; i++)
	{
		active[i] = false;
		injump[i] = false;
		jockeys[i] = 0;
		victims[i] = 0;
	}
}

public Action:Ride_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	jockeys[jockey_count] = GetClientOfUserId(GetEventInt(event, "userid"));
	victims[jockey_count] = GetClientOfUserId(GetEventInt(event, "victim"));
	active[jockey_count] = true;
	jockey_count++;
	
	//PrintToChatAll("Jockey Ride!!!");
}

public Action:Ride_End_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new jockey = GetClientOfUserId(GetEventInt(event, "userid"));
	new index = -1;
	
	for (new i = 0; i < 8; i++)
	{
		if (jockeys[i] == jockey)
		{
			index = i;
			break;
		}
	}
	
	//Oo
	if (index == -1) return;
	
	jockeys[index] = 0;
	victims[index] = 0;
	active[index] = false;
	jockey_count--;	
	
	//PrintToChatAll("over...");
}

public Action:OnPlayerRunCmd(client, &buttons)
{
	if (jockey_count > 0)
	{
		if (buttons & IN_JUMP)
		{
			new index = -1;
			
			for (new i = 0; i < 8; i++)
			{
				if (jockeys[i] == client)
				{
					index = i;
					break;
				}	
			}
			
			//PrintToChatAll("Jump?");
			
			if (index != -1)
			{
				if (!injump[index])
				{
					jump(victims[index]);
					injump[index] = true;
					CreateTimer(2.0, ResetJump, index);
				}
			}
		}
	}
}

public Action:ResetJump(Handle:timer, any:index)
{
	injump[index] = false;
}

jump(client)
{
	//PrintToChatAll("Jump!");
	new Float:vec[3] = {0.0, 0.0, 330.0};
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
}