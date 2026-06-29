#include <sourcemod>
#include <sdktools>
#include <store>
#include <entity>

new Handle:SpeedTimers[MAXPLAYERS+1]
new Handle:GravityTimers[MAXPLAYERS+1]

public OnPluginStart()
{
    Store_RegisterItemType("char", OnCharUse, OnWeaponsAttributesLoad);
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "store-inventory"))
    {
        Store_RegisterItemType("char", OnCharUse, OnWeaponsAttributesLoad);
    }   
}

// This will be called when the attributes are loaded.
public OnWeaponsAttributesLoad(const String:itemName[], const String:attrs[])
{
}

// This will be called when players use our item in their inventory.
public Store_ItemUseAction:OnCharUse(client, itemId, bool:equipped)
{
new HP = GetClientHealth(client);
	switch (itemId)
	{
		case 152:
		{
			if (HP < 100)
			{
				SetEntityHealth(client, 100)
			}
			else if (HP >= 100)
			{
				PrintToChat(client, "\x04Запрещено пользоваться аптечкой при полном HP");
				return Plugin_Handled;
			}
			
		}
		case 153:
		{
			if (HP = 100)
			{
				SetEntityHealth(client, 110)
			}
			else
			{
				PrintToChat(client, "\x04Запрещено пользоваться стимуляторами при менее 100 HP");
				return Plugin_Handled;
			}
		}
		case 154:
		{
			if (HP = 100)
			{
				SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.5);
				SpeedTimers[client] = CreateTimer(30.0, SpeedPlayer, client);
				PrintToChat(client, "\x04Вы чувствуете сильный прилив сил...");
			}
			else
			{
				PrintToChat(client, "\x04Запрещено пользоваться стимуляторами при менее 100 HP");
				return Plugin_Handled;
			}
		}
		case 155:
		{
			if (HP = 100)
			{
				SetEntityGravity(client, 0.5);
				GravityTimers[client] = CreateTimer(30.0, GravityPlayer, client);
				PrintToChat(client, "\x04Вы чувствуете , что можете допрыгнуть до луны...");
			}
			else
			{
				PrintToChat(client, "\x04Запрещено пользоваться стимуляторами при менее 100 HP");
				return Plugin_Handled;
			}
		}
	}
	
    return Store_DeleteItem;
}

public Action:SpeedPlayer(Handle:timer, any:client)
{
	PrintToChat(client, "\x04Действие стимулятора окончено!");
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
	KillTimer(SpeedTimers[client]);
	SpeedTimers[client] = INVALID_HANDLE;
}
public Action:GravityPlayer(Handle:timer, any:client)
{
	PrintToChat(client, "\x04Действие стимулятора окончено!");
	SetEntityGravity(client, 1.0);
	KillTimer(GravityTimers[client]);
	GravityTimers[client] = INVALID_HANDLE;
}