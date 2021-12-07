#include <sourcemod>
#include <sdktools>
#include <morecolors>

#define MAX_KILLS_ONE_RESPONSE 1000

int ClientNumber[MAXPLAYERS+1];

public OnPluginStart()
{
	RegConsoleCmd("sm_achv", Command_Achievement);
}

public OnClientPutInServer(int Client)
{
	ClientNumber[Client] = 0;
}

public Action:Command_Achievement(Client, Args)
{
	Menu hMenu = new Menu(Menu_Achievement, MENU_ACTIONS_ALL);
	SetMenuTitle(hMenu, "kill menu");
	hMenu.AddItem("500", "500 zombies");
	hMenu.AddItem("100000", "100,000 zombies");
	hMenu.Display(Client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Menu_Achievement(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if(action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(param2, sInfo, sizeof(sInfo));
		int Zombies_Number = StringToInt(sInfo);
		
		if(ClientNumber[param1] > 0)
		{
			CPrintToChat(param1, "[\x07FF0000Error\x01] You already have an unlock in progress!");
			return;
		}
		
		if(!IsPlayerAlive(param1))
		{
			CPrintToChat(param1, "[\x07FF0000Error\x01] You have died!");
			return;
		}
		
		//find a zombie.
		int Zombie = -1;
		int MaxEntity = GetMaxEntities();
		decl String:ClassName[64];
		for (int Entity = GetMaxClients(); Entity < MaxEntity; Entity++)
		{
			if ( IsValidEdict(Entity) && IsValidEntity(Entity) )
			{
				GetEdictClassname(Entity, ClassName, sizeof(ClassName));
				if ( StrEqual(ClassName, "npc_nmrih_shamblerzombie")
					|| StrEqual(ClassName, "npc_nmrih_runnerzombie")
					|| StrEqual(ClassName, "npc_nmrih_kidzombie")
					|| StrEqual(ClassName, "npc_nmrih_turnedzombie") )
				{
					Zombie = Entity;
					break;
				}
			}
		}
		//If no valid zombie are found, create one.
		if(!IsValidEntity(Zombie))
		{
			Zombie = CreateEntityByName("npc_nmrih_shamblerzombie");
			DispatchSpawn(Zombie);
		}
		
		if(Zombies_Number <= MAX_KILLS_ONE_RESPONSE )
		{
			for(int i = 1; i <= Zombies_Number; i++)
			{
				//The weapon you take, or you can create specified weapons yourself.
				int Weapon = GetEntPropEnt( param1, Prop_Send, "m_hActiveWeapon" );
				
				//Fire zombiekilled event
				Handle Event_Kill = CreateEvent("entity_killed", true);
				SetEventInt(Event_Kill, "entindex_killed", Zombie);
				SetEventInt(Event_Kill, "entindex_attacker", param1);
				SetEventInt(Event_Kill, "entindex_inflictor", Weapon);
				SetEventInt(Event_Kill, "damagebits", 528386);
				FireEvent(Event_Kill);
				
				if(i == Zombies_Number)
				{
					AcceptEntityInput(Zombie, "Kill");
					CPrintToChat(param1, "[\x04Notice\x01] The kill was done");
				}
			}
			
			
		}
		else
		{
			ClientNumber[param1] = Zombies_Number;
			CreateTimer(1.0, Timer_Response, param1 | (Zombie << 7), TIMER_REPEAT);
			CPrintToChat(param1, "[\x04Notice\x01] The killing started. It takes about \x04%d\x01 seconds, keep alive!",
								 Zombies_Number / MAX_KILLS_ONE_RESPONSE);
			CPrintToChat(param1, "[\x04Notice\x01] You can view progress on the right messagebox.");
		}
	}
}

public Action Timer_Response(Handle timer, any param)
{
	int Client = param & 0x7F;
	int Zombie = param >> 7;
	
	if(!IsClientInGame(Client))
	{
		return Plugin_Stop;
	}
	
	if(!IsPlayerAlive(Client))
	{
		ClientNumber[Client] = 0;
		CPrintToChat(Client, "[\x07FF0000Error\x01] You have died, stop killing.");
		return Plugin_Stop;
	}
	
	bool IsValidZombie = false;
	
	if(IsValidEntity(Zombie))
	{
		decl String:ClassName[64];
		GetEdictClassname(Zombie, ClassName, sizeof(ClassName));
		if ( StrEqual(ClassName, "npc_nmrih_shamblerzombie")
			|| StrEqual(ClassName, "npc_nmrih_runnerzombie")
			|| StrEqual(ClassName, "npc_nmrih_kidzombie")
			|| StrEqual(ClassName, "npc_nmrih_turnedzombie") )
		{
			IsValidZombie = true;
			int Weapon = GetEntPropEnt( Client, Prop_Send, "m_hActiveWeapon" );
			
			for(int i = 1; i <= MAX_KILLS_ONE_RESPONSE; i++)
			{
				Handle Event_Kill = CreateEvent("entity_killed", true);
				SetEventInt(Event_Kill, "entindex_killed", Zombie);
				SetEventInt(Event_Kill, "entindex_attacker", Client);
				SetEventInt(Event_Kill, "entindex_inflictor", Weapon);
				SetEventInt(Event_Kill, "damagebits", 528386);
				FireEvent(Event_Kill);
				
				ClientNumber[Client]--;
				if(ClientNumber[Client] <= 0)
				{
					AcceptEntityInput(Zombie, "Kill");
					CPrintToChat(Client, "[\x04Notice\x01] The kill was done");
					
					new Handle:Message = StartMessageOne("KeyHintText", Client);
					SetGlobalTransTarget(Client);
					BfWriteByte(Message, 1); 
					BfWriteString(Message, "kill: 0"); 
					EndMessage();
					
					return Plugin_Stop;
				}
			}
		}
	}
	
	//The zombie is invalid, find/create another.
	if(!IsValidZombie)
	{
		Zombie = -1;
		int MaxEntity = GetMaxEntities();
		decl String:ClassName[64];
		for (int Entity = GetMaxClients(); Entity < MaxEntity; Entity++)
		{
			if ( IsValidEdict(Entity) && IsValidEntity(Entity) )
			{
				GetEdictClassname(Entity, ClassName, sizeof(ClassName));
				if ( StrEqual(ClassName, "npc_nmrih_shamblerzombie")
					|| StrEqual(ClassName, "npc_nmrih_runnerzombie")
					|| StrEqual(ClassName, "npc_nmrih_kidzombie")
					|| StrEqual(ClassName, "npc_nmrih_turnedzombie") )
				{
					Zombie = Entity;
					break;
				}
			}
		}
		
		if(!IsValidEntity(Zombie))
		{
			Zombie = CreateEntityByName("npc_nmrih_shamblerzombie");
			DispatchSpawn(Zombie);
			CreateTimer(1.0, Timer_Response, Client | (Zombie << 7), TIMER_REPEAT);
			return Plugin_Stop;
		}
	}
	
	char Buffer[128];
	Format(Buffer, sizeof(Buffer), "kill: %d", ClientNumber[Client]);
	new Handle:Message = StartMessageOne("KeyHintText", Client);
	SetGlobalTransTarget(Client);
	BfWriteByte(Message, 1); 
	BfWriteString(Message, Buffer); 
	EndMessage();
	
	return Plugin_Continue;
}