#include <sourcemod>
#include <sdktools>
//Buguse
static pressedE[33];
static Float:lastpressedE[33];
static bool:PrethinkBuffer[33] = false;

public Plugin:myinfo =
{
	name = "E Spammer",
	author = "Darkthrone, Krim",
	description = "Blocks Spamming E",
	version = "1.2",
	url = "http://forums.alliedmods.net/showthread.php?t=78191"
};
 
public OnGameFrame()
{
	//Declare:
	decl MaxPlayers;

	//Initialize:
	MaxPlayers = GetMaxClients();

	//Loop:
	for(new Client = 1; Client <= MaxPlayers; Client++)
	{
		//Connected:
		if(IsClientConnected(Client) && IsClientInGame(Client))
		{
			if(GetClientButtons(Client) & IN_USE)
	        	{
                		if(!PrethinkBuffer[Client])    
                		{
                    			PrethinkBuffer[Client] = true; 
                    			decl Ent;
                    			decl String:ClassName[255];
                      
                    			Ent = GetClientAimTarget(Client, false);
                    
                    			if(Ent != -1 && Ent > 0 && Ent > GetMaxClients())
                    			{
                        			GetEdictClassname(Ent, ClassName, 255);
                        			if(StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating"))
                        			{    
                            				decl Float:ClientOrigin[3], Float:EntOrigin[3];  
                            				decl Float:Dist;
                            				GetClientAbsOrigin(Client, ClientOrigin);
                            				GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", EntOrigin);
                            				Dist = GetVectorDistance(ClientOrigin, EntOrigin);
                            
                            				if(Dist < 300)
                            				{
                                				if(!pressedE[Client]) pressedE[Client] = 1;
                                				else pressedE[Client]++;
                                
                                				if(lastpressedE[Client] >= GetGameTime()-3)
                                				{     
                                    					if(pressedE[Client] == 20)
                                    					{
                                        					CreateTimer(0.1, Kick, Client);
                                    					}
                                    					else if(pressedE[Client] == 16)
                                        					PrintToChat(Client, "\x04[DoorBlock] \x01LAST WARNING: Stop Doorblocking or KICK!");  
                                    					else if(pressedE[Client] == 12)
                                        					PrintToChat(Client, "\x04[DoorBlock] \x01Warning: Stop Doorblocking or KICK!"); 
                                    					else if(pressedE[Client] == 8)
                                        					PrintToChat(Client, "\x04[DoorBlock] \x01Stop DoorBlocking!"); 
                                    					else if(pressedE[Client] == 4)
                                        					PrintToChat(Client, "\x04[DoorBlock] \x01Stop DoorBlocking"); 
                                				} else
                                				{
                                     					pressedE[Client] = 1;
                                				}
                                				lastpressedE[Client] = GetGameTime();
                            				}			
                       				}
                    			}
                		}
	        	}
            		else
            		{
            			//Hook:
            			PrethinkBuffer[Client] = false;
            		}
        	} 
    	}
}

public Action:Kick(Handle:Timer, any:Client)
{
    KickClient(Client, "Door blocking");
    return Plugin_Handled; 
}

