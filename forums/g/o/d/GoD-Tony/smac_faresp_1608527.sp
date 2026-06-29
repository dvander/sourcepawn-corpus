#pragma semicolon 1

#include <sourcemod>
#include <cstrike>

new UserMsg:msgUpdateRadar = INVALID_MESSAGE_ID;

public OnPluginStart()
{
	msgUpdateRadar = GetUserMessageId("UpdateRadar");
	
	if (msgUpdateRadar != INVALID_MESSAGE_ID)
	{
		HookUserMessage(msgUpdateRadar, Hook_UpdateRadar, true);
		CreateTimer(1.0, Timer_UpdateRadar, _, TIMER_REPEAT);
	}
}

public Action:Hook_UpdateRadar(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	// We will send custom messages only.
	return Plugin_Handled;
}

public Action:Timer_UpdateRadar(Handle:timer)
{
	// Determine which clients we'll need data from.
	decl iTClients[MaxClients], iCTClients[MaxClients];
	new inumTClients, inumCTClients;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
		{
			switch (GetClientTeam(i))
			{
				case CS_TEAM_T:
				{
					iTClients[inumTClients++] = i;
				}
				case CS_TEAM_CT:
				{
					iCTClients[inumCTClients++] = i;
				}
			}
		}
	}
	
	// Send a separate message to each team.
	decl Float:vOrigin[3], Float:vAngles[3], client;
	
	// Terrorists.
	if (inumTClients && inumTClients <= 36)
	{
		new Handle:bf = StartMessageEx(msgUpdateRadar, iTClients, inumTClients, USERMSG_BLOCKHOOKS);
		
		for (new i = 0; i < inumTClients; i++)
		{
			client = iTClients[i];
			
			GetClientAbsOrigin(client, vOrigin);
			GetClientAbsAngles(client, vAngles);
			
			BfWriteByte(bf, client);
			BfWriteSBitLong(bf, RoundToNearest(vOrigin[0] / 4.0), 13);
			BfWriteSBitLong(bf, RoundToNearest(vOrigin[1] / 4.0), 13);
			BfWriteSBitLong(bf, RoundToNearest(vOrigin[2] / 4.0), 13);
			BfWriteSBitLong(bf, RoundToNearest(vAngles[1]), 9);
		}
		
		BfWriteByte(bf, 0);
		EndMessage();
	}
	
	// Counter-Terrorists.
	if (inumCTClients && inumCTClients <= 36)
	{
		new Handle:bf = StartMessageEx(msgUpdateRadar, iCTClients, inumCTClients, USERMSG_BLOCKHOOKS);
		
		for (new i = 0; i < inumCTClients; i++)
		{
			client = iCTClients[i];
			
			GetClientAbsOrigin(client, vOrigin);
			GetClientAbsAngles(client, vAngles);
			
			BfWriteByte(bf, client);
			BfWriteSBitLong(bf, RoundToNearest(vOrigin[0] / 4.0), 13);
			BfWriteSBitLong(bf, RoundToNearest(vOrigin[1] / 4.0), 13);
			BfWriteSBitLong(bf, RoundToNearest(vOrigin[2] / 4.0), 13);
			BfWriteSBitLong(bf, RoundToNearest(vAngles[1]), 9);
		}
		
		BfWriteByte(bf, 0);
		EndMessage();
	}
	
	return Plugin_Continue;
}

stock BfWriteSBitLong(Handle:bf, data, numBits)
{
	decl bool:bit;
	
	for (new i = 0; i < numBits; i++)
	{
		bit = !!(data & (1 << i));
		BfWriteBool(bf, bit);
	}
}

stock BfReadSBitLong(Handle:bf, numBits)
{
	decl bool:bits[numBits], ret, i;
	
	for (i = 0; i < numBits; i++)
	{
		bits[i] = BfReadBool(bf);
	}
	
	ret = bits[numBits-1] ? -1 : 0;
	
	for (i = numBits-1; i >= 0; i--)
	{
		ret <<= 1;
		ret |= bits[i];
	}
	
	return ret;
}
