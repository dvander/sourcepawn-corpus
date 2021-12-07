#include <sdktools>
#include <cstrike>

char botTarget;
bool IsAimed[MAXPLAYERS+1];
bool InUse[MAXPLAYERS+1];
float clientVec[3];
float botVec[3];
int PlayerAimTarget[MAXPLAYERS+1];

Handle HandleDropC4 = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Bots drop C4",
	author = "gOoDnIgHt",
	description = "Players can force nearby Bots to drop C4 with E",
	version = "1.0",
	url = "ExaGame.ir"
};

public OnMapStart()
{
	HandleDropC4 = EndPrepSDKCall();
}
public Action OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_T)
	{
		botTarget = GetClientAimTarget(client, true);
		if(botTarget != -1 && IsClientInGame(botTarget) && IsFakeClient(botTarget) && GetPlayerWeaponSlot(botTarget, 4) != -1)
		{
			GetClientAbsOrigin(client, clientVec);
			GetClientAbsOrigin(botTarget, botVec);
			if(GetVectorDistance(clientVec, botVec) < 200)
			{
				PlayerAimTarget[client] = botTarget;
				IsAimed[client] = true;
				PrintCenterText(client, "Press E, to take the bomb!");
				if(!InUse[client] && buttons & IN_USE)
				{
					DropC4(client, 0);
					InUse[client] = true;
				}
				else if(InUse[client] && !(buttons & IN_USE))
				{
					InUse[client] = false;
				}
			}
			return Plugin_Continue;
		}
		if(PlayerAimTarget[client] && IsAimed[client])
		{
			botTarget = PlayerAimTarget[client];
			PlayerAimTarget[client] = 0;
			PrintCenterText(client, " ");
			IsAimed[client] = false;
		}
	}
	return Plugin_Continue;
}
public Action DropC4(client, args)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsFakeClient(i) && GetPlayerWeaponSlot(i, 4) != -1)
		{
			FakeClientCommand(i, "say_team I dropped the Bomb!");
			SDKCall(HandleDropC4, i, GetPlayerWeaponSlot(i, 4), false, false);
		}
	}
	return Plugin_Handled;
}