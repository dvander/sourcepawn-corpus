#include <sourcemod>
#include <sdktools>

new pressedE[MAXPLAYERS+1];
new Float:lastPressed[MAXPLAYERS+1];
new bool:blocked[MAXPLAYERS+1];

public OnPluginStart()
{
	HookEvent("round_start", roundStart);
}

public Action:roundStart(Handle:event, const String:Name[], bool:dontBroadcast)
{
	new Max = GetMaxEntities();
	for(new i = 1; i <= Max; i++)
	{
		if(IsValidEdict(i))
		{
			decl String:name[90];
			GetEdictClassname(i, name, sizeof(name));
			
			if(StrContains(name, "door_rotating") != -1)
			{
				HookSingleEntityOutput(i, "OnOpen", Open);
			}
		}
	}
}

public Open(const String:output[], door, client, Float:delay)
{
	if(!pressedE[client])
	{
		pressedE[client] = 1;
		lastPressed[client] = GetGameTime()
	}
	else if(pressedE[client] >= 1)
	{
		if(lastPressed[client] >= GetGameTime()-3)
		{
			pressedE[client]++;
			
			if(pressedE[client] == 5)
			{
				blocked[client] = true;
				CreateTimer(5.0, Allow, client);
				PrintToChat(client,"\x04[DoorBlock \x01By.:RpM\x04]\x03 You can't use \"E\" for 5 seconds!"); 
			}
		}
		else
		{
			pressedE[client] = 1;
		}
	}
}


public Action:Allow(Handle:Timer, any:client)
{
	blocked[client] = false;
	PrintToChat(client,"\x04[DoorBlock \x01By.:RpM\x04]\x03 You can use \"E\" again!"); 
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(blocked[client])
	{
		buttons &= ~IN_USE;
	}
}